import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const String _tokenKey = 'github_token';
  static const String _profilePictureKey = 'profile_picture';

  // ============ GITHUB TOKEN ============
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ============ PROFILE PICTURE ============
  static Future<void> saveProfilePicture(String path) async {
    await _storage.write(key: _profilePictureKey, value: path);
  }

  static Future<String?> getProfilePicture() async {
    return await _storage.read(key: _profilePictureKey);
  }

  static Future<void> deleteProfilePicture() async {
    await _storage.delete(key: _profilePictureKey);
  }
}