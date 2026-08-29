#!/usr/bin/env bash
set -e

echo "=== X6840 Repack Tools Setup ==="

sudo apt update

sudo apt install -y \
  git \
  python3 \
  python3-pip \
  python3-setuptools \
  build-essential \
  make \
  gcc \
  g++ \
  pkg-config \
  libssl-dev \
  libfdt-dev \
  zlib1g-dev \
  liblz4-tool \
  lz4 \
  xz-utils \
  gzip \
  bzip2 \
  unzip \
  zip \
  rsync \
  wget \
  curl

echo "Building DTC..."
if [ -d tools/dtc ]; then
    make -C tools/dtc -j"$(nproc)"
fi

chmod +x tools/mkbootimg/*.py 2>/dev/null || true
chmod +x setup.sh

echo
echo "=== Setup completed ==="
echo "DTC:       tools/dtc/dtc"
echo "fdtget:    tools/dtc/fdtget"
echo "fdtput:    tools/dtc/fdtput"
echo "mkbootimg: tools/mkbootimg/mkbootimg.py"
echo "unpack:    tools/mkbootimg/unpack_bootimg.py"
