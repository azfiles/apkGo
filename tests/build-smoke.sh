#!/usr/bin/env bash
set -euo pipefail
BT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}/build-tools/35.0.0"
API="${ANDROID_SDK_ROOT:-$ANDROID_HOME}/platforms/android-35/android.jar"
mkdir -p build/test/{classes,dex}
"$BT/aapt2" link -I "$API" --manifest tests/AndroidManifest.xml -o build/test/resources.apk
javac -source 8 -target 8 -encoding UTF-8 -classpath "$API" -d build/test/classes tests/SmokeInstrumentation.java
python3 - <<'PYZIP'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
with ZipFile('build/test/classes.jar','w',ZIP_DEFLATED) as z:
 for p in Path('build/test/classes').rglob('*.class'):z.write(p,str(p.relative_to('build/test/classes')))
PYZIP
"$BT/d8" --min-api 26 --lib "$API" --output build/test/dex build/test/classes.jar
cp build/test/resources.apk build/test/unsigned.apk
python3 - <<'PY'
from zipfile import ZipFile,ZIP_STORED
with ZipFile('build/test/unsigned.apk','a') as z:z.write('build/test/dex/classes.dex','classes.dex',compress_type=ZIP_STORED)
PY
"$BT/zipalign" -f -p 4 build/test/unsigned.apk build/test/aligned.apk
"$BT/apksigner" sign --ks build/demo-signing.p12 --ks-pass pass:schulte-demo-public --ks-key-alias schulte-demo --out build/test/smoke.apk build/test/aligned.apk
