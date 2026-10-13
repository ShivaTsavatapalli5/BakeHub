import 'package:firebase_database/firebase_database.dart';
import 'package:bakehub/models/order.dart';

class RealtimeReadyService {
  static final DatabaseReference _db =
  FirebaseDatabase.instance.ref();

  /// 🚀 Create delivery request when order becomes READY
  static Future<void> uploadReadyOrder(Order order) async {
    await _db.child('delivery_requests').child(order.id).set({
      'orderId': order.id,
      'phone': order.deliveryAddress.phone,
      'locationName': order.deliveryAddress.fullAddress,
      'timestamp': ServerValue.timestamp,

      // 🚁 Drone State
      'drone_status': 'idle',

      // 🛫 TAKEOFF CONTROL (Owner Only)
      'takeoff_permission': 'waiting',
      'takeoff_triggered': false,
      'takeoff_by': 'none',

      // 🛬 LAND CONTROL (Owner + Customer)
      'landing_permission': 'waiting',
      'landing_triggered': false,
      'landing_by': 'none',

      // 🏠 RETURN HOME CONTROL (Owner + Customer)
      'return_permission': 'waiting',
      'return_triggered': false,
      'return_by': 'none',
    });
  }

  /// 🔎 Listen to specific order node
  static Stream<DatabaseEvent> listenToOrder(String orderId) {
    return _db.child('delivery_requests/$orderId').onValue;
  }

  // ============================================================
  // 🛫 TAKEOFF CONTROL METHODS
  // ============================================================

  /// Drone activates TAKEOFF permission after safety checks
  static Future<void> activateTakeoff(String orderId) async {
    await _db.child('delivery_requests/$orderId').update({
      'takeoff_permission': 'Activate',
    });
  }
  static Future<void> activateReturn(String orderId) async {
    await _db.child('delivery_requests/$orderId').update({
      'return_permission': 'Activate',
    });
  }
  /// Owner triggers takeoff
  static Future<void> triggerTakeoff(String orderId) async {
    await _db.child('delivery_requests/$orderId').update({
      'takeoff_triggered': true,
      'takeoff_by': 'owner',
      'drone_status': 'taking_off',
    });
  }

  // ============================================================
  // 🛬 LAND CONTROL METHODS
  // ============================================================

  /// Drone activates landing permission when hovering
  static Future<void> activateLanding(String orderId) async {
    await _db.child('delivery_requests/$orderId').update({
      'landing_permission': 'Activate',
      'drone_status': 'hovering',
    });
  }

  /// Trigger landing (Owner or Customer)
  static Future<void> triggerLanding(
      String orderId, String triggeredBy) async {
    await _db.child('delivery_requests/$orderId').update({
      'landing_triggered': true,
      'landing_by': triggeredBy,
      'drone_status': 'landing',
    });
  }

  // ============================================================
  // 🚁 DRONE STATUS UPDATE
  // ============================================================

  /// Update drone status during mission
  static Future<void> updateDroneStatus(
      String orderId, String status) async {
    await _db.child('delivery_requests/$orderId').update({
      'drone_status': status,
    });
  }
  /// Trigger return (Owner or Customer)
  static Future<void> triggerReturn(
      String orderId, String triggeredBy) async {
    await _db.child('delivery_requests/$orderId').update({
      'return_triggered': true,
      'return_by': triggeredBy,
      'drone_status': 'returning',
    });
  }
  // ============================================================
  // ✅ COMPLETE DELIVERY
  // ============================================================

  /// Remove node safely after mission complete
  static Future<void> completeDelivery(String orderId) async {
    await _db.child('delivery_requests/$orderId').remove();
  }
}