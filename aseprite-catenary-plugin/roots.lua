-- Adapted from https://crates.io/crates/roots

local M = {}


-- https://docs.rs/roots/0.0.8/roots/fn.find_root_newton_raphson.html
function M.find_root_newton_raphson(start, f, d)
    local x = start
    for i = 0, 100, 1
    do
        local val = f(x)
        local deriv = d(x)

        if math.abs(val) < 1e-10 then
            return x
        end

        if math.abs(deriv) < 1e-10 then
            if i == 0 then
                -- Derivative is 0; try to correct the bad starting point
                x = x + 1
                goto continue
            else
                return nil
            end
        end

        x = x - val / deriv

        ::continue::
    end
    return nil
end

-- https://en.wikipedia.org/wiki/Bisection_method
function M.find_root_bisecting(min, max, f)
    local v_min = f(min)
    local v_max = f(max)
    if v_min > v_max then
        local temp = v_min
        v_min = v_max
        v_max = temp
        temp = min
        min = max
        max = temp
    end

    if v_min > 0 or v_max < 0 then
        -- print("not bracketed properly")
        return nil
    end

    if math.abs(v_min) < 1e-10 then
        return min
    end

    if math.abs(v_max) < 1e-10 then
        return max
    end

    local center
    local v_center
    for i = 0, 10000, 1 do
        center = (min + max) / 2
        v_center = f(center)
        if math.abs(v_center) < 1e-10 then
            return center
        end
        if v_center < 0 then
            min = center
        else
            max = center
        end
    end
    -- print("failed to converge, error: " .. v_center)
    return nil
end

return M
