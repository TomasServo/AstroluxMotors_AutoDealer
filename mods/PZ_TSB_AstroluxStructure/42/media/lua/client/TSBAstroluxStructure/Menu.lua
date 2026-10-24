local Menus=require 'TSBAstroluxVend/ContextMenu'
require 'ISUI/ISModalRichText'
local function report(player,fn)
    local ok,result,reason=pcall(fn)
    if ok and result then return end
    local message=ok and reason or result
    local modal=ISModalRichText:new(100,100,620,250,'Astrolux Motors lab <LINE> '..tostring(message or 'Operation could not complete.'),false,nil,nil,player:getPlayerNum())
    modal:initialise();modal:addToUIManager()
end
Events.OnFillWorldObjectContextMenu.Add(function(playerNum,context,objects,test)
    if test or isClient() or isServer() or not getDebug() then return end
    if not tostring(getWorld():getWorld()):match('^AstroluxStructureLab') then return end
    local player=getSpecificPlayer(playerNum)
    if not player or player:isDead() or player:getZ()~=0 then return end
    local builder=TSBAstroluxStructure
    if not builder then return end
    for _,obj in ipairs(objects) do
        local sq=obj:getSquare()
        if sq and sq:getZ()==0 then
            local x,y=sq:getX(),sq:getY()
            local record=require('TSBAstroluxStructure/Records').near(x,y)
            local size=record and (record.combinedSize or 8) or 8
            local inside=record and x>=record.x and x<=record.x+size and y>=record.y and y<=record.y+size
            local menu=Menus.section(context,'Showroom')
            if inside then
            local entrances=Menus.submenu(menu,'Entrances')
            local clickedRug
            for _,candidate in ipairs(objects)do
                local sprite=candidate:getSprite();local name=sprite and sprite:getName()
                if type(name)=='string' and name:match('^TSBAstroluxLogoRug_%d+$')then clickedRug=candidate;break end
            end
            for _,direction in ipairs({'north','south','east','west'})do
                local edge=direction
                local closed=record.closedEntrances and record.closedEntrances[edge]
                entrances:addOption(edge..(closed and ': restore sliding doors and linked rug' or ': replace doors with windows'),player,function()
                    report(player,function()return require('TSBAstroluxStructure/EntranceAdmin').toggle(player,record,edge)end)
                end)
                if record.entranceRugs and record.entranceRugs[edge] then
                    entrances:addOption(edge..': unlink entrance rug',player,function()
                        report(player,function()return require('TSBAstroluxStructure/EntranceAdmin').unlink(player,record,edge)end)
                    end)
                elseif clickedRug and not closed then
                    entrances:addOption(edge..': link this rug',player,function()
                        report(player,function()return require('TSBAstroluxStructure/EntranceAdmin').link(player,record,edge,clickedRug)end)
                    end)
                end
            end
            menu:addOption('Save furnishings and inventory',player,function()
                report(player,function()
                    local capture=require 'TSBAstroluxStructure/DecorCapture'
                    local profile,why=capture.capture(record)
                    if not profile then return nil,why end
                    player:Say('Saved '..#profile.objects..' furnishings and their inventory for future pastes.')
                    return true
                end)
            end)
            menu:addOption('Remove this showroom',player,function()
                local modal=ISModalRichText:new(100,100,520,230,
                    'Remove only this lab prototype? <LINE> Clear all people and loose items first. Original ground is retained.',
                    true,nil,function(_,button)
                        if button.internal=='YES' then report(player,function() local removed,reason=builder.remove(player,x,y); if removed then player:Say('Astrolux Motors prototype removed.') end; return removed,reason end) end
                    end,playerNum)
                modal:initialise();modal:addToUIManager()
            end)
            else
            menu:addOption('Place furnished showroom here',player,function()
                report(player,function()
                    local plan,why=builder.preview(player,x,y,true);if not plan then return nil,why end
                    local text='Paste a complete Astrolux Motors showroom here? <LINE> '..
                        'Includes the glass tower, gray bordered floor, eight sliding door leaves and the saved furnishings and container inventories. <LINE> '..
                        'Pasted inventory is copied; the original is kept. Kiosks receive fresh identities and need new vehicle delivery areas. Existing showrooms and their purchases are retained. <LINE> '..
                        'Stand outside the footprint and clear the site first.'
                    local modal=ISModalRichText:new(100,100,620,310,text,true,nil,function(_,button)
                        if button.internal=='YES' then report(player,function()
                            local record,reason=builder.paste(player,x,y)
                            if record then player:Say('Astrolux showroom pasted with saved furnishings and inventory. Configure its new kiosks.') end
                            return record,reason
                        end) end
                    end,playerNum)
                    modal:initialise();modal:addToUIManager();return true
                end)
            end)
            end
            break
        end
    end
end)
