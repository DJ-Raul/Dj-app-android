// lib/core/midi/midi_event_dispatcher.dart
import 'dart:async';
import 'inpulse_300_mapping.dart';

// ─────────────────────────────────────────────────────────
// MIDI Event Types
// ─────────────────────────────────────────────────────────
enum MidiEventType {
  // Deck controls
  play, pause, cue, sync, load, loadLong,
  // Loop
  loopIn, loopOut, loopInLong,
  // FX
  fxOn, fx2On, fxSelect,
  // Jog
  jogTouch, jogRelease, jogTurn, jogScratch, jogPadScratch,
  // Pads
  padPressed, padReleased,
  // Mode buttons
  modeSelect,
  // Sliders/Knobs
  volume, filter, eqLow, eqMid, eqHigh,
  gain, fxLevel, dryWet, pitch,
  // Global
  crossfader, masterVolume, headphonesVolume,
  browseEncoder, browse,
  // Toggles
  slip, quantize, vinyl, pfl, pfLMaster,
  beatmatchGuide, assistant,
  // Pads FX select
  padFxSelect,
}

enum DeckId { a, b, none }

class MidiEvent {
  final MidiEventType type;
  final DeckId deck;
  final bool pressed;       // For buttons
  final double value;       // For knobs/faders (0.0 - 1.0)
  final int rawValue;       // Raw MIDI value
  final int padIndex;       // For pads (0-7)
  final int padMode;        // For pads (1-8)
  final int jogDirection;   // -1 CCW, +1 CW
  final int jogSpeed;       // 1-24
  final bool shifted;

  const MidiEvent({
    required this.type,
    this.deck = DeckId.none,
    this.pressed = false,
    this.value = 0.0,
    this.rawValue = 0,
    this.padIndex = 0,
    this.padMode = 1,
    this.jogDirection = 0,
    this.jogSpeed = 0,
    this.shifted = false,
  });

  @override
  String toString() =>
    'MidiEvent($type, deck=$deck, pressed=$pressed, value=$value, '
    'pad=$padIndex/mode$padMode, jog=$jogDirection*$jogSpeed)';
}

// ─────────────────────────────────────────────────────────
// MIDI Event Dispatcher
// Parses raw bytes → MidiEvent objects
// ─────────────────────────────────────────────────────────
class MidiEventDispatcher {
  final _controller = StreamController<MidiEvent>.broadcast();
  Stream<MidiEvent> get events => _controller.stream;

  // Filtered streams for convenience
  Stream<MidiEvent> get deckAEvents =>
      events.where((e) => e.deck == DeckId.a);
  Stream<MidiEvent> get deckBEvents =>
      events.where((e) => e.deck == DeckId.b);
  Stream<MidiEvent> get globalEvents =>
      events.where((e) => e.deck == DeckId.none);

  /// Parse raw MIDI bytes [status, data1, data2]
  void dispatch(int status, int data1, int data2) {
    final event = _parse(status, data1, data2);
    if (event != null) {
      _controller.add(event);
    }
  }

  MidiEvent? _parse(int status, int data1, int data2) {
    final bool pressed = data2 == 0x7F;
    final double norm = Inpulse300Mapping.midiToNorm(data2);

    switch (status) {
      // ── NOTE ON GLOBAL ──────────────────────────────
      case Inpulse300Mapping.NOTE_ON_GLOBAL:
        return _parseGlobalNote(data1, data2, pressed);

      // ── NOTE ON DECK A ──────────────────────────────
      case Inpulse300Mapping.NOTE_ON_DECK_A:
        return _parseDeckNote(DeckId.a, data1, data2, pressed, false);

      // ── NOTE ON DECK B ──────────────────────────────
      case Inpulse300Mapping.NOTE_ON_DECK_B:
        return _parseDeckNote(DeckId.b, data1, data2, pressed, false);

      // ── NOTE ON SHIFT+DECK A/B ───────────────────────
      case Inpulse300Mapping.NOTE_ON_SHIFT_AB:
        return _parseDeckNoteShifted(data1, data2, pressed);

      // ── PADS DECK A ─────────────────────────────────
      case Inpulse300Mapping.NOTE_ON_PADS_A:
        return _parsePad(DeckId.a, data1, data2, pressed, false);

      // ── PADS DECK B ─────────────────────────────────
      case Inpulse300Mapping.NOTE_ON_PADS_B:
        return _parsePad(DeckId.b, data1, data2, pressed, false);

      // ── CC GLOBAL ───────────────────────────────────
      case Inpulse300Mapping.CC_GLOBAL:
        return _parseCCGlobal(data1, data2, norm);

      // ── CC DECK A ───────────────────────────────────
      case Inpulse300Mapping.CC_DECK_A:
        return _parseCCDeck(DeckId.a, data1, data2, norm);

      // ── CC DECK B ───────────────────────────────────
      case Inpulse300Mapping.CC_DECK_B:
        return _parseCCDeck(DeckId.b, data1, data2, norm);

      default:
        return null;
    }
  }

