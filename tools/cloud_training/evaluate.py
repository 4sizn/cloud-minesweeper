"""Evaluate the bundled cloud model against the previous colour rule.

Runs on the held-out test split of the COCO-Stuff derived dataset (see
build_dataset.py), through the same two-model pipeline and cell selection the
app uses. Also checks ONNX/PyTorch parity and regenerates the integration-test
fixtures.
"""
import base64
import csv
import hashlib
import io
import json
import time
from pathlib import Path

import numpy as np
import onnxruntime as ort
from PIL import Image, ImageDraw
import torch

from train import ROOT, CloudNet, MobileCloudNet, load_split, metrics

DATA = ROOT / '.local-data/coco/dataset'
OUT = ROOT / '.local-data/coco/training'
CLOUD_MODEL = ROOT / 'assets/models/cloud_coco_v1.onnx'


def smooth(lo, hi, x):
    t = np.clip((x - lo) / (hi - lo), 0, 1)
    return t * t * (3 - 2 * t)


def baseline(rgb, sky):
    """The colour rule the app used before a model was trained."""
    r, g, b = (rgb.astype(np.float32) / 255).transpose(2, 0, 1)
    light = np.maximum(r, np.maximum(g, b))
    sat = (light - np.minimum(r, np.minimum(g, b))) / np.maximum(.04, light)
    return (smooth(.7, .94, r / np.maximum(.04, b)) * smooth(.18, .55, light)
            * (1 - smooth(.45, .85, sat)) * smooth(.4, .8, sky))


def sky_mask(session, rgb):
    x = rgb.astype(np.float32) / max(1, int(rgb.max()))
    x = ((x - np.array([.406, .456, .485])) / np.array([.225, .224, .229])).transpose(2, 0, 1)[None].astype(np.float32)
    return session.run(None, {'image': x})[0][0, 0]


def grid(x):
    return x.reshape(len(x), 16, 20, 16, 20).mean((2, 4))


def component(mask):
    remaining = set(np.flatnonzero(mask)); best = set()
    while remaining:
        todo = [remaining.pop()]; found = set(todo)
        while todo:
            i = todo.pop(); y, x = divmod(i, 16)
            for yy in range(max(0, y - 1), min(16, y + 2)):
                for xx in range(max(0, x - 1), min(16, x + 2)):
                    j = yy * 16 + xx
                    if j in remaining:
                        remaining.remove(j); found.add(j); todo.append(j)
        if len(found) > len(best):
            best = found
    out = np.zeros(256, dtype=bool)
    if len(best) <= 256 * .92:
        out[list(best)] = True
    return out.reshape(16, 16)


def selected_cells(rgb, sky, cloud, threshold):
    """The app's gates: brightness, sky coverage, threshold, largest component."""
    if rgb.max(2).mean() / 255 < .18 or (sky >= .6).mean() < .12:
        return np.zeros((16, 16), bool)
    return component(grid((cloud * smooth(.4, .8, sky))[None])[0] >= threshold)


