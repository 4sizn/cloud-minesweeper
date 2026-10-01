import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cloud_analysis.dart';
import 'app_info.dart';
import 'game.dart';
import 'l10n/app_localizations.dart';
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
  CloudFinding? finding;
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
        final l = AppLocalizations.of(context);
        error = cameraDenied ? l.cameraDenied : l.cameraFailed;
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
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Not on inactive: the first camera permission prompt makes the app
      // inactive while initialize() is still waiting for the answer.
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
          error = AppLocalizations.of(context).shotFailed;
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
      finding = null;
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
        finding = result.finding;
        analysing = false;
        editing = !result.playable;
      });
    } catch (_) {
      if (!mounted || generation != analysisGeneration) return;
      setState(() {
        analysing = false;
        analysisFailed = true;
        editing = true;
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context).needConnectedCells(minimumCloudCells),
          ),
        ),
      );
      return;
    }
    Navigator.pop<CloudDraft>(context, (
      shape: CloudShape(columns, rows, cluster).trimmed,
      name: AppLocalizations.of(context).defaultCloudName,
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

  String findingMessage(AppLocalizations l) => switch (finding) {
    CloudFinding.tooDark => l.findingTooDark,
    CloudFinding.noSky => l.findingNoSky,
    CloudFinding.noEdge => l.findingNoEdge,
    CloudFinding.none => l.findingNone,
    CloudFinding.small => l.findingSmall,
    CloudFinding.found => l.findingFound,
    null => analysisFailed ? l.analysisFailed : l.analysing,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final level = l.difficulty(difficulty.name);
    return Scaffold(
      backgroundColor: paper,
      appBar: AppBar(
        title: Text(photo == null ? l.captureTitle : l.foundTitle),
        backgroundColor: paper,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                photo == null
                    ? l.captureHeading
                    : analysing
                    ? l.searchingHeading
                    : l.playHeading,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                photo == null ? l.captureHint : findingMessage(l),
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
                          onScaleUpdate: (d) =>
                              setZoom(pinchStartZoom * d.scale),
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
                            l.zoomSemantics(v.toStringAsFixed(1)),
                        onChanged: setZoom,
                      ),
                    ),
                    const Icon(Icons.zoom_in, color: mutedInk),
                  ],
                ),
              const SizedBox(height: 24),
              if (photo != null) ...[
                Semantics(
                  label: l.difficultySemantics(difficulty.index + 1, level),
                  child: Chip(
                    avatar: const Icon(Icons.bar_chart_rounded, size: 18),
                    label: Text(l.difficultyBadge(difficulty.index + 1, level)),
                  ),
                ),
                const SizedBox(height: 12),
                if (editing && !analysing) ...[
                  Text(
                    l.selectionCount(selected.length, minimumCloudCells),
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
                        child: Text(l.restoreAuto),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          selected.clear();
                          manuallyEdited = true;
                        }),
                        child: Text(l.clearAll),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      l.paintHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: mutedInk),
                    ),
                  ),
                ],
                PrimaryButton(
                  label: l.startWithCloud,
                  onPressed: canStart ? finish : null,
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    if (analysisFailed)
                      TextButton(
                        onPressed: analysing
                            ? null
                            : () => processPhoto(
                                originalPhoto!,
                                newCapture: false,
                              ),
                        child: Text(l.reanalyse),
                      )
                    else
                      TextButton(
                        onPressed: analysing
                            ? null
                            : () => setState(() => editing = !editing),
                        child: Text(editing ? l.finishEditing : l.editShape),
                      ),
                    TextButton(
                      onPressed: analysing ? null : retake,
                      child: Text(l.retake),
                    ),
                  ],
                ),
              ] else ...[
                PrimaryButton(
                  label: error != null
                      ? (cameraDenied ? l.openSettings : l.reconnectCamera)
                      : busy
                      ? l.capturing
                      : l.captureSky,
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
                Text(
                  l.difficultyRollHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: mutedInk),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                l.privacyNote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  color: mutedInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
