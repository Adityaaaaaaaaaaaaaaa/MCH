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
  late Box _inventoryBox;
  StreamSubscription? _firestoreSub;
  StreamSubscription? _connectivitySub;
  bool _isListeningFirestore = false;

  InventoryController() : super([]) {
    _init();
  }

  Future<void> _init() async {
    print('\x1B[34m[DEBUG] Initializing InventoryController\x1B[0m');
    _inventoryBox = await Hive.openBox('inventoryBox');
    _loadLocal();
    _listenConnectivity();
    if (await _isOnline()) {
      _listenFirestore();
    }
  }

  void _loadLocal() {
    print('\x1B[34m[DEBUG] Loading inventory from Hive\x1B[0m');
    state = _inventoryBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
    print('\x1B[34m[DEBUG] Current local state: $state\x1B[0m');
  }

  void _listenFirestore() {
    if (_isListeningFirestore) {
      print('\x1B[34m[DEBUG] Already listening to Firestore, skipping re-listen\x1B[0m');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('\x1B[34m[DEBUG] No user for Firestore listen\x1B[0m');
      return;
    }
    print('\x1B[34m[DEBUG] Listening to Firestore: users/${user.uid}/inventory\x1B[0m');
    _isListeningFirestore = true;
    _firestoreSub?.cancel();
    _firestoreSub = FirebaseFirestore.instance
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
            _inventoryBox.put(item['id'], item);
          }
        }, onDone: () {
          _isListeningFirestore = false;
          print('\x1B[34m[DEBUG] Firestore listen closed\x1B[0m');
        }, onError: (e) {
          _isListeningFirestore = false;
          print('\x1B[34m[DEBUG] Firestore listen error: $e\x1B[0m');
        });
  }

  void _listenConnectivity() {
    print('\x1B[34m[DEBUG] Listening for connectivity changes\x1B[0m');
    _connectivitySub = Connectivity().onConnectivityChanged.listen((status) async {
      print('\x1B[34m[DEBUG] Connectivity changed: $status\x1B[0m');
      if (await _isOnline()) {
        _listenFirestore();
        await syncLocalToFirestore();
      } else {
        _firestoreSub?.cancel();
        _isListeningFirestore = false;
        _loadLocal();
      }
    });
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    print('\x1B[34m[DEBUG] Online check: ${result != ConnectivityResult.none}\x1B[0m');
    return result != ConnectivityResult.none;
  }

  Future<void> addOrUpdateItem(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('\x1B[34m[DEBUG] Cannot add/update item: not logged in\x1B[0m');
      return;
    }
    if (await _isOnline()) {
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');
      if (item['id'] != null) {
        await ref.doc(item['id']).set(item);
        print('\x1B[34m[DEBUG] Updated item online: ${item['id']}\x1B[0m');
      } else {
        final doc = await ref.add(item);
        item['id'] = doc.id;
        print('\x1B[34m[DEBUG] Added new item online: ${doc.id}\x1B[0m');
      }
      item['offline'] = false;
    } else {
      // Add to Hive and mark as offline
      final id = item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      item['id'] = id;
      item['offline'] = true;
      if (item['dateAdded'] is int) {
        item['dateAdded'] = Timestamp.fromMillisecondsSinceEpoch(item['dateAdded']);
      }
      await _inventoryBox.put(id, item);
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
    if (await _isOnline()) {
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('inventory');
      for (var id in ids) {
        await ref.doc(id).delete();
        print('\x1B[34m[DEBUG] Deleted item online: $id\x1B[0m');
        await _inventoryBox.delete(id);
      }
    } else {
      // Only delete locally
      for (var id in ids) {
        await _inventoryBox.delete(id);
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
    for (var item in _inventoryBox.values) {
      final m = Map<String, dynamic>.from(item);
      if (m['offline'] == true) {
        if (m['id'] != null) {
          await ref.doc(m['id']).set(m);
        } else {
          final doc = await ref.add(m);
          m['id'] = doc.id;
        }
        m['offline'] = false;
        await _inventoryBox.put(m['id'], m);
        print('\x1B[34m[DEBUG] Synced item online: ${m['id']}\x1B[0m');
      }
    }
    _loadLocal();
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    _connectivitySub?.cancel();
    print('\x1B[34m[DEBUG] InventoryController disposed\x1B[0m');
    super.dispose();
  }
}
