Recover = Class(BehaviourNode, function(self, inst, hunterparams, see_dist, safe_dist, fn, runhome)
    BehaviourNode._ctor(self, "Recover")
    self.inst = inst
	self.recoverangle = "low" --12-28-16 AN ATTEMPT TO GIVE AI THE CHOICE TO RECOVER HIGH OR LOW
	self.choserecovery = false
	self.debugprint = AIDEBUGPRINT
	
	self.anchor = TheSim:FindFirstEntityWithTag("anchor")
	self.lledgepos = self.anchor.components.gamerules.lledgepos
	self.rledgepos = self.anchor.components.gamerules.rledgepos
end)

function Recover:DebugPrint(output, output2) --STEALING IT AND ADDING MY OWN FLAIR
	if self.debugprint == true then
		print("RecVr: " .. output .. (tostring(output2 or "")))
	end
end

function Recover:__tostring()
    -- return string.format("RUNAWAY %f from: %s", self.safe_dist, tostring(self.hunter))
	return string.format("RUNAWAY %f from: %s")
end

function Recover:SkillCheck()
	return self.inst.components.aifeelings.ailevel
end


function Recover:GetRecoveryChance()
	if self:SkillCheck() >= 6 then
		return true
	elseif self:SkillCheck() == 1 then
		return false
	elseif self:SkillCheck() <= 5 then
		if math.random() <= 0.1 then return true else return false end
	else
		return false
	end
end



function Recover:Visit()
    
    if self.status == READY then
		
		
		--1-17-17
		if (self.inst.components.aifeelings:IsSafeToEdgeChase() and not self.inst:HasTag("juggled")) or self.inst.sg:HasStateTag("hanging") then --and self.inst.components.aifeelings:GetAttackNode().chosenattack == "jumpin" then
			self.status = FAILED
			return end
		-- end
		self:DebugPrint("VISITING RECOVER")
		
		
		local center_stage = self.anchor.components.gamerules.center_stage
		local mypos, myposy = self.inst.Transform:GetWorldPosition()
		
		
		-- if self.inst.components.launchgravity:GetIsAirborn() and myposy <= -0.5 then   --7-6 ADDED TEST FOR MYPOS
		if self.inst.components.launchgravity:GetIsAirborn() and (mypos <= (self.anchor.components.gamerules.lledgepos) or mypos >= (self.anchor.components.gamerules.rledgepos)) then --7-31
			self.inst:RemoveTag("holdleft")
			self.inst:RemoveTag("holdright")
			self.status = RUNNING
			
			if math.random() >= 0.6 and self.choserecovery == false then --12-28-16 --CHANCE TO RECOVER HIGH
				self.recoverangle = "high"
			end
			self.choserecovery = true
		else
            self.status = FAILED
			-- print("FAILED")
			self.recoverangle = "low" --IS LOW BY DEFAULT
			self.choserecovery = false
        end
        
    end

    if self.status == RUNNING then
		-- print("MARATHON MAN")
		
		local center_stage = self.anchor.components.gamerules.center_stage
		local mypos, myposy = self.inst.Transform:GetWorldPosition()
		local myvelx, myvely = self.inst.Physics:GetVelocity()
		local jumps = self.inst.components.jumper.currentdoublejumps
		
		--1-31-17 NOW SAFELY ON STAGE, CANCEL EVERYTHIN
		if mypos >= (self.anchor.components.gamerules.lledgepos + 3) and mypos <= (self.anchor.components.gamerules.rledgepos - 3) then
			self.status = FAILED 
			self:DebugPrint("WE'RE BACK ON STAGE! RECOVERY OVER")
			self.inst:RemoveTag("holdleft")
			self.inst:RemoveTag("holdright")
			return end
		
		
		if mypos <= center_stage then
			-- angle = 0
			self.inst:AddTag("holdleft")
		else
			-- angle = 180
			self.inst:AddTag("holdright")
		end
		
		
		local opponent = self.inst.components.stats.opponent
		
		if self:SkillCheck() >= 6 then
			if self.inst.components.aifeelings:IsSafeToEdgeChase() and not self.inst:HasTag("juggled") then
				if self.inst.components.aifeelings:CalculateTrajectory(4, 0, -1, 3) then --(frames, xpos, ypos, range)
					-- self.inst.components.talker:Say("HERE COMES DAS BOOT!")
					self.inst:PushEvent("throwattack", {key = "down"})
					-- print("RISKY MID-RECOVERY DAIR!")
				end
			end
		end
		
		
		self.inst.components.aifeelings:GetDistFromLedge()
		
		--1-20-17 A SIDE-SEPCIAL HIGH RECOVERY OPTION
		if (self:SkillCheck() >= 5 and math.random() >= 0.5) or self:SkillCheck() >= 7 then
			if (self.recoverangle == "high" and myposy >= -1) then
				
				self.inst.components.locomotor:FaceCenterStage()
				self.inst:PushEvent("throwspecial", {key = "forward"})
				-- print("SIDE SPECIAL RECOVERY!")
				-- self.inst.components.talker:Say("SIDE SPECIAL RECOVERY!")
				
			else --1-16-22
				if self:SkillCheck() >= 7 and jumps == 0 and myvely < 0 and self.inst.components.aifeelings:GetDistFromLedge() > 5 and myposy < 2 and myposy >= -8 then
					self.inst.components.locomotor:FaceCenterStage()
					self.inst:PushEvent("throwspecial", {key = "forward"})
					self:DebugPrint("EMERGENCY FSPECIAL JUST TO GET CLOSER TO STAGE")
				end
			end
			
		end
		
		-- if myposy <= -2 then
		if myposy <= -2 or (self.recoverangle == "high" and myposy <= 12 ) then --12-28-16 JUMP EARLY IF RECOVERING HIGH. MAYBE FLESH THIS OUT A BIT MORE SOMETIME LATER
			self.inst:PushEvent("jump")    --!!!! HAVE AN OPTION TO JUST USE THE JUMP EARLY IF YOU ARE FAR ENOUGH OFFSTAGE TO TRY AND RECOVER HIGH --!!!!
			
			if jumps == 0 and myvely < 0 and myposy <= (-3 + math.random(-1, 1)) then
				if self:GetRecoveryChance() then --LOWER THE CHANCE OF RECOVERY FOR DUMBER AI
					self.inst:PushEvent("throwspecial", {key = "up"})
					-- print("RECOVER! UPSPEC")
				end
			end
			
			
		end
		
		if self.inst.components.stats.opponent and self.inst.components.stats.opponent:IsValid() then --MAKE SURE AN OPPONENT EXISTS BEFORE TRYING TO DODGE PAST ONE
			if self.inst.components.aifeelings:CalculateTrajectory(5, 0, 0.5, 2.5) and myvely > 0 then
				-- print("THE WHEEL OF DEATH!")
				if math.random() >= 0.6 then
					self.inst:PushEvent("block_key")
				else --if math.random() >= 0.5 then
					self.inst:PushEvent("throwattack")
				end
				
				-- self.inst:PushEvent("jump")
				
				-- self.status = SUCCESS
			end
		end
		
		
		if not self.inst.components.launchgravity:GetIsAirborn() or self.inst.sg:HasStateTag("hanging") then
			self:DebugPrint("WE'RE BACK ON THE LEDGE! RECOVERY OVER")
			self.inst:RemoveTag("holdleft")
			self.inst:RemoveTag("holdright")
			self.status = SUCCESS
		end
		
    end
end
