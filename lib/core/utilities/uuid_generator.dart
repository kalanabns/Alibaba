import 'dart:math';

/// Utility class for generating and validating RFC 4122 version 4 UUIDs
/// without introducing external package dependencies.
class UuidUtils {
  UuidUtils._();

  static final Random _random = _createRandom();

  static Random _createRandom() {
    try {
      return Random.secure();
    } catch (_) {
      return Random();
    }
  }

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Generates a RFC 4122 version 4 UUID.
  static String generate() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set version to 4: 0100xxxx in byte 6
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant to 10xx in byte 8 (RFC 4122)
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Checks if [value] is a valid UUID format.
  static bool isValidUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    return _uuidRegex.hasMatch(value);
  }
}
