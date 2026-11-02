package.path='mods/PZ_TSB_AstroluxStructure/42/media/lua/shared/?.lua;mods/PZ_TSB_AstroluxStructure/42/media/lua/client/?.lua;'..package.path
local Stock=require 'TSBAstroluxVend/StockPreview'
local source={getFullName=function()return 'Base.88toyotaHiluxSC'end,getModel=function()return {}end}
function getScriptManager()return {getVehicle=function(_,name)if name=='Base.88toyotaHiluxSC' then return source end end}end
local nativeError=error
function error(...)nativeError('Unexpected thrown preview error',0)end
local resolved,why=Stock.resolve(source)
assert(not resolved and why:find('preview unavailable'))
local calls={};local scene={javaObject={}}
function scene:setVisible(value)self.visible=value end
function scene.javaObject:fromLua1(action)calls[#calls+1]=action end
local preview=require('TSBAstroluxVend/Preview').new(scene)
preview:show({script='Base.88toyotaHiluxSC'})
assert(not scene.visible and not preview.loaded and #calls==0 and preview.status:find('Restart'))
error=nativeError
assert(Stock.resolve({getFullName=function()return 'Base.Van'end})=='Base.Van')
print('PASS: Hilux preview holders present and missing-holder fallback creates no scene or Lua error')
