#!/bin/sh
# Two distinct rejection reasons: one proposal fails quorum outright
# (too few members voted at all), a second meets quorum but fails
# majority (more weighted "no" than "yes"). Neither moves any money.
set -e
DB="tests/data/rejected.json"
rm -f "$DB"
D="$LARZDAO --board=$DB"

$D fund alice 200
$D fund bob 200
$D fund carol 200
$D create-dao "Core Protocol" 0.4 0.5
id="$($D list | awk 'NR==3{print $2}')"
$D contribute "$id" alice 100
$D contribute "$id" bob 50
$D contribute "$id" carol 30

echo "--- quorum failure: only carol (weight 30 of 180 total) votes ---"
$D propose "$id" alice grantee 50 "quorum test" --period=5
pid1="$($D show "$id" | grep grantee | awk '{print $2}')"
$D vote "$id" "$pid1" carol yes
sleep 6
$D tally "$id" "$pid1"
$D balance grantee

echo "--- majority failure: everyone votes, but no (100) beats yes (80) ---"
$D propose "$id" alice grantee 50 "majority test" --period=5
pid2="$($D show "$id" | grep -v "quorum test" | grep grantee | awk '{print $2}')"
$D vote "$id" "$pid2" alice no
$D vote "$id" "$pid2" bob yes
$D vote "$id" "$pid2" carol yes
sleep 6
$D tally "$id" "$pid2"
$D balance grantee
$D show "$id"
