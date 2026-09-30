#!/bin/sh
set -e
DB="tests/data/passed.json"
rm -f "$DB"
D="$LARZDAO --board=$DB"

$D fund alice 200
$D fund bob 200
$D fund carol 200
$D create-dao "Marketing Guild" 0.4 0.5
id="$($D list | awk 'NR==3{print $2}')"
$D contribute "$id" alice 100
$D contribute "$id" bob 50
$D contribute "$id" carol 30
$D show "$id"

$D propose "$id" alice designer 50 "new logo" --period=5
pid="$($D show "$id" | grep designer | awk '{print $2}')"
$D vote "$id" "$pid" alice yes
$D vote "$id" "$pid" bob yes
$D vote "$id" "$pid" carol no
sleep 6
$D tally "$id" "$pid"
$D balance designer
$D proposal "$id" "$pid"
