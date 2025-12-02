import 'package:flutter/material.dart';

enum RiskLevel { safe, medium, high }

class PhoneReputation {
  final String phoneNumber;
  final RiskLevel riskLevel;
  final int reportCount;
  final DateTime lastReported;
  final List<String> reportTypes;
  final double trustScore;

  PhoneReputation({
    required this.phoneNumber,
    required this.riskLevel,
    required this.reportCount,
    required this.lastReported,
    required this.reportTypes,
    required this.trustScore,
  });

  factory PhoneReputation.fromMap(Map<String, dynamic> map) {
    return PhoneReputation(
      phoneNumber: map['phone_number'] ?? '',
      riskLevel: RiskLevel.values[map['risk_level'] ?? 0],
      reportCount: map['report_count'] ?? 0,
      lastReported:
          DateTime.fromMillisecondsSinceEpoch(map['last_reported'] ?? 0),
      reportTypes: (map['report_types'] ?? '')
          .split(',')
          .where((t) => t.isNotEmpty)
          .toList(),
      trustScore: (map['trust_score'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone_number': phoneNumber,
      'risk_level': riskLevel.index,
      'report_count': reportCount,
      'last_reported': lastReported.millisecondsSinceEpoch,
      'report_types': reportTypes.join(','),
      'trust_score': trustScore,
    };
  }

  Color get riskColor {
    switch (riskLevel) {
      case RiskLevel.safe:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  String get riskText {
    switch (riskLevel) {
      case RiskLevel.safe:
        return 'Safe / No reports';
      case RiskLevel.medium:
        return 'Medium-risk';
      case RiskLevel.high:
        return 'High-risk';
    }
  }
}
