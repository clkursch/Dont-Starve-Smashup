local HoverBadge = Class(function(self, inst)
    self.inst = inst

	self.testbadge = nil
	self.topper = nil
	
	self.teamglow = nil --1-20-22
	self.playerheight = self.inst.components.stats.height
	self.glowoffset = 0
	
	self.case = "health" --FOR BADGE POSITIONS
	--REALLY ALL WE DO WITH THIS IS IF = "BLOCK" THEN BADGE GOES UNDER THE PLAYER
	
	self.badgeposx = 0
	self.badgeposy = 2
	self.badgesize = 2 --DST CHANGE ONLY  - SINCE IT SEEMED 1.5 BIT SMALL IN DST
	
	self.inst:StartUpdatingComponent(self)
end)
--THIS WHOLE THING SEEMS KIND OF INEFFICIANT BUT YOU KNOW WHAT, IT MAKES SENSE AND IS EASY TO UNDERSTAND SO IT'S STAYING




function HoverBadge:TestBadge(player)   
	
	if not TheWorld.ismastersim then 
		return end --12-7-17 MAYBE ONLY THE MASTER SHOULD RUN THIS...
		
		
		
	--TOPPER NEEDS TO GO ON TOP
	--12-10-17 --SAME WITH TOPPER
	if self.topper then
		self.topper:Remove()
	end
	
	self.topper = SpawnPrefab("fight_fx")
	-- local healthfxpos = Vector3(v.Transform:GetWorldPosition())
	self.topper.AnimState:SetBank("status_meter")
	self.topper.AnimState:SetBuild("status_meter")
	self.topper.AnimState:PlayAnimation("anim")
	self.topper.AnimState:SetPercent("anim", 50/100)
	self.topper.AnimState:SetAddColour(0,0,0,0)
	self.topper.AnimState:SetMultColour( (174 / 255), (21 / 255), (21 / 255), 1 ) --9-28-20
	self.topper.Transform:SetScale(self.badgesize,self.badgesize,self.badgesize)
	self.topper.entity:AddPhysics()
	self.topper:Hide()
	
	
	
	--12-10-17 --LETS TRY THIS. IF THERES ALREADY A TESTBADGE, REMOVE IT FIRST. WE ONLY WANT ONE
	if self.testbadge then
		self.testbadge:Remove()
		self.badgeframe:Remove()
	end
	
	self.testbadge = SpawnPrefab("fight_fx")
	-- local healthfxpos = Vector3(v.Transform:GetWorldPosition())
	-- self.testbadge.AnimState:SetBank("effigy_topper") 
	-- self.testbadge.AnimState:SetBank("status_meter")  --4-14-20 OH THEY CHANGED THE NAME. ITS NO LONGER EFFIGY_TOPPER
	-- self.testbadge.AnimState:SetBuild("status_meter")
	-- self.testbadge.AnimState:SetBank("health")
	self.testbadge.AnimState:SetBank("status_meter") --4-14-20 THEY CHANGED THIS FROM HEALTH TOO
	self.testbadge.AnimState:SetBuild("status_meter")
	self.testbadge.AnimState:PlayAnimation("frame")
	--9-28-20 OK WAIT ITS MORE THAN JUST THAT. THEY CHANGED THE WAY THE ENTIRE THING WORKS, ANIMATION-WISE
	-- self.testbadge.AnimState:SetMultColour( (174 / 255), (21 / 255), (21 / 255), 1 )
	-- self.testbadge.AnimState:SetMultColour( 1, 0, 0, 1 )
	--AND THE ICON FOR THE BADGE ISN'T AN ACTUAL ANIMATION, BUT A SET OF SPRITES FROM AN ANIMATION BANK MANUALLY REPLACED
	local iconbuild = "status_health" --AND THERE MUST BE A FOLDER OF SPRITES CALLED "ICON" IN THAT BUILD
	self.testbadge.AnimState:OverrideSymbol("icon", iconbuild, "icon")
	
	
	self.testbadge.AnimState:SetPercent("frame", 0) --YET WE STILL USE THIS I GUESS?
	
	self.testbadge.AnimState:SetAddColour(0,0,0,0)
	self.testbadge.Transform:SetScale(self.badgesize,self.badgesize,self.badgesize)
	self.testbadge.entity:AddPhysics()
	-- self.inst:StartUpdatingComponent(self) --OH, THATS NIFTY
	-- self.inst:StartWallUpdatingComponent(self)
	self.testbadge:Hide()
	
	
	--4-15-20 HEY, THERES A FRAME NOW... HAS THAT ALWAYS BEEN THERE?? COULD'VE SWORN THAT WAS BUILT INTO THE ORIGINAL SPRITE
	self.badgeframe = SpawnPrefab("fight_fx")
	self.badgeframe.AnimState:SetBank("status_meter")
	self.badgeframe.AnimState:SetBuild("status_meter")
	self.badgeframe.AnimState:PlayAnimation("frame")
	self.badgeframe.AnimState:SetAddColour(0,0,0,0)
	self.badgeframe.Transform:SetScale(self.badgesize,self.badgesize,self.badgesize)
	self.badgeframe:Hide()
	
	
	--9-28-20
	--MY FIGHTFX PREFABS CAN'T BE FLIPPED UPSIDE DOWN OR TURNED BLACK LIKE UI ANIMS CAN...
	--SO I GUESS THAT BLACK TOPPER JUST ISN'T GOING TO BE A THING ANYMORE
	
