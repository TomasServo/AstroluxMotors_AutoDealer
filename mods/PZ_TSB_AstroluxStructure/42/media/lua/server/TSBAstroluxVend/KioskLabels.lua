local M={}
function M.ensure(db)
 local used,missing={},{};local maximum=db.kioskDisplaySerial or 0
 for id,t in pairs(db.terminals or {})do
  local n=t.displayNumber
  if type(n)=='number' and n>0 and n==math.floor(n)and not used[n]then used[n]=true;maximum=math.max(maximum,n)
  else missing[#missing+1]={id=id,t=t}end
 end
 table.sort(missing,function(a,b)
  if a.t.x~=b.t.x then return a.t.x<b.t.x end
  if a.t.y~=b.t.y then return a.t.y<b.t.y end
  return tostring(a.id)<tostring(b.id)
 end)
 for _,entry in ipairs(missing)do maximum=maximum+1;entry.t.displayNumber=maximum end
 db.kioskDisplaySerial=maximum
end
function M.mark(obj,t,x,y)
 local label=nil -- Numbers now render once at the saved zone center.
 local md=obj:getModData()
 if md.TSBAstroluxZoneNumber~=label then md.TSBAstroluxZoneNumber=label;if obj:getObjectIndex()>=0 then obj:transmitModData()end end
end
return M
