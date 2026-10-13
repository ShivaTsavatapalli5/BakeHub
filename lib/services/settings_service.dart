import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bakehub/models/app_settings.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._();
  SettingsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bakeries';

  final String _bakeryId = 'wi9LNUqFuwOwTOLQqJHwecqQXiq1';

  Stream<AppSettings> getSettingsStream() {
    return _firestore.collection(_collection).doc(_bakeryId).snapshots().map((
      snapshot,
    ) {
      print(
        '🔥 Firestore bakery snapshot - exists: ${snapshot.exists}, hasData: ${snapshot.data() != null}',
      );
      if (!snapshot.exists || snapshot.data() == null) {
        print('⚠️ Using default settings');
        return AppSettings.defaultSettings();
      }

      final data = snapshot.data()!;

      final gstRate =
          double.tryParse(data['gstRate']?.toString() ?? '5') ?? 5.0;
      final deliveryCharge =
          double.tryParse(data['deliveryCharge']?.toString() ?? '50') ?? 50.0;
      final freeDeliveryAbove =
          double.tryParse(data['freeDeliveryAbove']?.toString() ?? '500') ??
          500.0;

      final settings = AppSettings(
        taxPercent: gstRate,
        deliveryFee: deliveryCharge,
        freeDeliveryMinAmount: freeDeliveryAbove,
      );

      print('✅ Loaded settings from bakery: $settings');
      return settings;
    });
  }

  Future<AppSettings> getSettings() async {
    try {
      final doc = await _firestore.collection(_collection).doc(_bakeryId).get();
      if (!doc.exists || doc.data() == null) {
        return AppSettings.defaultSettings();
      }

      final data = doc.data()!;

      final gstRate =
          double.tryParse(data['gstRate']?.toString() ?? '5') ?? 5.0;
      final deliveryCharge =
          double.tryParse(data['deliveryCharge']?.toString() ?? '50') ?? 50.0;
      final freeDeliveryAbove =
          double.tryParse(data['freeDeliveryAbove']?.toString() ?? '500') ??
          500.0;

      return AppSettings(
        taxPercent: gstRate,
        deliveryFee: deliveryCharge,
        freeDeliveryMinAmount: freeDeliveryAbove,
      );
    } catch (e) {
      print('Error getting settings: $e');
      return AppSettings.defaultSettings();
    }
  }

  Future<bool> updateSettings(AppSettings settings) async {
    try {
      await _firestore.collection(_collection).doc(_bakeryId).update({
        'gstRate': settings.taxPercent.toString(),
        'deliveryCharge': settings.deliveryFee.toString(),
        'freeDeliveryAbove': settings.freeDeliveryMinAmount.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating settings: $e');
      return false;
    }
  }
}
