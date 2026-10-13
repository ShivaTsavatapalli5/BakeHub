import 'package:cloud_firestore/cloud_firestore.dart';

class Bakery {
  final String id;
  final String bakeryName;
  final String address;
  final String businessHours;

  // Contact Information
  final String? contactPhone;
  final String? contactEmail;

  // Delivery Settings
  final String deliveryRadius;
  final String deliveryCharge;
  final String freeDeliveryAbove;
  final String estimatedDelivery;

  // Payment Methods
  final PaymentMethods paymentMethods;
  final String? qrCodeImageUrl;
  final String? upiId;

  // Tax Settings
  final String gstRate;
  final String gstin;

  final DateTime createdAt;
  final DateTime updatedAt;

  Bakery({
    required this.id,
    required this.bakeryName,
    required this.address,
    required this.businessHours,
    this.contactPhone,
    this.contactEmail,
    required this.deliveryRadius,
    required this.deliveryCharge,
    required this.freeDeliveryAbove,
    required this.estimatedDelivery,
    required this.paymentMethods,
    this.qrCodeImageUrl,
    this.upiId,
    required this.gstRate,
    required this.gstin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bakery.fromJson(Map<String, dynamic> json) {
    return Bakery(
      id: json['id'] ?? '',
      bakeryName: json['bakeryName'] ?? '',
      address: json['address'] ?? '',
      businessHours: json['businessHours'] ?? '',
      contactPhone: json['contactPhone'],
      contactEmail: json['contactEmail'],
      deliveryRadius: json['deliveryRadius']?.toString() ?? '0',
      deliveryCharge: json['deliveryCharge']?.toString() ?? '0',
      freeDeliveryAbove: json['freeDeliveryAbove']?.toString() ?? '0',
      estimatedDelivery: json['estimatedDelivery'] ?? '',
      paymentMethods: PaymentMethods.fromJson(
        json['paymentMethods'] as Map<String, dynamic>? ?? {},
      ),
      qrCodeImageUrl: json['qrCodeImageUrl'],
      upiId: json['upiId'],
      gstRate: json['gstRate']?.toString() ?? '0',
      gstin: json['gstin'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bakeryName': bakeryName,
      'address': address,
      'businessHours': businessHours,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'deliveryRadius': deliveryRadius,
      'deliveryCharge': deliveryCharge,
      'freeDeliveryAbove': freeDeliveryAbove,
      'estimatedDelivery': estimatedDelivery,
      'paymentMethods': paymentMethods.toJson(),
      'qrCodeImageUrl': qrCodeImageUrl,
      'upiId': upiId,
      'gstRate': gstRate,
      'gstin': gstin,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Bakery copyWith({
    String? id,
    String? bakeryName,
    String? address,
    String? businessHours,
    String? contactPhone,
    String? contactEmail,
    String? deliveryRadius,
    String? deliveryCharge,
    String? freeDeliveryAbove,
    String? estimatedDelivery,
    PaymentMethods? paymentMethods,
    String? qrCodeImageUrl,
    String? upiId,
    String? gstRate,
    String? gstin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bakery(
      id: id ?? this.id,
      bakeryName: bakeryName ?? this.bakeryName,
      address: address ?? this.address,
      businessHours: businessHours ?? this.businessHours,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      freeDeliveryAbove: freeDeliveryAbove ?? this.freeDeliveryAbove,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      qrCodeImageUrl: qrCodeImageUrl ?? this.qrCodeImageUrl,
      upiId: upiId ?? this.upiId,
      gstRate: gstRate ?? this.gstRate,
      gstin: gstin ?? this.gstin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PaymentMethods {
  final bool cashOnDelivery;
  final bool qrCodePayment;
  final bool upiIdPayment;

  PaymentMethods({
    required this.cashOnDelivery,
    required this.qrCodePayment,
    required this.upiIdPayment,
  });

  factory PaymentMethods.fromJson(Map<String, dynamic> json) {
    return PaymentMethods(
      cashOnDelivery: json['cashOnDelivery'] ?? false,
      qrCodePayment: json['qrCodePayment'] ?? false,
      upiIdPayment: json['upiIdPayment'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cashOnDelivery': cashOnDelivery,
      'qrCodePayment': qrCodePayment,
      'upiIdPayment': upiIdPayment,
    };
  }

  PaymentMethods copyWith({
    bool? cashOnDelivery,
    bool? qrCodePayment,
    bool? upiIdPayment,
  }) {
    return PaymentMethods(
      cashOnDelivery: cashOnDelivery ?? this.cashOnDelivery,
      qrCodePayment: qrCodePayment ?? this.qrCodePayment,
      upiIdPayment: upiIdPayment ?? this.upiIdPayment,
    );
  }
}
