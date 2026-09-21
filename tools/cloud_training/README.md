# Local cloud segmentation training

The app's original detector used red/blue ratio, brightness and saturation inside a
sky mask. This pipeline learns cloud appearance from annotated photographs while
keeping the sky mask to exclude buildings and trees. No user photographs are used.

## Data and licensing

- **COCO-Stuff**, H. Caesar, J. Uijlings, V. Ferrari, *COCO-Stuff: Thing and Stuff
  Classes in Context*, CVPR 2018. https://github.com/nightrome/cocostuff
- Annotations are **CC BY 4.0**; the `clouds` and `sky-other` classes provide the labels.
- Photographs come from COCO (https://cocodataset.org) and are Flickr images with
  per-image licenses. `build_dataset.py` keeps only the COCO license ids that allow
  commercial use *and* derivative works: 4 (CC BY 2.0), 5 (CC BY-SA 2.0),
  7 (no known copyright restrictions) and 8 (US Government work). NonCommercial (1, 2, 3)
  and NoDerivatives (3, 6) images are dropped, so the trained weights carry no
  noncommercial restriction.
- No photograph is bundled with the app. Only the trained weights ship.
- Attribution shipped in the app: `assets/licenses/COCO-STUFF-attribution.txt` and
  `assets/licenses/CC-BY-4.0.txt`.

## Reproduce

Python 3.12, torch 2.14.0, numpy 2.5.3, Pillow 12.3.0, onnx 1.23.0,
onnxruntime 1.30.0. Dependencies are development-only; the Flutter runtime is unchanged.

```sh
mkdir -p .local-data/coco
curl -fL 'http://images.cocodataset.org/annotations/annotations_trainval2017.zip' -o .local-data/coco/annotations_trainval2017.zip
curl -fL 'https://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset/stuffthingmaps_trainval2017.zip' -o .local-data/coco/stuffthingmaps_trainval2017.zip
curl -fL 'https://raw.githubusercontent.com/nightrome/cocostuff/master/labels.txt' -o .local-data/coco/labels.txt
unzip -q .local-data/coco/annotations_trainval2017.zip -d .local-data/coco/
unzip -q .local-data/coco/stuffthingmaps_trainval2017.zip -d .local-data/coco/stuffthingmaps
python tools/cloud_training/build_dataset.py
python tools/cloud_training/train.py --epochs 40
python tools/cloud_training/evaluate.py
```

`build_dataset.py` scans the label maps for images with enough annotated cloud, then
takes the largest square window that is at least 90% sky (clouds included) and at least
8% cloud, so the crops match what the camera sees when it is pointed at the sky. Each
photo contributes one crop and is assigned to train/validation/test by a hash of its
COCO image id, so no crop of one photograph appears in two splits. Only then is the
photograph downloaded, and only the crop and its mask are written to disk.

`train.py` trains the same small encoder/decoder the app ships (12/24/48 channels),
picks the checkpoint by validation pixel IoU and the cell threshold by validation grid
IoU, reports the held-out test split, and exports `assets/models/cloud_coco_v1.onnx`.
`evaluate.py` re-runs the full app pipeline (sky model, cloud model, cell selection)
against the colour rule, checks PyTorch/ONNX parity, and regenerates
`integration_test/fixtures/cloud_cases.dart`.

Artifacts under `.local-data/coco/training` include the checkpoint, every epoch, the
validation threshold search, per-image CSV and comparison sheets. Raw data, downloaded
photographs and these artifacts are ignored by Git and are not bundled with the app.

## Evaluation scope

IoU is intersection / union of predicted and annotated cloud area, not a percentage of
photographs correctly recognised. The report gives pixel, 16×16 grid and final
largest-component scores for both the colour rule and the trained model. The final
component uses the app's brightness, sky coverage, connectivity and overcast gates. It
does not count the minimum 30-cell playability constraint as segmentation accuracy.

COCO photographs are everyday outdoor scenes from many cameras, which is closer to phone
use than a single fixed sky camera, but the annotations are coarser than a dedicated
sky/cloud dataset: thin cirrus and haze are often left unlabelled. Accuracy on any
particular phone, at dusk, or against unusual scenes is not established by this
benchmark. Manual correction stays available in the app.
