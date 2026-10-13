import 'package:cloud_firestore/cloud_firestore.dart';

class DBServices {
  static DBServices instance = DBServices();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new user document in Firestore
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'role': 'customer', // default role
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'photoUrl': null,
        'phoneNumber': phone,
        'address': null,
      });
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  /// Get user data from Firestore
  Future<DocumentSnapshot> getUserData(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    }
  }

  /// Update user data in Firestore
  Future<void> updateUser({
    required String uid,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (data != null) {
        data['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(uid).update(data);
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  /// Delete user document from Firestore
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  /// Check if user exists in Firestore
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  /// Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  /// Stream user data
  Stream<DocumentSnapshot> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Get all users (for admin)
  Future<QuerySnapshot> getAllUsers() async {
    try {
      return await _firestore.collection('users').get();
    } catch (e) {
      print('Error getting all users: $e');
      rethrow;
    }
  }

  /// Stream all users (for admin)
  Stream<QuerySnapshot> streamAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  /// Create admin user with bakery details
  Future<void> createAdminUser({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required Map<String, dynamic> bakeryDetails,
  }) async {
    try {
      // Create user document with admin role
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phoneNumber': phone,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'photoUrl': null,
        'address': bakeryDetails['address'],
      });

      // Create bakery document
      await _firestore.collection('bakeries').doc(uid).set({
        'ownerId': uid,
        'bakeryName': bakeryDetails['bakeryName'],
        'email': email,
        'phone': phone,
        'address': bakeryDetails['address'],
        'businessHours': bakeryDetails['businessHours'],
        // Delivery Settings
        'deliveryRadius': bakeryDetails['deliveryRadius'],
        'deliveryCharge': bakeryDetails['deliveryCharge'],
        'freeDeliveryAbove': bakeryDetails['freeDeliveryAbove'],
        'estimatedDelivery': bakeryDetails['estimatedDelivery'],
        // Payment Settings
        'paymentMethods': bakeryDetails['paymentMethods'],
        'qrCodeImageUrl': bakeryDetails['qrCodeImageUrl'],
        'upiId': bakeryDetails['upiId'],
        // Tax Configuration
        'gstRate': bakeryDetails['gstRate'],
        'gstin': bakeryDetails['gstin'],
        // Metadata
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      print('Error creating admin user: $e');
      rethrow;
    }
  }

  /// Get bakery details
  Future<DocumentSnapshot> getBakeryDetails(String ownerId) async {
    try {
      return await _firestore.collection('bakeries').doc(ownerId).get();
    } catch (e) {
      print('Error getting bakery details: $e');
      rethrow;
    }
  }

  /// Update bakery details
  Future<void> updateBakeryDetails({
    required String ownerId,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('bakeries').doc(ownerId).update(data);
    } catch (e) {
      print('Error updating bakery details: $e');
      rethrow;
    }
  }
}
