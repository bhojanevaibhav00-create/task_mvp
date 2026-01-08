import 'package:flutter/material.dart';
import '../../widgets/cards/task_card.dart';
import '../../screens/tasks/kanban_board_skeleton.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tasks"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "List"),
              Tab(text: "Kanban"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TaskListView(),
            KanbanBoardSkeleton(),
          ],
        ),
      ),
    );
  }
}

class _TaskListView extends StatelessWidget {
  const _TaskListView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: const [
          TaskCard(
            title: "Design Login Screen",
            status: "In Progress",
            priority: "High",
            dueDate: "20 Jan",
          ),
          TaskCard(
            title: "Setup Database",
            status: "Todo",
            priority: "Medium",
            dueDate: "22 Jan",
          ),
          TaskCard(
            title: "API Integration",
            status: "Done",
            priority: "Low",
            dueDate: "15 Jan",
          ),
        ],
      ),
    );
  }
}
