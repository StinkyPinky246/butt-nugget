# Butt Nugget

A 1280 × 720 arcade shooter for Godot 4. Open `project.godot` and run the main scene.

- **WASD or arrow keys** move. **Mouse** aims. **Hold left mouse** to fire. **Esc** pauses.
- **F8** opens Wave Select. Enter a wave from 1 to 9999 to start a fresh run there. **Esc** closes it.
- Each wall bounce adds one damage. Watch the live damage number on the egg. The wide end leads into every shot and ricochet. Wall banks keep the shell intact. Enemy hits play the shell-crack effect beside a white hit marker that turns gold for a kill.
- Wave one has 15 mobs. Six more are added each wave until the cap. The Skull Boss appears on every fifth wave, with the Dark Knight taking its place on wave 10. The Knight telegraphs a sweep, rising slash, and overhead slam. Pick one free upgrade from up to three randomized cards after each wave. The draft prioritizes upgrades absent from recent menus. Extra Ball adds two shots, Power adds starting damage, Bounce Boost adds damage on wall bounces, Quick Shot shortens the firing interval, and Patch Up restores one heart.
- To bring back the optional features, open scenes/game.tscn, select **Game**, then find **Optional Mechanics** in the Inspector. Upgrades are on. Returns and the Multiplier are off.
- Enemies arrive at amber markers at least 410 pixels from you. If you approach a marker before it activates, it relocates. Horned Slimes and Flying Tridents appear on wave one, Dark Knights on wave two, and Armored Tanks on wave three.

## Desktop packages

Extract the Windows ZIP and run **Butt Nugget.exe**. The macOS ZIP contains a separate universal app. Export presets target Windows x64 and macOS. To rerun the integration checks after importing the project, use `godot --headless --path . --script tests/run.gd`.

## Web build

Upload `Butt Nugget-Web.zip` as an **HTML** project on itch.io and mark it **This file will be played in the browser**. Keep `index.html` and the other export files together at the ZIP root. The game uses a keyboard and mouse. Click inside the game if the page has keyboard focus. Use a 16:9 embed, such as 960 × 540, or choose fullscreen launch.

To rebuild, use **Project → Export → Web → Export Project** in Godot and save as `dist/web/index.html`. The preset uses the single-threaded template. To preview locally, run `python3 -m http.server 8000 --bind 127.0.0.1 --directory dist/web` from the project folder and open `http://127.0.0.1:8000`.

## Credits

- Skull Boss animation uses the seven supplied Piskel frames from the neighboring bounce-game--main project.
- Boss music: [Ritual by Of Far Different Nature](https://fardifferent.bandcamp.com/track/ritual-2), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The original MP3 loops during the fight.
- The mushroom hero, chicken launcher, egg flight, and shell crack come from the supplied `bounce-game--main (2).zip`. The chicken and egg packs include generation prompts and Piskel sources. Enemy animations include work from [Zerie, Tiny RPG Character Asset Pack 02](https://zerie.itch.io/tiny-rpg-character-asset-pack-02). The pack’s terms apply to its character art.
- The menus use ToffeeCraft’s Retro UI buttons and tiles, and the multiplier gems come from ToffeeCraft’s Mega Bundle. The hearts and reticle are from Kenney’s CC0 packs. The menus use Barlow Semi Condensed by Jeremy Tribby. The earlier AI-generated kit textures are archived in `art/archive/`.
- Arena tiles by LeewayStudio from [Mossvault Dungeon Free](https://leewaystudio.itch.io/mossvault-dungeon-free). Effects, sound effects, and music were made for this project.

## Jam edit kit

- Open `scenes/game.tscn` for the main scene. Press **F5** to play. Use **Remote** in the Scene panel during play to inspect live enemies, balls, HUD, menus, and effects.
- Open `scenes/player.tscn`, `scenes/weapon.tscn`, `scenes/ball.tscn`, or `scenes/egg_impact.tscn` and open the AnimatedSprite2D’s **SpriteFrames** to preview and edit each animation. The live PNGs are in `art/characters/mushroom/`, `art/characters/chicken/`, and `art/projectiles/`. The unpacked chicken and egg source files are in `art/archive/chicken_update/`.
- `art/toffeecraft/` contains the game-ready menu and gem crops with source credit. `art/kenney/` contains the HUD and shop icons with license notices. `art/ui/` contains earlier prototype icons. `art/characters/` contains the animation strips and the outline shader. `art/audio/` contains each sound and the music loop. Select an imported sound in Godot to preview it.
- Edit `tools/generate_presentation.py` and run it with Python 3 to regenerate the legacy pixel sprites, icons, launcher frames, music, and sound effects. To paint the arena, open `scenes/arena.tscn` and select **DungeonTiles**. The outer ricochet bounds are set in `scripts/arena.gd`. The HUD, menus, and effects are editable in the Godot scripts.
- See [the game jam disclosure](docs/JAM_DISCLOSURE.md) for credits, asset sources, and copy-ready submission text.

- [Character pack shortlist and sprite swap guide](docs/CHARACTER_ART.md).
