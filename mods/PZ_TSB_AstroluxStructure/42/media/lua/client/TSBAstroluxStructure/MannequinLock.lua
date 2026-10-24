-- Local showroom display protection. Not a multiplayer security boundary.
if isClient() or isServer() then return end
local R=require 'TSBAstroluxStructure/Records'
local Menus=require 'TSBAstroluxVend/ContextMenu'
local L={key='TSBAstroluxDisplayOutfitLocked'}
function L.locked(o)
 return o and instanceof(o,'IsoMannequin') and o:getModData()[L.key]==true or false
end
function L.container(c)return c and c.getParent and L.locked(c:getParent()) or false end
local function showroom(o)
 local sq=o and o:getSquare();if not sq or sq:getZ()~=0 then return false end
 for _,r in ipairs(R.all())do
  local size=r.combinedSize or 8
  if r.status=='ready' and sq:getX()>=r.x and sq:getX()<r.x+size and sq:getY()>=r.y and sq:getY()<r.y+size then return true end
 end
 return false
end
function L.set(player,o,value)
 if not getDebug() or not player or player:isDead() or not o or not instanceof(o,'IsoMannequin') or o:getObjectIndex()<0 or not showroom(o) then return false end
 local sq=o:getSquare()
 if player:getZ()~=sq:getZ() or (player:getX()-sq:getX())^2+(player:getY()-sq:getY())^2>9 then return false end
 o:getModData()[L.key]=value==true or nil
 o:transmitModData()
 return true
end
local function blocked(a)return L.container(a.srcContainer) or L.container(a.destContainer)end
local function moving(a)
 return L.locked(a.object) or L.locked(a.moveProps and a.moveProps.object) or L.locked(a.origMoveProps and a.origMoveProps.object)
end
local function wrap(class,name,predicate,result)
 if not class or type(class[name])~='function' then return end
 local key='TSBAstroluxLock_'..name
 if class[key]then return end
 local original=class[name]
 class[name]=function(self,...)if predicate(self,...)then return result end;return original(self,...)end
 class[key]=true
end
function L.install()
 wrap(ISInventoryTransferAction,'isValid',blocked,false)
 wrap(ISInventoryTransferAction,'transferItem',blocked,nil)
 for _,name in ipairs({'ISLootWindowObjectControlHandler_MannequinWearAll','ISLootWindowObjectControlHandler_MannequinSwitchOutfit'})do
  local handler=_G[name]
  wrap(handler,'shouldBeVisible',function(h)return L.locked(h.object)end,false)
  wrap(handler,'perform',function(h)return L.locked(h.object)end,nil)
 end
 wrap(ISMoveableSpriteProps,'canPickUpMoveable',function(_,_,_,o)return L.locked(o)end,false)
 wrap(ISMoveablesAction,'isValid',moving,false)
 wrap(ISMoveablesAction,'complete',moving,false)
end
Events.OnGameStart.Add(L.install)
local ticks=0
Events.OnTick.Add(function()ticks=ticks+1;if ticks%120==0 then L.install()end end)
Events.OnFillWorldObjectContextMenu.Add(function(n,context,objects,test)
 if test or not getDebug()then return end
 local player=getSpecificPlayer(n)
 for _,o in ipairs(objects)do
  if instanceof(o,'IsoMannequin') and showroom(o)then
   local display=o;local locked=L.locked(display)
   local menu=Menus.section(context,'Showroom')
   menu:addOption(locked and 'Unlock display outfit' or 'Lock display outfit',player,function()
    if L.set(player,display,not locked)then player:Say(locked and 'Display unlocked. You can change its outfit.' or 'Display outfit locked.')
    else player:Say('Stand beside a showroom mannequin to change its lock.')end
   end)
   break
  end
 end
end)
return L
