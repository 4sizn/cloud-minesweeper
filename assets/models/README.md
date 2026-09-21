# Bundled sky model

- Architecture: U²-Net-small (U2NETP), 320×320 input, fused sigmoid head only.
- Weights: [geohot/U-2-Net-tinygrad](https://github.com/geohot/U-2-Net-tinygrad),
  `weights/u2netp_sky.pth`, commit `cba5242158611e39a505f732b4a78a3018f93a5b`.
- Architecture source: [xuebinqin/U-2-Net](https://github.com/xuebinqin/U-2-Net),
  `model/u2net.py`, retained in `tools/model_export/u2net.py`.
- Licenses: Apache-2.0, included in `assets/licenses/U2NET-sky.txt` and `U2NET.txt`.
- Conversion: `python tools/model_export/export.py /path/to/u2netp_sky.pth`.
  Tested with Python 3.12, PyTorch 2.14.0 and ONNX 1.23.0; export opset 17.
  Modified from checkpoint: fused head only; exported to ONNX for mobile inference.
- Size: 4611294 bytes.
- SHA-256: `0fcba93a6e305e1110dd995bafac551cc167844a0dd693fbe71a080951470c0b`.

## Contract

Input `image`: float32 `[1,3,320,320]`.
EXIF orientation is baked, then a centered square matching camera preview is cropped.
Resize RGB to 320×320 and divide by the maximum channel value (at least 1).
Following the checkpoint's supplied inference code, RGB means are `[.406,.456,.485]`
and standard deviations `[.225,.224,.229]`; this differs from standard ImageNet order.
Output `sky`: float32 `[1,1,320,320]`, higher means sky. The upstream demo
inverts this mask to exclude sky; this app deliberately does not invert it.
No image-relative min/max normalization is applied, so an all-sky image remains all sky.

## Cloud model (0.2.0)

`cloud_coco_v1.onnx` is a locally trained, small encoder/decoder with skip
connections (12/24/48 channels; 273,065 bytes). It accepts raw RGB float32
`rgb [1,3,320,320]` in [0,255], average-pools to 160px and divides by 255 inside
the model; output `cloud [1,1,320,320]` is a sigmoid cloud score, bilinearly resized.
Scores are not a guarantee of correctness or calibrated confidence.

Trained on 490 sky-dominated crops derived from COCO-Stuff: 310 training, 48
validation, 132 evaluation, split by COCO image id. Model (epoch 38 of 40) and the
0.425 cell threshold are selected using validation only.

- Training provenance and reproduction: `tools/cloud_training/README.md`.
- Results, split, hashes: `docs/cloud-evaluation.md` and `docs/cloud-evaluation/`.
- Cloud model SHA-256: `23a0978e01053b5ed13ec1efbdb0c667292a21a27c7493550a7f21b37b2923be`.
- **Commercially usable.** COCO-Stuff annotations are CC BY 4.0 and only COCO
  photographs whose license permits commercial use and derivative works were used
  (CC BY 2.0, CC BY-SA 2.0, no known copyright restrictions, US Government works).
  Attribution and license are included in `assets/licenses/COCO-STUFF-attribution.txt`
  and `assets/licenses/CC-BY-4.0.txt`. The previous SWIMSEG model (CC BY-NC 4.0) was
  removed together with its fixtures and licenses.

## Production selection and limitations

Multiply cloud scores by smoothstep(.4,.8,sky). Aggregate each 20×20 patch into
one of 16×16 cells; select scores >= .425 and the largest 8-connected component.
At least 30 cells are needed to play. Very dark images, insufficient sky and a
cloud covering >92% of the board retain explicit correction/reshoot messages.

On the held-out COCO split the 16×16 grid IoU is 74.2%, against 63.5% for the colour
rule the app used before a model existed. This is **not** an accuracy claim for all
phone photographs. Thin clouds, glare, dusk and unfamiliar scenes can still fail.
Manual correction remains available.

Both models are packaged in the app with no runtime download. Sequential ONNX
inference releases tensors and sessions after each model. Android uses the same
pipeline but has not been built here.

Test fixtures are excluded from the production entry point. `sky_photo.dart`
comes from the pinned Apache-2.0 sky model repository. `cloud_cases.dart` contains
three validation crops from the COCO-Stuff derived set, with attribution.
