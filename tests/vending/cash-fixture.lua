local F={}
function instanceof(item,kind)return kind=='InventoryContainer' and item.bag==true end
function F.item(kind)
 local i={kind=kind}
 function i:getFullType()return self.kind end
 function i:getContainer()return self.container end
 function i:isEquipped()return self.equipped end
 function i:isFavorite()return self.favorite end
 function i:getInventory()return self.inventory end
 return i
end
function F.container()
 local c={items={}}
 function c:getItems()local items=self.items;return {size=function()return #items end,get=function(_,n)return items[n+1]end}end
 function c:AddItem(i)if self.failAdd then error('add failure')end;self.items[#self.items+1]=i;i.container=self;return i end
 function c:DoRemoveItem(i)
  if self.failRemove then error('remove failure')end
  for n,v in ipairs(self.items)do if v==i then table.remove(self.items,n);i.container=nil;return end end
 end
 return c
end
function F.player(name,bundles,bills)
 local p={name=name,inventory=F.container()}
 function p:getUsername()return self.name end
 function p:isDead()return false end
 function p:getInventory()return self.inventory end
 for n=1,bundles or 0 do p.inventory:AddItem(F.item('Base.MoneyBundle'))end
 for n=1,bills or 0 do p.inventory:AddItem(F.item('Base.Money'))end
 return p
end
function F.adapter()return {now=function()return 100 end,createMoney=function()return F.item('Base.Money')end,notify=function()end}end
return F
