/// 게임 화면 — 보드 + HUD + 입력(탭/드래그/키보드/D패드) + 튜토리얼 코치
/// + 물 클리어 연출(수도꼭지 낙하→콸콸) + 별점 배너 + 색종이.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/controller.dart';
import '../core/game.dart';
import 'board_painter.dart';
import 'mascot.dart';
import 'theme.dart';

class GameScreen extends StatefulWidget {
  final GameController ctl;
  const GameScreen({super.key, required this.ctl});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final AnimationController _anim; // 상시 티커 (펄스/마스코트)
  late final AnimationController _water; // 물 흐름
  late final AnimationController _faucet; // 수도꼭지 낙하
  late final AnimationController _confetti;
  final _focus = FocusNode();
  bool _clearRunning = false;

  GameController get ctl => widget.ctl;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    _water = AnimationController(vsync: this);
    _faucet =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
    _confetti =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    ctl.addListener(_onCtl);
  }

  void _onCtl() {
    if (ctl.phase == ClearPhase.waterFlow && !_clearRunning) {
      _clearRunning = true;
      _runClearSequence();
    }
    if (mounted) setState(() {});
  }

  Future<void> _runClearSequence() async {
    HapticFeedback.mediumImpact();
    _faucet.value = 0;
    _water.value = 0;
    await _faucet.forward(); // 낙하 + 착지
    HapticFeedback.heavyImpact();
    final ms = (ctl.game.path.length * 70).clamp(1600, 4200);
    _water.duration = Duration(milliseconds: ms);
    await _water.forward();
    _confetti.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 450));
    _clearRunning = false;
    ctl.waterFlowDone();
  }

  @override
  void dispose() {
    ctl.removeListener(_onCtl);
    _anim.dispose();
    _water.dispose();
    _faucet.dispose();
    _confetti.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _move(MoveDir d) {
    final before = ctl.game.target;
    if (ctl.move(d)) {
      if (ctl.game.target != before) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _handlePointer(Offset local, BoardGeometry geo, {required bool isTap}) {
    if (ctl.phase == ClearPhase.waterFlow || ctl.phase == ClearPhase.banner) return;
    final cell = geo.cellAt(local);
    if (cell == null) return;
    final (r, c) = cell;
    if (ctl.game.head == null) {
      if (isTap && ctl.tapCell(r, c)) HapticFeedback.mediumImpact();
      return;
    }
    final dr = r - ctl.game.head!.$1, dc = c - ctl.game.head!.$2;
    if (dr.abs() + dc.abs() == 1) {
      final dir = MoveDir.values.firstWhere((d) => d.dr == dr && d.dc == dc);
      _move(dir);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) {
      _move(MoveDir.up);
    } else if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS) {
      _move(MoveDir.down);
    } else if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      _move(MoveDir.left);
    } else if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
      _move(MoveDir.right);
    } else if (k == LogicalKeyboardKey.keyZ) {
      ctl.undo();
    } else if (k == LogicalKeyboardKey.keyR) {
      ctl.retry();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final tutorialWait = ctl.tutorial && ctl.game.head == null && !ctl.game.over;
    return Scaffold(
      body: Container(
        decoration: bgDecoration(),
        child: SafeArea(
          child: Focus(
            focusNode: _focus,
            autofocus: true,
            onKeyEvent: _onKey,
            child: Stack(
              children: [
                Column(
                  children: [
                    _brandBar(),
                    _hud(),
                    _ruleText(tutorialWait),
                    Expanded(child: _board(tutorialWait)),
                    _controls(),
                    const SizedBox(height: 8),
                  ],
                ),
                if (ctl.phase == ClearPhase.banner) _banner(),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _confetti,
                    builder: (_, _) => _confetti.isAnimating
                        ? CustomPaint(
                            size: MediaQuery.sizeOf(context),
                            painter: ConfettiPainter(_confetti.value),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      child: Row(
        children: [
          _iconBtn('🗺️', () => Navigator.of(context).maybePop()),
          const SizedBox(width: 6),
          const Mascot(size: 30),
          const SizedBox(width: 8),
          const Text('CRDL',
              style: TextStyle(
                  fontFamily: numFont,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: C.head)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${ctl.genre == Genre.fill ? "⛏" : "✏"} 판 #${ctl.stage} · ${ctl.config.tier}',
              style: const TextStyle(fontSize: 12, color: C.muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(String emoji, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: C.ink2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.grid),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _hud() {
    final g = ctl.game;
    final prog = ctl.genre == Genre.fill
        ? '${g.path.length} / ${g.total}'
        : '${math.min(g.target - 1, g.level.count)} / ${g.level.count}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        children: [
          _hudCard('다음 숫자', g.target > g.level.count ? '완료' : '${g.target}',
              valueColor: C.token),
          const SizedBox(width: 7),
          _hudCard(ctl.genre == Genre.fill ? '채운 칸' : '숫자', prog),
          const SizedBox(width: 7),
          _hudCard('시간', '${ctl.elapsed.toStringAsFixed(1)}s'),
        ],
      ),
    );
  }

  Widget _hudCard(String label, String value, {Color valueColor = C.head}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [C.ink2, Color(0xFF0A1D24)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.grid),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9, letterSpacing: 1.5, color: C.muted)),
            Text(value,
                style: TextStyle(
                    fontFamily: numFont,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _ruleText(bool tutorialWait) {
    String text;
    if (tutorialWait) {
      text = '🐍 숫자 1을 탭하면 뱀이 출발해요!';
    } else if (ctl.tutorial && ctl.stage == 1) {
      text = '✨ 반짝이는 화살표를 따라가요 — 옆 칸 탭·드래그 모두 OK!';
    } else if (ctl.tutorial && ctl.stage == 2) {
      text = '🚧 지나온 몸통은 벽! 이번엔 스스로 길을 찾아보세요.';
    } else if (ctl.tutorial && ctl.stage == 3) {
      text = '⛏ 모든 칸을 덮어야 클리어! 갇히면 게임 오버.';
    } else {
      text = ctl.genre == Genre.fill
          ? '⛏ 모든 칸을 채우면서 숫자를 1→N 순서로. 갇히면 게임 오버.'
          : '✏ 숫자만 1→N 순서로 이어요. 칸을 다 채울 필요는 없어요.';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: C.muted)),
    );
  }

  Widget _board(bool tutorialWait) {
    return LayoutBuilder(builder: (context, box) {
      final g = ctl.game;
      const pad = 6.0;
      final cell = math.min(
        (box.maxWidth - 20 - pad * 2) / g.cols,
        (box.maxHeight - 8 - pad * 2) / g.rows,
      );
      final geo = BoardGeometry(g.rows, g.cols, cell, pad: pad);
      final boardSize = geo.size;
      final left = (box.maxWidth - boardSize.width) / 2;
      final top = (box.maxHeight - boardSize.height) / 2;

      // 수도꼭지 위치 (물 연출)
      Widget? faucet;
      if (ctl.phase == ClearPhase.waterFlow && g.path.isNotEmpty) {
        final start = g.path.first;
        final cx = left + geo.center(start.$1, start.$2).dx;
        faucet = AnimatedBuilder(
          animation: Listenable.merge([_faucet, _water]),
          builder: (_, _) {
            final f = Curves.easeOutBack.transform(_faucet.value);
            final fy = top - 58;
            final y = -80 + (fy + 80) * f;
            final streamTop = fy + 46;
            final streamBottom =
                top + geo.center(start.$1, start.$2).dy - cell * 0.15;
            return Stack(children: [
              if (_faucet.isCompleted && _water.value < 1)
                Positioned(
                  left: cx - 3.5,
                  top: streamTop,
                  child: Container(
                    width: 7,
                    height: math.max(0, streamBottom - streamTop),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFD6F6FF), C.water]),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                            color: C.water.withValues(alpha: .8), blurRadius: 12)
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: cx - 24,
                top: y,
                child: Transform.rotate(
                  angle: (1 - f) * -1.2,
                  child: Transform.scale(
                    scale: .3 + .7 * f,
                    child: const _FaucetIcon(size: 48),
                  ),
                ),
              ),
            ]);
          },
        );
      }

      return Stack(children: [
        Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            onTapDown: (d) => _handlePointer(d.localPosition, geo, isTap: true),
            onPanUpdate: (d) =>
                _handlePointer(d.localPosition, geo, isTap: false),
            child: AnimatedBuilder(
              animation: Listenable.merge([_anim, _water]),
              builder: (_, _) => CustomPaint(
                size: boardSize,
                painter: BoardPainter(
                  ctl,
                  geo,
                  animT: _anim.value,
                  waterP: ctl.phase == ClearPhase.waterFlow ? _water.value : 0,
                  coachSpot: tutorialWait,
                ),
              ),
            ),
          ),
        ),
        ?faucet,
        if (tutorialWait) _coachHand(geo, left, top),
        if (tutorialWait) _coachBubble(tutorialWait),
      ]);
    });
  }

  Widget _coachHand(BoardGeometry geo, double left, double top) {
    final g = ctl.game;
    final k1 = g.level.numAt.entries.firstWhere((e) => e.value == 1).key;
    final r = k1 ~/ g.cols, c = k1 % g.cols;
    final p = geo.center(r, c);
    return Positioned(
      left: left + p.dx - 4,
      top: top + p.dy + 2,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, _) {
          final tap = math.sin(_anim.value * 2 * math.pi * 11).abs();
          return Transform.translate(
            offset: Offset(4 - tap * 4, 8 - tap * 8),
            child: Transform.scale(
              scale: 1 - tap * .15,
              child: const Text('👆', style: TextStyle(fontSize: 32)),
            ),
          );
        },
      ),
    );
  }

  Widget _coachBubble(bool tutorialWait) {
    final text = ctl.stage == 1
        ? '🐍 숫자 1을 탭하면 뱀이 출발해요!'
        : ctl.stage == 2
            ? '조금 더 넓어졌어요. 숫자 1을 탭!'
            : '마지막 연습! 숫자 1을 탭!';
    return Positioned(
      top: 4,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF12333F), Color(0xFF0B2129)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.accent, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 16)
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Mascot(size: 34),
            const SizedBox(width: 8),
            Flexible(
              child:
                  Text(text, style: const TextStyle(fontSize: 13, color: C.text)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _controls() {
    return Column(children: [
      SizedBox(
        width: 190,
        child: Column(children: [
          _dpadBtn('▲', MoveDir.up),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dpadBtn('◀', MoveDir.left),
              _dpadBtn('▼', MoveDir.down),
              _dpadBtn('▶', MoveDir.right),
            ],
          ),
        ]),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _textBtn('↩ 되돌리기', ctl.undo),
        const SizedBox(width: 7),
        _textBtn('🔄 다시', ctl.retry, primary: true),
      ]),
    ]);
  }

  Widget _dpadBtn(String label, MoveDir d) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        width: 54,
        height: 42,
        child: ElevatedButton(
          onPressed: () => _move(d),
          style: ElevatedButton.styleFrom(
            backgroundColor: C.ink2,
            foregroundColor: C.text,
            side: const BorderSide(color: C.grid),
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 17)),
        ),
      ),
    );
  }

  Widget _textBtn(String label, VoidCallback onTap, {bool primary = false}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary ? const Color(0xFF13A88A) : C.ink2,
        foregroundColor: primary ? const Color(0xFF012A22) : C.text,
        side: BorderSide(color: primary ? const Color(0xFF1EE0BD) : C.grid),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: const TextStyle(
            fontFamily: uiFont, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }

  Widget _banner() {
    final won = ctl.game.won;
    return Container(
      color: const Color(0xCC030A0C),
      alignment: Alignment.center,
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [C.ink2, Color(0xFF08171C)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.grid),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: .6), blurRadius: 40)
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            won ? '판 #${ctl.stage} 클리어!' : '게임 오버',
            style: TextStyle(
                fontFamily: uiFont,
                fontSize: 23,
                color: won ? C.eaten : C.danger),
          ),
          if (won) _stars(),
          const SizedBox(height: 6),
          Text(
            won
                ? '숫자 1~${ctl.game.level.count}을 차례대로 완성했어요.\n'
                    '${ctl.game.path.length - 1}이동 · ${ctl.elapsed.toStringAsFixed(1)}초'
                : '${ctl.loseReason ?? ""}\n되돌리기로 살리거나 다시 도전!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: C.text, height: 1.5),
          ),
          if (won && ctl.newRecord)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('🏆 신기록!',
                  style: TextStyle(fontSize: 12, color: C.token)),
            ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _textBtn('🗺️ 지도', () => Navigator.of(context).maybePop()),
            const SizedBox(width: 8),
            if (won)
              _textBtn('▶ 다음 판', () {
                _confetti.reset();
                ctl.nextStage();
              }, primary: true)
            else
              _textBtn('🔁 다시 도전', ctl.retry, primary: true),
          ]),
        ]),
      ),
    );
  }

  Widget _stars() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final earned = i < ctl.earnedStars;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + i * 220),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(earned ? '⭐' : '☆',
                  style: TextStyle(
                      fontSize: 30,
                      color: earned ? C.gold : C.muted.withValues(alpha: .4))),
            ),
          );
        }),
      ),
    );
  }
}

