"""한글 폰트를 내려받아 assets/fonts 에 넣고 pubspec.yaml 에 선언을 추가한다.

Jua      — 둥근 제목용 한글 폰트
Gothic A1 — 본문용 한글 폰트

폰트를 못 받아도 스크립트는 실패하지 않는다. 그 경우 pubspec 을 건드리지 않고
앱은 시스템 한글 폰트로 대체되어 정상 동작한다.
"""
from __future__ import annotations

import ssl
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FONT_DIR = ROOT / "assets" / "fonts"
BASE = "https://raw.githubusercontent.com/google/fonts/main/ofl"

FONTS = {
    "Jua-Regular.ttf": f"{BASE}/jua/Jua-Regular.ttf",
    "GothicA1-Medium.ttf": f"{BASE}/gothica1/GothicA1-Medium.ttf",
    "GothicA1-Bold.ttf": f"{BASE}/gothica1/GothicA1-Bold.ttf",
}

DECLARATION = """
  fonts:
    - family: Jua
      fonts:
        - asset: assets/fonts/Jua-Regular.ttf
    - family: GothicA1
      fonts:
        - asset: assets/fonts/GothicA1-Medium.ttf
          weight: 500
        - asset: assets/fonts/GothicA1-Bold.ttf
          weight: 700
"""


def download() -> bool:
    FONT_DIR.mkdir(parents=True, exist_ok=True)
    ctx = ssl.create_default_context()
    ok = True
    for name, url in FONTS.items():
        target = FONT_DIR / name
        if target.exists() and target.stat().st_size > 1000:
            print(f"skip {name} (already present)")
            continue
        try:
            with urllib.request.urlopen(url, timeout=60, context=ctx) as r:
                data = r.read()
            if len(data) < 1000:
                raise ValueError("too small")
            target.write_bytes(data)
            print(f"got  {name} ({len(data)} bytes)")
        except Exception as e:  # noqa: BLE001
            print(f"FAIL {name}: {e}")
            ok = False
    return ok


def patch_pubspec() -> None:
    p = ROOT / "pubspec.yaml"
    s = p.read_text(encoding="utf-8")
    if "family: Jua" in s:
        print("pubspec already declares fonts")
        return
    marker = "    - assets/gamja/\n"
    if marker not in s:
        print("pubspec marker not found, skipping")
        return
    s = s.replace(marker, marker + DECLARATION, 1)
    p.write_text(s, encoding="utf-8")
    print("patched pubspec.yaml")


if __name__ == "__main__":
    if download():
        patch_pubspec()
    else:
        print("폰트를 모두 받지 못해 pubspec 은 그대로 둡니다. "
              "앱은 시스템 한글 폰트로 동작합니다.")
    sys.exit(0)  # 폰트 실패로 빌드를 멈추지 않는다
