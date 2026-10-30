if isClient()then return end
local Access=require 'TSBAstroluxStructure/ReleaseAccess'
local Records=require 'TSBAstroluxStructure/Records'
local M={channel='TSBAstroluxRelease',pending={},last={},serial=0}
TSBAstroluxReleasePlacement=M
local function reply(p,kind,data)
 if isServer()then sendServerCommand(p,M.channel,kind,data)
 elseif TSBAstroluxReleaseClient then TSBAstroluxReleaseClient.receive(kind,data)end
end
function M.snapshot()
 local out={}
 for _,r in ipairs(Records.all())do if r.releaseTower then
  out[#out+1]={id=r.id,x=r.x,y=r.y,status=r.status,combinedSize=12,releaseTower=1,slidingDoorsRevision=r.slidingDoorsRevision,
   closedEntrances=r.closedEntrances or {},coffeeRestockEnabled=r.coffeeRestockEnabled,automaticDoorsEnabled=r.automaticDoorsEnabled,displayOutfitsLocked=r.displayOutfitsLocked}
 end end
 return {records=out}
end
function M.broadcast()
 local data=M.snapshot()
 if isServer()then sendServerCommand(M.channel,'sites',data)
 elseif TSBAstroluxReleaseClient then TSBAstroluxReleaseClient.receive('sites',data)end
end
local function scoped(player,fn)
 assert(not TSBAstroluxReleasePlacementActor,'Placement already active')
 TSBAstroluxReleasePlacementActor=player
 local ok,a,b=pcall(fn);TSBAstroluxReleasePlacementActor=nil
 if not ok then error(a,0)end
 return a,b
end
local function journal()return ModData.getOrCreate('TSBAstroluxReleasePlacements.v1')end
local function active(p,args)
 assert(type(args.id)=='string','Choose a tower')
 for _,r in ipairs(Records.all())do
  if r.id==args.id and r.releaseTower then
   assert(r.status=='ready' and p:getZ()==0 and p:getX()>=r.x-3 and p:getX()<=r.x+15 and p:getY()>=r.y-3 and p:getY()<=r.y+15,'Stand at a ready showroom')
   return r
  end
 end
 error('Tower unavailable')
