import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper function to check and display current bakery settings from Firestore
/// The settings are already in the bakeries collection
Future<void> initializeAppSettings() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final bakeryRef = firestore
        .collection('bakeries')
        .doc('wi9LNUqFuwOwTOLQqJHwecqQXiq1');

    // Check if bakery document exists
    final doc = await bakeryRef.get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      print('✅ Bakery settings found!');
      print('Bakery Name: ${data['bakeryName']}');
      print('GST Rate: ${data['gstRate']}%');
      print('Delivery Charge: ₹${data['deliveryCharge']}');
      print('Free Delivery Above: ₹${data['freeDeliveryAbove']}');
      print('Business Hours: ${data['businessHours']}');
      print('Estimated Delivery: ${data['estimatedDelivery']} mins');

      if (data['gstRate'] == null ||
          data['deliveryCharge'] == null ||
          data['freeDeliveryAbove'] == null) {
        print('⚠️ Warning: Some settings fields are missing!');
      }
    } else {
      print('❌ Bakery document not found - using default settings');
      print('Expected document ID: wi9LNUqFuwOwTOLQqJHwecqQXiq1');
    }
  } catch (e) {
    print('❌ Error loading bakery settings: $e');
  }
}
