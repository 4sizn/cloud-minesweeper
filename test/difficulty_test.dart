import 'dart:io';
import 'dart:math';

import 'package:cloud_minesweeper/capture_screen.dart';
import 'package:cloud_minesweeper/collection.dart';
import 'package:cloud_minesweeper/game.dart';
import 'package:cloud_minesweeper/play_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test(
    'four levels have distinct mine counts and safe, solvable first cells',
    () {
      final shape = CloudShape(16, 16, List.generate(256, (i) => i));
      final counts = <int>[];
      for (final level in Difficulty.values) {
        for (final first in [0, 7, 119, 255]) {
          final game = MineGame(
            shape: shape,
            seed: 79,
            name: '구름',
            difficulty: level,
          );
          game.open(first);
          expect(game.mines.length, game.mineCount);
          expect(
            game.mines.intersection({first, ...shape.neighbors(first)}),
            isEmpty,
          );
          for (final cell in shape.cells) {
            if (!game.mines.contains(cell)) game.open(cell);
          }
          expect(game.status, GameStatus.won);
          expect(CloudPiece.fromWin(game, 3).difficulty, level);
        }
        counts.add(
          MineGame(
            shape: shape,
            seed: 1,
            name: '',
            difficulty: level,
          ).mineCount,
        );
      }
      expect(counts, [20, 30, 43, 56]);
      final random = Random(20260921);
      final draws = <Difficulty, int>{for (final d in Difficulty.values) d: 0};
      for (var i = 0; i < 4000; i++) {
        draws.update(Difficulty.roll(random), (n) => n + 1);
      }
      expect(draws.values.every((n) => n > 850 && n < 1150), isTrue);
    },
  );

  testWidgets(
    'failed analysis retry keeps photo difficulty; editing does not reroll',
    (tester) async {
      final photo = img.Image(width: 32, height: 32);
      img.fill(photo, color: img.ColorRgb8(45, 125, 235));
      // No native ONNX plugin in widget tests: the real error/retry path is exercised.
      await tester.pumpWidget(
        MaterialApp(home: CaptureScreen(initialPhoto: img.encodePng(photo))),
      );
      Future<void> finishAnalysis() async {
        for (var i = 0; i < 100 && find.text('다시 분석').evaluate().isEmpty; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
        }
        expect(find.text('다시 분석'), findsOneWidget);
      }

      await finishAnalysis();
      final level = (tester.widget<Chip>(find.byType(Chip)).label as Text).data;
      await tester.ensureVisible(find.text('다시 분석'));
      await tester.tap(find.text('다시 분석'));
      await tester.pump();
      await finishAnalysis();
      expect(find.text(level!), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );

  testWidgets(
    'retry retains difficulty, help and leave confirmation work on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = MineGame(
        shape: sampleClouds.first.shape,
        seed: 71,
        name: '사진 구름',
        difficulty: Difficulty.expert,
      );
      game.open(game.shape.cells.first);
      game.open(game.mines.first);
      expect(game.status, GameStatus.lost);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayScreen(
                      game: game,
                      collection: CloudCollection(
                        File('/unused-difficulty.json'),
                      ),
                    ),
                  ),
                ),
                child: const Text('시작'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('시작'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다시 도전'));
      await tester.pumpAndSettle();
      final retry =
          (tester.state(find.byType(PlayScreen)) as dynamic).game as MineGame;
      expect(retry.difficulty, Difficulty.expert);
      expect(retry.seed, game.seed);
      expect(retry.id, game.id);
      expect(retry.status, GameStatus.ready);
      await tester.tap(find.byTooltip('플레이 방법'));
      await tester.pumpAndSettle();
      expect(find.text('1. 구름을 촬영해요'), findsOneWidget);
      await tester.tap(find.byTooltip('도움말 닫기'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(ValueKey('cell-${retry.shape.cells.first}')),
      );
      await tester.tap(find.byKey(ValueKey('cell-${retry.shape.cells.first}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('내 하늘로 돌아가기'));
      await tester.pumpAndSettle();
      expect(find.text('이번 게임에서 나갈까요?'), findsOneWidget);
      await tester.tap(find.text('계속하기'));
      await tester.pumpAndSettle();
      expect(find.byType(PlayScreen), findsOneWidget);
      await tester.tap(find.byTooltip('내 하늘로 돌아가기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('나가기'));
      await tester.pumpAndSettle();
      expect(find.text('시작'), findsOneWidget);
    },
  );
}
