/// CRDL(차례대로) — 숫자를 1→N 순서대로 먹는 격자 퍼즐.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/controller.dart';
import 'core/progress.dart';
import 'ui/theme.dart';
import 'ui/title_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final progress = await Progress.load();
  runApp(CrdlApp(controller: GameController(progress)));
}

class CrdlApp extends StatelessWidget {
  final GameController controller;
  const CrdlApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRDL — 차례대로',
      debugShowCheckedModeBanner: false,
      theme: crdlTheme(),
      home: TitleScreen(ctl: controller),
    );
  }
}
