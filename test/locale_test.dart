import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_minesweeper/main.dart';
import 'package:cloud_minesweeper/collection.dart';

void main() {
  testWidgets('Flutter labels stay Korean on an English device', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      CloudApp(
        collection: CloudCollection(File('/unused-locale-test.json')),
        enableSensors: false,
      ),
    );
    final context = tester.element(find.byType(Scaffold).first);
    expect(MaterialLocalizations.of(context).backButtonTooltip, '뒤로');
    expect(Localizations.localeOf(context), const Locale('ko'));
  });
}
