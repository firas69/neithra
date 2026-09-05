import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/test_model.dart';

class FileDbService {
  static const String _fileName = 'test_data.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<void> saveTestData(TestModel testData) async {
    final file = await _localFile;
    await file.writeAsString(json.encode(testData.toJson()));
  }

  Future<TestModel?> loadTestData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        String contents = await file.readAsString();
        Map<String, dynamic> jsonData = json.decode(contents);
        return TestModel.fromJson(jsonData);
      }
    } catch (e) {
      log('Error loading test data: $e');
    }
    return null;
  }

  Future<bool> hasTestData() async {
    final file = await _localFile;
    return await file.exists();
  }

  Future<void> clearTestData() async {
    final file = await _localFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
