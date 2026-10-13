import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:bakehub/constants/app_colors.dart';
import 'package:bakehub/models/order.dart';
import 'package:bakehub/models/address.dart';
import 'package:bakehub/models/delivery_location.dart';
import 'package:bakehub/models/bakery.dart';
import 'package:bakehub/models/coupon.dart';
import 'package:bakehub/provider/cart_provider.dart';
import 'package:bakehub/provider/auth_provider.dart';
import 'package:bakehub/services/order_service.dart';
import 'package:bakehub/services/location_service.dart';
import 'package:bakehub/services/admin_service.dart';
import 'package:bakehub/services/cloudinary_service.dart';
import 'package:bakehub/services/coupon_service.dart';
import 'package:bakehub/services/snackbar_services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';

class CustomerCheckoutScreen extends StatefulWidget {
  const CustomerCheckoutScreen({super.key});

  @override
  State<CustomerCheckoutScreen> createState() => _CustomerCheckoutScreenState();
}

class _CustomerCheckoutScreenState extends State<CustomerCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final CartProvider _cartProvider = CartProvider.instance;
  final AuthProvider _authProvider = AuthProvider.instance;
  final OrderService _orderService = OrderService.instance;
  final LocationService _locationService = LocationService.instance;
  final AdminService _adminService = AdminService();
  final CouponService _couponService = CouponService.instance;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _utrController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  PaymentMethod? _selectedPaymentMethod;
  bool _isPlacingOrder = false;
  DeliveryLocation? _selectedLocation;
  PaymentMethods? _paymentMethods;
  StreamSubscription? _bakerySubscription;
  String? _qrCodeImageUrl;
  String? _upiId;
  File? _paymentScreenshot;
  final ImagePicker _imagePicker = ImagePicker();

  // Coupon related state
  Coupon? _appliedCoupon;
  double _discountAmount = 0.0;
  bool _isValidatingCoupon = false;

  // Hardcoded bakery ID (single admin system)
  final String _bakeryId = 'wi9LNUqFuwOwTOLQqJHwecqQXiq1';

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _loadPaymentMethods();
  }

  void _loadPaymentMethods() {
    _bakerySubscription = _adminService.getBakerySettings(_bakeryId).listen((
      bakery,
    ) {
      if (bakery != null && mounted) {
        setState(() {
          _paymentMethods = bakery.paymentMethods;
          _qrCodeImageUrl = bakery.qrCodeImageUrl;
          _upiId = bakery.upiId;
          // Set default payment method to first enabled method
          if (_selectedPaymentMethod == null) {
            if (_paymentMethods!.cashOnDelivery) {
              _selectedPaymentMethod = PaymentMethod.cashOnDelivery;
            } else if (_paymentMethods!.upiIdPayment) {
              _selectedPaymentMethod = PaymentMethod.upi;
            } else if (_paymentMethods!.qrCodePayment) {
              _selectedPaymentMethod = PaymentMethod.creditCard;
            }
          }
        });
      }
    });
  }

  Future<void> _loadUserDetails() async {
    final userId = _authProvider.user?.uid;
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data();
        if (data != null) {
          setState(() {
            _nameController.text = data['name'] as String? ?? '';
            _phoneController.text = data['phoneNumber'] as String? ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user details: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _utrController.dispose();
    _couponController.dispose();
    _bakerySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedBuilder(
        animation: _cartProvider,
        builder: (context, _) {
          final cart = _cartProvider.cart;
          if (cart == null || cart.isEmpty) {
            return _buildEmptyCart();
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildOrderSummary(),
                _buildDeliveryForm(),
                _buildPaymentMethod(),
                _buildCouponSection(),
                _buildOrderNotes(),
                _buildTotalSection(),
                _buildPlaceOrderButton(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/customer/products'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Browse Products',
              style: TextStyle(color: AppColors.textOnPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final cart = _cartProvider.cart!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName} x${item.quantity}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '₹${(item.productPrice * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Customer Details
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length != 10) {
                  return 'Please enter a valid 10-digit phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Location Selector
            const Text(
              'Select Delivery Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose from available delivery areas',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<DeliveryLocation>>(
              stream: _locationService.getActiveLocations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Error loading locations: ${snapshot.error}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final locations = snapshot.data ?? [];

                // Validate selected location still exists in current list
                if (_selectedLocation != null && locations.isNotEmpty) {
                  final locationExists = locations.any(
                    (loc) => loc.id == _selectedLocation!.id,
                  );
                  if (!locationExists) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedLocation = null;
                        });
                      }
                    });
                  }
                }

                if (locations.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No delivery locations available',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Please contact the bakery for delivery options',
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedLocation == null
                              ? Colors.red[300]!
                              : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: locations.map((location) {
                          final isSelected =
                              _selectedLocation?.id == location.id;
                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.08)
                                  : Colors.transparent,
                              border: Border(
                                bottom: location != locations.last
                                    ? BorderSide(color: Colors.grey[200]!)
                                    : BorderSide.none,
                              ),
                            ),
                            child: RadioListTile<String>(
                              value: location.id,
                              groupValue: _selectedLocation?.id,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLocation = location;
                                });
                              },
                              title: Text(
                                location.locationName,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 14,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  location.fullAddress,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              activeColor: AppColors.primary,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (_selectedLocation == null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Please select a delivery location',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Delivery Address',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedLocation!.locationName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedLocation!.fullAddress,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Loading state
          if (_paymentMethods == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          // No payment methods enabled
          else if (!_paymentMethods!.cashOnDelivery &&
              !_paymentMethods!.upiIdPayment &&
              !_paymentMethods!.qrCodePayment)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No payment methods are currently available. Please contact the bakery.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          // Show enabled payment methods
          else ...[
            if (_paymentMethods!.cashOnDelivery)
              RadioListTile<PaymentMethod>(
                title: const Text('Cash on Delivery'),
                subtitle: const Text('Pay when you receive the order'),
                value: PaymentMethod.cashOnDelivery,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                    _paymentScreenshot = null;
                    _utrController.clear();
                  });
                },
              ),

            if (_paymentMethods!.upiIdPayment)
              RadioListTile<PaymentMethod>(
                title: const Text('UPI'),
                subtitle: const Text('Pay via Google Pay, PhonePe, Paytm'),
                value: PaymentMethod.upi,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),

            // Show UPI ID if UPI payment is selected
            if (_selectedPaymentMethod == PaymentMethod.upi &&
                _upiId != null &&
                _upiId!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Pay to UPI ID',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UPI ID',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _upiId!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      color: AppColors.primary,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _upiId!));
                        if (mounted) {
                          SnackBarService.showSuccess(
                            context,
                            'UPI ID copied to clipboard',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],

            if (_paymentMethods!.qrCodePayment)
              RadioListTile<PaymentMethod>(
                title: const Text('QR Code / Online Payment'),
                subtitle: const Text('Pay using QR code or credit/debit card'),
                value: PaymentMethod.creditCard,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),

            // Show QR Code if QR payment is selected
            if (_selectedPaymentMethod == PaymentMethod.creditCard &&
                _qrCodeImageUrl != null &&
                _qrCodeImageUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Scan QR Code to Pay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _qrCodeImageUrl!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          width: 200,
                          height: 200,
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
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],

            // Payment proof fields for UPI or QR Code
            if (_selectedPaymentMethod == PaymentMethod.upi ||
                _selectedPaymentMethod == PaymentMethod.creditCard) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Upload Payment Proof',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Upload Payment Screenshot
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _paymentScreenshot == null
                    ? ListTile(
                        leading: const Icon(
                          Icons.upload_file,
                          color: AppColors.primary,
                        ),
                        title: const Text('Upload Payment Screenshot'),
                        subtitle: const Text('Required for verification'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _pickPaymentScreenshot,
                      )
                    : ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: const Text('Screenshot uploaded'),
                        subtitle: Text(
                          _paymentScreenshot!.path.split('/').last,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _paymentScreenshot = null;
                            });
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // UTR Number Field
              TextFormField(
                controller: _utrController,
                decoration: InputDecoration(
                  labelText: 'UTR / Transaction ID *',
                  hintText: 'Enter UTR or Transaction Reference Number',
                  prefixIcon: const Icon(Icons.receipt_long),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: 'Required for order verification',
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _pickPaymentScreenshot() async {
    try {
      // Request permission
      final status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        if (mounted) {
          SnackBarService.showError(
            context,
            'Gallery permission is required to upload payment screenshot',
          );
        }
        return;
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _paymentScreenshot = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      SnackBarService.showError(context, 'Please enter a coupon code');
      return;
    }

    setState(() {
      _isValidatingCoupon = true;
    });

    try {
      final userId = _authProvider.user?.uid;
      final orderAmount =
          _cartProvider.subtotal +
          _cartProvider.deliveryCharge +
          _cartProvider.tax;

      final result = await _couponService.validateCoupon(
        code,
        orderAmount,
        userId,
      );

      if (result['isValid'] == true) {
        final coupon = await _couponService.getCouponByCode(code);
        setState(() {
          _appliedCoupon = coupon;
          _discountAmount = result['discount'] as double;
        });
        if (mounted) {
          SnackBarService.showSuccess(context, result['message']);
        }
      } else {
        if (mounted) {
          SnackBarService.showError(context, result['message']);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'Failed to apply coupon: $e');
      }
    } finally {
      setState(() {
        _isValidatingCoupon = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discountAmount = 0.0;
      _couponController.clear();
    });
    SnackBarService.showInfo(context, 'Coupon removed');
  }

  void _showAvailableCoupons() {
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
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer, color: AppColors.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Available Coupons',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Coupon>>(
                    stream: _couponService.getActiveCoupons(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 60,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading coupons',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final coupons = snapshot.data ?? [];

                      if (coupons.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 80,
                                  color: AppColors.textHint,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No coupons available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Check back later for new offers',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: coupons.length,
                        itemBuilder: (context, index) {
                          final coupon = coupons[index];
                          final isApplied = _appliedCoupon?.id == coupon.id;
                          final orderAmount =
                              _cartProvider.subtotal +
                              _cartProvider.deliveryCharge +
                              _cartProvider.tax;
                          final canApply =
                              coupon.minOrderAmount == null ||
                              orderAmount >= coupon.minOrderAmount!;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: isApplied ? 4 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isApplied
                                    ? AppColors.success
                                    : Colors.grey[300]!,
                                width: isApplied ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          coupon.code,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isApplied)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'APPLIED',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    coupon.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.discount,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        coupon.discountType ==
                                                DiscountType.percentage
                                            ? 'Save ${coupon.discountValue.toStringAsFixed(0)}%'
                                            : 'Save ₹${coupon.discountValue.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                        ),
                                      ),
                                      if (coupon.maxDiscount != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '(Max: ₹${coupon.maxDiscount!.toStringAsFixed(0)})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (coupon.minOrderAmount != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.shopping_cart,
                                          size: 16,
                                          color: AppColors.textHint,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Min order: ₹${coupon.minOrderAmount!.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: AppColors.textHint,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Valid till ${_formatCouponDate(coupon.validUpto)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!canApply) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: AppColors.warning,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Add ₹${(coupon.minOrderAmount! - orderAmount).toStringAsFixed(0)} more to apply',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.warning,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isApplied
                                          ? null
                                          : canApply
                                          ? () {
                                              _couponController.text =
                                                  coupon.code;
                                              Navigator.pop(context);
                                              _applyCoupon();
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isApplied
                                            ? AppColors.success
                                            : AppColors.primary,
                                        disabledBackgroundColor:
                                            Colors.grey[300],
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(
                                        isApplied ? 'Applied' : 'Apply Coupon',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isApplied || canApply
                                              ? AppColors.textOnPrimary
                                              : AppColors.textHint,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatCouponDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildCouponSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Apply Coupon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: _showAvailableCoupons,
                child: const Text(
                  'View Coupons',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_appliedCoupon == null) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.local_offer),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isValidatingCoupon ? null : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: _isValidatingCoupon
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textOnPrimary,
                            ),
                          ),
                        )
                      : const Text(
                          'Apply',
                          style: TextStyle(color: AppColors.textOnPrimary),
                        ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appliedCoupon!.code,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _appliedCoupon!.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You saved ₹${_discountAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: _removeCoupon,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderNotes() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Special Instructions (Optional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Add any special requests or notes...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    final isFreeDelivery = _cartProvider.isFreeDeliveryEligible;
    final finalTotal = _cartProvider.total - _discountAmount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', _cartProvider.subtotal),
          const SizedBox(height: 8),
          _buildPriceRow(
            'Tax (${_cartProvider.settings.taxPercent.toStringAsFixed(1)}% GST)',
            _cartProvider.tax,
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            isFreeDelivery ? 'Delivery (FREE)' : 'Delivery Fee',
            _cartProvider.deliveryCharge,
            color: isFreeDelivery ? AppColors.success : AppColors.textPrimary,
          ),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              'Discount',
              -_discountAmount,
              color: AppColors.success,
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '₹${finalTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
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

  Widget _buildPriceRow(String label, double amount, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: color ?? AppColors.textPrimary),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isPlacingOrder || _paymentMethods == null)
            ? null
            : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isPlacingOrder
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textOnPrimary,
                  ),
                ),
              )
            : const Text(
                'Place Order',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      if (mounted) {
        SnackBarService.showError(context, 'Please select a delivery location');
      }
      return;
    }

    if (_selectedPaymentMethod == null) {
      if (mounted) {
        SnackBarService.showError(context, 'Please select a payment method');
      }
      return;
    }

    // Validate payment proof for online payments
    if (_selectedPaymentMethod == PaymentMethod.upi ||
        _selectedPaymentMethod == PaymentMethod.creditCard) {
      if (_paymentScreenshot == null) {
        if (mounted) {
          SnackBarService.showError(
            context,
            'Please upload payment screenshot for verification',
          );
        }
        return;
      }

      if (_utrController.text.trim().isEmpty) {
        if (mounted) {
          SnackBarService.showError(context, 'Please enter UTR/Transaction ID');
        }
        return;
      }
    }

    final userId = _authProvider.user?.uid;
    if (userId == null) {
      if (mounted) {
        SnackBarService.showError(context, 'Please login to place order');
      }
      return;
    }

    final cart = _cartProvider.cart;
    if (cart == null || cart.isEmpty) {
      if (mounted) {
        SnackBarService.showError(context, 'Your cart is empty');
      }
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      // Upload payment screenshot if provided
      String? paymentScreenshotUrl;
      if (_paymentScreenshot != null) {
        try {
          paymentScreenshotUrl = await CloudinaryService.instance
              .uploadPaymentProof(_paymentScreenshot!.path);
          if (paymentScreenshotUrl.isEmpty) {
            throw Exception('Failed to upload payment screenshot');
          }
        } catch (e) {
          if (mounted) {
            SnackBarService.showError(
              context,
              'Failed to upload payment screenshot. Please try again.',
            );
          }
          setState(() {
            _isPlacingOrder = false;
          });
          return;
        }
      }

      // Create address from selected location
      final address = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        street: _selectedLocation!.street,
        city: _selectedLocation!.city,
        state: _selectedLocation!.state,
        pinCode: _selectedLocation!.pinCode,
        landmark: _selectedLocation!.landmark,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      // Convert cart items to order items
      final orderItems = cart.items.map((cartItem) {
        return OrderItem(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              cartItem.productId,
          productId: cartItem.productId,
          productName: cartItem.productName,
          price: cartItem.productPrice,
          quantity: cartItem.quantity,
          productImage: cartItem.productImage,
        );
      }).toList();

      // Create order
      final finalTotal = _cartProvider.total - _discountAmount;

      final order = Order(
        id: '', // Will be set by OrderService
        userId: userId,
        items: orderItems,
        subtotal: _cartProvider.subtotal,
        deliveryCharge: _cartProvider.deliveryCharge,
        tax: _cartProvider.tax,
        totalAmount: finalTotal,
        status: OrderStatus.pending,
        paymentMethod: _selectedPaymentMethod!,
        paymentStatus: _selectedPaymentMethod! == PaymentMethod.cashOnDelivery
            ? PaymentStatus.pending
            : PaymentStatus.pending,
        deliveryAddress: address,
        estimatedDeliveryTime: DateTime.now().add(const Duration(hours: 2)),
        orderDate: DateTime.now(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        paymentScreenshot: paymentScreenshotUrl,
        utrNumber: _utrController.text.trim().isEmpty
            ? null
            : _utrController.text.trim().toUpperCase(),
        couponId: _appliedCoupon?.id,
        couponCode: _appliedCoupon?.code,
        discountAmount: _discountAmount > 0 ? _discountAmount : null,
      );

      // Save order to Firebase
      final orderId = await _orderService.createOrder(order);

      if (orderId != null) {
        // Increment coupon usage if applied
        if (_appliedCoupon != null) {
          try {
            await _couponService.incrementCouponUsage(
              _appliedCoupon!.id,
              userId,
            );
          } catch (e) {
            print('Error incrementing coupon usage: $e');
          }
        }

        // Clear the cart
        await _cartProvider.clearCart(userId);

        if (mounted) {
          SnackBarService.showSuccess(
            context,
            'Order placed successfully! Order ID: #${orderId.substring(0, 8).toUpperCase()}',
          );

          // Navigate to orders screen
          context.go('/customer/orders');
        }
      } else {
        if (mounted) {
          SnackBarService.showError(
            context,
            'Failed to place order. Please try again.',
          );
        }
      }
    } catch (e) {
      print('Error placing order: $e');
      if (mounted) {
        SnackBarService.showError(
          context,
          'An error occurred. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }
}
