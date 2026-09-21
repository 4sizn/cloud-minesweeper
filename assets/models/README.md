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

## Cloud model (0.1.2)

`cloud_swimseg_v1.onnx` is a locally trained, small encoder/decoder with skip
connections (12/24/48 channels; 273,065 bytes). It accepts raw RGB float32
`rgb [1,3,320,320]` in [0,255], average-pools to 160px and divides by 255 inside
the model; output `cloud [1,1,320,320]` is a sigmoid cloud score, bilinearly resized.
Scores are not a guarantee of correctness or calibrated confidence.

Trained on 548 unique SWIMSEG photos, validated on 92, evaluated on 347, split by
capture date. Model and 0.525 cell threshold are selected using validation only.
White annotation pixels mean cloud; the mirror's class dictionary is inverted.

- Training provenance and reproduction: `tools/cloud_training/README.md`.
- Results, split, hashes: `docs/cloud-evaluation.md` and `docs/cloud-evaluation/`.
- Cloud model SHA-256: `ce7981bef1de2e5b73a6435d27a7003b3a7f0f2f2360c6901a15bee6d7cb5ede`.
- **Noncommercial development model**, trained using SWIMSEG (CC BY-NC 4.0).
  Attribution and license are included in `assets/licenses/SWIMSEG-*`.
  Commercial release requires replacement data/model or appropriate permission.

## Production selection and limitations

Multiply cloud scores by smoothstep(.4,.8,sky). Aggregate each 20×20 patch into
one of 16×16 cells; select scores >= .525 and the largest 8-connected component.
At least 30 cells are needed to play. Very dark images, insufficient sky and a
cloud covering >92% of the board retain explicit correction/reshoot messages.

Date-held-out SWIMSEG grid IoU improved from 51.2% to 79.8%. This is **not** an
accuracy claim for all phone photographs. Thin clouds, glare, dusk and unfamiliar
scenes can still fail. Manual correction remains available.

Both models are packaged in the app with no runtime download. Sequential ONNX
inference releases tensors and sessions after each model. Android uses the same
pipeline but has not been built here.

Test fixtures are excluded from the production entry point. `sky_photo.dart`
comes from the pinned Apache-2.0 sky model repository. `swimseg_cases.dart`
contains three resized validation images under CC BY-NC 4.0, with attribution.
