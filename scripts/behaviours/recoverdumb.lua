Recover = Class(BehaviourNode, function(self, inst, hunterparams, see_dist, safe_dist, fn, runhome)
    BehaviourNode._ctor(self, "Recover")
    self.inst = inst
	self.recoverangle = "low" --12-28-16 AN ATTEMPT TO GIVE AI THE CHOICE TO RECOVER HIGH OR LOW
	self.choserecovery = false
	
	self.anchor = TheSim:FindFirstEntityWithTag("anchor") --DST
end)

function Recover:__tostring()
    -- return string.format("RUNAWAY %f from: %s", self.safe_dist, tostring(self.hunter))
	return string.format("RUNAWAY %f from: %s")
end



function Recover:Visit()
    
    if self.status == READY then
		
		
		local center_stage = self.anchor.components.gamerules.center_stage
		local mypos, myposy = self.inst.Transform:GetWorldPosition()
		
		
		-- if self.inst.components.launchgravity:GetIsAirborn() and myposy <= -0.5 then   --7-6 ADDED TEST FOR MYPOS
		if self.inst.components.launchgravity:GetIsAirborn() and mypos <= (self.anchor.components.gamerules.lledgepos) or mypos >= (self.anchor.components.gamerules.rledgepos) then --7-31
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
        
		
		local center_stage = self.anchor.components.gamerules.center_stage
		local mypos, myposy = self.inst.Transform:GetWorldPosition()
		local myvelx, myvely = self.inst.Physics:GetVelocity()
		
		if mypos >= (self.anchor.components.gamerules.lledgepos + 3) and mypos <= (self.anchor.components.gamerules.rledgepos - 3) then
			self.status = FAILED 
			-- self:DebugPrint("WE'RE BACK ON STAGE! RECOVERY OVER")
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
		
		
		-- if myposy <= -2 then
		if myposy <= -2 or (self.recoverangle == "high" and myposy <= 12 ) then --12-28-16 JUMP EARLY IF RECOVERING HIGH.
			self.inst:PushEvent("jump")   
			
			--NO UP-SPECIAL RECOVERY. TOO STUPID TO DO THAT (SO ARE MOST BEGINNER SMASH PLAYERS. SO NOW ITS EVEN)
			-- if self.inst.components.jumper.currentdoublejumps == 0 and myvely < 0 and myposy <= (-3 + math.random(-1, 1)) then
				-- self.inst:PushEvent("throwattack", {key = "uspecial"})
			-- end
			
		end
		
		--ALSO NO ATTACKING OR DODGING WHEN JUMPING BACK ONTO STAGE
		
    end
end
