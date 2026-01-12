// models/notification_model.dart
class NotificationModel {
  final int id;
  final int tagihanId;
  final String forRole;
  final bool isGlobal;
  final DateTime createdAt;
  final String type;
  final String title;
  final String message;

  NotificationModel({
    required this.id,
    required this.tagihanId,
    required this.forRole,
    required this.isGlobal,
    required this.createdAt,
    required this.type,
    required this.title,
    required this.message,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      tagihanId:
          json['tagihanId'] is int
              ? json['tagihanId']
              : int.tryParse(json['tagihanId'].toString()) ?? 0,
      forRole: json['forRole'],
      isGlobal: json['isGlobal'],
      createdAt: DateTime.parse(json['createdAt']),
      type: json['type'],
      title: json['title'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tagihanId': tagihanId,
      'forRole': forRole,
      'isGlobal': isGlobal,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
      'title': title,
      'message': message,
    };
  }
}
