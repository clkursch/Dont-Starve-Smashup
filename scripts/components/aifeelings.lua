local AiFeelings = Class(function(self, inst) --7-6
    self.inst = inst

	--------------------------------
	self.fear = 0
	self.confidence = 0 --1-15-17 NEW VERSION
	self.baseconfidence = 0
	
	self.ailevel = 1
	
	self.tempfear = 0 --1-19-17
	
	self.escapemode = false
	
	self.shieldchecked = false
	self.punishblockedmove = false
	
	self.oppdir = "left" --8-11
	-- self.jumpdir = "left" --8-11
	
	
	--8-23
	self.dashattackmod = 0
	self.fspecialmod = 0
	self.grabmod = 0
	self.baitsmashmod = 0
	self.jumpinmod = 0
	self.rawfsmashmod = 0
	self.dashingusmashmod = 0
	self.blockapproachmod = 0
	self.highapproachmod = 0 --1-17-22
	
	self.ftechmod = 0
	
	self.lastseenmove = nil
	
	--tumblereactiontime = 0 --1-25-17
	self.techchance = 0.3
	self.readytech = 0.3
	
	-- 8-27
	self.oppshieldtendancy = 0
	
	self.anchor = TheSim:FindFirstEntityWithTag("anchor") --DST
end)


function AiFeelings:ReactToHit()
	self.fear = self.fear + 1
    self.currentfuel = 7.5
end

function AiFeelings:Tick() --HONESTLY DO I EVEN NEED THIS? I THINK I'LL USE A DIFFERENT METHOD
	if self.fear > 0 then
		self.fear = self.fear - 0.30 --BRAINSPEED
	else
		self.fear = 0
		self.escapemode = false
		-- self.inst:RemoveTag("braceyourself")
	end
end

function AiFeelings:AddFear(ammount) --UNUSED
	self.fear = self.fear + ammount
end



--1-15-17 COMPLETELY NEW VERSION OF THE FEAR/CONFIDENCE SYSTEM
function AiFeelings:ConfidenceBoost(ammount)
	self.confidence = self.confidence + ammount
	math.clamp(self.confidence, -35, 35)
	-- print("IM FEELING LUCKY", self.confidence, self:ConfidencePercent())
end

function AiFeelings:ConfidencePercent() --RETURNS A NUMBER BETWEEN 0-1 BASED ON CONFIDENCE (FOR RANDOMIZERS)
	
	if self.inst.components.percent.currentpercent >= 85 then --1-17-17  IF LOW HEALTH, LOWER CONFIDENCE
		local cowardconf = self.confidence - 15 --NOTE, LOWERED HEALTH ONLY APPLIES TO THE CONFIDENCEPERCENT FUNTION, NOT THE VARIABLE ITSELF
		math.clamp(cowardconf, -35, 35)
		return ((cowardconf + 35)/70)
		
		
	else --ELSE, JUST RETURN REGULAR CONFIDENCE
		return ((self.confidence + 35)/70)
	end

	
end


--1-25-17 I GUESS I'M JUST THROWING THESE AROUND ANYWHERE, HUH?
function AiFeelings:FtechPercent() 
	math.clamp(self.ftechmod, -35, 35)
	return ((self.ftechmod + 35)/70)
end


--4-5
function AiFeelings:SetKeyBuffer(event, key)
	self.event = event
	self.key = key
	self.buffertick = 5
end


--8-23
function AiFeelings:EncourageUse(move, ammount)
	local ammount = ammount
	local move = move 
	
	move = move + ammount
	
	if move <= -20 then
		move = -20
	end
	
	return move
end


--11-14-20 OK, THESE SPIDERS HAVE SOME PRETTY FRUSTRATINGLY ACCURATE AIM-BOT. WE NEED TO TONE THINGS DOWN SO THEY CAN'T REACT INSTANTLY TO SUDDEN CHANGES IN AIR VELOCITY
function AiFeelings:AirialLockOnTimer(opponent, ailevel)
	
	--HMM... OR AM I JUST BAD??
	local xvel, yvel = opponent.Physics:GetVelocity()
	--COMPARES THE LAST STORED ENEMY VELOCITY VALUE TO THE CURRENT ONE
	local xdiff = self.oppvelx - xvel
	local ydiff = self.oppvely - yvel
	
	local greatestchange = math.max(xdiff, ydiff)
	
	if greatestchange > self.lastvelchange then
		self.lastvelchange = greatestchange
	else
		self.lastvelchange = self.lastvelchange - 1
	end
	
	
	
	return move
