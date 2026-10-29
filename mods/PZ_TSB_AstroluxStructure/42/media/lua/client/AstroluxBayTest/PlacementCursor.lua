-- Native building cursors load with server Lua in single player. Define this
-- cursor lazily when the menu is used, after both Lua environments are ready.
local cached
local function cursorClass()
if cached then return cached end
require 'BuildingObjects/ISBuildingObject'
require 'BuildingObjects/ISBuildCursorMouse'
require 'ISUI/ISModalRichText'
local Cursor=ISBuildCursorMouse:derive('AstroluxPlacementCursor')
local function message(player,text)
 local m=ISModalRichText:new(100,100,680,330,text,false,nil,nil,player:getPlayerNum());m:initialise();m:addToUIManager()
end
function Cursor:rotateKey()end
function Cursor:rotateMouse()end
function Cursor:isValid(square)
 if not square or square:getZ()~=0 then self.review=nil;self.checked=nil;self.reason='Choose loaded ground at level 0.';return false end
 local x,y=square:getX(),square:getY();local now=getTimestampMs()
 if self.x~=x or self.y~=y or not self.checked or now-self.checked>=350 then
  self.x=x;self.y=y;self.checked=now
  local ok,result,why=pcall(require('AstroluxBayTest/SiteClearance').inspect,self.character,x,y,self.clear)
  if ok and type(result)=='table' then
   self.review=result;self.reason=nil
  else
   self.review=nil
   self.reason=tostring((ok and why or result) or 'Site validation returned no result. Move the cursor and try again.')
  end
 end
 return self.review~=nil
end
function Cursor:render(x,y,z,square)
 self:isValid(square)
 if z~=0 then return end
 if not self.tile then self.tile=IsoSprite.new();self.tile:LoadSingleTexture('carpentry_02_56')end
 local r,g,b=.12,.85,.35
 if not self.review then r,g,b=1,.16,.12 elseif #self.review.objects>0 then r,g,b=1,.64,.12 end
 -- 12x12 floor plus the east/south anchor tiles used by wall and furniture pieces.
 -- Every square eligible for clearing is visibly marked, including the border.
 for dx=0,12 do for dy=0,12 do
  self.tile:RenderGhostTileColor(x+dx,y+dy,0,r,g,b,(dx==12 or dy==12)and .55 or .28)
 end end
 -- Cyan entrance markers show all four door positions; layout rotation is fixed.
 for _,v in ipairs({{5,0},{6,0},{0,5},{0,6},{12,5},{12,6},{5,12},{6,12}})do
  self.tile:RenderGhostTileColor(x+v[1],y+v[2],0,.12,.85,1,.75)
 end
 self.tooltipName='Astrolux building placement'
 self.tooltipTxt='12 x 12 building. Highlighted 13 x 13 zone includes wall anchors. <LINE> Origin: '..x..', '..y..' <LINE> '
 if self.review then
  self.tooltipTxt=self.tooltipTxt..(#self.review.objects==0 and 'GREEN: site is empty.' or 'AMBER: '..#self.review.objects..' objects will be cleared; '..self.review.containers..' containers / '..self.review.items..' contents.')
  self.tooltipTxt=self.tooltipTxt..' <LINE> Left-click to review placement. Right-click or Escape to cancel.'
 else self.tooltipTxt=self.tooltipTxt..'RED: '..tostring(self.reason or 'Choose loaded ground at level 0.')end
 self:renderTooltip()
end
function Cursor:tryBuild(x,y,z)
 if self.pending or z~=0 then return end
 local site=require 'AstroluxBayTest/PerformanceSite'
 local ok,plan,reason,profile,review=pcall(site.preview,self.character,x,y,self.clear)
 if not ok or not plan then message(self.character,tostring((ok and reason or plan) or 'Placement validation returned no result; nothing changed.'));return end
 self.pending=true;getCell():setDrag(nil,self.player)
 local text='Place Astrolux at '..x..', '..y..'? <LINE> '
 if #review.objects>0 then
  text=text..'CLEAR '..#review.objects..' existing objects, including '..review.containers..' containers and '..review.items..' contained or dropped items. <LINE> '
 else text=text..'No existing objects need clearing. <LINE> 'end
 text=text..'Only the highlighted 13 x 13 zone, ground through level 4, is cleared. Ground terrain remains. <LINE> This becomes the active tower preview; earlier showrooms remain protected. <LINE> Confirm clear and place?'
 local m=ISModalRichText:new(100,100,700,390,text,true,nil,function(_,button)
  if button.internal~='YES'then return end
  local success,record,why=pcall(site.place,self.character,x,y,review)
  if success and record then self.character:Say('Astrolux placed. Site clearing complete.')
  else message(self.character,tostring((success and why or record) or 'Placement returned no building; inspect the site before retrying.'))end
 end,self.player)
 m:initialise();m:addToUIManager()
end
function Cursor:onSquareSelected(square)
 if square then self:tryBuild(square:getX(),square:getY(),square:getZ())end
end
function Cursor.start(player,clear)
 -- Native new() stores isValid directly on the instance. Supply the real
 -- callbacks; a placeholder would shadow the derived class's validator.
 local o=ISBuildCursorMouse.new(Cursor,player,Cursor.onSquareSelected,Cursor.isValid)
 o.clear=clear==true;o.dragNilAfterPlace=true;o:setSprite('carpentry_02_56')
 getCell():setDrag(o,player:getPlayerNum())
 return o
end
cached=Cursor
return Cursor
end
return {start=function(player,clear)return cursorClass().start(player,clear)end}
