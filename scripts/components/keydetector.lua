local KeyDetector = Class(function(self, inst)
    self.inst = inst
    self.onlight = nil
	
	self.attack = KEY_1
	self.special = KEY_1
	self.jump = KEY_1
	self.block = KEY_1
	self.up = KEY_1
	self.down = KEY_1
	self.left = KEY_1
	self.right = KEY_1
	
	self.tapup = false --2-1-22 TO DETERMINE IF THEIR MOST RECENT JUMP INPUT WAS A TAPJUMP INPUT
	
	self.controllerbound = false --self.inst.components.playercontroller and TheInput:ControllerAttached() --4-4-19 THERE. THIS IS THE MORE LOGICAL WAY
	
	--7-22-17 DST CHANGE TO GET ANALOG INPUT FROM USERS
	self.analogright = 0
	self.analogleft = 0
	self.analogup = 0
	self.analogdown = 0
	
	--4-23-20
	self.old_analogup = 0
	
	self.analogup_mem = "deadzone" --1-13-22 TO SEND LESS DATA TO THE HOST
	self.analogdown_mem = "deadzone"
	self.analogleft_mem = "deadzone"
	self.analogright_mem = "deadzone"
	
	--1-5-22 OKAY THESE REALLY BELONG IN HERE. PLAYERCONTROLLER_1 SHOULD BEGONE
	self.holdingleft = false
	self.holdingright = false
	self.holdingup = false
	self.holdingdown = false
	self.holdingattack = false
	self.holdingjump = false --6-9-20
end)


--[[
if target.components.keydetector.analogup >= 0.70 or target.components.keydetector.analogdown >= 0.70 then


]]



--1-5-22 IN FACT, COME HERE. I'M DOING IT RIGHT NOW. MERGING PLAYERCONTROLLER_1
function KeyDetector:OnUpdate(dt)
	self:UpdateKeys(self.inst)
	
	if self.controllerbound then --WE ONLY WANT THIS PART RUNNING FOR CLIENT, RIGHT? I THINK THAT SHOULD WORK, NOW THAT CONTROLLERBOUND IS CLIENT ONLY
		self:UpAnalogCheck()  --1-13-22 THIS VERSION IS OPTIMIZED MUCH BETTER FOR SENDING DATA TO HOST FROM CLIENT
	end
end

function KeyDetector:InitiateKeys(inst)
	inst:StartUpdatingComponent(self)
	-- print("INITIATING KEYS")
	
	if inst == ThePlayer then
		--EVERY 2 (I GUESS?) SECONDS, CHECK AGAIN FOR IF WE'RE USING A CONTROLLER 
		inst:DoPeriodicTask(2, function()   
			self.controllerbound = TheInput:ControllerAttached()
		end)
	end
end

function KeyDetector:UpdateKeys(inst)
	if inst:HasTag("lockcontrols") then 
		inst.components.locomotor:Stop()
		-- print("LOCKED CONTROLS", self.inst)
		return end
	
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
			
			--1-25-22 ADDING AN ANNOYING CHECK TO MAKE SURE WE DON'T HAVE A JUMP BUFFERED, BC THIS WALK CYCLE WILL TURN US AROUND IF WE BUFFERED BACKAIR
			if (inst.components.stats.event == "jump" and inst.components.stats.buffertick >= 1) then
				return end
				
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



--1-12-22 GET UPWARD ANALOG VALUES --THIS SHOULD ONLY BE NEEDED CLIENTSIDE

