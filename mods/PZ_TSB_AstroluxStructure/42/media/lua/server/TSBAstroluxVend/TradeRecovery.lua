local Amount=require 'TSBAstroluxVend/Amount'
local Access=require 'TSBAstroluxVend/AdminAccess'
local M={}
function M.rows(db,terminal)
 local rows={}
 for actor,r in pairs(db.tradeIns or {})do
  if r.terminal==terminal and (r.status=='hold' or r.status=='processing')then
   rows[#rows+1]={actor=actor,token=r.token,revision=r.recoveryRevision or 0,amount=r.amount,paidAmount=r.paidAmount,paidItems=r.paidItems or 0,status=r.status,error=r.error,vehicles=r.vehicles or {}}
  end
 end
 table.sort(rows,function(a,b)return a.actor<b.actor end);return rows
end
function M.resolve(db,terminal,args,admin,adapter)
 if not Access.allowed(admin)then return false,'Administrator access required.'end
 local r=type(args.tradeActor)=='string' and (db.tradeIns or {})[args.tradeActor]
 if not r or r.terminal~=terminal or r.token~=args.tradeToken or (r.recoveryRevision or 0)~=args.recoveryRevision or r.status~='hold'then return false,'Trade changed or is not held. Refresh the list.'end
 if args.reconciled~=true or type(args.recoveryNote)~='string' or #args.recoveryNote<5 or #args.recoveryNote>500 then return false,'Verify vehicle removals and money received, then enter a reconciliation note.'end
 if not Amount.valid(args.settlementTotal,0) or not Amount.valid(args.alreadyPaid,0) or args.alreadyPaid>args.settlementTotal or args.settlementTotal>r.amount then return false,'Enter verified whole-dollar totals: paid <= settlement <= original offer.'end
 local due=args.settlementTotal-args.alreadyPaid
 local target=adapter.player(args.tradeActor)
 if due>0 and (not target or target:isDead())then return false,'Customer must be online and alive for the remaining payment.'end
 local items,weight={},0
 local function add(kind,n,value)
  for i=1,n do local item=adapter.create(kind);if not item then error('Payment item unavailable')end
   items[#items+1]={item=item,value=value};weight=weight+item:getActualWeight()
  end
 end
 local ok,why=pcall(function()add('Base.MoneyBundle',math.floor(due/100),100);add('Base.Money',due%100,1)end)
 if not ok then return false,tostring(why)end
 local inv=target and target:getInventory()
 if due>0 and inv:getCapacityWeight()+weight>inv:getEffectiveCapacity(target)then return false,'Customer needs room for the remaining payment.'end
 db.tradeRecoveryAudit=db.tradeRecoveryAudit or {}
 local revision=(r.recoveryRevision or 0)+1
 local audit={actor=args.tradeActor,token=r.token,revision=revision,administrator=tostring(admin:getUsername()),time=adapter.now(),note=args.recoveryNote,settlementTotal=args.settlementTotal,verifiedPaid=args.alreadyPaid,remaining=due,added=0,vehicles=r.vehicles,status='processing'}
 local key=args.tradeActor..':'..tostring(r.token)..':'..revision
 if db.tradeRecoveryAudit[key]then return false,'Recovery receipt already exists. Refresh and inspect.'end
 db.tradeRecoveryAudit[key]=audit;r.recoveryRevision=revision;r.status='processing';r.paidAmount=args.alreadyPaid
 ok,why=pcall(function()
  for i,entry in ipairs(items)do
   entry.item:getModData().TSBAstroluxTradeRecovery={receipt=key,item=i,value=entry.value}
   if inv:AddItem(entry.item)~=entry.item or entry.item:getContainer()~=inv then error('Cash insertion interrupted')end
   audit.added=Amount.add(audit.added,entry.value);r.paidAmount=Amount.add(r.paidAmount,entry.value)
   if not pcall(adapter.notify,inv,entry.item)then audit.syncWarning=true end
  end
 end)
 if not ok then r.status='hold';r.error=tostring(why);audit.status='hold';return false,'Recovery interrupted. Inspect the recorded cash and receipt before reconciling again.'end
 r.status='resolved';r.settlementTotal=args.settlementTotal;r.resolvedBy=audit.administrator;r.resolution=key;audit.status='resolved'
 return true,'Trade reconciled. Remaining payment: $'..due..'. Vehicles were not changed; audit retained.'
end
return M
