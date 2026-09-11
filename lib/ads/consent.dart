/// 유럽 이용자 동의(UMP, User Messaging Platform).
///
/// 왜 필요한가: 구글은 EEA·영국 이용자에게 광고를 내보내려면 인증된 동의 관리 플랫폼을
/// 거치도록 요구한다. 이걸 붙이지 않으면 해당 지역에서 광고가 나가지 않거나
/// AdMob 계정에 정책 경고가 붙는다. 한국만 대상이어도 스토어는 전 세계에 노출되므로
/// 처음부터 넣어 두는 편이 안전하다.
///
/// 이 앱의 특수성: 아동이 이용하는 앱이므로 동의 요청 자체를
/// "동의 연령 미만" 신호와 함께 보낸다. 이 신호가 켜져 있으면 UMP 는
/// 맞춤형 광고 동의를 묻지 않고 비맞춤형 광고로만 진행한다.
///
/// 실패해도 게임은 그대로 돌아간다. 동의 절차가 게임 진입을 막아서는 안 된다.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentManager {
  ConsentManager._();
  static final ConsentManager instance = ConsentManager._();

  bool _done = false;

  /// 동의 절차를 마쳤는지. 실패로 끝난 경우에도 true 가 된다.
  bool get settled => _done;

  /// 광고 요청이 가능한 상태인지 확인한다.
  /// 동의를 받지 못했더라도 비맞춤형 광고는 대개 가능하므로 차단하지 않는다.
  Future<void> gather() async {
    if (_done) return;
    try {
      final params = ConsentRequestParameters(
        tagForUnderAgeOfConsent: true,
      );
      final completer = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          try {
            if (await ConsentInformation.instance.isConsentFormAvailable()) {
              await _loadAndShow();
            }
          } catch (e) {
            debugPrint('Consent form failed: $e');
          }
          if (!completer.isCompleted) completer.complete();
        },
        (err) {
          debugPrint('Consent update failed: ${err.message}');
          if (!completer.isCompleted) completer.complete();
        },
      );
      await completer.future.timeout(const Duration(seconds: 8),
          onTimeout: () => debugPrint('Consent timed out'));
    } catch (e) {
      debugPrint('Consent gather failed: $e');
    }
    _done = true;
  }

  Future<void> _loadAndShow() async {
    final completer = Completer<void>();
    ConsentForm.loadConsentForm(
      (form) async {
        final status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          form.show((err) {
            if (err != null) debugPrint('Consent show failed: ${err.message}');
            if (!completer.isCompleted) completer.complete();
          });
        } else {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (err) {
        debugPrint('Consent load failed: ${err.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future;
  }

  /// 보호자 화면에서 동의 설정을 다시 열 수 있게 한다.
  /// EEA 이용자는 동의를 철회할 수 있어야 하므로 진입점이 하나는 있어야 한다.
  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((err) {
        if (err != null) debugPrint('Privacy options failed: ${err.message}');
      });
    } catch (e) {
      debugPrint('Privacy options failed: $e');
    }
  }

  /// 개인정보 설정 버튼을 보여 줄지 여부. EEA 밖에서는 보통 false 다.
  Future<bool> get privacyOptionsRequired async {
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      return false;
    }
  }
}
