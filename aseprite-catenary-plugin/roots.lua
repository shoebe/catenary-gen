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

-- https://docs.rs/roots/0.0.8/roots/fn.find_root_brent.html
function M.find_root_brent(min, max, f)
    -- todo
    return nil
end

return M
