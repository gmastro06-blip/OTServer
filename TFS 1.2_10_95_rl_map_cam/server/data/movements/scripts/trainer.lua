addSta = {}
local config = {
timeToAdd = 3, -- intervalo de tempo para adicionar.
addTime = 5, -- quanto vai adicionar.
}

local function addStamina(cid)
    if not isPlayer(cid) then
        addSta[cid] = nil
	return true
    end
    doPlayerSetStamina(cid, getPlayerStamina(cid) + config.addTime)
	doPlayerSendTextMessage(cid, 25, "Você recebeu "..config.addTime.." minutos de stamina.")
    addSta[cid] = addEvent(addStamina, config.timeToAdd * 60 * 1000, cid)
end

function onStepIn(cid)
    if isPlayer(cid) then
        addSta[cid] = addEvent(addStamina, config.timeToAdd * 60 * 1000, cid)
    end
return true
end

function onStepOut(cid)
    if isPlayer(cid) then
        stopEvent(addSta[cid])
        addSta[cid] = nil
    end
return true
end