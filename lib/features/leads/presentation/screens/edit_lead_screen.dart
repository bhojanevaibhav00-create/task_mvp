import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../data/database/database.dart';

class EditLeadScreen extends ConsumerStatefulWidget {
  final Lead lead;

  const EditLeadScreen({super.key, required this.lead});

  @override
  ConsumerState<EditLeadScreen> createState() => _EditLeadScreenState();
}

class _EditLeadScreenState extends ConsumerState<EditLeadScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController companyController;
  late TextEditingController contactController;
  late TextEditingController mobileController;
  late TextEditingController emailController;
  late TextEditingController productController;
  late TextEditingController discussionController;

  late String selectedStatus;
  DateTime? followUpDate;

  @override
  void initState() {
    super.initState();
    companyController = TextEditingController(text: widget.lead.companyName);
    contactController = TextEditingController(text: widget.lead.contactPersonName);
    mobileController = TextEditingController(text: widget.lead.mobile);
    emailController = TextEditingController(text: widget.lead.email ?? "");
    productController = TextEditingController(text: widget.lead.productPitched ?? "");
    discussionController = TextEditingController(text: widget.lead.discussion ?? "");

    selectedStatus = widget.lead.status;
    followUpDate = widget.lead.followUpDate;
  }

  @override
  void dispose() {
    companyController.dispose();
    contactController.dispose();
    mobileController.dispose();
    emailController.dispose();
    productController.dispose();
    discussionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Edit Lead Details", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
                "Client Profile",
                Icons.person_pin_rounded,
                isDark,
                [
                  _buildModernField(companyController, "Company Name", Icons.store_rounded),
                  _buildModernField(contactController, "Contact Person", Icons.person_rounded),
                  _buildModernField(mobileController, "Mobile Number", Icons.phone_iphone_rounded, keyboard: TextInputType.phone),
                  _buildModernField(emailController, "Email Address", Icons.alternate_email_rounded, keyboard: TextInputType.emailAddress),
                ],
              ),
              _buildSectionCard(
                "Sales Intelligence",
                Icons.insights_rounded,
                isDark,
                [
                  _buildModernField(productController, "Product/Service Pitched", Icons.shopping_cart_checkout_rounded),
                  _buildStatusSelector(isDark),
                  _buildModernField(discussionController, "Remarks & Discussion", Icons.notes_rounded, maxLines: 3),
                ],
              ),
              _buildSectionCard(
                "Timeline",
                Icons.event_note_rounded,
                isDark,
                [
                  _buildDatePicker(isDark),
                ],
              ),
              const SizedBox(height: 30),
              _buildUpdateButton(),
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.grey, letterSpacing: 0.5)),
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
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
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
          const Text("Lead Status", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ["Hot", "Warm", "Cold", "Lost", "Closed"].map((s) {
              final isSelected = selectedStatus == s;
              return ChoiceChip(
                label: Text(s),
                selected: isSelected,
                onSelected: (val) => setState(() => selectedStatus = s),
                selectedColor: AppColors.primary,
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

  Widget _buildDatePicker(bool isDark) {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              followUpDate == null ? "Schedule Follow-up" : "Follow-up: ${followUpDate!.day}/${followUpDate!.month}/${followUpDate!.year}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
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
        onPressed: _updateLead,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: const Text("SAVE & SYNC CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
      ),
    );
  }

  // --- LOGIC ---

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: followUpDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => followUpDate = picked);
  }

  Future<void> _updateLead() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('leads')
          .where('mobile', isEqualTo: widget.lead.mobile)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({
          'companyName': companyController.text.trim(),
          'contactPersonName': contactController.text.trim(),
          'email': emailController.text.trim(),
          'status': selectedStatus,
          'productPitched': productController.text.trim(),
          'discussion': discussionController.text.trim(),
          'followUpDate': followUpDate?.toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await (db.update(db.leads)..where((l) => l.id.equals(widget.lead.id))).write(
        LeadsCompanion(
          companyName: drift.Value(companyController.text.trim()),
          contactPersonName: drift.Value(contactController.text.trim()),
          mobile: drift.Value(mobileController.text.trim()),
          email: drift.Value(emailController.text.trim()),
          productPitched: drift.Value(productController.text.trim()),
          discussion: drift.Value(discussionController.text.trim()),
          status: drift.Value(selectedStatus),
          followUpDate: drift.Value(followUpDate),
        ),
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Changes Saved & Synced"), backgroundColor: Colors.blueAccent, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sync Error: $e"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
    }
  }
}