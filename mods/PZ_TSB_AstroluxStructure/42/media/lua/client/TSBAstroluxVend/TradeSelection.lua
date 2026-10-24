require 'ISUI/ISScrollingListBox'
require 'ISUI/ISTickBox'
local U={}
function U.invalidate(p)
 p.tradeQuote=nil;p.tradeRows:clear();p.tradeAccept:setEnable(false);p.tradeDecline:setEnable(false)
 local any=false;for _ in pairs(p.tradeSelected or {})do any=true;break end
 p.tradeAppraise:setEnable(p.tradeEnabled==true and any);p.tradeDecline:setEnable(any)
end
function U.ids(p)
 local ids={};for id in pairs(p.tradeSelected or {})do ids[#ids+1]=id end;table.sort(ids);return ids
end
function U.clear(p)
 p.tradeSelected={};p.tradeAll:setSelected(1,false);U.invalidate(p)
end
function U.create(p,widget,button,request)
 p.tradeSelected={};p.tradeCandidates={}
 p.tradeAll=widget('trade',ISTickBox:new(20,135,240,28,'AstroluxTradeAll',p,function(panel)
  panel.tradeSelected={}
  if panel.tradeAll:isSelected(1)then for _,row in ipairs(panel.tradeCandidates)do if row.eligible then panel.tradeSelected[row.id]=true end end end
  U.invalidate(panel)
 end));p.tradeAll:addOption('Trade In All');p.tradeAll:setSelected(1,false)
 button('trade',280,135,180,'Refresh Vehicles',function(panel)U.clear(panel);request(panel,'open')end)
 p.tradeVehicleList=widget('trade',ISScrollingListBox:new(20,195,440,300));p.tradeVehicleList.itemheight=42;p.tradeVehicleList.selected=0
 p.tradeVehicleList.doDrawItem=function(list,y,item)
  local row=item.item;local chosen=p.tradeSelected[row.id];local c=row.eligible and 1 or 0.55
  list:drawText((chosen and '[x] ' or '[ ] ')..row.label..' [#'..row.id..']',8,y+3,c,c,c,1,UIFont.Small)
  local info=row.eligible and ('$'..row.amount..' | '..row.script..' | '..row.x..', '..row.y)or row.reason
  list:drawText(tostring(info):sub(1,76),8,y+21,c,c,c,1,UIFont.Small)
  return y+42
 end
 p.tradeVehicleList.onMouseDown=function(list,x,y)
  local entry=list.items[list:rowAt(x,y)]
  if entry and entry.item.eligible then local id=entry.item.id
   p.tradeSelected[id]=not p.tradeSelected[id] or nil;p.tradeAll:setSelected(1,false);U.invalidate(p)
  end
  return true
 end
 p.tradeRows=widget('trade',ISScrollingListBox:new(500,195,460,300));p.tradeRows.selected=0
 p.tradeAppraise=button('trade',20,510,300,'Appraise Selected Vehicles',function(panel)U.invalidate(panel);request(panel,'tradeQuote')end)
 p.tradeAccept=button('trade',340,510,300,'Accept Selected Trade-Ins',function(panel)
  request(panel,'tradeAccept');U.invalidate(panel)
 end)
 p.tradeDecline=button('trade',660,510,300,'Clear Selection / Keep Cars',function(panel)
  request(panel,'tradeDecline');U.clear(panel)
 end)
 p.tradeAccept:setEnable(false);p.tradeDecline:setEnable(false);p.tradeAppraise:setEnable(false)
end
function U.receive(p,data)
 p.tradeQuote=data.tradeQuote;p.tradeEnabled=data.tradeInsEnabled==true;p.tradeRules=data.tradeRules
 p.tradeCandidates=data.tradeVehicles or {};p.tradeSelected={};p.tradeAll:setSelected(1,false)
 p.tradeVehicleList:clear();p.tradeVehicleList.selected=0
 for _,row in ipairs(p.tradeCandidates)do p.tradeVehicleList:addItem(row.label,row)end
 p.tradeRows:clear();p.tradeRows.selected=0
 for _,vehicle in ipairs(data.tradeQuote and data.tradeQuote.vehicles or {})do
  p.tradeSelected[vehicle.id]=true
  p.tradeRows:addItem(vehicle.script..' [#'..vehicle.id..'] - $'..vehicle.amount,vehicle)
  for _,part in ipairs(vehicle.parts or {})do
   p.tradeRows:addItem('  '..part.id..' | '..(part.missing and 'Missing' or (tostring(part.condition)..'%'))..' | $'..part.value..' / $'..part.maximum,part)
  end
 end
 p.tradeAppraise:setEnable(p.tradeEnabled and #U.ids(p)>0)
 p.tradeAccept:setEnable(data.tradeQuote~=nil and data.tradeQuote.token~=nil and data.tradeQuote.amount>0)
 p.tradeDecline:setEnable(data.tradeQuote~=nil)
 if data.tradeQuote then p:showTab('trade')end
end
function U.render(p)
 local rules=p.tradeRules or {};local q=p.tradeQuote
 p:drawText(p.tradeEnabled and 'Choose vehicles in this kiosk delivery zone.' or 'Buybacks are disabled by the administrator.',20,110,1,1,1,1,UIFont.Small)
 local total=0;for _,row in ipairs(p.tradeCandidates or {})do if p.tradeSelected[row.id]then total=total+(row.amount or 0)end end
 p:drawText(q and ('Appraised '..#q.vehicles..' vehicles | Total: $'..q.amount..' | Expires in 60 seconds')or ('Selected: '..#U.ids(p)..' | Estimated total: $'..total),500,140,1,0.9,0.7,1,UIFont.Small)
 p:drawText('Select Vehicles (None Selected by Default)',20,175,1,1,1,1,UIFont.Small)
 p:drawText('Itemized Appraisal by Vehicle and Part',500,175,1,1,1,1,UIFont.Small)
 p:drawText('Base '..tostring(rules.buybackPercent or 50)..'% | Minimum parts '..tostring(rules.minimumBuybackParts or 75)..'% | Empty cars, engine off, everyone out.',20,545,0.85,0.85,0.85,1,UIFont.Small)
end
return U
