import 'package:encrypt/encrypt.dart' as enc;

class CryptoHelper {
  // WARNING: For production, do NOT hardcode keys. Load from secure storage or env.
  // 32-byte key and 16-byte IV for AES-CBC
  static final enc.Key _key = enc.Key.fromUtf8('ThaneMitrSecretKey1234567890abcd'); // 32 chars
  static final enc.IV _iv = enc.IV.fromUtf8('VectorInit123456'); // 16 chars

  static final enc.Encrypter _encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));

  static String encryptText(String plain) {
    if (plain.isEmpty) return plain;
    final encrypted = _encrypter.encrypt(plain, iv: _iv);
    return encrypted.base64;
  }

  static String decryptText(String base64) {
    if (base64.isEmpty) return base64;
    try {
      return _encrypter.decrypt64(base64, iv: _iv);
    } catch (_) {
      // If it's not valid base64/ciphertext, return as-is to keep backward compatibility
      return base64;
    }
  }

  // Tries to find AADHAR:<value> in a free-form string and decrypt just the value, excluding PAN
  static String decryptAadhaarInIdentityString(String text) {
    if (text.isEmpty) return text;
    final reg = RegExp(r'AADHAR:([^,\s]+)');
    final match = reg.firstMatch(text);
    if (match != null) {
      final encVal = match.group(1)?.trim() ?? '';
      final dec = decryptText(encVal);
      return 'AADHAR:$dec';
    }
    return text;
  }
}