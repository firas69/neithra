import 'answer_value_model.dart';

class ResponseModel {
  final String questionId;
  final AnswerValue answer;
  final DateTime timestamp;
  final String sessionId;

  ResponseModel({
    required this.questionId,
    required this.answer,
    required this.timestamp,
    required this.sessionId,
  });

  String get response => answer.toStorage();

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'response': answer.toStorage(),
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
    };
  }

  factory ResponseModel.fromJson(Map<String, dynamic> json) {
    return ResponseModel(
      questionId: json['questionId'].toString(),
      answer: AnswerValue.fromStorage(json['response']?.toString()),
      timestamp: DateTime.parse(json['timestamp'].toString()),
      sessionId: json['sessionId'].toString(),
    );
  }
}
