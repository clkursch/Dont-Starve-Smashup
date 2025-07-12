GetUp = Class(BehaviourNode, function(self, inst, hunterparams, see_dist, safe_dist, fn, runhome)
    BehaviourNode._ctor(self, "GetUp")
    self.inst = inst
	
	self.debugprint = AIDEBUGPRINT
end)

function GetUp:DebugPrint(output, output2) --STEALING IT AND ADDING MY OWN FLAIR
	if self.debugprint == true then
		print("GetUp: " .. output .. (tostring(output2 or "")))
	end
end

function GetUp:__tostring()
    -- return string.format("RUNAWAY %f from: %s", self.safe_dist, tostring(self.hunter))
	return string.format("RUNAWAY %f from: %s")
end

-- function GetUp:OnStop()
	-- --DONT FORGET TO REMOVE THE EVENT LISTENERS SO THEY DONT HAPPEN EVEN WHEN BEHAVIOR ISNT ACTIVE. --VERY SMART KLEI~
	-- self.inst:RemoveEventCallback("block_hit", self.onblockedfn)
-- end

function GetUp:DistFromEnemy(dir)
	--JUST CALL THE REAL ONE
	return self.inst.components.aifeelings:DistFromEnemy(dir)
end

function GetUp:SkillCheck()
	return self.inst.components.aifeelings.ailevel
end


