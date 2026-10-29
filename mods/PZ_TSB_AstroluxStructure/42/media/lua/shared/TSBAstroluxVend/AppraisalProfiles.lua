-- Explicit profiles remain overrides; other loaded vehicles use native part definitions.
local P={version=3,vehicles={}}
P.vehicles['Base.CarNormal']={
    'Battery',
    'BrakeFrontLeft',
    'BrakeFrontRight',
    'BrakeRearLeft',
    'BrakeRearRight',
    'DoorFrontLeft',
    'DoorFrontRight',
    'DoorRearLeft',
    'DoorRearRight',
    'Engine',
    'EngineDoor',
    'GasTank',
    'GloveBox',
    'HeadlightLeft',
    'HeadlightRearLeft',
    'HeadlightRearRight',
    'HeadlightRight',
    'Heater',
    'Muffler',
    'Radio',
    'SeatFrontLeft',
    'SeatFrontRight',
    'SeatRearLeft',
    'SeatRearRight',
    'SuspensionFrontLeft',
    'SuspensionFrontRight',
    'SuspensionRearLeft',
    'SuspensionRearRight',
    'TireFrontLeft',
    'TireFrontRight',
    'TireRearLeft',
    'TireRearRight',
    'TruckBed',
    'TrunkDoor',
    'WindowFrontLeft',
    'WindowFrontRight',
    'WindowRearLeft',
    'WindowRearRight',
    'Windshield',
    'WindshieldRear',
}
P.vehicles['Base.PickUpVan']={
    'Battery',
    'BrakeFrontLeft',
    'BrakeFrontRight',
    'BrakeRearLeft',
    'BrakeRearRight',
    'DoorFrontLeft',
    'DoorFrontRight',
    'Engine',
    'EngineDoor',
    'GasTank',
    'GloveBox',
    'HeadlightLeft',
    'HeadlightRearLeft',
    'HeadlightRearRight',
    'HeadlightRight',
    'Heater',
    'Muffler',
    'Radio',
    'SeatFrontLeft',
    'SeatFrontRight',
    'SuspensionFrontLeft',
    'SuspensionFrontRight',
    'SuspensionRearLeft',
    'SuspensionRearRight',
    'TireFrontLeft',
    'TireFrontRight',
    'TireRearLeft',
    'TireRearRight',
    'TruckBed',
    'TrunkDoor',
    'WindowFrontLeft',
    'WindowFrontRight',
    'Windshield',
    'WindshieldRear',
}
P.vehicles['Base.88toyotaHiluxSC']={
    'Battery',
    'BrakeFrontLeft',
    'BrakeFrontRight',
    'BrakeRearLeft',
    'BrakeRearRight',
    'DAMNBumperFront',
    'DAMNBumperRear',
    'DoorFrontLeft',
    'DoorFrontRight',
    'Engine',
    'EngineDoor',
    'GasTank',
    'GloveBox',
    'HLX88Trunk',
    'HeadlightLeft',
    'HeadlightRearLeft',
    'HeadlightRearRight',
    'HeadlightRight',
    'Heater',
    'Muffler',
    'Radio',
    'SeatFrontLeft',
    'SeatFrontRight',
    'SuspensionFrontLeft',
    'SuspensionFrontRight',
    'SuspensionRearLeft',
    'SuspensionRearRight',
    'TireFrontLeft',
    'TireFrontRight',
    'TireRearLeft',
    'TireRearRight',
    'TrunkDoor',
    'WindowFrontLeft',
    'WindowFrontRight',
    'Windshield',
    'WindshieldRear',
}
P.vehicles['Base.88toyotaHiluxXC']={
    'Battery',
    'BrakeFrontLeft',
    'BrakeFrontRight',
    'BrakeRearLeft',
    'BrakeRearRight',
    'DAMNBumperFront',
    'DAMNBumperRear',
    'DoorFrontLeft',
    'DoorFrontRight',
    'Engine',
    'EngineDoor',
    'GasTank',
    'GloveBox',
    'HLX88Trunk',
    'HeadlightLeft',
    'HeadlightRearLeft',
    'HeadlightRearRight',
    'HeadlightRight',
    'Heater',
    'Muffler',
    'Radio',
    'SeatFrontLeft',
    'SeatFrontRight',
    'SeatRearLeft',
    'SeatRearRight',
    'SuspensionFrontLeft',
    'SuspensionFrontRight',
    'SuspensionRearLeft',
    'SuspensionRearRight',
    'TireFrontLeft',
    'TireFrontRight',
    'TireRearLeft',
    'TireRearRight',
    'TrunkDoor',
    'WindowFrontLeft',
    'WindowFrontRight',
    'WindowRearLeft',
    'WindowRearRight',
    'Windshield',
    'WindshieldRear',
}
P.vehicles['Base.88toyotaHiluxXCS']={
    'Battery',
    'BrakeFrontLeft',
    'BrakeFrontRight',
    'BrakeRearLeft',
    'BrakeRearRight',
    'DAMNBumperFront',
    'DAMNBumperRear',
    'DoorFrontLeft',
    'DoorFrontRight',
    'Engine',
    'EngineDoor',
    'GasTank',
    'GloveBox',
    'HLX88Trunk',
    'HeadlightLeft',
    'HeadlightRearLeft',
    'HeadlightRearRight',
    'HeadlightRight',
    'Heater',
    'Muffler',
    'Radio',
    'SeatFrontLeft',
    'SeatFrontRight',
    'SeatRearLeft',
    'SeatRearRight',
    'SuspensionFrontLeft',
    'SuspensionFrontRight',
    'SuspensionRearLeft',
    'SuspensionRearRight',
    'TireFrontLeft',
    'TireFrontRight',
    'TireRearLeft',
    'TireRearRight',
    'TrunkDoor',
    'WindowFrontLeft',
    'WindowFrontRight',
    'WindowRearLeft',
    'WindowRearRight',
    'Windshield',
    'WindshieldRear',
}
-- Native CarStationWagon/CarStationWagon2 declare the reviewed CarNormal
-- standard part templates (four doors/seats/windows, trunk, tires and running gear).
-- Copy arrays so later vehicle-specific revisions remain independent.
for _,name in ipairs({'Base.CarStationWagon','Base.CarStationWagon2'})do
 local profile={};for i,id in ipairs(P.vehicles['Base.CarNormal'])do profile[i]=id end
 P.vehicles[name]=profile
