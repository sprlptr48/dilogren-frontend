import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/schemas.dart';

class AuthService with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token';

  String? _token;
  UserProfile? _user;

  String? get token => _token;
  UserProfile? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;

  AuthService() {
    _loadTokenFromStorage();
  }

  Future<void> _loadTokenFromStorage() async {
    _token = await _storage.read(key: _tokenKey);
    // On app start, if we have a token, we should try to get the user profile
    // For this project, we will force a re-login for simplicity.
    /*if (_token != null) {
      await logout();
    }*/
    notifyListeners();
  }

  // Called by ApiService after getting a token
  Future<void> setTokenForSession(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: _token);
    // We don't notify listeners yet, as the user is not fully authenticated
  }

  // Called by ApiService after getting the user profile
  void finalizeLogin(UserProfile userProfile) {
    _user = userProfile;
    // Now the user is fully authenticated, notify all listeners
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }

  void updateUser(UserProfile user) {
    _user = user;
    notifyListeners();
  }
}
