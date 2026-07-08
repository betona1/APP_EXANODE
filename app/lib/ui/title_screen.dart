/// 타이틀 화면 — 떠다니는 마스코트 + CRDL 로고 + 모험 시작.
library;

import 'package:flutter/material.dart';
import '../core/controller.dart';
import 'map_screen.dart';
import 'mascot.dart';
import 'theme.dart';

class TitleScreen extends StatefulWidget {
  final GameController ctl;
  const TitleScreen({super.key, required this.ctl});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.ctl.progress.onboarded) _showGuide();
    });
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  void _showGuide() {
    widget.ctl.progress.setOnboarded();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [C.ink2, Color(0xFF08171C)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: C.grid),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Mascot(size: 74),
            const SizedBox(height: 6),
            const Text('CRDL 시작 가이드',
                style: TextStyle(fontSize: 20, color: C.head)),
            const SizedBox(height: 12),
            _sec('🎯 목표', '뱀 커서로 격자를 훑으며 숫자를 1 → N 순서대로 밟으세요.'),
            _sec('🐍 이동 규칙', '상하좌우 이동, 지나간 칸(몸통)은 재통과 불가. 갇히면 게임 오버.'),
            _sec('⛏ 두 장르', '땅파기 — 모든 칸을 채우면서 완성 (어려움)\n길잇기 — 숫자만 순서대로 이으면 완성 (쉬움)'),
            _sec('🎮 조작', '숫자 1을 탭해서 시작 → 옆 칸 탭 · 드래그 · D패드 모두 OK.'),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13A88A),
                  foregroundColor: const Color(0xFF012A22),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('좋아, 시작!',
                    style: TextStyle(fontFamily: uiFont, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sec(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13, color: C.accent, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(body,
            style: const TextStyle(fontSize: 13, color: C.text, height: 1.5)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctl = widget.ctl;
    return Scaffold(
      body: Container(
        decoration: bgDecoration(),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _float,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -9 * _float.value),
                child: child,
              ),
              child: const Mascot(size: 150),
            ),
            const SizedBox(height: 4),
            const Text('CRDL',
                style: TextStyle(
                  fontFamily: numFont,
                  fontSize: 62,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 14,
                  color: C.head,
                  shadows: [
                    Shadow(color: Color(0x8854E6C8), blurRadius: 30),
                    Shadow(color: Colors.black54, offset: Offset(0, 4)),
                  ],
                )),
            const Text('차 · 례 · 대 · 로',
                style: TextStyle(
                    fontSize: 12, letterSpacing: 6, color: C.muted)),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: C.ink2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: C.grid),
              ),
              child: Text(
                '🏆 최고 판 ${ctl.progress.maxStage(ctl.genre)}  ·  ⭐ ${ctl.progress.totalStars(ctl.genre)}',
                style: const TextStyle(fontSize: 12, color: C.muted),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 260,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MapScreen(ctl: ctl))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13A88A),
                  foregroundColor: const Color(0xFF012A22),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('▶ 모험 시작',
                    style: TextStyle(
                        fontFamily: uiFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: 260,
              child: OutlinedButton(
                onPressed: _showGuide,
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.text,
                  side: const BorderSide(color: C.grid),
                  backgroundColor: C.ink2,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('❓ 게임 방법',
                    style: TextStyle(fontFamily: uiFont, fontSize: 14)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
