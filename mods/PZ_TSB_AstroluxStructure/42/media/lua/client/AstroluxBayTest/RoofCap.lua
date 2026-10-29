-- Approved chamfered roof, exported from its shared model at native PZ scale.
-- Decorative only: existing caller owns visibility/cutaway; no world/save edits.
local combinedLights=require 'AstroluxBayTest/CombinedLights'
local M={}
function M.draw(panel,x,y)
 local day=getTexture('media/textures/AstroluxRoofChamferDay.png')
 local night=getTexture('media/textures/AstroluxRoofChamferNight.png')
 if not day or not night then return end
 local off=getTexture('media/textures/AstroluxRoofChamferOff.png')
 local zoom=getCore():getZoom(0)
 local sq=getCell():getGridSquare(x+10,y+10,1)
 local light=sq and math.max(.12,math.min(1,sq:getLightLevel(0))) or 1
 -- Measured camera: +x=(64,32), +y=(-64,32), +z=(0,-192).
 -- The model's world point (6,6,4.6) is pixel (640,448) in both exports.
 local sx=(IsoUtils.XToScreen(x+6,y+6,4.6,0)-IsoCamera.getOffX(0))/zoom
 local sy=(IsoUtils.YToScreen(x+6,y+6,4.6,0)-IsoCamera.getOffY(0))/zoom
 local left,top=sx-640/zoom,sy-448/zoom
 -- Both powered exports contain luminous signs. Use the matching non-emissive render during an outage.
 if (combinedLights.brightness or 0)<=0 then
  if not off then return end
  panel:drawTextureScaled(off,left,top,1280/zoom,896/zoom,1,light,light,light)
  return
 end
 local blend=(light-.12)/.88
 -- Keep the neon lit at night; interpolate the approved day/night appearance.
 if blend<=0 then
  panel:drawTextureScaled(night,left,top,1280/zoom,896/zoom,1,1,1,1)
 elseif blend>=1 then
  panel:drawTextureScaled(day,left,top,1280/zoom,896/zoom,1,1,1,1)
 else
  panel:drawTextureScaled(night,left,top,1280/zoom,896/zoom,1,1,1,1)
  panel:drawTextureScaled(day,left,top,1280/zoom,896/zoom,blend,1,1,1)
 end
end
return M
