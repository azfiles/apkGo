#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${ANDROID_SDK_ROOT:=${ANDROID_HOME:-}}"
: "${ANDROID_SDK_ROOT:?Set ANDROID_SDK_ROOT}"
: "${JAVA_HOME:?Set JAVA_HOME to a JDK 17 installation}"
export ANDROID_SDK_ROOT JAVA_HOME
GODOT="${GODOT:-godot}"
BT="$ANDROID_SDK_ROOT/build-tools/35.0.0"
export XDG_CONFIG_HOME="$PWD/build/godot-config"
mkdir -p "$XDG_CONFIG_HOME/godot" build/godot/output
python3 - <<'PY'
import json, os
from pathlib import Path
settings = '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
settings += 'export/android/android_sdk_path = '+json.dumps(os.environ['ANDROID_SDK_ROOT'])+'\n'
settings += 'export/android/java_sdk_path = '+json.dumps(os.environ['JAVA_HOME'])+'\n'
Path(os.environ['XDG_CONFIG_HOME'],'godot','editor_settings-4.6.tres').write_text(settings)
PY
timeout 120 "$GODOT" --headless --path godot --editor --import > build/godot/export-import-report.txt 2>&1
! grep -E 'SCRIPT ERROR|Parse Error|ERROR:' build/godot/export-import-report.txt
timeout 300 "$GODOT" --headless --path godot --export-release Android ../build/godot/unsigned.apk > build/godot/export-report.txt 2>&1 || { cat build/godot/export-report.txt; exit 1; }
! grep -E 'SCRIPT ERROR|ERROR:' build/godot/export-report.txt
"$BT/zipalign" -P 16 -f 4 build/godot/unsigned.apk build/godot/aligned.apk
# The existing public demo certificate gives repeatable update signatures.
base64 --decode signing/demo-signing.p12.base64 > build/godot/demo-signing.p12
APK=build/godot/output/Schulte-Flow-Godot-2.0.0.apk
"$BT/apksigner" sign --ks build/godot/demo-signing.p12 --ks-pass pass:schulte-demo-public --ks-key-alias schulte-demo --out "$APK" build/godot/aligned.apk
bash scripts/godot/verify-apk.sh "$APK" | tee build/godot/apk-report.txt
(cd build/godot/output && sha256sum Schulte-Flow-Godot-2.0.0.apk > SHA256SUMS.txt)
