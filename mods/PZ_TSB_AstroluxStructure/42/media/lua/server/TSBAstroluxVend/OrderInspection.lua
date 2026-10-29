-- Read-only evidence for a held order. Never infer absence from unloaded cars.
local M={}
function M.inspect(db,order,vehicles)
 local receipt='astroluxRebuild:'..tostring(order.id)
 local payments=order.payment=='serverBank' and db.bankPayments or db.payments
 local attempt=payments and payments[order.actor]
 local payment='unverified'
 if attempt and attempt.receipt==receipt then payment=tostring(attempt.status) end
 local count,matched=0,nil
 local iterator=vehicles:iterator()
 while iterator:hasNext() do
  local v=iterator:next()
  if tostring(v:getModData().TSBAstroluxVendOrder)==tostring(order.id) then
   count=count+1;matched=v
  end
 end
 local evidence='no tagged vehicle loaded (not proof it is absent)'
 if count==1 then
  evidence='tagged vehicle '..tostring(matched:getId())..' at '..math.floor(matched:getX())..','..math.floor(matched:getY())
  if order.vehicleId~=nil and tostring(order.vehicleId)~=tostring(matched:getId()) then evidence=evidence..' (ID mismatch)' end
 elseif count>1 then evidence=tostring(count)..' tagged vehicles loaded; ambiguous' end
 local summary='Order '..tostring(order.id)..' ['..tostring(order.status)..']; payment '..payment..'; '..evidence..'.'
 local detail=summary..' Script='..tostring(order.script)..'; payment type='..tostring(order.payment)..
  '; recorded vehicle='..tostring(order.vehicleId)..'; key issued='..tostring(order.keyIssued==true)..
  '; payment committed flag='..tostring(order.paymentCommitted==true)..'; error='..tostring(order.error)
 return summary,detail
end
return M
