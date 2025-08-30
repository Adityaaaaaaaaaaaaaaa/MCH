// lib/services/shopping_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/models/cravings.dart'; // for ShoppingItemModel if you keep using it

// If you prefer a lighter model only for the list UI, you can define your own.
// Here we reuse ShoppingItemModel { name, need, unit, have, tag } for continuity.

class ShoppingService extends StateNotifier<List<ShoppingItemModel>> {
  ShoppingService() : super(const []);

  String? _activeListId; // null means not "created" yet (pre-commit buffer)

  String? get activeListId => _activeListId;
  bool get hasActiveList => _activeListId != null;

  /// Add or update an item in the working buffer
  void setItem({ required String name, required String tag, double? need, String? unit, double have = 0 }) {
    final idx = state.indexWhere((e) => e.name.trim().toLowerCase() == name.trim().toLowerCase());
    final item = ShoppingItemModel(
      name: name,
      need: (need == null || need <= 0) ? 1 : need,
      unit: (unit == null || unit.isEmpty) ? 'count' : unit,
      have: have,
      tag: tag,  // 'buy' or 'add'
    );
    if (idx == -1) {
      state = [...state, item];
    } else {
      final copy = [...state]; copy[idx] = item; state = copy;
    }
    // ignore: avoid_print
    print('\x1B[34m[SVC] SET  ${item.tag} | ${item.name} | ${item.need} ${item.unit}\x1B[0m');
  }

  void removeItem(String name) {
    state = state.where((e) => e.name.trim().toLowerCase() != name.trim().toLowerCase()).toList();
    // ignore: avoid_print
    print('\x1B[34m[SVC] REMOVE  $name\x1B[0m');
  }

  void clearAll() {
    state = const [];
    _activeListId = null;
    // ignore: avoid_print
    print('\x1B[34m[SVC] CLEAR ALL\x1B[0m');
  }

  /// Called by the CTA when turning GREEN (“create list”).
  /// If a list already exists, you can choose to no-op or refresh the timestamp.
  /// For now, we only create once and return the id.
  String createListIfAbsent() {
    if (_activeListId != null) return _activeListId!;
    // generate a simple id (timestamp). Replace with Firestore doc id if you persist.
    _activeListId = DateTime.now().millisecondsSinceEpoch.toString();
    // TODO: persist `state` under `_activeListId` in Firestore if needed.
    return _activeListId!;
  }

  // UI helpers
  int get totalCount => state.length;
  List<ShoppingItemModel> get buyItems => state.where((e) => e.tag.toLowerCase() == 'buy').toList();
  List<ShoppingItemModel> get addItems => state.where((e) => e.tag.toLowerCase() == 'add').toList();
}

// Global provider
final shoppingServiceProvider =
    StateNotifierProvider<ShoppingService, List<ShoppingItemModel>>((ref) {
  return ShoppingService();
});
