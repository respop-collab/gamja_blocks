"""flutter create 로 생성된 플랫폼 파일에 출시용 설정을 주입한다.

Android
  - AndroidManifest.xml : AdMob APPLICATION_ID, 앱 이름, 인터넷 권한
  - build.gradle(.kts)  : minSdk / targetSdk / compileSdk 고정

iOS
  - Info.plist          : GADApplicationIdentifier, 앱 이름,
                          SKAdNetworkItems, 암호화 면제 선언
  - PrivacyInfo.xcprivacy : 애플 개인정보 매니페스트 (2024년 5월부터 필수)

앱 ID 값은 lib/ads/ad_config.dart 에서 읽는다 (단일 진실 원천).

한글 경로를 셸에 넘기지 않고 파이썬 안에서만 다루므로 인코딩 사고가 나지 않는다.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP_NAME = "감자토끼 블록퍼즐"

# 광고 SDK 요구 사항. google_mobile_ads 5.x 기준.
MIN_SDK = 23
TARGET_SDK = 35   # 2025년 8월 이후 구글 플레이 신규 업로드 요건
COMPILE_SDK = 35


def read_app_ids() -> tuple[str, str]:
    src = (ROOT / "lib" / "ads" / "ad_config.dart").read_text(encoding="utf-8")
    android = re.search(r"androidAppId\s*=\s*'([^']+)'", src).group(1)
    ios = re.search(r"iosAppId\s*=\s*'([^']+)'", src).group(1)
    return android, ios


# --------------------------------------------------------------------------
# Android
# --------------------------------------------------------------------------

def patch_android(app_id: str) -> None:
    manifest = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest.exists():
        print("skip android (no manifest)")
        return

    xml = manifest.read_text(encoding="utf-8")
    if "com.google.android.gms.ads.APPLICATION_ID" not in xml:
        meta = (
            '        <meta-data\n'
            '            android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
            f'            android:value="{app_id}"/>\n'
        )
        xml = xml.replace("</application>", meta + "    </application>")
    xml = re.sub(r'android:label="[^"]*"', f'android:label="{APP_NAME}"', xml, count=1)
    if "android.permission.INTERNET" not in xml:
        xml = xml.replace(
            "<application",
            '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',
            1,
        )
    manifest.write_text(xml, encoding="utf-8")
    print("patched", manifest)

    for name in ("build.gradle.kts", "build.gradle"):
        gradle = ROOT / "android" / "app" / name
        if not gradle.exists():
            continue
        g = gradle.read_text(encoding="utf-8")
        before = g
        # Kotlin DSL 과 Groovy DSL 양쪽 표기를 모두 처리한다.
        g = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", f"minSdk = {MIN_SDK}", g)
        g = re.sub(r"minSdkVersion\s+flutter\.minSdkVersion", f"minSdkVersion {MIN_SDK}", g)
        g = re.sub(r"targetSdk\s*=\s*flutter\.targetSdkVersion", f"targetSdk = {TARGET_SDK}", g)
        g = re.sub(r"targetSdkVersion\s+flutter\.targetSdkVersion", f"targetSdkVersion {TARGET_SDK}", g)
        g = re.sub(r"compileSdk\s*=\s*flutter\.compileSdkVersion", f"compileSdk = {COMPILE_SDK}", g)
        g = re.sub(r"compileSdkVersion\s+flutter\.compileSdkVersion", f"compileSdkVersion {COMPILE_SDK}", g)
        if g != before:
            gradle.write_text(g, encoding="utf-8")
            print("patched", gradle)
        break


# --------------------------------------------------------------------------
# iOS
# --------------------------------------------------------------------------

def skadnetwork_ids() -> list[str]:
    """SKAdNetwork 식별자 목록.

    구글이 공식 문서에 게시하는 목록을 tools/skadnetwork_ids.txt 에 한 줄에 하나씩
    붙여 넣으면 그대로 주입된다. 파일이 없으면 구글 자체 식별자 하나만 넣는다.

    식별자를 추측해서 넣으면 안 된다. 틀린 값이 들어가면 광고 성과 측정이
    조용히 어긋나고 원인을 찾기 어렵다. 목록은 반드시 구글 문서에서 복사한다.
    """
    base = ["cstr6suwn9.skadnetwork"]  # Google AdMob
    extra = ROOT / "tools" / "skadnetwork_ids.txt"
    if extra.exists():
        for line in extra.read_text(encoding="utf-8").splitlines():
            v = line.strip().lower()
            if v and not v.startswith("#") and v.endswith(".skadnetwork"):
                if v not in base:
                    base.append(v)
    return base


def patch_ios(app_id: str) -> None:
    plist = ROOT / "ios" / "Runner" / "Info.plist"
    if not plist.exists():
        print("skip ios (no plist)")
        return

    p = plist.read_text(encoding="utf-8")

    if "GADApplicationIdentifier" not in p:
        items = "".join(
            "\t\t<dict>\n"
            "\t\t\t<key>SKAdNetworkIdentifier</key>\n"
            f"\t\t\t<string>{i}</string>\n"
            "\t\t</dict>\n"
            for i in skadnetwork_ids()
        )
        extra = (
            "\t<key>GADApplicationIdentifier</key>\n"
            f"\t<string>{app_id}</string>\n"
            "\t<key>SKAdNetworkItems</key>\n"
            "\t<array>\n" + items + "\t</array>\n"
        )
        p = p.replace("</dict>\n</plist>", extra + "</dict>\n</plist>")

    # 표준 암호화만 쓰므로 수출 규정 면제. 없으면 업로드마다 질문을 받는다.
    if "ITSAppUsesNonExemptEncryption" not in p:
        p = p.replace(
            "</dict>\n</plist>",
            "\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>\n</dict>\n</plist>",
        )

    # 추적 권한(ATT)은 요청하지 않는다.
    # 아동 대상 신호를 켜고 비맞춤형 광고만 쓰므로 요청할 근거가 없고,
    # 근거 없이 요청하면 오히려 애플 심사에서 문제가 된다.
    # 따라서 NSUserTrackingUsageDescription 을 일부러 넣지 않는다.

    p = re.sub(
        r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)",
        rf"\g<1>{APP_NAME}\g<2>",
        p,
    )
    plist.write_text(p, encoding="utf-8")
    print("patched", plist)

    write_privacy_manifest()


PRIVACY_MANIFEST = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>NSPrivacyTracking</key>
\t<false/>
\t<key>NSPrivacyTrackingDomains</key>
\t<array/>
\t<key>NSPrivacyCollectedDataTypes</key>
\t<array/>
\t<key>NSPrivacyAccessedAPITypes</key>
\t<array>
\t\t<dict>
\t\t\t<key>NSPrivacyAccessedAPIType</key>
\t\t\t<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
\t\t\t<key>NSPrivacyAccessedAPITypeReasons</key>
\t\t\t<array>
\t\t\t\t<string>CA92.1</string>
\t\t\t</array>
\t\t</dict>
\t</array>
</dict>
</plist>
"""


