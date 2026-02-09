import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

// ✅ IMPORTANT IMPORT (THIS FIXES YOUR ERROR)
import 'package:task_mvp/data/database/database.dart';
import 'package:task_mvp/core/providers/database_provider.dart';
import 'package:task_mvp/core/providers/project_providers.dart';
import 'package:task_mvp/core/constants/app_colors.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState
    extends ConsumerState<CreateProjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    // ✅ THIS IS CORRECT
    final db = ref.read(databaseProvider);

    await db.into(db.projects).insert(
      ProjectsCompanion(
        name: drift.Value(name),
        createdAt: drift.Value(DateTime.now()),
      ),
    );

    // 🔄 Refresh dashboard
    ref.invalidate(allProjectsProvider);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,

      // ===== PREMIUM HEADER =====
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        title: const Text(
          'Create Project',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            const Text(
              'Project Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Task MVP App',
                filled: true,
                fillColor:
                isDark ? AppColors.cardDark : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSaving ? null : _createProject,
                child: _isSaving
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
                    : const Text(
                  'Create Project',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}