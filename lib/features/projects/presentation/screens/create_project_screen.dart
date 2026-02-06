import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../data/database/database.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../core/providers/collaboration_providers.dart'; // ✅ Added for allProjectsProvider
import '../../../../core/constants/app_colors.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

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
        const SnackBar(content: Text("Project name is required")),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    
    // 1. Insert into Database
    await db.into(db.projects).insert(ProjectsCompanion.insert(
      name: name,
      description: drift.Value(_descController.text.trim()),
      createdAt: drift.Value(DateTime.now()),
    ));

    // 2. ✅ FIXED: Invalidate the specific provider that feeds the Dashboard & Detail screens
    // This ensures that when you go back, the new project is already visible.
    ref.invalidate(allProjectsProvider); 
    ref.invalidate(tasksProvider); 

    if (mounted) {
      // Return true so the calling screen knows it needs to refresh if not using a provider
      Navigator.pop(context, true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FORCE WHITE THEME (Matches Dashboard/Login)
    const backgroundColor = Color(0xFFF8F9FD);
    const cardColor = Colors.white;
    const primaryTextColor = Color(0xFF1A1C1E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Create New Project", 
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PROJECT DETAILS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.blueGrey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            
            // ✅ PREMIUM INPUTS
            _buildTextField(
              controller: _nameController,
              label: "Project Name",
              hint: "e.g. Mobile App Revamp",
              cardColor: cardColor,
              textColor: primaryTextColor,
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _descController,
              label: "Description (Optional)",
              hint: "What is this project about?",
              cardColor: cardColor,
              textColor: primaryTextColor,
              maxLines: 4,
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "Create Project", 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color cardColor,
    required Color textColor,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: cardColor,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}