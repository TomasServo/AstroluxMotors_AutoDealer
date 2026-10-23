local A={}
function A.allowed(player)
    if not player then return false end
    if tostring(player:getAccessLevel()):lower()=='admin'then return true end
    -- Local debug tools do not confer administrator rights on a remote server.
    return not isClient() and not isServer() and isDebugEnabled()==true
end
return A
