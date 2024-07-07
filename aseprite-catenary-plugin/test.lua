local cat = require "catenary"

local success = cat.render_cat_from_params(100, 100, 250, false, function(x, y)
    print(x, y)
end)
if not success then
    print("failed")
end
