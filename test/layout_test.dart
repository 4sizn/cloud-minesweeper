import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_minesweeper/main.dart';
import 'package:cloud_minesweeper/collection.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('empty sky fits ${size.width} × ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = size.width == 320
          ? 1.3
          : 1;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        CloudApp(
          collection: CloudCollection(File('/unused-layout-test.json')),
          enableSensors: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('새 구름 찾기'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('샘플'), findsNothing);
      expect(find.byKey(const ValueKey('cloud-distance')), findsNothing);
      await tester.tap(find.byTooltip('앱 안내'));
      await tester.pumpAndSettle();
      expect(find.text('플레이 방법'), findsOneWidget);
      expect(find.text('4sizn@naver.com'), findsOneWidget);
      await tester.tap(find.text('플레이 방법'));
      await tester.pumpAndSettle();
      expect(find.text('1. 구름을 촬영해요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
