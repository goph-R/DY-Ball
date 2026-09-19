-- input.lua — one finger, and nothing else.
--
-- Both mobile hosts are strictly single-pointer. Android's GameView handles
-- only ACTION_DOWN / MOVE / UP / CANCEL with no pointer ids, so a second
-- finger is invisible; the web host captures one pointer the same way. Every
-- action therefore shares the steering finger — which is why the shooting
-- paddle auto-fires instead of asking for a tap.
--
-- The paddle is steered by a relative slide inside a band at the bottom of the
-- SCREEN, not the bottom of the play field. On a tall phone the field is
-- width-bound and centred, so its bottom edge sits above the thumb; a zone
-- measured in design units would miss the most comfortable part of the reach.
-- The zone is therefore tested in virtual coords, straight off viewSize().
--
-- Deltas are computed here from the absolute x rather than taken from
-- onMouseMove's dx. Android derives dx correctly from the previous position,
-- but the web host takes it from PointerEvent.movementX, which is not
-- populated for touch pointers on iOS Safari — a dx-driven paddle works on
-- desktop and Android and sits motionless on an iPhone.

local view = require "view"

local M = {}

-- Fraction of the screen height, measured from the bottom, that steers.
M.ZONE = 0.33

-- Thumb travel to paddle travel. 1.0 means the thumb must cross the whole
-- 720-unit field to do the same — far more than a comfortable arc. Saved as a
-- player option; this is the default.
M.sensitivity = 1.8

local steering = false
local lastX    = 0

function M.isSteering() return steering end

-- Returns true when this press started steering, which is also the moment to
-- release a ball stuck to a sticky paddle: the same press both frees the ball
-- and begins the slide, so there is no tap-versus-drag threshold to tune.
function M.pointerDown(vx, vy)
    if vy > view.vh / 2 - view.vh * M.ZONE then
        steering = true
        lastX = vx
        return true
    end
    return false
end

-- Returns the paddle movement in DESIGN units since the last call, or 0 when
-- this press did not start in the zone. Deliberately ignores the host's dx.
function M.pointerMove(vx)
    if not steering then return 0 end
    local d = (vx - lastX) / view.scale * M.sensitivity
    lastX = vx
    return d
end

-- Android fires mouseUp and then a synthetic mouseMove at an off-screen
-- position, to park the cursor so a tapped widget doesn't stay lit. Clearing
-- the flag here makes that stray move a no-op.
function M.pointerUp()
    steering = false
end

return M
