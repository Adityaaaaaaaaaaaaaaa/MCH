import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '/services/shopping_service.dart';
import '/services/ingredient_image_service.dart';

final inventoryControllerProvider = StateNotifierProvider<InventoryController, List<Map<String, dynamic>>>((ref) {
  return InventoryController();
});

class InventoryController extends StateNotifier<List<Map<String, dynamic>>> {
  late Box inventoryBox;
  StreamSubscription? firestoreSub;
  StreamSubscription? connectivitySub;
  bool isListeningFirestore = false;
  StreamSubscription<User?>? authSub;
  bool _imageBackfillInProgress = false;

  InventoryController() : super([]) {
    _init();
  }

  Future<void> resetLocal() async {
    await inventoryBox.clear();
    state = [];
  }

  //for hive
  Map<String, dynamic> _normalizeForHive(Map<String, dynamic> m) {
    final out = <String, dynamic>{};
    m.forEach((k, v) {
      if (v is Timestamp) {
        out[k] = v.millisecondsSinceEpoch;
      } else if (v is Map) {
        out[k] = _normalizeForHive(Map<String, dynamic>.from(v));
      } else if (v is List) {
        out[k] = v.map((e) {
          if (e is Timestamp) return e.millisecondsSinceEpoch;
          if (e is Map) return _normalizeForHive(Map<String, dynamic>.from(e));
          return e;
        }).toList();
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  Future<void> _init() async {
    inventoryBox = await Hive.openBox('inventoryBox');
    _loadLocal();
    _listenConnectivity();

    // Auth change: clear cache instantly to prevent ghost items, rebind stream.
    authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      firestoreSub?.cancel();
      isListeningFirestore = false;
      await inventoryBox.clear();
      state = [];
      if (user != null && await _isOnline()) {
        _listenFirestore();
      }
    });

    if (await _isOnline()) {
      _listenFirestore();
    }
  }

  void _loadLocal() {
    final local = inventoryBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
    state = local;
  }

  void _listenFirestore() {
    if (isListeningFirestore) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    isListeningFirestore = true;
    firestoreSub?.cancel();

    final q = FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('inventory')
        .orderBy('dateAdded', descending: true);

    firestoreSub = q.snapshots().listen((snapshot) async {

      final newState = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['offline'] = false;
        if (data.containsKey('dateAdded') && data['dateAdded'] is Timestamp) {
          data['dateAdded'] = (data['dateAdded'] as Timestamp).millisecondsSinceEpoch;
        }
        return data;
      }).toList();

      state = newState;

      // ignore: unused_local_variable
      final missing = state.where((m) => ((m['imageUrl'] ?? '').toString().isEmpty)).length;

      // OR, if you want the full batched run with throttle:
      unawaited(backfillAllImages(
        batchSize: 20,
        perItemDelay: const Duration(milliseconds: 1200),
        hardCap: 0, // 0 = no cap; keep going until all missing done
      ));

      // mirror to Hive
      for (var item in state) {
        await inventoryBox.put(item['id'], _normalizeForHive(item));
      }
    }, onDone: () {
      isListeningFirestore = false;
    }, onError: (e) {
      isListeningFirestore = false;
    });
  }

  void _listenConnectivity() {
    connectivitySub = Connectivity().onConnectivityChanged.listen((status) async {
      if (await _isOnline()) {
        _listenFirestore();
        await syncLocalToFirestore();
      } else {
        firestoreSub?.cancel();
        isListeningFirestore = false;
        _loadLocal();
      }
    });
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    final online = result != ConnectivityResult.none;
    return online;
  }

