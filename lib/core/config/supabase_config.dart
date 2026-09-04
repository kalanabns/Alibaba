class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static void validate() {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw StateError(
        'Missing or invalid SUPABASE_URL. Start the app with '
        '--dart-define-from-file=config/supabase.local.json.',
      );
    }

    if (publishableKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_PUBLISHABLE_KEY. Start the app with '
        '--dart-define-from-file=config/supabase.local.json.',
      );
    }
  }
}
