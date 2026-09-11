/// 감자 카드 정의. UI가 아니라 데이터이므로 game 계층에 둔다.
/// 저장소(prefs)와 화면(album) 양쪽이 같은 목록을 참조해야 하기 때문이다.
library;

class CardDef {
  final String asset;
  final String name;

  /// 같은 시리즈끼리 앨범에서 묶어 보여 준다.
  final String series;

  const CardDef(this.asset, this.name, this.series);
}

const String kSeriesBasic = '기본';
const String kSeriesTravel = '여행';
const String kSeriesGolf = '골프';

/// 카드 목록. 순서가 곧 획득 순서다.
/// 10단계마다 한 장씩 주므로 31장이면 310단계까지 수집이 이어진다.
const List<CardDef> kCards = [
  // 기본 8종 — 1~80단계
  CardDef('assets/gamja/wave.png', '인사 감자', kSeriesBasic),
  CardDef('assets/gamja/carrot_eat.png', '당근 감자', kSeriesBasic),
  CardDef('assets/gamja/peek.png', '빼꼼 감자', kSeriesBasic),
  CardDef('assets/gamja/carrot.png', '감자의 당근', kSeriesBasic),
  CardDef('assets/gamja/paws.png', '발도장', kSeriesBasic),
  CardDef('assets/gamja/bowl.png', '밥그릇', kSeriesBasic),
  CardDef('assets/gamja/sleep.png', '쿨쿨 감자', kSeriesBasic),
  CardDef('assets/gamja/hero.png', '멋쟁이 감자', kSeriesBasic),

  // 여행 18종 — 81~260단계
  CardDef('assets/gamja/street_food.png', '포장마차 감자', kSeriesTravel),
  CardDef('assets/gamja/hiking.png', '등산 감자', kSeriesTravel),
  CardDef('assets/gamja/photo.png', '사진 찍는 감자', kSeriesTravel),
  CardDef('assets/gamja/map.png', '지도 보는 감자', kSeriesTravel),
  CardDef('assets/gamja/pottery.png', '도자기 감자', kSeriesTravel),
  CardDef('assets/gamja/bus.png', '버스 탄 감자', kSeriesTravel),
  CardDef('assets/gamja/suitcase.png', '여행 가는 감자', kSeriesTravel),
  CardDef('assets/gamja/selfie.png', '셀카 감자', kSeriesTravel),
  CardDef('assets/gamja/shopping.png', '쇼핑 감자', kSeriesTravel),
  CardDef('assets/gamja/resting.png', '게임하는 감자', kSeriesTravel),
  CardDef('assets/gamja/museum.png', '박물관 감자', kSeriesTravel),
  CardDef('assets/gamja/flight.png', '비행기 감자', kSeriesTravel),
  CardDef('assets/gamja/local_food.png', '현지 음식 감자', kSeriesTravel),
  CardDef('assets/gamja/packing.png', '짐 싸는 감자', kSeriesTravel),
  CardDef('assets/gamja/night_view.png', '야경 감자', kSeriesTravel),
  CardDef('assets/gamja/hanbok.png', '한복 감자', kSeriesTravel),
  CardDef('assets/gamja/snorkel.png', '물놀이 감자', kSeriesTravel),
  CardDef('assets/gamja/statue.png', '유적 감자', kSeriesTravel),

  // 골프 5종 — 261~310단계
  CardDef('assets/gamja/golf_caddie.png', '캐디 감자', kSeriesGolf),
  CardDef('assets/gamja/golf_team.png', '한판 승부 감자', kSeriesGolf),
  CardDef('assets/gamja/golf_score.png', '점수표 감자', kSeriesGolf),
  CardDef('assets/gamja/golf_penalty.png', '벌타 감자', kSeriesGolf),
  CardDef('assets/gamja/golf_range.png', '연습장 감자', kSeriesGolf),
];

int get kCardCount => kCards.length;

/// 10단계마다 한 장. 전부 모으면 처음부터 다시 순환한다.
int? cardIndexForStage(int stage) =>
    stage % 10 == 0 ? (stage ~/ 10 - 1) % kCards.length : null;

/// 앨범에서 시리즈 순서대로 보여 주기 위한 목록
List<String> get kSeriesOrder =>
    const [kSeriesBasic, kSeriesTravel, kSeriesGolf];
