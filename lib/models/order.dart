import 'address.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

enum PaymentMethod { cashOnDelivery, creditCard, debitCard, upi }

enum PaymentStatus { pending, completed, failed, refunded }

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? productImage;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.productImage,
  });

  double get totalPrice => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      productImage: json['productImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'productImage': productImage,
    };
  }

  OrderItem copyWith({
    String? id,
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    String? productImage,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      productImage: productImage ?? this.productImage,
    );
  }

  @override
  String toString() {
    return 'OrderItem(id: $id, productName: $productName, quantity: $quantity)';
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryCharge;
  final double tax;
  final double totalAmount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final Address deliveryAddress;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final DateTime orderDate;
  final String? notes;
  final int? rating;
  final String? review;
  final String? paymentScreenshot;
  final String? utrNumber;
  final String? couponId;
  final String? couponCode;
  final double? discountAmount;
  final String? cancellationReason;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryCharge,
    required this.tax,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    required this.orderDate,
    this.notes,
    this.rating,
    this.review,
    this.paymentScreenshot,
    this.utrNumber,
    this.couponId,
    this.couponCode,
    this.discountAmount,
    this.cancellationReason,
  });

  bool get canBeCancelled =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  bool get canBeRated => status == OrderStatus.delivered;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: List<OrderItem>.from(
        (json['items'] as List?)?.map(
              (item) => OrderItem.fromJson(item as Map<String, dynamic>),
            ) ??
            [],
      ),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryCharge: (json['deliveryCharge'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['status']}',
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${json['paymentMethod']}',
        orElse: () => PaymentMethod.cashOnDelivery,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${json['paymentStatus']}',
        orElse: () => PaymentStatus.pending,
      ),
      deliveryAddress: Address.fromJson(
        json['deliveryAddress'] as Map<String, dynamic>,
      ),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'] as String)
          : null,
      actualDeliveryTime: json['actualDeliveryTime'] != null
          ? DateTime.parse(json['actualDeliveryTime'] as String)
          : null,
      orderDate: DateTime.parse(json['orderDate'] as String),
      notes: json['notes'] as String?,
      rating: json['rating'] as int?,
      review: json['review'] as String?,
      paymentScreenshot: json['paymentScreenshot'] as String?,
      utrNumber: json['utrNumber'] as String?,
      couponId: json['couponId'] as String?,
      couponCode: json['couponCode'] as String?,
      discountAmount: json['discountAmount'] != null
          ? (json['discountAmount'] as num).toDouble()
          : null,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'tax': tax,
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'deliveryAddress': deliveryAddress.toJson(),
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'actualDeliveryTime': actualDeliveryTime?.toIso8601String(),
      'orderDate': orderDate.toIso8601String(),
      'notes': notes,
      'rating': rating,
      'review': review,
      'paymentScreenshot': paymentScreenshot,
      'utrNumber': utrNumber,
      'couponId': couponId,
      'couponCode': couponCode,
      'discountAmount': discountAmount,
      'cancellationReason': cancellationReason,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryCharge,
    double? tax,
    double? totalAmount,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    Address? deliveryAddress,
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    DateTime? orderDate,
    String? notes,
    int? rating,
    String? review,
    String? paymentScreenshot,
    String? utrNumber,
    String? couponId,
    String? couponCode,
    double? discountAmount,
    String? cancellationReason,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      tax: tax ?? this.tax,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      orderDate: orderDate ?? this.orderDate,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      paymentScreenshot: paymentScreenshot ?? this.paymentScreenshot,
      utrNumber: utrNumber ?? this.utrNumber,
      couponId: couponId ?? this.couponId,
      couponCode: couponCode ?? this.couponCode,
      discountAmount: discountAmount ?? this.discountAmount,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  @override
  String toString() {
    return 'Order(id: $id, userId: $userId, totalAmount: $totalAmount, status: ${status.toString().split('.').last})';
  }
}