  // Add/update with quantity merge. previousId supports rename.
  Future<void> addOrUpdateItem(Map<String, dynamic> item, {String? previousId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final col = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');

    // sanitize doc ID from itemName
    String newId = (item['itemName'] ?? '').toString().replaceAll(RegExp(r'[\/\\.#\$\[\]]'), '_').trim();
    if (newId.isEmpty) {
      newId = (item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString();
    }

    // 1) Safer parsing for incoming quantity
    final incomingQty = (item['quantity'] is num)
        ? (item['quantity'] as num).toDouble()
        : double.tryParse(item['quantity']?.toString() ?? '') ?? 0.0;

    final isEdit = previousId != null && previousId.isNotEmpty;

    double _deltaForShopping = 0.0;
    String _nameForShopping = (item['itemName'] ?? newId).toString();
    String _unitForShopping = ((item['unit'] ?? 'count').toString());


    if (await _isOnline()) {
      if (isEdit && previousId != newId) {
        try {
          await col.doc(previousId).delete();
          await inventoryBox.delete(previousId);
        // ignore: empty_catches
        } catch (e) {
        }
      }

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final docRef = col.doc(newId);
        final snap = await tx.get(docRef);

        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          final existingQty = ((data['quantity'] ?? 0) as num).toDouble();
          final unit = (item['unit'] ?? '').toString();
          final cat  = (item['category'] ?? '').toString();

          // 2) If editing, set absolute; otherwise increment
          final nextQty = isEdit ? incomingQty : (existingQty + incomingQty);

          // capture delta & fields for shopping deduction (only increases)
          _deltaForShopping = (nextQty - existingQty).clamp(0, double.infinity).toDouble();
          _nameForShopping  = (data['itemName'] ?? newId).toString();
          _unitForShopping  = unit.isNotEmpty ? unit : ((data['unit'] ?? 'count').toString());

          final update = <String, dynamic>{
            'quantity': nextQty,
            'dateAdded': FieldValue.serverTimestamp(),
          };
          if (unit.isNotEmpty) update['unit'] = unit;
          if (cat.isNotEmpty)  update['category'] = cat;

          tx.update(docRef, update);

          // Mirror to Hive (normalized)
          final mergedLocal = Map<String, dynamic>.from(data)
            ..['quantity'] = nextQty
            ..['unit'] = unit.isNotEmpty ? unit : data['unit']
            ..['category'] = cat.isNotEmpty ? cat : data['category']
            ..['id'] = newId
            ..['offline'] = false;

          await inventoryBox.put(newId, _normalizeForHive(mergedLocal));

        } else {
          // New doc: set what the user provided (as-is)
          // brand new doc → delta is the whole incoming amount
          _deltaForShopping = math.max(0.0, incomingQty);
          _nameForShopping  = (item['itemName'] ?? newId).toString();
          _unitForShopping  = ((item['unit'] ?? 'count').toString());

          final toSet = Map<String, dynamic>.from(item)
            ..['dateAdded'] = FieldValue.serverTimestamp();
          tx.set(docRef, toSet);

          final local = Map<String, dynamic>.from(item)
            ..['id'] = newId
            ..['offline'] = false
            ..['dateAdded'] = DateTime.now().millisecondsSinceEpoch;
          await inventoryBox.put(newId, _normalizeForHive(local));
        }
      });

      // AFTER the transaction completes:
      if (_deltaForShopping > 0) {
        unawaited(ShoppingService.deductForInventoryIncrease(
          name: _nameForShopping,
          delta: _deltaForShopping,
          unit:  _unitForShopping,
        ));
      }

      // opportunistic image for this item
      unawaited(backfillImagesForMissing(max: 1));

    } else {
      // OFFLINE: merge into Hive
      final safeId = newId;

      // Support offline rename: if name changed, drop old key locally
      if (isEdit && previousId != safeId) {
        await inventoryBox.delete(previousId);
      }

      final existing = inventoryBox.get(safeId);
      if (existing != null) {
        final m = Map<String, dynamic>.from(existing);
        final current = ((m['quantity'] ?? 0) as num).toDouble();

        // 3) If editing, set absolute; otherwise increment
        m['quantity'] = isEdit ? incomingQty : (current + incomingQty);
        m['unit'] = (item['unit'] ?? m['unit']);
        m['category'] = (item['category'] ?? m['category']);
        m['offline'] = true;
        m['source'] = 'Manual_edit';
        m['dateAdded'] = DateTime.now().toIso8601String();

        await inventoryBox.put(safeId, _normalizeForHive(m));
      } else {
        final m = Map<String, dynamic>.from(item)
          ..['id'] = safeId
          ..['quantity'] = incomingQty // set as-is for brand new offline doc
          ..['offline'] = true
          ..['source'] = 'Manual_edit'
          ..['dateAdded'] = DateTime.now().toIso8601String();

        await inventoryBox.put(safeId, _normalizeForHive(m));
      }
    }

