import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bakehub/models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  Future<String> createProduct(Product product) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(product.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Stream<List<Product>> getAllProducts() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Product.fromJson(data);
          }).toList();
        });
  }

  Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(productId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  Stream<Product?> getProductByIdStream(String productId) {
    return _firestore.collection(_collection).doc(productId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Product.fromJson(data);
      }
      return null;
    });
  }

  Stream<List<Product>> getProductsByCategory(String categoryId) {
    return _firestore
        .collection(_collection)
        .where('categoryId', isEqualTo: categoryId)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Product.fromJson(data);
          }).toList();
        });
  }

  Stream<List<Product>> getAvailableProducts() {
    return _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .where('stock', isGreaterThan: 0)
        .orderBy('stock')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Product.fromJson(data);
          }).toList();
        });
  }

  Stream<List<Product>> getLowStockProducts() {
    return _firestore
        .collection(_collection)
        .where('stock', isLessThan: 5)
        .where('stock', isGreaterThan: 0)
        .orderBy('stock')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Product.fromJson(data);
          }).toList();
        });
  }

  Stream<List<Product>> getOutOfStockProducts() {
    return _firestore
        .collection(_collection)
        .where('stock', isEqualTo: 0)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Product.fromJson(data);
          }).toList();
        });
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isAvailable', isEqualTo: true)
          .get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();

      return products
          .where(
            (product) =>
                product.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  Future<void> updateProduct(String productId, Product product) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(productId)
          .update(product.toJson());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Update product stock
  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _firestore.collection(_collection).doc(productId).update({
        'stock': newStock,
        'isAvailable': newStock > 0,
      });
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  /// Increase stock (for restocking)
  Future<void> increaseStock(String productId, int quantity) async {
    try {
      final doc = await _firestore.collection(_collection).doc(productId).get();
      if (doc.exists) {
        final currentStock = doc.data()?['stock'] as int? ?? 0;
        final newStock = currentStock + quantity;
        await updateStock(productId, newStock);
      }
    } catch (e) {
      throw Exception('Failed to increase stock: $e');
    }
  }

  /// Decrease stock (for orders)
  Future<void> decreaseStock(String productId, int quantity) async {
    try {
      final doc = await _firestore.collection(_collection).doc(productId).get();
      if (doc.exists) {
        final currentStock = doc.data()?['stock'] as int? ?? 0;
        final newStock = (currentStock - quantity).clamp(0, currentStock);
        await updateStock(productId, newStock);
      }
    } catch (e) {
      throw Exception('Failed to decrease stock: $e');
    }
  }

  /// Update product availability
  Future<void> updateAvailability(String productId, bool isAvailable) async {
    try {
      await _firestore.collection(_collection).doc(productId).update({
        'isAvailable': isAvailable,
      });
    } catch (e) {
      throw Exception('Failed to update availability: $e');
    }
  }

  /// Update product price
  Future<void> updatePrice(String productId, double newPrice) async {
    try {
      await _firestore.collection(_collection).doc(productId).update({
        'price': newPrice,
      });
    } catch (e) {
      throw Exception('Failed to update price: $e');
    }
  }

  /// Update product images
  Future<void> updateImages(String productId, List<String> imageUrls) async {
    try {
      await _firestore.collection(_collection).doc(productId).update({
        'imageUrls': imageUrls,
      });
    } catch (e) {
      throw Exception('Failed to update images: $e');
    }
  }

  // ========== DELETE ==========

  /// Delete product (soft delete - mark as unavailable)
  Future<void> softDeleteProduct(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).update({
        'isAvailable': false,
      });
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Permanently delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to permanently delete product: $e');
    }
  }

  // ========== INVENTORY MANAGEMENT ==========

  /// Get inventory summary
  Future<Map<String, dynamic>> getInventorySummary() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      int totalProducts = snapshot.docs.length;
      int availableProducts = 0;
      int lowStockProducts = 0;
      int outOfStockProducts = 0;
      int totalStockUnits = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final stock = data['stock'] as int? ?? 0;
        final isAvailable = data['isAvailable'] as bool? ?? false;

        totalStockUnits += stock;

        if (isAvailable && stock > 0) {
          availableProducts++;
        }

        if (stock < 5 && stock > 0) {
          lowStockProducts++;
        }

        if (stock == 0) {
          outOfStockProducts++;
        }
      }

      return {
        'totalProducts': totalProducts,
        'availableProducts': availableProducts,
        'lowStockProducts': lowStockProducts,
        'outOfStockProducts': outOfStockProducts,
        'totalStockUnits': totalStockUnits,
      };
    } catch (e) {
      throw Exception('Failed to get inventory summary: $e');
    }
  }

  /// Batch update stock (for multiple products)
  Future<void> batchUpdateStock(Map<String, int> stockUpdates) async {
    try {
      final batch = _firestore.batch();

      for (var entry in stockUpdates.entries) {
        final productId = entry.key;
        final newStock = entry.value;
        final docRef = _firestore.collection(_collection).doc(productId);
        batch.update(docRef, {'stock': newStock, 'isAvailable': newStock > 0});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update stock: $e');
    }
  }

  // ========== STATISTICS ==========

  /// Get products count by category
  Future<Map<String, int>> getProductCountByCategory() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final Map<String, int> categoryCounts = {};

      for (var doc in snapshot.docs) {
        final categoryId = doc.data()['categoryId'] as String?;
        if (categoryId != null) {
          categoryCounts[categoryId] = (categoryCounts[categoryId] ?? 0) + 1;
        }
      }

      return categoryCounts;
    } catch (e) {
      throw Exception('Failed to get product count by category: $e');
    }
  }
}
