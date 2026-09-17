import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/data/models/todo_models.dart';

/// `UpdateTodoItem` encodes two "clear" intents as sentinels the API expects:
/// `groupId: 0` and `location: ""`. These pin the wire shape, since sending
/// null for either is silently ignored server-side.
void main() {
  test('location is sent when given and omitted when not', () {
    expect(
      const UpdateTodoItem(location: 'Aisle 7').toJson(),
      {'location': 'Aisle 7'},
    );
    expect(const UpdateTodoItem(content: 'Milk').toJson(), {'content': 'Milk'});
  });

  test('clearLocation sends the empty string and wins over location', () {
    expect(
      const UpdateTodoItem(clearLocation: true).toJson(),
      {'location': ''},
    );
    expect(
      const UpdateTodoItem(location: 'Bakery', clearLocation: true).toJson(),
      {'location': ''},
    );
  });

  test('removeFromGroup sends the 0 sentinel and wins over groupId', () {
    expect(const UpdateTodoItem(groupId: 4).toJson(), {'groupId': 4});
    expect(
      const UpdateTodoItem(groupId: 4, removeFromGroup: true).toJson(),
      {'groupId': 0},
    );
  });
}
