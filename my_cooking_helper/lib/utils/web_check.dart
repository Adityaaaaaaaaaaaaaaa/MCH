import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

const String kGenericAndroidMobileUA =
    'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

class WebsiteCheckResult {
  final String resolvedUrl;        // what we will open (prefer HTTPS if input was HTTP)
  final bool wasHttp;              // original url used http:// ?
  final bool httpsAvailable;       // https reachable (probe result)?
  final bool mobileFriendly;       // has viewport meta?
  final List<String> warnings;     // human text labels to render

  WebsiteCheckResult({
    required this.resolvedUrl,
    required this.wasHttp,
    required this.httpsAvailable,
    required this.mobileFriendly,
    required this.warnings,
  });
}

class WebChecker {
  static final Map<String, WebsiteCheckResult> _cache = {};

  static Future<WebsiteCheckResult> check(String url) async {
    final trimmed = url.trim();
    if (_cache.containsKey(trimmed)) return _cache[trimmed]!;

    final wasHttp = trimmed.startsWith('http://');
    final httpsCandidate = wasHttp
        ? trimmed.replaceFirst('http://', 'https://')
        : trimmed;

    // Always try to open HTTPS if original was HTTP 
    String resolved = wasHttp ? httpsCandidate : trimmed;

    // Probe whether HTTPS actually responds
    bool httpsAvailable = false;
    if (wasHttp) {
      try {
        final head = await http
            .head(Uri.parse(httpsCandidate), headers: {'User-Agent': kGenericAndroidMobileUA})
            .timeout(const Duration(seconds: 4));
        httpsAvailable = head.statusCode >= 200 && head.statusCode < 400;
      } catch (_) {
        try {
          final get = await http
              .get(Uri.parse(httpsCandidate), headers: {'User-Agent': kGenericAndroidMobileUA})
              .timeout(const Duration(seconds: 5));
          httpsAvailable = get.statusCode >= 200 && get.statusCode < 400;
        } catch (_) {}
      }
    }

    bool mobileFriendly = false;
    try {
      final resp = await http
          .get(Uri.parse(resolved), headers: {'User-Agent': kGenericAndroidMobileUA})
          .timeout(const Duration(seconds: 7));

      if (resp.statusCode >= 200 && resp.statusCode < 400) {
        final doc = html.parse(resp.body);
        final viewport = doc
                .querySelector('meta[name="viewport"]')
                ?.attributes['content']
                ?.toLowerCase() ??
            '';
        mobileFriendly = viewport.contains('width=device-width') ||
            viewport.contains('initial-scale');
      }
    } catch (_) {
    }

    final warnings = <String>[];
    if (wasHttp && httpsAvailable) {
      warnings.add('Originally HTTP (Trying HTTPS)');
    } else if (wasHttp && !httpsAvailable) {
      warnings.add('Not secure (HTTP)');
    }
    if (!mobileFriendly) {
      warnings.add('May not be mobile-friendly');
    }

    final result = WebsiteCheckResult(
      resolvedUrl: resolved,
      wasHttp: wasHttp,
      httpsAvailable: httpsAvailable,
      mobileFriendly: mobileFriendly,
      warnings: warnings,
    );

    _cache[trimmed] = result;
    return result;
  }
}
