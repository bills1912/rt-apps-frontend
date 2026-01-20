import 'dart:convert';
import 'package:rt_app_apk/models/laporan_keuangan.dart';
import 'package:rt_app_apk/services/api_services.dart';

class LaporanKeuanganService {
  final ApiServices _apiServices;

  LaporanKeuanganService(this._apiServices);

  Future<List<LaporanKeuangan>> getAll({String? periode, String? jenisTransaksi}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (periode != null) queryParams['periode'] = periode;
      if (jenisTransaksi != null) queryParams['jenisTransaksi'] = jenisTransaksi;

      final response = await _apiServices.dio.get(
        '/laporan-keuangan',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
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
          .map((e) => LaporanKeuangan.fromJson(e))
          .toList();
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LaporanSummary>> getSummary({String? periode}) async {
    try {
      final queryParams = periode != null ? {'periode': periode} : null;

      final response = await _apiServices.dio.get(
        '/laporan-keuangan/summary',
        queryParameters: queryParams,
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
          .map((e) => LaporanSummary.fromJson(e))
          .toList();
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> create({
    required DateTime tanggal,
    required String jenisTransaksi,
    required String kategori,
    String? pihakKetiga,
    required double jumlah,
    String? keterangan,
    String? periode,
  }) async {
    try {
      final response = await _apiServices.dio.post(
        '/laporan-keuangan',
        data: {
          'tanggal': tanggal.toIso8601String(),
          'jenisTransaksi': jenisTransaksi,
          'kategori': kategori,
          'pihakKetiga': pihakKetiga,
          'jumlah': jumlah,
          'keterangan': keterangan,
          'periode': periode,
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

  Future<bool> update({
    required int id,
    DateTime? tanggal,
    String? jenisTransaksi,
    String? kategori,
    String? pihakKetiga,
    double? jumlah,
    String? keterangan,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (tanggal != null) data['tanggal'] = tanggal.toIso8601String();
      if (jenisTransaksi != null) data['jenisTransaksi'] = jenisTransaksi;
      if (kategori != null) data['kategori'] = kategori;
      if (pihakKetiga != null) data['pihakKetiga'] = pihakKetiga;
      if (jumlah != null) data['jumlah'] = jumlah;
      if (keterangan != null) data['keterangan'] = keterangan;

      final response = await _apiServices.dio.put(
        '/laporan-keuangan/$id',
        data: data,
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

  Future<bool> delete(int id) async {
    try {
      final response = await _apiServices.dio.delete('/laporan-keuangan/$id');
      final body = response.data;

      if (body['error'] != null) {
        throw Exception(body['error']);
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getPeriods() async {
    try {
      final response = await _apiServices.dio.get('/laporan-keuangan/periods');
      final body = response.data;

      if (body['error'] != null) {
        throw Exception(body['error']);
      }

      var dataList = body['data'];
      if (dataList is String) {
        dataList = jsonDecode(dataList);
      }

      return (dataList as List).map((e) => e.toString()).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> publishToWarga({required String periode}) async {
    try {
      final response = await _apiServices.dio.post(
        '/laporan-keuangan/publish',
        data: {'periode': periode},
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

  // Get published reports (for users) - with required periode
  Future<List<LaporanKeuangan>> getPublishedReports({required String periode}) async {
    try {
      final response = await _apiServices.dio.get(
        '/laporan-keuangan/published',
        queryParameters: {'periode': periode},
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
          .map((e) => LaporanKeuangan.fromJson(e))
          .toList();
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LaporanSummary>> getPublishedSummary({required String periode}) async {
    try {
      final response = await _apiServices.dio.get(
        '/laporan-keuangan/published/summary',
        queryParameters: {'periode': periode},
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
          .map((e) => LaporanSummary.fromJson(e))
          .toList();
      return data;
    } catch (e) {
      rethrow;
    }
  }
}