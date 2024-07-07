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

local function render_cat(sel, slack, flip_x)
    local success = false

    app.transaction(
        "render catenary",
        function()
            app.command.DeselectMask()
            local max = sel.origin


            success = cat.render_cat_from_params(sel.w, sel.h, slack, false, function(x, y)
                if flip_x then
                    x = sel.w - 1 - x
                end
                local point = Point { sel.x + x, sel.y + y }
                if point.x > max.x then
                    max.x = point.x
                end
                if point.y > max.y then
                    max.y = point.y
                end
                app.useTool {
                    tool = "pencil",
                    color = app.fgColor,
                    points = { point },
                }
            end)
            if success then
                app.useTool {
                    tool = "rectangular_marquee",
                    points = { sel.origin, max }
                }
            end
        end
    )
    if success then
        app.refresh()
    end
    return success
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
    if sel.w == 0 or sel.h == 0 then
        app.alert("Use selection tool first")
        return
    end

    local last_success = render_cat(sel, 0)

    local dlg = Dialog("Catenary")

    function on_change()
        if last_success ~= nil then
            app.undo()
        end
        last_success = render_cat(sel, dlg.data.slack_num, dlg.data.flip_x)
    end

    dlg:number {
        id = "slack_num",
        label = "slack",
        decimals = 0,
        onchange = on_change
    }
    dlg:check {
        id = "flip_x",
        label = "flip x",
        selected = false,
        onclick = on_change
    }
    dlg:show {
        wait = true
    }
end

function init(plugin)
    plugin:newCommand {
        id = "RenderCatenary",
        title = "Render Catenary",
        group = "edit_fill",
        onclick = open_dialog,
    }
end
