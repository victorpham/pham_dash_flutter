import '../../core/api/api_client.dart';
import '../models/todo_models.dart';
import 'decode.dart';

/// Todo lists, items, groups and labels.
///
/// Deliberately exposes **targeted** operations rather than a save-the-whole-
/// list call. The web editor recomputes a full client-side diff on every save
/// and issues N+M requests to apply it; on mobile that is both slow and easy to
/// get wrong. There is no bulk-update endpoint - adding one would be a
/// worthwhile API change.
class TodoRepository {
  const TodoRepository(this._api);

  final ApiClient _api;

  // --- Lists ---------------------------------------------------------------

  /// Ordered pinned-first, then by `displayOrder`, then by
  /// `updatedAt ?? createdAt` descending. Archived lists are excluded unless
  /// [includeArchived] is set.
  Future<List<TodoList>> lists({bool includeArchived = false}) async =>
      decodeList(
        await _api.get<dynamic>(
          '/todo/lists',
          query: {'includeArchived': includeArchived},
        ),
        TodoList.fromJson,
      );

  Future<TodoList?> list(int id) async => decodeOrNull(
        await _api.get<dynamic>('/todo/lists/$id'),
        TodoList.fromJson,
      );

  Future<List<TodoList>> listsForPerson(String personId) async => decodeList(
        await _api.get<dynamic>('/todo/lists/person/$personId'),
        TodoList.fromJson,
      );

  Future<TodoList?> createList(CreateTodoList body) async => decodeOrNull(
        await _api.post<dynamic>('/todo/lists', body: body.toJson()),
        TodoList.fromJson,
      );

  Future<TodoList?> updateList(int id, UpdateTodoList body) async =>
      decodeOrNull(
        await _api.put<dynamic>('/todo/lists/$id', body: body.toJson()),
        TodoList.fromJson,
      );

  /// Answers 204 even when the list never existed.
  Future<void> deleteList(int id) => _api.delete('/todo/lists/$id');

  /// A **toggle**, not a setter - it flips the current value and returns the
  /// new one.
  Future<bool?> togglePin(int id) async {
    final data = await _api.post<dynamic>('/todo/lists/$id/pin');
    return data is Map ? data['isPinned'] as bool? : null;
  }

  /// A **toggle**, not a setter.
  Future<bool?> toggleArchive(int id) async {
    final data = await _api.post<dynamic>('/todo/lists/$id/archive');
    return data is Map ? data['isArchived'] as bool? : null;
  }

  /// Clears every completion on the list.
  ///
  /// The caller should restore the item order captured when the list was first
  /// loaded - completed-last sorting will have reshuffled it since.
  Future<void> resetItems(int id) =>
      _api.post<dynamic>('/todo/lists/$id/reset-items');

  // --- Items ---------------------------------------------------------------

  /// New items always land at the end (`displayOrder = max + 1` within the
  /// list), regardless of where the UI shows them being added.
  Future<TodoItem?> addItem(
    int listId, {
    required String content,
    int? indentLevel,
    int? groupId,
    String? location,
  }) async =>
      decodeOrNull(
        await _api.post<dynamic>(
          '/todo/lists/$listId/items',
          body: {
            'content': content,
            'indentLevel': ?indentLevel,
            'groupId': ?groupId,
            'location': ?location,
          },
        ),
        TodoItem.fromJson,
      );

  Future<TodoItem?> updateItem(int itemId, UpdateTodoItem body) async =>
      decodeOrNull(
        await _api.put<dynamic>('/todo/items/$itemId', body: body.toJson()),
        TodoItem.fromJson,
      );

  Future<void> deleteItem(int itemId) => _api.delete('/todo/items/$itemId');

  /// Sets the item's picture, replacing any it already had. One picture per
  /// item - there is no gallery, unlike a person.
  ///
  /// Multipart with the field named `file`; the server enforces the type and
  /// 5 MB rules and answers 400 with a readable message when they fail. Also
  /// cleaned up server-side when the item or its list is deleted.
  Future<TodoItem?> setItemImage(
    int itemId, {
    required String filePath,
    required String fileName,
  }) async =>
      decodeOrNull(
        await _api.upload<dynamic>(
          '/todo/items/$itemId/image',
          filePath: filePath,
          fileName: fileName,
        ),
        TodoItem.fromJson,
      );

  /// Removes the item's picture. Idempotent: answers 200 even if it had none.
  Future<void> removeItemImage(int itemId) =>
      _api.delete('/todo/items/$itemId/image');

  /// Flips completion, and sets or clears `completedAt` server-side.
  Future<TodoItem?> toggleItem(int itemId) async => decodeOrNull(
        await _api.post<dynamic>('/todo/items/$itemId/toggle'),
        TodoItem.fromJson,
      );

  /// Assigns `displayOrder = index` for the ids sent, scoped to the list.
  ///
  /// **Send the full ordering.** Ids you omit keep their old `displayOrder`,
  /// which produces duplicate positions.
  Future<void> reorderItems(int listId, List<int> itemIds) => _api.post<dynamic>(
        '/todo/lists/$listId/items/reorder',
        body: {'itemIds': itemIds},
      );

  // --- Groups --------------------------------------------------------------

  Future<TodoItemGroup?> addGroup(int listId, String name) async =>
      decodeOrNull(
        await _api.post<dynamic>(
          '/todo/lists/$listId/groups',
          body: {'name': name},
        ),
        TodoItemGroup.fromJson,
      );

  Future<TodoItemGroup?> updateGroup(
    int groupId, {
    String? name,
    int? displayOrder,
  }) async =>
      decodeOrNull(
        await _api.put<dynamic>(
          '/todo/groups/$groupId',
          body: {
            'name': ?name,
            'displayOrder': ?displayOrder,
          },
        ),
        TodoItemGroup.fromJson,
      );

  Future<void> deleteGroup(int groupId) => _api.delete('/todo/groups/$groupId');

  /// Note the asymmetry with [reorderItems]: group reorder takes a **bare JSON
  /// array**, item reorder takes `{ "itemIds": [...] }`.
  Future<void> reorderGroups(int listId, List<int> groupIds) =>
      _api.post<dynamic>('/todo/lists/$listId/groups/reorder', body: groupIds);

  // --- Labels --------------------------------------------------------------

  Future<List<TodoLabel>> labels() async => decodeList(
        await _api.get<dynamic>('/todo/labels'),
        TodoLabel.fromJson,
      );

  Future<TodoLabel?> createLabel(String name, {String? color}) async =>
      decodeOrNull(
        await _api.post<dynamic>(
          '/todo/labels',
          body: {'name': name, 'color': ?color},
        ),
        TodoLabel.fromJson,
      );

  Future<TodoLabel?> updateLabel(
    int labelId, {
    String? name,
    String? color,
  }) async =>
      decodeOrNull(
        await _api.put<dynamic>(
          '/todo/labels/$labelId',
          body: {
            'name': ?name,
            'color': ?color,
          },
        ),
        TodoLabel.fromJson,
      );

  Future<void> deleteLabel(int labelId) => _api.delete('/todo/labels/$labelId');

  Future<void> addLabelToList(int listId, int labelId) =>
      _api.post<dynamic>('/todo/lists/$listId/labels/$labelId');

  Future<void> removeLabelFromList(int listId, int labelId) =>
      _api.delete('/todo/lists/$listId/labels/$labelId');

  Future<List<TodoList>> listsWithLabel(int labelId) async => decodeList(
        await _api.get<dynamic>('/todo/labels/$labelId/lists'),
        TodoList.fromJson,
      );
}
