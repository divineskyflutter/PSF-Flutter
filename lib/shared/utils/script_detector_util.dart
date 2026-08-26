enum DetectedScript {
  english,
  hindi,
  gujarati,
  unknown,
}

class ScriptDetector {
  ScriptDetector._();

  static DetectedScript detectScript(String text) {
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      return DetectedScript.hindi;
    }
    if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(text)) {
      return DetectedScript.gujarati;
    }
    if (RegExp(r'[A-Za-z]').hasMatch(text)) {
      return DetectedScript.english;
    }
    return DetectedScript.unknown;
  }
}
