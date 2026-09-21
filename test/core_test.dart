import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_minesweeper/collection.dart';
import 'package:cloud_minesweeper/game.dart';
import 'package:cloud_minesweeper/sky_geometry.dart';

MineGame solved({int seed = 7, Difficulty difficulty = Difficulty.normal}) {
  final game = MineGame(
    shape: sampleClouds.first.shape,
    seed: seed,
    name: 'test',
    difficulty: difficulty,
  );
  game.open(game.shape.cells.first);
  for (final cell in game.shape.cells) {
    if (!game.mines.contains(cell)) game.open(cell);
  }
  expect(game.status, GameStatus.won);
  return game;
}

void main() {
  test('every first cell is safe, counts respect the irregular board', () {
    for (final sample in sampleClouds) {
      for (final first in sample.shape.cells) {
        final game = MineGame(
          shape: sample.shape,
          seed: first,
          name: sample.name,
        );
        game.open(first);
        expect(game.mines.length, game.mineCount);
        expect(
          game.mines.intersection({first, ...sample.shape.neighbors(first)}),
          isEmpty,
        );
        expect(game.opened.intersection(game.mines), isEmpty);
        expect(game.mines.every(sample.shape.cells.contains), isTrue);
        for (final cell in sample.shape.cells) {
          final x = cell % sample.shape.columns,
              y = cell ~/ sample.shape.columns;
          final expected = game.mines
              .where(
                (mine) =>
                    (mine % sample.shape.columns - x).abs() <= 1 &&
                    (mine ~/ sample.shape.columns - y).abs() <= 1 &&
                    mine != cell,
              )
              .length;
          expect(game.adjacent(cell), expected);
        }
      }
    }
  });

  test('flags block opening; mines lose; won and lost boards stay frozen', () {
    final game = MineGame(shape: sampleClouds[1].shape, seed: 42, name: 'test');
    final first = game.shape.cells.first;
    game.flag(first);
    game.open(first);
    expect(game.status, GameStatus.ready);
    game.flag(first);
    game.open(first);
    game.open(game.mines.first);
    expect(game.status, GameStatus.lost);
    final before = game.opened.toSet();
    game.open(game.shape.cells.last);
    expect(game.opened, before);
    expect(() => CloudPiece.fromWin(game, 1), throwsStateError);
    final won = solved();
    won.open(won.mines.first);
    expect(won.status, GameStatus.won);
  });

  test('disconnected selection uses the largest 8-connected cloud', () {
    final shape = CloudShape.pattern(['##....', '.##...', '......', '.....#']);
    expect(shape.largestComponent, {0, 1, 7, 8});
  });

  test(
    'collection restores shape and spherical placement and deduplicates wins',
    () async {
      final directory = await Directory.systemTemp.createTemp('cloud-test-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/sky.json');
      final collection = CloudCollection(file);
      final game = solved(difficulty: Difficulty.expert);
      final piece = await collection.collect(game, 91);
      expect(piece.placed, isFalse);
      await collection.collect(game, 99);
      expect(collection.pieces.length, 1);
      piece
        ..azimuth = pi - .001
        ..elevation = .43
        ..distance = 3.2
        ..placed = true;
      final firstSave = collection.save();
      piece
        ..azimuth = -pi + .002
        ..name = '고래 구름';
      final lastSave = collection.save();
      await Future.wait([firstSave, lastSave]);
      final restored = CloudCollection(file);
      await restored.load();
      expect(restored.pieces.single.name, '고래 구름');
      expect(restored.pieces.single.azimuth, -pi + .002);
      expect(restored.pieces.single.elevation, .43);
      expect(restored.pieces.single.distance, 3.2);
      expect(restored.pieces.single.difficulty, Difficulty.expert);
      final legacy = piece.toJson()
        ..remove('distance')
        ..remove('difficulty');
      expect(CloudPiece.fromJson(legacy).distance, 1);
      expect(CloudPiece.fromJson(legacy).difficulty, Difficulty.normal);
      for (final invalid in [0, -.1, 6.1, double.nan, double.infinity]) {
        expect(
          () => CloudPiece.fromJson({...legacy, 'distance': invalid}),
          throwsFormatException,
        );
      }
      expect(restored.pieces.single.seconds, 91);
      expect(restored.pieces.single.shape.cells, game.shape.cells);
      expect(await File('${file.path}.bak').exists(), isTrue);
      final original = await file.readAsString();
      await file.writeAsString('{broken');
      await expectLater(CloudCollection(file).load(), throwsFormatException);
      expect(await file.readAsString(), '{broken');
      expect(original, contains('고래 구름'));
    },
  );

  test(
    'save failure is reported and can be retried without losing a won piece',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'cloud-save-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final blocker = File('${directory.path}/blocked');
      await blocker.writeAsString('file where directory should be');
      final collection = CloudCollection(File('${blocker.path}/sky.json'));
      final game = solved();
      await expectLater(
        collection.collect(game, 4),
        throwsA(isA<FileSystemException>()),
      );
      expect(collection.saveError, isNotNull);
      expect(collection.pieces, hasLength(1));
      await blocker.delete();
      await collection.collect(game, 4);
      expect(collection.saveError, isNull);
      expect(collection.pieces, hasLength(1));
    },
  );

  test(
    'projection handles all headings, poles, zoom and behind-camera culling',
    () {
      for (final azimuth in [-pi, -.01, 0.0, pi / 2, pi - .001]) {
        for (final elevation in [-pi / 2 + .001, 0.0, .6, pi / 2 - .001]) {
          final view = SkyView.looking(azimuth, elevation);
          final center = view.project(
            Vec3.fromDirection(azimuth, elevation),
            390,
            480,
          )!;
          expect(center.x, closeTo(195, 1e-8));
          expect(center.y, closeTo(240, 1e-8));
          expect(view.project(view.forward * -1, 390, 480), isNull);
          for (final zoom in [.55, 1.0, 2.2]) {
            final ray = view.unproject(
              const Point(80, 340),
              390,
              480,
              zoom: zoom,
            );
            final back = view.project(ray, 390, 480, zoom: zoom)!;
            expect(back.x, closeTo(80, 1e-8));
            expect(back.y, closeTo(340, 1e-8));
          }
        }
      }
      // Portrait phone: screen right=east, screen up=up, back camera=north.
      final portrait = SkyView.rotation([1, 0, 0, 0, 0, -1, 0, 1, 0]);
      expect(portrait.forward.direction.azimuth, closeTo(0, 1e-8));
      expect(portrait.forward.direction.elevation, closeTo(0, 1e-8));
      expect(
        portrait.project(const Vec3(.1, 1, 0), 390, 480)!.x,
        greaterThan(195),
      );
      expect(
        portrait.project(const Vec3(0, 1, .1), 390, 480)!.y,
        lessThan(240),
      );
    },
  );
}
