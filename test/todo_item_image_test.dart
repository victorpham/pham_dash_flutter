import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/todo_models.dart';
import 'package:pham_dash_flutter/data/repositories/todo_repository.dart';
import 'package:pham_dash_flutter/features/todo/todo_item_image.dart';
import 'package:pham_dash_flutter/features/todo/todo_list_detail_screen.dart';

const _milk = TodoItem(
  id: 1,
  todoListId: 10,
  content: 'Milk',
  isCompleted: false,
  displayOrder: 0,
  indentLevel: 0,
  // Signed, the way the API hands it out. The query string is the credential.
  imageUrl: '/uploads/todo-items/1_20260915_ab.jpg?exp=1&sig=a',
);

const _eggs = TodoItem(
  id: 2,
  todoListId: 10,
  content: 'Eggs',
  isCompleted: false,
  displayOrder: 1,
  indentLevel: 0,
);

const _groceries = TodoList(
  id: 10,
  title: 'Groceries',
  isPinned: false,
  isArchived: false,
  displayOrder: 0,
  items: [_milk, _eggs],
  groups: [],
  labels: [],
  totalItems: 2,
  completedItems: 0,
);

/// Subclasses rather than implements - see `todo_lists_tab_test.dart`. Records
/// the image writes so the sheet's actions can be asserted at the endpoint.
class _FakeTodos extends TodoRepository {
  _FakeTodos(super.api);

  final removed = <int>[];

  @override
  Future<TodoList?> list(int id) async => _groceries;

  @override
  Future<void> removeItemImage(int itemId) async => removed.add(itemId);
}

Future<_FakeTodos> _pump(WidgetTester tester) async {
  final todos = _FakeTodos(ApiClient(AuthService()));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todoRepositoryProvider.overrideWithValue(todos),
        cacheStorageProvider.overrideWithValue(Storage.inMemory()),
      ],
      child: const MaterialApp(home: TodoListDetailScreen(listId: 10)),
    ),
  );
  await tester.pumpAndSettle();
  return todos;
}

void main() {
  _viewerTests();

  // CachedNetworkImage never gets to fetch anything under test, so the
  // assertions are on the thumbnail's wrapper key rather than on pixels.
  testWidgets('an item with a picture shows a thumbnail; one without does not',
      (tester) async {
    await _pump(tester);

    expect(find.byKey(const ValueKey('item-image-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('item-image-2')), findsNothing);
  });

  testWidgets('long-press offers Remove photo only when there is one',
      (tester) async {
    await _pump(tester);

    await tester.longPress(find.text('Eggs'));
    await tester.pumpAndSettle();
    expect(find.text('Edit text'), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Remove photo'), findsNothing);

    // Dismiss the sheet.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Milk'));
    await tester.pumpAndSettle();
    expect(find.text('Remove photo'), findsOneWidget);
  });

  testWidgets('Remove photo confirms, then calls the endpoint', (tester) async {
    final todos = await _pump(tester);

    await tester.longPress(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();

    expect(find.text('Remove this photo?'), findsOneWidget);
    expect(todos.removed, isEmpty);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(todos.removed, [1]);
  });
}

void _viewerTests() {
  Future<void> pumpViewer(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTodoItemImage(context, _milk),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // Two frames, not pumpAndSettle: the route needs one to push and one to
    // build, and the loading spinner would keep pumpAndSettle waiting forever.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(TodoItemImageViewer), findsOneWidget);
  }

  testWidgets('tapping the backdrop closes the viewer', (tester) async {
    await pumpViewer(tester);

    // Bottom corner: well outside any centred image.
    final backdrop = find.byKey(const ValueKey('item-image-backdrop'));
    await tester.tapAt(tester.getBottomLeft(backdrop) + const Offset(8, -8));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(TodoItemImageViewer), findsNothing);
  });

  testWidgets('tapping the image itself does not close the viewer',
      (tester) async {
    await pumpViewer(tester);

    // The InteractiveViewer is sized to whatever the image slot shows - under
    // test, the placeholder or the broken-image icon - so its centre is "on
    // the image" either way.
    await tester.tap(find.byType(InteractiveViewer));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(TodoItemImageViewer), findsOneWidget);
  });
}
