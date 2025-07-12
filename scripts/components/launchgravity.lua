
--PRETTY MUCH JUST LAUNCH UTILITY FUNCTIONS

local LaunchGravity = Class(function(self, inst)
    self.inst = inst
	
	self.jumpvelocity = nil
	self.gravitypull = nil
	self.jumping = nil
	self.fallingspeed = nil
	self.knockback = nil
	
	self.landinglag = nil
	self.llanim = nil
	self.llstate = nil
	
	self.islaunched = false
	
	self.JUMPIN = nil
	self.LAUNCHIN = nil
	
	self.onlandingfn = nil --10-21-18 --CHARACTER SPECIFIC ON-LAND FNS THAT RUN ON HITTING THE GROUND. FOR SELF USE ONLY!

	self.inst:ListenForEvent("hitground", function(inst)
		self:Land() --1-30-22 MAKING THIS RUN AS AN EVENTLISTENER SO IT'S DELAYED TO RUN AT THE END OF THE FRAME SO HITBOXES CAN REGISTER HITS FIRST
	end) 

end)


--12-15 THIS WILL MAKE THINGS A MILLION TIMES EASIER  --7-14-19 -OKAY I JUST NEED A VERSION OF THIS IN STATS
function LaunchGravity:GetRotationValue(inst)
	--self.dir = self.inst.Transform:GetRotation()
	-- print("ROTATE BANANA", self.inst.Transform:GetRotation(), self.inst)
	if self.inst.Transform:GetRotation() >= - 1 then --1-2 SOMETIMES VALUE IS POSITIVE 180 --OH BOY I MESSED UP, GOING BACK TO THIS METHOD UNTIL I THINK OF SOMETHING ELSE
		return 1
	else
		return -1
	end
end


function LaunchGravity:GetRotationFunction(inst)
	-- self.dir = self.inst.Transform:GetRotation()
	if self.inst.Transform:GetRotation() >= - 1 then
		return "left" 
	else
		return "right" 
	end
end



function LaunchGravity:GetHeight(inst)   --inst
	local x, y = self.inst.Transform:GetWorldPosition()
	return y
end

function LaunchGravity:GetVertSpeed(inst)
	local vx, vy = self.inst.Physics:GetVelocity()
	return vy
end

function LaunchGravity:GetHorSpeed(inst)
	local vx, vy = self.inst.Physics:GetVelocity()
	return vx
end

--12-15
function LaunchGravity:GetAngle(inst)
	local vx, vy = self.inst.Physics:GetVelocity()
	local angle = (math.atan2(vy, vx))/DEGREES --* self:GetRotationValue() --2-29 GONNA TRY REGULAR TAN BECAUSE ATAN MAKES AUTOLINKING VERTICALLY INVERTED
	
	return angle
end


function LaunchGravity:SetLandingLag(ll, anim, state) --1-9  --WHY DID I MAKE IT A LAUNCH GRAVITY FUNCTION???  --12-8-17 REUSEABLE- GO TO A STATE INSTEAD
	self.landinglag = ll
	
	if anim then --1-5-17 I GUESS I SHOULD HAVE DONE THIS A LONG TIME AGO ANYWAYS
		self.llanim = anim 
	else
		self.llanim = nil
	end
	
	if state then --12-8-17 REUSEABLE
		self.llstate = state 
	else
		self.llstate = nil
	end
end


--1-25-17
function LaunchGravity:AiTechTest() --AM I REALLY DOING AI STUFF IN LAUNCHGRAVITY NOW???
	if self.inst:HasTag("cpu") and self.inst.components.aifeelings.ailevel >= 4 then
		-- print("TECH CHANCE:   ", (self.inst.components.aifeelings.techchance + self.inst.components.aifeelings.readytech))
		if math.random() <= (self.inst.components.aifeelings.techchance + self.inst.components.aifeelings.readytech) then
			if math.random() <= (0.2 + (self.inst.components.aifeelings:FtechPercent())) then --STARTS OUT AT 0.5 AND NEVER GOES BACK UP!!!
				self.inst.sg:GoToState("tech_forward_roll")
			elseif math.random() <= (0.5) then --EHHH.. I HATE TO BE LAZY, BUT THERE ISNT REALLY A GOOD WAY TO DO IT
				self.inst.sg:GoToState("tech_backward_roll")
			else
				self.inst.sg:GoToState("tech_getup")
			end
			
			return true --TO SHOW THAT IT IS A CPU AND TO SKIP NORMAL LAND CLUMSEY
		else
			return false --CLUMSEY LAND ANYWAYS
		end
		
	else
		return false
	end
end



