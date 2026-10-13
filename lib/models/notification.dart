enum NotificationType {
  orderPlaced,
  orderConfirmed,
  orderPreparing,
  orderReady,
  outForDelivery,
  orderDelivered,
  orderCancelled,
  payment,
  promotion,
  newProduct,
  general,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? imageUrl;
  final String? deepLink;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.imageUrl,
    this.deepLink,
    this.metadata,
    this.isRead = false,
    required this.createdAt,
  });

  String get typeText {
    switch (type) {
      case NotificationType.orderPlaced:
        return 'Order Placed';
      case NotificationType.orderConfirmed:
        return 'Order Confirmed';
      case NotificationType.orderPreparing:
        return 'Preparing Order';
      case NotificationType.orderReady:
        return 'Ready for Delivery';
      case NotificationType.outForDelivery:
        return 'Out for Delivery';
      case NotificationType.orderDelivered:
        return 'Order Delivered';
      case NotificationType.orderCancelled:
        return 'Order Cancelled';
      case NotificationType.payment:
        return 'Payment';
      case NotificationType.promotion:
        return 'Special Offer';
      case NotificationType.newProduct:
        return 'New Product';
      case NotificationType.general:
        return 'Notification';
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.general,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      imageUrl: json['imageUrl'] as String?,
      deepLink: json['deepLink'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'deepLink': deepLink,
      'metadata': metadata,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? imageUrl,
    String? deepLink,
    Map<String, dynamic>? metadata,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      deepLink: deepLink ?? this.deepLink,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, type: ${type.toString().split('.').last}, isRead: $isRead)';
  }
}
