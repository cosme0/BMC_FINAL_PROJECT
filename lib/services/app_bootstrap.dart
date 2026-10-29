import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Prepares the Supabase client used for payments.
///
/// Initialisation is guarded by a timeout so a slow/unreachable backend can
/// never block the first frame. Errors are exposed through [lastError] so the
/// payment screen can show a readable message instead of crashing.
class AppBootstrap {
  AppBootstrap._();

  static Future<String?>? _initialisation;

  /// Error from the last initialisation attempt, or `null` on success.
  static String? lastError;

  /// Initialises Supabase and returns `null` on success or an error message.
  static Future<String?> initialize() {
    return _initialisation ??= _initialise();
  }

  static Future<String?> _initialise() async {
    if (!AppConfig.isConfigured) {
      lastError = 'Supabase credentials are not configured.';
      return lastError;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseKey,
        authOptions: const FlutterAuthClientOptions(
          // Checkout is guest-based: no customer sign-in is required, so no
          // persisted session or deep-link observer is needed.
          detectSessionInUri: false,
          persistSession: false,
          autoRefreshToken: false,
        ),
      ).timeout(const Duration(seconds: 15));

      lastError = null;
      return null;
    } catch (error) {
      lastError = '$error';
      return lastError;
    }
  }
}
