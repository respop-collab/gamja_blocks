import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ads/ad_manager.dart';
import '../game/curve.dart';
import '../game/engine.dart';
import '../game/piece.dart';
import '../game/cards.dart';
import '../storage/prefs.dart';
import 'theme.dart';
import 'widgets.dart';

class GameScreen extends StatefulWidget {
  final int stage;
  const GameScreen({super.key, required this.stage});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late GameEngine _e;
  final GlobalKey _boardKey = GlobalKey();
  final List<GlobalKey> _trayKeys = List.generate(kTraySize, (_) => GlobalKey());

  int? _dragIndex;
  Offset _dragAt = Offset.zero;
  double _grabFx = 0.5, _grabFy = 0.5, _lift = 0;
  (int, int)? _hover;
  Set<int> _flash = {};
  bool _dialogOpen = false;
  bool _revived = false;

  String _buddySprite = Gamja.peek;
  String _buddyText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _e = _loadOrStart();
    _buddyText = _idleLine();
  }

  GameEngine _loadOrStart() {
    final saved = Prefs.savedGame;
    if (saved != null) {
      final e = GameEngine.fromJson(saved);
      if (e != null && e.p.stage == widget.stage) return e;
    }
    return GameEngine.start(widget.stage);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) _persist();
  }

  void _persist() {
    Prefs.setSavedGame(_e.result == StageResult.playing ? _e.toJson() : null);
  }

  String _idleLine() => switch (_e.p.tier) {
        Tier.elementary => '같이 놀자!',
        Tier.middle => '할 수 있어!',
        Tier.high => '집중!',
        Tier.adult => '쉽지 않을걸.',
        Tier.endless => '끝이 없어!',
      };

  void _say(String text, {String sprite = Gamja.wave}) {
    setState(() {
      _buddyText = text;
      _buddySprite = sprite;
    });
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() {
        _buddyText = _idleLine();
        _buddySprite = Gamja.peek;
      });
    });
  }

  void _haptic(HapticKind k) {
    if (!Prefs.vibration) return;
    switch (k) {
      case HapticKind.select:
        HapticFeedback.selectionClick();
      case HapticKind.light:
        HapticFeedback.lightImpact();
      case HapticKind.medium:
        HapticFeedback.mediumImpact();
    }
  }

  // ---------- 드래그 ----------

  double get _cell {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return 40;
    return (box.size.width - 8) / _e.size;
  }

  /// 흡착 관대함도 난이도다. 어릴수록 넉넉하게 붙여 준다.
  double get _snapTolerance => switch (_e.p.tier) {
        Tier.elementary => 2.4,
        Tier.middle => 1.9,
        _ => 1.4,
      };

  (int, int)? _snap(Piece p, double rf, double cf) {
    final r0 = rf.round(), c0 = cf.round();
    (int, int)? best;
    var bd = double.infinity;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final r = r0 + dr, c = c0 + dc;
        if (!_e.canPlace(p, r, c)) continue;
        final d = math.pow(r - rf, 2) + math.pow(c - cf, 2);
        if (d < bd) {
          bd = d.toDouble();
          best = (r, c);
        }
      }
    }
    return (best != null && bd <= _snapTolerance) ? best : null;
  }

  void _onPanStart(int i, DragStartDetails d, Size pieceSize, Offset pieceOrigin) {
    if (_e.tray[i] == null || _e.result != StageResult.playing) return;
    final local = d.globalPosition - pieceOrigin;
    setState(() {
      _dragIndex = i;
      _dragAt = d.globalPosition;
      _grabFx = (local.dx / pieceSize.width).clamp(0.0, 1.0);
      _grabFy = (local.dy / pieceSize.height).clamp(0.0, 1.0);
      // 손가락이 도형을 가리므로 위로 띄운다. 마우스는 띄우지 않는다.
      _lift = _cell * 1.2;
      _hover = null;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final i = _dragIndex;
    if (i == null) return;
    final p = _e.tray[i]!;
    final cell = _cell;
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final topLeft = _ghostTopLeft(d.globalPosition, p, cell);
    final local = box.globalToLocal(topLeft);
    final spot = _snap(p, (local.dy - 4) / cell, (local.dx - 4) / cell);
    final changed = spot != _hover;
    setState(() {
      _dragAt = d.globalPosition;
      _hover = spot;
    });
    if (changed && spot != null) _haptic(HapticKind.select);
  }

  Offset _ghostTopLeft(Offset finger, Piece p, double cell) => Offset(
        finger.dx - _grabFx * p.width * cell,
        finger.dy - _grabFy * p.height * cell - _lift,
      );

  void _onPanEnd() {
    final i = _dragIndex, h = _hover;
    setState(() {
      _dragIndex = null;
      _hover = null;
    });
    if (i == null || h == null) return;
    final out = _e.place(i, h.$1, h.$2);
    if (out == null) return;

    _haptic(out.clearedLines > 0 ? HapticKind.medium : HapticKind.light);
    if (out.clearedLines > 0) {
      setState(() => _flash = out.clearedCells.toSet());
      Future.delayed(const Duration(milliseconds: 240), () {
        if (mounted) setState(() => _flash = {});
      });
      _say(out.clearedLines >= 3
          ? '대단해!'
          : out.clearedLines >= 2
              ? '우와! 두 줄!'
              : '잘했어!');
    } else {
      setState(() {});
    }
    _persist();

    switch (_e.result) {
      case StageResult.cleared:
        Future.delayed(const Duration(milliseconds: 420), _onCleared);
      case StageResult.failedStuck:
      case StageResult.failedOutOfMoves:
        Future.delayed(const Duration(milliseconds: 420), _onFailed);
      case StageResult.playing:
        // 초등 구간은 실패가 없다. 막히면 감자가 치워 준다.
        if (!_e.anyMoveAvailable && !_e.p.canFail) {
          Future.delayed(const Duration(milliseconds: 420), _doHelp);
        }
    }
  }

  // ---------- 도움 ----------

  void _doHelp() {
    final cleared = _e.helpClear();
    if (cleared.isEmpty) return;
    setState(() => _flash = cleared.toSet());
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) setState(() => _flash = {});
    });
    _say('내가 치워 줄게!');
    _persist();
  }

  bool get _canHelp =>
      _e.result == StageResult.playing && (_e.p.unlimitedHelps || _e.helpsLeft > 0);

  // ---------- 클리어 / 실패 ----------

  Future<void> _onCleared() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    await Prefs.setSavedGame(null);
    await Prefs.incStagesCleared();
    final next = _e.p.stage + 1;
    await Prefs.setStage(next);
    if (next > Prefs.bestStage) await Prefs.setBestStage(next);

    final cardIdx = cardIndexForStage(_e.p.stage);
    if (cardIdx != null) {
      final cards = Prefs.cards;
      cards[cardIdx] = cards[cardIdx] + 1;
      await Prefs.setCards(cards);
    }
    if (!mounted) return;

    final nextTier = tierOf(next);
    final sub = cardIdx != null
        ? '감자 카드를 한 장 받았어요'
        : nextTier != _e.p.tier
            ? '다음은 ${nextTier.label} 구간이에요'
            : '${10 - (_e.p.stage % 10)}단계 뒤에 카드를 받아요';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ResultDialog(
        image: cardIdx != null ? kCards[cardIdx].asset : Gamja.wave,
        title: cardIdx != null ? '${kCards[cardIdx].name} 획득!' : '${_e.p.stage}단계 통과!',
        subtitle: sub,
        primaryLabel: '다음 단계',
        onPrimary: () => Navigator.pop(ctx),
      ),
    );
    _dialogOpen = false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(stage: next)),
    );
  }

  Future<void> _onFailed() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    await Prefs.setSavedGame(null);
    if (!mounted) return;

    final outOfMoves = _e.result == StageResult.failedOutOfMoves;
    final canRevive = !_revived && AdManager.instance.rewardedReadyFor(_e.p.tier);

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ResultDialog(
        image: Gamja.sleep,
        title: outOfMoves ? '수를 다 썼어요' : '더 놓을 곳이 없어요',
        subtitle: '줄 ${_e.linesCleared}개까지 갔어요. 목표는 ${_e.p.goal}개!',
        primaryLabel: canRevive ? '광고 보고 이어하기' : '다시 하기',
        onPrimary: () => Navigator.pop(ctx, canRevive ? 'revive' : 'retry'),
        secondaryLabel: canRevive ? '다시 하기' : null,
        onSecondary: canRevive ? () => Navigator.pop(ctx, 'retry') : null,
        tertiaryLabel: '홈으로',
        onTertiary: () => Navigator.pop(ctx, 'home'),
      ),
    );
    _dialogOpen = false;
    if (!mounted) return;

    switch (action) {
      case 'revive':
        final ok = await AdManager.instance.showRewarded();
        if (!mounted) return;
        if (ok) {
          _revived = true;
          setState(() => _e.reviveByAd());
          _say('한 번 더!');
          _persist();
        } else {
          _onFailed();
        }
      case 'retry':
        AdManager.instance.onStageFailed(_e.p.tier, onDone: () {
          if (!mounted) return;
          setState(() {
            _e = GameEngine.start(widget.stage);
            _revived = false;
          });
        });
      default:
        Navigator.of(context).pop();
    }
  }

  // ---------- 화면 ----------

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final boardW = math.min(media.size.width - 32, media.size.height * 0.48);
    final cell = (boardW - 8) / _e.size;
    final dragPiece = _dragIndex == null ? null : _e.tray[_dragIndex!];

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) => _persist(),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildHud(),
                    const Spacer(),
                    Center(child: _buildBoard(boardW, cell)),
                    const SizedBox(height: 14),
                    _buildTray(cell),
                    const SizedBox(height: 6),
                    BuddyBar(
                      sprite: _buddySprite,
                      text: _buddyText,
                      trailing: _e.p.unlimitedHelps || _e.p.helps > 0
                          ? GbButton(
                              label: _e.p.unlimitedHelps ? '도움' : '도움 ${_e.helpsLeft}',
                              onPressed: _canHelp ? _doHelp : null,
                            )
                          : null,
                    ),
                    const Spacer(),
                    const BannerSlot(),
                  ],
                ),
              ),
              if (dragPiece != null)
                Builder(builder: (context) {
                  final tl = _ghostTopLeft(_dragAt, dragPiece, cell);
                  final pad = media.padding;
                  return Positioned(
                    left: tl.dx - 16,
                    top: tl.dy - pad.top,
                    child: IgnorePointer(
                      child: PieceView(piece: dragPiece, cell: cell, opacity: 0.92),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    final p = _e.p;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _persist();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_ios_new, color: kInkSoft, size: 20),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: kCarrot,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0xFFC9712A), offset: Offset(0, 3))],
            ),
            child: Text('${p.stage}단계',
                style: const TextStyle(fontFamily: 'Jua', fontSize: 18, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: kTierColor[p.tier],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(p.tier.label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kInk)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '줄 ${p.goal}개 (${math.min(_e.linesCleared, p.goal)}/${p.goal})'
                  '${p.hasMoveLimit ? ' · 남은 수 ${math.max(0, _e.movesLeft)}' : ''}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: kInkSoft),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _e.progress,
                    minHeight: 13,
                    backgroundColor: kHole,
                    valueColor: const AlwaysStoppedAnimation(kCarrot),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(double boardW, double cell) {
    final hoverCells = <int>{};
    Color? hoverColor;
    if (_hover != null && _dragIndex != null) {
      final p = _e.tray[_dragIndex!]!;
      hoverColor = kBlockColors[p.colorIndex % kBlockColors.length];
      for (final (dr, dc) in p.cells) {
        hoverCells.add((_hover!.$1 + dr) * _e.size + _hover!.$2 + dc);
      }
    }

    return Container(
      key: _boardKey,
      width: boardW,
      height: boardW,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kBoardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          for (var r = 0; r < _e.size; r++)
            for (var c = 0; c < _e.size; c++)
              Positioned(
                left: c * cell,
                top: r * cell,
                width: cell,
                height: cell,
                child: Padding(
                  padding: EdgeInsets.all(cell * 0.05),
                  child: _cellWidget(r, c, hoverCells, hoverColor),
                ),
              ),
        ],
      ),
    );
  }

  Widget _cellWidget(int r, int c, Set<int> hoverCells, Color? hoverColor) {
    final k = r * _e.size + c;
    if (_flash.contains(k)) {
      return const BlockCell(color: Colors.white);
    }
    final v = _e.board[r][c];
    if (v == kStone) return const HoleCell(stone: true);
    if (v != kEmpty) {
      return BlockCell(color: kBlockColors[(v - 1) % kBlockColors.length]);
    }
    if (hoverCells.contains(k) && hoverColor != null) {
      return BlockCell(color: hoverColor, opacity: 0.45);
    }
    return const HoleCell();
  }

  Widget _buildTray(double boardCell) {
    final trayCell = boardCell * 0.52;
    return SizedBox(
      height: 104,
      child: Row(
        children: [
          for (var i = 0; i < kTraySize; i++)
            Expanded(child: _traySlot(i, trayCell)),
        ],
      ),
    );
  }

  Widget _traySlot(int i, double trayCell) {
    final p = _e.tray[i];
    if (p == null || _dragIndex == i) return const SizedBox.shrink();
    final key = _trayKeys[i];
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          final box = key.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return;
          _onPanStart(i, d, box.size, box.localToGlobal(Offset.zero));
        },
        onPanUpdate: _onPanUpdate,
        onPanEnd: (_) => _onPanEnd(),
        onPanCancel: _onPanEnd,
        child: PieceView(key: key, piece: p, cell: trayCell),
      ),
    );
  }
}

enum HapticKind { select, light, medium }

class _ResultDialog extends StatelessWidget {
  final String image, title, subtitle, primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel, tertiaryLabel;
  final VoidCallback? onSecondary, onTertiary;

  const _ResultDialog({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.tertiaryLabel,
    this.onTertiary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: kLine, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(image, height: 130, filterQuality: FilterQuality.medium),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Jua', fontSize: 25, color: kInk)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: kInkSoft)),
            const SizedBox(height: 20),
            GbButton(label: primaryLabel, primary: true, onPressed: onPrimary, width: double.infinity),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              GbButton(label: secondaryLabel!, onPressed: onSecondary, width: double.infinity),
            ],
            if (tertiaryLabel != null) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: onTertiary,
                child: Text(tertiaryLabel!,
                    style: const TextStyle(fontFamily: 'Jua', fontSize: 16, color: kInkSoft)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