end




--7-20 CALCULATE ENEMY POSITION    --!! I COPIED THIS FROM CHASEANDFIGHT SO AT SOME POINT REPLACE THE FUNCTIONS IN THERE WITH THIS ONE !! TODOLIST
function AiFeelings:CalculateTrajectory(frames, xoffset, yoffset, range, yrange, standstill, oppoverride) --1-17-17 ADDED A STANDSTILL VARIABLE TO CALCULATE AS IF HAROLD WAS NOT MOVING
    local opponent = self.inst.components.stats.opponent --or GetPlayer()
	
	if oppoverride then
		opponent = oppoverride
	end
	
	if not opponent or not opponent:IsValid() then --DST CHANGE - NO CHECKING FOR GETPLAYER
		return false
	else
	
	if yrange and not (yrange and yrange == 0) then
		yrange = yrange
	else
		yrange = range
	end
	
	local myposx, myposy = self.inst.Transform:GetWorldPosition()
	local oppx, oppy = opponent.Transform:GetWorldPosition() --or GetPlayer().Transform:GetWorldPosition()
	local oppvelx, oppvely = opponent.Physics:GetVelocity()
	local myvelx, myvely = self.inst.Physics:GetVelocity()
	
	
	--1-16-17   ---ADDING TO ACCOUNT FOR PLAYER HEIGHTS---
	oppy = oppy + (opponent.components.stats.height / 2)
	yrange = yrange + (opponent.components.stats.height / 2)
	--NOTE, I ALSO MADE THAT CHANGE TO LINE 165 TO ACCOUNT FOR THE RAISED OPPY POSITION
	
	--SPECIFICALLY FOR ANYTHING THAT ISNT AN AIREAL OR DASH ATTACK, WHERE HE WILL STOP MOVING THE MOMENT THE ATTACK BEGINS
	if standstill and standstill == "still" then
		myvelx = 0
		myvely = 0
	end
	
	
	-- print("WHAT DO YOU MEAN NIL VALUE", yrange)	
	
	-- print("CALCULATE X TRAJECTORY", distsq(myposx, 0, oppx, 0), (((oppvelx + myvelx) * 0.35 * frames) + 0))	
	-- print("CALCULATE Y TRAJECTORY", distsq(0, myposy, 0, oppy), (((oppvely + myvely) * 0.35 * frames) + 0))	
	
	
	-- if distsq(myposx, 0, oppx, 0) <= 3 then
	-- if distsq((myposx + (1 * self.inst.components.launchgravity:GetRotationValue())), 0, oppx, 0) <= oppvelx then
	-- if distsq(myposx, 0, oppx, 0) <= ((oppvelx + myvelx) * 0.35 * frames) and distsq(0, myposy, 0, oppy) <= ((oppvely + myvely) * 0.35 * frames) then
	-- if distsq(myposx, 0, oppx, 0) <= (((oppvelx + myvelx) * 0.35 * frames) + range) and distsq(0, myposy, 0, oppy) <= (((oppvely + myvely) * 0.35 * frames) + 0) then
		-- self.inst:AddTag("wantstojab")
		
		--TRY SQUARING FRAMES?????? --8-19
	-- local xdetection = ((oppvelx + myvelx) * 0.35 * -frames) --* self.inst.components.launchgravity:GetRotationValue())) --8-20 THIS IS WHAT IT WAS AT BEFORE THE NEW CHANGES
	local xdetection = ((oppvelx + myvelx) * 0.35 * -(1/(frames*frames))) --8-20
	-- local xdetection = ((myvelx + oppvelx) * 0.35 * -frames)
	-- local xdetection = ((myvelx + oppvelx) * 0.35 * -frames) --#4
	-- local xdetection = (distsq(oppvelx, 0, myvelx, 0) * 0.35 * frames)  --#3   
	-- local xdetection = (self.inst:distnorm(oppvelx, 0, myvelx, 0) * 0.35 * frames)
	-- local ydetection = ((oppvely + myvely) * 0.35 * -frames)
	-- local ydetection = ((oppvely - myvely) * 0.35 * -frames) --8-17 FROM HERE AND DOWNWARD   --8-20 THIS IS WHAT IT WAS AT BEFORE THE NEW CHANGES
	-- local ydetection = (math.abs(oppvely - myvely) * 0.35 * -frames)
	-- local ydetection = ((oppvely - myvely) * 0.35 * -(1/(frames*frames))) --8-20 --FIXD IT AGAIN
	-- local ydetection = (math.abs(oppvely - myvely) * 0.35 * -(1/(frames*frames))) --8-23 OKAY OKAY, FIXED IT AGAIN -- NO WAIT
	-- local ydetection = ((myvely - oppvely) * 0.35 * -(1/(frames*frames)))
	local ydetection = 0 --INITIALIZIATION FOR THE BELOW FUNCTION--8-23
	
	if myposy > (oppy - (opponent.components.stats.height / 2)) then --8-23 OKAY THIS MIGHT HAVE FIXED IT??? IT CONFIRMED WORKS FOR BOTH SIDES OF AIRvGROUND ATTACKS, BUT UNSURE ABOUT AIRvAIR
		ydetection = ((oppvely - myvely) * 0.35 * -(1/(frames*frames))) 
	else
		ydetection = ((myvely - oppvely) * 0.35 * -(1/(frames*frames)))
	end
	
	
	-- local xdistance = (distsq(myposx, 0, oppx, 0))
	-- local xdistance = (self.inst:distnorm(myposx, 0, oppx, 0))
	-- local xdistance = -(myposx - oppx)  --HUH... I GUESS IT WORKS. 7-23   #3
	-- local xdistance = (myposx - oppx) --#4
	
	local xdistance = -((myposx + (xoffset* self.inst.components.launchgravity:GetRotationValue())) - oppx)
	-- local ydistance = -((myposy + yoffset) - oppy)
	local ydistance = -(math.abs((myposy + yoffset) - oppy)) --8-17 --THIS FIXED IT. Y VALUES ARE MUCH BETTER NOW
	
	
	-- print("CALCULATE X RANGE", xdetection, xdistance) --(xdetection + range), (xdetection - range)) --distsq(myposx, 0, oppx, 0), (((oppvelx + myvelx) * 0.35 * frames) + range))	
	-- print("CALCULATE Y RANGE", (ydetection + range), (ydetection - range))
	
	------------------- FOR VISUAL REPRESENTATION ONLY. DISABLE WHEN NOT IN USE
				-- self.inst.components.hitbox:SetDamage(1)
				-- self.inst.components.hitbox:SetAngle(361)
				-- self.inst.components.hitbox:SetBaseKnockback(1)
				-- self.inst.components.hitbox:SetGrowth(95)
				-- self.inst.components.hitbox:SetSize(0.15)
				-- self.inst.components.hitbox:SetLingerFrames(0) --2
				-- self.inst.components.hitbox.property = 5 ----**PROBABLY ALL THIS ^^^
				
				-- self.inst.components.hitbox:SpawnHitbox(((xdetection + range)/4), 3, 0) --**   --UNCOMMENT THE ** LINES FOR VISUAL TESTING
				-- self.inst.components.hitbox:SpawnHitbox(((xdetection - range)/4), 3, 0) --**
				-- self.inst.components.hitbox.property = 5 --**
				-- self.inst.components.hitbox:SpawnHitbox(-1, ((ydetection + yrange)/4), 0) --Y VERSION --**
				-- self.inst.components.hitbox:SpawnHitbox(-1, ((ydetection - yrange)/4), 0) --**
				
				
				-- self.inst.components.hitbox:SetSize(0.20) --**
				-- self.inst.components.hitbox.property = 5 --**
				-- -- self.inst.components.hitbox:SpawnHitbox((distsq(myposx, 0, oppx, 0) / 4), 4, 0)
				-- self.inst.components.hitbox:SpawnHitbox((xdistance / 4), 4, 0) --X --**
				-- self.inst.components.hitbox:SpawnHitbox(-1, (ydistance / 4), 0) --Y --**
				-- self.inst.components.hitbox:SpawnHitbox((xdistance / 4), (ydistance / 4), 0) --BOTH --**
	----------------------------------------------------
	
	
	-- if (xdistance <= (xdetection + range) and xdistance >= (xdetection - range)) then --and (distsq(0, myposy, 0, oppy) <= (ydetection + range) and distsq(0, myposy, 0, oppy) >= (ydetection - range)) then
	-- if (xdistance <= (xdetection + range) and xdistance >= (xdetection - range)) and (ydistance <= (ydetection + range) and ydistance >= (ydetection - range)) then
	if (xdistance <= (xdetection + range) and xdistance >= (xdetection - range)) and (ydistance <= (ydetection + yrange) and ydistance >= (ydetection - yrange)) then --8-25 NEW VERSION TO ACCOUNT FOR Y RANGE
	-- if (distsq(myposx, 0, oppx, 0) - range <= (xdetection + 0) and distsq(myposx, 0, oppx, 0) + range >= (xdetection - 0)) then --and (distsq(0, myposy, 0, oppy) <= (ydetection + range) and distsq(0, myposy, 0, oppy) >= (ydetection - range)) then
	
		return true --"grab_range"
	else
		return false
	end
	
	end
