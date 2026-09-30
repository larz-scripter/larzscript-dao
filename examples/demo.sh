#!/bin/sh
# A narrated walkthrough - three members contribute unequal stakes to a
# DAO treasury, then watch the same require-gated tally logic produce
# three different real outcomes: a proposal that genuinely passes, one
# that fails quorum outright, and one where everyone votes (quorum met)
# but "no" genuinely outweighs "yes". Run from the repo root:
# sh examples/demo.sh
set -e
DB="/tmp/larzdao-demo-$$.json"
rm -f "$DB"
LARZDAO="larzscript bin/larzdao.lz --board=$DB"

echo "--- fund three members (demo-only faucet) ---"
$LARZDAO fund alice 200
$LARZDAO fund bob 200
$LARZDAO fund carol 200

echo "--- create a DAO: 40% quorum, >50% majority of decisive votes ---"
$LARZDAO create-dao "Marketing Guild" 0.4 0.5
id="$($LARZDAO list | awk 'NR==3{print $2}')"

echo "--- unequal stakes: alice 100, bob 50, carol 30 - voting power matches ---"
$LARZDAO contribute "$id" alice 100
$LARZDAO contribute "$id" bob 50
$LARZDAO contribute "$id" carol 30
$LARZDAO show "$id"

echo
echo "--- proposal 1: alice + bob vote yes, carol votes no - passes ---"
$LARZDAO propose "$id" alice designer 50 "new logo" --period=5
pid1="$($LARZDAO show "$id" | grep designer | awk '{print $2}')"
$LARZDAO vote "$id" "$pid1" alice yes
$LARZDAO vote "$id" "$pid1" bob yes
$LARZDAO vote "$id" "$pid1" carol no
sleep 6
$LARZDAO tally "$id" "$pid1"
$LARZDAO balance designer

echo
echo "--- proposal 2: only carol votes (weight 30 of 180 total) - fails quorum ---"
$LARZDAO propose "$id" alice grantee 50 "quorum test" --period=5
pid2="$($LARZDAO show "$id" | grep -v "new logo" | grep grantee | awk '{print $2}')"
$LARZDAO vote "$id" "$pid2" carol yes
sleep 6
$LARZDAO tally "$id" "$pid2"
$LARZDAO balance grantee

echo
echo "--- proposal 3: everyone votes (quorum met), but no (100) beats yes (80) ---"
$LARZDAO propose "$id" alice grantee 50 "majority test" --period=5
pid3="$($LARZDAO show "$id" | grep "majority test" | awk '{print $2}')"
$LARZDAO vote "$id" "$pid3" alice no
$LARZDAO vote "$id" "$pid3" bob yes
$LARZDAO vote "$id" "$pid3" carol yes
sleep 6
$LARZDAO tally "$id" "$pid3"
$LARZDAO balance grantee

echo
echo "--- final state ---"
$LARZDAO show "$id"

rm -f "$DB"
