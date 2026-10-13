import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bakehub/constants/app_colors.dart';
import 'package:bakehub/services/admin_service.dart';
import 'package:bakehub/models/order.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your bakery efficiently',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ========== TODAY'S STATS ==========
            Text(
              'Today\'s Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            StreamBuilder<Map<String, dynamic>>(
              stream: _adminService.getDashboardStatsStream(),
              builder: (context, snapshot) {
                // Handle error state
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Error loading stats: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                // Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final stats = snapshot.data ?? {};
                final totalOrders = stats['totalOrders'] ?? 0;
                final pendingOrders = stats['pendingOrders'] ?? 0;
                final todayRevenue = stats['todayRevenue'] ?? 0.0;
                final revenueChange = stats['revenueChange'] ?? 0.0;
                final totalCustomers = stats['totalCustomers'] ?? 0;
                final newCustomersToday = stats['newCustomersToday'] ?? 0;

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      icon: Icons.shopping_bag,
                      title: 'Total Orders',
                      value: '$totalOrders',
                      subtitle: 'Today',
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      icon: Icons.pending_actions,
                      title: 'Pending Orders',
                      value: '$pendingOrders',
                      subtitle: 'Need attention',
                      color: Colors.orange,
                    ),
                    _buildStatCard(
                      icon: Icons.currency_rupee,
                      title: 'Today\'s Revenue',
                      value: '₹${todayRevenue.toStringAsFixed(0)}',
                      subtitle: revenueChange >= 0
                          ? '+${revenueChange.toStringAsFixed(1)}% from yesterday'
                          : '${revenueChange.toStringAsFixed(1)}% from yesterday',
                      color: Colors.green,
                    ),
                    _buildStatCard(
                      icon: Icons.people,
                      title: 'Total Customers',
                      value: '$totalCustomers',
                      subtitle: '+$newCustomersToday new today',
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // ========== SALES REPORT ==========
            _buildSectionHeader(context, 'Sales Report'),
            const SizedBox(height: 12),
            StreamBuilder<Map<String, dynamic>>(
              stream: _adminService.getSalesReportStream(),
              builder: (context, snapshot) {
                // Handle error or loading state
                if (snapshot.hasError ||
                    snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: snapshot.hasError
                          ? Text('Error: ${snapshot.error}')
                          : const CircularProgressIndicator(),
                    ),
                  );
                }

                final report = snapshot.data ?? {};
                final totalSales =
                    (report['totalSales'] as num?)?.toDouble() ?? 0.0;
                final avgOrderValue =
                    (report['averageOrderValue'] as num?)?.toDouble() ?? 0.0;
                final completedOrders = report['completedOrders'] as int? ?? 0;
                final cancelledOrders = report['cancelledOrders'] as int? ?? 0;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReportRow(
                        label: 'Total Sales',
                        value: '₹${totalSales.toStringAsFixed(0)}',
                        change: '+15%',
                        changeColor: Colors.green,
                      ),
                      const Divider(),
                      _buildReportRow(
                        label: 'Average Order Value',
                        value: '₹${avgOrderValue.toStringAsFixed(0)}',
                        change: '+5%',
                        changeColor: Colors.green,
                      ),
                      const Divider(),
                      _buildReportRow(
                        label: 'Orders Completed',
                        value: '$completedOrders',
                        change: '+12%',
                        changeColor: Colors.green,
                      ),
                      const Divider(),
                      _buildReportRow(
                        label: 'Cancelled Orders',
                        value: '$cancelledOrders',
                        change: '-2%',
                        changeColor: Colors.blue,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ========== RECENT ORDERS ==========
            _buildSectionHeader(
              context,
              'Recent Orders',
              onViewAll: () => context.go('/admin/orders'),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _adminService.getRecentOrdersStream(limit: 4),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final orders = snapshot.data!;

                if (orders.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'No orders yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: orders.asMap().entries.map((entry) {
                      final index = entry.key;
                      final order = entry.value;

                      final orderId =
                          '#${order['orderId'].toString().substring(0, 8)}';
                      final customerName = order['customerName'] as String;
                      final items = order['items'] as int;
                      final status = order['status'] as String;
                      final amount = (order['totalAmount'] as num).toDouble();

                      Color statusColor;
                      String statusText;
                      switch (status) {
                        case 'pending':
                          statusColor = Colors.orange;
                          statusText = 'Pending';
                          break;
                        case 'preparing':
                          statusColor = Colors.blue;
                          statusText = 'Preparing';
                          break;
                        case 'ready':
                          statusColor = Colors.teal;
                          statusText = 'Ready';
                          break;
                        case 'outForDelivery':
                          statusColor = Colors.purple;
                          statusText = 'Out for Delivery';
                          break;
                        case 'delivered':
                          statusColor = Colors.green;
                          statusText = 'Delivered';
                          break;
                        default:
                          statusColor = Colors.grey;
                          statusText = status;
                      }

                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 0),
                          _buildOrderItem(
                            orderId: orderId,
                            customer: customerName,
                            items: '$items items',
                            status: statusText,
                            statusColor: statusColor,
                            amount: '₹${amount.toStringAsFixed(2)}',
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ========== COUPON USAGE ==========
            _buildSectionHeader(
              context,
              'Active Coupons',
              onViewAll: () => context.go('/admin/coupons'),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _adminService.getActiveCouponsStream(limit: 3),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final coupons = snapshot.data!;

                if (coupons.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'No active coupons',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: coupons.asMap().entries.map((entry) {
                      final index = entry.key;
                      final coupon = entry.value;
                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 0),
                          _buildCouponRow(
                            code: coupon['code'] as String,
                            discount: coupon['discount'] as String,
                            used: coupon['used'] as String,
                            status: coupon['status'] as String,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ========== ORDER STATUS BREAKDOWN ==========
            _buildSectionHeader(
              context,
              'Order Status Overview',
              onViewAll: () => context.go('/admin/orders'),
            ),
            const SizedBox(height: 12),
            StreamBuilder<Map<OrderStatus, int>>(
              stream: _adminService.getOrderStatusBreakdownStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    height: 200,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final breakdown = snapshot.data!;

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.15,
                  children: [
                    _buildOrderStatusCard(
                      status: 'Pending',
                      count: '${breakdown[OrderStatus.pending] ?? 0}',
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                    _buildOrderStatusCard(
                      status: 'Preparing',
                      count: '${breakdown[OrderStatus.preparing] ?? 0}',
                      icon: Icons.restaurant,
                      color: Colors.blue,
                    ),
                    _buildOrderStatusCard(
                      status: 'Ready',
                      count: '${breakdown[OrderStatus.ready] ?? 0}',
                      icon: Icons.check_circle,
                      color: Colors.teal,
                    ),
                    _buildOrderStatusCard(
                      status: 'Out for Delivery',
                      count: '${breakdown[OrderStatus.outForDelivery] ?? 0}',
                      icon: Icons.delivery_dining,
                      color: Colors.purple,
                    ),
                    _buildOrderStatusCard(
                      status: 'Delivered',
                      count: '${breakdown[OrderStatus.delivered] ?? 0}',
                      icon: Icons.done_all,
                      color: Colors.green,
                    ),
                    _buildOrderStatusCard(
                      status: 'Cancelled',
                      count: '${breakdown[OrderStatus.cancelled] ?? 0}',
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ========== WIDGETS ==========

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              'View All',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow({
    required String label,
    required String value,
    required String change,
    required Color changeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem({
    required String orderId,
    required String customer,
    required String items,
    required String status,
    required Color statusColor,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      orderId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$customer • $items',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponRow({
    required String code,
    required String discount,
    required String used,
    required String status,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  discount,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                used,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard({
    required String status,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          // Value
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
