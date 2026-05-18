import 'package:flutter/material.dart';
import '../global.dart';
import '../dict/dict.dart';

class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _wordController = TextEditingController();
  final _phoneticController = TextEditingController();
  final _definitionController = TextEditingController();

  @override
  void dispose() {
    _wordController.dispose();
    _phoneticController.dispose();
    _definitionController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final word = _wordController.text.trim();
    final phonetic = _phoneticController.text.trim();
    final definition = _definitionController.text.trim();

    if (word.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('单词不能为空')));
      return;
    }

    final entry = Entry(word: word, phonetic: phonetic, definition: definition);

    await runtimeData.selectedDict.addItem(entry);

    if (!mounted) return;
    Navigator.pop(context, true); // 返回 true 通知主页刷新
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加单词')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _wordController,
              decoration: const InputDecoration(
                labelText: '单词/词组',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneticController,
              decoration: const InputDecoration(
                labelText: '音标',
                hintText: '词组时为空',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _definitionController,
              decoration: const InputDecoration(
                labelText: '释义',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.save, size: 32),
              label: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddEntryFromString extends StatefulWidget {
  const AddEntryFromString({super.key});

  @override
  State<AddEntryFromString> createState() => _AddEntryFromStringState();
}

class _AddEntryFromStringState extends State<AddEntryFromString> {
  bool _isSaving = false;
  final TextEditingController _textEditingController = TextEditingController();

  void _setSaving(bool value) {
    setState(() => _isSaving = value);
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    _setSaving(true);
    final text = _textEditingController.text.trim();
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('文本不能为空')));
      _setSaving(false);
      return;
    }

    final errors = await runtimeData.selectedDict.addItems(text);
    if (!mounted) {
      _setSaving(false);
      return;
    }
    if (errors.isNotEmpty) {
      _setSaving(false);
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('解析错误'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('第${e.$1}个: ${e.$2}'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
      return;
    }
    _setSaving(false);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('批量添加单词'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Column(
        children: [
          TextField(
            controller: _textEditingController,
            decoration: InputDecoration(
              labelText: '文本',
              hintText:
                  '格式: 单词|音标(为空当做词组)|释义\n例: vocab|美[ˈvoʊˌkæb],英[ˈvəʊkæb]|词汇',
              border: OutlineInputBorder(),
            ),
            maxLines: null,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveEntry,
            icon: const Icon(Icons.save, size: 32),
            label: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
