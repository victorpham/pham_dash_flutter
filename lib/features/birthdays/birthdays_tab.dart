import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/person_avatar.dart';
import '../../data/models/people_models.dart';

/// Computed server-side across everyone with a birth date, ordered by days
/// until, so no client-side date maths is needed.
final upcomingBirthdaysProvider =
    FutureProvider.autoDispose<List<UpcomingBirthday>>(
  (ref) => ref.watch(peopleRepositoryProvider).upcomingBirthdays(count: 8),
);

class BirthdaysTab extends ConsumerWidget {
  const BirthdaysTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthdays = ref.watch(upcomingBirthdaysProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(upcomingBirthdaysProvider.future),
      child: AsyncView<List<UpcomingBirthday>>(
        value: birthdays,
        onRetry: () => ref.invalidate(upcomingBirthdaysProvider),
        emptyIcon: Icons.cake_outlined,
        emptyTitle: 'No birthdays coming up',
        emptyMessage: 'Add birth dates to people to see them here.',
        builder: (data) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: data.length,
          itemBuilder: (context, index) => _BirthdayRow(birthday: data[index]),
        ),
      ),
    );
  }
}

class _BirthdayRow extends StatelessWidget {
  const _BirthdayRow({required this.birthday});

  final UpcomingBirthday birthday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final birthDate = birthday.birthDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          PersonAvatar(
            storedPath: birthday.profilePictureUrl,
            initials: birthday.initials,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        birthday.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _CountdownPill(birthday: birthday),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (birthDate != null)
                      DateFormat('MMM d').format(birthDate),
                    if (birthday.upcomingAge != null)
                      'Turning ${birthday.upcomingAge}',
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

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.birthday});

  final UpcomingBirthday birthday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = birthday.isToday ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        birthday.countdownLabel,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
