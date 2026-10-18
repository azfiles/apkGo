#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${ANDROID_SDK_ROOT:=${ANDROID_HOME:-}}"
: "${ANDROID_SDK_ROOT:?Set ANDROID_SDK_ROOT}"
source_apk="${1:?Pass the built Unity APK}"
build_tools="$ANDROID_SDK_ROOT/build-tools/35.0.0"
mkdir -p work/unity-build build/unity-release
"$build_tools/aapt" dump badging "$source_apk" > work/unity-build/badging.txt
python3 - <<'PY'
from pathlib import Path
import re
text = Path('work/unity-build/badging.txt').read_text()
package = re.search(r"^package: name='([^']+)' versionCode='(\d+)'", text, re.M)
if not package or package[1] != 'com.alex.pipimaze.unitypreview' or int(package[2]) < 100001:
    raise SystemExit('Expected the independent Pipi Maze Unity preview package/version.')
for abi in ('arm64-v8a', 'x86_64'):
    if not re.search(r"^native-code:.*'" + abi + "'", text, re.M):
        raise SystemExit('Missing runtime ABI: ' + abi)
print('PASS: Unity package, preview version, ARM64 device and x86_64 emulator runtimes')
PY
base64 --decode signing/demo-signing.p12.base64 > work/unity-build/demo-signing.p12
trap 'rm -f work/unity-build/demo-signing.p12' EXIT
"$build_tools/zipalign" -P 16 -f 4 "$source_apk" work/unity-build/aligned.apk
"$build_tools/apksigner" sign --ks work/unity-build/demo-signing.p12 --ks-pass pass:schulte-demo-public \
  --ks-key-alias schulte-demo --out build/unity-release/Pipi-Maze-Unity-0.1.0.apk work/unity-build/aligned.apk
"$build_tools/apksigner" verify --verbose --print-certs build/unity-release/Pipi-Maze-Unity-0.1.0.apk > build/unity-release/signature-report.txt
"$build_tools/zipalign" -c -P 16 4 build/unity-release/Pipi-Maze-Unity-0.1.0.apk
cp work/unity-build/badging.txt build/unity-release/package-report.txt
(cd build/unity-release && sha256sum Pipi-Maze-Unity-0.1.0.apk > SHA256SUMS.txt)
