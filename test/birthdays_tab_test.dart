import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/api/api_client.dart';
import 'package:pham_dash_flutter/core/auth/auth_service.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/core/ui/async_view.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/data/repositories/people_repository.dart';
import 'package:pham_dash_flutter/features/birthdays/birthdays_tab.dart';

final _saved = UpcomingBirthday(
  id: 'p1',
  firstName: 'Tu',
  lastName: 'Pham',
  birthDate: DateTime(1990, 6, 15),
  daysUntilBirthday: 3,
  upcomingAge: 36,
);

/// Only the read the tab performs is faked; it waits on [gate] so the test
/// can look at the screen while "the database is still waking".
class _FakePeople extends PeopleRepository {
  _FakePeople(super.api);

  Completer<void>? gate;

  @override
  Future<List<UpcomingBirthday>> upcomingBirthdays({int count = 8}) async {
    await gate?.future;
    return [_saved.copyWith(daysUntilBirthday: 2)];
  }
}

void main() {
  testWidgets('a cold launch shows the saved birthdays while the fetch waits',
      (tester) async {
    final store = Storage<String, String>.inMemory();
    store.write(
      'birthdays',
      jsonEncode([_saved.toJson()]),
      const StorageOptions(),
    );
    final gate = Completer<void>();
    final people = _FakePeople(ApiClient(AuthService()))..gate = gate;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          peopleRepositoryProvider.overrideWithValue(people),
          cacheStorageProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(home: Scaffold(body: BirthdaysTab())),
      ),
    );
    await tester.pump();

    expect(find.text('Tu Pham'), findsOneWidget);
    expect(find.byType(RefreshingStrip), findsOneWidget);
    expect(find.byType(PatientLoading), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(RefreshingStrip), findsNothing);
    expect(find.text('Tu Pham'), findsOneWidget);
  });
}
