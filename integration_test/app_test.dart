import 'dart:io';
import 'dart:convert';

import 'fixtures/sky_photo.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_minesweeper/main.dart';
import 'package:cloud_minesweeper/collection.dart';
import 'package:cloud_minesweeper/game.dart';
import 'package:cloud_minesweeper/play_screen.dart';
import 'package:cloud_minesweeper/app_info.dart';
import 'package:cloud_minesweeper/l10n/app_localizations.dart';

// Store screenshots per language: flutter drive ... --dart-define=SCREEN_LOCALE=en
const locale = Locale(String.fromEnvironment('SCREEN_LOCALE', defaultValue: 'ko'));
final l = lookupAppLocalizations(locale);

void main() {
  registerAssetLicenses();
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('win → collect → point and place → drag → undo → reload', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final temporary = await getTemporaryDirectory();
    Future<void> screenshot(String name) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pumpAndSettle();
      final bytes = await binding.takeScreenshot('${locale.languageCode}-$name');
      await File('${temporary.path}/qa-$name.png').writeAsBytes(bytes);
    }

    Future<void> solveVisibleBoard() async {
      final board = tester.widget<PlayScreen>(find.byType(PlayScreen)).game;
      await tester.tap(find.byKey(ValueKey('cell-${board.shape.cells.first}')));
      await tester.pumpAndSettle();
      await screenshot('game');
      for (final cell in board.shape.cells.toList()) {
        if (!board.opened.contains(cell) && !board.mines.contains(cell)) {
          await tester.ensureVisible(find.byKey(ValueKey('cell-$cell')));
          await tester.tap(find.byKey(ValueKey('cell-$cell')));
          await tester.pump(const Duration(milliseconds: 180));
        }
      }
      expect(board.status, GameStatus.won);
      await tester.pumpAndSettle();
    }

    Offset cloudPoint(CloudPiece piece) {
      final rect = tester.getRect(
        find.byKey(ValueKey('cloud-piece-${piece.id}')),
      );
      final cell = piece.shape.cells.elementAt(piece.shape.cells.length ~/ 2);
      return rect.topLeft +
          Offset(
            (cell % piece.shape.columns + .5) *
                rect.width /
                piece.shape.columns,
            (cell ~/ piece.shape.columns + .5) * rect.height / piece.shape.rows,
          );
    }

    final file = File('${temporary.path}/integration-sky.json');
    if (await file.exists()) await file.delete();
    final collection = CloudCollection(file);
    await tester.pumpWidget(
      CloudApp(
        collection: collection,
        enableSensors: false,
        capturePhoto: base64Decode(skyPhotoBase64),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l.emptySkyTitle), findsOneWidget);
    await screenshot('empty');
    expect(find.textContaining('샘플'), findsNothing);
    await tester.tap(find.text(l.findNewCloud));
    await tester.pumpAndSettle();
    await screenshot('captured-cloud');
    await tester.ensureVisible(find.text(l.startWithCloud));
    await tester.tap(find.text(l.startWithCloud));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l.howToPlay));
    await tester.pumpAndSettle();
    await screenshot('play-help');
    await tester.tap(find.byTooltip(l.closeHelp));
    await tester.pumpAndSettle();
    await solveVisibleBoard();
    expect(find.text(l.wonTitle), findsOneWidget);
    await screenshot('won');
    await tester.tap(find.text(l.placeInMySky));
    await tester.pumpAndSettle();
    expect(collection.pieces, hasLength(1));
    expect(collection.pieces.single.placed, isFalse);
    await screenshot('placing');
    final distanceSlider = find.byKey(const ValueKey('cloud-distance'));
    final pendingCloud = find.byKey(const ValueKey('pending-cloud'));
    final originalWidth = tester.getSize(pendingCloud).width;
    await tester.tapAt(
      tester.getRect(distanceSlider).centerRight - const Offset(40, 0),
    );
    await tester.pumpAndSettle();
    final cloudDistance = collection.pieces.single.distance;
    final pendingWidth = tester.getSize(pendingCloud).width;
    expect(cloudDistance, greaterThan(2));
    expect(pendingWidth, closeTo(originalWidth / cloudDistance, .01));
    await screenshot('depth-placement');
    await tester.tap(find.text(l.placeHere));
    await tester.pumpAndSettle();
    expect(collection.pieces.single.placed, isTrue);
    expect(collection.pieces.single.distance, cloudDistance);
    expect(
      tester
          .getSize(
            find.byKey(ValueKey('cloud-piece-${collection.pieces.single.id}')),
          )
          .width,
      closeTo(pendingWidth, .01),
    );
    final original = collection.pieces.single.azimuth;
    final center = cloudPoint(collection.pieces.single);
    await tester.dragFrom(center, const Offset(65, -20));
    await tester.pumpAndSettle();
    expect(collection.pieces.single.azimuth, isNot(closeTo(original, 1e-5)));
    await tester.tap(find.byTooltip(l.undoMove));
    await tester.pumpAndSettle();
    expect(collection.pieces.single.azimuth, closeTo(original, 1e-8));
    await tester.dragFrom(center, const Offset(-45, 15));
    await tester.pumpAndSettle();
    final firstPosition = collection.pieces.first.azimuth;
    await tester.tap(find.text(l.findNewCloud));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l.startWithCloud));
    await tester.tap(find.text(l.startWithCloud));
    await tester.pumpAndSettle();
    await screenshot('fresh-board');
    await solveVisibleBoard();
    await tester.tap(find.text(l.placeInMySky));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.placeHere));
    await tester.pumpAndSettle();
    expect(collection.pieces, hasLength(2));
    await tester.dragFrom(
      cloudPoint(collection.pieces.last),
      const Offset(115, -10),
    );
    await tester.pumpAndSettle();
    expect(collection.pieces.first.azimuth, firstPosition);
    await screenshot('two-clouds');
    await collection.save();
    final restored = CloudCollection(file);
    await restored.load();
    expect(restored.pieces.last.azimuth, collection.pieces.last.azimuth);
    expect(restored.pieces.first.distance, cloudDistance);
    expect(restored.pieces.last.distance, 1);
    expect(
      restored.pieces.map((p) => p.difficulty),
      collection.pieces.map((p) => p.difficulty),
    );
    await tester.pumpWidget(
      CloudApp(key: UniqueKey(), collection: restored, enableSensors: false),
    );
    await tester.pumpAndSettle();
    expect(find.text(l.defaultCloudName), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
    await tester.tap(find.byTooltip(l.showAllClouds));
    await tester.pumpAndSettle();
    expect(find.text(l.collectionTitle), findsOneWidget);
    await screenshot('collection');
    await tester.tap(find.text(l.defaultCloudName).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.findNewCloud));
    await tester.pumpAndSettle();
    expect(find.text(l.captureTitle), findsOneWidget);
    await screenshot('camera-fallback');
    expect(find.textContaining('샘플'), findsNothing);
    expect(find.text(l.reconnectCamera), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l.appInfo));
    await tester.pumpAndSettle();
    await screenshot('app-info');
    await tester.tap(find.text(l.copyEmail));
    await tester.pumpAndSettle();
    expect(find.text(l.emailCopied), findsOneWidget);
    await tester.tap(find.text(l.licenses));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('COCO-Stuff attribution'), 300);
    expect(find.text('COCO-Stuff attribution'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.privacyTitle));
    await tester.pumpAndSettle();
    await screenshot('privacy-info');
    expect(find.textContaining('4sizn@naver.com'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
