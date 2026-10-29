-- Replace the old drawn strips/fake rocker with native persistent fixtures.
local C=require 'TSBCeilingLights'
local M={};local ticks=0
local positions={{3,3},{8,3},{3,8},{8,8},{6,6}}
local function state()
 if isClient() or isServer() or getNumActivePlayers()~=1 or not getWorld() or
  not require('AstroluxBayTest/TestWorld').enabled() then return end
 local s=ModData.get('TSBAstroluxCombined12.v1')
 if s and s.ready and s.x and s.y then return s end
end
local function find(sq,key)
 local list=sq:getObjects()
 for i=0,list:size()-1 do local o=list:get(i)
  if o:getModData().TSBAstroluxCeilingV1==key then return o end
 end
end
local function create(sq,sprite,key)
 local old=find(sq,key);if old then return old end
 local spr=getSprite(sprite)
 if not spr or spr:getName()~=sprite then return end
 local o=IsoLightSwitch.new(getCell(),sq,spr,sq:getRoomID())
 o:getModData().TSBAstroluxCeilingV1=key
 o:addLightSourceFromSprite()
 sq:AddSpecialObject(o);sq:RecalcAllWithNeighbours(true)
 return o
end
-- Retire test battery mode; native electricity and bulb behavior remain authoritative.
local function provision(o)
 require('TSBAstroluxStructure/Electricity').retireTestBattery(o,o:getModData().TSBAstroluxCeilingPowerV2)
end

function M.update()
 local s=state();if not s or not getCell() then return end
 -- Preflight all squares and assets before adding anything.
 local squares={}
 for i,p in ipairs(positions) do
  squares[i]=getCell():getGridSquare(s.x+p[1],s.y+p[2],0)
  if not squares[i] then return end
 end
 local wall=getCell():getGridSquare(s.x+9,s.y+12,0)
 if not wall then return end
 for _,n in ipairs({'TSBAstroluxCeiling_0','TSBAstroluxCeilingSwitch_0'}) do
  local spr=getSprite(n);if not spr or spr:getName()~=n then return end
 end
 local switch=find(wall,'switch')
 if not switch then
  if s.nativeCeilingLightsRevision then return end
  switch=create(wall,'TSBAstroluxCeilingSwitch_0','switch')
  if not switch then return end
  switch:setActive(s.showroomLights~=false,false,true)
 end
 provision(switch)
 for i,sq in ipairs(squares) do
  local panel=find(sq,'panel'..i)
  -- A completed migration never respawns a panel that a player picked up.
  if not panel and (not s.nativeCeilingLightsRevision or (i==5 and s.nativeCeilingLightsRevision<2)) then
   panel=create(sq,'TSBAstroluxCeiling_0','panel'..i)
   if not panel then return end
  end
  if panel then
   provision(panel)
   if not panel:getModData()[C.key] then C.bind(panel,switch) end
   C.refresh(panel)
  end
 end
 s.nativeCeilingLightsRevision=2
end
-- The old overlay calls this method. Fixtures are now deliberately invisible.
function M.draw() end
function M.refresh() M.update() end
Events.OnTick.Add(function()
 ticks=ticks+1;if ticks%60==0 then
  local ok,why=pcall(M.update)
  if not ok then print('[Astrolux Ceiling] '..tostring(why)) end
 end
end)
return M