function GetUp:Visit()
    
    if self.status == READY then
		
		if self.inst.sg:HasStateTag("grounded") or self.inst.sg:HasStateTag("hanging") or self.inst.sg:HasStateTag("grabbing") then 
			self.status = RUNNING
			self:DebugPrint("VISITING GETUP", self:DistFromEnemy("horizontal"))
		else
			self.status = FAILED --1-31-21 PRETTY SURE THIS SHOULD BE HERE
		end
        -- print("IF I JUST LAY HERE")
    end

    if self.status == RUNNING then

		-- print("IM JUST GONNA LAY HERE FOR A SEC")
		
		
		if self.inst.sg:HasStateTag("grounded") then --2, 0, 0, 3
			if (self.inst.components.aifeelings:CalculateTrajectory(4, 0, 0, 1.5)) then -- or self:DistFromEnemy("horizontal") <= 10) and math.random() < (0.85) then --(frames, xpos, ypos, range)
				-- print("GET AWAY!")
				self.inst:PushEvent("attack_key")
			elseif (self:DistFromEnemy("horizontal") <= 35 or self.inst:HasTag("braceyourself")) and math.random() < (0.85) then

					self.inst:PushEvent("backward_key")
					-- print("BACK IT UP!")
			
			elseif (self:DistFromEnemy("horizontal") >= 50) and math.random() < (0.85) then
				self.inst:PushEvent("forward_key")
				
			elseif math.random() < (0.85) then
				self.inst:PushEvent("up")
			end
		end
		
		
		--1-17-22 WE CAN BE A LITTLE SMARTER THAN THIS ABOUT GETTING UP
		local attackmod = 1
		local rollmod = 1
		local jumpmod = 1
		local standupmod = 1
		--ANY SPIDER CAN RUN THIS, BUT IT'S MUCH MORE LIKELY FOR SMARTER SPIDERS
		if (math.random() < (self:SkillCheck() / 10)) and self.inst.components.stats.opponent and self.inst.components.stats.opponent.sg then
			if self.inst.components.stats.opponent.sg:HasStateTag("scary") then
				if self:DistFromEnemy("horizontal") <= 36 then --IF ENEMY IS CLOSER THAN 6 UNITS
					self:DebugPrint("SCARY LEDGEAURDER!")
					attackmod = 0.1
					rollmod = 0.4
					jumpmod = 0.4
					standupmod = 0
				elseif self:DistFromEnemy("horizontal") <= 16 then --IF ENEMY IS CLOSER THAN 4 UNITS
					self:DebugPrint("SCARYER LEDGEAURDER!")
					attackmod = 0.5
					rollmod = 1
					jumpmod = 0
					standupmod = 0
				end
			end
			--IF ENEMY IS FARTHER THAN 10 UNITS AWAY
			if self:DistFromEnemy("horizontal") >= 100 then 
				attackmod = 0
				rollmod = 0
				jumpmod = 1
				standupmod = 2
			end
		end
		
		
		self:DebugPrint("CHOICES CHOICES..", self.inst.components.aifeelings:ConfidencePercent())
		if self.inst.sg:HasStateTag("hanging") then 
			if (self.inst.components.aifeelings:CalculateTrajectory(7, 1.5, 0, 1.5)) and math.random() < ((0.2 + (self.inst.components.aifeelings:ConfidencePercent() / 3)) *attackmod)  then
				self:DebugPrint("GETUP ATTACK!")
				self.inst:PushEvent("attack_key")
			elseif math.random() < (0.3 - (self.inst.components.aifeelings:ConfidencePercent() / 2))*rollmod then
				self.inst:PushEvent("block_key")
				self:DebugPrint("GETUP ROLL!")
			elseif math.random() < (0.1)*jumpmod then
				self.inst:PushEvent("jump_ledge") --VERY SPECIFIC BECAUSE HAROLD TRIES TO JUMP ALLL THE TIME
				self:DebugPrint("GETUP JUMP!")
			elseif math.random() < (0.1 * standupmod) then
				self.inst:PushEvent("forward_key")
				self:DebugPrint("GETUP NORMAL I GUESS..")
			else
				self:DebugPrint("I THINK I'LL JUST HANG FOR A BIT...")
			end
			-- print("CALCULATING GETUP...")
		end
		
		
		
		
		
		--11-28-20 NOT REALLY A "GETUP" ACTION, BUT WE KINDA STILL NEED IT.
		if self.inst.sg:HasStateTag("grabbing") then 
			--1-17-22 --SMART COOKIES KNOW TO TOSS PLAYERS OFF THE NEAREST LEDGE
			if math.random() < (self:SkillCheck() / 10) and self.inst.components.aifeelings:GetDistFromLedge() >= -7 and self.inst.components.aifeelings:IsFacingCenterStage() then
				self:DebugPrint("TOSSING THEM BACKWARDS OFF THE CLIFF!~")
				self.inst:PushEvent("backward_key")
			else
				self.inst:PushEvent("forward_key")
			end
			
		end
		
		
		--WE'RE JUST ABOUT TO NEED THIS BEHAVIOR! WAIT JUST A BIT LONGER
		if (self.inst.sg:HasStateTag("grounded") and self.inst.sg:HasStateTag("nogetup"))
			or (self.inst.sg:HasStateTag("hanging") and not self.inst.sg:HasStateTag("can_act")) 
			or (self.inst.sg:HasStateTag("grabbing") and not self.inst.sg:HasStateTag("handling_opponent")) then
			self.status = RUNNING
		
		--WE'RE IN THE STATE WE NEED TO BE! BUT WE DECIDED TO WAIT, FOR WHATEVER REASON.. COME BACK AGAIN IN 0.20 SECONDS
		elseif (self.inst.sg:HasStateTag("grounded") and not self.inst.sg:HasStateTag("nogetup"))
			or (self.inst.sg:HasStateTag("hanging") and self.inst.sg:HasStateTag("can_act")) 
			or (self.inst.sg:HasStateTag("grabbing") and self.inst.sg:HasStateTag("handling_opponent")) then
			self:DebugPrint("WE'RE IN THE STATE WE NEED TO BE! BUT WE DECIDED TO WAIT")
			self.status = SUCCESS		
		
		--WE'RE DONE HERE! CARRY ON
		else
			self:DebugPrint("WE'RE DONE HERE! CARRY ON")
			self.status = FAILED
		end
		
    end
end