function KeyDetector:UpAnalogCheck() 
	
	local anlogval = TheInput:GetAnalogControlValue(CONTROL_MOVE_UP)
	self.analogup = anlogval
	local analogstring = nil
	
	if anlogval < 0.3 then --BELOW 0.3 IS THE DEADZONE
		self.old_analogup = anlogval --WE ARENT RUNNING ANY MATH WITH IT SO ITS OK TO SET IT EARLY
		self.holdingup = false
		analogstring = "deadzone" --THIS IS WHAT WILL GET PASSED TO THE HOST IF IT'S DIFFERENT THAN THE LAST KNOWN STRING
	else
		-- DETECT IF THE STICK WAS "FLICKED" QUICKLY.
		local analogdiff = anlogval - self.old_analogup  --DIFFERENCE BETWEEN PREVIOUS VALUE
		local flicked = (analogdiff >= 0.45)
		-- print("WAS I FLICKED?", flicked, analogdiff, anlogval, self.old_analogup)
		self.old_analogup = anlogval
		self.holdingup = true
		
		if not flicked then
			analogstring = "upslight"
		elseif flicked then --IF IT'S HELD ALL THE WAY UP
			analogstring = "upflick"
		end
	end
	
	--SO WE DON'T OVERWHELM THE SERVER, ONLY UPDATE THE VALUE IF IT'S DIFFERENT THAN THE CURRENT ONE
	if analogstring ~= self.analogup_mem then
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["upanalogreceiver"], analogstring) --1-13-22 SEND THESE TO THE SERVER.
		self.analogup_mem = analogstring
	end
	
end



--1-14-22 SOMETHING SIMILAR FOR DOWN, BUT USED A BIT DIFFERENTLY
--[[ BUT WE CAN'T REFERENCE THIS EASILY WITHOUT PULLING FROM THEPLAYER AND I HATE THAT. SO LETS MOVE IT TO FIGHTER_KEYHANDLERS
function KeyDetector:DownAnalogCheck(dir) 
	local anlogval = TheInput:GetAnalogControlValue(CONTROL_MOVE_DOWN)
	local analogstring = nil
	
	if self.analogdown_mem < 0.3 then --BELOW 0.3 IS THE DEADZONE
		self.holdingdown = false
		analogstring = "deadzone"
	else
		self.holdingdown = true
		analogstring = "active"
	end
	
	--SO WE DON'T OVERWHELM THE SERVER, ONLY UPDATE THE VALUE IF IT'S DIFFERENT THAN THE CURRENT ONE
	if analogstring ~= self.analogdown_mem then
		anlogval = TheInput:GetAnalogControlValue(CONTROL_MOVE_DOWN)
		self.analogdown_mem = analogstring
	end
end
]]



--7-23-17 DST CHANGE -NEW METHODS OF OBTAINING ANALOG CONTROL VALUES
function KeyDetector:GetAnalogRight(target)
    -- local xdir = TheInput:GetAnalogControlValue(CONTROL_MOVE_RIGHT) - TheInput:GetAnalogControlValue(CONTROL_MOVE_LEFT)
    -- local ydir = TheInput:GetAnalogControlValue(CONTROL_MOVE_UP) - TheInput:GetAnalogControlValue(CONTROL_MOVE_DOWN)
	-- print("OBEY YOUR GOAT OVERLORD", TheInput:GetAnalogControlValue(CONTROL_MOVE_RIGHT))
	-- return TheInput:GetAnalogControlValue(CONTROL_MOVE_RIGHT)
	return target.components.keydetector.analogright --THERE WE GO c:
end

function KeyDetector:GetAnalogLeft(target)
	return target.components.keydetector.analogleft
end
function KeyDetector:GetAnalogUp(target)
	return target.components.keydetector.analogup
end

function KeyDetector:GetAnalogDown(target)
	return target.components.keydetector.analogdown
end


--8-27 NEW FUNCTION FOR THE INCLUSION OF CONTROLLERS!!!
--[[ 1-13-22 SEEMINGLY UNUSED
function KeyDetector:CheckKey(key)
	if self.controllerbound == true then
		if TheInput:IsControlPressed(key) then
			return true
		else
			return false
		end
	else
		return true
	end
end
]]


--4-5
function KeyDetector:GetBufferKey(target1)
	
	local target = target1
	--DST-9-9-17 FOR KEY SHARING ENTITIES LIKE MAXWELL'S CLONE
	if target.components.stats.master and target.components.stats.master:IsValid() then --9-9-17 FOR MAXCLONES
		target = target.components.stats.master --IF A MASTER EXISTS, CHECK HIS VALUES INSTEAD OF OURS
	end

	if self:GetUp(target) and self:GetForward(target) then --11-7-16 ADDING A CHECK FOR DIAGONALS
		return "diagonalf"
	elseif self:GetUp(target) and self:GetBackward(target) then --DST!!! ADDING TARGET PARAMS INTO EVERYTHING TO SPECIFY WHICH PLAYER WE ARE CHECKING
		return "diagonalb"
	elseif self:GetUp(target) then
		return "up"
	elseif self:GetDown(target) then
		return "down"
	elseif self:GetForward(target) then
		return "forward"
	elseif self:GetBackward(target) then
		return "backward"
	elseif self:GetBlock(target) then
		return "block"
		
	else
		return "neutral"
	end

