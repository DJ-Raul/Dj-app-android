// lib/features/decks/jog_wheel_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/audio/deck.dart';

class JogWheelWidget extends StatefulWidget {
  final DeckState deck;
  final Color color;

  const JogWheelWidget({
    super.key,
    required this.deck,
    required this.color,
  });

  @override
  State<JogWheelWidget> createState() => _JogWheelWidgetState();
}

class _JogWheelWidgetState extends State<JogWheelWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  double _rotation = 0.0;
  Offset? _lastDragPos;
  bool _touching = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Spin when playing
    _spinController.addListener(() {
      if (widget.deck.playing && !_touching) {
        setState(() {
          _rotation = _spinController.value * 2 * math.pi;
        });
      }
    });

    widget.deck.addListener(_onDeckChanged);
  }

  void _onDeckChanged() {
    if (widget.deck.playing) {
      _spinController.repeat();
    } else {
      _spinController.stop();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    widget.deck.removeListener(_onDeckChanged);
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    _touching = true;
    _lastDragPos = d.localPosition;
    widget.deck.setJogTouched(true);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_lastDragPos == null) return;
    final center = const Offset(90, 90); // half of size
    final prev = _lastDragPos! - center;
    final curr = d.localPosition - center;

    // Calculate angle difference
    final prevAngle = math.atan2(prev.dy, prev.dx);
    final currAngle = math.atan2(curr.dy, curr.dx);
    double diff = currAngle - prevAngle;

    // Normalize to -pi..pi
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;

    final direction = diff > 0 ? 1 : -1;
    final speed = (diff.abs() * 20).clamp(1, 24).round();

    widget.deck.jogTurn(direction, speed);

    setState(() {
      _rotation += diff;
    });
    _lastDragPos = d.localPosition;
  }

  void _onPanEnd(DragEndDetails d) {
    _touching = false;
    _lastDragPos = null;
    widget.deck.setJogTouched(false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        width: 180,
        height: 180,
        child: CustomPaint(
          painter: _JogWheelPainter(
            rotation: _rotation,
            color: widget.color,
            isPlaying: widget.deck.playing,
            isTouching: _touching,
            progress: widget.deck.waveformProgress,
          ),
        ),
      ),
    );
  }
}

class _JogWheelPainter extends CustomPainter {
  final double rotation;
  final Color color;
  final bool isPlaying;
  final bool isTouching;
  final double progress;

  _JogWheelPainter({
    required this.rotation,
    required this.color,
    required this.isPlaying,
    required this.isTouching,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = outerR * 0.55;
    final platR = innerR * 0.9;

    // ── Outer ring ──────────────────────────
    final ringPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerR, ringPaint);

    // Outer ring border
    final borderPaint = Paint()
      ..color = isTouching ? color : color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, outerR - 1, borderPaint);

    // ── Tick marks on outer ring ──────────
    final tickPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 24; i++) {
      final angle = rotation + (i / 24) * 2 * math.pi;
      final isMajor = i % 4 == 0;
      final startR = outerR - (isMajor ? 16 : 10);
      final endR = outerR - 3;
      canvas.drawLine(
        center + Offset(math.cos(angle) * startR, math.sin(angle) * startR),
        center + Offset(math.cos(angle) * endR, math.sin(angle) * endR),
        tickPaint,
      );
    }

    // ── Progress arc ──────────────────────
    final progressPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerR + 8),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      progressPaint,
    );

    // ── Platter (inner circle) ─────────────
    final platterPaint = Paint()
      ..color = isPlaying
          ? const Color(0xFF181828)
          : const Color(0xFF111118)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerR, platterPaint);

    // Platter glow when playing
    if (isPlaying) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(center, innerR, glowPaint);
    }

    // ── Platter stripes (rotating) ─────────
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final stripePaint = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 1;
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi;
      canvas.drawLine(
        Offset(math.cos(angle) * -platR, math.sin(angle) * -platR),
        Offset(math.cos(angle) * platR, math.sin(angle) * platR),
        stripePaint,
      );
    }
    canvas.restore();

    // ── Center label ──────────────────────
    final textSpan = TextSpan(
      text: isPlaying ? '▶' : '⏸',
      style: TextStyle(
        color: color.withOpacity(0.6),
        fontSize: 18,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_JogWheelPainter old) =>
      old.rotation != rotation ||
      old.isPlaying != isPlaying ||
      old.isTouching != isTouching ||
      old.progress != progress;
}
