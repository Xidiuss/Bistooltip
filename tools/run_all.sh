#!/usr/bin/env bash
# tools/run_all.sh — single offline gate for Bistooltip META-Z.
# Requires lua5.1 + luac5.1 (WSL: wsl -e bash -c "cd <repo> && bash tools/run_all.sh").
set -e
cd "$(dirname "$0")/.."

echo "== syntax (luac -p) =="
fail=0
for f in Bistooltip/*.lua Bistooltip/ui/*.lua Bistooltip/util/*.lua \
         Bistooltip_Scanner/*.lua tools/*.lua \
         Bistooltip_*/main.lua; do
  [ -f "$f" ] || continue
  luac5.1 -p "$f" || fail=1
done
[ "$fail" -eq 0 ] && echo "syntax: OK"

echo "== unit suites =="
lua5.1 tools/test_formatter.lua
lua5.1 tools/test_pluginapi.lua
lua5.1 tools/check_sources.lua
lua5.1 tools/census_bis.lua

echo "== plugins (end-to-end, every Bistooltip_*/main.lua) =="
for p in Bistooltip_*/main.lua; do
  [ -f "$p" ] || continue
  lua5.1 tools/test_plugin.lua "$p" | grep -E "^plugin:|error|assertion" || exit 1
done

echo "run_all: ALL GREEN"
