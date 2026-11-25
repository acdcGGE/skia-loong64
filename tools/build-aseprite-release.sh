#!/usr/bin/env bash
# Rebuild the self-contained Skia release bundle from:
#   - the upstream skia-m124-loong64 tarball
#   - a restored Skia source tree (commit from commit.txt)
#   - a locally built ICU 78 static library
#   - system libjpeg / libpng headers and Aseprite's libwebp headers
set -euo pipefail

: "${SKIA_TARBALL:?set SKIA_TARBALL to skia-loong64.tar.zst}"
: "${SKIA_RESTORED:?set SKIA_RESTORED to the dir with modules/ src/ restored}"
: "${ICU78_LIB:?set ICU78_LIB to the dir with libicu*.a}"
: "${WEBP_SRC:?set WEBP_SRC to aseprite third_party/libwebp/src}"
: "${OUT_DIR:?set OUT_DIR for the resulting tarballs}"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE" "$OUT_DIR"

tar -I zstd -xf "$SKIA_TARBALL" -C "$STAGE"
ROOT="$STAGE/skia-loong64"

cp -a "$SKIA_RESTORED/modules" "$ROOT/"
cp -a "$SKIA_RESTORED/src" "$ROOT/"

mkdir -p "$ROOT/third_party/externals/icu/flutter"
cp -a "$SKIA_RESTORED/third_party/externals/icu/flutter/icudtl.dat" \
  "$ROOT/third_party/externals/icu/flutter/icudtl.dat"

mkdir -p "$ROOT/third_party/externals/libjpeg-turbo/loongarch64-linux-gnu"
for h in jpeglib.h jerror.h jmorecfg.h; do
  cp -a "/usr/include/$h" "$ROOT/third_party/externals/libjpeg-turbo/$h"
done
cp -a /usr/include/loongarch64-linux-gnu/jconfig.h \
  "$ROOT/third_party/externals/libjpeg-turbo/jconfig.h"
cp -a /usr/include/loongarch64-linux-gnu/jconfig.h \
  "$ROOT/third_party/externals/libjpeg-turbo/loongarch64-linux-gnu/jconfig.h"

mkdir -p "$ROOT/third_party/externals/libpng"
for h in png.h pngconf.h pnglibconf.h; do
  cp -a "/usr/include/$h" "$ROOT/third_party/externals/libpng/$h"
done

mkdir -p "$ROOT/third_party/externals/libwebp"
cp -a "$WEBP_SRC" "$ROOT/third_party/externals/libwebp/src"

if [ -L "$ROOT/src/ports/fontations/Cargo.toml" ] && \
   [ ! -e "$ROOT/src/ports/fontations/Cargo.toml" ]; then
  rm -f "$ROOT/src/ports/fontations/Cargo.toml"
fi

cp -a /usr/lib/loongarch64-linux-gnu/libjpeg.a "$ROOT/lib/libjpeg.a"

find "$STAGE" -type d -exec chmod 755 {} +
find "$STAGE" -type f -exec chmod 644 {} +

tar --format=gnu --owner=0 --group=0 --numeric-owner \
  --use-compress-program='zstd -T0 -12' \
  -cf "$OUT_DIR/skia-loong64-aseprite.tar.zst" -C "$STAGE" .

ICU_STAGE="$(mktemp -d)"
mkdir -p "$ICU_STAGE/icu78/lib"
for l in libicuuc.a libicui18n.a libicudata.a; do
  cp -a "$ICU78_LIB/$l" "$ICU_STAGE/icu78/lib/$l"
done
find "$ICU_STAGE" -type d -exec chmod 755 {} +
find "$ICU_STAGE" -type f -exec chmod 644 {} +
tar --format=gnu --owner=0 --group=0 --numeric-owner \
  --use-compress-program='zstd -T0 -12' \
  -cf "$OUT_DIR/icu78-loong64-static.tar.zst" -C "$ICU_STAGE" .
rm -rf "$ICU_STAGE"

sha256sum "$OUT_DIR"/skia-loong64-aseprite.tar.zst \
          "$OUT_DIR"/icu78-loong64-static.tar.zst
