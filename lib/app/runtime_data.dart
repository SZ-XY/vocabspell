import 'dart:io';
import '../dict/dict.dart';
import '../global.dart';
import '../tools/file_tools.dart';
import 'package:path/path.dart' as p;
import '../tools/cache_audio_tools.dart';
import '../tools/copy_assets.dart';

class RuntimeData {
  int cachedAudioCount = 0;

  late Dict selectedDict;
  late Map<String, File> dictMap;
  late File _file;

  Map<String, dynamic> _toJson() => {
    'cachedAudioCount': cachedAudioCount,
    'selectedDictName': selectedDict.name,
    'dictPaths': Map.fromEntries(
      dictMap.entries.map((e) => MapEntry(e.key, e.value.path)),
    ),
  };
  Future<void> fromJson(Map<String, dynamic> json) async {
    cachedAudioCount = json['cachedAudioCount'] as int;
    final selectedDictName = json['selectedDictName'] as String;
    final files = Map<String, String>.from(json['dictPaths']);
    dictMap = files.map((name, path) => MapEntry(name, File(path)));
    final targetFile = dictMap[selectedDictName];
    if (targetFile == null || !targetFile.existsSync()) {
      throw Exception('词典文件丢失: $selectedDictName');
    }
    selectedDict = await Dict.fromFile(targetFile, onWordRemoved);
    selectedDict.loadProgress();
  }

  RuntimeData();

  Future<void> init() async {
    final dataDir = Directory(p.join(appDocDir, 'runtimedata'));
    if (!dataDir.existsSync()) {
      dataDir.createSync(recursive: true);
    }
    _file = File(p.join(appDocDir, 'runtimedata', 'data.json'));
    if (_file.existsSync()) {
      final json = readFile(_file);
      await fromJson(json);
    } else {
      await copyExampleDict();
      final exampleFile = File(p.join(appDocDir, 'dicts', 'example.txt'));
      selectedDict = await Dict.fromFile(exampleFile, onWordRemoved);
      dictMap = {selectedDict.name: exampleFile};
      selectedDict.loadProgress();
      await save();
    }
  }

  Future<void> save() async {
    final json = _toJson();
    writeFile(json, _file);
  }

  List<String> getDictList() => dictMap.keys.toList();

  Future<void> switchDict(String dict) async {
    final file = dictMap[dict];
    if (file != null) {
      if (file.existsSync()) {
        selectedDict.saveProgress();
        selectedDict = await Dict.fromFile(file, onWordRemoved);
        selectedDict.loadProgress();
        await save();
      }
    }
  }

  Future<void> newDict(
    String name,
    String author,
    String description, {
    List<Entry> content = const [],
  }) async {
    final newDict = await Dict.newDict(
      name,
      author,
      description,
      onWordRemoved: onWordRemoved,
    );
    dictMap[name] = newDict.file;
  }

  void onCorrect() {
    selectedDict.reviewScheduler.onCorrect();
    selectedDict.saveProgress();
  }

  void onMistake() {
    selectedDict.reviewScheduler.onMistake();
    selectedDict.saveProgress();
  }

  void onWordRemoved(int wordIndex) {
    final word = selectedDict.content[wordIndex].word;
    rmAudioCache(word);
  }
}
