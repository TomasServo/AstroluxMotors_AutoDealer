local Trade=require 'TSBAstroluxVend/TradeIn'
local Appraisal=require 'TSBAstroluxVend/Appraisal'
local Profiles=require 'TSBAstroluxVend/AppraisalProfiles'
local Amount=require 'TSBAstroluxVend/Amount'
local C=require 'TSBAstroluxVend/Config'
local B={}
local function fail(message)error(message,0)end
local function settled(db,vehicle)
 local id=vehicle:getModData().TSBAstroluxVendOrder
 if id then for _,order in pairs(db.orders or {})do
  if order.id==id and order.status~='delivered'then fail('Resolve the vehicle purchase hold before trading it in.')end
 end end
end
function B.resolve(terminal,ids)
 if type(ids)~='table' or #ids==0 then fail('Select at least one vehicle to appraise.')end
 local wanted,count={},0
 for key,id in pairs(ids)do
  if type(key)~='number' or key<1 or key>#ids or key~=math.floor(key) or type(id)~='number' or id~=id or id~=math.floor(id) or math.abs(id)==math.huge or wanted[id]then fail('Invalid or duplicate vehicle selection.')end
  wanted[id]=true;count=count+1
 end
 if count~=#ids then fail('Invalid vehicle selection.')end
 local found={};local all=getCell():getVehicles():iterator()
 while all:hasNext()do local v=all:next();if wanted[v:getId()] and Trade.inArea(terminal,v)then found[v:getId()]=v end end
 local result={};for _,id in ipairs(ids)do if not found[id]then fail('A selected vehicle is no longer loaded inside the delivery zone. Refresh vehicles.')end;result[#result+1]=found[id]end
 return result
end
function B.new(db,adapter)
 db.tradeIns=db.tradeIns or {};db.tradeSerial=db.tradeSerial or 0;db.tradeAudit=db.tradeAudit or {}
 for _,r in pairs(db.tradeIns)do if r.status=='processing'then r.status='hold';r.error='Interrupted trade-in; inspect the recorded vehicles and cash.'end end
 local self={quotes={}}
 local function available(player)
  if not Trade.enabled(db)then fail('Vehicle buybacks are disabled.')end
  local actor=tostring(player:getUsername());local previous=db.tradeIns[actor]
  if previous and (previous.status=='hold' or previous.status=='processing')then fail('Previous trade-in needs administrator inspection.')end
  return actor
 end
 local function grade(player,terminal,vehicle,retail)
  local valid,why=Trade.validate(player,terminal,vehicle,db.pricing);if not valid then fail(why)end
  settled(db,vehicle)
  local price=retail(vehicle);if not price then fail('Vehicle is not in the enabled Astrolux Motors catalog.')end
  local a=Appraisal.calculate(vehicle,price,((db.pricing or {}).buybackPercent or C.tradeInRate*100)/100,((db.pricing or {}).damagePercent or 100)/100)
  Trade.checkParts(a,db.pricing)
  if a.amount<1 then fail('No payable offer: this vehicle appraises to $0.')end
  return a
 end
 function self:list(player,terminal,retail)
  local result={};if not terminal.spawnArea then return result end
  local previous=db.tradeIns[tostring(player:getUsername())]
  local allowed=Trade.enabled(db) and not (previous and (previous.status=='hold' or previous.status=='processing'))
  local hold=Trade.enabled(db) and 'Previous trade-in needs administrator inspection.' or 'Vehicle buybacks are disabled.'
  local all=getCell():getVehicles():iterator()
  while all:hasNext()do
   local vehicle=all:next()
   if Trade.inArea(terminal,vehicle)then
    local script=vehicle:getScript():getFullName()
    local translated=getTextOrNull and getTextOrNull('IGUI_VehicleName'..vehicle:getScript():getName())
    local row={id=vehicle:getId(),script=script,label=translated or script,x=math.floor(vehicle:getX()),y=math.floor(vehicle:getY()),eligible=false}
    local ok,a=false,hold
    if allowed then
     if not Profiles.vehicles[script]then
      a='This vehicle has no reviewed trade-in appraisal profile.'
     else
      local valid,why=Trade.validate(player,terminal,vehicle,db.pricing)
      if not valid then a=why else ok,a=pcall(grade,player,terminal,vehicle,retail)end
     end
    end
    if ok then row.eligible=true;row.amount=a.amount;row.maximum=a.maximum else row.reason=tostring(a)end
    result[#result+1]=row
   end
  end
  table.sort(result,function(a,b)return a.id<b.id end);return result
 end
 function self:quote(player,terminal,vehicles,retail,revision)
  local actor=available(player);self.quotes[actor]=nil
  if #vehicles==0 then fail('Select at least one vehicle to appraise.')end
  local rows,public,seen={}, {}, {};local amount,totalRetail,maximum=0,0,0
  for _,v in ipairs(vehicles)do
   if seen[v:getId()]then fail('Duplicate vehicle selection.')end;seen[v:getId()]=true
   local a=grade(player,terminal,v,retail)
   rows[#rows+1]={vehicle=v,id=v:getId(),script=v:getScript():getFullName(),appraisal=a}
   public[#public+1]={id=v:getId(),script=v:getScript():getFullName(),amount=a.amount,retail=a.retail,maximum=a.maximum,parts=a.parts}
   amount=Amount.add(amount,a.amount);totalRetail=Amount.add(totalRetail,a.retail);maximum=Amount.add(maximum,a.maximum)
  end
  db.tradeSerial=db.tradeSerial+1;local token=tostring(db.tradeSerial);local expires=adapter.now()+60
  self.quotes[actor]={token=token,terminal=terminal.id,vehicles=rows,amount=amount,revision=revision,expires=expires}
  return {token=token,vehicles=public,amount=amount,retail=totalRetail,maximum=maximum,expires=expires}
 end
 function self:decline(player)self.quotes[tostring(player:getUsername())]=nil end
 function self:accept(player,terminal,token,retail,revision)
  local actor=available(player);local q=self.quotes[actor]
  if not q or q.token~=token or q.terminal~=terminal.id or q.revision~=revision or q.expires<adapter.now()then fail('Trade-in quote expired. Appraise your selection again.')end
  -- Revalidate every selected car and prepare ALL cash before removing any car.
  for _,row in ipairs(q.vehicles)do
   if row.vehicle:getId()~=row.id or row.vehicle:getScript():getFullName()~=row.script then fail('Vehicle identity changed. Appraise again.')end
   local fresh=grade(player,terminal,row.vehicle,retail)
   if fresh.fingerprint~=row.appraisal.fingerprint or fresh.amount~=row.appraisal.amount or fresh.retail~=row.appraisal.retail then self.quotes[actor]=nil;fail('Vehicle condition or price changed. Appraise your selection again.')end
  end
  local payout,weight={},0
  local function add(kind,count)
   for _=1,count do local item=adapter.create(kind);if not item then fail('Could not prepare trade-in payment.')end
    payout[#payout+1]=item;weight=weight+item:getActualWeight()
   end
  end
  add('Base.MoneyBundle',math.floor(q.amount/100));add('Base.Money',q.amount%100)
  local inventory=player:getInventory()
  if inventory:getCapacityWeight()+weight>inventory:getEffectiveCapacity(player)then fail('Make room in your main inventory for the full trade-in payment.')end
  local record={token=token,terminal=terminal.id,amount=q.amount,vehicles={},status='processing',paidItems=0,time=adapter.now()}
  for _,row in ipairs(q.vehicles)do record.vehicles[#record.vehicles+1]={id=row.id,script=row.script,amount=row.appraisal.amount,retail=row.appraisal.retail,removed=false}end
  self.quotes[actor]=nil;db.tradeIns[actor]=record
  local ok,err=pcall(function()
   for i,row in ipairs(q.vehicles)do
    row.vehicle:getModData().AstroluxTradeIn={actor=actor,token=token,index=i};record.vehicles[i].marked=true
    row.vehicle:transmitModData();row.vehicle:permanentlyRemove()
    if not row.vehicle:isRemovedFromWorld()then fail('Native vehicle removal was not confirmed.')end
    record.vehicles[i].removed=true
   end
   record.removed=true
   for _,item in ipairs(payout)do
    if inventory:AddItem(item)~=item or item:getContainer()~=inventory then fail('Cash payout was interrupted.')end
    record.paidItems=record.paidItems+1
   end
  end)
  if not ok then record.status='hold';record.error=tostring(err);fail('Trade-in batch needs administrator inspection. Do not retry; each vehicle and cash progress is recorded.')end
  record.status='paid';db.tradeAudit[#db.tradeAudit+1]={actor=actor,token=token,amount=q.amount,vehicles=record.vehicles,time=adapter.now()}
  if #db.tradeAudit>200 then table.remove(db.tradeAudit,1)end
  for _,item in ipairs(payout)do if not pcall(adapter.notify,inventory,item)then record.syncWarning=true end end
  return q.amount,#q.vehicles
 end
 return self
end
return B
