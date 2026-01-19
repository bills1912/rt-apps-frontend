import 'dart:convert';
import 'package:rt_app_apk/models/data_warga.dart';
import 'package:rt_app_apk/services/api_services.dart';

class DataWargaService {
  final ApiServices _apiServices;

  DataWargaService(this._apiServices);

  Future<List<DataWarga>> getAllWarga() async {
    try {
      final response = await _apiServices.dio.get('/data-warga');
      final body = response.data;

      if (body['error'] != null) {
        throw Exception(body['error']);
      }

      var dataList = body['data'];
      if (dataList is String) {
        dataList = jsonDecode(dataList);
      }

      final data = (dataList as List)
          .map((e) => DataWarga.fromJson(e))
          .toList();
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentStats> getPaymentStats({String? month}) async {
    try {
      final queryParams = month != null ? {'month': month} : null;

      final response = await _apiServices.dio.get(
        '/data-warga/stats',
        queryParameters: queryParams,
      );
      final body = response.data;

      if (body['error'] != null) {
        throw Exception(body['error']);
      }

      // Handle response structure
      var statsData = body['data'];

      // If statsData is a string, parse it
      if (statsData is String) {
        statsData = jsonDecode(statsData);
      }

      return PaymentStats.fromJson(statsData);
    } catch (e) {
      print('Error in getPaymentStats: $e');
      rethrow;
    }
  }

  Future<bool> updatePaymentStatus(
      int wargaId,
      String month,
      bool status,
      ) async {
    try {
      final response = await _apiServices.dio.put(
        '/data-warga/$wargaId/payment-status',
        data: {
          'month': month,
          'status': status,
        },
      );
      final body = response.data;

      if (body['error'] != null) {
        throw Exception(body['error']);
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> syncWargaData() async {
    try {
      final response = await _apiServices.dio.post('/data-warga/sync');
      final body = response.data;

      if (body['error'] != null) {
        throw Exception(body['error']);
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateWargaAddress(int wargaId, String alamat) async {
    try {
      final response = await _apiServices.dio.put(
        '/data-warga/$wargaId/address',
        data: {'alamat': alamat},
      );
      final body = response.data;

      if (body['error'] != null) {
        throw Exception(body['error']);
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }
}