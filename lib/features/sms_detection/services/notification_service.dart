import 'package:flutter/services.dart';

import '../models/sms_scan_result.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const MethodChannel _channel =
      MethodChannel('momoshield/notifications');

  Future<void> showFraudAlert(SmsScanResult scamMessage) async {
    try {
      await _channel.invokeMethod('showFraudAlert', {
        'phoneNumber': scamMessage.phoneNumber,
        'message': scamMessage.message,
        'threatType': _getThreatType(scamMessage.matchedRule),
      });
    } catch (e) {
      print('Error showing fraud alert: $e');
    }
  }

  Future<void> wakeUpApp() async {
    try {
      await _channel.invokeMethod('wakeUpApp');
    } catch (e) {
      print('Error waking up app: $e');
    }
  }

  String _getThreatType(String? matchedRule) {
    if (matchedRule == null) return 'FRAUD';

    if (matchedRule.toLowerCase().contains('pin')) return 'PIN SCAM';
    if (matchedRule.toLowerCase().contains('money')) return 'MONEY SCAM';
    if (matchedRule.toLowerCase().contains('prize')) return 'PRIZE SCAM';
    if (matchedRule.toLowerCase().contains('account')) return 'ACCOUNT SCAM';

    return 'FRAUD';
  }
}
