function onKill(cid, target) 

local m = {
["crystalcrusher"] = 101001,
["cliff strider"] = 101002, 
["ironblight"] = 101003,
["lava golem"] = 101004,
["orewalker"] = 101005,
["hideous fungus"] = 101006,
["humongous fungus"] = 101007,
["damaged crystal golem"] = 101008,
["magma crawler"] = 101009,
["lost berserker"] = 101010,
["enraged crystal golem"] = 101011,
["infected weeper"] = 101012,
["weeper"] = 101013,
["wiggler"] = 101014,
["vulcongra"] = 101015,
} 
  
if(isMonster(target) == TRUE) then 
local n = getCreatureName(target) 
local name_monster = m[string.lower(n)] 
if(name_monster) then 
local contagem = getPlayerStorageValue(cid, name_monster) 
if(contagem == -1) then 
contagem = 1 
end 
setPlayerStorageValue(cid, name_monster, contagem+1)  
end 
end 
return TRUE 
end