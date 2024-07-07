local cat = require "catenary"

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local function render_cat(sel, slack)
    local max_x = sel.x
    local max_y = sel.y
    local points = {}
    local success = cat.render_cat_from_params(sel.w, sel.h, slack, false, function(x, y)
        table.insert(points, Point { sel.x + x, sel.y + y })
        if sel.x > max_x then
            max_x = sel.x
        end
        if sel.y > max_y then
            max_y = sel.y
        end
    end)
    if not success then
        return false
    end
    --[[ if app.sprite ~= nil then
        app.sprite.selection:select(Rectangle {
            sel.x, sel.y, max_x - sel.x, max_y - sel.y
        })
    end ]]
    app.transaction(
        "render catenary",
        function()
            for k, v in pairs(points) do
                app.useTool {
                    tool = "pencil",
                    color = app.fgColor,
                    points = { v },
                }
            end
        end
    )

    app.refresh()
    return true
end

local function open_dialog()
    if app.sprite == nil then
        app.alert("No sprite selected")
        return
    end

    if app.sprite.selection == nil then
        app.alert("Use selection tool first")
        return
    end

    local sel = app.sprite.selection.bounds
    app.sprite.selection:deselect()

    if sel.w == 0 or sel.h == 0 then
        app.alert("Use selection tool first")
        return
    end

    local last_success = render_cat(sel, 0)

    local dlg = Dialog("Catenary")
    dlg:number {
        id = "slack_num",
        label = "slack",
        decimals = 0,
        onchange = function()
            if last_success then
                app.undo()
            end
            last_success = render_cat(sel, dlg.data.slack_num)
        end
    }
    dlg:show()
end

function init(plugin)
    plugin:newCommand {
        id = "RenderCatenary",
        title = "Render Catenary",
        group = "edit_fill",
        onclick = open_dialog,
    }
end
