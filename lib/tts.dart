import 'package:flutter_tts/flutter_tts.dart';

class TTSTool {
  static final TTSTool _singleton = TTSTool._internal();
  FlutterTts _flutterTts = FlutterTts();

  factory TTSTool() {
    return _singleton;
  }

  Future<void> setupTTS() async {
    await _flutterTts.setLanguage("zh-CN");
  }

  TTSTool._internal() {
    setupTTS();
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }
}
