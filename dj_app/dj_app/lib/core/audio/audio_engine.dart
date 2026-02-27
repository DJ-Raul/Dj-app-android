// lib/core/audio/audio_engine.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../midi/midi_manager.dart';
import '../midi/midi_event_dispatcher.dart';
import '../midi/inpulse_300_mapping.dart';
import 'deck.dart';
import 'mixer.dart';

class AudioEngine extends ChangeNotifier {
  final MidiManager midi;
  final DeckState deckA = DeckState(DeckId.a);
  final DeckState deckB = DeckState(DeckId.b);
  final MixerState mixer = MixerState();

  final List<StreamSubscription> _subs = [];

  AudioEngine({required this.midi}) {
    _bindMidiEvents();
    _bindDeckFeedback();
  }

  // ─────────────────────────────────────────────
  // Bind MIDI events → deck/mixer actions
  // ─────────────────────────────────────────────
  void _bindMidiEvents() {
    final d = midi.dispatcher;

    _subs.add(d.events.listen(_handleEvent));
  }

  void _handleEvent(MidiEvent e) {
    final deck = e.deck == DeckId.a ? deckA : deckB;

    switch (e.type) {
      // ── Transport ─────────────────────────────
      case MidiEventType.play:
        if (e.pressed) deck.togglePlay();
        break;
      case MidiEventType.pause:
        break; // handled by play toggle
      case MidiEventType.cue:
        if (e.pressed) deck.cue();
        break;
      case MidiEventType.sync:
        if (e.pressed) deck.toggleSync();
        break;

      // ── Load ──────────────────────────────────
      case MidiEventType.load:
        if (e.pressed) {
          // Signal UI to show browser for this deck
          notifyListeners();
        }
        break;

      // ── Jog ───────────────────────────────────
      case MidiEventType.jogTouch:
        deck.setJogTouched(true);
        break;
      case MidiEventType.jogRelease:
        deck.setJogTouched(false);
        break;
      case MidiEventType.jogTurn:
      case MidiEventType.jogScratch:
        if (e.deck != DeckId.none) {
          deck.jogTurn(e.jogDirection, e.jogSpeed);
        }
        break;

      // ── Loop ──────────────────────────────────
      case MidiEventType.loopIn:
        if (e.pressed) deck.setLoopIn();
        break;
      case MidiEventType.loopOut:
        if (e.pressed) deck.setLoopOut();
        break;

      // ── Pads ──────────────────────────────────
      case MidiEventType.padPressed:
        deck.onPadPress(e.padIndex, e.shifted);
        _sendPadLed(e.deck, e.padMode, e.padIndex, true);
        break;
      case MidiEventType.padReleased:
        _sendPadLed(e.deck, e.padMode, e.padIndex, false);
        break;

      // ── Mode ──────────────────────────────────
      case MidiEventType.modeSelect:
        deck.setPadMode(e.padMode);
        _updateModeLeds(e.deck, e.padMode);
        break;

      // ── Mixer ─────────────────────────────────
      case MidiEventType.volume:
        if (e.deck != DeckId.none) deck.setVolume(e.value);
        break;
      case MidiEventType.filter:
        if (e.deck != DeckId.none) deck.setFilter(e.value);
        break;
      case MidiEventType.eqLow:
        if (e.deck != DeckId.none) deck.setEqLow(e.value);
        break;
      case MidiEventType.eqMid:
        if (e.deck != DeckId.none) deck.setEqMid(e.value);
        break;
      case MidiEventType.eqHigh:
        if (e.deck != DeckId.none) deck.setEqHigh(e.value);
        break;
      case MidiEventType.gain:
        if (e.deck != DeckId.none) deck.setGain(e.value);
        break;
      case MidiEventType.pitch:
        if (e.deck != DeckId.none) deck.setPitch(e.value);
        break;

      // ── Global ────────────────────────────────
      case MidiEventType.crossfader:
        mixer.setCrossfader(e.value);
        break;
      case MidiEventType.masterVolume:
        mixer.setMasterVolume(e.value);
        break;
      case MidiEventType.headphonesVolume:
        mixer.setHeadphonesVolume(e.value);
        break;
      case MidiEventType.browseEncoder:
        // Signal UI to navigate browser
        notifyListeners();
        break;

      // ── Toggles ───────────────────────────────
      case MidiEventType.slip:
        if (e.pressed) {
          deck.toggleSlip();
          _updateToggleLed(e.deck, e.deck == DeckId.a
              ? Inpulse300Mapping.SLIP_A : Inpulse300Mapping.SLIP_B,
              deck.slip);
        }
        break;
      case MidiEventType.vinyl:
        if (e.pressed) {
          deck.toggleVinyl();
          _updateToggleLed(e.deck, e.deck == DeckId.a
              ? Inpulse300Mapping.VINYL_A : Inpulse300Mapping.VINYL_B,
              deck.vinyl);
        }
        break;
      case MidiEventType.quantize:
        if (e.pressed) {
          deck.toggleQuantize();
          _updateToggleLed(e.deck, e.deck == DeckId.a
              ? Inpulse300Mapping.QUANTIZE_A : Inpulse300Mapping.QUANTIZE_B,
              deck.quantize);
        }
        break;
      case MidiEventType.pfl:
        if (e.pressed) deck.togglePfl();
        break;
      case MidiEventType.fxOn:
        if (e.pressed) deck.toggleFx();
        break;

      default:
        break;
    }
  }

