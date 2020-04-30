-- Register the behaviour
behaviour("ChatFeed")

-- The max number of lines allowed
local maxLines = 10

local playerInvolvedMessageChanceBoost = 0.6

local friendlySquadStatusChance = 0.2;
local enemySquadStatusChance = 0.01;

local killerMessageChance = 0.3
local killedMessageChance = 0.2

local teamKillerMessageChance = 0.5
local teamKilledMessageChance = 0.2

local statusPostTime = 1
local statusPostTimeVariance = 5

local postTimeVariance = 1
local killerPostTime = 1
local killedPostTime = postTimeVariance + 0.5

local killerMessages = {
	"Haha I got you good %s",
	"Lol %s got you again!",
	"Easy!!",
	"Boom, headshot!",
	"Wow %s that was epic",
	"Hahaha %s",
	"This is too easy...",
	"WAOW",
	"I clicked on your head, %s",
	"%s >:D",
}

local killedMessage = {
	"Oh come on...",
	"Wow you are good %s",
	"Nice one %s",
	"Good kill lol",
	"Oh no you got me %s",
	"I almost had you %s",
	"I'll get you for that %s",
	"I dont get it %s how are you so good?",
	"HOW?",
	"Awww %s... Again?!",
	"Oof %s outta nowhere",
}

local teamKillerMessages = {
	"Oh noooo, sorry!",
	"Oops my bad %s",
	"Sorry %s",
	"Oops!",
	"Sorry %s, it will not happen again",
	"Aww %s I'm sorry!",
	"sry",
	"sry %s",
}

local teamKilledMessages = {
	"Hey, watch it %s",
	"Stop teamkilling plz",
	"plz %s",
	"Stop it %s",
	"Aww %s come on...",
	"%s...",
	"...",
}



function ChatFeed:Start()
	-- Run when behaviour is created
	GameEvents.onActorDied.AddListener(self, "OnActorDied")
	GameEvents.onSquadAssignedNewOrder.AddListener(self, "OnSquadAssignedNewOrder");

	self.text = self.targets.text.GetComponent(Text)

	-- Create empty lines
	self.lines = {}
	for i=1,maxLines do
		self.lines[i] = ""
	end

	self:UpdateText()
end

function ChatFeed:OnSquadAssignedNewOrder(squad, order)

	local chance = friendlySquadStatusChance;
	if squad.leader.team ~= Player.team then
		chance = enemySquadStatusChance;
	end

	if not RandomChance(chance) then
		return
	end

	local messageSource = squad.leader;
	local memberCount = #squad.members;
	if squad.hasPlayerLeader then
		if(memberCount == 1) then
			return
		else
			messageSource = squad.members[2]
			memberCount = memberCount - 1;
		end
	end

	local subject = "We are "
	if #squad.members == 1 then
		subject = "I am "
	end

	local verb = "";

	if order.type == OrderType.Attack then
		verb = "attacking "
	elseif order.type == OrderType.Defend then
		verb = "defending "
	elseif order.type == OrderType.Roam then
		verb = "scouting around "
	else
		return
	end

	local message = subject .. verb .. string.lower(order.targetPoint.name)

	if squad.squadVehicle ~= nil then
		message = message .. " using " .. string.lower(squad.squadVehicle.name)
	end

	local delay = statusPostTime + math.random() * statusPostTimeVariance
	self:PushMessageAfterDelay(messageSource, message, delay)

	if messageSource.team ~= Player.team then
		self:PushMessageAfterDelay(messageSource, "Oops, wrong team chat :(", delay + 2)
	end
end

function ChatFeed:OnActorDied(actor, killer, isSilent)
	if isSilent then
		return
	end

	if killer ~= nil and actor ~= killer then
    	--self:PushBoldLine(GetActorString(killer) .. " killed " .. GetActorString(actor))

		if actor.team == killer.team then
			self:OnTeamKill(actor, killer)
		else
			self:OnKill(actor, killer)
		end

    else
    	--self:PushBoldLine(GetActorString(actor) .. " died")
    end
end

function RandomChance(chance)
	return math.random() < chance
end

function ChatFeed:OnKill(actor, killer)
	local baseChance = 0
	if actor.isPlayer or killer.isPlayer then
		baseChance = playerInvolvedMessageChanceBoost
	end

	if RandomChance(baseChance + killerMessageChance) then
		self:FormatBotMessage(killer, actor, killerMessages, killerPostTime + math.random() * postTimeVariance)
	end

	if RandomChance(baseChance + killedMessageChance) then
		self:FormatBotMessage(actor, killer, killedMessage, killedPostTime + math.random() * postTimeVariance)
	end
end

function ChatFeed:OnTeamKill(actor, killer)
	local baseChance = 0
	if actor.isPlayer or killer.isPlayer then
		baseChance = playerInvolvedMessageChanceBoost
	end

	if RandomChance(baseChance + teamKillerMessageChance) then
		self:FormatBotMessage(killer, actor, teamKillerMessages, killerPostTime + math.random() * postTimeVariance)
	end

	if RandomChance(baseChance + teamKilledMessageChance) then
		self:FormatBotMessage(actor, killer, teamKilledMessages, killedPostTime + math.random() * postTimeVariance)
	end
end

function ChatFeed:FormatBotMessage(from, to, messageCollection, delay)
	if from.isPlayer then
		return
	end

	local message = string.format(GetRandomEntry(messageCollection), to.name)

	if to.isPlayer then
		-- Highlight messages directed to the player
		message = "<b>"..message.."</b>"
	end

	self:PushMessageAfterDelay(from, message, delay)
end

function ChatFeed:PushMessageAfterDelay(from, message, delay)
	self.script.StartCoroutine(function() self.PushMessageAfterDelayCoroutine(self, from, message, delay) end)
end

function ChatFeed:PushMessageAfterDelayCoroutine(from, message, delay)
	coroutine.yield(WaitForSeconds(delay))
	self:PushMessage(from, message)
end

function GetActorString(actor)
	local color = ColorScheme.GetTeamColorBrighter(actor.team)
	color = Color.Lerp(color, Color.white, 0.5)

	return ColorScheme.RichTextColorTag(color) .. actor.name .. "</color>"
end

function ChatFeed:PushLine(line)
	for i=1,maxLines-1 do
		self.lines[i] = self.lines[i+1]
	end
	self.lines[maxLines] = line

	self:UpdateText()
end

function ChatFeed:PushBoldLine(line)
	self:PushLine("<b>"..line.."</b>")
end

function ChatFeed:PushMessage(actor, message)
	self.targets.audio.Play()
	self:PushLine(GetActorString(actor) .. ": " .. message)
end

function ChatFeed:UpdateText()
	local finalString = ""

	for i=1,maxLines do
		if self.lines[i] ~= "" then
			finalString = finalString .. self.lines[i] .. "\n"
		end
	end

	self.text.text = finalString
end

function GetRandomEntry(collection)
	return collection[math.random(#collection)]
end