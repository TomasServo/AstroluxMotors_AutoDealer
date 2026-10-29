local D={}
function D.apply(db,t,args,isAdmin)
 if not isAdmin then error('Administrator access required.',0)end
 if args.confirmed~=true then error('Confirm delivery zone deletion first.',0)end
 if not t.spawnArea then error('This kiosk has no saved delivery zone.',0)end
 if args.revision~=(t.spawnArea.revision or 0)then error('Delivery zone changed. Refresh before deleting.',0)end
 for _,o in pairs(db.orders or {})do
  if o.terminal==t.id and o.status~='delivered' then error('Resolve outstanding orders before deleting the delivery zone.',0)end
 end
 t.spawnArea=nil;t.deliveryBorder=false
end
return D
