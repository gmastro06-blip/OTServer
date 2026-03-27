local stamina_full = 42 -- horas (stamina full)

function onUse(cid, item, fromPosition, itemEx, toPosition, isHotkey)

	local player = Player(cid)
	if player:getPremiumDays() < 1 then
		player:sendCancelMessage("You must have a premium account.")
	else
		if player:getStamina() >= (stamina_full * 60) then
			player:sendCancelMessage("Your stamina is already full.")
		else
			player:setStamina(stamina_full * 60)
			player:sendTextMessage(MESSAGE_INFO_DESCR, "Your stamina has been refilled.")
			item:remove(1)
		end
	end

	return true
end