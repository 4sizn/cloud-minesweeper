import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cloud_analysis.dart';
import 'app_info.dart';
import 'game.dart';
import 'style.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, this.initialPhoto});
  // Allows the same photo pipeline to be exercised on camera-less test devices.
  final Uint8List? initialPhoto;
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  Uint8List? photo, originalPhoto;
  String? error;
  String analysisMessage = '';
  bool busy = false, painting = true;
  bool analysing = false, manuallyEdited = false;
  bool editing = false, analysisFailed = false, cameraDenied = false;
  bool openingCamera = false;
  final random = Random();
  Difficulty difficulty = Difficulty.normal;
  int cameraGeneration = 0;
  int analysisGeneration = 0;
  final selected = <int>{};
  final automaticSelection = <int>{};
  static const columns = cloudGridSide, rows = cloudGridSide;
  Offset? previousPoint;
  double zoom = 1, minZoom = 1, maxZoom = 1, pinchStartZoom = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialPhoto != null) {
      processPhoto(widget.initialPhoto!);
    } else {
      openCamera();
    }
  }

  Future<void> openCamera() async {
    if (photo != null || busy || controller != null || openingCamera) return;
    openingCamera = true;
    setState(() => error = null);
    final generation = ++cameraGeneration;
    CameraController? next;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('No camera');
      final camera =
          cameras
              .where((c) => c.lensDirection == CameraLensDirection.back)
              .firstOrNull ??
          cameras.first;
      next = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await next.initialize();
      final lowest = await next.getMinZoomLevel();
      // Past 8x the digital zoom only magnifies noise.
      final highest = min(await next.getMaxZoomLevel(), 8.0);
      if (!mounted || generation != cameraGeneration) {
        await next.dispose();
        return;
      }
      setState(() {
        controller = next;
        minZoom = lowest;
        maxZoom = max(lowest, highest);
        zoom = lowest;
        error = null;
        cameraDenied = false;
      });
    } catch (exception) {
      await next?.dispose();
      if (!mounted || generation != cameraGeneration) return;
      setState(() {
        cameraDenied =
            exception is CameraException && exception.code.contains('Access');
        error = cameraDenied
            ? '카메라 접근이 꺼져 있어요.\n설정에서 카메라 권한을 켜주세요.'
            : '카메라를 연결하지 못했어요.\n잠시 후 다시 시도해주세요.';
      });
    } finally {
      if (generation == cameraGeneration) openingCamera = false;
    }
  }

  Future<void> closeCamera() async {
    cameraGeneration++;
    openingCamera = false;
    final old = controller;
    controller = null;
    await old?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && photo == null) {
      openCamera();
    } else if (state != AppLifecycleState.resumed) {
      closeCamera();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    analysisGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    closeCamera();
    super.dispose();
  }

  void setZoom(double level) {
    final camera = controller;
    if (camera == null) return;
    final next = level.clamp(minZoom, maxZoom);
    if (next == zoom) return;
    setState(() => zoom = next);
    camera.setZoomLevel(next).catchError((_) {});
  }

  Future<void> takePhoto() async {
    if (busy || controller == null) return;
    setState(() => busy = true);
    XFile? shot;
    try {
      shot = await controller!.takePicture();
      final bytes = await shot.readAsBytes();
      await closeCamera();
      if (mounted) {
        await processPhoto(bytes);
      }
    } catch (_) {
      await closeCamera();
      if (mounted) {
        setState(() {
          error = '촬영하지 못했어요. 다시 시도해주세요.';
          busy = false;
        });
      }
    } finally {
      if (shot != null) {
        final temporaryPhoto = File(shot.path);
        try {
          if (await temporaryPhoto.exists()) await temporaryPhoto.delete();
        } on FileSystemException {
          // The camera temporary directory is also cleaned by the OS.
        }
      }
    }
  }

  Future<void> processPhoto(Uint8List bytes, {bool newCapture = true}) async {
    final generation = ++analysisGeneration;
    setState(() {
      photo = bytes;
      originalPhoto = bytes;
      if (newCapture) difficulty = Difficulty.roll(random);
      analysing = true;
      busy = false;
      manuallyEdited = false;
      editing = false;
      analysisFailed = false;
      automaticSelection.clear();
      selected.clear();
      analysisMessage = '기기 안에서 구름 모양을 분석하고 있어요.';
    });
    try {
      final prepared = await compute(prepareCloudPhoto, bytes);
      if (!mounted || generation != analysisGeneration) return;
      setState(() => photo = prepared.preview);
      final result = await analyseCloud(prepared);
      if (!mounted || generation != analysisGeneration) return;
      setState(() {
        selected.addAll(result.cells);
        automaticSelection.addAll(result.cells);
        analysisMessage = result.message;
        analysing = false;
        editing = !result.playable;
      });
    } catch (_) {
      if (!mounted || generation != analysisGeneration) return;
      setState(() {
        analysing = false;
        analysisFailed = true;
        editing = true;
        analysisMessage = '자동 분석을 마치지 못했어요. 다시 분석하거나 구름을 직접 골라주세요.';
      });
    }
  }

  int? cellAt(Offset point, double side) {
    if (point.dx < 0 || point.dy < 0 || point.dx >= side || point.dy >= side) {
      return null;
    }
    return (point.dy / side * rows).floor() * columns +
        (point.dx / side * columns).floor();
  }

  void stroke(Offset point, double side, {bool start = false}) {
    if (analysing || !editing) return;
    final index = cellAt(point, side);
    if (index == null) return;
    if (start) {
      painting = !selected.contains(index);
      previousPoint = point;
    }
    final from = previousPoint ?? point;
    final steps = max(
      1,
      ((point - from).distance / (side / columns / 2)).ceil(),
    );
    setState(() {
      manuallyEdited = true;
      for (var step = 0; step <= steps; step++) {
        final p = Offset.lerp(from, point, step / steps)!;
        final cell = cellAt(p, side);
        if (cell != null) {
          if (painting) {
            selected.add(cell);
          } else {
            selected.remove(cell);
          }
        }
      }
    });
    previousPoint = point;
  }

  void finish() {
    if (analysing || selected.length < minimumCloudCells) return;
    final shape = CloudShape(columns, rows, selected);
    final cluster = shape.largestComponent;
    if (cluster.length < minimumCloudCells) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서로 이어진 구름 칸을 30개 이상 골라주세요.')),
      );
      return;
    }
    Navigator.pop<CloudDraft>(context, (
      shape: CloudShape(columns, rows, cluster).trimmed,
      name: '내가 찾은 구름',
      source: manuallyEdited ? 'camera-corrected' : 'camera-auto',
      difficulty: difficulty,
    ));
  }

  void retake() {
    analysisGeneration++;
    setState(() {
      photo = originalPhoto = null;
      selected.clear();
      automaticSelection.clear();
      error = null;
    });
    openCamera();
  }

  bool get canStart =>
      !analysing &&
      selected.length >= minimumCloudCells &&
      CloudShape(columns, rows, selected).largestComponent.length >=
          minimumCloudCells;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: paper,
    appBar: AppBar(
      title: Text(photo == null ? '오늘의 하늘 찾기' : '찾아낸 구름'),
      backgroundColor: paper,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              photo == null
                  ? '하늘을 화면에 담아주세요'
                  : analysing
                  ? '구름을 찾고 있어요'
                  : '이 구름으로 놀아볼까요?',
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              photo == null ? '한 장 찍으면 구름 모양을 자동으로 찾아요.' : analysisMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: mutedInk, height: 1.5),
            ),
            const SizedBox(height: 26),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1,
                child: photo != null
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final side = constraints.maxWidth;
                          return GestureDetector(
                            onPanStart: (d) =>
                                stroke(d.localPosition, side, start: true),
                            onPanUpdate: (d) => stroke(d.localPosition, side),
                            onTapUp: (d) =>
                                stroke(d.localPosition, side, start: true),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(photo!, fit: BoxFit.cover),
                                if (!analysing)
                                  CustomPaint(
                                    painter: _SelectionPainter(
                                      selected.toSet(),
                                    ),
                                  ),
                                if (analysing)
                                  const ColoredBox(
                                    color: Color(0x55183D62),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      )
                    : error != null
                    ? ColoredBox(
                        color: const Color(0xFFE7EFF4),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 42,
                                  color: mutedInk,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: mutedInk,
                                    height: 1.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : controller != null && controller!.value.isInitialized
                    ? GestureDetector(
                        onScaleStart: (_) => pinchStartZoom = zoom,
                        onScaleUpdate: (d) => setZoom(pinchStartZoom * d.scale),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: controller!.value.previewSize!.height,
                                height: controller!.value.previewSize!.width,
                                child: CameraPreview(controller!),
                              ),
                            ),
                            if (maxZoom > minZoom)
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      '${zoom.toStringAsFixed(1)}x',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : const ColoredBox(
                        color: Color(0xFFE7EFF4),
                        child: Center(child: CircularProgressIndicator()),
                      ),
              ),
            ),
            if (photo == null && controller != null && maxZoom > minZoom)
              Row(
                children: [
                  const Icon(Icons.zoom_out, color: mutedInk),
                  Expanded(
                    child: Slider(
                      value: zoom,
                      min: minZoom,
                      max: maxZoom,
                      label: '${zoom.toStringAsFixed(1)}x',
                      semanticFormatterCallback: (v) =>
                          '확대 ${v.toStringAsFixed(1)}배',
                      onChanged: setZoom,
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: mutedInk),
                ],
              ),
            const SizedBox(height: 24),
            if (photo != null) ...[
              Semantics(
                label: '이번 구름 난이도 ${difficulty.description}',
                child: Chip(
                  avatar: const Icon(Icons.bar_chart_rounded, size: 18),
                  label: Text('난이도 ${difficulty.description}'),
                ),
              ),
              const SizedBox(height: 12),
              if (editing && !analysing) ...[
                Text(
                  '${selected.length}칸 선택 · 연결된 30칸 이상 필요',
                  style: const TextStyle(color: mutedInk, fontSize: 12),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        selected
                          ..clear()
                          ..addAll(automaticSelection);
                        manuallyEdited = false;
                      }),
                      child: const Text('자동 선택 복원'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        selected.clear();
                        manuallyEdited = true;
                      }),
                      child: const Text('전체 지우기'),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    '구름을 칠해 추가하고, 다시 칠해 지워요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: mutedInk),
                  ),
                ),
              ],
              PrimaryButton(
                label: '이 구름으로 시작',
                onPressed: canStart ? finish : null,
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  if (analysisFailed)
                    TextButton(
                      onPressed: analysing
                          ? null
                          : () =>
                                processPhoto(originalPhoto!, newCapture: false),
                      child: const Text('다시 분석'),
                    )
                  else
                    TextButton(
                      onPressed: analysing
                          ? null
                          : () => setState(() => editing = !editing),
                      child: Text(editing ? '수정 마치기' : '모양 수정'),
                    ),
                  TextButton(
                    onPressed: analysing ? null : retake,
                    child: const Text('다시 촬영'),
                  ),
                ],
              ),
            ] else ...[
              PrimaryButton(
                label: error != null
                    ? (cameraDenied ? '설정 열기' : '카메라 다시 연결')
                    : busy
                    ? '촬영하고 있어요'
                    : '하늘 담기',
                icon: cameraDenied
                    ? Icons.settings_outlined
                    : Icons.camera_alt_outlined,
                onPressed: error != null
                    ? (cameraDenied
                          ? () => openDeviceSettings(context)
                          : openCamera)
                    : !busy && controller != null
                    ? takePhoto
                    : null,
              ),
              const SizedBox(height: 12),
              const Text(
                '촬영할 때마다 4단계 난이도 중 하나가 정해져요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: mutedInk),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              '사진은 보관하지 않고 구름 모양만 남겨요.\n모든 과정은 기기 안에서 이루어져요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.7, color: mutedInk),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SelectionPainter extends CustomPainter {
  _SelectionPainter(this.cells);
  final Set<int> cells;
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / cloudGridSide;
    for (var i = 0; i < cloudGridSide * cloudGridSide; i++) {
      final rect = Rect.fromLTWH(
        i % cloudGridSide * unit,
        i ~/ cloudGridSide * unit,
        unit,
        unit,
      );
      if (cells.contains(i)) {
        canvas.drawRect(rect, Paint()..color = accent.withValues(alpha: .24));
      } else {
        canvas.drawRect(
          rect,
          Paint()..color = Colors.black.withValues(alpha: .12),
        );
      }
      canvas.drawRect(
        rect,
        Paint()
          ..color = cells.contains(i)
              ? accent
              : Colors.white.withValues(alpha: .4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6,
      );
    }
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) =>
      !setEquals(cells, oldDelegate.cells);
}