  // ─────────────────────────────────────────────
  // LED Feedback
  // ─────────────────────────────────────────────
  void _sendPadLed(DeckId deck, int mode, int padIndex, bool on) {
    final int channel = deck == DeckId.a
        ? Inpulse300Mapping.NOTE_ON_PADS_A
        : Inpulse300Mapping.NOTE_ON_PADS_B;
    final int note = Inpulse300Mapping.padNote(mode, padIndex);
    midi.setLed(channel, note, on);
  }

  void _updateModeLeds(DeckId deck, int activeMode) {
    final int channel = deck == DeckId.a
        ? Inpulse300Mapping.NOTE_ON_DECK_A
        : Inpulse300Mapping.NOTE_ON_DECK_B;
    final int baseNote = deck == DeckId.a
        ? Inpulse300Mapping.MODE1_A
        : Inpulse300Mapping.MODE1_B;

    for (int i = 0; i < 8; i++) {
      midi.setLed(channel, baseNote + i, i + 1 == activeMode);
    }
  }

  void _updateToggleLed(DeckId deck, int note, bool on) {
    final int channel = deck == DeckId.a
        ? Inpulse300Mapping.NOTE_ON_DECK_A
        : Inpulse300Mapping.NOTE_ON_DECK_B;
    midi.setLed(channel, note, on);
  }

  // ─────────────────────────────────────────────
  // Bind deck state changes → LED feedback
  // ─────────────────────────────────────────────
  void _bindDeckFeedback() {
    deckA.addListener(() => _updateDeckLeds(deckA));
    deckB.addListener(() => _updateDeckLeds(deckB));
  }

  void _updateDeckLeds(DeckState deck) {
    final bool isA = deck.deckId == DeckId.a;
    final int ch = isA
        ? Inpulse300Mapping.NOTE_ON_DECK_A
        : Inpulse300Mapping.NOTE_ON_DECK_B;

    // Play/Pause LED
    midi.setLed(ch, isA ? Inpulse300Mapping.PLAY_A : Inpulse300Mapping.PLAY_B,
        deck.playing);
    // Sync LED
    midi.setLed(ch, isA ? Inpulse300Mapping.SYNC_A : Inpulse300Mapping.SYNC_B,
        deck.sync);
    // Update VU meter
    final double vu = deck.playing ? deck.volume : 0.0;
    midi.sendMidi(
      0xB0 | (isA ? 0x01 : 0x02),
      Inpulse300Mapping.CC_VUMETER_DA,
      Inpulse300Mapping.normToMidi(vu),
    );
  }

  // ─────────────────────────────────────────────
  // Load track
  // ─────────────────────────────────────────────
  Future<void> loadTrackToDeck(DeckId deckId, String path,
      {String? title, String? artist}) async {
    final deck = deckId == DeckId.a ? deckA : deckB;
    await deck.loadTrack(path, title: title, artist: artist);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    deckA.dispose();
    deckB.dispose();
    super.dispose();
  }
}
