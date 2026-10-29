-- Read-only, bounded diagnostic. No object, sprite, room or save mutations.
if isClient() or isServer() then return end
local M={}
local function read(fn)
 local ok,v=pcall(fn);return ok and tostring(v) or 'unavailable'
end
function M.describe(o,p)
 local sp=o:getSprite();local sq=o:getSquare();local props=sp and sp:getProperties()
 local out={'sprite='..tostring(sp and sp:getName()),'xy='..sq:getX()..','..sq:getY()}
 local function add(k,fn)out[#out+1]=k..'='..read(fn)end
 add('alpha',function()return o:getAlpha(0)end)
 add('target',function()return o:getTargetAlpha(0)end)
 add('render',function()return o:getDoRender()end)
 add('room',function()return sq:getRoom()end)
 add('sameRoom',function()return sq:getRoom()==p:getSquare():getRoom()end)
 for _,name in ipairs({'solid','solidtrans','cutN','cutW','attachedSurface','attachedCeiling','NeverCutaway'})do
  local flag=IsoFlagType[name]
  if flag then
   add('sprite.'..name,function()return props and props:has(flag)end)
   add('square.'..name,function()local properties=sq:getProperties();return properties and properties:has(flag)end)
  end
 end
 return table.concat(out,' ')
end
local frames,samples=0,0
local last={}
function M.sample()
 if not getDebug() or getNumActivePlayers()~=1 or not require('AstroluxBayTest/TestWorld').enabled() then return end
 local p=getSpecificPlayer(0);local cell=getCell();local db=ModData.get('TSBAstroluxStructure.Lab.v1')
 if not p or not cell or not db then return end
 local records={};if db.tower then records[#records+1]=db.tower end
 for _,r in pairs(db.showrooms or {})do records[#records+1]=r end
 local seen={}
 for _,r in ipairs(records)do
  if not seen[r.id] and r.status=='ready' and r.combinedSize==12 and math.abs(p:getX()-r.x)<40 and math.abs(p:getY()-r.y)<40 then
   seen[r.id]=true
   for _,c in ipairs({{0,0,'NW'},{12,0,'NE'},{0,12,'SW'},{12,12,'SE'}})do
    local sq=cell:getGridSquare(r.x+c[1],r.y+c[2],0)
    if sq then
     local list=sq:getObjects()
     for i=0,list:size()-1 do
      local o=list:get(i);local sp=o:getSprite();local name=sp and sp:getName() or ''
      if string.find(name,'TSBAstroluxGroundPillar_',1,true)==1 then
       local key=tostring(r.id)..':'..c[3];local report=M.describe(o,p)
       if last[key]~=report then
        last[key]=report
        print('[Astrolux Pillar Audit] '..key..' player='..p:getX()..','..p:getY()..' '..report)
       end
      end
     end
    end
   end
  end
 end
end
local function tick()
 frames=frames+1;if frames%30~=0 then return end
 samples=samples+1
 local ok,err=pcall(M.sample)
 if not ok then print('[Astrolux Pillar Audit] stopped: '..tostring(err)) end
 if not ok or samples>=600 then Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick)
return M
