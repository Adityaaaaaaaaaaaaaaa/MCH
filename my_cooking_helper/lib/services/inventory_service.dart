import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'shopping_service.dart';

String toTitleCase(String input) {
  if (input.isEmpty) return input;
  return input
      .split(' ')
      .map((word) => word.isNotEmpty
          ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
          : '')
      .join(' ');
}

class InventoryService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Saves or updates items in the user's inventory.
  /// For existing items, only the quantity is updated; other fields remain unchanged.
  /// For new items, all fields are set.
  Future<void> addItemsToInventory(List<Map<String, dynamic>> items) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    final inventoryRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('inventory');

    // Prepare map of item names to item data
    final Map<String, Map<String, dynamic>> itemsByName = {};
    for (final item in items) {
      String rawName = item['itemName'] ?? '';
      String capName = toTitleCase(rawName);
      String safeName = capName.replaceAll(RegExp(r'[\/\\]'), '_');
      item['itemName'] = capName;
      itemsByName[safeName] = item;
    }

    // Fetch existing documents (those with the same documentId)
    final existingDocs = await inventoryRef
        .where(FieldPath.documentId, whereIn: itemsByName.keys.toList())
        .get();

    final Set<String> existingIds = existingDocs.docs.map((doc) => doc.id).toSet();
    final Map<String, double> existingQuantities = {
      for (final doc in existingDocs.docs)
        doc.id: (doc.data()['quantity'] ?? 0.0) is int
            ? (doc.data()['quantity'] as int).toDouble()
            : (doc.data()['quantity'] ?? 0.0) as double
    };

    // Prepare the batch operation
    final batch = _db.batch();
    for (final entry in itemsByName.entries) {
      final docRef = inventoryRef.doc(entry.key);
      final item = entry.value;
      final addQuantity = (item['quantity'] ?? 1.0) is int
          ? (item['quantity'] as int).toDouble()
          : (item['quantity'] ?? 1.0) as double;

      if (existingIds.contains(entry.key)) {
        // Existing item: Only update quantity (and optionally dateAdded)
        final double newQuantity = existingQuantities[entry.key]! + addQuantity;
        batch.update(docRef, {
          'quantity': newQuantity,
          'dateAdded': FieldValue.serverTimestamp(), // Optional: update date
        });
      } else {
        // New item: Set all fields
        batch.set(docRef, {
          'itemName': item['itemName'] ?? '',
          'quantity': addQuantity,
          'unit': item['unit'] ?? '',
          'category': item['category'] ?? '',
          'source': item['source'] ?? '',
          'nutritionId': item['nutritionId'] ?? '',
          'imageUrl': item['imageUrl'] ?? '',
          'dateAdded': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();

    // Deduct per item from the shopping list (best-effort; no throw)
    for (final entry in itemsByName.entries) {
      final item = entry.value;
      final name = (item['itemName'] ?? '').toString();
      final unit = ((item['unit'] ?? 'count') as String).trim().toLowerCase();
      final double addQty = (item['quantity'] is num)
          ? (item['quantity'] as num).toDouble()
          : double.tryParse(item['quantity']?.toString() ?? '') ?? 0.0;

      if (name.isEmpty || addQty <= 0) continue;
      unawaited(ShoppingService.deductForInventoryIncrease(
        name: name,
        delta: addQty,
        unit: unit,
      ));
    }
  }
}
