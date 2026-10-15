#!/usr/bin/env bash
set -euo pipefail
APK="${1:?APK path required}"
BT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}/build-tools/35.0.0"
"$BT/apksigner" verify --verbose "$APK"
"$BT/zipalign" -c -P 16 4 "$APK"
BADGING=$("$BT/aapt2" dump badging "$APK")
echo "$BADGING"
grep -q "name='com.alex.schulteflow.godot'" <<< "$BADGING"
grep -Eq "(minSdkVersion|sdkVersion):'24'" <<< "$BADGING"
grep -q "targetSdkVersion:'36'" <<< "$BADGING"
! grep -q 'android.permission.INTERNET' <<< "$BADGING"
python3 - "$APK" <<'PY'
import sys, zipfile, struct
with zipfile.ZipFile(sys.argv[1]) as z:
    names=z.namelist()
    for abi in ('arm64-v8a','armeabi-v7a','x86_64'):
        name=f'lib/{abi}/libgodot_android.so'
        assert name in names, f'Missing {abi}'
        data=z.read(name)
        bits=data[4]
        offset=struct.unpack_from('<Q' if bits==2 else '<I',data,32 if bits==2 else 28)[0]
        entry_size, count=struct.unpack_from('<HH',data,54 if bits==2 else 42)
        for i in range(count):
            pos=offset+i*entry_size
            if bits==2 and struct.unpack_from('<I',data,pos)[0]==1:
                alignment=struct.unpack_from('<Q' if bits==2 else '<I',data,pos+(48 if bits==2 else 28))[0]
                assert alignment>=16384, (abi,'ELF segment is not 16 KB aligned')
    assert any(n.startswith('assets/') for n in names), 'Missing game assets'
    assert not any('/tests/' in n for n in names), 'Test code leaked into APK'
print('APK PASS: signature, 16 KB ZIP/64-bit ELF alignment, manifest, 3 ABIs, offline permissions, game assets')
PY
