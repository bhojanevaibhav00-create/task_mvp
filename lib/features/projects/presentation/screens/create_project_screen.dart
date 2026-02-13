import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../data/database/database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/project_providers.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../core/constants/app_colors.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState
    extends ConsumerState<CreateProjectScreen> {
  final TextEditingController _nameController =
  TextEditingController();
  final TextEditingController _descController =
  TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Project name is required")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseProvider);

      await db.into(db.projects).insert(
        ProjectsCompanion.insert(
          name: name,
          description: drift.Value(
            _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
          ),
          createdAt: drift.Value(DateTime.now()),
        ),
      );

      ref.invalidate(allProjectsProvider);
      ref.invalidate(tasksProvider);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Create New Project",
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        iconTheme:
        const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding:
        const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              "PROJECT DETAILS",
              style: theme.textTheme.labelSmall
                  ?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodySmall
                    ?.color
                    ?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 28),

            _buildTextField(
              controller: _nameController,
              label: "Project Name",
              hint: "e.g. Mobile App Revamp",
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            _buildTextField(
              controller: _descController,
              label: "Description (Optional)",
              hint: "What is this project about?",
              maxLines: 4,
              isDark: isDark,
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                _isSaving ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.primary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child:
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  "Create Project",
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w900,
                    fontSize: 16,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme
                  .textTheme.bodySmall?.color
                  ?.withOpacity(0.5),
            ),
            filled: true,
            fillColor: theme.cardColor,
            contentPadding:
            const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.dividerColor,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius:
              BorderRadius.all(
                  Radius.circular(16)),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}