#!/bin/bash
# Verify the base-image README updater rewrites the dated tag and the upstream
# version cell, and is idempotent on an already-current README.
set -euo pipefail
W=$(mktemp -d); trap 'rm -rf $W' EXIT
ORIG=$PWD/README.md

run() { # $1=ffmpeg version  $2=date tag  $3=file
  local FFMPEG_VERSION=$1 DATE_TAG=$2 f=$3
  sed -i -E "s#ispy-ffmpeg-[0-9][0-9.]*-(DDMMYYYY|[0-9]{8})#ispy-ffmpeg-${FFMPEG_VERSION}-${DATE_TAG}#g" "$f"
  sed -i "s|ispy-ffmpeg-[0-9.]*-intel-[0-9.]*|ispy-ffmpeg-${FFMPEG_VERSION}|g" "$f"
  sed -i "s|ispy-ffmpeg-[0-9][0-9.]*|ispy-ffmpeg-${FFMPEG_VERSION}|g" "$f"
  sed -i -E "s#(\| iSpy FFmpeg \|[^|]*\| )[0-9][0-9.]*( \|)#\1${FFMPEG_VERSION}\2#" "$f"
}

echo "== Case 1: placeholder DDMMYYYY + stale upstream cell =="
cp "$ORIG" $W/a.md; run 9.0.1 19082026 $W/a.md
grep -q 'ispy-ffmpeg-9.0.1-19082026' $W/a.md || { echo "FAIL dated tag not written"; exit 1; }
if grep -q 'DDMMYYYY' $W/a.md; then echo "FAIL placeholder survived"; exit 1; fi
grep -qE '^\| iSpy FFmpeg \|.*\| 9\.0\.1 \|$' $W/a.md || { echo "FAIL upstream cell: $(grep 'iSpy FFmpeg' $W/a.md)"; exit 1; }
grep -q 'trixie-slim-vlc-ispy-ffmpeg-9.0.1`' $W/a.md || { echo "FAIL rolling tag row damaged"; exit 1; }
echo "  dated tag + upstream cell updated, placeholder gone"

echo "== Case 2: idempotent re-run =="
cp $W/a.md $W/b.md; run 9.0.1 19082026 $W/b.md
diff -q $W/a.md $W/b.md >/dev/null || { echo "FAIL not idempotent"; diff $W/a.md $W/b.md; exit 1; }
echo "  no churn on re-run"

echo "== Case 3: new ffmpeg version and later date =="
cp $W/a.md $W/c.md; run 9.1.0 25082026 $W/c.md
grep -q 'ispy-ffmpeg-9.1.0-25082026' $W/c.md || { echo "FAIL new dated tag"; exit 1; }
if grep -q '9\.0\.1' $W/c.md; then echo "FAIL old version left behind: $(grep -n '9\.0\.1' $W/c.md)"; exit 1; fi
grep -qE '^\| iSpy FFmpeg \|.*\| 9\.1\.0 \|$' $W/c.md || { echo "FAIL upstream cell not bumped"; exit 1; }
echo "  rolls forward cleanly"

echo "== Case 4: only the intended lines change =="
diff "$ORIG" $W/a.md | grep '^[<>]' || true
n=$(diff "$ORIG" $W/a.md | grep -c '^<' || true)
[ "$n" = 2 ] || { echo "FAIL expected 2 changed lines, got $n"; exit 1; }
echo "ALL CHECKS PASSED"
