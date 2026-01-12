import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:rt_app_apk/models/tagihan.dart';
import 'package:rt_app_apk/models/tagihan_item.dart';
import 'package:rt_app_apk/models/tagihan_user.dart';
import 'package:rt_app_apk/services/api_services.dart';

class TagihanServices {
  final ApiServices _apiServices;

  TagihanServices(this._apiServices);

  Future<List<Tagihan>> getAll() async {
    try {
      final response = await _apiServices.dio.get('/tagihan');
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

      final data = (dataList as List).map((e) => Tagihan.fromJson(e)).toList();
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TagihanUser>> getAllTagihanUser() async {
    try {
      final response = await _apiServices.dio.get('/tagihan/tagihan-user');
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
          (dataList as List).map((e) => TagihanUser.fromJson(e)).toList();
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> payTicket(
    List<String> images,
    int tagihanId,
    String description,
  ) async {
    try {
      FormData formData = FormData.fromMap({
        'images': images,
        'tagihanId': tagihanId,
        'description': description,
      });
      final response = await _apiServices.dio.post(
        '/tagihan/pay',
        data: formData,
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

  Future<bool> updateTagihanUser(
    int tagihanId,
    String status, {
    List<String>? images,
    String? description,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'images': images,
        'description': description,
        'status': status,
      });
      final response = await _apiServices.dio.put(
        '/tagihan/tagihan-user/$tagihanId',
        data: formData,
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

  Future<bool> updateTagihanUserByUser(
    int tagihanId,
    List<String> images,
    String description,
  ) async {
    try {
      FormData formData = FormData.fromMap({
        'images': images,
        'description': description,
      });
      final response = await _apiServices.dio.put(
        '/tagihan/tagihan-user/by-user/$tagihanId',
        data: formData,
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

  Future<bool> create(
    List<TagihanItem> items,
    DateTime datetime,
    String tagihanName,
    String tagihanDescription,
  ) async {
    try {
      final response = await _apiServices.dio.post(
        '/tagihan',
        data: {
          'items': items,
          'tagihanDate': datetime.toIso8601String(),
          'tagihanName': tagihanName,
          'tagihanDescription': tagihanDescription,
        },
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

  Future<List<TagihanUser>> getAllTagihanUserHistory({String? month}) async {
    try {
      final response = await _apiServices.dio.get(
        '/tagihan/tagihan-user-history',
        queryParameters: {'month': month},
      );
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
          (dataList as List).map((e) => TagihanUser.fromJson(e)).toList();
      return data;
    } catch (e) {
      rethrow;
    }
  }
}