end


function KeyDetector:GetJump(target)
	--DST CHANGE!!!!- HAVE TO REPLACE THE JUMP DETECTOR WITH THIS   --6-9-20 ADDED TAPJUMP RECOGNITION  --MAN I COULDVE SAVED A LOT OF CLUTTER IF I JUST CHECKED IT ALL FROM HERE
	-- if self.inst:HasTag("jump_key_dwn") or (self.inst.components.stats.tapjump and self:GetUp(target)) then 
	--1-14-22 FINE, I GUESS THERE IS A REASON FOR THE JUMP_KEY_DWN TAG
	if target:HasTag("jump_key_dwn") or (target.components.stats.tapjump and self:GetUp(target)) then --1-14-22 THIS SHOULD REALLY USE HOLDINGJUMP
		return true
	else
		return false
	end

end


function KeyDetector:GetUp(target)
	if target and target.components.keydetector.holdingup then --DST- CHANGING ALL "SELF.INSTS" TO "TARGET"
		return true
	else
		return false
	end
end

--4-23-20 SO FOR CONTROLLERS, WE NEED TO DIFFERENTIATE BETWEEN UP-TILTS AND FULL-UP ON THE STICK FOR JUMPING. THIS SHOULD HELP
--[[ 1-13-22 CURRENTLY UNUSED
function KeyDetector:GetUpTilt(target)
	-- print("ARE WE TILTING?", self:VerticalJoystickStretch(target), target.components.keydetector.analogup)
	if target and target.components.keydetector.holdingup and self:VerticalJoystickStretch(target) then
		return true
	else
		return false
	end
end
]]

--7-17-17 SPECIFICALLY FOR ROLL BUFFERING  --DSEDIT 7-19-17
function KeyDetector:GetLeftRight(target)
	-- if self:CheckKey(self.left) or TheInput:GetAnalogControlValue(self.left) >= 0.2 then
	-- print("SO AM I LEFT OR WHAT?", target.components.keydetector.holdingleft)
	if self:GetLeft(target) then --WHY ISNT THIS WORKING?????
		return "left"
	elseif self:GetRight(target) then--self:CheckKey(self.right) or TheInput:GetAnalogControlValue(self.right) >= 0.2 then
		return "right"
	else
		return "none"
	end
end

--7-17-17 AT SOME POINT I MIGHT MAKE A VERSION OF GETLEFTRIGHT THAT RETURNS THE LAST PRESSED KEY FOR QUICKROLLS BUT FOR NOW IM LEAVING IT OUT. 


function KeyDetector:GetLeft(target)
	if target.components.keydetector.holdingleft then --self:CheckKey(self.left) or TheInput:GetAnalogControlValue(self.left) >= 0.2 then
		return true
	else
		return false
	end
end

function KeyDetector:GetRight(target)
	if target.components.keydetector.holdingright then
		return true
	else
		return false
	end
end

function KeyDetector:GetDown(target)
	if target.components.keydetector.holdingdown then
		return true
	else
		return false
	end
end

function KeyDetector:GetAttack(target)
	if target.components.keydetector.holdingattack then
		return true
	else
		return false
	end
end

function KeyDetector:GetSpecial(target)
	if target:HasTag("spc_key_dwn") then
		return true
	else
		return false
	end
end

function KeyDetector:GetBlock(target)
	if target:HasTag("wantstoblock") then
		return true
	else
		return false
	end
end


function KeyDetector:GetDTilt(target) --WHY ON EARTH IS THIS STILL HERE???
	if self:CheckKey(258) then
		print("DTILT")
		return true
	else
		return false
	end
end


