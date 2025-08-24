import 'dart:convert';
import 'dart:typed_data';

Uint8List? decodeDataUrl(String? dataUrl) {
  if (dataUrl == null || dataUrl.isEmpty) return null;
  try {
    final uri = UriData.parse(dataUrl); // handles data:image/...;base64,
    return uri.contentAsBytes();
  } catch (_) {
    // Fallback: split on comma and decode the tail if it looks like base64
    final idx = dataUrl.indexOf(',');
    try {
      final payload = (idx >= 0) ? dataUrl.substring(idx + 1) : dataUrl;
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }
}
