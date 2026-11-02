-- Private feedback entry point. No automatic diagnostics or server permissions.
require 'ISUI/ISModalRichText'
-- Shared guard prevents duplicate menu entries when other mods ship this hook.
if TSBPrivateModFeedbackInstalled then return end
TSBPrivateModFeedbackInstalled=true

local function openFeedback(player)
    local modal=ISModalRichText:new(100,100,620,270,
        'The Space Bar: private mod feedback <LINE> '..
        'Open the Space Bar reporting form in your browser? <LINE> '..
        'Reports go privately to the mod author. You review everything before sending. '..
        'No game logs, player identity, server address or save data are uploaded automatically. <LINE> '..
        'The author may publish a separately reviewed summary.',
        true,nil,function(_,button)
            if button.internal=='YES' then
                openUrl('https://reports.thespacebar.pro/')
            end
        end,player:getPlayerNum())
    modal:initialise()
    modal:addToUIManager()
end

Events.OnFillWorldObjectContextMenu.Add(function(playerNum,context,objects,test)
    if test then return end
    local player=getSpecificPlayer(playerNum)
    if not player then return end
    context:addOption('Report a mod issue or send feedback',player,openFeedback)
end)
