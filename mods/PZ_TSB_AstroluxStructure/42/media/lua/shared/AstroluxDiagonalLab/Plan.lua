local P={saveName='AstroluxDiagonalCornerLab_20261027',key='TSBAstroluxDiagonalCornerLab.v1',size=6}
function P.inside(x,y) return x>=0 and x<6 and y>=0 and y<6 and x+y<=7 end
function P.plan(x,y)
 local result={x=x,y=y,windows={},roof={},panes={}}
 local function window(dx,dy,north,pane)
  result.windows[#result.windows+1]={x=x+dx,y=y+dy,north=north,pane=pane,sprite='TSBAstroluxClearGlass_'..(north and 1 or 0)}
 end
 for i=0,5 do window(i,0,true);window(0,i,false) end
 for i=0,2 do window(6,i,false);window(i,6,true) end
 for i=0,2 do
  window(5-i,3+i,true,i+1);window(5-i,3+i,false,i+1)
  result.panes[i+1]={a={6-i,3+i},b={5-i,4+i}}
 end
 for dx=0,5 do for dy=0,5 do if P.inside(dx,dy) then
  result.roof[#result.roof+1]={x=x+dx,y=y+dy,z=1,sprite='floors_interior_tilesandwood_01_28'}
 end end end
 return result
end
function P.enabled()
 return getWorld and getWorld() and (tostring(getWorld():getWorld())==P.saveName or require('AstroluxBayTest/TestWorld').freshLot())
  and not isClient() and not isServer() and getDebug() and getNumActivePlayers()==1
end
-- Rendering/maintenance for already registered towers, independent of debug.
-- Site validation remains in ShowroomPreview.site; no placement is enabled here.
function P.runtimeEnabled()
 return getWorld and getWorld() and not isClient() and not isServer() and getNumActivePlayers()==1
end
return P
