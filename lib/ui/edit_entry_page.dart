import 'package:flutter/material.dart';
import '../global.dart';
import '../dict/dict.dart';

class EditEntryPage extends StatefulWidget {
  final int index;
  const EditEntryPage({required this.index, super.key});

  @override
  State<EditEntryPage> createState() => _EditEntryPageState();
}

class _EditEntryPageState extends State<EditEntryPage> {
  late final TextEditingController _wordController;
  late final TextEditingController _phoneticController;
  late final TextEditingController _definitionController;

  @override
  void dispose() {
    _wordController.dispose();
    _phoneticController.dispose();
    _definitionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final entry = runtimeData
        .selectedDict
        .content[(widget.index == -1) ? 0 : widget.index];
    _wordController = TextEditingController(text: entry.word);
    _phoneticController = TextEditingController(text: entry.phonetic);
    _definitionController = TextEditingController(text: entry.definition);
  }

  Future<void> _saveEntry() async {
    final word = _wordController.text.trim();
    final phonetic = _phoneticController.text.trim();
    final definition = _definitionController.text.trim();

    if (word.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('单词不能为空')));
      return;
    }

    final entry = Entry(word: word, phonetic: phonetic, definition: definition);

    runtimeData.selectedDict.content[(widget.index == -1) ? 0 : widget.index] =
        entry;
    await runtimeData.selectedDict.saveContent();

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改单词')),
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
