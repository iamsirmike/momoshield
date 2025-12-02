class ScamRule {
  final String id;
  final String pattern;
  final String description;

  ScamRule({
    required this.id,
    required this.pattern,
    required this.description,
  });

  factory ScamRule.fromMap(Map<String, dynamic> map) {
    return ScamRule(
      id: map['id'] ?? '',
      pattern: map['pattern'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pattern': pattern,
      'description': description,
    };
  }

  bool matches(String message) {
    return message.toLowerCase().contains(pattern.toLowerCase());
  }
}
