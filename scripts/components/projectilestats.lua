local ProjectileStats = Class(function(self, inst)
    self.inst = inst

	--------------------------------
	self.opponent = nil
	self.playernumber = nil
	self.master = self.inst.components.stats.master
	
	self.xprojectilespeed = 0
	self.yprojectilespeed = 0
	
	self.maxreturnspeedx = 4
	self.maxreturnspeedy = 4
	
	self.yhitboxoffset = 0
	self.xhitboxoffset = 0
	
	--12-8-17 
	self.projectileduration = 100 --LIKE 3 SECONDS
	self.originalprojectileduration = nil
	
	--9-13-18
	self.reflectdirection = "leftright"  --DETERMINES WHAT DIRECTION THIS SPECIFIC PROJECTILE WILL GO WHEN REFLECTED. VERTICAL, HORIZONTAL, OR BOTH
	self.physicsbased = false  --TO DETERMINE IF A PROJECTILE IS PROPELED BY THE PHYSICS-ENGINE/GRAVITY AS OPPOSED TO MOTORS
	
	--12-4-21
	self.inst:StartUpdatingComponent(self)
	self.boomerang_accel = 0.3
	self.yrangreturn = 1.0 --THE HEIGHT MODIFIER THE BOOMERANG WILL ATTEMPT TO RETURN TO
	self.boomeranging = false --SHOULD ONLY BE TRUE WHILE BOOMERANGS ARE ON THEIR WAY BACK TO OWNER, TO BECOME GRABABLE

end)


--12-8-17 WE WILL NOW HANDLE PROJECTILE LIFESPAN AS A MANIPULATEABLE TIMER IN HERE
function ProjectileStats:SetProjectileDuration(duration)
	self.projectileduration = duration
	self.originalprojectileduration = duration --IN CASE WE NEED TO KNOW FOR LIKE REFLECTING THINGS
end
--AND ANOTHER ONE, JUST FOR EASE OF ACCESS
function ProjectileStats:AddProjectileDuration(duration)
	self.projectileduration = self.projectileduration + duration
end


--[[  --12-4-21 NAH, GET THIS ROOKIE CRAP OUTTA HERE
function ProjectileStats:BeActive(me)
	self.inst.Physics:SetMotorVel(self.xprojectilespeed, self.yprojectilespeed, 0)
	me.task_projectilemovement = me:DoPeriodicTask(0.1, function()
		self.inst.Physics:SetMotorVel(self.xprojectilespeed, self.yprojectilespeed, 0) --8-30 A NEW COMPONENT BASED SPEED SYSTEM THAT CAN BE ALTERED BY OUTSIDE SOURCES
	end)
	
	--12-8-17 SLOWLY TICKS DOWN. CAN BE ADDED ON TO BY OUTSIDE SOURCES --REUSEABLE
	me:DoPeriodicTask(0, function()
		if not me:HasTag("hitfrozen") then --DOESN'T TICK DOWN WHILE IN HITLAG
			self.projectileduration = self.projectileduration - 1
			if self.projectileduration == 0 then --REMOVE THEM ONCE THEIR TIMER REACHES ZERO
				me:Remove()
			end
		end
	end)
end
]]

