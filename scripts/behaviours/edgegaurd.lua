EdgeGaurd = Class(BehaviourNode, function(self, inst, max_chase_time, give_up_dist, max_attacks, findnewtargetfn, walk)
    BehaviourNode._ctor(self, "EdgeGaurd")
    self.inst = inst
	
	self.chosenattack = "dashattack"
	self.calcframes = 1
	self.calcxpos = 3
	self.calcypos = 0
	self.calcrange = 2
	self.calcyrange = 0
	
	self.skipnode = false --1-25-17 --OHHH GOOD IDEA
	self.forcedash = false
    
	self.anchor = TheSim:FindFirstEntityWithTag("anchor") --DST
	self.debugprint = AIDEBUGPRINT
end)

function EdgeGaurd:__tostring()
    return string.format("target %s", tostring(self.inst.components.combat.target))
end


function EdgeGaurd:DebugPrint(output, output2) --STEALING IT AND ADDING MY OWN FLAIR
	if self.debugprint == true then
		print("EdgGrd: " .. output .. tostring(output2 or ""))
	end
end


function EdgeGaurd:OnStop()
	--DONT FORGET TO REMOVE THE EVENT LISTENERS SO THEY DONT HAPPEN EVEN WHEN BEHAVIOR ISNT ACTIVE. --VERY SMART KLEI~
	-- self.inst:RemoveEventCallback("block_hit", self.onblockedfn)
end


function EdgeGaurd:SkillCheck()
	return self.inst.components.aifeelings.ailevel
end




--7-25 -TO SEE IF HE SHOULD BAIT SMASH
function EdgeGaurd:ShouldEdgeGaurdToAttacker(target)
	-- print("CONGRATULATIONS ON YOUR NEWBORN!", self:DistFromEnemy("horizontal"))

    if self:DistFromEnemy("horizontal") >= 0 and self:DistFromEnemy("horizontal") <= 65 then
		-- print("ITS A MAILBOX!")
		
		self.chosenattack = "baitsmash"
		self.calcframes = 1
		self.calcrange = 1
		self.calcxpos = 1.6
		self.calcypos = 0
		
	return true
	end
	
	-- self.status = SUCCESS
end





