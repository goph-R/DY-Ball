/* SOOB Template — entry point.
 *
 * Everything the game does lives in Lua (scripts/main.lua) and in the
 * manifests beside it: app.lua (identity), assets.lua (content), config.lua
 * (display). The whole C host — SDL/GL boot, the 2D frame loop, audio,
 * screenshots, shutdown — is soobRun() in ../SOOB-Core/soob_main.h.
 *
 * Two knobs live here and nowhere else, both compile-time by nature:
 *
 *   UI_VIRTUAL_H  Virtual canvas height. The default 480 matches a 640x480
 *                 design target, so one source pixel maps to one virtual unit
 *                 at the reference resolution. Uncomment and change it if your
 *                 art is drawn to a different scale; everything else in the
 *                 renderer derives from it.
 *
 *   SoobApp       Native Lua bindings, if this game needs any. Pure-Lua games
 *                 pass 0 and never touch it:
 *
 *                     static void reg(ScriptSystem *s) {
 *                         lua_register(s->L, "myThing", scrMyThing);
 *                     }
 *                     SoobApp app = soobAppDefaults();
 *                     app.onRegister = reg;
 *                     return soobRun(argc, argv, &app);
 */

/* #define UI_VIRTUAL_H 540.0f */

#include "soob_main.h"

int main(int argc, char *argv[])
{
    return soobRun(argc, argv, 0);
}
