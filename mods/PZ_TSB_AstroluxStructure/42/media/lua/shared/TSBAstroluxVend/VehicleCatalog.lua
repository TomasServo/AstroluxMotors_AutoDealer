local Amount=require 'TSBAstroluxVend/Amount'
local Pilot=require 'TSBAstroluxVend/HotelPilot'
local C=require 'TSBAstroluxVend/Config'
local P=require 'TSBAstroluxVend/Pricing'
local Policy=require 'TSBAstroluxVend/CatalogPolicy'
local Families=require 'TSBAstroluxVend/VehicleFamilies'
local V={}
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<=1000000 end
function V.measure(script) return require('TSBAstroluxVend/SpawnAreas').measure(script,'N') end
function V.new(manager,settings,demandOffer)
    local self={nativeOffers={},offers={},byID={},rejected=0,installable={},installedScripts={},scriptLabels={},adminOnly={},vehicleAvailability={}}
    local legacy={};for _,offer in ipairs(C.catalog)do legacy[offer.script]=offer end
    local scripts=manager:getAllVehicleScripts()
    for i=0,scripts:size()-1 do
        local script=scripts:get(i)
        local ok,offer=pcall(function()
            local full=script:getFullName()
            if type(full)~='string' or #full>200 then return nil end
            if full:find('TSBAstroluxVendPreview.',1,true)==1 then return nil end
            local lowered=full:lower()
            if lowered:find('smashed',1,true) or lowered:find('burnt',1,true) or lowered:find('wreck',1,true) then return nil end
            local nativeName=script:getName()
            local display=getTextOrNull and getTextOrNull('IGUI_VehicleName'..nativeName) or nil
            local friendly=display or (legacy[full] or {}).name or nativeName
            local reason=Policy.reason(script,full..' '..nativeName..' '..friendly)
            local override={}
            for k,v in pairs(C.vehicleOverrides[full] or {})do override[k]=v end
            if settings and settings.modelPrices and settings.modelPrices[full]~=nil then override.price=settings.modelPrices[full]end
            if settings and settings.vehicles and settings.vehicles[full]~=nil then override.price=settings.vehicles[full] end
            local rx,ry=V.measure(script)
            self.installable[full]=true;self.installedScripts[#self.installedScripts+1]=full
            self.adminOnly[full]=reason
            self.scriptLabels[full]=friendly..' ['..full..']'
            local choice=settings and settings.enabled and settings.enabled[full]
            local enabled=choice==true or (choice==nil and not override.disabled and not reason and (not Pilot.enabled() or legacy[full]~=nil))
            self.vehicleAvailability[full]=enabled
            if not enabled then return nil end
            local old=legacy[full]
            local pricing=P.forScript(script,override,settings)
            local price=pricing.total
            if not Amount.valid(price,1) then error('Invalid catalog price')end
            return {id=old and old.id or full,script=full,name=old and old.name or script:getName(),
                price=price,pricing=pricing,rx=rx,ry=ry,available=true}
        end)
        if ok and offer then self.nativeOffers[offer.script]=offer end
        if not ok then self.rejected=self.rejected+1 end
    end
    -- One visible model row; preserve exact offer IDs for requests and existing orders.
    local representatives={}
    for _,offer in pairs(self.nativeOffers)do
        local base=Families.canonical(offer.script)
        self.byID[offer.id]=offer
        local current=representatives[base]
        if not current or offer.script==base or (current.script~=base and offer.script<current.script)then representatives[base]=offer end
    end
    for base,offer in pairs(representatives)do
        offer.modelScript=base
        self.offers[#self.offers+1]=offer
    end
    table.sort(self.installedScripts)
    table.sort(self.offers,function(a,b)return a.script<b.script end)
    function self:resolve(id)
        local offer=self.byID[id]
        if not offer then error('Vehicle is not in the enabled server catalog.',0)end
        local rx,ry=V.measure(manager:getVehicle(offer.script))
        return demandOffer and demandOffer(offer) or offer
    end
    function self:variant(id,target)
        local base=self:resolve(id)
        target=target or base.script
        if target==base.script then return base end
        local member=Families.member(base.script,target)
        if not member and Families.canonical(base.script)==Families.canonical(target) then member=Families.members[target] end
        local native=member and self.nativeOffers[target]
        if not native then error('Vehicle configuration is unavailable in this catalog.',0)end
        local result={};for k,v in pairs(demandOffer and demandOffer(native) or native)do result[k]=v end
        result.id=base.id;result.catalogScript=base.script
        if member.kind=='configuration'then
            local p=Families.policy(settings,base.script,target)
            if not p.enabled then error('Vehicle configuration disabled by owner.',0)end
            result.price=Amount.add(result.price,p.price)
            result.configurationLabel=member.label..(p.price>0 and (' +$'..p.price) or '')
        end
        return result
    end
    -- Match every enabled native script, not only the visible parent rows.
    -- The registry includes vanilla and loaded mod vehicles and folded variants.
    function self:tradeOffer(scriptName)
        local native=self.nativeOffers[scriptName]
        if not native then return nil end
        local direct=self.byID[native.id]
        if direct and direct.script==scriptName then return direct end
        local parent=self.nativeOffers[Families.canonical(scriptName)]
        if not parent then return nil end
        return self:variant(parent.id,scriptName)
    end
    function self:paintVariants(offer)
        local out={}
        for target,d in pairs(Families.members)do
            if d.base==offer.script and d.kind=='paint' and self.nativeOffers[target]then out[#out+1]={script=target,label=d.label}end
        end
        table.sort(out,function(a,b)return a.script<b.script end)
        return out
    end
    function self:configurations(offer)
        local out={}
        for target,native in pairs(self.nativeOffers)do
            local d=Families.member(offer.script,target)
            if target~=offer.script and Families.canonical(target)==Families.canonical(offer.script) then
                d=d or Families.members[target]
                if d and d.kind~='paint' and (d.kind~='configuration' or Families.policy(settings,offer.script,target).enabled)then
                    local variant=self:variant(offer.id,target)
                    variant.label=d.label;out[#out+1]=variant
                end
            end
        end
        table.sort(out,function(a,b)return a.script<b.script end)
        return out
    end
    function self:page(query,page)
        query=type(query)=='string' and string.lower(string.sub(query,1,80)) or ''
        page=finite(page) and math.max(1,math.floor(page)) or 1
        local matches={}
        for _,offer in ipairs(self.offers)do
            local hit=query=='' or string.find(string.lower(offer.name..' '..offer.script..' '..(self.scriptLabels[offer.modelScript] or '')),query,1,true)
            if not hit then for target,native in pairs(self.nativeOffers)do
                if Families.canonical(target)==Families.canonical(offer.script) and string.find(string.lower(native.name..' '..target..' '..(self.scriptLabels[target] or '')),query,1,true)then hit=true;break end
            end end
            if hit then matches[#matches+1]=offer end
        end
        local pages=math.max(1,math.ceil(#matches/C.pageSize));page=math.min(page,pages)
        local result={}
        for i=(page-1)*C.pageSize+1,math.min(#matches,page*C.pageSize)do
            local o=matches[i]
            if demandOffer then o=demandOffer(o)end
            result[#result+1]={id=o.id,script=o.script,name=o.name,modelScript=o.modelScript,price=o.price,basePrice=o.basePrice,pricing=o.pricing,rx=o.rx,ry=o.ry,available=o.available}
        end
        return result,page,pages,#matches
    end
    return self
end
return V
