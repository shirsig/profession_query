profession_query = {}

profession_query_skills = {}

function profession_query.on_event()
	if event == 'TRADE_SKILL_SHOW' then
		profession_query.update_trade_skill()
	elseif event == 'CRAFT_SHOW' then
		profession_query.update_craft()
	elseif event == 'CHAT_MSG_WHISPER' then
		profession_query.respond(arg1, arg2)
	end
end

function profession_query.update_craft()
	local category
	for i=1,GetNumCrafts() do
		local name, _, entry_type = GetCraftInfo(i)
		if entry_type == 'header' then
			category = name
		else
			local link = GetCraftItemLink(i)
			if not profession_query_skills[link] then
				local reagents = {}
				for j=1,GetCraftNumReagents(i) do
					tinsert(reagents, {
						link = GetCraftReagentItemLink(i, j),
						count = ({ GetCraftReagentInfo(i, j) })[3],
					})
				end
				
				profession_query_skills[link] = {
					name = name,
					category = category,
					link = link,
					reagents = reagents,
				}
			end
		end
	end
end

function profession_query.update_trade_skill()
	local category
	for i=1,GetNumTradeSkills() do
		local name, entry_type = GetTradeSkillInfo(i)
		if entry_type == 'header' then
			category = name
		else
			local link = GetTradeSkillItemLink(i)
			if not profession_query_skills[link] then
				local reagents = {}
				for j=1,GetTradeSkillNumReagents(i) do
					tinsert(reagents, {
						link = GetTradeSkillReagentItemLink(i, j),
						count = ({ GetTradeSkillReagentInfo(i, j) })[3],
					})
				end
				
				profession_query_skills[link] = {
					name = name,
					category = category,
					link = link,
					reagents = reagents,
				}
			end
		end
	end
end

function profession_query.respond(message, sender)
	local _, _, pattern = strfind(message, '^%?(.+)')
	if pattern then
		for _, skill in pairs(profession_query_skills) do
			if strfind(strlower(skill.name), strlower(pattern)) then
				local response = skill.link..' ='
				for i, reagent in ipairs(skill.reagents) do
					response = response..string.format(
						' %s x %i',
						reagent.link,
						reagent.count
					)
				end
				SendChatMessage(response ,'WHISPER' ,nil , sender)
			end
		end
	end
end