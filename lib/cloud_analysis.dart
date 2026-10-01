import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

import 'game.dart';

const cloudGridSide = 16;
const minimumCloudCells = 30;
const _modelSide = 320;

typedef PreparedCloudPhoto = ({
  Uint8List preview,
  Uint8List rgb,
  Float32List input,
  Float32List cloudInput,
});

// Decode EXIF orientation before taking exactly the center square shown in camera.
PreparedCloudPhoto prepareCloudPhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Cannot decode photograph');
  final upright = img.bakeOrientation(decoded);
  final side = min(upright.width, upright.height);
  final crop = img.copyCrop(
    upright,
    x: (upright.width - side) ~/ 2,
    y: (upright.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final preview = img.copyResize(crop, width: min(640, side));
  final small = img.copyResize(
    crop,
    width: _modelSide,
    height: _modelSide,
    interpolation: img.Interpolation.linear,
  );
  final rgb = small.getBytes(order: img.ChannelOrder.rgb);
  final input = Float32List(_modelSide * _modelSide * 3);
  final cloudInput = Float32List(input.length);
  // Match the published sky checkpoint's RGB normalization, including max scale.
  final scale = max(1, rgb.reduce(max));
  const mean = [.406, .456, .485], std = [.225, .224, .229];
  final area = _modelSide * _modelSide;
  for (var i = 0; i < area; i++) {
    for (var c = 0; c < 3; c++) {
      cloudInput[c * area + i] = rgb[i * 3 + c].toDouble();
      input[c * area + i] = (rgb[i * 3 + c] / scale - mean[c]) / std[c];
    }
  }
  return (
    preview: img.encodePng(preview),
    rgb: rgb,
    input: input,
    cloudInput: cloudInput,
  );
}

enum CloudFinding { tooDark, noSky, noEdge, none, small, found }

class CloudAnalysis {
  const CloudAnalysis(this.cells, this.finding);
  final Set<int> cells;
  final CloudFinding finding;
  bool get playable => cells.length >= minimumCloudCells;
}

Future<CloudAnalysis> analyseCloud(PreparedCloudPhoto photo) async {
  // Both models are bundled. Photographs never leave the device.
  final sky = await _infer('sky_u2netp_v1.onnx', 'image', 'sky', photo.input);
  final cloud = await _infer(
    'cloud_coco_v1.onnx',
    'rgb',
    'cloud',
    photo.cloudInput,
  );
  return compute(_extractCloud, (rgb: photo.rgb, sky: sky, cloud: cloud));
}

Future<List<double>> _infer(
  String asset,
  String inputName,
  String outputName,
  Float32List data,
) async {
  final session = await OnnxRuntime().createSessionFromAsset(
    'assets/models/$asset',
    options: OrtSessionOptions(intraOpNumThreads: 2, interOpNumThreads: 1),
  );
  OrtValue? input;
  Map<String, OrtValue>? outputs;
  try {
    input = await OrtValue.fromList(data, [1, 3, _modelSide, _modelSide]);
    outputs = await session.run({inputName: input});
    return (await outputs[outputName]!.asFlattenedList()).cast<double>();
  } finally {
    if (outputs != null) {
      for (final value in outputs.values) {
        await value.dispose();
      }
    }
    await input?.dispose();
    await session.close();
  }
}

CloudAnalysis _extractCloud(
  ({Uint8List rgb, List<double> sky, List<double> cloud}) data,
) => cloudCellsFromMask(data.rgb, data.sky, data.cloud, _modelSide);

// Cloud-specific learned scores, gated by sky to reject buildings and trees.
// The threshold is selected using date-separated validation photos; see training report.
CloudAnalysis cloudCellsFromMask(
  Uint8List rgb,
  List<double> sky,
  List<double> cloud,
  int side,
) {
  if (side < cloudGridSide ||
      rgb.length != side * side * 3 ||
      sky.length != side * side ||
      cloud.length != side * side ||
      sky.any((v) => !v.isFinite) ||
      cloud.any((v) => !v.isFinite)) {
    throw const FormatException('Invalid segmentation mask');
  }
  final scores = List<double>.filled(cloudGridSide * cloudGridSide, 0);
  final counts = List<int>.filled(scores.length, 0);
  var skyPixels = 0, brightness = 0.0;
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      final i = y * side + x;
      final r = rgb[3 * i] / 255,
          g = rgb[3 * i + 1] / 255,
          b = rgb[3 * i + 2] / 255;
      final light = max(r, max(g, b));
      brightness += light;
      if (sky[i] >= .6) skyPixels++;
      final skyScore = _smooth(.4, .8, sky[i]);
      final cell =
          (y * cloudGridSide ~/ side) * cloudGridSide +
          x * cloudGridSide ~/ side;
      scores[cell] += cloud[i].clamp(0.0, 1.0) * skyScore;
      counts[cell]++;
    }
  }
  if (brightness / sky.length < .18) {
    return const CloudAnalysis({}, CloudFinding.tooDark);
  }
  if (skyPixels / sky.length < .12) {
    return const CloudAnalysis({}, CloudFinding.noSky);
  }
  final candidates = <int>{
    for (var i = 0; i < scores.length; i++)
      if (scores[i] / counts[i] >= .425) i,
  };
  final cells = candidates.length < 2
      ? candidates
      : CloudShape(cloudGridSide, cloudGridSide, candidates).largestComponent;
  if (cells.length > scores.length * .92) {
    return const CloudAnalysis({}, CloudFinding.noEdge);
  }
  if (cells.length < minimumCloudCells) {
    return CloudAnalysis(
      cells,
      cells.isEmpty ? CloudFinding.none : CloudFinding.small,
    );
  }
  return CloudAnalysis(cells, CloudFinding.found);
}

double _smooth(double low, double high, double value) {
  final t = ((value - low) / (high - low)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}
