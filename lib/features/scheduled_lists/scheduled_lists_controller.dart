import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/todo_models.dart';
import 'dismissed_lists_store.dart';
import 'time_status.dart';

/// How often the feed reloads and its status labels are recomputed.
const Duration kFeedRefreshInterval = Duration(minutes: 1);

/// How long a completed item stays in place before the list re-sorts, so the
/// check animation is visible before the row moves away.
const Duration kResortDelay = Duration(milliseconds: 700);

class ScheduledFeed {
  const ScheduledFeed({
    required this.lists,
    required this.itemOrder,
    required this.originalOrder,
    required this.dismissed,
    required this.now,
  });

  final List<TodoList> lists;

  /// Per list, the item ids in the order they should be drawn.
  ///
  /// Kept separate from [lists] so a toggle can flip a checkbox immediately
  /// without the row jumping to the bottom in the same frame.
  final Map<int, List<int>> itemOrder;

  /// Per list, the item order as first loaded.
  ///
  /// "Reset items" restores this, because the completed-last sorting will have
  /// reshuffled the working order since.
  final Map<int, List<int>> originalOrder;

  final Set<int> dismissed;

  /// The clock the status labels were computed against. Advancing this is what
  /// makes "In 20 min" tick down to "Now".
  final DateTime now;

  ScheduledFeed copyWith({
    List<TodoList>? lists,
    Map<int, List<int>>? itemOrder,
    Map<int, List<int>>? originalOrder,
    Set<int>? dismissed,
    DateTime? now,
  }) =>
      ScheduledFeed(
        lists: lists ?? this.lists,
        itemOrder: itemOrder ?? this.itemOrder,
        originalOrder: originalOrder ?? this.originalOrder,
        dismissed: dismissed ?? this.dismissed,
        now: now ?? this.now,
      );

  /// The visible feed, after the day-of-week filter, the active window and
  /// dismissals.
  ({List<TodoList> active, TodoList? upNext}) get sections {
    final kept =
        lists.where((list) => !dismissed.contains(list.id)).toList();
    return ScheduledListRules.classify(kept, now);
  }

  /// The items of one section of a list, in display order.
  List<TodoItem> ordered(int listId, List<TodoItem> items) {
    final order = itemOrder[listId];
    if (order == null) return items;

    final positions = {for (var i = 0; i < order.length; i++) order[i]: i};
    final sorted = [...items]..sort(
        (a, b) => (positions[a.id] ?? 1 << 30).compareTo(
          positions[b.id] ?? 1 << 30,
        ),
      );
    return sorted;
  }
}

class ScheduledListsController extends AsyncNotifier<ScheduledFeed> {
  Timer? _ticker;
  final Map<int, Timer> _resortTimers = {};

  @override
  Future<ScheduledFeed> build() async {
    _ticker?.cancel();
    _ticker = Timer.periodic(kFeedRefreshInterval, (_) => _tick());

    ref.onDispose(() {
      _ticker?.cancel();
      for (final timer in _resortTimers.values) {
        timer.cancel();
      }
    });

    return _load();
  }

  Future<ScheduledFeed> _load() async {
    final lists = await ref.read(todoRepositoryProvider).allScheduled();
    final now = DateTime.now();

    final store = DismissedListsStore(ref.read(sharedPreferencesProvider));

    return ScheduledFeed(
      lists: lists,
      itemOrder: {
        for (final list in lists) list.id: _sortedIds(list),
      },
      originalOrder: {
        for (final list in lists)
          list.id: list.allItems.map((item) => item.id).toList(),
      },
      dismissed: store.read(now: now),
      now: now,
    );
  }

  /// Completed items sink to the bottom, applied independently to the
  /// ungrouped items and to each group so nothing escapes its group.
  static List<int> _sortedIds(TodoList list) => [
        ...ScheduledListRules.completedLast(list.items).map((i) => i.id),
        for (final group in list.groups)
          ...ScheduledListRules.completedLast(group.items).map((i) => i.id),
      ];

