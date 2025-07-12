


local Jumper = Class(function(self, inst)
	self.inst = inst

	self.jumping = 0
	self.doublejumping = 0
	
	self.currentdoublejumps = self.inst.components.stats.numberofdoublejumps
	
	self.velx = 0
	self.vx = 0
	self.vy = 0
	self.x = 0 --GOD I'M STUPID
	self.y = 0
	
	self.dirmult = 1
	self.facedir = nil
	self.fastfalling = false
	self.di = 0 --NAH, FORGET THIS. DISABLING
	self.contact = 0 --1-5
	
	self.jumpdir = nil --8-11 FOR AI USE ONLY
end)



function Jumper:GetVertSpeed(inst)
	self.vx, self.vy = self.inst.Physics:GetVelocity()
	return self.vy
end

function Jumper:GetHorSpeed(inst)
	self.vx, self.vy = self.inst.Physics:GetVelocity()
	return self.vx
end


--WAIT, ISNT THE SYNTAX FOR THIS WRONG?... HOW DOES THIS WORK??
function Jumper:GetHeight(inst)
	self.x, self.y = self.inst.Transform:GetWorldPosition()
	return y
end


function Jumper:GetFaceDir(inst)
	self.facedir = self.inst.components.launchgravity:GetRotationFunction()
		self.dirmult = 1
		if self.facedir == ("left") then
			self.dirmult = 1	--3-31-19 LOL 2016 ME DIDNT KNOW HOW TO RETURN VALUES FROM FUNCTIONS. HOW CUTE.
		else
			self.dirmult = (-1)
		end
end

--WE PROBABLY DON'T NEED/USE THIS BUT I'M TOO AFRAID TO GET RID OF IT
function Jumper:HitGround(inst)
	self.vx, self.vy = inst.Physics:GetVelocity()
	return self.vy
end



function Jumper:ResetDoubleJumps() --1-5 THIS WILL PROBABLY REPLACE MY CURRENT JUMPING SYSTEM IN JUMPER.LUA
	self.currentdoublejumps = self.inst.components.stats.numberofdoublejumps 
end


function Jumper:Jump(inst)
	self.inst.components.stats.fallingspeed = self.inst.components.stats.basefallingspeed
	self.fastfalling = false
	self:GetFaceDir() 
	local xlaunch = self:GetHorSpeed() * self.dirmult --12-16-18 dst change reuseable --MAKING THIS MORE LIKE DOUBLE JUMP
	
	--11-10-20 SNEAKY CHECK TO SEE IF WE BUFFERED AN UPSMASH AT THE LAST POSSIBLE SECOND.  IF SO; CANCEL THE JUMP
	if inst.components.stats and inst.components.stats.event == "cstick_up" and inst.components.stats.tapjump then
		inst:RemoveTag("listenforfullhop")
		-- print("CANCELING JUMP TO UP-SMASH INSTEAD")
		return end
	
	--12-16-18 -ADDING THE FORWARD/BACKWARD MOMENTUM BOOST TO SINGLEJUMPING TOO
	if self.inst.components.keydetector then
		if self.inst.components.keydetector:GetForward(inst) then  --DST- DONT FORGET TO ADD INST TO ALL USES OF KEYDETECTOR
			xlaunch = (self.inst.components.stats.air_speed)
		elseif self.inst.components.keydetector:GetBackward(inst) then
			xlaunch = -(self.inst.components.stats.air_speed)
		end
	else
		if self.jumpdir == "forward" then	--FOR AI USE ONLY
			xlaunch = (self.inst.components.stats.air_speed)
		elseif self.jumpdir == "backward" then
			xlaunch = -(self.inst.components.stats.air_speed)
		else	
			xlaunch = self:GetHorSpeed() * self.dirmult
		end
	end
	
	
	
	
	if self.jumping == 0 and self.doublejumping == 0 then
		self.inst.components.locomotor:Stop() 
		
		self.inst.components.launchgravity:Launch(xlaunch, self.inst.components.stats.shorthopheight, 0)
		
	end
end

