import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_minesweeper/main.dart';
import 'package:cloud_minesweeper/collection.dart';

void main() {
  for (final (device, back, title) in [
    (const Locale('en', 'US'), 'Back', 'My sky'),
    (const Locale('ko', 'KR'), '뒤로', '나의 하늘'),
    // Unsupported device languages fall back to English.
    (const Locale('fr', 'FR'), 'Back', 'My sky'),
  ]) {
    testWidgets('$device device shows "$title"', (tester) async {
      tester.platformDispatcher.localesTestValue = [device];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        CloudApp(
          collection: CloudCollection(File('/unused-locale-test.json')),
          enableSensors: false,
        ),
      );
      final context = tester.element(find.byType(Scaffold).first);
      expect(MaterialLocalizations.of(context).backButtonTooltip, back);
      expect(find.text(title), findsOneWidget);
    });
  }
}
