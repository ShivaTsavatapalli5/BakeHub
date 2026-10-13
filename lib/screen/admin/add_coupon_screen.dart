import 'package:flutter/material.dart';
import 'package:bakehub/constants/app_colors.dart';

class AddCouponScreen extends StatelessWidget {
  const AddCouponScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Coupon'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Add Coupon Screen'),
            const SizedBox(height: 8),
            Text(
              'Coupon creation form coming soon',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
