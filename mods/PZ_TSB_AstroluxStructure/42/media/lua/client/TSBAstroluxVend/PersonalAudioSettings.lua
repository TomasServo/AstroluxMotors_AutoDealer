-- Client preferences live in Zomboid/Lua, outside world/server ModData.
local P={cache={}}
function P.defaultVolume(key)return key=='musicVolume' and 0.09 or 1 end
local function valid(n)return type(n)=='number' and n==n and n>=0 and n<=100 and n==math.floor(n)end
function P.file(player)
 player=player or getSpecificPlayer(0)
 local name=player and tostring(player:getUsername()) or 'local'
 local hex=name:gsub('.',function(c)return string.format('%02x',string.byte(c))end)
 return 'TSBAstroluxAudio_'..hex..'_'..tostring(player and player:getPlayerNum() or 0)..'.ini'
end
function P.get(player)
 local file=P.file(player)
 if P.cache[file]then return P.cache[file]end
 local values={}
 local ok=pcall(function()
  local reader=getFileReader(file,false)
  if not reader then return end
  local line=reader:readLine()
  while line do
   local key,raw=line:match('^(%w+)=(%d+)$');local n=tonumber(raw)
   if (key=='purchaseVolume' or key=='musicVolume' or key=='doorVolume') and valid(n)then values[key]=n end
   if (key=='mutePurchase' or key=='muteMusic' or key=='muteDoor') and (n==0 or n==1)then values[key]=n==1 end
   if key=='musicTrack' and (n==1 or n==2)then values.musicTrack=n end
   line=reader:readLine()
  end
  reader:close()
 end)
 if not ok then values={}end
 P.cache[file]=values;return values
end
function P.save(player,values)
 if values.musicTrack~=nil and values.musicTrack~=1 and values.musicTrack~=2 then return false end
 for _,key in ipairs({'purchaseVolume','musicVolume','doorVolume'})do
  if values[key]~=nil and not valid(values[key])then return false end
 end
 local copy={musicTrack=values.musicTrack,purchaseVolume=values.purchaseVolume,musicVolume=values.musicVolume,doorVolume=values.doorVolume,
  mutePurchase=values.mutePurchase==true,muteMusic=values.muteMusic==true,muteDoor=values.muteDoor==true}
 local ok=pcall(function()
  local writer=assert(getFileWriter(P.file(player),true,false))
  for _,key in ipairs({'purchaseVolume','musicVolume','doorVolume'})do if copy[key]~=nil then writer:write(key..'='..copy[key]..'\n')end end
  if copy.musicTrack then writer:write('musicTrack='..copy.musicTrack..'\n')end
  writer:write('mutePurchase='..(copy.mutePurchase and '1' or '0')..'\n')
  writer:write('muteMusic='..(copy.muteMusic and '1' or '0')..'\n');writer:write('muteDoor='..(copy.muteDoor and '1' or '0')..'\n');writer:close()
 end)
 if ok then P.cache[P.file(player)]=copy end
 return ok
end
function P.volume(player,key,default)
 local n=P.get(player)[key];return valid(n) and n/100 or P.defaultVolume(key)
end
function P.muted(player,key)
 local field=key=='purchaseSound' and 'mutePurchase' or (key=='doorSound' and 'muteDoor' or 'muteMusic')
 return P.get(player)[field]==true
end
function P.track(player,default) local n=P.get(player).musicTrack;return (n==1 or n==2) and n or default end
return P