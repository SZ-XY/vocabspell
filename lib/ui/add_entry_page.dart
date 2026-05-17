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
