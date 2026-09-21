import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_minesweeper/cloud_analysis.dart';
import 'package:cloud_minesweeper/game.dart';

void main() {
  test('photo board trims empty margins without changing cloud adjacency', () {
    final shape = CloudShape(16, 16, [34, 35, 50, 51, 52]);
    final cropped = shape.trimmed;
    expect(cropped.columns, 3);
    expect(cropped.rows, 2);
    expect(cropped.cells, {0, 1, 3, 4, 5});
    expect(
      cropped.cells.map((i) => cropped.neighbors(i).length).toList()..sort(),
      shape.cells.map((i) => shape.neighbors(i).length).toList()..sort(),
    );
  });
  test(
    'learned gray clouds survive color variation; bright ground is excluded',
    () {
      const side = 64;
      final rgb = Uint8List(side * side * 3);
      final sky = List<double>.filled(side * side, 1);
      final cloud = List<double>.filled(side * side, 0);
      for (var y = 0; y < side; y++) {
        for (var x = 0; x < side; x++) {
          final i = y * side + x;
          final white = (x >= 16 && x < 48 && y >= 8 && y < 32) || y >= 48;
          rgb.setAll(i * 3, white ? [90, 108, 140] : [55, 130, 230]);
          cloud[i] = white ? .95 : .05;
          if (y >= 48) sky[i] = 0; // White building: must not become cloud.
        }
      }
      final result = cloudCellsFromMask(rgb, sky, cloud, side);
      expect(result.playable, isTrue);
      expect(result.cells.length, 48);
      expect(result.cells.every((i) => i ~/ 16 >= 2 && i ~/ 16 < 8), isTrue);
    },
  );

  test(
    'no sky, clear blue sky and darkness do not produce playable clouds',
    () {
      const side = 32;
      for (final color in [
        [40, 120, 235],
        [0, 0, 0],
        [5, 7, 10],
      ]) {
        final rgb = Uint8List.fromList(
          List.generate(side * side, (_) => color).expand((v) => v).toList(),
        );
        expect(
          cloudCellsFromMask(
            rgb,
            List.filled(side * side, 1),
            List.filled(side * side, 0),
            side,
          ).playable,
          isFalse,
        );
      }
      final white = Uint8List(side * side * 3)
        ..fillRange(0, side * side * 3, 255);
      expect(
        cloudCellsFromMask(
          white,
          List.filled(side * side, 0),
          List.filled(side * side, 1),
          side,
        ).cells,
        isEmpty,
      );
      expect(
        cloudCellsFromMask(
          white,
          List.filled(side * side, 1),
          List.filled(side * side, 1),
          side,
        ).playable,
        isFalse,
      );
    },
  );

  test('disconnected fragments cannot meet minimum board size together', () {
    const side = 32;
    final rgb = Uint8List(side * side * 3);
    final cloud = List<double>.filled(side * side, 0);
    for (var y = 0; y < side; y++) {
      for (var x = 0; x < side; x++) {
        final white = y < 8 && (x < 8 || x >= 24);
        cloud[y * side + x] = white ? 1 : 0;
        rgb.setAll(
          (y * side + x) * 3,
          white ? [245, 245, 245] : [50, 120, 230],
        );
      }
    }
    final result = cloudCellsFromMask(
      rgb,
      List.filled(side * side, 1),
      cloud,
      side,
    );
    expect(result.cells.length, 16);
    expect(result.playable, isFalse);
  });

  test('photo and model use the same square crop, including rotated EXIF', () {
    final source = img.Image(width: 80, height: 40);
    img.fill(source, color: img.ColorRgb8(20, 230, 20));
    img.fillRect(
      source,
      x1: 20,
      y1: 0,
      x2: 39,
      y2: 39,
      color: img.ColorRgb8(30, 80, 235),
    );
    img.fillRect(
      source,
      x1: 40,
      y1: 0,
      x2: 59,
      y2: 39,
      color: img.ColorRgb8(235, 70, 40),
    );
    source.exif.imageIfd.orientation = 6;
    final prepared = prepareCloudPhoto(img.encodeJpg(source));
    final preview = img.decodePng(prepared.preview)!;
    expect(preview.width, preview.height);
    expect(prepared.input.length, 3 * 320 * 320);
    expect(prepared.cloudInput.length, prepared.input.length);
    expect(
      prepared.cloudInput[40 * 320 + 160 + 2 * 320 * 320],
      prepared.rgb[(40 * 320 + 160) * 3 + 2].toDouble(),
    );
    expect(preview.getPixel(20, 5).b, greaterThan(200));
    expect(preview.getPixel(20, 35).r, greaterThan(200));
    final top = (40 * 320 + 160) * 3, bottom = (280 * 320 + 160) * 3;
    expect(prepared.rgb[top + 2], greaterThan(200));
    expect(prepared.rgb[bottom], greaterThan(200));
    expect(() => prepareCloudPhoto(Uint8List(8)), throwsFormatException);
  });
}
