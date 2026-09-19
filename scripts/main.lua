-- DY-Ball — entry script.
--
-- A scaffold, not the game: it exists to prove the two things that had to be
-- settled before any art or level design happens — that the fixed 720x1280
-- field lands correctly on every screen shape, and that one-finger steering
-- works on a real device. Bricks, bonuses and collision replace the
-- placeholders from here.
--
-- Read scripts/view.lua first. Nothing in this game uses raw virtual
-- coordinates; everything is authored in the 720x1280 design space and mapped
-- at draw time, so the numbers here match the designs 1:1.

local scene  = require "engine.scene"
local view   = require "view"
local input  = require "input"
local Paddle = require "paddle"

scene.installHooks(_G)

local play = {}

local BG        = { 0.05, 0.05, 0.09 }   -- the bleed, outside the field
local FIELD     = { 0.09, 0.10, 0.16 }
local FIELD_EDGE = { 0.20, 0.23, 0.34 }

-- Placeholder brick grid, in design units. 576 wide / 8 columns = 72, which is
-- also the width that survives on the narrowest phones if the fit is ever
-- abandoned for a full-bleed layout.
local COLS, ROWS = 8, 6
local BRICK_W, BRICK_H = 80, 34
local GRID_X, GRID_Y = 40, 180
local GAP = 8

function play:enter()
    self.paddle = Paddle.new()
    self.ball   = { x = view.DESIGN_W / 2, y = 800, vx = 260, vy = -420, r = 14 }
    self.stuck  = true
end

function play:update(dt)
    view.update()
    self.paddle:update(dt)

    if self.stuck then
        self.ball.x = self.paddle.x
        self.ball.y = Paddle.Y - self.ball.r
        return
    end

    local b = self.ball
    b.x = b.x + b.vx * dt
    b.y = b.y + b.vy * dt

    -- Field walls, in design units — identical on every device, which is the
    -- whole point of the fixed box.
    if b.x - b.r < 0             then b.x = b.r;                  b.vx = -b.vx end
    if b.x + b.r > view.DESIGN_W then b.x = view.DESIGN_W - b.r;   b.vx = -b.vx end
    if b.y - b.r < 0             then b.y = b.r;                  b.vy = -b.vy end

    -- Paddle.
    local p = self.paddle
    if b.vy > 0 and b.y + b.r >= Paddle.Y and b.y - b.r <= Paddle.Y + Paddle.H
       and b.x >= p.x - p:halfW() and b.x <= p.x + p:halfW() then
        b.y  = Paddle.Y - b.r
        b.vy = -b.vy
        -- Angle off the contact point, the usual brick-breaker feel.
        b.vx = (b.x - p.x) / p:halfW() * 420
        if p.kind == Paddle.STICKY then self.stuck = true end
    end

    -- Floor: reset rather than lose a life, this being a scaffold.
    if b.y - b.r > view.DESIGN_H then self.stuck = true end
end

function play:render()
    -- The bleed. drawBg("background") replaces this once there is art — it
    -- cover-fits a region to the whole view, which is exactly what the areas
    -- outside the field want.
    drawQuad(-view.vw / 2, -view.vh / 2, view.vw, view.vh, { color = BG })

    -- The 720x1280 field.
    drawQuad(view.x(0), view.y(0), view.len(view.DESIGN_W), view.len(view.DESIGN_H),
             { color = FIELD })

    for r = 0, ROWS - 1 do
        for c = 0, COLS - 1 do
            local bx = GRID_X + c * (BRICK_W + GAP)
            local by = GRID_Y + r * (BRICK_H + GAP)
            drawQuad(view.x(bx), view.y(by), view.len(BRICK_W), view.len(BRICK_H),
                     { color = { 0.30 + r * 0.09, 0.42, 0.72 } })
        end
    end

    self.paddle:render()

    local b = self.ball
    drawEllipse(view.x(b.x), view.y(b.y), view.len(b.r), view.len(b.r),
                { color = { 1, 1, 1 }, thickness = view.len(4) })

    -- Field edge, drawn last so it reads as a frame over the contents.
    drawQuad(view.x(0), view.y(0), view.len(view.DESIGN_W), view.len(2), { color = FIELD_EDGE })
    drawQuad(view.x(0), view.y(view.DESIGN_H - 2), view.len(view.DESIGN_W), view.len(2), { color = FIELD_EDGE })

    self:renderHud()
end

-- On-screen because the interesting failures only happen on a device: a wrong
-- fit, a steering zone that misses the thumb, a paddle that will not move
-- because the host reported no delta.
function play:renderHud()
    local lines = {
        string.format("view %.0fx%.0f  scale %.3f", view.vw, view.vh, view.scale),
        string.format("field %.0fx%.0f in view", view.w, view.h),
        string.format("paddle %s  x=%.0f  %s", self.paddle.kind, self.paddle.x,
                      input.isSteering() and "STEERING" or ""),
    }
    for i, s in ipairs(lines) do
        drawText(s, view.x(12), view.y(12 + (i - 1) * 26), {
            scale = view.len(1.4),
            color = { 0.55, 0.62, 0.78 },
        })
    end
end

-- One finger: the press that starts steering also frees a stuck ball, so the
-- sticky paddle needs no second gesture.
function play:mouseDown(x, y, b)
    if input.pointerDown(x, y) then
        self.stuck = false
    end
end

function play:mouseMove(x, y)
    local dx = input.pointerMove(x)
    if dx ~= 0 then self.paddle:moveBy(dx) end
end

function play:mouseUp()
    input.pointerUp()
end

-- Desktop conveniences. Touch never reaches these.
function play:keyDown(name)
    if name == "escape" then requestQuit()
    elseif name == "1" then self.paddle:setKind(Paddle.NORMAL)
    elseif name == "2" then self.paddle:setKind(Paddle.STICKY)
    elseif name == "3" then self.paddle:setKind(Paddle.SHOOTING)
    elseif name == "space" then self.stuck = false
    end
end

function onStart()
    view.update()
    scene.push(play)
end
