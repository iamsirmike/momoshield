import 'package:flutter/foundation.dart';

import '../models/sms_scan_result.dart';
import '../services/sms_detection_service.dart';

enum SmsDetectionState {
  idle,
  loading,
  scanning,
  listening,
  error,
}

class SmsDetectionController extends ChangeNotifier {
  final SmsDetectionService _detectionService = SmsDetectionService();

  SmsDetectionState _state = SmsDetectionState.idle;
  String? _errorMessage;
  List<SmsScanResult> _messages = [];
  bool _isInitialized = false;
  bool _hasPermissions = false;

  // Getters
  SmsDetectionState get state => _state;
  String? get errorMessage => _errorMessage;
  List<SmsScanResult> get messages => _messages;
  bool get isInitialized => _isInitialized;
  bool get hasPermissions => _hasPermissions;
  bool get isListening => _detectionService.isListening;

  // Filtered getters
  List<SmsScanResult> get scamMessages =>
      _messages.where((msg) => msg.isScam).toList();
  List<SmsScanResult> get safeMessages =>
      _messages.where((msg) => !msg.isScam).toList();
  int get scamCount => scamMessages.length;
  int get totalCount => _messages.length;

  // Statistics
  double get scamPercentage =>
      totalCount > 0 ? (scamCount / totalCount) * 100 : 0.0;

  SmsDetectionController() {
    _initialize();
  }

  Future<void> _initialize() async {
    _setState(SmsDetectionState.loading);

    try {
      final success = await _detectionService.initialize();
      if (success) {
        _isInitialized = true;
        await _checkPermissions();
        _setState(SmsDetectionState.idle);
      } else {
        _setError('Failed to initialize SMS detection service');
      }
    } catch (e) {
      _setError('Initialization error: ${e.toString()}');
    }
  }

  Future<void> _checkPermissions() async {
    try {
      _hasPermissions = await _detectionService.hasPermissions();
      notifyListeners();
    } catch (e) {
      _setError('Permission check error: ${e.toString()}');
    }
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      _setError('Service not initialized');
      return false;
    }

    _setState(SmsDetectionState.loading);

    try {
      final granted = await _detectionService.requestPermissions();
      _hasPermissions = granted;

      if (granted) {
        // Automatically scan messages and start listening when permissions are granted
        await scanMessages();
        startRealTimeDetection();
        _setState(SmsDetectionState.idle);
      } else {
        _setError('SMS permissions were denied');
      }

      return granted;
    } catch (e) {
      _setError('Permission request error: ${e.toString()}');
      return false;
    }
  }

  Future<void> scanMessages({int limit = 100}) async {
    if (!_isInitialized) {
      _setError('Service not initialized');
      return;
    }

    if (!_hasPermissions) {
      _setError('SMS permissions not granted');
      return;
    }

    _setState(SmsDetectionState.scanning);

    try {
      await _detectionService.scanRecentMessages(limit: limit);
      _messages = _detectionService.scannedMessages;
      _setState(SmsDetectionState.idle);
    } catch (e) {
      _setError('Scan error: ${e.toString()}');
    }
  }

  void startRealTimeDetection() {
    if (!_isInitialized) {
      _setError('Service not initialized');
      return;
    }

    if (!_hasPermissions) {
      _setError('SMS permissions not granted');
      return;
    }

    try {
      _detectionService.startRealTimeDetection();
      _setState(SmsDetectionState.listening);

      // Listen for changes in the service
      _detectionService.addListener(_onServiceUpdated);
    } catch (e) {
      _setError('Real-time detection error: ${e.toString()}');
    }
  }

  void stopRealTimeDetection() {
    try {
      _detectionService.stopRealTimeDetection();
      _detectionService.removeListener(_onServiceUpdated);
      _setState(SmsDetectionState.idle);
    } catch (e) {
      _setError('Stop detection error: ${e.toString()}');
    }
  }

  void _onServiceUpdated() {
    _messages = _detectionService.scannedMessages;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == SmsDetectionState.error) {
      _setState(SmsDetectionState.idle);
    }
  }

  SmsScanResult? getMessageById(String id) {
    try {
      return _messages.firstWhere((msg) => msg.id == id);
    } catch (e) {
      return null;
    }
  }

  List<SmsScanResult> getMessagesByPhoneNumber(String phoneNumber) {
    return _messages.where((msg) => msg.phoneNumber == phoneNumber).toList();
  }

  Map<String, int> getScamStatsByRule() {
    final Map<String, int> stats = {};
    for (final message in scamMessages) {
      if (message.matchedRule != null) {
        stats[message.matchedRule!] = (stats[message.matchedRule!] ?? 0) + 1;
      }
    }
    return stats;
  }

  void _setState(SmsDetectionState newState) {
    _state = newState;
    if (newState != SmsDetectionState.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = SmsDetectionState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _detectionService.removeListener(_onServiceUpdated);
    super.dispose();
  }
}
