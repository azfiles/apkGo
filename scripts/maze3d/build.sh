#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-godot}"
: "${ANDROID_SDK_ROOT:=${ANDROID_HOME:-}}"
: "${ANDROID_SDK_ROOT:?Set ANDROID_SDK_ROOT}"
: "${JAVA_HOME:?Set JAVA_HOME to JDK 17}"
export ANDROID_SDK_ROOT JAVA_HOME
export XDG_CONFIG_HOME="$PWD/build/maze3d/config"
mkdir -p "$XDG_CONFIG_HOME/godot" build/maze3d/output
python3 - <<'PY'
import json, os
from pathlib import Path
settings = '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
settings += 'export/android/android_sdk_path = ' + json.dumps(os.environ['ANDROID_SDK_ROOT']) + '\n'
settings += 'export/android/java_sdk_path = ' + json.dumps(os.environ['JAVA_HOME']) + '\n'
Path(os.environ['XDG_CONFIG_HOME'], 'godot', 'editor_settings-4.6.tres').write_text(settings)
PY
timeout 120 "$GODOT" --headless --path maze3d --editor --import > build/maze3d/export-import-report.txt 2>&1
if grep -nE 'SCRIPT ERROR|ERROR:' build/maze3d/export-import-report.txt; then exit 1; fi
for platform in Android Linux; do
  timeout 300 "$GODOT" --headless --path maze3d --export-release "$platform" > "build/maze3d/export-${platform}-report.txt" 2>&1 || { cat "build/maze3d/export-${platform}-report.txt"; exit 1; }
  if grep -nE 'SCRIPT ERROR|ERROR:' "build/maze3d/export-${platform}-report.txt"; then exit 1; fi
done
BT="$ANDROID_SDK_ROOT/build-tools/35.0.0"
"$BT/zipalign" -P 16 -f 4 build/maze3d/unsigned.apk build/maze3d/aligned.apk
base64 --decode signing/demo-signing.p12.base64 > build/maze3d/demo-signing.p12
APK=build/maze3d/output/Pipi-Maze-Ruins-0.3.0.apk
"$BT/apksigner" sign --ks build/maze3d/demo-signing.p12 --ks-pass pass:schulte-demo-public --ks-key-alias schulte-demo --out "$APK" build/maze3d/aligned.apk
"$BT/apksigner" verify --verbose "$APK" > build/maze3d/apk-report.txt
"$BT/zipalign" -c -P 16 -v 4 "$APK" >> build/maze3d/apk-report.txt
"$BT/aapt2" dump badging "$APK" >> build/maze3d/apk-report.txt
"$BT/aapt2" dump permissions "$APK" >> build/maze3d/apk-report.txt
grep -q "package: name='com.alex.pipimaze.ruins'" build/maze3d/apk-report.txt
if grep -nE 'android.permission.(INTERNET|RECORD_AUDIO|READ_EXTERNAL_STORAGE)' build/maze3d/apk-report.txt; then exit 1; fi
chmod +x build/maze3d/output/Pipi-Maze-Ruins.x86_64
(cd build/maze3d/output && sha256sum Pipi-Maze-Ruins-0.3.0.apk Pipi-Maze-Ruins.x86_64 > SHA256SUMS.txt)
cat build/maze3d/output/SHA256SUMS.txt
