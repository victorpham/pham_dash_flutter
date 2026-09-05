import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/theme_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    // Once signed in, pull the saved accent colour down. The router handles the
    // navigation itself.
    ref.listen(authControllerProvider, (previous, next) {
      if (next.value != null && previous?.value == null) {
        ref.read(themeControllerProvider.notifier).loadFromApi();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    size: 64,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PhamDash',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your family dashboard',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 40),
                  if (auth.hasError) ...[
                    _LoginError(error: auth.error!),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: auth.isLoading
                        ? null
                        : () => ref
                            .read(authControllerProvider.notifier)
                            .signIn(),
                    icon: auth.isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(auth.isLoading ? 'Signing in…' : 'Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = switch (error) {
      final ApiException e => e.message,
      _ => _describe(error),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Turns the two failures worth calling out by name into actionable text.
  ///
  /// A missing redirect-URI registration is far and away the most likely
  /// first-run failure, and Entra's raw `AADSTS50011` says nothing useful to
  /// someone who has not seen it before.
  static String _describe(Object error) {
    final text = error.toString();
    if (text.contains('AADSTS50011')) {
      return 'This app\'s redirect URI is not registered. Add '
          'com.phamdash.app://oauthredirect to the app registration under '
          'Authentication -> Mobile and desktop applications.';
    }
    // A bare redirect_uri_mismatch comes from the *upstream* identity provider
    // (Google or the Microsoft account app), not from our app registration —
    // its callback is registered against phamdashauth.ciamlogin.com only.
    if (text.contains('redirect_uri')) {
      return 'The identity provider rejected Entra\'s callback. Check that '
          'sign-in is running against phamdashauth.ciamlogin.com, and that '
          'https://phamdashauth.ciamlogin.com/common/federation/oidc is '
          'registered on the Google OAuth client.';
    }
    if (text.contains('User cancelled') || text.contains('cancel')) {
      return 'Sign-in was cancelled.';
    }
    return 'Sign-in failed. $text';
  }
}
