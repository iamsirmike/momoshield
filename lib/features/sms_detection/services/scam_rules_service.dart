import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/scam_rule.dart';

class ScamRulesService {
  static final ScamRulesService _instance = ScamRulesService._internal();
  factory ScamRulesService() => _instance;
  ScamRulesService._internal();

  List<ScamRule> _scamRules = [];
  bool _isLoaded = false;

  List<ScamRule> get scamRules => _scamRules;

  Future<void> loadScamRules() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/scam_rules.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> patternsJson = jsonData['scam_patterns'];
      _scamRules = patternsJson.map((pattern) => ScamRule.fromMap(pattern)).toList();
      
      _isLoaded = true;
    } catch (e) {
      print('Error loading scam rules: $e');
      _scamRules = [];
    }
  }

  ScamRule? findMatchingRule(String message) {
    for (final rule in _scamRules) {
      if (rule.matches(message)) {
        return rule;
      }
    }
    return null;
  }

  bool isScamMessage(String message) {
    return findMatchingRule(message) != null;
  }
}
