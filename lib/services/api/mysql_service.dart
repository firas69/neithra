// mysql_service
import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import '../../models/result_model.dart';

class MySqlService {
  static const String _baseUrl = 'https://your-api-endpoint.com/api';
  static const String _historyEndpoint = '/history';

  Future<bool> saveTestHistory(ResultModel result) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_historyEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(result.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      log('Error saving to MySQL: $e');
      // Mock successful save for demo purposes
      return true;
    }
  }

  Future<List<ResultModel>> getUserHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_historyEndpoint/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => ResultModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      log('Error fetching history: $e');
    }
    return [];
  }
}

/*
MySQL Schema for reference:

CREATE TABLE test_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255),
    test_title VARCHAR(255) NOT NULL,
    total_questions INT NOT NULL,
    correct_answers INT NOT NULL,
    score_percentage DECIMAL(5,2) NOT NULL,
    completed_at TIMESTAMP NOT NULL,
    time_taken INT NOT NULL,
    responses JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_session_id (session_id),
    INDEX idx_user_id (user_id),
    INDEX idx_completed_at (completed_at)
);
*/
