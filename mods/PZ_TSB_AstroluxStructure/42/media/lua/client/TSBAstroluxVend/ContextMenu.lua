-- Reuse a single root across independent context-menu event handlers.
local M={}
local function submenu(context,label)
    for _,option in ipairs(context.options or {})do
        if option.name==label and option.TSBAstroluxSubmenu then return option.TSBAstroluxSubmenu end
    end
    local option=context:addOption(label)
    local sub=ISContextMenu:getNew(context)
    context:addSubMenu(option,sub)
    option.TSBAstroluxSubmenu=sub
    return sub
end
function M.root(context)return submenu(context,'Astrolux Motors')end
function M.section(context,label)return submenu(M.root(context),label)end
function M.submenu(context,label)return submenu(context,label)end
return M
