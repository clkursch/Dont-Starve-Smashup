local VisualsManager = Class(function(self, inst)
    self.inst = inst

	self.testbadge = nil
	self.topper = nil
	
	self.case = "health" --FOR BADGE POSITIONS
	
	self.badgeposx = 0
	self.badgeposy = 2
	self.badgesize = 1.5
	
	
	self.ignorestate = nil --DONT DO ANYTHING WITH THIS STATE IF SPECIFICALLY ASKED NOT TO, UNTIL THE USER GOES TO ANOTHER STATE
	
	self.multcolorstorage = nil --KEEPING TRACK OF THEIR OLD ONE
	
	self.blinking = false --FOR THE INTANGIBILITY DETECTOR TO TELL IF IT SHOULD IGNORE
	self.firstblink = false --TO BLINK ON THE FIRST FRAME OF INTANGIBILITY
	
	--10-25-17 SHIMMY STUFF
	self.shimmydir = "left" --NOT SURE IF I EVEN USED THIS
	self.shimmytick = 1
end)



--10-29-17 REUSEABLE -I WOULD LIKE TO MOVE THE BLINK FUNCTION INTO THIS COMPONENT HERE, IF POSSIBLE SO THAT THE INTANGIBLE DETECTOR CAN IGNORE IT
--TO MAKE AN INST BLINK A CERTAIN COLOR FOR A GIVEN DURATION
function VisualsManager:Blink(inst, duration, r, g, b, glow, alpha) --I MIGHT ADD ADDITIONAL VARIABLES FOR GLOW COLORS
	
	if not r then
		r = 0
		g = 0
		b = 0
	end
	
	if not glow then
		glow = 0
	end
	
	if not alpha then
		alpha = 1
	end
	
	--10-18-17 DST CHANGE!!! REUSEABLE - AND SO IS MOST OF THIS NEW FN CHANGES
	local glowr = glow
	local glowg = glow
	local glowb = glow
	
	if r < 0 then
		glowr = -r
	end
	if g < 0 then
		glowr = -g
	end
	if b < 0 then
		glowr = -b
	end
	
	-- inst.AnimState:SetMultColour((alpha + r),(alpha + g),(alpha + b),alpha)
	inst.AnimState:SetMultColour((0 + r),(0 + g),(0 + b),alpha)
	-- inst.AnimState:SetAddColour(glow,glow,glow,glow)
	inst.AnimState:SetAddColour(glowr,glowg,glowb,glow) --DST CHANGE!!
	

	self.blinking = true
	
	inst:DoTaskInTime((duration+0)*FRAMES, function(inst) --DST CHANGED +1 TO +0
		inst.AnimState:SetMultColour(1,1,1,1)
		inst.AnimState:SetAddColour(0,0,0,0)
		self.blinking = false
	end)
end



--12-16-17 LETS GET FANCY WITH THIS LIGHTEMITTER STUFF --REUSEABLE
function VisualsManager:Glow(inst, duration, r, g, b, glow, radius, falloff)
	
	--LIGHT EMMITTER AT GROUND LEVEL CAN LOOK WEIRD WITH A TILTED CAMERA. LETS PUSH IT UP A BIT
	-- inst.components.hitbox:MakeFX("slide1", 0, 0, 0, 	1.5, 1.5,	 0.8, duration, 0,  nil,nil,nil, 1)
	-- local bulb = inst.components.stats.lastfx --NAH. FX BLINKS SEEM TO CANCEL OUT EARLY FOR SOME REASON. IM NOT SURE WHY
	local bulb = inst
	
	if not r then
		r = 1
		g = 1
		b = 1
	end
	
	bulb.entity:AddLight()
	bulb.Light:SetIntensity(glow) --.8
	bulb.Light:SetRadius(radius) --.5
	bulb.Light:SetFalloff(falloff) --0.65
	bulb.Light:SetColour(r, b, g)
	bulb.Light:Enable(true)
	
	bulb:DoTaskInTime((duration)*FRAMES, function(inst)
		bulb.Light:Enable(false)
	end)
end




