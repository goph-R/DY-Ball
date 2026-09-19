-- view.lua — the fixed 720x1280 design space, fitted into whatever the host
-- gives us.
--
-- SOOB's virtual canvas is fixed-height / extend-width: viewSize() always
-- reports h = UI_VIRTUAL_H and w scaling with the window's aspect ratio. This
-- game is laid out in a fixed 720x1280 box instead, so everything is authored
-- in design units and mapped through here — the Lua equivalent of libGDX's
-- FitViewport.
--
--     scale = min(viewW / 720, viewH / 1280)
--
-- On a 9:16 screen the box fills the view exactly. On a taller phone it is
-- width-bound and the leftover height shows background above and below. On a
-- desktop window or a tablet it is height-bound and pillarboxes. One formula,
-- no special cases — which is why UI_VIRTUAL_H's actual value is irrelevant
-- to this game and stays at the engine default.

local M = {}

M.DESIGN_W = 720
M.DESIGN_H = 1280

M.scale  = 1
M.ox, M.oy = 0, 0   -- design (0,0) expressed in virtual coords
M.w,  M.h  = 0, 0   -- the fitted box, in virtual units
M.vw, M.vh = 0, 0   -- the whole view, for screen-space work (see input.lua)

-- Call once per frame before drawing. Cheap, and the view can change at any
-- time: a desktop window resize, a phone rotating, the browser chrome
-- collapsing on scroll.
function M.update()
    local vw, vh = viewSize()
    M.vw, M.vh = vw, vh
    M.scale = math.min(vw / M.DESIGN_W, vh / M.DESIGN_H)
    M.w = M.DESIGN_W * M.scale
    M.h = M.DESIGN_H * M.scale
    -- Centred: the virtual canvas has its origin at the screen centre, so the
    -- box's top-left is simply half its size back from there. Bleed splits
    -- evenly above and below.
    M.ox = -M.w / 2
    M.oy = -M.h / 2
end

-- Design -> virtual. x/y map a point; len maps a distance (width, radius).
function M.x(dx)   return M.ox + dx * M.scale end
function M.y(dy)   return M.oy + dy * M.scale end
function M.len(d)  return d * M.scale end

-- Virtual -> design. The hosts report pointer positions in virtual coords
-- while the game thinks in design units, so input has to come back through
-- this.
function M.toDesign(vx, vy)
    return (vx - M.ox) / M.scale, (vy - M.oy) / M.scale
end

return M
