Escapekb = Class(BehaviourNode, function(self, inst, hunterparams, see_dist, safe_dist, fn, runhome)
    BehaviourNode._ctor(self, "Escapekb")
    self.inst = inst

	self.action = 0
	self.method = "defensive"
	self.anchor = TheSim:FindFirstEntityWithTag("anchor") --DST
	self.debugprint = AIDEBUGPRINT
end)

function Escapekb:DebugPrint(output, output2) --STEALING IT AND ADDING MY OWN FLAIR
	if self.debugprint == true then
		print("EscKB: " .. output .. (tostring(output2 or "")))
	end
end

function Escapekb:__tostring()
    -- return string.format("RUNAWAY %f from: %s", self.safe_dist, tostring(self.hunter))
	return string.format("RUNAWAY %f from: %s")
end

function EdgeGaurd:OnStop()
	self.action = 0
end


function Escapekb:Visit()
    
    if self.status == READY then
		-- print("VISITING ESCAPEKB", self.action)
		if self.inst.sg:HasStateTag("inknockback") then -- or (self.inst.components.launchgravity:GetIsAirborn() and not self.inst:HasTag("going_in")) then 
			self:DebugPrint("VISITING ESCAPEKB: ", self.action)
			if self.action >= 10 then
				-- self.status = RUNNING
				-- self.inst:RemoveTag("wantstoblock")
				
				-- self.inst.components.talker:Say("OW! THATS MY HEAD!")
				self:DebugPrint("TIME TO TAKE ACTION!: ", self.inst.components.aifeelings:ConfidencePercent())
				if math.random() < (0.2 + (self.inst.components.aifeelings:ConfidencePercent() / 2)) then  --ADJUSTING THIS GREATLY
					self.inst.components.aifeelings:GetAttackNode().chosenattack = "jumpin"
					self.inst.components.aifeelings:GetAttackNode().chosenside = "highapproach"
					self.method = "agressive"
					self.status = RUNNING --WE CAN'T FAIL IT YET! IF WE'RE GETTING RAPID JABBED, IT'LL JUST HIT US OUT OF IT
					self:DebugPrint("HEY THAT HURT! I'M RETALIATING!!! ATTACK NODE, TAKE OVER WITH THIS ATTACK")
					-- self.inst.components.talker:Say("OW! THATS MY HEAD!")
					
				else
					self:DebugPrint("HEY THAT HURT! GET ME OUTTA HERE")
					self.method = "defensive"
					self.status = RUNNING
				end
			end
			self.action = self.action + 1
		else
			self.status = FAILED
			self.action = math.clamp(self.action - 1, 0, 10) --1-16-22
		end
        
    end

    if self.status == RUNNING then
        
		self.inst:RemoveTag("wantstoblock")
		
		
		local center_stage = self.anchor.components.gamerules.center_stage
		local mypos, myposy = self.inst.Transform:GetWorldPosition()
		local oppx, oppy = self.inst.components.stats.opponent.Transform:GetWorldPosition()
		
		--1-17-22 A MORE CALCULATED APPROACH
		if self.method == "agressive" then
			--HAVE WE JUMPED YET? IF SO, MISSION ACCOMPLISHED. IF NOT, SEE IF WE CAN JUMP
			if self.inst.components.jumper.currentdoublejumps == 0 then
				self.inst:AddTag("going_in") --OKAY NOOOW WE CAN GO_IN
				self.status = FAILED
				return end
			
			if not self.inst.sg:HasStateTag("inknockback") then
				self:DebugPrint("NOWS OUR CHANCE. RUSH THEM!!! ")
				
				self.inst:RemoveTag("holdleft")
				self.inst:RemoveTag("holdright")
				if mypos <= oppx then
					self.inst:AddTag("holdleft")
				elseif mypos >= oppx then
					self.inst:AddTag("holdright")
				end
				self.inst:PushEvent("jump")
				return end
				
			
		elseif self.method == "defensive" then
			-- if self.inst.components.aifeelings:CalculateTrajectory(1, 0.0, -0.5, 2) then
			if self.inst.components.aifeelings:CalculateTrajectory(3, 0.0, 0, 2) then
				if not self.inst.sg:HasStateTag("busy") then
					-- self.inst:AddTag("wantstoblock")
					self.inst:PushEvent("block_key")
					self:DebugPrint("AIRDODGE TO ESCAPE KB!")
				else
					self.inst:PushEvent("jump")
					self:DebugPrint("JUMP TO ESCAPE KB!")
					-- self.inst.sg:GoToState("doublejump")
				end
				
			end
		end
		
		
		
		self.inst:RemoveTag("holdleft")
		self.inst:RemoveTag("holdright")
		
		if mypos <= (center_stage - 7.5) then
			self.inst:AddTag("holdleft")
		elseif mypos >= (center_stage + 7.5) then
			self.inst:AddTag("holdright")
			
		elseif math.abs(mypos - oppx) >= 5 and self.method == "defensive" then --DONT WORRY IF ENEMY IS TOO FAR TO DO ANYTHING
			self.inst:RemoveTag("holdleft")
			self.inst:RemoveTag("holdright")
			self.inst.components.jumper:FastFall()
			
		elseif mypos <= oppx then
			self.inst:AddTag("holdright")
		elseif mypos >= oppx then
			self.inst:AddTag("holdleft")
		else
			self.inst:RemoveTag("holdleft")
			self.inst:RemoveTag("holdright")
		end
		
		
		
		if not self.inst.components.launchgravity:GetIsAirborn() then
			self:DebugPrint("WHEW, WE ESCAPED THE KB")
			self.action = 0 --1-15-22 BECAUSE OTHERWISE I'M PRETTY SURE THIS DOESNT RESET
			self.status = FAILED
		end
		
		
    end
end
