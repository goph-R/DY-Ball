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
local layout = require "layout"
local input  = require "input"
local Paddle = require "paddle"

scene.installHooks(_G)

local play = {}

-- Placeholder colours. Each one stands in for art named in the mockup.
local BG      = { 0.03, 0.03, 0.05 }   -- the bleed; drawBg("space") replaces it
local FIELD   = { 0.05, 0.05, 0.09 }   -- starfield area
local HUD     = { 0.16, 0.17, 0.20 }   -- the panel with score / level / counter
local HAZARD  = { 0.85, 0.75, 0.15 }   -- its yellow bottom border
local STRIP   = { 0.13, 0.14, 0.17 }   -- the thumb affordance

local ROWS = 6

function play:enter()
    self.paddle = Paddle.new()
    self.ball   = { x = view.DESIGN_W / 2, y = 800, vx = 0, vy = 0,
                    r = layout.BALL_R }
    self.stuck  = true

    -- Ramp state is per LEVEL, not per ball: with triple balls in play a
    -- per-ball counter would climb three times as fast for the same rally.
    self.hits     = 0
    self.speedMul = 1      -- pickups 12 and 14 live here
end

-- Ramped speed, then the pickup multiplier, then the absolute clamp. The ramp
-- caps on its own so a level plateaus; the clamp is wider so a Fast Ball is
-- still felt after it has.
function play:ballSpeed()
    local s = layout.BALL_SPEED * layout.BALL_SPEED_GAIN ^ self.hits
    s = math.min(s, layout.BALL_SPEED_MAX) * self.speedMul
    return math.max(layout.BALL_SPEED_FLOOR,
                    math.min(s, layout.BALL_SPEED_CEILING))
end

-- Leave the ship at an angle set by where it was struck: dead centre goes
-- straight up, the very edge goes BALL_MAX_ANGLE off vertical. Speed is set
-- from the ramp rather than reflected, so the ramp only ever steps here.
function play:launch(offset)
    local a = math.max(-1, math.min(1, offset)) * layout.BALL_MAX_ANGLE
    local s = self:ballSpeed()
    self.ball.vx =  math.sin(a) * s
    self.ball.vy = -math.cos(a) * s
    self.stuck   = false
end

function play:update(dt)
    view.update()
    self.paddle:update(dt)

    if self.stuck then
        self.ball.x = self.paddle.x
        self.ball.y = Paddle.SURFACE - self.ball.r
        return
    end

    local b = self.ball
    b.x = b.x + b.vx * dt
    b.y = b.y + b.vy * dt

    -- Field walls, in design units — identical on every device, which is the
    -- whole point of the fixed box.
    if b.x - b.r < 0             then b.x = b.r;                  b.vx = -b.vx end
    if b.x + b.r > view.DESIGN_W then b.x = view.DESIGN_W - b.r;   b.vx = -b.vx end
    -- Ceiling is the underside of the HUD, not the top of the design box.
    if b.y - b.r < layout.FIELD_TOP then
        b.y = layout.FIELD_TOP + b.r; b.vy = -b.vy
    end

    -- Paddle.
    local p = self.paddle
    if b.vy > 0 and b.y + b.r >= Paddle.SURFACE and b.y - b.r <= Paddle.Y + Paddle.H
       and b.x >= p.x - p:halfW() and b.x <= p.x + p:halfW() then
        b.y = Paddle.SURFACE - b.r
        self.hits = self.hits + 1
        if p.kind == Paddle.STICKY then
            self.stuck = true
        else
            self:launch((b.x - p.x) / p:halfW())
        end
    end

    -- Floor: re-stick rather than lose a life, this being a scaffold. The ramp
    -- is deliberately NOT reset here — whether losing a ball should cost the
    -- accumulated speed is still open (dd.md).
    if b.y - b.r > view.DESIGN_H then self.stuck = true end
end