end



function HoverBadge:AddTeamGlow(color)   
	if not TheWorld.ismastersim then 
		return end
	
	if self.teamglow then
		self.teamglow:Remove()
	end
	
	self.teamglow = SpawnPrefab("fight_fx")
	self.teamglow.AnimState:SetBank("fight_fx")
	self.teamglow.AnimState:SetBuild("fight_fx")
	self.teamglow.AnimState:PlayAnimation("softglow")
	
	if color == "red" then
		self.teamglow.AnimState:SetAddColour(1,0,0,0.2)
	elseif color == "blue" then
		self.teamglow.AnimState:SetAddColour(0,0,1,0.2)
	end
	
	local glowsize = 2
	self.teamglow.Transform:SetScale(glowsize, glowsize, glowsize)
end



--THIS IS CURRENTLY UNUSED 4-15-20
function HoverBadge:SpawnBadge(player)
	
	local healthfx = SpawnPrefab("fight_fx")
	local healthfxpos = Vector3(v.Transform:GetWorldPosition())
	healthfx.AnimState:SetBank("status_meter")
	healthfx.AnimState:SetBuild("status_meter")
	healthfx.AnimState:SetBank("status_health")
	healthfx.AnimState:SetBuild("status_health")
	healthfx.AnimState:PlayAnimation("anim")
	healthfx.AnimState:SetPercent("anim", percent/100)
	healthfx.AnimState:SetAddColour(0,0,0,0)
	healthfx.entity:AddPhysics()
	-- healthfx.Transform:SetPosition((healthfxpos.x), (healthfxpos.y + 2), (healthfxpos.z + 0.3))
	healthfx:DoPeriodicTask(0, function()
		if healthfx:IsValid() then
			local healthfxpos = Vector3(v.Transform:GetWorldPosition())
			healthfx.Transform:SetPosition((healthfxpos.x), (healthfxpos.y + 2), (healthfxpos.z + 0.3))
			local velx, vely = v.Physics:GetVelocity()
			-- healthfx.entity:AddPhysics()
			healthfx.Physics:SetVel(velx, vely, 0)
		end
	end)
	healthfx:DoTaskInTime((30)*FRAMES, function(inst)
		healthfx:Remove()
	end)
	
	
	local healthfx = SpawnPrefab("fight_fx")
	local healthfxpos = Vector3(v.Transform:GetWorldPosition())
	healthfx.AnimState:SetBank("status_meter")
	healthfx.AnimState:SetBuild("status_meter")
	healthfx.AnimState:PlayAnimation("anim")
	healthfx.AnimState:SetPercent("anim", percent/100)
	healthfx.AnimState:SetAddColour(0,0,0,0)
	healthfx.entity:AddPhysics()
	-- healthfx.Transform:SetPosition((healthfxpos.x), (healthfxpos.y + 2), (healthfxpos.z + 0.3))
	healthfx:DoPeriodicTask(0, function()
		if healthfx:IsValid() then
			local healthfxpos = Vector3(v.Transform:GetWorldPosition())
			healthfx.Transform:SetPosition((healthfxpos.x), (healthfxpos.y + 2), (healthfxpos.z + 0.3))
			local velx, vely = v.Physics:GetVelocity()
			-- healthfx.entity:AddPhysics()
			healthfx.Physics:SetVel(velx, vely, 0)
		end
	end)
	healthfx:DoTaskInTime((30)*FRAMES, function(inst)
		healthfx:Remove()
	end)
end



