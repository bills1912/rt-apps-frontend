import 'dart:convert';
import 'package:rt_app_apk/models/notification_model.dart';
import 'package:rt_app_apk/services/api_services.dart';

class NotificationServices {
  final ApiServices _apiServices;

  NotificationServices(this._apiServices);

  Future<List<NotificationModel>> getAll() async {
    try {
      final response = await _apiServices.dio.get('/notification');
      final body = response.data;

      if (body['error'] != null) {
        throw Exception(body['error']);
      }

      var dataList = body['data'];
      if (dataList is String) {
        dataList = jsonDecode(dataList);
      }
      // Handle double encoded JSON
      if (dataList is String) {
        dataList = jsonDecode(dataList);
      }

      final data =
          (dataList as List).map((e) => NotificationModel.fromJson(e)).toList();
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> delete(int notificationId) async {
    try {
      final response = await _apiServices.dio.delete(
        '/notification/$notificationId',
      );
      final body = response.data;
      if (body['error'] != null) {
        print(body['error']);
        throw Exception(body['error']);
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
