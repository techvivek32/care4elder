import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import '../../features/emergency/services/sos_service.dart';
import '../services/profile_service.dart';

class HotwordService {
  static final HotwordService _instance = HotwordService._internal();
  factory HotwordService() => _instance;
  HotwordService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isListening = false;
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
    if (_isListening) return;
    
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
      finalTimeout: const Duration(milliseconds: 0), // Disable sound on timeout
    );
    if (!available) return;
    _isListening = true;
    _listen();
  }

  void stop() {
    _restartTimer?.cancel();
    _restartTimer = null;
    _speech.stop();
    _isListening = false;
  }

  void _listen() async {
    if (!_isListening || _isAttemptingListen || _speech.isListening) return;

    try {
      _isAttemptingListen = true;
      await _speech.listen(
        listenMode: stt.ListenMode.confirmation, // Better for keyword spotting
        partialResults: true,
        onResult: (result) {
          final text = result.recognizedWords.toLowerCase();
          if (text.isEmpty) return;
          
          for (final k in _keywords) {
            if (text.contains(k)) {
              final now = DateTime.now();
              if (_lastTrigger == null || now.difference(_lastTrigger!) > _cooldown) {
                _lastTrigger = now;
                _triggerSos();
              }
              break;
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) print('Speech Listen Error: $e');
    } finally {
      _isAttemptingListen = false;
    }

    // Watchdog to ensure it stays listening
    _restartTimer?.cancel();
    _restartTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isListening) return;
      if (!_speech.isListening && !_isAttemptingListen) {
        _listen();
      }
    });
  }

  Future<void> _triggerSos() async {
    try {
      // Play beep sound
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'), volume: 1.0);
      
      await SOSService().startSOS();
    } catch (e) {
      if (kDebugMode) print('Hotword Trigger Error: $e');
    }
  }

  void _onStatus(String status) {
    if (kDebugMode) print('Speech Status: $status');
    if (status.toLowerCase() == 'notlistening') {
      if (_isListening && !_isAttemptingListen) {
        // Delay slightly before restarting to avoid tight loops
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isListening && !_speech.isListening && !_isAttemptingListen) {
            _listen();
          }
        });
      }
    }
  }

  void _onError(Object error) {
    if (kDebugMode) print('Speech Error: $error');
    if (_isListening && !_isAttemptingListen) {
      Future.delayed(const Duration(seconds: 2), () {
        if (_isListening && !_speech.isListening && !_isAttemptingListen) {
          _listen();
        }
      });
    }
  }
}