end





--10-3-20 ITS BEEN A WHILE SINCE I WAS HERE. 
--NEW FN FOR FINDING ALTERNATE OPPONENTS SO THEY DONT BLINDLY CHASE THE SAME GUY FOREVER
function AiFeelings:CheckForAlternateOpponent()

	local opponent = self.inst.components.stats.opponent --or GetPlayer()
	if not (opponent and opponent:IsValid() and opponent.components.stats.alive == true) then
		return true end --DON'T RUN THE REST
		
	local enemydist = self:DistFromEnemy() --DISTANCE FROM OUR "CURRENT" ENEMY
	local newenemy = false
	
	for k,v in pairs(self.anchor.components.gamerules.livingplayers) do
		if v ~= opponent and not self.anchor.components.gamerules:IsOnSameSide(self.inst, v) then
			if self:DistFromEnemy("both", v) < enemydist then
				self.inst.components.stats.opponent = v
				newenemy = true
				-- combat:SetTarget(nil)--PRETTY SURE THIS IS USELESS
			end
		end
		
	end
	return newenemy --IN CASE WE WANT TO END ANY RUNNING BEHAVIORS ON FINDING A NEW OPPONENT
end


--10-3-20 THIS SHOULD HAVE BEEN HERE YEARS AGO INSTEAD OF COPYING IT ALL OVER THEIR BEHAVIORS
function AiFeelings:DistFromEnemy(dir, altenemy) --OPTION TO SPECIFY AN ENEMY OTHER THAN THE ONE SET IN OUR STATS
	local opponent = altenemy or self.inst.components.stats.opponent
	local myposx, myposy = self.inst.Transform:GetWorldPosition() --IF I EVER FIX THE VERTACLE DISTANCE DETECTION, ILL HAVE TO FIX THE OTHERS TOO --TODOLIST
	local oppx, oppy = opponent.Transform:GetWorldPosition()
	
	--1-1-22 HAPPY NEW YEAR. AND UM, IF WE HAVE NO ENEMY, RETURN 0 AND DON'T RUN THE REST
	if not (opponent and opponent:IsValid()) then
		print("NO OPPONENT FOUND. RETURNING 0 DISTANCE")
		return 0
		end
	
	if dir and dir == "horizontal" then --LENGTHWISE
		self.distfromenemy = distsq(myposx, 0, oppx, 0) 
		return distsq(myposx, 0, oppx, 0)
	elseif dir and dir == "vertical" then --HIEGHT
		self.distfromenemy = distsq(0, myposy, 0, oppy) 
		return distsq(0, myposy, 0, oppy)
	else --BOTH
		self.distfromenemy = distsq(myposx, myposy, oppx, oppy) 
		return distsq(myposx, myposy, oppx, oppy)
	end
	
