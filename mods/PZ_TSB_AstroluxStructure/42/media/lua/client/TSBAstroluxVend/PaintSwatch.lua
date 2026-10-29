-- Selection feedback only: never changes vehicle scripts or purchase data.
local M={}
function M.rgb(paint)
 if not paint or type(paint.h)~='number' or type(paint.s)~='number' or type(paint.v)~='number' then return end
 local h,s,v=paint.h,paint.s,paint.v
 if h~=h or s~=s or v~=v or h<0 or h>1 or s<0 or s>1 or v<0 or v>1 then return end
 local n=(h%1)*6;local i=math.floor(n);local f=n-i
 local p,q,t=v*(1-s),v*(1-s*f),v*(1-s*(1-f))
 local colors={{v,t,p},{q,v,p},{p,v,t},{p,q,v},{t,p,v},{v,p,q}}
 return colors[i+1]
end
function M.label(paint)
 if not paint then return 'Selected paint: factory appearance' end
 local name=tostring(paint.label or 'Factory appearance')
 if M.rgb(paint) then return 'Selected paint: '..name..' (approx.)' end
 return 'Selected design: '..name
end
function M.draw(panel,paint)
 local color=M.rgb(paint);local x=500
 if color then
  panel:drawRect(x,478,24,18,1,color[1],color[2],color[3])
  panel:drawRectBorder(x,478,24,18,1,.8,.8,.8)
  x=x+32
 end
 local text=M.label(paint);local max=960-x
 local tm=getTextManager()
 if tm:MeasureStringX(UIFont.Small,text)>max then
  while #text>0 and tm:MeasureStringX(UIFont.Small,text..'...')>max do text=text:sub(1,-2) end
  text=text..'...'
 end
 panel:drawText(text,x,478,.9,.9,.9,1,UIFont.Small)
end
return M
