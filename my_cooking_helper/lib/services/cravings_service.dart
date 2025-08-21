// /lib/features/cravings/cravings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CravingsContext {
  final List<String> allergies;
  final List<String> cuisines;
  final List<String> diets;
  final String? spiceLabel;
  final int spiceLevel;
  final List<String> ingredients;

  const CravingsContext({
    required this.allergies,
    required this.cuisines,
    required this.diets,
    required this.spiceLabel,
    required this.spiceLevel,
    required this.ingredients,
  });
}

// --- small helper model for preferences (moved outside) ---
class _Prefs {
  final List<String> allergies;
  final List<String> cuisines;
  final List<String> diets;
  final String? spiceLabel;

  const _Prefs({
    required this.allergies,
    required this.cuisines,
    required this.diets,
    required this.spiceLabel,
  });
}

class CravingsService {
  CravingsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<CravingsContext> loadUserCravingsContext(String userId) async {
    final prefs = await _fetchUserPreferences(userId);
    final ingredients = await _fetchInventoryIngredientNames(userId);

    final spiceLabel = prefs.spiceLabel;
    final spiceLevel = _mapSpiceLabelToLevel(spiceLabel);

    final userPref = CravingsContext(
      allergies: prefs.allergies,
      cuisines: prefs.cuisines,
      diets: prefs.diets,
      spiceLabel: spiceLabel,
      spiceLevel: spiceLevel,
      ingredients: ingredients,
    );

    _blue('[DEBUG][Cravings] Context for $userId');
    _blue('  Allergies : ${userPref.allergies}');
    _blue('  Cuisines  : ${userPref.cuisines}');
    _blue('  Diets     : ${userPref.diets}');
    _blue('  Spice     : ${userPref.spiceLabel} -> $spiceLevel');
    _blue('  Inventory : ${userPref.ingredients}');

    return userPref;
  }

  Future<_Prefs> _fetchUserPreferences(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) {
      _blue('[DEBUG][Cravings] No doc for $userId, using defaults');
      return const _Prefs(
        allergies: <String>[],
        cuisines: <String>[],
        diets: <String>[],
        spiceLabel: null,
      );
    }

    final data = doc.data() ?? {};
    final prefs = (data['preferences'] as Map<String, dynamic>?) ?? {};

    // ignore: no_leading_underscores_for_local_identifiers
    List<String> _list(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? <String>[];

    return _Prefs(
      allergies: _list(prefs['allergies']),
      cuisines: _list(prefs['cuisines']),
      diets: _list(prefs['diets']),
      spiceLabel: prefs['spiceLevel']?.toString(),
    );
  }

  Future<List<String>> _fetchInventoryIngredientNames(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .get();

    return snap.docs.map((doc) => doc.id.toString()).toList();
  }

  static const Map<String, int> _spiceMap = {
    'no spice (plain jane)': 0,
    'gentle warmth (mild)': 1,
    'balanced kick (medium)': 2,
    'bring the heat (spicy)': 3,
    'rip (super spicy!)': 4,
    'mystery heat (surprise me!)': 5,
    "spice? i'm open!": 6,
  };

  int _mapSpiceLabelToLevel(String? label) {
    if (label == null) return 2;
    final key = label.trim().toLowerCase();
    return _spiceMap[key] ??
        _spiceMap.entries
            .firstWhere(
              (e) => e.key.contains(key) || key.contains(e.key),
              orElse: () => const MapEntry('balanced kick (medium)', 2),
            )
            .value;
  }

  void _blue(Object msg) {
    print('\x1B[34m$msg\x1B[0m');
  }
}
