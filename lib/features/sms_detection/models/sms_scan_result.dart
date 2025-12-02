class SmsScanResult {
  final String id;
  final String phoneNumber;
  final String message;
  final bool isScam;
  final String? matchedRule;
  final int timestamp;

  SmsScanResult({
    required this.id,
    required this.phoneNumber,
    required this.message,
    required this.isScam,
    this.matchedRule,
    required this.timestamp,
  });

  factory SmsScanResult.fromMap(Map<String, dynamic> map) {
    return SmsScanResult(
      id: map['id'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      message: map['message'] ?? '',
      isScam: map['isScam'] ?? false,
      matchedRule: map['matchedRule'],
      timestamp: map['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'message': message,
      'isScam': isScam,
      'matchedRule': matchedRule,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'SmsScanResult(id: $id, phoneNumber: $phoneNumber, message: $message, isScam: $isScam, matchedRule: $matchedRule, timestamp: $timestamp)';
  }
}
