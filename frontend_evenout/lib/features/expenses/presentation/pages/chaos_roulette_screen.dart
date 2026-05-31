import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/expenses_repository.dart';

/// A participant fed into the chaos wheel.
class ChaosParticipant {
  final String id;
  final String name;
  const ChaosParticipant({required this.id, required this.name});
}

/// The outcome of a chaos spin: the elimination order and each person's share.
class ChaosResult {
  final List<String> orderedIds; // elimination sequence (0 = first out = pays most)
  final Map<String, double> shares; // user id -> amount owed
  const ChaosResult({required this.orderedIds, required this.shares});
}

/// "Chaos Roulette" split (PRD Feature 8). Spin the wheel to eliminate
/// participants one by one; each elimination locks in a cascading 50% share of
/// the bill. The first person eliminated pays the most, the survivor the least.
class ChaosRouletteScreen extends StatefulWidget {
  final double total;
  final List<ChaosParticipant> participants;

  const ChaosRouletteScreen({
    super.key,
    required this.total,
    required this.participants,
  });

  @override
  State<ChaosRouletteScreen> createState() => _ChaosRouletteScreenState();
}

class _ChaosRouletteScreenState extends State<ChaosRouletteScreen>
    with SingleTickerProviderStateMixin {
  static const List<Color> _palette = [
    Color(0xFF60BB46),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFFDD835),
    Color(0xFF6D4C41),
  ];

  late final AnimationController _controller;
  Animation<double>? _animation;
  double _rotation = 0.0;
  final math.Random _random = math.Random();

  late final List<double> _shares; // index = elimination position
  late List<ChaosParticipant> _remaining;
  final List<ChaosParticipant> _order = []; // eliminated in sequence
  final Map<String, double> _assigned = {};
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _shares = computeChaosShares(widget.total, widget.participants.length);
    _remaining = List.of(widget.participants);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addListener(() {
        final anim = _animation;
        if (anim != null) setState(() => _rotation = anim.value);
      });

    // A single participant has nothing to spin for — assign immediately.
    if (widget.participants.length < 2) {
      for (var i = 0; i < widget.participants.length; i++) {
        _order.add(widget.participants[i]);
        _assigned[widget.participants[i].id] = _shares[i];
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDone => _remaining.length <= 1 && _assigned.isNotEmpty ||
      widget.participants.length < 2;

  Color _colorFor(String id) {
    final index = widget.participants.indexWhere((p) => p.id == id);
    return _palette[(index < 0 ? 0 : index) % _palette.length];
  }

  void _spin() {
    if (_spinning || _remaining.length <= 1) return;

    final segCount = _remaining.length;
    final seg = (2 * math.pi) / segCount;
    final picked = _random.nextInt(segCount);

    // Land the picked segment's centre under the top pointer, after a few
    // full turns for drama. The painter draws segment 0 starting at the top
    // (−π/2) and sweeping clockwise, so aligning means rotating the wheel by
    // the negative of that segment's centre angle.
    final desired = ((-(picked * seg + seg / 2)) % (2 * math.pi) + 2 * math.pi) %
        (2 * math.pi);
    const baseTurns = 5;
    final target = baseTurns * 2 * math.pi + desired;

    _animation = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    setState(() => _spinning = true);
    _controller.forward(from: 0).whenComplete(() {
      setState(() {
        final eliminated = _remaining.removeAt(picked);
        final position = _order.length;
        _order.add(eliminated);
        _assigned[eliminated.id] = _shares[position];

        // When one survivor remains, they automatically take the final share.
        if (_remaining.length == 1) {
          final last = _remaining.removeAt(0);
          _order.add(last);
          _assigned[last.id] = _shares[_order.length - 1];
        }

        _rotation = 0; // reshuffle for the next, smaller wheel
        _spinning = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1B1B3A);
    final subtextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '🎲 Chaos Roulette',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Text(
                _isDone
                    ? 'The dice have spoken. Here is who pays what.'
                    : 'Spin to eliminate players. Each one out locks in a share '
                        '— first out pays the most!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subtextColor, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),

            // The wheel
            Expanded(
              flex: 5,
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: _rotation,
                        child: CustomPaint(
                          size: const Size(260, 260),
                          painter: _WheelPainter(
                            segments: _remaining,
                            colorFor: _colorFor,
                          ),
                        ),
                      ),
                      // Hub
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _isDone ? '✅' : '🎲',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      // Top pointer
                      Positioned(
                        top: -2,
                        child: Icon(Icons.arrow_drop_down_rounded,
                            size: 48, color: AppColors.owe),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Results list
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _order.isEmpty
                    ? Center(
                        child: Text(
                          'No one eliminated yet',
                          style: TextStyle(color: subtextColor, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _order.length,
                        itemBuilder: (context, index) {
                          final p = _order[index];
                          final amount = _assigned[p.id] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: _colorFor(p.id),
                                  child: Text('${index + 1}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(p.name,
                                      style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Text('Rs ${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        color: amount == 0
                                            ? AppColors.settle
                                            : textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Action button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDone ? AppColors.settle : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isDone
                      ? () => Navigator.pop(
                            context,
                            ChaosResult(
                              orderedIds: _order.map((p) => p.id).toList(),
                              shares: Map.of(_assigned),
                            ),
                          )
                      : (_spinning ? null : _spin),
                  icon: Icon(_isDone
                      ? Icons.check_circle_rounded
                      : Icons.casino_rounded),
                  label: Text(
                    _isDone
                        ? 'USE THIS SPLIT'
                        : (_spinning ? 'SPINNING…' : 'SPIN THE WHEEL'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<ChaosParticipant> segments;
  final Color Function(String id) colorFor;

  _WheelPainter({required this.segments, required this.colorFor});

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
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.segments != segments;
}
