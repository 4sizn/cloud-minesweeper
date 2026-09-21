"""Train a small cloud segmenter. Public SWIMSEG data is research-only (CC BY-NC).
Download/extract as documented in README.md; no user photographs are accessed.
"""
import argparse
import csv
import hashlib
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
    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, rgb):
        # Raw RGB [0,255], NCHW 320px. Average pooling is reproducible in Dart/ORT.
        x = F.avg_pool2d(rgb / 255.0, 2)
        return F.interpolate(self.model(x).sigmoid(), scale_factor=2,
                             mode='bilinear', align_corners=False)


def load_data(directory):
    # Known annotated pixels prevent the mirror's reversed class CSV corrupting labels.
    reference = Image.open(directory / 'train_labels/0001.png').convert('L')
    assert reference.getpixel((300, 30)) == 255  # visible cloud
    assert reference.getpixel((150, 500)) == 0   # clear blue sky
    rows = list(csv.DictReader((directory / 'metadata.csv').open()))
    dates = sorted({r['Date'] for r in rows})
    random.Random(SEED).shuffle(dates)
    groups = {d: ('test' if i < 3 else 'val' if i < 6 else 'train') for i, d in enumerate(dates)}
    paths = {p.stem: p for split in ('train', 'val', 'test') for p in (directory / split).glob('*.png')}
    data = {'train': [], 'val': [], 'test': []}
    hashes = {}
    manifest = []
    for row in rows:
        p = paths[row['Number']]
        mask = p.parent.parent / (p.parent.name + '_labels') / p.name
        raw = np.array(Image.open(p).convert('RGB').resize((320, 320), Image.Resampling.BILINEAR))
        digest = hashlib.sha256(Image.open(p).convert('RGB').tobytes()).hexdigest()
        if digest in hashes:
            manifest.append(dict(id=p.stem, date=row['Date'], split='duplicate',
                                 duplicate_of=Path(hashes[digest]).stem, sha256=digest))
            continue
        hashes[digest] = str(p)
        # The mirror class_dict.csv is inverted. Actual label PNGs use WHITE=cloud.
        # Verified against 0001/0135 photo + mask overlays, not the incorrect CSV.
        target = np.array(Image.open(mask).convert('L').resize((SIDE, SIDE), Image.Resampling.NEAREST)) > 127
        split = groups[row['Date']]
        data[split].append((raw, target, p.stem))
        manifest.append(dict(id=p.stem, date=row['Date'], split=split, sha256=digest))
    return data, manifest


def tensors(samples, device):
    raw = torch.from_numpy(np.stack([s[0] for s in samples])).permute(0, 3, 1, 2).float() / 255
    x = F.avg_pool2d(raw, 2)
    y = torch.from_numpy(np.stack([s[1] for s in samples])[:, None]).float()
    return x.to(device), y.to(device)


def metrics(p, y, threshold=.5):
    pred, gt = p >= threshold, y >= .5
    tp = np.logical_and(pred, gt).sum()
    fp = np.logical_and(pred, ~gt).sum()
    fn = np.logical_and(~pred, gt).sum()
    inter = np.logical_and(pred, gt).sum(axis=(-2, -1))
    union = np.logical_or(pred, gt).sum(axis=(-2, -1))
    return dict(iou=float(tp / max(1, tp+fp+fn)),
                mean_image_iou=float(np.mean((inter + 1e-7) / (union + 1e-7))),
                precision=float(tp / max(1, tp+fp)), recall=float(tp / max(1, tp+fn)))


def predict(model, x):
    model.eval()
    with torch.no_grad():
        return torch.cat([model(b).sigmoid().cpu() for b in x.split(16)]).numpy()[:, 0]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', type=Path, default=ROOT / '.local-data/clouds/swimseg-2')
    parser.add_argument('--epochs', type=int, default=30)
    args = parser.parse_args()
    torch.manual_seed(SEED); np.random.seed(SEED); random.seed(SEED)
    torch.set_num_threads(4)
    device = 'mps' if torch.backends.mps.is_available() else 'cpu'
    data, manifest = load_data(args.data)
    out = ROOT / '.local-data/clouds/training'
    out.mkdir(parents=True, exist_ok=True)
    (out / 'split.json').write_text(json.dumps(manifest, indent=2))
    print('Split by capture date:', {k: len(v) for k,v in data.items()}, 'device:', device, flush=True)
    x, y = tensors(data['train'], device)
    vx, vy = tensors(data['val'], device)
    vy_np = vy.cpu().numpy()[:, 0]
    model = CloudNet().to(device)
    opt = torch.optim.Adam(model.parameters(), lr=.001)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(opt, args.epochs, eta_min=.0001)
    best = -1
    history = []
    start = time.monotonic()
    for epoch in range(args.epochs):
        model.train(); losses = []
        order = torch.randperm(len(x), device=device)
        for ids in order.split(16):
            bx, by = x[ids], y[ids]
            if random.random() < .5: bx, by = bx.flip(-1), by.flip(-1)
            if random.random() < .5: bx, by = bx.flip(-2), by.flip(-2)
            # Mild exposure variation without relabelling blue sky as grey.
            gain = torch.rand((len(ids),1,1,1), device=device) * .3 + .85
            bx = (bx * gain).clamp(0,1)
            logits = model(bx)
            bce = F.binary_cross_entropy_with_logits(logits, by)
            prob = logits.sigmoid()
            dice = 1 - (2*(prob*by).sum((1,2,3))+1) / (prob.sum((1,2,3))+by.sum((1,2,3))+1)
            loss = bce + .3*dice.mean()
            opt.zero_grad(); loss.backward(); opt.step()
            losses.append(float(loss.detach()))
        scheduler.step()
        val = metrics(predict(model, vx), vy_np)
        record = dict(epoch=epoch+1, loss=float(np.mean(losses)), validation=val,
                      elapsed_seconds=round(time.monotonic()-start, 1))
        history.append(record)
        print(json.dumps(record), flush=True)
        if val['iou'] > best:
            best = val['iou']
            torch.save({k:v.cpu() for k,v in model.state_dict().items()}, out / 'best.pt')
        (out / 'history.json').write_text(json.dumps(history, indent=2))
    print('Training finished; select threshold on validation only, then run evaluate.py.', flush=True)


if __name__ == '__main__':
    main()
