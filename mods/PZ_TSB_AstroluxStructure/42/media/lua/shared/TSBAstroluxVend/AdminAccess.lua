local A={}
function A.allowed(player)
    if not player then return false end
    if tostring(player:getAccessLevel()):lower()=='admin'then return true end
    -- The local single-player owner may configure the mod; remote players require admin.
    return not isClient() and not isServer() 
end
return A
