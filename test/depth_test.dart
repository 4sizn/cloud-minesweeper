import 'dart:io';

import 'package:cloud_minesweeper/collection.dart';
import 'package:cloud_minesweeper/main.dart';
import 'package:cloud_minesweeper/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'core_test.dart' show solved;

void main() {
  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets(
      'depth changes perspective, picking and saved placement at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final directory = await tester.runAsync(
          () => Directory.systemTemp.createTemp('depth-test-'),
        );
        addTearDown(() => directory!.delete(recursive: true));
        final collection = CloudCollection(File('${directory!.path}/sky.json'));
        Future<void> flushSave() async {
          var finished = false;
          collection.save().then((_) => finished = true);
          for (var i = 0; i < 100 && !finished; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.pump();
          }
          expect(finished, isTrue, reason: 'Collection save must finish');
        }

        await tester.pumpWidget(
          CloudApp(collection: collection, enableSensors: false),
        );
        await tester.pumpAndSettle();
        final slider = find.byKey(const ValueKey('cloud-distance'));
        Future<void> sendFar() async {
          await tester.tapAt(
            tester.getRect(slider).centerRight - const Offset(28, 0),
          );
          await tester.pumpAndSettle();
        }

        expect(slider, findsNothing);
        expect(collection.pieces, isEmpty);

        final near = await tester.runAsync(
          () => collection.collect(solved(seed: 71), 1),
        );
        final far = await tester.runAsync(
          () => collection.collect(solved(seed: 72), 1),
        );
        near!
          ..name = '가까운 구름'
          ..placed = true;
        far!
          ..name = '먼 구름'
          ..placed = true
          ..distance = 3;
        await tester.pumpWidget(
          CloudApp(
            key: UniqueKey(),
            collection: collection,
            enableSensors: false,
          ),
        );
        await tester.pumpAndSettle();
        final front = find.byKey(ValueKey('cloud-piece-${near.id}'));
        final back = find.byKey(ValueKey('cloud-piece-${far.id}'));
        final originalWidth = tester.getSize(front).width;
        final originalCenter = tester.getCenter(front);
        final farWidth = tester.getSize(back).width;
        expect(originalWidth, closeTo(farWidth * 3, .001));
        // Added first, but nearer: must draw on top and win picking.
        await tester.tapAt(tester.getCenter(front));
        await tester.pump();
        expect(find.text('가까운 구름'), findsOneWidget);
        await sendFar();
        expect(near.distance, greaterThan(3));
        expect(tester.getCenter(front), originalCenter);
        expect(
          tester.getSize(front).width,
          closeTo(originalWidth / near.distance, .001),
        );
        expect(tester.getSize(back).width, farWidth);
        final order = tester
            .widgetList<CloudArtwork>(
              find.descendant(
                of: find.byKey(const ValueKey('sky-canvas')),
                matching: find.byType(CloudArtwork),
              ),
            )
            .map((w) => w.key)
            .toList();
        expect(order, [
          ValueKey('cloud-piece-${near.id}'),
          ValueKey('cloud-piece-${far.id}'),
        ]);
        await tester.tap(find.byTooltip('마지막 이동 되돌리기'));
        await tester.pumpAndSettle();
        expect(near.distance, 1);
        expect(tester.getSize(front).width, closeTo(originalWidth, .001));
        await sendFar();
        final savedDistance = near.distance;
        final restored = CloudCollection(collection.file);
        await flushSave();
        await tester.runAsync(restored.load);
        expect(restored.pieces.first.distance, savedDistance);

        // The same depth control also works before placement, even on a short screen.
        near.placed = false;
        await flushSave();
        await tester.pumpAndSettle();
        final pending = find.byKey(const ValueKey('pending-cloud'));
        final pendingWidth = tester.getSize(pending).width;
        await tester.tap(find.text('여기에 놓기'));
        await tester.pumpAndSettle();
        expect(near.placed, isTrue);
        expect(near.distance, savedDistance);
        expect(tester.getSize(front).width, closeTo(pendingWidth, .001));

        // A cloud smaller than gesture recognition slop still drags from its original touch.
        near.distance = 6;
        far.azimuth = 3.14;
        await flushSave();
        await tester.pumpAndSettle();
        final azimuth = near.azimuth;
        await tester.dragFrom(tester.getCenter(front), const Offset(65, -20));
        await tester.pumpAndSettle();
        expect(near.azimuth, isNot(closeTo(azimuth, 1e-5)));
        expect(near.distance, 6);
        await tester.tap(find.byTooltip('마지막 이동 되돌리기'));
        await tester.pumpAndSettle();
        expect(near.azimuth, closeTo(azimuth, 1e-8));
        expect(tester.takeException(), isNull);
        await flushSave();
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
}
