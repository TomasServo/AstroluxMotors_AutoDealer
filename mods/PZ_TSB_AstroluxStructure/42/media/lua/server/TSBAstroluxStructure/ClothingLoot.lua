-- Additive native loot entries; existing explored containers are never refilled.
require 'Items/ProceduralDistributions'
local M={}
local prefix='TSBAstrolux.'
local jackets={'AstroluxRacingJacket','AstroluxRacingJacketWhite'}
local pants={'AstroluxRacingPants','AstroluxRacingPantsWhite'}
function M.add(name,items,weight)
 local dist=ProceduralDistributions.list[name]
 if not dist or not dist.items then return end
 for _,id in ipairs(items)do
  local full=prefix..id;local found=false
  for i=1,#dist.items,2 do if dist.items[i]==full then found=true;break end end
  if not found then table.insert(dist.items,full);table.insert(dist.items,weight)end
 end
end
function M.apply()
 -- Weights are relative native loot weights, not percentage chances.
 M.add('ClothingStoresJackets',jackets,0.3)
 M.add('ClothingStoresPants',pants,0.3)
 for _,name in ipairs({'WardrobeGeneric','WardrobeClassy','WardrobeRedneck'})do
  M.add(name,jackets,0.1);M.add(name,pants,0.1)
 end
 M.add('ClothingStorageAllJackets',jackets,0.3)
 M.add('ClothingStorageLegwear',pants,0.3)
 for _,name in ipairs({'MechanicShelfOutfit','MechanicOutfit'})do
  M.add(name,jackets,0.5);M.add(name,pants,0.5)
 end
end
M.apply()
return M
