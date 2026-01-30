import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../data/database/database.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../core/constants/app_colors.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  Future<void> _handleCreate() async {
    if (_nameController.text.isEmpty) return;

    final db = ref.read(databaseProvider);
    
    // Insert new project into Drift Database
    await db.into(db.projects).insert(ProjectsCompanion.insert(
      name: _nameController.text.trim(),
      description: drift.Value(_descController.text.trim()),
      createdAt: drift.Value(DateTime.now()),
    ));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Project")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Project Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleCreate,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text("Create Project", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}