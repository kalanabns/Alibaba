import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utilities/validators.dart';
import '../../../shared/widgets/finora_error_view.dart';
import '../../../shared/widgets/finora_primary_button.dart';
import '../../../shared/widgets/finora_text_field.dart';
import '../application/auth_controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final success = await widget.authController.signUp(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      // Pop back to root auth gate controller
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ListenableBuilder(
              listenable: widget.authController,
              builder: (context, _) {
                final isLoading = widget.authController.isLoading;
                final errorMessage = widget.authController.errorMessage;

                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Get Started with Finora AI',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your account to start managing your business financial health.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (errorMessage != null) ...[
                        FinoraErrorView(
                          message: errorMessage,
                          onRetry: widget.authController.clearError,
                        ),
                        const SizedBox(height: 20),
                      ],
                      FinoraTextField(
                        controller: _emailController,
                        label: 'Business Email',
                        hint: 'owner@business.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        enabled: !isLoading,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      FinoraTextField(
                        controller: _passwordController,
                        label: 'Password',
                        obscureText: true,
                        prefixIcon: Icons.lock_outlined,
                        enabled: !isLoading,
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: 16),
                      FinoraTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        obscureText: true,
                        prefixIcon: Icons.lock_clock_outlined,
                        enabled: !isLoading,
                        validator: (val) => Validators.validateConfirmPassword(
                          val,
                          _passwordController.text,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FinoraPrimaryButton(
                        text: 'Create Account',
                        isLoading: isLoading,
                        onPressed: _handleSignUp,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
