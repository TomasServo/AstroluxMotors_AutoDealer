local W=require 'AstroluxBayTest/TestWorld'
Events.OnFillWorldObjectContextMenu.Add(function(playerNum,context,objects,test)
 if test or not (W.city() or W.corner())then return end
 local player=getSpecificPlayer(playerNum)
 if not player or player:isDead() or player:getZ()~=0 then return end
 local root=context:addOption('Place Astrolux building...')
 local sub=ISContextMenu:getNew(context);context:addSubMenu(root,sub)
 local function start(clear)require('AstroluxBayTest/PlacementCursor').start(player,clear)end
 sub:addOption('Preview zone and clear existing objects',nil,function()start(true)end)
 sub:addOption('Preview on empty ground only',nil,function()start(false)end)
end)
