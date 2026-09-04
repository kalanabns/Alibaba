import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/auth_gate.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/application/auth_controller.dart';
import 'features/businesses/application/business_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SupabaseConfig.validate();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const FinoraApp());
}

class FinoraApp extends StatefulWidget {
  const FinoraApp({super.key});

  @override
  State<FinoraApp> createState() => _FinoraAppState();
}

class _FinoraAppState extends State<FinoraApp> {
  late final AuthController _authController;
  late final BusinessController _businessController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _businessController = BusinessController();
  }

  @override
  void dispose() {
    _authController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finora AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: AuthGate(
        authController: _authController,
        businessController: _businessController,
      ),
    );
  }
}
