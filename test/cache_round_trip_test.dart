import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/core/cache/cached_list.dart';
import 'package:pham_dash_flutter/data/models/calendar_models.dart';
import 'package:pham_dash_flutter/data/models/converters.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/data/models/todo_models.dart';

/// Every model a `CachedList` stores has to survive `toJson` -> `fromJson`
/// unchanged, or the cached copy would silently differ from what the API
/// sent. The converters are the risk: `WallClock` must not shift a birthday
/// and `UtcStamp` must come back as the same instant, so each gets a value.
void main() {
  const tag = PersonTag(id: 3, name: 'Pickleball', personCount: 2);

  final person = Person(
    id: 'p1',
    firstName: 'Tu',
    lastName: 'Pham',
    vietnameseName: 'Tú',
    homeAddress: '1 Main St',
    birthDate: DateTime(1990, 6, 15),
    profilePictureUrl: '/uploads/p1.jpg?exp=1&sig=abc',
    tags: const [tag],
  );

  List<T> roundTrip<T>(
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      decodeEncodedList(encodeList(items, toJson), fromJson);

  test('people and tags', () {
    expect(roundTrip([person], (p) => p.toJson(), Person.fromJson), [person]);
    expect(roundTrip([tag], (t) => t.toJson(), PersonTag.fromJson), [tag]);
  });

  test('upcoming birthdays keep their wall-clock birth date', () {
    final birthday = UpcomingBirthday(
      id: 'p1',
      firstName: 'Tu',
      lastName: 'Pham',
      birthDate: DateTime(1990, 6, 15),
      profilePictureUrl: '/uploads/p1.jpg?exp=1&sig=abc',
      daysUntilBirthday: 3,
      upcomingAge: 36,
    );
    final back = roundTrip(
      [birthday],
      (b) => b.toJson(),
      UpcomingBirthday.fromJson,
    );
    expect(back, [birthday]);
    expect(back.single.birthDate, DateTime(1990, 6, 15));
  });

  test('recent notes, with their embedded author', () {
    final note = Note(
      noteId: 7,
      personId: 'p1',
      content: 'Called about the roof.',
      createdAt: DateTime.utc(2026, 9, 14, 18, 30).toLocal(),
      category: 'General',
      person: person,
    );
    expect(roundTrip([note], (n) => n.toJson(), Note.fromJson), [note]);
  });

  test('the bulk notes list, without an author', () {
    // `/api/notes` leaves `person` null; the same `fromJson` must read it.
    final note = Note(
      noteId: 8,
      personId: 'p1',
      content: '**Bold** plans.',
      createdAt: DateTime.utc(2026, 9, 1, 8).toLocal(),
    );
    expect(roundTrip([note], (n) => n.toJson(), Note.fromJson), [note]);
  });

  test('relationships keep their integer type and both date kinds', () {
    final relationship = Relationship(
      relationshipId: 12,
      personId: 'p1',
      relatedPersonId: 'p2',
      type: RelationshipType.sibling,
      createdAt: DateTime.utc(2026, 3, 3, 3).toLocal(),
      relatedPersonFirstName: 'Ha',
      relatedPersonLastName: 'Pham',
      relatedPersonBirthDate: DateTime(1988, 2, 29),
      relatedPersonProfilePictureUrl: '/uploads/p2.jpg?exp=1&sig=def',
    );
    expect(
      roundTrip([relationship], (r) => r.toJson(), Relationship.fromJson),
      [relationship],
    );
  });

  test('person pictures', () {
    final picture = PersonPicture(
      id: 4,
      personId: 'p1',
      profilePictureUrl: '/uploads/p1_004.jpg?exp=1&sig=ghi',
      isPrimary: true,
      uploadedAt: DateTime.utc(2026, 8, 8, 8).toLocal(),
    );
    expect(
      roundTrip([picture], (p) => p.toJson(), PersonPicture.fromJson),
      [picture],
    );
  });

  test('schedule events keep their wall-clock times', () {
    final event = CalendarEvent(
      id: 'e1',
      title: 'Dentist',
      start: DateTime(2026, 9, 16, 9, 30),
      end: DateTime(2026, 9, 16, 10),
      isAllDay: false,
      attendees: const [EventAttendeeRef(personId: 'p1', name: 'Tu Pham')],
      categories: const [EventCategory(id: 1, name: 'Health')],
    );
    final back = roundTrip([event], (e) => e.toJson(), CalendarEvent.fromJson);
    expect(back, [event]);
    expect(back.single.start, DateTime(2026, 9, 16, 9, 30));
  });

  test('todo lists with items, groups, labels and stamps', () {
    const label = TodoLabel(id: 1, name: 'Chores', listCount: 1);
    final item = TodoItem(
      id: 10,
      todoListId: 5,
      content: 'Milk',
      isCompleted: true,
      displayOrder: 0,
      indentLevel: 0,
      createdAt: DateTime.utc(2026, 9, 1, 8).toLocal(),
      completedAt: DateTime.utc(2026, 9, 2, 8).toLocal(),
    );
    final list = TodoList(
      id: 5,
      title: 'Groceries',
      color: '#22c55e',
      isPinned: true,
      isArchived: false,
      displayOrder: 1,
      createdAt: DateTime.utc(2026, 8, 30, 12).toLocal(),
      updatedAt: DateTime.utc(2026, 9, 2, 8).toLocal(),
      reminderDateTime: DateTime(2026, 9, 20, 7),
      items: [item],
      groups: [
        TodoItemGroup(
          id: 2,
          todoListId: 5,
          name: 'Dairy',
          displayOrder: 0,
          items: [item],
        ),
      ],
      labels: const [label],
      totalItems: 1,
      completedItems: 1,
    );
    expect(roundTrip([list], (l) => l.toJson(), TodoList.fromJson), [list]);
    expect(roundTrip([label], (l) => l.toJson(), TodoLabel.fromJson), [label]);
  });
}
