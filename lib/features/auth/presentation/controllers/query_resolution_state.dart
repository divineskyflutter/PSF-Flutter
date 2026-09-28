import 'package:get/get.dart';

import 'package:psf_application/features/enum_bundle/data/models/enum_bundle_model.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/utils/script_detector.dart';

import '../../data/models/query_item_model.dart';

/// Drives the post-login "fix these specific fields" flow — active only
/// when a login came back with `hasUnresolvedQueries == true` (see
/// LoginScreen). While active, exactly the fields named by [start]'s
/// query list are unlocked across the Personal Details / Nominee / Health
/// Declaration steps; everything else is fully locked. Held as a plain
/// field on `RegistrationController` (not a GetX controller/mixin itself)
/// so it resets cleanly with the rest of that controller's per-session
/// state and never touches anything outside this one wizard session.
///
/// `tableId` (1=Personal Details/tblMember, 2=Nominee/tblNominee,
/// 3=Health Declaration/tblHealthDeclaration) and `fieldId` come from
/// `EnumBundleModel.queryTables`/`memberFields`/`nomineeFields`/
/// `healthDeclarationFields` — set via [setFieldEnums] once
/// `RegistrationController.loadEnumOptions` has fetched them. `itemNumber`
/// only matters for table 2 — the 1-based ordinal of which nominee (by
/// ascending `nomineeId`) a query is about.
///
/// **Passes**: when a single conceptual field has more than one queried
/// variant (e.g. both `GAddress` and `HAddress` flagged together), they
/// are NOT resolved in one edit — the screen unlocks Gujarati first, the
/// member fills/confirms it, then (still the same screen) Hindi unlocks
/// next, and so on, in Gujarati > Hindi > plain priority. [currentPass]
/// tracks which script is "open" per table (+ nominee itemNumber); a
/// field only reports [isFieldEditable] while its own required script
/// matches the active pass and it isn't already resolved.
class QueryResolutionState {
  List<QueryItem> _queries = const [];

  List<EnumItem> _memberFields = const [];
  List<EnumItem> _nomineeFields = const [];
  List<EnumItem> _healthFields = const [];

  final Map<String, RxBool> _resolved = {};
  final Map<String, RxBool> _scriptMismatch = {};
  final Map<String, bool> _toastedForMismatch = {};
  final Map<String, Rx<ScriptType>> _currentPass = {};
  final Set<int> _apiResolvedQueryIds = {};

  /// Bumped whenever [markApiResolved] records new ids, so an Obx that
  /// reads [isTableApiResolved] rebuilds once QueryResolve has been sent.
  final RxInt apiResolvedTick = 0.obs;

  /// Bumped when the field-name lists arrive (see [setFieldEnums]), so
  /// anything showing "is this field editable" rebuilds even if the pass
  /// itself didn't change — the answer depends on each field's name.
  final RxInt namesTick = 0.obs;

  /// `true` once the enum bundle's field-name lists have been received.
  bool get hasFieldNames => _memberFields.isNotEmpty;

  /// Fields a member can never edit in the app (ids, status, audit
  /// columns, the login mobile number...). If one is somehow flagged there
  /// is nothing on screen to fix — keeping it would block Next forever with
  /// nothing highlighted, so it's left out of the flow.
  static const _unfixableFields = <int, Set<int>>{
    1: {1, 5, 15, 16, 36, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60},
    2: {1, 7},
    3: {1, 2},
  };

  /// Language this flow's own labels and toasts are shown in. The screen
  /// keeps it mirroring the app's real language (the top-right picker
  /// opens the same sheet as the drawer), so `.tr` text and flow-localized
  /// text always agree. Independent of any table's pass — see
  /// [passLanguageFor] for that.
  final Rx<AppLanguage> localLanguage = AppLanguage.english.obs;

  bool get isActive => _queries.isNotEmpty;

