import 'package:bakehub/screen/auth/login_screen.dart';
import 'package:bakehub/screen/auth/register_screen.dart';
import 'package:bakehub/screen/auth/admin_register_screen.dart';
import 'package:bakehub/screen/auth/email_verification_screen.dart';
import 'package:bakehub/screen/auth/reset_password_screen.dart';
import 'package:bakehub/screen/splash_screen.dart';
import 'package:bakehub/screen/admin/admin_shell.dart';
import 'package:bakehub/screen/admin/admin_dashboard_screen.dart';
import 'package:bakehub/screen/admin/admin_products_screen.dart';
import 'package:bakehub/screen/admin/admin_orders_screen.dart';
import 'package:bakehub/screen/admin/admin_coupons_screen.dart';
import 'package:bakehub/screen/admin/admin_settings_screen.dart';
import 'package:bakehub/screen/admin/admin_locations_screen.dart';
import 'package:bakehub/screen/admin/add_product_screen.dart';
import 'package:bakehub/screen/admin/add_coupon_screen.dart';
import 'package:bakehub/screen/admin/admin_categories_screen.dart';
import 'package:bakehub/screen/admin/customers_screen.dart';
import 'package:bakehub/screen/admin/reports_screen.dart';
import 'package:bakehub/screen/admin/edit_product_screen.dart';
import 'package:bakehub/screen/customer/customer_shell.dart';
import 'package:bakehub/screen/customer/customer_home_screen.dart';
import 'package:bakehub/screen/customer/customer_products_screen.dart';
import 'package:bakehub/screen/customer/customer_cart_screen.dart';
import 'package:bakehub/screen/customer/customer_checkout_screen.dart';
import 'package:bakehub/screen/customer/customer_orders_screen.dart';
import 'package:bakehub/screen/customer/customer_profile_screen.dart';
import 'package:bakehub/screen/customer/product_detail_screen.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ========== AUTH ROUTES ==========
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/admin-register',
      builder: (context, state) => const AdminRegisterScreen(),
    ),
    GoRoute(
      path: '/email-verification',
      builder: (context, state) => const EmailVerificationScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),

    // ========== ADMIN ROUTES WITH SHELL ==========
    ShellRoute(
      builder: (context, state, child) {
        return AdminShell(child: child);
      },
      routes: [
        // Dashboard
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),

        // Products
        GoRoute(
          path: '/admin/products',
          builder: (context, state) => const AdminProductsScreen(),
        ),
        GoRoute(
          path: '/admin/product/add',
          builder: (context, state) => const AddProductScreen(),
        ),
        GoRoute(
          path: '/admin/product/edit/:id',
          builder: (context, state) {
            final productId = state.pathParameters['id']!;
            return EditProductScreen(productId: productId);
          },
        ),

        // Orders
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) => const AdminOrdersScreen(),
        ),

        // Coupons
        GoRoute(
          path: '/admin/coupons',
          builder: (context, state) => const AdminCouponsScreen(),
        ),
        GoRoute(
          path: '/admin/coupon/add',
          builder: (context, state) => const AddCouponScreen(),
        ),

        // Settings
        GoRoute(
          path: '/admin/settings',
          builder: (context, state) => const AdminSettingsScreen(),
        ),

        // Locations
        GoRoute(
          path: '/admin/locations',
          builder: (context, state) => const AdminLocationsScreen(),
        ),

        // Categories
        GoRoute(
          path: '/admin/categories',
          builder: (context, state) => const AdminCategoriesScreen(),
        ),

        // Customers
        GoRoute(
          path: '/admin/customers',
          builder: (context, state) => const CustomersScreen(),
        ),

        // Reports
        GoRoute(
          path: '/admin/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
      ],
    ),

    // ========== CUSTOMER ROUTES WITH SHELL ==========
    ShellRoute(
      builder: (context, state, child) {
        return CustomerShell(child: child);
      },
      routes: [
        // Home
        GoRoute(
          path: '/customer/home',
          builder: (context, state) => const CustomerHomeScreen(),
        ),

        // Products
        GoRoute(
          path: '/customer/products',
          builder: (context, state) => const CustomerProductsScreen(),
        ),

        // Cart
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CustomerCartScreen(),
        ),

        // Checkout
        GoRoute(
          path: '/customer/checkout',
          builder: (context, state) => const CustomerCheckoutScreen(),
        ),

        // Orders
        GoRoute(
          path: '/customer/orders',
          builder: (context, state) => const CustomerOrdersScreen(),
        ),

        // Profile
        GoRoute(
          path: '/customer/profile',
          builder: (context, state) => const CustomerProfileScreen(),
        ),
      ],
    ),

    // ========== CUSTOMER DETAIL ROUTES (Outside Shell) ==========
    GoRoute(
      path: '/customer/product/detail/:id',
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        return ProductDetailScreen(productId: productId);
      },
    ),
  ],
);
