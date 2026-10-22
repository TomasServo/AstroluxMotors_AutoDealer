-- PZ's hit-test list can omit a tabletop computer behind a cabinet/window.
local M={}
function M.isComputer(obj)
    local s=obj and obj:getSprite();local name=s and s:getName()
    return name=='appliances_com_01_72' or name=='appliances_com_01_73'
        or name=='appliances_com_01_74' or name=='appliances_com_01_75'
end
function M.isKiosk(obj)
    local s=obj and obj:getSprite();local name=s and s:getName()
    return type(name)=='string' and name:match('^TSBAstroluxKiosk_[0-3]$')~=nil
end
function M.label(obj)
    local sq=obj:getSquare()
    if M.isKiosk(obj)then return 'Astrolux Motors kiosk ('..sq:getX()..', '..sq:getY()..')'end
    if M.isComputer(obj)then return 'Desktop computer ('..sq:getX()..', '..sq:getY()..')'end
    return obj:getSprite():getName()
end
function M.collect(objects,cell)
    local computers,others,seen,scanned={},{},{},{}
    local function add(obj)
        local sq=obj and obj:getSquare();local sprite=obj and obj:getSprite()
        if sq and obj~=sq:getFloor() and sprite and sprite:getName() and not seen[obj]then
            seen[obj]=true;local list=M.isComputer(obj) and computers or others;list[#list+1]=obj
        end
    end
    for _,obj in ipairs(objects)do
        add(obj);local sq=obj:getSquare()
        if sq then
            for x=sq:getX()-1,sq:getX()+1 do for y=sq:getY()-1,sq:getY()+1 do
                local key=x..','..y..','..sq:getZ()
                if not scanned[key]then
                    scanned[key]=true;local nearby=cell:getGridSquare(x,y,sq:getZ())
                    if nearby then local list=nearby:getObjects()
                        for i=0,list:size()-1 do local candidate=list:get(i)
                            if M.isComputer(candidate) or M.isKiosk(candidate)then add(candidate)end
                        end
                    end
                end
            end end
        end
    end
    for _,obj in ipairs(others)do computers[#computers+1]=obj end
    return computers
end
return M
