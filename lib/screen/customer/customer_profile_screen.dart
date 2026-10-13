import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bakehub/constants/app_colors.dart';
import 'package:bakehub/provider/auth_provider.dart';
import 'package:bakehub/provider/cart_provider.dart';
import 'package:bakehub/services/db_services.dart';
import 'package:bakehub/services/order_service.dart';
import 'package:bakehub/models/bakery.dart';
import 'package:bakehub/widgets/custom_text_field.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final DBServices _dbServices = DBServices.instance;
  final OrderService _orderService = OrderService.instance;
  final CartProvider _cartProvider = CartProvider.instance;

  Map<String, dynamic>? _userData;
  int _orderCount = 0;
  bool _isLoading = true;
  Bakery? _bakeryInfo;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Load user data from Firestore
      final userDoc = await _dbServices.getUserData(userId);
      if (userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>?;
      }

      // Load order count
      final orders = await _orderService.getOrdersStream(userId).first;
      _orderCount = orders.length;

      // Load bakery info for contact details
      final bakerySnapshot = await FirebaseFirestore.instance
          .collection('bakeries')
          .limit(1)
          .get();
      if (bakerySnapshot.docs.isNotEmpty) {
        _bakeryInfo = Bakery.fromJson(bakerySnapshot.docs.first.data());
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header
                    _buildProfileHeader(
                      _userData?['name'] ?? user?.displayName ?? 'Guest User',
                      _userData?['email'] ?? user?.email ?? '',
                      _userData?['phoneNumber'],
                    ),

                    const SizedBox(height: 16),

                    // Stats Section
                    _buildStatsSection(),

                    const SizedBox(height: 24),

                    // Menu Items
                    _buildMenuSection(context, authProvider),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String? phone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textOnPrimary, width: 3),
            ),
            child: Icon(Icons.person, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textOnPrimary.withOpacity(0.9),
            ),
          ),

          // Phone
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone,
                  size: 14,
                  color: AppColors.textOnPrimary.withOpacity(0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textOnPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Edit Profile Button
          OutlinedButton.icon(
            onPressed: _showEditProfileDialog,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textOnPrimary,
              side: const BorderSide(color: AppColors.textOnPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Orders',
              value: '$_orderCount',
              color: AppColors.primary,
              onTap: () => context.go('/customer/orders'),
            ),
            Container(
              height: 50,
              width: 1,
              color: AppColors.textHint.withOpacity(0.3),
            ),
            AnimatedBuilder(
              animation: _cartProvider,
              builder: (context, _) {
                return _buildStatItem(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Cart Items',
                  value: '${_cartProvider.cart?.items.length ?? 0}',
                  color: AppColors.textSecondary,
                  onTap: () => context.go('/customer/cart'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Quick Actions
          _buildSectionTitle('Quick Actions'),
          _buildMenuItem(
            icon: Icons.shopping_bag_outlined,
            title: 'My Orders',
            subtitle: '$_orderCount orders',
            onTap: () => context.go('/customer/orders'),
          ),
          _buildMenuItem(
            icon: Icons.shopping_cart_outlined,
            title: 'Shopping Cart',
            subtitle: AnimatedBuilder(
              animation: _cartProvider,
              builder: (context, _) {
                final itemCount = _cartProvider.cart?.items.length ?? 0;
                return Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                );
              },
            ),
            onTap: () => context.go('/customer/cart'),
          ),
          _buildMenuItem(
            icon: Icons.cake_outlined,
            title: 'Browse Products',
            onTap: () => context.go('/customer/products'),
          ),

          const SizedBox(height: 24),

          // Account Settings
          _buildSectionTitle('Account Settings'),
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: _userData?['email'],
            onTap: _showEditProfileDialog,
          ),

          const SizedBox(height: 24),

          // Support
          _buildSectionTitle('Support & Information'),
          _buildMenuItem(
            icon: Icons.store_outlined,
            title: 'Bakery Information',
            subtitle: _bakeryInfo?.bakeryName ?? 'Loading...',
            onTap: () => _showBakeryInfoDialog(context),
          ),
          _buildMenuItem(
            icon: Icons.contact_support_outlined,
            title: 'Contact Us',
            subtitle: _bakeryInfo?.contactPhone ?? 'View details',
            onTap: () => _showContactDialog(context),
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'About BakeHub',
            onTap: () => _showAboutDialog(context),
          ),

          const SizedBox(height: 24),

          // Logout
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            iconColor: AppColors.error,
            titleColor: AppColors.error,
            onTap: () => _showLogoutDialog(context, authProvider),
          ),

          const SizedBox(height: 32),

          // App Version
          Text(
            'BakeHub v1.0.0',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    dynamic subtitle,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    Widget? subtitleWidget;
    if (subtitle != null) {
      if (subtitle is Widget) {
        subtitleWidget = subtitle;
      } else if (subtitle is String) {
        subtitleWidget = Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: AppColors.textHint),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.primary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: titleColor ?? AppColors.textPrimary,
          ),
        ),
        subtitle: subtitleWidget,
        trailing: Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    final nameController = TextEditingController(
      text: _userData?['name'] ?? '',
    );
    final phoneController = TextEditingController(
      text: _userData?['phoneNumber'] ?? '',
    );
    final formKey = GlobalKey<FormState>();

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nameController,
                    label: 'Full Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: phoneController,
                    label: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    hint: '+91 9876543210',
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final phoneRegex = RegExp(r'^\+?[\d\s-()]+$');
                        if (!phoneRegex.hasMatch(value)) {
                          return 'Please enter a valid phone number';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isSaving = true);
                        try {
                          await _dbServices.updateUser(
                            uid: userId,
                            data: {
                              'name': nameController.text.trim(),
                              'phoneNumber': phoneController.text.trim(),
                            },
                          );

                          // Update display name in Firebase Auth
                          await authProvider.user?.updateDisplayName(
                            nameController.text.trim(),
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            _loadUserData();
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBakeryInfoDialog(BuildContext context) {
    if (_bakeryInfo == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.store, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Bakery Information'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow(Icons.business, 'Name', _bakeryInfo!.bakeryName),
              const Divider(),
              _buildInfoRow(Icons.location_on, 'Address', _bakeryInfo!.address),
              const Divider(),
              _buildInfoRow(
                Icons.access_time,
                'Business Hours',
                _bakeryInfo!.businessHours,
              ),
              if (_bakeryInfo!.contactPhone != null) ...[
                const Divider(),
                _buildInfoRow(Icons.phone, 'Phone', _bakeryInfo!.contactPhone!),
              ],
              if (_bakeryInfo!.contactEmail != null) ...[
                const Divider(),
                _buildInfoRow(Icons.email, 'Email', _bakeryInfo!.contactEmail!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    if (_bakeryInfo == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.contact_support, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Contact Us'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Get in touch with us:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              if (_bakeryInfo!.contactPhone != null) ...[
                _buildContactMethodCard(
                  icon: Icons.phone,
                  title: 'Call Us',
                  value: _bakeryInfo!.contactPhone!,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
              ],
              if (_bakeryInfo!.contactEmail != null) ...[
                _buildContactMethodCard(
                  icon: Icons.email,
                  title: 'Email Us',
                  value: _bakeryInfo!.contactEmail!,
                  color: AppColors.info,
                ),
                const SizedBox(height: 12),
              ],
              _buildContactMethodCard(
                icon: Icons.location_on,
                title: 'Visit Us',
                value: _bakeryInfo!.address,
                color: AppColors.error,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethodCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await authProvider.logout(() async {
                  context.go('/login');
                });
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About BakeHub'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BakeHub',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 8),
              Text('Version 1.0.0'),
              SizedBox(height: 16),
              Text(
                'Your one-stop solution for fresh baked goods delivered to your doorstep.',
              ),
              SizedBox(height: 16),
              Text(
                '© 2024 BakeHub. All rights reserved.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
