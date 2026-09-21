"""Build a commercially licensed cloud segmentation dataset from COCO-Stuff.

COCO-Stuff annotations are CC BY 4.0. The photographs are Flickr images under
per-image licenses, so only images whose COCO license allows commercial use and
derivative works are kept: CC BY 2.0, CC BY-SA 2.0, no known copyright
restrictions, and United States Government works. NonCommercial and
NoDerivatives images are dropped.

Inputs (see README.md for the download commands):
  .local-data/coco/annotations/instances_{train,val}2017.json
  .local-data/coco/stuffthingmaps/{train,val}2017/*.png
  .local-data/coco/labels.txt

Output: .local-data/coco/dataset/{train,val,test}/{images,masks}/<id>.png
plus manifest.json recording every source image, its license and its split.
"""
import argparse
import hashlib
import json
import random
import urllib.request
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
COCO = ROOT / '.local-data/coco'
SEED = 20260921
SIDE = 320
# COCO license ids that permit commercial use and derivative works.
ALLOWED_LICENSES = {4: 'CC BY 2.0', 5: 'CC BY-SA 2.0',
                    7: 'No known copyright restrictions',
                    8: 'United States Government Work'}
MIN_CLOUD = 0.12   # cloud share of the crop
MAX_CLOUD = 0.85   # keep both classes visible; COCO often paints a whole sky as cloud
MIN_SKY = 0.70     # sky (incl. cloud) share of the crop; the sky model gates the rest at runtime
DEEP_BLUE = 0.62   # red/blue ratio below which a sky pixel is plainly clear sky
OVERCAST_SHARE = 0.15  # fraction of the kept crops allowed to be fully clouded skies


def label_ids():
    ids = {}
    for line in (COCO / 'labels.txt').read_text().splitlines():
        number, name = line.split(':', 1)
        ids[name.strip()] = int(number) - 1  # PNG values are label id - 1
    return ids['clouds'], ids['sky-other']


