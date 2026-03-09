import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  // ✅ AJINKYA SIR'S CHANGE: Module Selection Toggle
  String _selectedModule = "Project"; 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===================================================================
  // ✅ FIREBASE LOGIN LOGIC WITH ROLE-BASED REDIRECTION
  // ===================================================================
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter email and password");
      return;
    }

    if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar("Please enter a valid email");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Authenticate with Firebase
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Fetch User Module Type from Cloud
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        final userModule = userDoc.data()?['module'] ?? "Project";

        if (mounted) {
          // 3. Separate Navigation based on Module
          if (userModule == "Lead") {
            context.go('/lead-dashboard'); 
          } else {
            context.go(AppRoutes.dashboard);
          }
        }
      } else {
        _showSnackBar("User module profile not found.");
      }

    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Login failed.");
    } catch (e) {
      _showSnackBar("Unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===================================================================
  // ✅ SNACKBAR (Original Styling)
  // ===================================================================
  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF1A1C1E),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ===================================================================
  // ✅ UI (FULL ORIGINAL FORMAT)
  // ===================================================================
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
                        "Welcome Back",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sign in to access your workspace",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ✅ TOGGLE SECTION: Added while maintaining UI flow
                      _buildModuleToggle(),
                      const SizedBox(height: 24),

                      _buildTextField(
                        controller: _emailController,
                        label: "Email Address",
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _passwordController,
                        label: "Password",
                        icon: Icons.lock_outline,
                        isObscure: true,
                      ),
                      const SizedBox(height: 32),

                      _buildLoginButton(),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () => context.push(AppRoutes.register),
                        child: const Text(
                          "Don't have an account? Register",
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

  Widget _buildModuleToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildToggleItem("Project", 0),
          _buildToggleItem("Lead", 1),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, int index) {
    bool isSelected = _selectedModule == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedModule = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
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
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
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
      style: const TextStyle(color: Color(0xFF1A1C1E), fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text(
              "Login",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }
}