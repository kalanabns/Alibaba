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
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListenableBuilder(
                listenable: widget.authController,
                builder: (context, _) {
                  final isLoading = widget.authController.isLoading;
                  final errorMessage = widget.authController.errorMessage;

                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Cyber-Navy Brand Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 28,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.heroGradient,
                              border: const Border(
                                bottom: BorderSide(color: Color(0x3538BDF8), width: 1.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryLight.withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Finora AI',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Intelligent SMB Financial Health & AI CFO',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Crisp White Form Container
                          Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Sign In to Workspace',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Access your financial radar, ledger, and AI CFO.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
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
                                  const SizedBox(height: 22),
                                  FinoraPrimaryButton(
                                    text: 'Sign In',
                                    isLoading: isLoading,
                                    onPressed: _handleLogin,
                                  ),
                                  const SizedBox(height: 18),
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
                                        child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  if (widget.businessController != null) ...[
                                    const SizedBox(height: 16),
                                    const Row(
                                      children: [
                                        Expanded(child: Divider()),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            'HACKATHON EVALUATION',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.textMuted,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.6,
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
                                      icon: const Icon(Icons.science_rounded, size: 18, color: AppTheme.primaryColor),
                                      label: const Text('Explore Demo Workspace (Pacific Coast Roasters)'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryColor,
                                        side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