  MidiEvent? _parseGlobalNote(int note, int value, bool pressed) {
    switch (note) {
      case Inpulse300Mapping.BROWSE_PUSH:
        return MidiEvent(type: MidiEventType.browse, pressed: pressed, rawValue: value);
      case Inpulse300Mapping.BEATMATCH_GUIDE:
        return MidiEvent(type: MidiEventType.beatmatchGuide, pressed: pressed, rawValue: value);
      case Inpulse300Mapping.PFL_MASTER:
        return MidiEvent(type: MidiEventType.pfLMaster, pressed: pressed, rawValue: value);
      case Inpulse300Mapping.ASSISTANT:
        return MidiEvent(type: MidiEventType.assistant, pressed: pressed, rawValue: value);
      default:
        return null;
    }
  }

  MidiEvent? _parseDeckNote(DeckId deck, int note, int value, bool pressed, bool shifted) {
    switch (note) {
      case Inpulse300Mapping.PLAY_A:
        return MidiEvent(type: pressed ? MidiEventType.play : MidiEventType.pause,
            deck: deck, pressed: pressed, shifted: shifted);
      case Inpulse300Mapping.CUE_A:
        return MidiEvent(type: MidiEventType.cue, deck: deck, pressed: pressed, shifted: shifted);
      case Inpulse300Mapping.SYNC_A:
        return MidiEvent(type: MidiEventType.sync, deck: deck, pressed: pressed, shifted: shifted);
      case Inpulse300Mapping.LOAD_A:
        return MidiEvent(type: MidiEventType.load, deck: deck, pressed: pressed, shifted: shifted);
      case Inpulse300Mapping.LOAD_A_LONG:
        return MidiEvent(type: MidiEventType.loadLong, deck: deck, pressed: pressed);
      case Inpulse300Mapping.LOOP_IN:
        return MidiEvent(type: MidiEventType.loopIn, deck: deck, pressed: pressed);
      case Inpulse300Mapping.LOOP_OUT:
        return MidiEvent(type: MidiEventType.loopOut, deck: deck, pressed: pressed);
      case Inpulse300Mapping.LOOP_IN_LONG:
        return MidiEvent(type: MidiEventType.loopInLong, deck: deck, pressed: pressed);
      case Inpulse300Mapping.JOG_TOUCH_A:
        return MidiEvent(
            type: pressed ? MidiEventType.jogTouch : MidiEventType.jogRelease,
            deck: deck, pressed: pressed);
      case Inpulse300Mapping.SLIP_A:
        return MidiEvent(type: MidiEventType.slip, deck: deck, pressed: pressed);
      case Inpulse300Mapping.QUANTIZE_A:
        return MidiEvent(type: MidiEventType.quantize, deck: deck, pressed: pressed);
      case Inpulse300Mapping.VINYL_A:
        return MidiEvent(type: MidiEventType.vinyl, deck: deck, pressed: pressed);
      case Inpulse300Mapping.PFL_A:
        return MidiEvent(type: MidiEventType.pfl, deck: deck, pressed: pressed);
      case Inpulse300Mapping.FX_ON_A:
        return MidiEvent(type: MidiEventType.fxOn, deck: deck, pressed: pressed);
      case Inpulse300Mapping.FX2_ON_A:
        return MidiEvent(type: MidiEventType.fx2On, deck: deck, pressed: pressed);
      // Mode buttons
      case Inpulse300Mapping.MODE1_A:
      case Inpulse300Mapping.MODE2_A:
      case Inpulse300Mapping.MODE3_A:
      case Inpulse300Mapping.MODE4_A:
      case Inpulse300Mapping.MODE5_A:
      case Inpulse300Mapping.MODE6_A:
      case Inpulse300Mapping.MODE7_A:
      case Inpulse300Mapping.MODE8_A:
        final modeNum = note - Inpulse300Mapping.MODE1_A + 1;
        return MidiEvent(type: MidiEventType.modeSelect, deck: deck,
            pressed: pressed, padMode: modeNum);
      default:
        return null;
    }
  }

