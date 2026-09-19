-- Asset manifest.
--
-- Logical name -> file path for every game asset. Loaded at startup by
-- scriptLoadAssets (script.h), which walks each subtable and populates the
-- engine-side registries: SoundLibrary for `sounds`, MusicLibrary for `music`,
-- AssetRegistry for `textures`, UiFontLib for `fonts`.
--
-- Naming: keys are snake_case string IDs (that is the convention for every
-- name you type in quotes); paths are relative to the repo root.

return {
    -- 16-bit PCM WAV. A name may map to a list instead of a string, in which
    -- case soundPlay picks a random non-repeating variant:
    --   steps = { "assets/sounds/step1.wav", "assets/sounds/step2.wav" },
    sounds = {},

    -- Streaming Ogg Vorbis for musicPlay(name [, fade [, loop]]). Files open
    -- lazily on first play. Ship a .m4a sibling too if you target Safari.
    music = {},

    textures = {},

    -- Regions are named sub-rectangles of a texture — the unit drawRegion()
    -- draws. x, y, w, h are source-texture pixels. Pack many into one texture
    -- to make an atlas.
    --   logo = { tex = "ui", x = 0, y = 0, w = 256, h = 64 },
    regions = {},

    -- BMFont (AngelCode) bitmap fonts: a .fnt text file next to its RGBA PNG
    -- atlas. "default" is used when a drawText call names no font.
    --
    -- Leaving this empty is fine to start with — ui.h builds an 8x8 fallback
    -- font at init, so drawText works before you have any font art.
    fonts = {},
}
