import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../features/emergency/services/sos_service.dart';
import '../services/profile_service.dart';

class HotwordService {
  static final HotwordService _instance = HotwordService._internal();
  factory HotwordService() => _instance;
  HotwordService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
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
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return;
    await ProfileService().fetchProfile();
    final available = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
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

  void _listen() {
    _speech.listen(
      listenMode: stt.ListenMode.dictation,
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
    _restartTimer?.cancel();
    _restartTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_isListening) return;
      if (!_speech.isListening) {
        _speech.stop();
        _listen();
      }
    });
  }

  Future<void> _triggerSos() async {
    try {
      await SOSService().startSOS();
    } catch (_) {}
  }

  void _onStatus(String status) {
    if (status.toLowerCase() == 'notlistening') {
      if (_isListening) {
        _speech.stop();
        _listen();
      }
    }
  }

  void _onError(Object error) {
    if (_isListening) {
      _speech.stop();
      _listen();
    }
  }
}
