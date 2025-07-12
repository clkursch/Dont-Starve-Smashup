Search = Class(BehaviourNode, function(self, inst, hunterparams, see_dist, safe_dist, fn, runhome)
    BehaviourNode._ctor(self, "Search")
    self.inst = inst
	self.anchor = TheSim:FindFirstEntityWithTag("anchor")
	self.debugprint = AIDEBUGPRINT
end)

function Search:DebugPrint(output, output2)
	if self.debugprint == true then
		print("Search: " .. output .. (tostring(output2 or "")))
	end
end

function Search:__tostring()
    -- return string.format("RUNAWAY %f from: %s", self.safe_dist, tostring(self.hunter))
	return string.format("RUNAWAY %f from: %s")
end


--FOR SEARCHING FOR TARGETS TO ENGAGE IN GLORIOUS COMBAT

function Search:Visit()
    
    if self.status == READY then

		-- print("THE LIGHTHOUSE", self.inst.components.stats.opponent)
		self:DebugPrint("===VISITING SEARCH===")
		local opponent = self.inst.components.stats.opponent
		if opponent and opponent:IsValid() and opponent.components.stats.alive then
			self.status = FAILED
			
		else 
			local nemisis = self.inst.components.aifeelings:FindNearestEnemy() --2-7-17
			
			if nemisis then --and nemisis ~= self.inst then
				self:DebugPrint("===IV'E FOUND A NEW NEMISIS===", nemisis)
				self.inst.components.stats.opponent = nemisis
				-- nemisis.components.stats.opponent = self.inst --9-6  --!!!!! DIDNT WORK!!!!! DOESNT RECOGNIZE NOT BUSY
				if nemisis.components.stats then --TO FIX A BUG IN CASE OPPONENT IS TEMP AND DOESNT HAVE STATS
					nemisis.components.stats.opponent = self.inst 
				end
				
				self.status = FAILED
			else
				self:DebugPrint("NO VALID NEMISIS FOUND!")
				self.status = SUCCESS
				
				--1-16-22 WE SHOULD TAKE CARE OF THIS FOR THE GETUP NODE THAT WON'T BE RUNNING
				if self.inst.sg:HasStateTag("hanging") then 
					self.inst:PushEvent("forward_key")
				end
			end
			
			 
		end
		
        
    end

    if self.status == RUNNING then
        
		
		local center_stage = self.anchor.components.gamerules.center_stage
		local mypos, myposy = self.inst.Transform:GetWorldPosition()
		
		if mypos <= center_stage then
			-- angle = 0
			self.inst:AddTag("holdleft")
		else
			-- angle = 180
			self.inst:AddTag("holdright")
		end
		
		-- if inst.components.launchgravity and inst.components.launchgravity:GetIsAirborn() then
			-- inst:AddTag("holdleft")
		-- else
			-- inst.components.locomotor:RunInDirection(angle, true) -- 0
		-- end
		
		if myposy <= -2 then
			self.inst:PushEvent("jump")
		end
		
		
    end
end
