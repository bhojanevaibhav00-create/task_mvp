import 'package:flutter/material.dart';
import 'package:task_mvp/data/models/enums.dart';
import 'package:task_mvp/data/models/tag_model.dart';
import 'package:task_mvp/core/constants/app_colors.dart';

void openFilterBottomSheet({
  required BuildContext context,
  required List<Tag> allTags,
  required Set<TaskStatus> statusFilters,
  required Set<Priority> priorityFilters,
  required Set<Tag> tagFilters,
  required String? dueBucket,
  required String? sort,
  required void Function(
      Set<TaskStatus>,
      Set<Priority>,
      Set<Tag>,
      String?,
      String?,
      ) onApply,
}) {
  Set<TaskStatus> localStatus = {...statusFilters};
  Set<Priority> localPriority = {...priorityFilters};
  Set<Tag> localTags = {...tagFilters};
  String? localDue = dueBucket;
  String? localSort = sort;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filters",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        localStatus.clear();
                        localPriority.clear();
                        localTags.clear();
                        localDue = null;
                        localSort = null;
                      });
                    },
                    child: const Text("Clear All"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onApply(localStatus, localPriority, localTags, localDue, localSort);
                    },
                    child: const Text("Apply"),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text("Status"),
              Wrap(
                children: TaskStatus.values.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: FilterChip(
                      label: Text(s.name),
                      selected: localStatus.contains(s),
                      onSelected: (v) {
                        setState(() {
                          v ? localStatus.add(s) : localStatus.remove(s);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text("Priority"),
              Wrap(
                children: Priority.values.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: FilterChip(
                      label: Text(p.name),
                      selected: localPriority.contains(p),
                      onSelected: (v) {
                        setState(() {
                          v ? localPriority.add(p) : localPriority.remove(p);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text("Tags"),
              Wrap(
                children: allTags.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: FilterChip(
                      label: Text(t.label),
                      selected: localTags.contains(t),
                      onSelected: (v) {
                        setState(() {
                          v ? localTags.add(t) : localTags.remove(t);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text("Due"),
              Wrap(
                children: ["Today", "Overdue", "Next 7 Days"].map((d) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: ChoiceChip(
                      label: Text(d),
                      selected: localDue == d,
                      onSelected: (_) => setState(() => localDue = d),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text("Sort"),
              Wrap(
                children: ["A-Z", "Due Date", "Priority"].map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: localSort == s,
                      onSelected: (_) => setState(() => localSort = s),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
