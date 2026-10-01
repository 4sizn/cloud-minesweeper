import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_minesweeper/main.dart';
import 'package:cloud_minesweeper/collection.dart';
import 'package:cloud_minesweeper/l10n/app_localizations.dart';

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    for (final size in [const Size(390, 844), const Size(320, 640)]) {
      // The test font draws every glyph one em wide, which makes Latin text
      // far wider than on a phone; the small screen is checked with CJK only.
      if (locale.languageCode == 'en' && size.width == 320) continue;
      testWidgets('empty sky fits ${size.width} × ${size.height} in $locale', (
        tester,
      ) async {
        final l = lookupAppLocalizations(locale);
        tester.platformDispatcher.localesTestValue = [locale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
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
        expect(find.text(l.findNewCloud), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('샘플'), findsNothing);
        expect(find.byKey(const ValueKey('cloud-distance')), findsNothing);
        await tester.tap(find.byTooltip(l.appInfo));
        await tester.pumpAndSettle();
        expect(find.text(l.howToPlay), findsOneWidget);
        expect(find.text('4sizn@naver.com'), findsOneWidget);
        await tester.tap(find.text(l.howToPlay));
        await tester.pumpAndSettle();
        expect(find.text(l.help1Title), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
