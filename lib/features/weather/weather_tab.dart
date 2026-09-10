import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../data/models/weather_models.dart';

/// The city the forecast is for, under the same key the web widget uses.
const String _cityKey = 'weatherCity';

/// The chosen city, or null until one has been entered.
class WeatherCity extends Notifier<String?> {
  @override
  String? build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_cityKey);
    return (saved == null || saved.isEmpty) ? null : saved;
  }

  Future<void> set(String city) async {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return;
    state = trimmed;
    await ref.read(sharedPreferencesProvider).setString(_cityKey, trimmed);
  }
}

final weatherCityProvider =
    NotifierProvider<WeatherCity, String?>(WeatherCity.new);

/// The forecast for the chosen city.
///
/// Four network calls sit behind this — geocoding, the NWS grid lookup and two
/// forecasts — so it is deliberately not `autoDispose`: the tab is kept alive
/// in the shell's indexed stack, and switching tabs should not re-run them.
final weatherForecastProvider = FutureProvider<WeatherForecast?>((ref) async {
  final city = ref.watch(weatherCityProvider);
  if (city == null) return null;
  return ref.watch(weatherRepositoryProvider).forecast(city);
});

class WeatherTab extends ConsumerWidget {
  const WeatherTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(weatherCityProvider);
    if (city == null) return const _CityPrompt();

    final forecast = ref.watch(weatherForecastProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(weatherForecastProvider.future),
      child: AsyncView<WeatherForecast?>(
        value: forecast,
        onRetry: () => ref.invalidate(weatherForecastProvider),
        isEmpty: (data) => data == null,
        emptyIcon: Icons.location_off_outlined,
        emptyTitle: 'No forecast',
        builder: (data) => _Forecast(forecast: data!),
      ),
    );
  }
}

/// Shown until a city has been set, and again whenever the user changes it.
class _CityPrompt extends ConsumerStatefulWidget {
  const _CityPrompt();

  @override
  ConsumerState<_CityPrompt> createState() => _CityPromptState();
}

class _CityPromptState extends ConsumerState<_CityPrompt> {
  late final _controller =
      TextEditingController(text: ref.read(weatherCityProvider) ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        Icon(
          Icons.place_outlined,
          size: 48,
          color: scheme.primary.withValues(alpha: 0.55),
        ),
        const SizedBox(height: 16),
        Text(
          'Where are you?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Forecasts come from weather.gov, which covers US locations only.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.mutedForeground),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'City',
            hintText: 'San Francisco, CA',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Show the forecast')),
      ],
    );
  }

  void _save() {
    ref.read(weatherCityProvider.notifier).set(_controller.text);
    FocusScope.of(context).unfocus();
  }
}

class _Forecast extends ConsumerWidget {
  const _Forecast({required this.forecast});

  final WeatherForecast forecast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolHours = forecast.tomorrowSchoolHours;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        _LocationBar(location: forecast.location),
        if (forecast.current case final current?) _Now(current: current),

        if (forecast.hourly.isNotEmpty) ...[
          const _SectionLabel('Next 24 hours'),
          _HourStrip(hours: forecast.hourly, markSchoolHours: true),
        ],

        if (schoolHours.isNotEmpty) ...[
          _SectionLabel(
            'Tomorrow at school · '
            '${DateFormat('EEEE, MMM d').format(schoolHours.first.time)}',
            icon: Icons.school_outlined,
          ),
          _HourStrip(hours: schoolHours, showPrecipitationAmount: true),
        ],

        if (forecast.daily.isNotEmpty) ...[
          const _SectionLabel('7-day forecast'),
          for (final day in forecast.daily) _DayRow(day: day),
        ],
      ],
    );
  }
}

class _LocationBar extends ConsumerWidget {
  const _LocationBar({required this.location});