end


function AiFeelings:IsOpponentApproaching() 
	
	if not self or not self.inst.components.stats.opponent then
		return false
		end
		
	local opponent = self.inst.components.stats.opponent --or GetPlayer()
	
	
	local myposx, myposy = self.inst.Transform:GetWorldPosition()
	local oppx, oppy = opponent.Transform:GetWorldPosition() --or GetPlayer().Transform:GetWorldPosition()
	
	local oppvelx, oppvely = opponent.Physics:GetVelocity()
	local myvelx, myvely = self.inst.Physics:GetVelocity()
	
	
	if myposx > oppx then --8-23 OKAY THIS MIGHT HAVE FIXED IT??? IT CONFIRMED WORKS FOR BOTH SIDES OF AIRvGROUND ATTACKS, BUT UNSURE ABOUT AIRvAIR
		if oppvelx > myvelx then
			return true
		else
			return false
		end
	else
		if oppvelx < myvelx then
			return true
		else
			return false
		end
	end
end



--8-14 --TO TEST IF ENTITY IS FACING A SELECTED TARGET
function AiFeelings:IsTargetFacingTarget(target1, target2)

	local enpos = target2.Transform:GetWorldPosition() 
	local mypos = target1.Transform:GetWorldPosition() 

    if mypos*self.inst.components.launchgravity:GetRotationValue() >= enpos*self.inst.components.launchgravity:GetRotationValue() then
		return false
	else
		return true
	end
