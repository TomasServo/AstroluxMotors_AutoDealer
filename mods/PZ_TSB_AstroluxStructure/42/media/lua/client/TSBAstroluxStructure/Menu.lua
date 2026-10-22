require 'ISUI/ISModalRichText'
local function report(player,fn)
    local ok,result=pcall(fn)
    player:Say(ok and 'Astrolux Motors structure lab: complete.' or tostring(result))
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
            context:addOption('Astrolux Motors lab: preview structure here',player,function()
                report(player,function()
                    builder.preview(player,x,y)
                    local text='Build the structure prototype at '..x..', '..y..'? <LINE> '..
                        '8 x 8 interior; five levels and a solid roof. Four native ground-floor doors. <LINE> '..
                        'Stand outside the 11 x 11 clearance area. Ground is preserved. <LINE> '..
                        'No stairs yet: inspect upper levels with debug tools. No cars or dealership systems. <LINE> '..
                        'Disposable lab save only. Native cutaway and roof behavior still require testing.'
                    local modal=ISModalRichText:new(100,100,620,320,text,true,nil,function(_,button)
                        if button.internal=='YES' then report(player,function() builder.place(player,x,y) end) end
                    end,playerNum)
                    modal:initialise();modal:addToUIManager()
                end)
            end)
            context:addOption('Astrolux Motors lab: remove prototype',player,function()
                local modal=ISModalRichText:new(100,100,520,230,
                    'Remove only this lab prototype? <LINE> Clear all people and loose items first. Original ground is retained.',
                    true,nil,function(_,button)
                        if button.internal=='YES' then report(player,function() builder.remove(player) end) end
                    end,playerNum)
                modal:initialise();modal:addToUIManager()
            end)
            break
        end
    end
end)
