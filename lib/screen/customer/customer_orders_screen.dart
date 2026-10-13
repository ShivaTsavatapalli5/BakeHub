// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:bakehub/constants/app_colors.dart';
import 'package:bakehub/models/order.dart';
import 'package:bakehub/services/order_service.dart';
import 'package:bakehub/provider/auth_provider.dart';
import 'package:firebase_database/firebase_database.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService.instance;
  final AuthProvider _authProvider = AuthProvider.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authProvider.user?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          title: const Text('My Orders'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: AppColors.textHint),
              const SizedBox(height: 16),
              const Text(
                'Please login to view orders',
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textOnPrimary,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.6),
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Preparing'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: StreamBuilder<List<Order>>(
        stream: _orderService.getOrdersStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading orders: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
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
                    .where(
                      (o) =>
                          o.status == OrderStatus.preparing ||
                          o.status == OrderStatus.confirmed ||
                          o.status == OrderStatus.outForDelivery,
                    )
                    .toList(),
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
            Icon(
              Icons.receipt_long_outlined,
              size: 100,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your orders will appear here',
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
        borderRadius: BorderRadius.circular(16),
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
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 12),

            // Order Details
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textHint),
                const SizedBox(width: 8),
                Text(
                  _formatDate(order.orderDate),
                  style: TextStyle(fontSize: 14, color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.shopping_bag, size: 16, color: AppColors.textHint),
                const SizedBox(width: 8),
                Text(
                  '${order.totalItems} items',
                  style: TextStyle(fontSize: 14, color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const Divider(),
            const SizedBox(height: 12),

            // Total and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        _showOrderDetails(order);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Details'),
                    ),
                    if (order.canBeCancelled) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _showCancelDialog(order);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textOnPrimary),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
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

  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case OrderStatus.delivered:
        backgroundColor = AppColors.success.withOpacity(0.2);
        textColor = AppColors.success;
        statusText = 'Delivered';
        break;
      case OrderStatus.preparing:
        backgroundColor = AppColors.info.withOpacity(0.2);
        textColor = AppColors.info;
        statusText = 'Preparing';
        break;
      case OrderStatus.confirmed:
        backgroundColor = AppColors.info.withOpacity(0.2);
        textColor = AppColors.info;
        statusText = 'Confirmed';
        break;
      case OrderStatus.ready:
        backgroundColor = AppColors.info.withOpacity(0.2);
        textColor = AppColors.info;
        statusText = 'Ready';
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = AppColors.warning.withOpacity(0.2);
        textColor = AppColors.warning;
        statusText = 'Out for Delivery';
        break;
      case OrderStatus.pending:
        backgroundColor = AppColors.secondary;
        textColor = AppColors.textPrimary;
        statusText = 'Pending';
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

  /*void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
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
                        _buildDetailRow(
                          'Order Date',
                          _formatDate(order.orderDate),
                        ),
                        _buildDetailRow(
                          'Payment Method',
                          _getPaymentMethodText(order.paymentMethod),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Delivery Address',
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
                        const SizedBox(height: 16),
                        const Text(
                          'Items',
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: AppColors.textOnPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }*/
  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
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
                        _buildDetailRow(
                          'Order Date',
                          _formatDate(order.orderDate),
                        ),
                        _buildDetailRow(
                          'Payment Method',
                          _getPaymentMethodText(order.paymentMethod),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.deliveryAddress.name,
                          style:
                          const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(order.deliveryAddress.phone),
                        Text(order.deliveryAddress.fullAddress),

                        const SizedBox(height: 16),
                        const Text(
                          'Items',
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
                                color:
                                AppColors.error.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),


                  /// 🔥 DRONE CONTROL BUTTONS
                  if (order.status == OrderStatus.outForDelivery) ...[
                    const SizedBox(height: 12),

                    StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance
                          .ref("delivery_requests/${order.id}")
                          .onValue,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                          return const SizedBox();
                        }

                        final data = Map<String, dynamic>.from(
                          snapshot.data!.snapshot.value as Map,
                        );
                        bool canLand =
                            data["landing_permission"] == "Activate" &&
                                data["landing_triggered"] == false &&
                                data["drone_status"] == "hovering";

                        bool canReturn =
                            data["return_permission"] == "Activate" &&
                                data["return_triggered"] == false &&
                                data["drone_status"] == "landed";

                        return Column(
                          children: [

                            /// LAND BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: canLand
                                    ? () async {
                                  await FirebaseDatabase.instance
                                      .ref("delivery_requests/${order.id}")
                                      .update({

                                    "landing_triggered": true,
                                    "landing_by": "customer",

                                  });
                                }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  "LAND DRONE",
                                  style: TextStyle(color: AppColors.textOnPrimary),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            /// RETURN HOME BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: canReturn
                                    ? () async {
                                  await FirebaseDatabase.instance
                                      .ref("delivery_requests/${order.id}")
                                      .update({
                                    "return_triggered": true,
                                    "return_by": "customer",

                                  });
                                }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text("RETURN TO HOME"),
                                ),
                              ),

                          ],
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 16),


                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        AppColors.primary,
                        padding:
                        const EdgeInsets.symmetric(
                            vertical: 16),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                            color:
                            AppColors.textOnPrimary),
                      ),
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

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.upi:
        return 'UPI';
    }
  }

  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
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
          _buildPriceRow('Delivery Charge', order.deliveryCharge),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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

  void _showCancelDialog(Order order) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _CancelReasonDialog(
          message:
              'Are you sure you want to cancel order\n#${order.id.substring(0, 8).toUpperCase()}?',
          hint: 'e.g. Changed my mind, Wrong item ordered...',
          onConfirm: (reason) async {
            Navigator.pop(dialogContext);
            final success = await _orderService.cancelOrder(
              order.id,
              reason: (reason.isNotEmpty) ? reason : null,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Order cancelled successfully'
                        : 'Failed to cancel order',
                  ),
                  backgroundColor: success
                      ? AppColors.success
                      : AppColors.error,
                ),
              );
            }
          },
          onCancel: () => Navigator.pop(dialogContext),
        );
      },
    );
  }
}

/// Manages its own [TextEditingController] lifecycle so the controller
/// is never disposed while the dialog widget tree is still alive.
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
                borderSide: BorderSide(color: AppColors.textHint),
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
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('No, Keep It'),
        ),
        ElevatedButton(
          onPressed: () => widget.onConfirm(_reasonController.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Yes, Cancel',
            style: TextStyle(color: AppColors.textOnPrimary),
          ),
        ),
      ],
    );
  }
}
