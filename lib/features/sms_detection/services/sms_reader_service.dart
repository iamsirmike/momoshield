import 'dart:async';

import 'package:flutter/services.dart';

import '../models/sms_scan_result.dart';

class SmsReaderService {
  static final SmsReaderService _instance = SmsReaderService._internal();
  factory SmsReaderService() => _instance;
  SmsReaderService._internal();

  static const MethodChannel _channel = MethodChannel('momoshield/sms');
  static const EventChannel _eventChannel =
      EventChannel('momoshield/sms_stream');

  Future<List<SmsScanResult>> getRecentMessages({int limit = 100}) async {
    try {
      final List<dynamic> messages =
          await _channel.invokeMethod('getRecentMessages', {'limit': limit});

      return messages.map((msg) {
        final Map<String, dynamic> messageMap = Map<String, dynamic>.from(msg);
        return SmsScanResult(
          id: messageMap['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          phoneNumber: messageMap['address'] ?? '',
          message: messageMap['body'] ?? '',
          isScam: false, // Will be determined by detection service
          timestamp:
              messageMap['date'] ?? DateTime.now().millisecondsSinceEpoch,
        );
      }).toList();
    } catch (e) {
      print('Error reading SMS messages: $e');
      return [];
    }
  }

  static StreamSubscription? _streamSubscription;
  static bool _isListening = false;

  void startListening(Function(SmsScanResult) onSmsReceived) {
    if (_isListening) return; // Already listening

    // Add a small delay to ensure platform channel is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        _streamSubscription = _eventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
            final Map<String, dynamic> messageMap =
                Map<String, dynamic>.from(event);
            final scanResult = SmsScanResult(
              id: messageMap['id']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              phoneNumber: messageMap['address'] ?? '',
              message: messageMap['body'] ?? '',
              isScam: false,
              timestamp:
                  messageMap['date'] ?? DateTime.now().millisecondsSinceEpoch,
            );
            onSmsReceived(scanResult);
          },
          onError: (error) {
            print('SMS stream error: $error');
            _isListening = false;
          },
          onDone: () {
            print('SMS stream closed');
            _isListening = false;
          },
        );
        _isListening = true;
        print('SMS listening started');
      } catch (e) {
        print('Error starting SMS listener: $e');
        _isListening = false;
      }
    });
  }

  void stopListening() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _isListening = false;
    print('SMS listening stopped');
  }

  bool get isListening => _isListening;
}
