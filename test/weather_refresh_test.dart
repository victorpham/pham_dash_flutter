import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pham_dash_flutter/core/providers.dart';
import 'package:pham_dash_flutter/data/models/weather_models.dart';
import 'package:pham_dash_flutter/data/repositories/weather_repository.dart';
import 'package:pham_dash_flutter/features/weather/weather_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _seattle = WeatherLocation(
  name: 'Seattle',
  state: 'WA',
  latitude: 47.6,
  longitude: -122.3,
);

/// Subclasses rather than implements - the repository owns a private Dio.
/// Each answer is stamped with [fetchedAt], so a test can hand back a forecast
/// that is already old.
class _FakeWeather extends WeatherRepository {
  int calls = 0;
  DateTime fetchedAt = DateTime(2026, 9, 15, 14, 5);

  @override
  Future<WeatherForecast> forecast(String city) async {
    calls++;
    return WeatherForecast(
      location: _seattle,
      daily: const [],
      hourly: const [],
      extendedHourly: const [],
      fetchedAt: fetchedAt,
    );
  }
}

void main() {
  late _FakeWeather weather;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'weatherCity': 'Seattle'});
    prefs = await SharedPreferences.getInstance();
    weather = _FakeWeather();
  });

  ProviderContainer container() => ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          weatherRepositoryProvider.overrideWithValue(weather),
        ],
      );

  group('refreshIfStale', () {
    test('leaves a forecast younger than fifteen minutes alone', () async {
      final c = container();
      await c.read(weatherForecastProvider.future);
      expect(weather.calls, 1);

      final notifier = c.read(weatherForecastProvider.notifier);
      await notifier.refreshIfStale(
        now: weather.fetchedAt.add(const Duration(minutes: 14)),
      );
      expect(weather.calls, 1);

      await notifier.refreshIfStale(
        now: weather.fetchedAt.add(const Duration(minutes: 15)),
      );
      expect(weather.calls, 2);
    });

    test('a failed fetch counts as stale', () async {
      final c = ProviderContainer.test(
        // Riverpod would otherwise retry the failure on its own timer.
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          weatherRepositoryProvider.overrideWithValue(_FailingWeather()),
        ],
      );
      await expectLater(c.read(weatherForecastProvider.future), throwsA(anything));

      // Swap in a working repository for the retry.
      c.updateOverrides([
        sharedPreferencesProvider.overrideWithValue(prefs),
        weatherRepositoryProvider.overrideWithValue(weather),
      ]);
      await c.read(weatherForecastProvider.notifier).refreshIfStale();
      expect(weather.calls, 1);
      expect(c.read(weatherForecastProvider).hasValue, isTrue);
    });
  });

  // The mechanism the tab uses to notice a visit: TickerMode flips on when
  // go_router shows the branch or the Navigator pops back to it. (Riverpod
  // pauses a hidden consumer's subscriptions on the same signal, so nothing
  // is asserted about what the tab shows while hidden.)
  testWidgets('the tab refetches a stale forecast when it becomes visible',
      (tester) async {
    final visible = ValueNotifier<bool>(false);
    addTearDown(visible.dispose);

    // With TickerMode off nothing animates, so `pumpAndSettle` can return
    // before the provider's completion has scheduled the rebuild; one more
    // frame picks it up.
    Future<void> settle() async {
      await tester.pumpAndSettle();
      await tester.pump();
    }

    // The first answer is already old, as a forecast held since before lunch
    // would be.
    weather.fetchedAt = DateTime.now().subtract(const Duration(minutes: 16));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          weatherRepositoryProvider.overrideWithValue(weather),
        ],
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (_, enabled, child) =>
                TickerMode(enabled: enabled, child: child!),
            child: const WeatherTab(),
          ),
        ),
      ),
    );
    await settle();
    expect(weather.calls, 1);

    // Coming into view with a stale forecast refetches; the answer this time
    // is fresh, and the stamp says so.
    weather.fetchedAt = DateTime.now();
    visible.value = true;
    await settle();
    expect(weather.calls, 2);
    expect(
      find.text('Updated ${DateFormat('h:mm a').format(weather.fetchedAt)}'),
      findsOneWidget,
    );

    // Away and back within fifteen minutes: nothing.
    visible.value = false;
    await settle();
    visible.value = true;
    await settle();
    expect(weather.calls, 2);
  });
}

class _FailingWeather extends WeatherRepository {
  @override
  Future<WeatherForecast> forecast(String city) async =>
      throw const WeatherException('nws down');
}
