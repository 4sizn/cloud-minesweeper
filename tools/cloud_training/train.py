"""Train the bundled cloud segmenter on the COCO-Stuff derived dataset.

Data comes from build_dataset.py, which keeps only COCO images whose license
allows commercial use and derivative works. No user photographs are accessed.

  python tools/cloud_training/build_dataset.py
  python tools/cloud_training/train.py --epochs 40
"""
import argparse
import json
import random
import time
from pathlib import Path

import numpy as np
from PIL import Image
import torch
from torch import nn
from torch.nn import functional as F

ROOT = Path(__file__).resolve().parents[2]
SEED = 20260921
SIDE = 160


class CloudNet(nn.Module):
    def __init__(self):
        super().__init__()
        def block(a, b):
            return nn.Sequential(nn.Conv2d(a, b, 3, padding=1), nn.ReLU(),
                                 nn.Conv2d(b, b, 3, padding=1), nn.ReLU())
        self.enc1 = block(3, 12)
        self.enc2 = block(12, 24)
        self.middle = block(24, 48)
        self.dec2 = block(72, 24)
        self.dec1 = block(36, 12)
        self.head = nn.Conv2d(12, 1, 1)

    def forward(self, x):
        a = self.enc1(x)
        b = self.enc2(F.avg_pool2d(a, 2))
        c = self.middle(F.avg_pool2d(b, 2))
        d = self.dec2(torch.cat([F.interpolate(c, scale_factor=2, mode='bilinear', align_corners=False), b], 1))
        e = self.dec1(torch.cat([F.interpolate(d, scale_factor=2, mode='bilinear', align_corners=False), a], 1))
        return self.head(e)


class MobileCloudNet(nn.Module):
    """Export wrapper: raw RGB [0,255] at 320px in, sigmoid cloud score out."""

    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, rgb):
        x = F.avg_pool2d(rgb / 255.0, 2)
        return F.interpolate(self.model(x).sigmoid(), scale_factor=2,
                             mode='bilinear', align_corners=False)


def load_split(directory, part):
    images, masks, ids = [], [], []
    for path in sorted((directory / part / 'images').glob('*.png')):
        mask = directory / part / 'masks' / path.name
        images.append(np.array(Image.open(path).convert('RGB').resize((320, 320), Image.Resampling.BILINEAR)))
        masks.append(np.array(Image.open(mask).convert('L').resize((SIDE, SIDE), Image.Resampling.NEAREST)) > 127)
        ids.append(path.stem)
    return images, masks, ids


def tensors(images, masks, device):
    raw = torch.from_numpy(np.stack(images)).permute(0, 3, 1, 2).float() / 255
    x = F.avg_pool2d(raw, 2)
    y = torch.from_numpy(np.stack(masks)[:, None]).float()
    return x.to(device), y.to(device)


def metrics(p, y, threshold=.5):
    pred, gt = p >= threshold, y >= .5
    tp = np.logical_and(pred, gt).sum()
    fp = np.logical_and(pred, ~gt).sum()
    fn = np.logical_and(~pred, gt).sum()
    inter = np.logical_and(pred, gt).sum(axis=(-2, -1))
    union = np.logical_or(pred, gt).sum(axis=(-2, -1))
    return dict(iou=float(tp / max(1, tp + fp + fn)),
                mean_image_iou=float(np.mean((inter + 1e-7) / (union + 1e-7))),
                precision=float(tp / max(1, tp + fp)), recall=float(tp / max(1, tp + fn)))


