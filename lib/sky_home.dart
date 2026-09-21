import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart' as sensor;

import 'capture_screen.dart';
import 'app_info.dart';
import 'collection.dart';
import 'game.dart';
import 'play_screen.dart';
import 'sky_geometry.dart';
import 'style.dart';

class SkyHome extends StatefulWidget {
  const SkyHome({
    super.key,
    required this.collection,
    this.enableSensors = true,
    this.capturePhoto,
  });
  final CloudCollection collection;
  final bool enableSensors;
  // Optional fixture input for camera-less integration devices.
  final Uint8List? capturePhoto;
  @override
  State<SkyHome> createState() => _SkyHomeState();
}

class _SkyHomeState extends State<SkyHome> with WidgetsBindingObserver {
  StreamSubscription<sensor.OrientationEvent>? subscription;
  Timer? sensorTimeout;
  int motionGeneration = 0;
  sensor.Quaternion? smoothed;
  Direction? previewDirection;
  SkyView motionView = SkyView.looking(0, .35);
  double yaw = 0, elevation = .35, zoom = 1, initialZoom = 1;
  bool motionEnabled = false, sensorAvailable = false, routeOpen = false;
  String? sensorMessage;
  String? selectedId, draggingId;
  CloudPiece? touchedCloud;
  SkyView? frozenView;
  Offset? dragCenter;
  ({
    CloudPiece piece,
    double azimuth,
    double elevation,
    double distance,
  })? dragOriginal,
      undo;
  Size canvasSize = Size.zero;
  final Map<String, Rect> hitRects = {};

  List<CloudPiece> get pieces => widget.collection.pieces;
  CloudPiece? get pending => pieces.where((p) => !p.placed).firstOrNull;
  CloudPiece? get selected =>
      pieces.where((p) => p.id == selectedId).firstOrNull;
  SkyView get view =>
      frozenView ??
      (motionEnabled && sensorAvailable
          ? motionView
          : SkyView.looking(yaw, elevation));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.collection.addListener(refresh);
    selectedId = pieces.lastOrNull?.id;
    if (widget.enableSensors) startMotion();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  Future<void> startMotion() async {
    final stopping = stopMotion();
    final generation = motionGeneration;
    await stopping;
    if (!mounted ||
        routeOpen ||
        !widget.enableSensors ||
        generation != motionGeneration) {
      return;
    }
    if (!sensor.RotationSensor.isPlatformSupported) {
      setState(() => sensorMessage = '터치로 하늘을 둘러볼 수 있어요');
      return;
    }
    sensor.RotationSensor.samplingPeriod = const Duration(milliseconds: 32);
    sensor.RotationSensor.referenceFrame = sensor.ReferenceFrame.magneticNorth;
    sensor.RotationSensor.coordinateSystem = sensor.CoordinateSystem.device();
    smoothed = null;
    setState(() {
      motionEnabled = true;
      sensorAvailable = false;
      sensorMessage = null;
    });
    subscription = sensor.RotationSensor.orientationStream.listen(
      (event) {
        if (!mounted || routeOpen || generation != motionGeneration) return;
        var next = event.quaternion;
        if (![next.x, next.y, next.z, next.w].every((v) => v.isFinite) ||
            next.length2 < .000001) {
          return;
        }
        sensorTimeout?.cancel();
        if (kDebugMode && !sensorAvailable) {
          debugPrint('Sky motion: receiving orientation from device');
        }
        if (smoothed != null) {
          final previous = smoothed!;
          final dot =
              previous.x * next.x +
              previous.y * next.y +
              previous.z * next.z +
              previous.w * next.w;
          if (dot < 0) next = -next;
          next = (previous * .65 + next * .35).normalize();
        }
        smoothed = next;
        final m = next.toRotationMatrix();
        setState(() {
          sensorAvailable = true;
          motionView = SkyView.rotation([for (var i = 0; i < 9; i++) m[i]]);
          previewDirection ??= motionView.forward.direction;
        });
      },
      onError: (Object error) {
        if (!mounted || generation != motionGeneration) return;
        if (kDebugMode) debugPrint('Sky motion: $error');
        stopMotion();
        setState(() {
          motionEnabled = false;
          sensorAvailable = false;
          sensorMessage = '방향 센서를 사용할 수 없어 터치로 둘러봐요';
        });
      },
    );
    sensorTimeout = Timer(const Duration(seconds: 10), () {
      if (mounted && generation == motionGeneration && !sensorAvailable) {
        stopMotion();
        setState(() {
          motionEnabled = false;
          sensorMessage = '방향 센서를 사용할 수 없어 터치로 둘러봐요';
        });
      }
    });
  }

