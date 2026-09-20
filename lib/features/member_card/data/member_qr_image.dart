import 'dart:convert';
import 'dart:typed_data';

/// The member's QR code image as returned by `GetMemberQrCode` — either
/// raw image [bytes] or a loadable [url].
///
/// The endpoint's response format isn't documented (Swagger only says
/// "200 OK"), so [parse] accepts every reasonable shape instead of
/// guessing one: raw PNG/JPEG/GIF/WebP bytes, or a JSON envelope (the
/// app's usual `{status, message, data}` or a bare value) whose payload is
/// an http(s) URL or a base64 string (optionally a `data:image/...;base64,`
/// URI). Returns `null` when nothing usable is found.
class MemberQrImage {
  const MemberQrImage({this.bytes, this.url});

  final Uint8List? bytes;

  final String? url;

  static MemberQrImage? parse(Uint8List raw) {
    if (raw.isEmpty) return null;

    if (_looksLikeImage(raw)) return MemberQrImage(bytes: raw);

    final String text;
    try {
      text = utf8.decode(raw).trim();
    } catch (_) {
      return null;
    }

    if (text.isEmpty) return null;

    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      decoded = text;
    }

    return _fromDynamic(decoded);
  }

  static MemberQrImage? _fromDynamic(dynamic value) {
    if (value is String) return _fromString(value);

    if (value is Map) {
      final data = _ciGet(value, 'data');
      if (data != null) {
        final fromData = _fromDynamic(data);
        if (fromData != null) return fromData;
      }

      for (final key in const [
        'qrCode',
        'qr',
        'qrImage',
        'image',
        'imageUrl',
        'url',
        'base64',
      ]) {
        final candidate = _ciGet(value, key);
        if (candidate != null) {
          final parsed = _fromDynamic(candidate);
          if (parsed != null) return parsed;
        }
      }

      for (final candidate in value.values) {
        if (candidate is String) {
          final parsed = _fromString(candidate);
          if (parsed != null) return parsed;
        }
      }
    }

    return null;
  }

  static MemberQrImage? _fromString(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    if (text.startsWith('http://') || text.startsWith('https://')) {
      return MemberQrImage(url: text);
    }

    final payload = text.startsWith('data:') && text.contains(',')
        ? text.substring(text.indexOf(',') + 1)
        : text;

    try {
      final bytes = Uint8List.fromList(base64Decode(base64.normalize(payload)));
      if (_looksLikeImage(bytes)) return MemberQrImage(bytes: bytes);
    } catch (_) {
      // Not base64 — fall through.
    }

    return null;
  }

  static dynamic _ciGet(Map map, String key) {
    final target = key.toLowerCase();
    for (final entry in map.entries) {
      if (entry.key.toString().toLowerCase() == target) return entry.value;
    }
    return null;
  }

  static bool _looksLikeImage(List<int> b) {
    if (b.length < 4) return false;

    final isPng = b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;
    final isJpeg = b[0] == 0xFF && b[1] == 0xD8;
    final isGif = b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46;
    final isWebp = b.length > 11 &&
        b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50;

    return isPng || isJpeg || isGif || isWebp;
  }
}
