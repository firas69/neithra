import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<String> getLocalFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  static Future<bool> fileExists(String fileName) async {
    final filePath = await getLocalFilePath(fileName);
    return File(filePath).exists();
  }

  static Future<void> deleteFile(String fileName) async {
    final filePath = await getLocalFilePath(fileName);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
