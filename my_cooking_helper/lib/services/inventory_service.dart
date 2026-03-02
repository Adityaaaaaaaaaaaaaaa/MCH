import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // for debugPrint (blue logs)
import 'package:http/http.dart' as http;
import '/config/backend_config.dart';
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

extension _Blue on Object {
  void blue() => debugPrint('\x1B[34m[DEBUG][InvDeduct] $this\x1B[0m');
}

// Payload used when calling the backend deduction endpoint
class CookedIngredientPayload {
  final String name;   // raw recipe line name
  final double amount; // as provided by recipe
  final String unit;   // raw recipe unit ("tbsp", "kg", "cup", "g", "ml", "count")

  CookedIngredientPayload(this.name, this.amount, this.unit);

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount, 'unit': unit};
}

class InventoryService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Saves or updates items in the user's inventory.
  /// For existing items, only the quantity is updated; other fields remain unchanged.
  /// For new items, all fields are set.
  Future<void> addItemsToInventory(List<Map<String, dynamic>> items) async {
    '[addItemsToInventory] incoming items: ${items.length}'.blue();

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
    final existingKeys = itemsByName.keys.toList();
    if (existingKeys.isEmpty) {
      '[addItemsToInventory] nothing to save'.blue();
      return;
    }
    final existingDocs = await inventoryRef
        .where(FieldPath.documentId, whereIn: existingKeys)
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
        // Existing item: Only update quantity 
        final double newQuantity = (existingQuantities[entry.key] ?? 0.0) + addQuantity;
        batch.update(docRef, {
          'quantity': newQuantity,
          'dateAdded': FieldValue.serverTimestamp(),
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
    '[addItemsToInventory] Firestore batch committed for ${itemsByName.length} items'.blue();

    // Deduct per item from the shopping list (best-effort; no throw)
    int triggered = 0;
    for (final entry in itemsByName.entries) {
      final item = entry.value;
      final name = (item['itemName'] ?? '').toString();
      final unit = ((item['unit'] ?? 'count') as String).trim().toLowerCase();
      final double addQty = (item['quantity'] is num)
          ? (item['quantity'] as num).toDouble()
          : double.tryParse(item['quantity']?.toString() ?? '') ?? 0.0;

      if (name.isEmpty || addQty <= 0) continue;
      triggered++;
      unawaited(ShoppingService.deductForInventoryIncrease(
        name: name,
        delta: addQty,
        unit: unit,
      ));
    }
    '[addItemsToInventory] triggered ShoppingService deductions for $triggered items'.blue();
  }

  /// Fire-and-forget call to the backend to deduct inventory based on cooked recipe.
  /// Uses aiRecipeInvCal (from backend_config.dart) as the endpoint.
  Future<void> deductViaBackend({
    required String uid,
    required List<CookedIngredientPayload> ingredients,
    bool apply = true,
  }) async {
    try {
      if (ingredients.isEmpty) {
        '[deductViaBackend] no ingredients to process'.blue();
        return;
      }
      final url = Uri.parse(aiRecipeInvCal);
      final payload = {
        'uid': uid,
        'apply': apply,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
      };
      'POST $url'.blue();
      const encoder = JsonEncoder.withIndent('  ');
      encoder.convert(payload).blue();

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      '[deductViaBackend] response ${resp.statusCode}'.blue();
      resp.body.blue();
      // UI remains unaffected; Firestore listeners will reflect changes when backend applies them.
    } catch (e, st) {
      '[deductViaBackend] error: $e'.blue();
      st.toString().blue();
    }
  }
}
