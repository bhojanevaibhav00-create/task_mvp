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
        title: const Text("Create New Lead", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildSectionCard(
                "Business Information",
                Icons.business_center_rounded,
                isDark,
                [
                  _buildModernField(companyController, "Company Name", Icons.store_rounded),
                  _buildModernField(contactController, "Contact Person", Icons.person_rounded),
                ],
              ),
              _buildSectionCard(
                "Contact Details",
                Icons.contact_phone_rounded,
                isDark,
                [
                  _buildModernField(mobileController, "Mobile Number", Icons.phone_iphone_rounded, keyboard: TextInputType.phone),
                  _buildModernField(emailController, "Email Address", Icons.alternate_email_rounded, keyboard: TextInputType.emailAddress),
                ],
              ),
              _buildSectionCard(
                "Lead Intelligence",
                Icons.psychology_rounded,
                isDark,
                [
                  _buildModernField(productController, "Product/Service Pitched", Icons.shopping_cart_checkout_rounded),
                  _buildStatusSelector(isDark),
                  if (selectedStatus == "Lost")
                    _buildModernField(lostReasonController, "Reason for Loss", Icons.sentiment_very_dissatisfied_rounded),
                  _buildModernField(discussionController, "Discussion Summary", Icons.notes_rounded, maxLines: 3),
                ],
              ),
              _buildSectionCard(
                "Follow-up Schedule",
                Icons.event_repeat_rounded,
                isDark,
                [
                  _buildDateTimeRow(context, isDark),
                ],
              ),
              const SizedBox(height: 30),
              _buildSaveButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- PREMIUM WIDGETS ---

  Widget _buildSectionCard(String title, IconData icon, bool isDark, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: AppColors.primary.withOpacity(0.04),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildStatusSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Priority Level", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ["Hot", "Warm", "Cold", "Lost", "Closed"].map((s) {
              final isSelected = selectedStatus == s;
              return ChoiceChip(
                label: Text(s),
                selected: isSelected,
                onSelected: (val) => setState(() => selectedStatus = s),
                selectedColor: _getStatusColor(s),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String s) {
    switch (s) {
      case "Hot": return Colors.redAccent;
      case "Warm": return Colors.orangeAccent;
      case "Cold": return Colors.blueAccent;
      case "Closed": return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildDateTimeRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildPickerTile(
            icon: Icons.calendar_today_rounded,
            label: followUpDate == null ? "Pick Date" : "${followUpDate!.day}/${followUpDate!.month}",
            onTap: _pickDate,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPickerTile(
            icon: Icons.alarm_rounded,
            label: followUpTime == null ? "Pick Time" : followUpTime!.format(context),
            onTap: _pickTime,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerTile({required IconData icon, required String label, required VoidCallback onTap, required bool isDark}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveLead,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text("CREATE LEAD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
      ),
    );
  }

  // --- LOGIC (REMAINING SAME) ---

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
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
      await FirebaseFirestore.instance.collection('leads').add(leadData);

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

      if (followUpDate != null && followUpTime != null) {
        final scheduledDateTime = DateTime(followUpDate!.year, followUpDate!.month, followUpDate!.day, followUpTime!.hour, followUpTime!.minute);
        if (scheduledDateTime.isAfter(DateTime.now())) {
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
          const SnackBar(content: Text("Lead Saved & Notification Scheduled"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sync Error: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }
}