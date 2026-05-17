import 'dart:io';
import '../tools/file_tools.dart';

class ReviewScheduler {
  final void Function(int wordIndex) onWordRemoved;
  // 单词的数量
  int length = 0;
  // 已经提问的单词数量
  int _t = 0;
  // 还没有被问的单词的索引
  List<int> pendingIndices = [];
  // (可以被问的最早时间, 连续正确的次数,负数则是连续错误的次数, 实际内容的索引)
  List<(int, int, int)> scheduledIndices = [];

  ReviewScheduler({required this.length, required this.onWordRemoved});

  Map<String, dynamic> toJson() => {
    '_t': _t,
    'pendingIndices': pendingIndices,
    'scheduledIndices': scheduledIndices
        .map((e) => [e.$1, e.$2, e.$3])
        .toList(),
  };
  void init(File file) {
    if (file.existsSync()) {
      final json = readFile(file);
      _t = json['_t'] as int;
      pendingIndices = (json['pendingIndices'] as List).cast<int>().toList();
      final raw = json['scheduledIndices'] as List;
      scheduledIndices = raw.map((e) {
        final list = (e as List).cast<int>();
        return (list[0], list[1], list[2]);
      }).toList();
    } else {
      _t = 0;
      pendingIndices = List.generate(length, (index) => index);
      scheduledIndices.clear();
      writeFile(toJson(), file);
    }
  }

  int getInterval(int correctStreak) {
    // 正确的间隔: 5,10,24,60,80,200,250
    if (correctStreak == 1) return 5;
    if (correctStreak == 2) return 10;
    if (correctStreak == 3) return 24;
    if (correctStreak == 4) return 60;
    if (correctStreak == 5) return 80;
    if (correctStreak == 6) return 200;
    if (correctStreak == 7) return 250;
    if (correctStreak > 7) return -1; // -1表示这个单词可以删除了(不再出现)

    // 错误的间隔 3,1,0
    if (correctStreak == -1) return 3;
    if (correctStreak == -2) return 1;
    if (correctStreak <= -3) return 0;

    return -2; // 传入0的结果
  }

  void add() {
    pendingIndices.add(length);
    length++;
  }

  void _insert(bool isCorrect) {
    final wordIndex = scheduledIndices[0].$3;
    int correctStreak = scheduledIndices[0].$2;
    if (isCorrect) {
      if (correctStreak >= 0) {
        correctStreak++;
      } else {
        correctStreak = 1;
      }
    } else {
      if (correctStreak < 0) {
        correctStreak--;
      } else {
        correctStreak = -1;
      }
    }
    final interval = getInterval(correctStreak);
    scheduledIndices.removeAt(0);

    if (interval == -1) {
      onWordRemoved(wordIndex);
      return;
    } else if (interval == -2) {
      throw Exception('没有回答就提交了');
    }
    final targetIndex = _t + interval;

    final high = scheduledIndices.length - 1;
    final low = findInsertIndex(targetIndex, high: high);
    scheduledIndices.insert(low, (targetIndex, correctStreak, wordIndex));
  }

  void _new(int index) {
    scheduledIndices.insert(findInsertIndex(_t), (_t, 0, index));
    pendingIndices.removeAt(0);
  }

  int findInsertIndex(int target, {int high = 0}) {
    int low = 0;
    if (high <= 0) {
      high = scheduledIndices.length;
    }
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (scheduledIndices[mid].$1 < target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    if (low < scheduledIndices.length && scheduledIndices[low].$1 < target) {
      return low + 1;
    }
    return low;
  }

  /// 给出下一个要出现单词的索引
  int next() {
    if (scheduledIndices.isEmpty || scheduledIndices[0].$1 > _t) {
      if (pendingIndices.isEmpty) {
        if (scheduledIndices.isEmpty) return -1;
        _t = scheduledIndices[0].$1; // 快进到最近的一个
        return scheduledIndices[0].$3;
      }
      final index = pendingIndices[0];
      _new(index); // 这里pendingIndices的第一个就已经删除了,后面不能用了
      return index;
    }
    return scheduledIndices[0].$3;
  }

  void onMistake() {
    _t++;
    _insert(false);
  }

  void onCorrect() {
    _t++;
    _insert(true);
  }
}
