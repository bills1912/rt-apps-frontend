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
    try {
      // Parse userInfo dengan pengecekan tipe yang lebih ketat
      List<UserInfo> parsedUserInfo = [];
      var userInfoJson = json['userInfo'];

      if (userInfoJson != null) {
        if (userInfoJson is String) {
          try {
            userInfoJson = jsonDecode(userInfoJson);
          } catch (e) {
            print('Error decoding userInfo string: $e');
          }
        }

        if (userInfoJson is List) {
          parsedUserInfo = userInfoJson
              .where((item) => item != null)
              .map((e) {
            try {
              return UserInfo.fromJson(e is Map<String, dynamic> ? e : {});
            } catch (e) {
              print('Error parsing UserInfo item: $e');
              return null;
            }
          })
              .whereType<UserInfo>()
              .toList();
        } else if (userInfoJson is Map<String, dynamic>) {
          // Jika userInfo adalah single object, bungkus dalam list
          try {
            parsedUserInfo = [UserInfo.fromJson(userInfoJson)];
          } catch (e) {
            print('Error parsing single UserInfo: $e');
          }
        }
      }

      // Parse adminReply dengan pengecekan tipe yang lebih ketat
      List<AdminReply> parsedAdminReply = [];
      var adminReplyJson = json['adminReply'];

      if (adminReplyJson != null) {
        if (adminReplyJson is String) {
          try {
            adminReplyJson = jsonDecode(adminReplyJson);
          } catch (e) {
            print('Error decoding adminReply string: $e');
          }
        }

        if (adminReplyJson is List) {
          parsedAdminReply = adminReplyJson
              .where((item) => item != null)
              .map((e) {
            try {
              return AdminReply.fromJson(e is Map<String, dynamic> ? e : {});
            } catch (e) {
              print('Error parsing AdminReply item: $e');
              return null;
            }
          })
              .whereType<AdminReply>()
              .toList();
        } else if (adminReplyJson is Map<String, dynamic>) {
          // Jika adminReply adalah single object, bungkus dalam list
          try {
            parsedAdminReply = [AdminReply.fromJson(adminReplyJson)];
          } catch (e) {
            print('Error parsing single AdminReply: $e');
          }
        }
      }

      // Parse tagihan
      Tagihan parsedTagihan;
      var tagihanJson = json['tagihan'];

      if (tagihanJson is String) {
        try {
          tagihanJson = jsonDecode(tagihanJson);
        } catch (e) {
          print('Error decoding tagihan string: $e');
          throw Exception('Invalid tagihan data');
        }
      }

      if (tagihanJson is Map<String, dynamic>) {
        parsedTagihan = Tagihan.fromJson(tagihanJson);
      } else {
        throw Exception('Tagihan data is not in expected format');
      }

      return TagihanUser(
        id: json['id'] is int
            ? json['id']
            : int.tryParse(json['id'].toString()) ?? 0,
        tagihan: parsedTagihan,
        userInfo: parsedUserInfo,
        adminReply: parsedAdminReply,
        status: json['status']?.toString() ?? 'unknown',
        userId: json['userId'] is int
            ? json['userId']
            : int.tryParse(json['userId'].toString()) ?? 0,
        paidAt: json['paidAt'] != null
            ? DateTime.parse(json['paidAt'])
            : DateTime.now(),
      );
    } catch (e) {
      print('Error in TagihanUser.fromJson: $e');
      print('JSON data: $json');
      rethrow;
    }
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