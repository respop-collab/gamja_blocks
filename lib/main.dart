import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads/ad_manager.dart';
import 'billing/billing.dart';
import 'storage/prefs.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Prefs.init();

  // 둘 다 첫 화면을 막지 않도록 비동기로 띄운다.
  // 광고 초기화 안에서 유럽 동의 절차를 먼저 처리한다.
  AdManager.instance.init();

  // 결제 스트림은 앱 시작 시점부터 듣고 있어야 한다.
  // 결제창을 띄운 채 앱이 죽었다가 살아난 경우의 미완료 거래가 여기서 정리된다.
  Billing.instance.init();

  runApp(const GamjaApp());
}

class GamjaApp extends StatelessWidget {
  const GamjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '감자토끼 블록퍼즐',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}
