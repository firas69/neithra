import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/test_model.dart';

class ExamFingerprintService {
  static String hashJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Exam JSON must be an object');
    }
    return hashParsedJson(decoded);
  }

  static String hashTest(TestModel exam) {
    return hashParsedJson(exam.toJson());
  }

  static String hashParsedJson(Map<String, dynamic> examJson) {
    final canonical = _canonicalize(_definitionOnly(examJson));
    return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
  }

  static Map<String, dynamic> _definitionOnly(Map<String, dynamic> source) {
    final copy = Map<String, dynamic>.from(source);
    copy.remove('id');
    copy.remove('title');
    copy.remove('topic');
    copy.remove('description');
    copy.remove('version');
    copy.remove('generated_date');
    copy.remove('generatedAt');
    copy.remove('question_count');
    return copy;
  }

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      final sortedKeys = value.keys.map((key) => key.toString()).toList()
        ..sort();
      return {
        for (final key in sortedKeys)
          key: _canonicalize(
            value.entries
                .firstWhere((entry) => entry.key.toString() == key)
                .value,
          ),
      };
    }

    if (value is List) {
      return value.map(_canonicalize).toList();
    }

    return value;
  }
}
