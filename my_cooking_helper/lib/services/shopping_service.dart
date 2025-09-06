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
    } catch (_) {}
    _userSub = _auth.userChanges().listen(_bindForUser);
    _bindForUser(_auth.currentUser);
  }

  // robust number parse (also handles "1,5" keyboards)
  static double _numParse(dynamic v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? fallback;
    return fallback;
  }

  // clamp by unit so weird values can't sneak in
  static double _clampByUnit(double v, String unitRaw) {
    final u = (unitRaw).trim().toLowerCase();
    if (u.isEmpty || u == 'count') return v.clamp(0, 999).toDouble();
    if (u == 'g' || u == 'ml')     return v.clamp(0, 99000).toDouble(); // 99 kg/L in base units
    return v.clamp(0, 9999).toDouble();
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
            need: _numParse(m['need'], fallback: 1.0),
            unit: ((m['unit'] as String?) ?? 'count').trim(),
            have: _numParse(m['have'], fallback: 0.0),
            tag:  (m['tag'] as String?) ?? '',
          );
        }).toList();
        state = items;
        print('\x1B[34m[SHOP SVC] snapshot → ${items.length} item(s)\x1B[0m');
      }, onError: (e, _) {
        print('\x1B[31m[SHOP SVC] snapshot error: $e\x1B[0m');
      });
  }

  // =================== PUBLIC API used by your pages ===================

  /// Add or update an item (optimistic + write-through).
  /// `unit` is constrained by UI (g/ml/count); we still default to 'count'.
  /// we ACCUMULATE the quantity instead of overwriting it.
  Future<void> addOrUpdate({
    required String name,
    double? need,
    String? unit,
    double have = 0,
    String tag = '',
  }) async {
    final normalizedUnit = (unit ?? 'count').trim().toLowerCase();
    final rawNeed = _numParse(need ?? 1, fallback: 1);
    final rawHave = _numParse(have, fallback: 0);

    // base clamps
    final incomingNeed = _clampByUnit(rawNeed <= 0 ? 1.0 : rawNeed, normalizedUnit);
    final incomingHave = _clampByUnit(rawHave < 0 ? 0.0 : rawHave, normalizedUnit);

    final idx = state.indexWhere(
      (e) => e.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );

    double finalNeed = incomingNeed;
    double finalHave = incomingHave;
    String finalUnit = normalizedUnit;
    String finalTag  = tag;

    if (idx != -1) {
      // Existing item found
      final existing = state[idx];

      // If unit matches, ACCUMULATE the 'need'
      if ((existing.unit.trim().toLowerCase()) == normalizedUnit) {
        finalNeed = _clampByUnit(existing.need + incomingNeed, normalizedUnit);
        // keep the larger 'have' (or just keep existing)
        finalHave = _clampByUnit(existing.have, normalizedUnit);
        // keep existing unit and tag unless caller explicitly provides tag
        finalUnit = existing.unit;
        if (finalTag.isEmpty) finalTag = existing.tag;

        // BLUE debug
        // ignore: avoid_print
        print('\x1B[34m[SVC] MERGE  $name | +$incomingNeed $normalizedUnit → $finalNeed $finalUnit | tag=${finalTag.isEmpty ? existing.tag : finalTag}\x1B[0m');
      } else {
        // Different unit → treat as an override (same as previous behavior)
        // keep incoming values; optionally keep existing tag if none provided
        if (finalTag.isEmpty) finalTag = existing.tag;
        // BLUE debug
        // ignore: avoid_print
        print('\x1B[34m[SVC] OVERRIDE  $name | unit change ${existing.unit} → $normalizedUnit | set=$finalNeed $finalUnit | tag=$finalTag\x1B[0m');
      }
    } else {
      // New item
      // ignore: avoid_print
      print('\x1B[34m[SVC] ADD  $name | $finalNeed $finalUnit | tag=$finalTag\x1B[0m');
    }

    // Local optimistic update
    final next = ShoppingItemModel(
      name: name,
      need: finalNeed,
      unit: finalUnit,
      have: finalHave,
      tag: finalTag,
    );

    if (idx == -1) {
      state = [...state, next];
    } else {
      final copy = [...state];
      copy[idx] = next;
      state = copy;
    }

    // Remote write (queued offline as needed)
    if (_col != null) {
      final id = _docIdFromName(name);
      print('\x1B[34m[SHOP SVC] → FS write "${_docIdFromName(name)}"\x1B[0m');
      await _col!.doc(id).set({
        'name': name,
        'need': finalNeed,
        'unit': finalUnit,
        'have': finalHave,
        'tag': finalTag,
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

  /// Decrease 'need' in the shopping list when inventory increases.
  /// - Matches by normalized name (same slug you already use)
  /// - Only deducts when units match ('g' | 'ml' | 'count')
  /// - Deletes the item when the remaining need is <= 0
  static Future<void> deductForInventoryIncrease({
    required String name,
    required double delta,   // how much inventory increased
    required String unit,    // 'g' | 'ml' | 'count'
  }) async {
    if (delta <= 0) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db  = FirebaseFirestore.instance;
    final col = db.collection('users').doc(user.uid).collection('shopping');
    final id  = _docIdFromName(name);

    await db.runTransaction((tx) async {
      final ref  = col.doc(id);
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final shopUnit = ((data['unit'] as String?) ?? 'count').trim().toLowerCase();
      final invUnit  = unit.trim().toLowerCase();

      if (shopUnit != invUnit) {
        // ignore: avoid_print
        print('\x1B[34m[SHOP SVC] skip deduct (unit mismatch) "$shopUnit" vs "$invUnit" for "$name"\x1B[0m');
        return;
      }

      final currentNeed = _numParse(data['need'], fallback: 0.0);
      final remaining   = currentNeed - delta;

      // tiny epsilon to avoid -1e-15 float leftovers
      const eps = 1e-9;
      if (remaining <= eps) {
        tx.delete(ref);
        print('\x1B[34m[SHOP SVC] quota met → removed "$name" from shopping list\x1B[0m');
        return;
      }

      // keep it clamped/clean
      final newNeed = _clampByUnit(remaining, shopUnit);
      tx.set(ref, {
        'need': newNeed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('\x1B[34m[SHOP SVC] deduct $delta $shopUnit from "$name" → need=$newNeed\x1B[0m');
    });
  }
}

// Provider
final shoppingServiceProvider =
    StateNotifierProvider<ShoppingService, List<ShoppingItemModel>>((ref) {
  return ShoppingService();
});