def write_privacy_manifest() -> None:
    """앱 자체의 개인정보 매니페스트.

    수집 항목은 비어 있다. 이 앱은 개발자가 수집하는 데이터가 없다.
    광고·결제 SDK 는 각자의 매니페스트를 포함해 배포되므로 여기에 적지 않는다.
    UserDefaults 접근 사유 CA92.1 은 "앱 자신의 설정 저장" 이다.
    """
    target = ROOT / "ios" / "Runner" / "PrivacyInfo.xcprivacy"
    target.write_text(PRIVACY_MANIFEST, encoding="utf-8")
    print("wrote", target)

    pbx = ROOT / "ios" / "Runner.xcodeproj" / "project.pbxproj"
    if not pbx.exists():
        return
    txt = pbx.read_text(encoding="utf-8")
    if "PrivacyInfo.xcprivacy" in txt:
        print("privacy manifest already registered")
        return

    # Info.plist 가 등록된 자리를 찾아 그 옆에 같은 방식으로 끼워 넣는다.
    m = re.search(
        r"([0-9A-F]{24}) /\* Info\.plist \*/ = \{isa = PBXFileReference;([^}]*)\};",
        txt,
    )
    if not m:
        print("경고: project.pbxproj 에 자동 등록하지 못했다. "
              "Xcode 에서 Runner 타깃에 PrivacyInfo.xcprivacy 를 직접 추가할 것.")
        return

    new_ref = "AA00000000000000000001"
    new_build = "AA00000000000000000002"
    file_ref = (
        f"\t\t{new_ref} /* PrivacyInfo.xcprivacy */ = {{isa = PBXFileReference; "
        "lastKnownFileType = text.xml; path = PrivacyInfo.xcprivacy; "
        "sourceTree = \"<group>\"; };\n"
    )
    txt = txt.replace(m.group(0), m.group(0) + "\n" + file_ref.rstrip("\n"), 1)

    build_file = (
        f"\t\t{new_build} /* PrivacyInfo.xcprivacy in Resources */ = "
        f"{{isa = PBXBuildFile; fileRef = {new_ref} /* PrivacyInfo.xcprivacy */; }};\n"
    )
    bm = re.search(r"/\* Begin PBXBuildFile section \*/\n", txt)
    if bm:
        txt = txt[: bm.end()] + build_file + txt[bm.end():]

    rm = re.search(r"(isa = PBXResourcesBuildPhase;.*?files = \(\n)", txt, re.S)
    if rm:
        txt = txt[: rm.end()] + f"\t\t\t\t{new_build} /* PrivacyInfo.xcprivacy in Resources */,\n" + txt[rm.end():]

    pbx.write_text(txt, encoding="utf-8")
    print("registered privacy manifest in xcode project")


if __name__ == "__main__":
    android_id, ios_id = read_app_ids()
    patch_android(android_id)
    patch_ios(ios_id)
    print("done")
    sys.exit(0)
