// lib/core/audio/deck.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../midi/midi_event_dispatcher.dart';

class HotCue {
  final int index;
  Duration position;
  String label;
  int color; // 0xRRGGBB

  HotCue({
    required this.index,
    required this.position,
    this.label = '',
    this.color = 0xFF2196F3,
  });
}

class LoopRegion {
  Duration start;
  Duration end;
  bool active;

  LoopRegion({
    required this.start,
    required this.end,
    this.active = false,
  });

  Duration get length => end - start;
}

class DeckState extends ChangeNotifier {
  final DeckId deckId;
  final AudioPlayer _player = AudioPlayer();

  // ── State ──────────────────────────────────────
  bool _playing = false;
  bool _slip = false;
  bool _vinyl = false;
  bool _quantize = true;
  bool _sync = false;
  bool _pfL = false;
  bool _fxOn = false;

  double _volume = 1.0;
  double _pitch = 0.0;       // -1.0 to +1.0
  double _filter = 0.5;      // 0.0=full low, 0.5=center, 1.0=full high
  double _eqLow = 0.75;
  double _eqMid = 0.75;
  double _eqHigh = 0.75;
  double _gain = 0.75;
  double _fxLevel = 0.0;
  double _dryWet = 0.5;

  String? _trackPath;
  String? _trackTitle;
  String? _trackArtist;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  double _bpm = 120.0;
  double _waveformProgress = 0.0;

  int _padMode = 1; // 1-8

  // Hot cues (8 slots)
  final List<HotCue?> _hotCues = List.filled(8, null);

  // Loop
  LoopRegion? _loop;
  Duration? _loopInPoint;

  // Jog touch
  bool _jogTouched = false;
  bool get jogTouched => _jogTouched;

  // ── Getters ────────────────────────────────────
  bool get playing => _playing;
  bool get slip => _slip;
  bool get vinyl => _vinyl;
  bool get quantize => _quantize;
  bool get sync => _sync;
  bool get pfL => _pfL;
  bool get fxOn => _fxOn;
  double get volume => _volume;
  double get pitch => _pitch;
  double get filter => _filter;
  double get eqLow => _eqLow;
  double get eqMid => _eqMid;
  double get eqHigh => _eqHigh;
  double get gain => _gain;
  double get fxLevel => _fxLevel;
  double get dryWet => _dryWet;
  String? get trackPath => _trackPath;
  String? get trackTitle => _trackTitle;
  String? get trackArtist => _trackArtist;
  Duration get duration => _duration;
  Duration get position => _position;
  double get bpm => _bpm;
  double get waveformProgress => _waveformProgress;
  int get padMode => _padMode;
  List<HotCue?> get hotCues => List.unmodifiable(_hotCues);
  LoopRegion? get loop => _loop;
  AudioPlayer get player => _player;

  // Remaining time
  Duration get remaining => _duration - _position;

