class UserInfo {
  final DateTime date;
  final List<String> transferProof;
  final String description;

  UserInfo({
    required this.date,
    required this.transferProof,
    required this.description,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      date: DateTime.parse(json['date']),
      transferProof: List<String>.from(
        json['transferProof'],
      ),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'transferProof': transferProof,
      'description': description,
    };
  }
}
