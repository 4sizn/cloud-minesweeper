import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads.dart';
import 'collection.dart';
import 'app_info.dart';
import 'game.dart';
import 'style.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.game, required this.collection});
  final MineGame game;
  final CloudCollection collection;
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with WidgetsBindingObserver {
  late MineGame game = widget.game;
  final stopwatch = Stopwatch();
  Timer? timer;
  bool flagMode = false, saving = false;
  bool confirmingExit = false, helpOpen = false;
  int get seconds => stopwatch.elapsed.inSeconds;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && stopwatch.isRunning) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      stopwatch.stop();
    } else if (game.status == GameStatus.playing &&
        !confirmingExit &&
        !helpOpen) {
      stopwatch.start();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    stopwatch.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void interact(int index, {bool flag = false}) {
    if (game.finished) return;
    setState(() {
      if (flag || flagMode) {
        game.flag(index);
      } else {
        game.open(index);
        if (game.status == GameStatus.playing) stopwatch.start();
        if (game.finished) stopwatch.stop();
      }
    });
    if (game.finished) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> collect() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final piece = await widget.collection.collect(game, seconds);
      await Ads.show();
      if (mounted) Navigator.pop(context, piece);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구름을 저장하지 못했어요. 다시 시도해주세요.')),
        );
      }
    }
  }

  Future<void> retry() async {
    await Ads.show();
    if (!mounted) return;
    setState(() {
      game = MineGame(
        shape: game.shape,
        seed: game.seed,
        name: game.name,
        id: game.id,
        source: game.source,
        difficulty: game.difficulty,
      );
      stopwatch
        ..stop()
        ..reset();
      flagMode = false;
    });
  }

  Future<void> confirmExit() async {
    if (confirmingExit || saving) return;
    confirmingExit = true;
    stopwatch.stop();
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          game.status == GameStatus.won ? '구름을 보관하지 않고 나갈까요?' : '이번 게임에서 나갈까요?',
        ),
        content: const Text('이 게임의 진행 상황은 저장되지 않아요. 모아둔 구름은 그대로 유지돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속하기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    confirmingExit = false;
    if (!mounted) return;
    if (leave == true) {
      Navigator.pop(context);
    } else if (game.status == GameStatus.playing) {
      stopwatch.start();
    }
  }

  Future<void> help() async {
    helpOpen = true;
    stopwatch.stop();
    await showPlayHelp(context);
    helpOpen = false;
    if (mounted && game.status == GameStatus.playing) stopwatch.start();
  }

  @override
  Widget build(BuildContext context) {
    final won = game.status == GameStatus.won;
    final lost = game.status == GameStatus.lost;
    return PopScope<CloudPiece>(
      canPop:
          !saving &&
          (game.status == GameStatus.ready || game.status == GameStatus.lost),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) confirmExit();
      },
      child: Scaffold(
        body: SkyBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 24, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: '내 하늘로 돌아가기',
                        onPressed: saving
                            ? null
                            : () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Chip(
                            label: Text(
                              '난이도 ${game.difficulty.description}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '플레이 방법',
                        onPressed: help,
                        icon: const Icon(Icons.help_outline, size: 21),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          won
                              ? '구름 하나를 완성했어요'
                              : lost
                              ? '다시, 천천히 해볼까요'
                              : game.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          won
                              ? '이제 나만의 하늘에 이어 붙여보세요.'
                              : lost
                              ? '이번 구름은 아직 모으지 않았어요.'
                              : '안전한 칸을 열어 구름을 완성하세요.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: mutedInk, fontSize: 14),
                        ),
                        const SizedBox(height: 30),
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 24,
                          runSpacing: 16,
                          children: [
                            _Stat(
                              Icons.flag_outlined,
                              '${max(0, game.mineCount - game.flagged.length)}',
                              '남은 지뢰',
                            ),
                            _Stat(
                              Icons.timer_outlined,
                              clockLabel(seconds),
                              '보낸 시간',
                            ),
                            _Stat(
                              Icons.grid_view_rounded,
                              '${game.opened.length}/${game.safeCount}',
                              '열린 칸',
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = min(constraints.maxWidth, 380.0);
                            return SizedBox(
                              width: width,
                              height:
                                  width * game.shape.rows / game.shape.columns +
                                  28,
                              child: InteractiveViewer(
                                minScale: 1,
                                maxScale: 2.5,
                                boundaryMargin: const EdgeInsets.all(40),
                                child: Center(
                                  child: SizedBox(
                                    width: width,
                                    height:
                                        width *
                                        game.shape.rows /
                                        game.shape.columns,
                                    child: GridView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: game.shape.columns,
                                          ),
                                      itemCount:
                                          game.shape.columns * game.shape.rows,
                                      itemBuilder: (context, i) =>
                                          game.shape.cells.contains(i)
                                          ? _cell(i)
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        if (!game.finished) ...[
                          SegmentedButton<bool>(
                            direction:
                                MediaQuery.sizeOf(context).width < 360 ||
                                    MediaQuery.textScalerOf(context).scale(14) >
                                        17
                                ? Axis.vertical
                                : Axis.horizontal,
                            segments: const [
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.touch_app_outlined),
                                label: Text('칸 열기'),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: Icon(Icons.flag_outlined),
                                label: Text('깃발 놓기'),
                              ),
                            ],
                            selected: {flagMode},
                            onSelectionChanged: (selection) =>
                                setState(() => flagMode = selection.first),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '첫 칸은 안전해요 · 길게 눌러도 깃발을 놓을 수 있어요',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: mutedInk),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '작은 칸은 두 손가락으로 확대해보세요',
                            style: TextStyle(fontSize: 12, color: mutedInk),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (game.finished)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 20, 26, 22),
                    child: PrimaryButton(
                      label: won
                          ? (saving ? '구름을 보관하고 있어요' : '내 하늘에 놓기')
                          : '다시 도전',
                      icon: won ? Icons.add_rounded : Icons.refresh_rounded,
                      onPressed: saving
                          ? null
                          : won
                          ? collect
                          : retry,
                    ),
                  ),
                if (!game.finished)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20, top: 14),
                    child: Eyebrow('천천히, 한 칸씩'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(int i) {
    final open = game.opened.contains(i), flag = game.flagged.contains(i);
    final mine = game.finished && game.mines.contains(i);
    final count = game.adjacent(i);
    final colors = [
      ink,
      const Color(0xFF3675A2),
      const Color(0xFF48866D),
      accent,
      const Color(0xFF7863A2),
    ];
    final row = i ~/ game.shape.columns + 1, col = i % game.shape.columns + 1;
    final description = mine
        ? '지뢰'
        : flag
        ? '깃발'
        : open
        ? '주변 지뢰 $count개'
        : '닫힌 칸';
    return Semantics(
      label: '$row행 $col열, $description',
      button: !open && !game.finished,
      child: GestureDetector(
        key: ValueKey('cell-$i'),
        onTap: () => interact(i),
        onLongPress: () => interact(i, flag: true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            color: i == game.exploded
                ? const Color(0xFFE9AC91)
                : open
                ? Colors.white.withValues(alpha: .42)
                : Colors.white.withValues(alpha: .93),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: open
                  ? Colors.white.withValues(alpha: .32)
                  : const Color(0xFFB8CEDF),
              width: .7,
            ),
          ),
          alignment: Alignment.center,
          child: mine
              ? Icon(
                  game.status == GameStatus.won
                      ? Icons.flag_rounded
                      : Icons.bolt_rounded,
                  size: 19,
                  color: accent,
                )
              : flag
              ? const Icon(Icons.flag_rounded, size: 19, color: accent)
              : open && count > 0
              ? Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors[min(count, 4)],
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label);
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: mutedInk),
          const SizedBox(width: 7),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: mutedInk, fontSize: 11)),
    ],
  );
}
