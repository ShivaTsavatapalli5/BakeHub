import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bakehub/constants/app_colors.dart';
import 'package:bakehub/provider/auth_provider.dart';
import 'package:bakehub/services/cloudinary_service.dart';
import 'package:bakehub/widgets/custom_text_field.dart';
import 'package:bakehub/widgets/custom_button.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bakeryNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _businessHoursController = TextEditingController();
  final _deliveryRadiusController = TextEditingController();
  final _deliveryChargeController = TextEditingController();
  final _freeDeliveryAboveController = TextEditingController();
  final _estimatedDeliveryController = TextEditingController();
  final _gstRateController = TextEditingController();
  final _gstinController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _cashOnDelivery = true;
  bool _qrCodePayment = true;
  bool _upiIdPayment = true;
  String? _qrCodeImagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bakeryNameController.dispose();
    _addressController.dispose();
    _businessHoursController.dispose();
    _deliveryRadiusController.dispose();
    _deliveryChargeController.dispose();
    _freeDeliveryAboveController.dispose();
    _estimatedDeliveryController.dispose();
    _gstRateController.dispose();
    _gstinController.dispose();
    _upiIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[1-9]\d{9,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validateBakeryName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bakery name is required';
    }
    if (value.length < 3) {
      return 'Bakery name must be at least 3 characters';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.length < 10) {
      return 'Please enter a complete address';
    }
    return null;
  }

  String? _validateBusinessHours(String? value) {
    if (value == null || value.isEmpty) {
      return 'Business hours are required';
    }
    return null;
  }

  String? _validateDeliveryRadius(String? value) {
    if (value == null || value.isEmpty) {
      return 'Delivery radius is required';
    }
    if (int.tryParse(value) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  String? _validateDeliveryCharge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Delivery charge is required';
    }
    if (double.tryParse(value) == null) {
      return 'Enter a valid amount';
    }
    return null;
  }

  String? _validateFreeDeliveryAbove(String? value) {
    if (value == null || value.isEmpty) {
      return 'Free delivery threshold is required';
    }
    if (double.tryParse(value) == null) {
      return 'Enter a valid amount';
    }
    return null;
  }

  String? _validateEstimatedDelivery(String? value) {
    if (value == null || value.isEmpty) {
      return 'Estimated delivery time is required';
    }
    return null;
  }

  String? _validateGstRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'GST rate is required';
    }
    final rate = double.tryParse(value);
    if (rate == null || rate < 0 || rate > 100) {
      return 'Enter a valid percentage (0-100)';
    }
    return null;
  }

  String? _validateGstin(String? value) {
    if (value == null || value.isEmpty) {
      return 'GSTIN is required';
    }
    if (value.length != 15) {
      return 'GSTIN must be 15 characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateUpiId(String? value) {
    if (value == null || value.isEmpty) {
      return 'UPI ID is required';
    }
    final upiRegex = RegExp(r'^[\w.-]+@[\w]+$');
    if (!upiRegex.hasMatch(value)) {
      return 'Enter a valid UPI ID (e.g., name@bank)';
    }
    return null;
  }

  Future<void> _pickQrCodeImage() async {
    try {
      // Show bottom sheet to choose source
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
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
                    subtitle: const Text('Open camera to take a photo'),
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
                    subtitle: const Text('Select an existing photo'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (source == null) return;

      // Request permissions based on source
      bool permissionGranted = false;

      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        permissionGranted = status.isGranted;

        if (!permissionGranted && mounted) {
          // Snackbar removed
          return;
        }
      } else {
        // For gallery, request photos permission
        PermissionStatus status;
        if (Platform.isAndroid) {
          // Android 13+ uses specific media permissions
          final androidInfo = await Permission.photos.status;
          if (androidInfo.isDenied) {
            status = await Permission.photos.request();
          } else {
            status = androidInfo;
          }

          // Fallback to storage permission for older Android versions
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
        } else {
          // iOS uses photos permission
          status = await Permission.photos.request();
        }

        permissionGranted = status.isGranted || status.isLimited;

        if (!permissionGranted && mounted) {
          // Snackbar removed
          return;
        }
      }

      // Pick the image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _qrCodeImagePath = image.path;
        });
        if (mounted) {
          // Snackbar removed
        }
      }
    } catch (e) {
      if (mounted) {
        // Snackbar removed
      }
      print('Image picker error: $e');
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      // Snackbar removed
      return;
    }

    // Validate payment methods
    if (!_cashOnDelivery && !_qrCodePayment && !_upiIdPayment) {
      // Snackbar removed
      return;
    }

    // Validate QR code image if QR payment is enabled
    if (_qrCodePayment && _qrCodeImagePath == null) {
      // Snackbar removed
      return;
    }

    // Validate UPI ID if UPI payment is enabled
    if (_upiIdPayment && _upiIdController.text.trim().isEmpty) {
      // Snackbar removed
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Upload QR code image to Cloudinary if QR payment is enabled
      String? qrCodeUrl;
      if (_qrCodePayment && _qrCodeImagePath != null) {
        try {
          if (mounted) {
            // Snackbar removed
          }

          print('Starting QR code upload to Cloudinary...');
          print('File path: $_qrCodeImagePath');
          qrCodeUrl = await CloudinaryService.instance.uploadQrCodeImage(
            _qrCodeImagePath!,
          );
          print('Upload successful! URL: $qrCodeUrl');
        } on SocketException catch (e) {
          print('Socket exception during upload: $e');
          if (mounted) {
            // Snackbar removed
            setState(() => _isLoading = false);
            return;
          }
        } catch (e) {
          print('Error uploading QR code: $e');
          if (mounted) {
            // Snackbar removed
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      // Prepare bakery details
      final bakeryDetails = {
        'bakeryName': _bakeryNameController.text.trim(),
        'address': _addressController.text.trim(),
        'businessHours': _businessHoursController.text.trim(),
        'deliveryRadius': _deliveryRadiusController.text.trim(),
        'deliveryCharge': _deliveryChargeController.text.trim(),
        'freeDeliveryAbove': _freeDeliveryAboveController.text.trim(),
        'estimatedDelivery': _estimatedDeliveryController.text.trim(),
        'paymentMethods': {
          'cashOnDelivery': _cashOnDelivery,
          'qrCodePayment': _qrCodePayment,
          'upiIdPayment': _upiIdPayment,
        },
        'qrCodeImageUrl': qrCodeUrl,
        'upiId': _upiIdPayment ? _upiIdController.text.trim() : null,
        'gstRate': _gstRateController.text.trim(),
        'gstin': _gstinController.text.trim(),
      };

      await authProvider.registerAdminWithBakeryDetails(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bakeryDetails: bakeryDetails,
        onSuccess: (uid) async {
          if (mounted) {
            // Snackbar removed
            // Wait a moment for snackbar to display before navigating
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              context.go('/admin/dashboard');
            }
          }
        },
        onError: (error) async {
          if (mounted) {
            // Snackbar removed
          }
        },
      );
    } catch (e) {
      if (mounted) {
        // Snackbar removed
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Admin Registration',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Register your bakery',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Bakery Information Section
                const Text(
                  'Bakery Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // Bakery Name
                CustomTextField(
                  controller: _bakeryNameController,
                  label: 'Bakery Name',
                  hint: 'Enter your bakery name',
                  prefixIcon: const Icon(Icons.store, color: AppColors.primary),
                  validator: _validateBakeryName,
                ),

                const SizedBox(height: 16),

                // Address
                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  hint: 'Enter bakery address',
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                  ),
                  validator: _validateAddress,
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Business Hours
                CustomTextField(
                  controller: _businessHoursController,
                  label: 'Business Hours',
                  hint: 'e.g., 8 AM - 10 PM',
                  prefixIcon: const Icon(
                    Icons.access_time,
                    color: AppColors.primary,
                  ),
                  validator: _validateBusinessHours,
                ),

                const SizedBox(height: 24),

                // Delivery Settings Section
                const Text(
                  'Delivery Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _deliveryRadiusController,
                        label: 'Delivery Radius',
                        hint: 'km',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(
                          Icons.social_distance,
                          color: AppColors.primary,
                        ),
                        validator: _validateDeliveryRadius,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _deliveryChargeController,
                        label: 'Delivery Charge',
                        hint: '₹',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(
                          Icons.currency_rupee,
                          color: AppColors.primary,
                        ),
                        validator: _validateDeliveryCharge,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _freeDeliveryAboveController,
                        label: 'Free Delivery Above',
                        hint: '₹',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(
                          Icons.local_shipping,
                          color: AppColors.primary,
                        ),
                        validator: _validateFreeDeliveryAbove,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _estimatedDeliveryController,
                        label: 'Est. Delivery',
                        hint: 'e.g., 30-45 mins',
                        prefixIcon: const Icon(
                          Icons.timer,
                          color: AppColors.primary,
                        ),
                        validator: _validateEstimatedDelivery,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Payment Settings Section
                const Text(
                  'Payment Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: const Text('Cash on Delivery'),
                        value: _cashOnDelivery,
                        onChanged: (value) {
                          setState(() => _cashOnDelivery = value ?? false);
                        },
                        activeColor: AppColors.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('QR Code Payment'),
                        value: _qrCodePayment,
                        onChanged: (value) {
                          setState(() => _qrCodePayment = value ?? false);
                        },
                        activeColor: AppColors.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_qrCodePayment) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upload QR Code Image',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _pickQrCodeImage,
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      style: BorderStyle.solid,
                                      width: 2,
                                    ),
                                  ),
                                  child: _qrCodeImagePath != null
                                      ? Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.file(
                                                File(_qrCodeImagePath!),
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: CircleAvatar(
                                                radius: 12,
                                                backgroundColor:
                                                    AppColors.success,
                                                child: const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 40,
                                                color: AppColors.textSecondary,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Tap to upload QR code',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      CheckboxListTile(
                        title: const Text('UPI Id Payment'),
                        value: _upiIdPayment,
                        onChanged: (value) {
                          setState(() => _upiIdPayment = value ?? false);
                        },
                        activeColor: AppColors.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_upiIdPayment) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: CustomTextField(
                            controller: _upiIdController,
                            label: 'UPI ID',
                            hint: 'e.g., yourname@paytm',
                            prefixIcon: const Icon(
                              Icons.account_balance,
                              color: AppColors.primary,
                            ),
                            validator: _upiIdPayment ? _validateUpiId : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tax Configuration Section
                const Text(
                  'Tax Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _gstRateController,
                        label: 'GST Rate',
                        hint: '%',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(
                          Icons.percent,
                          color: AppColors.primary,
                        ),
                        validator: _validateGstRate,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _gstinController,
                        label: 'GSTIN',
                        hint: '15 digit GSTIN',
                        prefixIcon: const Icon(
                          Icons.receipt_long,
                          color: AppColors.primary,
                        ),
                        validator: _validateGstin,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Owner Information Section
                const Text(
                  'Owner Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // Full Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                  ),
                  validator: _validateName,
                ),

                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.primary,
                  ),
                  validator: _validateEmail,
                ),

                const SizedBox(height: 16),

                // Phone
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.primary,
                  ),
                  validator: _validatePhone,
                ),

                const SizedBox(height: 24),

                // Security Section
                const Text(
                  'Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a strong password',
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: _validatePassword,
                ),

                const SizedBox(height: 16),

                // Confirm Password
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                  ),
                  validator: _validateConfirmPassword,
                ),

                const SizedBox(height: 24),

                // Terms and Conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreeToTerms = !_agreeToTerms;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Register Button
                CustomButton(
                  text: 'Register Bakery',
                  onPressed: _isLoading ? null : _handleRegister,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
