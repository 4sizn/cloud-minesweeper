import 'dart:io';
import 'dart:math';

import 'package:cloud_minesweeper/collection.dart';
import 'package:cloud_minesweeper/game.dart';
import 'package:cloud_minesweeper/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart' as sensor;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('native orientation moves clouds, survives gestures and resume', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final messenger = tester.binding.defaultBinaryMessenger;
    const codec = StandardMethodCodec();
    var listens = 0;
    messenger.setMockMethodCallHandler(
      const MethodChannel('native_device_orientation_events'),
      (_) async => null,
    );

    messenger.setMockMethodCallHandler(
      const MethodChannel('rotation_sensor/method'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('rotation_sensor/orientation'),
      (call) async {
        if (call.method == 'listen') listens++;
        return null;
      },
    );
    // Core Motion uses north / west / up. The plugin maps it to east / north / up.
    Future<void> point(double heading) async {
      final northPortrait = sensor.Quaternion(sqrt(.5), 0, 0, sqrt(.5));
      final worldTurn = sensor.Quaternion(
        0,
        0,
        sin(-heading / 2),
        cos(heading / 2),
      );
      final enu = worldTurn * northPortrait;
      final toApple = sensor.Quaternion(0, 0, -sqrt(.5), sqrt(.5));
      final native = toApple * enu;
      for (var i = 0; i < 25; i++) {
        messenger.handlePlatformMessage(
          'rotation_sensor/orientation',
          codec.encodeSuccessEnvelope([
            native.x,
            native.y,
            native.z,
            native.w,
            -1.0,
            i,
          ]),
          (_) {},
        );
        await tester.pump(const Duration(milliseconds: 32));
      }
    }

    final directory = await tester.runAsync(
      () => Directory.systemTemp.createTemp('motion-test-'),
    );
    addTearDown(() => directory!.delete(recursive: true));
    final collection = CloudCollection(File('${directory!.path}/sky.json'));
    await tester.pumpWidget(CloudApp(collection: collection));
    await tester.pump();
    await point(0);
    final preview = find.byKey(const ValueKey('preview-cloud'));
    final previewStart = tester.getCenter(preview);
    await point(pi / 9);
    expect(tester.getCenter(preview).dx, lessThan(previewStart.dx - 50));
    final game = MineGame(
      shape: sampleClouds.first.shape,
      seed: 7,
      name: '북쪽 구름',
    );
    game.open(game.shape.cells.first);
    for (final i in game.shape.cells) {
      if (!game.mines.contains(i)) game.open(i);
    }
    final piece = await tester.runAsync(() => collection.collect(game, 1));
    piece!
      ..azimuth = 0
      ..elevation = 0
      ..placed = true;
    await tester.pumpWidget(
      CloudApp(key: const ValueKey('collected'), collection: collection),
    );
    await tester.pump();
    await point(0);
    expect(find.text('기기 방향'), findsOneWidget);
    final cloud = find.byKey(ValueKey('cloud-piece-${piece.id}'));
    expect(cloud, findsOneWidget);
    final initial = tester.getCenter(cloud);
    await point(pi / 9);
    expect(tester.getCenter(cloud).dx, lessThan(initial.dx - 50));

    // An empty-sky pan and a pinch must not quietly turn tracking off.
    final canvas = find.byKey(const ValueKey('sky-canvas'));
    final corner = tester.getTopLeft(canvas) + const Offset(20, 20);
    await tester.dragFrom(corner, const Offset(40, 25));
    await tester.pump();
    expect(find.text('기기 방향'), findsOneWidget);
    final a = await tester.startGesture(corner, pointer: 1);
    final b = await tester.startGesture(
      corner + const Offset(40, 0),
      pointer: 2,
    );
    await a.moveBy(const Offset(-10, 0));
    await b.moveBy(const Offset(10, 0));
    await a.up();
    await b.up();
    await tester.pump();
    expect(find.text('기기 방향'), findsOneWidget);

    await point(pi);
    expect(cloud, findsNothing);
    await tester.tap(find.byTooltip('구름 방향 찾기'));
    await tester.pump();
    expect(find.text('기기 방향'), findsOneWidget);
    expect(find.byKey(const ValueKey('cloud-direction-guide')), findsOneWidget);
    await tester.tap(find.byTooltip('모든 구름 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('북쪽 구름').last);
    await tester.pumpAndSettle();
    expect(find.text('기기 방향'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await point(0);
    expect(listens, greaterThanOrEqualTo(2));
    expect(cloud, findsOneWidget);
    expect(find.text('기기 방향'), findsOneWidget);
    await tester.tap(find.text('기기 방향'));
    await tester.pump();
    expect(find.text('터치 모드'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));
}
