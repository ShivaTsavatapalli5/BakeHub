import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bakehub/models/cart.dart';
import 'package:bakehub/models/product.dart';
import 'package:bakehub/models/app_settings.dart';
import 'package:bakehub/services/cart_service.dart';
import 'package:bakehub/services/settings_service.dart';

class CartProvider extends ChangeNotifier {
  static final CartProvider instance = CartProvider._();
  CartProvider._();

  final CartService _cartService = CartService.instance;
  final SettingsService _settingsService = SettingsService.instance;

  Cart? _cart;
  AppSettings _settings = AppSettings.defaultSettings();
  StreamSubscription? _cartSubscription;
  StreamSubscription? _settingsSubscription;
  bool _isLoading = false;

  Cart? get cart => _cart;
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  int get itemCount => _cart?.itemCount ?? 0;
  double get subtotal => _cart?.subtotal ?? 0;

  double get deliveryCharge {
    if (subtotal >= _settings.freeDeliveryMinAmount) {
      return 0;
    }
    return _settings.deliveryFee;
  }

  double get tax => subtotal * (_settings.taxPercent / 100);

  double get total => subtotal + deliveryCharge + tax;

  bool get isEmpty => _cart?.isEmpty ?? true;

  bool get isFreeDeliveryEligible =>
      subtotal >= _settings.freeDeliveryMinAmount;

  double get amountForFreeDelivery {
    final remaining = _settings.freeDeliveryMinAmount - subtotal;
    return remaining > 0 ? remaining : 0;
  }

  // Initialize cart and settings subscriptions for a user
  void initializeCart(String userId) {
    _cartSubscription?.cancel();
    _settingsSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    // Listen to settings changes
    _settingsSubscription = _settingsService.getSettingsStream().listen(
      (settings) {
        _settings = settings;
        print(
          '📊 Settings updated: Tax=${settings.taxPercent}%, Delivery=₹${settings.deliveryFee}, FreeAt=₹${settings.freeDeliveryMinAmount}',
        );
        notifyListeners();
      },
      onError: (error) {
        print('❌ Settings stream error: $error');
        _settings = AppSettings.defaultSettings();
        notifyListeners();
      },
    );

    // Listen to cart changes
    _cartSubscription = _cartService
        .getCartStream(userId)
        .listen(
          (cart) {
            _cart = cart;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            print('❌ Cart stream error: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Add item to cart
  Future<bool> addToCart({
    required String userId,
    required Product product,
    int quantity = 1,
  }) async {
    final success = await _cartService.addToCart(
      userId: userId,
      product: product,
      quantity: quantity,
    );
    return success;
  }

  // Update quantity
  Future<bool> updateQuantity({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    final success = await _cartService.updateQuantity(
      userId: userId,
      productId: productId,
      quantity: quantity,
    );
    return success;
  }

  // Remove from cart
  Future<bool> removeFromCart({
    required String userId,
    required String productId,
  }) async {
    final success = await _cartService.removeFromCart(
      userId: userId,
      productId: productId,
    );
    return success;
  }

  // Clear cart
  Future<bool> clearCart(String userId) async {
    final success = await _cartService.clearCart(userId);
    return success;
  }

  // Get item quantity in cart
  int getItemQuantity(String productId) {
    if (_cart == null) return 0;
    final item = _cart!.items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        id: '',
        productId: '',
        productName: '',
        productPrice: 0,
        quantity: 0,
        addedAt: DateTime.now(),
      ),
    );
    return item.quantity;
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    if (_cart == null) return false;
    return _cart!.items.any((item) => item.productId == productId);
  }

  // Dispose
  void disposeCart() {
    _cartSubscription?.cancel();
    _settingsSubscription?.cancel();
    _cart = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
