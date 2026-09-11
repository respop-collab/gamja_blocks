/// 부모 확인 게이트와 보호자 화면.
///
/// 애플 심사 지침 1.3은 키즈 카테고리 앱에서 구매와 외부 링크를
/// 부모 게이트 뒤의 별도 영역에 두도록 요구한다.
/// 다만 5.1.4가 명시하듯 부모 게이트는 개인정보 수집 동의와 다른 것이므로,
/// 이 앱은 애초에 개인정보를 수집하지 않는 쪽으로 설계했다.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/consent.dart';
import '../billing/billing.dart';
import '../storage/prefs.dart';
import 'theme.dart';

/// 개인정보 처리방침 주소.
/// 원문은 docs/privacy.html 에 있고, GitHub Pages 로 그대로 게시된다.
/// 저장소 설정 > Pages > Source 를 main 브랜치의 /docs 로 지정해야 살아난다.
/// 플레이 콘솔의 개인정보 처리방침 항목에도 같은 주소를 넣는다.
const String kPrivacyPolicyUrl =
    'https://respop-collab.github.io/gamja_blocks/privacy.html';

/// 고객지원 페이지. 같은 방식으로 게시된다.
const String kSupportUrl = 'https://respop-collab.github.io/gamja_blocks/';

Future<void> showParentGate(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _GateDialog(),
  );
  if (ok == true && context.mounted) {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => const _AdultSheet(),
    );
  }
}

class _GateDialog extends StatefulWidget {
  const _GateDialog();

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  late int a, b;
  late List<int> options;
  final Set<int> _wrong = {};

  @override
  void initState() {
    super.initState();
    _make();
  }

