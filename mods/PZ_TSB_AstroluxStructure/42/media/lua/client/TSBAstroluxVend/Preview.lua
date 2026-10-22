-- One native scene object, replaced only on selection changes. No world vehicles,
-- animation/rotation timer, render hook, or background catalog scanning.
local StockPreview=require 'TSBAstroluxVend/StockPreview'
local P={}
function P.new(scene)
    local self={scene=scene,enabled=true,status='Select a vehicle.'}
    function self:clear()
        if self.loaded then pcall(function()scene.javaObject:fromLua1('removeObject','astroluxPreview')end) end
        self.loaded=false;self.script=nil
    end
    function self:show(offer)
        if not self.enabled then self:clear();scene:setVisible(false);self.status='3D preview disabled.';return end
        if offer and offer.script==self.script then return end
        self:clear();scene:setVisible(false)
        if not offer then self.status='No vehicles on this page.';return end
        local ok,err=pcall(function()
            local script=getScriptManager():getVehicle(offer.script)
            if not script or not script:getModel() then error('Missing client model')end
            self.loaded=true
            scene.javaObject:fromLua1('createVehicle','astroluxPreview')
            scene.javaObject:fromLua2('setVehicleScript','astroluxPreview',StockPreview.resolve(script))
            scene.javaObject:fromLua1('setDrawGrid',false)
            scene.javaObject:fromLua1('setView','UserDefined')
            scene.javaObject:fromLua3('setViewRotation',20,135,0)
            scene.javaObject:fromLua1('setZoom',math.max(1,math.floor(8-math.max(offer.rx or 3,offer.ry or 4)/3)))
        end)
        if ok then self.script=offer.script;scene:setVisible(true);self.status='Scroll to zoom; drag to pan.'
        else self:clear();self.status='Preview error; see console log.';print('[AstroluxPreview] '..tostring(err)) end
    end
    return self
end
return P
