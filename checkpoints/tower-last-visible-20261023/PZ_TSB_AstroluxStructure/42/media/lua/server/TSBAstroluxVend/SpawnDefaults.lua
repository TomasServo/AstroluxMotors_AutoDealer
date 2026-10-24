-- Scope provider-default suppression to a single native dealership spawn.
-- No provider files, player installation callbacks or existing vehicles changed.
local Stock=require 'TSBAstroluxVend/Stock'
local Equipment=require 'TSBAstroluxVend/Equipment'
local S={}
function S.create(script,spawn)
    local parts=DAMN and DAMN.Parts
    if not parts or type(parts.processDefaults)~='function' then return spawn() end
    local original=parts.processDefaults
    parts.processDefaults=function(self,vehicle,part,...)
        if vehicle and part and vehicle:getScript():getFullName()==script and (Equipment.optional(vehicle:getScript(),part:getId()) or Stock.choice(script,part:getId())~=nil) then
            vehicle:getModData()['defaultPartSet_'..part:getId()]='true'
            return
        end
        return original(self,vehicle,part,...)
    end
    local ok,result=pcall(spawn)
    parts.processDefaults=original
    if not ok then error(result,0)end
    return result
end
return S
