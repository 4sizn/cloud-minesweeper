# Local cloud segmentation training

The app's original detector used red/blue ratio, brightness and saturation inside a
sky mask. This pipeline learns cloud appearance from annotated photographs while
keeping the sky mask to exclude buildings and trees. No user photographs are used.

## Data and attribution

- **SWIMSEG**, S. Dev, Y. H. Lee, S. Winkler, *Color-based segmentation of sky/cloud
  images from ground-based cameras*, IEEE JSTARS 10(1), 231–242, 2017.
- Original: https://malea.winkler.site/swimseg.html
- Downloaded research mirror: https://doi.org/10.7910/DVN/HEJTK1
  (Qianqian Song, replication dataset; file ID 3758694).
- Original and the archive's `license.html`: **CC BY-NC 4.0**.
  The mirror's top-level CC0 metadata does not supersede the original restrictions.
  This is a noncommercial development model; commercial distribution requires
  replacing the training data/model or obtaining appropriate permission.
- Archive includes 1,013 RGB 600×600 photographs and paired masks. The downloaded
  `class_dict.csv` reverses the actual mask colors: **white pixels in label PNGs
  are clouds**, black is clear sky. Photo/mask overlays (e.g. 0001 and 0135) were
  checked before final training. Do not use the CSV's inverted labels.

## Reproduce

Python 3.12, torch 2.14.0, numpy 2.5.3, Pillow 12.3.0, onnx 1.23.0,
onnxruntime 1.30.0. Dependencies are development-only; Flutter runtime is unchanged.

```sh
mkdir -p .local-data/clouds
curl -fL 'https://dataverse.harvard.edu/api/access/datafile/3758694' -o .local-data/clouds/swimseg.rar
bsdtar -xf .local-data/clouds/swimseg.rar -C .local-data/clouds
python tools/cloud_training/train.py --epochs 30
python tools/cloud_training/evaluate.py
```

`load_data` hashes decoded pixels and drops 26 exact duplicates. A fixed seed,
20260921, splits **capture dates**, not random neighboring patches. The 987 unique
images become 548 training / 92 validation / 347 evaluation images with no shared
dates or exact images. The model checkpoint is chosen by validation pixel IoU;
the mask threshold is chosen by validation grid IoU. Evaluation photos do not
choose parameters. MPS training can vary slightly between runs.

Artifacts under `.local-data/clouds/training` include the full split/image manifest,
checkpoint, all epochs, validation threshold search, per-image CSV, and contact
sheets (evenly spaced examples plus the worst case). Raw data and these images are
ignored by Git and are not bundled with the app. The final model is exported into
`assets/models/cloud_swimseg_v1.onnx`; evaluation checks PyTorch/ONNX parity.

## Evaluation scope

IoU is intersection / union of predicted and annotated cloud area, not a percentage
of photographs correctly recognized. The report gives pixel, 16×16 grid, and final
largest-component scores for **both** v1 and v2. The final component uses the app's
brightness, sky coverage, connectivity and overcast gates. It does not count the
minimum 30-cell playability constraint as segmentation accuracy.

These are daytime, sky-only patches from one Singapore camera. Date separation
helps avoid leakage, but it does not establish accuracy on every iPhone camera,
night scenes, city buildings or unseen climates. Camera review/manual correction
remains available. Device capture validation is separate from this benchmark.
