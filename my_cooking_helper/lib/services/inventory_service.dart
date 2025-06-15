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
      final doc = inventoryRef.doc();
      batch.set(doc, {
        'itemName': item['itemName'],           
        'quantity': item['quantity'],
        'unit': item['unit'] ?? '',              
        'category': item['category'] ?? '',      
        'source': item['source'] ?? '',          
        'nutritionId': item['nutritionId'] ?? '',
        'imageUrl': item['imageUrl'] ?? '',      
        'dateAdded': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
