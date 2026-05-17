import 'package:flutter/material.dart';
import 'license_page.dart';
import '../tools/play_text.dart';
import '../global.dart';
import '../tools/cache_audio_tools.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _getVoiceName(int sid) {
    const voices = [
      'Bella',
      'Jasper',
      'Luna',
      'Bruno',
      'Rosie',
      'Hugo',
      'Kiki',
      'Leo',
    ];
    return (sid >= 0 && sid < voices.length) ? voices[sid] : '未知';
  }

  void _previewVoice() {
    playWord('Hello, this is a test.');
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除缓存'),
        content: Text('确定要删除所有音频缓存吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      rmAllAudioCache();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('音频缓存已清除')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('开源许可证'),
            subtitle: const Text('查看使用的开源组件和使用条款'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LicenseScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('当前音色'),
            subtitle: Text(_getVoiceName(settings.sid)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Slider(
              value: settings.sid.toDouble(),
              min: 0,
              max: 7,
              divisions: 7,
              label: _getVoiceName(settings.sid),
              onChanged: (value) {
                setState(() {
                  settings.sid = value.round();
                });
              },
              onChangeEnd: (value) {
                settings.sid = value.round();
                settings.saveSettings();
                _previewVoice();
                setState(() {});
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('清除音频缓存'),
            subtitle: Text('删除当前 ${runtimeData.cachedAudioCount} 个单词音频'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmClearCache(context),
          ),
        ],
      ),
    );
  }
}
