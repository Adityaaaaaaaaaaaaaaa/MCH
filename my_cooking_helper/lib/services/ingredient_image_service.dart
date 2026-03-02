import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// Global ingredient image resolver & cache (TheMealDB-backed).
/// - Reads/writes Firestore: /ingredient_images/{key}
/// - Tries multiple name variants (descriptor-stripping, plural/singular, case)
/// - Tries sizes: -small, -medium, -large, and base .png
/// - Returns the first URL that exists, else null.
class IngredientImageService {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'ingredient_images';
  static const _base = 'https://www.themealdb.com/images/ingredients';

  /// Public entry point used by the controller.
  static Future<String?> getOrResolveFromGlobalPool(String rawName) async {
    final key = _canonicalKey(rawName);

    // 1) Check global pool first
    try {
      final snap = await _db.collection(_collection).doc(key).get();
      if (snap.exists) {
        final data = snap.data() ?? {};
        final url = (data['url'] ?? '').toString();
        final notFound = data['notFound'] == true;
        if (url.isNotEmpty) {
          _d({'cached hit': {'name': rawName, 'url': url}});
          return url;
        }
        if (notFound) {
          _d({'cached notFound': rawName});
          return null;
        }
      }
    } catch (e) {
      _d({'pool read error': e.toString()});
    }

    // 2) Resolve via TheMealDB
    final url = await _resolveViaMealDB(rawName);

    // 3) Persist result to the global pool
    try {
      final doc = _db.collection(_collection).doc(key);
      if (url != null) {
        await doc.set({
          'name': rawName,
          'key': key,
          'url': url,
          'checkedAt': DateTime.now().toUtc().toIso8601String(),
        }, SetOptions(merge: true));
      } else {
        await doc.set({
          'name': rawName,
          'key': key,
          'url': '',
          'notFound': true,
          'checkedAt': DateTime.now().toUtc().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      _d({'pool write error': e.toString()});
    }

    return url;
  }

  // Resolver

  static Future<String?> _resolveViaMealDB(String rawName) async {
    final variants = _buildNameVariants(rawName);

    // Try each variant with sizes: -small, -medium, -large, base
    const sizes = ['-small', '-medium', '-large', ''];
    for (final v in variants) {
      for (final sfx in sizes) {
        final url = '$_base/$v$sfx.png';
        if (await _urlExists(url)) {
          _d({'resolve ok': {'name': rawName, 'url': url}});
          return url;
        } else {
          _d({'probe miss': url});
        }
      }
    }
    _d({'resolve fail': rawName});
    return null;
  }

  /// Make many plausible variants:
  /// - Trim, collapse spaces, strip punctuation
  /// - Remove descriptors/adjectives (e.g., "small", "fresh", colors)
  /// - Try singular/plural flips
  /// - Try TitleCase and lowercase
  static List<String> _buildNameVariants(String raw) {
    final cleaned = _clean(raw);
    final tokens = cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    // Strip common descriptors (size, form, colors, generic prep words)
    final blacklist = <String>{
      'small','large','medium','fresh','dried','dry','ground','minced','sliced','chopped',
      'crushed','powder','powdered','flake','flakes','grated','ripe','unripe',
      'red','green','yellow','orange','black','white','brown'
    };

    final coreTokens = tokens.where((t) => !blacklist.contains(t)).toList();
    final core = coreTokens.isEmpty ? tokens : coreTokens;

    // Join with underscore
    String joinUnderscore(List<String> tks) => tks.join('_');

    // Plural/singular toggles for last token
    String flipPlural(String w) {
      if (w.endsWith('ies') && w.length > 3) return '${w.substring(0, w.length - 3)}y'; // berries -> berry
      if (w.endsWith('es') && w.length > 2) return w.substring(0, w.length - 2);       // tomatoes -> tomato
      if (w.endsWith('s') && w.length > 1) return w.substring(0, w.length - 1);        // walnuts -> walnut
      // singular -> plural naive:
      if (w.endsWith('y')) return '${w.substring(0, w.length - 1)}ies';                // cherry -> cherries
      if (w.endsWith('o')) return '${w}es';                                            // tomato -> tomatoes
      return '${w}s';                                                                   // walnut -> walnuts
    }

    // Manual synonyms / normalizations that frequently differ
    final manual = <String, String>{
      'bell_pepper': 'red_pepper', // try TheMealDB common
      'scallion': 'spring_onion',
      'coriander_leaves': 'coriander',
      'cilantro': 'coriander',
      'small_pumpkin': 'pumpkin',
      'pumpkins': 'pumpkin',
      'walnut': 'walnuts',
      'pecan': 'pecans',
    };

    final baseCore = joinUnderscore(core);
    final baseAll  = joinUnderscore(tokens);

    // Primary candidates
    final candidates = <String>{
      baseCore,
      baseAll,
      // singular/plural flips on the last token of core
      if (core.isNotEmpty) joinUnderscore([...core.take(core.length - 1), flipPlural(core.last)]),
      if (core.isNotEmpty) joinUnderscore([...core.take(core.length - 1), _singular(core.last)]),
    };

    // Add manual synonyms where applicable
    for (final c in candidates.toList()) {
      if (manual.containsKey(c)) candidates.add(manual[c]!);
    }

    // Include case variants (TitleCase + lower)
    final withCase = <String>{};
    for (final c in candidates) {
      withCase.add(_titleCaseUnderscore(c));
      withCase.add(c.toLowerCase());
    }

    // Deduplicate while preserving order preference: TitleCase first, then lower
    final ordered = <String>[];
    void addOnce(String v) { if (!ordered.contains(v)) ordered.add(v); }
    for (final v in withCase) {
      // prefer TitleCase ordering
      if (v.contains(RegExp(r'[A-Z]'))) addOnce(v);
    }
    for (final v in withCase) {
      final lower = v.toLowerCase();
      if (!v.contains(RegExp(r'[A-Z]'))) addOnce(lower);
    }

    _d({'variants': {'raw': raw, 'set': ordered}});
    return ordered;
  }

  static String _clean(String s) {
    final t = s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    return t;
  }

  static String _singular(String w) {
    if (w.endsWith('ies') && w.length > 3) return '${w.substring(0, w.length - 3)}y';
    if (w.endsWith('es') && w.length > 2) return w.substring(0, w.length - 2);
    if (w.endsWith('s') && w.length > 1) return w.substring(0, w.length - 1);
    return w;
  }

  static String _titleCaseUnderscore(String underscored) {
    final parts = underscored.split('_').where((p) => p.isNotEmpty).toList();
    return parts.map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase()).join('_');
  }

  static String _canonicalKey(String raw) {
    // consistent key for the global pool doc id
    return _clean(raw).replaceAll(' ', '_');
  }

  static Future<bool> _urlExists(String url) async {
    try {
      // HEAD first (cheap). If not allowed, fallback to GET.
      final h = await http.head(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (h.statusCode == 200) return true;
      if (h.statusCode == 405 || h.statusCode == 403) {
        final g = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
        return g.statusCode == 200 && (g.headers['content-type']?.contains('image') ?? true);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void _d(Object o) {
    try {
      final pretty = (o is String) ? o : const JsonEncoder.withIndent('  ').convert(o);
      for (final line in pretty.split('\n')) {
        // ignore: avoid_print
        print('[INV] $line');
      }
    } catch (_) {
      // ignore
    }
  }
}
