import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bakehub/constants/app_colors.dart';
import 'package:bakehub/provider/cart_provider.dart';
import 'package:bakehub/provider/auth_provider.dart';
import 'package:bakehub/services/snackbar_services.dart';

class CustomerCartScreen extends StatefulWidget {
  const CustomerCartScreen({super.key});

  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  final CartProvider _cartProvider = CartProvider.instance;
  final AuthProvider _authProvider = AuthProvider.instance;

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  void _initializeCart() {
    final userId = _authProvider.user?.uid;
    if (userId != null) {
      _cartProvider.initializeCart(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cartProvider,
      builder: (context, _) {
        if (_cartProvider.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              title: const Text(
                'My Cart',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final cart = _cartProvider.cart;
        final isEmpty = cart?.isEmpty ?? true;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            title: const Text(
              'My Cart',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (!isEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    _showClearCartDialog();
                  },
                ),
            ],
          ),
          body: isEmpty ? _buildEmptyCart() : _buildCartContent(),
          bottomNavigationBar: isEmpty ? null : _buildCheckoutButton(),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add some delicious items to get started!',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/customer/products');
            },
            icon: const Icon(
              Icons.shopping_bag,
              color: AppColors.textOnPrimary,
            ),
            label: const Text(
              'Browse Products',
              style: TextStyle(color: AppColors.textOnPrimary),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    final cart = _cartProvider.cart;
    if (cart == null) return const SizedBox();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              return _buildCartItem(cart.items[index]);
            },
          ),
        ),
        _buildPriceSummary(),
      ],
    );
  }

  Widget _buildCartItem(item) {
    final userId = _authProvider.user?.uid;
    if (userId == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: item.productImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.productImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.cake,
                            size: 40,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    )
                  : Icon(Icons.cake, size: 40, color: AppColors.primary),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.productPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quantity Controls
                  Row(
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onTap: () async {
                          if (item.quantity > 1) {
                            await _cartProvider.updateQuantity(
                              userId: userId,
                              productId: item.productId,
                              quantity: item.quantity - 1,
                            );
                          } else {
                            await _cartProvider.removeFromCart(
                              userId: userId,
                              productId: item.productId,
                            );
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onTap: () async {
                          await _cartProvider.updateQuantity(
                            userId: userId,
                            productId: item.productId,
                            quantity: item.quantity + 1,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove Button
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.error),
              onPressed: () async {
                await _cartProvider.removeFromCart(
                  userId: userId,
                  productId: item.productId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }

  Widget _buildPriceSummary() {
    final amountNeeded = _cartProvider.amountForFreeDelivery;
    final isFreeDelivery = _cartProvider.isFreeDeliveryEligible;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Free delivery note
          if (!isFreeDelivery && amountNeeded > 0)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add ₹${amountNeeded.toStringAsFixed(2)} more to get FREE delivery!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isFreeDelivery)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Congratulations! You got FREE delivery!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _buildPriceRow('Subtotal', _cartProvider.subtotal),
          const SizedBox(height: 8),
          _buildPriceRow(
            'Tax (${_cartProvider.settings.taxPercent.toStringAsFixed(1)}% GST)',
            _cartProvider.tax,
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            isFreeDelivery ? 'Delivery Fee (FREE)' : 'Delivery Fee',
            _cartProvider.deliveryCharge,
            isStrikethrough:
                isFreeDelivery && _cartProvider.settings.deliveryFee > 0,
            originalAmount: isFreeDelivery
                ? _cartProvider.settings.deliveryFee
                : null,
          ),
          const Divider(height: 24),
          _buildPriceRow('Total', _cartProvider.total, isBold: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isStrikethrough = false,
    double? originalAmount,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
        Row(
          children: [
            if (isStrikethrough && originalAmount != null) ...[
              Text(
                '₹${originalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isBold ? 18 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: isBold
                    ? AppColors.primary
                    : (isStrikethrough
                          ? AppColors.success
                          : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          _proceedToCheckout();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Proceed to Checkout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '₹${_cartProvider.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog() {
    final userId = _authProvider.user?.uid;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text(
            'Are you sure you want to remove all items from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final success = await _cartProvider.clearCart(userId);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    SnackBarService.showSuccess(context, 'Cart cleared');
                  } else {
                    SnackBarService.showError(context, 'Failed to clear cart');
                  }
                }
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _proceedToCheckout() {
    context.push('/customer/checkout');
  }
}