  void start(List<QueryItem> queries) {
    _queries = queries
        .where((query) =>
            !(_unfixableFields[query.tableId]?.contains(query.fieldId) ??
                false))
        .toList();
    _resolved.clear();
    _scriptMismatch.clear();
    _toastedForMismatch.clear();
    _currentPass.clear();
    _apiResolvedQueryIds.clear();
    apiResolvedTick.value = 0;
  }

  /// Reset once the flow is fully done (all steps saved through Preview) —
  /// so a later, genuinely fresh registration session isn't affected.
  void reset() {
    _queries = const [];
    _resolved.clear();
    _scriptMismatch.clear();
    _toastedForMismatch.clear();
    _currentPass.clear();
    _apiResolvedQueryIds.clear();
    localLanguage.value = AppLanguage.english;
  }

  void setFieldEnums(EnumBundleModel bundle) {
    _memberFields = bundle.memberFields;
    _nomineeFields = bundle.nomineeFields;
    _healthFields = bundle.healthDeclarationFields;
    namesTick.value++;
  }

  List<EnumItem> _fieldsFor(int tableId) => switch (tableId) {
        1 => _memberFields,
        2 => _nomineeFields,
        3 => _healthFields,
        _ => const [],
      };

  /// The enum name for a field id on the given table (e.g. `GAddress`) —
  /// empty when the bundle hasn't loaded yet or the id is unknown. Its
  /// own `G`/`H`/plain prefix is what `ScriptDetector.requiredScriptFor`
  /// reads.
  String fieldNameFor(int tableId, int fieldId) {
    for (final item in _fieldsFor(tableId)) {
      if (item.id == fieldId) return item.name;
    }
    return '';
  }

  QueryItem? _lookup(int tableId, int fieldId, {int? itemNumber}) {
    for (final query in _queries) {
      if (query.tableId != tableId || query.fieldId != fieldId) continue;
      if (tableId == 2 && query.itemNumber != itemNumber) continue;
      return query;
    }
    return null;
  }

  /// Whether this exact field has an active query at all — regardless of
  /// the current pass (unlike [isFieldEditable], which also requires the
  /// field's own required script to be the ACTIVE pass right now). Used
  /// where a field's usual visibility is conditional on something else
  /// entirely (e.g. Health Declaration's hereditary-disease detail box
  /// only normally shows once its OWN checkbox is ticked) — that
  /// visibility needs to also account for "this field has a query" on
  /// its own, or a query targeting it could never be reached/resolved at
  /// all when the unrelated condition happens to be false.
  bool hasQueryFor(int tableId, int fieldId, {int? itemNumber}) =>
      _lookup(tableId, fieldId, itemNumber: itemNumber) != null;

  String _key(int tableId, int fieldId, int? itemNumber) =>
      '$tableId:$fieldId:${itemNumber ?? ''}';

  String _passKey(int tableId, int? itemNumber) =>
      '$tableId:${itemNumber ?? ''}';

  /// Which script is currently unlocked for editing on [tableId] (+
  /// nominee [itemNumber]) — see the class doc comment on passes.
  Rx<ScriptType> currentPass(int tableId, {int? itemNumber}) {
    final key = _passKey(tableId, itemNumber);
    return _currentPass.putIfAbsent(key, () => ScriptType.latin.obs);
  }

  /// `false` (red/unresolved) until the member edits this field at all —
  /// see [markTouched]. Cached per field so the same `RxBool` instance is
  /// reused across rebuilds (needed for `Obx` to track it correctly).
  RxBool isFieldResolved(int tableId, int fieldId, {int? itemNumber}) {
    final key = _key(tableId, fieldId, itemNumber);
    return _resolved.putIfAbsent(key, () => false.obs);
  }

