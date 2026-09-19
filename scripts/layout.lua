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

-- Bricks. The 60-unit pitch is confirmed twice over in the mockup: a 9-brick
-- colour row spanning x 120..659 (540 = 9 x 60) and an 8-brick steel row
-- spanning x 120..598 (479 = 8 x 60). The mockup places bricks ad hoc, so the
-- grid origin below is the symmetric version: 10 columns, 60 each, centred.
M.BRICK_W, M.BRICK_H = 60, 50
M.PITCH_X, M.PITCH_Y = 60, 60
M.COLS   = 10
M.GRID_X = 60      -- 60 .. 660, leaving equal 60-unit margins
M.GRID_Y = 365     -- first brick row in the mockup

-- Ship. All three variants are 125 wide; the art box is y 962..1002. The body
-- surface sits about 10 units below the art top — that is the line the ball
-- should bounce off, not the top of the sprite.
M.SHIP_W, M.SHIP_H = 125, 41
M.SHIP_Y     = 962
M.SHIP_INSET = 10

M.BALL_R = 11      -- 21 units across in the mockup

-- The thumb strip, as drawn: x 52..668, y 1147..1201 — 617 wide and centred on
-- 360 to within half a unit. This is the visual affordance only. input.lua's
-- live zone is deliberately larger (see the note there), so a thumb that lands
-- slightly high or wide still steers.
M.STRIP_X, M.STRIP_W = 52, 617
M.STRIP_Y, M.STRIP_H = 1147, 55

return M
