import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utilities/validators.dart';
import '../../../shared/widgets/finora_error_view.dart';
import '../../../shared/widgets/finora_primary_button.dart';
import '../../../shared/widgets/finora_text_field.dart';
import '../../businesses/application/business_controller.dart';
import '../../businesses/data/demo_business_service.dart';
import '../application/auth_controller.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authController,
    this.businessController,
  });

  final AuthController authController;
  final BusinessController? businessController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    await widget.authController.signIn(
      _emailController.text,
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListenableBuilder(
                listenable: widget.authController,
                builder: (context, _) {
                  final isLoading = widget.authController.isLoading;
                  final errorMessage = widget.authController.errorMessage;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Navy Accent Brand Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryNavy.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 36,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Finora AI',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'AI-Powered Financial Health & Advisory',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Crisp White Form Container (60% Light Body)
                      Container(
                        padding: const EdgeInsets.all(28.0),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                          border: Border.all(color: AppTheme.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Sign In to Your Workspace',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Access your financial ledger, metrics, and AI CFO.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (errorMessage != null) ...[
                                FinoraErrorView(
                                  message: errorMessage,
                                  onRetry: widget.authController.clearError,
                                ),
                                const SizedBox(height: 16),
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
                              const SizedBox(height: 24),
                              FinoraPrimaryButton(
                                text: 'Sign In',
                                isLoading: isLoading,
                                onPressed: _handleLogin,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account?",
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            widget.authController.clearError();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => SignUpScreen(
                                                  authController:
                                                      widget.authController,
                                                ),
                                              ),
                                            );
                                          },
                                    child: const Text('Create Account'),
                                  ),
                                ],
                              ),
                                if (widget.businessController != null) ...[
                                  const SizedBox(height: 16),
                                  const Row(
                                    children: [
                                      Expanded(child: Divider()),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          'HACKATHON EVALUATION',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textMuted,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      Expanded(child: Divider()),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      final demo = DemoBusinessService.getDemoData();
                                      widget.businessController!.loadDemoMode(demo.business);
                                    },
                                    icon: const Icon(Icons.science_outlined, size: 18, color: AppTheme.primaryNavy),
                                    label: const Text('Explore Demo Workspace (Pacific Coast Roasters)'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryNavy,
                                      side: const BorderSide(color: AppTheme.primaryNavy),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
