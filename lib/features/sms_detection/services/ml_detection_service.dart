class MlDetectionService {
  static final MlDetectionService _instance = MlDetectionService._internal();
  factory MlDetectionService() => _instance;
  MlDetectionService._internal();

  // Suspicious patterns with weighted scoring
  final Map<String, double> _suspiciousPatterns = {
    // Financial urgency
    'urgent.*money': 0.8,
    'immediate.*payment': 0.7,
    'account.*blocked': 0.9,
    'verify.*account': 0.6,

    // Personal information requests
    'send.*pin': 0.95,
    'share.*password': 0.9,
    'confirm.*details': 0.7,
    'otp.*verification': 0.6,

    // Rewards/prizes
    'congratulations.*won': 0.8,
    'claim.*prize': 0.7,
    'free.*gift': 0.6,
    'bonus.*unlock': 0.7,

    // Threats/consequences
    'account.*suspended': 0.8,
    'legal.*action': 0.7,
    'expire.*today': 0.6,

    // Common scam phrases
    'cash.*out': 0.8,
    'reset.*account': 0.7,
    'update.*information': 0.5,
  };

  final Map<String, double> _legitimatePatterns = {
    'bank.*statement': -0.3,
    'transaction.*successful': -0.4,
    'balance.*inquiry': -0.3,
    'payment.*received': -0.4,
  };

  Future<double> calculateScamProbability(
      String message, String phoneNumber) async {
    double score = 0.0;
    final normalizedMessage = message.toLowerCase();

    // Pattern matching with weights
    score += _checkPatterns(normalizedMessage, _suspiciousPatterns);
    score += _checkPatterns(normalizedMessage, _legitimatePatterns);

    // Behavioral analysis
    score += _analyzeMessageStructure(normalizedMessage);
    score += _analyzeSenderReputability(phoneNumber);
    score += _analyzeUrgencyIndicators(normalizedMessage);
    score += _analyzeFinancialContent(normalizedMessage);

    // Normalize score to 0-1 range
    return (score).clamp(0.0, 1.0);
  }

  double _checkPatterns(String message, Map<String, double> patterns) {
    double score = 0.0;
    for (final entry in patterns.entries) {
      final regex = RegExp(entry.key, caseSensitive: false);
      if (regex.hasMatch(message)) {
        score += entry.value;
      }
    }
    return score;
  }

  double _analyzeMessageStructure(String message) {
    double suspicionScore = 0.0;

    // Short messages with urgent content are suspicious
    if (message.length < 100 && _containsUrgentWords(message)) {
      suspicionScore += 0.3;
    }

    // Excessive punctuation/caps
    final exclamationCount = message.split('!').length - 1;
    final capsRatio =
        message.replaceAll(RegExp(r'[^A-Z]'), '').length / message.length;

    if (exclamationCount > 2) suspicionScore += 0.2;
    if (capsRatio > 0.3) suspicionScore += 0.2;

    // Phone numbers or links (common in scams)
    if (RegExp(r'\b\d{10,}\b').hasMatch(message)) suspicionScore += 0.1;
    if (RegExp(r'http|www|\.com').hasMatch(message)) suspicionScore += 0.3;

    return suspicionScore;
  }

  double _analyzeSenderReputability(String phoneNumber) {
    // Unknown/suspicious number patterns
    if (phoneNumber.isEmpty) return 0.2;

    // Short codes are often legitimate
    if (phoneNumber.length <= 6 && RegExp(r'^\d+$').hasMatch(phoneNumber)) {
      return -0.2;
    }

    // International numbers can be suspicious
    if (phoneNumber.startsWith('+') && !phoneNumber.startsWith('+233')) {
      return 0.3;
    }

    return 0.0;
  }

  double _analyzeUrgencyIndicators(String message) {
    final urgentWords = [
      'urgent',
      'immediate',
      'now',
      'today',
      'expire',
      'deadline',
      'last chance',
      'limited time',
      'act fast',
      'hurry'
    ];

    double urgencyScore = 0.0;
    for (final word in urgentWords) {
      if (message.contains(word)) {
        urgencyScore += 0.1;
      }
    }

    return urgencyScore.clamp(0.0, 0.4);
  }

  double _analyzeFinancialContent(String message) {
    final financialKeywords = [
      'money',
      'payment',
      'account',
      'bank',
      'transfer',
      'fund',
      'credit',
      'debit',
      'balance',
      'transaction',
      'momo',
      'mobile money'
    ];

    final requestKeywords = [
      'send',
      'give',
      'provide',
      'share',
      'confirm',
      'verify'
    ];

    bool hasFinancial = financialKeywords.any((word) => message.contains(word));
    bool hasRequest = requestKeywords.any((word) => message.contains(word));

    if (hasFinancial && hasRequest) {
      return 0.4; // High suspicion when requesting financial info
    } else if (hasFinancial) {
      return 0.1; // Moderate suspicion for financial content
    }

    return 0.0;
  }

  bool _containsUrgentWords(String message) {
    final urgentPatterns = ['urgent', 'immediate', 'now', 'asap', 'quickly'];
    return urgentPatterns.any((word) => message.contains(word));
  }

  String? getMatchedPattern(String message) {
    final normalizedMessage = message.toLowerCase();

    for (final entry in _suspiciousPatterns.entries) {
      final regex = RegExp(entry.key, caseSensitive: false);
      if (regex.hasMatch(normalizedMessage)) {
        return _getPatternDescription(entry.key);
      }
    }

    return null;
  }

  String _getPatternDescription(String pattern) {
    final descriptions = {
      'urgent.*money': 'Urgent money request pattern',
      'immediate.*payment': 'Immediate payment demand',
      'account.*blocked': 'Fake account blocking notification',
      'verify.*account': 'Account verification scam',
      'send.*pin': 'PIN sharing request',
      'share.*password': 'Password sharing request',
      'confirm.*details': 'Personal information request',
      'congratulations.*won': 'Fake prize notification',
      'claim.*prize': 'Prize claiming scam',
      'free.*gift': 'Free gift scam',
      'bonus.*unlock': 'Fake bonus unlock',
      'account.*suspended': 'Account suspension threat',
      'legal.*action': 'Legal threat scam',
      'expire.*today': 'Fake expiration notice',
      'cash.*out': 'Fake cash-out notification',
      'reset.*account': 'Account reset scam',
      'update.*information': 'Information update request',
    };

    return descriptions[pattern] ?? 'Suspicious pattern detected';
  }
}
