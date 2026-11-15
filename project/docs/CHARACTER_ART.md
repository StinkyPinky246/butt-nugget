# Character art options

**Best match for the current game:** [Pixel Crawler by Anokolisa](https://anokolisa.itch.io/free-pixel-art-asset-pack-topdown-tileset-rpg-16x16-sprites). This free top-down pack has heroes and skeleton and orc enemies in a shared 16 × 16 style. The creator lists idle, walk or run, and death animations, and marks the pack as made without generative AI. A hero and two enemy silhouettes from one set would fit the wooden fantasy UI. See the creator’s linked terms before using assets in a release.

**Simplest source to build from:** [16x16 DungeonTileset II by 0x72](https://0x72.itch.io/dungeontileset-ii). CC0 pixel dungeon art with animated characters and monsters in a common palette. Use it if you want to mix and adapt assets alongside your own pixel art.

**Cozy direction:** [ToffeeCraft's Forest, Cat, UI & Animals Mega Bundle](https://toffeecraft.itch.io/mega-bundle-forest-cat-user-interface-animals). It shares an artist with the installed Retro UI and includes animated cats and animals. The free ZIP has samples with limited animation coverage. The artist lists the more extensive animation sets as part of the full bundle. A cat hero with animals as opponents would shift the tone of the current dungeon game.

## Replacing the working sprites in Godot

The mushroom player uses the two supplied mushroom poses. Two enemy types use Zerie animations. The wave 10 Dark Knight uses the imported Dark Knight attack frames in `art/characters/mobs/dark_knight/animations.tres`. The Skull Boss uses editable SpriteFrames in art/characters/skull/skull_boss.tres, built from the seven supplied Piskel frames. Open `scenes/player.tscn`, select **Character**, and edit its **SpriteFrames** resource. Keep the `idle`, `walk`, and `hurt` animation names. The weapon and its aiming are configured separately in `scenes/weapon.tscn`.

Godot currently loads the basic and fast enemy strips from `art/characters/` through `scripts/art.gd`. Keep the `idle`, `walk`, `hurt`, and `death` suffixes when replacing strips. Each current strip uses 32 × 32 padded cells. For your own 16 × 16 art, center a frame in each padded cell or update the atlas cell size to match your source. Align feet across frames and preview at nearest-neighbor filtering before changing hitbox sizes.

The four supplied mobs have their own editable SpriteFrames resources in `art/characters/mobs/`. They use 64 × 64 atlas cells.
