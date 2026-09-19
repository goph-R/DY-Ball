# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

DY-Ball, a DX-Ball style brick breaker for portrait phones (desktop too). The engine — the C host, the build
fragments, the Lua engine modules — lives in `../SOOB-Core`. This repo holds
only per-game files: `app.lua`, `config.lua`, `assets.lua`, `scripts/`,
`assets/`, and three-line build files. The Android player lives in
`../SOOB-Core-Android`; `android/` here is only the APK's identity.

**Read `../SOOB-Core/CLAUDE.md` first** — it owns the coding conventions, and
`../SOOB-Core/SOOB-Lua.md` is the binding reference.

## Where things live

- `main.cpp` is 3 lines of code: it calls `soobRun()` from
  `../SOOB-Core/soob_main.h`. Do not reintroduce a per-game host loop. If a
  game needs native Lua bindings, use `SoobApp.onRegister` — documented in
  `main.cpp` itself.
- `Makefile`, `CMakeLists.txt` and `build_win10.bat` delegate to
  `../SOOB-Core/build/`. Change the shared fragment, not the stub.
- `build.bat` (Win98) is deliberately a full per-game copy — COMMAND.COM
  cannot safely `call` a shared script. It is **goto-only: no `setlocal`, no
  quoted `set`, no parenthesised if-blocks**. Its one per-game line is
  `set NAME=`.
- `scripts/engine/` is **generated** — copied from SOOB-Core on every build and
  gitignored. Never edit it here; fix the source in SOOB-Core.
- `scripts/view.lua` owns the coordinate system. The play field is a fixed
  720x1280 box fitted into the engine's fixed-height/extend-width canvas.
  **All game code is written in design units** and calls `view.x/y/len` at draw
  time; `view.toDesign` is the inverse, needed because the hosts report pointer
  positions in virtual coords. Do not introduce raw virtual coordinates into
  game logic — the single exception is the steering zone in `input.lua`, which
  is screen-relative on purpose (on a tall phone the field's bottom edge sits
  above the thumb).
- `scripts/input.lua` is single-pointer by necessity, not by choice: neither
  mobile host reports a second finger. Do not add a gesture that needs one.
  Shooting is on a timer and a stuck ball is freed by the same press that
  begins a slide, both for this reason. It also computes its own deltas from
  the absolute x — `onMouseMove`'s `dx` comes from `PointerEvent.movementX` on
  web, which iOS Safari leaves at 0 for touch.
- `android/` is an APK wrapper, not a port. It has **no Kotlin and no C**: the
  host, the JNI bridge and Lua all come from `../SOOB-Core-Android` through the
  `includeBuild` in `android/settings.gradle`. The build logic lives in that
  repo's `gradle/soobApp.gradle` and `gradle/syncGame.gradle` — change the
  shared fragment, not the stub, exactly as with `Makefile` and `CMakeLists.txt`.
  The one per-game line is `def appId` in `android/app/build.gradle`; everything
  else a game sets (label, colour, orientation, save file) comes from `app.lua`.
- `android/app/src/main/assets/` is **generated** by the `syncGame` task —
  the bundle plus SOOB-Core's `scripts/engine` — and gitignored. Never edit it.

## Build and verify

```sh
make                                    # needs libsdl1.2-dev, libopenal-dev
env ALSOFT_DRIVERS=null timeout 1.5 ./<bin> -windowed > /tmp/out 2>&1
```

Two things matter in that incantation. `ALSOFT_DRIVERS=null` is required
because OpenAL has its own backend chain independent of SDL — without it
`sndInit` fails and the process exits before Lua ever loads. And stdout must
go to a **file**: piping to `head` loses the buffer when `timeout` sends
SIGTERM, so you see nothing even though the run was fine.

A clean boot prints `Renderer:`, `Resolution:`, `VSync:`, the font atlas line,
`opt: persistence at ...`, `script: Lua 5.1 initialised`, each asset's load
line, then the `assets: N sound(s), ...` summary. A Lua traceback after
`script:` is a real error.

This confirms syntax, `require` resolution and asset registration — which
covers most refactor regressions. It cannot check colours, layout or animation
timing; those need the dev box.

For the Android wrapper, a configuration-only check catches most breakage
without a device or an NDK compile:

```sh
cd android && ./gradlew :app:tasks     # resolves the composite build
```

A full `:app:assembleDebug` needs SDK 36 + NDK 29. The C half can also be
booted against this bundle without a phone, from
`../SOOB-Core-Android/tools/hosttest`: `./host_test.exe ../../../<this repo>`.
It reports `FAIL textures/regions/fonts/sounds registered` for an assetless
bundle — that is the harness expecting Find5's content, not a fault here.

## Constraints

- **No C++11.** Dev-C++ 4.x ships GCC 3.4: no `auto`, no `nullptr`, no
  range-for. C-style `NULL`, explicit types, `malloc`/`free`.
- **No shaders.** Fixed-function GL only; minimum GPU is a GeForce 4 MX 440.
- **Assets are relative-pathed.** No `chdir`, no absolute asset lookups.
- **Header-only modules with `static` functions** — one TU per target.
