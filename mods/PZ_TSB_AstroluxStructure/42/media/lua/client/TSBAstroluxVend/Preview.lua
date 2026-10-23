-- One native scene object, replaced only on selection changes. No world vehicles,
-- animation/rotation timer, render hook, or background catalog scanning.
local StockPreview=require 'TSBAstroluxVend/StockPreview'
local Equipment=require 'TSBAstroluxVend/Equipment'
local P={}
function P.new(scene)
    local self={scene=scene,enabled=true,status='Select a vehicle.'}
    function self:clear()
        if self.loaded then pcall(function()scene.javaObject:fromLua1('removeObject','astroluxPreview')end) end
        self.loaded=false;self.script=nil;self.camperTop=nil;self.equipmentKey=nil
    end
    function self:show(offer,camperTop,equipment)
        if offer then local source=getScriptManager():getVehicle(offer.script);if source then Equipment.list(source)end end
        local key=Equipment.key(equipment or (camperTop and {camper=true} or {}))
        camperTop=camperTop==true
        if not self.enabled then self:clear();scene:setVisible(false);self.status='3D preview disabled.';return end
        if offer and offer.script==self.script and self.camperTop==camperTop and self.equipmentKey==key then return end
        self:clear();scene:setVisible(false)
        if not offer then self.status='No vehicles on this page.';return end
        local ok,err=pcall(function()
            local script=getScriptManager():getVehicle(offer.script)
            if not script or not script:getModel() then error('Missing client model')end
            local resolved,why=StockPreview.resolve(script,camperTop,equipment)
            if not resolved then self.status=why;return false end
            self.loaded=true
            scene.javaObject:fromLua1('createVehicle','astroluxPreview')
            scene.javaObject:fromLua2('setVehicleScript','astroluxPreview',resolved)
            scene.javaObject:fromLua1('setDrawGrid',false)
            scene.javaObject:fromLua1('setView','UserDefined')
            scene.javaObject:fromLua3('setViewRotation',20,135,0)
            scene.javaObject:fromLua1('setZoom',math.max(0,math.min(2,math.floor(4-math.max(offer.rx or 3,offer.ry or 4)/3))))
        end)
        if ok and err==false then self:clear()
        elseif ok then self.script=offer.script;self.camperTop=camperTop;self.equipmentKey=key;scene:setVisible(true);self.status='Scroll to zoom; drag to pan.'
        else self:clear();self.status='Preview error; see console log.';print('[AstroluxPreview] '..tostring(err)) end
    end
    return self
end
return P
