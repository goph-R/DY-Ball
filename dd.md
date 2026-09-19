# DY-Ball — design document

What the game is made of. The source of truth for anything visual is
`design/arkanoid-6.jpg` (the reference sheet: three ships, the full pickup set)
and `design/arkanoid-6b.jpg` (the gameplay mockup). `arkanoid-6.jpg` reads top
to bottom as: the brick types, then an example level, then the pickups that
drop from bricks. Both files are exactly 720x1280,
so every figure here is in design units and maps 1:1 onto the coordinates in
`scripts/layout.lua`.

Measurements below were taken by pixel scan of those files, not estimated.

Atlas cell sizes: **bricks 60 x 30, pickups 40 x 40.**

## Screen

| Band | Design units |
|---|---|
| HUD panel | 0 – 274 |
| Hazard stripe (the panel's bottom border) | 254 – 270 |
| Play field | 280 – 1280 |
| Thumb strip (drawn affordance) | y 1147 – 1201, x 52 – 668 |
| Ship | 125 x 41, top at y 962 |
| Ball | radius 11 |
| Brick | 60 x 30, flush (pitch = size) |

The ship sits ~180 units above the thumb strip: the steering finger must never
cover it.

## HUD

Left to right: pause button, `SCORE`, `LEVEL`, and the **level goal** counter.

The goal counter is the level's win condition, shown as an icon plus progress:
in the mockup it reads `0/14` beside an orange brick, meaning *destroy 14
orange bricks*. The level is complete when the counter fills — not necessarily
when the field is empty. Each level names a brick type and a count.

## Controls

Two schemes, picked by the device rather than by the platform.

**Touch.** A relative slide inside a band at the bottom of the *screen*. The
finger drags the ship rather than being it: absolute would park the ship under
the thumb, where the player cannot see it. The band is measured against the
screen, not the field, because on a tall phone the field's bottom edge sits
above the thumb — and it is deliberately larger than the strip drawn in the
mockup, which is a hint rather than a hit box.

**Mouse.** The ship's centre follows the pointer's x directly, continuously,
with no button held and no zone. That is what a desktop player expects, and
the cursor is visible so nothing is hidden. Sensitivity does not apply —
absolute pointing has no gain to tune.

**Choosing between them.** By *hover*: a mouse emits moves with no button
held, a touch screen cannot. The first hover switches to mouse mode for good.
`platform` would be the obvious alternative and is not good enough — `"web"`
covers both a desktop browser and a phone browser, and the desktop host does
not set it at all. Hover also gets a mouse plugged into an Android device
right, which that host already reports.

Both mobile hosts park their cursor at -1e5 on touch release, exactly because
touch has no pointer-leave, so that synthetic move is filtered out before it
can be mistaken for a hover.

**One finger.** The mobile hosts are strictly single-pointer: Android handles
no pointer ids, the web host captures one pointer. So the steering finger is
the only one, which is why shooting is automatic and why the press that starts
a slide is also what frees a held ball. On a mouse, any click frees it, since
the ship is already tracking the pointer.

## Bricks

Every brick is **60 x 30** — a 2:1 tile — and they sit flush, so the pitch
equals the size. Ten columns fill x 60..660 across the field. The colours are
the original DX-Ball palette.

Eleven types, in the order the reference sheet lists them:

| # | Type | Hits | Notes |
|---|---|---|---|
| 1 | Metal | — | **Indestructible.** No damaged variant; it is never cleared and never counts toward the level goal |
| 2 | Green | 1 or 2 | |
| 3 | Teal | 1 or 2 | |
| 4 | Blue | 1 or 2 | |
| 5 | Purple | 1 or 2 | |
| 6 | Red | 1 or 2 | |
| 7 | Orange | 1 or 2 | |
| 8 | Yellow | 1 or 2 | |
| 9 | Rock | **3** | The only three-state brick. Very dark stone, then mid stone, then pale |
| 10 | Pink | 2 | **Hidden.** Invisible until the first hit reveals it; the second clears it |
| 11 | Bomb | — | Orange/yellow, stripes animate on a frame cycle. Detonating it removes the brick **and its four adjacent neighbours** |

### Damage states

A brick's art *is* its remaining hit count, so each destructible type ships one
sprite per state. The reference sheet stacks them with the most durable state
at the top and the about-to-break state at the bottom, so the bottom row reads
left to right as the full type list.

| Type | States |
|---|---|
| The seven colours | 2: plated (2 hits) above plain (1 hit) |
| Rock | **3**: very dark, then mid, then pale |
| Pink | 2, but the first is invisible — see below |
| Metal | 1, and it is never destroyed |
| Bomb | 1, animated |

Rock is the only three-state brick, and its extra state is the very dark one
sitting above the two rows on the sheet.

### The pink brick

A hidden brick, and deliberately annoying. It is **invisible** on the field
until something hits it — the first hit reveals it, the second clears it. Two
hits in total, but the player does not know it is there until they have spent
one of them.

### Bombs

**The blast.** A detonating bomb removes itself plus its four *adjacent*
neighbours — up, down, left and right. Not the whole row and column: one brick
in each direction.

```
        . X .
        X B X          B = the bomb, X = also removed
        . X .
```

Two things detonate it:

- Pickup **#4**, which sets off every bomb brick on the field at once.
- Pickup **#7**, which gives the ball the same blast on every bounce, turning
  any brick it hits into a bomb.

**Chains.** A blast that removes another bomb brick **detonates it too**, and
so on outward. One ball hitting one bomb in a dense cluster can therefore take
out a large part of the field, which is the point of them.

This makes removal a queue rather than a loop. Each brick is marked removed at
the moment it is *enqueued*, not when it is processed — otherwise a bomb
reached from two directions is detonated twice, and two adjacent bombs
enqueue each other forever.

**The animation.** The bomb's orange/yellow stripes cycle continuously, which
is what makes it readable at a glance among static bricks. On the original this
was palette rotation; that is not available here — the renderer draws textured
quads with no indexed colour anywhere in the pipeline — so the cycle has to be
**real frames in the atlas**, N tiles of 60x30.

Either packing works: N separate regions stepped by name, or one region spanning
the strip with `srcX` advanced by 60 per frame (`drawRegion` takes
`srcX/srcY/srcW/srcH`), which keeps it to a single entry in `assets.lua`.
`engine.animation` is tweens only — no frame-stepping helper — so the cycle is
a modulo timer the game owns. It is the only animated brick.

## Pickups

Pickups drop from bricks when they are hit. Fifteen types, falling as
**40 x 40** tiles. The tile colour is the whole legend:

- **Grey** — paddle size and ball count
- **Blue** — beneficial
- **Red** — harmful

Positions below are the tile's top-left corner in `design/arkanoid-6.jpg`,
where the set is laid out 3 columns x 5 rows on a 50-unit pitch. The tile
falling in the gameplay mockup is 40x40 too, so the sheet shows the in-game
sprites at 1:1.

| # | Pos | Tile | Icon | Effect |
|---|---|---|---|---|
| 1 | 24, 655 | grey | outward arrows | Grow the paddle |
| 2 | 74, 655 | grey | inward arrows | Shrink the paddle |
| 3 | 124, 655 | grey | three spheres | Triple balls |
| 4 | 24, 705 | blue | orange brick, arrows out | Detonate every bomb brick on the field |
| 5 | 74, 705 | blue | large sphere | Bigger ball |
| 6 | 124, 705 | red | small sphere | Smaller ball |
| 7 | 24, 756 | blue | meteor | Every bounce detonates: the brick and its four neighbours |
| 8 | 74, 756 | blue | field schematic | Next level |
| 9 | 124, 756 | red | skull | Death |
| 10 | 24, 807 | blue | paddle with turrets | Shooting ship |
| 11 | 74, 807 | blue | arrow through a field | Ball passes through bricks, removing them |
| 12 | 124, 807 | red | double chevron | Faster ball |
| 13 | 24, 858 | blue | paddle with sparks | Sticky ship — holds the ball (electric effect) |
| 14 | 74, 858 | blue | sphere with arcs | Slower ball |
| 15 | 124, 858 | red | bar with down arrow | Move every brick down one row |

By what they touch:

- **Paddle** — 1 grow, 2 shrink, 10 shooting, 13 sticky
- **Ball** — 3 triple, 5 bigger, 6 smaller, 7 explosive, 11 pass-through,
  12 faster, 14 slower
- **Field** — 4 detonate bombs, 8 next level, 15 bricks down
- **Life** — 9 death

### How they reach the art

Paddle width (1, 2) is a 9-patch stretch — that is what the `slice` metadata on
the ship regions is for, so grow and shrink cost no extra art. The three ship
kinds (normal, 10, 13) are three separate regions, which makes them mutually
exclusive by construction. Ball size (5, 6) steps between three authored
sprites: small, normal, big.

Shooting is **automatic** while held. The hosts are single-pointer and the one
finger is already steering, so there is no input left to fire with — see
`scripts/input.lua`.

### Ship modes replace each other

The ship is always in exactly one of three modes — normal, shooting (#10) or
holder (#13) — because it is one of three sprites. Picking one up while
another is active **switches to the new one**: take the holder while shooting
and the ship becomes a holder, losing the guns.

So a ship pickup is never wasted and never stacks. The most recent one wins.

## Open questions

Not yet decided; listed so they are decided on purpose rather than by whatever
the code happens to do first.

1. **Duration.** Are 10, 11, 12, 13, 14 timed, or do they last until the ball
   is lost? A timer needs a HUD indicator; until-ball-lost does not.
2. **Switching away from holder.** If the ship is holding a ball and a
   shooting pickup lands, the ball has to go somewhere — does it launch
   immediately, on the next press, or is the switch deferred until it is
   released?
3. **Clamping.** Ball size has three authored steps; what does 5 do at "big"
   or 6 at "small"? Same for the speed pair, 12 and 14.
4. **Triple balls.** Do ball modifiers apply to all three? Is a life lost when
   the first ball drops, or the last?
5. **Explosive ball (7).** One detonation, or every bounce until the ball is
   lost?
6. **Death (9).** It falls like any other pickup, so it has to be *dodged* —
   which conflicts with steering toward the ball. Intended?
7. **Bricks down (15).** What happens when the lowest row reaches the ship?
8. **Drops.** Which bricks drop pickups, at what rate, and how many may be
   falling at once?
9. **Bomb animation.** How many frames, and at what rate? It sets the atlas
   budget: at 60x30 each frame is cheap, but the count has to be chosen before
   the sheet is packed.
10. **Colour legend.** #2 shrinks the paddle — harmful — but is grey, while
   every other harmful pickup (6, 9, 12, 15) is red. Is grey a third category
   (size and count), or should #2 be red?