function VisualsManager:Shimmy(start, add, tickadd) --(START SHIMMY, ADD SHIMMY, TICK, TICK TO ADD)

	local shim = start

	--NO, FORGET TICK. IT WILL BE 2 AT ALL TIMES. 2 IS A GOOD NUMBER FOR THIS
	self.inst.shimmytask = self.inst:DoPeriodicTask((2*FRAMES), function() 
		local x,y,z = self.inst.Transform:GetWorldPosition()
		shim = shim * -1 --CHANGE DIRECTION EVERY TIME
		self.inst.Transform:SetPosition( (x + shim), y, z )
	end)
	
	
	--THIS IS THE TASK TO INCREASE SHIMMY
	self.inst.shimmyaddtask = self.inst:DoPeriodicTask((tickadd*FRAMES), function() 
		if shim < 0 then
			shim = shim - add
		else
			shim = shim + add
		end
	end)
	
	--1-9-22 AND NOW WE NEED A FAILSAFE TASK TO END THE SHIMMY TO PREVENT THE OMEGA BROKEN TELEPORTING BUG
	self.inst.shimmyfailtask = self.inst:DoTaskInTime(5, function(inst) 
		self.inst.components.visualsmanager:EndShimmy()
	end)
		
end


--END THE SHIMMY
function VisualsManager:EndShimmy() --IF THE SHIMMY TASK STILL EXISTS, END IT

	if self.inst.shimmytask then
		self.inst.shimmytask:Cancel()
	end
	
	if self.inst.shimmyaddtask then
		self.inst.shimmyaddtask:Cancel()
	end
	
	if self.inst.shimmyfailtask then
		self.inst.shimmyfailtask:Cancel()
	end
end



function VisualsManager:UpdatePosition()

	local healthfx = self.testbadge
	
	if healthfx:IsValid() then
		local healthfxpos = Vector3(self.inst.Transform:GetWorldPosition())
		
		-- if self.inst.sg and self.inst.sg:HasStateTag("blocking") then --CUSTOM BADGE FOR BLOCKING
		if self.case == "block" then --CUSTOM BADGE FOR BLOCKING
			healthfx.Transform:SetPosition((healthfxpos.x + self.badgeposx), (healthfxpos.y -0.3), (healthfxpos.z + 0.3))
			self.topper.Transform:SetPosition((healthfxpos.x + self.badgeposx), (healthfxpos.y -0.3), (healthfxpos.z + 0.3))
		else
			healthfx.Transform:SetPosition((healthfxpos.x + self.badgeposx), (healthfxpos.y + self.badgeposy), (healthfxpos.z + 0.3))
			self.topper.Transform:SetPosition((healthfxpos.x + self.badgeposx), (healthfxpos.y + self.badgeposy), (healthfxpos.z + 0.3))
		end
	end
	
end


--IF THE PLAYER IS INTANGIBLE, ADD A LITTLE GLOW TO EM
function VisualsManager:CheckForIntangibilityGlow(player) 

	if self.blinking or self.ignorestate or player.sg:HasStateTag("ignoreglow") then return end --DON'T BOTHER IF THEY'RE IN THE MIDDLE OF A BLINK OR SPECIFY TO IGNORE THE STATE
	
	if player.sg and player.sg:HasStateTag("intangible") or player.components.stats:IsInvuln() == true then
		player.AnimState:SetMultColour(0.8,0.8,0.8,0.8)
		player.AnimState:SetAddColour(0.15,0.15,0.15,0.15)
		player:AddTag("intglow")
		
		if self.firstblink == true then --ONLY BLINK AT THE BEGINNING OF A SET OF INTANGIBILITY
			-- self:Blink(player, 4,   1, 1, 1,   0.2)
			
			--ACTUALLY, LETS JUST DO IT CUSTOM
			player.AnimState:SetMultColour(1,1,1,0.9)
			player.AnimState:SetAddColour(0.3,0.3,0.3,0.3)
			self.blinking = true
			
			player:DoTaskInTime(3*FRAMES, function(player)
				self.blinking = false
			end)
			
			self.firstblink = false
		end
		
	elseif player:HasTag("intglow") then --JUST SET IT BACK ONCE. DONT KEEP EM THAT WAY THE WHOLE GAME
		player:RemoveTag("intglow") 
		self.firstblink = true
		player.AnimState:SetMultColour(1,1,1,1) --TEMP
		player.AnimState:SetAddColour(0,0,0,0)
	end
	
end



function VisualsManager:ForceHide() 
	self.testbadge:Hide()
	self.topper:Hide()
	
end


--ALRIGHT. SINCE ONUPDATE DOESNT SEEM TO WORK BY ITSELF.
function VisualsManager:CustomUpdate(inst) --2-21-17 IS THIS HOW THIS WORKS? I DUNNO, IVE NEVER DONE THIS BEFORE
	inst:DoPeriodicTask(0, function(inst) --CLOSE ENOUGH!
		self:CheckForIntangibilityGlow(inst)
	end)
end


return VisualsManager
