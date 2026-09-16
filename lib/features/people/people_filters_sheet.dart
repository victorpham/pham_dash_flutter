import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/people_models.dart';
import 'people_providers.dart';
import 'people_screen.dart';

/// The two data-hygiene filters, off the people screen and behind an action.
///
/// They used to be a row of chips under the search box. They are work queues
/// rather than everyday lenses — you open them to fill gaps in, not to find
/// somebody — so they cost 56px of every scroll for a rare job. The app bar
/// keeps the "clear search and filters" action, which is what admits one is
/// still on once this sheet is closed.
Future<void> showPeopleFiltersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => const PeopleFiltersList(),
  );
}

/// The filter list itself, exposed so a widget test can pump it without a
/// navigator or a modal route — as [PersonTagList] is.
class PeopleFiltersList extends ConsumerWidget {
  const PeopleFiltersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Counts are over the whole directory, not the filtered view — they say how
    // much data is missing, so filtering them would make them meaningless.
    final people = ref.watch(allPeopleProvider).value ?? const <Person>[];
    final missingBirthdate = people.where((p) => p.birthDate == null).length;
    final missingPicture = people
        .where((p) => p.profilePictureUrl == null)
        .length;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Missing information',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          SwitchListTile(
            title: Text('No birthday ($missingBirthdate)'),
            value: ref.watch(missingBirthdateFilterProvider),
            onChanged: (_) =>
                ref.read(missingBirthdateFilterProvider.notifier).toggle(),
          ),
          SwitchListTile(
            title: Text('No photo ($missingPicture)'),
            value: ref.watch(missingPictureFilterProvider),
            onChanged: (_) =>
                ref.read(missingPictureFilterProvider.notifier).toggle(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
