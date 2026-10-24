local M={}
local Records=require 'TSBAstroluxStructure/Records'
function M.record(player)
 if isClient() or isServer() or not getDebug() or not player or player:isDead() or player:getZ()~=0
 or not getWorld() or not tostring(getWorld():getWorld()):match('^AstroluxStructureLab') then
  return nil,'Available in the local debug showroom.'
 end
 local r=Records.near(player:getX(),player:getY());local n=r and (r.combinedSize or 8)
 if not r or r.status~='ready' or player:getX()<r.x-3 or player:getX()>r.x+n+3 or player:getY()<r.y-3 or player:getY()>r.y+n+3 then
  return nil,'Stand at the showroom to change these settings.'
 end
 return r
end
function M.entrance(player,edge,enabled)
 local r,why=M.record(player);if not r then return nil,why end
 if edge~='north' and edge~='south' and edge~='east' and edge~='west' then return nil,'Unknown entrance.' end
 local open=not (r.closedEntrances and r.closedEntrances[edge]==true)
 if open==(enabled==true) then return true end
 return require('TSBAstroluxStructure/EntranceAdmin').toggle(player,r,edge)
end
function M.coffee(player,enabled)
 local r,why=M.record(player);if not r then return nil,why end
 enabled=enabled==true
 if (r.coffeeRestockEnabled~=false)==enabled then return true end
 r.coffeeRestockEnabled=enabled
 -- Resume with a fresh real-time interval; never take a new inventory snapshot.
 r.coffeeRestockResumeAt=enabled and (getTimestamp()+600) or nil
 return true
end
return M
