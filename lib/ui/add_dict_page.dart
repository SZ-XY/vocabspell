import 'package:flutter/material.dart';
import '../global.dart';
import '../dict/dict.dart';

class AddNewDictPage extends StatefulWidget {
  const AddNewDictPage({super.key});

  @override
  State<AddNewDictPage> createState() => _AddNewDictPageState();
}

class _AddNewDictPageState extends State<AddNewDictPage> {
  final _nameController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveDict() async {
    final name = _nameController.text.trim();
    final author = _authorController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('词库名字不能为空')));
      return;
    }
    if (author.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('词库作者不能为空')));
      return;
    }
    if (description.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('词库描述不能为空')));
      return;
    }
    await runtimeData.newDict(name, author, description);

    if (!mounted) return;
    Navigator.pop(context, true); // 返回 true 通知主页刷新
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建词库')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名字',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: '作者',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveDict,
              icon: const Icon(Icons.save, size: 32),
              label: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddDictPage extends StatefulWidget {
  const AddDictPage({super.key});

  @override
  State<AddDictPage> createState() => _AddDictPageState();
}

class _AddDictPageState extends State<AddDictPage> {
  final _textController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _resetSavingState() {
    setState(() => _isSaving = false);
  }

  Future<void> _saveDict() async {
    if (_isSaving) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正在保存')));
      return;
    }
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('输入为空')));
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final result = await Dict.fromString(_textController.text);
    if (!mounted) return;
    _resetSavingState();

    String? errorMsg;
    switch (result) {
      case 1:
        errorMsg = '名字和作者格式错误';
        break;
      case 2:
        errorMsg = '缺少词典描述';
        break;
      case 3:
        errorMsg = '存在格式不正确的词条';
        break;
      case 0: // 成功
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      default:
        errorMsg = '未知错误';
        break;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMsg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('从文本新建词库')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: '文本',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveDict,
              icon: const Icon(Icons.save, size: 32),
              label: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
