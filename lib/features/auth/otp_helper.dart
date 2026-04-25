import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

class OtpHelper {
  static const _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static String? extractSecret(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.toLowerCase().startsWith('otpauth://')) {
      final uri = Uri.tryParse(trimmed);
      final secret = uri?.queryParameters['secret'];
      return _normalizeSecret(secret);
    }

    return _normalizeSecret(trimmed);
  }

  static String? generateTotp(String secret,
      {DateTime? now, int intervalSeconds = 30, int digits = 6}) {
    final secretBytes = _base32Decode(secret);
    if (secretBytes == null || secretBytes.isEmpty) return null;

    final counter =
        (now ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/ 1000 ~/ intervalSeconds;
    final counterBytes = Uint8List(8);
    var value = counter;
    for (var i = 7; i >= 0; i--) {
      counterBytes[i] = value & 0xff;
      value >>= 8;
    }

    final hmac = crypto.Hmac(crypto.sha1, secretBytes);
    final hash = hmac.convert(counterBytes).bytes;
    final offset = hash.last & 0x0f;
    final binary = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);

    final otp = binary % 1000000;
    return otp.toString().padLeft(digits, '0');
  }

  static String? _normalizeSecret(String? secret) {
    if (secret == null) return null;
    final cleaned = secret.replaceAll(' ', '').replaceAll('=', '').toUpperCase();
    return cleaned.isEmpty ? null : cleaned;
  }

  static Uint8List? _base32Decode(String input) {
    final cleaned = _normalizeSecret(input);
    if (cleaned == null) return null;

    var buffer = 0;
    var bitsLeft = 0;
    final bytes = <int>[];

    for (final rune in cleaned.codeUnits) {
      final index = _base32Alphabet.indexOf(String.fromCharCode(rune));
      if (index == -1) return null;

      buffer = (buffer << 5) | index;
      bitsLeft += 5;

      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        bytes.add((buffer >> bitsLeft) & 0xff);
      }
    }

    return Uint8List.fromList(bytes);
  }
}
