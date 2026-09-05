import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import '../../models/result_model.dart';

class RemoteHistoryService {
  static const String _baseUrl = String.fromEnvironment('NEITHRA_HISTORY_API');
  static const String _historyEndpoint = '/history';

  Future<bool> saveTestHistory(ResultModel result) async {
    if (_baseUrl.isEmpty) return false;

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
      return false;
    }
  }

  Future<List<ResultModel>> getUserHistory(String userId) async {
    if (_baseUrl.isEmpty) return [];

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
