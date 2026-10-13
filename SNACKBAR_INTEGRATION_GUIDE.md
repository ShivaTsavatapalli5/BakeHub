# BakeHub Snackbar Service Integration Guide

## Your Snackbar Service

Location: `lib/services/snackbar_services.dart`

### Available Methods

```dart
// Success message (green)
SnackBarService.showSuccess(context, 'Operation successful!');

// Error message (red)
SnackBarService.showError(context, 'Something went wrong!');

// Info message (blue)
SnackBarService.showInfo(context, 'Information message');

// Warning message (orange)
SnackBarService.showWarning(context, 'Warning message');

// Loading message (stays until hidden)
SnackBarService.showLoading(context, 'Processing...');

// Hide current snackbar
SnackBarService.hide(context);

// Custom with primary color
SnackBarService.show(context, 'Custom message', icon: Icons.star);
```

---

## Integration Examples by Screen

### 1. LOGIN SCREEN (`lib/screen/auth/login_screen.dart`)

**Import at the top:**

```dart
import 'package:bakehub/services/snackbar_services.dart';
```

**Usage in \_handleLogin() - Line ~85:**

```dart
(error) async {
  // Error callback - show error message
  if (mounted) {
    setState(() => _isLoginLoading = false);
    SnackBarService.showError(context, error); // Add this
  }
},
```

**Email not verified (add after role check):**

```dart
if (!authProvider.currentUser!.emailVerified) {
  SnackBarService.showWarning(
    context,
    'Please verify your email to continue',
  );
  return;
}
```

**Success message (in success callback):**

```dart
() async {
  // Success callback - navigate based on user role
  if (mounted) {
    SnackBarService.showSuccess(context, 'Login successful!'); // Add this
    try {
      final role = await DBServices.instance.getUserRole(
        authProvider.currentUserId!,
      );
      // ... rest of code
    }
  }
},
```

---

### 2. ADD PRODUCT SCREEN (`lib/screen/admin/add_product_screen.dart`)

**Import at the top:**

```dart
import 'package:bakehub/services/snackbar_services.dart';
```

**Line ~57 - Category loading error:**

```dart
} catch (e) {
  if (mounted) {
    SnackBarService.showError(context, 'Failed to load categories');
  }
}
```

**Line ~71 - Photo permission denied:**

```dart
if (!permissionStatus.isGranted) {
  if (mounted) {
    SnackBarService.showWarning(context, 'Gallery permission required');
  }
  return;
}
```

**Line ~85 - Image picker error:**

```dart
} catch (e) {
  if (mounted) {
    SnackBarService.showError(context, 'Failed to select images');
  }
}
```

**Line ~96 - Camera permission denied:**

```dart
if (!permissionStatus.isGranted) {
  if (mounted) {
    SnackBarService.showWarning(context, 'Camera permission required');
  }
  return;
}
```

**Line ~112 - Camera error:**

```dart
} catch (e) {
  if (mounted) {
    SnackBarService.showError(context, 'Failed to take photo');
  }
}
```

**Line ~175 - No category selected:**

```dart
if (_selectedCategory == null) {
  SnackBarService.showWarning(context, 'Please select a category');
  return;
}
```

**Line ~180 - No images selected:**

```dart
if (_selectedImagePaths.isEmpty) {
  SnackBarService.showWarning(context, 'Please add at least one product image');
  return;
}
```

**Line ~186 - Show uploading:**

```dart
setState(() => _isUploadingImages = true);
SnackBarService.showLoading(context, 'Uploading images...');

final imageUrls = await CloudinaryService.instance.uploadMultipleImages(
  _selectedImagePaths,
  folder: 'bakehub/products',
);

setState(() => _isUploadingImages = false);
SnackBarService.hide(context); // Hide loading
```

**Line ~211 - Success:**

```dart
if (mounted) {
  SnackBarService.showSuccess(
    context,
    '${_nameController.text} added successfully!',
  );
  Navigator.pop(context);
}
```

