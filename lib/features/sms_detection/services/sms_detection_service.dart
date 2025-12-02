import 'package:flutter/foundation.dart';

import '../models/scam_rule.dart';
import '../models/sms_scan_result.dart';
import 'ml_detection_service.dart';
import 'scam_rules_service.dart';
import 'sms_permission_service.dart';
import 'sms_reader_service.dart';

class SmsDetectionService extends ChangeNotifier {
  static final SmsDetectionService _instance = SmsDetectionService._internal();
  factory SmsDetectionService() => _instance;
  SmsDetectionService._internal();

  final SmsPermissionService _permissionService = SmsPermissionService();
  final SmsReaderService _readerService = SmsReaderService();
  final ScamRulesService _rulesService = ScamRulesService();
  final MlDetectionService _mlDetectionService = MlDetectionService();

  List<SmsScanResult> _scannedMessages = [];
  bool _isScanning = false;
  bool _isListening = false;

  List<SmsScanResult> get scannedMessages => _scannedMessages;
  bool get isScanning => _isScanning;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    try {
      await _rulesService.loadScamRules();
      return true;
    } catch (e) {
      print('Error initializing SMS detection service: $e');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    return await _permissionService.requestPermissions();
  }

  Future<bool> hasPermissions() async {
    return await _permissionService.hasPermissions();
  }

  Future<SmsScanResult> _analyzeMessage(SmsScanResult message) async {
    try {
      // Use ML-based detection
      final scamProbability =
          await _mlDetectionService.calculateScamProbability(
        message.message,
        message.phoneNumber,
      );

      final isScam = scamProbability > 0.6; // Threshold for scam detection
      final matchedRule = isScam
          ? _mlDetectionService.getMatchedPattern(message.message)
          : null;

      return SmsScanResult(
        id: message.id,
        phoneNumber: message.phoneNumber,
        message: message.message,
        isScam: isScam,
        matchedRule: matchedRule,
        timestamp: message.timestamp,
      );
    } catch (e) {
      print('Error in ML analysis: $e');
      // Fallback to rule-based detection
      final ScamRule? matchedRule =
          _rulesService.findMatchingRule(message.message);

      return SmsScanResult(
        id: message.id,
        phoneNumber: message.phoneNumber,
        message: message.message,
        isScam: matchedRule != null,
        matchedRule: matchedRule?.description,
        timestamp: message.timestamp,
      );
    }
  }

  Future<void> scanRecentMessages({int limit = 100}) async {
    if (!await hasPermissions()) {
      throw Exception('SMS permissions not granted');
    }

    _isScanning = true;
    notifyListeners();

    try {
      final messages = await _readerService.getRecentMessages(limit: limit);
      _scannedMessages = await Future.wait(messages.map(_analyzeMessage));
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  void startRealTimeDetection() async{
    if (!_isListening) {
      _readerService.startListening((SmsScanResult message) async {
        final analyzedMessage = await _analyzeMessage(message);
        _scannedMessages.insert(0, analyzedMessage);

        if (analyzedMessage.isScam) {
          _onScamDetected(analyzedMessage);
        }

        notifyListeners();
      });
      _isListening = true;
      notifyListeners();
    }
  }

  void stopRealTimeDetection() {
    if (_isListening) {
      _readerService.stopListening();
      _isListening = false;
      notifyListeners();
    }
  }

  void _onScamDetected(SmsScanResult scamMessage) {
    // This method can be extended to show notifications, alerts, etc.
    print('SCAM DETECTED: ${scamMessage.message}');
    print('Matched Rule: ${scamMessage.matchedRule}');
  }

  List<SmsScanResult> getScamMessages() {
    return _scannedMessages.where((msg) => msg.isScam).toList();
  }

  List<SmsScanResult> getSafeMessages() {
    return _scannedMessages.where((msg) => !msg.isScam).toList();
  }

  int get scamCount => _scannedMessages.where((msg) => msg.isScam).length;
  int get totalCount => _scannedMessages.length;
}
