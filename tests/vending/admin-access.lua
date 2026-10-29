local base='mods/PZ_TSB_AstroluxStructure/42/media/lua/'
assert(loadfile(base..'client/TSBAstroluxVend/Client.lua'))
assert(loadfile(base..'server/TSBAstroluxVend/Server.lua'))
local client,server,debug=false,false,false
function isClient()return client end
function isServer()return server end
function isDebugEnabled()return debug end
local level='None';local player={getAccessLevel=function()return level end}
local A=dofile(base..'shared/TSBAstroluxVend/AdminAccess.lua')
assert(A.allowed(player),'single-player owner allowed without debug')
debug=true;assert(A.allowed(player),'debug single player allowed')
client=true;assert(not A.allowed(player),'remote client debug does not grant rights')
level='Admin';assert(A.allowed(player),'multiplayer admin allowed')
level='Moderator';assert(not A.allowed(player),'moderator is not administrator')
client=false;server=true;assert(not A.allowed(player),'debug server does not elevate normal accounts')
level='admin';assert(A.allowed(player),'server administrator allowed')
assert(not A.allowed(nil))
print('PASS: Lua syntax; non-debug/debug single player; multiplayer admin, moderator and client-debug boundaries; nil player denied')
