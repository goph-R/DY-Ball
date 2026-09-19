-- app.lua — who this game is. Read by every SOOB-Core host.
--
-- The single place a game names itself. The desktop build titles its window
-- and picks its per-user save path from this; the web build feeds its <title>,
-- its PWA manifest and its localStorage key from it; the Android player names
-- its options file and picks its screen orientation from it. Nothing else is
-- per-game — assets live in assets.lua, display settings in config.lua.
--
--   name        window title / app label / PWA name
--   id          persistence stem: <id>.dat, and the localStorage key on web
--   orientation "landscape" | "portrait" — honoured by the mobile hosts;
--               desktop ignores it (config.lua sizes the window there)
--   description one line, used by the web app manifest
--   background  "#rrggbb" clear colour, used by all three hosts

return {
    name        = "DY-Ball",
    id          = "dyball",
    orientation = "portrait",
    description = "A DX-Ball style brick breaker, in portrait.",
    background  = "#14141f",
}
