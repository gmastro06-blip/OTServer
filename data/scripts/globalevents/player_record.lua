local event = GlobalEvent("PlayerRecord")

function event.onRecord(current, old)
	do
		local __sched_msg = "New record: " .. current .. " players are logged in."
		local __sched_status = MESSAGE_STATUS_DEFAULT
		local __sched_delay = 150
		addEvent(function()
			Game.broadcastMessage(__sched_msg, __sched_status)
		end, __sched_delay)
	end
	return true
end

event:register()
