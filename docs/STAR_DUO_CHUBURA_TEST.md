# v0.22 Star Duo / Chubura Revival / HUD — Acceptance Test

## Enemy: Star Duo
- The user-designed pair (star head + triangle head, neon purple/cyan) appears as a **single linked enemy** from WAVE 3.
- It has one shared HP bar and collision body, ~21 base HP (scales per wave).
- When approaching, the triangle fighter winds up and dashes. The star partner releases two purple magic projectiles at range, on cooldown.
- The sprite is embedded in `scripts/star_duo_art.gd` as an indexed transparent PNG (8 x 32px frames), generated from the supplied sheet, and decoded on game initialization.
- Verify in-game that sprites are actually loaded, visible and proportional. Test attack, hit and death. Manual gameplay and visual tests are separate from CI.

## Chubura
1. Start a game: Chubura has 65/65 HP, displayed above the rabbit and in the [T] pet menu.
2. Outside a camp, leave her near hostiles. Some enemies target Chubura and collision/projectiles lower her HP.
3. Picking her up protects her from normal damage. Camp is also safe.
4. At 0 HP she disappears, stops fighting/eating, and leaves a pink heart `ちゅぶらの命 [E]`.
5. Approach the heart and press E. Go to the moon shrine in the south-east and press E to revive to 75% HP. Pet equipment, affection, hunger remain.
6. Repeat with Mint also down: both souls can be collected, and both revived in one press E at the same shrine.
7. Reset the game and confirm pet HP and soul state reset.

## HUD
- No large Ookami or bunny medallion overlaps the top left labels.
- The hero status occupies the first row; MP/XP occupies the second; Mint HP/XP uses the third.
- Phase and skill labels still work, and Chubura's HP is shown near her in-world character, avoiding extra top HUD clutter.

## Safety
- Do not change the existing GitHub protection / CI settings.
- Require PR Godot Validation to pass (import and short headless startup).
- Full combat, soul recovery and HUD readability require a manual on-screen test.