**Line ~215 - Network error:**

```dart
} on SocketException {
  if (mounted) {
    SnackBarService.showError(
      context,
      'No internet connection. Please check your network.',
    );
  }
}
```

**Line ~221 - General error:**

```dart
} catch (e) {
  if (mounted) {
    SnackBarService.showError(
      context,
      'Failed to add product: ${e.toString()}',
    );
  }
}
```

---

### 3. ADMIN CATEGORIES SCREEN (`lib/screen/admin/admin_categories_screen.dart`)

**Import at the top:**

```dart
import 'package:bakehub/services/snackbar_services.dart';
```

**Line ~332 - Category added successfully:**

```dart
if (context.mounted) {
  Navigator.pop(context);
  SnackBarService.showSuccess(
    context,
    'Category "${nameController.text}" added successfully',
  );
}
```

**Line ~336 - Category add error:**

```dart
} catch (e) {
  if (context.mounted) {
    SnackBarService.showError(
      context,
      'Failed to add category: ${e.toString()}',
    );
  }
}
```

**Similar pattern for edit/update category:**

```dart
SnackBarService.showSuccess(
  context,
  'Category updated successfully',
);
```

**For delete:**

```dart
SnackBarService.showInfo(
  context,
  'Category deleted',
);
```

---

### 4. ADMIN REGISTER SCREEN (`lib/screen/auth/admin_register_screen.dart`)

**Import at the top:**

```dart
import 'package:bakehub/services/snackbar_services.dart';
```

**Line ~363 - Terms not agreed:**

```dart
if (!_agreeToTerms) {
  SnackBarService.showWarning(
    context,
    'Please agree to terms and conditions',
  );
  return;
}
```

**Line ~368 - No payment method:**

```dart
if (!_cashOnDelivery && !_qrCodePayment && !_upiIdPayment) {
  SnackBarService.showWarning(
    context,
    'Please select at least one payment method',
  );
  return;
}
```

**Line ~374 - No QR code:**

```dart
if (_qrCodePayment && _qrCodeImagePath == null) {
  SnackBarService.showWarning(
    context,
    'Please upload QR code for QR payment',
  );
  return;
}
```

**Line ~380 - No UPI ID:**

```dart
if (_upiIdPayment && _upiIdController.text.trim().isEmpty) {
  SnackBarService.showWarning(
    context,
    'Please enter UPI ID for UPI payment',
  );
  return;
}
```

**Line ~394 - QR upload starting:**

```dart
if (mounted) {
  SnackBarService.showLoading(context, 'Uploading QR code...');
}
```

**Line ~402 - Network error during upload:**

```dart
} on SocketException catch (e) {
  print('Socket exception during upload: $e');
  if (mounted) {
    SnackBarService.hide(context);
    SnackBarService.showError(
      context,
      'No internet connection. Please try again.',
    );
    setState(() => _isLoading = false);
    return;
  }
}
```

**Line ~413 - Upload error:**

```dart
} catch (e) {
  print('Error uploading QR code: $e');
  if (mounted) {
    SnackBarService.hide(context);
    SnackBarService.showError(
      context,
      'Failed to upload QR code: ${e.toString()}',
    );
    setState(() => _isLoading = false);
    return;
  }
}
```

**Registration success:**

```dart
SnackBarService.hide(context); // Hide any loading
SnackBarService.showSuccess(
  context,
  'Registration successful! Please verify your email.',
);
```

**Registration error:**

```dart
SnackBarService.showError(
  context,
  'Registration failed: ${error.toString()}',
);
```

---

### 5. PRODUCT DETAIL SCREEN (`lib/screen/customer/product_detail_screen.dart`)

**Import at the top:**

```dart
import 'package:bakehub/services/snackbar_services.dart';
```

**Line ~350 - Add to cart:**

```dart
void _addToCart() {
  SnackBarService.showSuccess(
    context,
    'Added to cart',
  );
  // TODO: Add cart logic
}
```

