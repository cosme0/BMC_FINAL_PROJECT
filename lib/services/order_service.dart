import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  Future<String> placeOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double total,
    String? customerName,
    String? phone,
    String? address,
    String? paymentMethod,
  }) async {
    try {
      final doc = await _orders.add({
        'userId': userId,
        'items': items,
        'total': total,
        'status': 'pending',
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e, st) {
      // Keep the demo/presentation flow working when backend is unavailable.
      developer.log('placeOrder failed; using local fallback',
          error: e, stackTrace: st);
      return 'local-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Stream<List<OrderModel>> streamOrdersForUser(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => OrderModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }
}