  Future<void> stopMotion() async {
    motionGeneration++;
    sensorTimeout?.cancel();
    final old = subscription;
    subscription = null;
    await old?.cancel();
  }

  void switchToTouch() {
    final direction = view.forward.direction;
    yaw = direction.azimuth;
    elevation = direction.elevation;
    motionEnabled = false;
    stopMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      stopMotion();
    } else if (motionEnabled && !routeOpen) {
      startMotion();
    }
  }

  @override
  void dispose() {
    stopMotion();
    widget.collection.removeListener(refresh);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> save() async {
    try {
      await widget.collection.save();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장하지 못했어요. 아래의 다시 저장을 눌러주세요.')),
        );
      }
    }
  }

  Future<void> openGame(CloudDraft draft) async {
    if (routeOpen) return;
    routeOpen = true;
    await stopMotion();
    if (!mounted) return;
    final piece = await Navigator.push<CloudPiece>(
      context,
      MaterialPageRoute(
        builder: (_) => PlayScreen(
          game: MineGame(
            shape: draft.shape,
            seed: Random().nextInt(0x7fffffff),
            name: draft.name,
            source: draft.source,
            difficulty: draft.difficulty,
          ),
          collection: widget.collection,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      routeOpen = false;
      if (piece != null) selectedId = piece.id;
    });
    if (motionEnabled) startMotion();
  }

  Future<void> openInfo() async {
    if (routeOpen) return;
    routeOpen = true;
    await stopMotion();
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AppInfoScreen()),
    );
    if (!mounted) return;
    routeOpen = false;
    if (motionEnabled) startMotion();
  }

  Future<void> openCamera() async {
    if (routeOpen) return;
    routeOpen = true;
    await stopMotion();
    if (!mounted) return;
    final draft = await Navigator.push<CloudDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureScreen(initialPhoto: widget.capturePhoto),
      ),
    );
    if (!mounted) return;
    routeOpen = false;
    if (draft != null) {
      await openGame(draft);
    } else if (motionEnabled) {
      startMotion();
    }
  }

  void placePending() {
    final piece = pending;
    if (piece == null || (motionEnabled && !sensorAvailable)) return;
    final direction = view.forward.direction;
    setState(() {
      piece
        ..azimuth = direction.azimuth
        ..elevation = direction.elevation
        ..placed = true;
      selectedId = piece.id;
      undo = null;
    });
    HapticFeedback.mediumImpact();
    save();
  }

  CloudPiece? hit(Offset point) {
    for (final entry in hitRects.entries.toList().reversed) {
      if (!entry.value.contains(point)) continue;
      final piece = pieces.firstWhere((p) => p.id == entry.key);
      final x =
          ((point.dx - entry.value.left) /
                  entry.value.width *
                  piece.shape.columns)
              .floor();
      final y =
          ((point.dy - entry.value.top) / entry.value.height * piece.shape.rows)
              .floor();
      if (piece.shape.cells.contains(y * piece.shape.columns + x)) return piece;
    }
    return null;
  }

  void beginGesture(ScaleStartDetails details) {
    initialZoom = zoom;
    // Recognition starts after touch slop; a distant cloud may already be behind the finger.
    final piece = pending == null && details.pointerCount == 1
        ? touchedCloud
        : null;
    final rect = hitRects[piece?.id];
    if (piece != null && rect != null) {
      frozenView = view;
      selectedId = draggingId = piece.id;
      dragCenter = rect.center;
      dragOriginal = (
        piece: piece,
        azimuth: piece.azimuth,
        elevation: piece.elevation,
        distance: piece.distance,
      );
    }
    setState(() {});
  }

  void updateGesture(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount > 1) {
        zoom = (initialZoom * details.scale).clamp(.55, 2.2);
        return;
      }
      if (draggingId != null) {
        dragCenter = dragCenter! + details.focalPointDelta;
        final direction = view
            .unproject(
              Point(dragCenter!.dx, dragCenter!.dy),
              canvasSize.width,
              canvasSize.height,
              zoom: zoom,
            )
            .direction;
        final piece = pieces.firstWhere((p) => p.id == draggingId);
        piece
          ..azimuth = direction.azimuth
          ..elevation = direction.elevation;
      } else if (!motionEnabled) {
        yaw = wrapAngle(
          yaw -
              details.focalPointDelta.dx /
                  (SkyView.focal(canvasSize.width) * zoom),
        );
        elevation =
            (elevation +
                    details.focalPointDelta.dy /
                        (SkyView.focal(canvasSize.width) * zoom))
                .clamp(-pi / 2 + .01, pi / 2 - .01);
      }
    });
  }

  void endGesture(ScaleEndDetails _) {
    final moved = dragOriginal;
    setState(() {
      if (moved != null &&
          (moved.piece.azimuth != moved.azimuth ||
              moved.piece.elevation != moved.elevation ||
              moved.piece.distance != moved.distance)) {
        undo = moved;
      }
      frozenView = null;
      draggingId = null;
      touchedCloud = null;
      dragOriginal = null;
    });
    if (moved != null) save();
  }

  void beginDistanceChange(CloudPiece piece) {
    setState(() {
      frozenView = view;
      dragOriginal = (
        piece: piece,
        azimuth: piece.azimuth,
        elevation: piece.elevation,
        distance: piece.distance,
      );
    });
  }

  Future<void> rename(CloudPiece piece) async {
    final controller = TextEditingController(text: piece.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('구름에 이름 붙이기'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          textInputAction: TextInputAction.done,
          onSubmitted: (text) {
            if (text.trim().isNotEmpty) Navigator.pop(context, text.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (name != null && mounted) {
      setState(() => piece.name = name);
      save();
    }
  }

  void focus(CloudPiece piece) {
    setState(() {
      selectedId = piece.id;
      if (!motionEnabled) {
        yaw = piece.azimuth;
        elevation = piece.elevation;
      }
      zoom = 1;
    });
  }

  Future<void> showCollection() async {
    final piece = await showModalBottomSheet<CloudPiece>(
      context: context,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (context) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: Row(
                children: [
                  const Text(
                    '모아온 구름',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${pieces.length} 조각',
                    style: const TextStyle(color: mutedInk),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: pieces.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final cloud = pieces[pieces.length - 1 - index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    leading: SizedBox(
                      width: 52,
                      child: CloudArtwork(shape: cloud.shape),
                    ),
                    title: Text(
                      cloud.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${cloud.difficulty.label} · ${dateLabel(cloud.collectedAt)}\n${cloud.placed ? clockLabel(cloud.seconds) : '놓을 자리 기다리는 중'}',
                    ),
                    trailing: const Icon(Icons.near_me_outlined, size: 19),
                    onTap: () => Navigator.pop(context, cloud),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (piece != null && mounted) focus(piece);
  }

  @override
  Widget build(BuildContext context) {
    final direction = view.forward.direction;
    return Scaffold(
      body: SkyBackground(
        view: view,
        zoom: zoom,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 18, 18, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '구름을 모으는 작은 습관',
                        style: TextStyle(fontSize: 12, color: mutedInk),
                      ),
                    ),
                    IconButton(
                      tooltip: '앱 안내',
                      onPressed: openInfo,
                      icon: const Icon(Icons.info_outline, size: 21),
                    ),
                    if (pieces.isNotEmpty)
                      IconButton(
                        tooltip: '모든 구름 보기',
                        onPressed: pieces.isEmpty ? null : showCollection,
                        icon: const Icon(Icons.grid_view_rounded, size: 21),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 12, 26, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '나의 하늘',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            pieces.isEmpty
                                ? '작은 발견들이 모여, 나만의 하늘로.'
                                : '${pieces.length}개의 구름, 이어지는 나의 이야기.',
                            style: const TextStyle(
                              color: mutedInk,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          Text(
                            pieces.length.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '모은 구름',
                            style: TextStyle(
                              fontSize: 7,
                              letterSpacing: 1.1,
                              color: mutedInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        if (motionEnabled) {
                          setState(switchToTouch);
                        } else {
                          startMotion();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              motionEnabled
                                  ? Icons.explore_outlined
                                  : Icons.pan_tool_outlined,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              motionEnabled
                                  ? (sensorAvailable ? '기기 방향' : '방향 연결 중')
                                  : '터치 모드',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    canvasSize = constraints.biggest;
                    return Listener(
                      onPointerDown: (event) =>
                          touchedCloud = hit(event.localPosition),
                      child: GestureDetector(
                        key: const ValueKey('sky-canvas'),
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: beginGesture,
                        onScaleUpdate: updateGesture,
                        onScaleEnd: endGesture,
                        onTapUp: (details) {
                          final piece = hit(details.localPosition);
                          if (piece != null) {
                            setState(() => selectedId = piece.id);
                          }
                        },
                        child: ClipRect(
                          child: Stack(
                            children: [
                              if (pieces.isEmpty) ...previewCloud(canvasSize),
                              if (pieces.isEmpty)
                                Align(
                                  alignment: const Alignment(0, .75),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '나만의 하늘을 채워보세요',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        motionEnabled
                                            ? '휴대폰을 돌려 하늘을 둘러보세요'
                                            : '빈 하늘을 밀어 둘러보세요',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mutedInk,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ...cloudWidgets(canvasSize),
                              if (motionEnabled &&
                                  sensorAvailable &&
                                  pending == null &&
                                  selected?.placed == true &&
                                  !hitRects.containsKey(selected!.id))
                                Positioned(
                                  top: 14,
                                  left: 24,
                                  right: 24,
                                  child: IgnorePointer(
                                    child: Text(
                                      directionGuide(selected!, direction),
                                      key: const ValueKey(
                                        'cloud-direction-guide',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                ),
                              if (pending != null)
                                ...pendingWidgets(canvasSize, pending!),
                              if (undo != null && pending == null)
                                Positioned(
                                  right: 16,
                                  top: 14,
                                  child: IconButton.filledTonal(
                                    tooltip: '마지막 이동 되돌리기',
                                    onPressed: () {
                                      final previous = undo!;
                                      setState(() {
                                        previous.piece
                                          ..azimuth = previous.azimuth
                                          ..elevation = previous.elevation
                                          ..distance = previous.distance;
                                        undo = null;
                                      });
                                      save();
                                    },
                                    icon: const Icon(
                                      Icons.undo_rounded,
                                      size: 19,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 17),
                child: Text(
                  pending != null
                      ? (motionEnabled
                            ? '휴대폰을 돌려 구름을 놓을 방향을 찾아보세요'
                            : '빈 하늘을 밀어 구름을 놓을 방향을 찾아보세요')
                      : draggingId != null
                      ? '손을 놓으면 이 자리에 저장돼요'
                      : pieces.isEmpty
                      ? '하늘에서 발견하고, 퍼즐로 간직해요'
                      : motionEnabled
                      ? '휴대폰을 돌려 둘러보고 · 구름은 끌어서 옮겨요'
                      : '빈 하늘을 밀어 둘러보고 · 구름은 끌어서 옮겨요',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: mutedInk),
                ),
              ),
              if (widget.collection.saveError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '저장되지 않은 변경이 있어요',
                          style: TextStyle(color: accent, fontSize: 12),
                        ),
                      ),
                      TextButton(onPressed: save, child: const Text('다시 저장')),
                    ],
                  ),
                ),
              bottomPanel(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> pendingWidgets(Size size, CloudPiece piece) {
    final width = SkyView.focal(size.width) * .48 * zoom / piece.distance;
    return [
      Positioned.fromRect(
        rect: Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: width,
          height: width * piece.shape.rows / piece.shape.columns,
        ),
        child: IgnorePointer(
          child: CloudArtwork(
            key: const ValueKey('pending-cloud'),
            shape: piece.shape,
            selected: true,
            opacity: .88,
          ),
        ),
      ),
      if (size.height > 130)
        const Positioned(
          top: 14,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Text(
                '새 구름',
                style: TextStyle(color: accent, fontSize: 11),
              ),
            ),
          ),
        ),
      const Center(
        child: IgnorePointer(
          child: Icon(Icons.add_rounded, color: accent, size: 22),
        ),
      ),
    ];
  }

  List<Widget> previewCloud(Size size) {
    final direction = previewDirection ?? (azimuth: 0.0, elevation: .35);
    final ray = Vec3.fromDirection(direction.azimuth, direction.elevation);
    final center = view.project(ray, size.width, size.height, zoom: zoom);
    if (center == null) return [];
    final width =
        SkyView.focal(size.width) * .55 * zoom / ray.dot(view.forward);
    return [
      Positioned(
        left: center.x - width / 2,
        top:
            center.y -
            width *
                sampleClouds.first.shape.rows /
                sampleClouds.first.shape.columns /
                2,
        width: width,
        child: IgnorePointer(
          child: CloudArtwork(
            key: const ValueKey('preview-cloud'),
            shape: sampleClouds.first.shape,
            opacity: .76,
          ),
        ),
      ),
    ];
  }

  List<Widget> cloudWidgets(Size size) {
    hitRects.clear();
    final widgets = <Widget>[];
    double depth(CloudPiece p) =>
        Vec3.fromDirection(p.azimuth, p.elevation).dot(view.forward) *
        p.distance;
    final ordered = pieces.where((p) => p.placed).toList()
      ..sort((a, b) => depth(b).compareTo(depth(a)));
    // Paint far to near; reverse hit testing then selects the visible front cloud.
    for (final piece in ordered) {
      final vector = Vec3.fromDirection(piece.azimuth, piece.elevation);
      final center = view.project(vector, size.width, size.height, zoom: zoom);
      if (center == null) continue;
      final width =
          SkyView.focal(size.width) *
          .48 *
          zoom /
          (vector.dot(view.forward) * piece.distance);
      final height = width * piece.shape.rows / piece.shape.columns;
      final rect = Rect.fromCenter(
        center: Offset(center.x, center.y),
        width: width,
        height: height,
      );
      if (!rect.overlaps(Offset.zero & size)) continue;
      hitRects[piece.id] = rect;
      widgets.add(
        Positioned.fromRect(
          rect: rect,
          child: Semantics(
            label: '${piece.name}, 구름 조각',
            child: CloudArtwork(
              key: ValueKey('cloud-piece-${piece.id}'),
              shape: piece.shape,
              selected: selectedId == piece.id,
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget distanceControl(CloudPiece cloud) => Row(
    children: [
      const Text('가까이', style: TextStyle(fontSize: 11, color: mutedInk)),
      Expanded(
        child: Slider(
          key: const ValueKey('cloud-distance'),
          value: log(cloud.distance),
          min: log(CloudPiece.minDistance),
          max: log(CloudPiece.maxDistance),
          semanticFormatterCallback: (value) =>
              '구름 거리, 기본의 ${exp(value).toStringAsFixed(1)}배',
          onChangeStart: (_) {
            beginDistanceChange(cloud);
          },
          onChanged: (value) => setState(() {
            final distance = exp(value)
                .clamp(CloudPiece.minDistance, CloudPiece.maxDistance);
            cloud.distance = distance;
          }),
          onChangeEnd: (_) => endGesture(ScaleEndDetails()),
        ),
      ),
      const Text('멀리', style: TextStyle(fontSize: 11, color: mutedInk)),
    ],
  );

  Widget bottomPanel() {
    final cloud = pending ?? selected;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      decoration: BoxDecoration(
        color: paper.withValues(alpha: .94),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cloud != null) ...[
            Row(
              children: [
                SizedBox(width: 46, child: CloudArtwork(shape: cloud.shape)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cloud.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${cloud.difficulty.label} · ${dateLabel(cloud.collectedAt)}',
                        style: const TextStyle(fontSize: 11, color: mutedInk),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '구름 이름 바꾸기',
                  onPressed: () => rename(cloud),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                if (cloud.placed)
                  IconButton(
                    tooltip: motionEnabled ? '구름 방향 찾기' : '이 구름 바라보기',
                    onPressed: () => focus(cloud),
                    icon: const Icon(Icons.center_focus_weak, size: 21),
                  ),
              ],
            ),
          ] else ...[
            const Row(
              children: [
                Expanded(
                  child: Text(
                    '오늘의 구름을 만나러 갈까요?',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.north_east_rounded, size: 18),
              ],
            ),
            const SizedBox(height: 18),
          ],
          if (cloud != null) distanceControl(cloud),
          PrimaryButton(
            label: pending != null
                ? (motionEnabled && !sensorAvailable ? '방향 연결 중…' : '여기에 놓기')
                : '새 구름 찾기',
            icon: pending != null
                ? Icons.add_rounded
                : Icons.camera_alt_outlined,
            onPressed: pending != null ? placePending : openCamera,
          ),
          if (pending != null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '놓은 뒤에도 위치와 거리를 바꿀 수 있어요',
                style: TextStyle(fontSize: 12, color: mutedInk),
              ),
            )
          else
            const SizedBox(height: 12),
          if (sensorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                sensorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: mutedInk),
              ),
            ),
        ],
      ),
    );
  }
}

String dateLabel(DateTime date) =>
    '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

String directionGuide(CloudPiece piece, Direction looking) {
  final horizontal = wrapAngle(piece.azimuth - looking.azimuth) * 180 / pi;
  final vertical = (piece.elevation - looking.elevation) * 180 / pi;
  final steps = [
    if (horizontal.abs() > 8)
      '${horizontal > 0 ? '오른쪽 →' : '← 왼쪽'} ${horizontal.abs().round()}°',
    if (vertical.abs() > 8)
      '${vertical > 0 ? '위 ↑' : '아래 ↓'} ${vertical.abs().round()}°',
  ];
  return '${piece.name}\n${steps.isEmpty ? '휴대폰을 천천히 돌려 찾아보세요' : steps.join(' · ')}';
}
