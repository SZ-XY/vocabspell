import 'dart:io';
import '../global.dart';
import 'package:path/path.dart' as p;
import '../tools/generate_audio_path.dart';

void rmAllAudioCache() {
  final dir = Directory(p.join(appCacheDir, 'audiocache'));
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
  dir.createSync(recursive: true);
  runtimeData.cachedAudioCount = 0;
}

void rmAudioCache(String word) {
  final path = findUsableCache(word);
  if (path == '') return;
  File(path).deleteSync();
  runtimeData.cachedAudioCount--;
}

/// 寻找是否有该单词的音频缓存,没有返回空字符串
String findUsableCache(String word, {double speed = 1.0}) {
  final path = generateAudioPath(word, settings.sid, appCacheDir, speed: speed);
  if (File(path).existsSync()) {
    return path;
  } else {
    return '';
  }
}

void enforceCacheLimit(File audio) {
  if (runtimeData.cachedAudioCount > settings.maxAudiosCached &&
      audio.existsSync()) {
    audio.deleteSync();
  }
}
