# LUMI SLOT — DOPAGAKI in-game mini-game

Implementation: `scripts/lumi_slot.gd`, Godot 4 native port of the user-supplied `slot-machine_1 (2).html`. Ordinary Godot 4 controls cannot directly display browser HTML without an external WebView plugin.

## Controls and rewards

- Go to camp slot machine and press **E**.
- **Space** or **レバーON**: spend 25 in-game G. A replay grants the next bet free.
- **1/2/3** or **STOP 1/2/3**: stop reels in any order. Middle line only is valid.
- **E/Esc**: close, after all reels are stopped. Use settings 1–6 or toggle auto mode in the modal.
- Outcomes are drawn when starting the reel spin, not affected by stop timing.
- BIG: 240G plus LEGENDARY (10% of BIG outcomes upgrade to MYTHIC); REG: 96G plus EPIC.
- Grapes: 8G and 14% chance of RARE weapon; Cherry: 2G and 20% RARE armor chance; Replay: next spin free.
- Gear appears at the existing machine's prize collection platform, ready for E pick-up.
- Entirely fictional in-game currency: no buying G with cash, cash-out or redemption.

## Test instructions

1. Import `project.godot` in Godot Engine 4 and press F5; check the debugger for parse errors.
2. Open camp slot using E. Observe G balance and per-spin cost.
3. Start a spin and stop reels in any order. Verify outcome displayed after third stop only.
4. Verify game G is deducted at lever and payout credited once per round; check free replay.
5. Verify settings 1–6, auto mode, accumulated counts and difference-graph display.
6. Verify jackpots spawn items at the collection platform rather than under the machine.
7. Verify game restart cancels an active auto spin and resets modal state.

## Scope

This is a **native UI reproduction**, not the HTML file embedded in a browser. Layout and controls are similar, but the CSS animation, Chart canvas and synthesized WebAudio are not pixel-perfect; Godot uses its own interface/visuals and existing audio cues. Headless Godot validation and F5 runtime confirmation remain necessary.
