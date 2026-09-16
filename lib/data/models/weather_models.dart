/// Weather is **not** a PhamDash API feature.
///
/// The web widget talks straight to weather.gov (NWS) for the forecast and to
/// OpenStreetMap Nominatim for geocoding, and this port does the same. Nothing
/// here is a PhamDash DTO, so these are plain classes rather than the freezed
/// `fromJson` models the rest of `data/models` holds — the shapes below are
/// *derived* from the NWS payloads, not decoded from them.
///
/// Both services are US-only, which is a property of weather.gov, not of this
/// code.
library;

/// A geocoded place, as Nominatim resolved the user's typed city.
class WeatherLocation {
  const WeatherLocation({
    required this.name,
    required this.state,
    required this.latitude,
    required this.longitude,
  });

  final String name;

  /// Nominatim's second `display_name` part, which is usually the state but is
  /// occasionally a county. Empty when the name had no second part.
  final String state;

  final double latitude;
  final double longitude;

  String get label =>
      [name, if (state.isNotEmpty) state, 'US'].join(', ');
}

/// A condition, classified from the NWS `shortForecast` text.
class WeatherCondition {
  const WeatherCondition({
    required this.main,
    required this.description,
    required this.iconCode,
  });

  /// A coarse bucket — `Rain`, `Snow`, `Clouds` — for the one-word summary
  /// under each day.
  final String main;

  /// The NWS `shortForecast` verbatim, e.g. "Slight Chance Rain Showers".
  final String description;

  /// An OpenWeatherMap-style code such as `10d`.
  ///
  /// NWS icon URLs are mapped onto this vocabulary because the web widget does,
  /// and keeping the same codes keeps the two clients' classification identical.
  /// The web then fetches OWM's PNGs; this app draws Material icons instead —
  /// no third-party image host, and they theme themselves in dark mode.
  final String iconCode;

  static const WeatherCondition unknown = WeatherCondition(
    main: 'Unknown',
    description: 'No forecast available',
    iconCode: '01d',
  );
}

/// One hour of the NWS hourly forecast.
class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.condition,
    required this.windSpeed,
    required this.precipitationChance,
    this.humidity,
    this.precipitationInches,
  });

  /// Local time. NWS timestamps carry a real UTC offset, unlike the PhamDash
  /// API's — so they are parsed normally, never through `ApiDate`.
  final DateTime time;

  final int temperature;
  final WeatherCondition condition;

  /// mph. NWS sends a string like `"5 to 10 mph"`; the higher bound wins.
  final int windSpeed;

  /// Percent, 0 when NWS omits it.
  final int precipitationChance;

  final int? humidity;
  final double? precipitationInches;

  /// Weekday school hours, 8am–2pm, highlighted on the 24-hour strip.
  bool get isSchoolHours =>
      time.weekday <= DateTime.friday && time.hour >= 8 && time.hour < 14;
}

/// One day of the NWS 7-day forecast, with its day and night periods merged.
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.condition,
    this.high,
    this.low,
    this.windSpeed = 0,
    this.humidity,
  });

  /// Local midnight of the day described.
  final DateTime date;

  final WeatherCondition condition;
  final int? high;
  final int? low;
  final int windSpeed;
  final int? humidity;
}

/// Everything one city's forecast needs to render.
class WeatherForecast {
  const WeatherForecast({
    required this.location,
    required this.daily,
    required this.hourly,
    required this.extendedHourly,
    required this.fetchedAt,
  });

  final WeatherLocation location;

  /// When this snapshot was pulled from weather.gov. The Weather tab shows it,
  /// and refreshes on a visit once it is more than fifteen minutes old.
  final DateTime fetchedAt;

  /// Up to seven days.
  final List<DailyForecast> daily;

  /// The next 24 hours.
  final List<HourlyForecast> hourly;

  /// The next 48, which is what reaches far enough to cover tomorrow morning.
  final List<HourlyForecast> extendedHourly;

  /// Conditions right now — the first hourly period, as the web widget does.
  /// NWS's basic forecast carries no observed current conditions.
  HourlyForecast? get current => hourly.isEmpty ? null : hourly.first;

  /// Tomorrow 7am–3pm, empty when tomorrow is a weekend or falls outside the
  /// 48-hour window.
  List<HourlyForecast> get tomorrowSchoolHours {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (tomorrow.weekday > DateTime.friday) return const [];

    return extendedHourly
        .where((hour) =>
            hour.time.year == tomorrow.year &&
            hour.time.month == tomorrow.month &&
            hour.time.day == tomorrow.day &&
            hour.time.hour >= 7 &&
            hour.time.hour < 15)
        .toList();
  }
}