  final WeatherLocation location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
      child: Row(
        children: [
          Icon(Icons.place_outlined, size: 16, color: scheme.mutedForeground),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              location.label,
              style: TextStyle(fontSize: 13, color: scheme.mutedForeground),
            ),
          ),
          IconButton(
            tooltip: 'Change location',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _changeCity(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _changeCity(BuildContext context, WidgetRef ref) async {
    final controller =
        TextEditingController(text: ref.read(weatherCityProvider) ?? '');

    final city = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change location'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'City',
            hintText: 'San Francisco, CA',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (city != null && city.isNotEmpty) {
      await ref.read(weatherCityProvider.notifier).set(city);
    }
  }
}

/// The headline: right now, big.
class _Now extends StatelessWidget {
  const _Now({required this.current});

  final HourlyForecast current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = weatherIconFor(current.condition.iconCode, scheme);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(style.icon, size: 56, color: style.color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${current.temperature}°',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  current.condition.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    '${current.windSpeed} mph wind',
                    if (current.precipitationChance > 0)
                      '${current.precipitationChance}% precip',
                    if (current.humidity case final humidity?)
                      '$humidity% humidity',
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontally scrolling run of hours.
class _HourStrip extends StatelessWidget {
  const _HourStrip({
    required this.hours,
    this.markSchoolHours = false,
    this.showPrecipitationAmount = false,
  });

  final List<HourlyForecast> hours;

  /// Outlines weekday 8am–2pm, as the web widget does.
  final bool markSchoolHours;

  final bool showPrecipitationAmount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: hours.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _HourCell(
          hour: hours[index],
          isNow: markSchoolHours && index == 0,
          outlineSchoolHours: markSchoolHours,
          showPrecipitationAmount: showPrecipitationAmount,
        ),
      ),
    );
  }
}

class _HourCell extends StatelessWidget {
  const _HourCell({
    required this.hour,
    required this.isNow,
    required this.outlineSchoolHours,
    required this.showPrecipitationAmount,
  });

  final HourlyForecast hour;
  final bool isNow;
  final bool outlineSchoolHours;
  final bool showPrecipitationAmount;

  /// The web outlines school hours in amber; the same colour reads in both
  /// themes without help.
  static const Color _schoolAmber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = weatherIconFor(hour.condition.iconCode, scheme);
    final isSchool = outlineSchoolHours && hour.isSchoolHours;

    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isNow ? scheme.primaryContainer : scheme.rowSurface,
        borderRadius: BorderRadius.circular(10),
        border: isSchool
            ? Border.all(color: _schoolAmber, width: 2)
            : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isNow ? 'Now' : DateFormat('h a').format(hour.time),
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Icon(style.icon, size: 26, color: style.color),
          const SizedBox(height: 4),
          Text(
            '${hour.temperature}°',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          if (hour.precipitationChance > 0)
            Text(
              showPrecipitationAmount && hour.precipitationInches != null
                  ? '${hour.precipitationChance}% · '
                      '${hour.precipitationInches}"'
                  : '${hour.precipitationChance}%',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF3B82F6)),
              maxLines: 1,
            )
          else
            const SizedBox(height: 14),
          Text(
            '${hour.windSpeed} mph',
            style: TextStyle(fontSize: 10, color: scheme.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});

  final DailyForecast day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = weatherIconFor(day.condition.iconCode, scheme);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              _label(day.date),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
          Icon(style.icon, size: 24, color: style.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              day.condition.main,
              style: TextStyle(fontSize: 12.5, color: scheme.mutedForeground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (day.high case final high?)
            Text(
              '$high°',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          const SizedBox(width: 8),
          if (day.low case final low?)
            Text(
              '$low°',
              style: TextStyle(fontSize: 15, color: scheme.mutedForeground),
            ),
        ],
      ),
    );
  }

  /// `Today` / `Tomorrow` / `Wed, Sep 9`, as the web labels its days.
  static String _label(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = date.difference(today).inDays;

    return switch (difference) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => DateFormat('EEE, MMM d').format(date),
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// How one OpenWeatherMap-style code is drawn.
typedef WeatherGlyph = ({IconData icon, Color color});

/// Maps the shared icon vocabulary onto Material icons.
///
/// The web fetches OpenWeatherMap's PNGs for these codes. Drawing them instead
/// keeps the forecast crisp at any size, tints it with the theme, and avoids a
/// per-cell image request to a third-party host — 24 hours plus 7 days is a lot
/// of little PNGs.
WeatherGlyph weatherIconFor(String iconCode, ColorScheme scheme) {
  final isNight = iconCode.endsWith('n');
  final sun = isNight ? const Color(0xFF94A3B8) : const Color(0xFFF59E0B);
  const rain = Color(0xFF3B82F6);

  return switch (iconCode.substring(0, iconCode.length - 1)) {
    '01' => (
        icon: isNight ? Icons.nightlight_round : Icons.wb_sunny,
        color: sun,
      ),
    '02' => (icon: Icons.wb_cloudy_outlined, color: sun),
    '03' => (icon: Icons.cloud_outlined, color: scheme.onSurfaceVariant),
    '04' => (icon: Icons.cloud, color: scheme.onSurfaceVariant),
    '09' => (icon: Icons.grain, color: rain),
    '10' => (icon: Icons.water_drop, color: rain),
    '11' => (icon: Icons.thunderstorm, color: Color(0xFF8B5CF6)),
    '13' => (icon: Icons.ac_unit, color: Color(0xFF60A5FA)),
    '50' => (icon: Icons.foggy, color: scheme.onSurfaceVariant),
    _ => (icon: Icons.wb_sunny, color: sun),
  };
}
