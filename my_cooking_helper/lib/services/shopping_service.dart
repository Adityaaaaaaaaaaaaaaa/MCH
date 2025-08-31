// lib/services/shopping_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/models/cravings.dart'; // ShoppingItemModel { name, need, unit, have, tag }

// Map a name to a stable doc id
String _docIdFromName(String name) {
  final s = name.trim().toLowerCase();
  final id = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  return id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id;
}

class ShoppingService extends StateNotifier<List<ShoppingItemModel>> {
  ShoppingService() : super(const []) {
    _init();
  }

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  StreamSubscription<User?>? _userSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _snapSub;
  CollectionReference<Map<String, dynamic>>? _col;

  String? _activeListId; // optional "created" marker for your CTA
  String? get activeListId => _activeListId;
  bool get hasActiveList => _activeListId != null;

  Future<void> _init() async {
    // Enable Firestore offline cache (safe to call repeatedly)
    try {
      _db.settings = const Settings(persistenceEnabled: true);
    } catch (_) {/* already set */}
    _userSub = _auth.userChanges().listen(_bindForUser);
    _bindForUser(_auth.currentUser);
  }

  void _bindForUser(User? user) {
    _snapSub?.cancel();
    _snapSub = null;
    _col = null;

    if (user == null) {
      state = const []; // ← clear local state when signed out
      print('\x1B[34m[SHOP SVC] user=null → local-only mode\x1B[0m');
      return;
    }

    _col = _db.collection('users').doc(user.uid).collection('shopping');

    _snapSub = _col!
        .orderBy('name')
        .snapshots()
        .listen((snap) {
          final items = snap.docs.map((d) {
            final m = d.data();
            return ShoppingItemModel(
              name: (m['name'] ?? d.id) as String,
              need: (m['need'] as num?)?.toDouble() ?? 1.0,
              unit: (m['unit'] as String?)?.trim() ?? 'count',
              have: (m['have'] as num?)?.toDouble() ?? 0.0,
              tag: (m['tag'] as String?) ?? '',
            );
          }).toList();
          state = items;
          // ignore: avoid_print
          print('\x1B[34m[SHOP SVC] snapshot → ${items.length} item(s)\x1B[0m');
        }, onError: (e, _) {
          // ignore: avoid_print
          print('\x1B[31m[SHOP SVC] snapshot error: $e\x1B[0m');
        });
  }

  // =================== PUBLIC API used by your pages ===================

  /// Add or update an item (optimistic + write-through).
  /// `unit` is constrained by UI (g/ml/count); we still default to 'count'.
  Future<void> addOrUpdate({
    required String name,
    double? need,
    String? unit,
    double have = 0,
    String tag = '',
  }) async {
    final fixedNeed = (need == null || need <= 0) ? 1.0 : need;
    final normalizedUnit = (unit == null || unit.isEmpty) ? 'count' : unit;

    // Local optimistic update
    final idx = state.indexWhere(
      (e) => e.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );
    final next = ShoppingItemModel(
      name: name,
      need: fixedNeed,
      unit: normalizedUnit,
      have: have,
      tag: tag,
    );
    if (idx == -1) {
      state = [...state, next];
    } else {
      final copy = [...state];
      copy[idx] = next;
      state = copy;
    }
    // ignore: avoid_print
    print('\x1B[34m[SVC] SET  ${next.name} | ${next.need} ${next.unit} | tag=${next.tag}\x1B[0m');

    // Remote write (queued offline as needed)
    if (_col != null) {
      final id = _docIdFromName(name);
      await _col!.doc(id).set({
        'name': name,
        'need': fixedNeed,
        'unit': normalizedUnit,
        'have': have,
        'tag': tag,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Remove by name (local + remote).
  Future<void> remove(String name) async {
    state = state
        .where((e) => e.name.trim().toLowerCase() != name.trim().toLowerCase())
        .toList();
    // ignore: avoid_print
    print('\x1B[34m[SVC] REMOVE  $name\x1B[0m');

    if (_col != null) {
      final id = _docIdFromName(name);
      await _col!.doc(id).delete();
    }
  }

  /// Clear entire list (local + remote).
  Future<void> clearAll() async {
    state = const [];
    _activeListId = null;
    // ignore: avoid_print
    print('\x1B[34m[SVC] CLEAR ALL\x1B[0m');

    if (_col != null) {
      final snapshot = await _col!.get();
      if (snapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final d in snapshot.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }
  }

  /// Optional CTA hook (no remote op needed).
  String createListIfAbsent() {
    if (_activeListId != null) return _activeListId!;
    _activeListId = DateTime.now().millisecondsSinceEpoch.toString();
    return _activeListId!;
  }

  // =================== BACK-COMPAT wrappers (tiles still call these) ===================

  Future<void> setItem({
    required String name,
    required String tag,
    double? need,
    String? unit,
    double have = 0,
  }) async {
    await addOrUpdate(name: name, need: need, unit: unit, have: have, tag: tag);
  }

  Future<void> removeItem(String name) async {
    await remove(name);
  }

  // Convenience
  int get totalCount => state.length;

  @override
  void dispose() {
    _snapSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}

// Provider
final shoppingServiceProvider =
    StateNotifierProvider<ShoppingService, List<ShoppingItemModel>>((ref) {
  return ShoppingService();
});
