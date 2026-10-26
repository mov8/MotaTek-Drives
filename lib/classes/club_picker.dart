import 'package:flutter/material.dart';
import '/services/services.dart';

/// Above Home and Shop, for someone with a choice of whose pages to see -
/// in more than one club, or Drives staff (who look after Drives' own).
/// Someone in one club just sees its pages; in none, Drives'.
class ClubPicker extends StatelessWidget {
  const ClubPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ClubService(),
      builder: (context, _) {
        ClubService clubs = ClubService();
        if (clubs.clubs.length + (clubs.canShowDrives ? 1 : 0) < 2) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Card(
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                const Icon(Icons.groups_outlined),
                const SizedBox(width: 10),
                const Text('Showing', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    value: clubs.showing.isEmpty ? null : clubs.showing,
                    items: [
                      if (clubs.canShowDrives)
                        DropdownMenuItem(
                            value: clubs.drives, child: const Text('Drives')),
                      for (Club club in clubs.clubs)
                        DropdownMenuItem(
                          value: club.id,
                          child: Text(club.isAdmin
                              ? '${club.name} (you look after its pages)'
                              : club.name),
                        ),
                    ],
                    onChanged: (clubId) async {
                      if (clubId == null || clubId == clubs.showing) return;
                      String? problem = await clubs.show(clubId);
                      if (problem != null && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(problem)));
                      }
                    },
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
