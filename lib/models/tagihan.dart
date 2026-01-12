import 'dart:convert';
import 'package:rt_app_apk/models/tagihan_item.dart';

class Tagihan {
  final int id;
  final List<TagihanItem> items;
  final DateTime tagihanDate;
  final int totalPrice;
  final bool? isPaid;
  final String? tagihanName;
  final String? tagihanDescription;

  Tagihan({
    required this.id,
    required this.items,
    required this.tagihanDate,
    required this.totalPrice,
    this.isPaid,
    this.tagihanName,
    this.tagihanDescription,
  });

  factory Tagihan.fromJson(Map<String, dynamic> json) {
    var itemsJson = json['items'];
    if (itemsJson is String) {
      itemsJson = jsonDecode(itemsJson);
    }

    return Tagihan(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      items:
          (itemsJson as List)
              .map((item) => TagihanItem.fromJson(item))
              .toList(),
      tagihanDate:
          json['tagihanDate'] != null
              ? DateTime.parse(json['tagihanDate'])
              : DateTime.now(),
      totalPrice: json['totalPrice'],
      isPaid: json['isPaid'],
      tagihanName: json['tagihanName'] ?? 'Nama Tagihan',
      tagihanDescription: json['tagihanDescription'] ?? 'Tidak ada deskripsi',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((item) => item.toJson()).toList(),
    'tagihanDate': tagihanDate.toIso8601String(),
    'totalPrice': totalPrice,
  };
}