/// 귀여운 수도꼭지 아이콘.
class _FaucetIcon extends StatelessWidget {
  final double size;
  const _FaucetIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size * .94), painter: _FaucetPainter());
  }
}

class _FaucetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;
    canvas.scale(s);
    final metal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE3F1F9), Color(0xFF9FBCCC), Color(0xFF6A8899)],
      ).createShader(const Rect.fromLTWH(0, 0, 64, 60));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xFF26404E);

    // 상단 파이프 + 밸브
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(27, 0, 10, 13), const Radius.circular(2.5)),
        metal);
    final pink = Paint()..color = const Color(0xFFFFA8BC);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(46.8, 3.5, 4.4, 12), const Radius.circular(2)),
        pink);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(43, 7.3, 12, 4.4), const Radius.circular(2)),
        pink);
    // 본체
    final body = Path()
      ..moveTo(22, 30)
      ..lineTo(22, 12)
      ..quadraticBezierTo(22, 10, 24, 10)
      ..lineTo(52, 10)
      ..quadraticBezierTo(56, 10, 56, 14)
      ..lineTo(56, 26)
      ..quadraticBezierTo(56, 30, 52, 30)
      ..close();
    canvas.drawPath(body, metal);
    canvas.drawPath(body, line);
    // 주둥이
    final spout = Path()
      ..moveTo(22, 10)
      ..quadraticBezierTo(8, 10, 8, 24)
      ..lineTo(8, 40)
      ..quadraticBezierTo(8, 46, 15, 46)
      ..quadraticBezierTo(22, 46, 22, 40)
      ..lineTo(22, 30);
    canvas.drawPath(spout, metal);
    canvas.drawPath(spout, line);
    // 얼굴
    final dark = Paint()..color = const Color(0xFF26404E);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(34, 19), width: 5.2, height: 6), dark);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(46, 19), width: 5.2, height: 6), dark);
    canvas.drawCircle(const Offset(34.9, 18), .9, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(46.9, 18), .9, Paint()..color = Colors.white);
    final blush = Paint()..color = C.blush.withValues(alpha: .65);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(30, 24.5), width: 4.8, height: 3),
        blush);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 24.5), width: 4.8, height: 3),
        blush);
    canvas.drawPath(
        Path()
          ..moveTo(37, 24)
          ..quadraticBezierTo(40, 27, 43, 24),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF26404E));
  }

  @override
  bool shouldRepaint(_FaucetPainter old) => false;
}

/// 색종이.
class ConfettiPainter extends CustomPainter {
  final double t;
  static final _rnd = math.Random(7);
  static final List<(double, double, double, double, int)> _parts =
      List.generate(46, (i) {
    return (
      _rnd.nextDouble(), // x (0~1)
      .6 + _rnd.nextDouble() * .8, // 낙하 속도 배율
      _rnd.nextDouble() * 2 * math.pi, // 회전 위상
      6 + _rnd.nextDouble() * 6, // 크기
      i % 6, // 색 인덱스
    );
  });
  static const _colors = [
    C.gold, C.accent, C.water, Color(0xFFFF6B8A), Color(0xFF7DFFC0), C.blush,
  ];

  ConfettiPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, sp, ph, sz, ci) in _parts) {
      final y = (t * sp * 1.3) % 1.15 - .08;
      final px = x * size.width + math.sin(t * 6 + ph) * 22;
      final py = y * size.height;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(t * 10 * sp + ph);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: sz, height: sz * 1.5),
              const Radius.circular(2)),
          Paint()..color = _colors[ci].withValues(alpha: .95));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => old.t != t;
}
