import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bakehub/constants/app_colors.dart';
import 'package:bakehub/models/product.dart';
import 'package:bakehub/models/category.dart';
import 'package:bakehub/services/product_service.dart';
import 'package:bakehub/services/category_service.dart';
import 'package:bakehub/services/cloudinary_service.dart';
import 'package:bakehub/services/snackbar_services.dart';
import 'package:bakehub/widgets/custom_text_field.dart';
import 'package:bakehub/widgets/custom_button.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedImagePaths = [];
  Category? _selectedCategory;
  List<Category> _categories = [];
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isUploadingImages = false;
  bool _isLoadingCategories = true;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final categories = await CategoryService.instance.getCategoriesAsFuture();

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });

        if (categories.isEmpty) {
          SnackBarService.showWarning(
            context,
            'No categories found. Please add categories first.',
          );
        } else if (!_isInitialLoad) {
          // Only show success message on manual refresh
          SnackBarService.showSuccess(
            context,
            '${categories.length} ${categories.length == 1 ? "category" : "categories"} loaded',
          );
        }

        _isInitialLoad = false;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        SnackBarService.showError(
          context,
          'Failed to load categories: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      // Check permission
      final permissionStatus = await Permission.photos.request();

      if (!permissionStatus.isGranted) {
        if (mounted) {
          SnackBarService.showWarning(context, 'Gallery permission required');
        }
        return;
      }

      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);

      if (images.isNotEmpty) {
        setState(() {
          _selectedImagePaths.addAll(images.map((e) => e.path));
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'Failed to select images');
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final permissionStatus = await Permission.camera.request();

      if (!permissionStatus.isGranted) {
        if (mounted) {
          SnackBarService.showWarning(context, 'Camera permission required');
        }
        return;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImagePaths.add(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'Failed to take photo');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImagePaths.removeAt(index);
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Product name is required';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    if (value.length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Enter a valid price';
    }
    return null;
  }

  String? _validateStock(String? value) {
    if (value == null || value.isEmpty) {
      return 'Stock is required';
    }
    final stock = int.tryParse(value);
    if (stock == null || stock < 0) {
      return 'Enter a valid stock quantity';
    }
    return null;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      SnackBarService.showWarning(context, 'Please select a category');
      return;
    }

    if (_selectedImagePaths.isEmpty) {
      SnackBarService.showWarning(
        context,
        'Please add at least one product image',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload images to Cloudinary
      setState(() => _isUploadingImages = true);
      SnackBarService.showLoading(context, 'Uploading images...');

      final imageUrls = await CloudinaryService.instance.uploadMultipleImages(
        _selectedImagePaths,
        folder: 'bakehub/products',
      );

      setState(() => _isUploadingImages = false);
      SnackBarService.hide(context);

      // Create product object
      final product = Product(
        id: '', // Firestore will generate
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        imageUrls: imageUrls,
        stock: int.parse(_stockController.text.trim()),
        isAvailable: _isAvailable,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await ProductService().createProduct(product);

      if (mounted) {
        SnackBarService.showSuccess(
          context,
          '${_nameController.text.trim()} added successfully!',
        );
        Navigator.pop(context);
      }
    } on SocketException {
      if (mounted) {
        SnackBarService.showError(
          context,
          'No internet connection. Please check your network.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(
          context,
          'Failed to add product: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImages = false;
        });
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoadingCategories ? null : _loadCategories,
            icon: _isLoadingCategories
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh categories',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Images Section
                  _buildImageSection(),

                  const SizedBox(height: 24),

                  // Product Name
                  CustomTextField(
                    label: 'Product Name',
                    hint: 'e.g., Chocolate Cake',
                    controller: _nameController,
                    prefixIcon: const Icon(
                      Icons.bakery_dining,
                      color: AppColors.primary,
                    ),
                    validator: _validateName,
                  ),

                  const SizedBox(height: 16),

                  // Description
                  CustomTextField(
                    label: 'Description',
                    hint: 'Describe your product',
                    controller: _descriptionController,
                    maxLines: 4,
                    prefixIcon: const Icon(
                      Icons.description,
                      color: AppColors.primary,
                    ),
                    validator: _validateDescription,
                  ),

                  const SizedBox(height: 16),

                  // Category Dropdown
                  _buildCategoryDropdown(),

                  const SizedBox(height: 16),

                  // Price and Stock Row
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Price',
                          hint: '0.00',
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefixIcon: const Icon(
                            Icons.attach_money,
                            color: AppColors.primary,
                          ),
                          validator: _validatePrice,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: 'Stock',
                          hint: '0',
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(
                            Icons.inventory,
                            color: AppColors.primary,
                          ),
                          validator: _validateStock,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Availability Switch
                  Card(
                    child: SwitchListTile(
                      title: const Text('Available for sale'),
                      subtitle: Text(
                        _isAvailable
                            ? 'Customers can order this product'
                            : 'Hidden from customers',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isAvailable ? Colors.green : Colors.grey,
                        ),
                      ),
                      value: _isAvailable,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() => _isAvailable = value);
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  CustomButton(
                    text: 'Add Product',
                    onPressed: _isLoading ? null : _saveProduct,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Upload Progress Overlay
          if (_isUploadingImages)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Uploading images...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Product Images',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.add_photo_alternate, color: AppColors.primary),
                  label: const Text('Add Images',style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedImagePaths.isEmpty)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No images selected',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImagePaths.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_selectedImagePaths[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (_isLoadingCategories)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_categories.isEmpty)
              TextButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _isLoadingCategories || _categories.isEmpty
                ? Colors.grey[100]
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedCategory == null && !_isLoadingCategories
                  ? Colors.grey[300]!
                  : AppColors.divider,
            ),
          ),
          child: _isLoadingCategories
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Loading categories...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : _categories.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No categories available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<Category>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: Text(
                      'Select Category (${_categories.length} available)',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primary,
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<Category>(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            if (category.productCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${category.productCount}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (Category? value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      if (value != null) {
                        SnackBarService.showInfo(
                          context,
                          'Category: ${value.name}',
                        );
                      }
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
