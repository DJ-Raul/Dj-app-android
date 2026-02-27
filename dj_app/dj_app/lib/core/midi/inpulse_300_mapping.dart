// lib/core/midi/inpulse_300_mapping.dart
// Complete MIDI mapping for Hercules DJControl Inpulse 300
// Based on official MIDI Commands documentation v1.2

class Inpulse300Mapping {
  // ─────────────────────────────────────────────
  // MIDI CHANNELS
  // ─────────────────────────────────────────────
  static const int chGlobal     = 0x00; // 0  - Global
  static const int chDeckA      = 0x01; // 1  - Deck A
  static const int chDeckB      = 0x02; // 2  - Deck B
  static const int chShift      = 0x03; // 3  - Shift modifier
  static const int chShiftDeckA = 0x04; // 4  - Deck A + Shift
  static const int chShiftDeckB = 0x05; // 5  - Deck B + Shift (CC)
  static const int chPadsA      = 0x06; // 6  - Pads Deck A
  static const int chPadsB      = 0x07; // 7  - Pads Deck B

  // ─────────────────────────────────────────────
  // NOTE ON MESSAGES — GLOBAL (channel 0x90)
  // ─────────────────────────────────────────────
  static const int BROWSE_PUSH      = 0x00;
  static const int BEATMATCH_GUIDE  = 0x01;
  static const int PFL_MASTER       = 0x02;
  static const int ASSISTANT        = 0x03;
  static const int ENERGY_LEVEL     = 0x05;

  // VU Meter Master
  static const int VUMETER1_MASTER_L = 0x06;
  static const int VUMETER2_MASTER_L = 0x07;
  static const int VUMETER3_MASTER_L = 0x08;
  static const int VUMETER4_MASTER_L = 0x09;
  static const int VUMETER5_MASTER_L = 0x0A;
  static const int VUMETER1_MASTER_R = 0x0B;
  static const int VUMETER2_MASTER_R = 0x0C;
  static const int VUMETER3_MASTER_R = 0x0D;
  static const int VUMETER4_MASTER_R = 0x0E;
  static const int VUMETER5_MASTER_R = 0x0F;

  // ─────────────────────────────────────────────
  // NOTE ON MESSAGES — DECK A (channel 0x91)
  // ─────────────────────────────────────────────
  static const int FX_ON_A        = 0x00;
  static const int SLIP_A         = 0x01;
  static const int QUANTIZE_A     = 0x02;
  static const int VINYL_A        = 0x03;
  static const int SHIFT_A        = 0x04;
  static const int SYNC_A         = 0x05;
  static const int CUE_A          = 0x06;
  static const int PLAY_A         = 0x07;
  static const int JOG_TOUCH_A    = 0x08;
  static const int LOOP_IN        = 0x09;
  static const int LOOP_OUT       = 0x0A;
  static const int LOOP_IN_LONG   = 0x0B;
  static const int PFL_A          = 0x0C;
  static const int LOAD_A         = 0x0D;
  static const int LOAD_A_LONG    = 0x0E;
  static const int MODE1_A        = 0x0F;
  static const int MODE2_A        = 0x10;
  static const int MODE3_A        = 0x11;
  static const int MODE4_A        = 0x12;
  static const int MODE5_A        = 0x13;
  static const int MODE6_A        = 0x14;
  static const int MODE7_A        = 0x15;
  static const int MODE8_A        = 0x16;
  static const int PADFX_SELECT_1A = 0x25;
  static const int PADFX_SELECT_2A = 0x26;
  static const int PADFX_SELECT_3A = 0x27;
  static const int PADFX_SELECT_4A = 0x28;
  static const int PADFX_SELECT_5A = 0x29;
  static const int PADFX_SELECT_6A = 0x2A;
  static const int FX2_ON_A       = 0x2B;

  // VU Meter Deck A
  static const int VUMETER1_DA    = 0x17;
  static const int VUMETER2_DA    = 0x18;
  static const int VUMETER3_DA    = 0x19;
  static const int VUMETER4_DA    = 0x1A;
  static const int VUMETER5_DA    = 0x1B;

  // Beat / Align guide Deck A
  static const int JOG_BEND_LEFT_A_ON   = 0x1C;
  static const int JOG_BEND_RIGHT_A_ON  = 0x1D;
  static const int PITCH_UP_A_ON        = 0x1E;
  static const int PITCH_DOWN_A_ON      = 0x1F;
  static const int JOG_BEND_LEFT_A_OFF  = 0x21;
  static const int JOG_BEND_RIGHT_A_OFF = 0x22;
  static const int PITCH_UP_A_OFF       = 0x23;
  static const int PITCH_DOWN_A_OFF     = 0x24;

