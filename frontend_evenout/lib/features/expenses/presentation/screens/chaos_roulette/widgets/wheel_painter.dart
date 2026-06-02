import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../chaos_roulette_screen.dart';

class WheelPainter extends CustomPainter {
  final List<ChaosParticipant> segments;
  final Color Function(String id) colorFor;

  WheelPainter({required this.segments, required this.colorFor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (segments.isEmpty) {
      final paint = Paint()..color = Colors.grey.shade300;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final seg = (2 * math.pi) / segments.length;
    // Segment 0 starts at the top (−π/2) and sweeps clockwise.
    final startBase = -math.pi / 2;

    for (var i = 0; i < segments.length; i++) {
      final start = startBase + i * seg;
      final paint = Paint()
        ..color = colorFor(segments[i].id)
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, start, seg, true, paint);

      // Divider lines
      final divider = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, start, seg, true, divider);

      // Label, rotated to sit along the radius at the segment centre.
      final mid = start + seg / 2;
      final textPainter = TextPainter(
        text: TextSpan(
          text: _shorten(segments[i].name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * 0.8);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(mid);
      // Move outward along the segment's bisector, then draw upright-ish text.
      canvas.translate(radius * 0.52, 0);
      canvas.rotate(math.pi / 2);
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    // Outer ring
    final ring = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, ring);
  }

  String _shorten(String name) {
    final first = name.trim().split(RegExp(r'\s+')).first;
    if (first.length <= 8) return first;
    return '${first.substring(0, 7)}…';
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) =>
      oldDelegate.segments != segments;
}