function LaunchGravity:HitGround(inst)

	self.inst:PushEvent("ground_check") --9-8 ALLOWS STATES WITH NOLANDINGSTOP TO DO CUSTOM THINGS ON HITTING THE GROUND
	self.inst:RemoveTag("potionhopped")
	self.inst:PushEvent("hitground")
	--[[
	if self.inst.sg:HasStateTag("nolandingstop") then
		-- print("DO NOTHING")
	elseif self.inst.sg:HasStateTag("dizzy") then
		self.inst.sg:GoToState("dizzy")
	elseif self.inst:HasTag("terminal_vel") and self.inst:HasTag("tumbling") then
		self.inst.sg:GoToState("meteor") --10-6-18 
		self.inst:RemoveTag("terminal_vel")
		
	elseif self.inst:HasTag("trytech") and (self.inst.sg:HasStateTag("tumbling") or self.inst:HasTag("cantech")) then--("cantech_window") then
		--self.inst.sg:GoToState("tech_getup")
		self.inst:PushEvent("tech")
	elseif self.landinglag and not self.inst.sg:HasStateTag("autocancel") then --1-9 REDOING WITH A LESS STUPID SETUP
		
		if self.llstate then --12-8-17 IF A LANDING STATE IS SET, GO TO THAT STATE INSTEAD OF LANDING LAG
			self.inst.sg:GoToState(self.llstate)
		else
			self.inst.sg:GoToState("ll_medium_getup", self.landinglag)
		end
		self.inst:PushEvent("hit_ground") --RUNS WAY TOO LATE TO USE FOR ANYTHING BUT WHATEVER, ILL LEAVE IT HERE JUST IN CASE
		self.landinglag = nil
		self.llanim = nil
		self.llstate = nil 
	elseif self.inst.sg:HasStateTag("tumbling") then
		if self:AiTechTest() == false then
			self.inst.sg:GoToState("land_clumsy")
		end
	else
		self.inst.sg:GoToState("run_stop")
	end
	
	self.islaunched = false
	self.inst.components.stats:ResetFallingSpeed()
	self.inst.components.jumper:ResetDoubleJumps()
	self.inst.components.stats.norecovery = false
	self.inst:RemoveTag("juggled") --1-6-17 FOR AI
	
	--10-21-18 --CHARACTER SPECIFIC ON-LAND FNS THAT RUN ON HITTING THE GROUND. FOR SELF USE ONLY!
	if self.onlandingfn then
		self.onlandingfn() --DO IT
	end
	]]
end


--1-30-22 MOVING THIS PORTION OF HITGROUND TO ITS OWN FN THAT RUNS AS PART OF AN EVENT LISTENER, SO THAT IT'S DELAYED LONG ENOUGH FOR ANY HITBOXES TO REGISTER HITS
function LaunchGravity:Land()
	
	if self.inst.sg:HasStateTag("nolandingstop") then
		-- print("DO NOTHING")
	elseif self.inst.sg:HasStateTag("dizzy") then
		self.inst.sg:GoToState("dizzy")
	elseif self.inst:HasTag("terminal_vel") and self.inst:HasTag("tumbling") then
		self.inst.sg:GoToState("meteor") --10-6-18 
		self.inst:RemoveTag("terminal_vel")
		
	elseif self.inst:HasTag("trytech") and (self.inst.sg:HasStateTag("tumbling") or self.inst:HasTag("cantech")) then--("cantech_window") then
		--self.inst.sg:GoToState("tech_getup")
		self.inst:PushEvent("tech")
	elseif self.landinglag and not self.inst.sg:HasStateTag("autocancel") then --1-9 REDOING WITH A LESS STUPID SETUP
		
		if self.llstate then --12-8-17 IF A LANDING STATE IS SET, GO TO THAT STATE INSTEAD OF LANDING LAG
			self.inst.sg:GoToState(self.llstate)
		else
			self.inst.sg:GoToState("ll_medium_getup", self.landinglag)
		end
		self.inst:PushEvent("hit_ground") --RUNS WAY TOO LATE TO USE FOR ANYTHING BUT WHATEVER, ILL LEAVE IT HERE JUST IN CASE
		self.landinglag = nil
		self.llanim = nil
		self.llstate = nil 
	elseif self.inst.sg:HasStateTag("tumbling") then
		if self:AiTechTest() == false then
			self.inst.sg:GoToState("land_clumsy")
		end
	else
		self.inst.sg:GoToState("run_stop")
	end
	
	self.islaunched = false
	self.inst.components.stats:ResetFallingSpeed()
	self.inst.components.jumper:ResetDoubleJumps()
	self.inst.components.stats.norecovery = false
	self.inst:RemoveTag("juggled") --1-6-17 FOR AI
	
	--10-21-18 --CHARACTER SPECIFIC ON-LAND FNS THAT RUN ON HITTING THE GROUND. FOR SELF USE ONLY!
	if self.onlandingfn then
		self.onlandingfn() --DO IT
	end
end




function LaunchGravity:LeaveGround()
	self.islaunched = true
	self.inst.components.jumper.jumping = 1
end


function LaunchGravity:AirOnlyLaunch(x, y, z)
	if self:GetIsAirborn() then
		self:Launch(x,y,z)
	end
end


