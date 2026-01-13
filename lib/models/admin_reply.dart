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
    try {
      // Parse images dengan validasi
      List<String> parsedImages = [];
      var imagesData = json['images'];

      if (imagesData != null) {
        if (imagesData is List) {
          parsedImages = imagesData
              .where((item) => item != null)
              .map((item) => item.toString())
              .toList();
        } else if (imagesData is String) {
          parsedImages = [imagesData];
        }
      }

      return AdminReply(
        date: json['date'] != null
            ? DateTime.parse(json['date'])
            : DateTime.now(),
        images: parsedImages,
        description: json['description']?.toString() ?? '',
      );
    } catch (e) {
      print('Error in AdminReply.fromJson: $e');
      print('JSON data: $json');
      // Return default object instead of throwing
      return AdminReply(
        date: DateTime.now(),
        images: [],
        description: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'images': images,
      'description': description,
    };
  }
}