import 'package:rt_app_apk/models/user.dart';

class AuthResponse {
  String? token;
  User? user;

  AuthResponse({this.token, this.user});

  AuthResponse.fromJson(Map<String, dynamic> json) {
    token = json['token'];
    user =
        json['user'] != null
            ? User.fromJson(json['user'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =
        Map<String, dynamic>();

    data['token'] = token;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}
