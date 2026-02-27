// lib/features/mixer/mixer_view.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio/mixer.dart';
import '../../core/audio/deck.dart';
import '../../core/audio/audio_engine.dart';

class MixerView extends StatelessWidget {
  const MixerView({super.key});

  @override
  Widget build(BuildContext context) {
    final mixer = context.watch<MixerState>();
    final engine = context.read<AudioEngine>();

    return Container(
      color: const Color(0xFF0D0D1A),
      child: Column(
        children: [
          // ── EQ Deck A ─────────────────────
          _EqSection(deckId: DeckId.a, color: const Color(0xFF00D4FF)),

          // ── VU Meters ─────────────────────
          _VuMeters(mixer: mixer),

          // ── Crossfader ────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                const Text('CROSSFADER',
                    style: TextStyle(color: Colors.white38, fontSize: 7)),
                const SizedBox(height: 4),
                _CrossfaderWidget(
                  value: mixer.crossfader,
                  onChanged: mixer.setCrossfader,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('A', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 9)),
                    Text('B', style: TextStyle(color: Color(0xFFFF6B35), fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),

          // ── Master Volume ──────────────────
          _KnobRow(
            label: 'MASTER',
            value: mixer.masterVolume,
            onChanged: mixer.setMasterVolume,
            color: Colors.white70,
          ),
          _KnobRow(
            label: 'PHONES',
            value: mixer.headphonesVolume,
            onChanged: mixer.setHeadphonesVolume,
            color: Colors.amber,
          ),

          // ── EQ Deck B ─────────────────────
          _EqSection(deckId: DeckId.b, color: const Color(0xFFFF6B35)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EQ Section for one deck
// ─────────────────────────────────────────────
class _EqSection extends StatelessWidget {
  final DeckId deckId;
  final Color color;
  const _EqSection({required this.deckId, required this.color});

  @override
  Widget build(BuildContext context) {
    final engine = context.read<AudioEngine>();
    final deck = deckId == DeckId.a ? engine.deckA : engine.deckB;

    return ListenableBuilder(
      listenable: deck,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Text(deckId == DeckId.a ? 'DECK A' : 'DECK B',
                style: TextStyle(color: color, fontSize: 8,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MiniKnob(label: 'HI', value: deck.eqHigh,
                    color: color, onChanged: deck.setEqHigh),
                _MiniKnob(label: 'MID', value: deck.eqMid,
                    color: color, onChanged: deck.setEqMid),
                _MiniKnob(label: 'LO', value: deck.eqLow,
                    color: color, onChanged: deck.setEqLow),
              ],
            ),
            const SizedBox(height: 4),
            // Volume fader
            _VerticalFader(
              value: deck.volume,
              color: color,
              onChanged: deck.setVolume,
              height: 60,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VU Meters
// ─────────────────────────────────────────────
class _VuMeters extends StatelessWidget {
  final MixerState mixer;
  const _VuMeters({required this.mixer});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _VuBar(value: mixer.masterVuL, color: Colors.green),
          const SizedBox(width: 4),
          _VuBar(value: mixer.masterVuR, color: Colors.green),
        ],
      ),
    );
  }
}

class _VuBar extends StatelessWidget {
  final double value;
  final Color color;
  const _VuBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.green, Colors.yellow, Colors.red],
                stops: const [0.0, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Crossfader
// ─────────────────────────────────────────────
class _CrossfaderWidget extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _CrossfaderWidget({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(d.globalPosition);
        onChanged((local.dx / box.size.width).clamp(0.0, 1.0));
      },
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white12),
        ),
        child: Stack(
          children: [
            // Track
            Center(
              child: Container(
                height: 2,
                color: Colors.white12,
              ),
            ),
            // Thumb
            Positioned(
              left: value * (120 - 20),
              top: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A4E),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Mini Knob
// ─────────────────────────────────────────────
class _MiniKnob extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  const _MiniKnob({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (d) {
        onChanged((value - d.delta.dy / 100).clamp(0.0, 1.0));
      },
      child: Column(
        children: [
          CustomPaint(
            size: const Size(24, 24),
            painter: _KnobPainter(value: value, color: color),
          ),
          Text(label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 7)),
        ],
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  final Color color;
  const _KnobPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    canvas.drawCircle(center, radius,
        Paint()..color = const Color(0xFF1A1A2E));
    canvas.drawCircle(center, radius,
        Paint()
          ..color = color.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Value indicator
    final angle = -2.356 + value * 4.712; // -135° to +135°
    final end = center + Offset(
      (radius - 3) * math.cos(angle),
      (radius - 3) * math.sin(angle),
    );
    canvas.drawLine(center, end,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_KnobPainter old) => old.value != value;
}

// ─────────────────────────────────────────────
// Vertical Fader
// ─────────────────────────────────────────────
class _VerticalFader extends StatelessWidget {
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  final double height;
  const _VerticalFader({
    required this.value,
    required this.color,
    required this.onChanged,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (d) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(d.globalPosition);
        onChanged(1.0 - (local.dy / box.size.height).clamp(0.0, 1.0));
      },
      child: SizedBox(
        height: height,
        width: 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 2, color: Colors.white12),
            Positioned(
              bottom: value * (height - 12),
              child: Container(
                width: 20,
                height: 12,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  border: Border.all(color: color.withOpacity(0.7)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnobRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  const _KnobRow({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.white38, fontSize: 7)),
          _MiniKnob(
            label: '',
            value: value,
            color: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
