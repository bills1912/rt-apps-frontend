import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rt_app_apk/models/user.dart';

class StorageServices {
  static final _storage = FlutterSecureStorage();

  static Future<User?> getUser() async {
    final userString = await _storage.read(
      key: 'user_info',
    );
    return userString != null
        ? User.fromJson(jsonDecode(userString))
        : null;
  }

  static Future<void> saveUser(String userJson) async {
    await _storage.write(key: 'user_info', value: userJson);
  }

  static Future<void> deleteUser() async {
    await _storage.delete(key: 'user_info');
  }

  static Future<void> signOut() async {
    await deleteUser();
    await _storage.delete(key: 'auth_token');
  }
}
