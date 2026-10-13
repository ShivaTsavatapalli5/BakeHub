import 'package:flutter/material.dart';
import 'package:bakehub/constants/app_colors.dart';
import 'package:bakehub/models/order.dart';
import 'package:bakehub/services/order_service.dart';
import 'package:bakehub/services/realtime_ready_service.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Orders Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.textOnPrimary,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.6),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Preparing'),
            Tab(text: 'Ready'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: StreamBuilder<List<Order>>(
        stream: _orderService.getAllOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading orders',
                    style: TextStyle(fontSize: 18, color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ],
              ),
            );
          }

          final allOrders = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(allOrders),
              _buildOrdersList(
                allOrders
                    .where((o) => o.status == OrderStatus.pending)
                    .toList(),
              ),
              _buildOrdersList(
                allOrders
                    .where((o) => o.status == OrderStatus.confirmed)
                    .toList(),
              ),
              _buildOrdersList(
                allOrders
                    .where((o) => o.status == OrderStatus.preparing)
                    .toList(),
              ),
              _buildOrdersList(
                allOrders.where((o) => o.status == OrderStatus.ready).toList(),
              ),
              _buildOrdersList(
                allOrders
                    .where((o) => o.status == OrderStatus.delivered)
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders will appear here',
              style: TextStyle(fontSize: 14, color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order.orderDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: AppColors.textHint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: AppColors.textHint),
                const SizedBox(width: 8),
                Text(
                  order.deliveryAddress.phone,
                  style: TextStyle(fontSize: 14, color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.shopping_bag, size: 16, color: AppColors.textHint),
                const SizedBox(width: 8),
                Text(
                  '${order.totalItems} items',
                  style: TextStyle(fontSize: 14, color: AppColors.textHint),
                ),
                const SizedBox(width: 16),
                Icon(Icons.payments, size: 16, color: AppColors.textHint),
                const SizedBox(width: 8),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showOrderDetails(order),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showStatusDialog(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    child: const Text('Update Status'),
                  ),
                ),
              ],
            ),
            // 🚁 OWNER TAKEOFF BUTTON
            if (order.status == OrderStatus.ready)
              const SizedBox(height: 12),

            if (order.status == OrderStatus.ready)
              StreamBuilder(
                stream: FirebaseDatabase.instance
                    .ref("delivery_requests/${order.id}")
                    .onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const SizedBox();
                  }


                  final data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );

                  bool canTakeoff =
                      data["takeoff_permission"] == "Activate" &&
                          data["takeoff_triggered"] == false &&
                          data["drone_status"] == "idle";

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canTakeoff
                          ? () async {
                        await FirebaseDatabase.instance
                            .ref("delivery_requests/${order.id}")
                            .update({
                          "takeoff_triggered": true,
                          "takeoff_by": "owner",

                        });
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white, ),
                      child: const Text("TAKEOFF DRONE"),
                    ),
                  );
                },
              ),
            // 🔥 OWNER LAND BUTTON
            if (order.status == OrderStatus.outForDelivery)
              const SizedBox(height: 12),

            if (order.status == OrderStatus.outForDelivery)
              StreamBuilder(
                stream: FirebaseDatabase.instance
                    .ref("delivery_requests/${order.id}")
                    .onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const SizedBox();
                  }

                  final data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );
                  bool canLand =
                      data["landing_permission"] == "Activate" &&
                          data["landing_triggered"] == false &&
                          data["drone_status"] == "hovering";

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canLand
                          ? () async {
                        await FirebaseDatabase.instance
                            .ref("delivery_requests/${order.id}")
                            .update({
                          "landing_triggered": true,
                          "landing_by": "owner",

                        });
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,),
                      child: const Text("LAND DRONE"),
                    ),
                  );
                },
              ),

            // 🏠 OWNER RETURN TO HOME BUTTON
            if (order.status == OrderStatus.outForDelivery)
              const SizedBox(height: 12),

            if (order.status == OrderStatus.outForDelivery)
              StreamBuilder(
                stream: FirebaseDatabase.instance
                    .ref("delivery_requests/${order.id}")
                    .onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const SizedBox();
                  }

                  final data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );
                  bool canReturn =
                      data["return_permission"] == "Activate" &&
                          data["return_triggered"] == false &&
                          data["drone_status"] == "landed";

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canReturn
                          ? () async {
                        await FirebaseDatabase.instance
                            .ref("delivery_requests/${order.id}")
                            .update({
                          "return_triggered": true,
                          "return_by": "owner",

                        });
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("RETURN TO HOME"),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = AppColors.warning.withOpacity(0.2);
        textColor = AppColors.warning;
        statusText = 'Pending';
        break;
      case OrderStatus.confirmed:
        backgroundColor = AppColors.info.withOpacity(0.2);
        textColor = AppColors.info;
        statusText = 'Confirmed';
        break;
      case OrderStatus.preparing:
        backgroundColor = AppColors.info.withOpacity(0.2);
        textColor = AppColors.info;
        statusText = 'Preparing';
        break;
      case OrderStatus.ready:
        backgroundColor = AppColors.success.withOpacity(0.2);
        textColor = AppColors.success;
        statusText = 'Ready';
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = AppColors.warning.withOpacity(0.2);
        textColor = AppColors.warning;
        statusText = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        backgroundColor = AppColors.success.withOpacity(0.2);
        textColor = AppColors.success;
        statusText = 'Delivered';
        break;
      case OrderStatus.cancelled:
        backgroundColor = AppColors.error.withOpacity(0.2);
        textColor = AppColors.error;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusChip(order.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildDetailRow(
                          'Order ID',
                          '#${order.id.substring(0, 8).toUpperCase()}',
                        ),
                        _buildDetailRow('Date', _formatDate(order.orderDate)),
                        _buildDetailRow(
                          'Payment Method',
                          _getPaymentMethodText(order.paymentMethod),
                        ),

                        if (order.paymentScreenshot != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Payment Screenshot',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              order.paymentScreenshot!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Failed to load image'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        if (order.utrNumber != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'UTR / Transaction ID',
                            order.utrNumber!,
                          ),
                        ],
                        if (order.couponCode != null &&
                            order.discountAmount != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.success.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_offer,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Coupon Applied',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        order.couponCode!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '-₹${order.discountAmount!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text(
                          'Customer Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.deliveryAddress.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(order.deliveryAddress.phone),
                        Text(order.deliveryAddress.fullAddress),
                        if (order.deliveryAddress.latitude != null &&
                            order.deliveryAddress.longitude != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Location: ${order.deliveryAddress.latitude!.toStringAsFixed(6)}, ${order.deliveryAddress.longitude!.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text(
                          'Order Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map((item) => _buildOrderItem(item)),
                        const SizedBox(height: 16),
                        _buildPriceSummary(order),
                        if (order.notes != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Notes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(order.notes!),
                        ],
                        if (order.cancellationReason != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                size: 18,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Cancellation Reason',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              order.cancellationReason!,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.error.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStatusDialog(Order order) {
    // Determine next status
    OrderStatus? nextStatus;
    String nextStatusText = '';

    switch (order.status) {
      case OrderStatus.pending:
        nextStatus = OrderStatus.confirmed;
        nextStatusText = 'Confirmed';
        break;
      case OrderStatus.confirmed:
        nextStatus = OrderStatus.preparing;
        nextStatusText = 'Preparing';
        break;
      case OrderStatus.preparing:
        nextStatus = OrderStatus.ready;
        nextStatusText = 'Ready';
        break;
      case OrderStatus.ready:
        nextStatus = OrderStatus.outForDelivery;
        nextStatusText = 'Out for Delivery';
        break;
      case OrderStatus.outForDelivery:
        nextStatus = OrderStatus.delivered;
        nextStatusText = 'Delivered';
        break;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        nextStatus = null;
        break;
    }

    if (nextStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order is already ${order.status == OrderStatus.delivered ? "delivered" : "cancelled"}',
          ),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return _StatusUpdateDialog(
          order: order,
          nextStatus: nextStatus!,
          nextStatusText: nextStatusText,
          onStatusUpdated: (success, message) {
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: success
                      ? AppColors.success
                      : AppColors.error,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(label, style: TextStyle(color: AppColors.textHint)),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (item.productImage != null)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.secondary,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.productImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.cake, color: AppColors.primary);
                  },
                ),
              ),
            ),
          if (item.productImage != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(Order order) {
    final hasDiscount =
        order.discountAmount != null && order.discountAmount! > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', order.subtotal),
          const SizedBox(height: 8),
          _buildPriceRow('Tax', order.tax),
          const SizedBox(height: 8),
          _buildPriceRow('Delivery', order.deliveryCharge),
          if (hasDiscount) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Discount'),
                    if (order.couponCode != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          order.couponCode!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '- ₹${order.discountAmount!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text('₹${amount.toStringAsFixed(2)}')],
    );
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.creditCard:
        return 'QR Code / Online Payment';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.upi:
        return 'UPI';
    }
  }
}

// Status Update Dialog Widget
class _StatusUpdateDialog extends StatefulWidget {
  final Order order;
  final OrderStatus nextStatus;
  final String nextStatusText;
  final Function(bool success, String message) onStatusUpdated;

  const _StatusUpdateDialog({
    required this.order,
    required this.nextStatus,
    required this.nextStatusText,
    required this.onStatusUpdated,
  });

  @override
  State<_StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<_StatusUpdateDialog> {
  bool _paymentVerified = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isConfirmingOrder = widget.nextStatus == OrderStatus.confirmed;

    return AlertDialog(
      title: const Text('Update Order Status', style: TextStyle(fontSize: 18)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order: #${widget.order.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Status',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      _buildSmallStatusChip(widget.order.status),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Next Status',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      _buildSmallStatusChip(widget.nextStatus),
                    ],
                  ),
                ),
              ],
            ),

            // Show payment details if confirming order
            if (isConfirmingOrder) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Payment Verification',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Payment Method
              Row(
                children: [
                  const Icon(Icons.payment, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _getPaymentMethodText(widget.order.paymentMethod),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),

              // Payment Screenshot with View Button
              if (widget.order.paymentScreenshot != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showFullScreenImage(context),
                        icon: const Icon(
                          Icons.image,
                          size: 18,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'View Payment Image',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // UTR Number (compact)
              if (widget.order.utrNumber != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'UTR: ${widget.order.utrNumber!}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // Payment Verification Checkbox (compact)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: CheckboxListTile(
                  value: _paymentVerified,
                  onChanged: (value) {
                    setState(() {
                      _paymentVerified = value ?? false;
                    });
                  },
                  title: const Text(
                    'Payment Received',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  dense: true,
                  activeColor: AppColors.success,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                ),
              ),
            ],
            SizedBox(height: 12),
          ],
        ),
      ),
      actions: [
        // Cancel Order Button
        if (widget.order.status == OrderStatus.pending ||
            widget.order.status == OrderStatus.confirmed ||
            widget.order.status == OrderStatus.preparing)
          TextButton(
            onPressed: _isProcessing ? null : () => _handleCancelOrder(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Order'),
          ),

        // Close Button
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),

        // Update Status Button
        ElevatedButton(
          onPressed: _isProcessing
              ? null
              : (isConfirmingOrder && !_paymentVerified)
              ? null
              : () => _handleUpdateStatus(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            disabledBackgroundColor: AppColors.textHint,
          ),
          child: _isProcessing
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text('Update Status'),
        ),
      ],
    );
  }

  Widget _buildSmallStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = AppColors.warning.withOpacity(0.2);
        textColor = AppColors.warning;
        statusText = 'Pending';
        break;
      case OrderStatus.confirmed:
        backgroundColor = AppColors.info.withOpacity(0.2);
        textColor = AppColors.info;
        statusText = 'Confirmed';
        break;
      case OrderStatus.preparing:
        backgroundColor = AppColors.info.withOpacity(0.2);
        textColor = AppColors.info;
        statusText = 'Preparing';
        break;
      case OrderStatus.ready:
        backgroundColor = AppColors.success.withOpacity(0.2);
        textColor = AppColors.success;
        statusText = 'Ready';
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = AppColors.warning.withOpacity(0.2);
        textColor = AppColors.warning;
        statusText = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        backgroundColor = AppColors.success.withOpacity(0.2);
        textColor = AppColors.success;
        statusText = 'Delivered';
        break;
      case OrderStatus.cancelled:
        backgroundColor = AppColors.error.withOpacity(0.2);
        textColor = AppColors.error;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.creditCard:
        return 'QR Code / Online Payment';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.upi:
        return 'UPI';
    }
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: const Text('Payment Screenshot'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  // Full screen image
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        widget.order.paymentScreenshot!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 60,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // UTR Overlay at bottom
                  if (widget.order.utrNumber != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'UTR / Transaction ID',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.order.utrNumber!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'monospace',
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _handleCancelOrder(BuildContext context) async {
    // Use a ValueNotifier so we can read the text after dialog closes
    // without disposing the controller prematurely (which causes
    // "used after dispose" errors during the dialog exit animation).
    String? capturedReason;

    // Show dialog with reason input
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          _CancelReasonDialog(
            message:
            'Are you sure you want to cancel this order? This action cannot be undone.',
            hint: 'e.g. Item unavailable, Customer request...',
            onConfirm: (reason) {
              capturedReason = reason;
              Navigator.pop(ctx, true);
            },
            onCancel: () => Navigator.pop(ctx, false),
          ),
    );

    if (confirmed != true) return;

    final reason = capturedReason?.trim();

    setState(() => _isProcessing = true);

    try {
      final success = await OrderService.instance.cancelOrder(
        widget.order.id,
        reason: (reason != null && reason.isNotEmpty) ? reason : null,
      );

      widget.onStatusUpdated(
        success,
        success ? 'Order cancelled successfully' : 'Failed to cancel order',
      );
    } catch (e) {
      widget.onStatusUpdated(false, 'Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }



  Future<void> _handleUpdateStatus(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      final success = await OrderService.instance.updateOrderStatus(
        widget.order.id,
        widget.nextStatus,
      );

      // 🔥 Upload to Realtime DB only when READY
      if (success && widget.nextStatus == OrderStatus.ready) {
        await FirebaseDatabase.instance
            .ref("delivery_requests/${widget.order.id}")
            .set({
          "locationName": widget.order.deliveryAddress.fullAddress,
          "orderId": widget.order.id,
          "phone": widget.order.deliveryAddress.phone,

          // 🚁 Drone state
          "drone_status": "idle",

          // 🛫 TAKEOFF CONTROL
          "takeoff_permission": "waiting",
          "takeoff_triggered": false,
          "takeoff_by": "none",

          // 🛬 LAND CONTROL
          "landing_permission": "waiting",
          "landing_triggered": false,
          "landing_by": "none",

          // 🏠 RETURN TO HOME CONTROL
          "return_permission": "waiting",
          "return_triggered": false,
          "return_by": "none",

        });
      }

      widget.onStatusUpdated(
        success,
        success
            ? 'Order status updated to ${widget.nextStatusText}'
            : 'Failed to update status',
      );
    } catch (e) {
      widget.onStatusUpdated(false, 'Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
/// Reusable cancel-reason dialog that manages its own [TextEditingController]
/// lifecycle, preventing "controller used after dispose" errors.
class _CancelReasonDialog extends StatefulWidget {
  final String message;
  final String hint;
  final void Function(String reason) onConfirm;
  final VoidCallback onCancel;

  const _CancelReasonDialog({
    required this.message,
    required this.hint,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
          const SizedBox(width: 8),
          const Text('Cancel Order', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          const Text(
            'Reason for cancellation (optional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('No')),
        ElevatedButton(
          onPressed: () => widget.onConfirm(_reasonController.text),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text(
            'Yes, Cancel',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
