import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class CravingsService {
  CravingsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // --- Public API -------------------------------------------------------------

  /// Fetch defaults from Firestore: allergies, cuisines, diets, spice label/level, inventory.
  /// Returns a map you can keep in state.
  Future<Map<String, dynamic>> fetchDefaults(String userId) async {
    final prefs = await _getUserPrefs(userId);
    final inv   = await _getInventory(userId);

    final spiceLabel = prefs['spiceLabel'] as String?;
    final spiceLevel = _mapSpiceLabelToLevel(spiceLabel); // 0..5 (5 = random)

    final defaults = <String, dynamic>{
      'allergies': prefs['allergies'] as List<String>,
      'cuisines':  prefs['cuisines']  as List<String>,
      'diets':     prefs['diets']     as List<String>,
      'spiceLabel': spiceLabel,
      'spiceLevel': spiceLevel, // 0..5
      'inventory': inv,         // List<String>
    };

    _blue('[DEBUG][Cravings] Firestore defaults for $userId');
    _blue('  Allergies : ${defaults['allergies']}');
    _blue('  Cuisines  : ${defaults['cuisines']}');
    _blue('  Diets     : ${defaults['diets']}');
    _blue('  Spice     : $spiceLabel -> $spiceLevel');
    _blue('  Inventory : ${defaults['inventory']}');

    return defaults;
  }

  /// Log user selection changes (blue).
  void debugUserSelection({int? spiceFixedLevel, bool? randomEnabled, int? timeMinutes}) {
    if (spiceFixedLevel != null) {
      _blue('[DEBUG][Cravings] User changed spice (fixed) -> $spiceFixedLevel');
    }
    if (randomEnabled != null) {
      _blue('[DEBUG][Cravings] User toggled random spice -> ${randomEnabled ? 'ON' : 'OFF'}');
    }
    if (timeMinutes != null) {
      _blue('[DEBUG][Cravings] User changed time -> ${timeMinutes}m');
    }
  }

  /// Build the final payload for backend and print it (blue).
  /// If [randomSpice] is true, we pick a random 0..4 locally (per your spec).
  Map<String, dynamic> buildFinalBundle({
    required String userId,
    required String query,
    required Map<String, dynamic> defaults, // from fetchDefaults
    required bool randomSpice,
    required int? fixedSpiceLevel, // 0..4 (ignored if random)
    required int timeMinutes,      // final time
  }) {
    final resolvedSpice = randomSpice
        ? Random().nextInt(5) // 0..4
        : (fixedSpiceLevel ?? (defaults['spiceLevel'] as int).clamp(0, 4));

    final bundle = <String, dynamic>{
      'userId': userId,
      'query': query,
      'allergies': defaults['allergies'],
      'cuisines':  defaults['cuisines'],
      'diets':     defaults['diets'],
      'inventory': defaults['inventory'],
      'spice': {
        'random': randomSpice,
        'requestedLevel': randomSpice ? 5 : (fixedSpiceLevel ?? defaults['spiceLevel']),
        'resolvedLevel': resolvedSpice, // always 0..4
      },
      'maxTimeMinutes': timeMinutes,    // final time (user or default 90)
    };

    _blue('[DEBUG][Cravings] FINAL BUNDLE → $bundle');
    return bundle;
  }

  // --- Internals -------------------------------------------------------------

  Future<Map<String, dynamic>> _getUserPrefs(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      _blue('[DEBUG][Cravings] No user doc for $userId. Using empty prefs.');
      return {
        'allergies': <String>[],
        'cuisines':  <String>[],
        'diets':     <String>[],
        'spiceLabel': null,
      };
    }
    final data  = doc.data() ?? {};
    final prefs = (data['preferences'] as Map<String, dynamic>?) ?? {};

    List<String> _list(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? <String>[];

    return {
      'allergies': _list(prefs['allergies']),
      'cuisines':  _list(prefs['cuisines']),
      'diets':     _list(prefs['diets']),
      'spiceLabel': prefs['spiceLevel']?.toString(),
    };
  }

  Future<List<String>> _getInventory(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .get();
    return snap.docs.map((d) => d.id.toString()).toList();
  }

  static const Map<String, int> _spiceMap = {
    'no spice (plain jane)': 0,
    'gentle warmth (mild)': 1,
    'balanced kick (medium)': 2,
    'bring the heat (spicy)': 3,
    'rip (super spicy!)': 4,
    'mystery heat (surprise me!)': 5, // random
    "spice? i'm open!": 5,            // random
  };

  int _mapSpiceLabelToLevel(String? label) {
    if (label == null) return 2; // default medium
    final key = label.trim().toLowerCase();
    if (_spiceMap.containsKey(key)) return _spiceMap[key]!;
    // soft match
    return _spiceMap.entries
        .firstWhere(
          (e) => e.key.contains(key) || key.contains(e.key),
          orElse: () => const MapEntry('balanced kick (medium)', 2),
        )
        .value;
  }

  void _blue(Object msg) {
    // ignore: avoid_print
    print('\x1B[34m$msg\x1B[0m');
  }
}
