import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bakehub/models/coupon.dart';

class CouponService {
  static CouponService instance = CouponService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'coupons';

  /// Create a new coupon
  Future<String> createCoupon(Coupon coupon) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'code': coupon.code.toUpperCase(),
        'description': coupon.description,
        'discountType': coupon.discountType == DiscountType.percentage
            ? 'percentage'
            : 'fixedAmount',
        'discountValue': coupon.discountValue,
        'maxDiscount': coupon.maxDiscount,
        'minOrderAmount': coupon.minOrderAmount,
        'maxUsageCount': coupon.maxUsageCount,
        'usageCount': 0,
        'maxUsagePerUser': coupon.maxUsagePerUser,
        'validFrom': coupon.validFrom.toIso8601String(),
        'validUpto': coupon.validUpto.toIso8601String(),
        'isActive': true,
        'applicableCategories': coupon.applicableCategories,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create coupon: $e');
    }
  }

  /// Get all coupons (admin view)
  Stream<List<Coupon>> getAllCoupons() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Coupon.fromJson(data);
          }).toList();
        });
  }

  /// Get active coupons only
  Stream<List<Coupon>> getActiveCoupons() {
    final now = DateTime.now().toIso8601String();
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('validUpto', isGreaterThanOrEqualTo: now)
        .orderBy('validUpto')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Coupon.fromJson(data);
          }).toList();
        });
  }

  /// Get coupon by ID
  Future<Coupon?> getCouponById(String couponId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(couponId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Coupon.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get coupon: $e');
    }
  }

  /// Get coupon by code
  Future<Coupon?> getCouponByCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return Coupon.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get coupon by code: $e');
    }
  }

  /// Update coupon
  Future<void> updateCoupon(
    String couponId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Uppercase the code if it's being updated
      if (updates.containsKey('code')) {
        updates['code'] = (updates['code'] as String).toUpperCase();
      }

      await _firestore.collection(_collection).doc(couponId).update(updates);
    } catch (e) {
      throw Exception('Failed to update coupon: $e');
    }
  }

  /// Toggle coupon active status
  Future<void> toggleCouponStatus(String couponId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(couponId).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw Exception('Failed to toggle coupon status: $e');
    }
  }

  /// Delete coupon
  Future<void> deleteCoupon(String couponId) async {
    try {
      await _firestore.collection(_collection).doc(couponId).delete();
    } catch (e) {
      throw Exception('Failed to delete coupon: $e');
    }
  }

  /// Validate and apply coupon
  Future<Map<String, dynamic>> validateCoupon(
    String code,
    double orderAmount,
    String? userId,
  ) async {
    try {
      final coupon = await getCouponByCode(code);

      if (coupon == null) {
        return {'isValid': false, 'message': 'Invalid coupon code'};
      }

      if (!coupon.isActive) {
        return {'isValid': false, 'message': 'This coupon is no longer active'};
      }

      if (coupon.isExpired) {
        return {'isValid': false, 'message': 'This coupon has expired'};
      }

      if (DateTime.now().isBefore(coupon.validFrom)) {
        return {'isValid': false, 'message': 'This coupon is not valid yet'};
      }

      if (coupon.minOrderAmount != null &&
          orderAmount < coupon.minOrderAmount!) {
        return {
          'isValid': false,
          'message': 'Minimum order amount is ₹${coupon.minOrderAmount}',
        };
      }

      if (coupon.maxUsageCount != null &&
          coupon.usageCount != null &&
          coupon.usageCount! >= coupon.maxUsageCount!) {
        return {
          'isValid': false,
          'message': 'This coupon has reached its usage limit',
        };
      }

      // Check per-user usage limit if userId is provided
      if (userId != null && coupon.maxUsagePerUser != null) {
        final userUsage = await _getUserCouponUsage(coupon.id, userId);
        if (userUsage >= coupon.maxUsagePerUser!) {
          return {
            'isValid': false,
            'message': 'You have already used this coupon',
          };
        }
      }

      final discount = coupon.calculateDiscount(orderAmount);

      return {
        'isValid': true,
        'discount': discount,
        'couponId': coupon.id,
        'message': 'Coupon applied successfully!',
      };
    } catch (e) {
      return {'isValid': false, 'message': 'Error validating coupon: $e'};
    }
  }

  /// Increment coupon usage count
  Future<void> incrementCouponUsage(String couponId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Increment total usage count
      final couponRef = _firestore.collection(_collection).doc(couponId);
      batch.update(couponRef, {'usageCount': FieldValue.increment(1)});

      // Track user-specific usage
      final usageRef = _firestore
          .collection(_collection)
          .doc(couponId)
          .collection('userUsage')
          .doc(userId);
      batch.set(usageRef, {
        'userId': userId,
        'usedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to increment coupon usage: $e');
    }
  }

  /// Get user's coupon usage count
  Future<int> _getUserCouponUsage(String couponId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(couponId)
          .collection('userUsage')
          .doc(userId)
          .get();

      return snapshot.exists ? 1 : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get coupon statistics
  Future<Map<String, dynamic>> getCouponStats() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      int totalCoupons = snapshot.docs.length;
      int activeCoupons = 0;
      int totalUsed = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isActive = data['isActive'] as bool? ?? false;
        final usageCount = data['usageCount'] as int? ?? 0;

        if (isActive) {
          activeCoupons++;
        }
        totalUsed += usageCount;
      }

      return {
        'totalCoupons': totalCoupons,
        'activeCoupons': activeCoupons,
        'totalUsed': totalUsed,
      };
    } catch (e) {
      throw Exception('Failed to get coupon stats: $e');
    }
  }
}
