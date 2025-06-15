import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Saves a list of items to the user's inventory.
  /// Each item should be a map with keys matching ScannedItem fields.
  Future<void> addItemsToInventory(List<Map<String, dynamic>> items) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    final inventoryRef = _db.collection('users')
                            .doc(user.uid)
                            .collection('inventory');
                            
    final batch = _db.batch();

    for (final item in items) {
      final doc = inventoryRef.doc(); // Auto-ID
      batch.set(doc, {
        'itemName': item['itemName'],            // <-- match your model field name
        'quantity': item['quantity'],
        'unit': item['unit'] ?? '',              // optional, fallback empty string
        'category': item['category'] ?? '',      // optional, fallback empty string
        'source': item['source'] ?? '',          // optional, fallback empty string
        'nutritionId': item['nutritionId'] ?? '',// optional, fallback empty string
        'imageUrl': item['imageUrl'] ?? '',      // optional, fallback empty string
        'dateAdded': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