function LaunchGravity:Launch(x, y, z)

	-- self.inst.components.locomotor:RunForward()  --ADDED 10-13 BECAUSE FOR WHATEVER REASON, STANDING STILL FOR 3 SECONDS GLUES YOU TO THE GROUND.
	self.inst.Physics:Stop()
	self.inst.Physics:SetMotorVel(0,0,0)
	self.islaunched = true
	
	local launchx = x
	if self:GetRotationFunction() == "left" then 
		launchx = x
	else 
		launchx = -x
	end
	--launchz = z  --THIS SHOULD REALLY JUST BE 0 AT ALL TIMES
	local launchy = y
	
	
	--REPLACING THE ABOVE FUNCTION 12-15
	if self.islaunched then 
		--WAS THERE A REASON I DISABLED THIS? --OH YEA, IT MAKES IT IMPOSSIBLE TO FULL HOP FOR SOME REASON. FIX THAT. --THEFIXLIST --TODOLIST
	elseif launchy <= 0.5 and launchy >= -0.01 then
		launchy = 0
		self.islaunched = false
	end
	
	--10-20-17 ADDING THE LISTENFORFULLHOP CHECK 
	-- self.inst:RemoveTag("listenforfullhop") --IF PLAYER WAS LISTENING FOR FULLHOP, STOP.
	
	self.inst.Physics:SetVel(launchx, launchy, 0)
	
	if self.inst.components.jumper and self.inst.components.jumper.fastfalling then
		self.inst.components.jumper.fastfalling = false
		self.inst.components.stats:ResetFallingSpeed() --1-18-22 KIND OF AN IMPORTANT THING TO MISS
	end

end

function LaunchGravity:Gravitate(x, y, z)
	local gravx = 0
	if self:GetRotationFunction() == "left" then 
		gravx = x
	else 
		gravx = -x
	end

	self.inst.Physics:SetVel(gravx, y, 0)
end


--1-13 ANOTHER GRAVITY FUNCTION. FOR ADJUSTING EXISTING VELOCITY VALUES WITHOUT OVERRIDING THEM COMPLETELY
function LaunchGravity:Push(x, y, z)
	local myx, myy = self.inst.Physics:GetVelocity()

	if self:GetRotationFunction() == "left" then 
		x = x
	else 
		x = -x
	end

	self.inst.Physics:SetActive(false) --8-23 MAKE SURE THIS DOES NOT CAUSE HITLAG INTERUPTION PROBLEMS!!!
	self.inst.Physics:SetActive(true)

	self.inst.Physics:SetVel(myx + x, myy + y, 0)

end


--1-13 ANOTHER GRAVITY FUNCTION. FOR PUSHING IGNORING FACING DIRECTION
function LaunchGravity:PushAwayFrom(x, y, inst2loc, inst2, xoffset, softpushvalue)
	-- print("LIKE YOU MEAN IT")
	-- local motorx = self.inst.Physics:GetMotorVel()
	local myx, myy = self.inst.Physics:GetVelocity()
	local xpos = self.inst.Transform:GetWorldPosition()
	-- local xpos2 = nil   --2-27-17 WARNING!!! A BUG WITH DELETEONHIT PROJECTILES CAN SOMETIMES CAUSE THE INST2 REF TO BE STALE BY THE TIME THIS RUNS
	local xpos2 = 0	--2-27-17 CRAPPY TEMPORARY WORKAROUND
	if inst2 and inst2:IsValid() then 
		xpos2 = inst2.Transform:GetWorldPosition()  --11-25-17 REUSEABLE - ADDED CHECK FOR ISVALID TO FIX CRASHING FROM BLOCKING PROJ
		
	else --2-6-22 BUT IF THE PROJECTILE LOCATION ISN'T VALID, TAKE THE STORED VERSION
		xpos2 = inst2loc
	end 
	
	local xoffset = xoffset or 0
	local softpushvalue = softpushvalue or 1
	-- print("BLUSTERY DAY", xpos, xpos2, inst2)

	
	-- if xpos >= xpos2 then
	-- if (xpos - ((xoffset) * (softpushvalue or 1))) >= xpos2 then --3-22
	if (xpos - ((xoffset) * (softpushvalue))) >= xpos2 then --3-22  --11-25-17 REUSEABLE - HERE TOO
	-- if (xpos - ((xoffset) * 1)) >= xpos2 then --3-22
	-- if (xpos - ((xoffset) * (self:GetRotationValue()))) >= xpos2 then --3-22 --!!!!!
		x = -x
	end


	self.inst.Physics:SetVel(myx - x, myy + y, 0)

end



--1-27-17 YET ANOTHER PUSH FUNCTION THAT JUST PUSHES. THATS IT. IS NOT AFFECTED BY DIRECTION AT ALL
function LaunchGravity:SimplePush(x, y, z)
	
	local myx, myy = self.inst.Physics:GetVelocity()

	self.inst.Physics:SetActive(false)
	self.inst.Physics:SetActive(true)

	self.inst.Physics:SetVel(myx + x, myy + y, 0)
end



function LaunchGravity:GetIsAirborn(inst)
	return self.islaunched
end



return LaunchGravity
