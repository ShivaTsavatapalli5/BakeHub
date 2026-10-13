# App Settings Configuration

This project uses real-time app settings from Firebase Firestore for tax, delivery fees, and free delivery thresholds.

## Firestore Structure

Create a collection called `settings` with a document `app_settings` containing:

```json
{
  "taxPercent": 5.0,
  "deliveryFee": 50.0,
  "freeDeliveryMinAmount": 500.0
}
```

## Firebase Console Setup

1. Go to Firebase Console → Firestore Database
2. Create a new collection: `settings`
3. Create a document with ID: `app_settings`
4. Add the following fields:
   - `taxPercent` (number): 5.0 (represents 5% GST)
   - `deliveryFee` (number): 50.0 (delivery charge in rupees)
   - `freeDeliveryMinAmount` (number): 500.0 (minimum order for free delivery)

## Features

### Dynamic Tax Calculation

- Tax percentage is fetched from Firebase in real-time
- Changes to tax in Firebase reflect immediately in the app
- Default: 5% GST

### Dynamic Delivery Fee

- Delivery fee is fetched from Firebase in real-time
- Automatically set to ₹0 when order reaches minimum amount
- Default: ₹50

### Free Delivery

- Configurable minimum purchase amount for free delivery
- Shows helpful message: "Add ₹X more to get FREE delivery!"
- Shows success message when free delivery is achieved
- Strikethrough original delivery fee when free

## How It Works

1. **Settings Service** (`services/settings_service.dart`)
   - Fetches settings from Firestore in real-time
   - Provides stream and one-time fetch methods
   - Returns default values if Firebase data unavailable

2. **Cart Provider** (`provider/cart_provider.dart`)
   - Listens to settings changes
   - Automatically recalculates cart totals
   - Determines free delivery eligibility

3. **Cart Screen** (`screen/customer/customer_cart_screen.dart`)
   - Displays real-time tax percentage in label
   - Shows free delivery progress note
   - Highlights when free delivery is achieved

## Updating Settings

Settings can be updated directly in Firebase Console:

1. Go to Firestore Database
2. Navigate to `settings/app_settings`
3. Edit any field
4. Changes reflect immediately in all active user sessions

## Admin Panel (Future Enhancement)

You can create an admin screen to update these values:

```dart
final settingsService = SettingsService.instance;
await settingsService.updateSettings(
  AppSettings(
    taxPercent: 8.0,
    deliveryFee: 60.0,
    freeDeliveryMinAmount: 600.0,
  ),
);
```

## Default Values

If Firebase is unavailable or settings don't exist:

- Tax: 5% GST
- Delivery Fee: ₹50
- Free Delivery Minimum: ₹500
