-- Private test-map power controls; never enabled on normal maps.
local channel='TSBAstroluxMPPowerTest'
local function testMap()return getWorld()and tostring(getWorld():getMap())=='Astrolux Test Lot'end
local function apply(off)
 local options=getSandboxOptions()
 options:set('ElecShutModifier',off and 0 or 2147483647)
 options:toLua();getWorld():setHydroPowerOn(not off)
end
if isServer()then
 local function state()return ModData.getOrCreate('TSBAstroluxMPPowerTest.v1')end
 Events.OnClientCommand.Add(function(module,command,p,args)
  if module~=channel or not testMap()or not p then return end
  if command=='status'then sendServerCommand(p,channel,'state',{off=state().off==true});return end
  if command~='set'or not require('TSBAstroluxStructure/ReleaseAccess').allowed(p)or type(args)~='table'or type(args.off)~='boolean'then return end
  state().off=args.off;apply(args.off);sendServerCommand(channel,'state',{off=args.off})
  print('[Astrolux power test] Municipal power '..(args.off and 'OFF' or 'ON'))
 end)
 Events.OnServerStarted.Add(function()if testMap()then apply(state().off==true)end end)
elseif isClient()then
 Events.OnServerCommand.Add(function(module,command,args)
  if module==channel and command=='state'and testMap()and type(args.off)=='boolean'then apply(args.off)end
 end)
 Events.OnConnected.Add(function()if testMap()then sendClientCommand(channel,'status',{})end end)
 Events.OnFillWorldObjectContextMenu.Add(function(index,context,objects,test)
  local p=getSpecificPlayer(index)
  if test or not testMap()or not require('TSBAstroluxStructure/ReleaseAccess').allowed(p)then return end
  context:addOption('Astrolux Test: Power OFF',nil,function()sendClientCommand(p,channel,'set',{off=true})end)
  context:addOption('Astrolux Test: Power ON',nil,function()sendClientCommand(p,channel,'set',{off=false})end)
 end)
end