  /// Whether this exact field (identified the same way a `QueryItem` is)
  /// should be unlocked right now: it must have a matching query AND its
  /// own required script must match the table's current active pass — a
  /// sibling variant of the same field queued for a later pass stays
  /// locked until its turn. Deliberately independent of [isFieldResolved]:
  /// a field stays interactive (and renders green, not just gray) for the
  /// REST of its own pass once resolved — it only re-locks when the pass
  /// itself advances (see [primeLocalLanguageForScreen]), not the instant
  /// it's touched. Callers should gate this behind `!isActive ||
  /// isFieldEditable(...)` so normal (non-query) sessions stay fully
  /// editable as today.
  bool isFieldEditable(int tableId, int fieldId, {int? itemNumber}) {
    // Always a real Rx read (also keeps any Obx around this valid, and
    // rebuilds it when the field names arrive late).
    namesTick.value;
    final query = _lookup(tableId, fieldId, itemNumber: itemNumber);
    if (query == null) return false;
    final requiredScript =
        ScriptDetector.requiredScriptFor(fieldNameFor(tableId, fieldId));
    return requiredScript == currentPass(tableId, itemNumber: itemNumber).value;
  }

  /// Call from a queried field's `onChanged` — any edit at all (even
  /// typed-then-cleared) counts as resolved; this is additive to whatever
  /// required-field validation already runs on the field.
  void markTouched(int tableId, int fieldId, {int? itemNumber}) {
    isFieldResolved(tableId, fieldId, itemNumber: itemNumber).value = true;
  }

  /// `true` while the field's current text doesn't match the script its
  /// own name requires — hard-blocks Next alongside [isFieldResolved].
  RxBool scriptMismatch(int tableId, int fieldId, {int? itemNumber}) {
    final key = _key(tableId, fieldId, itemNumber);
    return _scriptMismatch.putIfAbsent(key, () => false.obs);
  }

  void setScriptMismatch(
    int tableId,
    int fieldId,
    bool hasMismatch, {
    int? itemNumber,
  }) {
    scriptMismatch(tableId, fieldId, itemNumber: itemNumber).value =
        hasMismatch;
  }

  /// `true` only the FIRST time [isMismatched] goes true for this field
  /// since it was last fixed — so the wrong-script toast fires once per
  /// mistake instead of on every keystroke while it's still wrong.
  /// Resets itself once [isMismatched] goes back to false, so a later,
  /// separate mistake toasts again.
  bool shouldToastMismatch(
    int tableId,
    int fieldId,
    bool isMismatched, {
    int? itemNumber,
  }) {
    final key = _key(tableId, fieldId, itemNumber);
    if (!isMismatched) {
      _toastedForMismatch.remove(key);
      return false;
    }
    if (_toastedForMismatch[key] == true) return false;
    _toastedForMismatch[key] = true;
    return true;
  }

  /// Whether table [tableId] has any query at all — used for the
  /// forward-skip logic (a table with none is skipped going forward, but
  /// still reachable, fully locked, going back).
  bool hasQueriesForTable(int tableId) =>
      _queries.any((query) => query.tableId == tableId);

  /// Readable names (Gujarati/Hindi versions folded together, e.g.
  /// `GAddress` + `HAddress` -> "Address") of the fields on [tableId]
  /// still waiting to be fixed — shown in a banner at the top of the step,
  /// so any flagged field is at least named on screen even if it ever had
  /// no box of its own.
  List<String> flaggedFieldLabels(int tableId, {int? itemNumber}) {
    apiResolvedTick.value;
    final labels = <String>[];
    for (final query in _queries) {
      if (query.tableId != tableId) continue;
      if (tableId == 2 &&
          itemNumber != null &&
          query.itemNumber != itemNumber) {
        continue;
      }
      if (_apiResolvedQueryIds.contains(query.queryId)) continue;
      final label = _friendlyFieldLabel(fieldNameFor(tableId, query.fieldId));
      if (label.isNotEmpty && !labels.contains(label)) labels.add(label);
    }
    return labels;
  }

