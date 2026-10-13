import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bakehub/constants/app_colors.dart';
import 'package:bakehub/models/bakery.dart';
import 'package:bakehub/services/admin_service.dart';
import 'package:bakehub/services/cloudinary_service.dart';
import 'package:bakehub/widgets/custom_text_field.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AdminService _adminService = AdminService();
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<auth.User?>(
      stream: _firebaseAuth.authStateChanges(),
      builder: (context, authSnapshot) {
        // Loading state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Settings'),
              centerTitle: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Settings'),
              centerTitle: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Please login to view settings',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Go to Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final adminId = authSnapshot.data!.uid;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            centerTitle: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: StreamBuilder<Bakery?>(
            stream: _adminService.getBakerySettings(adminId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('No bakery settings found'));
              }

              final bakery = snapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bakery Information
                    _buildSectionHeader(context, 'Bakery Information'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        _buildSettingRow('Bakery Name', bakery.bakeryName),
                        const Divider(),
                        _buildSettingRow('Address', bakery.address),
                        const Divider(),
                        _buildSettingRow(
                          'Business Hours',
                          bakery.businessHours,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _showEditBakeryInfoDialog(bakery, adminId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Edit Bakery Info',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Contact Information
                    _buildSectionHeader(context, 'Contact Information'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        _buildSettingRow(
                          'Phone',
                          bakery.contactPhone ?? 'Not set',
                        ),
                        const Divider(),
                        _buildSettingRow(
                          'Email',
                          bakery.contactEmail ?? 'Not set',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _showEditContactInfoDialog(bakery, adminId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Edit Contact Info',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Delivery Settings
                    _buildSectionHeader(context, 'Delivery Settings'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        _buildSettingRow(
                          'Delivery Radius',
                          '${bakery.deliveryRadius} km',
                        ),
                        const Divider(),
                        _buildSettingRow(
                          'Delivery Charge',
                          '₹${bakery.deliveryCharge}',
                        ),
                        const Divider(),
                        _buildSettingRow(
                          'Free Above',
                          '₹${bakery.freeDeliveryAbove}',
                        ),
                        const Divider(),
                        _buildSettingRow(
                          'Est. Delivery',
                          bakery.estimatedDelivery,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showEditDeliverySettingsDialog(
                                bakery,
                                adminId,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Edit Delivery Settings',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Payment Settings
                    _buildSectionHeader(context, 'Payment Settings'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        _buildPaymentMethod(
                          'Cash on Delivery',
                          bakery.paymentMethods.cashOnDelivery,
                          () => _togglePaymentMethod(
                            adminId,
                            'cashOnDelivery',
                            !bakery.paymentMethods.cashOnDelivery,
                          ),
                        ),
                        const Divider(),
                        _buildPaymentMethod(
                          'QR Code Payment',
                          bakery.paymentMethods.qrCodePayment,
                          () => _togglePaymentMethod(
                            adminId,
                            'qrCodePayment',
                            !bakery.paymentMethods.qrCodePayment,
                          ),
                        ),
                        const Divider(),
                        _buildPaymentMethod(
                          'UPI Payment',
                          bakery.paymentMethods.upiIdPayment,
                          () => _togglePaymentMethod(
                            adminId,
                            'upiIdPayment',
                            !bakery.paymentMethods.upiIdPayment,
                          ),
                        ),
                        if (bakery.upiId != null &&
                            bakery.upiId!.isNotEmpty) ...[
                          const Divider(),
                          _buildSettingRow('UPI ID', bakery.upiId ?? 'N/A'),
                        ],
                        if (bakery.qrCodeImageUrl != null &&
                            bakery.qrCodeImageUrl!.isNotEmpty) ...[
                          const Divider(),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment QR Code',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () =>
                                    _showQrCodeDialog(bakery.qrCodeImageUrl!),
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      bakery.qrCodeImageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.error_outline,
                                                color: Colors.red,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to view full size',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showEditPaymentSettingsDialog(
                                bakery,
                                adminId,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Edit Payment Settings',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Category Management
                    _buildSectionHeader(context, 'Category Management'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Manage product categories for your bakery',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/admin/categories'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            icon: const Icon(
                              Icons.category,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Manage Categories',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Coupon Management
                    _buildSectionHeader(context, 'Coupon Management'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Create and manage discount coupons for your customers',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/admin/coupons'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            icon: const Icon(
                              Icons.local_offer,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Manage Coupons',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Delivery Locations
                    _buildSectionHeader(context, 'Delivery Locations'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Manage predefined delivery locations for customers',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/admin/locations'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            icon: const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Manage Delivery Locations',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tax Settings
                    _buildSectionHeader(context, 'Tax Configuration'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        _buildSettingRow('GST Rate', '${bakery.gstRate}%'),
                        const Divider(),
                        _buildSettingRow('GSTIN', bakery.gstin),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _showEditTaxSettingsDialog(bakery, adminId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Edit Tax Settings',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Last Updated Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Last updated: ${_formatDateTime(bakery.updatedAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(
    String name,
    bool isEnabled,
    VoidCallback onToggle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 14)),
          Switch(
            value: isEnabled,
            onChanged: (_) => onToggle(),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseAuth.signOut();
        if (mounted) {
          context.go('/');
        }
      } catch (e) {
        if (mounted) {
          // Snackbar removed
        }
      }
    }
  }

  Future<void> _togglePaymentMethod(
    String adminId,
    String methodName,
    bool isEnabled,
  ) async {
    try {
      await _adminService.togglePaymentMethod(
        adminId: adminId,
        methodName: methodName,
        isEnabled: isEnabled,
      );

      if (mounted) {
        // Snackbar removed
      }
    } catch (e) {
      if (mounted) {
        // Snackbar removed
      }
    }
  }

  void _showEditBakeryInfoDialog(Bakery bakery, String adminId) {
    final nameController = TextEditingController(text: bakery.bakeryName);
    final addressController = TextEditingController(text: bakery.address);
    final hoursController = TextEditingController(text: bakery.businessHours);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bakery Information'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Bakery Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter bakery name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: addressController,
                  label: 'Address',
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: hoursController,
                  label: 'Business Hours',
                  hint: 'e.g., 8 AM - 10 PM',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter business hours';
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _adminService.updateBakeryInfo(
                    adminId: adminId,
                    bakeryName: nameController.text.trim(),
                    address: addressController.text.trim(),
                    businessHours: hoursController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    // Snackbar removed
                  }
                } catch (e) {
                  if (context.mounted) {
                    // Snackbar removed
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditContactInfoDialog(Bakery bakery, String adminId) {
    final phoneController = TextEditingController(text: bakery.contactPhone);
    final emailController = TextEditingController(text: bakery.contactEmail);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact Information'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: phoneController,
                  label: 'Contact Phone',
                  hint: 'e.g., +91 9876543210',
                  keyboardType: TextInputType.phone,
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
                const SizedBox(height: 16),
                CustomTextField(
                  controller: emailController,
                  label: 'Contact Email',
                  hint: 'e.g., bakery@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _adminService.updateContactInfo(
                    adminId: adminId,
                    contactPhone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    contactEmail: emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    // Snackbar removed
                  }
                } catch (e) {
                  if (context.mounted) {
                    // Snackbar removed
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDeliverySettingsDialog(Bakery bakery, String adminId) {
    final radiusController = TextEditingController(text: bakery.deliveryRadius);
    final chargeController = TextEditingController(text: bakery.deliveryCharge);
    final freeAboveController = TextEditingController(
      text: bakery.freeDeliveryAbove,
    );
    final estimatedController = TextEditingController(
      text: bakery.estimatedDelivery,
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Delivery Settings'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: radiusController,
                  label: 'Delivery Radius (km)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter delivery radius';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: chargeController,
                  label: 'Delivery Charge (₹)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter delivery charge';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: freeAboveController,
                  label: 'Free Delivery Above (₹)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter free delivery threshold';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: estimatedController,
                  label: 'Estimated Delivery Time',
                  hint: 'e.g., 30-45 mins',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter estimated delivery time';
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _adminService.updateDeliverySettings(
                    adminId: adminId,
                    deliveryRadius: radiusController.text.trim(),
                    deliveryCharge: chargeController.text.trim(),
                    freeDeliveryAbove: freeAboveController.text.trim(),
                    estimatedDelivery: estimatedController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    // Snackbar removed
                  }
                } catch (e) {
                  if (context.mounted) {
                    // Snackbar removed
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditPaymentSettingsDialog(Bakery bakery, String adminId) {
    final upiIdController = TextEditingController(text: bakery.upiId);
    final formKey = GlobalKey<FormState>();

    bool cashOnDelivery = bakery.paymentMethods.cashOnDelivery;
    bool qrCodePayment = bakery.paymentMethods.qrCodePayment;
    bool upiIdPayment = bakery.paymentMethods.upiIdPayment;
    String? qrCodeImagePath;
    String? currentQrCodeUrl = bakery.qrCodeImageUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Payment Settings'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Methods',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Cash on Delivery'),
                    value: cashOnDelivery,
                    onChanged: (value) =>
                        setState(() => cashOnDelivery = value),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('QR Code Payment'),
                    value: qrCodePayment,
                    onChanged: (value) => setState(() => qrCodePayment = value),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('UPI Payment'),
                    value: upiIdPayment,
                    onChanged: (value) => setState(() => upiIdPayment = value),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 24),

                  // QR Code Section
                  if (qrCodePayment) ...[
                    const Text(
                      'QR Code Image',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (qrCodeImagePath != null ||
                        currentQrCodeUrl != null) ...[
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: qrCodeImagePath != null
                              ? Image.file(
                                  File(qrCodeImagePath!),
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  currentQrCodeUrl!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: () async {
                        final path = await _pickQrCodeImage();
                        if (path != null) {
                          setState(() => qrCodeImagePath = path);
                        }
                      },
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(
                        qrCodeImagePath != null || currentQrCodeUrl != null
                            ? 'Change QR Code'
                            : 'Upload QR Code',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // UPI ID Section
                  if (upiIdPayment) ...[
                    CustomTextField(
                      controller: upiIdController,
                      label: 'UPI ID',
                      hint: 'e.g., name@bank',
                      validator: (value) {
                        if (upiIdPayment && (value == null || value.isEmpty)) {
                          return 'Please enter UPI ID';
                        }
                        if (value != null && value.isNotEmpty) {
                          final upiRegex = RegExp(r'^[\w.-]+@[\w]+$');
                          if (!upiRegex.hasMatch(value)) {
                            return 'Enter a valid UPI ID';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!cashOnDelivery && !qrCodePayment && !upiIdPayment) {
                  // Snackbar removed
                  return;
                }

                if (formKey.currentState!.validate()) {
                  try {
                    String? qrCodeUrl = currentQrCodeUrl;

                    // Upload new QR code if selected
                    if (qrCodeImagePath != null) {
                      // Snackbar removed
                      qrCodeUrl = await CloudinaryService.instance
                          .uploadQrCodeImage(qrCodeImagePath!);
                    }

                    await _adminService.updatePaymentMethods(
                      adminId: adminId,
                      cashOnDelivery: cashOnDelivery,
                      qrCodePayment: qrCodePayment,
                      upiIdPayment: upiIdPayment,
                      upiId: upiIdPayment ? upiIdController.text.trim() : null,
                      qrCodeImageUrl: qrCodeUrl,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      // Snackbar removed
                    }
                  } catch (e) {
                    if (context.mounted) {
                      // Snackbar removed
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaxSettingsDialog(Bakery bakery, String adminId) {
    final gstRateController = TextEditingController(text: bakery.gstRate);
    final gstinController = TextEditingController(text: bakery.gstin);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tax Settings'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: gstRateController,
                label: 'GST Rate (%)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter GST rate';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate < 0 || rate > 100) {
                    return 'Please enter a valid percentage (0-100)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: gstinController,
                label: 'GSTIN',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter GSTIN';
                  }
                  if (value.length != 15) {
                    return 'GSTIN must be 15 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _adminService.updateTaxSettings(
                    adminId: adminId,
                    gstRate: gstRateController.text.trim(),
                    gstin: gstinController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    // Snackbar removed
                  }
                } catch (e) {
                  if (context.mounted) {
                    // Snackbar removed
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickQrCodeImage() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        useRootNavigator: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choose Image Source',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.photo_camera,
                        color: AppColors.primary,
                      ),
                    ),
                    title: const Text('Take Photo'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: AppColors.primary,
                      ),
                    ),
                    title: const Text('Choose from Gallery'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (source == null) return null;

      // Request permissions
      bool permissionGranted = false;
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        permissionGranted = status.isGranted;
      } else {
        PermissionStatus status;
        if (Platform.isAndroid) {
          status = await Permission.photos.request();
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
        } else {
          status = await Permission.photos.request();
        }
        permissionGranted = status.isGranted || status.isLimited;
      }

      if (!permissionGranted) {
        if (mounted) {
          // Snackbar removed
        }
        return null;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      return image?.path;
    } catch (e) {
      if (mounted) {
        // Snackbar removed
      }
      return null;
    }
  }

  void _showQrCodeDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment QR Code'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            SizedBox(height: 8),
                            Text('Failed to load image'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Pinch to zoom',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
