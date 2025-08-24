// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '/config/backend_config.dart';
import '/models/cravings.dart';

class CravingsService {
  CravingsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ───────────────────────────── Public API ─────────────────────────────

  /// Fetch defaults from Firestore: allergies, cuisines, diets, spice label/level, inventory (names).
  /// Returns a map you can keep in state.
  Future<Map<String, dynamic>> fetchDefaults(String userId) async {
    final prefs = await _getUserPrefs(userId);
    final invNames = await _getInventoryNames(userId);

    final spiceLabel = prefs['spiceLabel'] as String?;
    final spiceLevel = _mapSpiceLabelToLevel(spiceLabel); // 0..5 (5=random)

    final defaults = <String, dynamic>{
      'allergies': prefs['allergies'] as List<String>,
      'cuisines': prefs['cuisines'] as List<String>,
      'diets': prefs['diets'] as List<String>,
      'spiceLabel': spiceLabel,
      'spiceLevel': spiceLevel,
      'inventory': invNames,
    };

    _blue('[DEBUG][Cravings] Firestore defaults for $userId');
    _blue('  Allergies : ${defaults['allergies']}');
    _blue('  Cuisines  : ${defaults['cuisines']}');
    _blue('  Diets     : ${defaults['diets']}');
    _blue('  Spice     : $spiceLabel -> $spiceLevel');
    _blue('  Inventory : ${defaults['inventory']}');

    return defaults;
  }

  /// Log user selection changes (always with ANSI reset).
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
  /// If [randomSpice] is true, a local 0..4 level is resolved as per spec.
  Future<Map<String, dynamic>> buildFinalBundle({
    required String userId,
    required String query,
    required Map<String, dynamic> defaults,
    required bool randomSpice,
    int? fixedSpiceLevel, // null if random
    required int timeMinutes,
  }) async {
    final invDetailed = await fetchInventoryDetailed(userId);

    // Resolve spice: 0..4 only
    final resolved = randomSpice
        ? (DateTime.now().millisecondsSinceEpoch % 5)
        : (fixedSpiceLevel ?? (defaults['spiceLevel'] as int)).clamp(0, 4);

    final payload = {
      'userId': userId,
      'query': query,
      'constraints': {
        'maxTimeMinutes': timeMinutes,
        'spice': {
          'random': randomSpice,
          'requestedLevel': fixedSpiceLevel,
          'resolvedLevel': resolved,
        },
      },
      'preferences': {
        'allergies': defaults['allergies'] as List<String>,
        'cuisines': defaults['cuisines'] as List<String>,
        'diets': defaults['diets'] as List<String>,
      },
      // Detailed inventory with quantities and units
      'inventory': invDetailed,
    };

    _blue('[DEBUG][Cravings] FINAL BUNDLE → $payload');
    return payload;
  }

  // ───────────────────────────── Internals ─────────────────────────────

  Future<Map<String, dynamic>> _getUserPrefs(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      _blue('[DEBUG][Cravings] No user doc for $userId. Using empty prefs.');
      return {
        'allergies': <String>[],
        'cuisines': <String>[],
        'diets': <String>[],
        'spiceLabel': null,
      };
    }
    final data = doc.data() ?? {};
    final prefs = (data['preferences'] as Map<String, dynamic>?) ?? {};

    List<String> _list(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? <String>[];

    return {
      'allergies': _list(prefs['allergies']),
      'cuisines': _list(prefs['cuisines']),
      'diets': _list(prefs['diets']),
      'spiceLabel': prefs['spiceLevel']?.toString(),
    };
  }

  /// Inventory names only (for quick logs / hints).
  Future<List<String>> _getInventoryNames(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .get();
    return snap.docs.map((d) => d.id.toString()).toList();
  }

  /// Detailed inventory for backend: [{name, quantity, unit}, ...]
  Future<List<Map<String, dynamic>>> fetchInventoryDetailed(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .get();

    final items = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final rawQty = data['quantity'];
      final qty = (rawQty is num) ? rawQty.toDouble() : 0.0;

      items.add({
        'name': doc.id.toString(),
        'quantity': qty, // double
        'unit': (data['unit'] ?? 'count').toString(), // normalize unit
      });
    }
    _blue('[DEBUG][Cravings] Inventory(detailed) count=${items.length}');
    for (final it in items.take(10)) {
      _blue('  - ${it['name']}: ${it['quantity']} ${it['unit']}');
    }
    if (items.length > 10) {
      _blue('  ... +${items.length - 10} more');
    }

    return items;
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
    final exact = _spiceMap[key];
    if (exact != null) return exact;

