import 'dart:math';
import 'dart:ui' as ui;

import 'package:cloud_minesweeper/sky_geometry.dart';
import 'package:cloud_minesweeper/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('sky pixels respond to heading and return after a full turn', (
    tester,
  ) async {
    final boundary = GlobalKey();
    final orientation = ValueNotifier(SkyView.looking(0, .35));
    addTearDown(orientation.dispose);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ValueListenableBuilder<SkyView>(
          valueListenable: orientation,
          builder: (context, view, _) => RepaintBoundary(
            key: boundary,
            child: SkyBackground(view: view, child: const SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (
      var i = 0;
      i < 30 &&
          find
              .byKey(const ValueKey('directional-sky-background'))
              .evaluate()
              .isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.byKey(const ValueKey('directional-sky-background')),
      findsOneWidget,
    );
    Future<List<int>> pixels() async {
      final image =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: .25);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List().toList();
      image.dispose();
      return bytes;
    }

    final north = await pixels();
    await binding.takeScreenshot('sky-north');
    orientation.value = SkyView.looking(pi / 2, .35);
    await tester.pumpAndSettle();
    final east = await pixels();
    await binding.takeScreenshot('sky-east');
    var changed = 0;
    for (var i = 0; i < north.length; i += 4) {
      if ((north[i] - east[i]).abs() +
              (north[i + 1] - east[i + 1]).abs() +
              (north[i + 2] - east[i + 2]).abs() >
          12) {
        changed++;
      }
    }
    expect(changed / (north.length / 4), greaterThan(.12));
    orientation.value = SkyView.looking(2 * pi, .35);
    await tester.pumpAndSettle();
    final fullTurn = await pixels();
    var delta = 0;
    for (var i = 0; i < north.length; i++) {
      delta += (north[i] - fullTurn[i]).abs();
    }
    expect(delta / north.length, lessThan(1));
    expect(tester.takeException(), isNull);
  });
}
