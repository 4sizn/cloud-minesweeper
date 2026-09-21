import 'dart:convert';
import 'dart:io';

import 'package:cloud_minesweeper/collection.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_minesweeper/capture_screen.dart';
import 'package:cloud_minesweeper/cloud_analysis.dart';
import 'package:cloud_minesweeper/game.dart';
import 'package:cloud_minesweeper/play_screen.dart';

import 'fixtures/sky_photo.dart';
import 'fixtures/swimseg_cases.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mobile cloud model matches three annotated validation cases', (
    tester,
  ) async {
    for (final sample in swimsegCases) {
      final result = await analyseCloud(
        prepareCloudPhoto(base64Decode(sample.png)),
      );
      expect(result.cells, sample.cells, reason: 'SWIMSEG ${sample.id}');
    }
  });

  testWidgets('real photograph automatically becomes a playable cloud board', (
    tester,
  ) async {
    CloudDraft? draft;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                draft = await Navigator.push<CloudDraft>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaptureScreen(
                      initialPhoto: base64Decode(skyPhotoBase64),
                    ),
                  ),
                );
                if (draft != null && context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayScreen(
                        collection: CloudCollection(
                          File('${Directory.systemTemp.path}/photo-test.json'),
                        ),
                        game: MineGame(
                          shape: draft!.shape,
                          name: draft!.name,
                          source: draft!.source,
                          difficulty: draft!.difficulty,
                          seed: 7,
                        ),
                      ),
                    ),
                  );
                }
              },
              child: const Text('사진 분석 시작'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('사진 분석 시작'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 90),
    );
    expect(find.text('구름을 자동으로 찾았어요. 모양을 확인하고 바로 시작하세요.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final assignedDifficulty = tester.widget<Chip>(find.byType(Chip)).label;
    final difficultyText = (assignedDifficulty as Text).data;
    await binding.takeScreenshot('photo-auto-selection');
    await tester.ensureVisible(find.text('모양 수정'));
    await tester.tap(find.text('모양 수정'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('자동 선택 복원'));
    await tester.tap(find.text('자동 선택 복원'));
    await tester.pumpAndSettle();
    expect(find.text(difficultyText!), findsOneWidget);
    await tester.ensureVisible(find.text('수정 마치기'));
    await tester.tap(find.text('수정 마치기'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('이 구름으로 시작'));
    await tester.tap(find.text('이 구름으로 시작'));
    await tester.pumpAndSettle();
    expect(draft!.source, 'camera-auto');
    expect(difficultyText, '난이도 ${draft!.difficulty.description}');
    expect(
      tester.widget<PlayScreen>(find.byType(PlayScreen)).game.difficulty,
      draft!.difficulty,
    );
    expect(draft!.shape.cells.length, greaterThanOrEqualTo(30));
    // The bottom half of this fixture is land, not cloud.
    expect(
      draft!.shape.cells.every((cell) => cell ~/ cloudGridSide < 8),
      isTrue,
    );
    expect(find.byType(PlayScreen), findsOneWidget);
    await binding.takeScreenshot('photo-generated-game');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'clear sky, darkness and leaving analysis do not create bogus boards',
    (tester) async {
      for (final color in [
        img.ColorRgb8(45, 125, 235),
        img.ColorRgb8(0, 0, 0),
      ]) {
        final image = img.Image(width: 320, height: 320);
        img.fill(image, color: color);
        final result = await analyseCloud(
          prepareCloudPhoto(img.encodePng(image)),
        );
        expect(result.playable, isFalse);
      }
      // Bundled model is still available with no runtime download path.
      expect(
        (await rootBundle.load('assets/models/sky_u2netp_v1.onnx'))
            .lengthInBytes,
        lessThan(5000000),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CaptureScreen(initialPhoto: base64Decode(skyPhotoBase64)),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
