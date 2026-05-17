import 'dart:isolate';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../tools/generate_audio_path.dart';

class _IsolateTask<T> {
  final SendPort sendPort;

  RootIsolateToken? rootIsolateToken;

  _IsolateTask(this.sendPort, this.rootIsolateToken);
}

class _PortModel {
  final String method;

  final SendPort? sendPort;
  dynamic data;

  _PortModel({required this.method, this.sendPort, this.data});
}

class _TtsManager {
  /// 主进程通信端口
  final ReceivePort receivePort;

  final Isolate isolate;

  final SendPort isolatePort;

  _TtsManager({
    required this.receivePort,
    required this.isolate,
    required this.isolatePort,
  });
}

class IsolateTts {
  static late final _TtsManager _ttsManager;

  /// 获取线程里的通信端口
  static SendPort get _sendPort => _ttsManager.isolatePort;

  static late sherpa_onnx.OfflineTts _tts;

  static Future<void> init() async {
    ReceivePort port = ReceivePort();
    RootIsolateToken? rootIsolateToken = RootIsolateToken.instance;

    Isolate isolate = await Isolate.spawn(
      _isolateEntry,
      _IsolateTask(port.sendPort, rootIsolateToken),
      errorsAreFatal: false,
    );
    final msg = await port.first; // 阻塞直到收到消息
    if (msg is SendPort) {
      _ttsManager = _TtsManager(
        receivePort: port,
        isolate: isolate,
        isolatePort: msg,
      );
    }
  }

  static Future<void> _isolateEntry(_IsolateTask task) async {
    if (task.rootIsolateToken != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(
        task.rootIsolateToken!,
      );
    }
    sherpa_onnx.initBindings();
    final receivePort = ReceivePort();
    task.sendPort.send(receivePort.sendPort);

    final appDoc = await getApplicationSupportDirectory();
    final appDocDir = appDoc.path;
    final appCache = await getApplicationCacheDirectory();
    final appCacheDir = appCache.path;
    final modelName =
        '$appDocDir/models/kitten-nano-en-v0_1-fp16/model.fp16.onnx';
    final dataDir = '$appDocDir/models/kitten-nano-en-v0_1-fp16/espeak-ng-data';
    final tokens = '$appDocDir/models/kitten-nano-en-v0_1-fp16/tokens.txt';
    final voices = '$appDocDir/models/kitten-nano-en-v0_1-fp16/voices.bin';

    final kitten = sherpa_onnx.OfflineTtsKittenModelConfig(
      model: modelName,
      dataDir: dataDir,
      tokens: tokens,
      voices: voices,
    );

    final modelConfig = sherpa_onnx.OfflineTtsModelConfig(
      kitten: kitten,
      numThreads: 2,
      debug: false,
      provider: 'cpu',
    );

    final config = sherpa_onnx.OfflineTtsConfig(
      model: modelConfig,
      maxNumSenetences: 1,
    );
    // print(config);
    receivePort.listen((msg) async {
      if (msg is _PortModel) {
        switch (msg.method) {
          case 'generate':
            _PortModel v = msg;
            try {
              final stopwatch = Stopwatch();
              stopwatch.start();
              final genConfig = sherpa_onnx.OfflineTtsGenerationConfig(
                sid: v.data['sid'],
                speed: v.data['speed'],
                silenceScale: 0.2,
              );
              final audio = _tts.generateWithConfig(
                text: v.data['text'],
                config: genConfig,
              );
              final audioDir = Directory(
                p.join(appCacheDir, 'audiocache', v.data['sid'].toString()),
              );
              if (!audioDir.existsSync()) {
                audioDir.createSync(recursive: true);
              }
              final filename = generateAudioPath(
                v.data['text'],
                v.data['sid'],
                appCacheDir,
                speed: v.data['speed'],
              );

              final ok = sherpa_onnx.writeWave(
                filename: filename,
                samples: audio.samples,
                sampleRate: audio.sampleRate,
              );

              if (ok) {
                stopwatch.stop();
                v.sendPort?.send(filename);
              } else {
                stopwatch.stop();
                v.sendPort?.send('failed');
              }
            } catch (e) {
              //print('合成失败: $e, $s');
              v.sendPort?.send('failed');
            }
            break;
        }
      }
    });
    _tts = sherpa_onnx.OfflineTts(config);
  }

  static Future<String> generate(
    String text, {
    int sid = 0,
    double speed = 1.0,
  }) async {
    ReceivePort receivePort = ReceivePort();
    _sendPort.send(
      _PortModel(
        method: 'generate',
        data: {'text': text, 'sid': sid, 'speed': speed},
        sendPort: receivePort.sendPort,
      ),
    );
    final result = await receivePort.first;
    receivePort.close();
    if (result == 'failed') {
      throw Exception('音频合成失败');
    }
    return result as String;
  }
}
