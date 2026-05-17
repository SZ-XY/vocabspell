import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocabspell/global.dart';
import '../tts/isolate_tts.dart';
import '../tools/copy_assets.dart';
import 'license_agreement_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = '正在加载初始资源\n请等待';
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await initGlobalValues();

    if (settings.isFirstRun) {
      setState(() {
        _status = '等待用户同意许可协议...';
      });
      if (!mounted) return;
      final agreed = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LicenseAgreementPage()),
      );
      if (agreed != true) {
        if (mounted) SystemNavigator.pop();
        return;
      }
    }
    setState(() {
      _status = '正在加载资源\n请等待';
    });
    // 已经复制时自动跳过
    await copyModel();

    setState(() => _status = '正在加载TTS引擎\n请等待');
    await IsolateTts.init();
    if (!mounted) return; // 防止异步操作时widget已经销毁
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(_status, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
