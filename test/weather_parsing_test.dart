import 'package:flutter_test/flutter_test.dart';
import 'package:pham_dash_flutter/data/repositories/weather_repository.dart';

/// An NWS timestamp: a real ISO string *with* an offset, unlike the PhamDash
/// API's. Built from a local time so the parsed result lands on the day the
/// test means, wherever the suite runs.
String _at(DateTime local) {
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}'
      'T${two(local.hour)}:${two(local.minute)}:00$sign$hours:$minutes';
}

Map<String, dynamic> _period({
  required DateTime start,
  required int temperature,
  bool isDaytime = true,
  String shortForecast = 'Sunny',
  String icon = 'https://api.weather.gov/icons/land/day/skc?size=medium',
  String windSpeed = '10 mph',
  int? precipitationChance,
}) =>
    {
      'startTime': _at(start),
      'isDaytime': isDaytime,
      'temperature': temperature,
      'shortForecast': shortForecast,
      'icon': icon,
      'windSpeed': windSpeed,
      if (precipitationChance != null)
        'probabilityOfPrecipitation': {'value': precipitationChance},
    };

void main() {
  group('wind speed', () {
    test('reads a plain speed', () {
      expect(WeatherRepository.parseWindSpeed('10 mph'), 10);
    });

    // A range read as its low end would show a gusty afternoon as calm.
    test('takes the upper bound of a range', () {
      expect(WeatherRepository.parseWindSpeed('5 to 15 mph'), 15);
    });

    test('falls back to zero on junk or nothing', () {
      expect(WeatherRepository.parseWindSpeed(null), 0);
      expect(WeatherRepository.parseWindSpeed(''), 0);
      expect(WeatherRepository.parseWindSpeed('calm'), 0);
    });
  });

  group('condition wording', () {
    // Order matters: this phrase contains both "showers" and "thunderstorms".
    test('severity wins over the earlier words in the phrase', () {
      expect(
        WeatherRepository.describeMain('Chance Rain Showers and Thunderstorms'),
        'Thunderstorm',
      );
    });

    test('classifies the common phrasings', () {
      expect(WeatherRepository.describeMain('Sunny'), 'Clear');
      expect(WeatherRepository.describeMain('Mostly Cloudy'), 'Clouds');
      expect(WeatherRepository.describeMain('Light Snow'), 'Snow');
      expect(WeatherRepository.describeMain('Patchy Fog'), 'Fog');
      expect(WeatherRepository.describeMain('Slight Chance Drizzle'), 'Drizzle');
    });

    test('an unrecognised phrase does not blow up', () {
      expect(WeatherRepository.describeMain('Volcanic Ash'), 'Clear');
    });
  });

  group('icon codes', () {
    test('reads the NWS abbreviations out of the url', () {
      expect(
        WeatherRepository.mapIconCode('/icons/land/day/tsra?size=medium', true),
        '11d',
      );
      expect(
        WeatherRepository.mapIconCode('/icons/land/night/bkn', false),
        '04n',
      );
      expect(WeatherRepository.mapIconCode('/icons/land/day/few', true), '02d');
    });

    test('day and night differ, and a missing url still yields a code', () {
      expect(WeatherRepository.mapIconCode(null, true), '01d');
      expect(WeatherRepository.mapIconCode(null, false), '01n');
    });
  });

  group('precipitation', () {
    test('converts millimetres to inches', () {
      final period = {
        'quantitativePrecipitation': {'value': 25.4},
      };
      expect(WeatherRepository.parsePrecipitation(period), 1.0);
    });

    test('is null when NWS reports nothing', () {
      expect(WeatherRepository.parsePrecipitation({}), isNull);
    });
  });

  group('hourly', () {
    test('takes only the requested number of hours', () {
      final start = DateTime.now();
      final periods = [
        for (var i = 0; i < 48; i++)
          _period(start: start.add(Duration(hours: i)), temperature: 60 + i),
      ];

      expect(WeatherRepository.parseHourly(periods, 24).length, 24);
      expect(WeatherRepository.parseHourly(periods, 48).length, 48);
    });

    test('defaults a missing precipitation chance to zero', () {
      final hours = WeatherRepository.parseHourly(
        [_period(start: DateTime.now(), temperature: 60)],
        24,
      );
      expect(hours.single.precipitationChance, 0);
    });
  });

  group('daily', () {
    test('merges the day and night periods into one entry', () {
      final today = DateTime.now();
      final noon = DateTime(today.year, today.month, today.day, 12);

      final daily = WeatherRepository.parseDaily(
        [
          _period(start: noon, temperature: 75, shortForecast: 'Sunny'),
          _period(
            start: noon.add(const Duration(hours: 8)),
            temperature: 55,
            isDaytime: false,
            shortForecast: 'Clear',
          ),
        ],
        const [],
      );

      expect(daily.length, 1);
      expect(daily.single.high, 75);
      expect(daily.single.low, 55);
      expect(daily.single.condition.main, 'Clear');
    });

    test('caps the forecast at seven days', () {
      final today = DateTime.now();
      final noon = DateTime(today.year, today.month, today.day, 12);

      final daily = WeatherRepository.parseDaily(
        [
          for (var i = 0; i < 10; i++)
            _period(
              start: noon.add(Duration(days: i)),
              temperature: 70 + i,
            ),
        ],
        const [],
      );

      expect(daily.length, 7);
    });

    // The reason the hourly series is passed in at all: opened at night,
    // today's daytime period is already gone from the daily forecast.
    test("fills a future day's missing high from the hourly series", () {
      final today = DateTime.now();
      final tomorrowNight =
          DateTime(today.year, today.month, today.day, 20).add(
        const Duration(days: 1),
      );

      final daily = WeatherRepository.parseDaily(
        [
          _period(
            start: tomorrowNight,
            temperature: 50,
            isDaytime: false,
            shortForecast: 'Clear',
          ),
        ],
        [
          _period(
            start: tomorrowNight.subtract(const Duration(hours: 8)),
            temperature: 81,
          ),
          _period(
            start: tomorrowNight.subtract(const Duration(hours: 6)),
            temperature: 77,
          ),
        ],
      );

      expect(daily.single.low, 50);
      expect(daily.single.high, 81, reason: 'the hourly maximum for that day');
    });

    test('today prefers the hourly high and low over the daily period', () {
      final today = DateTime.now();
      final noon = DateTime(today.year, today.month, today.day, 12);

      final daily = WeatherRepository.parseDaily(
        [_period(start: noon, temperature: 70)],
        [
          _period(start: noon, temperature: 90),
          _period(
            start: noon.add(const Duration(hours: 2)),
            temperature: 40,
          ),
        ],
      );

      expect(daily.single.high, 90);
      expect(daily.single.low, 40);
    });

    test('a day with only one reading repeats it rather than showing a gap',
        () {
      final today = DateTime.now();
      final future =
          DateTime(today.year, today.month, today.day, 12).add(
        const Duration(days: 3),
      );

      final daily = WeatherRepository.parseDaily(
        [_period(start: future, temperature: 68)],
        const [],
      );

      expect(daily.single.high, 68);
      expect(daily.single.low, 68);
    });

    test('an empty forecast yields no days', () {
      expect(WeatherRepository.parseDaily(const [], const []), isEmpty);
    });
  });
}
