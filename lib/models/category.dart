class Category {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? icon;
  final int displayOrder;
  final bool isActive;
  final int productCount;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.icon,
    required this.displayOrder,
    this.isActive = true,
    this.productCount = 0,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      icon: json['icon'] as String?,
      displayOrder: json['displayOrder'] as int,
      isActive: json['isActive'] as bool? ?? true,
      productCount: json['productCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'icon': icon,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'productCount': productCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? icon,
    int? displayOrder,
    bool? isActive,
    int? productCount,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      icon: icon ?? this.icon,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, productCount: $productCount)';
  }
}