def grid_iou(p, y, threshold):
    """IoU over the 16x16 playing grid, which is what the game actually uses."""
    cells = lambda a: a.reshape(a.shape[0], 16, a.shape[1] // 16, 16, a.shape[2] // 16).mean((2, 4))
    pred, gt = cells(p) >= threshold, cells(y.astype(np.float32)) >= .5
    inter = np.logical_and(pred, gt).sum()
    union = np.logical_or(pred, gt).sum()
    return float(inter / max(1, union))


def predict(model, x):
    model.eval()
    with torch.no_grad():
        return torch.cat([model(b).sigmoid().cpu() for b in x.split(16)]).numpy()[:, 0]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', type=Path, default=ROOT / '.local-data/coco/dataset')
    parser.add_argument('--epochs', type=int, default=40)
    parser.add_argument('--out', type=Path, default=ROOT / '.local-data/coco/training')
    args = parser.parse_args()
    torch.manual_seed(SEED); np.random.seed(SEED); random.seed(SEED)
    torch.set_num_threads(4)
    device = 'mps' if torch.backends.mps.is_available() else 'cpu'
    args.out.mkdir(parents=True, exist_ok=True)

    splits = {part: load_split(args.data, part) for part in ('train', 'val', 'test')}
    print({part: len(v[2]) for part, v in splits.items()}, 'device:', device, flush=True)
    x, y = tensors(*splits['train'][:2], device)
    vx, vy = tensors(*splits['val'][:2], device)
    vy_np = vy.cpu().numpy()[:, 0]

    model = CloudNet().to(device)
    opt = torch.optim.Adam(model.parameters(), lr=.001)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(opt, args.epochs, eta_min=.0001)
    best, history, start = -1, [], time.monotonic()
    for epoch in range(args.epochs):
        model.train(); losses = []
        for ids in torch.randperm(len(x), device=device).split(16):
            bx, by = x[ids], y[ids]
            if random.random() < .5: bx, by = bx.flip(-1), by.flip(-1)
            if random.random() < .5: bx, by = bx.flip(-2), by.flip(-2)
            gain = torch.rand((len(ids), 1, 1, 1), device=device) * .3 + .85
            bx = (bx * gain).clamp(0, 1)
            logits = model(bx)
            bce = F.binary_cross_entropy_with_logits(logits, by)
            prob = logits.sigmoid()
            dice = 1 - (2 * (prob * by).sum((1, 2, 3)) + 1) / (prob.sum((1, 2, 3)) + by.sum((1, 2, 3)) + 1)
            loss = bce + .3 * dice.mean()
            opt.zero_grad(); loss.backward(); opt.step()
            losses.append(float(loss.detach()))
        scheduler.step()
        val = metrics(predict(model, vx), vy_np)
        record = dict(epoch=epoch + 1, loss=float(np.mean(losses)), validation=val,
                      elapsed_seconds=round(time.monotonic() - start, 1))
        history.append(record)
        print(json.dumps(record), flush=True)
        if val['iou'] > best:
            best = val['iou']
            torch.save({k: v.cpu() for k, v in model.state_dict().items()}, args.out / 'best.pt')
        (args.out / 'history.json').write_text(json.dumps(history, indent=2))

    model.load_state_dict(torch.load(args.out / 'best.pt'))
    model.to(device)
    # Threshold is chosen on validation only; test images never tune anything.
    val_pred = predict(model, vx)
    search = [dict(threshold=round(t, 3), pixel_iou=metrics(val_pred, vy_np, t)['iou'],
                   grid_iou=grid_iou(val_pred, vy_np, t))
              for t in np.arange(.3, .75, .025)]
    chosen = max(search, key=lambda r: r['grid_iou'])
    (args.out / 'threshold.json').write_text(json.dumps(dict(search=search, chosen=chosen), indent=2))

    tx, ty = tensors(*splits['test'][:2], device)
    ty_np = ty.cpu().numpy()[:, 0]
    test_pred = predict(model, tx)
    report = dict(validation=metrics(val_pred, vy_np, chosen['threshold']),
                  validation_grid_iou=grid_iou(val_pred, vy_np, chosen['threshold']),
                  test=metrics(test_pred, ty_np, chosen['threshold']),
                  test_grid_iou=grid_iou(test_pred, ty_np, chosen['threshold']),
                  threshold=chosen['threshold'],
                  counts={part: len(v[2]) for part, v in splits.items()})
    (args.out / 'report.json').write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2), flush=True)

    export = MobileCloudNet(model.cpu()).eval()
    target = ROOT / 'assets/models/cloud_coco_v1.onnx'
    torch.onnx.export(export, torch.zeros(1, 3, 320, 320), str(target), input_names=['rgb'],
                      output_names=['cloud'], opset_version=17, dynamo=False)
    print('exported', target, target.stat().st_size, 'bytes', flush=True)


if __name__ == '__main__':
    main()