  // ─────────────────────────────────────────────
  // NOTE ON MESSAGES — DECK B (channel 0x92)
  // ─────────────────────────────────────────────
  static const int FX_ON_B        = 0x00;
  static const int SLIP_B         = 0x01;
  static const int QUANTIZE_B     = 0x02;
  static const int VINYL_B        = 0x03;
  static const int SHIFT_B        = 0x04;
  static const int SYNC_B         = 0x05;
  static const int CUE_B          = 0x06;
  static const int PLAY_B         = 0x07;
  static const int JOG_TOUCH_B    = 0x08;
  static const int LOOP_IN_B      = 0x09;
  static const int LOOP_OUT_B     = 0x0A;
  static const int LOOP_IN_B_LONG = 0x0B;
  static const int PFL_B          = 0x0C;
  static const int LOAD_B         = 0x0D;
  static const int LOAD_B_LONG    = 0x0E;
  static const int MODE1_B        = 0x0F;
  static const int MODE2_B        = 0x10;
  static const int MODE3_B        = 0x11;
  static const int MODE4_B        = 0x12;
  static const int MODE5_B        = 0x13;
  static const int MODE6_B        = 0x14;
  static const int MODE7_B        = 0x15;
  static const int MODE8_B        = 0x16;
  static const int PADFX_SELECT_1B = 0x25;
  static const int PADFX_SELECT_2B = 0x26;
  static const int PADFX_SELECT_3B = 0x27;
  static const int PADFX_SELECT_4B = 0x28;
  static const int PADFX_SELECT_5B = 0x29;
  static const int PADFX_SELECT_6B = 0x2A;
  static const int FX2_ON_B       = 0x2B;

  // VU Meter Deck B
  static const int VUMETER1_DB    = 0x17;
  static const int VUMETER2_DB    = 0x18;
  static const int VUMETER3_DB    = 0x19;
  static const int VUMETER4_DB    = 0x1A;
  static const int VUMETER5_DB    = 0x1B;

  // ─────────────────────────────────────────────
  // PADS — Deck A (channel 0x96), Deck B (channel 0x97)
  // Each mode has 8 pads, offset by 0x10 per mode
  // MODE1=0x00, MODE2=0x10, MODE3=0x20, MODE4=0x30
  // MODE5=0x40, MODE6=0x50, MODE7=0x60, MODE8=0x70
  // ─────────────────────────────────────────────
  static int padNote(int mode, int padIndex) {
    // mode: 1-8, padIndex: 0-7
    return ((mode - 1) * 0x10) + padIndex;
  }

  // Shift+Pad offset is +0x08 within same mode block
  static int padNoteShift(int mode, int padIndex) {
    return ((mode - 1) * 0x10) + 0x08 + padIndex;
  }

  // ─────────────────────────────────────────────
  // CONTROL CHANGE MESSAGES — GLOBAL (channel 0xB0)
  // ─────────────────────────────────────────────
  static const int CC_XFADER         = 0x00;
  static const int CC_XFADER_LSB     = 0x20;
  static const int CC_BROWSE_ENC     = 0x01;
  static const int CC_BROWSE_ASSIST  = 0x02;
  static const int CC_VOL_MASTER     = 0x03;
  static const int CC_VOL_MASTER_LSB = 0x23;
  static const int CC_VOL_HDP        = 0x04;
  static const int CC_VOL_HDP_LSB    = 0x24;
  static const int CC_VUMETER_MASTER_L = 0x40;
  static const int CC_VUMETER_MASTER_R = 0x41;

  // ─────────────────────────────────────────────
  // CONTROL CHANGE MESSAGES — DECK A (channel 0xB1)
  // ─────────────────────────────────────────────
  static const int CC_VOL_A       = 0x00;
  static const int CC_FILTER_A    = 0x01;
  static const int CC_LOW_A       = 0x02;
  static const int CC_MID_A       = 0x03;
  static const int CC_HIGH_A      = 0x04;
  static const int CC_GAIN_A      = 0x05;
  static const int CC_FX_LVL_A   = 0x06;
  static const int CC_DRY_WET_A  = 0x07;
  static const int CC_PITCH_A    = 0x08;
  static const int CC_JOG_A      = 0x09;
  static const int CC_JOG_SCRATCH_A     = 0x0A;
  static const int CC_JOG_PADSCRATCH_A  = 0x0C;
  static const int CC_PAD_FX_A   = 0x0D;
  // LSB versions
  static const int CC_VOL_A_LSB   = 0x20;
  static const int CC_FILTER_A_LSB = 0x21;
  static const int CC_LOW_A_LSB   = 0x22;
  static const int CC_MID_A_LSB   = 0x23;
  static const int CC_HIGH_A_LSB  = 0x24;
  static const int CC_GAIN_A_LSB  = 0x25;
  static const int CC_PITCH_A_LSB = 0x28;
  static const int CC_VUMETER_DA  = 0x40;

