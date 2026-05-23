import 'dart:io';
import '../tools/file_tools.dart';
import 'package:path_provider/path_provider.dart';

class AppSettings {
  int maxAudiosCached = 500;
  bool isFirstRun = true;
  int sid = 3;
  late File _file;
  Future<void> initSettings() async {
    final appDir = await getApplicationSupportDirectory();
    final settingsDir = Directory('${appDir.path}/settings');
    if (!settingsDir.existsSync()) {
      settingsDir.createSync(recursive: true);
    }
    _file = File('${settingsDir.path}/settings.json');

    if (_file.existsSync()) {
      final settings = readFile(_file);
      maxAudiosCached = settings['maxAudiosCached'] ?? 500;
      isFirstRun = settings['isFirstRun'] ?? true;
      sid = settings['sid'] ?? 3;
    } else {
      saveSettings();
    }
  }

  void saveSettings() {
    final settings = {
      'isFirstRun': isFirstRun,
      'maxAudiosCached': maxAudiosCached,
      'sid': sid,
    };
    writeFile(settings, _file);
  }
}
