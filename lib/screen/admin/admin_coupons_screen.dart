import 'package:flutter/material.dart';
import 'package:bakehub/constants/app_colors.dart';
import 'package:bakehub/models/coupon.dart';
import 'package:bakehub/services/coupon_service.dart';
import 'package:bakehub/widgets/custom_text_field.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({Key? key}) : super(key: key);

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final CouponService _couponService = CouponService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Coupons'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCouponDialog(),
            tooltip: 'Add Coupon',
          ),
        ],
      ),
      body: StreamBuilder<List<Coupon>>(
        stream: _couponService.getAllCoupons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
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

          final coupons = snapshot.data ?? [];

          if (coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No coupons yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first coupon',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return _buildCouponCard(coupon);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCouponDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Coupon', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    final isExpired = coupon.isExpired;
    final isActive = coupon.isActive && !isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.1)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_offer,
            color: isActive ? AppColors.primary : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                coupon.code,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green
                    : isExpired
                    ? Colors.grey
                    : Colors.orange,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                isExpired
                    ? 'EXPIRED'
                    : isActive
                    ? 'ACTIVE'
                    : 'INACTIVE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              coupon.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? Colors.grey[700] : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.discount, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  coupon.discountType == DiscountType.percentage
                      ? '${coupon.discountValue}% OFF'
                      : '₹${coupon.discountValue} OFF',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Used: ${coupon.usageCount ?? 0}' +
                      (coupon.maxUsageCount != null
                          ? '/${coupon.maxUsageCount}'
                          : ''),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Valid: ${coupon.validFrom.day}/${coupon.validFrom.month}/${coupon.validFrom.year} - ${coupon.validUpto.day}/${coupon.validUpto.month}/${coupon.validUpto.year}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            if (coupon.minOrderAmount != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Min Order: ₹${coupon.minOrderAmount}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditCouponDialog(coupon);
                break;
              case 'toggle':
                _toggleCouponStatus(coupon);
                break;
              case 'delete':
                _showDeleteConfirmation(coupon);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (!isExpired)
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      coupon.isActive ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(coupon.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCouponDialog() {
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    final discountValueController = TextEditingController();
    final maxDiscountController = TextEditingController();
    final minOrderController = TextEditingController();
    final maxUsageController = TextEditingController();
    final maxUsagePerUserController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    DiscountType discountType = DiscountType.percentage;
    DateTime validFrom = DateTime.now();
    DateTime validUpto = DateTime.now().add(const Duration(days: 30));
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Coupon'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: codeController,
                    label: 'Coupon Code',
                    hint: 'e.g., SAVE20',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter coupon code';
                      }
                      if (value.length < 3) {
                        return 'Code must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: descriptionController,
                    label: 'Description',
                    hint: 'What\'s this coupon for?',
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Discount Type',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<DiscountType>(
                          title: const Text('Percentage'),
                          value: DiscountType.percentage,
                          groupValue: discountType,
                          onChanged: (value) {
                            setState(() => discountType = value!);
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<DiscountType>(
                          title: const Text('Fixed'),
                          value: DiscountType.fixedAmount,
                          groupValue: discountType,
                          onChanged: (value) {
                            setState(() => discountType = value!);
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: discountValueController,
                    label: discountType == DiscountType.percentage
                        ? 'Discount (%)'
                        : 'Discount Amount (₹)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter discount value';
                      }
                      final number = double.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Please enter valid amount';
                      }
                      if (discountType == DiscountType.percentage &&
                          number > 100) {
                        return 'Percentage cannot exceed 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (discountType == DiscountType.percentage) ...[
                    CustomTextField(
                      controller: maxDiscountController,
                      label: 'Max Discount Amount (₹) - Optional',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                  ],
                  CustomTextField(
                    controller: minOrderController,
                    label: 'Minimum Order Amount (₹) - Optional',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: maxUsageController,
                    label: 'Max Total Usage - Optional',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: maxUsagePerUserController,
                    label: 'Max Usage Per User - Optional',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Valid From',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: validFrom,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => validFrom = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${validFrom.day}/${validFrom.month}/${validFrom.year}',
                          ),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Valid Until',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: validUpto,
                        firstDate: validFrom,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => validUpto = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${validUpto.day}/${validUpto.month}/${validUpto.year}',
                          ),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);

                        try {
                          final coupon = Coupon(
                            id: '',
                            code: codeController.text.trim(),
                            description: descriptionController.text.trim(),
                            discountType: discountType,
                            discountValue: double.parse(
                              discountValueController.text.trim(),
                            ),
                            maxDiscount: maxDiscountController.text.isNotEmpty
                                ? double.parse(
                                    maxDiscountController.text.trim(),
                                  )
                                : null,
                            minOrderAmount: minOrderController.text.isNotEmpty
                                ? double.parse(minOrderController.text.trim())
                                : null,
                            maxUsageCount: maxUsageController.text.isNotEmpty
                                ? int.parse(maxUsageController.text.trim())
                                : null,
                            usageCount: 0,
                            maxUsagePerUser:
                                maxUsagePerUserController.text.isNotEmpty
                                ? int.parse(
                                    maxUsagePerUserController.text.trim(),
                                  )
                                : null,
                            validFrom: validFrom,
                            validUpto: validUpto,
                            createdAt: DateTime.now(),
                          );

                          await _couponService.createCoupon(coupon);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Coupon created successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCouponDialog(Coupon coupon) {
    final descriptionController = TextEditingController(
      text: coupon.description,
    );
    final maxUsageController = TextEditingController(
      text: coupon.maxUsageCount?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${coupon.code}'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: descriptionController,
                    label: 'Description',
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: maxUsageController,
                    label: 'Max Total Usage - Optional',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);

                        try {
                          await _couponService.updateCoupon(coupon.id, {
                            'description': descriptionController.text.trim(),
                            if (maxUsageController.text.isNotEmpty)
                              'maxUsageCount': int.parse(
                                maxUsageController.text.trim(),
                              ),
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Coupon updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCouponStatus(Coupon coupon) async {
    try {
      await _couponService.toggleCouponStatus(coupon.id, !coupon.isActive);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon ${!coupon.isActive ? "activated" : "deactivated"}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Coupon coupon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text(
          'Are you sure you want to delete "${coupon.code}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _couponService.deleteCoupon(coupon.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coupon deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