--1-5 NEW FUNCTION SPECIFICALLY FOR DOUBLEJUMPING --SHOULD PROBABLY GET RID OF THE OLD ONE IN THE SINGLE JUMP --TODOLIST
function Jumper:DoubleJump(inst)

	self.inst.components.stats.fallingspeed = self.inst.components.stats.basefallingspeed
	self.fastfalling = false
	
	self.inst:RemoveTag("listenforfullhop") --10-20-17 LISTENFORFULLHOP CHECK -REUSEABLE
	
	local xlaunch = 0
	
	if self.inst.components.keydetector then
		if self.inst.components.keydetector:GetForward(inst) then  --DST- DONT FORGET TO ADD INST TO ALL USES OF KEYDETECTOR
			xlaunch = (self.inst.components.stats.air_speed)
		elseif self.inst.components.keydetector:GetBackward(inst) then
			xlaunch = -(self.inst.components.stats.air_speed)
		end
	else
		if self.jumpdir == "forward" then
			xlaunch = (self.inst.components.stats.air_speed)
		elseif self.jumpdir == "backward" then
			xlaunch = -(self.inst.components.stats.air_speed)
		else	
			xlaunch = self:GetHorSpeed()
		end
	end

	self.inst.components.locomotor:StopMoving()
	self.doublejumping = 1 --DID I NOT KNOW WHAT A BOOLEAN WAS OR SOMETHING?
	self.inst.components.launchgravity:Launch(xlaunch, self.inst.components.stats.doublejumpheight, 0)
	self.currentdoublejumps = self.currentdoublejumps - 1
end

--11-10-20 SINCE THIS IS ALWAYS CALLED BY A 2 FRAME DOTASKINTIME, THIS CAN CAUSE ISSUES BECAUSE THE TAG DOESNT REMOVE ITSELF ON EXITING A STATE.
--BUT RIGHT NOW, THE PROBLEMS ARE VERY MINOR AND RARE, SO I MAY JUST LEAVE IT FOR NOW
function Jumper:CheckForFullHop(inst)
	if self.jumping == 0 and self.doublejumping == 0 then
		local holdup = false
		if self.inst.components.keydetector then
			holdup = self.inst.components.keydetector:GetJump(self.inst) 
		end
		self.velx = self:GetHorSpeed()
		if (holdup or self.inst.components.stats.jumpspec == "full") and self.inst:HasTag("listenforfullhop") then
			self:GetFaceDir()
			self.inst.components.launchgravity:Launch(self.velx*self.dirmult, self.inst.components.stats.jumpheight, 0)
			self.inst:RemoveTag("listenforfullhop")
		end
	end
	
	if self.inst.components.launchgravity:GetIsAirborn() then --11-10-20 ADDED THIS CHECK
		self.jumping = 1
	end
end

--FAST FALLING
function Jumper:FastFall()
	if not self.fastfalling and not self.inst.sg:HasStateTag("noairmoving") and self:GetVertSpeed() <= 0 then
		self.velx = self:GetHorSpeed()
		self.vely = -(self.inst.components.stats.fallingspeed * (1 + self.inst.components.stats.fastfallingspeedincrease) ) * 10
		
		self.inst.components.stats.fallingspeed = -self.vely --BOTH NEGATIVE
		--10-31-16 OKAY WHAT IS GOING ON. WHY DOES THIS SOMETIMES HAPPEN MULTIPLE TIMES AND CREATE A SUPER FASTFALL
		self.inst.components.launchgravity:Launch((self.velx * self.dirmult), (self.vely+0), 0) --MAKE AN OVERWRITE VELOCITY
		self.fastfalling = true
		-- print("FAAST FALLING", self.vely, self.inst.components.stats.basefallingspeed)
	end
end



--8-30 UN-FASTFALLING
function Jumper:UnFastFall()
if self.fastfalling and self:GetVertSpeed() <= 0 then
	self.velx = self:GetHorSpeed()
	self.inst.components.stats:ResetFallingSpeed()
	self.vely = -(self.inst.components.stats.fallingspeed * (1 + 0) ) * 10
	self.inst.components.launchgravity:Launch((self.velx * self.dirmult), (-self.inst.components.stats.basefallingspeed*10), 0)
	self.fastfalling = false
end
end


