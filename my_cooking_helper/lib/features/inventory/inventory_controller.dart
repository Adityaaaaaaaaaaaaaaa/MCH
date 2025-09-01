import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final inventoryControllerProvider = StateNotifierProvider<InventoryController, List<Map<String, dynamic>>>((ref) {
  return InventoryController();
});

class InventoryController extends StateNotifier<List<Map<String, dynamic>>> {
  late Box inventoryBox;
  StreamSubscription? firestoreSub;
  StreamSubscription? connectivitySub;
  bool isListeningFirestore = false;
  StreamSubscription<User?>? authSub;

  InventoryController() : super([]) {
    _init();
  }

  Future<void> resetLocal() async {
    await inventoryBox.clear();
    state = [];
  }

  //remove apres tresting //////////////////////////////////////////////////////////////
  void blueDebugPrint(Object msg) {
    dynamic makeEncodable(dynamic value) {
      if (value is Set) {
        return value.map(makeEncodable).toList();
      } else if (value is List) {
        return value.map(makeEncodable).toList();
      } else if (value is Map) {
        return value.map((k, v) => MapEntry(k, makeEncodable(v)));
      } else {
        return value;
      }
    }

    final encodable = makeEncodable(msg);
    final str = (encodable is String)
        ? encodable
        : const JsonEncoder.withIndent('  ').convert(encodable);

    for (final line in str.split('\n')) {
      print('\x1B[34m[DEBUG] $line\x1B[0m');
    }
  }
  /////////////////////////////////////////////////////////////////////////////////////////////