function HoverBadge:UpdatePosition()
	
	if not TheWorld.ismastersim then 
		return end --12-7-17 MAYBE ONLY THE MASTER SHOULD RUN THIS...
	
	local healthfx = self.testbadge --1-20-22 ?? WELL THIS IS A WEIRD WAY TO DO IT BUT OK 
	
	if healthfx:IsValid() then
		local healthfxpos = Vector3(self.inst.Transform:GetWorldPosition())
		
		-- if self.inst.sg and self.inst.sg:HasStateTag("blocking") then --CUSTOM BADGE FOR BLOCKING
		if self.case == "block" then --CUSTOM BADGE FOR BLOCKING
			healthfx.Transform:SetPosition((healthfxpos.x + self.badgeposx), (healthfxpos.y -0.3), (healthfxpos.z + 0.32))
			self.badgeframe.Transform:SetPosition((healthfxpos.x + self.badgeposx), (healthfxpos.y -0.3), (healthfxpos.z + 0.3))
			self.topper.Transform:SetPosition((healthfxpos.x + self.badgeposx), (healthfxpos.y -0.29), (healthfxpos.z + 0.30)) --ADD 0.05!!! REUSEABLE
		else
			healthfx.Transform:SetPosition((healthfxpos.x + self.badgeposx), (healthfxpos.y + self.badgeposy), (healthfxpos.z + 0.32))
			self.badgeframe.Transform:SetPosition((healthfxpos.x + self.badgeposx), (healthfxpos.y + self.badgeposy), (healthfxpos.z + 0.3))
			self.topper.Transform:SetPosition((healthfxpos.x + self.badgeposx), (healthfxpos.y + self.badgeposy), (healthfxpos.z + 0.30))
		end
	end
	
	--1-20-22 ADDING IT IN HOVERBADGE BECAUSE THIS COMPONENTS GETS WALLUPDATED OR SOMETHING. SO IT'S EXTRA SMOOTH
	if self.teamglow then
		local mypos = Vector3(self.inst.Transform:GetWorldPosition())
		self.teamglow.Transform:SetPosition(mypos.x, (mypos.y + self.glowoffset), (mypos.z - 0.32))
	end
	
end


function HoverBadge:SetTopperPercent(perc, length)
	
	self.testbadge:CancelAllPendingTasks() --OTHERWISE PREVIOUS HITS ENDING WILL OVERLAP THE HIDE TASK
	-- print("SETTING THE TOPPER TO ", perc)
	
	-- self.testbadge.AnimState:SetPercent("anim", perc) --9-28-20 REMOVING SINCE THE METHOD HAS CHANGED. NOW SWAPS ICONS INSTEAD OF AN ANIMATION
	self.testbadge:Show() --THIS SEEMS TO BE THE MISSING ONE
	self.badgeframe:Show()
	
	self.topper.AnimState:SetPercent("anim", perc)
	self.topper:Show() --ONLY DISABLED FOR TESTING --6-30-20
	
	self.testbadge:DoTaskInTime((length)*FRAMES, function(inst)
		self.testbadge:Hide()
		self.badgeframe:Hide()
		--6-10-18 FOR SHIELDS, WE NEED THIS OFF. BUT FOR HEARTS, WE NEED IT ON. SO IF > 1 THEN TURN IT ON
		if length > 1 then
			self.topper:Hide()
		end
	end)
	
end

function HoverBadge:SetBadgeSprite(iconbuild, tint, case)  --9-28-20 UPDATING WITH A NEW METHOD!
	-- self.testbadge.AnimState:SetBank(bank) --9-28-20 REMOVING THESE TWO SINCE THE METHOD HAS CHANGED
	-- self.testbadge.AnimState:SetBuild(build)
	
	self.testbadge.AnimState:OverrideSymbol("icon", iconbuild, "icon")
	--MAYBE WE SHOULD SET THE COLOR HERE TOO?
	self.topper.AnimState:SetMultColour(unpack(tint))
	
	if case then
		self.case = case
	else
		self.case = "status_health" --status_health
	end
	
end

function HoverBadge:ForceHide() 
	--12-31-21 THE PLAYABLE SPIDER WARRIOR APPARENTLY CAUSES ALL SORTS OF ISSUES WITH THIS :/ THE TESTBADGE SHOULD EXST HERE BUT FOR SOME REASON IT DONT.
	if self.testbadge then
		self.testbadge:Hide()
		self.badgeframe:Hide()
		self.topper:Hide()
	end
end


function HoverBadge:OnUpdate(dt) --2-21-17 IS THIS HOW THIS WORKS? I DUNNO, IVE NEVER DONE THIS BEFORE
	if self.teamglow then
		if self.inst.sg:HasStateTag("hanging") then
			self.glowoffset = -(self.playerheight/2)
		elseif self.inst.sg:HasStateTag("grounded") then
			self.glowoffset = 0.5
		else
			self.glowoffset = (self.playerheight/2)
		end
		
		--MOSTLY FOR LIKE MAXWELL'S TELEPORT AND STUFF
		if self.inst.sg:HasStateTag("invisible") then
			self.teamglow:Hide()
		else
			self.teamglow:Show()
		end
	end
end


function HoverBadge:RemoveAllBadges() --6-10-18 -GET RID OF ALL THIS TRASH AFTER THEY DIE  -DST CHANGE REUSEABLE
	if self.testbadge then --3-3-19 --IS THIS CLIENT OR HOST SIDE? I REALLY CANT TELL BUT DEDICATED WANTS THIS
		self.testbadge:Remove()
		self.badgeframe:Remove()
		self.topper:Remove()
	end
	if self.teamglow then
		self.teamglow:Remove()
	end
end


return HoverBadge
