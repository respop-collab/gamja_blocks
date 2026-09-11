/// 로컬 저장소. 서버 없음, 개인정보 수집 없음.
/// 저장하는 것은 진행 단계, 카드 수집 현황, 진행 중인 판, 설정, 광고 빈도 카운터뿐이다.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../game/cards.dart';
import '../game/records.dart';

class Prefs {
  static late SharedPreferences _p;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  // 진행 단계
  static int get stage => _p.getInt('stage') ?? 1;
  static Future<void> setStage(int v) => _p.setInt('stage', v);

  static int get bestStage => _p.getInt('best_stage') ?? 1;
  static Future<void> setBestStage(int v) => _p.setInt('best_stage', v);

  // 감자 카드 (종류별 획득 수).
  // 카드가 늘어나도 기존 저장값을 잃지 않도록 길이를 맞춰 읽는다.
  static List<int> get cards {
    final out = List.filled(kCardCount, 0);
    final raw = _p.getStringList('cards');
    if (raw == null) return out;
    for (var i = 0; i < kCardCount && i < raw.length; i++) {
      out[i] = int.tryParse(raw[i]) ?? 0;
    }
    return out;
  }

  static Future<void> setCards(List<int> v) =>
      _p.setStringList('cards', v.map((e) => e.toString()).toList());

  // 진행 중인 판
  static String? get savedGame => _p.getString('saved_game');
  static Future<void> setSavedGame(String? json) =>
      json == null ? _p.remove('saved_game') : _p.setString('saved_game', json);

  // 설정
  static bool get sound => _p.getBool('sound') ?? true;
  static Future<void> setSound(bool v) => _p.setBool('sound', v);

  static bool get vibration => _p.getBool('vibration') ?? true;
  static Future<void> setVibration(bool v) => _p.setBool('vibration', v);

  static bool get adsRemoved => _p.getBool('ads_removed') ?? false;
  static Future<void> setAdsRemoved(bool v) => _p.setBool('ads_removed', v);

  // 통계
  static int get stagesCleared => _p.getInt('stages_cleared') ?? 0;
  static Future<void> incStagesCleared() => _p.setInt('stages_cleared', stagesCleared + 1);

  // 기록 — 마일스톤 단계의 개인 최고 클리어 시간(밀리초)
  //
  // 나중에 Play Games 리더보드를 켤 때 이 값을 그대로 올린다.
  // 그때 가서 기록을 처음부터 모으면 먼저 시작한 이용자가 불리해지므로
  // 순위표가 없는 지금부터 쌓아 둔다.
  static int bestTimeMs(int stage) => _p.getInt('best_ms_$stage') ?? 0;

  /// 더 빠른 기록일 때만 갱신한다. 갱신했으면 true.
  static Future<bool> recordTime(int stage, int ms) async {
    if (!isMilestone(stage) || ms <= 0) return false;
    final prev = bestTimeMs(stage);
    if (prev != 0 && prev <= ms) return false;
    await _p.setInt('best_ms_$stage', ms);
    return true;
  }

  /// 모든 판에 들인 시간의 합. 나중에 누적 시간 순위에 쓴다.
  static int get totalPlayMs => _p.getInt('total_play_ms') ?? 0;
  static Future<void> addPlayMs(int ms) =>
      _p.setInt('total_play_ms', totalPlayMs + (ms > 0 ? ms : 0));

  // 전면광고 빈도 제어
  static int get failCount => _p.getInt('fail_count') ?? 0;
  static Future<void> setFailCount(int v) => _p.setInt('fail_count', v);
  static int get lastInterstitialMs => _p.getInt('last_interstitial_ms') ?? 0;
  static Future<void> setLastInterstitialMs(int v) => _p.setInt('last_interstitial_ms', v);
}
