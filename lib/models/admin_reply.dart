class AdminReply {
  final DateTime date;
  final List<String> images;
  final String description;

  AdminReply({
    required this.date,
    required this.images,
    required this.description,
  });

  factory AdminReply.fromJson(Map<String, dynamic> json) {
    return AdminReply(
      date: DateTime.parse(json['date']),
      images: List<String>.from(json['images']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'transferProof': images,
      'description': description,
    };
  }
}
