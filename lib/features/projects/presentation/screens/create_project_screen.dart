import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../data/database/database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/project_providers.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// ✅ IMPROVED: Combined Logic for Database + Notification + Navigation
    Future<void> _handleCreate() async {
  final name = _nameController.text.trim();
  final description = _descController.text.trim();

  if (name.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Project name is required")),
    );
    return;
  }

  setState(() => _isSaving = true);

  try {
    final db = ref.read(databaseProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception("User not logged in");
    }

    // ============================
    // 1️⃣ SAVE TO DRIFT (LOCAL DB)
    // ============================
    final projectId = await db.into(db.projects).insert(
      ProjectsCompanion.insert(
        name: name,
        description: drift.Value(
            description.isEmpty ? null : description),
        color: const drift.Value(0xFF2196F3),
        createdAt: drift.Value(DateTime.now()),
      ),
    );

    // ============================
    // 2️⃣ SAVE TO FIREBASE (GLOBAL PROJECT)
    // ============================
    final projectRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId.toString());

    await projectRef.set({
      'id': projectId,
      'name': name,
      'description': description.isEmpty ? null : description,
      'color': 0xFF2196F3,
      'createdBy': firebaseUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ============================
    // 3️⃣ ADD CREATOR AS OWNER
    // ============================
    await projectRef
        .collection('members')
        .doc(firebaseUser.uid)
        .set({
      'userId': firebaseUser.uid,
      'role': 'Owner',
      'addedAt': FieldValue.serverTimestamp(),
    });

    // ============================
    // 4️⃣ REFRESH UI
    // ============================
    ref.invalidate(allProjectsProvider);

    if (mounted) {
      Navigator.pop(context, true);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating project: $e")),
      );
    }
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}


  @override
  Widget build(BuildContext context) {
    // 🎨 THEME SYNC: Detect system brightness for Dark Mode support
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD);
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1A1C1E);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.blueGrey;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Create New Project", 
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Text(
              "PROJECT DETAILS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: secondaryTextColor,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Name Input
            _buildTextField(
              controller: _nameController,
              label: "Project Name",
              hint: "e.g. Mobile App Revamp",
              cardColor: cardColor,
              textColor: primaryTextColor,
              isDark: isDark,
              icon: Icons.work_outline_rounded,
            ),
            const SizedBox(height: 24),
            
            // Description Input
            _buildTextField(
              controller: _descController,
              label: "Description (Optional)",
              hint: "What is this project about?",
              cardColor: cardColor,
              textColor: primaryTextColor,
              isDark: isDark,
              maxLines: 5,
              icon: Icons.description_outlined,
            ),
            
            const SizedBox(height: 48),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isSaving 
                  ? const SizedBox(
                      height: 24, 
                      width: 24, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      "Create Project", 
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🛠️ CUSTOM UI COMPONENT: Styled TextField with Dark Mode support
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.black45),
            const SizedBox(width: 8),
            Text(
              label, 
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white12 : Colors.black26, 
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}