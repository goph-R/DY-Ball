-- input.lua — steering the ship, on a thumb or on a mouse.
--
-- Two schemes, because the devices want opposite things:
--
--   TOUCH   a relative slide inside a band at the bottom of the SCREEN. The
--           finger is not the ship — it drags it. Absolute would put the ship
--           under the thumb, where it cannot be seen.
--   MOUSE   the ship's centre simply follows the pointer's x, continuously and
--           with no button held. That is what a desktop player expects, and
--           the cursor is visible so there is nothing to hide behind.
--
-- Which one is chosen by *hover*, not by the platform. A mouse emits moves with
-- no button held; a touch screen cannot — there is no pointer-leave on touch,
-- which is why the Android host parks its virtual cursor off-canvas on lift.
-- So the first hover we see means a real pointing device, and we switch for
-- good.
--
-- `platform` would be the obvious alternative and it is not good enough:
-- "web" covers both a desktop browser and a phone browser, and the desktop
-- host does not set it at all. Hover also gets a mouse plugged into an Android
-- device right, which that host already reports (ACTION_HOVER_MOVE).
--
-- Deltas in touch mode are computed here from the absolute x rather than taken
-- from onMouseMove's dx. Android derives dx correctly, but the web host takes
-- it from PointerEvent.movementX, which is not populated for touch pointers on
-- iOS Safari — a dx-driven paddle works on desktop and Android and sits
-- motionless on an iPhone.
--
-- Both mobile hosts are strictly single-pointer: Android handles no pointer
-- ids, the web host captures one pointer. So the one finger steers and
-- everything else shares it — which is why shooting is automatic and why the
-- press that starts a slide is also what frees a held ball.

local view = require "view"

local M = {}

-- Fraction of the screen height, measured from the bottom, that steers.
--
-- Deliberately larger than the strip drawn in the mockup (layout.STRIP_*,
-- 55 units tall at the bottom of a 1280 field). The drawn strip is a hint
-- about where to put the thumb; the live area has to forgive landing above it,
-- and on a tall phone it also needs to cover the background bleed *below* the
-- field, which is physically the lowest part of the screen.
M.ZONE = 0.33

-- Thumb travel to ship travel, touch only. 1.0 means the thumb must cross the
-- whole 720-unit field to do the same — far more than a comfortable arc. Saved
-- as a player option; this is the default. Mouse mode ignores it: absolute
-- pointing has no gain to tune.
M.sensitivity = 1.8

M.mode = "touch"          -- becomes "mouse" on the first hover, and stays

local steering = false
local held     = false
local lastX    = 0

-- Both mobile hosts park the cursor at -1e5 on touch release -- Android in
-- GameView, the web host in clearHover -- precisely because touch has no
-- pointer-leave. Virtual coordinates are only a few hundred units, so anything
-- out here is that sentinel and must not be mistaken for a hover.
local function parked(vx) return vx < -10000 end

function M.isSteering() return steering end
function M.isMouse()    return M.mode == "mouse" end

-- True when this press should also free a ball held by the ship. On touch that
-- means a press inside the zone, which is the same press that begins the
-- slide. On a mouse the ship already tracks the pointer, so any click will do.
function M.pointerDown(vx, vy)
    held = true
    if M.mode == "mouse" then return true end
    if vy > view.vh / 2 - view.vh * M.ZONE then
        steering = true
        lastX = vx
        return true
    end
    return false
end

-- Where the ship's centre should be now, in design units, or nil to leave it
-- alone. The ship clamps the result to the field, so this does not have to.
function M.steer(shipX, vx, vy)
    if parked(vx) then return nil end

    -- A move with no button held can only be a hovering pointer.
    if not held then M.mode = "mouse" end

    if M.mode == "mouse" then
        local designX = view.toDesign(vx, vy)
        return designX
    end

    if not steering then return nil end
    local d = (vx - lastX) / view.scale * M.sensitivity
    lastX = vx
    return shipX + d
end

-- Android fires mouseUp and then a synthetic mouseMove at the parked position.
-- Clearing the flags here makes that stray move a no-op in touch mode, and
-- `parked` catches it in mouse mode.
function M.pointerUp()
    steering = false
    held     = false
end

return M
