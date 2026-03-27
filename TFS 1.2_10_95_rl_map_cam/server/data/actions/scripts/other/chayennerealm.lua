function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(Storage.chayennerealm.lua) == 1 then
		return false
	end

	player:setStorageValue(Storage.chayennerealm, 1)
	player:addItem(18511, 1)
	return true
end