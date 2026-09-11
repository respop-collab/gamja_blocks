# 감자토끼 블록퍼즐 (gamja_blocks)

서버 없는 무한 단계 블록 퍼즐. 무료 + AdMob 광고, 카메라·개인정보 수집 없음.

## 난이도 구조

| 구간 | 단계 | 보드 | 최대 도형 | 작은 도형 | 목표 줄 | 수 제한 | 돌 | 도움 | 실패 |
|---|---|---|---|---|---|---|---|---|---|
| 초등 | 1~10 | 6×6 | 4칸 | 55% | 3~8 | 없음 | 0 | 무제한 | **없음** |
| 중학 | 11~50 | 7×7 | 5칸 | 50→38% | 8~18 | 없음 | 0 | 3회 | 있음 |
| 고등 | 51~100 | 8×8 | 6칸 | 38→30% | 18~25 | 없음 | 0~2 | 1회 | 있음 |
| 성인 | 101~1000 | 8×8 | 6칸 | 40% | 25 | 61→54 | 2~4 | 없음 | 있음 |
| 무한 | 1001~ | 8×8 | 6칸 | 40% | 25→45 | 2.2×목표×효율 | 3~6 | 없음 | 있음 |

무한 구간은 300단계마다 한 회차다. 회차가 넘어가면 목표가 올라가고 난이도가 잠깐
완화됐다 다시 조여진다(톱니). 목표가 상한 45줄에 걸리는 약 2200단계부터는
톱니를 멈추고 최고 난도로 고정된다. **난이도가 무한히 오르지는 않는다** —
성공률이 0%가 되면 그 뒤 단계는 모두 같아지기 때문이다.

봇 실측 성공률: 1단계 100% → 100단계 57% → 1000단계 10% → 2200단계 이후 약 20% 고정.

### 곡선을 바꾸려면

`lib/game/curve.dart` 의 `paramsFor()` 하나만 고치면 된다. 이 파일의 숫자는
봇 시뮬레이션 약 4만 판으로 실측해 정한 값이며, 근거는 파일 상단 주석에 있다.

특히 다음 세 가지는 실측으로 확인된 제약이므로 함부로 바꾸면 안 된다.

- **8×8에서 6칸 초과 도형은 생존을 무너뜨린다.** 3×3 정사각형을 넣으면 중앙값이 절반이 된다.
- **보드를 키우면 오히려 쉬워진다.** 배치 여유가 늘어나는 효과가 더 크다.
- **수 제한의 바닥은 약 50.** 그 아래는 성공률이 0%가 된다.

## 구조

```
lib/
  main.dart                진입 (세로 고정, Prefs 초기화, 광고 비동기 초기화)
  game/curve.dart          난이도 곡선 — 단계 하나로 파라미터 전부 계산
  game/cards.dart          감자 카드 31종 정의 (기본 8 + 여행 18 + 골프 5)
  game/piece.dart          도형 24종 (모두 6칸 이하)
  game/engine.dart         순수 게임 로직 (배치·소거·목표·수 제한·도움·저장복원)
  ads/ad_config.dart       광고 ID와 구간별 노출 정책 (출시 전 이 파일만 수정)
  ads/ad_manager.dart      배너·전면·리워드 관리
  ads/consent.dart         유럽 이용자 광고 동의 (UMP)
  billing/billing.dart     앱 내 결제 — 광고 제거 1종, 구매 복원 포함
  storage/prefs.dart       로컬 저장 (단계, 카드, 진행 중인 판, 설정)
  ui/theme.dart            팔레트·버튼·감자 에셋 경로
  ui/widgets.dart          블록, 도형, 배너, 말풍선
  ui/home_screen.dart      홈
  ui/game_screen.dart      게임 화면 (드래그, 흡착, 클리어·실패 처리)
  ui/album_screen.dart     감자 카드 앨범
  ui/parent_gate.dart      부모 확인 게이트 + 보호자 화면(결제·설정)
test/
  curve_test.dart          구간 경계 연속성, 단조성, 무한 구간 포화, 안전 범위
  engine_test.dart         배치·소거·실패·도움·광고 보상·저장복원
  cards_test.dart          카드 정합성, 획득 주기, 수집 지속 구간
  release_test.dart        출시 점검 — 자리표시자·스텁·정책 설정 누락 검출
tools/
  fetch_fonts.py           한글 폰트 내려받기 + pubspec 선언 추가
  patch_platform.py        AdMob 앱 ID·앱 이름·minSdk 주입
  enable_signing.py        릴리스 서명 설정 주입
  make_icons.py            앱 런처 아이콘 생성 (안드로이드 mipmap + iOS AppIcon)
  skadnetwork_ids.txt      iOS 광고 측정 식별자 목록 (구글 문서에서 붙여 넣는다)
docs/
  index.html               고객지원 페이지 (앱 스토어 필수 항목)
  privacy.html             개인정보 처리방침 (양대 스토어 필수 항목)
.github/workflows/build.yml  안드로이드(테스트→APK→AAB) + iOS(컴파일 검증)
```

