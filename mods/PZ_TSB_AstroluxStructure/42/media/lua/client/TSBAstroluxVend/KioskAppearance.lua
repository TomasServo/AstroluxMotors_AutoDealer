-- Keep powered glow and outage cover attached to the native kiosk render.
-- No sprite/identity replacement: native furniture and order state stay intact.
local Detail=require 'TSBAstroluxVend/TextureDetail'
local Electricity=require 'TSBAstroluxStructure/Electricity'
local M={};local tracked=setmetatable({},{__mode='k'});local elapsed=0
function M.refresh(o)
 if not o or o:getObjectIndex()<0 then return end
 local sp=o:getSprite();local name=sp and sp:getName()
 if type(name)~='string' or not name:match('^TSBAstroluxKiosk_[0-3]$') then return end
 Detail.apply()
 local powered=Electricity.square(o:getSquare())
 local index=tonumber(name:match('_(%d+)$'))
 local overlay=o:getOverlaySprite()
 local overlayName=overlay and overlay:getName()
 local own=type(overlayName)=='string' and (overlayName:match('^TSBAstroluxKioskScreenOff_[01]$') or overlayName:match('^TSBAstroluxKioskGlow_[01]$'))
 local wanted=index<2 and ((powered and 'TSBAstroluxKioskGlow_' or 'TSBAstroluxKioskScreenOff_')..index) or nil
 -- Do not replace an unrelated overlay owned by another system.
 if not overlay or own then
  if wanted~=overlayName then o:setOverlaySprite(wanted,1,1,1,1,false) end
 end
 if tracked[o]==powered then return end
 -- Fixed native kiosk artwork has no player paint. Keep alpha opaque.
 local v=1 -- Cabinet, logo and trim remain unchanged.
 o:setCustomColor(ColorInfo.new(v,v,v,1))
 o:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_REDRAW)
 tracked[o]=powered
end
function M.visit(sq)
 if not sq then return end
 local objects=sq:getObjects()
 for i=0,objects:size()-1 do M.refresh(objects:get(i)) end
end
Events.LoadGridsquare.Add(M.visit)
Events.OnObjectAdded.Add(M.refresh)
Events.OnTick.Add(function()
 elapsed=elapsed+1;if elapsed<30 then return end;elapsed=0
 for o in pairs(tracked)do if o:getObjectIndex()<0 then tracked[o]=nil else M.refresh(o)end end
 for i=0,getNumActivePlayers()-1 do local player=getSpecificPlayer(i)
  if player then local x,y=math.floor(player:getX()),math.floor(player:getY())
   for dx=-8,8 do for dy=-8,8 do M.visit(getCell():getGridSquare(x+dx,y+dy,player:getZ()))end end
  end
 end
end)
return M
