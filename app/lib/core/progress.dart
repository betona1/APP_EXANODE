/// 진행 저장 — 프로토타입 localStorage 키 체계(crdl.*)를 그대로 미러링.
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';

class BestRecord {
  final int moves;
  final double time;
  final int stars;
  const BestRecord(this.moves, this.time, this.stars);
}

class Progress {
  final SharedPreferences _p;
  Progress(this._p);

  static Future<Progress> load() async =>
      Progress(await SharedPreferences.getInstance());

  String _g(Genre g) => g == Genre.fill ? 'fill' : 'path';

  int stage(Genre g) => _p.getInt('crdl.stage.${_g(g)}') ?? 1;
  Future<void> setStage(Genre g, int s) => _p.setInt('crdl.stage.${_g(g)}', s);

  int maxStage(Genre g) => _p.getInt('crdl.max.${_g(g)}') ?? 0;
  Future<void> setMaxStage(Genre g, int s) => _p.setInt('crdl.max.${_g(g)}', s);

  Genre get genre =>
      (_p.getString('crdl.genre') ?? 'fill') == 'path' ? Genre.path : Genre.fill;
  Future<void> setGenre(Genre g) => _p.setString('crdl.genre', _g(g));

  bool get soundOn => _p.getBool('crdl.soundOn') ?? true;
  Future<void> setSoundOn(bool v) => _p.setBool('crdl.soundOn', v);

  bool get onboarded => _p.getBool('crdl.onboarded') ?? false;
  Future<void> setOnboarded() => _p.setBool('crdl.onboarded', true);

  BestRecord? best(Genre g, int stage) {
    final key = 'crdl.best.${_g(g)}.$stage';
    final moves = _p.getInt('$key.moves');
    if (moves == null) return null;
    return BestRecord(
      moves,
      _p.getDouble('$key.time') ?? 0,
      _p.getInt('$key.stars') ?? 1,
    );
  }

  Future<void> setBest(Genre g, int stage, BestRecord r) async {
    final key = 'crdl.best.${_g(g)}.$stage';
    await _p.setInt('$key.moves', r.moves);
    await _p.setDouble('$key.time', r.time);
    await _p.setInt('$key.stars', r.stars);
  }

  int totalStars(Genre g) {
    var t = 0;
    final max = maxStage(g);
    for (var s = 1; s <= max; s++) {
      t += best(g, s)?.stars ?? 1;
    }
    return t;
  }
}
