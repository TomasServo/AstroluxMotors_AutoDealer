local Stock=require 'TSBAstroluxVend/Stock'
local P={}
local ready={}
local function vector(v)return string.format('%.8f %.8f %.8f',v:x(),v:y(),v:z())end
local function modelBlock(m,id)
    local out={'model '..(id or '')..' { file = '..m:getFile()..', scale = '..m:getScale()..', offset = '..vector(m:getOffset())..', rotate = '..vector(m:getRotate())..','}
    if m:getAttachmentNameParent()then out[#out+1]='attachmentParent = '..m:getAttachmentNameParent()..','end
    if m:getAttachmentNameSelf()then out[#out+1]='attachmentSelf = '..m:getAttachmentNameSelf()..','end
    out[#out+1]='}'
    return table.concat(out,' ')
end
function P.resolve(source)
    local full=source:getFullName()
    if not Stock.isHilux(full)then return full end
    local name=full:gsub('Base.88toyota','')
    local previewName='TSBAstroluxVendPreview.'..name
    if ready[full]then return previewName end
    local target=getScriptManager():getVehicle(previewName)
    if not target then error('Stock preview definitions need a game restart.')end
    -- Copy already-loaded geometry without Loaded(): re-running it would scale
    -- wheel offsets a second time. Animation/parent data is deep-copied by the
    -- native copyPartsFrom API; the original vehicle scripts remain untouched.
    target:Load(name,'{ '..modelBlock(source:getModel())..' skin { texture = Vehicles/Vehicles_88toyotaHilux_Shell_beige, } textureMask = Vehicles/Vehicles_88toyotaHilux_Mask, textureLights = Vehicles/Vehicles_88toyotaHilux_Lights, }')
    target:copyWheelsFrom(source,'*')
    for i=0,source:getPartCount()-1 do
        local part=source:getPart(i);local id=part:getId()
        if not Stock.optional(id)then
            local _,chosen=Stock.choice(full,id)
            if id=='GloveBox' and part:getModelCount()>1 then
                -- B42 UI3DScene.initPartModel looks up model info by part ID,
                -- not model ID. Give each static body section its own part so
                -- the bed/interior do not incorrectly reuse the cab mesh.
                for j=0,part:getModelCount()-1 do
                    local m=part:getModel(j)
                    local partID=j==0 and id or ('TSBStockBody'..j)
                    target:Load(name,'{ part '..partID..' { '..modelBlock(m,m:getId())..' } }')
                end
            elseif chosen then
                local m=part:getModelById(chosen)
                if not m then error('Missing stock preview model: '..id..'/'..chosen)end
                local wheel=id:match('^Tire(.+)$')
                target:Load(name,'{ part '..id..' { '..(wheel and ('wheel = '..wheel..', ') or '')..modelBlock(m,chosen)..' } }')
            else target:copyPartsFrom(source,id)end
        end
    end
    ready[full]=true
    print('[AstroluxPreview] stock source='..full..' scene='..previewName)
    return previewName
end
return P
