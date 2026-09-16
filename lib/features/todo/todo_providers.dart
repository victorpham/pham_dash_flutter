import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_list.dart';
import '../../core/providers.dart';
import '../../data/models/todo_models.dart';

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
