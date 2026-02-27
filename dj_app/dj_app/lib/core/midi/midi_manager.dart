// lib/core/midi/midi_manager.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'midi_event_dispatcher.dart';

class MidiManager extends ChangeNotifier {
  static const _channel = MethodChannel('com.djapp/midi');
  static const _eventChannel = EventChannel('com.djapp/midi_events');

  final MidiEventDispatcher dispatcher = MidiEventDispatcher();

  bool _connected = false;
  bool get connected => _connected;

  String _deviceName = '';
  String get deviceName => _deviceName;

  StreamSubscription? _midiSub;

  // ─────────────────────────────────────────────
  // Connect to Inpulse 300 via USB
  // ─────────────────────────────────────────────
  Future<bool> connect() async {
    try {
      if (Platform.isAndroid) {
        return await _connectAndroid();
      } else if (Platform.isIOS) {
        return await _connectIOS();
      }
      return false;
    } catch (e) {
      debugPrint('MIDI connect error: $e');
      return false;
    }
  }

  Future<bool> _connectAndroid() async {
    final result = await _channel.invokeMethod<Map>('connectUSBMidi');
    if (result == null) return false;

    _connected = result['connected'] as bool? ?? false;
    _deviceName = result['deviceName'] as String? ?? '';
    notifyListeners();

    if (_connected) {
      _listenToMidiEvents();
    }
    return _connected;
  }

  Future<bool> _connectIOS() async {
    final result = await _channel.invokeMethod<Map>('connectCoreMidi');
    if (result == null) return false;

    _connected = result['connected'] as bool? ?? false;
    _deviceName = result['deviceName'] as String? ?? '';
    notifyListeners();

    if (_connected) {
      _listenToMidiEvents();
    }
    return _connected;
  }

  // ─────────────────────────────────────────────
  // Listen to incoming MIDI bytes
  // ─────────────────────────────────────────────
  void _listenToMidiEvents() {
    _midiSub?.cancel();
    _midiSub = _eventChannel.receiveBroadcastStream().listen(
      (dynamic data) {
        if (data is List && data.length >= 3) {
          dispatcher.dispatch(
            data[0] as int,
            data[1] as int,
            data[2] as int,
          );
        }
      },
      onError: (error) {
        debugPrint('MIDI stream error: $error');
        _connected = false;
        notifyListeners();
      },
    );
  }

  // ─────────────────────────────────────────────
  // Send MIDI output (for LEDs)
  // ─────────────────────────────────────────────
  Future<void> sendMidi(int status, int data1, int data2) async {
    if (!_connected) return;
    try {
      await _channel.invokeMethod('sendMidi', {
        'status': status,
        'data1': data1,
        'data2': data2,
      });
    } catch (e) {
      debugPrint('MIDI send error: $e');
    }
  }

  // Convenience: turn LED on/off
  Future<void> setLed(int status, int note, bool on) async {
    await sendMidi(status, note, on ? 0x7F : 0x00);
  }

  // Set energy ring color
  Future<void> setEnergyColor(int colorValue) async {
    await sendMidi(0x90, 0x05, colorValue);
  }

  // Set VU meter level (0.0 - 1.0)
  Future<void> setVuMeter(int channel, int cc, double level) async {
    final int midiVal = (level * 127).round().clamp(0, 127);
    await sendMidi(0xB0 | channel, cc, midiVal);
  }

  // ─────────────────────────────────────────────
  // Disconnect
  // ─────────────────────────────────────────────
  Future<void> disconnect() async {
    _midiSub?.cancel();
    await _channel.invokeMethod('disconnectMidi');
    _connected = false;
    _deviceName = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _midiSub?.cancel();
    dispatcher.dispose();
    super.dispose();
  }
}