--12-4-21 /SIGH/ OH BOY, THIS COMPONENT COULD USE AN UPDATE. LETS FIX THIS
function ProjectileStats:OnUpdate(dt)
	self.inst.Physics:SetMotorVel(self.xprojectilespeed, self.yprojectilespeed, 0)
	
	if not self.inst:HasTag("hitfrozen") then --DOESN'T TICK DOWN WHILE IN HITLAG
		self.projectileduration = self.projectileduration - 1
		if self.projectileduration == 0 then --REMOVE THEM ONCE THEIR TIMER REACHES ZERO
			self.inst:Remove()
		end
	end
	
	
	if self.boomeranging then
		if not (self.master and self.master:IsValid()) then
			return end
			
		local mypos, myposy = self.inst.Transform:GetWorldPosition()
		local ownerpos, ownerposy = self.master.Transform:GetWorldPosition()
		
		-- print("OWNER RAD", math.floor((myposy*10) ) /10, math.floor(ownerposy*10)/10, math.floor((myposy - ownerposy)*10)/10)
		-- print("PROJECTILE SPEED", self.yprojectilespeed)
		local yreturnmod = self.yrangreturn - self.yhitboxoffset
		
		local rangmod = 1
		if mypos > ownerpos then
			rangmod = -1
		end
		rangmod = rangmod * self.inst.components.launchgravity:GetRotationValue()
		
		local yrangmod = 1
		if (myposy*1) < (ownerposy + yreturnmod) then
			yrangmod = -1
		end
		
		self.xprojectilespeed = self.xprojectilespeed + (self.boomerang_accel * rangmod)
		self.yprojectilespeed = self.yprojectilespeed - (self.boomerang_accel * yrangmod)
		
		
		--SPEED CAPS
		if self.xprojectilespeed > self.maxreturnspeedx then
			self.xprojectilespeed = self.maxreturnspeedx 
		elseif self.xprojectilespeed < -self.maxreturnspeedx then
			self.xprojectilespeed = -self.maxreturnspeedx
		end
		
		if self.yprojectilespeed > self.maxreturnspeedy then
			self.yprojectilespeed = self.maxreturnspeedy
		elseif self.yprojectilespeed < -self.maxreturnspeedy then
			self.yprojectilespeed = -self.maxreturnspeedy
		end
		
		
		if math.abs(mypos - ownerpos) <= 1 and math.abs(myposy - (ownerposy + yreturnmod)) <= 1 then
			self.inst.SoundEmitter:PlaySound("dontstarve/wilson/equip_item") --12-4-21 LOL THIS MAKES MUCH MORE SENSE
			self.master:PushEvent("boomerang_catch")
			self.inst:Remove()
		end
	end
	
end


function ProjectileStats:BePhysicsBased()
	--self.inst.task_projectilemovement:Cancel() --12-4-21 WE REPLACED THIS WITH ONUPDATE
	self.inst:StopUpdatingComponent(self)
	self.physicsbased = true
	self.inst.Physics:SetDamping(0.0)
	self.inst.Physics:ClearMotorVelOverride()
end


