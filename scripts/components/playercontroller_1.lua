require "class"

--I COULD PROBABLY JUST PASTE ALL THE KEYDETECTOR FUNCTIONS IN HERE AND CALL ALL KEY STUFF FROM IT

--1-5-22 AND YOU KNOW WHAT, I WILL. MOVING ALL PLAYERCONTROLLER_1 UTILITY TO KEYDETECTOR AND OBSOLETING THIS COMPONENT.

local PlayerController_1 = Class(function(self, inst)
    self.inst = inst
    self.enabled = true
	self.holdingleft = false
	self.holdingright = false
	self.holdingup = false
	self.holdingdown = false
	self.holdingattack = false
	self.holdingjump = false --6-9-20
	
	-- self.controllerbound = TheInput:ControllerAttached() --1-5-22 WE DON'T EVEN USE THIS VERSION
	
	--I THOUGHT THESE WERE SET ELSEWHERE?? --THEY DEF ARE
	self.attack = KEY_N
	self.special = KEY_M
	self.grab = 44 --KEY_COMMA
	self.jump = KEY_SPACE
	self.block = 306 --LCONTROL  --KEY_LSHIFT --INCOMPATIBLE WHILE NUMPAD IS IN USE OR ESLE RIP PLAYER2
	self.up = KEY_W
	self.down = KEY_S
	self.left = KEY_A
	self.right = KEY_D
	self.cstick_up = KEY_U
	self.cstick_down = KEY_J
	self.cstick_left = KEY_H
	self.cstick_right = KEY_K
	
	
end)




function PlayerController_1:UpdateKeys(inst)
	if not inst.sg:HasStateTag("busy") then
		if not inst.sg:HasStateTag("no_running") and not inst.components.launchgravity:GetIsAirborn() then  --11-16
			local xwalk = 0
			local ywalk = 0
			local ang = nil
			
			if inst.components.keydetector:GetLeft(inst) then
				xwalk = xwalk - 1
				ang = 0
			end
	        
			if inst.components.keydetector:GetRight(inst) then
				xwalk = xwalk + 1
				ang = 180
			end
			
			if xwalk ~= 0 or ywalk ~= 0 then
				inst.components.locomotor:RunInDirection(ang)
				inst.components.locomotor:SetBufferedAction(nil)
				inst:ClearBufferedAction()
			else
				inst.components.locomotor:Stop()
            end
    end
	end
    
end


--9-9-17 A SPECIAL UPDATER TO CONTROL WALKING FOR CLONES? (LIKE MAXWELL'S)
--1-5-22 WAIT DO WE NOT USE THIS ANYMORE?? I GUESS WE DON'T. HUH.
function PlayerController_1:UpdateSlaveKeys(inst)
	
	local master = inst.components.stats.master
	
	if not master or not master:IsValid() then --MAKE SURE MASTER EXISTS FIRST.
		return end
	
	if not inst.sg:HasStateTag("busy") then
		if not inst.sg:HasStateTag("no_running") and not inst.components.launchgravity:GetIsAirborn() then  --11-16
			local xwalk = 0
			local ywalk = 0
			local ang = nil
			
			if master.components.keydetector:GetLeft(master) then
				xwalk = xwalk - 1
				ang = 0
			end
	        
			if master.components.keydetector:GetRight(master) then
				xwalk = xwalk + 1
				ang = 1
			end
			
			if xwalk ~= 0 or ywalk ~= 0 then
				inst.components.locomotor:RunInDirection(ang)
				inst.components.locomotor:SetBufferedAction(nil)
				inst:ClearBufferedAction()
			else
				inst.components.locomotor:Stop()
            end
		end
	end
    
end


return PlayerController_1
