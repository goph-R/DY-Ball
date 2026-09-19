-- layout.lua — the design, in numbers.
--
-- Every constant here was measured off design/arkanoid-6b.jpg by pixel scan,
-- not eyeballed. That mockup is exactly 720x1280 and therefore 1:1 with the
-- design units the whole game is written in, so these figures are what the art
-- actually does. When the design moves, move it here and nowhere else.

local M = {}

-- HUD. The panel runs from the top edge down to the hazard stripe, which is
-- its bottom border rather than a separate element.
M.HUD_H    = 280   -- panel occupies 0..274
M.HAZARD_Y = 254
M.HAZARD_H = 17

-- Play area: between the HUD and the bottom edge of the design box.
M.FIELD_TOP    = M.HUD_H
M.FIELD_BOTTOM = 1280

-- Bricks are always 60x30 — a 2:1 tile — and sit flush, so the pitch equals
-- the size in both axes. Ten columns fill x 60..660, which is exactly what the
-- reference row in arkanoid-6.jpg does (its 1-hit row spans x 60..659).
M.BRICK_W, M.BRICK_H = 60, 30
M.PITCH_X, M.PITCH_Y = 60, 30
M.COLS   = 10
M.GRID_X = 60      -- 60 .. 660, equal 60-unit margins either side
M.GRID_Y = 365     -- first brick row in the mockup

-- Ship. All three variants are 125 wide; the art box is y 962..1002. The body
-- surface sits about 10 units below the art top — that is the line the ball
-- should bounce off, not the top of the sprite.
M.SHIP_W, M.SHIP_H = 125, 41
M.SHIP_Y     = 962
M.SHIP_INSET = 10

M.BALL_R = 11      -- 21 units across in the mockup

-- Ball speed, in design units per second. It is 692 units from the underside of
-- the HUD (FIELD_TOP) to the ship's surface, so the straight-down traverse runs
-- 1.38s at the base speed and 0.49s at the cap. Angled shots take longer.
--
-- The ramp keys off PADDLE HITS, not wall-clock. A time ramp keeps
-- accelerating while the holder ship has the ball stuck to it, so stalling
-- banks free speed and thinking is punished; hits also pause by themselves
-- between lives. See dd.md, "Ball speed".
--
-- The RATIOS come from DX-Ball 2, which documents its internal speeds: the
-- ball starts at 13, accelerates naturally to 18, and Slow Ball floors it at 9.
-- So the natural ramp is only 1.38x across a level and the slow floor is 0.69x
-- of base -- far gentler than it feels while playing. Base speed is ours to
-- pick (it sets the scale); the ratios are not guesses.
M.BALL_SPEED      = 500     -- at the start of a level; 1.38s straight traverse
M.BALL_SPEED_MAX  = 700     -- 1.38x, the natural cap; 0.99s traverse
M.BALL_SPEED_GAIN = 1.005   -- compounding per paddle hit; ~70 hits to the cap

-- Pickups 12 (faster) and 14 (slower) multiply the ramped speed rather than
-- replacing it, so they are felt at any point in a level. The product is
-- clamped to these: the floor is DX-Ball 2's 0.69x Slow Ball limit, and the
-- ceiling sits above the natural cap so a Fast Ball still does something once
-- the ramp has plateaued.
--
-- DX-Ball 2 also has a threshold at 1.62x of base (~810 here) where the ball
-- gains a particle trail and one-shots multi-hit bricks. Not implemented; a
-- good thing to steal later.
M.BALL_SPEED_FLOOR   = 350   -- 0.69x
M.BALL_SPEED_CEILING = 900

-- How far off vertical the ball leaves the ship when struck at its very edge.
-- 1.05 rad is about 60 degrees; higher makes the ship steer more and the
-- rallies wilder.
M.BALL_MAX_ANGLE = 1.05

-- Angle the ball leaves at when released from the ship, as a fraction of
-- BALL_MAX_ANGLE. Not zero: straight up comes straight back down onto a ship
-- that has not moved, is struck dead centre, and goes straight up again -- a
-- vertical loop the player cannot break out of without deliberately missing.
M.BALL_RELEASE_OFFSET = 0.35

-- The thumb strip, as drawn: x 52..668, y 1147..1201 — 617 wide and centred on
-- 360 to within half a unit. This is the visual affordance only. input.lua's
-- live zone is deliberately larger (see the note there), so a thumb that lands
-- slightly high or wide still steers.
M.STRIP_X, M.STRIP_W = 52, 617
M.STRIP_Y, M.STRIP_H = 1147, 55

return M