## 감자 카드

10단계마다 한 장씩 준다. 31종이므로 **310단계까지 새 카드가 계속 나온다.**
그 뒤에는 처음부터 순환하며 장수만 쌓인다.

| 시리즈 | 장수 | 획득 구간 |
|---|---|---|
| 기본 감자 | 8 | 1~80단계 |
| 여행 감자 | 18 | 81~260단계 |
| 골프 감자 | 5 | 261~310단계 |

카드를 늘리려면 `lib/game/cards.dart` 에 항목을 추가하고 이미지를
`assets/gamja/` 에 넣으면 된다.
스토어 제출용 아이콘과 그래픽은 `assets/icon/` 에 있다(앱에 번들하지 않는다). 저장된 수집 기록은 길이가 달라져도
앞에서부터 맞춰 읽으므로 깨지지 않는다.

## 빌드 (PC에 Android Studio 없이)

1. GitHub 비공개 저장소 생성 후 이 폴더 전체를 main 브랜치에 push
2. Actions 탭 → build 완료 후 Artifacts 에서 내려받기
   - `gamja-debug-apk` : 폰에 직접 설치해 테스트
   - `gamja-release-aab` : Play Console 업로드용 (서명 Secrets 등록 후)

플랫폼 폴더(android/)는 저장소에 넣지 않고 CI에서 `flutter create` 로 만든다.

## 로컬 개발 (선택)

```
flutter create --platforms=android --org com.seiho --project-name gamja_blocks .
rm -f test/widget_test.dart
python3 tools/fetch_fonts.py
python3 tools/patch_platform.py
flutter pub get && flutter test && flutter run
```

폰트를 못 받아도 시스템 한글 폰트로 대체되어 정상 동작한다.

## 광고 정책 (구간별)

구간별로 광고 강도를 다르게 두는 것은 수익 최적화가 아니라 **규제 대응**이다.
아동이 실제로 머무는 초등 구간의 광고를 최소화해야 구글플레이 Families 정책과
애플 심사 지침 양쪽에서 위험이 낮아진다.

| 구간 | 배너 | 리워드 | 전면 |
|---|---|---|---|
| 초등 | O | X (실패가 없어 붙일 지점이 없음) | X |
| 중학 | O | O (실패 시 이어하기) | X |
| 고등 이상 | O | O | 실패 3회마다, 최소 120초 간격 |

- 앱 실행 직후 광고는 넣지 않는다 (Families 정책 금지 항목)
- 리워드는 5초 후 닫기가 가능해야 한다 (Families 정책)
- 광고 콘텐츠 등급은 G로 고정

## 출시 전 체크리스트

- [ ] AdMob 앱 등록 → 앱 ID 2개, 광고 단위 ID 6개 발급
- [ ] `lib/ads/ad_config.dart` 에 ID 입력, `useRealIds = true`
- [ ] `lib/ui/parent_gate.dart` 의 `kPrivacyPolicyUrl` 교체
- [ ] 광고 제거 인앱결제 연동 (`in_app_purchase`), `_buyRemoveAds` 구현
- [ ] 업로드 키 생성 후 GitHub Secrets 등록
      (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`)
- [ ] 앱 아이콘 제작 (감자 머리 에셋 활용)
- [ ] 개인정보처리방침 페이지 (GitHub Pages 한 장이면 충분)
- [ ] Play Console 데이터 보안 양식: 광고 ID 수집 = 예
- [ ] Play Console 대상 연령: 전연령(아동 포함) 혼합 대상
- [ ] 게임제작업 등록 여부를 관할 구청에 문의 (수익 발생 시 필요 가능성)

## 알려진 제한

- 드래그 시 도형을 손가락 위로 띄우는 오프셋이 항상 적용된다. 모바일 전용이라
  문제 없으나, 태블릿에 마우스를 연결하면 어색할 수 있다.
- 광고 제거 결제는 아직 자리만 있고 연동되지 않았다.
- 무한 구간은 약 2200단계에서 난이도가 포화한다. 그 이후의 동기는 난이도가 아닌
  기록 경쟁으로 옮기는 것을 권장한다.
