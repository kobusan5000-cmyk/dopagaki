# Ninja umbrella art integration (v0.21)

- Source: original user-supplied ninja concept (black bob, single braid, crimson eyes and ribbons, black-and-red outfit and Japanese umbrella).
- In-game atlas: `assets/characters/ninja_actions.png` (384x48, 8 frames, 48x48 each, transparency). These frames are simplified for game display from the original illustration.
- Frames: 0 = portrait/front, 1 = walk, 2 = back, 3 = side, 4 = umbrella idle, 5 = umbrella slash, 6 = dodge/dash, 7 = ninjutsu.
- The ninja (`class_id == 6`) replaces the old wolf+headband rendering; other jobs are not changed.
- The ninja shadow clones use the same sprite, with transparent crimson tint; no changes to the actual kunai/projectile effects or healing mechanics.
- Q = existing shadow clone ninjutsu with a brief visual animation. Jump uses the dodge pose; attacking uses the slash pose. No new keybindings.

## Manual play checklist
1. Select ninja (7) and check the ninja portrait appears in the class selection menu.
2. Enter the game, stand still: black-red ninja holds a parasol.
3. Move WASD/arrow keys, try up and left/right directions. Check the frame switches without clipping.
4. Leave the safe camp and attack with kunai: ninja displays slash action pose; damage and hits remain as before.
5. Press Space: dodge pose appears while the original jump mechanic remains unchanged.
6. Level to 5 and use Q: ninjutsu frame appears, clones have ninja art and still throw kunai.
7. Change weapons, equip gear, switch to other classes after restart. Original gameplay must continue to work.
8. Check that the PNG is crisp, feet positions match the ground and no magenta/black box appears around the characters.

## Validation limits
Headless Godot smoke testing verifies import, parse and initial scene start, not all gameplay actions or the exact visual presentation. Review the in-game look on Windows before considering the visuals final.
