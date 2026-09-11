"""android/key.properties 가 있을 때 릴리스 서명 설정을 build.gradle(.kts)에 주입한다.
flutter create 가 만든 기본 gradle 파일(디버그 키로 릴리스 서명)을 업로드 키 서명으로 바꾼다.
"""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "android" / "app"


def patch_kts(path: Path) -> None:
    g = path.read_text(encoding="utf-8")
    if "keystoreProperties" in g:
        return
    header = (
        "import java.util.Properties\n"
        "import java.io.FileInputStream\n\n"
        "val keystoreProperties = Properties()\n"
        "val keystorePropertiesFile = rootProject.file(\"key.properties\")\n"
        "if (keystorePropertiesFile.exists()) {\n"
        "    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n"
        "}\n\n"
    )
    g = header + g
    signing = (
        "    signingConfigs {\n"
        "        create(\"release\") {\n"
        "            keyAlias = keystoreProperties[\"keyAlias\"] as String\n"
        "            keyPassword = keystoreProperties[\"keyPassword\"] as String\n"
        "            storeFile = file(keystoreProperties[\"storeFile\"] as String)\n"
        "            storePassword = keystoreProperties[\"storePassword\"] as String\n"
        "        }\n"
        "    }\n\n"
        "    buildTypes {\n"
    )
    g = g.replace("    buildTypes {\n", signing, 1)
    g = g.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("release")')
    path.write_text(g, encoding="utf-8")
    print("patched", path)


def patch_groovy(path: Path) -> None:
    g = path.read_text(encoding="utf-8")
    if "keystoreProperties" in g:
        return
    header = (
        "def keystoreProperties = new Properties()\n"
        "def keystorePropertiesFile = rootProject.file('key.properties')\n"
        "if (keystorePropertiesFile.exists()) {\n"
        "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
        "}\n\n"
    )
    g = g.replace("android {\n", header + "android {\n", 1)
    signing = (
        "    signingConfigs {\n"
        "        release {\n"
        "            keyAlias keystoreProperties['keyAlias']\n"
        "            keyPassword keystoreProperties['keyPassword']\n"
        "            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null\n"
        "            storePassword keystoreProperties['storePassword']\n"
        "        }\n"
        "    }\n\n"
        "    buildTypes {\n"
    )
    g = g.replace("    buildTypes {\n", signing, 1)
    g = g.replace("signingConfig signingConfigs.debug", "signingConfig signingConfigs.release")
    path.write_text(g, encoding="utf-8")
    print("patched", path)


if __name__ == "__main__":
    kts = APP / "build.gradle.kts"
    groovy = APP / "build.gradle"
    if kts.exists():
        patch_kts(kts)
    elif groovy.exists():
        patch_groovy(groovy)
    else:
        raise SystemExit("gradle file not found")
