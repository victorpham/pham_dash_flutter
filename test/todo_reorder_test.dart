import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/data/models/todo_models.dart';

TodoItem _item(int id) => TodoItem(
      id: id,
      todoListId: 1,
      content: 'Item $id',
      isCompleted: false,
      displayOrder: id,
      indentLevel: 0,
    );

TodoItemGroup _group(int id, String name, List<int> itemIds) => TodoItemGroup(
      id: id,
      todoListId: 1,
      name: name,
      displayOrder: id,
      items: itemIds.map(_item).toList(),
    );

TodoList _list({
  List<int> ungrouped = const [],
  List<TodoItemGroup> groups = const [],
}) =>
    TodoList(
      id: 1,
      title: 'Packing',
      isPinned: false,
      isArchived: false,
      displayOrder: 0,
      items: ungrouped.map(_item).toList(),
      groups: groups,
      labels: const [],
      totalItems: 0,
      completedItems: 0,
    );

void main() {
  group('reorderPayload', () {
    test('carries every item, ungrouped first then each group', () {
      final list = _list(
        ungrouped: [1, 2],
        groups: [
          _group(10, 'Clothes', [3, 4]),
          _group(11, 'Tech', [5]),
        ],
      );

      expect(list.reorderPayload(), [1, 2, 3, 4, 5]);
    });

    test('applies a new ungrouped ordering and leaves the groups alone', () {
      final list = _list(
        ungrouped: [1, 2, 3],
        groups: [
          _group(10, 'Clothes', [4, 5]),
        ],
      );

      expect(list.reorderPayload(ungrouped: [3, 1, 2]), [3, 1, 2, 4, 5]);
    });

    test('applies a new ordering inside one group only', () {
      final list = _list(
        ungrouped: [1],
        groups: [
          _group(10, 'Clothes', [2, 3]),
          _group(11, 'Tech', [4, 5]),
        ],
      );

      expect(
        list.reorderPayload(groups: {
          11: [5, 4],
        }),
        [1, 2, 3, 5, 4],
      );
    });

    // The whole point of the payload: omitted ids keep their old displayOrder,
    // so a partial send would collide with the ids that did move.
    test('a moved group still sends the ungrouped items', () {
      final list = _list(
        ungrouped: [1, 2],
        groups: [
          _group(10, 'Clothes', [3, 4]),
        ],
      );

      final payload = list.reorderPayload(groups: {
        10: [4, 3],
      });

      expect(payload.length, 4);
      expect(payload.take(2), [1, 2]);
    });

    test('an empty list sends nothing', () {
      expect(_list().reorderPayload(), isEmpty);
    });
  });
}
