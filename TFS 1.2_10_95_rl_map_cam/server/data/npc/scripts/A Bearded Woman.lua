local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

local t = {}
local renown = {}

local config = {
	['earthheart cuirass'] = {itemid = 25177, token = {type = 'silver', id = 25172, count = 100}},
	['earthheart platemail'] = {itemid = 25179, token = {type = 'silver', id = 25172, count = 100}},
	['earthmind raiment'] = {itemid = 25191, token = {type = 'silver', id = 25172, count = 100}},
	['earthsoul tabard'] = {itemid = 25187, token = {type = 'silver', id = 25172, count = 100}},
	['fireheart cuirass'] = {itemid = 25174, token = {type = 'silver', id = 25172, count = 100}},
	['fireheart hauberk'] = {itemid = 25175, token = {type = 'silver', id = 25172, count = 100}},
	['fireheart platemail'] = {itemid = 25176, token = {type = 'silver', id = 25172, count = 100}},
	['firemind raiment'] = {itemid = 25190, token = {type = 'silver', id = 25172, count = 100}},
	['firesoul tabard '] = {itemid = 25186, token = {type = 'silver', id = 25172, count = 100}},
	['frostheart cuirass'] = {itemid = 18517, token = {type = 'silver', id = 25172, count = 100}},
	['frostheart hauberk'] = {itemid = 25184, token = {type = 'silver', id = 25172, count = 100}},
	['frostheart platemail'] = {itemid = 25185, token = {type = 'silver', id = 25172, count = 100}},
	['frostmind raiment'] = {itemid = 25193, token = {type = 'silver', id = 25172, count = 100}},
	['frostsoul tabard'] = {itemid = 25189, token = {type = 'silver', id = 25172, count = 100}},
	['thunderheart cuirass'] = {itemid = 25180, token = {type = 'silver', id = 25172, count = 100}},
	['thunderheart hauberk'] = {itemid = 25181, token = {type = 'silver', id = 25172, count = 100}},
	['thunderheart platemail'] = {itemid = 25182, token = {type = 'silver', id = 25172, count = 100}},
	['thundermind raiment'] = {itemid = 25192, token = {type = 'silver', id = 25172, count = 100}},
	['thundermind tabard'] = {itemid = 25188, token = {type = 'silver', id = 25172, count = 100}},	
	}


local function getTable()
	local itemsList = {
		{name = "bell", id = 18343, buy = 50},
		{name = "gnomish crystal package", id = 18313, buy = 1000},
		{name = "gnomish extraction crystal", id = 18213, buy = 50},
		{name = "gnomish spore gatherer", id = 18328, buy = 50},
		{name = "little pig", id = 18339, buy = 150}
	}
	return itemsList
end

local function setNewTradeTable(table)
	local items, item = {}
	for i = 1, #table do
		item = table[i]
		items[item.id] = {itemId = item.id, buyPrice = item.buy, sellPrice = item.sell, subType = 0, realName = item.name}
	end
	return items
end

local function onBuy(cid, item, subType, amount, ignoreCap, inBackpacks)
	local player = Player(cid)
	local items = setNewTradeTable(getTable())
	local count = 0
	for i = 1, amount do
		local item = Game.createItem(items[item].itemId, subType)
		if player:addItemEx(item, false) ~= RETURNVALUE_NOERROR then
			npcHandler:say('First make sure you have enough space in your inventory.', cid)
			break
		end
		count = i
	end

	if count == 0 then
		return true
	end

	player:removeMoney(items[item].buyPrice * count)
	player:sendTextMessage(MESSAGE_INFO_DESCR, string.format('Bought %dx %s for %d gold.', count, items[item].realName, items[item].buyPrice * count))
	return true
end

