"""앱 런처 아이콘 생성.

flutter create 로 android/ios 폴더가 만들어진 뒤에 실행한다.
assets/icon/app_icon.png 한 장으로 안드로이드 mipmap 과 iOS AppIcon 을 모두 채운다.

한글 경로를 셸에 직접 넣지 않고 파이썬에서만 다루므로 인코딩 사고가 나지 않는다.
Pillow 가 없으면 아무 것도 하지 않고 정상 종료한다. 아이콘은 빌드 필수 요소가 아니다.
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "icon", "app_icon.png")

ANDROID = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def main() -> int:
    try:
        from PIL import Image
    except Exception as exc:  # pragma: no cover
        print("Pillow 없음, 아이콘 생성 건너뜀:", exc)
        return 0

    if not os.path.isfile(SRC):
        print("아이콘 원본 없음:", SRC)
        return 0

    base = Image.open(SRC).convert("RGB")

    res = os.path.join(ROOT, "android", "app", "src", "main", "res")
    if os.path.isdir(res):
        for folder, size in ANDROID.items():
            d = os.path.join(res, folder)
            os.makedirs(d, exist_ok=True)
            base.resize((size, size), Image.LANCZOS).save(
                os.path.join(d, "ic_launcher.png"), optimize=True
            )
        print("안드로이드 런처 아이콘 생성 완료")

    ios = os.path.join(
        ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset"
    )
    meta = os.path.join(ios, "Contents.json")
    if os.path.isfile(meta):
        with open(meta, encoding="utf-8") as fp:
            data = json.load(fp)
        for item in data.get("images", []):
            name = item.get("filename")
            if not name:
                continue
            try:
                pt = float(item["size"].split("x")[0])
                scale = float(item["scale"].replace("x", ""))
            except (KeyError, ValueError):
                continue
            px = int(round(pt * scale))
            base.resize((px, px), Image.LANCZOS).save(
                os.path.join(ios, name), optimize=True
            )
        print("iOS 앱 아이콘 생성 완료")

    return 0


if __name__ == "__main__":
    sys.exit(main())
