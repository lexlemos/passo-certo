import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/services/voice_navigation_service.dart';

class FlutterTtsServiceImpl implements VoiceNavigationService {
  final FlutterTts _tts;

  FlutterTtsServiceImpl({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  @override
  Future<void> initService() async {
    try {
      await _tts.setLanguage("pt-BR");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
    } catch (_) {
      // Ignora falhas de inicialização em ambientes de teste/simuladores sem TTS instalado
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
