class Category {
  final String id;
  final String name;
  final String imageUrl;
  final int order;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.order = 0,
  });

  factory Category.fromFirestore(String id, Map<String, dynamic> data) {
    return Category(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['image_url'] ?? '',
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image_url': imageUrl,
      'order': order,
    };
  }
}