  DeckState(this.deckId) {
    _player.positionStream.listen((pos) {
      _position = pos;
      if (_duration.inMilliseconds > 0) {
        _waveformProgress = pos.inMilliseconds / _duration.inMilliseconds;
      }
      // Handle loop
      if (_loop != null && _loop!.active && pos >= _loop!.end) {
        _player.seek(_loop!.start);
      }
      notifyListeners();
    });

    _player.playerStateStream.listen((state) {
      _playing = state.playing;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      if (dur != null) _duration = dur;
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────
  // TRANSPORT
  // ─────────────────────────────────────────────
  Future<void> play() async {
    await _player.play();
    _playing = true;
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    _playing = false;
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> cue() async {
    if (_playing) {
      // Return to cue point and pause
      await _player.seek(Duration.zero);
      await pause();
    } else {
      // Set cue point at current position
      await _player.seek(_position);
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekToProgress(double progress) async {
    final ms = (progress * _duration.inMilliseconds).round();
    await seekTo(Duration(milliseconds: ms));
  }

  // ─────────────────────────────────────────────
  // LOAD TRACK
  // ─────────────────────────────────────────────
  Future<void> loadTrack(String path, {String? title, String? artist}) async {
    _trackPath = path;
    _trackTitle = title ?? path.split('/').last;
    _trackArtist = artist ?? 'Unknown';
    _position = Duration.zero;
    _waveformProgress = 0.0;

    await _player.setFilePath(path);
    notifyListeners();
  }

  Future<void> loadUrl(String url, {String? title, String? artist}) async {
    _trackPath = url;
    _trackTitle = title ?? 'Stream';
    _trackArtist = artist ?? 'Unknown';
    _position = Duration.zero;

    await _player.setUrl(url);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // JOG WHEEL
  // ─────────────────────────────────────────────
  void jogTurn(int direction, int speed) {
    if (_vinyl && _jogTouched) {
      // Scratch mode
      _scratch(direction, speed);
    } else {
      // Pitch bend mode
      _pitchBend(direction, speed);
    }
  }

  void _scratch(int direction, int speed) {
    final ms = direction * speed * 5;
    final newPos = _position + Duration(milliseconds: ms);
    _player.seek(newPos.clamp(Duration.zero, _duration));
  }

  void _pitchBend(int direction, int speed) {
    // Temporary pitch adjustment
    final bendAmount = direction * speed * 0.005;
    _player.setSpeed((1.0 + _pitch + bendAmount).clamp(0.5, 2.0));
  }

  void setJogTouched(bool touched) {
    _jogTouched = touched;
    if (!touched) {
      // Reset speed to normal + pitch offset
      _applyPitch();
    }
  }

  // ─────────────────────────────────────────────
  // PITCH & TEMPO
  // ─────────────────────────────────────────────
  void setPitch(double value) {
    _pitch = value.clamp(-1.0, 1.0);
    _applyPitch();
    notifyListeners();
  }

  void _applyPitch() {
    // Map -1.0..+1.0 to 0.5x..2.0x speed
    final speed = 1.0 + (_pitch * 0.5);
    _player.setSpeed(speed.clamp(0.5, 2.0));
  }

  void setBpm(double bpm) {
    _bpm = bpm;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // MIXER
  // ─────────────────────────────────────────────
  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    _player.setVolume(_volume);
    notifyListeners();
  }

  void setFilter(double value) {
    _filter = value.clamp(0.0, 1.0);
    // TODO: Apply filter DSP
    notifyListeners();
  }

  void setEqLow(double value) {
    _eqLow = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setEqMid(double value) {
    _eqMid = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setEqHigh(double value) {
    _eqHigh = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setGain(double value) {
    _gain = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // LOOP
  // ─────────────────────────────────────────────
  void setLoopIn() {
    _loopInPoint = _position;
    notifyListeners();
  }

  void setLoopOut() {
    if (_loopInPoint != null) {
      _loop = LoopRegion(
        start: _loopInPoint!,
        end: _position,
        active: true,
      );
      _loopInPoint = null;
      notifyListeners();
    }
  }

  void toggleLoop() {
    if (_loop != null) {
      _loop!.active = !_loop!.active;
      notifyListeners();
    }
  }

  void setLoopLength(double beats) {
    if (_bpm <= 0) return;
    final beatDuration = Duration(milliseconds: (60000 / _bpm).round());
    final loopLength = beatDuration * beats.round();
    _loop = LoopRegion(
      start: _position,
      end: _position + loopLength,
      active: true,
    );
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // HOT CUES
  // ─────────────────────────────────────────────
  void setHotCue(int index) {
    if (index < 0 || index >= 8) return;
    _hotCues[index] = HotCue(index: index, position: _position);
    notifyListeners();
  }

  Future<void> jumpToHotCue(int index) async {
    if (index < 0 || index >= 8) return;
    final cue = _hotCues[index];
    if (cue != null) {
      await seekTo(cue.position);
      if (!_playing) await play();
    }
  }

  void deleteHotCue(int index) {
    if (index < 0 || index >= 8) return;
    _hotCues[index] = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // TOGGLES
  // ─────────────────────────────────────────────
  void toggleSlip() {
    _slip = !_slip;
    notifyListeners();
  }

  void toggleVinyl() {
    _vinyl = !_vinyl;
    notifyListeners();
  }

  void toggleQuantize() {
    _quantize = !_quantize;
    notifyListeners();
  }

  void toggleSync() {
    _sync = !_sync;
    notifyListeners();
  }

  void togglePfl() {
    _pfL = !_pfL;
    notifyListeners();
  }

  void toggleFx() {
    _fxOn = !_fxOn;
    notifyListeners();
  }

  void setPadMode(int mode) {
    _padMode = mode.clamp(1, 8);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // PAD ACTIONS (based on mode)
  // ─────────────────────────────────────────────
  Future<void> onPadPress(int padIndex, bool shifted) async {
    switch (_padMode) {
      case 1: // Hot Cue
        if (shifted) {
          deleteHotCue(padIndex);
        } else if (_hotCues[padIndex] != null) {
          await jumpToHotCue(padIndex);
        } else {
          setHotCue(padIndex);
        }
        break;
      case 2: // Roll
        final beatLengths = [0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0];
        if (padIndex < beatLengths.length) {
          setLoopLength(beatLengths[padIndex]);
        }
        break;
      case 4: // Sampler
        // TODO: Trigger sample
        break;
      case 8: // Beat Jump
        final jumps = [-8.0, -4.0, -2.0, -1.0, 1.0, 2.0, 4.0, 8.0];
        if (padIndex < jumps.length && _bpm > 0) {
          final beatMs = (60000 / _bpm * jumps[padIndex]).round();
          final newPos = _position + Duration(milliseconds: beatMs);
          await seekTo(newPos.clamp(Duration.zero, _duration));
        }
        break;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
