#!/usr/bin/env bash
set -euo pipefail
adb shell wm size 720x1560
adb shell wm density 320
adb shell input keyevent 82
adb install -r build/output/Schulte-Flow-1.0.0.apk
adb install -r build/test/smoke.apk
adb shell am instrument -w com.alex.schulteflow.smoke/com.alex.schulteflow.smoke.SmokeInstrumentation | tee build/smoke-report.txt
adb pull /sdcard/Android/data/com.alex.schulteflow/files build/screenshots || true
adb logcat -d > build/logcat.txt
grep -E 'TOTAL [0-9]+ UI CHECKS PASS' build/smoke-report.txt
! grep -E 'FAIL|INSTRUMENTATION_FAILED' build/smoke-report.txt
