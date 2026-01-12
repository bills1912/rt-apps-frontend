import 'dart:convert';
import 'package:rt_app_apk/models/admin_reply.dart';
import 'package:rt_app_apk/models/tagihan.dart';
import 'package:rt_app_apk/models/user_info.dart';

class TagihanUser {
  final int id;
  final Tagihan tagihan;
  final List<UserInfo> userInfo;
  final List<AdminReply> adminReply;
  final String status;
  final int userId;
  final DateTime paidAt;

  TagihanUser({
    required this.id,
    required this.tagihan,
    required this.userInfo,
    required this.adminReply,
    required this.status,
    required this.userId,
    required this.paidAt,
  });

  factory TagihanUser.fromJson(Map<String, dynamic> json) {
    var userInfoJson = json['userInfo'];
    if (userInfoJson is String) {
      userInfoJson = jsonDecode(userInfoJson);
    }

    var adminReplyJson = json['adminReply'];
    if (adminReplyJson is String) {
      adminReplyJson = jsonDecode(adminReplyJson);
    }

    return TagihanUser(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      tagihan: Tagihan.fromJson(json['tagihan']),
      userInfo:
          (userInfoJson as List).map((e) => UserInfo.fromJson(e)).toList(),
      adminReply:
          (adminReplyJson as List).map((e) => AdminReply.fromJson(e)).toList(),
      status: json['status'],
      userId:
          json['userId'] is int
              ? json['userId']
              : int.tryParse(json['userId'].toString()) ?? 0,
      paidAt: DateTime.parse(json['paidAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tagihan': tagihan.toJson(),
    'userInfo': userInfo.map((e) => e.toJson()).toList(),
    'adminReply': adminReply.map((e) => e.toJson()).toList(),
    'status': status,
    'userId': userId,
    'paidAt': paidAt.toIso8601String(),
  };
}