  // ─────────────────────────────────────────────
  // CONTROL CHANGE MESSAGES — DECK B (channel 0xB2)
  // ─────────────────────────────────────────────
  static const int CC_VOL_B       = 0x00;
  static const int CC_FILTER_B    = 0x01;
  static const int CC_LOW_B       = 0x02;
  static const int CC_MID_B       = 0x03;
  static const int CC_HIGH_B      = 0x04;
  static const int CC_GAIN_B      = 0x05;
  static const int CC_FX_LVL_B   = 0x06;
  static const int CC_DRY_WET_B  = 0x07;
  static const int CC_PITCH_B    = 0x08;
  static const int CC_JOG_B      = 0x09;
  static const int CC_JOG_SCRATCH_B     = 0x0A;
  static const int CC_JOG_PAD_B         = 0x0B;
  static const int CC_JOG_PADSCRATCH_B  = 0x0C;
  static const int CC_PAD_FX_B   = 0x0D;
  static const int CC_VUMETER_DB  = 0x40;

  // ─────────────────────────────────────────────
  // MIDI STATUS BYTES
  // ─────────────────────────────────────────────
  static const int NOTE_ON_GLOBAL     = 0x90;
  static const int NOTE_ON_DECK_A     = 0x91;
  static const int NOTE_ON_DECK_B     = 0x92;
  static const int NOTE_ON_SHIFT      = 0x93;
  static const int NOTE_ON_SHIFT_AB   = 0x94;
  static const int NOTE_ON_PADS_A     = 0x96;
  static const int NOTE_ON_PADS_B     = 0x97;
  static const int CC_GLOBAL          = 0xB0;
  static const int CC_DECK_A          = 0xB1;
  static const int CC_DECK_B          = 0xB2;
  static const int CC_SHIFT_GLOBAL    = 0xB3;
  static const int CC_SHIFT_DECK_A    = 0xB4;
  static const int CC_SHIFT_DECK_B    = 0xB5;

  // ─────────────────────────────────────────────
  // PAD MODE NAMES (MODE1 = Hot Cues, etc.)
  // ─────────────────────────────────────────────
  static const List<String> padModeNames = [
    'Hot Cue',    // MODE1
    'Roll',       // MODE2
    'Slicer',     // MODE3
    'Sampler',    // MODE4
    'Toneplay',   // MODE5
    'FX',         // MODE6
    'Sliderloop', // MODE7
    'BeatJump',   // MODE8
  ];

  // ─────────────────────────────────────────────
  // ENERGY LEVEL COLORS (browser ring backlight)
  // ─────────────────────────────────────────────
  static const Map<String, int> energyColors = {
    'off':          0x00,
    'dark_blue':    0x01,
    'blue':         0x03,
    'medium_blue':  0x0B,
    'light_blue':   0x17,
    'blue_green':   0x1E,
    'green':        0x3C,
    'red':          0x60,
    'light_red':    0x64,
    'orange':       0x6C,
    'light_orange': 0x74,
    'yellow':       0x7C,
    'white':        0x7F,
  };

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  /// Convert 7-bit MIDI value (0-127) to normalized double (0.0-1.0)
  static double midiToNorm(int value) => value / 127.0;

  /// Convert normalized double to 7-bit MIDI value
  static int normToMidi(double value) => (value * 127).round().clamp(0, 127);

  /// Check if jog wheel is moving clockwise
  static bool jogIsCW(int value) => value >= 0x01 && value <= 0x3F;

  /// Check if jog wheel is moving counter-clockwise
  static bool jogIsCCW(int value) => value >= 0x40 && value <= 0x7F;

  /// Get jog wheel speed (1=slow, 24=fast)
  static int jogSpeed(int value) {
    if (jogIsCW(value)) return value;
    if (jogIsCCW(value)) return 0x80 - value;
    return 0;
  }

  /// Get jog wheel direction as -1 or +1
  static int jogDirection(int value) {
    if (jogIsCW(value)) return 1;
    if (jogIsCCW(value)) return -1;
    return 0;
  }
}
