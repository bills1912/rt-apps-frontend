class DataWarga {
  final int id;
  final int userId;
  final String nama;
  final String alamat;
  final Map<String, bool> paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  DataWarga({
    required this.id,
    required this.userId,
    required this.nama,
    required this.alamat,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DataWarga.fromJson(Map<String, dynamic> json) {
    // Parse payment status
    Map<String, bool> status = {};
    if (json['paymentStatus'] != null) {
      if (json['paymentStatus'] is Map) {
        json['paymentStatus'].forEach((key, value) {
          status[key.toString()] = value == true || value == 1;
        });
      }
    }

    return DataWarga(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId'].toString()) ?? 0,
      nama: json['nama']?.toString() ?? '',
      alamat: json['alamat']?.toString() ?? '',
      paymentStatus: status,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'nama': nama,
      'alamat': alamat,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PaymentStats {
  final int totalWarga;
  final Map<String, MonthStats> monthlyStats;

  PaymentStats({
    required this.totalWarga,
    required this.monthlyStats,
  });

  factory PaymentStats.fromJson(dynamic json) {
    // PERBAIKAN: Accept dynamic and convert safely
    final Map<String, dynamic> data = json is Map<String, dynamic>
        ? json
        : Map<String, dynamic>.from(json as Map);

    Map<String, MonthStats> stats = {};

    if (data['monthlyStats'] != null) {
      final monthlyStatsRaw = data['monthlyStats'];

      if (monthlyStatsRaw is Map) {
        monthlyStatsRaw.forEach((key, value) {
          try {
            if (value != null) {
              // Safely convert each value to Map<String, dynamic>
              final Map<String, dynamic> valueMap;

              if (value is Map<String, dynamic>) {
                valueMap = value;
              } else if (value is Map) {
                valueMap = {
                  'paid': value['paid'],
                  'unpaid': value['unpaid'],
                };
              } else {
                return; // Skip invalid entries
              }

              stats[key.toString()] = MonthStats.fromJson(valueMap);
            }
          } catch (e) {
            print('Error parsing month stats for $key: $e');
          }
        });
      }
    }

    return PaymentStats(
      totalWarga: data['totalWarga'] is int
          ? data['totalWarga']
          : int.tryParse(data['totalWarga']?.toString() ?? '0') ?? 0,
      monthlyStats: stats,
    );
  }
}

class MonthStats {
  final int paid;
  final int unpaid;

  MonthStats({
    required this.paid,
    required this.unpaid,
  });

  factory MonthStats.fromJson(Map<String, dynamic> json) {
    return MonthStats(
      paid: json['paid'] is int
          ? json['paid']
          : int.tryParse(json['paid']?.toString() ?? '0') ?? 0,
      unpaid: json['unpaid'] is int
          ? json['unpaid']
          : int.tryParse(json['unpaid']?.toString() ?? '0') ?? 0,
    );
  }

  double get percentagePaid {
    final total = paid + unpaid;
    return total > 0 ? (paid / total) * 100 : 0;
  }
}