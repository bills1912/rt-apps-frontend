import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rt_app_apk/models/auth_response.dart';

import 'package:rt_app_apk/services/api_services.dart';

class UserService {
  final ApiServices _apiServices;

  UserService(this._apiServices);

  Future<bool> signIn(String kk, String password) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      final response = await _apiServices.dio.post(
        '/auth/login',
        data: {'kk': kk, 'password': password, 'fcmToken': token},
      );
      final data = response.data;

      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      var authData = data['data'];
      if (authData is String) {
        authData = jsonDecode(authData);
      }
      // Handle double encoded JSON
      if (authData is String) {
        authData = jsonDecode(authData);
      }

      final authResponse = AuthResponse.fromJson(authData);

      await _apiServices.storage.write(
        key: 'auth_token',
        value: authResponse.token,
      );

      await _apiServices.storage.write(
        key: 'user_info',
        value: jsonEncode(authResponse.user),
      );

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> signUp(
    String kk,
    String password,
    String name,
    String address,
  ) async {
    try {
      final response = await _apiServices.dio.post(
        '/auth/register',
        data: {
          'kk': kk,
          'password': password,
          'name': name,
          'address': address,
        },
      );
      final data = response.data;

      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }
}
