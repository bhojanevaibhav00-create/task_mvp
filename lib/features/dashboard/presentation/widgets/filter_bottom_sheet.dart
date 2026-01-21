import 'package:flutter/material.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/tag_model.dart';

void openFilterBottomSheet({
  required BuildContext context,
  required Set<TaskStatus> statusFilters,
  required Set<Priority> priorityFilters,
  required Set<Tag> tagFilters,
  required String? dueBucket,
  required Function(
      Set<TaskStatus> status,
      Set<Priority> priority,
      Set<Tag> tags,
      String? due,
      String? sort,
      )
  onApply,
  List<Tag> allTags = const [],
}) {
  Set<TaskStatus> tempStatus = {...statusFilters};
  Set<Priority> tempPriority = {...priorityFilters};
  Set<Tag> tempTags = {...tagFilters};
  String? tempDue = dueBucket;
  String? tempSort;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text("Filters", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: TaskStatus.values.map((s) {
                final selected = tempStatus.contains(s);
                return ChoiceChip(
                  label: Text(s.name),
                  selected: selected,
                  onSelected: (_) {
                    if (selected) {
                      tempStatus.remove(s);
                    } else {
                      tempStatus.add(s);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: Priority.values.map((p) {
                final selected = tempPriority.contains(p);
                return ChoiceChip(
                  label: Text(p.name),
                  selected: selected,
                  onSelected: (_) {
                    if (selected) {
                      tempPriority.remove(p);
                    } else {
                      tempPriority.add(p);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: allTags.map((t) {
                final selected = tempTags.contains(t);
                return ChoiceChip(
                  label: Text(t.label),
                  selected: selected,
                  onSelected: (_) {
                    if (selected) {
                      tempTags.remove(t);
                    } else {
                      tempTags.add(t);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    tempStatus.clear();
                    tempPriority.clear();
                    tempTags.clear();
                    tempDue = null;
                  },
                  child: const Text("Clear"),
                ),
                ElevatedButton(
                  onPressed: () {
                    onApply(tempStatus, tempPriority, tempTags, tempDue, tempSort);
                    Navigator.pop(context);
                  },
                  child: const Text("Apply"),
                )
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}
