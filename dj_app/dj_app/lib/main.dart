// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/midi/midi_manager.dart';
import 'core/audio/audio_engine.dart';
import 'core/audio/mixer.dart';
import 'core/audio/deck.dart';
import 'features/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Force landscape for DJ app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Hide status bar for immersive mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  runApp(const DJApp());
}

class DJApp extends StatelessWidget {
  const DJApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MidiManager()),
        ChangeNotifierProxyProvider<MidiManager, AudioEngine>(
          create: (ctx) => AudioEngine(midi: ctx.read<MidiManager>()),
          update: (ctx, midi, prev) => prev ?? AudioEngine(midi: midi),
        ),
        ChangeNotifierProxyProvider<AudioEngine, DeckState>(
          create: (ctx) => ctx.read<AudioEngine>().deckA,
          update: (ctx, engine, prev) => engine.deckA,
        ),
        ChangeNotifierProxyProvider<AudioEngine, MixerState>(
          create: (ctx) => ctx.read<AudioEngine>().mixer,
          update: (ctx, engine, prev) => engine.mixer,
        ),
      ],
      child: MaterialApp(
        title: 'DJ Controller',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A0A0F),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D4FF),
            secondary: Color(0xFFFF6B35),
            surface: Color(0xFF12121A),
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}