  /// The once-a-minute tick: refresh the data and re-stamp the clock so labels
  /// move on even when the payload is unchanged.
  Future<void> _tick() async {
    final current = state.value;
    if (current == null) return;

    // Advance the clock immediately so labels stay honest even if the request
    // is slow or fails.
    state = AsyncData(current.copyWith(now: DateTime.now()));

    try {
      state = AsyncData(await _load());
    } catch (_) {
      // A failed background refresh should not blank a working screen.
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  /// Optimistic toggle: flip the checkbox and the completed counter now, send
  /// the request, then re-sort after a beat so the animation is visible.
  Future<void> toggleItem(int listId, TodoItem item) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      _applyToggle(current, listId, item.id, !item.isCompleted),
    );

    _resortTimers[listId]?.cancel();
    _resortTimers[listId] = Timer(kResortDelay, () => _resort(listId));

    try {
      await ref.read(todoRepositoryProvider).toggleItem(item.id);
    } catch (_) {
      // The optimistic state is now suspect; reload rather than guess.
      await refresh();
    }
  }

  ScheduledFeed _applyToggle(
    ScheduledFeed feed,
    int listId,
    int itemId,
    bool completed,
  ) {
    TodoItem update(TodoItem item) => item.id == itemId
        ? item.copyWith(
            isCompleted: completed,
            completedAt: completed ? DateTime.now() : null,
          )
        : item;

    final lists = feed.lists.map((list) {
      if (list.id != listId) return list;

      final updated = list.copyWith(
        items: list.items.map(update).toList(),
        groups: list.groups
            .map((g) => g.copyWith(items: g.items.map(update).toList()))
            .toList(),
      );
      return updated.copyWith(
        completedItems:
            updated.allItems.where((item) => item.isCompleted).length,
      );
    }).toList();

    return feed.copyWith(lists: lists);
  }

  void _resort(int listId) {
    final current = state.value;
    if (current == null) return;

    final list = current.lists.where((l) => l.id == listId).firstOrNull;
    if (list == null) return;

    state = AsyncData(
      current.copyWith(
        itemOrder: {...current.itemOrder, listId: _sortedIds(list)},
      ),
    );
  }

  /// Clears every completion and restores the order the list had on load.
  Future<void> resetItems(int listId) async {
    final current = state.value;
    if (current == null) return;

    try {
      await ref.read(todoRepositoryProvider).resetItems(listId);
    } catch (_) {
      await refresh();
      return;
    }

    TodoItem clear(TodoItem item) =>
        item.copyWith(isCompleted: false, completedAt: null);

    final lists = current.lists.map((list) {
      if (list.id != listId) return list;
      return list.copyWith(
        items: list.items.map(clear).toList(),
        groups: list.groups
            .map((g) => g.copyWith(items: g.items.map(clear).toList()))
            .toList(),
        completedItems: 0,
      );
    }).toList();

    state = AsyncData(
      current.copyWith(
        lists: lists,
        itemOrder: {
          ...current.itemOrder,
          // Completed-last sorting has reshuffled the working order, so restore
          // the order captured at load rather than re-deriving it.
          listId: current.originalOrder[listId] ?? const [],
        },
      ),
    );
  }

  Future<void> dismiss(int listId) async {
    final current = state.value;
    if (current == null) return;

    final dismissed = {...current.dismissed, listId};
    state = AsyncData(current.copyWith(dismissed: dismissed));

    await DismissedListsStore(ref.read(sharedPreferencesProvider))
        .write(dismissed, now: current.now);
  }

  Future<void> restoreDismissed() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(dismissed: {}));
    await DismissedListsStore(ref.read(sharedPreferencesProvider))
        .write({}, now: current.now);
  }
}

final scheduledListsControllerProvider =
    AsyncNotifierProvider<ScheduledListsController, ScheduledFeed>(
  ScheduledListsController.new,
);

/// A short label for a list's schedule: `7:30 AM` or the linked event's start.
String scheduleContext(TodoList list) {
  final event = list.linkedEvent;
  if (event != null) {
    final title = event.eventTitle ?? 'Event';
    return event.isAllDay
        ? title
        : '$title · ${_time(event.eventStart)}';
  }

  final minutes = list.scheduledMinutes;
  if (minutes == null) return '';
  return _time(
    DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60),
  );
}

String _time(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
}
