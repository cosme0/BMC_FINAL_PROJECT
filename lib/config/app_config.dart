/// Application configuration for the First Gear Gym app.
///
/// The Supabase **publishable/anon** key is public and safe to ship in a
/// Flutter binary. The service-role key, Xendit secret key and webhook token
/// are server-side only and live in Supabase Edge Function secrets.
///
/// The working demo project below is used by default, so the app runs without
/// any local setup. To point it at another project, create a `.env` file
/// (see `.env.example`) and run:
///
/// ```bash
/// flutter run --dart-define-from-file=.env
/// flutter build apk --release --dart-define-from-file=.env
/// ```
///
/// `--dart-define` values can also be passed individually.
class AppConfig {
  AppConfig._();

  /// Working demo project used by the BMC finals reference app.
  static const String _defaultSupabaseUrl =
      'https://kfvxqsxycpmawgbwugyr.supabase.co';

  static const String _defaultSupabaseKey =
      'sb_publishable_IJvYbkAOlEZu1rDqquaKtg_FTmV5Pq7';

  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultSupabaseUrl,
  );

  static const String _supabaseKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultSupabaseKey,
  );

  static String get supabaseUrl => _supabaseUrl.trim();

  static String get supabaseKey => _supabaseKey.trim();

  /// True when the app has everything it needs to talk to Supabase.
  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') && supabaseKey.isNotEmpty;

  /// Human readable name of the application.
  static const String appName = 'First Gear Gym';

  /// Currency of the demonstration (Philippine Peso, used by Xendit).
  static const String currencySymbol = '₱';

  /// Name of the Edge Function that creates the Xendit invoice.
  static const String createInvoiceFunction = 'create-invoice';
}
