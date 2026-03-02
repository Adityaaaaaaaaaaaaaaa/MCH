import 'dart:convert';
import 'dart:typed_data';

Uint8List? decodeDataUrl(String? dataUrl) {
  if (dataUrl == null || dataUrl.isEmpty) return null;

  try {
    // Strip whitespace/newlines that sometimes sneak in
    var s = dataUrl.replaceAll(RegExp(r'\s+'), '');

    // If it's a full data URL, isolate the payload
    final comma = s.indexOf(',');
    if (comma >= 0) s = s.substring(comma + 1);

    // URL-safe to standard base64
    s = s.replaceAll('-', '+').replaceAll('_', '/');

    // Fix padding: base64 length must be multiple of 4
    final mod = s.length % 4;
    if (mod != 0) s = s.padRight(s.length + (4 - mod), '=');

    return base64Decode(s);
  } catch (_) {
    return null;
  }
}