def fixtures(images, ids, skies, clouds, threshold, count=3):
    """Dart fixtures: photograph plus the cells this pipeline selects for it."""
    lines = ['// COCO-Stuff derived test images, CC BY 4.0 annotations.',
             '// Photographs: COCO images under licenses permitting commercial use.',
             '// See assets/licenses/COCO-STUFF-attribution.txt.',
             '// Expected cells come from Python ONNX inference + the production policy.',
             'const cloudCases = [']
    step = max(1, len(ids) // count)
    for index in list(range(0, len(ids), step))[:count]:
        buffer = io.BytesIO()
        Image.fromarray(images[index]).save(buffer, format='PNG', optimize=True)
        cells = sorted(int(c) for c in np.flatnonzero(
            selected_cells(images[index], skies[index], clouds[index], threshold).reshape(-1)))
        lines.append('  (')
        lines.append(f"    id: '{ids[index]}',")
        lines.append(f"    png: '{base64.b64encode(buffer.getvalue()).decode()}',")
        lines.append('    cells: <int>{' + ', '.join(str(c) for c in cells) + '},')
        lines.append('  ),')
    lines.append('];')
    return '\n'.join(lines) + '\n'


def main():
    torch.set_num_threads(4)
    model = CloudNet().eval()
    model.load_state_dict(torch.load(OUT / 'best.pt', weights_only=True))
    wrapper = MobileCloudNet(model).eval()
    torch.onnx.export(wrapper, torch.zeros(1, 3, 320, 320), str(CLOUD_MODEL),
                      input_names=['rgb'], output_names=['cloud'], opset_version=17, dynamo=False)
    options = ort.SessionOptions(); options.intra_op_num_threads = 2; options.inter_op_num_threads = 1
    sky_session = ort.InferenceSession(str(ROOT / 'assets/models/sky_u2netp_v1.onnx'), options)
    cloud_session = ort.InferenceSession(str(CLOUD_MODEL), options)
    threshold = json.loads((OUT / 'threshold.json').read_text())['chosen']['threshold']

    summary = {'threshold': threshold, 'threshold_selection': 'validation grid IoU only',
               'cloud_model_sha256': hashlib.sha256(CLOUD_MODEL.read_bytes()).hexdigest()}
    rows = []
    start = time.monotonic()
    store = {}
    for split in ('val', 'test'):
        images, masks, ids = load_split(DATA, split)
        truth = np.array([np.array(Image.fromarray(m).resize((320, 320), Image.Resampling.NEAREST)) > 0
                          for m in [(m * 255).astype(np.uint8) for m in masks]])
        skies, clouds, old = [], [], []
        for index, rgb in enumerate(images):
            sm = sky_mask(sky_session, rgb)
            cm = cloud_session.run(None, {'rgb': rgb.astype(np.float32).transpose(2, 0, 1)[None]})[0][0, 0]
            skies.append(sm); clouds.append(cm * smooth(.4, .8, sm)); old.append(baseline(rgb, sm))
            if index % 50 == 0:
                print(split, index, 'elapsed', round(time.monotonic() - start), flush=True)
        skies, clouds, old = np.array(skies), np.array(clouds), np.array(old)
        truth_grid = grid(truth.astype(float)) >= .5
        summary[split] = {
            'images': len(ids),
            'colour_rule_pixel': metrics(old, truth, .46), 'model_pixel': metrics(clouds, truth, threshold),
            'colour_rule_grid': metrics(grid(old), truth_grid, .46), 'model_grid': metrics(grid(clouds), truth_grid, threshold),
        }
        old_components, new_components, truth_components = [], [], []
        for index, rgb in enumerate(images):
            old_components.append(selected_cells(rgb, skies[index], old[index] / np.maximum(1e-6, smooth(.4, .8, skies[index])), .46))
            new_components.append(selected_cells(rgb, skies[index], clouds[index] / np.maximum(1e-6, smooth(.4, .8, skies[index])), threshold))
            truth_components.append(component(truth_grid[index]))
            rows.append(dict(id=ids[index], split=split,
                             colour_rule_iou=metrics(grid(old[index:index + 1]), truth_grid[index:index + 1], .46)['iou'],
                             model_iou=metrics(grid(clouds[index:index + 1]), truth_grid[index:index + 1], threshold)['iou']))
        summary[split]['colour_rule_selected_component'] = metrics(np.array(old_components), np.array(truth_components))
        summary[split]['model_selected_component'] = metrics(np.array(new_components), np.array(truth_components))
        store[split] = (images, ids, skies, clouds, old, truth)

        indices = sorted({0, len(ids) // 3, 2 * len(ids) // 3, len(ids) - 1})
        sheet = Image.new('RGB', (4 * 240, len(indices) * 260 + 32), 'white')
        draw = ImageDraw.Draw(sheet)
        for column, title in enumerate(['Photograph', 'Ground truth', 'Colour rule', 'Trained model']):
            draw.text((column * 240 + 8, 8), title, fill='black')
        for row, index in enumerate(indices):
            variants = [Image.fromarray(images[index]), Image.fromarray((truth[index] * 255).astype('uint8')),
                        Image.fromarray(((old[index] >= .46) * 255).astype('uint8')),
                        Image.fromarray(((clouds[index] >= threshold) * 255).astype('uint8'))]
            for column, variant in enumerate(variants):
                sheet.paste(variant.resize((240, 240)), (column * 240, row * 260 + 32))
            draw.text((8, row * 260 + 272), ids[index], fill='black')
        sheet.save(OUT / f'{split}-comparison.jpg')

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'metrics.json').write_text(json.dumps(summary, indent=2))
    with (OUT / 'per-image.csv').open('w') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0])); writer.writeheader(); writer.writerows(rows)

    images, ids, skies, clouds, _, _ = store['val']
    (ROOT / 'integration_test/fixtures/cloud_cases.dart').write_text(
        fixtures(images, ids, skies, [c / np.maximum(1e-6, smooth(.4, .8, s)) for c, s in zip(clouds, skies)], threshold))

    example = store['val'][0][0].astype(np.float32).transpose(2, 0, 1)[None]
    with torch.no_grad():
        expected = wrapper(torch.from_numpy(example)).numpy()
    np.testing.assert_allclose(cloud_session.run(None, {'rgb': example})[0], expected, rtol=1e-4, atol=1e-5)

    print(json.dumps(summary, indent=2), flush=True)
    assert summary['test']['model_grid']['iou'] > summary['test']['colour_rule_grid']['iou'], 'Do not ship a regression'


if __name__ == '__main__':
    main()
