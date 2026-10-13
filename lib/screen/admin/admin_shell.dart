// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bakehub/constants/app_colors.dart';

class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({required this.child, Key? key}) : super(key: key);

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  void _onNavTap(int index, BuildContext context) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/products');
        break;
      case 2:
        context.go('/admin/orders');
        break;
      case 3:
        context.go('/admin/coupons');
        break;
      case 4:
        context.go('/admin/settings');
        break;
    }
  }

  int _getSelectedIndex(String currentRoute) {
    if (currentRoute.contains('/admin/dashboard')) return 0;
    if (currentRoute.contains('/admin/products')) return 1;
    if (currentRoute.contains('/admin/orders')) return 2;
    if (currentRoute.contains('/admin/coupons')) return 3;
    if (currentRoute.contains('/admin/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final selectedIndex = _getSelectedIndex(currentRoute);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[600],
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Coupons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) => _onNavTap(index, context),
      ),
    );
  }
}
