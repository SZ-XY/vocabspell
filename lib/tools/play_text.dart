import 'package:audioplayers/audioplayers.dart';
import '../tts/isolate_tts.dart';
import '../global.dart';
import '../tools/cache_audio_tools.dart';

/// 自动处理空字符串
Future<void> playWord(String text, {double speed = 1.0}) async {
  if (text == '') return;
  late final String audioPath;

  final path = findUsableCache(text);

  if (path == '') {
    audioPath = await IsolateTts.generate(
      text,
      speed: speed,
      sid: settings.sid,
    );
    runtimeData.cachedAudioCount++;
  } else {
    audioPath = path;
  }
  await player.play(DeviceFileSource(audioPath));
}
