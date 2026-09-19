-- paddle.lua — the ship, in three flavours.
--
-- Everything here is in DESIGN units (720x1280); view.lua maps to the screen
-- at draw time. The paddle owns its own x because input.lua reports movement
-- as a delta, never an absolute position.
--
-- SHOOTING fires on a timer rather than on a tap. That is not a stylistic
-- choice: the hosts are single-pointer, the one finger is already steering,
-- so there is no second input to fire with. Picking up the bonus arms it and
-- it shoots by itself until the bonus is lost.

local view = require "view"

local M = {}

M.NORMAL   = "normal"
M.STICKY   = "sticky"
M.SHOOTING = "shooting"

-- Design-space geometry. y is the top edge; the field's floor is DESIGN_H.
M.W_DEFAULT = 160
M.H         = 28
M.Y         = view.DESIGN_H - 120

M.FIRE_INTERVAL = 0.45   -- seconds between shots while SHOOTING
M.SHOT_SPEED    = 900    -- design units / second, upward
M.SHOT_W        = 6
M.SHOT_H        = 22

function M.new()
    local p = {
        kind  = M.NORMAL,
        x     = view.DESIGN_W / 2,   -- centre of the paddle
        w     = M.W_DEFAULT,
        timer = 0,
        shots = {},
    }
    return setmetatable(p, { __index = M })
end

function M:halfW() return self.w / 2 end

-- Move by a delta and clamp to the field. The clamp is why input.lua can hand
-- over raw deltas without knowing anything about the play area.
function M:moveBy(dx)
    local half = self:halfW()
    self.x = math.max(half, math.min(view.DESIGN_W - half, self.x + dx))
end

function M:setKind(kind)
    self.kind  = kind
    self.timer = 0
end

function M:update(dt)
    if self.kind == M.SHOOTING then
        self.timer = self.timer - dt
        if self.timer <= 0 then
            self.timer = M.FIRE_INTERVAL
            self:fire()
        end
    end

    local live = {}
    for _, s in ipairs(self.shots) do
        s.y = s.y - M.SHOT_SPEED * dt
        if s.y + M.SHOT_H > 0 then live[#live + 1] = s end
    end
    self.shots = live
end

-- Two barrels, at the paddle's shoulders.
function M:fire()
    local inset = self:halfW() - 14
    for _, off in ipairs({ -inset, inset }) do
        self.shots[#self.shots + 1] = { x = self.x + off, y = M.Y }
    end
end

local COLOR = {
    normal   = { 0.62, 0.78, 1.00 },
    sticky   = { 1.00, 0.82, 0.38 },
    shooting = { 1.00, 0.46, 0.46 },
}

function M:render()
    for _, s in ipairs(self.shots) do
        drawQuad(view.x(s.x - M.SHOT_W / 2), view.y(s.y),
                 view.len(M.SHOT_W), view.len(M.SHOT_H),
                 { color = { 1, 0.9, 0.5 } })
    end

    -- PLACEHOLDER. Once the ship art exists this becomes a single call:
    --     widget.draw9patch("ship_" .. self.kind,
    --         view.x(self.x - self:halfW()), view.y(M.Y),
    --         view.len(self.w), view.len(M.H))
    -- with `slice = { x1, x2, y1, y2 }` on the region in assets.lua, y1/y2
    -- spanning the full height so it stretches horizontally only. That is what
    -- makes the expand/shrink bonuses free.
    drawQuad(view.x(self.x - self:halfW()), view.y(M.Y),
             view.len(self.w), view.len(M.H),
             { color = COLOR[self.kind] })
end

return M