function play:render()
    -- The bleed. drawBg("space") replaces this once there is art — it
    -- cover-fits a region to the whole view, which is exactly what the areas
    -- outside the field want.
    drawQuad(-view.vw / 2, -view.vh / 2, view.vw, view.vh, { color = BG })

    -- The 720x1280 field.
    drawQuad(view.x(0), view.y(0), view.len(view.DESIGN_W), view.len(view.DESIGN_H),
             { color = FIELD })

    self:renderBricks()
    self.paddle:render()

    local b = self.ball
    drawEllipse(view.x(b.x), view.y(b.y), view.len(b.r), view.len(b.r),
                { color = { 1, 1, 1 }, thickness = view.len(4) })

    self:renderHud()
    self:renderStrip()
    self:renderDebug()
end

function play:renderBricks()
    for r = 0, ROWS - 1 do
        for c = 0, layout.COLS - 1 do
            local bx = layout.GRID_X + c * layout.PITCH_X
            local by = layout.GRID_Y + r * layout.PITCH_Y
            drawQuad(view.x(bx), view.y(by),
                     view.len(layout.BRICK_W), view.len(layout.BRICK_H),
                     { color = { 0.30 + r * 0.09, 0.42, 0.72 } })
        end
    end
end

-- PLACEHOLDER for the panel in the mockup: pause button, SCORE, LEVEL and the
-- bricks-remaining counter, over a cable-and-plate background with the hazard
-- stripe as its bottom border. Drawn after the field so it sits over it, the
-- way the art does.
function play:renderHud()
    drawQuad(view.x(0), view.y(0),
             view.len(view.DESIGN_W), view.len(layout.HAZARD_Y),
             { color = HUD })
    drawQuad(view.x(0), view.y(layout.HAZARD_Y),
             view.len(view.DESIGN_W), view.len(layout.HAZARD_H),
             { color = HAZARD })

    drawText("SCORE 0", view.x(240), view.y(90), { scale = view.len(1.8), color = { 0.8, 1, 0.8 } })
    drawText("LEVEL 1", view.x(510), view.y(90), { scale = view.len(1.8), color = { 0.8, 1, 0.8 } })
end

-- PLACEHOLDER for the thumb affordance. It is only a hint: input.lua's live
-- zone is larger, so landing slightly above or outside it still steers.
function play:renderStrip()
    drawQuad(view.x(layout.STRIP_X), view.y(layout.STRIP_Y),
             view.len(layout.STRIP_W), view.len(layout.STRIP_H),
             { color = STRIP, alpha = input.isSteering() and 0.9 or 0.5 })
end

-- On-screen because the interesting failures only happen on a device: a wrong
-- fit, a steering zone that misses the thumb, a paddle that will not move
-- because the host reported no delta.
function play:renderDebug()
    local lines = {
        string.format("view %.0fx%.0f  scale %.3f", view.vw, view.vh, view.scale),
        string.format("field %.0fx%.0f in view", view.w, view.h),
        string.format("ship %s  x=%.0f  [%s]%s", self.paddle.kind, self.paddle.x,
                      input.isMouse() and "mouse" or "touch",
                      input.isSteering() and "  STEERING" or ""),
        string.format("speed %.0f  hits %d  x%.2f", self:ballSpeed(), self.hits,
                      self.speedMul),
    }
    for i, s in ipairs(lines) do
        drawText(s, view.x(12), view.y(12 + (i - 1) * 26), {
            scale = view.len(1.4),
            color = { 0.55, 0.62, 0.78 },
        })
    end
end

-- The press that frees a held ball is the same one that starts a slide on
-- touch, or any click on a mouse -- see input.lua.
function play:mouseDown(x, y, b)
    if input.pointerDown(x, y) and self.stuck then
        self:launch(layout.BALL_RELEASE_OFFSET)
    end
end

function play:mouseMove(x, y)
    local nx = input.steer(self.paddle.x, x, y)
    if nx then self.paddle:moveTo(nx) end
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
    elseif name == "space" then
        if self.stuck then self:launch(layout.BALL_RELEASE_OFFSET) end
    elseif name == "r"     then self.hits = 0
    end
end

function onStart()
    view.update()
    scene.push(play)
end
