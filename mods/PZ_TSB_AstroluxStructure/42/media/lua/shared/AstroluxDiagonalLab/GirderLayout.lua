-- Same eight joints as the approved glass/canopy layout. Original supports remain separate.
local L={height=193/192,tag='TSBAstroluxNativeHelperV1',artKind='diagonalGirderArt',blockKind='diagonalGirderBlock',positions={
 {0,3,0},{3,0,1},{9,0,2},{12,3,3},{12,9,0},{9,12,1},{3,12,2},{0,9,3},
}}
function L.sprite(p)return 'TSBAstroluxDiagonalPillar_'..p[3]end
function L.present(site)
 local result={}
 for _,p in ipairs(L.positions)do
  local sq=getCell():getGridSquare(site.x+p[1],site.y+p[2],0)
  if sq then local objects=sq:getObjects();for i=0,objects:size()-1 do
   local o=objects:get(i);local data=o:getModData()[L.tag];local sprite=o:getSprite()
   if data and data.owner==site.recordId and data.kind==L.artKind and o:getDoRender()
    and sprite and sprite:getName()==L.sprite(p)then result[p[1]..':'..p[2]]=p;break end
  end end
 end
 return result
end
return L
