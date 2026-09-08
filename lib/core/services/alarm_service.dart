import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'alarm_audio_stub.dart'
    if (dart.library.html) 'alarm_audio_web.dart';

final alarmServiceProvider = ChangeNotifierProvider<AlarmService>((ref) {
  return AlarmService();
});

class AlarmService extends ChangeNotifier {
  bool _isRinging = false;
  bool _soundEnabled = true;
  Timer? _ringingTimer;

  bool get isRinging => _isRinging;
  bool get soundEnabled => _soundEnabled;

  void toggleSound(bool enabled) {
    _soundEnabled = enabled;
    notifyListeners();
  }

  /// Start ringing the alarm chime until explicitly stopped
  void startAlarm() {
    _isRinging = true;
    notifyListeners();

    _playChimeTone();

    _ringingTimer?.cancel();
    _ringingTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (!_isRinging) {
        timer.cancel();
        return;
      }
      _playChimeTone();
    });
  }

  /// Stop and dismiss the ringing alarm
  void stopAlarm() {
    _isRinging = false;
    _ringingTimer?.cancel();
    _ringingTimer = null;
    notifyListeners();
  }

  /// Play a quick single chime for testing sound output
  void playTestChime() {
    _playChimeTone();
  }

  void _playChimeTone() {
    if (!_soundEnabled) return;

    try {
      // Platform alert sound
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    } catch (_) {}

    // Web Audio API chime synthesis for loud browser ring
    try {
      playWebAlarmChime();
    } catch (_) {}
  }

  @override
  void dispose() {
    _ringingTimer?.cancel();
    super.dispose();
  }
}