    _loadLocal();
  }

  Future<void> deleteItems(List<String> ids) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');
    if (await _isOnline()) {
      for (var id in ids) {
        await ref.doc(id).delete();
        await inventoryBox.delete(id);
      }
    } else {
      // Only delete locally
      for (var id in ids) {
        await inventoryBox.delete(id);
      }
    }
    _loadLocal();
  }

  Future<void> syncLocalToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');

    // gather offline items
    final List<Map<String, dynamic>> offlineItems = [];
    for (var item in inventoryBox.values) {
      final m = Map<String, dynamic>.from(item);
      if (m['offline'] == true) offlineItems.add(m);
    }

    for (var m in offlineItems) {
      String safeName = (m['itemName'] ?? '').replaceAll(RegExp(r'[\/\\.#\$\\[\\]]'), '_');
      if (safeName.isEmpty) {
        safeName = m['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      }
      await ref.doc(safeName).set(m, SetOptions(merge: true));
      m['id'] = safeName;
      await inventoryBox.put(safeName, m);
    }
    _loadLocal();
  }

  @override
  void dispose() {
    firestoreSub?.cancel();
    connectivitySub?.cancel();
    authSub?.cancel();
    super.dispose();
  }

  Future<void> refreshFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('inventory')
        .orderBy('dateAdded', descending: true);

    final snapshot = await ref.get();

    final newState = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      data['offline'] = false;
      if (data.containsKey('dateAdded') && data['dateAdded'] is Timestamp) {
        data['dateAdded'] = (data['dateAdded'] as Timestamp).millisecondsSinceEpoch;
      }
      return data;
    }).toList();

    state = newState;
    for (var item in state) {
      await inventoryBox.put(item['id'], _normalizeForHive(item));
    }

    unawaited(backfillAllImages(
      batchSize: 20,
      perItemDelay: const Duration(milliseconds: 1200),
      hardCap: 0, // 0 = no cap; keep going until all missing done
    ));
  }

  /// Fill a few missing imageUrls by checking the global pool or resolving TheMealDB.
  /// Saves url to BOTH global pool and user inventory doc (merge), then mirrors to Hive/state.
  /// Limit each pass to `max` docs to avoid hammering.
  Future<void> backfillImagesForMissing({int max = 8}) async {
    if (_imageBackfillInProgress) {
      return;
    }
    if (!await _isOnline()) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _imageBackfillInProgress = true;

    try {
      final missing = state
          .where((m) =>
              ((m['imageUrl'] ?? '').toString().isEmpty) &&
              (m['imageStatus'] != 'none') &&                     // ← skip known misses
              ((m['itemName'] ?? '') as String).isNotEmpty)
          .take(max)
          .toList();


      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('inventory');

      for (final m in missing) {
        final id = (m['id'] ?? '').toString();
        final name = (m['itemName'] ?? '').toString();
        if (id.isEmpty || name.isEmpty) continue;

        final url = await IngredientImageService.getOrResolveFromGlobalPool(name);
        if (url == null) {
          // Mark permanent miss
          await col.doc(id).set({'imageStatus': 'none'}, SetOptions(merge: true));
          final updatedMiss = Map<String, dynamic>.from(m)..['imageStatus'] = 'none';
          await inventoryBox.put(id, updatedMiss);
          continue;
        }

        await col.doc(id).set({'imageUrl': url}, SetOptions(merge: true));
        final updated = Map<String, dynamic>.from(m)..['imageUrl'] = url;
        await inventoryBox.put(id, updated);
      }

      _loadLocal();
    } finally {
      _imageBackfillInProgress = false;
    }
  }

  // Process ALL missing images in batches, with optional per-item delay.
  // - batchSize: how many docs to attempt per pass
  // - perItemDelay: delay between each HTTP probe (avoid hammering TheMealDB)
  // - hardCap: stop after N items total (0 = no cap; process all)
  Future<void> backfillAllImages({
    int batchSize = 20,
    Duration perItemDelay = const Duration(milliseconds: 1200),
    int hardCap = 0,
  }) async {
    if (_imageBackfillInProgress) {
      return;
    }
    if (!await _isOnline()) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _imageBackfillInProgress = true;
    try {
      // Take a snapshot of what’s missing NOW (single pass queue)
      final queue = state
          .where((m) =>
              ((m['imageUrl'] ?? '').toString().isEmpty) &&
              (m['imageStatus'] != 'none') &&                    // ← skip known misses
              ((m['itemName'] ?? '') as String).isNotEmpty)
          .toList();

      final totalToProcess =
          (hardCap > 0) ? math.min(hardCap, queue.length) : queue.length;

      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('inventory');

      // Process the fixed queue in batches
      for (int start = 0; start < totalToProcess; start += batchSize) {
        final end = math.min(start + batchSize, totalToProcess);
        final batch = queue.sublist(start, end);

        for (final m in batch) {
          final id = (m['id'] ?? '').toString();
          final name = (m['itemName'] ?? '').toString();
          if (id.isEmpty || name.isEmpty) continue;

          final url = await IngredientImageService.getOrResolveFromGlobalPool(name);
          if (url != null) {
            try {
              await col.doc(id).set({'imageUrl': url}, SetOptions(merge: true));
              final updated = Map<String, dynamic>.from(m)..['imageUrl'] = url;
              await inventoryBox.put(id, updated);
            } catch (e) {
              print(e);
            }
          } else {
            // Mark as permanently missing so we never try again
            try {
              await col.doc(id).set({'imageStatus': 'none'}, SetOptions(merge: true));
              final updated = Map<String, dynamic>.from(m)..['imageStatus'] = 'none';
              await inventoryBox.put(id, updated);
            } catch (e) {
              print(e);
            }
          }

          if (perItemDelay > Duration.zero) {
            await Future.delayed(perItemDelay);
          }
        }

        // Refresh UI from Hive after each batch
        _loadLocal();
      }

    } finally {
      _imageBackfillInProgress = false;
    }
  }
}