  static String _friendlyFieldLabel(String name) {
    if (name.isEmpty) return '';
    var base = name;
    if (base.length > 1 &&
        ScriptDetector.requiredScriptFor(base) != ScriptType.latin) {
      base = base.substring(1);
    }
    base = base
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'(?<=[a-z0-9])(?=[A-Z])'),
          (match) => ' ',
        )
        .trim();
    if (base.isEmpty) return '';
    return base[0].toUpperCase() + base.substring(1);
  }

  /// Total number of queries on [tableId] (and, for nominees,
  /// [itemNumber]) — compare against [resolvedQueryIdsFor]'s length to
  /// know whether every query on a screen has been resolved.
  int totalQueriesFor(int tableId, {int? itemNumber}) {
    return _queries
        .where((query) =>
            query.tableId == tableId &&
            (tableId != 2 || query.itemNumber == itemNumber))
        .length;
  }

  /// Every nominee `itemNumber` that has at least one query, ascending —
  /// only these nominee slots get any editable fields in this flow.
  List<int> nomineeItemNumbersWithQueries() {
    final numbers = _queries
        .where((query) => query.tableId == 2 && query.itemNumber != null)
        .map((query) => query.itemNumber!)
        .toSet()
        .toList();
    numbers.sort();
    return numbers;
  }

  /// Every queryId on [tableId] (and, for nominees, [itemNumber]) that's
  /// been resolved (touched, no active script mismatch) — regardless of
  /// pass. See [newlyResolvedQueryIdsFor] for the subset not yet sent to
  /// the API.
  List<int> resolvedQueryIdsFor(int tableId, {int? itemNumber}) {
    return _queries
        .where((query) =>
            query.tableId == tableId &&
            (tableId != 2 || query.itemNumber == itemNumber))
        .where((query) =>
            isFieldResolved(query.tableId, query.fieldId, itemNumber: itemNumber)
                .value)
        .where((query) =>
            !scriptMismatch(query.tableId, query.fieldId, itemNumber: itemNumber)
                .value)
        .map((query) => query.queryId)
        .toList();
  }

  /// Same as [resolvedQueryIdsFor] but excludes queryIds already sent to
  /// `QueryResolve` (see [markApiResolved]) — since Next can be tapped
  /// once per pass on the same screen, this stops an earlier pass's
  /// already-resolved queries from being re-sent on a later pass's Next.
  List<int> newlyResolvedQueryIdsFor(int tableId, {int? itemNumber}) {
    return resolvedQueryIdsFor(tableId, itemNumber: itemNumber)
        .where((id) => !_apiResolvedQueryIds.contains(id))
        .toList();
  }

  void markApiResolved(Iterable<int> queryIds) {
    _apiResolvedQueryIds.addAll(queryIds);
    apiResolvedTick.value++;
  }

  /// `true` once QueryResolve has actually been SENT for every query on
  /// [tableId]/[itemNumber] — unlike [isTableFullyResolved], which turns
  /// true as soon as each field has merely been edited on screen (before
  /// anything is saved). Anything that decides "does this still need
  /// saving/resolving?" must use this one.
  bool isTableApiResolved(int tableId, {int? itemNumber}) {
    apiResolvedTick.value;
    return _queries
        .where((query) =>
            query.tableId == tableId &&
            (tableId != 2 || query.itemNumber == itemNumber))
        .every((query) => _apiResolvedQueryIds.contains(query.queryId));
  }

  /// `true` once every query on [tableId]/[itemNumber] is resolved,
  /// across all passes — this is what actually allows moving on to the
  /// next step.
  bool isTableFullyResolved(int tableId, {int? itemNumber}) {
    if (!hasQueriesForTable(tableId)) return true;
    return resolvedQueryIdsFor(tableId, itemNumber: itemNumber).length ==
        totalQueriesFor(tableId, itemNumber: itemNumber);
  }

  /// `true` once every query belonging to the CURRENT pass is resolved —
  /// there may still be a later pass (e.g. Hindi after Gujarati) pending,
  /// in which case [isTableFullyResolved] is still false. Gates Next.
  bool isCurrentPassResolved(int tableId, {int? itemNumber}) {
    final pass = currentPass(tableId, itemNumber: itemNumber).value;
    final passQueries = _queries.where((query) =>
        query.tableId == tableId &&
        (tableId != 2 || query.itemNumber == itemNumber) &&
        ScriptDetector.requiredScriptFor(fieldNameFor(tableId, query.fieldId)) ==
            pass);
    return passQueries.every((query) =>
        isFieldResolved(tableId, query.fieldId, itemNumber: itemNumber).value);
  }

  /// Every field id on [tableId] (+ nominee [itemNumber]) that's unlocked
  /// right now — i.e. has a query AND belongs to the current pass,
  /// regardless of resolved state. Used to proactively re-check script
  /// mismatches the instant a pass opens (see
  /// RegistrationController.recheckStep1ScriptMismatches) instead of
  /// waiting for the member's first edit.
  List<int> editableFieldIds(int tableId, {int? itemNumber}) {
    return _queries
        .where((query) =>
            query.tableId == tableId &&
            (tableId != 2 || query.itemNumber == itemNumber))
        .where((query) =>
            isFieldEditable(tableId, query.fieldId, itemNumber: itemNumber))
        .map((query) => query.fieldId)
        .toList();
  }

  /// The first unresolved, currently-editable field's id on [tableId] (+
  /// nominee [itemNumber]), in the query list's own order — used to
  /// auto-scroll to it whenever the screen first opens or a new pass
  /// unlocks a different field. Skips fields already resolved this pass
  /// (they're still editable per [isFieldEditable], just not what the
  /// member needs to look at next). `null` when nothing is left to fix
  /// right now (e.g. every field in this pass is already resolved).
  int? firstEditableFieldId(int tableId, {int? itemNumber}) {
    for (final query in _queries) {
      if (query.tableId != tableId) continue;
      if (tableId == 2 && query.itemNumber != itemNumber) continue;
      if (!isFieldEditable(tableId, query.fieldId, itemNumber: itemNumber)) {
        continue;
      }
      if (isFieldResolved(tableId, query.fieldId, itemNumber: itemNumber)
          .value) {
        continue;
      }
      return query.fieldId;
    }
    return null;
  }

  /// Recomputes and sets the current pass for [tableId]/[itemNumber] to
  /// whichever script (Gujarati > Hindi > plain) still has unresolved
  /// queries. Call once on first
  /// entering a screen and again after each pass's queries are resolved,
  /// to advance to the next pass — a no-op (stays on the same pass) if
  /// nothing has changed.
  void primeLocalLanguageForScreen(int tableId, {int? itemNumber}) {
    final unresolved = _queries.where((query) =>
        query.tableId == tableId &&
        (tableId != 2 || query.itemNumber == itemNumber) &&
        !isFieldResolved(tableId, query.fieldId, itemNumber: itemNumber).value);

    ScriptType pass = ScriptType.latin;
    if (unresolved.any((query) =>
        ScriptDetector.requiredScriptFor(fieldNameFor(tableId, query.fieldId)) ==
        ScriptType.gujarati)) {
      pass = ScriptType.gujarati;
    } else if (unresolved.any((query) =>
        ScriptDetector.requiredScriptFor(fieldNameFor(tableId, query.fieldId)) ==
        ScriptType.devanagari)) {
      pass = ScriptType.devanagari;
    }

    currentPass(tableId, itemNumber: itemNumber).value = pass;
  }

  /// The language a table's (or nominee's) CURRENT pass requires. Used for
  /// the "Gujarati data updated. Now enter Hindi data." toast — names come
  /// from the passes themselves, never from [localLanguage] (which is the
  /// language the UI text is shown in, mirroring the app's real language).
  AppLanguage passLanguageFor(int tableId, {int? itemNumber}) {
    return switch (currentPass(tableId, itemNumber: itemNumber).value) {
      ScriptType.gujarati => AppLanguage.gujarati,
      ScriptType.devanagari => AppLanguage.hindi,
      ScriptType.latin => AppLanguage.english,
    };
  }
}
