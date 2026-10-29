require 'ISUI/ISRichTextPanel'
require 'ISUI/ISModalRichText'
local M={}
local function plain(s)return tostring(s or '-'):gsub('<','('):gsub('>',')')end
function M.create(panel,button)
 panel.groups.orders={}
 local rows=panel.settings.recoveryOrders or {}
 local choice=panel:addControl('orders',ISComboBox:new(10,55,900,28,panel,nil))
 local details=panel:addControl('orders',ISRichTextPanel:new(10,100,900,245))
 details.autosetheight=false;details:addScrollBars()
 local function selected()return rows[choice.selected]end
 local cancel
 local function update()
  local r=selected()
  cancel:setEnable(r~=nil and r.allowed==true)
  cancel.tooltip=r and r.reason or 'No outstanding orders at this kiosk.'
  details.text=r and ('Order '..plain(r.id)..' | Customer: '..plain(r.actor)..' <LINE> Vehicle: '..plain(r.script)..
   ' | Recorded vehicle ID: '..plain(r.vehicleId)..' <LINE> Status: '..plain(r.status)..' | Price: '..plain(r.price)..
   ' <LINE> '..plain(r.reason)..' <LINE> Original failure: '..plain(r.error)..
   ' <LINE> Cancellation preserves an audit record. It never refunds money, issues keys, deletes vehicles or retries delivery.')
   or 'No outstanding orders at this kiosk. Use Refresh Orders to check again.'
  details:paginate()
 end
 choice.onChange=update
 for _,r in ipairs(rows)do choice:addOption('Order '..r.id..' - '..r.actor..' - '..r.status)end
 button('orders',10,365,270,'Refresh Orders',function(p)p.send({action='orderRefresh'})end).tooltip='Read current outstanding orders for all customers at this kiosk.'
 cancel=button('orders',300,365,610,'Cancel Selected Order (No Refund)',function(p)
  local r=selected();if not r or not r.allowed then return end
  local text='Cancel order '..plain(r.id)..' for '..plain(r.actor)..'? <LINE> No money or vehicles will change.'
  if r.manual then text=text..' <LINE> IMPORTANT: unloaded vehicles are not detected here. <LINE> Select YES only after independently verifying that the partial vehicle was removed from the saved world. Otherwise select NO.'
  else text=text..' <LINE> This unpaid order has not started spawning.' end
  local submitted=false
  local modal=ISModalRichText:new(100,100,680,280,text,true,nil,function(_,b)
   if b.internal=='YES' and not submitted then
    submitted=true;p.send({action='orderCancel',orderActor=r.actor,orderId=r.id,confirmed=true,vehicleRemovalVerified=r.manual==true})
   end
  end,p.player)
  modal:initialise();modal:addToUIManager();modal:bringToTop()
 end)
 update()
end
return M