--9-9-18 -REFLECT PROJECTILES!!!
function ProjectileStats:OnReflect(newmaster)

	--5-6-20 SOME EXTRA UTILITY FOR REFLECTING THINGS
	-- self.inst.components.hurtboxutil.owner:PushEvent("got_reflected") --PUSHED TO THE THING THAT GOT REFLECTED (I HOPE)
	-- self.opponent:PushEvent("reflected_something") --PUSHED TO THE PLAYER REFLECTING THE THING
	self.inst:PushEvent("got_reflected") --PUSHED TO THE THING THAT GOT REFLECTED (I HOPE)
	newmaster:PushEvent("reflected_something") --PUSHED TO THE PLAYER REFLECTING THE THING

	self.master = newmaster --.components.stats.master --WE DONT USE THIS VERSION OF MASTER
	self.inst.components.stats.master = newmaster --THIS KIND OF MASTER ALSO NEEDS TO BE CHANGED
	
	--AND CHANGE IT'S TEAM TOO! (EVEN IF THAT MEANS CHANGING IT TO NIL)
	if self.inst.components.stats.team then
		self.inst.components.stats.team = newmaster.components.stats.team
	end
	
	--GET ITS POSITION SO WE CAN TURN IT AROUND
	local pos = Vector3(self.inst.Transform:GetWorldPosition())
	
	if self.reflectdirection == "leftright" or self.reflectdirection == "both" then
		self.inst:ForceFacePoint((pos.x + (-self.inst.components.launchgravity:GetRotationValue())), (pos.y + 1), (pos.z)) --WHY +1?
	end
	
	self.projectileduration = self.originalprojectileduration or self.projectileduration --RESET THE LIFESPAN OF THE PROJECTILE BACK TO WHAT IT USED TO BE
	
	--FLIP ITS POSITIONAL OFFSETS (BUT ONLY ON THE AXIS THAT IT'S FLIPED ON)
	self.xhitboxoffset = -self.xhitboxoffset --THIS ONE WILL ALMOST ALWAYS GET FLIPPED. UNLESS ITS A PROJECTILE THAT TRAVEL'S STRAIGHT DOWN
	
	--9-13-18 -A SEPERATE CASE FOR PHYSICS-BASED PROJECTILES
	if self.physicsbased == true then
		--NO MOTORS HERE. JUST GET THEIR CURRENT PHYSICAL SPEED AND REFLECT IT ACCORDINGLY.
		local vx, vy = self.inst.Physics:GetVelocity()
		
		if self.reflectdirection == "leftright" then
			self.inst.Physics:SetVel(-vx, vy, 0)
		elseif self.reflectdirection == "updown" then
			self.inst.Physics:SetVel(vx, -vy, 0)
		elseif self.reflectdirection == "both" then
			self.inst.Physics:SetVel(-vx, -vy, 0)
		end
	end
end



--[[
function ProjectileStats:Rang(myspeedx, myspeedy)
	
	if not (self.master and self.master:IsValid()) then
		return end
		
	local mypos, myposy = self.inst.Transform:GetWorldPosition()
	local ownerpos, ownerposy = self.master.Transform:GetWorldPosition()
	--local myspeedy = myspeedx / 2 --12-4-21 HOLDPU, TF IS THIS??? NO
	
	-- X RETURN
	if (mypos*1) > ownerpos then --self.inst.components.launchgravity:GetRotationValue()
		self.xprojectilespeed = self.xprojectilespeed + ((myspeedx) / 3) --math.abs(
		-- print("-----------------LEFT", myspeedx, myspeednewx, self.xprojectilespeed, mypos, ownerpos, self.inst.components.launchgravity:GetRotationValue())
	elseif (mypos*1) < ownerpos then
		self.xprojectilespeed = self.xprojectilespeed - ((myspeedx*1) / 3) --math.abs(
		-- print("-----------------RIGHT", myspeedx, myspeednewx, self.xprojectilespeed, mypos, ownerpos, self.inst.components.launchgravity:GetRotationValue())
	end
	
	
	--Y RETURN
	if mypos > ownerpos then --8-30 TO --DONE (FOR NOW)--!!!!!!!! USE THIS ONE THINGY I USED IN AIFEELINGS TO FIX WHATEVER THE HECK GOES WRONG WHEN X SIDES ARE REVERSED
		if (myposy*1) < (ownerposy + 0.6) then
			-- self.yprojectilespeed = self.yprojectilespeed + ((myspeedy) / 3) --math.abs(
			self.yprojectilespeed = self.yprojectilespeed - ((myspeedy*1) / 3)
			--12-4-21 WAIT WHY TF IS IT REVERSED FOR THE LEFT?... AND WHY DOES IT BREAK WHEN I UNDO IT?!
		elseif (myposy*1) > (ownerposy + 0.6) then
			-- self.yprojectilespeed = self.yprojectilespeed - ((myspeedy*1) / 3) --math.abs(
			self.yprojectilespeed = self.yprojectilespeed + ((myspeedy) / 3)
		end 
	else
		if (myposy*1) < (ownerposy + 0.6) then --1
			self.yprojectilespeed = self.yprojectilespeed + ((myspeedy) / 3) --math.abs(
		elseif (myposy*1) > (ownerposy + 0.6) then
			self.yprojectilespeed = self.yprojectilespeed - ((myspeedy*1) / 3) --math.abs(
		end 
	end
	--ALRIGHT THIS IS MEGA SUS, LET ME JUST TRY AGAIN FROM SCRATCH
	
	
	--MAX SPEED RESTRAINER
	if self.xprojectilespeed > self.maxreturnspeedx then
		self.xprojectilespeed = self.maxreturnspeedx 
	elseif self.xprojectilespeed < -self.maxreturnspeedx then
		self.xprojectilespeed = -self.maxreturnspeedx
	end
	
	if self.yprojectilespeed > myspeedy then
		-- self.yprojectilespeed = myspeedy  --9-1 REMOVING THESE FOR NOW BECAUSE THEY ARE CAUSING PROBLEMS WHEN PROJECTILE IS THROWN TO THE LEFT --THEFIXLIST
	elseif self.yprojectilespeed < -myspeedy then
		-- self.yprojectilespeed = -myspeedy
	end
	
	--12-4-21 OKAY, IT'S NOT ACTUALLY THE GRAB RADIUS, IT'S THAT IT WAS FLYING PAST US BEFORE THE DETECTOR COULD REGISTER IT
	--IM MOVING THE GRAB DETECTION UP INTO A PROPER ONUPDATE TO RUN EVERY FRAME LIKE IT SHOULD
	--I CAN'T EASILY DO THAT WITH THE RANG() FUNCTION ITSELF, BECAUSE THAT WOULD AFFECT THE PROJECTILE RETURN SPEED
	-- print("OWNER RAD", math.floor((myposy*10) ) /10, math.floor(ownerposy*10)/10, math.floor((myposy - ownerposy)*10)/10)
	
	if math.abs(mypos - ownerpos) <= 1 and math.abs(myposy - ownerposy) <= 5 then   --DOUBLING THE CATCH RADIUS
		-- self.inst.SoundEmitter:PlaySound("dontstarve/wilson/use_break") --9-8 ADDING SOUNDS
		-- self.inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_linebreak")
		-- self.inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_straw")
		self.inst:Remove()
	end
end


function ProjectileStats:ReturnToOwner(roundabout, myspeedx, myspeedy) --8-30 A NEW COMPONENT BASED SPEED SYSTEM THAT CAN BE ALTERED BY OUTSIDE SOURCES
	
	if not (self.master and self.master:IsValid()) then
		return end
		
	local mypos = self.inst.Transform:GetWorldPosition()
	local ownerpos = self.master.Transform:GetWorldPosition()
	local myspeedx, myspeedy = self.inst.Physics:GetMotorVel()
	
	self.inst:DoPeriodicTask((roundabout/4), function()
		-- self:Rang(mypos, ownerpos, -myspeedx*self.inst.components.launchgravity:GetRotationValue(), myspeedy)
		self:Rang((-myspeedx*self.inst.components.launchgravity:GetRotationValue()), myspeedy)
	end)
	
	self.boomeranging = true
end
]]


--DETERMINES WHEN THE PROJECTILE WILL START TO TURN AROUND AND FLY BACK TO IT'S OWNER, AND AT WHAT SPEED
function ProjectileStats:DoBoomerang(flytime, accel, maxreturnspeedx, maxreturnspeedy)
	self.maxreturnspeedx = maxreturnspeedx
	self.maxreturnspeedy = maxreturnspeedy
	self.boomerang_accel = accel
	
	--local myspeedx, myspeedy = self.inst.Physics:GetMotorVel()
	
	self.inst:DoTaskInTime(flytime, function()
		-- projectile.components.projectilestats:ReturnToOwner(0.25, 0.3) --8-30 A NEW COMPONENT BASED SPEED SYSTEM THAT CAN BE ALTERED BY OUTSIDE SOURCES
		--self:ReturnToOwner(roundabout, myspeedx, myspeedy)
		--12-4-21  REPLACING "RANG" AND "RETURNTOOWNER" WITH A SIMPLER AND MORE ROBUST ONUPDATE TO HANDLE BOTH.
		self.boomeranging = true
	end)
end


function ProjectileStats:SetProjectileSpeed(xspeed, yspeed)
	self.xprojectilespeed = xspeed
	self.yprojectilespeed = yspeed
end


return ProjectileStats