end
function M.handle(p,command,args)
 if not p then return end
 args=type(args)=='table' and args or {}
 if command=='sites'then reply(p,'sites',M.snapshot());return end
 local actor=tostring(p:getUsername());local now=getTimestampMs()
 if M.last[actor]and now>=M.last[actor]and now-M.last[actor]<250 then
  reply(p,'result',{ok=false,message='Please wait a moment, then try again.'})
  return false
 end
 M.last[actor]=now
 local ok,why=pcall(function()
  assert(Access.allowed(p),'Administrator access required')
  if command=='reviewDeleteNearby'then
   local nearest,distance
   for _,r in ipairs(Records.all())do
    if r.releaseTower and type(r.x)=='number'and type(r.y)=='number'and (p:getX()-r.x)^2+(p:getY()-r.y)^2<=900 then
     local dx=math.max(r.x-p:getX(),0,p:getX()-(r.x+12))
     local dy=math.max(r.y-p:getY(),0,p:getY()-(r.y+12))
     local d=dx*dx+dy*dy
     if not nearest or d<distance or (d==distance and tostring(r.id)<tostring(nearest.id))then nearest=r;distance=d end
    end
   end
   assert(nearest,'No registered Astrolux release tower within 30 tiles. The server must recognize the tower before it can be deleted.')
   local data,reason=require('TSBAstroluxStructure/ReleaseDelete').review(p,nearest.id)
   if data then reply(p,'reviewDelete',data)else reply(p,'result',{ok=false,message=reason})end;return
  elseif command=='reviewDelete'then
   local data,reason=require('TSBAstroluxStructure/ReleaseDelete').review(p,args.id)
   if data then reply(p,'reviewDelete',data)else reply(p,'result',{ok=false,message=reason})end;return
  elseif command=='deleteTower'then
   local deleted,result,reason=pcall(require('TSBAstroluxStructure/ReleaseDelete').execute,p,args.token)
   M.broadcast()
   reply(p,'result',{ok=deleted and result~=nil,message=tostring(deleted and (result or reason)or result)});return
  elseif command=='review'then
   local plan,reason=scoped(p,function()return require('AstroluxBayTest/ShowroomBuilder12').preview(p,args.x,args.y,true)end)
   if not plan then reply(p,'result',{ok=false,message=tostring(reason)});return end
   local floorOK,floorWhy=require('TSBAstroluxStructure/ReleaseFloor').preflight(args.x,args.y)
   if not floorOK then reply(p,'result',{ok=false,message=floorWhy});return end
   local profile=require('TSBAstroluxStructure/DefaultFurnishings12') -- Release pastes use the approved template, not stale world authoring defaults.
   local prepared,reason=require('AstroluxBayTest/ShowroomFurnishings12').prepare({x=args.x,y=args.y,replacementProfile=profile})
   if not prepared then reply(p,'result',{ok=false,message=tostring(reason)});return end
   M.serial=M.serial+1
   local token=actor..':'..now..':'..M.serial
   M.pending[actor]={token=token,x=args.x,y=args.y,expires=now+60000,profile=profile}
   reply(p,'review',{token=token,x=args.x,y=args.y});return
  elseif command=='place'then
   local q=M.pending[actor];assert(q and args.token==q.token and now<=q.expires,'Placement preview expired; review again')
   M.pending[actor]=nil
   local floorOK,floorWhy=require('TSBAstroluxStructure/ReleaseFloor').preflight(q.x,q.y)
   if not floorOK then reply(p,'result',{ok=false,message=floorWhy});return end
   local entry={actor=actor,id='structure:'..q.x..':'..q.y,x=q.x,y=q.y,status='placing',token=q.token};journal()[q.token]=entry
   local r
   local placed,err=pcall(function()
    r=scoped(p,function()return require('AstroluxBayTest/ShowroomBuilder12').place(p,q.x,q.y,{multiple=true,furnished=true,profile=q.profile})end)
    assert(r,'Placement refused')
    entry.id=r.id;r.releaseTower=1;r.status='assembling'
    require('TSBAstroluxStructure/ReleaseAssembly').finish(r)
    require('TSBAstroluxStructure/ReleaseAssembly').publish(r)
    r.status='ready';entry.status='ready'
   end)
   if not placed then
    entry.status='hold';entry.error=tostring(err)
    if not r then for _,candidate in ipairs(Records.all())do if candidate.id==entry.id then r=candidate;break end end end
    if r then r.releaseTower=1;r.status='hold' end
    M.broadcast();error('Placement held for inspection: '..tostring(err))
   end
   M.broadcast();reply(p,'result',{ok=true,message='Astrolux tower placed. Configure delivery zones in its kiosks.'});return
  elseif command=='setting'then
   local r=active(p,args);assert(type(args.enabled)=='boolean','Choose an on/off value')
   if args.setting=='entrance'then
    assert(args.edge=='north'or args.edge=='west'or args.edge=='south'or args.edge=='east','Unknown entrance')
    local open=not(r.closedEntrances and r.closedEntrances[args.edge])
    if open~=args.enabled then local changed,err=require('TSBAstroluxStructure/ReleaseEntrance').toggle(p,r,args.edge);assert(changed,err);require('TSBAstroluxStructure/ReleaseAssembly').frames(r)end
   elseif args.setting=='coffee'then r.coffeeRestockEnabled=args.enabled;r.coffeeRestockResumeAt=args.enabled and getTimestamp()+600 or nil
   elseif args.setting=='displayLocks'then require('TSBAstroluxStructure/DisplayLocks').set(r,args.enabled)
   elseif args.setting=='automaticDoors'then r.automaticDoorsEnabled=args.enabled
   else error('Unknown tower setting')end
   M.broadcast();reply(p,'result',{ok=true,message='Tower setting saved.'});return
  elseif command=='recover'then
   local entry=type(args.token)=='string'and journal()[args.token]
   assert(entry and entry.status=='hold'and args.confirmed==true,'Choose and confirm a held placement')
   assert(p:getZ()==0 and (p:getX()-entry.x)^2+(p:getY()-entry.y)^2<=900,'Stand within 30 tiles of the held site')
   local record
   for _,r in ipairs(Records.all())do if r.id==entry.id then record=r end end
   assert(not record or record.status~='deleting','Deletion is in progress; use Delete Astrolux Tower to resume')
   if args.action=='resume'then
    assert(record and record.furnishingsRevision and record.slidingDoorsRevision and record.flooring and not record.furnishingsHold,'Base construction is incomplete. Inspect the site; finishing cannot recreate missing furnishings.')
    record.status='assembling';entry.status='placing'
    local resumed,err=pcall(function()
     require('TSBAstroluxStructure/ReleaseAssembly').finish(record)
     require('TSBAstroluxStructure/ReleaseAssembly').publish(record)
    end)
    if not resumed then record.status='hold';entry.status='hold';entry.error=tostring(err);error(err)end
    record.status='ready';entry.status='ready'
   elseif args.action=='clear'then
    for dx=-1,13 do for dy=-1,13 do
     assert(getCell():getGridSquare(entry.x+dx,entry.y+dy,0),'Load the complete held site first')
     for z=0,4 do local sq=getCell():getGridSquare(entry.x+dx,entry.y+dy,z)
      if sq then local list=sq:getObjects();for i=0,list:size()-1 do local md=list:get(i):getModData();local f=md.movableData and md.movableData.TSBAstroluxFurnishingV1
       assert(md.TSBAstroluxStructure~=entry.id and md.TSBAstroluxFlooring~=entry.id and not(f and f.tower==entry.id),'Owned tower objects remain. Clear the site through normal admin tools before releasing this empty-site hold.')
      end end
     end
    end end
    if record then local db=Records.state();if db.tower==record then db.tower=nil end;if db.showrooms then db.showrooms[record.id]=nil end end
    entry.status='cleared'
   else error('Choose Resume Finishing or Clear Empty-Site Hold')end
   entry.recoveredBy=actor;entry.recoveredAt=getTimestamp();M.broadcast();reply(p,'result',{ok=true,message='Placement recovery recorded.'});return
  elseif command=='holds'then
   local rows={};for token,e in pairs(journal())do if e.status~='ready'and e.status~='cleared'then rows[#rows+1]={token=token,x=e.x,y=e.y,status=e.status,error=e.error}end end
   reply(p,'holds',{rows=rows});return
  end
  error('Unknown tower command')
 end)
 if not ok then reply(p,'result',{ok=false,message=tostring(why)})end
end
Events.OnClientCommand.Add(function(module,command,p,args)if module==M.channel then M.handle(p,command,args)end end)
Events.OnInitGlobalModData.Add(function()
 for _,e in pairs(journal())do if e.status=='placing'then e.status='hold';e.error='Interrupted placement; inspect the recorded site before any further work.'end end
 for _,r in ipairs(Records.all())do if r.releaseTower and r.status=='assembling'then r.status='hold'end end
end)
return M
