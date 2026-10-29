-- Astrolux economy estimates, not provider-supplied market prices.
-- Used for trade-ins only; never enables sale or installation of an accessory.
local M={version=1}
function M.lightbar(id)
 local s=string.lower(id or ''):gsub('[^%w]','')
 return s:find('lightbar',1,true)~=nil or s:find('siren',1,true)~=nil
end
function M.estimate(id)
 local s=string.lower(id or ''):gsub('[^%w]','')
 if s:find('armor',1,true) or s:find('armour',1,true)then return 250 end
 if s:find('generator',1,true)then return 1000 end
 if s:find('bullbar',1,true) or s:find('bumper',1,true) or s:find('rack',1,true) or s:find('basket',1,true) or s:find('camper',1,true) or s:find('bedcap',1,true) or s:find('rollbar',1,true)then return 500 end
 if s:find('mudflap',1,true)then return 100 end
 return 250
end
function M.price(settings,script,d,policy)
 local per=((settings or {}).accessories or {})[script] or {}
 local override=per[d.id] or (d.policyAlias and per[string.format(d.policyAlias,script)]) or {}
 if override.price~=nil or not d.discovered then return policy.price,false end
 return M.estimate(d.id),true
end
return M