end




--1-17-16
function AiFeelings:IsSafeToEdgeChase()
	
	local mypos, myposy = self.inst.Transform:GetWorldPosition()
	local myvelx, myvely = self.inst.Physics:GetVelocity()
	
	local opponent = self.inst.components.stats.opponent
	if (not opponent) or (not opponent:IsValid()) or self.ailevel <= 5 or opponent:HasTag("projectile") then --VALIDATE OPPONENT --DST CHANGE- DONT CHECK FOR GETPLAYER
		return false
	else
		
		--IF THE OPPONENT IS ON GROUND, DONT BOTHER STAYING OFFSTAGE
		if not opponent.components.launchgravity:GetIsAirborn() then 
			return false
		else
			
			if self:IsSafeToEdgeAct() then
				return true
			else
				return false
			end
			
		end
	end
end




--1-31-17 A SLIGHTLY DIFFERENT VERSION OF THE ABOVE FUNT THAT IGNORES THE ENEMY IN THE EQUATION
function AiFeelings:IsSafeToEdgeAct()
	
	local mypos, myposy = self.inst.Transform:GetWorldPosition()
	local myvelx, myvely = self.inst.Physics:GetVelocity()
	
			
	-- THE ACTUAL MEAT OF THE FUNCTION --
	if self.inst.components.jumper.currentdoublejumps >= 1 then
		if self.inst.components.launchgravity:GetVertSpeed() <= -5 and self.inst.components.launchgravity:GetIsAirborn() and myposy <= -4.0 or (mypos <= (self.anchor.components.gamerules.lledgepos - 5) or mypos >= (self.anchor.components.gamerules.rledgepos + 5)) then
			return false
		elseif self.inst.components.launchgravity:GetVertSpeed() <= -12 and self.inst.components.launchgravity:GetIsAirborn() and myposy <= -2.5 or (mypos <= (self.anchor.components.gamerules.lledgepos - 5) or mypos >= (self.anchor.components.gamerules.rledgepos + 5)) then
			return false --DID WE NEED THIS SECOND ONE???
		else
			return true
		end
	else --IF WE DONT HAVE A JUMP
		if self.inst.components.launchgravity:GetVertSpeed() <= 2 and self.inst.components.launchgravity:GetIsAirborn() and (myposy <= -1.5 or (mypos <= (self.anchor.components.gamerules.lledgepos - 4) or mypos >= (self.anchor.components.gamerules.rledgepos + 4))) then
			return false
		elseif self.inst.components.launchgravity:GetVertSpeed() <= 0 and myposy <= -4 then --4-18-17 ADDING THIS TO INCREASE SENSE OF PRESERVENCE? HE KEPT GOING TOO DEEP
			return false
		elseif myposy <= -6.5 then
			return false
		else
			return true
		end
	end
