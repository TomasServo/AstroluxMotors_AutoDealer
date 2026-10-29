-- Private manual diagnostic. Never creates or edits a structure automatically.
local P=require 'AstroluxDiagonalLab/Plan'
local M={};TSBAstroluxDiagonalCornerLab=M
local tag='TSBAstroluxDiagonalCornerLab'
local function state()return ModData.get(P.key)end
local function message(player,text)if player then player:Say(text)end;print('[Diagonal Corner Lab] '..text)end
local function integer(n)return type(n)=='number' and n==n and math.abs(n)<1000000 and n==math.floor(n)end
local function inBounds(r,player)
 return player and not player:isDead() and player:getZ()==0 and
  (player:getX()-r.x)^2+(player:getY()-r.y)^2<=900
end
function M.objects(r)
 local found={}
 for x=r.x,r.x+6 do for y=r.y,r.y+6 do for z=0,1 do
  local sq=getCell():getGridSquare(x,y,z)
  if sq then local list=sq:getObjects();for i=0,list:size()-1 do
   local obj=list:get(i);if obj:getModData()[tag]==r.id then found[#found+1]={sq=sq,obj=obj}end
  end end
 end end end
 return found
end
function M.preflight(player,x,y)
 if not P.enabled() then return nil,'Exact disposable save and single-player debug only.' end
 if not integer(x) or not integer(y) or not inBounds({x=x,y=y},player) then return nil,'Choose loaded ground within 30 tiles.' end
 local existing=state();if existing and existing.ready then return nil,'Remove the current test room first.'end
 for sx=x-1,x+7 do for sy=y-1,y+7 do for z=0,1 do
  local sq=getCell():getGridSquare(sx,sy,z)
  if z==0 and (not sq or not sq:TreatAsSolidFloor() or not sq:isOutside()) then return nil,'Choose an empty outdoor site.'end
  if sq then
   if sq:getMovingObjects():size()>0 or sq:getStaticMovingObjects():size()>0 or sq:getWorldObjects():size()>0 then return nil,'Clear people, animals and loose items from the test site.'end
   local list=sq:getObjects()
   for i=0,list:size()-1 do if z~=0 or list:get(i)~=sq:getFloor() then return nil,'Existing object or ceiling blocks the test site.'end end
  end
 end end end
 local vehicles=getCell():getVehicles():iterator()
 while vehicles:hasNext() do local v=vehicles:next()
  if v:getX()>=x-2 and v:getX()<=x+8 and v:getY()>=y-2 and v:getY()<=y+8 then return nil,'Move the nearby vehicle first.'end
 end
 local plan=P.plan(x,y)
 for _,group in ipairs({plan.windows,plan.roof})do for _,e in ipairs(group)do
  local sprite=getSprite(e.sprite);if not sprite or sprite:getName()~=e.sprite then return nil,'Required sprite is missing: '..e.sprite end
 end end
 return plan
end
function M.place(player,x,y)
 local plan,reason=M.preflight(player,x,y);if not plan then message(player,reason);return false end
 local record={id=P.key..':'..x..':'..y,x=x,y=y,ready=false,guides=true,hideBacking=false}
 local made={}
 local ok,why=pcall(function()
  for _,e in ipairs(plan.windows)do
   local sq=getCell():getGridSquare(e.x,e.y,0)
   local obj=IsoWindow.new(getCell(),sq,getSprite(e.sprite),e.north);obj:setPermaLocked(true)
   obj:getModData()[tag]=record.id;obj:getModData().diagonalPane=e.pane
   made[#made+1]={sq=sq,obj=obj};sq:AddSpecialObject(obj);sq:RecalcAllWithNeighbours(true)
  end
  for _,e in ipairs(plan.roof)do
   local sq=getCell():getGridSquare(e.x,e.y,1) or getCell():createNewGridSquare(e.x,e.y,1,true)
   assert(sq and sq:getObjects():size()==0,'Upper square changed after preflight')
   -- Only empty upper squares are touched; existing ground floors stay intact.
   local obj=IsoObject.new(getCell(),sq,getSprite(e.sprite))
   obj:getModData()[tag]=record.id;made[#made+1]={sq=sq,obj=obj}
   sq:AddTileObject(obj);sq:RecalcAllWithNeighbours(true)
  end
 end)
 if not ok then
  local clean=true
  for i=#made,1,-1 do local e=made[i];if not pcall(function()if e.obj:getObjectIndex()>=0 then e.sq:RemoveTileObject(e.obj);e.sq:RecalcAllWithNeighbours(true)end end)then clean=false end end
  if not clean then record.ready=true;record.hold=true;local s=ModData.getOrCreate(P.key);for k,v in pairs(record)do s[k]=v end end
  message(player,'Placement failed: '..tostring(why)..(clean and ' Objects rolled back.' or ' Partial test held for cleanup.'));return false
 end
 record.ready=true;local s=ModData.getOrCreate(P.key);for k,v in pairs(record)do s[k]=v end
 message(player,'Test room placed. Orange lines show real grid collision; cyan glass is diagonal.');return true
end
function M.setBacking(player)
 local r=state();if not P.enabled() or not r or not r.ready or not inBounds(r,player)then return end
 r.hideBacking=not r.hideBacking
 for _,e in ipairs(M.objects(r))do if e.obj:getModData().diagonalPane then e.obj:setDoRender(not r.hideBacking)end end
 message(player,r.hideBacking and 'Backing hidden for appearance only; collision is unchanged.' or 'Native backing visible for interaction tests.')
end
function M.report(player)
 local r=state();if not P.enabled() or not r or not r.ready or not inBounds(r,player)then return end
 local objects=M.objects(r);local pairs={{0,0},{0,0},{0,0}}
 for _,e in ipairs(objects)do local pane=e.obj:getModData().diagonalPane
  if pane and instanceof(e.obj,'IsoWindow')then pairs[pane][1]=pairs[pane][1]+1;if e.obj:isDestroyed()then pairs[pane][2]=pairs[pane][2]+1 end end
 end
 for i=1,3 do print('[Diagonal Corner Lab] pane '..i..' native edges='..pairs[i][1]..' smashed='..pairs[i][2])end
 for _,sample in ipairs({{2,2},{4,3},{5,3},{5,4}})do local sq=getCell():getGridSquare(r.x+sample[1],r.y+sample[2],0)
  print('[Diagonal Corner Lab] square '..sample[1]..','..sample[2]..' outside='..tostring(sq and sq:isOutside())..' nativeRoom='..tostring(sq and sq:getRoom()~=nil))
 end
 local sq=player:getCurrentSquare();message(player,'Outside='..tostring(sq and sq:isOutside())..'; detailed pane/room report in console.')
end
function M.smash(player,pane)
 local r=state();if not P.enabled() or not r or not r.ready or not inBounds(r,player)then return end
 for _,e in ipairs(M.objects(r))do if e.obj:getModData().diagonalPane==pane and instanceof(e.obj,'IsoWindow')then e.obj:smashWindow(true,false)end end
 message(player,'Smashed both native edges of diagonal pane '..pane..'. Test each opening separately.')
end
function M.remove(player)
 local r=state();if not P.enabled() or not r or not r.ready or not inBounds(r,player)then return end
 local objects=M.objects(r)
 for _,e in ipairs(objects)do
  if e.sq:getMovingObjects():size()>0 or e.sq:getStaticMovingObjects():size()>0 or e.sq:getWorldObjects():size()>0 or e.obj:getContainer()then message(player,'Clear occupants and loose items from test tiles before cleanup.');return end
  local list=e.sq:getObjects();for i=0,list:size()-1 do local other=list:get(i)
   if other~=e.sq:getFloor() and other:getModData()[tag]~=r.id then message(player,'Foreign object on a test square; cleanup stopped.');return end
  end
 end
 for _,e in ipairs(objects)do e.sq:RemoveTileObject(e.obj);e.sq:RecalcAllWithNeighbours(true)end
 r.ready=false;message(player,'Owned test windows and ceiling removed. Existing ground left intact.')
end
local function menu(index,context,worldobjects,test)
 if test or not P.enabled()then return end
 local player=getSpecificPlayer(index);if not player then return end
 local sq=worldobjects[1] and worldobjects[1]:getSquare();if not sq then return end
 local root=context:addOption('Diagonal corner prototype');local sub=ISContextMenu:getNew(context);context:addSubMenu(root,sub)
 local r=state()
 if not r or not r.ready then sub:addOption('Place empty test room here',player,M.place,sq:getX(),sq:getY());return end
 sub:addOption('Print collision / room / damage report',player,M.report)
 sub:addOption(r.hideBacking and 'Show native window backing' or 'Hide backing for visual inspection',player,M.setBacking)
 sub:addOption(r.guides and 'Hide orange collision guide' or 'Show orange collision guide',nil,function()r.guides=not r.guides end)
 for i=1,3 do sub:addOption('Smash test pane '..i..' (both grid edges)',player,M.smash,i)end
 sub:addOption('Remove owned test room',player,M.remove)
end
Events.OnFillWorldObjectContextMenu.Add(menu)
return M
