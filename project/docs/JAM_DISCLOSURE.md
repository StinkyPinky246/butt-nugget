# Butt Nugget · Game jam disclosure

## Copy-ready submission text

> I supplied the game design brief and asset kit and directed the gameplay and polish revisions. I used OpenAI Codex to implement and test the Godot game, build the interface and effects, write the pixel-art and audio generators, and package the builds. The current mushroom, chicken, egg, and shell sprites came from the supplied bounce-game--main (2) archive. The chicken and egg packs include generation prompts. Codex cleaned their frames, recolored and resized the chicken, mirrored the egg so its wider end leads, and integrated the animations into Godot. The menus use ToffeeCraft’s Retro UI assets, the multiplier gems come from ToffeeCraft’s Mega Bundle, and the hearts and reticle come from Kenney’s CC0 packs. The arena loop and sound effects were synthesized from code. The boss music is Ritual by Of Far Different Nature, licensed under CC BY 4.0. Zerie supplied the original two enemy sprites. The four additional enemy packs came from the supplied bounce-game--main archive and include generation prompts. Codex prepared their frames for Godot and programmed their behavior. The Skull Boss uses seven supplied Piskel frames. Codex adapted the Dark Knight’s supplied sweep, rising slash, overhead slam, hurt, and death frames for the wave 10 boss fight. The prototype used AI-generated art from the supplied asset kit. The current arcade build lets the player choose one free upgrade after each wave. Ball returns and the multiplier field are disabled. The menus use Barlow Semi Condensed by Jeremy Tribby, and the score uses Pixelify Sans by the Pixelify Sans Project Authors. The arena uses LeewayStudio’s Mossvault tiles, which the artist describes as deterministic pixel geometry made with Python/Pillow, with AI assistance on code and documentation.

## What went into the build

| Part | Source and changes | Editable location |
| --- | --- | --- |
| Game rules | Supplied GDD v3.1 and later direction. The current build uses mixed enemy waves, distance-checked spawn warnings, one free upgrade choice between waves, bank shots, hit markers, and scoring. Return, upgrade draft, and multiplier code is retained behind Inspector switches. | `scenes/`, `scripts/`, `tests/` |
| Player | Two supplied mushroom designs used as idle, walk, and hurt poses. | `art/characters/mushroom/`, `scenes/player.tscn` |
| Fast enemies | Zerie's Demon_A. | `art/characters/`, `scripts/enemy.gd` |
| Skull Boss | Seven supplied Piskel frames from the neighboring bounce-game--main download. Godot plays the frame animations and handles damage and the death fade. | `art/characters/skull/`, `scripts/enemy.gd` |
| Basic enemies | Zerie's Blood Monster_A. The character shader adds a dark outline, while hit flashes and death effects are driven by Godot. | `art/characters/`, `scripts/enemy.gd` |
| Four new mobs | Horned Slime, Flying Trident, Dark Knight, and Armored Tank came from the supplied archive, which includes new enemy generation prompts. Codex embedded cleaned 64-pixel frame atlases, adjusted animation timing, and wired windup and strike logic. | `art/characters/mobs/`, `scripts/enemy.gd`, `scripts/wave_manager.gd` |
| Dark Knight boss | The existing supplied Knight atlas powers the wave 10 boss. Godot telegraphs sword reach, times hits to the attack frames, and plays a synthesized swing sound. | `art/characters/mobs/dark_knight/`, `scripts/enemy.gd`, `scripts/wave_manager.gd` |
| Launcher | Eight supplied chicken firing frames, cleaned, recolored to teal, and timed for the shot. The tail follows the aim and marks where the egg appears. | `art/characters/chicken/`, `scenes/weapon.tscn` |
| Projectile and impact | Three supplied egg flight frames and five shell-crack frames. Godot rotates the wide end into the flight direction, animates squash on ricochets, and draws live damage numbers. The crack animation plays on enemy hits. | `art/projectiles/`, `scenes/ball.tscn`, `scenes/egg_impact.tscn` |
| ×2 field | A dashed strip drawn in Godot with ToffeeCraft gem endpoints. It moves during combat and recharges after splitting a shot. | `scenes/multiplier_wall.tscn` |
| Arena | LeewayStudio’s 32 px Mossvault atlas painted into Godot as an editable TileMapLayer. Four continuous wall colliders follow the inside edge of the stone rims. | `art/mossvault/`, `scenes/arena.tscn`, `scripts/arena.gd` |
| UI and effects | Codex assembled the menus and wired the Godot Controls. The Retro UI and multiplier gem are from ToffeeCraft. The hearts and crosshair are from Kenney. The upgrade picker draws up to three text-only cards from five upgrades and prioritizes upgrades absent from recent menus. It uses Barlow Semi Condensed. | `art/toffeecraft/`, `art/kenney/`, `scripts/art.gd`, `scripts/hud.gd`, `scripts/upgrade_menu.gd` |
| Music and sound | One 16.64-second original synthesized chip loop and 12 original synthesized sound effects. The generator contains the notes and oscillator parameters. | `art/audio/`, `tools/generate_presentation.py` |