--1-14-22 BRINGING THIS BACK, GONNA TRY AND TURN IT INTO A CLIENT-ONLY FUNCTION TO OPTIMIZE CONTROLLER RPCS
--NOT YET.... SOON --DSEDIT
--7-18-17 SOMETHING TO HELP PLAYERS USE UP/DOWN TILTS/SPECIALS WITHOUT ACCIDENTALLY TURNING AROUND TOO EASILY
--1-13-22 SEEMS TO BE UNUSED AT THE MOMENT. BUT MAYBE WE HAD PLANS TO IMPLIMENT IT AT SOME POINT?
function KeyDetector:VerticalJoystickStretch(target)
	-- print("VERTICAL JOYSTICK STRETCH", TheInput:GetAnalogControlValue(self.up), TheInput:GetAnalogControlValue(self.down))
	-- print("HORIZONTAL JOYSTICK", TheInput:GetAnalogControlValue(self.left), TheInput:GetAnalogControlValue(self.right))
	
	-- if TheInput:GetAnalogControlValue(self.up) >= 0.70 or TheInput:GetAnalogControlValue(self.down) >= 0.70 then
	if target.components.keydetector.analogup >= 0.70 or target.components.keydetector.analogdown >= 0.70 then --DST CHANGE
	-- if target.components.keydetector.holdingattack then
		-- print("TOO STRETCHY")
		return true
	else
		return false
	end
end



function KeyDetector:GetForward(target)
	local facedir = target.components.launchgravity:GetRotationFunction()
	if facedir == "left" then
		-- if self:CheckKey(self.left) or TheInput:GetAnalogControlValue(self.left) >= 0.2 then   --8-30 ADDING AN ANALOG TEST FOR LIGHT TILTS
		if self:GetLeft(target) then
			return true
		else 
			return false
		end
	elseif facedir == "right" then
		if self:GetRight(target) then 
			return true
		else 
			return false
		end
	end
end

function KeyDetector:GetBackward(target)
	local facedir = target.components.launchgravity:GetRotationFunction()
	if facedir == "left" then
		if self:GetRight(target) then --TODO... THE VERTICAL STRETCH STUFF. YOU KNOW
			return true
		else 
			return false
		end
	elseif facedir == "right" then
		if self:GetLeft(target) then
			return true
		else 
			return false
		end
	end
end


--4-18-20 GET DIRECTIONAL INPUT FROM C-STICK BASED ON FACE DIRECTION
function KeyDetector:GetCStickDirection(target, stickdirection)
	local facedir = target.components.launchgravity:GetRotationFunction()
	if facedir == "left" then
		if stickdirection == "left" then --TODO... THE VERTICAL STRETCH STUFF. YOU KNOW
			return "forward"
		else 
			return "backward"
		end
	elseif facedir == "right" then
		if stickdirection == "left" then --TODO... THE VERTICAL STRETCH STUFF. YOU KNOW
			return "backward"
		else 
			return "forward"
		end
	else 
		return "neutral" --SHOULDN'T BE POSSIBLE BUT YA KNOW, JUST IN CASE
	end
end


--10-22-18 --NEW TEST SPECIFICALLY TO SEE IF PLAYERS SHOULD IGNORE LEDGE GRABS OR NOT
function KeyDetector:HoldingTowardsStage(target)
	--COMPARE THE TARGET'S X POSITION TO THE STAGE'S X POSITION  (WE CAN ASSUME STAGE'S X POSITION IS 0, RIGHT? I THINK)
	local stageposx, stageposy, stageposz = target.Transform:GetWorldPosition() 
	
	if self:GetLeft(target) and stageposx > 0 then
		return true
	elseif self:GetRight(target) and stageposx < 0 then
		return true
	else
		return false
	end
end


--9-30-21 BEEN A WHILE. GUESS KEYBUFFER STUFF IS ALSO GOING IN HERE
--REDESIGNING HOW AUTO-DASH AND CANCELING DASHING WITH THE DOWN KEY WORKS
--RETURNS TRUE IF WE WOULD RATHER WALK THAN RUN
function KeyDetector:CheckWalkImpulse(inst)
	--ITS USUALLY SAFER TO RE-TREAD THE PATH TO THE KEYDETECTOR COMPONENT RATHER THAN TRYING TO REFERENCE ITSELF FROM HERE
	if inst.components.stats.autodash == false or inst.components.keydetector:GetDown(inst) then 
		return true
	else
		return false
	end
end


return KeyDetector