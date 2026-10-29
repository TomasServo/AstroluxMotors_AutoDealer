local M=require 'TSBAstroluxStructure/MannequinRotation'
Events.OnClientCommand.Add(function(module,command,player,args)
 if module~=M.channel or command~='rotate' or type(args)~='table'then return end
 for _,key in ipairs({'x','y','z','index'})do local n=args[key]
  if type(n)~='number' or n~=n or math.abs(n)>1000000 or n~=math.floor(n)then return end
 end
 if not player or player:isDead() or math.abs(player:getX()-args.x)>4 or math.abs(player:getY()-args.y)>4 or math.floor(player:getZ())~=args.z then return end
 local sq=getCell():getGridSquare(args.x,args.y,args.z)
 if not sq or args.index<0 or args.index>=sq:getObjects():size()then return end
 M.apply(player,sq:getObjects():get(args.index),args.direction)
end)
