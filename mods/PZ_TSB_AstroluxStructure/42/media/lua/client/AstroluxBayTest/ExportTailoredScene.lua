-- One-time read-only survey of the user's finished bundled-save scene.
if isClient() or isServer() then return end
local done=false;local ticks=0
local key='TSBAstroluxTailoredExport20261026'
local function export()
 if done or not getWorld() or tostring(getWorld():getWorld())~='2026-10-26_12-43-49' then return end
 if not require('AstroluxBayTest/TestWorld').testMap() then return end
 local saved=ModData.getOrCreate(key)
 if saved.complete then done=true;return end
 local records=require('TSBAstroluxStructure/Records').all()
 if #records~=1 or records[1].status~='ready' then return end
 local D=TSBAstroluxDecorCapture
 if not D then return end
 local profile,why=D.survey(records[1],getCell())
 if not profile then return end -- Wait for all furniture squares to stream in.
 local ok,message=D.write(profile)
 if not ok then error(message) end
 saved.complete=true;saved.count=#profile.objects;done=true
 print('[Astrolux tailored scene] Exported '..#profile.objects..' furniture pieces; no objects moved or created.')
end
Events.OnTick.Add(function()
 if done then return end
 ticks=ticks+1;if ticks%120~=0 then return end
 local ok,why=pcall(export)
 if not ok then done=true;print('[Astrolux tailored scene] Export stopped: '..tostring(why)) end
end)
