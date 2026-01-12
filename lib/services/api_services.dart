import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiServices {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  ApiServices() {
    _dio.options.baseUrl = 'https://rt-apps-backend-production.up.railway.app/api';
    // _dio.options.baseUrl = 'http://192.168.178.12:5001/api';
    // _dio.options.baseUrl = 'http://192.168.1.6:5001/api';

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  FlutterSecureStorage get storage => _storage;
}