function EdgeGaurd:ChooseAttack()
    --print ("on attack other", target)
	
	-- if self:ShouldEdgeGaurdToAttacker() then
		-- return end
		
		
	
	local opponent = self.inst.components.stats.opponent
	
	-- self.inst:RemoveTag("going_in")
	self.inst:RemoveTag("wantstoblock")
	self.calcyrange = 0
	self.forcedash = false
	
	
	--EASY VERSION:
	if self.inst.components.aifeelings.ailevel == 1 then
		-- if math.random() < (0.2) then
			-- self.chosenattack = "jumpnair" --NO. THE QUEEN CANT DO THIS
		-- else
			self.chosenattack = "none" --WILL THIS WORK IN THIS CONTEXT?
		-- end
		return end --WE HAVE TO RETURN END, SINCE BABY SPIDERS DONT HAVE ATTACK NODES, AND THIS WILL CRASH
	
	local jumpinmod = 1
	if self.inst.components.aifeelings.ailevel >= 10 then
		jumpinmod = 2
	end
	
	-- print("MODCHECK", math.random(), self.inst.components.aifeelings:GetAttackNode():JumpinConfPercent())
	if math.random() < (0.4 + (self.inst.components.aifeelings:GetAttackNode():JumpinConfPercent() / 2) * jumpinmod) then --RIGGED -20
		self.chosenattack = "jumpin"
		-- self.inst:AddTag("going_in")
	-- end
	
	
	
	elseif math.random() < (0.5) and opponent.components.launchgravity:GetHeight() >= 8 then
		self.chosenattack = "jumpnair"
		self.calcframes = 2
		self.calcxpos = 0
		self.calcypos = 0
		self.calcrange = 2
		self.inst:PushEvent("singlejump")
		-- self.inst:PushEvent("throwattack")
	
	
	elseif math.random() < (0.5 + (self.inst.components.aifeelings:ConfidencePercent() / 4)) then --opponent.components.launchgravity:GetHeight() >= 1 then
		self.chosenattack = "baitsmash"
		self.calcframes = 1
		self.calcxpos = 0.8
		self.calcypos = 0.5
		self.calcrange = 1.2			
		-- self.inst:PushEvent("throwattack", {key = "fsmash"}) --NOT YET, IT'LL JUST DASH ATTACK
		-- self.inst:AddTag("chargesmash")
	elseif math.random() < (0.5 + (self.inst.components.aifeelings:ConfidencePercent() / 4)) then
		self.chosenattack = "ledgedrop"
		self.calcframes = 4
		self.calcxpos = 5.0
		self.calcypos = -4.5
		self.calcrange = 2
		self.calcyrange = 6
		self.inst.components.aifeelings:GetAttackNode().chosenattack = "dair"
	
	else  --if opponent.components.launchgravity:GetHeight() <= 1 then -- (:
		self.chosenattack = "ledgesmash"
		-- self.calcframes = 1
		-- self.calcrange = 1
		-- self.calcxpos = 1.6
		-- self.calcypos = 0
		-- self.inst:PushEvent("throwattack", {key = "fsmash"})
		-- self.inst:DoTaskInTime(0.2, function() self.inst:PushEvent("throwattack", {key = "fsmash"}) end )
		-- self.inst:DoTaskInTime(0.2, function() self.inst:PushEvent("throwattack", {key = "usmash"}) end ) --1-23-17 LETS TRY USMASH INSTEAD --ACTUALLY, JUST DONT DO ANYTHING
		-- self.inst:AddTag("chargesmash")
	end
	
	
	if self.inst.components.aifeelings.ailevel <= 3 then
		if math.random() < (0.5) then
			self.chosenattack = "jumpnair"
		else
			self.chosenattack = "jumpnair"
		end	
	
	elseif self:SkillCheck() <=6 then --5 AND LOWER
		-- if self.chosenattack == "ledgedrop" then
			-- self:ChooseAttack() --JUST DONT ALLOW LEDGE DROP I GUESS??? I DUNNO
		-- end
	
	end
	
	self:DebugPrint("CHOOSING AN EDGEGAURD TACTIC... : ", self.chosenattack)
	
end





function EdgeGaurd:DistFromEnemy(dir)
	--JUST CALL THE REAL ONE
	return self.inst.components.aifeelings:DistFromEnemy(dir)
end






--3-14
-- function EdgeGaurd:OnAttacked()
    -- self.inst:RemoveTag("going_in")
	-- self.inst.components.talker:Say("OUCH!")
	-- self:ChooseAttack()
	-- self.status = SUCCESS
-- end


function EdgeGaurd:Visit()
    
    if self.status == READY then
		
		local center_stage = self.anchor.components.gamerules.center_stage
		local mypos, myposy = self.inst.Transform:GetWorldPosition()
		local enpos, enposy = self.inst.components.stats.opponent.Transform:GetWorldPosition()
		-- print("WHY AM I HERE???", center_stage, mypos, enpos)
		if not (center_stage and mypos and enpos) then --8-14 ANTI CRASH MEASURES
			self.status = SUCCESS
		end
		
		--1-16-22 AIRBORN VERSION SHOULD ACT DIFFERENTLY
		if self.inst.components.launchgravity:GetIsAirborn() then
			self.status = FAILED
			self:DebugPrint("WE'RE A LITTLE TOO AIRBORN TO DECIDE EDGAURDING AT THE MOMENT")
			return end
			
		
		-- if enpos <= (GetPlayer().components.gamerules.lledgepos) or enpos >= (GetPlayer().components.gamerules.rledgepos) and not self.inst:HasTag("going_in") and self.inst.components.aifeelings:IsSafeToEdgeChase() then
		if enpos <= (self.anchor.components.gamerules.lledgepos) or enpos >= (self.anchor.components.gamerules.rledgepos) and self.inst.components.aifeelings:IsSafeToEdgeChase() then
			self.status = RUNNING
			self:DebugPrint("VISITING EDGEGAURD")
			self:ChooseAttack()
			
			-- if (self.inst.components.aifeelings:GetAttackNode().chosenattack == "jumpin" or self.inst.components.aifeelings:GetAttackNode().chosenattack == "followup") then
				-- self.status = FAILED --1-16-17 GIVE HIM A CHANCE TO CHASE OFFSTAGE IF NEEDED
			-- else
				-- self.status = RUNNING
			-- end
		else
            self.status = FAILED
			-- print("FAILED, NOT SAFE TO EDGE CHASE------------------------")
			-- self.chosenattack = "none"
			
			--1-17-17
			-- if (self.chosenattack == "jumpin" and self.inst.components.aifeelings:IsSafeToEdgeChase()) then
				-- self.status = RUNNING
			-- else
				-- self.status = FAILED
			-- end
			
        end
		
		if self.skipnode == true then
			self.status = FAILED
			self.skipnode = false
		end
		
		
		
    end

	
	
	
	
    if self.status == RUNNING then
		-- print("AND DONT EVER COME BACK!", self.chosenattack)
		
		if not self.inst.components.stats.opponent:IsValid() then
			return end
		
		local center_stage = self.anchor.components.gamerules.center_stage
		local mypos, myposy = self.inst.Transform:GetWorldPosition()
		local enpos, enposy = self.inst.components.stats.opponent.Transform:GetWorldPosition()
		local myvelx, myvely = self.inst.Physics:GetVelocity()
		-- print("CURRENT VELOCITY TO Y", myvely, myposy)
		local opponent = self.inst.components.stats.opponent
		
		if enpos >= (self.anchor.components.gamerules.lledgepos + 1) and enpos <= (self.anchor.components.gamerules.rledgepos - 1) then --1-24-17  OHHHHHH, IT NEEDS TO BE "AND" NOT "OR" IS THIS WRONG??? ITS INSTANTLY TURNING OFF
		-- if enpos <= (GetPlayer().components.gamerules.lledgepos + 0) or enpos <= (GetPlayer().components.gamerules.rledgepos - 0) then --WTF???
			self.status = FAILED
			self:DebugPrint("THEY'RE BACK ONSTAGE. ABORT EDGEGAURD")
			return end
		
		--10-3-20 CANT BELEIVE I FORGOT THIS. WE DONT WANT SPIDERS WAITING AT LEDGE FOREVER FOR AN OPPONENT THAT ISNT COMING BACK UP
		if opponent and opponent.components.stats and opponent.components.stats.alive == false then --4-4-19 THERE. EVERYBODY GOT STATS! NO MORE HEALTH
            -- self.inst.components.aifeelings:FindNearestEnemy() --WILL FIND THE NEXT (BUT NOT NEAREST) LIVING ENEMY
			self:DebugPrint("HAHAAA! GOTTEM")
			self.inst:RemoveTag("chargesmash")
			self.status = SUCCESS
			return end
		--10-3-20 ALSO, SEE IF THERE ARE ANY OTHER OPPONENTS WE COULD BE FIGHTING INSTEAD
		if not (self.inst.components.launchgravity:GetIsAirborn() or self.inst.sg:HasStateTag("busy")) then --BUT ONLY IF CONVENIENT
			if self.inst.components.aifeelings:CheckForAlternateOpponent() then --WILL RETURN TRUE IF WE FIND A BETTER OPPONENT (IT SETS ITSELF)
				self:DebugPrint("THERE ARE OTHER ENEMIES TO WORRY ABOUT. ILL STOP EDGEGAURDING")
				self.status = SUCCESS 
				return end
		end
			
		
		if mypos <= (self.anchor.components.gamerules.lledgepos + 3) or mypos >= (self.anchor.components.gamerules.rledgepos - 3) then --7-31
			
			
			----1-16-17 GIVE HIM A CHANCE TO CHASE OFFSTAGE IF NEEDED --EH, SHOULD I KEEP THIS??
			-- if (self.inst.components.aifeelings:GetAttackNode().chosenattack == "jumpin" or self.inst.components.aifeelings:GetAttackNode().chosenattack == "followup") then
				-- self.inst.components.stats.jumpspec = "full"
				-- self.inst:PushEvent("singlejump")
				-- self.status = FAILED 
				-- return end
			
			
			
			-- self.inst:PushEvent("halt") --1-17-17 USED TO BE HERE
			
		--MOVED THIS HERE CHUNK DOWN TO THE BOTTOM SO HAROLD STOPS ATTACKING FROM ACROSS THE MAP WHEN IM OFF THE CLIFF
		-- elseif not self.inst.sg:HasStateTag("busy") and not self.inst.components.launchgravity:GetIsAirborn() then 
			-- self.inst.components.locomotor:FaceTarget(self.inst.components.stats.opponent)
			-- self.inst:PushEvent("dash")
			-- self.status = SUCCESS
		-- end
		
		
		-- print("STOP ME IF YOUVE HEARD THIS ONE BEFORE!", self.inst:HasTag("holdleft"), self.inst:HasTag("holdright"))
		if self.chosenattack == "jumpin" or self.chosenattack == "ledgedrop" then
			self.inst.components.aifeelings:GetAttackNode():DriftTowardOpp()
		end
		
		
		if self:SkillCheck() >= 4 then
			--1-17-17
			if self.chosenattack == "jumpin" and self.inst.components.aifeelings:CalculateTrajectory(7, 5, 5, 5, 4) then
				-- self.chosenattack = "jumpin"
				self.inst.components.aifeelings:GetAttackNode().chosenattack = "dair"
				self.inst:PushEvent("dash")
				self.inst:DoTaskInTime(0*FRAMES, function()
					self.inst.components.stats.jumpspec = "full"
					self.inst:PushEvent("singlejump")
					-- self.inst.components.talker:Say("BRAVE JUMP!")
				end)
				
			elseif self.forcedash == false then
				self.inst:PushEvent("halt")
			end
			
			
			--1-16-17 LETS JUST GO FOR IT. DAIR --
			if (self.chosenattack == "jumpin" or self.chosenattack == "ledgedrop") and self.inst.components.aifeelings:CalculateTrajectory(4, 0, -0.5, 2) and self.inst.components.aifeelings:IsSafeToEdgeChase() and self.inst.components.launchgravity:GetIsAirborn() then --(frames, xpos, ypos, range)
				-- self.inst.components.talker:Say("HERE COMES DAS BOOT!")
				self:DebugPrint("HERE COMES DAS BOOT!")
				self.inst:PushEvent("throwattack", {key = "down"})
			end
		--6-27-18 OKAY BUT AT LEAST LET THE CHILDREN HALT AT THE EDGE TOO
		else
			self.inst:PushEvent("halt")
		end
		
		
		
		--11-28-20 QUEENS SHOULD PATIENTLY WAIT AT THE LEDGE AND DO NOTHING.
		if self:SkillCheck() == 1 then
			self.status = SUCCESS
			return end
		
		
		
		
		
		
		--1-16-17 TAKE ACTION ONCE THEY ACTUALLY GRAB LEDGE
		-- print("STATUS REPORT AGAIN??", opponent.sg:HasStateTag("hanging"), opponent.components.launchgravity:GetIsAirborn(), self.chosenattack == "ledgegaurd", (opponent.sg:HasStateTag("hanging") or not opponent.components.launchgravity:GetIsAirborn()))
		-- print("STATUS REPORT FOR THE THIRD TIME??", ((opponent.sg:HasStateTag("hanging") or not opponent.components.launchgravity:GetIsAirborn()) and self.chosenattack ~= "ledgegaurd"), self.chosenattack ~= "ledgegaurd")
		if (opponent.sg:HasStateTag("hanging") or not (opponent.components.launchgravity and opponent.components.launchgravity:GetIsAirborn())) then --and self.chosenattack ~= "ledgegaurd" then  --1-24-17 OH RIGHT.... THIS CRAP AGAIN. NO USING "NOT ==" MUST ALWAYS USE "~="
			self.chosenattack = "ledgegaurd"
			self:DebugPrint("HE'S ON THE LEDGE!")
			
			if not self.inst.sg:HasStateTag("busy") then
				-- self.inst:PushEvent("throwattack", {key = "fsmash"})
				-- self.chosenattack = "ledgegaurd" --OTHERWISE IT'LL TRY AND ATTACK WHILE BLOCKING
				
				if math.random() < (0.6) then
					self.inst:RemoveTag("going_in")
					self.inst:AddTag("braceyourself")
					self.inst:AddTag("wantstoblock")
					self.inst:DoTaskInTime(1.5, function(inst) 
						self.inst:RemoveTag("braceyourself") 
						self.inst:RemoveTag("wantstoblock")
						self.inst:AddTag("going_in")
						self.skipnode = true
						self.status = SUCCESS
					end ) --0.5
					self.inst:PushEvent("block_key")
					self:DebugPrint("WAIT IN SHIELD FOR HIM TO CLIMB UP")
					-- self.status = SUCCESS
					-- self:Sleep(.125) --THIS DOES SOMETHING????
				elseif not self.inst:HasTag("wantstoblock") then
					self.inst:RemoveTag("wantstoblock")
					if self:SkillCheck() >= 4 then --ONLY SMART SPIDERS CAN DO THIS
						-- self.inst:PushEvent("throwattack", {key = "usmash"})
						self:DebugPrint("TOSS OUT AN UPSMASH AND SEE IF HE CLIMBS INTO IT")
						self.inst:PushEvent("cstick_up")
						self.status = SUCCESS
					end
				end
			end
		
		
		
		else
		
					--BEFORE ENEMY HAS GRABBED THE LEDGE YET---
			-- print("eh?")
			
			-- opponent:RemoveTag("wantstoblock") --WHAT????
			self.inst:RemoveTag("wantstoblock")
			
			--WE NEED TO FACE OUTWARD SO OUR TRAJECTORY CALC WORKS
			local airborn = self.inst.components.launchgravity:GetIsAirborn()
			if self.inst.components.aifeelings:IsFacingCenterStage() and not (self.inst.sg:HasStateTag("busy") or airborn) then
				self.inst.components.locomotor:TurnAround()
			end
			
			
			
			if self.chosenattack == "baitsmash" then
				
				if not self.inst.sg:HasStateTag("busy") then
					self.inst:PushEvent("throwattack", {key = "fsmash"})
					self.inst:AddTag("chargesmash")
					self:DebugPrint("BAITSMASH!")
				end
				
				
				-- self.inst:PushEvent("throwattack", {key = "fsmash"})
				if self.inst.components.aifeelings:CalculateTrajectory(self.calcframes, self.calcxpos, self.calcypos, self.calcrange) then --or opponent.components.launchgravity:GetHeight() >= 2 then
					self.inst:PushEvent("throwsmash")
					self.inst:RemoveTag("chargesmash")
					self:DebugPrint("HIYA")
					self.status = SUCCESS
				end
				-- self:ChooseAttack()
			elseif self.chosenattack == "ledgesmash" then --SMASH AS THEY GET UP FROM THE LEDGE
				
					-----1-23-17 ACTUALLY, JUST DONT DO ANYHTING-----
					
					
					--1-31-17 ACTUALLY, LETS JUST TAKE WHAT WAS UP IN THE LEDGE BLOCK AND THROW IT IN HERE
					if self.inst.components.aifeelings:CalculateTrajectory(7, 0, 1, 3) then
						self.inst:RemoveTag("going_in")
						self.inst:AddTag("braceyourself")
						self.inst:AddTag("wantstoblock")
						self.inst:DoTaskInTime(1.5, function(inst) 
							self.inst:RemoveTag("braceyourself") 
							self.inst:RemoveTag("wantstoblock")
							self.inst:AddTag("going_in")
							self.skipnode = true
							self.status = SUCCESS
						end ) --0.5
						self.inst:PushEvent("block_key")
					end
				
				
			elseif self.chosenattack == "ledgedrop" then
				
				if self.inst.components.aifeelings:CalculateTrajectory(self.calcframes, self.calcxpos, self.calcypos, self.calcrange, self.calcyrange) then
					self.inst:PushEvent("dash")
					self.forcedash = true
					self:DebugPrint("LEDGE DROP!")
				end
				if self.forcedash == true then self.inst:PushEvent("dash") end
				
			elseif self.chosenattack == "jumpnair" then --JUMP UP AND HIT THEM AS THEY TRY TO GO OVER
				-- print("IN A WHILE CROCKODILE")
				if self.inst.components.aifeelings:CalculateTrajectory(3, 2, 5, 2, 5) then
					self.inst.components.stats.jumpspec = "full"
					self.inst:PushEvent("singlejump")
					self.inst:AddTag("going_in")
					self.inst.components.aifeelings:GetAttackNode().chosenattack = "jumpin"
					self.status = FAILED
					self:DebugPrint("JUMPNAIR")
				end
				
			end
			
			-- self.status = SUCCESS
		
		end
		
		
						
	elseif not self.inst.sg:HasStateTag("busy") and not self.inst.components.launchgravity:GetIsAirborn() then 
			self.inst.components.locomotor:FaceTarget(self.inst.components.stats.opponent)
			self.inst:PushEvent("dash")
			self:DebugPrint("CASUALLY APPROACH THE VICTIM")
			self.status = SUCCESS
		end
	end
	
	
	
        
    -- end
end
