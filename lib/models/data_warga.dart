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

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    Map<String, MonthStats> stats = {};

    if (json['monthlyStats'] != null && json['monthlyStats'] is Map) {
      json['monthlyStats'].forEach((key, value) {
        stats[key.toString()] = MonthStats.fromJson(value);
      });
    }

    return PaymentStats(
      totalWarga: json['totalWarga'] ?? 0,
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
      paid: json['paid'] ?? 0,
      unpaid: json['unpaid'] ?? 0,
    );
  }

  double get percentagePaid {
    final total = paid + unpaid;
    return total > 0 ? (paid / total) * 100 : 0;
  }
}