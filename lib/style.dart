import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game.dart';
import 'sky_geometry.dart';

const ink = Color(0xFF183D62);
const mutedInk = Color(0xFF55748C);
const accent = Color(0xFFD47D58);
const paper = Color(0xFFF7F9F8);

class SkyBackground extends StatefulWidget {
  const SkyBackground({
    super.key,
    required this.child,
    this.view,
    this.zoom = 1,
  });
  final Widget child;
  final SkyView? view;
  final double zoom;
  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground> {
  ui.FragmentShader? shader;
  ui.Image? texture;

  @override
  void initState() {
    super.initState();
    if (widget.view != null) loadSky();
  }

  Future<void> loadSky() async {
    ui.Image? decoded;
    ui.FragmentShader? loaded;
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/sky.frag');
      final bytes = await rootBundle.load('assets/sky.png');
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      try {
        decoded = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
      loaded = program.fragmentShader()..setImageSampler(0, decoded);
      if (!mounted) {
        loaded.dispose();
        decoded.dispose();
        return;
      }
      setState(() {
        shader = loaded;
        texture = decoded;
      });
    } catch (error) {
      loaded?.dispose();
      decoded?.dispose();
      // The static sky remains available if a GPU cannot compile the effect.
      debugPrint('Sky background could not load: $error');
    }
  }

  @override
  void dispose() {
    shader?.dispose();
    texture?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (shader != null && widget.view != null)
        CustomPaint(
          key: const ValueKey('directional-sky-background'),
          painter: SkyDomePainter(shader!, widget.view!, widget.zoom),
        )
      else
        Image.asset(
          'assets/sky.png',
          fit: BoxFit.cover,
          alignment: const Alignment(.05, 0),
        ),
      ColoredBox(color: const Color(0xFFD9EBF7).withValues(alpha: .52)),
      widget.child,
    ],
  );
}

class SkyDomePainter extends CustomPainter {
  SkyDomePainter(this.shader, this.view, this.zoom);
  final ui.FragmentShader shader;
  final SkyView view;
  final double zoom;
  @override
  void paint(Canvas canvas, Size size) {
    final values = [
      size.width,
      size.height,
      SkyView.focal(size.width) * zoom,
      view.right.x,
      view.right.y,
      view.right.z,
      view.up.x,
      view.up.y,
      view.up.z,
      view.forward.x,
      view.forward.y,
      view.forward.z,
    ];
    for (var i = 0; i < values.length; i++) {
      shader.setFloat(i, values[i]);
    }
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(SkyDomePainter old) =>
      old.view != view || old.zoom != zoom;
}

class CloudArtwork extends StatelessWidget {
  const CloudArtwork({
    super.key,
    required this.shape,
    this.selected = false,
    this.opacity = 1,
  });
  final CloudShape shape;
  final bool selected;
  final double opacity;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity,
    child: AspectRatio(
      aspectRatio: shape.columns / shape.rows,
      child: CustomPaint(painter: CloudPainter(shape, selected)),
    ),
  );
}

/// The pixel geometry is the actual won board, not an illustrative cloud icon.
class CloudPainter extends CustomPainter {
  CloudPainter(this.shape, this.selected);
  final CloudShape shape;
  final bool selected;
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / shape.columns;
    final silhouette = Path();
    for (final i in shape.cells) {
      silhouette.addRect(
        Rect.fromLTWH(
          (i % shape.columns) * unit,
          (i ~/ shape.columns) * unit,
          unit,
          unit,
        ),
      );
    }
    canvas.drawShadow(silhouette, ink.withValues(alpha: .12), 10, false);
    canvas.drawPath(silhouette, Paint()..color = const Color(0xFFF9FCFF));
    final grid = Paint()
      ..color = const Color(0xFFD9E7F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6;
    final border = Paint()
      ..color = selected ? accent : const Color(0xFFBBCFDE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 1.7 : .9;
    for (final i in shape.cells) {
      final x = i % shape.columns, y = i ~/ shape.columns;
      final rect = Rect.fromLTWH(x * unit, y * unit, unit, unit);
      canvas.drawRect(rect, grid);
      if (x == 0 || !shape.cells.contains(i - 1)) {
        canvas.drawLine(rect.topLeft, rect.bottomLeft, border);
      }
      if (x == shape.columns - 1 || !shape.cells.contains(i + 1)) {
        canvas.drawLine(rect.topRight, rect.bottomRight, border);
      }
      if (!shape.cells.contains(i - shape.columns)) {
        canvas.drawLine(rect.topLeft, rect.topRight, border);
      }
      if (!shape.cells.contains(i + shape.columns)) {
        canvas.drawLine(rect.bottomLeft, rect.bottomRight, border);
      }
    }
  }

  @override
  bool shouldRepaint(CloudPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.selected != selected;
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 21),
    label: Text(label),
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      backgroundColor: ink,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
    ),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 2.6,
      color: mutedInk,
    ),
  );
}
