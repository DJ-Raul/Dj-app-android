// lib/features/decks/deck_view.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio/deck.dart';
import '../pads/pad_grid_view.dart';
import 'jog_wheel_widget.dart';

class DeckView extends StatelessWidget {
  final DeckId deckId;
  const DeckView({super.key, required this.deckId});

  Color get deckColor => deckId == DeckId.a
      ? const Color(0xFF00D4FF)
      : const Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckState>();

    return Container(
      color: const Color(0xFF0D0D15),
      child: Column(
        children: [
          // ── Track Info ────────────────────────
          _TrackInfo(deck: deck, deckColor: deckColor),

          // ── Waveform ──────────────────────────
          _WaveformDisplay(deck: deck, deckColor: deckColor),

          // ── BPM + Pitch ───────────────────────
          _BpmBar(deck: deck, deckColor: deckColor),

          // ── Jog Wheel + Controls ──────────────
          Expanded(
            child: Row(
              children: [
                // Left controls
                _LeftControls(deck: deck, deckColor: deckColor),

                // Jog Wheel (center)
                Expanded(
                  child: Center(
                    child: JogWheelWidget(
                      deck: deck,
                      color: deckColor,
                    ),
                  ),
                ),

                // Right controls
                _RightControls(deck: deck, deckColor: deckColor),
              ],
            ),
          ),

          // ── Pads ──────────────────────────────
          PadGridView(deck: deck, deckColor: deckColor),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Track Info
// ─────────────────────────────────────────────
class _TrackInfo extends StatelessWidget {
  final DeckState deck;
  final Color deckColor;
  const _TrackInfo({required this.deck, required this.deckColor});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: deckColor.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  deck.trackTitle ?? 'No Track Loaded',
                  style: TextStyle(
                    color: deck.trackTitle != null ? Colors.white : Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (deck.trackArtist != null)
                  Text(deck.trackArtist!,
                      style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          // Time display
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDuration(deck.position),
                style: TextStyle(
                  color: deckColor,
                  fontSize: 14,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '-${_formatDuration(deck.remaining)}',
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Waveform Display
// ─────────────────────────────────────────────
class _WaveformDisplay extends StatelessWidget {
  final DeckState deck;
  final Color deckColor;
  const _WaveformDisplay({required this.deck, required this.deckColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) {
        final box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(d.globalPosition);
        final progress = localPos.dx / box.size.width;
        deck.seekToProgress(progress.clamp(0.0, 1.0));
      },
      child: Container(
        height: 60,
        color: const Color(0xFF08080F),
        child: CustomPaint(
          painter: _WaveformPainter(
            progress: deck.waveformProgress,
            color: deckColor,
            isPlaying: deck.playing,
          ),
          child: Stack(
            children: [
              // Hot cue markers
              ...deck.hotCues.asMap().entries.where((e) => e.value != null).map((e) {
                final cue = e.value!;
                final pos = deck.duration.inMilliseconds > 0
                    ? cue.position.inMilliseconds / deck.duration.inMilliseconds
                    : 0.0;
                return Positioned(
                  left: pos * (MediaQuery.of(context).size.width / 2 - 70),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: Color(cue.color),
                    child: Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          color: Color(cue.color),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(fontSize: 8, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isPlaying;

  _WaveformPainter({
    required this.progress,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintPlayed = Paint()..color = color.withOpacity(0.8);
    final paintFuture = Paint()..color = color.withOpacity(0.25);
    final paintCenter = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1;

    final rng = math.Random(42); // fixed seed for consistent fake waveform
    final barWidth = 2.0;
    final gap = 1.0;
    final totalBars = (size.width / (barWidth + gap)).floor();
    final playedBars = (progress * totalBars).floor();

    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + gap);
      final height = (rng.nextDouble() * 0.7 + 0.1) * size.height;
      final top = (size.height - height) / 2;
      final paint = i < playedBars ? paintPlayed : paintFuture;

      canvas.drawRect(
        Rect.fromLTWH(x, top, barWidth, height),
        paint,
      );
    }

    // Playhead
    final px = progress * size.width;
    canvas.drawLine(Offset(px, 0), Offset(px, size.height), paintCenter);
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.isPlaying != isPlaying;
}

// ─────────────────────────────────────────────
// BPM Bar
// ─────────────────────────────────────────────
class _BpmBar extends StatelessWidget {
  final DeckState deck;
  final Color deckColor;
  const _BpmBar({required this.deck, required this.deckColor});

  @override
  Widget build(BuildContext context) {
    final pitchPct = (deck.pitch * 100).toStringAsFixed(1);
    final sign = deck.pitch >= 0 ? '+' : '';

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF0A0A12),
      child: Row(
        children: [
          Text(
            '${deck.bpm.toStringAsFixed(1)} BPM',
            style: TextStyle(
              color: deckColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$sign$pitchPct%',
            style: TextStyle(
              color: deck.pitch.abs() > 0.01
                  ? Colors.orange
                  : Colors.white38,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          // Status badges
          if (deck.sync)
            _Badge('SYNC', Colors.cyan),
          if (deck.slip)
            _Badge('SLIP', Colors.purple),
          if (deck.vinyl)
            _Badge('VINYL', Colors.orange),
          if (deck.quantize)
            _Badge('QUANT', Colors.green),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Left Controls (Loop + toggles)
// ─────────────────────────────────────────────
class _LeftControls extends StatelessWidget {
  final DeckState deck;
  final Color deckColor;
  const _LeftControls({required this.deck, required this.deckColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _DeckButton(
            label: 'LOOP\nIN',
            color: Colors.green,
            onTap: deck.setLoopIn,
          ),
          _DeckButton(
            label: 'LOOP\nOUT',
            color: Colors.red,
            onTap: deck.setLoopOut,
          ),
          _DeckButton(
            label: 'LOOP',
            color: deck.loop?.active == true ? Colors.green : Colors.white38,
            onTap: deck.toggleLoop,
          ),
          _DeckButton(
            label: 'VINYL',
            color: deck.vinyl ? Colors.orange : Colors.white38,
            onTap: deck.toggleVinyl,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Right Controls (Transport)
// ─────────────────────────────────────────────
class _RightControls extends StatelessWidget {
  final DeckState deck;
  final Color deckColor;
  const _RightControls({required this.deck, required this.deckColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _DeckButton(
            label: 'SYNC',
            color: deck.sync ? Colors.cyan : Colors.white38,
            onTap: deck.toggleSync,
          ),
          _DeckButton(
            label: 'CUE',
            color: Colors.amber,
            onTap: deck.cue,
          ),
          GestureDetector(
            onTap: deck.togglePlay,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: deck.playing
                    ? deckColor.withOpacity(0.3)
                    : Colors.white10,
                border: Border.all(
                  color: deck.playing ? deckColor : Colors.white24,
                  width: 2,
                ),
              ),
              child: Icon(
                deck.playing ? Icons.pause : Icons.play_arrow,
                color: deck.playing ? deckColor : Colors.white54,
                size: 24,
              ),
            ),
          ),
          _DeckButton(
            label: 'PFL',
            color: deck.pfL ? Colors.green : Colors.white38,
            onTap: deck.togglePfl,
          ),
        ],
      ),
    );
  }
}

class _DeckButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DeckButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
