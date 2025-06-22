import 'dart:async';
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

  InventoryController() : super([]) {
    _init();
  }

  Future<void> _init() async {
    print('\x1B[34m[DEBUG] Initializing InventoryController\x1B[0m');
    inventoryBox = await Hive.openBox('inventoryBox');
    _loadLocal();
    _listenConnectivity();
    if (await _isOnline()) {
      _listenFirestore();
    }
  }

  void _loadLocal() {
    print('\x1B[34m[DEBUG] Loading inventory from Hive\x1B[0m');
    state = inventoryBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
    print('\x1B[34m[DEBUG] Current local state: $state\x1B[0m');
  }

  void _listenFirestore() {
    if (isListeningFirestore) {
      print('\x1B[34m[DEBUG] Already listening to Firestore, skipping re-listen\x1B[0m');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('\x1B[34m[DEBUG] No user for Firestore listen\x1B[0m');
      return;
    }
    print('\x1B[34m[DEBUG] Listening to Firestore: users/${user.uid}/inventory\x1B[0m');
    isListeningFirestore = true;
    firestoreSub?.cancel();
    firestoreSub = FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('inventory')
        .snapshots()
        .listen((snapshot) {
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
          print('\x1B[34m[DEBUG] Firestore state updated: $state\x1B[0m');
          // Save to Hive
          for (var item in state) {
            inventoryBox.put(item['id'], item);
          }
        }, onDone: () {
          isListeningFirestore = false;
          print('\x1B[34m[DEBUG] Firestore listen closed\x1B[0m');
        }, onError: (e) {
          isListeningFirestore = false;
          print('\x1B[34m[DEBUG] Firestore listen error: $e\x1B[0m');
        });
  }

  void _listenConnectivity() {
    print('\x1B[34m[DEBUG] Listening for connectivity changes\x1B[0m');
    connectivitySub = Connectivity().onConnectivityChanged.listen((status) async {
      print('\x1B[34m[DEBUG] Connectivity changed: $status\x1B[0m');
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
    print('\x1B[34m[DEBUG] Online check: ${result != ConnectivityResult.none}\x1B[0m');
    return result != ConnectivityResult.none;
  }

  // Accepts an extra previousId parameter for renames
  Future<void> addOrUpdateItem(Map<String, dynamic> item, {String? previousId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('\x1B[34m[DEBUG] Cannot add/update item: not logged in\x1B[0m');
      return;
    }

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');

    // Use the itemName as document ID, safely formatted
    String newId = (item['itemName'] ?? '').replaceAll(RegExp(r'[\/\\.#\$\\[\\]]'), '_');
    if (newId.isEmpty) {
      // fallback: use id or timestamp
      newId = item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    }

    if (await _isOnline()) {
      // If renaming, delete old doc
      if (previousId != null && previousId != newId) {
        try {
          await ref.doc(previousId).delete();
          await inventoryBox.delete(previousId);
          print('\x1B[34m[DEBUG] Deleted old item: $previousId\x1B[0m');
        } catch (e) {
          print('\x1B[34m[DEBUG] Error deleting old item: $e\x1B[0m');
        }
      }

      // Save the new/updated item
      await ref.doc(newId).set(item, SetOptions(merge: true));
      item['id'] = newId;
      item['offline'] = false;
      await inventoryBox.put(newId, item);
      print('\x1B[34m[DEBUG] Saved/Updated item online: $newId\x1B[0m');
    } else {
      // Add to Hive and mark as offline
      final id = item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      item['id'] = id;
      item['offline'] = true;
      if (item['dateAdded'] is int) {
        item['dateAdded'] = Timestamp.fromMillisecondsSinceEpoch(item['dateAdded']);
      }
      await inventoryBox.put(id, item);
      print('\x1B[34m[DEBUG] Saved item offline: $id\x1B[0m');
    }
    _loadLocal();
  }

  Future<void> deleteItems(List<String> ids) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('\x1B[34m[DEBUG] Cannot delete items: not logged in\x1B[0m');
      return;
    }
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');
    if (await _isOnline()) {
      for (var id in ids) {
        await ref.doc(id).delete();
        print('\x1B[34m[DEBUG] Deleted item online: $id\x1B[0m');
        await inventoryBox.delete(id);
      }
    } else {
      // Only delete locally
      for (var id in ids) {
        await inventoryBox.delete(id);
        print('\x1B[34m[DEBUG] Deleted item offline: $id\x1B[0m');
      }
    }
    _loadLocal();
  }

  Future<void> syncLocalToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('\x1B[34m[DEBUG] Cannot sync: not logged in\x1B[0m');
      return;
    }
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');
    print('\x1B[34m[DEBUG] Syncing offline changes to Firestore...\x1B[0m');
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
        print('\x1B[34m[DEBUG] Synced item online: $safeName\x1B[0m');
      }
    }
    _loadLocal();
  }

  @override
  void dispose() {
    firestoreSub?.cancel();
    connectivitySub?.cancel();
    print('\x1B[34m[DEBUG] InventoryController disposed\x1B[0m');
    super.dispose();
  }
}
