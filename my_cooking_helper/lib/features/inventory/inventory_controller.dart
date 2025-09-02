import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
    blueDebugPrint('resetLocal(): clearing Hive + state');
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

  //remove apres tresting //////////////////////////////////////////////////////////////
  void blueDebugPrint(Object msg) {
    dynamic makeEncodable(dynamic value) {
      if (value is Set) return value.map(makeEncodable).toList();
      if (value is List) return value.map(makeEncodable).toList();
      if (value is Map) return value.map((k, v) => MapEntry(k, makeEncodable(v)));
      return value;
    }

    final encodable = makeEncodable(msg);
    final str = (encodable is String)
        ? encodable
        : const JsonEncoder.withIndent('  ').convert(encodable);

    for (final line in str.split('\n')) {
      // blue
      // ignore: avoid_print
      print('\x1B[34m[INV] $line\x1B[0m');
    }
  }
  /////////////////////////////////////////////////////////////////////////////////////////////

  Future<void> _init() async {
    blueDebugPrint('Initializing InventoryController');
    inventoryBox = await Hive.openBox('inventoryBox');
    _loadLocal();
    _listenConnectivity();

    // Auth change: clear cache instantly to prevent ghost items, rebind stream.
    authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      blueDebugPrint({
        'authStateChanges': user == null ? 'SIGNED OUT' : 'SIGNED IN',
        'uid': user?.uid ?? '-'
      });
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
    blueDebugPrint({'_loadLocal count': local.length});
  }

  void _listenFirestore() {
    if (isListeningFirestore) {
      blueDebugPrint('_listenFirestore(): already listening, skip');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      blueDebugPrint('_listenFirestore(): no user');
      return;
    }

    blueDebugPrint('Attach Firestore stream: users/${user.uid}/inventory orderBy(dateAdded desc)');
    isListeningFirestore = true;
    firestoreSub?.cancel();

    final q = FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('inventory')
        .orderBy('dateAdded', descending: true);

    firestoreSub = q.snapshots().listen((snapshot) async {
      blueDebugPrint({'Firestore snapshot docs': snapshot.docs.length});

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

      final missing = state.where((m) => ((m['imageUrl'] ?? '').toString().isEmpty)).length;
      blueDebugPrint({'state updated (count)': state.length, 'missing imageUrl': missing});

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
      blueDebugPrint('Firestore stream closed');
    }, onError: (e) {
      isListeningFirestore = false;
      blueDebugPrint('Firestore stream error: $e');
    });
  }

  void _listenConnectivity() {
    blueDebugPrint('Listening for connectivity changes');
    connectivitySub = Connectivity().onConnectivityChanged.listen((status) async {
      blueDebugPrint({'connectivity': status.toString()});
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
    blueDebugPrint({'_isOnline': online, 'status': result.toString()});
    return online;
  }

  // Add/update with quantity merge. previousId supports rename.
  Future<void> addOrUpdateItem(Map<String, dynamic> item, {String? previousId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      blueDebugPrint('addOrUpdateItem(): not logged in');
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

    blueDebugPrint({'addOrUpdateItem': {'newId': newId, 'previousId': previousId, 'qty+': incomingQty}});

    if (await _isOnline()) {
      // Rename handling
      // ONLINE path

      // Handle rename (delete old doc if name changed)
      if (isEdit && previousId != newId) {
        try {
          await col.doc(previousId).delete();
          await inventoryBox.delete(previousId);
          blueDebugPrint({'rename': 'deleted old doc', 'oldId': previousId});
        } catch (e) {
          blueDebugPrint({'rename error': e.toString()});
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
          final double nextQty = isEdit ? incomingQty : (existingQty + incomingQty);

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
          blueDebugPrint({'tx:update qty': nextQty, 'id': newId});

        } else {
          // New doc: set what the user provided (as-is)
          final toSet = Map<String, dynamic>.from(item)
            ..['dateAdded'] = FieldValue.serverTimestamp();
          tx.set(docRef, toSet);

          final local = Map<String, dynamic>.from(item)
            ..['id'] = newId
            ..['offline'] = false
            ..['dateAdded'] = DateTime.now().millisecondsSinceEpoch;
          await inventoryBox.put(newId, _normalizeForHive(local));
          blueDebugPrint({'tx:set new doc': newId});
        }
      });

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
        blueDebugPrint({'offline ${isEdit ? 'set' : 'merge'}': {'id': safeId, 'qty': m['quantity']}});
      } else {
        final m = Map<String, dynamic>.from(item)
          ..['id'] = safeId
          ..['quantity'] = incomingQty // set as-is for brand new offline doc
          ..['offline'] = true
          ..['source'] = 'Manual_edit'
          ..['dateAdded'] = DateTime.now().toIso8601String();

        await inventoryBox.put(safeId, _normalizeForHive(m));
        blueDebugPrint({'offline new': safeId});
      }
    }

    _loadLocal();
  }

  Future<void> deleteItems(List<String> ids) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      blueDebugPrint('deleteItems(): not logged in');
      return;
    }
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');
    blueDebugPrint({'deleteItems count': ids.length});
    if (await _isOnline()) {
      for (var id in ids) {
        await ref.doc(id).delete();
        await inventoryBox.delete(id);
        blueDebugPrint({'deleted online': id});
      }
    } else {
      // Only delete locally
      for (var id in ids) {
        await inventoryBox.delete(id);
        blueDebugPrint({'deleted offline': id});
      }
    }
    _loadLocal();
  }

  Future<void> syncLocalToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      blueDebugPrint('syncLocalToFirestore(): not logged in');
      return;
    }
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');

    // gather offline items
    final List<Map<String, dynamic>> offlineItems = [];
    for (var item in inventoryBox.values) {
      final m = Map<String, dynamic>.from(item);
      if (m['offline'] == true) offlineItems.add(m);
    }
    blueDebugPrint({'syncLocalToFirestore offlineCount': offlineItems.length});

    for (var m in offlineItems) {
      String safeName = (m['itemName'] ?? '').replaceAll(RegExp(r'[\/\\.#\$\\[\\]]'), '_');
      if (safeName.isEmpty) {
        safeName = m['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      }
      await ref.doc(safeName).set(m, SetOptions(merge: true));
      m['id'] = safeName;
      await inventoryBox.put(safeName, m);
      blueDebugPrint({'synced online': safeName});
    }
    _loadLocal();
  }

  @override
  void dispose() {
    firestoreSub?.cancel();
    connectivitySub?.cancel();
    authSub?.cancel();
    blueDebugPrint('InventoryController disposed');
    super.dispose();
  }

  Future<void> refreshFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('inventory')
        .orderBy('dateAdded', descending: true);

    blueDebugPrint('refreshFromFirestore()');
    final snapshot = await ref.get();
    blueDebugPrint({'refreshFromFirestore docs': snapshot.docs.length});

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
      blueDebugPrint('backfillImagesForMissing(): already running, skip');
      return;
    }
    if (!await _isOnline()) {
      blueDebugPrint('backfillImagesForMissing(): offline, skip');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _imageBackfillInProgress = true;
    blueDebugPrint('backfillImagesForMissing(): start');

    try {
      final missing = state
          .where((m) =>
              ((m['imageUrl'] ?? '').toString().isEmpty) &&
              (m['imageStatus'] != 'none') &&                     // ← skip known misses
              ((m['itemName'] ?? '') as String).isNotEmpty)
          .take(max)
          .toList();

      blueDebugPrint({'backfill: candidates': missing.map((m) => m['itemName']).toList()});

      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('inventory');

      for (final m in missing) {
        final id = (m['id'] ?? '').toString();
        final name = (m['itemName'] ?? '').toString();
        if (id.isEmpty || name.isEmpty) continue;

        blueDebugPrint({'resolve try': name});
        final url = await IngredientImageService.getOrResolveFromGlobalPool(name);
        if (url == null) {
          // Mark permanent miss
          await col.doc(id).set({'imageStatus': 'none'}, SetOptions(merge: true));
          final updatedMiss = Map<String, dynamic>.from(m)..['imageStatus'] = 'none';
          await inventoryBox.put(id, updatedMiss);
          blueDebugPrint({'resolve fail → marked none': name});
          continue;
        }

        blueDebugPrint({'resolve ok': {'name': name, 'url': url}});
        await col.doc(id).set({'imageUrl': url}, SetOptions(merge: true));
        final updated = Map<String, dynamic>.from(m)..['imageUrl'] = url;
        await inventoryBox.put(id, updated);
      }

      _loadLocal();
      blueDebugPrint('backfillImagesForMissing(): done');
    } catch (e) {
      blueDebugPrint({'backfill error': e.toString()});
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
      blueDebugPrint('backfillAllImages(): already running, skip');
      return;
    }
    if (!await _isOnline()) {
      blueDebugPrint('backfillAllImages(): offline, skip');
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

      blueDebugPrint({
        'backfillAllImages queue': {
          'totalMissingNow': queue.length,
          'willProcess': totalToProcess,
          'batchSize': batchSize,
        }
      });

      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('inventory');

      // Process the fixed queue in batches
      for (int start = 0; start < totalToProcess; start += batchSize) {
        final end = math.min(start + batchSize, totalToProcess);
        final batch = queue.sublist(start, end);
        blueDebugPrint({
          'backfillAllImages batch': {
            'range': '$start..${end - 1}',
            'size': batch.length,
          }
        });

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
              blueDebugPrint({'backfill saved': {'id': id, 'name': name, 'url': url}});
            } catch (e) {
              blueDebugPrint({'backfill save error': e.toString()});
            }
          } else {
            // Mark as permanently missing so we never try again
            try {
              await col.doc(id).set({'imageStatus': 'none'}, SetOptions(merge: true));
              final updated = Map<String, dynamic>.from(m)..['imageStatus'] = 'none';
              await inventoryBox.put(id, updated);
              blueDebugPrint({'backfill miss (marked none)': name});
            } catch (e) {
              blueDebugPrint({'mark none error': e.toString()});
            }
          }

          if (perItemDelay > Duration.zero) {
            await Future.delayed(perItemDelay);
          }
        }

        // Refresh UI from Hive after each batch
        _loadLocal();
      }

      blueDebugPrint({'backfillAllImages done': {'processedTotal': totalToProcess}});
    } finally {
      _imageBackfillInProgress = false;
    }
  }
}
