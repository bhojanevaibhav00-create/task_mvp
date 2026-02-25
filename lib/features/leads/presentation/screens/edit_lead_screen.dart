import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

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

  late String selectedStatus;
  DateTime? followUpDate;

  @override
  void initState() {
    super.initState();

    companyController =
        TextEditingController(text: widget.lead.companyName);
    contactController =
        TextEditingController(text: widget.lead.contactPersonName);
    mobileController =
        TextEditingController(text: widget.lead.mobile);
    emailController =
        TextEditingController(text: widget.lead.email ?? "");

    selectedStatus = widget.lead.status;
    followUpDate = widget.lead.followUpDate;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.scaffoldDark : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Edit Lead"),
        backgroundColor:
        isDark ? AppColors.cardDark : Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              _buildTextField(companyController, "Company Name"),
              _buildTextField(contactController, "Contact Person"),
              _buildTextField(
                  mobileController, "Mobile Number",
                  keyboard: TextInputType.phone),
              _buildTextField(
                  emailController, "Email",
                  keyboard: TextInputType.emailAddress),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: "Lead Status",
                ),
                items: ["Hot", "Warm", "Cold", "Lost", "Closed"]
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  followUpDate == null
                      ? "Select Follow-up Date"
                      : "Follow-up: ${followUpDate!.day}/${followUpDate!.month}/${followUpDate!.year}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: followUpDate ?? DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      followUpDate = picked;
                    });
                  }
                },
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _updateLead,
                child: const Text("Update Lead"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType keyboard = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (value) =>
        value == null || value.isEmpty ? "Required field" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _updateLead() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);

    await (db.update(db.leads)
      ..where((l) => l.id.equals(widget.lead.id)))
        .write(
      LeadsCompanion(
        companyName: drift.Value(companyController.text.trim()),
        contactPersonName:
        drift.Value(contactController.text.trim()),
        mobile: drift.Value(mobileController.text.trim()),
        email: drift.Value(emailController.text.trim()),
        status: drift.Value(selectedStatus),
        followUpDate: drift.Value(followUpDate),
      ),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }
}