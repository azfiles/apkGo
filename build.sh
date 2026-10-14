#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
: "${ANDROID_SDK_ROOT:=${ANDROID_HOME:-}}"
: "${ANDROID_SDK_ROOT:?Set ANDROID_SDK_ROOT}"
BT="$ANDROID_SDK_ROOT/build-tools/35.0.0"
API="$ANDROID_SDK_ROOT/platforms/android-35/android.jar"
mkdir -p build/{flat,generated,classes,dex,output}
python3 scripts/generate_sounds.py
python3 - <<'PY'
from pathlib import Path
s=Path('app/src/main/AndroidManifest.xml').read_text().replace('<manifest ','<manifest package="com.alex.schulteflow" ',1)
Path('build/AndroidManifest.xml').write_text(s)
PY
"$BT/aapt2" compile --dir app/src/main/res -o build/flat
"$BT/aapt2" link -I "$API" --manifest build/AndroidManifest.xml --java build/generated -o build/resources.apk --min-sdk-version 26 --target-sdk-version 35 build/flat/*.flat
find app/src/main/java build/generated -name '*.java' > build/sources.txt
javac -source 8 -target 8 -encoding UTF-8 -classpath "$API" -d build/classes @build/sources.txt
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
with ZipFile('build/classes.jar','w',ZIP_DEFLATED) as z:
 for p in Path('build/classes').rglob('*.class'):z.write(p,str(p.relative_to('build/classes')))
PY
"$BT/d8" --release --min-api 26 --lib "$API" --output build/dex build/classes.jar
cp build/resources.apk build/unsigned.apk
python3 - <<'PY'
from zipfile import ZipFile,ZIP_STORED
with ZipFile('build/unsigned.apk','a') as z:z.write('build/dex/classes.dex','classes.dex',compress_type=ZIP_STORED)
PY
"$BT/zipalign" -f -p 4 build/unsigned.apk build/aligned.apk
base64 --decode signing/demo-signing.p12.base64 > build/demo-signing.p12
"$BT/apksigner" sign --ks build/demo-signing.p12 --ks-pass pass:schulte-demo-public --ks-key-alias schulte-demo --out build/output/Schulte-Flow-1.0.0.apk build/aligned.apk
"$BT/apksigner" verify --verbose build/output/Schulte-Flow-1.0.0.apk
"$BT/zipalign" -c -p 4 build/output/Schulte-Flow-1.0.0.apk
(cd build/output && sha256sum Schulte-Flow-1.0.0.apk > SHA256SUMS.txt)
