local A=require 'TSBAstroluxVend/SpawnAreas'
local G={}
function G.apply(db,t,args,isAdmin)
 if not isAdmin then error('Administrator access required.',0)end
 if not t.spawnArea then error('Save a delivery zone first.',0)end
 if args.revision~=(t.spawnArea.revision or 0)then error('Delivery zone changed. Refresh before applying spacing.',0)end
 local gap,why=A.spacing(args.gap)
 if args.gap==nil or gap==nil then error(why or 'Enter car spacing in tiles.',0)end
 local rows=args.rowGap;if rows==nil then rows=t.spawnArea.rowGap end
 if rows~=nil then local valid,msg=A.spacing(rows);if valid==nil then error(msg,0)end;rows=valid end
 for _,o in pairs(db.orders or {})do
  if o.terminal==t.id and o.status~='delivered'then error('Resolve outstanding orders before changing spacing.',0)end
 end
 local area={};for k,v in pairs(t.spawnArea)do area[k]=v end
 area.gap=gap;area.rowGap=rows;area.revision=(area.revision or 0)+1;t.spawnArea=area
 return area
end
return G
