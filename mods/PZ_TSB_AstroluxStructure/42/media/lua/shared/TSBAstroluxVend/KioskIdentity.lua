-- Client-only visual objects can change list positions. Never trust an index
-- when a stable terminal ID was supplied; resolve only inside the selected square.
local M={}
function M.resolve(objects,args)
 if not objects then return nil end
 if args.kioskId~=nil then
  if type(args.kioskId)~='string' or #args.kioskId==0 or #args.kioskId>200 then return nil end
  local match
  for i=0,objects:size()-1 do
   local obj=objects:get(i)
   if obj:getModData().TSBAstroluxVend==args.kioskId then
    if match then return nil end -- Ambiguous registration must not select arbitrarily.
    match=obj
   end
  end
  return match
 end
 -- Compatibility with older requests; caller still validates registration & range.
 if type(args.index)=='number' and args.index==math.floor(args.index)
  and args.index>=0 and args.index<objects:size()then return objects:get(args.index)end
end
return M
