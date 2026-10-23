-- Trusted server-side extensions only. No client registration or account data.
local R={providers={}}
function R.register(id,adapter)
 assert(type(id)=='string' and #id<=40 and id:match('^[a-z][a-z0-9_-]*$'),'Invalid bank adapter ID')
 assert(not R.providers[id],'Bank adapter ID already registered')
 assert(type(adapter)=='table' and type(adapter.label)=='string' and #adapter.label>0 and #adapter.label<=80,'Invalid bank label')
 for _,key in ipairs({'detect','balance','charge'})do assert(type(adapter[key])=='function','Missing bank '..key)end
 R.providers[id]=adapter
end
function R.available(id)
 local provider=R.providers[id];if not provider then return false end
 local ok,active=pcall(provider.detect)
 return ok and active==true
end
function R.list()
 local ids={};for id in pairs(R.providers)do if R.available(id)then ids[#ids+1]=id end end
 table.sort(ids);return ids
end
function R.get(id)
 if not R.available(id)then error('Selected bank is unavailable. Refresh and choose a payment method; no automatic cash charge.',0)end
 return R.providers[id]
end
-- Optional TSB adapter: inspect capabilities lazily, never require its mod.
R.register('tsb',{
 label='TSB Banking',
 detect=function()
  local bank=SpacebarEconomyServer
  return bank~=nil and bank.autoVendBridgeVersion==1 and type(bank.serviceBalance)=='function' and type(bank.chargeService)=='function'
 end,
 balance=function(actor)return SpacebarEconomyServer.serviceBalance(actor)end,
 charge=function(actor,amount,receipt,apply)
  return SpacebarEconomyServer.chargeService(actor,amount,receipt,apply,'vehiclePurchase')
 end,
})
return R
