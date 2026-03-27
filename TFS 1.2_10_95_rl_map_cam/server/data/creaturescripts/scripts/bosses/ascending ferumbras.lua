local t = {
    tpId = 1387,                         -- ID do teleport.
    tpNew = {x = 33392, y = 31473, z = 14}, -- Local onde irá aparecer o teleport.
    tpPos = {x = 33388, y = 31412, z = 14}, -- Local para onde o teleport irá levar.
    monster = "ascending ferumbras",                 -- Nome do monstro(pokémon/normal), coloque em letra minúscula.
    timeRemove = 60                       -- Tempo para remover o teleport em segundos.
}

function onKill(cid, target)
    local function removeTeleport(position)
    position.stackpos = 1
        if (getThingfromPos(position).itemid == t.tpId) then
	    doRemoveItem(getThingfromPos(position).uid)
	    doSendMagicEffect(t.tpNew, 13)
        end
       return true
    end

    if (isMonster(target) and string.lower(getCreatureName(target)) == t.monster) then
       doCreateTeleport(t.tpId, t.tpPos, t.tpNew)
       doCreatureSay(target, "Você tem ".. t.timeRemove .." segundos para entrar no teleport.", TALKTYPE_ORANGE_1, 0, 0, t.tpNew)
       addEvent(removeTeleport, t.timeRemove * 1000, t.tpNew)
    end
   return true
end