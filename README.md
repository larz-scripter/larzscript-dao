# LarzDAO

Stake-weighted governance treasuries, written entirely in Larzscript,
the money-native language. Members contribute real money into a shared
treasury and get voting power equal to what they put in. A proposal can
only pay out once a real `require` confirms two things across **every**
member, not just the recipient's own wallet: enough of the DAO's total
voting power actually showed up (quorum), and of the decisive votes
cast, yes genuinely outweighs no (majority).

Part of the [Larzscript ecosystem growth plan](https://github.com/larz-scripter/larzscript/blob/main/GROWTH.md)'s
flagship-app track (alongside [`LarzBank`](https://github.com/larz-scripter/larzscript-bank),
[`LarzBounty`](https://github.com/larz-scripter/larzscript-bounty),
[`LarzCrowd`](https://github.com/larz-scripter/larzscript-crowd),
[`LarzInsure`](https://github.com/larz-scripter/larzscript-insure), and
[`LarzGig`](https://github.com/larz-scripter/larzscript-gig)).

## Why this needed `require` for something no single wallet check can express

Every sibling project's `require` gates a payment on money: enough
escrow, enough reserve, a reconciling split. LarzDAO's gate is
**consensus**, not cash — and it has to be computed fresh from every
vote on record, against the DAO's *entire* membership, not just whoever
happened to vote:

```larzscript
let total_power = total_voting_power(dao)   # every member, not just voters
...
require cast_w >= dao["quorum_pct"] * total_power, "quorum not reached"
require yes_w > dao["majority_pct"] * (yes_w + no_w), "majority not reached"
```

Two DAOs with the exact same proposal, the exact same "yes" votes, and
the exact same treasury balance can land on opposite outcomes purely
because of who *didn't* vote — that's what quorum means, and the demo
below shows it happening for real: a proposal with 30 yes-weight out of
180 total voting power is rejected outright (nobody else showed up),
while a near-identical proposal with 150 yes-weight passes cleanly.

## Quickstart

```bash
larzscript bin/larzdao.lz fund alice 200
larzscript bin/larzdao.lz create-dao "Marketing Guild" 0.4 0.5
larzscript bin/larzdao.lz contribute <dao_id> alice 100
larzscript bin/larzdao.lz propose <dao_id> alice designer 50 "new logo" --period=86400
larzscript bin/larzdao.lz vote <dao_id> <proposal_id> alice yes
larzscript bin/larzdao.lz tally <dao_id> <proposal_id>
```

State (wallets, DAOs, proposals) persists to `board.json` in the current
directory across runs — each command is a fresh process; see "How it's
built" below for how that's made to work with a native `wallet` value,
which isn't something JSON can hold. Override the state file with
`--board=path/to/file.json`.

## Real transcript (`sh examples/demo.sh`, copy-pasted, not invented)

```
--- fund three members (demo-only faucet) ---
alice balance is now $200
bob balance is now $200
carol balance is now $200
--- create a DAO: 40% quorum, >50% majority of decisive votes ---
created dao dd23eb37  "Marketing Guild"  quorum 40%  majority 50%
full id: dd23eb37-3b27-4f3c-9885-ccddb062c59a
--- unequal stakes: alice 100, bob 50, carol 30 - voting power matches ---
alice contributed $100 - voting power now 100
bob contributed $50 - voting power now 50
carol contributed $30 - voting power now 30
id:        dd23eb37-3b27-4f3c-9885-ccddb062c59a
name:      Marketing Guild
treasury:  $180
quorum:    40%  of total voting power 180
majority:  50%  of decisive (yes/no) votes
members:
  - alice  power 100
  - bob  power 50
  - carol  power 30
proposals:

--- proposal 1: alice + bob vote yes, carol votes no - passes ---
proposal 8dfa6e44 opened - $50 to designer
full id: 8dfa6e44-4856-454b-bd2a-256a00213453
alice voted yes
bob voted yes
carol voted no
PASSED - paid out
designer: $50

--- proposal 2: only carol votes (weight 30 of 180 total) - fails quorum ---
proposal b0f161ec opened - $50 to grantee
full id: b0f161ec-9152-407a-ab09-6f423ed8e4bf
carol voted yes
REJECTED: quorum not reached (line 171)
grantee: $0

--- proposal 3: everyone votes (quorum met), but no (100) beats yes (80) ---
proposal fb323813 opened - $50 to grantee
full id: fb323813-7aa9-4572-b55a-acd97194601f
alice voted no
bob voted yes
carol voted yes
REJECTED: majority not reached (line 172)
grantee: $0

--- final state ---
id:        dd23eb37-3b27-4f3c-9885-ccddb062c59a
name:      Marketing Guild
treasury:  $130
quorum:    40%  of total voting power 180
majority:  50%  of decisive (yes/no) votes
members:
  - alice  power 100
  - bob  power 50
  - carol  power 30
proposals:
  - 8dfa6e44  $50 to designer  [passed]  new logo
  - b0f161ec  $50 to grantee  [rejected]  quorum test
  - fb323813  $50 to grantee  [rejected]  majority test
```

## Commands

| Command | What it does |
|---|---|
| `fund <name> <amount>` | Demo-only faucet — credits a balance directly. A real deployment replaces this with an actual funding flow. |
| `create-dao <name> <quorum_pct> <majority_pct>` | Opens a DAO. `quorum_pct` (0.4 = 40%) is the share of *total* voting power that must vote for any tally to count; `majority_pct` (0.5 = 50%) is the share of decisive (yes+no, abstain excluded) votes yes must exceed. |
| `contribute <dao_id> <member> <amount>` | Moves real money into the treasury permanently and mints voting power 1:1 against it. |
| `propose <dao_id> <proposer> <recipient> <amount> <description> --period=<secs>` | Opens a proposal. Only a member with voting power may propose. |
| `vote <dao_id> <proposal_id> <member> <yes\|no\|abstain>` | Casts (or changes) a vote, weighted by the member's *current* voting power. Only members may vote; only before the deadline. |
| `tally <dao_id> <proposal_id>` | Settles a proposal after its deadline: pays out if quorum and majority both hold, otherwise rejects with the specific reason — no partial payout either way. |
| `list` | Lists every DAO with its treasury, quorum/majority settings, and member count. |
| `show <dao_id>` | Full detail on one DAO: treasury, total voting power, every member's stake, and every proposal's status. `<id>` may be the short 8-character prefix `create-dao`/`list` print. |
| `proposal <dao_id> <proposal_id>` | Full detail on one proposal: every vote cast and, once settled, the exact tally. |
| `balance <name>` | Shows the current balance. |

## How it's built

- **`lib/moneyx.lz`** — the bridge between the native `wallet`/Money
  type and a plain float, for persisting balances to JSON. There is no
  `float(money)` builtin; stripping the leading `"$"` off `str(m)` is
  the real, working conversion.
- **`lib/dao.lz`** — DAOs, proposals, and the vote/tally logic described
  above. Like LarzInsure, this uses `pay` **directly** rather than the
  `escrow` package's open/release/refund vocabulary — a contribution
  pools into the treasury permanently, the same way a real DAO's
  treasury isn't a refundable deposit.
- **`bin/larzdao.lz`** — the CLI. Each invocation loads `board.json`,
  does one thing, saves it back. `_find_dao_by_prefix()`/
  `_find_proposal_by_prefix()` both reject a too-short/empty id outright
  rather than risk matching the wrong record — the same class of bug
  found and fixed in the sibling LarzBounty/LarzCrowd/LarzGig projects,
  applied here from the start.

## Limitations (read before treating this as more than a toy)

- **`fund` is a faucet, not a payment rail.** There's no real deposit
  flow behind it.
- **No identity/authorization model.** Anyone running the CLI can cast
  a vote as anyone — there's no signature or login tying a vote to the
  person who cast it. A real deployment needs an auth layer in front of
  this.
- **No exit/redemption path.** Contributing is one-way — there's no way
  for a member to withdraw their stake and reduce their voting power,
  the same deliberate choice LarzInsure made for premiums.
- **Voting power is purely plutocratic** (1 dollar contributed = 1 vote,
  forever) — no quadratic voting, no delegation, no time-decay. A real
  governance system often wants at least one of these.
- **Floating-point, not arbitrary-precision.** Larzscript's only numeric
  type is a double, the same limitation every Larz Stack money package
  documents.
- **Single-process, no concurrent access.** Two `larzdao` invocations
  racing against the same `board.json` can clobber each other — fine
  for a personal CLI tool, not for anything multi-user.
- **`board.json` is not encrypted or access-controlled.** Don't put real
  financial data in it.

## Tests

```bash
sh tests/run_tests.sh
```

Real CLI output, diffed against `tests/*.expected`, `uuid.v4()` ids
normalized like the sibling projects. Covers: a proposal that genuinely
passes (quorum and majority both hold), one that's rejected for missing
quorum, one that's rejected for missing majority despite quorum being
met, and the too-short-id-prefix guard plus a non-member being refused
a vote and a vote correctly refused after the deadline.

## License

MIT
