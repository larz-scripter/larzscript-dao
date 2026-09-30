#!/bin/sh
# A too-short/empty id must fail cleanly, not silently match the first
# dao/proposal iterated over - see bin/larzdao.lz's _find_dao_by_prefix()/
# _find_proposal_by_prefix(). Also covers a non-member correctly being
# refused a vote, and voting after the deadline being refused.
set -e
DB="tests/data/guard.json"
rm -f "$DB"
D="$LARZDAO --board=$DB"

$D fund alice 200
$D create-dao "Only DAO" 0.4 0.5
id="$($D list | awk 'NR==3{print $2}')"
$D show "" || true
$D show "ab" || true

$D contribute "$id" alice 100
$D propose "$id" alice grantee 10 "test" --period=5
pid="$($D show "$id" | grep grantee | awk '{print $2}')"

echo "--- a non-member (no voting power) tries to vote ---"
$D vote "$id" "$pid" mallory yes || true

echo "--- voting after the deadline ---"
sleep 6
$D vote "$id" "$pid" alice yes || true
