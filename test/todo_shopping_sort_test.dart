import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/data/models/todo_models.dart';

TodoItem _item(
  int id,
  String content, {
  bool done = false,
  int? groupId,
  int order = 0,
}) =>
    TodoItem(
      id: id,
      todoListId: 1,
      groupId: groupId,
      content: content,
      isCompleted: done,
      displayOrder: order,
      indentLevel: 0,
    );

List<String> _names(List<TodoItem> items) =>
    items.map((item) => item.content).toList();

void main() {
  group('sortShopping', () {
    test('unchecked items come first, then checked, each alphabetical', () {
      final sorted = sortShopping([
        _item(1, 'Milk', done: true, order: 0),
        _item(2, 'Eggs', order: 1),
        _item(3, 'Apples', done: true, order: 2),
        _item(4, 'Bread', order: 3),
      ]);

      expect(_names(sorted), ['Bread', 'Eggs', 'Apples', 'Milk']);
    });

    test('ignores case', () {
      final sorted = sortShopping([
        _item(1, 'bananas', order: 0),
        _item(2, 'Apples', order: 1),
        _item(3, 'cheese', order: 2),
      ]);

      expect(_names(sorted), ['Apples', 'bananas', 'cheese']);
    });

    test('equal names keep their display order', () {
      final sorted = sortShopping([
        _item(2, 'Milk', order: 5),
        _item(1, 'Milk', order: 1),
        _item(3, 'milk', order: 3),
      ]);

      expect(sorted.map((item) => item.id), [1, 3, 2]);
    });

    test('returns a new list and leaves the input alone', () {
      final input = [_item(1, 'Milk', order: 0), _item(2, 'Eggs', order: 1)];
      final sorted = sortShopping(input);

      expect(_names(input), ['Milk', 'Eggs']);
      expect(_names(sorted), ['Eggs', 'Milk']);
    });
  });

  group('TodoList.shoppingSorted', () {
    test('sorts the ungrouped items and each group independently', () {
      final list = TodoList(
        id: 1,
        title: 'Groceries',
        isPinned: false,
        isArchived: false,
        displayOrder: 0,
        items: [
          _item(1, 'Milk', done: true, order: 0),
          _item(2, 'Eggs', order: 1),
        ],
        groups: [
          TodoItemGroup(
            id: 10,
            todoListId: 1,
            name: 'Bakery',
            displayOrder: 0,
            items: [
              _item(3, 'Rolls', order: 2),
              _item(4, 'Bagels', order: 3),
              // Would sort first overall; must stay in its group.
              _item(5, 'Almond croissant', done: true, order: 4),
            ],
          ),
        ],
        labels: const [],
        totalItems: 5,
        completedItems: 2,
      );

      final sorted = list.shoppingSorted;

      expect(_names(sorted.items), ['Eggs', 'Milk']);
      expect(_names(sorted.groups.single.items), [
        'Bagels',
        'Rolls',
        'Almond croissant',
      ]);
      // The original is untouched: it still carries the server's order.
      expect(_names(list.items), ['Milk', 'Eggs']);
      expect(list.reorderPayload(), [1, 2, 3, 4, 5]);
    });
  });
}
