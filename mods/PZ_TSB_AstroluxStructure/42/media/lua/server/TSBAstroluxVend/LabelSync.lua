if isClient()then return end
local Labels=require 'TSBAstroluxVend/KioskLabels'
local M={channel='TSBAstroluxLabels',last=0,requests={}}
function M.snapshot(db)
 Labels.ensure(db);local out={}
 for id,t in pairs(db.terminals or {})do
  if not t.packed then
   local row={id=id,x=t.x,y=t.y,z=t.z or 0,sprite=t.sprite,number=t.displayNumber}
   local a=t.spawnArea
   if a and t.deliveryNumber~=false then row.area={x1=a.x1,y1=a.y1,x2=a.x2,y2=a.y2,heading=a.heading}end
   out[#out+1]=row
  end
 end
 table.sort(out,function(a,b)return tostring(a.id)<tostring(b.id)end);return out
end
local function current()
 local db=ModData.get('TSBAstroluxVend.State.v1')
 return db and M.snapshot(db)or {}
end
local function fingerprint(rows)
 local keys={}
 for _,r in ipairs(rows)do
  keys[#keys+1]=table.concat({r.id,r.x,r.y,r.z,r.sprite or '',r.number},':')
  local a=r.area;if a then keys[#keys+1]=table.concat({a.x1,a.y1,a.x2,a.y2,a.heading},':')end
 end
 return table.concat(keys,'|')
end
Events.OnClientCommand.Add(function(module,command,p,args)
 if module~=M.channel or command~='snapshot'or not p then return end
 local key=p:getOnlineID();local now=getTimestampMs()
 if M.requests[key]and now-M.requests[key]<2000 then return end;M.requests[key]=now
 sendServerCommand(p,M.channel,'snapshot',{rows=current()})
end)
Events.OnTick.Add(function()
 local now=getTimestampMs();if now-M.last<1000 then return end;M.last=now
 local rows=current();local key=fingerprint(rows)
 if key==M.key then return end;M.key=key
 if isServer()then sendServerCommand(M.channel,'snapshot',{rows=rows})
 else TSBAstroluxPresentationLabels=rows end
end)
return M
