import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_log.dart';
import '../../core/cache/freshness.dart';
import '../../core/cache/preferences_storage.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';

/// What the offline cache did on this launch, and what is in it now.
///
/// Every way a cached tab can come up empty used to be silent: a decode that
/// threw was swallowed by Riverpod, a corrupt envelope was dropped without a
/// word, a sign-out cleared the lot. The report that mattered - "the Lists page
/// showed nothing while the server woke, once" - was unanswerable a day later,
/// because nothing on the phone had kept a record. This is that record.
///
/// Read-only, in memory, and never leaves the device. It lists outcomes and
/// sizes, never the cached content itself.
class CacheDiagnosticsScreen extends ConsumerWidget {
  const CacheDiagnosticsScreen({super.key});

  static const String routeName = 'cacheDiagnostics';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = PreferencesStorage.describeAll(
      ref.watch(sharedPreferencesProvider),
    );
    final log = ref.watch(cacheLogProvider);
    final events = log.events;
    final authHistory = log.authHistory;
    final stamps = ref.watch(freshnessProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cache diagnostics')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _Heading('Stored (${entries.length})'),
          if (entries.isEmpty)
            const _Hint('Nothing is cached. Open a tab to fill it.')
          else
            for (final entry in entries)
              _StoredRow(entry: entry, fetchedAt: stamps[entry.key]),
          const Divider(height: 32),
          _Heading('Sign-in history (${authHistory.length})'),
          if (authHistory.isEmpty)
            const _Hint('No sign-in activity recorded yet.')
          else
            for (final event in authHistory)
              _EventRow(event: event, withDate: true),
          const Divider(height: 32),
          _Heading('This session (${events.length})'),
          if (events.isEmpty)
            const _Hint(
              'No cache activity yet. Events are kept in memory only, so this '
              'starts empty on every launch.',
            )
          else
            for (final event in events) _EventRow(event: event),
        ],
      ),
    );
  }
}

class _StoredRow extends StatelessWidget {
  const _StoredRow({required this.entry, this.fetchedAt});

  final CacheEntryInfo entry;
  final DateTime? fetchedAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final expireAt = entry.expireAt;

    return ListTile(
      dense: true,
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(entry.key),
      subtitle: Text(
        [
          _size(entry.bytes),
          if (fetchedAt != null) 'fetched ${_ago(fetchedAt!)}',
          if (expireAt != null) 'expires ${_ago(expireAt.toLocal())}',
        ].join(' · '),
        style: TextStyle(color: scheme.mutedForeground),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, this.withDate = false});

  final CacheEvent event;

  /// The sign-in history spans launches, so a bare clock time is ambiguous.
  final bool withDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, colour) = switch (event.kind) {
      CacheEventKind.hit => (Icons.check_circle_outline, scheme.primary),
      CacheEventKind.rowsSkipped => (Icons.rule, scheme.tertiary),
      CacheEventKind.miss ||
      CacheEventKind.notSeeded =>
        (Icons.circle_outlined, scheme.mutedForeground),
      CacheEventKind.expired => (Icons.schedule, scheme.mutedForeground),
      CacheEventKind.cleared ||
      CacheEventKind.sessionExpired =>
        (Icons.delete_sweep_outlined, scheme.tertiary),
      CacheEventKind.envelopeCorrupt ||
      CacheEventKind.decodeFailed ||
      CacheEventKind.uncaught ||
      CacheEventKind.authRefreshFailed =>
        (Icons.error_outline, scheme.error),
      CacheEventKind.authSignIn ||
      CacheEventKind.authRestore ||
      CacheEventKind.authRefresh =>
        (Icons.key_outlined, scheme.primary),
      CacheEventKind.authSignOut => (Icons.logout, scheme.mutedForeground),
    };

    final detail = event.detail;
    final when = withDate ? _stamp(event.at) : _clock(event.at);

    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: colour),
      title: Text('${event.key} — ${_label(event.kind)}'),
      subtitle: Text(
        detail == null ? when : '$when · $detail',
        style: TextStyle(color: scheme.mutedForeground),
      ),
      isThreeLine: detail != null && detail.length > 48,
    );
  }
}

String _label(CacheEventKind kind) => switch (kind) {
      CacheEventKind.hit => 'seeded from cache',
      CacheEventKind.miss => 'nothing stored',
      CacheEventKind.expired => 'stored copy had expired',
      CacheEventKind.envelopeCorrupt => 'stored value was unreadable',
      CacheEventKind.decodeFailed => 'stored copy could not be decoded',
      CacheEventKind.rowsSkipped => 'some rows skipped',
      CacheEventKind.notSeeded => 'cache not consulted',
      CacheEventKind.cleared => 'cache cleared',
      CacheEventKind.sessionExpired => 'session expired',
      CacheEventKind.uncaught => 'uncaught error',
      CacheEventKind.authSignIn => 'signed in',
      CacheEventKind.authRestore => 'session restored',
      CacheEventKind.authRefresh => 'token renewed',
      CacheEventKind.authRefreshFailed => 'token renewal failed',
      CacheEventKind.authSignOut => 'signed out',
    };

String _stamp(DateTime at) =>
    '${at.month.toString().padLeft(2, '0')}-'
    '${at.day.toString().padLeft(2, '0')} ${_clock(at)}';

String _size(int bytes) => bytes < 1024
    ? '$bytes B'
    : '${(bytes / 1024).toStringAsFixed(bytes < 1024 * 10 ? 1 : 0)} KB';

String _clock(DateTime at) =>
    '${at.hour.toString().padLeft(2, '0')}:'
    '${at.minute.toString().padLeft(2, '0')}:'
    '${at.second.toString().padLeft(2, '0')}';

/// Signed, so an expiry in the future reads "in 29 days".
String _ago(DateTime at) {
  final delta = DateTime.now().difference(at);
  final ahead = delta.isNegative;
  final span = delta.abs();

  final amount = switch (span) {
    _ when span.inMinutes < 1 => 'moments',
    _ when span.inHours < 1 => '${span.inMinutes} min',
    _ when span.inDays < 1 => '${span.inHours} h',
    _ => '${span.inDays} d',
  };
  return ahead ? 'in $amount' : '$amount ago';
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.mutedForeground,
              ),
        ),
      );
}