def best_square(sky, cloud, low=MIN_CLOUD, high=MAX_CLOUD):
    """Sky-dominated square window that splits the sky between cloud and clear.

    The share is measured against the sky pixels, not the whole window: COCO
    often paints an entire sky as cloud, and measuring against the window would
    accept those as soon as the sky covered the minimum area. Windows are scored
    by distance from a 50/50 sky split so the set keeps both classes visible.
    """
    h, w = sky.shape
    integral_sky = np.pad(sky.cumsum(0).cumsum(1), ((1, 0), (1, 0)))
    integral_cloud = np.pad(cloud.cumsum(0).cumsum(1), ((1, 0), (1, 0)))

    def window(box, t, l, s):
        return box[t + s, l + s] - box[t, l + s] - box[t + s, l] + box[t, l]

    best = None
    for size in range(min(h, w), 95, -16):
        step = max(8, size // 8)
        for top in range(0, h - size + 1, step):
            for left in range(0, w - size + 1, step):
                area = size * size
                sky_count = window(integral_sky, top, left, size)
                if sky_count < MIN_SKY * area:
                    continue
                share = window(integral_cloud, top, left, size) / max(1, sky_count)
                if not low <= share <= high:
                    continue
                score = abs(share - .5)
                if best is None or score < best[0]:
                    best = (score, top, left, size)
                if score < .1:
                    return best[1:]
    return best[1:] if best else None


def refine(photo, cloud):
    """Remove plainly blue pixels from the annotated cloud area.

    COCO annotators frequently paint a whole sky as "clouds", including deep
    blue gaps. Training on that teaches "any sky is a cloud". Only clearly blue
    pixels are removed; grey, white and hazy cloud stays exactly as annotated.
    """
    channels = np.asarray(photo, dtype=np.float32) / 255
    ratio = channels[..., 0] / np.maximum(channels[..., 2], .04)
    return cloud & (ratio >= DEEP_BLUE)


def consistent(rgb, cloud, sky):
    """Drop crops whose annotation contradicts the photograph.

    COCO annotators often paint an entire sky as "clouds", including deep blue
    areas. Those crops would teach the model that any sky is a cloud.
    """
    channels = np.asarray(rgb, dtype=np.float32) / 255
    ratio = channels[..., 0] / np.maximum(channels[..., 2], .04)
    if cloud.sum() < 100 or (ratio[cloud] >= .7).mean() < .8:
        return False
    clear = sky & ~cloud  # buildings and ground are not expected to look like sky
    return clear.sum() < 100 or (ratio[clear] < .85).mean() >= .6


def fetch(url, path):
    if path.exists():
        return True
    try:
        with urllib.request.urlopen(url, timeout=60) as response:
            data = response.read()
    except Exception:
        return False
    path.write_bytes(data)
    return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--limit', type=int, default=2000, help='max crops to build')
    args = parser.parse_args()

    cloud_id, sky_id = label_ids()
    cache = COCO / 'images'
    cache.mkdir(parents=True, exist_ok=True)
    out = COCO / 'dataset'
    manifest = []
    kept = 0
    overcast_kept = 0

    for split in ('train2017', 'val2017'):
        meta = json.loads((COCO / 'annotations' / f'instances_{split}.json').read_text())
        images = {image['id']: image for image in meta['images']
                  if image['license'] in ALLOWED_LICENSES}
        maps = COCO / 'stuffthingmaps' / split
        scanned = 0
        for image in sorted(images.values(), key=lambda i: i['id']):
            scanned += 1
            if scanned % 2000 == 0:
                print(f'{split}: scanned {scanned}/{len(images)}, kept {kept}', flush=True)
            if kept >= args.limit:
                break
            label_path = maps / (Path(image['file_name']).stem + '.png')
            if not label_path.exists():
                continue
            labels = np.array(Image.open(label_path))
            annotated = labels == cloud_id
            if annotated.mean() < MIN_CLOUD / 2:
                continue
            photo_path = cache / Path(image['file_name']).name
            if not fetch(image['coco_url'], photo_path):
                continue
            full = Image.open(photo_path).convert('RGB')
            if full.size != (labels.shape[1], labels.shape[0]):
                continue
            cloud = refine(full, annotated)
            sky = annotated | (labels == sky_id)
            box = best_square(sky.astype(np.int64), cloud.astype(np.int64))
            overcast = False
            if box is None and overcast_kept < 8 + kept * OVERCAST_SHARE:
                # A minority of fully clouded skies keeps overcast photos in domain.
                box = best_square(sky.astype(np.int64), cloud.astype(np.int64), .95, 1.0)
                overcast = box is not None
            if box is None:
                continue
            top, left, size = box
            photo = full.crop(
                (left, top, left + size, top + size)).resize((SIDE, SIDE), Image.Resampling.BILINEAR)
            mask = Image.fromarray((cloud[top:top + size, left:left + size] * 255).astype(np.uint8)).resize(
                (SIDE, SIDE), Image.Resampling.NEAREST)
            sky_crop = np.asarray(Image.fromarray((sky[top:top + size, left:left + size] * 255).astype(np.uint8)).resize(
                (SIDE, SIDE), Image.Resampling.NEAREST)) > 127
            if not consistent(photo, np.asarray(mask) > 127, sky_crop):
                continue
            overcast_kept += overcast
            # Split by image id so no crop of one photo leaks across splits.
            bucket = int(hashlib.sha256(f'{SEED}:{image["id"]}'.encode()).hexdigest(), 16) % 10
            part = 'test' if bucket < 3 else 'val' if bucket < 4 else 'train'
            for kind, data in (('images', photo), ('masks', mask)):
                directory = out / part / kind
                directory.mkdir(parents=True, exist_ok=True)
                data.save(directory / f'{image["id"]}.png')
            manifest.append(dict(id=image['id'], file=image['file_name'], split=part,
                                 license=ALLOWED_LICENSES[image['license']],
                                 flickr_url=image.get('flickr_url', ''),
                                 crop=[int(top), int(left), int(size)], overcast=overcast,
                                 cloud_share=round(float(cloud[top:top + size, left:left + size].mean()), 4),
                                 cloud_share_of_sky=round(float(
                                     cloud[top:top + size, left:left + size].sum()
                                     / max(1, sky[top:top + size, left:left + size].sum())), 4)))
            kept += 1

    out.mkdir(parents=True, exist_ok=True)
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=1))
    counts = {part: sum(1 for m in manifest if m['split'] == part) for part in ('train', 'val', 'test')}
    licenses = {}
    for m in manifest:
        licenses[m['license']] = licenses.get(m['license'], 0) + 1
    print(f'crops: {kept} {counts} overcast: {overcast_kept}')
    print('licenses:', licenses)


if __name__ == '__main__':
    random.seed(SEED)
    main()
