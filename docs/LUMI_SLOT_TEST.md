# LUMI SLOT — DOPAGAKI in-game mini-game

Implementation: `scripts/lumi_slot.gd`, Godot 4 native port of the user-supplied `slot-machine_1 (2).html`. Ordinary Godot 4 controls cannot directly display browser HTML without an external WebView plugin.

## Controls and rewards

- Go to camp slot machine and press **E**.
- **Space** or **レバーON**: spend 25 in-game G. A replay grants the next bet free.
- **1/2/3** or **STOP 1/2/3**: stop reels in any order. Middle line only is valid.
- **E/Esc**: close, after all reels are stopped. Toggle auto mode in the modal. The slot is permanently locked to setting 6; the player cannot select odds.
- Outcomes are drawn when starting the reel spin, not affected by stop timing.
- Bonus draw (fantasy game odds): **setting 6 only**, BIG 1/17 and REG 1/6.2; combined about **1/4.54**. No setting selector is displayed.
- BIG: **160G + guaranteed EPIC-or-better weapon**. EPIC 74%, LEGENDARY 23%, MYTHIC 3% of BIG wins.
- REG: **60G + one equipment drop**. COMMON 75%, RARE 22%, EPIC 3% of REG wins; 55% weapons / 45% armor.
- Grapes: 8G and 14% chance of RARE weapon; Cherry: 2G and 20% RARE armor chance; Replay: next spin free.
- The 25G entry fee remains unchanged. Bonus cash payouts were reduced from the original simulator to keep in-game gold generation controlled now that bonuses are much more common.
- Gear appears at the existing machine's prize collection platform, ready for E pick-up.
- Entirely fictional in-game currency: no buying G with cash, cash-out or redemption.

## Test instructions

1. Import `project.godot` in Godot Engine 4 and press F5; check the debugger for parse errors.
2. Open camp slot using E. Observe G balance and per-spin cost.
3. Start a spin and stop reels in any order. Verify outcome displayed after third stop only.
4. Verify game G is deducted at lever and payout credited once per round; check free replay.
5. Verify there is **no setting selector**, the bonus display is fixed to BIG 1/17 / REG 1/6.2, and auto mode, accumulated counts and difference-graph display work.
6. Verify jackpots spawn items at the collection platform rather than under the machine.
7. Verify game restart cancels an active auto spin and resets modal state.

## Scope

This is a **native UI reproduction**, not the HTML file embedded in a browser. Layout and controls are similar, but the CSS animation, Chart canvas and synthesized WebAudio are not pixel-perfect; Godot uses its own interface/visuals and existing audio cues. Headless Godot validation and F5 runtime confirmation remain necessary.