function Jumper:ScootForward(sforce)
	self.inst.Physics:SetActive(false) --8-23 WOW!! WHAT A STRANGE FIX FOR A STRANGE BUG
	self.inst.Physics:SetActive(true)
	
	--7-14-19 I THINK WE NEED THESE TO UPDATE THE GRAVITATE FUNCTION BEFORE USING IT, BECAUSE OTHERWISE THE DIRECTION IS STALE
	self.inst.components.launchgravity:GetRotationFunction(self.inst)
	self.inst.components.launchgravity:Gravitate(sforce, 0, 0)
end

function Jumper:AirStall(power, ypower)
	local power = power or 5
	local ypower = ypower or power
	self.velx = self:GetHorSpeed() / power 
	self.vely = self:GetVertSpeed() / ypower --3-15 ADDING ADJUSTABLE POWERS
	self.inst:RemoveTag("listenforfullhop") --10-20-17
	self.inst.components.launchgravity:Launch((self.velx * self.dirmult), (self.vely+0), 0)
end


--7-25-17 
function Jumper:AirDrag(mspeed, mfall, maccel, duration)
	
	self.inst.components.stats.air_accel = self.inst.components.stats.baseairaccel * mspeed
	self.inst.components.stats.fallingspeed = self.inst.components.stats.basefallingspeed * mfall
	
	self.inst:RemoveTag("listenforfullhop") --10-20-17 
	
	self.inst.airdragtask = self.inst:DoTaskInTime(duration*FRAMES, function(inst)
		self:EndAirDrag()
	end)
end

--7-25-17  --IF AN AIRDRAG TASK TIMER EXISTS, RESET STATS BACK TO NORMAL AND END THE TIMER
function Jumper:EndAirDrag()
	if self.inst.airdragtask then
		self.inst.components.stats.air_accel = self.inst.components.stats.baseairaccel
		self.inst.components.stats.fallingspeed = self.inst.components.stats.basefallingspeed
	
		self.inst.airdragtask:Cancel()
	end
end

--7-26-17  AN END-ALL FN TO END ALL END-OF-STATE MOTOR OR MOVEMENT ORIENTED TASKS
function Jumper:EndAllStateTasks()
	
	if self.inst.motortask then
		self.inst.motortask:Cancel()
	end
	
	if self.inst.slowfalltask then
		self.inst.components.stats:ResetFallingSpeed()
		self.inst.slowfalltask:Cancel()
	end
	
	if self.inst.airdragtask then
		self:EndAirDrag()
	end
end


--1-7 LEDGE GATE DETECTORS, AN INVISIBLE BARRIER TO KEEP PLAYERS FROM FALLING OFF A LEDGE DURING ROLLS AND OTHER SPECIFIED STATES
function Jumper:CheckLedgeGates()
	if (self.inst.components.launchgravity:GetIsAirborn() or self.inst.sg:HasStateTag("ignore_ledge_barriers")) then --and wax ~= "off" then
		self.inst.Physics:ClearCollisionMask()
		self.inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	elseif not self.inst.components.launchgravity:GetIsAirborn() then
		self.inst.Physics:CollidesWith(COLLISION.LIMITS)
	end
end

--9-1 FIXES THE PROBLEM WHERE LEDGE GATES PREVENT X KNOCKBACK
function Jumper:ForceRemoveLedgeGates()
	self.inst.Physics:SetActive(true) 
	self.inst.Physics:ClearCollisionMask()
	self.inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	self.inst.Physics:SetActive(false)
end


--1-5 PHYSICS CALLBACKS. REALLY THIS SHOULD HAVE BEEN THE VERY FIRST THING I DID, BUT I DID NOT KNOW ENOUGH ABOUT IT UNTIL NOW --OH MY GOD THIS IS SO EASY
local function OnCollide(inst, object)
	if object:HasTag("floor") then
		inst.components.jumper.contact = 1
		inst.components.jumper:PostTickGroundTest()
	end
	
end