  void _make() {
    final now = DateTime.now().microsecondsSinceEpoch;
    a = 6 + now % 7;
    b = 6 + (now ~/ 7) % 7;
    final answer = a * b;
    final set = <int>{answer};
    var k = 1;
    while (set.length < 3) {
      final v = answer + ((k.isEven ? 1 : -1) * (2 + k * 3));
      if (v > 0) set.add(v);
      k++;
    }
    options = set.toList()..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final answer = a * b;
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
            const Text('어른 확인',
                style: TextStyle(fontFamily: 'Jua', fontSize: 25, color: kInk)),
            const SizedBox(height: 6),
            const Text('아래 계산의 답을 골라 주세요',
                style: TextStyle(fontSize: 14, color: kInkSoft)),
            const SizedBox(height: 16),
            Text('$a × $b = ?',
                style: const TextStyle(fontFamily: 'Jua', fontSize: 30, color: kInk)),
            const SizedBox(height: 18),
            Row(
              children: [
                for (final v in options) ...[
                  Expanded(
                    child: Opacity(
                      opacity: _wrong.contains(v) ? 0.35 : 1,
                      child: GbButton(
                        label: '$v',
                        width: double.infinity,
                        onPressed: _wrong.contains(v)
                            ? null
                            : () {
                                if (v == answer) {
                                  Navigator.pop(context, true);
                                } else {
                                  setState(() => _wrong.add(v));
                                }
                              },
                      ),
                    ),
                  ),
                  if (v != options.last) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('닫기',
                  style: TextStyle(fontFamily: 'Jua', fontSize: 16, color: kInkSoft)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdultSheet extends StatefulWidget {
  const _AdultSheet();

  @override
  State<_AdultSheet> createState() => _AdultSheetState();
}

class _AdultSheetState extends State<_AdultSheet> {
  StreamSubscription<PurchaseOutcome>? _sub;
  bool _busy = false;
  bool _privacyOptions = false;

  @override
  void initState() {
    super.initState();
    _sub = Billing.instance.outcomes.listen(_onOutcome);
    ConsentManager.instance.privacyOptionsRequired.then((v) {
      if (mounted) setState(() => _privacyOptions = v);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onOutcome(PurchaseOutcome o) {
    if (!mounted) return;
    setState(() => _busy = o == PurchaseOutcome.pending);
    final msg = switch (o) {
      PurchaseOutcome.success => '광고를 껐습니다. 고맙습니다.',
      PurchaseOutcome.restored => '이전 구매를 복원했습니다.',
      PurchaseOutcome.pending => '결제를 확인하는 중입니다.',
      PurchaseOutcome.canceled => '결제를 취소했습니다.',
      PurchaseOutcome.unavailable => '지금은 스토어에 연결할 수 없습니다.',
      PurchaseOutcome.error => '결제에 실패했습니다. 잠시 후 다시 시도해 주세요.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('보호자 화면',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Jua', fontSize: 24, color: kInk)),
            const SizedBox(height: 18),

            SwitchListTile(
              title: const Text('소리', style: TextStyle(fontFamily: 'Jua', fontSize: 17)),
              value: Prefs.sound,
              onChanged: (v) async {
                await Prefs.setSound(v);
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('진동', style: TextStyle(fontFamily: 'Jua', fontSize: 17)),
              value: Prefs.vibration,
              onChanged: (v) async {
                await Prefs.setVibration(v);
                setState(() {});
              },
            ),
            const SizedBox(height: 10),

            // 결제는 보호자만 접근하는 이 영역에만 둔다.
            // 확률형 아이템과 아동 대상 결제 유도는 넣지 않는다.
            // 가격은 스토어가 내려 주는 지역 통화 값을 그대로 쓴다.
            GbButton(
              label: _buyLabel(),
              primary: !Prefs.adsRemoved && !_busy,
              width: double.infinity,
              onPressed: (Prefs.adsRemoved || _busy) ? null : _buyRemoveAds,
            ),
            const SizedBox(height: 8),

            // 비소모성 상품이므로 복원 경로가 반드시 있어야 한다 (애플 3.1.1).
            GbButton(
              label: '구매 복원',
              width: double.infinity,
              onPressed: _busy ? null : () => Billing.instance.restore(),
            ),
            const SizedBox(height: 8),

            GbButton(
              label: '개인정보 처리방침',
              width: double.infinity,
              onPressed: () => launchUrl(Uri.parse(kPrivacyPolicyUrl),
                  mode: LaunchMode.externalApplication),
            ),
            const SizedBox(height: 8),
            GbButton(
              label: '문의와 도움말',
              width: double.infinity,
              onPressed: () => launchUrl(Uri.parse(kSupportUrl),
                  mode: LaunchMode.externalApplication),
            ),

            // 유럽 이용자는 광고 동의를 언제든 바꿀 수 있어야 한다.
            // 해당 지역이 아니면 이 버튼은 나타나지 않는다.
            if (_privacyOptions) ...[
              const SizedBox(height: 8),
              GbButton(
                label: '광고 동의 설정',
                width: double.infinity,
                onPressed: () => ConsentManager.instance.showPrivacyOptions(),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              '이 앱은 개인정보를 수집하지 않고 서버를 쓰지 않습니다. '
              '카메라와 사진 기능이 없으며, 기록은 이 기기에만 저장됩니다.',
              style: TextStyle(fontSize: 12, color: kInkSoft, height: 1.6),
            ),
            const SizedBox(height: 14),
            GbButton(label: '나가기', onPressed: () => Navigator.pop(context), width: double.infinity),
          ],
        ),
      ),
    );
  }

  String _buyLabel() {
    if (Prefs.adsRemoved) return '광고가 꺼져 있어요';
    if (_busy) return '결제 확인 중...';
    final price = Billing.instance.priceLabel;
    if (!Billing.instance.available || price == null) return '광고 없애기';
    return '광고 없애기 · $price';
  }

  Future<void> _buyRemoveAds() async {
    setState(() => _busy = true);
    await Billing.instance.buyRemoveAds();
    if (mounted) setState(() => _busy = false);
  }
}
