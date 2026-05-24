import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tools/play_text.dart';
import '../global.dart';
import '../dict/dict.dart';
import '../ui/add_entry_page.dart';
import '../ui/add_dict_page.dart';
import '../ui/edit_entry_page.dart';
import 'package:file_picker/file_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textEditingController = TextEditingController();
  late int _currentIndex;
  bool _isAnswered = false; // 是否提交答案
  bool _isWordCorrect = false; // 提交的答案是否正确(用于判断是否显示释义)
  bool _showDefinition = false; // 是否显示释义
  Entry? _currentEntry;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();

  Future<void> _loadNextWord() async {
    _currentIndex = runtimeData.selectedDict.reviewScheduler.next();
    if (_currentIndex == -1) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('提示'),
          content: Text('当前没有可学习的单词，请添加新词或稍后再来'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('知道了')),
          ],
        ),
      );
      // 更新空白界面
      setState(() {
        _currentEntry = null;
        _isAnswered = false;
        _isWordCorrect = false;
        _showDefinition = false;
        _textEditingController.clear();
      });
      return;
    }
    setState(() {
      _currentEntry = runtimeData.selectedDict.content[_currentIndex];
      _isAnswered = false;
      _isWordCorrect = false;
      _showDefinition = false;
      _textEditingController.clear();
    });
    if (_currentEntry?.phonetic == '') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mainFocusNode.requestFocus();
        }
      });
      _isAnswered = true;
      _isWordCorrect = true;
      return;
    } else {
      // 自动播放新单词的发音并请求焦点
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
      await playWord(_currentEntry?.word ?? '');
    }
  }

  void _advance({bool isWrong = false}) {
    if (_currentEntry == null) {
      _loadNextWord();
      return;
    }
    if (_isAnswered) {
      if (_isWordCorrect) {
        if (_showDefinition) {
          if (isWrong) {
            runtimeData.onMistake();
            _loadNextWord();
            return;
          } else {
            runtimeData.onCorrect();
            _loadNextWord();
            return;
          }
        } else {
          // 没有显示释义就显示
          setState(() {
            _showDefinition = true;
          });
        }
      } else {
        // 单词错误
        if (_showDefinition) {
          runtimeData.onMistake();
          _loadNextWord();
        } else {
          _textEditingController.text = _currentEntry?.word ?? '';
          _showDefinition = true;
        }
      }
    } else {
      runtimeData.onMistake();
      // 单词拼写失败,点击继续显示释义等
      setState(() {
        _isWordCorrect = false;
        _isAnswered = true;
        _showDefinition = true;
        _textEditingController.text = _currentEntry?.word ?? '';
      });
    }
  }

  Future<void> _addEntryPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEntryPage()),
    );
    if (!context.mounted) return;
    if (result == true) {
      _loadNextWord();
    }
  }

  Future<void> _editEntryPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditEntryPage(index: _currentIndex),
      ),
    );
    if (!context.mounted) return;
    if (result == true) {
      setState(() {
        _currentEntry = runtimeData.selectedDict.content[_currentIndex];
        _isAnswered = false;
        _isWordCorrect = false;
        _showDefinition = false;
        _textEditingController.clear();
      });
      await playWord(_currentEntry!.word);
    }
  }

  Future<void> _addEntryFromStringPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEntryFromString()),
    );
    if (!context.mounted) return;
    if (result == true) {
      _loadNextWord();
    }
  }

  Future<void> _newDictPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddNewDictPage()),
    );
    if (!context.mounted) return;
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _dictFromStringPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddDictPage()),
    );
    if (!context.mounted) return;
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _importDictPage() async {
    FilePickerResult? fileResult = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (fileResult == null) return;
    if (!mounted) return;
    File file = File(fileResult.files.single.path!);
    final String text = await file.readAsString();
    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddDictPage(text: text)),
    );
    if (!context.mounted) return;
    if (result == true) {
      setState(() {});
    }
  }

  void _showDictSelector(BuildContext context) async {
    final dictNames = runtimeData.getDictList();
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择词典'),
        children: dictNames.map((name) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, name),
            child: Text(name),
          );
        }).toList(),
      ),
    );
    if (!context.mounted) return;
    if (selected != null && selected != runtimeData.selectedDict.name) {
      await runtimeData.switchDict(selected);
      _loadNextWord();
    }
  }

  Future<void> _deleteDictPage(BuildContext context) async {
    final dictNames = runtimeData.getDictList();
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('删除词典'),
        children: dictNames.map((name) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, name),
            child: Text(name),
          );
        }).toList(),
      ),
    );
    if (!context.mounted) return;
    if (selected == null) return;
    if (selected == runtimeData.selectedDict.name) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法删除当前正在使用的词典: $selected')));
      return;
    }
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除词典 $selected吗?\n此操作不可撤销'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (confirm != true) return;
    Dict.deleteDict(selected);
    setState(() {});
    _loadNextWord();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已删除词典: $selected')));
  }

  Future<void> _resetProgressPage(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除词典 ${runtimeData.selectedDict.name}的进度吗?\n此操作不可撤销'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (confirm != true) return;
    runtimeData.selectedDict.resetProgress();
    setState(() {});
    _loadNextWord();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已删除词典: ${runtimeData.selectedDict.name}的进度')),
    );
  }

  void _showDictOption(BuildContext context) async {
    final option = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('词典管理'),
        children: [
          SimpleDialogOption(
            child: Text('导入词典'),
            onPressed: () => Navigator.pop(ctx, 'importDict'),
          ),

          SimpleDialogOption(
            child: Text('从文本新建'),
            onPressed: () => Navigator.pop(ctx, 'fromString'),
          ),
          SimpleDialogOption(
            child: Text('新建空白词典'),
            onPressed: () => Navigator.pop(ctx, 'newDict'),
          ),
          SimpleDialogOption(
            child: Text('删除词典'),
            onPressed: () => Navigator.pop(ctx, 'deleteDict'),
          ),
          SimpleDialogOption(
            child: Text('重置当前词典进度'),
            onPressed: () => Navigator.pop(ctx, 'resetDictProgress'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (option == 'importDict') {
      await _importDictPage();
    } else if (option == 'fromString') {
      await _dictFromStringPage();
    } else if (option == 'newDict') {
      await _newDictPage();
    } else if (option == 'deleteDict') {
      await _deleteDictPage(context);
    } else if (option == 'resetDictProgress') {
      await _resetProgressPage(context);
    }
  }

  void _showEntryOption(BuildContext context) async {
    final option = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('单词管理'),
        children: [
          SimpleDialogOption(
            child: Text('新建'),
            onPressed: () => Navigator.pop(ctx, 'new'),
          ),
          SimpleDialogOption(
            child: Text('修改'),
            onPressed: () => Navigator.pop(ctx, 'edit'),
          ),
          SimpleDialogOption(
            child: Text('从文本新建'),
            onPressed: () => Navigator.pop(ctx, 'fromString'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (option == 'new') {
      await _addEntryPage();
    } else if (option == 'edit') {
      await _editEntryPage();
    } else if (option == 'fromString') {
      await _addEntryFromStringPage();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNextWord();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    _mainFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null,
        toolbarHeight: 48,
        automaticallyImplyLeading: false,
        actions: [
          GestureDetector(
            onTap: () => _showDictSelector(context),
            onSecondaryTap: () => _showDictOption(context),
            onLongPress: () => _showDictOption(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.3,
              ),
              child: Text(
                runtimeData.selectedDict.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.circle,
            color: (_currentEntry == null) ? Colors.red : Colors.green,
            size: 12,
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _addEntryPage(),
            onSecondaryTap: () => _showEntryOption(context),
            onLongPress: () => _showEntryOption(context),
            child: Icon(Icons.add),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: FractionallySizedBox(
          widthFactor: 0.6,
          child: CallbackShortcuts(
            bindings: _shotcuts,
            child: Focus(
              focusNode: _mainFocusNode,
              autofocus: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: (_currentEntry?.phonetic == '')
                    ? [
                        Text(
                          _currentEntry?.definition ?? '',
                          style: TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 60),
                        Text(
                          _showDefinition ? _currentEntry?.word ?? '' : '',
                          style: TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 60),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: '前进\n快捷键: A',
                              child: ElevatedButton(
                                onPressed: () => _advance(),
                                child: Icon(Icons.arrow_forward, size: 32),
                              ),
                            ),
                            _showDefinition
                                ? Padding(
                                    padding: const EdgeInsetsGeometry.only(
                                      left: 30,
                                    ),
                                    child: Tooltip(
                                      message: '标记为错误\n快捷键: M',
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _advance(isWrong: true),
                                        child: Icon(Icons.cancel),
                                      ),
                                    ),
                                  )
                                : SizedBox(width: 0),
                          ],
                        ),
                      ]
                    : [
                        TextField(
                          focusNode: _focusNode,
                          readOnly: _isAnswered,
                          controller: _textEditingController,
                          onChanged: (text) {
                            if (_currentEntry == null) {
                              _loadNextWord();
                              return;
                            }
                            if (text == _currentEntry!.word) {
                              setState(() {
                                _isAnswered = true;
                                _isWordCorrect = true;
                              });
                            }
                          },
                          textInputAction: TextInputAction.send,
                          style: TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _isAnswered ? _currentEntry?.phonetic ?? '' : '',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _showDefinition
                              ? _currentEntry?.definition ?? ''
                              : '',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: '播放音频\n快捷键: R (输入时 Ctrl+R)',
                              child: ElevatedButton(
                                onPressed: () => playWord(
                                  (_currentEntry == null)
                                      ? ''
                                      : _currentEntry!.word,
                                ),
                                child: Icon(Icons.play_arrow, size: 32),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Tooltip(
                              message: '前进(答错会标记错误)\n快捷键: A (输入时 Ctrl+A)',
                              child: ElevatedButton(
                                onPressed: () => _advance(),
                                child: Icon(Icons.arrow_forward, size: 32),
                              ),
                            ),
                            _showDefinition
                                ? Padding(
                                    padding: const EdgeInsetsGeometry.only(
                                      left: 20,
                                    ),
                                    child: Tooltip(
                                      message: '标记为错误\n快捷键: M (输入时 Ctrl+M)',
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _advance(isWrong: true),
                                        child: Icon(Icons.cancel),
                                      ),
                                    ),
                                  )
                                : SizedBox(width: 0),
                          ],
                        ),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> get _shotcuts {
    if (_isAnswered) {
      return {
        SingleActivator(LogicalKeyboardKey.keyA): () => _advance(),
        SingleActivator(LogicalKeyboardKey.keyR): () =>
            playWord(_currentEntry?.word ?? ''),
        SingleActivator(LogicalKeyboardKey.keyM): () => _advance(isWrong: true),
      };
    } else {
      return {
        SingleActivator(LogicalKeyboardKey.keyA, control: true): () =>
            _advance(),
        SingleActivator(LogicalKeyboardKey.keyR, control: true): () =>
            playWord(_currentEntry?.word ?? ''),
        SingleActivator(LogicalKeyboardKey.keyM, control: true): () =>
            _advance(isWrong: true),
      };
    }
  }
}
