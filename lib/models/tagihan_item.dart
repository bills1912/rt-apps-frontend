class TagihanItem {
  final String name;
  final String description;
  final int price;

  TagihanItem({
    required this.name,
    required this.description,
    required this.price,
  });

  factory TagihanItem.fromJson(Map<String, dynamic> json) {
    return TagihanItem(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
  };
}
