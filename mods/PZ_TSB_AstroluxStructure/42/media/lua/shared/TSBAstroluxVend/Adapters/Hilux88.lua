-- Astrolux-owned mapping data; no provider code or assets copied.
local Registry=require 'TSBAstroluxVend/VehicleAdapters'
local function slot(part,item,model)return {part=part,item=item,model=model}end
local definitions={
 {id='camper',label='Camper Top (Bed Cap)',price=500,bonus=46,effect='Native enclosed bed cap. Replaces the rollbar in the same bed slot; removable only after the roof rack is removed.',slots={slot('HLX88TruckBedExtras','Base.88toyotaHiluxBedCap2','HLX88Cap')}},
 {id='roofRack',label='Roof Rack',price=500,requiresAny={'camper','rollbar'},effect='Native roof-rack storage. Requires a camper top or rollbar in the bed attachment slot.',slots={slot('HLX88Roofrack','Base.88toyotaHiluxRoofrack2','Roofrack0')}},
 {id='frontBullbar',label='Front bullbar',price=500,effect='Native front bullbar; replaces the standard front bumper.',slots={slot('DAMNBumperFront','Base.88toyotaHiluxBullbarFrontA','FrontBullbarA')}},
 {id='rearBullbar',label='Rear bullbar',price=500,effect='Native rear bullbar; replaces the standard rear bumper.',slots={slot('DAMNBumperRear','Base.88toyotaHiluxBullbarRearA','RearBullbarA')}},
 {id='steps',label='Side Steps',price=250,effect='Native side-step equipment',slots={slot('DAMNSideSteps','Base.88toyotaHiluxSideSteps2','SideSteps0')}},
 {id='armor',label='Window armor',price=1500,effect='Native armor for fitted window positions: four on SC, six on XC/XCS. Does not add missing cab windows.',partial=true,slots={
  slot('DAMNWindshieldArmor','Base.88toyotaHiluxWindshieldArmor','winda'),
  slot('DAMNFrontLeftArmor','Base.88toyotaHiluxFrontWindowArmor','leftWindowa'),
  slot('DAMNFrontRightArmor','Base.88toyotaHiluxFrontWindowArmor','rightWindowa'),
  slot('DAMNBackLeftArmor','Base.88toyotaHiluxBackWindowArmor','winbla'),
  slot('DAMNBackRightArmor','Base.88toyotaHiluxBackWindowArmor','winbra'),
  slot('DAMNWindshieldRearArmor','Base.88toyotaHiluxWindshieldRearArmor','windra')}},
 {id='bedSpare',label='Bed-mounted spare tire',price=250,effect='Native spare tire and mount',slots={slot('DAMNSpareTireBed','Base.88toyotaHiluxTire2','SpareTire')}},
 {id='spareTire',label='Underbody spare tire',price=250,effect='Native spare tire; hidden underbody mounting',slots={slot('DAMNSpareTire','Base.88toyotaHiluxTire2',false)}},
 {id='rollbar',label='Rollbar',price=0,effect='Native open bed rollbar. Alternative to the camper top in the same bed slot; supports the native roof-rack requirement.',slots={slot('HLX88TruckBedExtras','Base.88toyotaHiluxRollbar2','HLX88Rollbar')}},
 {id='mudflaps',label='Mudflaps',price=0,effect='Native front and rear mudflap set, using the cab-specific positions.',slots={{part='DAMNMudflaps',item='Base.88toyotaHiluxMudflaps2',model='DAMNMudflapsF',models={'DAMNMudflapsF','DAMNMudflapsR'}}}},

}
-- Provider callback mappings: only these exact accessories can override protection.
definitions[3].protectionParts={DAMNBumperFront={'EngineDoor','Engine','HeadlightLeft','HeadlightRight'}}
definitions[4].protectionParts={DAMNBumperRear={'TrunkDoor','HLX88Trunk','HeadlightRearLeft','HeadlightRearRight'}}
definitions[6].protectionParts={
 DAMNFrontLeftArmor={'WindowFrontLeft'},DAMNFrontRightArmor={'WindowFrontRight'},
 DAMNBackLeftArmor={'WindowBackLeft'},DAMNBackRightArmor={'WindowBackRight'},
 DAMNWindshieldArmor={'Windshield'},DAMNWindshieldRearArmor={'WindshieldRear'},
}
local scripts={'Base.88toyotaHiluxSC','Base.88toyotaHiluxXC','Base.88toyotaHiluxXCS'}
for i,d in ipairs(definitions)do d.bit=2^(i-1)end -- Preserve paid orders and saved masks.
definitions[1].priceSetting='camperTop';definitions[1].bonusSetting='camperTopCapacityBonus'
definitions[1].exclusiveGroup='bedAttachment';definitions[9].exclusiveGroup='bedAttachment'
definitions[10].policyAlias='native:%s:DAMNMudflaps:Base.88toyotaHiluxMudflaps2'
definitions[10].orderAlias=definitions[10].policyAlias
local stock={DAMNBumperFront={'Base.88toyotaHiluxBumperFront0','FrontBumper0'},DAMNBumperRear={'Base.88toyotaHiluxBumperRear0','RearBumper0'}}
for _,id in ipairs({'TireFrontLeft','TireFrontRight','TireRearLeft','TireRearRight'})do stock[id]={'Base.88toyotaHiluxTire2','HLX88Tire0'}end
Registry.register({id='tsb:hilux88',scripts=scripts,definitions=definitions,stock=stock,blankParts={TruckBed=true},capacityPart='HLX88Trunk',legacyHilux=true,
 previewAppearance=' skin { texture = Vehicles/Vehicles_88toyotaHilux_Shell_beige, } textureMask = Vehicles/Vehicles_88toyotaHilux_Mask, textureLights = Vehicles/Vehicles_88toyotaHilux_Lights, ',
 previewPrefixes={['Base.88toyotaHiluxSC']='HiluxSC',['Base.88toyotaHiluxXC']='HiluxXC',['Base.88toyotaHiluxXCS']='HiluxXCS'}})
return true
