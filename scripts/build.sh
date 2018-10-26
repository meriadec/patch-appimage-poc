#!/bin/bash

set -e

yarn compile
electron-builder
ls -l dist

BASE_URL=http://mirrors.kernel.org/ubuntu/pool/main/k/krb5
PACKAGE_SUFFIX=-2build1_amd64.deb
TMP_DIR=$(mktemp -d)
PACKAGE_NAME=patch-appimage-poc
PACKAGE_VERSION=$(grep version package.json | sed -E 's/.*: "(.*)",/\1/g')

cp "dist/$PACKAGE_NAME-$PACKAGE_VERSION-x86_64.AppImage" "$TMP_DIR"
pushd "$TMP_DIR"

declare -a LIBRARIES=(
  "libgssapi-krb5-2_1.16"
  "libk5crypto3_1.16"
  "libkrb5-3_1.16"
  "libkrb5support0_1.16"
)

for PACKAGE in "${LIBRARIES[@]}"; do
  curl -fOL "$BASE_URL/$PACKAGE$PACKAGE_SUFFIX"
  ar p "$PACKAGE$PACKAGE_SUFFIX" data.tar.xz | tar xvJf >/dev/null - ./usr/lib/x86_64-linux-gnu/
  rm "$PACKAGE$PACKAGE_SUFFIX"
done

curl -fOL "https://s3-eu-west-1.amazonaws.com/ledger-ledgerlive-resources-dev/public_resources/appimagetool-x86_64.AppImage"

./"$PACKAGE_NAME"-"$PACKAGE_VERSION"-linux-x86_64.AppImage --appimage-extract
cp -a usr/lib/x86_64-linux-gnu/*.so.* squashfs-root/usr/lib

chmod +x appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage squashfs-root "$OLDPWD/dist/$PACKAGE_NAME-$PACKAGE_VERSION-linux-x86_64.AppImage"

popd
