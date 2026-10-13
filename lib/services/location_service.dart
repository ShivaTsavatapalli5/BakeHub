import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bakehub/models/delivery_location.dart';

class LocationService {
  static LocationService instance = LocationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'delivery_locations';

  /// Create a new delivery location
  Future<String> createLocation(DeliveryLocation location) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'adminId': location.adminId,
        'locationName': location.locationName,
        'street': location.street,
        'city': location.city,
        'state': location.state,
        'pinCode': location.pinCode,
        'landmark': location.landmark,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'isActive': location.isActive,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create location: $e');
    }
  }

  /// Get all delivery locations for an admin (as stream)
  Stream<List<DeliveryLocation>> getLocationsByAdmin(String adminId) {
    return _firestore
        .collection(_collection)
        .where('adminId', isEqualTo: adminId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return DeliveryLocation.fromJson(data);
          }).toList();
        });
  }

  /// Get all active delivery locations for customers
  Stream<List<DeliveryLocation>> getActiveLocations() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final locations = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return DeliveryLocation.fromJson(data);
          }).toList();

          // Sort by location name in memory to avoid Firestore composite index
          locations.sort((a, b) => a.locationName.compareTo(b.locationName));
          return locations;
        });
  }

  /// Get location by ID
  Future<DeliveryLocation?> getLocationById(String locationId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(locationId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return DeliveryLocation.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  /// Update location
  Future<void> updateLocation(
    String locationId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection(_collection).doc(locationId).update(updates);
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  /// Toggle location active status
  Future<void> toggleLocationStatus(String locationId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(locationId).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw Exception('Failed to toggle location status: $e');
    }
  }

  /// Delete location
  Future<void> deleteLocation(String locationId) async {
    try {
      await _firestore.collection(_collection).doc(locationId).delete();
    } catch (e) {
      throw Exception('Failed to delete location: $e');
    }
  }

  /// Get location count by admin
  Future<int> getLocationCount(String adminId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('adminId', isEqualTo: adminId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get location count: $e');
    }
  }
}
