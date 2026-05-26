import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Mock credentials
  static const String mockEmail = 'user@example.com';
  static const String mockPassword = 'password123';
  static const String mockToken = 'mock_jwt_token_12345';
  
  // Storage keys
  static const String _tokenKey = 'auth_token';
  
  /// Validate login credentials
  Future<bool> login(String email, String password) async {
    // Mock validation
    if (email == mockEmail && password == mockPassword) {
      // Store mock JWT token
      await _storage.write(key: _tokenKey, value: mockToken);
      return true;
    }
    return false;
  }
  
  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }
  
  /// Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
  
  /// Logout - clear token
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }
}

// Made with Bob
