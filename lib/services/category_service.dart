import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bakehub/models/category.dart';

class CategoryService {
  static CategoryService instance = CategoryService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';

  /// Get all active categories
  Stream<List<Category>> getAllCategories() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Category.fromJson(data);
          }).toList();
        });
  }

  /// Get all categories (admin view)
  Stream<List<Category>> getAllCategoriesAdmin() {
    return _firestore
        .collection(_collection)
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Category.fromJson(data);
          }).toList();
        });
  }

  /// Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(categoryId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Category.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  /// Create category
  Future<String> createCategory(Category category) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(category.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update category
  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(categoryId).update(data);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection(_collection).doc(categoryId).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Get categories as future (for dropdown)
  Future<List<Category>> getCategoriesAsFuture() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Category.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }
}
