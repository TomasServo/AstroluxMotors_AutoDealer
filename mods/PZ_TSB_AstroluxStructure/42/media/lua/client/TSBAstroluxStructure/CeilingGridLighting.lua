-- Pasted rooms lack compiled room metadata. Supplement only powered,
-- installed ceiling panels for which the native grid light cannot operate.
local Ceiling=require 'TSBCeilingLights'
local Electricity=require 'TSBAstroluxStructure/Electricity'
local Power=require 'TSBAstroluxStructure/FixturePower'
local function fixture(o)return Ceiling.isPanel(o)or Power.isTowerLamp(o)end
local M={};local tracked=setmetatable({},{__mode='k'});local active={};local ticks=0
function M.shouldLight(o)
 if not fixture(o)or o:getObjectIndex()<0 then return false end
 local tag=o:getModData().TSBAstroluxCeilingV1
 if Ceiling.isPanel(o)and(type(tag)~='string'or not tag:match('^panel[1-5]$'))then return false end
 local sq=o:getSquare();local cell=getCell()
 if not sq or not cell or cell:getGridSquare(sq:getX(),sq:getY(),sq:getZ())~=sq then return false end
 -- Public canSwitchLight delegates to native electricity with a bulb and no battery mode.
 -- hasElectricityAround is private and cannot be called from Lua.
 if o:getUseBattery()or not o:getBulbItem()or not o:isActivated()or o:canSwitchLight()then return false end
 if Ceiling.isPanel(o)then
  local switch,linked=Ceiling.resolveSwitch(o)
  if linked and(not switch or not switch:isActivated())then return false end
 end
 return Electricity.square(sq)
end
local function clear(o)
 local a=active[o];if a then a.cell:removeLamppost(a.source);active[o]=nil end
end
function M.refresh(o)
 if not M.shouldLight(o)then clear(o);return end
 local sq=o:getSquare();local cell=getCell();local a=active[o]
 if a and(a.cell~=cell or a.square~=sq)then clear(o);a=nil end
 if not a then
  local radius=6
  if not Ceiling.isPanel(o)then
   local lights=o:getLights();if lights:size()>0 then radius=lights:get(0):getRadius()end
  end
  local light=cell:addLamppost(sq:getX(),sq:getY(),sq:getZ(),o:getPrimaryR(),o:getPrimaryG(),o:getPrimaryB(),radius)
  if light then a={cell=cell,source=light,square=sq};active[o]=a end
 end
 if a then a.source:setR(o:getPrimaryR());a.source:setG(o:getPrimaryG());a.source:setB(o:getPrimaryB())end
end
local function visit(sq)
 if not sq then return end
 local objects=sq:getObjects()
 for i=0,objects:size()-1 do local o=objects:get(i);if fixture(o)then tracked[o]=true end end
end
Events.LoadGridsquare.Add(visit)
Events.OnObjectAdded.Add(function(o)if fixture(o)then tracked[o]=true end end)
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%30~=0 then return end
 local cell=getCell()
 if cell then for i=0,getNumActivePlayers()-1 do local p=getSpecificPlayer(i)
  if p then for x=-12,12 do for y=-12,12 do visit(cell:getGridSquare(math.floor(p:getX())+x,math.floor(p:getY())+y,p:getZ()))end end end
 end end
 for o in pairs(tracked)do M.refresh(o);if o:getObjectIndex()<0 then tracked[o]=nil end end
end)
return M
