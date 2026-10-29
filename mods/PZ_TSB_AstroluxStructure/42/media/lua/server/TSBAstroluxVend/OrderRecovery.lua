-- Recovery changes order bookkeeping only; never money, keys or world vehicles.
local M={}
function M.check(db,o,vehicles)
 if not o then return false,'Order no longer exists.' end
 if o.payment~='vanillaCash' or o.paymentTiming~='onDelivery' then
  return false,'Bank and legacy prepaid orders require payment-provider reconciliation.'
 end
 if o.status~='hold' and o.status~='queued' then return false,'Only held or unpaid queued orders can be cancelled.' end
 if o.paymentCommitted or o.keyIssued then return false,'Payment or key was committed; manual reconciliation required.' end
 local p=db.payments and db.payments[o.actor]
 local matching=p and p.receipt=='astroluxRebuild:'..tostring(o.id)
 if p and (p.status=='processing' or p.status=='hold') then return false,'Cash payment is uncertain; reconcile it first.' end
 if matching and p.status~='failed' then return false,'Cash rollback is not confirmed.' end
 local partial=o.spawnStarted or o.vehicleId~=nil or o.status=='hold'
 if partial and not (matching and p.status=='failed') then return false,'Matching failed cash receipt required.' end
 local it=vehicles:iterator()
 while it:hasNext() do
  local v=it:next()
  if tostring(v:getModData().TSBAstroluxVendOrder)==tostring(o.id)
    or (o.vehicleId~=nil and tostring(v:getId())==tostring(o.vehicleId)) then
   return false,'A matching vehicle is loaded. Inspect/remove it before cancelling; this control never deletes vehicles.'
  end
 end
 if partial then return true,'Cash rollback confirmed. No matching vehicle is loaded; this does NOT prove absence. Verify removal across the saved world before cancelling.',true end
 return true,'Unpaid queue; spawning has not started. Cancellation changes no money or vehicles.',false
end
function M.rows(db,terminal,vehicles)
 local rows={}
 for actor,o in pairs(db.orders or {})do
  if o.terminal==terminal and o.status~='delivered' then
   local allowed,reason,manual=M.check(db,o,vehicles)
   rows[#rows+1]={actor=actor,id=tostring(o.id),script=o.script,status=o.status,
    vehicleId=o.vehicleId,price=o.price,error=o.error,allowed=allowed,reason=reason,manual=manual==true}
  end
 end
 table.sort(rows,function(a,b)return a.actor<b.actor end)
 return rows
end
function M.cancel(db,terminal,args,vehicles,administrator,now)
 if args.confirmed~=true or type(args.orderActor)~='string' or type(args.orderId)~='string' then return false,'Select and confirm an order first.' end
 local o=db.orders and db.orders[args.orderActor]
 if not o or tostring(o.id)~=args.orderId or o.actor~=args.orderActor or o.terminal~=terminal then return false,'Order changed or belongs to another kiosk. Refresh the list.' end
 local allowed,reason,manual=M.check(db,o,vehicles)
 if not allowed then return false,reason end
 if manual and args.vehicleRemovalVerified~=true then return false,'Administrator must verify that the partial vehicle was removed from the saved world.' end
 db.orderRecoveryAudit=db.orderRecoveryAudit or {}
 local key=tostring(o.id)
 if db.orderRecoveryAudit[key] then return false,'An audit record already exists; manual inspection required.' end
 local p=db.payments and db.payments[o.actor]
 db.orderRecoveryAudit[key]={order=o,payment=p and p.receipt=='astroluxRebuild:'..key and p or nil,
  administrator=administrator,time=now,action='cancel_without_financial_or_vehicle_changes',vehicleRemovalVerified=manual==true}
 db.orders[args.orderActor]=nil
 return true,'Order '..key..' cancelled and archived. No money, keys or vehicles changed.'
end
return M
