import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSTool {
  static final TTSTool _singleton = TTSTool._internal();
  FlutterTts _flutterTts = FlutterTts();

  factory TTSTool() {
    return _singleton;
  }

  Future<void> setupTTS() async {
    debugPrint("=================");
    var listLangugages = await _flutterTts.getLanguages;
    debugPrint('languages: $listLangugages');

    var listEngines = await _flutterTts.getEngines;
    debugPrint('engines: $listEngines');

    var defaultEngine = await _flutterTts.getDefaultEngine;
    debugPrint('default engine: $defaultEngine');

    // await _flutterTts.setLanguage("zh-CN");
    bool ret = await _flutterTts.isLanguageAvailable("zh-CN");

    if (ret) {
      await _flutterTts.setLanguage("zh-CN");
      debugPrint('lang: zh-CN');
    } else {
      await _flutterTts.setLanguage("en-US");
      debugPrint('lang: en-US');
    }
  }

  TTSTool._internal() {
    setupTTS();
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }
}
