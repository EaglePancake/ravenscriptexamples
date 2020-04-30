-- Register the behaviour
behaviour("NameTags")

function NameTags:Start()

	self.tags = {}

	for k,actor in pairs(ActorManager.actors) do
		if actor.isBot then
			local tag = GameObject.Instantiate(self.targets.tagPrefab).GetComponent(Text)
			tag.rectTransform.parent = self.targets.canvas.transform
			tag.rectTransform.position = Vector3(100, 100, 0)
			tag.CrossFadeAlpha(0, 0, true)

			tagData = {}
			tagData.tag = tag;
			tagData.isDrawing = false
			tagData.lastSeenTimestamp = 0;
			tagData.usingDriverTag = false
			self.tags[actor] = tagData

			self:SetDefaultTag(actor)
		end
	end
end

function NameTags:SetTag(actor, suffix)
	local color = ColorScheme.GetTeamColorBrighter(actor.team)
	color = Color.Lerp(color, Color.white, 0.5)
	local prefix = ColorScheme.RichTextColorTag(color)

	self.tags[actor].tag.text = prefix .. actor.name .. suffix .. "</color>"
end

function NameTags:SetDriverTag(actor)

	local passengers = -1 -- Start at -1 since the driver shouldn't count towards the passenger number.
	local seats = actor.activeVehicle.seats
	for k,seat in pairs(seats) do
		if seat.isOccupied then
			passengers = passengers + 1
		end
	end

	local suffix = ""
	if passengers > 0 then
		suffix = " +"..passengers
	end

	self:SetTag(actor, suffix)
	self.tags[actor].usingDriverTag = true
end

function NameTags:SetDefaultTag(actor)
	self:SetTag(actor, "")
	self.tags[actor].usingDriverTag = false
end

function NameTags:Update()
	if self.tags ~= nil then

		local camera = PlayerCamera.activeCamera
		local worldToScreenMatrix = camera.projectionMatrix * camera.worldToCameraMatrix

		for actor,tagData in pairs(self.tags) do

			local tag = tagData.tag

			local anchorWorldPos = actor.centerPosition;
			anchorWorldPos.y = anchorWorldPos.y + 1
			--local anchorScreenPos = worldToScreenMatrix.MultiplyPoint(anchorWorldPos)
			local anchorScreenPos = camera.WorldToScreenPoint(anchorWorldPos)

			if(ActorManager.ActorCanSeePlayer(actor)) then
				tagData.lastSeenTimestamp = Time.time;
			end

			local isTeammate = actor.team == Player.team
			local focusSize = Screen.height/10
			local isInFocus = math.abs(anchorScreenPos.x - Screen.width/2) < focusSize and math.abs(anchorScreenPos.y - Screen.height/2) < focusSize

			local isInView = anchorScreenPos.z > 0
			local shouldDraw = isInView and not actor.isDead and not actor.isPassenger and (isInFocus or (isTeammate and anchorScreenPos.z < 50)) and tagData.lastSeenTimestamp > Time.time - 0.2

			if not tagData.isDrawing and shouldDraw then
				tagData.isDrawing = true
				tag.CrossFadeAlpha(1, 0.1, true)
			elseif tagData.isDrawing and not shouldDraw then
				tagData.isDrawing = false
				tag.CrossFadeAlpha(0, 0.1, true)
			end

			if shouldDraw then
				-- Check if we should update the tag or not
				if actor.isDriver then
					-- Always update driver tags since there might be new passengers.
					self:SetDriverTag(actor)
				elseif not actor.isDriver and tagData.usingDriverTag then
					-- Only set the default tag once.
					self:SetDefaultTag(actor)
				end
			end

			tag.rectTransform.position = anchorScreenPos
			
			if(isInView) then
				tag.color = Color.white;
			else
				tag.color = Color.clear;
			end
		end
	end
end
