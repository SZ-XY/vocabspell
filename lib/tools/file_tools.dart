import 'dart:io';
import 'dart:convert';

Map<String, dynamic> readFile(File file) {
  final content = file.readAsStringSync();
  return jsonDecode(content) as Map<String, dynamic>;
}

void writeFile(Map<String, dynamic> content, File file) {
  file.writeAsStringSync(jsonEncode(content));
}
