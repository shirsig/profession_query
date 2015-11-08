profession_query = {}

profession_query_skills = {}

function profession_query.on_event()
	if event == 'TRADE_SKILL_SHOW' then
		profession_query.update_skills()
	elseif event == 'CHAT_MSG_WHISPER' then
		profession_query.respond(arg1, arg2)
	end
end

function profession_query.update_skills()
	local category
	for i=1,GetNumTradeSkills() do
		local name, entry_type = GetTradeSkillInfo(i)
		if entry_type == 'header' then
			category = name
			snipe.log(name)
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
	for _, skill in pairs(profession_query_skills) do
		if strfind(strlower(skill.name), strlower(message)) then
			SendChatMessage(skill.link ,'WHISPER' ,'Common' , sender)
			for i, reagent in ipairs(skill.reagents) do
				local reagent_message = string.format(
					'[reagent %i] %s x %i',
					i,
					reagent.link,
					reagent.count
				)
				SendChatMessage(reagent_message ,'WHISPER' ,'Common' , sender)
			end
			snipe.log(skill.link)
		end
	end
end