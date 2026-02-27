// lib/core/audio/mixer.dart
import 'package:flutter/foundation.dart';
import 'deck.dart';

class MixerState extends ChangeNotifier {
  double _crossfader = 0.5; // 0.0 = full A, 1.0 = full B
  double _masterVolume = 0.75;
  double _headphonesVolume = 0.75;
  double _masterVuL = 0.0;
  double _masterVuR = 0.0;

  double get crossfader => _crossfader;
  double get masterVolume => _masterVolume;
  double get headphonesVolume => _headphonesVolume;
  double get masterVuL => _masterVuL;
  double get masterVuR => _masterVuR;

  // Crossfader curves
  double get gainA {
    if (_crossfader <= 0.5) return 1.0;
    return 1.0 - ((_crossfader - 0.5) * 2.0);
  }

  double get gainB {
    if (_crossfader >= 0.5) return 1.0;
    return _crossfader * 2.0;
  }

  void setCrossfader(double value) {
    _crossfader = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setMasterVolume(double value) {
    _masterVolume = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setHeadphonesVolume(double value) {
    _headphonesVolume = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void updateVuMeters(double l, double r) {
    _masterVuL = l;
    _masterVuR = r;
    notifyListeners();
  }

  /// Apply crossfader mix to both decks
  void applyMix(DeckState deckA, DeckState deckB) {
    deckA.setVolume(deckA.volume * gainA * _masterVolume);
    deckB.setVolume(deckB.volume * gainB * _masterVolume);
  }
}
