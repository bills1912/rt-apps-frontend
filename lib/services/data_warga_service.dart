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

  Future<Map<String, dynamic>> getAllWargaPaginated({
    int page = 1,
    int limit = 10,
    String search = ''
  }) async {
    try {
      final response = await _apiServices.dio.get(
        '/data-warga',
        queryParameters: {
          'page': page,
          'limit': limit,
          'search': search,
        },
      );
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

      return {
        'data': data,
        'pagination': body['pagination'] ?? {},
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentStats> getPaymentStats({String? month}) async {
    try {
      // Prepare query parameters
      final queryParams = <String, dynamic>{};
      if (month != null && month.isNotEmpty) {
        queryParams['month'] = month;
        print('🔍 Requesting stats with month: $month');
      }

      final response = await _apiServices.dio.get(
        '/data-warga/stats',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Raw response data: ${response.data}');

      final body = response.data;

      if (body == null) {
        throw Exception('Response body is null');
      }

      if (body['error'] != null) {
        throw Exception(body['error']);
      }

      // Extract data
      dynamic statsData = body['data'];

      print('📊 Stats data type: ${statsData.runtimeType}');
      print('📊 Stats data content: $statsData');

      // Handle string response
      if (statsData is String) {
        print('⚠️ Stats data is string, parsing...');
        try {
          statsData = jsonDecode(statsData);
          print('✅ Parsed to: ${statsData.runtimeType}');
        } catch (e) {
          print('❌ Failed to parse string: $e');
          throw Exception('Failed to parse stats data');
        }
      }

      // Validate structure
      if (statsData == null) {
        throw Exception('Stats data is null');
      }

      // Create PaymentStats from dynamic data
      try {
        final stats = PaymentStats.fromJson(statsData);
        print('✅ PaymentStats created successfully');
        print('   Total Warga: ${stats.totalWarga}');
        print('   Monthly Stats Keys: ${stats.monthlyStats.keys.join(", ")}');
        return stats;
      } catch (e) {
        print('❌ Error creating PaymentStats: $e');
        rethrow;
      }

    } catch (e, stackTrace) {
      print('❌ Error in getPaymentStats: $e');
      print('Stack trace: $stackTrace');
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