enum DiscountType { percentage, fixedAmount }

class Coupon {
  final String id;
  final String code;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final double? maxDiscount;
  final double? minOrderAmount;
  final int? maxUsageCount;
  final int? usageCount;
  final int? maxUsagePerUser;
  final DateTime validFrom;
  final DateTime validUpto;
  final bool isActive;
  final List<String>? applicableCategories;
  final DateTime createdAt;

  Coupon({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    this.minOrderAmount,
    this.maxUsageCount,
    this.usageCount,
    this.maxUsagePerUser,
    required this.validFrom,
    required this.validUpto,
    this.isActive = true,
    this.applicableCategories,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(validUpto);

  bool get isValid =>
      isActive && !isExpired && DateTime.now().isAfter(validFrom);

  double calculateDiscount(double amount) {
    if (!isValid) return 0;
    if (minOrderAmount != null && amount < minOrderAmount!) return 0;

    double discount = 0;
    if (discountType == DiscountType.percentage) {
      discount = (amount * discountValue) / 100;
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      discount = discountValue;
    }
    return discount;
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String,
      discountType: json['discountType'] == 'percentage'
          ? DiscountType.percentage
          : DiscountType.fixedAmount,
      discountValue: (json['discountValue'] as num).toDouble(),
      maxDiscount: json['maxDiscount'] != null
          ? (json['maxDiscount'] as num).toDouble()
          : null,
      minOrderAmount: json['minOrderAmount'] != null
          ? (json['minOrderAmount'] as num).toDouble()
          : null,
      maxUsageCount: json['maxUsageCount'] as int?,
      usageCount: json['usageCount'] as int?,
      maxUsagePerUser: json['maxUsagePerUser'] as int?,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validUpto: DateTime.parse(json['validUpto'] as String),
      isActive: json['isActive'] as bool? ?? true,
      applicableCategories: json['applicableCategories'] != null
          ? List<String>.from(json['applicableCategories'] as List)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discountType': discountType == DiscountType.percentage
          ? 'percentage'
          : 'fixedAmount',
      'discountValue': discountValue,
      'maxDiscount': maxDiscount,
      'minOrderAmount': minOrderAmount,
      'maxUsageCount': maxUsageCount,
      'usageCount': usageCount,
      'maxUsagePerUser': maxUsagePerUser,
      'validFrom': validFrom.toIso8601String(),
      'validUpto': validUpto.toIso8601String(),
      'isActive': isActive,
      'applicableCategories': applicableCategories,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Coupon copyWith({
    String? id,
    String? code,
    String? description,
    DiscountType? discountType,
    double? discountValue,
    double? maxDiscount,
    double? minOrderAmount,
    int? maxUsageCount,
    int? usageCount,
    int? maxUsagePerUser,
    DateTime? validFrom,
    DateTime? validUpto,
    bool? isActive,
    List<String>? applicableCategories,
    DateTime? createdAt,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxUsageCount: maxUsageCount ?? this.maxUsageCount,
      usageCount: usageCount ?? this.usageCount,
      maxUsagePerUser: maxUsagePerUser ?? this.maxUsagePerUser,
      validFrom: validFrom ?? this.validFrom,
      validUpto: validUpto ?? this.validUpto,
      isActive: isActive ?? this.isActive,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Coupon(code: $code, discountValue: $discountValue, isValid: $isValid)';
  }
}
