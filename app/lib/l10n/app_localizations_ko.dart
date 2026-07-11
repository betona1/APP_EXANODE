// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class L10nKo extends L10n {
  L10nKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Exanode';

  @override
  String get tagline => '엑 · 사 · 노 · 드';

  @override
  String get startAdventure => '▶ 모험 시작';

  @override
  String get howToPlay => '❓ 게임 방법';

  @override
  String bestBanner(int stage, int stars) {
    return '🏆 최고 판 $stage  ·  ⭐ $stars';
  }

  @override
  String get guideTitle => 'Exanode 시작 가이드';

  @override
  String get guideGoalTitle => '🎯 목표';

  @override
  String get guideGoalBody => '뱀 커서로 격자를 훑으며 숫자를 1 → N 순서대로 밟으세요.';

  @override
  String get guideMoveTitle => '🐍 이동 규칙';

  @override
  String get guideMoveBody => '상하좌우 이동, 지나간 칸(몸통)은 재통과 불가. 갇히면 게임 오버.';

  @override
  String get guideGenreTitle => '⛏ 두 장르';

  @override
  String get guideGenreBody =>
      '땅파기 — 모든 칸을 채우면서 완성 (어려움)\n길잇기 — 숫자만 순서대로 이으면 완성 (쉬움)';

  @override
  String get guideControlTitle => '🎮 조작';

  @override
  String get guideControlBody => '숫자 1을 탭해서 시작 → 옆 칸 탭 · 드래그 · D패드 모두 OK.';

  @override
  String get guideOk => '좋아, 시작!';

  @override
  String get stagesTitle => '스테이지';

  @override
  String get genreFill => '⛏ 땅파기';

  @override
  String get genrePath => '✏ 길잇기';

  @override
  String get lockedToast => '🔒 이전 판을 먼저 클리어하세요!';

  @override
  String get hudNext => '다음 숫자';

  @override
  String get hudDone => '완료';

  @override
  String get hudFilled => '채운 칸';

  @override
  String get hudNumbers => '숫자';

  @override
  String get hudTime => '시간';

  @override
  String boardHeader(int stage, String tier) {
    return '판 #$stage · $tier';
  }

  @override
  String get coachTapStart => '🐍 숫자 1을 탭하면 뱀이 출발해요!';

  @override
  String get coachArrows => '✨ 반짝이는 화살표를 따라가요 — 옆 칸 탭·드래그 모두 OK!';

  @override
  String get coachStage2 => '🚧 지나온 몸통은 벽! 이번엔 스스로 길을 찾아보세요.';

  @override
  String get coachFill => '⛏ 모든 칸을 덮어야 클리어! 갇히면 게임 오버.';

  @override
  String get ruleFill => '⛏ 모든 칸을 채우면서 숫자를 1→N 순서로. 갇히면 게임 오버.';

  @override
  String get rulePath => '✏ 숫자만 1→N 순서로 이어요. 칸을 다 채울 필요는 없어요.';

  @override
  String get tutorialWider => '조금 더 넓어졌어요. 숫자 1을 탭!';

  @override
  String get tutorialLast => '마지막 연습! 숫자 1을 탭!';

  @override
  String get undo => '↩ 되돌리기';

  @override
  String get restart => '🔄 다시';

  @override
  String clearTitle(int stage) {
    return '판 #$stage 클리어!';
  }

  @override
  String get gameOver => '게임 오버';

  @override
  String clearBody(int count, int moves, String time) {
    return '숫자 1~$count을 차례대로 완성했어요.\n$moves이동 · $time초';
  }

  @override
  String loseBody(String reason) {
    return '$reason\n되돌리기로 살리거나 다시 도전!';
  }

  @override
  String get newRecord => '🏆 신기록!';

  @override
  String get toMap => '🗺️ 지도';

  @override
  String get nextStage => '▶ 다음 판';

  @override
  String get retry => '🔁 다시 도전';

  @override
  String get tierTutorial => '튜토리얼';

  @override
  String get tierTutorial1 => '튜토리얼 1/3';

  @override
  String get tierTutorial2 => '튜토리얼 2/3';

  @override
  String get tierTutorial3 => '튜토리얼 3/3';

  @override
  String get tierFirst => '첫 실전';

  @override
  String get tierBeginner => '초급';

  @override
  String get tierEasy => '쉬움';

  @override
  String get tierNormal => '보통';

  @override
  String get tierHard => '어려움';

  @override
  String get tierMaster => '고수';

  @override
  String get loseDeadEnd => '막다른 길! 더 이상 이동할 수 없어요.';

  @override
  String get loseTrapped => '미로처럼 엉켰어요. 갇힌 칸이 생겼습니다.';

  @override
  String get loseNumberCut => '다음 숫자로 가는 길이 막혔어요.';
}
