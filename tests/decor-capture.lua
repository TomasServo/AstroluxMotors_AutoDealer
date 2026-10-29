package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/server/?.lua;'..package.path
package.preload['Moveables/ISMoveableSpriteProps']=function()return {}end
local callbacks={}
Events={OnGameStart={Add=function(fn)callbacks.start=fn end},OnTick={Add=function(fn)callbacks.tick=fn end}}
local D=require 'TSBAstroluxStructure/DecorCapture'
local function obj(name,md,movable)
    return {transmitModData=function()end,getModData=function()return md or {}end,getObjectName=function()return 'IsoThumpable'end,getRenderYOffset=function()return 34 end,
        getChildSprites=function()return nil end,getSprite=function()return {getName=function()return name end,
        getProperties=function()return {has=function(_,key)return (key=='IsMoveAble' and movable) or key=='Facing' end,get=function()return 'N'end}end}end}
end
local floor=obj('floor',{},true)
local lamp=obj('lighting_indoor_02_32',{private='not copied'},true)
local kiosk=obj('TSBAstroluxKiosk_2',{TSBAstroluxKiosk=true,TSBAstroluxVend='terminal:9'},true)
local wall=obj('glass',{TSBAstroluxStructure='tower:1'},true)
local contents={floor,lamp,kiosk,wall,obj('decal',{},false)}
local missing=false
local cell={getGridSquare=function(_,x,y,z)
    assert(x>=100 and x<=108 and y>=200 and y<=208 and z==0)
    if missing then return nil end
    local entries=x==102 and y==203 and contents or {floor}
    return {getFloor=function()return floor end,getObjects=function()return {size=function()return #entries end,get=function(_,i)return entries[i+1]end}end}
end}
local record={x=100,y=200,id='tower:1',status='ready'}
local profile=assert(D.survey(record,cell))
assert(#profile.objects==2)
assert(profile.objects[1].sprite=='lighting_indoor_02_32' and profile.objects[1].dx==2 and profile.objects[1].dy==3)
assert(profile.objects[1].facing=='N' and profile.objects[1].renderYOffset==34)
assert(not profile.objects[1].private and not profile.objects[2].TSBAstroluxVend)
assert(profile.objects[2].service=='freshAstroluxKiosk')
local output
function getFileWriter(name,create,append)
    -- Native B42 permits txt/json/log/ini/cfg, but rejects lua output.
    if not name:match('%.txt$') then return nil end
    assert(name==D.filename and create and not append)
    return {write=function(_,s)output=s end,close=function()end}
end
assert(D.write(profile));local decoded=assert((loadstring or load)(output))()
assert(#decoded.objects==2 and decoded.objects[2].sprite=='TSBAstroluxKiosk_2')
missing=true;assert(not D.survey(record,cell));missing=false
contents={floor,wall};assert(not D.survey(record,cell));contents={floor,lamp,kiosk,wall}
local defaults={};local now=0
function getTimestampMs()return now end
function isClient()return false end
function isServer()return false end
function getWorld()return {getWorld=function()return 'AstroluxStructureLab'end}end
function getCell()return cell end
function getSpecificPlayer()return nil end
ModData={getOrCreate=function(key)return key=='TSBAstroluxStructure.Lab.v1' and {tower=record} or defaults end}
assert(not callbacks.start and not callbacks.tick,'No automatic capture hooks');assert(D.capture(record));assert(defaults.profile and defaults.sourceTower==record.id)
local original=defaults.profile;contents={floor,lamp};now=9000;assert(defaults.profile==original)
local nativeWriter=getFileWriter
defaults.profile=nil
function getFileWriter()return nil end
assert(not D.capture());assert(not defaults.profile,'Failed export must not install a partial capture')
getFileWriter=nativeWriter;assert(D.capture(record));assert(#defaults.profile.objects==1,'Explicit retry captures current layout')
print('PASS: decoration survey records relative furniture layout, exports reloadable default, excludes shell/private state and requires explicit capture; failed export retains previous state')
local saved=dofile('mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/TSBAstroluxStructure/DefaultFurnishings.lua')
assert(saved.width==8 and saved.height==8 and #saved.objects==19)
local kiosks,coffee,cactus,lamp=0,0,false,false
for _,entry in ipairs(saved.objects)do
    assert(not entry.inventory and not entry.modData and not entry.terminal and not entry.TSBAstroluxVend)
    if entry.service=='freshAstroluxKiosk' then kiosks=kiosks+1 end
    if entry.coffeeSupplies then coffee=coffee+1;assert(entry.dx==0 and entry.dy==7)end
    if entry.sprite=='vegetation_indoor_01_3' then cactus=true;assert(entry.renderYOffset==-34)end
    if entry.sprite=='lighting_indoor_02_35' then lamp=true;assert(entry.renderYOffset==-4 and entry.order==2)end
end
assert(kiosks==2 and coffee==1 and cactus and lamp)
local sink=saved.objects[19]
assert(sink.sprite=='fixtures_sinks_01_11' and sink.dx==1 and sink.dy==7 and sink.facing=='N' and sink.renderYOffset==2)
print('PASS: captured default plus requested sink retains coffee-cabinet role, fresh kiosks, tabletop offsets and object order without private state')