---

### 6. EDIT PRODUCT SCREEN (`lib/screen/admin/edit_product_screen.dart`)

**Import at the top:**

```dart
import 'package:bakehub/services/snackbar_services.dart';
```

**Update button handler:**

```dart
onPressed: () async {
  try {
    // TODO: Update product with edited data
    SnackBarService.showSuccess(
      context,
      'Product updated successfully',
    );
    Navigator.pop(context);
  } catch (e) {
    SnackBarService.showError(
      context,
      'Failed to update product: ${e.toString()}',
    );
  }
},
```

---

## Common Patterns

### Pattern 1: Form Validation

```dart
if (!_formKey.currentState!.validate()) {
  SnackBarService.showWarning(context, 'Please fill all required fields');
  return;
}
```

### Pattern 2: Network Operations

```dart
try {
  SnackBarService.showLoading(context, 'Processing...');

  await someNetworkOperation();

  SnackBarService.hide(context);
  SnackBarService.showSuccess(context, 'Operation successful!');

} on SocketException {
  SnackBarService.showError(
    context,
    'No internet connection. Please check your network.',
  );
} catch (e) {
  SnackBarService.showError(
    context,
    'Failed: ${e.toString()}',
  );
}
```

### Pattern 3: Image Upload

```dart
setState(() => _isUploadingImages = true);
SnackBarService.showLoading(context, 'Uploading images...');

try {
  final urls = await CloudinaryService.instance.uploadMultipleImages(paths);

  SnackBarService.hide(context);
  SnackBarService.showSuccess(context, 'Images uploaded successfully');

} catch (e) {
  SnackBarService.hide(context);
  SnackBarService.showError(context, 'Failed to upload images');
} finally {
  setState(() => _isUploadingImages = false);
}
```

### Pattern 4: Permission Denied

```dart
if (!permissionStatus.isGranted) {
  if (mounted) {
    SnackBarService.showWarning(
      context,
      'Permission required to access this feature',
    );
  }
  return;
}
```

### Pattern 5: Delete Operations

```dart
SnackBarService.showInfo(
  context,
  'Item deleted',
);
```

### Pattern 6: Settings Updated

```dart
SnackBarService.showSuccess(
  context,
  'Settings saved successfully',
);
```

---

## Quick Reference Table

| Situation        | Method        | Example               |
| ---------------- | ------------- | --------------------- |
| Success action   | `showSuccess` | Product added         |
| Failed action    | `showError`   | Upload failed         |
| Warning/Alert    | `showWarning` | Permission denied     |
| General info     | `showInfo`    | Item deleted          |
| During operation | `showLoading` | Uploading...          |
| Stop loading     | `hide`        | After async completes |

---

## Important Notes

1. **Always pass context**: Your service requires `BuildContext` as the first parameter

2. **Check if mounted**: Before showing snackbars in async callbacks:

   ```dart
   if (mounted) {
     SnackBarService.showSuccess(context, 'Done!');
   }
   ```

3. **Hide loading**: Always hide loading snackbars when operation completes:

   ```dart
   SnackBarService.showLoading(context, 'Processing...');
   try {
     await operation();
     SnackBarService.hide(context); // Important!
   } catch (e) {
     SnackBarService.hide(context); // Also here!
   }
   ```

4. **Duration parameter**: Available for all methods except `showLoading`:

   ```dart
   SnackBarService.showSuccess(
     context,
     'Quick message',
     duration: const Duration(seconds: 2),
   );
   ```

5. **Auto-dismiss**: Your service provides a "Dismiss" button automatically

---

## Testing Checklist

- [ ] Login success/failure messages
- [ ] Registration validation errors
- [ ] Product add success
- [ ] Image upload progress
- [ ] Network error handling
- [ ] Permission denied warnings
- [ ] Category add/edit/delete
- [ ] Form validation messages
- [ ] Settings save confirmation

---

**Ready to implement!** Start with login screen, then move to product management. 🚀
