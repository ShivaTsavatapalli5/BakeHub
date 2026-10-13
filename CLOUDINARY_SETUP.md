# Cloudinary Setup for BakeHub

## Overview

BakeHub uses Cloudinary to store and manage images (QR codes, product images, bakery logos). This guide will help you set up Cloudinary for your project.

## Step 1: Create Cloudinary Account

1. Go to [https://cloudinary.com/users/register/free](https://cloudinary.com/users/register/free)
2. Sign up for a free account (includes 25GB storage and 25GB bandwidth per month)
3. Verify your email address

## Step 2: Get Your Credentials

1. Log in to [Cloudinary Console](https://cloudinary.com/console)
2. You'll see your dashboard with:
   - **Cloud Name** (e.g., `dxyz123abc`)
   - **API Key**
   - **API Secret**

## Step 3: Create Upload Preset

Upload presets define how your images will be processed and stored.

1. In Cloudinary Console, go to **Settings** (gear icon)
2. Click on **Upload** tab
3. Scroll to **Upload presets** section
4. Click **Add upload preset**
5. Configure:
   - **Preset name**: `bakehub_unsigned` (or your preferred name)
   - **Signing Mode**: **Unsigned** (allows client-side uploads)
   - **Folder**: Leave empty (we set folders in code)
   - **Access Mode**: Public read
   - **Unique filename**: Enabled
   - **Overwrite**: Disabled
6. Click **Save**

## Step 4: Update Flutter Code

Open `lib/services/cloudinary_service.dart` and update these constants:

```dart
static const String _cloudName = 'YOUR_CLOUD_NAME';  // e.g., 'dxyz123abc'
static const String _uploadPreset = 'YOUR_UPLOAD_PRESET';  // e.g., 'bakehub_unsigned'
```

**Replace with your actual credentials:**

```dart
// Example:
static const String _cloudName = 'dxyz123abc';
static const String _uploadPreset = 'bakehub_unsigned';
```

## Step 5: Install Dependencies

Run in terminal:

```bash
flutter pub get
```

## Folder Structure in Cloudinary

The service automatically organizes images into folders:

```
bakehub/
├── qr-codes/       # QR code payment images
├── products/       # Product images
└── logos/          # Bakery logos
```

## Image Upload Flow

### QR Code Upload (Admin Registration)

```
User selects QR image
    ↓
Image picked from gallery
    ↓
Display preview in form
    ↓
On registration submit:
    ↓
Upload to Cloudinary → bakehub/qr-codes/
    ↓
Get secure URL (e.g., https://res.cloudinary.com/.../image.jpg)
    ↓
Save URL to Firestore bakery document
    ↓
Complete registration
```

## Testing Upload

1. Complete admin registration form
2. Upload a QR code image
3. Submit form
4. Check Cloudinary Media Library:
   - Go to [Media Library](https://cloudinary.com/console/media_library)
   - Look in `bakehub/qr-codes/` folder
   - Your uploaded image should appear

## Firestore Structure with Cloudinary URL

```javascript
// bakeries/{ownerId}
{
  qrCodeImageUrl: "https://res.cloudinary.com/YOUR_CLOUD/image/upload/v1234567890/bakehub/qr-codes/abc123.jpg",
  // ... other fields
}
```

## Advanced Features

### Image Optimization

The service includes URL transformation for optimized delivery:

```dart
String optimizedUrl = CloudinaryService.instance.getOptimizedImageUrl(
  originalUrl,
  width: 300,
  height: 300,
  quality: 'auto',
  format: 'auto',
);
```

### Upload Product Images

```dart
String productImageUrl = await CloudinaryService.instance.uploadProductImage(filePath);
```

### Upload Bakery Logo

```dart
String logoUrl = await CloudinaryService.instance.uploadBakeryLogo(filePath);
```

### Delete Images

```dart
await CloudinaryService.instance.deleteImage('bakehub/qr-codes/abc123');
```

## Security Best Practices

1. **Use Unsigned Upload Presets** for client-side uploads
2. **Set Access Control** to restrict who can view images
3. **Enable Unique Filenames** to prevent overwrites
4. **Set File Size Limits** in upload preset (e.g., max 5MB)
5. **Use HTTPS URLs** (Cloudinary provides secure URLs by default)

## Cloudinary Free Tier Limits

- 25 GB storage
- 25 GB bandwidth/month
- 25 credits/month for transformations
- Unlimited transformations for free tier features

Perfect for development and small-scale production!

## Troubleshooting

### Error: "Invalid cloud name"

- Double-check your cloud name in cloudinary_service.dart
- Cloud name is case-sensitive

### Error: "Invalid upload preset"

- Verify upload preset name matches exactly
- Ensure preset is set to "Unsigned" mode
- Check preset is not disabled

### Error: "File upload failed"

- Check internet connection
- Verify file path is correct
- Check file size (free tier has limits)
- Ensure file is a valid image format (JPG, PNG, etc.)

### Images not appearing in Cloudinary

- Check Media Library → All folders
- Search by upload date
- Verify folder path in code matches your setup

## Environment Variables (Optional)

For better security in production, use environment variables:

1. Create `.env` file (add to .gitignore):

```
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_preset
```

2. Use `flutter_dotenv` package to load credentials
3. Never commit credentials to Git

## Support

- Cloudinary Documentation: [https://cloudinary.com/documentation](https://cloudinary.com/documentation)
- Community Forum: [https://community.cloudinary.com](https://community.cloudinary.com)
- Support: [https://support.cloudinary.com](https://support.cloudinary.com)
