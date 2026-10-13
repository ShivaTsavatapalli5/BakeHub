class DeliveryLocation {
  final String id;
  final String adminId;
  final String locationName;
  final String street;
  final String city;
  final String state;
  final String pinCode;
  final String? landmark;
  final double latitude;
  final double longitude;
  final bool isActive;
  final DateTime createdAt;

  DeliveryLocation({
    required this.id,
    required this.adminId,
    required this.locationName,
    required this.street,
    required this.city,
    required this.state,
    required this.pinCode,
    this.landmark,
    required this.latitude,
    required this.longitude,
    this.isActive = true,
    required this.createdAt,
  });

  String get fullAddress =>
      '$street, ${landmark != null && landmark!.isNotEmpty ? "$landmark, " : ""}$city, $state - $pinCode';

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    return DeliveryLocation(
      id: json['id'] as String,
      adminId: json['adminId'] as String,
      locationName: json['locationName'] as String,
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pinCode: json['pinCode'] as String,
      landmark: json['landmark'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : (json['createdAt'] as DateTime),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adminId': adminId,
      'locationName': locationName,
      'street': street,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DeliveryLocation copyWith({
    String? id,
    String? adminId,
    String? locationName,
    String? street,
    String? city,
    String? state,
    String? pinCode,
    String? landmark,
    double? latitude,
    double? longitude,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return DeliveryLocation(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      locationName: locationName ?? this.locationName,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
