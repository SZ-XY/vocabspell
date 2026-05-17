import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../global.dart';
import '../ui/license_page.dart';

class LicenseAgreementPage extends StatefulWidget {
  const LicenseAgreementPage({super.key});

  @override
  State<LicenseAgreementPage> createState() => _LicenseAgreementPageState();
}

class _LicenseAgreementPageState extends State<LicenseAgreementPage> {
  String _licenseText = '加载中...';
  String _licenseZh = '中文参考';

  Future<void> _loadLicense() async {
    final text = await Future.wait([
      rootBundle
          .loadString('assets/LICENSE')
          .catchError(
            (_) => '无法加载英文许可协议\n请见:https://apache.org/licenses/LICENSE-2.0',
          ),
      rootBundle
          .loadString('assets/LICENSE_zh.txt')
          .catchError((_) => '中文译本暂未提供'),
    ]);
    setState(() {
      _licenseText = text[0];
      _licenseZh = text[1];
    });
  }

  @override
  void initState() {
    super.initState();
    _loadLicense();
  }

  void _onAgree() {
    settings.isFirstRun = false;
    settings.saveSettings();
    Navigator.pop(context, true);
  }

  void _onDisagree() {
    // 用户不同意，退出应用
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('用户协议与开源许可'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ExpansionTile(
                    title: Text('许可证全文', style: const TextStyle(fontSize: 16)),
                    initiallyExpanded: false,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _licenseText,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text(
                      '中文参考(非官方译文,仅为便于阅读理解研讨,不提供任何明示或默示或保证)',
                      style: const TextStyle(fontSize: 16),
                    ),
                    initiallyExpanded: false,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_licenseZh, style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LicenseScreen()),
                );
              },
              child: Text('查看使用的开源组件'),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onDisagree,
                        child: const Text('不同意并退出'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onAgree,
                        child: const Text('同意并继续'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
