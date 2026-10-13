// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:bakehub/models/order.dart';
import 'package:bakehub/models/user.dart';
import 'package:bakehub/models/coupon.dart';
import 'package:bakehub/models/product.dart';
import 'package:bakehub/models/bakery.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== REAL-TIME DASHBOARD STREAMS ==========

  /// Get dashboard stats as a real-time stream
  Stream<Map<String, dynamic>> getDashboardStatsStream() {
    // Use orders collection listener for real-time updates
    return _firestore.collection('orders').snapshots().asyncMap((_) async {
      try {
        return await getDashboardStats();
      } catch (e) {
        print('Error in getDashboardStatsStream: $e');
        // Return empty stats on error
        return {
          'totalOrders': 0,
          'pendingOrders': 0,
          'todayRevenue': 0.0,
          'revenueChange': 0.0,
          'totalCustomers': 0,
          'newCustomersToday': 0,
        };
      }
    });
  }

  /// Get order status breakdown stream
  Stream<Map<OrderStatus, int>> getOrderStatusBreakdownStream() {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      Map<OrderStatus, int> breakdown = {
        for (var status in OrderStatus.values) status: 0,
      };

      for (var doc in snapshot.docs) {
        final statusStr = doc.data()['status'] as String?;
        if (statusStr != null) {
          final status = OrderStatus.values.firstWhere(
            (e) => e.name == statusStr,
            orElse: () => OrderStatus.pending,
          );
          breakdown[status] = (breakdown[status] ?? 0) + 1;
        }
      }

      return breakdown;
    });
  }

  /// Get recent orders stream
  Stream<List<Map<String, dynamic>>> getRecentOrdersStream({int limit = 5}) {
    return _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> orders = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final userId = data['userId'] as String?;

            // Fetch customer name
            String customerName = 'Unknown';
            if (userId != null) {
              try {
                final userDoc = await _firestore
                    .collection('users')
                    .doc(userId)
                    .get();
                if (userDoc.exists) {
                  customerName =
                      userDoc.data()?['name'] as String? ?? 'Unknown';
                }
              } catch (e) {
                // Handle error silently
              }
            }

            orders.add({
              'id': doc.id,
              'orderId': doc.id,
              'customerName': customerName,
              'items': (data['items'] as List?)?.length ?? 0,
              'status': data['status'] as String? ?? 'pending',
              'totalAmount': (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
              'orderDate': data['orderDate'],
            });
          }

          return orders;
        });
  }

  /// Get active coupons stream
  Stream<List<Map<String, dynamic>>> getActiveCouponsStream({int limit = 3}) {
    return _firestore
        .collection('coupons')
        .where('isActive', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final discountType = data['discountType'] as String?;
            final discountValue =
                (data['discountValue'] as num?)?.toDouble() ?? 0;

            String discountDisplay = '';
            if (discountType == 'percentage') {
              discountDisplay = '${discountValue.toInt()}% off';
            } else {
              discountDisplay = '₹${discountValue.toInt()} off';
            }

            final maxUsageCount = data['maxUsageCount'] as int?;
            final usageCount = data['usageCount'] as int? ?? 0;
            String usedDisplay = maxUsageCount != null
                ? '$usageCount/$maxUsageCount'
                : '$usageCount/Unlimited';

            return {
              'code': data['code'] as String? ?? '',
              'discount': discountDisplay,
              'used': usedDisplay,
              'status': 'Active',
            };
          }).toList();
        });
  }

  /// Get low stock products stream
  Stream<List<Map<String, dynamic>>> getLowStockProductsStream({
    int threshold = 10,
  }) {
    return _firestore
        .collection('products')
        .where('stock', isLessThan: threshold)
        .where('stock', isGreaterThan: 0)
        .orderBy('stock')
        .limit(5)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final stock = data['stock'] as int? ?? 0;

            String status;
            Color statusColor;
            if (stock <= 3) {
              status = 'Critical';
              statusColor = Colors.red;
            } else if (stock <= 5) {
              status = 'Low Stock';
              statusColor = Colors.red;
            } else {
              status = 'Low Stock';
              statusColor = Colors.orange;
            }

            return {
              'name': data['name'] as String? ?? 'Unknown',
              'stock': '$stock units',
              'status': status,
              'categoryId': data['categoryId'] as String?,
            };
          }).toList();
        });
  }

  /// Get sales report stream (for today)
  Stream<Map<String, dynamic>> getSalesReportStream() {
    return _firestore.collection('orders').snapshots().asyncMap((_) async {
      try {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final endOfToday = today.add(const Duration(days: 1));
        return await getSalesReport(startDate: today, endDate: endOfToday);
      } catch (e) {
        print('Error in getSalesReportStream: $e');
        return {
          'totalSales': 0.0,
          'totalOrders': 0,
          'completedOrders': 0,
          'cancelledOrders': 0,
          'averageOrderValue': 0.0,
        };
      }
    });
  }

  /// Get top products stream
  Stream<List<Map<String, dynamic>>> getTopProductsStream({int limit = 4}) {
    return _firestore.collection('orders').snapshots().asyncMap((_) async {
      try {
        return await getTopProducts(limit: limit);
      } catch (e) {
        print('Error in getTopProductsStream: $e');
        return [];
      }
    });
  }

  /// Get category performance stream
  Stream<List<Map<String, dynamic>>> getCategoryPerformanceStream() {
    return _firestore.collection('orders').snapshots().asyncMap((_) async {
      try {
        return await getCategoryPerformance();
      } catch (e) {
        print('Error in getCategoryPerformanceStream: $e');
        return [];
      }
    });
  }

  /// Get weekly revenue stream
  Stream<List<Map<String, dynamic>>> getWeeklyRevenueStream() {
    return _firestore.collection('orders').snapshots().asyncMap((_) async {
      return await getWeeklyRevenue();
    });
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      // Run queries in parallel for better performance
      final results = await Future.wait([
        // Get today's orders
        _firestore
            .collection('orders')
            .where('orderDate', isGreaterThanOrEqualTo: today.toIso8601String())
            .get(),
        // Get yesterday's orders
        _firestore
            .collection('orders')
            .where(
              'orderDate',
              isGreaterThanOrEqualTo: yesterday.toIso8601String(),
            )
            .where('orderDate', isLessThan: today.toIso8601String())
            .get(),
        // Get pending orders
        _firestore
            .collection('orders')
            .where('status', isEqualTo: OrderStatus.pending.name)
            .get(),
        // Get total customers
        _firestore
            .collection('users')
            .where('role', isEqualTo: UserRole.customer.name)
            .get(),
        // Get new customers today
        _firestore
            .collection('users')
            .where('role', isEqualTo: UserRole.customer.name)
            .where('createdAt', isGreaterThanOrEqualTo: today)
            .get(),
      ]);

      final todayOrders = results[0];
      final yesterdayOrders = results[1];
      final pendingOrders = results[2];
      final customersSnapshot = results[3];
      final newCustomersToday = results[4];

      // Calculate today's revenue (excluding cancelled orders)
      double todayRevenue = 0;
      for (var doc in todayOrders.docs) {
        final status = doc.data()['status'] as String?;
        if (status != OrderStatus.cancelled.name) {
          todayRevenue += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0;
        }
      }

      // Calculate yesterday's revenue (excluding cancelled orders)
      double yesterdayRevenue = 0;
      for (var doc in yesterdayOrders.docs) {
        final status = doc.data()['status'] as String?;
        if (status != OrderStatus.cancelled.name) {
          yesterdayRevenue +=
              (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0;
        }
      }

      return {
        'totalOrders': todayOrders.docs.length,
        'pendingOrders': pendingOrders.docs.length,
        'todayRevenue': todayRevenue,
        'revenueChange': yesterdayRevenue > 0
            ? ((todayRevenue - yesterdayRevenue) / yesterdayRevenue * 100)
            : 0,
        'totalCustomers': customersSnapshot.docs.length,
        'newCustomersToday': newCustomersToday.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  /// Get sales report for a date range
  Future<Map<String, dynamic>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final orders = await _firestore
          .collection('orders')
          .where(
            'orderDate',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where('orderDate', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      double totalSales = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      Map<String, int> productSales = {};

      for (var doc in orders.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;

        // Only add to total sales if order is not cancelled
        if (status != OrderStatus.cancelled.name) {
          totalSales += amount;
        }

        if (status == OrderStatus.delivered.name) {
          completedOrders++;
        } else if (status == OrderStatus.cancelled.name) {
          cancelledOrders++;
        }

        // Count product sales
        final items = data['items'] as List<dynamic>?;
        if (items != null) {
          for (var item in items) {
            final productId = item['productId'] as String?;
            final quantity = item['quantity'] as int? ?? 0;
            if (productId != null) {
              productSales[productId] =
                  (productSales[productId] ?? 0) + quantity;
            }
          }
        }
      }

      final averageOrderValue = orders.docs.isNotEmpty
          ? totalSales / orders.docs.length
          : 0;

      return {
        'totalSales': totalSales,
        'totalOrders': orders.docs.length,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'averageOrderValue': averageOrderValue,
        'productSales': productSales,
      };
    } catch (e) {
      throw Exception('Failed to get sales report: $e');
    }
  }

  /// Get top selling products
  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 10}) async {
    try {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));

      final orders = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: monthAgo)
          .where('status', isEqualTo: OrderStatus.delivered.name)
          .get();

      Map<String, Map<String, dynamic>> productStats = {};

      for (var doc in orders.docs) {
        final items = doc.data()['items'] as List<dynamic>?;
        if (items != null) {
          for (var item in items) {
            final productId = item['productId'] as String?;
            final productName = item['productName'] as String?;
            final quantity = item['quantity'] as int? ?? 0;
            final price = (item['price'] as num?)?.toDouble() ?? 0;

            if (productId != null) {
              if (!productStats.containsKey(productId)) {
                productStats[productId] = {
                  'productId': productId,
                  'productName': productName ?? 'Unknown',
                  'totalQuantity': 0,
                  'totalRevenue': 0.0,
                };
              }
              productStats[productId]!['totalQuantity'] += quantity;
              productStats[productId]!['totalRevenue'] += (price * quantity);
            }
          }
        }
      }

      // Sort by quantity and get top products
      final topProducts = productStats.values.toList()
        ..sort(
          (a, b) =>
              (b['totalQuantity'] as int).compareTo(a['totalQuantity'] as int),
        );

      return topProducts.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get top products: $e');
    }
  }

  /// Get weekly revenue data
  Future<List<Map<String, dynamic>>> getWeeklyRevenue() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      List<Map<String, dynamic>> dailyRevenue = [];

      for (int i = 0; i < 7; i++) {
        final date = weekAgo.add(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final orders = await _firestore
            .collection('orders')
            .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
            .where('createdAt', isLessThan: endOfDay)
            .get();

        double revenue = 0;
        for (var doc in orders.docs) {
          revenue += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0;
        }

        dailyRevenue.add({
          'day': _getDayName(date.weekday),
          'date': startOfDay,
          'revenue': revenue,
          'orderCount': orders.docs.length,
        });
      }

      return dailyRevenue;
    } catch (e) {
      throw Exception('Failed to get weekly revenue: $e');
    }
  }

  // ========== ORDER MANAGEMENT ==========

  /// Get all orders with filtering
  Stream<List<Order>> getOrders({OrderStatus? status}) {
    Query query = _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Order.fromJson(data);
      }).toList();
    });
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Get recent orders
  Future<List<Order>> getRecentOrders({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Order.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get recent orders: $e');
    }
  }

  // ========== CUSTOMER MANAGEMENT ==========

  /// Get all customers
  Stream<List<User>> getCustomers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.customer.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return User.fromJson(data);
          }).toList();
        });
  }

  /// Get customer statistics
  Future<Map<String, dynamic>> getCustomerStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final allCustomers = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.customer.name)
          .get();

      final newCustomersToday = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.customer.name)
          .where('createdAt', isGreaterThanOrEqualTo: today)
          .get();

      // Get customers with orders
      final orders = await _firestore.collection('orders').get();
      final Set<String> activeCustomers = {};

      for (var doc in orders.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null) {
          activeCustomers.add(userId);
        }
      }

      return {
        'totalCustomers': allCustomers.docs.length,
        'newToday': newCustomersToday.docs.length,
        'activeCustomers': activeCustomers.length,
      };
    } catch (e) {
      throw Exception('Failed to get customer stats: $e');
    }
  }

  // ========== CATEGORY MANAGEMENT ==========

  /// Get category performance
  Future<List<Map<String, dynamic>>> getCategoryPerformance() async {
    try {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));

      final orders = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: monthAgo)
          .where('status', isEqualTo: OrderStatus.delivered.name)
          .get();

      Map<String, Map<String, dynamic>> categoryStats = {};

      for (var doc in orders.docs) {
        final items = doc.data()['items'] as List<dynamic>?;
        if (items != null) {
          for (var item in items) {
            // Assuming items have categoryId or we need to fetch from products
            final productId = item['productId'] as String?;
            if (productId != null) {
              final product = await _firestore
                  .collection('products')
                  .doc(productId)
                  .get();

              if (product.exists) {
                final categoryId = product.data()?['categoryId'] as String?;
                final categoryName = product.data()?['categoryName'] as String?;
                final quantity = item['quantity'] as int? ?? 0;
                final price = (item['price'] as num?)?.toDouble() ?? 0;

                if (categoryId != null) {
                  if (!categoryStats.containsKey(categoryId)) {
                    categoryStats[categoryId] = {
                      'categoryId': categoryId,
                      'categoryName': categoryName ?? 'Unknown',
                      'totalOrders': 0,
                      'totalRevenue': 0.0,
                    };
                  }
                  categoryStats[categoryId]!['totalOrders'] += quantity;
                  categoryStats[categoryId]!['totalRevenue'] +=
                      (price * quantity);
                }
              }
            }
          }
        }
      }

      return categoryStats.values.toList()..sort(
        (a, b) => (b['totalRevenue'] as double).compareTo(
          a['totalRevenue'] as double,
        ),
      );
    } catch (e) {
      throw Exception('Failed to get category performance: $e');
    }
  }

  // ========== INVENTORY ALERTS ==========

  /// Get low stock products
  Future<List<Product>> getLowStockAlerts({int threshold = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('stock', isLessThan: threshold)
          .where('stock', isGreaterThan: 0)
          .orderBy('stock')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get low stock alerts: $e');
    }
  }

  // ========== COUPON MANAGEMENT ==========

  /// Get active coupons
  Stream<List<Coupon>> getActiveCoupons() {
    final now = DateTime.now();
    return _firestore
        .collection('coupons')
        .where('isActive', isEqualTo: true)
        .where('validUntil', isGreaterThanOrEqualTo: now)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Coupon.fromJson(data);
          }).toList();
        });
  }

  /// Get coupon usage statistics
  Future<Map<String, dynamic>> getCouponStats() async {
    try {
      final coupons = await _firestore.collection('coupons').get();

      int totalCoupons = coupons.docs.length;
      int activeCoupons = 0;
      int totalUsed = 0;

      for (var doc in coupons.docs) {
        final data = doc.data();
        final isActive = data['isActive'] as bool? ?? false;
        final usedCount = data['usedCount'] as int? ?? 0;

        if (isActive) {
          activeCoupons++;
        }
        totalUsed += usedCount;
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

  // ========== BAKERY SETTINGS MANAGEMENT (REAL-TIME) ==========

  /// Get bakery settings as a real-time stream
  Stream<Bakery?> getBakerySettings(String adminId) {
    return _firestore.collection('bakeries').doc(adminId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        return null;
      }
      final data = snapshot.data()!;
      data['id'] = snapshot.id;
      return Bakery.fromJson(data);
    });
  }

  /// Update bakery information
  Future<void> updateBakeryInfo({
    required String adminId,
    required String bakeryName,
    required String address,
    required String businessHours,
  }) async {
    try {
      await _firestore.collection('bakeries').doc(adminId).update({
        'bakeryName': bakeryName,
        'address': address,
        'businessHours': businessHours,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update bakery info: $e');
    }
  }

  /// Update delivery settings
  Future<void> updateDeliverySettings({
    required String adminId,
    required String deliveryRadius,
    required String deliveryCharge,
    required String freeDeliveryAbove,
    required String estimatedDelivery,
  }) async {
    try {
      await _firestore.collection('bakeries').doc(adminId).update({
        'deliveryRadius': deliveryRadius,
        'deliveryCharge': deliveryCharge,
        'freeDeliveryAbove': freeDeliveryAbove,
        'estimatedDelivery': estimatedDelivery,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update delivery settings: $e');
    }
  }

  /// Update payment methods
  Future<void> updatePaymentMethods({
    required String adminId,
    required bool cashOnDelivery,
    required bool qrCodePayment,
    required bool upiIdPayment,
    String? upiId,
    String? qrCodeImageUrl,
  }) async {
    try {
      final data = {
        'paymentMethods': {
          'cashOnDelivery': cashOnDelivery,
          'qrCodePayment': qrCodePayment,
          'upiIdPayment': upiIdPayment,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (upiId != null) {
        data['upiId'] = upiId;
      }

      if (qrCodeImageUrl != null) {
        data['qrCodeImageUrl'] = qrCodeImageUrl;
      }

      await _firestore.collection('bakeries').doc(adminId).update(data);
    } catch (e) {
      throw Exception('Failed to update payment methods: $e');
    }
  }

  /// Update tax settings
  Future<void> updateTaxSettings({
    required String adminId,
    required String gstRate,
    required String gstin,
  }) async {
    try {
      await _firestore.collection('bakeries').doc(adminId).update({
        'gstRate': gstRate,
        'gstin': gstin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update tax settings: $e');
    }
  }

  /// Update contact information
  Future<void> updateContactInfo({
    required String adminId,
    String? contactPhone,
    String? contactEmail,
  }) async {
    try {
      await _firestore.collection('bakeries').doc(adminId).update({
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update contact info: $e');
    }
  }

  /// Toggle specific payment method
  Future<void> togglePaymentMethod({
    required String adminId,
    required String methodName,
    required bool isEnabled,
  }) async {
    try {
      await _firestore.collection('bakeries').doc(adminId).update({
        'paymentMethods.$methodName': isEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle payment method: $e');
    }
  }

  // ========== HELPER METHODS ==========

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