  Future<void> _init() async {
    //print('\x1B[34m[DEBUG] Initializing InventoryController\x1B[0m');
    blueDebugPrint('Initializing InventoryController');
    inventoryBox = await Hive.openBox('inventoryBox');
    _loadLocal();
    _listenConnectivity();

    // Re-bind Firestore when the user changes; clear local state immediately
    authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      firestoreSub?.cancel();
      isListeningFirestore = false;
      await inventoryBox.clear(); // clear previous user's cache
      state = [];                 // clear UI instantly (no ghost items)

      if (user != null && await _isOnline()) {
        _listenFirestore();       // attach fresh stream for new user
      }
    });

    if (await _isOnline()) {
      _listenFirestore();
    }
  }

  void _loadLocal() {
    //print('\x1B[34m[DEBUG] Loading inventory from Hive\x1B[0m');
    blueDebugPrint('Loading inventory from Hive');

    state = inventoryBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
    //print('\x1B[34m[DEBUG] Current local state: $state\x1B[0m');
    blueDebugPrint({'Current local state: $state'});
  }

  void _listenFirestore() {
    if (isListeningFirestore) {
      blueDebugPrint('Already listening to Firestore, skipping re-listen');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      blueDebugPrint('No user for Firestore listen');
      return;
    }

    blueDebugPrint('Listening to Firestore: users/${user.uid}/inventory');
    isListeningFirestore = true;
    firestoreSub?.cancel();

    // Order by dateAdded (missing values sort first, so it’s safe)
    final q = FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('inventory')
        .orderBy('dateAdded', descending: true);

    firestoreSub = q.snapshots().listen((snapshot) {
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
      blueDebugPrint({'Firestore state updated': state});

      // mirror into Hive
      for (var item in state) {
        inventoryBox.put(item['id'], item);
      }
    }, onDone: () {
      isListeningFirestore = false;
      blueDebugPrint('Firestore listen closed');
    }, onError: (e) {
      isListeningFirestore = false;
      blueDebugPrint('Firestore listen error: $e');
    });
  }

  void _listenConnectivity() {
    //print('\x1B[34m[DEBUG] Listening for connectivity changes\x1B[0m');
    blueDebugPrint('Listening for connectivity changes');
    connectivitySub = Connectivity().onConnectivityChanged.listen((status) async {
      //print('\x1B[34m[DEBUG] Connectivity changed: $status\x1B[0m');
      blueDebugPrint('Connectivity changed: $status');
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
    //print('\x1B[34m[DEBUG] Online check: ${result != ConnectivityResult.none}\x1B[0m');
    blueDebugPrint('Online check: ${result != ConnectivityResult.none}');
    return result != ConnectivityResult.none;
  }

  // Accepts an extra previousId parameter for renames
  Future<void> addOrUpdateItem(Map<String, dynamic> item, {String? previousId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      blueDebugPrint('Cannot add/update item: not logged in');
      return;
    }

    final col = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');

    // sanitize doc ID from itemName
    String newId = (item['itemName'] ?? '').toString().replaceAll(RegExp(r'[\/\\.#\$\[\]]'), '_').trim();
    if (newId.isEmpty) {
      newId = (item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString();
    }

    // Ensure numeric quantity
    final incomingQty = ((item['quantity'] ?? 1) as num).toDouble();

    if (await _isOnline()) {
      // Handle rename (previousId -> newId)
      if (previousId != null && previousId.isNotEmpty && previousId != newId) {
        try {
          await col.doc(previousId).delete();
          await inventoryBox.delete(previousId);
          blueDebugPrint('Deleted old doc due to rename: $previousId');
        } catch (e) {
          blueDebugPrint('Error deleting old doc: $e');
        }
      }

      // Transaction to increment quantity if doc exists
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final docRef = col.doc(newId);
        final snap = await tx.get(docRef);

        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          final existingQty = ((data['quantity'] ?? 0) as num).toDouble();
          final update = <String, dynamic>{
            'quantity': existingQty + incomingQty,
            'dateAdded': FieldValue.serverTimestamp(),
          };

          // Optionally update unit/category if provided (and non-empty)
          final unit = (item['unit'] ?? '').toString();
          if (unit.isNotEmpty) update['unit'] = unit;
          final cat = (item['category'] ?? '').toString();
          if (cat.isNotEmpty) update['category'] = cat;

          tx.update(docRef, update);

          // Mirror to Hive
          final mergedLocal = Map<String, dynamic>.from(data)
            ..['quantity'] = existingQty + incomingQty
            ..['unit'] = unit.isNotEmpty ? unit : data['unit']
            ..['category'] = cat.isNotEmpty ? cat : data['category']
            ..['id'] = newId
            ..['offline'] = false;
          await inventoryBox.put(newId, mergedLocal);

        } else {
          // New doc
          final toSet = Map<String, dynamic>.from(item)
            ..['dateAdded'] = FieldValue.serverTimestamp();
          tx.set(docRef, toSet);

          final local = Map<String, dynamic>.from(item)
            ..['id'] = newId
            ..['offline'] = false
            ..['dateAdded'] = DateTime.now().millisecondsSinceEpoch;
          await inventoryBox.put(newId, local);
        }
      });

    } else {
      // OFFLINE: merge into Hive
      final safeId = newId;
      final existing = inventoryBox.get(safeId);
      if (existing != null) {
        final m = Map<String, dynamic>.from(existing);
        final current = ((m['quantity'] ?? 0) as num).toDouble();
        m['quantity'] = current + incomingQty;
        m['unit'] = (item['unit'] ?? m['unit']);
        m['category'] = (item['category'] ?? m['category']);
        m['offline'] = true;
        m['source'] = 'Manual_edit';
        m['dateAdded'] = DateTime.now().toIso8601String();
        await inventoryBox.put(safeId, m);
      } else {
        final m = Map<String, dynamic>.from(item)
          ..['id'] = safeId
          ..['offline'] = true
          ..['source'] = 'Manual_edit'
          ..['dateAdded'] = DateTime.now().toIso8601String();
        await inventoryBox.put(safeId, m);
      }
    }

    _loadLocal();
  }

  Future<void> deleteItems(List<String> ids) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //print('\x1B[34m[DEBUG] Cannot delete items: not logged in\x1B[0m');
      blueDebugPrint('Cannot delete items: User not logged in');
      return;
    }
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');
    if (await _isOnline()) {
      for (var id in ids) {
        await ref.doc(id).delete();
        //print('\x1B[34m[DEBUG] Deleted item online: $id\x1B[0m');
        blueDebugPrint('Deleted item online: $id');
        await inventoryBox.delete(id);
      }
    } else {
      // Only delete locally
      for (var id in ids) {
        await inventoryBox.delete(id);
        //print('\x1B[34m[DEBUG] Deleted item offline: $id\x1B[0m');
        blueDebugPrint('Deleted item offline: $id');
      }
    }
    _loadLocal();
  }

  Future<void> syncLocalToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //print('\x1B[34m[DEBUG] Cannot sync: not logged in\x1B[0m');
      blueDebugPrint('Cannot sync: not logged in');
      return;
    }
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');
    //print('\x1B[34m[DEBUG] Syncing offline changes to Firestore...\x1B[0m');
    blueDebugPrint('Syncing offline changes to Firestore...');
    for (var item in inventoryBox.values) {
      final m = Map<String, dynamic>.from(item);
      if (m['offline'] == true) {
        String safeName = (m['itemName'] ?? '').replaceAll(RegExp(r'[\/\\.#\$\\[\\]]'), '_');
        if (safeName.isEmpty) {
          safeName = m['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        }
        await ref.doc(safeName).set(m, SetOptions(merge: true));
        m['id'] = safeName;
        await inventoryBox.put(safeName, m);
        //print('\x1B[34m[DEBUG] Synced item online: $safeName\x1B[0m');
        blueDebugPrint('Synced item online: $safeName');
      }
    }
    _loadLocal();
  }

  @override
  void dispose() {
    firestoreSub?.cancel();
    connectivitySub?.cancel();
    authSub?.cancel();
    //print('\x1B[34m[DEBUG] InventoryController disposed\x1B[0m');
    blueDebugPrint('InventoryController disposed');
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
      await inventoryBox.put(item['id'], item);
    }
  }
}