end




function AiFeelings:IsOffstage()
	
	local center_stage = self.anchor.components.gamerules.center_stage
	local mypos, myposy = self.inst.Transform:GetWorldPosition()
	-- local myvelx, myvely = self.inst.Physics:GetVelocity()
		
	--1-31-17 NOW SAFELY ON STAGE, CANCEL EVERYTHIN
	if mypos >= (self.anchor.components.gamerules.lledgepos) and mypos <= (self.anchor.components.gamerules.rledgepos) then
		return true
	end
end


--RETURNS HOW FAR OFFSTAGE THEY ARE
function AiFeelings:GetDistFromLedge()
	
	local center_stage = self.anchor.components.gamerules.center_stage
	local mypos, myposy = self.inst.Transform:GetWorldPosition()
	local dist = 0
	
	if mypos < 0 then
		dist = self.anchor.components.gamerules.lledgepos - mypos
	else
		dist = mypos - self.anchor.components.gamerules.rledgepos
	end
	
	-- print("MYDIST", dist, mypos, self.anchor.components.gamerules.lledgepos)
	return dist
end



function AiFeelings:IsFacingCenterStage()
	
	local center_stage = self.anchor.components.gamerules.center_stage
	local mypos, myposy = self.inst.Transform:GetWorldPosition()
	local facedir = self.inst.components.launchgravity:GetRotationFunction()
	
	if mypos < 0 and facedir == "left" then
		return true
	elseif mypos > 0 and facedir == "right" then
		return true
	else
		return false
	end
end




--1-3-17 EASY ACCESS TO BOTH OF THE MORE IMPORTANT BEHAVIOR NODES. I HOPE
function AiFeelings:GetDefendNode()
	for i,node in ipairs(self.inst.brain.bt.root.children) do
		if node.name == "Parallel" and node.children[1].name == "Defend" then
			-- print("NODE ACCESS:", node.children[2].name)
			return node.children[2]
		end
	end
end

function AiFeelings:GetAttackNode()
	for i,node in ipairs(self.inst.brain.bt.root.children) do
		if node.name == "ChaseAndFight" then
			-- print("NODE ACCESS:", node.name)
			return node
		end
	end
end


--4-5-19 DST SPECIFIC: A GATE THAT ONLY ALLOWS HOST TO RUN THESE BRAIN FUNCTS, BECAUSE CLIENT CANT SEE THE BRAIN
function AiFeelings:HostBrainContact(inst, command)
	
	if not (TheWorld.ismastersim and inst.brain) then --1-1-22 ADDING CHECK FOR BRAIN BECAUSE OF A REPORTED CRASH EVEN THOUGH ?? HOW IS THAT EVEN POSSIBLE?
		return end --GO HOME LITTLE GUY. ONLY THE HOST IS ALLOWED HERE
	
	if command == "stop" then
		inst.brain:Stop()
	elseif command == "refresh" then
		inst.brain:ForceRefresh()
	end
end

--2-7-17
function AiFeelings:FindNearestEnemy()
	local myposx, myposy, myposz = self.inst.Transform:GetWorldPosition()
	-- local ents = TheSim:FindEntities(myposx, myposy, myposz, 25, {"fighter"})
	local ents = (self.anchor.components.gamerules.livingplayers)
	
	local foundtarget = false
	
	for k,v in pairs(ents) do
		if v:IsValid() then 
			if v ~= self.inst and not self.anchor.components.gamerules:IsOnSameSide(self.inst, v) and v.components.stats.alive == true then
				foundtarget = true
				return v
			end
		end
    end
	
	if foundtarget == false then
		return ThePlayer
	end
	
	
end



return AiFeelings
