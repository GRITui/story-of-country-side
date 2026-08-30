#!/bin/bash
# Super User per-sprint regression battery (sprint-004+).
# One command to answer "is the current base branch still green, and do
# the fixes/features other squads landed actually work end-to-end?"
#
# Usage: bash superuser/run_battery.sh [sprint-label]
#   sprint-label (optional) tags the /tmp/battery-<label>/ output dir;
#   defaults to a timestamp. Exit code = number of failed steps (capped 9).

set -u
cd "$(dirname "$0")/.."
LABEL="${1:-$(date +%Y%m%d-%H%M%S)}"
OUT="/tmp/battery-$LABEL"
mkdir -p "$OUT"
FAILED=0

step() { echo ""; echo "=== [$1] $2 ==="; }
note() { FAILED=$((FAILED+1)); echo "*** STEP FAILED: $1"; }

step 0 "editor class-cache refresh"
godot --headless --editor --quit > "$OUT/editor.log" 2>&1 \
  && echo "ok" || note "editor refresh"

step 1 "full unit suite"
godot --headless --path . tests/TestRunner.tscn > "$OUT/tests.log" 2>&1
grep -E "ALL TESTS PASSED|TESTS FAILED|checks" "$OUT/tests.log" | tail -2
grep -q "ALL TESTS PASSED" "$OUT/tests.log" || note "unit suite"

step 2 "smoke: project main scene (TitleScreen)"
godot --headless --path . --quit-after 60 > "$OUT/smoke_title.log" 2>&1 \
  && echo "exit ok" || note "title smoke"
grep -iE "SCRIPT ERROR|ERROR:" "$OUT/smoke_title.log" | grep -v "Leaked instance" | head -3

step 3 "smoke: Main.tscn direct (independent entry point)"
godot --headless --path . scenes/Main.tscn --quit-after 60 > "$OUT/smoke_main.log" 2>&1 \
  && echo "exit ok" || note "main smoke"

step 4 "retailer economy matrix (21 checks)"
godot --headless --path . superuser/autoplay/RetailSimDriver.tscn -- --phase retail > "$OUT/retail.log" 2>&1
grep -E "SU3-RESULT\] checks|failure=" "$OUT/retail.log" | head -4

step 5 "title screen probe (#92 coverage)"
godot --headless --path . superuser/autoplay/RetailSimDriver.tscn -- --phase title > "$OUT/title.log" 2>&1
grep -E "SU3-RESULT\] checks|failure=|T04|SU3-NOTE" "$OUT/title.log" | head -5

step 6 "festival save (process 1 of 2)"
godot --headless --path . superuser/autoplay/RetailSimDriver.tscn -- --phase fest_save > "$OUT/fest_save.log" 2>&1
grep -E "SU3-FEST" "$OUT/fest_save.log" | head -2

step 7 "festival relaunch (process 2 of 2)"
godot --headless --path . superuser/autoplay/RetailSimDriver.tscn -- --phase fest_check > "$OUT/fest_check.log" 2>&1
grep -E "SU3-FEST|SU3\] F0|SU3-FAIL" "$OUT/fest_check.log" | head -8

step 8 "autoplay full new-player playthrough"
godot --headless --path . superuser/autoplay/AutoplayDriver.tscn -- --phase full > "$OUT/autoplay.log" 2>&1
grep -E "SU2-RESULT\] failures|economy gold" "$OUT/autoplay.log" | head -3

echo ""
echo "=== battery '$LABEL' complete: $FAILED failed step(s); logs in $OUT ==="
exit $(( FAILED > 9 ? 9 : FAILED ))