    // Soft match
    for (final e in _spiceMap.entries) {
      if (e.key.contains(key) || key.contains(e.key)) return e.value;
    }
    return 2;
  }

  /// POST the final bundle to your backend.
  /// - [aiRecipeUrl] e.g. "$backendApiUrl/recipes/aiRecipe" which we imported from config.
  /// - This method intentionally returns void (for now) and logs status + preview.
  Future<void> postAiRecipeBundle({
    required String userId,
    required String query,
    required Map<String, dynamic> defaults,
    required bool randomSpice,
    int? fixedSpiceLevel,
    required int timeMinutes,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    // Build bundle (also logs inventory details and final payload summary).
    final payload = await buildFinalBundle(
      userId: userId,
      query: query,
      defaults: defaults,
      randomSpice: randomSpice,
      fixedSpiceLevel: fixedSpiceLevel,
      timeMinutes: timeMinutes,
    );

    try {
      _blue('[DEBUG][Cravings] POST → $aiRecipe');
      final resp = await http
          .post(
            Uri.parse(aiRecipe),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      _blue('[DEBUG][Cravings] Backend responded: ${resp.statusCode}');
      // Preview at most 300 chars to avoid log spam
      final body = resp.body;
      if (body.isNotEmpty) {
        final preview = body.length > 300 ? '${body.substring(0, 300)}…' : body;
        _blue('[DEBUG][Cravings] Response preview: $preview');
      } else {
        _blue('[DEBUG][Cravings] Empty body');
      }

      // We intentionally do not return anything now.
      // Later: parse JSON, map into UI models, etc.

    } on http.ClientException catch (e) {
      _blue('[DEBUG][Cravings][NET] ClientException: $e');
      rethrow;
    } on FormatException catch (e) {
      _blue('[DEBUG][Cravings][NET] Bad URL/Format: $e');
      rethrow;
    } on TimeoutException {
      _blue('[DEBUG][Cravings][NET] Request timed out after ${timeout.inSeconds}s');
      rethrow;
    } catch (e) {
      _blue('[DEBUG][Cravings][NET] Unknown error: $e');
      rethrow;
    }
  }

  Future<List<CravingRecipeModel>> fetchLatestCravingsWithImages(
    String userId, {
    int maxTries = 6, // ~6s total (6 * 1s)
    Duration delay = const Duration(seconds: 1),
  }) async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> _sessionDocs = [];
    String? sessionId;

    for (int attempt = 0; attempt < maxTries; attempt++) {
      final aiCol = _firestore.collection('users').doc(userId).collection('aiCravings');
      final latest = await aiCol.orderBy('createdAt', descending: true).limit(1).get();
      if (latest.docs.isNotEmpty) {
        _sessionDocs = latest.docs;
        sessionId = _sessionDocs.first.id;
        break;
      }
      await Future.delayed(delay);
    }

    if (_sessionDocs.isEmpty || sessionId == null) {
      _blue('[DEBUG][Cravings] No sessions found for $userId');
      return <CravingRecipeModel>[];
    }

    // recipes in the session
    List<QueryDocumentSnapshot<Map<String, dynamic>>> recipeDocs = [];
    for (int attempt = 0; attempt < maxTries; attempt++) {
      final recSnap = await _firestore
          .collection('users').doc(userId)
          .collection('aiCravings').doc(sessionId)
          .collection('recipes').orderBy('id')
          .get();

      if (recSnap.docs.isNotEmpty) {
        recipeDocs = recSnap.docs;
        break;
      }
      await Future.delayed(delay);
    }

    if (recipeDocs.isEmpty) return <CravingRecipeModel>[];

    final models = recipeDocs.map((d) => CravingRecipeModel.fromFirestore(d.data())).toList();
    _blue('[DEBUG][Cravings] Loaded ${models.length} recipes for $sessionId');

    await Future.wait(models.map((m) async {
      if (!m.hasImage) return;
      m.imageDataUrl = await _fetchImageDataUrlByTitle(m.title);
    }));

    return models;
  }

  Future<String?> _fetchImageDataUrlByTitle(String title,
      {Duration timeout = const Duration(seconds: 20)}) async {
    final url = '$backendApiUrl/recipes/gemini/image?title=${Uri.encodeComponent(title)}';
    try {
      final resp = await http.get(Uri.parse(url)).timeout(timeout);
      if (resp.statusCode == 200 && resp.body.isNotEmpty) return resp.body;
      _blue('[DEBUG][Cravings] image GET failed code=${resp.statusCode}');
    } catch (e) {
      _blue('[DEBUG][Cravings] image GET error: $e');
    }
    return null;
  }

  void _blue(Object msg) {
    final s = msg.toString();
    const max = 800; // logcat safe chunk (under 1024)
    if (s.length <= max) {
      print('\x1B[34m$s\x1B[0m');
      return;
    }
    for (int i = 0; i < s.length; i += max) {
      final end = (i + max < s.length) ? i + max : s.length;
      final part = s.substring(i, end);
      print('\x1B[34m$part\x1B[0m');
    }
  }
}
