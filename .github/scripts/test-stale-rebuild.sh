#!/usr/bin/env bash
# Self-check for the image-age (Debian package refresh) rebuild decision.
#
# Replays the auto-check branch of "Determine build versions" with a stubbed
# `crane config` so no registry is touched. The rule under test: with no upstream
# FFmpeg change, rebuild anyway once the published image reaches MAX_IMAGE_AGE_DAYS,
# and do not let the tag-exists check veto that rebuild.
set -uo pipefail
fail() { echo "FAIL: $*"; exit 1; }

# $1 = age of :latest in days ("none" = unreadable), $2 = ffmpeg changed?,
# $3 = MAX_IMAGE_AGE_DAYS, $4 = tag already exists?
decide() {
  local age=$1 ffmpeg_changed=$2 MAX_IMAGE_AGE_DAYS=$3 tag_exists=$4
  local SHOULD_BUILD="false" STALE_REBUILD="false"

  [[ "$ffmpeg_changed" == "true" ]] && SHOULD_BUILD="true"

  if [[ "$SHOULD_BUILD" != "true" && "${MAX_IMAGE_AGE_DAYS:-30}" != "0" ]]; then
    local CREATED=""
    [[ "$age" != "none" ]] && CREATED=$(date -u -d "${age} days ago" +%Y-%m-%dT%H:%M:%SZ)
    if [[ -n "$CREATED" ]]; then
      local CREATED_EPOCH AGE_DAYS
      CREATED_EPOCH=$(date -d "$CREATED" +%s 2>/dev/null || echo 0)
      if [[ "$CREATED_EPOCH" -gt 0 ]]; then
        AGE_DAYS=$(( ( $(date +%s) - CREATED_EPOCH ) / 86400 ))
        if [[ "$AGE_DAYS" -ge "${MAX_IMAGE_AGE_DAYS}" ]]; then
          SHOULD_BUILD="true"; STALE_REBUILD="true"
        fi
      fi
    fi
  fi

  # Final build decision: the tag-exists veto, which must not fire on a refresh.
  local FINAL="$SHOULD_BUILD"
  if [[ "$SHOULD_BUILD" == "true" && "$tag_exists" == "true" \
        && "$STALE_REBUILD" != "true" ]]; then
    FINAL="false"
  fi
  echo "$FINAL $STALE_REBUILD"
}

echo "== fresh image, no upstream change =="
read -r build stale <<< "$(decide 5 false 30 true)"
[ "$build" = "false" ] || fail "rebuilt a 5-day-old image (build=$build)"
echo "  no rebuild (build=$build stale=$stale)"

echo "== 29 days: still inside the window =="
read -r build stale <<< "$(decide 29 false 30 true)"
[ "$build" = "false" ] || fail "rebuilt at 29d, threshold is 30d"
echo "  no rebuild"

echo "== 30 days: threshold reached =="
read -r build stale <<< "$(decide 30 false 30 true)"
[ "$build" = "true" ] || fail "no rebuild at exactly 30d"
[ "$stale" = "true" ] || fail "stale_rebuild flag not set"
echo "  rebuilds despite the tag already existing"

echo "== 75 days: the real 5 Jun -> 19 Aug gap =="
read -r build stale <<< "$(decide 75 false 30 true)"
[ "$build" = "true" ] || fail "no rebuild after 75d -- the mesa CVE gap would recur"
echo "  rebuilds"

echo "== upstream change wins, and is not marked stale =="
read -r build stale <<< "$(decide 1 true 30 false)"
[ "$build" = "true" ] || fail "upstream change did not build"
[ "$stale" = "false" ] || fail "upstream build wrongly flagged as a package refresh"
echo "  normal version build, stale flag clear"

echo "== tag-exists veto still applies to a non-stale build =="
read -r build stale <<< "$(decide 1 true 30 true)"
[ "$build" = "false" ] || fail "existing tag was rebuilt without the stale flag"
echo "  veto intact"

echo "== disabled with MAX_IMAGE_AGE_DAYS=0 =="
read -r build stale <<< "$(decide 400 false 0 true)"
[ "$build" = "false" ] || fail "age check ran while disabled"
echo "  no rebuild"

echo "== unreadable creation date degrades safely =="
read -r build stale <<< "$(decide none false 30 true)"
[ "$build" = "false" ] || fail "built on an unreadable creation date"
echo "  skipped, no build"

echo "ALL CHECKS PASSED"
