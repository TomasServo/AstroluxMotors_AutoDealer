require 'ISUI/ISRichTextPanel'
require 'ISUI/ISModalRichText'
local M={}
local function text(s)return tostring(s or '-'):gsub('<','('):gsub('>',')')end
function M.create(panel,button)
 panel.groups.tradeRecovery={}
 local rows=panel.settings.recoveryTrades or {}
 local choice=panel:addControl('tradeRecovery',ISComboBox:new(10,40,900,28,panel,nil))
 local details=panel:addControl('tradeRecovery',ISRichTextPanel:new(10,80,900,200));details.autosetheight=false;details:addScrollBars()
 local total=panel:addControl('tradeRecovery',ISTextEntryBox:new('',10,315,180,28))
 local paid=panel:addControl('tradeRecovery',ISTextEntryBox:new('',260,315,180,28))
 local note=panel:addControl('tradeRecovery',ISTextEntryBox:new('',10,380,900,28))
 total.tooltip='Verified total owed for the reconciled trade, including any money already paid.'
 paid.tooltip='Actual money already received, including earlier partial recovery payments. Verify against the customer and receipts.'
 note.tooltip='Explain removed/retained vehicles and how prior payment was verified.'
 local verified=panel:addControl('tradeRecovery',ISTickBox:new(10,420,900,28,'TradeReconciled',panel,nil))
 verified:addOption('I Verified Vehicle Removals, Settlement Total & Money Already Received')
 local pay
 local function update()
  local r=rows[choice.selected];verified:setSelected(1,false);note:setText('')
  total:setText(r and tostring(r.amount) or '');paid:setText('')
  pay:setEnable(r~=nil and r.status=='hold')
  local lines={}
  if r then
   lines={'Customer: '..text(r.actor)..' | Trade: '..text(r.token)..' | Original offer: $'..text(r.amount),
    'Recorded paid amount: '..text(r.paidAmount)..' | Paid items: '..text(r.paidItems),text(r.error)}
   for _,v in ipairs(r.vehicles)do lines[#lines+1]=text(v.script)..' [#'..text(v.id)..'] $'..text(v.amount)..' | Removal recorded: '..tostring(v.removed==true)end
   lines[#lines+1]='Verify the saved world and customer inventory. Unloaded vehicles and spent/transferred cash cannot be proven absent here. No vehicles are removed by recovery.'
  else lines={'No held trade-ins at this kiosk.'}end
  details.text=table.concat(lines,' <LINE> ');details:paginate()
 end
 choice.onChange=update
 for _,r in ipairs(rows)do choice:addOption(r.actor..' | Trade '..tostring(r.token)..' | '..r.status)end
 button('tradeRecovery',10,465,250,'Refresh Held Trade-Ins',function(p)p.send({action='tradeRecoveryRefresh'})end)
 pay=button('tradeRecovery',280,465,630,'Resolve & Pay Verified Remainder',function(p)
  local r=rows[choice.selected];if not r or not verified:isSelected(1)then return end
  local a={action='tradeRecoveryResolve',tradeActor=r.actor,tradeToken=r.token,recoveryRevision=r.revision,reconciled=true,settlementTotal=tonumber(total:getText()),alreadyPaid=tonumber(paid:getText()),recoveryNote=note:getText()}
  if not a.settlementTotal or not a.alreadyPaid then return end
  local submitted=false
  local modal=ISModalRichText:new(100,100,680,260,'Resolve trade '..text(r.token)..' for '..text(r.actor)..'? <LINE> Verified total: $'..a.settlementTotal..' | Already paid: $'..a.alreadyPaid..' <LINE> Pay remainder: $'..(a.settlementTotal-a.alreadyPaid)..' <LINE> This archives the reconciliation and unblocks trading. Vehicles are unchanged.',true,nil,function(_,b)
   if b.internal=='YES' and not submitted then submitted=true;p.send(a)end
  end,p.player)
  modal:initialise();modal:addToUIManager();modal:bringToTop()
 end)
 local render=details.prerender
 details.prerender=function(self)render(self)end
 -- Labels drawn by the owning panel, not by hidden-page child widgets.
 panel.tradeRecoveryLabels=function(p)
  p:drawText('Verified Settlement Total ($)',10,290,1,1,1,1,UIFont.Small)
  p:drawText('Verified Already Paid ($)',260,290,1,1,1,1,UIFont.Small)
  p:drawText('Reconciliation Note',10,355,1,1,1,1,UIFont.Small)
 end
 update()
end
return M