## Third-party credits

- Music: [Ritual by Of Far Different Nature](https://fardifferent.bandcamp.com/track/ritual-2), from [ANOTHER STEP BACK](https://fardifferent.bandcamp.com/album/another-step-back), under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The game uses the supplied MP3, with volume and looping set in Godot. Credit appears on the title screen and in the exported project.

- [Mossvault Dungeon Free v0.2.0 by LeewayStudio](https://leewaystudio.itch.io/mossvault-dungeon-free). The atlas and adapted TileSet are used in the arena. The included license allows distribution as part of the finished game and prohibits redistributing the atlas as a standalone asset or public source template. See `art/mossvault/LICENSE.md`.

- [ToffeeCraft's UI User Interface Pack – Retro](https://toffeecraft.itch.io/ui). The menu uses game-ready crops of the published `Freebuttons.zip` from `ClassicalButtons.png` and `LongButtons2.png`. The six crops are in `art/toffeecraft/retro/`. The full set is available from ToffeeCraft.
- [Pixelify Sans by the Pixelify Sans Project Authors](https://github.com/eifetx/Pixelify-Sans). The score uses this font under the SIL Open Font License, included in `art/fonts/pixelify/`.
- [Barlow Semi Condensed by Jeremy Tribby](https://tribby.com/fonts/barlow/). Medium and Bold are bundled with their SIL Open Font License under `art/fonts/barlow/`.

- [ToffeeCraft's Forest, Cat, UI & Animals Mega Bundle](https://toffeecraft.itch.io/mega-bundle-forest-cat-user-interface-animals). The active build uses the multiplier gem from `MegaPackFree.zip` → `UIBundleFree/freefantasy.png`. ToffeeCraft permits use in games and prohibits standalone redistribution. The editable project contains the integrated crops and a credit file. The complete download is available from ToffeeCraft.

- Kenney artwork for the interface. The health icons are 16 px adaptations from [New Platformer Pack](https://kenney.nl/assets/new-platformer-pack). The resized reticle comes from [Crosshair Pack](https://kenney.nl/assets/crosshair-pack). The packs are CC0 and the included notices are in `art/kenney/`.
- UI references for this revision include [Downwell by Moppin](https://store.steampowered.com/app/360740/Downwell/) and the [Celeste control prompt guidance](https://www.celestegame.com/changelog.html).

- [Tiny RPG Character Asset Pack 02 by Zerie](https://zerie.itch.io/tiny-rpg-character-asset-pack-02). The pack allows use and modification in games. Its terms restrict redistributing the art as assets. Use the compiled player build for public submission and keep the editable source kit for your own project work.
- Bounce Back Godot Asset Kit. Its README identifies the prototype launcher, orb, heart, and multiplier wall as AI-generated. Those prototype textures are saved locally in `art/archive/`, which is excluded from the playable exports. The archive also includes the earlier menu copy of Pixelify Sans and its license.

The jam's specific rules were not provided. The disclosure above describes the work on this project and can be pasted into the jam's own form.

## How the game is wired

- `game.gd` ties together the main scene, aiming and shot timing, scoring, the upgrade draft, and game-over/restart. Firing spawns independent eggs and plays the chicken animation.
- `ball.gd` sweeps a circle along its flight path, reflects velocity from the collision normal, and changes the damage label when damage increases. The ×2 field angles both shots apart and gives the copy half damage. It spends one charge per split, then reappears elsewhere. Both faces work, and the player can walk through it. In return mode the ball flies directly toward the player’s current position, passes through enemies and the multiplier field, and awards five points on contact.
- `wave_manager.gd` schedules enemy spawns and tracks the remaining count. `enemy.gd` handles chase movement, hit knockback, HP, and death. The HUD shows the elite's HP and the upgrade draft opens when the wave clears.
- `hud.gd` draws the combat status and crosshair and animates falling hearts. `upgrade_menu.gd` renders upgrade choices, levels, and availability. `art.gd` contains the shared palette, button styles, and font.
- `art/audio/` includes `shot`, `bounce`, `split`, `hit`, `death`, `coin`, `return`, `hurt`, `buy`, `clear`, `over`, and `knight_swing` one-shots. `arena_loop.wav` is the separate music bed.
