import 'dart:io';
import 'dart:convert';
import '../tools/file_tools.dart';
import '../global.dart';
import 'package:path/path.dart' as p;
import '../dict/review_scheduler.dart';

class Dict {
  late File file;
  String name = '';
  String author = '';
  String description = '';
  List<Entry> content = [];
  // 这里的列表中是索引
  late ReviewScheduler reviewScheduler;
  Dict({
    required this.file,
    required this.name,
    required this.author,
    required this.description,
    required this.content,
    required this.reviewScheduler,
  });
  void saveProgress() {
    final json = reviewScheduler.toJson();
    // 目录第一次复制时会创建
    final file = File(p.join(appDocDir, 'dicts', '${name.safeName}.json'));
    writeFile(json, file);
  }

  void loadProgress() {
    final file = File(p.join(appDocDir, 'dicts', '${name.safeName}.json'));
    reviewScheduler.init(file);
  }

  void resetProgress() {
    final file = File(p.join(appDocDir, 'dicts', '${name.safeName}.json'));
    if (file.existsSync()) {
      file.deleteSync();
    }
    reviewScheduler.init(file);
  }

  Future<void> addItem(Entry entry) async {
    content.add(entry);
    reviewScheduler.add();
    await file.writeAsString(
      '${entry.toStringForm()}\n',
      mode: FileMode.append,
    );
    saveProgress();
  }

  void updateEntry(int index, Entry entry) {
    if (index < 0 || index >= reviewScheduler.length) return;
    content[index] = entry;
  }

  Future<void> saveContent() async {
    final buffer = StringBuffer();
    buffer.writeln('$name|$author');
    buffer.writeln(description);
    for (final item in content) {
      buffer.writeln(item.toStringForm());
    }
    await file.writeAsString(buffer.toString());
  }

  static Future<Dict> fromFile(
    File file,
    void Function(int wordIndex) onWordRemoved,
  ) async {
    final lines = await file.readAsLines();
    int convertProgress = 0;
    String name = '';
    String author = '';
    String description = '';
    List<Entry> content = [];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // 识别名字和作者,格式为: "名字|作者"
      if (convertProgress == 0) {
        final parts = line.split('|');
        convertProgress++;
        if (parts.length != 2) {
          throw FormatException('格式不正确: $line');
        }
        name = parts[0].trim();
        author = parts[1].trim();
      } else if (convertProgress == 1) {
        // 识别描述(即第二行)
        convertProgress++;
        description = line.trim();
      } else {
        // 正常解析,格式为: "单词|音标|释义", 音标为空即词组
        final entry = Entry.fromString(line);
        content.add(entry);
      }
    }
    if (convertProgress < 2) {
      throw FormatException('文件格式不完整：需要名字,作者和描述行');
    }
    final int length = content.length;
    // 规范换行,中间无空行,末尾有换行
    if (lines.length == length + 2) {
      // 正常行数为条目数+开头2行(readAsLines不会返回末尾空行)
      // 行数正确，但可能末尾无换行，检查并补齐
      final filelength = file.lengthSync();
      if (filelength > 0) {
        final lastByte = await file.openRead(filelength - 1, filelength).first;
        if (lastByte[0] != 0x0A) {
          await file.writeAsString('\n', mode: FileMode.append);
        }
      }
    } else {
      final buffer = StringBuffer();
      buffer.writeln('$name|$author');
      buffer.writeln(description);
      for (final item in content) {
        buffer.writeln(item.toStringForm());
      }
      await file.writeAsString(buffer.toString());
    }

    return Dict(
      file: file,
      name: name,
      author: author,
      description: description,
      content: content,
      reviewScheduler: ReviewScheduler(
        length: length,
        onWordRemoved: onWordRemoved,
      ),
    );
  }

  static Future<Dict> newDict(
    String name,
    String author,
    String description, {
    List<Entry> content = const [],
    required void Function(int wordIndex) onWordRemoved,
  }) async {
    final file = File(p.join(appDocDir, 'dicts', '${name.safeName}.txt'));
    final buffer = StringBuffer();
    buffer.writeln('$name|$author');
    buffer.writeln(description);
    for (final item in content) {
      buffer.writeln(item.toStringForm());
    }
    await file.writeAsString(buffer.toString());
    return Dict(
      file: file,
      name: name,
      author: author,
      description: description,
      content: content,
      reviewScheduler: ReviewScheduler(
        length: content.length,
        onWordRemoved: onWordRemoved,
      ),
    );
  }

  /// 0表示没问题,1表示名字或作者格式有问题,2表示描述有问题,3表示内容有问题
  static Future<int> fromString(String dict) async {
    int convertProgress = 0;
    String name = '';
    String author = '';
    String description = '';
    List<Entry> content = [];
    List<String> lines = LineSplitter.split(
      dict,
    ).toList().where((l) => l.trim().isNotEmpty).toList();
    for (final line in lines) {
      // 识别名字和作者,格式为: "名字|作者"
      if (convertProgress == 0) {
        final parts = line.split('|');
        if (parts.length != 2) {
          return 1;
        }
        name = parts[0].trim();
        author = parts[1].trim();
        convertProgress++;
      } else if (convertProgress == 1) {
        // 识别描述(即第二行)
        convertProgress++;
        description = line.trim();
      } else {
        try {
          final entry = Entry.fromString(line);
          content.add(entry);
        } on FormatException {
          return 3;
        }
      }
    }
    if (convertProgress < 2) return 2; // 缺少描述行
    final file = File(p.join(appDocDir, 'dicts', '${name.safeName}.txt'));
    final buffer = StringBuffer();
    buffer.writeln('$name|$author');
    buffer.writeln(description);
    for (final item in content) {
      buffer.writeln(item.toStringForm());
    }
    await file.writeAsString(buffer.toString());
    runtimeData.dictMap[name] = file;
    return 0;
  }

  static void deleteDict(String name) {
    final file = runtimeData.dictMap[name];
    if (file == null || !file.existsSync()) return;
    file.deleteSync();
    final progress = File(p.join(appDocDir, 'dicts', '${name.safeName}.json'));
    if (progress.existsSync()) {
      progress.deleteSync();
    }
    runtimeData.dictMap.remove(name);
  }
}

extension StringSafeName on String {
  String get safeName => replaceAll(RegExp(r'[^\w\-\u4e00-\u9fff]'), '_');
}

class Entry {
  final String word;
  final String phonetic;
  final String definition;

  Entry({required this.word, required this.phonetic, required this.definition});

  factory Entry.fromString(String text) {
    final parts = text.split('|');
    if (parts.length != 3) {
      throw FormatException('格式不正确: $text');
    }
    return Entry(
      word: parts[0].trim(),
      phonetic: parts[1].trim(),
      definition: parts[2].trim(),
    );
  }
  String toStringForm() {
    return '$word|$phonetic|$definition';
  }
}
