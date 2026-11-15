# Butt Nugget

A mushroom, a chicken launcher, and a dungeon full of enemies. Eggs gain damage with each wall bounce. Choose one upgrade between waves and face the Dark Knight on wave 10.

## Open the game in Godot

Import [project/project.godot](project/project.godot) in Godot 4.7.2, open the project, and press **F5**.

Use **WASD or arrow keys** to move, aim with the **mouse**, and hold **left click** to fire. **Esc** pauses. **F8** opens wave select.

## Repository contents

| Location | Contents |
| --- | --- |
| `index.html` and `index.*` | Playable browser build |
| `project/project.godot` | Editable Godot project |
| `project/scenes/` | Main game, player, chicken launcher, eggs, effects, and arena |
| `project/scripts/` | Movement, combat, waves, upgrades, and interface |
| `project/art/characters/` | Mushroom, chicken, enemies, bosses, animations, and shaders |
| `project/art/projectiles/` | Egg flight and shell-crack frames |
| `project/art/audio/` | Sound effects and music |
| `project/art/mossvault/` | Dungeon tiles and credits |
| `project/art/toffeecraft/`, `project/art/kenney/`, `project/art/ui/` | Interface and earlier prototype artwork |
| `project/art/fonts/` | Fonts and their licenses |
| `project/art/archive/` | Original source artwork and earlier asset versions |
| `project/tests/` | Godot gameplay checks |
| `project/tools/` | Asset and audio generation utilities |
| `project/docs/` | Asset sources and game jam disclosure |

## Play the browser build locally

From the repository folder, run `python3 -m http.server 8000 --bind 127.0.0.1`, then open `http://127.0.0.1:8000`.

The root contains the static files for GitHub Pages. In the repository's Pages settings, select deployment from `main` and `/(root)`.

## Rebuild and test

In Godot, choose **Project → Export → Web → Export Project** and export to `project/dist/web/index.html`. Copy the contents of that output folder to the repository root to update the browser build.

Run `godot --headless --path project --script tests/run.gd` for the gameplay checks.

See the [project guide](project/README.md) and [game jam disclosure and credits](project/docs/JAM_DISCLOSURE.md) for asset sources, modifications, and AI assistance. Each third-party asset keeps its applicable license and credits.
