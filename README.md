# Reforge

A Windower 4 addon for Final Fantasy XI that upgrades your Artifact, Relic and Empyrean armor for you, from the old sets up to +3. It trades each piece to the NPC, waits out the game day, collects it and moves on to the next. When a piece is short of something, it tells you exactly what to go and get.

> Reforge talks to NPCs and trades items by sending packets to the game server. Use it at your own risk.

## Install

1. Put this folder in `Windower/addons/` so the files are at `Windower/addons/reforge/reforge.lua`.
2. In game: `//lua load reforge`

Commands work as `//reforge`, `//frg` or `//forge`.

## Running upgrades

Put the pieces you want upgraded in your inventory, stand by the NPC and `//frg start`.

| NPC | Where | Upgrades |
|---|---|---|
| Monisette | Port Jeuno | Old sets → iL109, iL109 → +1 |
| Coelestrox | Reisenjima | Artifact +1 → +2, +2 → +3 (the +3 takes two trades, a day apart) |
| Aurix ("???") | Ru'Lude Gardens | Relic +1 → +2, +2 → +3 |
| Ruspix | Leafallia | Empyrean +1 → +2, +2 → +3 |

| Command | What it does |
|---|---|
| `//frg start` | Upgrade, one at a time, every piece in inventory whose materials you have |
| `//frg stop` | Stop; `//frg start` carries on later |
| `//frg status` | What each NPC was given, and what is ready next |
| `//frg debug [on\|off]` | Dry run: trade packets go to `data/dryrun.log` instead of being sent |

When you start, after each day change and after each collection, Reforge talks to the NPC to see what they have. Then it collects a finished piece, waits for one that isn't ready, or trades the next piece from your inventory. That means:

- An upgraded piece whose next step is at the same NPC carries straight on.
- Pieces you add mid-run are picked up.
- A crash, a reload or anything you do by hand is noticed the next time it asks.

Just before each trade, the materials for that piece are moved into inventory from your Satchel, Sack and Case. Only what that trade needs is moved, and only when there is room. At Monisette, Rem's Tales stored with her are withdrawn when a piece needs them.

Reforge always waits out the day. It never picks the option that spends beads to finish an upgrade instantly.

## Checking what you need

| Command | What it does |
|---|---|
| `//frg scan [job]` | Every upgradeable piece you own and whether its next step is ready |
| `//frg check <name>` | Full list for pieces whose name contains `<name>`: what you have, where it is, what's missing |
| `//frg check inv` | The same for every piece in your inventory |
| `//frg need [job]` | Shopping list of everything missing |
| `//frg gather` (or `//frg mats`) | In your Mog House: moves what the pieces in your inventory are short of out of the Mog Safes, Storage and Mog Locker |

- Add `inv` to `scan` or `need` to look only at pieces in your inventory, e.g. `//frg need GEO inv`.
- Add `slips` to include armor stored on storage slips.
- When an NPC can do several steps in a row (Aurix does +1 → +2 → +3), `scan`, `check` and `need` show all of them.
- `check` only tells you to move things Reforge can't move itself: the piece, materials in your Mog House or on a slip.

## Things to know

- **It stops if anything looks wrong:** Reforge only carries on when the NPC replies the way it expects: its menu names a piece of equipment (Ruspix's never say what he'll give back) and Coelestrox asks the normal bead fee. If anything else happens, it tells you in chat and stops without trading anything more. If the NPC's window is left stuck on screen, zoning clears it. What happened is saved in `data/menus.log`. A game update can cause this. If it does, opening an issue with what's in that file helps get it working again.
