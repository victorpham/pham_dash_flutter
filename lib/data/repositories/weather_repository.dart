import 'package:dio/dio.dart';

import '../../core/api/api_exception.dart';
import '../models/weather_models.dart';

/// Errors from the weather services, carrying a sentence worth showing.
///
/// Extends [ApiException] only so the shared error view renders the message
/// instead of falling back to "Something went wrong" — there is no PhamDash
/// status code behind it.
class WeatherException extends ApiException {
  const WeatherException(String message) : super(null, message);
}

/// weather.gov (NWS) forecasts, geocoded through OpenStreetMap Nominatim.
///
/// Deliberately independent of [ApiClient]: these are third-party services on
/// other hosts, they must not receive the PhamDash bearer token, and both
/// require a `User-Agent` identifying the caller — Nominatim's usage policy
/// rejects requests without one, and NWS asks for the same.
///
/// US-only, because weather.gov is.
class WeatherRepository {
  WeatherRepository({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 20)
      ..headers['User-Agent'] = _userAgent
      ..validateStatus = (status) => status != null && status < 400;
  }

  static const String _userAgent =
      'PhamDash Weather Widget (personal use)';
  static const String _nwsBase = 'https://api.weather.gov';
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';

  final Dio _dio;

  /// Geocodes [city], then pulls the daily and hourly forecasts for it.
  ///
  /// Four requests: one to Nominatim, one to the NWS grid-point lookup, then
  /// the two forecasts in parallel.
  Future<WeatherForecast> forecast(String city) async {
    final location = await _geocode(city);
    final points = await _gridPoints(location);

    final responses = await Future.wait([
      _getJson(points.forecastUrl, 'Failed to fetch the weather forecast.'),
      _getJson(points.hourlyUrl, 'Failed to fetch the hourly forecast.'),
    ]);

    final dailyPeriods = _periods(responses[0]);
    final hourlyPeriods = _periods(responses[1]);

    return WeatherForecast(
      location: location,
      daily: parseDaily(dailyPeriods, hourlyPeriods),
      hourly: parseHourly(hourlyPeriods, 24),
      extendedHourly: parseHourly(hourlyPeriods, 48),
    );
  }

