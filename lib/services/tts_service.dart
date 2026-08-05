import 'package:flutter_tts/flutter_tts.dart';
import 'translation_service.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isPlaying = false;

  static bool get isPlaying => _isPlaying;

  static Future<void> speak(String text) async {
    final lang = TranslationService();
    final String ttsLangCode = lang.getTtsLanguageCode();
    
    await _flutterTts.setLanguage(ttsLangCode);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.85); // slightly slower for agricultural clarity

    _isPlaying = true;
    await _flutterTts.speak(text);

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
    });

    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
    });
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
  }
}