  MidiEvent? _parseDeckNoteShifted(int note, int value, bool pressed) {
    // Shifted deck A buttons use channel 0x94
    // Re-use same parsing but mark shifted=true
    // Most shifted buttons have same note numbers
    return _parseDeckNote(DeckId.a, note, value, pressed, true);
  }

  MidiEvent? _parsePad(DeckId deck, int note, int value, bool pressed, bool shifted) {
    // Pads: note = (mode-1)*0x10 + padIndex
    // Shifted pads: note = (mode-1)*0x10 + 0x08 + padIndex
    final int modeBlock = note ~/ 0x10; // 0-7
    final int offset = note % 0x10;
    final bool isShifted = offset >= 0x08;
    final int padIndex = isShifted ? offset - 0x08 : offset;
    final int padMode = modeBlock + 1;

    return MidiEvent(
      type: pressed ? MidiEventType.padPressed : MidiEventType.padReleased,
      deck: deck,
      pressed: pressed,
      padIndex: padIndex,
      padMode: padMode,
      shifted: isShifted,
      rawValue: value,
    );
  }

  MidiEvent? _parseCCGlobal(int cc, int value, double norm) {
    switch (cc) {
      case Inpulse300Mapping.CC_XFADER:
        return MidiEvent(type: MidiEventType.crossfader, value: norm, rawValue: value);
      case Inpulse300Mapping.CC_BROWSE_ENC:
        return MidiEvent(
          type: MidiEventType.browseEncoder,
          jogDirection: Inpulse300Mapping.jogDirection(value),
          jogSpeed: Inpulse300Mapping.jogSpeed(value),
          rawValue: value,
        );
      case Inpulse300Mapping.CC_VOL_MASTER:
        return MidiEvent(type: MidiEventType.masterVolume, value: norm, rawValue: value);
      case Inpulse300Mapping.CC_VOL_HDP:
        return MidiEvent(type: MidiEventType.headphonesVolume, value: norm, rawValue: value);
      default:
        return null;
    }
  }

  MidiEvent? _parseCCDeck(DeckId deck, int cc, int value, double norm) {
    // Skip LSB messages (0x20-0x3F range) — handled by main CC
    if (cc >= 0x20 && cc <= 0x3F) return null;

    switch (cc) {
      case Inpulse300Mapping.CC_VOL_A:
        return MidiEvent(type: MidiEventType.volume, deck: deck, value: norm, rawValue: value);
      case Inpulse300Mapping.CC_FILTER_A:
        return MidiEvent(type: MidiEventType.filter, deck: deck, value: norm, rawValue: value);
      case Inpulse300Mapping.CC_LOW_A:
        return MidiEvent(type: MidiEventType.eqLow, deck: deck, value: norm, rawValue: value);
      case Inpulse300Mapping.CC_MID_A:
        return MidiEvent(type: MidiEventType.eqMid, deck: deck, value: norm, rawValue: value);
      case Inpulse300Mapping.CC_HIGH_A:
        return MidiEvent(type: MidiEventType.eqHigh, deck: deck, value: norm, rawValue: value);
      case Inpulse300Mapping.CC_GAIN_A:
        return MidiEvent(type: MidiEventType.gain, deck: deck, value: norm, rawValue: value);
      case Inpulse300Mapping.CC_FX_LVL_A:
        return MidiEvent(type: MidiEventType.fxLevel, deck: deck, value: norm, rawValue: value);
      case Inpulse300Mapping.CC_DRY_WET_A:
        return MidiEvent(type: MidiEventType.dryWet, deck: deck, value: norm, rawValue: value);
      case Inpulse300Mapping.CC_PITCH_A:
        // Pitch: center = 0x40 (64), map to -1.0 .. +1.0
        final double pitchNorm = (value - 64) / 64.0;
        return MidiEvent(type: MidiEventType.pitch, deck: deck,
            value: pitchNorm, rawValue: value);
      case Inpulse300Mapping.CC_JOG_A:
        return MidiEvent(
          type: MidiEventType.jogTurn,
          deck: deck,
          jogDirection: Inpulse300Mapping.jogDirection(value),
          jogSpeed: Inpulse300Mapping.jogSpeed(value),
          rawValue: value,
        );
      case Inpulse300Mapping.CC_JOG_SCRATCH_A:
        return MidiEvent(
          type: MidiEventType.jogScratch,
          deck: deck,
          jogDirection: Inpulse300Mapping.jogDirection(value),
          jogSpeed: Inpulse300Mapping.jogSpeed(value),
          rawValue: value,
        );
      default:
        return null;
    }
  }

  void dispose() {
    _controller.close();
  }
}
