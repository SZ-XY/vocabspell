import 'package:flutter/material.dart';
import 'package:vocabspell/dict/review_scheduler.dart';
import 'license_page.dart';
import '../tools/play_text.dart';
import '../global.dart';
import '../tools/cache_audio_tools.dart';
import '../tools/get_voice_name.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _previewVoice() {
    playWord('Hello, this is a test.');
  }

  Future<void> _showSpeakerSelector(BuildContext context) async {
    final selectedSid = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择音色'),
        children: List.generate(voices.length, (i) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, i),
            child: (i == settings.sid)
                ? Text(voices[i], style: TextStyle(color: Colors.green))
                : Text(voices[i]),
          );
        }),
      ),
    );

    if (selectedSid != null && context.mounted) {
      setState(() {
        settings.sid = selectedSid;
        settings.saveSettings();
        _previewVoice();
      });
    }
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

  void _editIntervalRules(BuildContext context) async {
    List<int> tempCorrect = List<int>.from(
      settings.intervalRules.correctIntervals,
    );
    List<int> tempIncorrect = List<int>.from(
      settings.intervalRules.incorrectIntervals,
    );
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('编辑间隔规则'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '正确间隔',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...List.generate(tempCorrect.length, (i) {
                  return ListTile(
                    dense: true,
                    title: Text('连续正确 ${i + 1} 次'),
                    subtitle: Text('间隔: ${tempCorrect[i]}'),
                    onTap: () async {
                      final newValue = await _showEditValueDialog(
                        ctx,
                        true,
                        i,
                        tempCorrect[i],
                      );
                      if (newValue != null) {
                        setDialogState(() {
                          tempCorrect[i] = newValue;
                        });
                      }
                    },
                  );
                }),
                const Divider(),
                ...List.generate(tempIncorrect.length, (i) {
                  return ListTile(
                    dense: true,
                    title: Text('连续错误 ${i + 1} 次'),
                    subtitle: Text('间隔: ${tempIncorrect[i]}'),
                    onTap: () async {
                      final newValue = await _showEditValueDialog(
                        ctx,
                        false,
                        i,
                        tempIncorrect[i],
                      );
                      if (newValue != null) {
                        setDialogState(() {
                          tempIncorrect[i] = newValue;
                        });
                      }
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final newIntervals = IntervalRules(
                  correctIntervals: tempCorrect,
                  incorrectIntervals: tempIncorrect,
                );
                settings.intervalRules = newIntervals;
                settings.intervalRules.save();
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _showEditValueDialog(
    BuildContext context,
    bool isEditingCorrect,
    int i,
    int currentValue,
  ) async {
    final controller = TextEditingController(text: currentValue.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEditingCorrect ? '修改第 ${i + 1} 次正确的间隔' : '修改第 ${i + 1} 次错误的间隔',
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '新值'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = int.tryParse(controller.text.trim());
              if (newValue != null &&
                  (isEditingCorrect ? newValue > 0 : newValue >= 0)) {
                Navigator.pop(ctx, newValue);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('请输入有效${isEditingCorrect ? "正整数" : "非负整数"}'),
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return result;
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
            subtitle: Text(getVoiceName(settings.sid)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSpeakerSelector(context),
          ),
          ListTile(
            title: const Text('编辑间隔规则'),
            subtitle: Text('自定义答对/答错后单词再次出现的间隔'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editIntervalRules(context),
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
