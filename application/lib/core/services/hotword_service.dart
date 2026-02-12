import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import '../../features/emergency/services/sos_service.dart';
import '../services/profile_service.dart';
import '../../router.dart';

class HotwordService {
  static final HotwordService _instance = HotwordService._internal();
  factory HotwordService() => _instance;
  HotwordService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isListening = false;
  bool get isListening => _isListening;
  bool _isAttemptingListen = false;
  DateTime? _lastTrigger;
  final Duration _cooldown = const Duration(seconds: 20);
  final List<String> _keywords = [
    'help',
    'bachao',
    'madad',
    'save me',
    'need help',
    'emergency'
  ];
  Timer? _restartTimer;

  Future<void> start() async {
    if (_isListening) {
      if (!_speech.isListening && !_isAttemptingListen) {
        _listen();
      }
      return;
    }
    
    // Check permission without blocking UI excessively
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      // Don't auto-request here as it might be annoying on every app start
      // instead, we wait for user to grant it elsewhere or on specific trigger
      return;
    }

    await ProfileService().fetchProfile();
    final available = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
      finalTimeout: const Duration(seconds: 0),
      options: [
        stt.SpeechConfigOption('android', 'android.speech.extra.DICTATION_MODE', true),
      ],
    );
    if (!available) return;
    _isListening = true;
    _listen();
  }

  Timer? _watchdogTimer;

  void stop() {
    _restartTimer?.cancel();
    _restartTimer = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _speech.cancel();
    _isListening = false;
  }

  void _listen() async {
    if (!_isListening || _isAttemptingListen) return;

    try {
      _isAttemptingListen = true;
      
      // Force cancel any existing session before starting a new one
      // This is the most reliable way to avoid error_busy
      await _speech.cancel();
      await Future.delayed(const Duration(milliseconds: 500));

      await _speech.listen(
        listenMode: stt.ListenMode.confirmation, // Better for short trigger words
        partialResults: true,
        onDevice: false, // Cloud recognition is often more accurate for trigger words
        listenFor: const Duration(seconds: 30), // Shorter bursts are more stable
        pauseFor: const Duration(seconds: 10),
        onResult: (result) {
          final text = result.recognizedWords.toLowerCase();
          if (text.isEmpty) return;
          
          if (kDebugMode) print('Recognized: $text');
          
          for (final k in _keywords) {
            // Check if the recognized text CONTAINS the keyword
            // This is more robust than exact regex matching
            if (text.contains(k)) {
              final now = DateTime.now();
              if (_lastTrigger == null || now.difference(_lastTrigger!) > _cooldown) {
                _lastTrigger = now;
                if (kDebugMode) print('Triggering SOS for keyword: $k');
                _triggerSos();
              }
              break;
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) print('Speech Listen Error: $e');
      _scheduleRestart(delaySeconds: 2);
    } finally {
      _isAttemptingListen = false;
    }

    // Separate watchdog timer
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_isListening && !_speech.isListening && !_isAttemptingListen) {
        if (kDebugMode) print('Watchdog: Restarting speech');
        _listen();
      }
    });
  }

  Future<void> _triggerSos() async {
    try {
      // Play beep sound (optional, don't let it block SOS)
      try {
        // Only try to play if file exists in future, for now we catch the error
        // await _audioPlayer.play(AssetSource('sounds/beep.mp3'), volume: 1.0);
      } catch (e) {
        if (kDebugMode) print('Sound play failed: $e');
      }
      
      // If app is in foreground, navigate to SOS screen with autoStart and trigger source enabled
      try {
        router.go('/patient/sos?autoStart=true&trigger=voice');
      } catch (e) {
        if (kDebugMode) print('Navigation failed (likely in background): $e');
      }
      
      // Start the actual SOS alert (API call + Location)
      await SOSService().startSOS();
    } catch (e) {
      if (kDebugMode) print('Hotword Trigger Error: $e');
    }
  }

  void _onStatus(String status) {
    if (kDebugMode) print('Speech Status: $status');
    
    final s = status.toLowerCase();
    // 'done' usually follows 'notListening' or an error
    if (s == 'notlistening' || s == 'done') {
      _scheduleRestart(delaySeconds: 1);
    }
  }

  void _onError(Object error) {
    if (kDebugMode) print('Speech Error: $error');
    
    final errorStr = error.toString().toLowerCase();
    int delay = 2;

    if (errorStr.contains('error_busy') || errorStr.contains('error_client')) {
      // Force cancel if busy or client error (engine crash)
      _speech.cancel();
      delay = 3; // Wait a bit for recovery
    } else if (errorStr.contains('error_no_match')) {
      // No match is normal, restart quickly but not instantly to avoid loops
      delay = 1;
    } else if (errorStr.contains('error_speech_timeout')) {
      delay = 1;
    } else if (errorStr.contains('error_network')) {
      delay = 5; // Network issues need more time
    }

    if (kDebugMode) print('Scheduling speech restart in ${delay}s due to error');
    _scheduleRestart(delaySeconds: delay);
  }

  void _scheduleRestart({int delaySeconds = 2}) {
    if (!_isListening) return;
    
    _restartTimer?.cancel();
    _restartTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isListening) return;
      
      // If still listening according to status, but we got an error, 
      // we might need to stop first to be safe
      if (_speech.isListening) {
        if (kDebugMode) print('Restart: Already listening, stopping first...');
        _speech.stop().then((_) => _listen());
      } else {
        _listen();
      }
    });
  }
}
