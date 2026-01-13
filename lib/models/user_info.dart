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
    try {
      // Parse transferProof dengan validasi
      List<String> parsedTransferProof = [];
      var transferProofData = json['transferProof'];

      if (transferProofData != null) {
        if (transferProofData is List) {
          parsedTransferProof = transferProofData
              .where((item) => item != null)
              .map((item) => item.toString())
              .toList();
        } else if (transferProofData is String) {
          parsedTransferProof = [transferProofData];
        }
      }

      return UserInfo(
        date: json['date'] != null
            ? DateTime.parse(json['date'])
            : DateTime.now(),
        transferProof: parsedTransferProof,
        description: json['description']?.toString() ?? '',
      );
    } catch (e) {
      print('Error in UserInfo.fromJson: $e');
      print('JSON data: $json');
      // Return default object instead of throwing
      return UserInfo(
        date: DateTime.now(),
        transferProof: [],
        description: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'transferProof': transferProof,
      'description': description,
    };
  }
}