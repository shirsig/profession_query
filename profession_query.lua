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
	for i=1,GetNumCrafts() do
		local name, _, entry_type = GetCraftInfo(i)
		if entry_type ~= 'header' then
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
					link = link,
					reagents = reagents,
				}
			end
		end
	end
end

function profession_query.update_trade_skill()
	for i=1,GetNumTradeSkills() do
		local name, entry_type = GetTradeSkillInfo(i)
		if entry_type ~= 'header' then
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
	
		local matches = {}
		for _, skill in pairs(profession_query_skills) do
			if strfind(strlower(skill.name), strlower(pattern)) then
				tinsert(matches, skill)
			end
		end
		
		local total_matches = getn(matches)
		
		while getn(matches) > 3 do
			tremove(matches, getn(matches))
		end
		
		if getn(matches) == 0 then
			SendChatMessage('No matches for '..pattern ,'WHISPER', nil, sender)
		elseif getn(matches) < total_matches then
			SendChatMessage('Matches for '..pattern..' ('..(total_matches - 3)..' omitted):' ,'WHISPER', nil, sender)
		else
			SendChatMessage('Matches for '..pattern..':' ,'WHISPER', nil, sender)
		end
		
		for _, match in ipairs(matches) do
			local partial_response = match.link..' ='
			for i, reagent in ipairs(match.reagents) do
				local reagent_info = string.format(
					'%s x %i',
					reagent.link,
					reagent.count
				)
				if strlen(partial_response..reagent_info) > 255 then
					SendChatMessage(partial_response ,'WHISPER', nil, sender)
					partial_response = '(cont.)'
				end
				partial_response = partial_response..' '..reagent_info
			end
			SendChatMessage(partial_response ,'WHISPER', nil, sender)
		end
	end
end