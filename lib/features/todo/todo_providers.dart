import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_list.dart';
import '../../core/cache/freshness.dart';
import '../../core/providers.dart';
import '../../core/sync/pending_writes.dart';
import '../../data/models/todo_models.dart';
import '../../data/repositories/todo_repository.dart';

final showArchivedProvider = valueProvider<bool>(() => false);

/// Null means "all labels".
final labelFilterProvider = valueProvider<int?>(() => null);

final todoListsProvider =
    AsyncNotifierProvider.autoDispose<TodoListsNotifier, List<TodoList>>(
      TodoListsNotifier.new,
    );

class TodoListsNotifier extends AsyncNotifier<List<TodoList>>
    with CachedList<TodoList> {
  @override
  Future<List<TodoList>> build() {
    final includeArchived = ref.watch(showArchivedProvider);
    final labelId = ref.watch(labelFilterProvider);

    // Only the launch view is cached. The filters are in-memory and reset on
    // every launch, so a filtered result would never be the one a cold start
    // wants to show first.
    if (!includeArchived && labelId == null) {
      persistList(
        'todo_lists',
        fromJson: TodoList.fromJson,
        toJson: (list) => list.toJson(),
      );
    }

    final repository = ref.watch(todoRepositoryProvider);
    if (labelId != null) return repository.listsWithLabel(labelId);
    return repository.lists(includeArchived: includeArchived);
  }

  /// Flips the pin at once and lets the server catch up. A pin is the one
  /// write made from the Lists tab itself, and it is often the first thing
  /// tapped after a cold launch - exactly when the database is still waking.
  /// Rolled back on failure; the caller shows the error. The re-read follows
  /// regardless, since pinning also reorders the list server-side.
  Future<void> togglePin(int listId) async {
    final before = state.value;
    if (before == null) return;

    state = AsyncData([
      for (final list in before)
        if (list.id == listId)
          list.copyWith(isPinned: !list.isPinned)
        else
          list,
    ]);
    try {
      await ref
          .read(pendingWritesProvider.notifier)
          .track(() => ref.read(todoRepositoryProvider).togglePin(listId));
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
    ref.invalidateSelf();
  }
}

final todoLabelsProvider =
    AsyncNotifierProvider.autoDispose<TodoLabelsNotifier, List<TodoLabel>>(
      TodoLabelsNotifier.new,
    );

class TodoLabelsNotifier extends AsyncNotifier<List<TodoLabel>>
    with CachedList<TodoLabel> {
  @override
  Future<List<TodoLabel>> build() {
    persistList(
      'todo_labels',
      fromJson: TodoLabel.fromJson,
      toJson: (label) => label.toJson(),
    );
    return ref.watch(todoRepositoryProvider).labels();
  }
}

/// One list, in full, for the detail screen.
///
/// This is the one place the app patches local state instead of invalidating
/// after a write, and it is deliberate. The detail screen is the shopping
/// list, used in an aisle after the app has sat idle long enough for the
/// database to pause - so a tap on an item has to take effect now, not after
/// the 20-40 s wake. Each write patches [state] first, then sends; the
/// server's own copy of the item is spliced in when it answers, and a failure
/// puts the snapshot back and rethrows so the row can say so. The provider is
/// never invalidated after a successful write: a re-read landing mid-burst
/// would briefly revert whichever taps came after it. The Lists tab is
/// invalidated instead, for its counts.
final todoListDetailProvider = AsyncNotifierProvider.autoDispose
    .family<TodoListDetailNotifier, TodoList?, int>(TodoListDetailNotifier.new);

class TodoListDetailNotifier extends AsyncNotifier<TodoList?> {
  TodoListDetailNotifier(this.listId);

  final int listId;

  /// Below this, an item is a placeholder for an add that is still in flight.
  /// Negative so it can never collide with a server id.
  static int _nextTempId = -1;

  /// Freshness key for this list's own fetch. The screen falls back to the
  /// Lists tab's stamp while this provider has no data of its own.
  String get freshnessKey => 'todo_list:$listId';

  @override
  Future<TodoList?> build() {
    listenSelf(
      (previous, next) => recordFetch(ref, freshnessKey, previous, next),
    );
    return ref.watch(todoRepositoryProvider).list(listId);
  }

  TodoRepository get _repository => ref.read(todoRepositoryProvider);

  /// Runs [write] against an optimistically patched list. [patch] is applied
  /// to the current list at once; [settle] folds the server's answer into
  /// whatever the list looks like by then (later taps may have landed).
  Future<void> _mutate<R>({
    required TodoList Function(TodoList list) patch,
    required Future<R> Function() write,
    TodoList Function(TodoList list, R result)? settle,
  }) async {
    // On a cold launch the screen is showing the Lists tab's cached copy while
    // this provider's own fetch still waits on the database. A tap then has
    // to work on that copy - it is the list the user is looking at.
    final seededFromCache = state.value == null;
    final before = state.value ?? _cachedCopy();
    if (before == null) return;

    state = AsyncData(patch(before));
    try {
      final result = await ref
          .read(pendingWritesProvider.notifier)
          .track(write);
      final current = state.value;
      if (settle != null && current != null) {
        state = AsyncData(settle(current, result));
      }
    } catch (_) {
      // Rolled back to the snapshot, not re-fetched: the fetch would wait on
      // the same server that just failed.
      state = AsyncData(before);
      rethrow;
    }
    ref.invalidate(todoListsProvider);
    // The fetch that was in flight when the tap happened predates the write;
    // whatever it returns is not to be trusted over what was just patched.
    // Invalidating discards it and re-reads, with the patched list kept on
    // screen meanwhile.
    if (seededFromCache) ref.invalidateSelf();
  }

  TodoList? _cachedCopy() => ref
      .read(todoListsProvider)
      .value
      ?.where((list) => list.id == listId)
      .firstOrNull;

  Future<void> toggle(int itemId) => _mutate(
    patch: (list) => _mapItem(
      list,
      itemId,
      (item) => item.copyWith(
        isCompleted: !item.isCompleted,
        completedAt: item.isCompleted ? null : DateTime.now(),
      ),
    ),
    write: () => _repository.toggleItem(itemId),
    settle: _replaceWithServer,
  );

  Future<void> updateItem(int itemId, UpdateTodoItem body) => _mutate(
    patch: (list) => _mapItem(list, itemId, (item) => _apply(item, body)),
    write: () => _repository.updateItem(itemId, body),
    settle: _replaceWithServer,
  );

  Future<void> deleteItem(int itemId) => _mutate(
    patch: (list) => _withoutItem(list, itemId),
    write: () => _repository.deleteItem(itemId),
  );

  /// Shows a placeholder at the end of the ungrouped items until the server
  /// hands back the real one. Placeholders carry a negative id; rows treat
  /// them as read-only until they are swapped.
  Future<void> addItem({required String content, String? location}) {
    final tempId = _nextTempId--;
    return _mutate(
      patch: (list) => list.copyWith(
        items: [
          ...list.items,
          TodoItem(
            id: tempId,
            todoListId: list.id,
            content: content,
            location: location,
            isCompleted: false,
            displayOrder: list.allItems.length,
            indentLevel: 0,
          ),
        ],
        totalItems: list.totalItems + 1,
      ),
      write: () =>
          _repository.addItem(listId, content: content, location: location),
      settle: (list, created) => created == null
          ? _withoutItem(list, tempId)
          : _mapItem(list, tempId, (_) => created),
    );
  }

  // --- pure helpers ---------------------------------------------------------

  static TodoList _replaceWithServer(TodoList list, TodoItem? fromServer) =>
      fromServer == null
      ? list
      : _mapItem(list, fromServer.id, (_) => fromServer);

  /// Applies an [UpdateTodoItem] locally the way the API will: only the
  /// fields it carries change, with the same sentinels for "clear".
  static TodoItem _apply(TodoItem item, UpdateTodoItem body) => item.copyWith(
    content: body.content ?? item.content,
    isCompleted: body.isCompleted ?? item.isCompleted,
    displayOrder: body.displayOrder ?? item.displayOrder,
    indentLevel: body.indentLevel ?? item.indentLevel,
    groupId: body.removeFromGroup ? null : (body.groupId ?? item.groupId),
    location: body.clearLocation ? null : (body.location ?? item.location),
  );

  /// Rewrites one item wherever it lives. If the rewrite changes its group,
  /// the item moves section - which is what the server's next read would
  /// show too.
  static TodoList _mapItem(
    TodoList list,
    int itemId,
    TodoItem Function(TodoItem item) change,
  ) {
    final all = list.allItems;
    final index = all.indexWhere((item) => item.id == itemId);
    if (index < 0) return list;
    final changed = change(all[index]);
    final rest = [...all]..removeAt(index);
    return _rebuild(list, [...rest, changed]);
  }

  static TodoList _withoutItem(TodoList list, int itemId) => _rebuild(
    list,
    list.allItems.where((item) => item.id != itemId).toList(),
    totalItems: list.totalItems - 1,
  );

  /// Distributes a flat set of items back into the list's ungrouped section
  /// and its groups, in display order, and recounts completions.
  static TodoList _rebuild(
    TodoList list,
    List<TodoItem> items, {
    int? totalItems,
  }) {
    int order(TodoItem a, TodoItem b) =>
        a.displayOrder.compareTo(b.displayOrder);
    final ungrouped = items.where((item) => item.groupId == null).toList()
      ..sort(order);
    return list.copyWith(
      items: ungrouped,
      groups: [
        for (final group in list.groups)
          group.copyWith(
            items: items.where((item) => item.groupId == group.id).toList()
              ..sort(order),
          ),
      ],
      totalItems: totalItems ?? list.totalItems,
      completedItems: items.where((item) => item.isCompleted).length,
    );
  }
}
