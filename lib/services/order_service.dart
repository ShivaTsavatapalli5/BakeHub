import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:bakehub/models/order.dart';

class OrderService {
  static final OrderService instance = OrderService._internal();
  factory OrderService() => instance;
  OrderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _ordersCollection = 'orders';

  // Create a new order
  Future<String?> createOrder(Order order) async {
    try {
      final docRef = _firestore.collection(_ordersCollection).doc();
      final orderWithId = order.copyWith(id: docRef.id);
      await docRef.set(orderWithId.toJson());
      print('✅ Order created: ${orderWithId.id}');
      return orderWithId.id;
    } catch (e) {
      print('❌ Error creating order: $e');
      return null;
    }
  }

  // Get orders stream for a user (real-time)
  Stream<List<Order>> getOrdersStream(String userId) {
    return _firestore
        .collection(_ordersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return Order.fromJson(doc.data());
            } catch (e) {
              print('❌ Error parsing order ${doc.id}: $e');
              rethrow;
            }
          }).toList();
        });
  }

  // Get a single order
  Future<Order?> getOrder(String orderId) async {
    try {
      final doc = await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .get();
      if (doc.exists) {
        return Order.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting order: $e');
      return null;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': status.toString().split('.').last,
      });
      print(
        '✅ Order status updated: $orderId -> ${status.toString().split('.').last}',
      );
      return true;
    } catch (e) {
      print('❌ Error updating order status: $e');
      return false;
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus(String orderId, PaymentStatus status) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'paymentStatus': status.toString().split('.').last,
      });
      print(
        '✅ Payment status updated: $orderId -> ${status.toString().split('.').last}',
      );
      return true;
    } catch (e) {
      print('❌ Error updating payment status: $e');
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      final Map<String, dynamic> data = {
        'status': OrderStatus.cancelled.toString().split('.').last,
      };
      if (reason != null && reason.isNotEmpty) {
        data['cancellationReason'] = reason;
      }
      await _firestore.collection(_ordersCollection).doc(orderId).update(data);
      print('✅ Order cancelled: $orderId');
      return true;
    } catch (e) {
      print('❌ Error cancelling order: $e');
      return false;
    }
  }

  // Add rating and review
  Future<bool> addRating(String orderId, int rating, String? review) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'rating': rating,
        'review': review,
      });
      print('✅ Rating added to order: $orderId');
      return true;
    } catch (e) {
      print('❌ Error adding rating: $e');
      return false;
    }
  }

  // Get all orders (for admin)
  Stream<List<Order>> getAllOrdersStream() {
    return _firestore
        .collection(_ordersCollection)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return Order.fromJson(doc.data());
            } catch (e) {
              print('❌ Error parsing order ${doc.id}: $e');
              rethrow;
            }
          }).toList();
        });
  }

  // Get orders by status (for admin)
  Stream<List<Order>> getOrdersByStatusStream(OrderStatus status) {
    return _firestore
        .collection(_ordersCollection)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return Order.fromJson(doc.data());
            } catch (e) {
              print('❌ Error parsing order ${doc.id}: $e');
              rethrow;
            }
          }).toList();
        });
  }

  // Update delivery times
  Future<bool> updateDeliveryTime(
    String orderId, {
    DateTime? estimatedTime,
    DateTime? actualTime,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (estimatedTime != null) {
        updates['estimatedDeliveryTime'] = estimatedTime.toIso8601String();
      }
      if (actualTime != null) {
        updates['actualDeliveryTime'] = actualTime.toIso8601String();
      }

      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .update(updates);
      print('✅ Delivery time updated: $orderId');
      return true;
    } catch (e) {
      print('❌ Error updating delivery time: $e');
      return false;
    }
  }
}
