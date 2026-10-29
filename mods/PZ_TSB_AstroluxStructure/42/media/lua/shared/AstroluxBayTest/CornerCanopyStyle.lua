-- Shared geometry for the reversible private showroom-corner preview.
local W=require 'AstroluxBayTest/TestWorld'
local M={glassTop=193/192,thickness=.10}
function M.active()
 if TSBAstroluxReleaseVisualSite then return true end
 local preview=rawget(_G,'TSBAstroluxShowroomDiagonalPreview')
 return W.corner() and preview and preview.enabled and preview.site()~=nil or false
end
function M.shape(x,y)
 local inner={x==0 and 3 or 9,y==0 and 3 or 9}
 local endpoints={
  ['0:0']={{0,3},{3,0}}, ['9:0']={{9,0},{12,3}},
  ['0:9']={{3,12},{0,9}}, ['9:9']={{12,9},{9,12}},
 }
 local edge=endpoints[x..':'..y];assert(edge,'Unknown showroom corner')
 return {edge[1],edge[2],inner}
end
return M