--2-7-17 AN ATTEMPT TO DECREASE THE TIME IT TAKES FOR THE GROUND TO REGISTER AND LAND. THIS FUNCT RUNS EVERY POST-UPDATE FROM THE MODMAIN
function Jumper:PostTickGroundTest() --CAREFUL, THIS FUNCT WILL RUN OFTEN. MAKE IT AS SIMPLE AS POSSIBLE TO AVOID ADDING LAG
	
	local yspeed = self.inst.components.launchgravity:GetVertSpeed()
	local is_airborn = self.inst.components.launchgravity:GetIsAirborn()
	local yhight = self.inst.components.launchgravity:GetHeight()
	
	if self.contact == 1 and yspeed <= 0.2 and is_airborn and yhight >= -0.3 and not self.inst:HasTag("hitfrozen") then
		
		--ALRIGHT. WHATEVER. IF THE PLAYER HAS SPAWNED A HITBOX ON THIS FRAME, WAIT. IF NOT, GO FOR IT.
		if self.inst:HasTag("notclearforlanding") then
			self.inst:RemoveTag("notclearforlanding") --I'LL ALSO ADD THIS TO THE CHECKER DOWN THERE SO IT CAN AT LEAST GET REMOVED EVERY FRAME. RIGHT?
			return end --CANCEL EVERYTHING!
		
		--ANOTHER TEST TO SEE IF THEY ARE CURRENTLY HITTING OPPONENTS
		for k,v in pairs (self.inst.components.hitbox.hitboxtable) do
			for l, b in pairs(v.components.hitboxes.pyschecktable) do
				if l == 1 then 
					-- print("OPPONENT DETECTED IN NOOBTABLE")
					return end --CANCEL EVERYTHING!
			end
		end
		
		self.inst.components.launchgravity:HitGround()
		self.jumping = 0
		self.doublejumping = 0
	end
	
	if self.contact == 0 and not is_airborn and not self.inst:HasTag("hitpaused") and not (yhight <= 0.01 and yhight >= -0.01) then --1-9 OKAY ITS BASICALLY JUST FLOORCHECKER 2.0 AT THIS POINT
		self.inst:PushEvent("air_transition")
	end
end


--2-22-17 GROUNDCHECKER MUST ALSO RUN EVERY TICK WHILE NOT TOUCHING GROUND, OR ELSE IT WONT KNOW WHEN TO LEAVE GROUND
function Jumper:OnUpdate(dt) --11-4-17 THIS FUNCT OFTEN RUNS BEFORE THE MASTERHITBOX UPDATER, SOMETIMES INTERRUPTING THE HITBOXES FROM HITTING BEFORE LANDING
	--6-8-17  LETS CHANGE THIS TOO. IF THIS WORKS, I THINK THIS MIGHT BE ALL WE NEED TO CHANGE
	if TheWorld.ismastersim then
		self:PostTickGroundTest()
		self.contact = 0
		self.inst:RemoveTag("notclearforlanding")
	end
	
	--5-13-18 OKAY I GUESS WE'LL CONTINUE THIS
	self:DoGravity()
	
	--3-31-19 AWW WHAT THE HEY. WHY NOT. WHATEVER IT TAKES TO GET THIS STUPID THING OUT OF A 0 TICK DOTASKINTIME LOOP EVEN THOUGH IT DOESNT REALLY BELONG HERE
	self.inst:PushEvent("update_stategraph") --ARE EVENTS RESOURCE INTENSIVE? IS THERE A BETTER WAY TO CALL THIS?
end





function Jumper:ApplyGroundChecker(inst)
	self.inst.Physics:SetCollisionCallback(OnCollide)
	self.inst:StartUpdatingComponent(self) --2-22-17   --5-13-18 WAIT-... WHAT??.. THIS WAS ALREADY HERE?... OKAY UH... I GUESS I DID THIS ALREADY??
	----5-13-18 I STILL FEEL LIKE THIS SHOULD REALLY BE CALLED FROM INITIALIZATION BUT OH WELL. MAYBE THIS WORKS OUT BETTER
end


