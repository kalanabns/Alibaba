import 'package:flutter/services.dart';

class SmsRawMessage {
  const SmsRawMessage({
    required this.id,
    required this.senderAddress,
    required this.body,
    required this.timestamp,
  });

  final String id;
  final String senderAddress;
  final String body;
  final DateTime timestamp;
}

class SmsReaderService {
  static const MethodChannel _channel = MethodChannel('finora/sms_reader');

  /// Checks whether Android SMS read permission has been granted.
  Future<bool> checkPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkSmsPermission');
      return result ?? false;
    } on MissingPluginException {
      // Running on web, desktop, or simulator without native channel
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the native Android SMS permission dialog.
  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestSmsPermission');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Reads recent incoming SMS messages from the device inbox.
  Future<List<SmsRawMessage>> readInbox({int limit = 50}) async {
    try {
      final List<dynamic>? rawList = await _channel.invokeListMethod(
        'readSmsInbox',
        {'limit': limit},
      );

      if (rawList == null) return [];

      return rawList.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final dateMillis = map['date'] is int
            ? map['date'] as int
            : int.tryParse(map['date'].toString()) ?? DateTime.now().millisecondsSinceEpoch;

        return SmsRawMessage(
          id: (map['id'] ?? '').toString(),
          senderAddress: (map['address'] ?? '').toString(),
          body: (map['body'] ?? '').toString(),
          timestamp: DateTime.fromMillisecondsSinceEpoch(dateMillis),
        );
      }).toList();
    } on MissingPluginException {
      // Graceful fallback for non-Android environments / unit tests
      return [];
    } catch (_) {
      return [];
    }
  }
}
