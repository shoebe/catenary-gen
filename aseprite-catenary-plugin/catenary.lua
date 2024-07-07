-- See PDF for derivations and Rust code for more comments

local hyperbolic = require "hyperbolic"
local roots = require "roots"

local M = {}

local sqrt = math.sqrt
local sinh = hyperbolic.sinh
local cosh = hyperbolic.cosh

function M.new_from_params(h, v, slack)
    local min_arc = sqrt(h * h + v * v)
    if slack < 1e-3 then
        slack = 1e-3
    end
    local L = min_arc + slack

    -- Inaccurate for small a, will return very big numbers or Inf
    local function f(a)
        local a2 = a * 2
        return a2 * sinh(h / a2) - sqrt(L * L - v * v)
    end

    -- Inaccurate for small a, could return 0, Inf, Nan, -Inf
    local function d(a)
        local a2 = a * 2.0
        local left = 2.0 * sinh(h / a2)
        local right = h / a * cosh(h / a2)
        return left - right
    end

    local a = roots.find_root_newton_raphson(20, f, d)

    if a == nil then
        a = roots.find_root_brent(1, 20, f)
    end

    return a
end

-- https://en.wikipedia.org/wiki/Inverse_hyperbolic_functions
local function asinh(x)
    return math.log(x + math.sqrt(x * x + 1))
end
local function acosh(x)
    return math.log(x + math.sqrt(x * x - 1))
end

function M.evaluate_at_x(a, x)
    return a * cosh(x / a)
end

function M.evaluate_at_y(a, y)
    return a * acosh(y / a)
end

function M.find_point_pair(a, h, v)
    local h_2 = h / 2

    local sh = sinh(h_2 / a)
    local r = v / (2.0 * a * sh)
    local x0 = asinh(r) * a - h_2

    local y_dif = M.evaluate_at_x(a, x0 + h) - M.evaluate_at_x(a, x0)
    local dif = math.abs(y_dif - v)
    if dif > 1e-5 then
        print("error: diff too big")
        return nil
    end

    return x0
end

local function round(x)
    return math.floor(x + 0.5)
end

function M.render_catenary_x(a, w, h, disp_x, disp_y, draw)
    for col = 0, w - 1, 1 do
        local x = col + disp_x
        local y = M.evaluate_at_x(a, x)

        local y_row_inv = round(y - disp_y)

        local row = h - 1 - y_row_inv
        if row > 0 and row < h then
            draw(col, row)
        end
    end
end

function M.render_catenary_y(a, w, h, disp_x, disp_y, draw)
    local max_y_at_0 = M.evaluate_at_x(a, 0 + disp_x)

    for row = 0, h - 1, 1 do
        local y = (h - 1 - row) + disp_y
        local x = M.evaluate_at_y(a, y)
        local col1 = round(x - disp_x)
        local col2 = round(-x - disp_x)

        if (col1 > 0 and col1 < w) or (col1 == 0 and y <= max_y_at_0) then
            draw(col1, row)
        end

        if (col2 > 0 and col2 < w) or (col2 == 0 and y <= max_y_at_0) then
            draw(col2, row)
        end
    end
end

function M.render_catenary(a, w, h, disp_x, disp_y, draw)
    M.render_catenary_x(a, w, h, disp_x, disp_y, draw)
    M.render_catenary_y(a, w, h, disp_x, disp_y, draw)
end

local function sign(x)
    if x < 0 then
        return -1
    elseif x > 0 then
        return 1
    else
        return 0
    end
end


-- h: horizontal disp, v: vertical disp
function M.render_cat_from_params(h, v, slack, flipped_x, draw)
    local a = M.new_from_params(h, v, slack)
    if a == nil then
        return false
    end
    local x0 = M.find_point_pair(a, h, v)

    local disp_x = x0
    -- y_0 is ymin, since v >= 0
    local y_0 = M.evaluate_at_x(a, x0)

    local disp_y
    if sign(x0) ~= sign(x0 + h) then
        disp_y = a
    else
        disp_y = y_0
    end

    local extra_v = y_0 - disp_y

    local w = h + 2
    local h = v + round(extra_v)

    M.render_catenary(a, w, h, disp_x, disp_y, draw)
    return true
end

return M