--5-13-18 OH, I GUESS AN ONUPDATE() ALREADY EXISTED SO NOW WE'RE CALLING THIS FROM ELSEWHERE. LETS JUST CALL IT DOGRAVITY
function Jumper:DoGravity()
		
	if not self.inst:HasTag("hitpaused") then
		self:CheckLedgeGates() --1-7
		
		local is_airborn = self.inst.components.launchgravity:GetIsAirborn() --10-19 ADDED
		
		--OH RIGHT THIS STILL NEEDS TO HAPPEN EVERY FRAME OR ELSE IT BECOMES AN ICE RINK
		if not self.inst:HasTag("motoring") then --4-20			--lol
			self.inst.Physics:SetMotorVel(0,0,0)
		end
		
		
		
		--3-31-19 -------------------
		if is_airborn == false then
			return end --3-31-19 IF WE ARE NOT AIRBORN. JUST  STOP. THIS WHOLE TIME, EVERYTHING UNDER THIS IS COMPLETELY UNNESSESSARY FOR GROUNDED PLAYERS
		
		
		
		local yhight = self.inst.components.launchgravity:GetHeight()
		local yspeed = self.inst.components.launchgravity:GetVertSpeed()
		local xspeed = self.inst.components.launchgravity:GetHorSpeed()
		
		local gravity = self.inst.components.stats.gravity --10-20-18 LETS JUST GET THIS EARLY
		-- print("FAAST FALLING", yspeed, self.inst.components.stats.fallingspeed)
		
		
		------AIRIAL MOMENTUM------
		
		-- print("VELX 2", self.velx)   --0
		-- print("GETHORSPEED 2", self:GetHorSpeed())
		
		
		self.vy = self:GetVertSpeed()
		self.velx = self:GetHorSpeed()  --IT RESETS TO ZERO HERE ON JUMPING STILL
		
	
		
		if self.inst.components.keydetector then
			self.holdleft = self.inst.components.keydetector:GetLeft(self.inst) or self.inst:HasTag("holdleft") --THE HOLDRIGHT TAG IS FOR BOTS
			self.holdright = self.inst.components.keydetector:GetRight(self.inst) or self.inst:HasTag("holdright") --THE HOLDRIGHT TAG IS FOR BOTS
		else
			self.holdleft = self.inst:HasTag("holdleft")
			self.holdright = self.inst:HasTag("holdright")
		end
		
		local unitmult = 10 --HAS NOT BEEN APPLIED TO EVERYWHERE YET
		
		self:GetFaceDir() --3-31-19 YA DOOFIS THIS IS FASTER
		
		
		--2-22-17 ADDING TEST TO MAKE SURE AIR-DRAG OCCURS WHEN IN HITSTUN EVEN WHILE HOLDING KEYS
		local inhitstun = self.inst.sg:HasStateTag("reeling")   --("noairmoving") --THIS COULD CAUSE PROBLEMS LATER WITH NON-HITSTUN NOAIRMOVING TAGS  --3-31-19 UM!! YEA!! NO WAY. CHANGING THIS TAG
		
		
		
		--11-16, MAX AIRSPEED
		local air_speed = self.inst.components.stats.air_speed --10-15-18 --ITS ABOUT TIME 
		
		if self.vy <= -(self.inst.components.stats.fallingspeed * 10) and not (self.inst.sg:HasStateTag("tumbling") and self.inst.sg:HasStateTag("busy")) then 
			self.vy = -(self.inst.components.stats.fallingspeed * unitmult)  
		end
		
		
		
		
		--11-16 CHANGE SO THAT MAX AIR SPEED ISNT APPLIED WHEN IN KB
		if not self.inst.sg:HasStateTag("noairmoving") then   --3-31-19 ACTUALLY... THIS ONE CAN STAY AS A CHECK FOR NOAIRMOVING. SPECIAL MOVES WITH HIGH MOBILITY MIGHT USE THIS A LOT
			if self.velx >= air_speed then 
				self.velx = air_speed --3-17 WHY DIDNT I JUST SET IT TO AIR SPEED BEFORE. IM DUMB
			elseif self.velx <= -air_speed then 
				self.velx = -air_speed
			end
		end
		
		
		--3-17 TRYING SOMETHING ELSE, AI ACCEL FEELS TOO SLOW
		--local air_accel = 0.07 * 5 * 2 --THE HECK OUTTA HERE, GEEZ
		local air_accel = self.inst.components.stats.air_accel --9-20-21 GOOD LORD THAT SHOULD HAVE BEEN DONE YEARS AGO
		
		--12-31 NEW DI SYSTEM
		if self.inst.sg:HasStateTag("noairmoving") then
			air_accel = 0
		elseif self.inst.sg:HasStateTag("di_movement_only") then  --2-22-17 SO AS OF RIGHT NOW, THIS TAG IS NEVER USED BY ITSELF (ITS ALWAYS WITH NOAIRMOVING IN TUMBLE)
			air_accel = air_accel / 15 -- 15
		elseif self.inst.sg:HasStateTag("reducedairacceleration") then
			air_accel = air_accel / 5 --5
		end
		
		
		
		--10-20-18 -BS. IT HAS TO BE, I JUST KNOW IT. KNOCKBACK IS NOT AFFECTED BT GRAVITY, GRAVITY IS AFFECTED BY KNOCKBACK
		if inhitstun then --self.inst.sg:HasStateTag("reeling") then  --WHILE IN TUMBLING HITSTUN, GRAVITY IS UNIVERSAL WITH THE DEFAULT UNTIL HITSTUN ENDS
			gravity = 0.87 --THE DEFAULT (MARIO'S) GRAVITY. 
		end
		
		
		
		
		
		--BASIC GRAVITY & AIR DRIFT	
		if self.holdleft and not inhitstun then
			self.velx = (self.velx +(0 + self.di + air_accel))  --10-12, CHANGING "2" TO A VARIALE THAT SCALES WITH KNOCKBACK
			-- self.inst.components.launchgravity:Launch((self.velx + self.running_start * self.dirmult), self.vy, 0)  -- -5
			--self.inst.components.launchgravity:Gravitate((self.velx * self.dirmult), (self.vy), 0)  -- -5
			-- self.inst.components.launchgravity:Gravitate((self.velx * self.dirmult), (self.vy + 1 - self.inst.components.stats.gravity), 0) --12-4
			-- self.inst.components.launchgravity:Gravitate((self.velx * self.dirmult), (self.vy + 1 - gravity), 0) --10-20-18 -SAME FORMULA, JUST CONDENSED
			
		elseif self.holdright and not inhitstun then
			self.velx = (self.velx -(0 + self.di + air_accel))
			-- self.inst.components.launchgravity:Gravitate((self.velx * self.dirmult), (self.vy + 1 - gravity), 0)
		else
			--self.inst.components.launchgravity:Gravitate((self.velx * self.dirmult), (self.vy + (1 - (1 * (1/self.inst.components.stats.gravity)))), 0)    --WITH "HORROR SPEED METHOD", KB WORKS, BUT NOT JP  --12-4 ADDING GRAVITY MULTIPLIER
			--self.inst.components.launchgravity:Gravitate((self.velx * self.dirmult), (self.vy), 0)    --WITH "HORROR SPEED METHOD", KB WORKS, BUT NOT JP  --12-4 ADDING GRAVITY MULTIPLIER
			-- self.inst.components.launchgravity:Gravitate((self.velx * self.dirmult), (self.vy + 1 - self.inst.components.stats.gravity), 0)   --12-4 ADDING GRAVITY MULTIPLIER
			-- self.velx = ((self.velx) -     math.min( (self.inst.components.stats.air_friction * 5 * 1), 0)       * self.dirmult ) --3-18
			-- self.velx = ((self.velx) -     ( (self.inst.components.stats.air_friction * 5 * 2))       * self.dirmult ) --3-18 --WORKS GREAT BUT PULLS YOU BACKWARDS
			-- self.velx = ((self.velx) *     (1 -  (0.2*1* 2))       * self.dirmult ) --3-18
			self.velx = ((self.velx) *     (1 - (self.inst.components.stats.air_friction * 1 * 2))) --3-21 WORKS GREAT ENOUGH BUT IDK WHAT IM DOING
			-- self.inst.components.launchgravity:Gravitate(((self.velx) * self.dirmult), (self.vy + 1 - gravity), 0)
		end
		
		--2-8-22 WOW, MY OLD VERSION IS HILARIOUS...
		self.inst.components.launchgravity:Gravitate((self.velx * self.dirmult), (self.vy + 1 - gravity), 0)
		
		
		--SECOND GROUND TEST  --9-29
		if yspeed < 0 and yhight <= 0.3 then
			self.velx = 0     --BUT NOW X LAUNCH VEL DOESNT WORK WITH THIS ENABLED  --OH I GUESS IT DIDNT WORK WITH IT OFF EITHER. NVM
		end
		
	end
end




return Jumper
