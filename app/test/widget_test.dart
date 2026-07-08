import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crdl/core/controller.dart';
import 'package:crdl/core/progress.dart';
import 'package:crdl/main.dart';

void main() {
  testWidgets('앱이 타이틀 화면으로 시작한다', (tester) async {
    SharedPreferences.setMockInitialValues({'crdl.onboarded': true});
    final progress = await Progress.load();
    await tester.pumpWidget(CrdlApp(controller: GameController(progress)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('CRDL'), findsOneWidget);
    expect(find.text('▶ 모험 시작'), findsOneWidget);
  });
}
