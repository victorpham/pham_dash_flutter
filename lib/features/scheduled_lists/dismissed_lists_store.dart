import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_date.dart';

/// "Done for today" dismissals.
///
/// Purely local — nothing is sent to the server. Dismissals are keyed by
/// today's `yyyy-MM-dd` and drop automatically when the date rolls over, so a
/// list dismissed yesterday reappears this morning without any cleanup step.
class DismissedListsStore {
  const DismissedListsStore(this._prefs);

  static const _key = 'phamdash_dismissed_lists';

  final SharedPreferences _prefs;

  Set<int> read({DateTime? now}) {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      if (decoded['date'] != ApiDate.dayKey(now ?? DateTime.now())) {
        // Stale: a different day's dismissals carry no meaning today.
        return {};
      }
      final ids = decoded['ids'];
      if (ids is! List) return {};
      return ids.whereType<num>().map((n) => n.toInt()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> write(Set<int> ids, {DateTime? now}) async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'date': ApiDate.dayKey(now ?? DateTime.now()),
        'ids': ids.toList(),
      }),
    );
  }
}
