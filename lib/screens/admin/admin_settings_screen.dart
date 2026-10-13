import 'package:flutter/material.dart';
import 'package:bakehub/constants/app_colors.dart';
import 'package:bakehub/models/app_settings.dart';
import 'package:bakehub/services/settings_service.dart';
import 'package:bakehub/services/snackbar_services.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final SettingsService _settingsService = SettingsService.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _deliveryFeeController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _settingsService.getSettings();
      _taxController.text = settings.taxPercent.toString();
      _deliveryFeeController.text = settings.deliveryFee.toString();
      _minAmountController.text = settings.freeDeliveryMinAmount.toString();
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'Failed to load settings: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final settings = AppSettings(
        taxPercent: double.parse(_taxController.text),
        deliveryFee: double.parse(_deliveryFeeController.text),
        freeDeliveryMinAmount: double.parse(_minAmountController.text),
      );

      final success = await _settingsService.updateSettings(settings);
      if (mounted) {
        if (success) {
          SnackBarService.showSuccess(context, 'Settings saved successfully!');
        } else {
          SnackBarService.showError(context, 'Failed to save settings');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'Error: $e');
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _taxController.dispose();
    _deliveryFeeController.dispose();
    _minAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: const Text('App Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These settings affect all customer orders in real-time',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tax Percent
                    _buildSectionTitle('Tax Settings'),
                    const SizedBox(height: 8),
                    Text(
                      'GST Rate applied to all orders',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Tax Percentage (%)',
                        hintText: '5.0',
                        prefixIcon: const Icon(Icons.percent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter tax percentage';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num < 0 || num > 100) {
                          return 'Enter a valid percentage (0-100)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Delivery Settings
                    _buildSectionTitle('Delivery Settings'),
                    const SizedBox(height: 8),
                    Text(
                      'Configure delivery charges and free delivery threshold',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deliveryFeeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Delivery Fee (₹)',
                        hintText: '50.0',
                        prefixIcon: const Icon(Icons.delivery_dining),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter delivery fee';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num < 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _minAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Minimum Amount for Free Delivery (₹)',
                        hintText: '500.0',
                        prefixIcon: const Icon(Icons.local_shipping),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter minimum amount';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num < 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reset to Default Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _taxController.text = '5.0';
                          _deliveryFeeController.text = '50.0';
                          _minAmountController.text = '500.0';
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: AppColors.primary),
                        ),
                        child: Text(
                          'Reset to Default Values',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
