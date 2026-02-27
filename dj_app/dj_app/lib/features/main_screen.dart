// lib/features/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/midi/midi_manager.dart';
import '../core/audio/audio_engine.dart';
import '../core/audio/deck.dart';
import '../core/audio/mixer.dart';
import 'decks/deck_view.dart';
import 'mixer/mixer_view.dart';
import 'browser/music_browser_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showBrowser = false;
  DeckId _browserTargetDeck = DeckId.a;

  @override
  void initState() {
    super.initState();
    _autoConnect();
  }

  Future<void> _autoConnect() async {
    final midi = context.read<MidiManager>();
    await midi.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // ── Main DJ Layout ─────────────────────
          Column(
            children: [
              // Top bar
              _TopBar(onBrowserToggle: () {
                setState(() => _showBrowser = !_showBrowser);
              }),

              // Main area: Deck A | Mixer | Deck B
              Expanded(
                child: Row(
                  children: [
                    // Deck A
                    Expanded(
                      flex: 5,
                      child: ChangeNotifierProvider.value(
                        value: context.read<AudioEngine>().deckA,
                        child: DeckView(deckId: DeckId.a),
                      ),
                    ),

                    // Center Mixer
                    const SizedBox(
                      width: 140,
                      child: MixerView(),
                    ),

                    // Deck B
                    Expanded(
                      flex: 5,
                      child: ChangeNotifierProvider.value(
                        value: context.read<AudioEngine>().deckB,
                        child: DeckView(deckId: DeckId.b),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Browser Overlay ────────────────────
          if (_showBrowser)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showBrowser = false),
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: GestureDetector(
                        onTap: () {}, // prevent close on browser tap
                        child: MusicBrowserView(
                          targetDeck: _browserTargetDeck,
                          onClose: () => setState(() => _showBrowser = false),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBrowserToggle;

  const _TopBar({required this.onBrowserToggle});

  @override
  Widget build(BuildContext context) {
    final midi = context.watch<MidiManager>();

    return Container(
      height: 36,
      color: const Color(0xFF12121A),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo
          const Text('DJ CONTROLLER',
              style: TextStyle(
                color: Color(0xFF00D4FF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              )),

          const Spacer(),

          // MIDI connection status
          GestureDetector(
            onTap: () async {
              if (!midi.connected) {
                await midi.connect();
              }
            },
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: midi.connected
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFF3333),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  midi.connected
                      ? 'Inpulse 300 Connected'
                      : 'Tap to connect controller',
                  style: TextStyle(
                    color: midi.connected
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFF3333),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Browser button
          IconButton(
            icon: const Icon(Icons.library_music, size: 18),
            color: const Color(0xFF00D4FF),
            onPressed: onBrowserToggle,
            tooltip: 'Music Browser',
          ),
        ],
      ),
    );
  }
}
