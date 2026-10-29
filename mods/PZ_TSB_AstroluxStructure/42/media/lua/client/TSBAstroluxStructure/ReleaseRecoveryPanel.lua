require 'ISUI/ISPanel'
require 'ISUI/ISScrollingListBox'
require 'ISUI/ISButton'
require 'ISUI/ISModalRichText'
local M={}
function M.open(rows)
 local panel=ISPanel:new(100,100,850,440);panel:initialise();panel:addToUIManager()
 local list=ISScrollingListBox:new(10,35,830,320);list:initialise();panel:addChild(list)
 for _,row in ipairs(rows)do list:addItem(row.x..', '..row.y..' | '..row.status..' | '..tostring(row.error or ''),row)end
 local function button(x,w,label,fn)local b=ISButton:new(x,385,w,28,label,panel,fn);b:initialise();panel:addChild(b)end
 local function recover(action)
  local selected=list.items[list.selected];if not selected then return end
  local row=selected.item;local sent=false
  local text=action=='resume'and 'Resume finishing this held tower? Existing furnishings are retained. Only towers whose base construction completed can resume.'or 'Clear this hold only if no owned tower objects remain? This does not delete objects. The server verifies the complete loaded site before removing its reservation.'
  local modal=ISModalRichText:new(120,120,700,300,text,true,nil,function(_,b)
   if b.internal=='YES'and not sent then sent=true;require('TSBAstroluxStructure/ReleaseClient').send('recover',{token=row.token,action=action,confirmed=true});panel:removeFromUIManager()end
  end,0);modal:initialise();modal:addToUIManager()
 end
 button(10,270,'Resume Finishing',function()recover('resume')end)
 button(290,340,'Clear Empty-Site Hold',function()recover('clear')end)
 button(640,200,'Close',function()panel:removeFromUIManager()end)
 panel.prerender=function(self)ISPanel.prerender(self);self:drawText('Held Astrolux Placements',10,8,1,1,1,1,UIFont.Medium)end
end
return M
