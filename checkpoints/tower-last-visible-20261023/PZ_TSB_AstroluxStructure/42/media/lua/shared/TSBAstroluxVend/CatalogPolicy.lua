local R={}
function R.reason(script,text)
    local bar=script.getLightbar and script:getLightbar()
    -- LightBar Java fields are not exposed through normal Lua indexing.
    -- Use the native field-inspection helpers used by vanilla ObjectViewer.
    local enabled=false
    if type(bar)=='table' then enabled=bar.enable==true
    elseif bar and getNumClassFields and getClassField and getClassFieldVal then
        for i=0,getNumClassFields(bar)-1 do
            local field=getClassField(bar,i)
            if field.getName and field:getName()=='enable' then
                enabled=getClassFieldVal(bar,field)==true
                break
            end
        end
    end
    if enabled then return 'Light bar' end
    if script.getHasSiren and script:getHasSiren() then return 'Siren/service vehicle' end
    local name=script:getFullName():lower()
    local fleet=(text or name):lower()
    if name:find('lights',1,true) then return 'Service/light-bar variant' end
    for _,word in ipairs({'police','sheriff','sherrif','ranger','swat','firedepartment','fire department','firedept','firetruck','fireengine','ambulance','emergency','rescue','county'})do
        if fleet:find(word,1,true) then return 'Service fleet' end
    end
    if name:match('fire$') or script:getFullName():find('KST',1,true) or name:match('kst$') or name:match('kstpd$') then return 'Service fleet' end
    if script.getPartCount then for i=0,script:getPartCount()-1 do
        local part=script:getPart(i)
        if part:getId():lower():find('lightbar',1,true) then return 'Light-bar equipment' end
        if part.getModelCount then for j=0,part:getModelCount()-1 do
            local model=part:getModel(j)
            if ((model:getId() or '')..' '..(model:getFile() or '')):lower():find('lightbar',1,true) then return 'Light-bar model' end
        end end
    end end
end
return R
