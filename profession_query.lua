local private, public = {}, {}
profession_query = public

profession_query_skills = {}

local TRADE_SKILL, CRAFT = {}, {}

function public.on_event()
	if event == 'TRADE_SKILL_SHOW' then
		private.update_profession(TRADE_SKILL)
	elseif event == 'CRAFT_SHOW' then
		private.update_profession(CRAFT)
	elseif event == 'CHAT_MSG_WHISPER' then
		private.respond(arg1, arg2)
	end
end

function private.profession(profession_type)
	if profession_type == CRAFT then
		return ({ GetCraftSkillLine(1) })[1]
	elseif profession_type == TRADE_SKILL then
		return ({ GetTradeSkillLine() })[1]
	end
end

function private.entry_count(profession_type)
	if profession_type == CRAFT then
		return GetNumCrafts()
	elseif profession_type == TRADE_SKILL then
		return GetNumTradeSkills()
	end
end

function private.info(profession_type, index)
	local name, entry_type
	if profession_type == CRAFT then
		name, _, entry_type = GetCraftInfo(index)
	elseif profession_type == TRADE_SKILL then
		name, entry_type = GetTradeSkillInfo(index)
	end
	return name, entry_type
end

function private.item_link(profession_type, index)
	if profession_type == CRAFT then
		return GetCraftItemLink(index)
	elseif profession_type == TRADE_SKILL then
		return GetTradeSkillItemLink(index)
	end
end

function private.reagent_count(profession_type, index)
	if profession_type == CRAFT then
		return GetCraftNumReagents(index)
	elseif profession_type == TRADE_SKILL then
		return GetTradeSkillNumReagents(index)
	end
end

function private.reagent_link(profession_type, entry_index, reagent_index)
	if profession_type == CRAFT then
		return GetCraftReagentItemLink(entry_index, reagent_index)
	elseif profession_type == TRADE_SKILL then
		return GetTradeSkillReagentItemLink(entry_index, reagent_index)
	end
end

function private.reagent_quantity(profession_type, entry_index, reagent_index)
	if profession_type == CRAFT then
		return ({ GetCraftReagentInfo(entry_index, reagent_index) })[3]
	elseif profession_type == TRADE_SKILL then
		return ({ GetTradeSkillReagentInfo(entry_index, reagent_index) })[3]
	end
end

function private.update_profession(profession_type)
	local profession = private.profession(profession_type)
	for i=1,private.entry_count(profession_type) do
		local name, entry_type = private.info(profession_type, i)
		if entry_type ~= 'header' then
			local link = private.item_link(profession_type, i)
			local reagents = {}
			for j=1,private.reagent_count(profession_type, i) do
				tinsert(reagents, {
					link = private.reagent_link(profession_type, i, j),
					quantity = private.reagent_quantity(profession_type, i, j),
				})
			end
			
			profession_query_skills[link] = {
				name = name,
				profession = profession,
				link = link,
				reagents = reagents,
			}
		end
	end
end

function private.respond(message, sender)
	local _, _, pattern_string = strfind(message, '^%?(.+)')
	if pattern_string then
		local patterns = private.split_on_whitespace(pattern_string)

		local matches = {}
		for _, skill in pairs(profession_query_skills) do
			if private.match(patterns, skill) then
				tinsert(matches, skill)
			end
		end
			
		local total_matches = getn(matches)
		
		while getn(matches) > 3 do
			tremove(matches, getn(matches))
		end
		
		if getn(matches) == 0 then
			SendChatMessage('No matches for "'..pattern_string..'"' ,'WHISPER', nil, sender)
		elseif getn(matches) < total_matches then
			SendChatMessage(total_matches..' match'..(total_matches > 1 and 'es' or '')..' for "'..pattern_string..'" ('..(total_matches - 3)..' omitted):' ,'WHISPER', nil, sender)
		else
			SendChatMessage(total_matches..' match'..(total_matches > 1 and 'es' or '')..' for "'..pattern_string..'":' ,'WHISPER', nil, sender)
		end
		
		for _, match in ipairs(matches) do
			local partial_response = match.link..' ='
			for i, reagent in ipairs(match.reagents) do
				local reagent_info = string.format(
					'%s x %i',
					reagent.link,
					reagent.quantity
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

function private.match(patterns, skill)
	for _, pattern in ipairs(patterns) do
		local name_match = strfind(strlower(skill.name), strlower(pattern))
		local profession_match = strfind(strlower(skill.profession), strlower(pattern))
		if not (name_match or profession_match) then
			return false
		end
	end
	return true
end

function private.split_on_whitespace(text)
	parts = {}
    for part in string.gfind(text, '(%S+)') do
		tinsert(parts, part)
    end
	return parts
end