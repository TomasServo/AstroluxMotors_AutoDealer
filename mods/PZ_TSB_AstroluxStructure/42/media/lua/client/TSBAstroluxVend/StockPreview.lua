local Adapters=require 'TSBAstroluxVend/VehicleAdapters'
local Stock=require 'TSBAstroluxVend/Stock'
local Equipment=require 'TSBAstroluxVend/Equipment'
local P={}
local ready={}
local dynamicKey
local function vector(v)return string.format('%.8f %.8f %.8f',v:x(),v:y(),v:z())end
local function modelBlock(m,id)
    local out={'model '..(id or '')..' { file = '..m:getFile()..', scale = '..m:getScale()..', offset = '..vector(m:getOffset())..', rotate = '..vector(m:getRotate())..','}
    if m:getAttachmentNameParent()then out[#out+1]='attachmentParent = '..m:getAttachmentNameParent()..','end
    if m:getAttachmentNameSelf()then out[#out+1]='attachmentSelf = '..m:getAttachmentNameSelf()..','end
    out[#out+1]='}'
    return table.concat(out,' ')
end
function P.resolve(source,camperTop,equipment)
    local full=source:getFullName()
    local selected=Equipment.selection(equipment,source,camperTop)
    local selectedParts=Equipment.parts(source,selected)
    local mask=Equipment.key(selected)
    local adapter=Adapters.get(full);local prefix=adapter and (adapter.previewPrefixes or {})[full]
    local dynamic=not prefix or mask:find('|',1,true)~=nil or (tonumber(mask) or 0)>255
    if dynamic then
        -- Vanilla's attachment editor renders loaded source scripts directly.
        -- No source mutation, private fields, or dynamic holder is needed.
        return full,'Base model preview; selected accessories may differ.'
    end
    local name=dynamic and 'Dynamic' or prefix
    if not dynamic then if mask=='1' then name=name..'Camper' elseif mask~='0' then name=name..'Equipment'..mask end end
    local previewName='TSBAstroluxVendPreview.'..name
    local dynamicID=full..'|'..mask
    if (dynamic and dynamicKey==dynamicID) or (not dynamic and ready[previewName])then return previewName end
    local target=getScriptManager():getVehicle(previewName)
    if not target then return nil,'Equipment preview unavailable. Restart after installing the preview definitions.' end
    -- Copy already-loaded geometry without Loaded(): re-running it would scale
    -- wheel offsets a second time. Animation/parent data is deep-copied by the
    -- native copyPartsFrom API; the original vehicle scripts remain untouched.
    local appearance=adapter and adapter.previewAppearance or ''
    target:Load(name,'{ '..modelBlock(source:getModel())..appearance..' }')
    target:copyWheelsFrom(source,'*')
    for i=0,source:getPartCount()-1 do
        local part=source:getPart(i);local id=part:getId()
        if selectedParts[id] then
            local choice=selectedParts[id]
            local ids=choice.models or (choice.model and {choice.model} or {})
            for j,modelID in ipairs(ids)do
                local model=part:getModelById(modelID)
                if not model then error('Accessory preview model is unavailable.')end
                local partID=j==1 and id or ('TSBAccessory'..i..'Model'..j)
                target:Load(name,'{ part '..partID..' { '..modelBlock(model,model:getId())..' } }')
            end
        elseif not selectedParts[id] and not Equipment.optional(source,id)then
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
    if dynamic then dynamicKey=dynamicID else ready[previewName]=true end
    print('[AstroluxPreview] stock source='..full..' scene='..previewName)
    return previewName
end
return P
