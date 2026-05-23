import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';
import '../global.dart';
import 'package:path/path.dart' as p;

Future<void> _extractModelBytes((Uint8List, String) args) async {
  final bz2Decoder = BZip2Decoder();
  final tarBytes = bz2Decoder.decodeBytes(args.$1);
  final tarArchive = TarDecoder().decodeBytes(tarBytes);

  for (final file in tarArchive.files) {
    if (file.name.endsWith('/')) continue;
    final relativePath = file.name.split('/').sublist(1).join('/');
    if (relativePath.isEmpty) continue;
    final target = File(p.join(args.$2, relativePath));
    await target.create(recursive: true);
    await target.writeAsBytes(file.content);
  }
}

Future<void> copyModel() async {
  final modelDir = Directory('$appDocDir/models/kokoro-int8-multi-lang-v1_0');
  if (!modelDir.existsSync()) {
    final ByteData byteData = await rootBundle.load(
      'assets/models/kokoro-int8-multi-lang-v1_0.tar.bz2',
    );
    final Uint8List exactBytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    await compute(_extractModelBytes, (exactBytes, modelDir.path));
  }
}

Future<void> copyExampleDict() async {
  final ByteData exampleDict = await rootBundle.load('assets/example.txt');
  final Uint8List bytes = exampleDict.buffer.asUint8List(
    exampleDict.offsetInBytes,
    exampleDict.lengthInBytes,
  );

  final dictDir = Directory('$appDocDir/dicts');
  if (!dictDir.existsSync()) {
    dictDir.createSync(recursive: true);
  }
  final file = File('$appDocDir/dicts/example.txt');
  await file.writeAsBytes(bytes);
}
