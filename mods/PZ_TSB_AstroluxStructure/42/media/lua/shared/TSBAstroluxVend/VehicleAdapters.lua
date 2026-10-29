-- Shared data-only adapter registration. Other mods may register from shared Lua.
local A={version=0,definitions={},byScript={},ids={}}
function A.register(adapter)
 assert(type(adapter)=='table' and type(adapter.id)=='string' and not A.ids[adapter.id],'Duplicate/invalid vehicle adapter')
 assert(type(adapter.scripts)=='table' and #adapter.scripts>0,'Adapter needs exact native script names')
 local ids={};for _,d in ipairs(A.definitions)do ids[d.id]=true end
 for _,d in ipairs(adapter.definitions or {})do
  assert(type(d.id)=='string' and not ids[d.id] and type(d.label)=='string' and type(d.slots)=='table' and #d.slots>0,'Invalid/duplicate accessory definition')
  ids[d.id]=true
  assert(d.bit==nil or adapter.id=='tsb:hilux88','New adapters must use stable namespaced IDs, not legacy bit positions')
  if adapter.id~='tsb:hilux88'then assert(d.id:find(adapter.id..':',1,true)==1,'Accessory ID must start with adapter ID and colon')end
  for _,slot in ipairs(d.slots)do assert(type(slot.part)=='string' and type(slot.item)=='string','Invalid native slot/item mapping')end
 end
 if adapter.appraisalProfile then
  assert(type(adapter.appraisalProfile)=='table' and #adapter.appraisalProfile>0,'Appraisal profile needs reviewed native part IDs')
  local seen={};for _,id in ipairs(adapter.appraisalProfile)do assert(type(id)=='string' and not seen[id],'Invalid/duplicate appraisal part');seen[id]=true end
 end
 local scripts={};for _,name in ipairs(adapter.scripts)do assert(type(name)=='string' and not scripts[name] and not A.byScript[name],'Duplicate native script adapter');scripts[name]=true end
 -- Commit only after the entire registration validates.
 A.ids[adapter.id]=true
 for name in pairs(scripts)do A.byScript[name]=adapter end
 for _,d in ipairs(adapter.definitions or {})do d.vehicles=scripts;A.definitions[#A.definitions+1]=d end
 A.version=A.version+1
end
function A.get(name)return A.byScript[name]end
return A
