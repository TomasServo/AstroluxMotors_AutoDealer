require 'ISUI/ISUIElement'
local P=require 'AstroluxDiagonalLab/Plan'
local Lab=require 'AstroluxDiagonalLab/Lab'
local View=ISUIElement:derive('AstroluxDiagonalCornerView')
-- Match the existing TSBAstroluxClearGlass source art: clear interior,
-- 1px borders at 2x tile scale, translucent charcoal and pale top highlight.
-- Keep the three physical panes, all XY endpoints and native backing unchanged.
local border={44/255,53/255,57/255,155/255}
local highlight={218/255,238/255,243/255,110/255}
local top=193/192 -- existing artwork is 193 pixels tall at 2x tile scale
-- Decorative full-screen UI must explicitly decline every mouse event.
-- The base ISUIElement methods return nil, which can consume world clicks.
function View:onMouseDown()return false end
function View:onMouseUp()return false end
function View:onRightMouseDown()return false end
function View:onRightMouseUp()return false end
function View:onMouseMove()return false end
function View:onMouseWheel()return false end
function View:render()
 if not P.enabled()then return end
 local r=ModData.get(P.key);local player=getSpecificPlayer(0)
 if not r or not r.ready or not player or player:getZ()~=0 or (player:getX()-r.x)^2+(player:getY()-r.y)^2>1600 then return end
 local zoom=getCore():getZoom(0)
 local function p(x,y,z)return (IsoUtils.XToScreen(r.x+x,r.y+y,z,0)-IsoCamera.getOffX(0))/zoom,(IsoUtils.YToScreen(r.x+x,r.y+y,z,0)-IsoCamera.getOffY(0))/zoom end
 local function line(a,b,z,width,color)
  local ax,ay=p(a[1],a[2],z);local bx,by=p(b[1],b[2],z);local dx,dy=bx-ax,by-ay;local length=math.sqrt(dx*dx+dy*dy)
  if length==0 then return end
  local nx,ny=-dy/length*width/zoom,dx/length*width/zoom
  self:drawPolygon(nil,ax+nx,ay+ny,bx+nx,by+ny,bx-nx,by-ny,ax-nx,ay-ny,color[1],color[2],color[3],color[4] or 1)
 end
 local broken={0,0,0};local edges={0,0,0}
 for _,e in ipairs(Lab.objects(r))do local pane=e.obj:getModData().diagonalPane
  if pane and instanceof(e.obj,'IsoWindow')then
   e.obj:setDoRender(not r.hideBacking)
   edges[pane]=edges[pane]+1;if e.obj:isDestroyed()then broken[pane]=broken[pane]+1 end
  end
 end
 for i,pane in ipairs(P.plan(0,0).panes)do
  local a,b=pane.a,pane.b
  -- Existing showroom panes have zero interior alpha. Do not add tint.
  line(a,b,0,.5,border);line(a,b,top,.5,highlight)
 end
 for i=0,3 do local x,y=6-i,3+i;local ax,ay=p(x,y,0);local bx,by=p(x,y,top)
  self:drawPolygon(nil,ax-.5/zoom,ay,ax+.5/zoom,ay,bx+.5/zoom,by,bx-.5/zoom,by,border[1],border[2],border[3],border[4])
 end
 if r.guides then
  local stair={{6,3},{5,3},{5,4},{4,4},{4,5},{3,5},{3,6}}
  for i=1,#stair-1 do line(stair[i],stair[i+1],.012,1.3,{1,.48,.04})end
 end
 local tx,ty=p(4.5,4.5,1.15)
 self:drawText('PROTOTYPE: orange = actual grid collision',tx-145,ty,1,.75,.28,1,UIFont.Small)
end
-- The test-room overlay shares the tower's UI owner. Separate backMost()
-- siblings exchange order each UIManager update, putting this glass over the
-- tower roof on alternating frames. Preserve the sample even before a tower
-- is pasted, but always draw it first whenever both are visible.
local M={View=View}
function M.active()
 if not P.enabled()then return false end
 local r=ModData.get(P.key);local player=getSpecificPlayer(0)
 return r and r.ready and player and player:getZ()==0
  and (player:getX()-r.x)^2+(player:getY()-r.y)^2<=1600 or false
end
function M.draw(panel)View.render(panel)end
TSBAstroluxDiagonalPrototypeView=M
return M
