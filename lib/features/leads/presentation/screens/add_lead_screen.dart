import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';
import 'package:task_mvp/core/providers/notification_providers.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../data/database/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddLeadScreen extends ConsumerStatefulWidget {
  const AddLeadScreen({super.key});

  @override
  ConsumerState<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends ConsumerState<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all fields in the spreadsheet
  final companyController = TextEditingController();
  final contactController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final productController = TextEditingController();
  final discussionController = TextEditingController();
  final lostReasonController = TextEditingController();

  String selectedStatus = "Hot";
  DateTime? followUpDate;
  TimeOfDay? followUpTime;

  @override
  void dispose() {
    // Clean up controllers
    companyController.dispose();
    contactController.dispose();
    mobileController.dispose();
    emailController.dispose();
    productController.dispose();
    discussionController.dispose();
    lostReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Add Lead", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTextField(companyController, "Company Name", Icons.business),
            _buildTextField(contactController, "Contact Person Name", Icons.person),
            _buildTextField(mobileController, "Contact Person Mob No", Icons.phone, keyboard: TextInputType.phone),
            _buildTextField(emailController, "Contact Person Mail ID", Icons.email, keyboard: TextInputType.emailAddress),
            _buildTextField(productController, "Product/ Service Pitched", Icons.shopping_bag),
            _buildTextField(discussionController, "Discussion Details/Remarks", Icons.comment, maxLines: 3),

            const SizedBox(height: 10),
            
            // STATUS DROPDOWN
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: "Lead Status: Hot/Warm/Cold/Lost",
                prefixIcon: const Icon(Icons.analytics),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ["Hot", "Warm", "Cold", "Lost", "Closed"]
                  .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) => setState(() => selectedStatus = value!),
            ),

            // CONDITIONAL FIELD: LOST REASON
            if (selectedStatus == "Lost") ...[
              const SizedBox(height: 16),
              _buildTextField(lostReasonController, "IF Lost: Reason", Icons.warning, isRequired: true),
            ],

            const SizedBox(height: 16),

            // DATE & TIME PICKERS
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(followUpDate == null ? "Follow Up Date" : "${followUpDate!.day}/${followUpDate!.month}/${followUpDate!.year}"),
                    subtitle: const Text("Date"),
                    leading: const Icon(Icons.calendar_month),
                    onTap: _pickDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(followUpTime == null ? "Follow Up Time" : followUpTime!.format(context)),
                    subtitle: const Text("Time"),
                    leading: const Icon(Icons.access_time),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _saveLead,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("SAVE LEAD", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for consistent TextFields
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
      {TextInputType keyboard = TextInputType.text, int maxLines = 1, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: (value) => (isRequired && (value == null || value.isEmpty)) ? "Field required" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => followUpDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => followUpTime = picked);
  }

  Future<void> _saveLead() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    // 1. Prepare data
    final leadData = {
      'companyName': companyController.text.trim(),
      'contactPersonName': contactController.text.trim(),
      'mobile': mobileController.text.trim(),
      'email': emailController.text.trim(),
      'productPitched': productController.text.trim(),
      'status': selectedStatus,
      'discussion': selectedStatus == "Lost" 
          ? "LOST REASON: ${lostReasonController.text}\n${discussionController.text}" 
          : discussionController.text,
      'followUpDate': followUpDate?.toIso8601String(),
      'followUpTime': followUpTime?.format(context),
      'ownerId': currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      // 2. SAVE TO FIREBASE
      await FirebaseFirestore.instance.collection('leads').add(leadData);

      // 3. SAVE TO DRIFT
      await db.into(db.leads).insert(
        LeadsCompanion(
          companyName: drift.Value(companyController.text.trim()),
          contactPersonName: drift.Value(contactController.text.trim()),
          mobile: drift.Value(mobileController.text.trim()),
          email: drift.Value(emailController.text.trim()),
          productPitched: drift.Value(productController.text.trim()),
          status: drift.Value(selectedStatus),
          followUpDate: drift.Value(followUpDate),
          followUpTime: drift.Value(followUpTime?.format(context)),
          createdAt: drift.Value(DateTime.now()),
        ),
      );

      // ✅ 4. SCHEDULE NOTIFICATION (New Step)
      if (followUpDate != null && followUpTime != null) {
        final scheduledDateTime = DateTime(
          followUpDate!.year,
          followUpDate!.month,
          followUpDate!.day,
          followUpTime!.hour,
          followUpTime!.minute,
        );

        // Ensure the time is in the future
        if (scheduledDateTime.isAfter(DateTime.now())) {
          // Assuming you have a notification provider configured
          ref.read(notificationServiceProvider).scheduleNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: "Follow-up: ${companyController.text.trim()}",
            body: "Call ${contactController.text.trim()} about ${productController.text.trim()}",
            scheduledDate: scheduledDateTime,
          );
        }
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lead Saved & Notification Scheduled"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sync Error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}
