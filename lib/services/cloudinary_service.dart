import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static CloudinaryService instance = CloudinaryService();

  static const String _cloudName = 'dir5b6t9h';
  static const String _uploadPreset = 'unsigned';

  late CloudinaryPublic _cloudinary;

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  /// Upload QR code image to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String> uploadQrCodeImage(String filePath) async {
    try {
      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Upload to Cloudinary
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: 'bakehub/qr-codes',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Return the secure URL
      return response.secureUrl;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }

  /// Upload multiple images to Cloudinary
  /// Returns list of secure URLs
  Future<List<String>> uploadMultipleImages(
    List<String> filePaths, {
    String folder = 'bakehub',
  }) async {
    try {
      List<String> urls = [];

      for (String filePath in filePaths) {
        final file = File(filePath);

        if (!await file.exists()) {
          print('Skipping non-existent file: $filePath');
          continue;
        }

        CloudinaryResponse response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            filePath,
            folder: folder,
            resourceType: CloudinaryResourceType.Image,
          ),
        );

        urls.add(response.secureUrl);
      }

      return urls;
    } catch (e) {
      print('Error uploading multiple images: $e');
      rethrow;
    }
  }

  /// Delete image from Cloudinary by public ID
  // Future<void> deleteImage(String publicId) async {
  //   try {
  //     await _cloudinary.destroy(publicId,);
  //   } catch (e) {
  //     print('Error deleting from Cloudinary: $e');
  //     rethrow;
  //   }
  // }

  /// Upload product image
  Future<String> uploadProductImage(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: 'bakehub/products',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      print('Error uploading product image: $e');
      rethrow;
    }
  }

  /// Upload bakery logo
  Future<String> uploadBakeryLogo(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: 'bakehub/logos',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      print('Error uploading logo: $e');
      rethrow;
    }
  }

  /// Upload category image
  Future<String> uploadCategoryImage(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: 'bakehub/categories',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      print('Error uploading category image: $e');
      rethrow;
    }
  }

  /// Upload payment proof screenshot
  Future<String> uploadPaymentProof(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: 'bakehub/payment_proofs',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      print('Error uploading payment proof: $e');
      rethrow;
    }
  }

  /// Get optimized image URL with transformations
  String getOptimizedImageUrl(
    String imageUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    // Extract public ID from URL
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;

    // Find version and public ID
    int uploadIndex = pathSegments.indexOf('upload');
    if (uploadIndex == -1) return imageUrl;

    // Build transformation string
    String transformation = 'q_$quality,f_$format';
    if (width != null) transformation += ',w_$width';
    if (height != null) transformation += ',h_$height';

    // Reconstruct URL with transformations
    List<String> newSegments = List.from(pathSegments);
    newSegments.insert(uploadIndex + 1, transformation);

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      pathSegments: newSegments,
    ).toString();
  }
}
