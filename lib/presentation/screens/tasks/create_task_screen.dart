import 'package:flutter/material.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../theme/app_text_styles.dart';

class CreateTaskScreen extends StatelessWidget {  // <-- THIS name must match
  const CreateTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create / Edit Task")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const AppTextField(label: "Title"),
            const SizedBox(height: 16),
            const AppTextField(label: "Description", maxLines: 4),
            const SizedBox(height: 16),
            const AppTextField(label: "Remarks"),
            const SizedBox(height: 16),
            const AppTextField(label: "Due Date"),
            const SizedBox(height: 16),
            const AppTextField(label: "Priority"),
            const SizedBox(height: 24),
            PrimaryButton(
              text: "Save Task",
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
