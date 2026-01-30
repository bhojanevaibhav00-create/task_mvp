import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnackBar('All fields are required');
      return;
    }

    if (!email.contains('@')) {
      _showSnackBar('Invalid email format');
      return;
    }

    if (password != confirm) {
      _showSnackBar('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      _showSnackBar('Registration successful!');
      context.go(AppRoutes.login);
    }

    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildLogo(),
                const SizedBox(height: 32),

                // Register Card
                Container(
                  width: 420,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Create Account",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sign up to start your workspace",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildTextField(
                        controller: _emailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _passwordController,
                        label: "Password",
                        icon: Icons.lock_outline,
                        isObscure: true,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _confirmController,
                        label: "Confirm Password",
                        icon: Icons.lock_reset_outlined,
                        isObscure: true,
                      ),
                      const SizedBox(height: 32),

                      _buildRegisterButton(),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: Text(
                          "Already have an account? Login",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
          )
        ],
      ),
      child: const Icon(
        Icons.task_alt_rounded,
        size: 48,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      // --- THE FIX: Force typing color to be dark grey/black ---
      style: const TextStyle(color: Color(0xFF111827), fontSize: 16), 
      decoration: InputDecoration(
        labelText: label,
        // --- Added labelStyle to ensure the hint/label is visible grey ---
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text(
              "Register",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
    );
  }
}