#!/usr/bin/env bash
set -e

echo "=== X6840 Auto Setup - NO SUDO ==="

check_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "[OK] $1"
    else
        echo "[MISSING] $1"
    fi
}

echo
echo "Checking basic commands..."
for cmd in git python3 make gcc g++ rsync wget curl unzip zip gzip xz; do
    check_cmd "$cmd"
done

echo
echo "Preparing executable scripts..."
chmod +x tools/mkbootimg/*.py 2>/dev/null || true
chmod +x tools/libufdt/utils/src/*.py 2>/dev/null || true

echo
echo "Building DTC..."
if [ -d tools/dtc ]; then
    make -C tools/dtc -j"$(nproc)"
else
    echo "[MISSING] tools/dtc"
fi

echo
echo "Checking X6840 tools..."
[ -x tools/dtc/dtc ] && echo "[OK] dtc" || echo "[MISSING] dtc"
[ -x tools/dtc/fdtget ] && echo "[OK] fdtget" || echo "[MISSING] fdtget"
[ -x tools/dtc/fdtput ] && echo "[OK] fdtput" || echo "[MISSING] fdtput"
[ -f tools/mkbootimg/mkbootimg.py ] && echo "[OK] mkbootimg.py" || echo "[MISSING] mkbootimg.py"
[ -f tools/mkbootimg/unpack_bootimg.py ] && echo "[OK] unpack_bootimg.py" || echo "[MISSING] unpack_bootimg.py"
[ -f tools/libufdt/utils/src/mkdtboimg.py ] && echo "[OK] mkdtboimg.py" || echo "[MISSING] mkdtboimg.py"

if [ -f tools/avb/avbtool.py ]; then
    chmod +x tools/avb/avbtool.py
    echo "[OK] avbtool.py"
else
    echo "[MISSING] avbtool.py"
fi

if [ -x tools/fec-build/lpmake ]; then
    echo "[OK] lpmake"
else
    echo "[MISSING] lpmake"
fi

echo
echo "=== NO-SUDO setup completed ==="
echo "Repo path: $PWD"
