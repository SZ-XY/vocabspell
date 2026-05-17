import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'app/settings.dart';
import 'app/runtime_data.dart';

late String appDocDir;
late String appCacheDir;
late AudioPlayer player;
late AppSettings settings;
late RuntimeData runtimeData;

Future<void> initGlobalValues() async {
  final appDoc = await getApplicationSupportDirectory();
  appDocDir = appDoc.path;

  final appCache = await getApplicationCacheDirectory();
  appCacheDir = appCache.path;

  player = AudioPlayer();

  settings = AppSettings();
  await settings.initSettings();

  runtimeData = RuntimeData();
  await runtimeData.init();
}
