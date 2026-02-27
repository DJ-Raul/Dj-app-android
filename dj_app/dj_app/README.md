# 🎛️ DJ Controller App — Hercules DJControl Inpulse 300

Aplicație Flutter completă pentru DJ, cu suport nativ pentru **Hercules DJControl Inpulse 300** via USB OTG (Android) și Lightning/USB-C (iOS).

---

## 📁 Structura proiectului

```
lib/
├── core/
│   ├── midi/
│   │   ├── inpulse_300_mapping.dart     ← Toate comenzile MIDI din PDF
│   │   ├── midi_event_dispatcher.dart   ← Parser bytes → events
│   │   └── midi_manager.dart            ← Conexiune USB + trimitere LED
│   └── audio/
│       ├── deck.dart                    ← Starea unui deck (play, cue, loop...)
│       ├── mixer.dart                   ← Crossfader, volume master
│       └── audio_engine.dart            ← Leagă MIDI → deck actions
├── features/
│   ├── decks/
│   │   ├── deck_view.dart               ← UI deck (waveform, transport)
│   │   └── jog_wheel_widget.dart        ← Jog wheel animat + scratch
│   ├── mixer/
│   │   └── mixer_view.dart              ← EQ, crossfader, VU meters
│   ├── pads/
│   │   └── pad_grid_view.dart           ← 8 pads cu Hot Cue, Roll, etc.
│   ├── browser/
│   │   └── music_browser_view.dart      ← Import fișiere + SoundCloud
│   └── main_screen.dart                 ← Layout principal
└── main.dart

android/app/src/main/
├── java/com/djapp/midi/MidiPlugin.kt    ← Kotlin: USB MIDI nativ
├── AndroidManifest.xml                  ← Permisiuni USB + audio
└── res/xml/device_filter.xml            ← Filter Hercules VID/PID

ios/Runner/
└── MidiPlugin.swift                     ← CoreMIDI nativ pentru iOS
```

---

## 🚀 Setup

### 1. Instalează Flutter
```bash
flutter pub get
```

### 2. Android setup

Înregistrează plugin-ul în `MainActivity.kt`:
```kotlin
import com.djapp.midi.MidiPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(MidiPlugin())
    }
}
```

### 3. iOS setup

Înregistrează plugin-ul în `AppDelegate.swift`:
```swift
import UIKit
import Flutter

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
    override func application(_ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        MidiPlugin.register(with: registrar(forPlugin: "MidiPlugin")!)
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

Adaugă în `Info.plist`:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>For MIDI connectivity</string>
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>armv7</string>
</array>
```

### 4. Run
```bash
# Android
flutter run

# iOS  
cd ios && pod install && cd ..
flutter run
```

---

## 🎚️ Funcționalități implementate

| Feature | Status |
|---------|--------|
| MIDI USB connection (Android) | ✅ |
| MIDI USB connection (iOS) | ✅ |
| Play / Pause / Cue | ✅ |
| Jog Wheel (bend + scratch) | ✅ |
| Hot Cues (8 slots) | ✅ |
| Loop In/Out | ✅ |
| Beat Roll | ✅ |
| Beat Jump | ✅ |
| EQ Low/Mid/High | ✅ |
| Crossfader | ✅ |
| Volume per deck | ✅ |
| Master Volume | ✅ |
| Waveform display | ✅ (vizual) |
| LED feedback | ✅ |
| VU Meters | ✅ |
| Pad modes (8) | ✅ |
| Slip mode | ✅ |
| Vinyl mode | ✅ |
| Quantize | ✅ |
| Sync | ✅ |
| Import fișiere locale | ✅ |
| SoundCloud streaming | 🔧 (API key necesar) |
| BPM detection | 🔧 (TODO) |
| Waveform real | 🔧 (TODO) |
| FX engine | 🔧 (TODO) |

---

## 🔌 Cum conectezi Inpulse 300

### Android
1. Conectează controller-ul cu cablu USB → OTG adapter → telefon
2. Deschide app-ul
3. Va apărea o fereastră de permisiune USB → Accept
4. LED-ul de status devine verde

### iOS  
1. Conectează cu Lightning/USB-C MIDI adapter (ex: iRig MIDI 2)
2. Sau USB-C direct pe iPhone 15+
3. App-ul detectează automat prin CoreMIDI

---

## 📡 MIDI Flow

```
[Inpulse 300]
    ↓ USB bytes (4 bytes per packet)
[MidiPlugin.kt / MidiPlugin.swift]
    ↓ EventChannel → Flutter
[MidiEventDispatcher.dispatch(status, data1, data2)]
    ↓ Parsare → MidiEvent
[AudioEngine._handleEvent(event)]
    ↓ Execută acțiune
[DeckState / MixerState]
    ↓ notifyListeners()
[UI rebuild] + [LED feedback → sendMidi()]
    ↓
[Inpulse 300 LEDs]
```

---

## 🔑 SoundCloud API

Adaugă cheia ta în `lib/core/soundcloud_service.dart` (de creat):
```dart
const String soundCloudClientId = 'YOUR_CLIENT_ID';
```

Înregistrează-te pe [developers.soundcloud.com](https://developers.soundcloud.com).

---

## 📝 Note tehnice

- **MIDI channels**: Deck A = 0x91, Deck B = 0x92, Global = 0x90
- **Pads**: Channel 0x96 (A), 0x97 (B), note = (mode-1)*16 + padIndex
- **VID/PID Hercules**: 0x06F8 / 0xB105
- **LED on/off**: trimite aceeași adresă cu value 0x7F (on) sau 0x00 (off)

---

*Built with Flutter + CoreMIDI + Android USB Host API*