end

-- Reviewed native OffRoad (Dash Rancher): same standard part templates as
-- PickUpVan plus two rear quarter windows; PassengerSeat2 has no rear seats.
do
 local profile={};for i,id in ipairs(P.vehicles['Base.PickUpVan'])do profile[i]=id end
 profile[#profile+1]='WindowRearLeft';profile[#profile+1]='WindowRearRight'
 P.vehicles['Base.OffRoad']=profile
end

-- Adapter-provided reviewed profiles allow new providers without editing this table.
setmetatable(P.vehicles,{__index=function(_,name)
 local adapter=require('TSBAstroluxVend/VehicleAdapters').get(name)
 return adapter and adapter.appraisalProfile or nil
end})
-- Build from declared slots, never only the currently installed inventory.
-- Missing stock parts therefore still lower value and installation percentage.
function P.resolve(vehicle,settings)
 local script=vehicle:getScript();local name=script:getFullName()
 local explicit=P.vehicles[name]
 local Roles=require 'TSBAstroluxVend/AppraisalPartRoles'
 if explicit then return Roles.filter(explicit,script,settings) end
 local Stock=require 'TSBAstroluxVend/Stock'
 local Equipment=require 'TSBAstroluxVend/Equipment'
 local count=script:getPartCount()
 if count<1 or count>500 then error('Vehicle has an unsupported part definition count.',0)end
 local result,seen={},{}
 for i=0,count-1 do
  local definition=script:getPart(i);local id=definition and definition:getId()
  if type(id)~='string' or id=='' or seen[id]then error('Invalid or duplicate declared vehicle part.',0)end
  seen[id]=true
  if not Stock.optional(id) and not Stock.blank(name,id) and not Equipment.optional(script,id)then
   local part=vehicle:getPartById(id)
   local types=part and part:getItemType()
   if id=='Engine' or id=='Heater' or not part or (types and not types:isEmpty())then
    result[#result+1]=id
   end
  end
 end
 if #result==0 then error('Vehicle declares no appraisable mechanical or inventory parts.',0)end
 table.sort(result)
 return Roles.filter(result,script,settings)
end
return P
