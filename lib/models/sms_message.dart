class SmsMessage {
  final String id;
  final String address;
  final String body;
  final DateTime date;
  final bool isScam;
  final double riskScore;
  final List<String> detectedPatterns;

  SmsMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    this.isScam = false,
    this.riskScore = 0.0,
    this.detectedPatterns = const [],
  });

  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    return SmsMessage(
      id: map['_id']?.toString() ?? '',
      address: map['address'] ?? '',
      body: map['body'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      isScam: map['is_scam'] == 1,
      riskScore: (map['risk_score'] ?? 0.0).toDouble(),
      detectedPatterns: (map['detected_patterns'] ?? '')
          .split(',')
          .where((p) => p.isNotEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'address': address,
      'body': body,
      'date': date.millisecondsSinceEpoch,
      'is_scam': isScam ? 1 : 0,
      'risk_score': riskScore,
      'detected_patterns': detectedPatterns.join(','),
    };
  }
}
