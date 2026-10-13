# Location Feature - Implementation Guide

## Overview

Added GPS location capture functionality to the checkout screen. Users can now get their current location coordinates (latitude and longitude) which are required for order placement.

## Changes Made

### 1. **Dependencies Added**

- **geolocator: ^11.0.0** - For getting device GPS location
- Already had: **permission_handler: ^11.3.1** - For requesting location permissions

### 2. **Checkout Screen Updates** (customer_checkout_screen.dart)

#### New Imports:

```dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
```

#### New Controllers:

```dart
final TextEditingController _latitudeController = TextEditingController();
final TextEditingController _longitudeController = TextEditingController();
```

#### New State Variable:

```dart
bool _isFetchingLocation = false;
```

#### New UI Section - Location Capture:

- **Location Badge**: Shows "Location (Required)" with location icon
- **"Use Location" Button**:
  - Click to get current GPS coordinates
  - Shows loading indicator while fetching
  - Disabled during fetch operation
- **Latitude Field**: Read-only field displaying captured latitude (6 decimal places)
- **Longitude Field**: Read-only field displaying captured longitude (6 decimal places)
- **Required Validation**: Both fields must have values to place order

#### New Function - `_getCurrentLocation()`:

1. **Permission Check**:
   - Checks if location permission is granted
   - Requests permission if denied
   - Shows error if user denies permission

2. **Location Service Check**:
   - Verifies GPS/location service is enabled
   - Shows error message if disabled

3. **Fetch Location**:
   - Uses `Geolocator.getCurrentPosition()` with high accuracy
   - Updates latitude and longitude controllers
   - Shows success message

4. **Error Handling**:
   - Catches and logs errors
   - Shows user-friendly error messages via SnackBar

#### Address Object Update:

Now includes latitude and longitude from captured location:

```dart
latitude: double.tryParse(_latitudeController.text),
longitude: double.tryParse(_longitudeController.text),
```

### 3. **Android Permissions** (AndroidManifest.xml)

Added location permissions:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### 4. **iOS Permissions** (Info.plist)

Added location usage descriptions:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to provide accurate delivery address.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs your location to provide accurate delivery address.</string>
```

## User Flow

### Placing an Order with Location:

1. **Fill Delivery Details**:
   - Enter name, phone, street address, city, state, PIN code
   - Optionally add landmark

2. **Capture Location** (Required):
   - Click "Use Location" button
   - App requests location permission (first time only)
   - User grants permission
   - App checks if GPS is enabled
   - GPS coordinates are fetched automatically
   - Latitude and Longitude fields populate
   - Success message appears

3. **Complete Order**:
   - Select payment method
   - Add special notes (optional)
   - Review total
   - Click "Place Order"

## Features

### Location Accuracy:

- High accuracy GPS positioning
- Coordinates stored with 6 decimal places (~0.1 meter precision)
- Real-time location fetching

### Validation:

- ✅ Location is **required** - cannot place order without coordinates
- ✅ Permission handling with clear error messages
- ✅ GPS service check before fetching
- ✅ Read-only fields prevent manual editing

### User Experience:

- Loading indicator while fetching location
- Button disabled during fetch to prevent multiple requests
- Success/error messages via SnackBar
- Clean UI with location icon and badge styling

### Error Scenarios Handled:

- Permission denied by user
- Location services disabled
- GPS fetch failure
- No GPS signal
- Timeout issues

## Technical Details

### Coordinate Format:

- **Latitude**: -90 to +90 (6 decimal places)
- **Longitude**: -180 to +180 (6 decimal places)
- **Example**:
  - Latitude: 28.613939
  - Longitude: 77.209021

### Permission Flow:

1. Check current permission status
2. Request if denied
3. Handle permanent denial
4. Verify location services enabled
5. Fetch coordinates with high accuracy

### Data Storage:

Coordinates stored in:

- **Address object** → latitude, longitude fields
- **Order object** → deliveryAddress.latitude, deliveryAddress.longitude
- **Firebase Firestore** → orders collection

## Testing Checklist

- ✅ Location button click triggers permission request
- ✅ Permission granted → coordinates fetched
- ✅ Permission denied → error message shown
- ✅ GPS disabled → error message shown
- ✅ Successful fetch → coordinates displayed
- ✅ Cannot place order without location
- ✅ Loading state during fetch
- ✅ Error handling for network/GPS issues
- ✅ Coordinates saved with order
- ✅ Order history shows delivery address with coordinates

## Future Enhancements

Potential improvements:

- Show pin on map after location capture
- Reverse geocoding (coordinates → address)
- Manual coordinate entry option (for precision)
- Show accuracy radius
- Location refresh button
- Address auto-fill from coordinates
- Distance calculation from bakery
- Delivery route optimization

## Notes

- Location is captured once per order
- Coordinates cannot be edited manually (read-only fields)
- High accuracy mode used (may drain battery faster)
- Requires active internet for permission dialogs
- Works offline for GPS coordinate fetching
- Coordinates stored in Firebase for delivery tracking
