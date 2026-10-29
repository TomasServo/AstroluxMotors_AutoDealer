-- Player-requested navigation only. No background process or automatic uploads.
require 'ISUI/ISModalRichText'
require 'ISUI/ISButton'
local M={url='https://reports.thespacebar.pro/'}
function M.steam(player)
 -- An explicit click must try the native browser call even if Steam's
 -- availability query is false or unavailable. Log the two results separately.
 local checked,enabled=pcall(function()return isSteamOverlayEnabled and isSteamOverlayEnabled()end)
 print('[Astrolux reporting] Overlay button clicked; availability='..tostring(checked and enabled))
 if not activateSteamOverlayToWebPage then
  print('[Astrolux reporting] Native overlay browser function missing')
  return false,'Steam browser is unavailable in this game session.'
 end
 local ok,result=pcall(function()return activateSteamOverlayToWebPage(M.url)end)
 print('[Astrolux reporting] Native overlay browser request: callOK='..tostring(ok)..'; result='..tostring(result))
 if not ok or result==false then return false,'Steam browser request failed. You can copy the reporting link.' end
 return true,'Steam browser requested. If it does not appear, copy the reporting link.'
end
function M.open(player)
 local requested=false
 local checked,enabled=pcall(function()return isSteamOverlayEnabled and isSteamOverlayEnabled()end)
 if checked and enabled and activateSteamOverlayToWebPage then
  requested=pcall(activateSteamOverlayToWebPage,M.url)
 end
 if not requested and openUrl then requested=pcall(openUrl,M.url)end
 -- Native browser APIs may fail silently. Keep a visible, usable fallback.
 local modal=ISModalRichText:new(100,100,620,250,
  'Bug reports and feedback <LINE> '..M.url,
  true,nil,function(_,button)
   if button.internal=='YES' then
    local ok=Clipboard and Clipboard.setClipboard and pcall(Clipboard.setClipboard,M.url)
    if player and player.Say then player:Say(ok and 'Reporting link copied.' or 'Open reports.thespacebar.pro in your browser.')end
   end
  end,player and player:getPlayerNum() or 0)
 modal.yesText='Copy reporting link';modal.noText='Close';modal:initialise()
 local h=modal.yes:getHeight();local y=modal.yes:getY()
 modal.yes:setX(230);modal.yes:setWidth(220)
 modal.no:setX(460);modal.no:setWidth(140)
 local steam=ISButton:new(20,y,200,h,'Open Steam Overlay',modal,function()
  local ok,status=M.steam(player)
  modal.chatText.text='Bug reports and feedback <LINE> '..M.url..' <LINE> '..status
  modal.chatText:paginate()
 end)
 steam:initialise();steam:instantiate();steam.anchorTop=false;steam.anchorBottom=true
 steam.backgroundColor={r=0,g=.35,b=.45,a=1}
 modal:addChild(steam)
 -- Keep the third button aligned when the native dialog changes height.
 local updateButtons=modal.updateButtons
 modal.updateButtons=function(self)updateButtons(self);steam:setY(self.yes:getY())end
 modal:addToUIManager()
 return requested
end
return M