  Future<WeatherLocation> _geocode(String city) async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        '$_nominatimBase/search',
        queryParameters: {
          'q': city,
          'format': 'json',
          'limit': 1,
          // weather.gov only covers the US, so there is no point offering the
          // user a match it cannot forecast.
          'countrycodes': 'us',
        },
      );
    } on DioException catch (error) {
      throw WeatherException(_networkMessage(error, 'find that city'));
    }

    final results = response.data;
    if (results is! List || results.isEmpty) {
      throw WeatherException(
        '"$city" was not found. weather.gov only covers US locations.',
      );
    }

    final first = results.first as Map<String, dynamic>;
    // Nominatim's display_name is a comma-separated hierarchy; the web widget
    // keeps the first two parts as the place and its state.
    final parts = (first['display_name'] as String? ?? city).split(', ');

    return WeatherLocation(
      name: parts.isNotEmpty ? parts.first : city,
      state: parts.length > 1 ? parts[1] : '',
      latitude: double.tryParse('${first['lat']}') ?? 0,
      longitude: double.tryParse('${first['lon']}') ?? 0,
    );
  }

  Future<({String forecastUrl, String hourlyUrl})> _gridPoints(
    WeatherLocation location,
  ) async {
    // NWS rejects more than four decimal places on the coordinates.
    final latitude = location.latitude.toStringAsFixed(4);
    final longitude = location.longitude.toStringAsFixed(4);

    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        '$_nwsBase/points/$latitude,$longitude',
        options: Options(headers: {'Accept': 'application/geo+json'}),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw const WeatherException(
          'weather.gov has no forecast for that location. Only US locations '
          'are covered.',
        );
      }
      throw WeatherException(_networkMessage(error, 'reach weather.gov'));
    }

    final properties =
        (response.data as Map<String, dynamic>?)?['properties'] as Map?;
    final forecastUrl = properties?['forecast'] as String?;
    final hourlyUrl = properties?['forecastHourly'] as String?;

    if (forecastUrl == null || hourlyUrl == null) {
      throw const WeatherException('weather.gov returned no forecast links.');
    }
    return (forecastUrl: forecastUrl, hourlyUrl: hourlyUrl);
  }

  Future<Map<String, dynamic>> _getJson(String url, String failure) async {
    try {
      final response = await _dio.get<dynamic>(
        url,
        options: Options(headers: {'Accept': 'application/geo+json'}),
      );
      return (response.data as Map<String, dynamic>?) ?? const {};
    } on DioException catch (error) {
      throw WeatherException(_networkMessage(error, failure));
    }
  }

  static List<Map<String, dynamic>> _periods(Map<String, dynamic> body) {
    final periods = (body['properties'] as Map?)?['periods'];
    if (periods is! List) return const [];
    return periods.whereType<Map<String, dynamic>>().toList();
  }

  static String _networkMessage(DioException error, String what) =>
      switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout =>
          'Timed out trying to $what.',
        DioExceptionType.connectionError =>
          'No connection. Could not $what.',
        _ => 'Could not $what.',
      };

  // --- parsing -------------------------------------------------------------
  //
  // Pure and static so the NWS shapes can be exercised without a network.

  /// The next [limit] hours.
  static List<HourlyForecast> parseHourly(
    List<Map<String, dynamic>> periods,
    int limit,
  ) {
    return periods.take(limit).map((period) {
      final isDaytime = period['isDaytime'] as bool? ?? true;

      return HourlyForecast(
        time: _localTime(period['startTime']),
        temperature: _int(period['temperature']) ?? 0,
        condition: _condition(period, isDaytime),
        windSpeed: parseWindSpeed(period['windSpeed'] as String?),
        precipitationChance:
            _int((period['probabilityOfPrecipitation'] as Map?)?['value']) ?? 0,
        humidity: _int((period['relativeHumidity'] as Map?)?['value']),
        precipitationInches: parsePrecipitation(period),
      );
    }).toList();
  }

  /// Merges the NWS day/night periods into up to seven daily summaries.
  ///
  /// NWS splits a day into a daytime and a night period, so a high or a low can
  /// be missing — most visibly when the widget is opened at night and today's
  /// daytime period is already gone. [hourlyPeriods] fills those gaps, and for
  /// *today* it overrides both ends: the hourly series is finer-grained, and
  /// this is what the web widget does.
  static List<DailyForecast> parseDaily(
    List<Map<String, dynamic>> periods,
    List<Map<String, dynamic>> hourlyPeriods,
  ) {
    final hourlyTemperatures = <String, List<int>>{};
    for (final period in hourlyPeriods) {
      final temperature = _int(period['temperature']);
      if (temperature == null) continue;
      hourlyTemperatures
          .putIfAbsent(_dateKey(_localTime(period['startTime'])), () => [])
          .add(temperature);
    }

    final days = <String, _DayBuilder>{};
    for (final period in periods) {
      final time = _localTime(period['startTime']);
      final day = days.putIfAbsent(_dateKey(time), () => _DayBuilder(time));
      final isDaytime = period['isDaytime'] as bool? ?? true;

      if (isDaytime) {
        day.high = _int(period['temperature']);
        day.condition = _condition(period, true);
        day.windSpeed = parseWindSpeed(period['windSpeed'] as String?);
        day.humidity ??= _int((period['relativeHumidity'] as Map?)?['value']);
      } else {
        day.low = _int(period['temperature']);
        // Night conditions stand in only when the daytime period is gone.
        day.condition ??= _condition(period, false);
        day.windSpeed ??= parseWindSpeed(period['windSpeed'] as String?);
        day.humidity ??= _int((period['relativeHumidity'] as Map?)?['value']);
      }
    }

    final today = _dateKey(DateTime.now());

    return days.entries.take(7).map((entry) {
      final day = entry.value;
      var high = day.high;
      var low = day.low;

      final temperatures = hourlyTemperatures[entry.key];
      if (temperatures != null && temperatures.isNotEmpty) {
        final hourlyHigh = temperatures.reduce((a, b) => a > b ? a : b);
        final hourlyLow = temperatures.reduce((a, b) => a < b ? a : b);

        if (entry.key == today) {
          high = hourlyHigh;
          low = hourlyLow;
        } else {
          high ??= hourlyHigh;
          low ??= hourlyLow;
        }
      }

      // A day with only one period reported reads better repeating the figure
      // it has than showing a gap.
      high ??= low;
      low ??= high;

      return DailyForecast(
        date: DateTime(day.date.year, day.date.month, day.date.day),
        condition: day.condition ?? WeatherCondition.unknown,
        high: high,
        low: low,
        windSpeed: day.windSpeed ?? 0,
        humidity: day.humidity,
      );
    }).toList();
  }

  /// `"10 mph"` → 10, `"5 to 10 mph"` → 10. The higher bound wins, as on the
  /// web, so a gust range is not read as calm.
  static int parseWindSpeed(String? windSpeed) {
    if (windSpeed == null || windSpeed.isEmpty) return 0;

    final range = RegExp(r'(\d+)\s*to\s*(\d+)', caseSensitive: false)
        .firstMatch(windSpeed);
    if (range != null) return int.tryParse(range.group(2)!) ?? 0;

    final single = RegExp(r'(\d+)').firstMatch(windSpeed);
    return single == null ? 0 : int.tryParse(single.group(1)!) ?? 0;
  }

  /// Inches. NWS reports `quantitativePrecipitation` in millimetres.
  static double? parsePrecipitation(Map<String, dynamic> period) {
    final quantitative =
        (period['quantitativePrecipitation'] as Map?)?['value'];
    if (quantitative is num) {
      return (quantitative / 25.4 * 100).round() / 100;
    }
    final fallback = (period['precipitation'] as Map?)?['value'];
    return fallback is num ? fallback.toDouble() : null;
  }

  /// Buckets the NWS `shortForecast` prose into one word.
  ///
  /// Order matters: "Chance Rain Showers and Thunderstorms" has to land on
  /// Thunderstorm, so the more severe tests come first.
  static String describeMain(String shortForecast) {
    final forecast = shortForecast.toLowerCase();

    if (forecast.contains('thunder') || forecast.contains('storm')) {
      return 'Thunderstorm';
    }
    if (forecast.contains('snow') || forecast.contains('blizzard')) {
      return 'Snow';
    }
    if (forecast.contains('rain') || forecast.contains('showers')) {
      return 'Rain';
    }
    if (forecast.contains('drizzle')) return 'Drizzle';
    if (forecast.contains('fog') || forecast.contains('mist')) return 'Fog';
    if (forecast.contains('cloud') || forecast.contains('overcast')) {
      return 'Clouds';
    }
    if (forecast.contains('partly')) return 'Partly Cloudy';
    if (forecast.contains('sunny') || forecast.contains('clear')) {
      return 'Clear';
    }
    if (forecast.contains('wind')) return 'Windy';
    if (forecast.contains('haze')) return 'Haze';

    return 'Clear';
  }

  /// Maps an NWS icon URL onto an OpenWeatherMap-style code.
  ///
  /// The NWS path carries abbreviations — `tsra`, `bkn`, `sct`, `few`, `skc` —
  /// which are more reliable than the prose for choosing a glyph.
  static String mapIconCode(String? iconUrl, bool isDaytime) {
    final suffix = isDaytime ? 'd' : 'n';
    if (iconUrl == null || iconUrl.isEmpty) return '01$suffix';

    final path = iconUrl.toLowerCase();
    if (path.contains('tsra') || path.contains('thunder')) return '11$suffix';
    if (path.contains('snow') || path.contains('blizzard')) return '13$suffix';
    if (path.contains('rain') || path.contains('showers')) return '10$suffix';
    if (path.contains('drizzle')) return '09$suffix';
    if (path.contains('fog') || path.contains('mist')) return '50$suffix';
    if (path.contains('ovc') || path.contains('overcast')) return '04$suffix';
    if (path.contains('bkn') || path.contains('broken')) return '04$suffix';
    if (path.contains('sct') || path.contains('scattered')) return '03$suffix';
    if (path.contains('few')) return '02$suffix';
    if (path.contains('skc') ||
        path.contains('clear') ||
        path.contains('sunny')) {
      return '01$suffix';
    }
    return '01$suffix';
  }

  static WeatherCondition _condition(
    Map<String, dynamic> period,
    bool isDaytime,
  ) {
    final shortForecast = period['shortForecast'] as String? ?? '';
    return WeatherCondition(
      main: describeMain(shortForecast),
      description: shortForecast,
      iconCode: mapIconCode(period['icon'] as String?, isDaytime),
    );
  }

  /// NWS timestamps carry a genuine UTC offset (`2026-09-09T06:00:00-07:00`),
  /// so they parse normally. This is the opposite of the PhamDash API, whose
  /// offset-less strings need `ApiDate` — do not route these through it.
  static DateTime _localTime(Object? value) {
    final parsed = DateTime.tryParse('$value');
    return (parsed ?? DateTime.now()).toLocal();
  }

  static String _dateKey(DateTime time) =>
      '${time.year.toString().padLeft(4, '0')}-'
      '${time.month.toString().padLeft(2, '0')}-'
      '${time.day.toString().padLeft(2, '0')}';

  static int? _int(Object? value) => switch (value) {
        final int value => value,
        final num value => value.round(),
        _ => null,
      };
}

class _DayBuilder {
  _DayBuilder(this.date);

  final DateTime date;
  int? high;
  int? low;
  int? windSpeed;
  int? humidity;
  WeatherCondition? condition;
}
