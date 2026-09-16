import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';

/// The loading / error / empty triad, mirroring the shared Vue component every
/// screen in the web app routes its async state through.
///
/// Keeping it in one place is what makes an empty calendar read as
/// "Your week looks clear!" rather than as a blank screen, everywhere.
///
/// Diverges from the web in one way: a value, once shown, is never taken away.
/// A refresh that fails keeps the list on screen under a "couldn't refresh"
/// banner, and a `CachedList` provider's saved copy renders under a thin
/// progress bar while the real fetch runs. Both exist because the production
/// database sleeps and its first answer of the day is slow or absent - see
/// [PatientLoading] for the no-data version of the same wait.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.loading,
    this.explainSlowLoad = true,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  /// Whether [T] should render as the empty state. Defaults to treating an
  /// empty [Iterable] as empty.
  final bool Function(T data)? isEmpty;

  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final Widget? loading;

  /// Whether a slow load explains itself once it has dragged on - see
  /// [PatientLoading]. On by default, since the database resume is the one
  /// slow load every API-backed screen shares; off for Weather, which never
  /// reaches the API.
  final bool explainSlowLoad;

  bool _isEmpty(T data) {
    final predicate = isEmpty;
    if (predicate != null) return predicate(data);
    if (data is Iterable) return data.isEmpty;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      skipError: true,
      loading: () => loading ?? PatientLoading(explainSlowLoad: explainSlowLoad),
      error: (error, _) => ErrorStateView(error: error, onRetry: onRetry),
      data: (data) {
        final content = _isEmpty(data)
            ? EmptyStateView(
                icon: emptyIcon,
                title: emptyTitle,
                message: emptyMessage,
              )
            : builder(data);

        // `skipError` above is what keeps `content` when a refresh fails; the
        // banner is what keeps that honest.
        final error = value.error;
        if (error != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RefreshFailedBanner(error: error, onRetry: onRetry),
              Flexible(child: content),
            ],
          );
        }

        // A reload with a value is either a `CachedList` seed or a dependency
        // change (a todo filter). Refreshes - a pull, or an invalidate after
        // a write - stay silent as before; the pull has its own indicator.
        if (value.isReloading) {
          return Stack(
            children: [
              content,
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RefreshingStrip(explainSlowLoad: explainSlowLoad),
              ),
            ],
          );
        }

        return content;
      },
    );
  }
}

/// The 2px bar over a list that is showing while its refresh runs, growing a
/// caption once the wait needs explaining.
class RefreshingStrip extends StatelessWidget {
  const RefreshingStrip({super.key, this.explainSlowLoad = true});

  final bool explainSlowLoad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LinearProgressIndicator(minHeight: 2),
        if (explainSlowLoad)
          AfterDelay(
            delay: PatientLoading.hintAfter,
            child: Material(
              color: theme.colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.bedtime_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(PatientLoading.hint, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Couldn't refresh": shown above data that is still the last good answer.
class RefreshFailedBanner extends StatelessWidget {
  const RefreshFailedBanner({super.key, required this.error, this.onRetry});

  static const String title = "Couldn't refresh - showing saved data.";

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 20, color: scheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onErrorContainer),
                  ),
                  Text(
                    userMessageFor(error),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onErrorContainer),
                  ),
                ],
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Shows nothing until [delay] has passed, then [child].
class AfterDelay extends StatefulWidget {
  const AfterDelay({super.key, required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<AfterDelay> createState() => _AfterDelayState();
}

class _AfterDelayState extends State<AfterDelay> {
  Timer? _timer;
  bool _elapsed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () => setState(() => _elapsed = true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _elapsed ? widget.child : const SizedBox.shrink();
}

/// A spinner that explains itself once the wait stops looking like a normal
/// load.
///
/// The API's database auto-pauses after an hour idle and takes tens of
/// seconds to resume, and the App Service holds the request open while it
/// does (`EnableRetryOnFailure`). From the phone that is indistinguishable
/// from a hang - so after [hintAfter] the spinner says what is happening.
/// The wait is unchanged; only its meaning is. `ServerWarmup` is the other
/// half, starting the resume before the user taps; [RefreshingStrip] is the
/// same hint for a screen that has a cached list to show meanwhile.
class PatientLoading extends StatelessWidget {
  const PatientLoading({super.key, this.explainSlowLoad = true});

  static const Duration hintAfter = Duration(seconds: 5);

  static const String hint = 'Waking up the server…';

  /// In the terms a family member would accept.
  static const String detail =
      'It naps after an hour of quiet and takes a moment to come back.';

  /// Whether to show [hint] once [hintAfter] has elapsed. Off for a screen
  /// that never reaches the API, or it would blame the wrong server.
  final bool explainSlowLoad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (explainSlowLoad)
            AfterDelay(
              delay: hintAfter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
                child: Column(
                  children: [
                    Text(hint, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// What to tell the user about [error]. An [ApiException] already carries a
/// message the API actually sent; anything else would leak a Dart
/// stack-trace-ish string at them.
String userMessageFor(Object error) =>
    error is ApiException ? error.message : 'Something went wrong.';

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final message = userMessageFor(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 44, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
