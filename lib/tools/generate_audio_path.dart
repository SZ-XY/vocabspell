import 'package:path/path.dart' as p;

String generateAudioPath(
  String word,
  int sid,
  String appCacheDir, {
  double speed = 1.0,
}) {
  final sanitized = word.replaceAll(RegExp(r'[^\w]'), '_');
  return p.join(
    appCacheDir,
    'audiocache',
    sid.toString(),
    '$sanitized-$speed.wav',
  );
}
