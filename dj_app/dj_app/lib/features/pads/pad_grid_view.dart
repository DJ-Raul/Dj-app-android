// lib/features/pads/pad_grid_view.dart
import 'package:flutter/material.dart';
import '../../core/audio/deck.dart';
import '../../core/midi/inpulse_300_mapping.dart';

class PadGridView extends StatelessWidget {
  final DeckState deck;
  final Color deckColor;
  const PadGridView({super.key, required this.deck, required this.deckColor});

  static const List<Color> _padColors = [
    Color(0xFFFF2D55), // Red
    Color(0xFFFF9500), // Orange
    Color(0xFFFFCC00), // Yellow
    Color(0xFF4CD964), // Green
    Color(0xFF5AC8FA), // Light Blue
    Color(0xFF007AFF), // Blue
    Color(0xFF5856D6), // Purple
    Color(0xFFFF2D55), // Red again
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      color: const Color(0xFF09090F),
      child: Column(
        children: [
          // Mode tabs
          _ModeBar(deck: deck, deckColor: deckColor),
          // Pad grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: List.generate(8, (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _PadButton(
                      index: i,
                      deck: deck,
                      baseColor: _padColors[i],
                    ),
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  final DeckState deck;
  final Color deckColor;
  const _ModeBar({required this.deck, required this.deckColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        itemCount: Inpulse300Mapping.padModeNames.length,
        itemBuilder: (_, i) {
          final modeNum = i + 1;
          final isActive = deck.padMode == modeNum;
          return GestureDetector(
            onTap: () => deck.setPadMode(modeNum),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? deckColor.withOpacity(0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: isActive ? deckColor : Colors.white12,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                Inpulse300Mapping.padModeNames[i],
                style: TextStyle(
                  color: isActive ? deckColor : Colors.white38,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PadButton extends StatefulWidget {
  final int index;
  final DeckState deck;
  final Color baseColor;
  const _PadButton({required this.index, required this.deck, required this.baseColor});

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Color get _padColor {
    switch (widget.deck.padMode) {
      case 1: // Hot Cue
        final cue = widget.deck.hotCues[widget.index];
        return cue != null ? Color(cue.color) : Colors.white12;
      case 2: // Roll
        return Colors.purple.withOpacity(0.5 + widget.index * 0.05);
      case 4: // Sampler
        return Colors.green.withOpacity(0.6);
      case 8: // Beat Jump
        return Colors.orange.withOpacity(0.6);
      default:
        return widget.baseColor.withOpacity(0.5);
    }
  }

  String get _padLabel {
    switch (widget.deck.padMode) {
      case 1: // Hot Cue
        return widget.deck.hotCues[widget.index] != null
            ? 'CUE ${widget.index + 1}'
            : '+ CUE';
      case 2: // Roll
        final beats = [1/8, 1/4, 1/2, 1, 2, 4, 8, 16];
        final b = beats[widget.index];
        return b < 1 ? '${(b * 4).round()}/4' : '${b.round()}B';
      case 8: // Beat Jump
        final jumps = [-8, -4, -2, -1, 1, 2, 4, 8];
        final j = jumps[widget.index];
        return j > 0 ? '+$j' : '$j';
      default:
        return '${widget.index + 1}';
    }
  }

  void _onPress() {
    setState(() => _active = true);
    _press.forward();
    widget.deck.onPadPress(widget.index, false);
  }

  void _onRelease() {
    setState(() => _active = false);
    _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.deck,
      builder: (_, __) {
        final color = _padColor;
        return GestureDetector(
          onTapDown: (_) => _onPress(),
          onTapUp: (_) => _onRelease(),
          onTapCancel: _onRelease,
          child: AnimatedBuilder(
            animation: _press,
            builder: (_, __) => Transform.scale(
              scale: 1.0 - _press.value * 0.08,
              child: Container(
                decoration: BoxDecoration(
                  color: _active
                      ? color.withOpacity(0.9)
                      : color.withOpacity(0.3),
                  border: Border.all(
                    color: color.withOpacity(_active ? 1.0 : 0.5),
                    width: _active ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: _active ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    _padLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _active ? Colors.white : Colors.white60,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
