import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bakehub/models/cart.dart';
import 'package:bakehub/models/product.dart';

class CartService {
  static final CartService instance = CartService._();
  CartService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'carts';

  // Get user's cart as a stream
  Stream<Cart?> getCartStream(String userId) {
    return _firestore.collection(_collection).doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        return Cart(userId: userId, items: [], createdAt: DateTime.now());
      }
      return Cart.fromJson(snapshot.data()!);
    });
  }

  // Get user's cart once
  Future<Cart?> getCart(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists || doc.data() == null) {
        return Cart(userId: userId, items: [], createdAt: DateTime.now());
      }
      return Cart.fromJson(doc.data()!);
    } catch (e) {
      print('Error getting cart: $e');
      return null;
    }
  }

  // Add item to cart
  Future<bool> addToCart({
    required String userId,
    required Product product,
    int quantity = 1,
  }) async {
    try {
      final cart = await getCart(userId);
      if (cart == null) return false;

      final existingItemIndex = cart.items.indexWhere(
        (item) => item.productId == product.id,
      );

      List<CartItem> updatedItems = List.from(cart.items);

      if (existingItemIndex >= 0) {
        // Update quantity if item exists
        final existingItem = updatedItems[existingItemIndex];
        updatedItems[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        );
      } else {
        // Add new item
        updatedItems.add(
          CartItem(
            id: '${product.id}_${DateTime.now().millisecondsSinceEpoch}',
            productId: product.id,
            productName: product.name,
            productPrice: product.price,
            productImage: product.imageUrls.isNotEmpty
                ? product.imageUrls.first
                : null,
            quantity: quantity,
            addedAt: DateTime.now(),
          ),
        );
      }

      final updatedCart = cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(updatedCart.toJson());

      return true;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }

  // Update item quantity
  Future<bool> updateQuantity({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    try {
      final cart = await getCart(userId);
      if (cart == null) return false;

      final updatedItems = cart.items.map((item) {
        if (item.productId == productId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();

      final updatedCart = cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(updatedCart.toJson());

      return true;
    } catch (e) {
      print('Error updating quantity: $e');
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeFromCart({
    required String userId,
    required String productId,
  }) async {
    try {
      final cart = await getCart(userId);
      if (cart == null) return false;

      final updatedItems = cart.items
          .where((item) => item.productId != productId)
          .toList();

      final updatedCart = cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(updatedCart.toJson());

      return true;
    } catch (e) {
      print('Error removing from cart: $e');
      return false;
    }
  }

  // Clear cart
  Future<bool> clearCart(String userId) async {
    try {
      final emptyCart = Cart(
        userId: userId,
        items: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(emptyCart.toJson());

      return true;
    } catch (e) {
      print('Error clearing cart: $e');
      return false;
    }
  }

  // Get cart item count
  Future<int> getCartItemCount(String userId) async {
    try {
      final cart = await getCart(userId);
      return cart?.itemCount ?? 0;
    } catch (e) {
      print('Error getting cart count: $e');
      return 0;
    }
  }
}
