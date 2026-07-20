import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _sub;

  User? _user;
  bool _loading = false;
  String? _errorKey;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get errorKey => _errorKey;

  AuthProvider() {
    _user = _authService.currentUser;
    _sub = _authService.authStateChanges.listen((u) {
      _user = u;
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<bool> signUp(String email, String password) async {
    _errorKey = null;
    _setLoading(true);
    try {
      await _authService.signUpWithEmail(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorKey = _authService.errorKey(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _errorKey = null;
    _setLoading(true);
    try {
      await _authService.signInWithEmail(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorKey = _authService.errorKey(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _errorKey = null;
    _setLoading(true);
    try {
      final result = await _authService.signInWithGoogle();
      _setLoading(false);
      return result != null;
    } catch (e) {
      _errorKey = _authService.errorKey(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _errorKey = null;
    try {
      await _authService.sendPasswordReset(email);
      return true;
    } catch (e) {
      _errorKey = _authService.errorKey(e);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
