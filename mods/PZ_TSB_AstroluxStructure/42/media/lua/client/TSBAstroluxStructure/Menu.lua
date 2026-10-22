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
            context:addOption('Astrolux Motors lab: preview structure here',player,function()
                report(player,function()
                    local plan,reason=builder.preview(player,x,y)
                    if not plan then return nil,reason end
                    local text='Build the structure prototype at '..x..', '..y..'? <LINE> '..
                        '8 x 8 native ground floor and ceiling, with the preserved car-display tower above. Two-tile openings centered on all four sides; sliding doors deferred. <LINE> '..
                        'Stand outside the 9 x 9 tower footprint. Keep the 11 x 11 site clear. Ground is preserved. <LINE> '..
                        'Upper tower is display artwork only. No upper walkable floors or dealership systems. <LINE> '..
                        'Disposable lab save only. Native cutaway and roof behavior still require testing.'
                    local modal=ISModalRichText:new(100,100,620,320,text,true,nil,function(_,button)
                        if button.internal=='YES' then report(player,function() local placed,reason=builder.place(player,x,y); if placed then player:Say('Astrolux Motors structure placed.') end; return placed,reason end) end
                    end,playerNum)
                    modal:initialise();modal:addToUIManager()
                    return true
                end)
            end)
            context:addOption('Astrolux Motors lab: remove prototype',player,function()
                local modal=ISModalRichText:new(100,100,520,230,
                    'Remove only this lab prototype? <LINE> Clear all people and loose items first. Original ground is retained.',
                    true,nil,function(_,button)
                        if button.internal=='YES' then report(player,function() local removed,reason=builder.remove(player); if removed then player:Say('Astrolux Motors prototype removed.') end; return removed,reason end) end
                    end,playerNum)
                modal:initialise();modal:addToUIManager()
            end)
            context:addOption('Astrolux Motors lab: apply car-display tower above ground floor',player,function()
                report(player,function() return builder.convert(player) end)
            end)
            context:addOption('Astrolux Motors lab: apply transparent walls and open entrances',player,function()
                report(player,function() return TSBAstroluxClearWalls.apply(player) end)
            end)
            context:addOption('Astrolux Motors lab: apply bordered gray tile floor',player,function()
                report(player,function() return TSBAstroluxFlooring.apply(player) end)
            end)
            context:addOption('Astrolux Motors lab: record showroom furnishings',player,function()
                report(player,function()
                    local capture=TSBAstroluxDecorCapture
                    if not capture then capture=require 'TSBAstroluxStructure/DecorCapture' end
                    local profile,reason=capture.capture()
                    if not profile then return nil,reason end
                    player:Say('Recorded '..#profile.objects..' showroom furnishings as the default layout.')
                    return true
                end)
            end)
            break
        end
    end
end)
