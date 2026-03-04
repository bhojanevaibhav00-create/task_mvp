import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../data/database/database.dart';

class EditLeadScreen extends ConsumerStatefulWidget {
  final Lead lead; // This is the Drift generated class

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
    // Initialize with existing lead data
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
        title: const Text("Edit Lead", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTextField(companyController, "Company Name", Icons.business),
            _buildTextField(contactController, "Contact Person", Icons.person),
            _buildTextField(mobileController, "Mobile Number", Icons.phone, keyboard: TextInputType.phone),
            _buildTextField(emailController, "Email", Icons.email, keyboard: TextInputType.emailAddress),
            _buildTextField(productController, "Product Pitched", Icons.shopping_bag),
            _buildTextField(discussionController, "Discussion/Remarks", Icons.notes, maxLines: 3),

            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: "Lead Status",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ["Hot", "Warm", "Cold", "Lost", "Closed"]
                  .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) => setState(() => selectedStatus = value!),
            ),

            ListTile(
              title: Text(followUpDate == null 
                ? "Select Follow-up" 
                : "Follow-up: ${followUpDate!.day}/${followUpDate!.month}/${followUpDate!.year}"),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _updateLead,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("UPDATE & SYNC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Same helper as AddLeadScreen for consistency
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: (value) => value == null || value.isEmpty ? "Required" : null,
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
      initialDate: followUpDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => followUpDate = picked);
  }

  Future<void> _updateLead() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);

    try {
      // 1. Update Cloud (Firebase)
      // Note: This assumes you stored the Firestore Document ID in your Drift table. 
      // If you didn't, you should query Firestore by mobile number or another unique field.
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

      // 2. Update Local (Drift)
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
          const SnackBar(content: Text("Lead Updated & Synced"), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update Failed: $e"), backgroundColor: Colors.red),
      );
    }
  }
}