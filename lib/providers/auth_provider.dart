import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  AppUser? user = const AppUser(
    uid: 'guest',
    displayName: 'Guest',
    email: null,
  );
  bool loading = false;
  String? error;

  AuthProvider() {
    _load();
  }

  AuthService get service => _service;

  bool get isAuthenticated => user != null;

  Future<void> _load() async {
    loading = true;
    notifyListeners();
    try {
      user = await _service.getCurrentUser();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      user = await _service.signIn(email: email, password: password);
    } catch (e) {
      error = _friendlyAuthError(e, fallback: 'Sign in failed');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      user = await _service.signUp(
        email: email,
        password: password,
        name: name,
      );
    } catch (e) {
      error = _friendlyAuthError(e, fallback: 'Sign up failed');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    user = await _service.getCurrentUser();
    notifyListeners();
  }

  String _friendlyAuthError(Object e, {required String fallback}) {
    final raw = e.toString().toLowerCase();
    if (raw.contains('already exists')) {
      return 'That email is already in use. Try logging in instead.';
    }
    if (raw.contains('invalid email or password')) {
      return 'Invalid email or password.';
    }
    if (raw.contains('password')) {
      return 'Please check your password and try again.';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
