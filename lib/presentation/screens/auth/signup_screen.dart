import 'package:flutter/material.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../theme/app_text_styles.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text("Create Account", style: AppTextStyles.heading),
              const SizedBox(height: 8),
              const Text("Sign up to get started", style: AppTextStyles.body),

              const SizedBox(height: 32),
              const AppTextField(label: "Full Name"),
              const SizedBox(height: 16),
              const AppTextField(label: "Email"),
              const SizedBox(height: 16),
              const AppTextField(label: "Password", obscureText: true),

              const SizedBox(height: 24),
              PrimaryButton(
                text: "Sign Up",
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Already have an account? Login"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
