import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';
import '../global.dart';

Future<void> copyModel() async {
  final modelDir = Directory('$appDocDir/models/kitten-nano-en-v0_1-fp16');
  if (!modelDir.existsSync()) {
    final ByteData byteData = await rootBundle.load(
      'assets/models/kitten-nano-en-v0_1-fp16.tar.bz2',
    );
    final Uint8List exactBytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    final bz2Decoder = BZip2Decoder();
    final tarBytes = bz2Decoder.decodeBytes(exactBytes);
    final tarArchive = TarDecoder().decodeBytes(tarBytes);

    for (final file in tarArchive.files) {
      // 跳过目录和可能的根目录前缀
      if (file.name.endsWith('/')) continue;
      final relativePath = file.name.split('/').sublist(1).join('/');
      if (relativePath.isEmpty) continue;

      final target = File('${modelDir.path}/$relativePath');
      await target.create(recursive: true);
      // 基本不会为空
      await target.writeAsBytes(file.content);
    }
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
