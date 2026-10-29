local M={}
local Release=require 'TSBAstroluxStructure/ReleaseSites'
local function releaseRequest(player,setting,enabled,edge)
 local r=Release.near(player);if not r then return false end
 if not require('TSBAstroluxStructure/ReleaseAccess').allowed(player)then return true,nil,'Administrator access required.'end
 require('TSBAstroluxStructure/ReleaseClient').send('setting',{id=r.id,setting=setting,enabled=enabled,edge=edge})
 return true,true
end
local Records=require 'TSBAstroluxStructure/Records'
function M.record(player)
 local released=Release.near(player);if released then if require("TSBAstroluxStructure/ReleaseAccess").allowed(player)then return released end;return nil,"Administrator access required."end
 if isClient() or isServer() or not getDebug() or not player or player:isDead() or player:getZ()~=0
 or not getWorld() or not (tostring(getWorld():getWorld()):match('^AstroluxStructureLab') or require('AstroluxBayTest/TestWorld').testMap()) then
  return nil,'Available in the local debug showroom.'
 end
 local r=Records.near(player:getX(),player:getY());local n=r and (r.combinedSize or 8)
 if not r or r.status~='ready' or player:getX()<r.x-3 or player:getX()>r.x+n+3 or player:getY()<r.y-3 or player:getY()>r.y+n+3 then
  return nil,'Stand at the showroom to change these settings.'
 end
 return r
end
function M.entrance(player,edge,enabled)
 local handled,ok,why=releaseRequest(player,"entrance",enabled,edge);if handled then return ok,why end
 local r,why=M.record(player);if not r then return nil,why end
 if edge~='north' and edge~='south' and edge~='east' and edge~='west' then return nil,'Unknown entrance.' end
 local open=not (r.closedEntrances and r.closedEntrances[edge]==true)
 if open==(enabled==true) then return true end
 return require('TSBAstroluxStructure/EntranceAdmin').toggle(player,r,edge)
end
function M.coffee(player,enabled)
 local handled,ok,why=releaseRequest(player,"coffee",enabled);if handled then return ok,why end
 local r,why=M.record(player);if not r then return nil,why end
 enabled=enabled==true
 if (r.coffeeRestockEnabled~=false)==enabled then return true end
 r.coffeeRestockEnabled=enabled
 -- Resume with a fresh real-time interval; never take a new inventory snapshot.
 r.coffeeRestockResumeAt=enabled and (getTimestamp()+600) or nil
 return true
end
-- Automatic entrance controls validate administrator access in the controller.
-- Keep this separate from legacy entrance-replacement permissions.
function M.autoDoorRecord(player)
 if Release.near(player)then return M.record(player)end
 local controller=rawget(_G,'TSBAstroluxAutomaticDoors')
 if not controller then return nil,'Available in the local showroom test.' end
 return controller.record(player)
end
function M.autoDoors(player,enabled)
 local handled,ok,why=releaseRequest(player,"automaticDoors",enabled);if handled then return ok,why end
 local controller=rawget(_G,'TSBAstroluxAutomaticDoors')
 if not controller then return nil,'Available in the local showroom test.' end
 return controller.setEnabled(player,enabled)
end
return M