local function greetCallback(cid)
	npcHandler:setMessage(MESSAGE_GREET, 'Ola eu troco os Silver Tokens por Itens Diga {equipamento}')
	return true
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	if msgcontains(msg, 'equipamento') then
		npcHandler:say({
			'{Silver Token}  ...',
					}, cid)
	elseif msgcontains(msg, 'silver token') then
		npcHandler:say({
			'Por Silver Tokens voce pode trocar entre {Earthheart Cuirass}, a {Earthheart Platemail}, {Earthmind Raiment}, a {Earthsoul Tabard} , a {Fireheart Cuirass}, a {Fireheart Hauberk}, {Fireheart Platemail}, {Firemind Raiment}, {Firesoul Tabard}, {Frostheart Cuirass}, {Frostheart Hauberk}, {Frostheart Platemail}, {Frostmind Raiment}, {Frostsoul Tabard}, {Thunderheart Cuirass}, {Thunderheart Hauberk}, {Thunderheart Platemail}, {Thundermind Raiment}, {Thundersoul Tabard} ...',
		}, cid)
	elseif msgcontains(msg, 'minor') then
		npcHandler:say({
			'For two minor tokens, you can buy one gnomish {supply} package! For eight tokens, you can buy a {muck} remover! For ten tokens, you can buy a {mission} crystal. For fifteen tokens, you can buy a crystal {lamp} or a mushroom {backpack}. ...',
			'For seventy tokens, I can offer you a voucher for an {addition to the soil guardian outfit}, or a voucher for an {addition to the crystal warlord armor outfit}.'
		}, cid)
	elseif config[msg] then
		local itemType = ItemType(config[msg].itemid)
		npcHandler:say(string.format('Do you want to trade %s %s for %d %s tokens?', (itemType:getArticle() ~= "" and itemType:getArticle() or ""), itemType:getName(), config[msg].token.count, config[msg].token.type), cid)
		npcHandler.topic[cid] = 1
		t[cid] = msg
	elseif msgcontains(msg, 'relations') then
		local player = Player(cid)
		if player:getStorageValue(Storage.BigfootBurden.QuestLine) >= 14 then
			npcHandler:say('Our relations improve with every mission you undertake on our behalf. Another way to improve your relations with us gnomes is to trade in minor crystal tokens. ...', cid)
			npcHandler:say('Your renown amongst us gnomes is currently {' .. math.max(0, player:getStorageValue(Storage.BigfootBurden.Rank)) .. '}. Do you want to improve your standing by sacrificing tokens? One token will raise your renown by 5 points. ', cid)
			npcHandler.topic[cid] = 2
		else
			npcHandler:say('You are not even a recruit of the Bigfoots. Sorry I can\'t help you.', cid)
		end
	elseif npcHandler.topic[cid] == 3 then
		local amount = getMoneyCount(msg)
		if amount > 0 then
			npcHandler:say('Do you really want to trade ' .. amount .. ' minor tokens for ' .. amount * 5 .. ' renown?', cid)
			renown[cid] = amount
			npcHandler.topic[cid] = 4
		end
	elseif msgcontains(msg, 'items') then
		npcHandler:say('Do you need to buy any mission items?', cid)
		npcHandler.topic[cid] = 5
	elseif msgcontains(msg, 'yes') then
		if npcHandler.topic[cid] == 1 then
			local player, targetTable = Player(cid), config[t[cid]]
			if player:getItemCount(targetTable.token.id) < targetTable.token.count then
				npcHandler:say('Sorry, you don\'t have enough ' .. targetTable.token.type .. ' tokens with you.', cid)
				npcHandler.topic[cid] = 0
				return true
			end

			local item = Game.createItem(targetTable.itemid, 1)
			local weight = 0
			weight = ItemType(item.itemid):getWeight(item:getCount())

			if player:addItemEx(item) ~= RETURNVALUE_NOERROR then
				if player:getFreeCapacity() < weight then
					npcHandler:say('First make sure you have enough capacity to hold it.', cid)
				else
					npcHandler:say('First make sure you have enough space in your inventory.', cid)
				end
				npcHandler.topic[cid] = 0
				return true
			end

			player:removeItem(targetTable.token.id, targetTable.token.count)
			npcHandler:say('Here have one of our ' .. item:getPluralName() .. '.', cid)
			npcHandler.topic[cid] = 0
		elseif npcHandler.topic[cid] == 2 then
			npcHandler:say("How many tokens do you want to trade?", cid)
			npcHandler.topic[cid] = 3
		elseif npcHandler.topic[cid] == 4 then
			local player = Player(cid)
			if player:removeItem(18422, renown[cid]) then
				player:setStorageValue(Storage.BigfootBurden.Rank, math.max(0, player:getStorageValue(Storage.BigfootBurden.Rank)) + renown[cid] * 5)
				npcHandler:say('As you wish! Your new renown is {' .. player:getStorageValue(Storage.BigfootBurden.Rank) .. '}.', cid)
			else
				npcHandler:say('You don\'t have these many tokens.', cid)
			end
			npcHandler.topic[cid] = 0
		elseif npcHandler.topic[cid] == 5 then
			openShopWindow(cid, getTable(), onBuy, onSell)
			npcHandler:say('Let us see if I have what you need.', cid)
			npcHandler.topic[cid] = 0
		end
	elseif msgcontains(msg, 'no') and isInArray({1, 3, 4, 5}, npcHandler.topic[cid]) then
		npcHandler:say('As you like.', cid)
		npcHandler.topic[cid] = 0
	end
	return true
end

local function onReleaseFocus(cid)
	t[cid], renown[cid] = nil, nil
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, onReleaseFocus)
npcHandler:addModule(FocusModule:new())
