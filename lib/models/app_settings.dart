class AppSettings {
  final double taxPercent;
  final double deliveryFee;
  final double freeDeliveryMinAmount;

  AppSettings({
    required this.taxPercent,
    required this.deliveryFee,
    required this.freeDeliveryMinAmount,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 5.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 50.0,
      freeDeliveryMinAmount:
          (json['freeDeliveryMinAmount'] as num?)?.toDouble() ?? 500.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taxPercent': taxPercent,
      'deliveryFee': deliveryFee,
      'freeDeliveryMinAmount': freeDeliveryMinAmount,
    };
  }

  // Default settings
  factory AppSettings.defaultSettings() {
    return AppSettings(
      taxPercent: 12.0,
      deliveryFee: 20.0,
      freeDeliveryMinAmount: 499.0,
    );
  }

  @override
  String toString() {
    return 'AppSettings(taxPercent: $taxPercent%, deliveryFee: $deliveryFee, freeDeliveryMinAmount: $freeDeliveryMinAmount)';
  }
}
