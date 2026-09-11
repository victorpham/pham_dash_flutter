import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/data/models/people_models.dart';
import 'package:pham_dash_flutter/features/people/people_screen.dart';

final _today = DateTime.now();

/// A person whose birthday falls [days] from today, at some past year so the
/// age is realistic.
Person _inDays(int days, {String last = 'Pham', String first = 'Ha'}) {
  final target = DateTime(_today.year, _today.month, _today.day)
      .add(Duration(days: days));
  return Person(
    id: '$first$last$days',
    firstName: first,
    lastName: last,
    birthDate: DateTime(target.year - 30, target.month, target.day),
  );
}

Person _undated({required String last, String first = 'A'}) =>
    Person(id: '$first$last', firstName: first, lastName: last);

List<String> _order(List<Person> people) {
  final sorted = [...people]..sort(comparePeopleByUpcomingBirthday);
  return sorted.map((person) => person.id).toList();
}

void main() {
  group('days until birthday', () {
    test('a birthday today is zero, not a year away', () {
      expect(_inDays(0).daysUntilBirthday, 0);
    });

    test('counts forward to an upcoming birthday', () {
      expect(_inDays(1).daysUntilBirthday, 1);
      expect(_inDays(30).daysUntilBirthday, 30);
    });

    test('a birthday already past rolls to next year', () {
      final yesterday = _inDays(-1).daysUntilBirthday!;
      expect(yesterday, greaterThan(300));
    });

    test('is null without a birth date', () {
      expect(_undated(last: 'Tran').daysUntilBirthday, isNull);
    });

    // Dart's DateTime rolls 29 February into 1 March in a common year, which
    // would put a leapling's birthday in the wrong month and a day late.
    // .NET's AddYears clamps to the 28th, and this must match it.
    test('a 29 February birthday stays in February', () {
      final person = Person(
        id: 'leap',
        firstName: 'Leap',
        lastName: 'Day',
        birthDate: DateTime(2016, 2, 29),
      );

      final days = person.daysUntilBirthday;
      expect(days, isNotNull);

      // Walk forward from today the way the getter does, and see where it
      // landed. Clamped, that is always February; rolled over, it is March.
      final now = DateTime.now();
      final resolved = DateTime.utc(now.year, now.month, now.day)
          .add(Duration(days: days!));

      expect(resolved.month, DateTime.february);
      expect(resolved.day, anyOf(28, 29));
    });
  });

  group('countdown wording', () {
    test('reads Today!, Tomorrow, then a day count', () {
      expect(_inDays(0).birthdayCountdown, 'Today!');
      expect(_inDays(1).birthdayCountdown, 'Tomorrow');
      expect(_inDays(12).birthdayCountdown, 'In 12 days');
    });

    test('is absent without a birth date', () {
      expect(_undated(last: 'Tran').birthdayCountdown, isNull);
    });
  });

  group('ordering', () {
    test('soonest birthday first', () {
      final people = [
        _inDays(40, first: 'Forty'),
        _inDays(0, first: 'Today'),
        _inDays(7, first: 'Week'),
      ];

      expect(_order(people), ['TodayPham0', 'WeekPham7', 'FortyPham40']);
    });

    test('people without a birthday sink to the bottom', () {
      final people = [
        _undated(last: 'Aaronson'),
        _inDays(200, first: 'Far'),
        _undated(last: 'Baker'),
      ];

      expect(_order(people).last, 'ABaker');
      expect(_order(people).first, 'FarPham200');
    });

    test('the undated group is alphabetical by last name', () {
      final people = [
        _undated(last: 'Tran'),
        _undated(last: 'Nguyen'),
        _undated(last: 'Pham'),
      ];

      expect(_order(people), ['ANguyen', 'APham', 'ATran']);
    });

    test('a shared birthday falls back to last name, then first', () {
      final people = [
        _inDays(5, first: 'Zoe', last: 'Pham'),
        _inDays(5, first: 'Amy', last: 'Pham'),
        _inDays(5, first: 'Bo', last: 'Nguyen'),
      ];

      expect(_order(people), ['BoNguyen5', 'AmyPham5', 'ZoePham5']);
    });

    test('sorting is case-insensitive on names', () {
      final people = [
        _undated(last: 'tran'),
        _undated(last: 'Nguyen'),
      ];

      expect(_order(people), ['ANguyen', 'Atran']);
    });

    test('an empty directory sorts to nothing', () {
      expect(_order(const []), isEmpty);
    });
  });
}
