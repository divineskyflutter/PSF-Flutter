/// Which script a piece of text is written in — used only by the
/// post-login query-resolution flow (see `QueryResolutionState`) to check
/// a queried field's typed input against the script its own name-prefix
/// requires (`G...` -> Gujarati, `H...` -> Hindi/Devanagari, no prefix ->
/// plain/Latin).
enum ScriptType { latin, devanagari, gujarati }

class ScriptDetector {
  ScriptDetector._();

  static const _devanagariStart = 0x0900;
  static const _devanagariEnd = 0x097F;
  static const _gujaratiStart = 0x0A80;
  static const _gujaratiEnd = 0x0AFF;

  /// Scans [text] for the first letter that falls in a Devanagari,
  /// Gujarati, or Latin-alphabet block; whitespace, digits and
  /// punctuation are skipped since they appear in every script and don't
  /// identify one. Falls back to [ScriptType.latin] once nothing
  /// script-specific is found at all (covers empty/punctuation-only
  /// input). See [matchesRequiredScript] for the actual mismatch check —
  /// that one looks at every letter, not just the first.
  static ScriptType detect(String text) {
    for (final rune in text.runes) {
      final script = _scriptOf(rune);
      if (script != null) return script;
    }
    return ScriptType.latin;
  }

  /// The script of a single character, or `null` for anything script-
  /// neutral (whitespace, digits, punctuation) that shouldn't count
  /// either way.
  static ScriptType? _scriptOf(int rune) {
    if (rune >= _devanagariStart && rune <= _devanagariEnd) {
      return ScriptType.devanagari;
    }
    if (rune >= _gujaratiStart && rune <= _gujaratiEnd) {
      return ScriptType.gujarati;
    }
    // Explicit Latin-letter check (not just "whatever's left after ruling
    // out Devanagari/Gujarati") — needed so a field that's SUPPOSED to be
    // Gujarati/Hindi but has Latin letters typed into it somewhere (e.g.
    // "સુરત test") is caught by matchesRequiredScript below, instead of
    // that scan only ever looking for Devanagari/Gujarati ranges and
    // silently ignoring Latin contamination.
    if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A)) {
      return ScriptType.latin;
    }
    return null;
  }

  /// What script a `tblMemberField`/`tblNomineeField`/
  /// `tblHealthDeclarationFields` enum name requires, from its own G/H/
  /// plain prefix (e.g. `GAddress` -> Gujarati, `HAddress` -> Hindi,
  /// `Address` -> Latin/plain).
  static ScriptType requiredScriptFor(String fieldName) {
    if (fieldName.startsWith('G')) return ScriptType.gujarati;
    if (fieldName.startsWith('H')) return ScriptType.devanagari;
    return ScriptType.latin;
  }

  /// `true` when [text] is empty/whitespace-only (not yet a script
  /// violation — the field's own required-field validation covers that
  /// case instead, so a freshly-unlocked field doesn't render as invalid
  /// before the member types anything) or EVERY letter in it matches what
  /// [fieldName] requires — not just the first one found. A field that's
  /// mostly correct but has a few foreign-script letters mixed in (typed
  /// by accident, or a leftover word from a previous pass) still counts
  /// as wrong; only [detect] (used for [primeLocalLanguageForScreen]-style
  /// "what pass is this account currently in" checks, where a single
  /// representative script is enough) looks at just the first match.
  static bool matchesRequiredScript(String text, String fieldName) {
    if (text.trim().isEmpty) return true;
    final required = requiredScriptFor(fieldName);
    for (final rune in text.runes) {
      final script = _scriptOf(rune);
      if (script != null && script != required) return false;
    }
    return true;
  }
}
