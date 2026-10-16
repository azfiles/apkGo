#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-godot}"
: "${ANDROID_SDK_ROOT:=${ANDROID_HOME:-}}"
: "${ANDROID_SDK_ROOT:?Set ANDROID_SDK_ROOT}"
: "${JAVA_HOME:?Set JAVA_HOME to JDK 17}"
export ANDROID_SDK_ROOT JAVA_HOME
export XDG_CONFIG_HOME="$PWD/build/maze/config"
mkdir -p "$XDG_CONFIG_HOME/godot" build/maze/output
python3 - <<'PY'
import json, os
from pathlib import Path
settings = '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
settings += 'export/android/android_sdk_path = ' + json.dumps(os.environ['ANDROID_SDK_ROOT']) + '\n'
settings += 'export/android/java_sdk_path = ' + json.dumps(os.environ['JAVA_HOME']) + '\n'
Path(os.environ['XDG_CONFIG_HOME'], 'godot', 'editor_settings-4.6.tres').write_text(settings)
PY
timeout 120 "$GODOT" --headless --path maze-godot --editor --import > build/maze/export-import-report.txt 2>&1
if rg -n 'SCRIPT ERROR|ERROR:' build/maze/export-import-report.txt; then exit 1; fi
for platform in Android Linux; do
  timeout 300 "$GODOT" --headless --path maze-godot --export-release "$platform" > "build/maze/export-${platform}-report.txt" 2>&1 || { cat "build/maze/export-${platform}-report.txt"; exit 1; }
  if rg -n 'SCRIPT ERROR|ERROR:' "build/maze/export-${platform}-report.txt"; then exit 1; fi
done
BT="$ANDROID_SDK_ROOT/build-tools/35.0.0"
"$BT/zipalign" -P 16 -f 4 build/maze/unsigned.apk build/maze/aligned.apk
base64 --decode signing/demo-signing.p12.base64 > build/maze/demo-signing.p12
APK=build/maze/output/Pipi-Maze-Garden-0.1.0.apk
"$BT/apksigner" sign --ks build/maze/demo-signing.p12 --ks-pass pass:schulte-demo-public --ks-key-alias schulte-demo --out "$APK" build/maze/aligned.apk
"$BT/apksigner" verify --verbose "$APK" > build/maze/apk-report.txt
"$BT/zipalign" -c -P 16 -v 4 "$APK" >> build/maze/apk-report.txt
"$BT/aapt2" dump badging "$APK" >> build/maze/apk-report.txt
"$BT/aapt2" dump permissions "$APK" >> build/maze/apk-report.txt
rg -q "package: name='com.alex.pipimaze.garden'" build/maze/apk-report.txt
if rg -n 'android.permission.(INTERNET|RECORD_AUDIO|READ_EXTERNAL_STORAGE)' build/maze/apk-report.txt; then exit 1; fi
chmod +x build/maze/output/Pipi-Maze-Garden.x86_64
(cd build/maze/output && sha256sum Pipi-Maze-Garden-0.1.0.apk Pipi-Maze-Garden.x86_64 > SHA256SUMS.txt)
cat build/maze/output/SHA256SUMS.txt
