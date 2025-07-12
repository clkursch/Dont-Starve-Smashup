--THIS HANDLES PRETTY MUCH ALL RPC HANDLERS AND NET VARS IN GENERAL, NOT JUST FOR KEYPRESSES

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local require = GLOBAL.require

--THIS MIGHT HELP FOR USING MODNAME OUTSIDE OF MODMAIN
GLOBAL.TUNING.MODNAME = modname



local function applykeyhandlers()

	local function UsingController()
		return GLOBAL.TheInput:ControllerAttached() and not GLOBAL.IsPaused()
	end
	
	local function RunWithKeyCheck(key, fn)
		-- print("RUNWITHKEY RPC", key)
		if key == false then
			fn()
			return true
		-- else
			-- return false
		end
	end
	
	--ROUND 2
	local function RunControlWithCheck(key, cdown, cup, bonusdata)
		if key == false then --IF DOWN, RUN THE KEYDOWNHANDLER
			if UsingController() then 
				if bonusdata then 
					SendModRPCToServer(MOD_RPC[modname][cdown], bonusdata) 
				else 
					SendModRPCToServer(MOD_RPC[modname][cdown]) 
				end
			end
			return true
		else --ELSE, RUN THE KEYUPHANDLER
			if UsingController() then SendModRPCToServer(MOD_RPC[modname][cup]) end
			return false
		end
	end
	
	
	--1-27-22 OKAY... YET ANOTHER ONE
	local function RunControlDown(key, cdown, cup, bonusdata)
		if GLOBAL.TheInput:IsControlPressed(key) == true then --IF DOWN, RUN THE KEYDOWNHANDLER
			if UsingController() then 
				if bonusdata then 
					SendModRPCToServer(MOD_RPC[modname][cdown], bonusdata) 
				else 
					SendModRPCToServer(MOD_RPC[modname][cdown]) 
				end
			end
		else --ELSE, RUN THE KEYUPHANDLER
			if UsingController() then SendModRPCToServer(MOD_RPC[modname][cup]) end
		end
	end
	
	
	--1-14-22 GUESS THIS COULD GO IN HERE INSTEAD OF KEYDETECTOR
	
	local function DownAnalogCheck(key, mem, fn)  --1-14-22 SOMETHING SIMILAR FOR DOWN, BUT USED A BIT DIFFERENTLY
		local anlogval = GLOBAL.TheInput:GetAnalogControlValue(key)
		local analogbool = nil
		-- print("DownAnalogCheck: ", key, mem)
		
		if anlogval < 0.3 then --BELOW 0.3 IS THE DEADZONE
			analogbool = false
		else
			analogbool = true
		end
		
		--SO WE DON'T OVERWHELM THE SERVER, ONLY UPDATE THE VALUE IF IT'S DIFFERENT THAN THE CURRENT ONE
		if analogbool ~= mem then
			fn()
		end
		return analogbool
	end

	
	--4-23-20 OK, GONNA TRY SOMETHING WEIRD. AN... EVERY TICK LISTENER THAT DETERMINES MOVEMENT STICK DIRECTION INSTEAD OF FORCING EVENTHANDLERS TO BE ANALOG > 0.5
	--4-23-20 THIS WILL HOPEFULLY REPLACE THE UPWARD DIRECTIONAL STICK HANDLER
	--1-12-22 NO, IT'S TOTALLY DESTROYING CLIENTSIDE PING WHEN SENDING RPCS EVERY SINGLE FRAME. NEED TO RETHINK THIS
	--[[
	local function upanalogcheck(player, anlogval) 
		--print("UPANALOG DETECTED ", anlogval)
		
		if player:HasTag("lockcontrols") then return end
		if not player.components.keydetector.controllerbound then return end --7-27-17
		
		--6-9-20 NOT ALL THE CLIENTSIDE VALUES ARE BEING PROPERLY REMEMBERED. MOVING SOME OF THE LOGIC IN HERE
		player.components.keydetector.analogup = anlogval
		
		if anlogval < 0.3 then --BELOW 0.3 IS THE DEADZONE
			player.components.keydetector.old_analogup = anlogval --WE ARENT RUNNING ANY MATH WITH IT SO ITS OK TO SET IT EARLY
			player.components.keydetector.holdingup = false
			return end
		
		
		-- DETECT IF THE STICK WAS "FLICKED" QUICKLY.
		local analogdiff = anlogval - player.components.keydetector.old_analogup  --DIFFERENCE BETWEEN PREVIOUS VALUE
		local flicked = (analogdiff >= 0.45)
		-- print("WAS I FLICKED?", flicked, analogdiff, anlogval, player.components.keydetector.old_analogup)
		player.components.keydetector.old_analogup = anlogval
		--IF FLICKED, RUN EVERYTHING. IF NOT, ONLY REGISTER THAT UP IS BEING HELD
		if not flicked then
			player.components.keydetector.holdingup = true
		
		--4-23-20 NOW WE ONLY WANT TO TEST IF IT'S HELD ALL THE WAY UP
		elseif flicked then -- if not player.components.keydetector.holdingup_full
			if not player.components.keydetector.holdingup then
				player:PushEvent("up")
				player:AddTag("listen_for_usmash")
				player:DoTaskInTime((2*GLOBAL.FRAMES), function()
					player:RemoveTag("listen_for_usmash")
				end)
				-- player.components.keydetector.gotup = true --TAPJUMP DOESNT NEED TO APPLY THIS. FULLHOP DETECTOR LOOKS FOR TAPJUMP+HOLDINGUP
			end
			player.components.keydetector.holdingup = true
			
			--6-9-20 GUESS WHAT! NOW WE NEED TAPJUMP STUFF  --COMPLETE DUPLICATE OF THE CONTROLLER JUMP FN. MAKE SURE CHANGES ARE MADE IN BOTH PLACES (BAD PRACTICE I KNOW)
			if player.components.stats.tapjump and player.components.jumper.currentdoublejumps > 0 then
				-- if not player:HasTag("jump_key_dwn") then --DONT GOTTA WORRY ABOUT THIS HERE. TESTING FOR FLICK ENSURES THIS WONT RUN MULTIPLE TIMES
					--4-23-20 IF THE JUMP BUTTON IS PRESSED AFTER ATTACK, IT CAN EAT THE ATTACK INPUT
					player:PushEvent("jump")
					if player.sg:HasStateTag("listen_for_atk") then
						player.components.stats:SetKeyBuffer("jump", player.components.stats.key) --4-24-20
					else
						player.components.stats:SetKeyBuffer("jump", "ITSNIL") --4-18-20 WE DONT USE THAT PART OF THE BUFFER
					end
					-- player:AddTag("jump_key_dwn") --DST CHANGE, MOVING THIS INTO PART OF THE CHECK
					--4-23-20 EXTRA BAGGAGE
					player.sg:AddStateTag("listen_for_jump")
					player:DoTaskInTime(0, function() 
						player.sg:RemoveStateTag("listen_for_jump")
					end)
				-- end
			end

		else
			player.components.keydetector.holdingup = false
		end
	end
	AddModRPCHandler(modname, "upanalogchecker", upanalogcheck)
	]]
	
	
	--UP
	--[[
	local function up1(player, aup)
	if player:HasTag("lockcontrols") then return end
	if not player.components.keydetector.controllerbound then return end --7-27-17
	player.components.keydetector.analogup = aup --7-23-17 
	-- if GLOBAL.TheInput:IsControlPressed(up) then
	if not player.components.keydetector.holdingup and player.components.keydetector:GetUpTilt(player) then --YES I KNOW ITS HERE TWICE. LAZY, THATS WHY
		
		--4-23-20 I WONDER IF THERES ENOUGH DELAY FROM THERE TO HERE TO REGISTER CHANGES IN Y ANALOGUE VALUE --NOPE
		-- if  player.components.keydetector:VerticalJoystickStretch(player) then 
			-- print("HOW ABOUT NOW? ", GLOBAL.TheInput:GetAnalogControlValue(up))
			-- return end
			
		if not player.components.keydetector.holdingup then
			player:PushEvent("up")
			player:AddTag("listen_for_usmash")
			player:DoTaskInTime((2*GLOBAL.FRAMES), function()
				player:RemoveTag("listen_for_usmash")
			end)
			player.components.keydetector.gotup = true --DST TRY-
		end
		-- holdingup = true --DST CHANGE-- USING THE ONE BELOW INSTEAD OF THIS ONE
		player.components.keydetector.holdingup = true  --DST CHANGE-- THIS ONE WORKS!!!
		else
			-- holdingup = false
			player.components.keydetector.holdingup = false
		end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "up1erc", up1)
	GLOBAL.TheInput:AddControlHandler(up, function() SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["up1erc"], GLOBAL.TheInput:GetAnalogControlValue(up)) end)
	]]
	
	
	--1-13-22 OKAY, LET'S RECREATE THIS AS A SIMPLE RPC HANDLER THAT JUST LISTENS FOR THE EVENTS AND APPLY THE VALUES
	local function upanalogreceiver(player, anlogstring) 
		--print("UPANALOG DETECTED ", anlogval)
		if player:HasTag("lockcontrols") then return end
		
		--6-9-20 NOT ALL THE CLIENTSIDE VALUES ARE BEING PROPERLY REMEMBERED. MOVING SOME OF THE LOGIC IN HERE
		-- player.components.keydetector.analogup = anlogval --ONLY THE CLIENT SHOULD NEED TO KEEP TRACK OF THIS
		
		--if anlogval < 0.3 then --BELOW 0.3 IS THE DEADZONE
		if anlogstring == "deadzone" then
			player.components.keydetector.holdingup = false
			return end
		
		
		-- if not flicked then
		if anlogstring == "upslight" then
			player.components.keydetector.holdingup = true
		
		--4-23-20 NOW WE ONLY WANT TO TEST IF IT'S HELD ALL THE WAY UP
		-- elseif flicked then
		elseif anlogstring == "upflick" then
			if not player.components.keydetector.holdingup then
				player:PushEvent("up")
				player:AddTag("listen_for_usmash")
				player:DoTaskInTime((2*GLOBAL.FRAMES), function()
					player:RemoveTag("listen_for_usmash")
				end)
				-- player.components.keydetector.gotup = true --TAPJUMP DOESNT NEED TO APPLY THIS. FULLHOP DETECTOR LOOKS FOR TAPJUMP+HOLDINGUP
			end
			player.components.keydetector.holdingup = true
			
			--6-9-20 GUESS WHAT! NOW WE NEED TAPJUMP STUFF  --COMPLETE DUPLICATE OF THE CONTROLLER JUMP FN. MAKE SURE CHANGES ARE MADE IN BOTH PLACES (BAD PRACTICE I KNOW)
			if player.components.stats.tapjump and player.components.jumper.currentdoublejumps > 0 then
				--4-23-20 IF THE JUMP BUTTON IS PRESSED AFTER ATTACK, IT CAN EAT THE ATTACK INPUT
				player:PushEvent("jump")
				if player.sg:HasStateTag("listen_for_atk") then
					player.components.stats:SetKeyBuffer("jump", player.components.stats.key) --4-24-20
				else
					player.components.stats:SetKeyBuffer("jump", "ITSNIL") --4-18-20 WE DONT USE THAT PART OF THE BUFFER
				end
				player.sg:AddStateTag("listen_for_jump")
				player:DoTaskInTime(0, function() 
					player.sg:RemoveStateTag("listen_for_jump")
				end)
			end

		else
			player.components.keydetector.holdingup = false
		end
		
		
	end
	AddModRPCHandler(modname, "upanalogreceiver", upanalogreceiver)
	
	
	
	--[[
	--MAKE THIS SO ONLY THIS RUNS IF A CONTROLLER IS ATTACHED, AND ONLY BELOW IF IT ISNT
	-- if GLOBAL.TheInput:ControllerAttached() then
	-- self.controllerbound = true
	
	-- --USB VERSION
	local attackc = GLOBAL.CONTROL_CONTROLLER_ACTION --A
	local specialc = GLOBAL.CONTROL_CONTROLLER_ALTACTION
	
	-- --WIIU PRO GLOBAL.CONTROLLER VERSION
	-- attack = GLOBAL.CONTROL_GLOBAL.CONTROLLER_ACTION  --A
	-- special = GLOBAL.CONTROL_GLOBAL.CONTROLLER_ALTACTION
	--9-1-21 WAIT DIDN'T WE FORGET TO DEFINE THESE ASE LOCALS?... HOW IS THIS NOT BREAKING?...
	local grab = GLOBAL.CONTROL_ROTATE_RIGHT --RIGHT TRIGGER
	local grab_alt = GLOBAL.CONTROL_ROTATE_LEFT
	local jump = GLOBAL.CONTROL_USE_ITEM_ON_ITEM  --X -DEFAULT
	local jump_alt = GLOBAL.KEY_1
	local block = GLOBAL.CONTROL_MAP_ZOOM_IN --L TRIGGER  --IT APPEARS HAVING THIS SET AS THE SAME KEY THAT OPENS CRAFTING MAKES BIG PROBLEMS. SET CRAFTING TO A DIFFERENT BUTTON TO FIX IT
	local block_alt = GLOBAL.CONTROL_MAP_ZOOM_OUT --R TRIGGER
	local up = GLOBAL.CONTROL_MOVE_UP
	local down = GLOBAL.CONTROL_MOVE_DOWN
	local leftc = GLOBAL.CONTROL_MOVE_LEFT
	local rightc = GLOBAL.CONTROL_MOVE_RIGHT
	local cstick_up = GLOBAL.CONTROL_INVENTORY_UP
	local cstick_down = GLOBAL.CONTROL_INVENTORY_DOWN
	local cstick_left = GLOBAL.CONTROL_INVENTORY_LEFT
	local cstick_right = GLOBAL.CONTROL_INVENTORY_RIGHT
	-- --GLOBAL.CONTROL_ROTATE_LEFT --LB
	local smash = GLOBAL. CONTROL_CONTROLLER_ATTACK --.CONTROL_INVENTORY_DROP --DPAD-DOWN
	--9-1-21 AND EVENTUALLY WE'LL MAKE THIS SOME SORT OF "NOT-BOUND" DEFAULT WITH "CONTROL_OPEN_DEBUG_MENU"
	
	
	--11-25-20 EXTERNAL CUSTOM CONTROLS FOR CONTROLLERS
	if GLOBAL.MODCONTROLS == true then
		attackc = GLOBAL.SMASHCONTROLS.CTL_ATTACK
		specialc = GLOBAL.SMASHCONTROLS.CTL_SPECIAL
		smash = GLOBAL.SMASHCONTROLS.CTL_SMASH
		grab = GLOBAL.SMASHCONTROLS.CTL_GRAB
		jump =  GLOBAL.SMASHCONTROLS.CTL_JUMP
		block = GLOBAL.SMASHCONTROLS.CTL_BLOCK
		grab_alt = GLOBAL.SMASHCONTROLS.CTL_GRAB_ALT
		jump_alt =  GLOBAL.SMASHCONTROLS.CTL_JUMP_ALT
		block_alt = GLOBAL.SMASHCONTROLS.CTL_BLOCK_ALT
		--AS MUCH AS I'D LIKE TO LET PLAYERS REASSIGN MOVEMENT CONTROLS TO SOMETHING LIKE DPAD, OUR ANALOG CHECKERS WILL WIG OUT IF ITS SET TO SOMETING THATS NOT A STICK
	end
	
	
	--1-14-22
	local analogupdwn = false
	local analogdowndwn = false
	local analogleftdwn = false
	local analogrightdwn = false
	
	
	--10-8-17 -ADDING A CHECK FOR "ISPAUSED" SO THAT PEOPLE DONT KEEP JUMPING AROUND WHILE 
	
	local function jump1(player)
	if player:HasTag("lockcontrols") then return end
	-- if not player.components.keydetector.controllerbound then return end --7-27-17
	--7-22-17 OH HOLD UP....SERVER CANT DETECT "ISCONTROLLPRESSED" FOR INDIVIDUAL CLIENTS. THIS COULD BE A PROBLEM	
	-- if GLOBAL.TheInput:IsControlPressed(jump) then 
		-- if not player:HasTag("jump_key_dwn") then --6-9-20 TAPJUMP ALSO USES THIS. LETS USE THE KEYDETECTOR VERSION INSTEAD
		if not player.components.keydetector.holdingjump == true then --6-9-20
			--4-23-20 IF THE JUMP BUTTON IS PRESSED AFTER ATTACK, IT CAN EAT THE ATTACK INPUT
			-- print("JUMP BUTTON")
			player:PushEvent("jump")
			if player.sg:HasStateTag("listen_for_atk") then
				-- print("---- FORCE RE-JUMP ----", player.components.stats.key)
				-- player.components.stats:SetKeyBuffer("jump", player.components.keydetector:GetBufferKey(player)) --ACTUALLY, KEEP THE KEY BUFFER THE SAME, THE ATTACKS WILL SET THOSE
				player.components.stats:SetKeyBuffer("jump", player.components.stats.key) --4-24-20
			else
				--player.components.stats:SetKeyBuffer("jump", player.components.keydetector:GetBufferKey(player))
				player.components.stats:SetKeyBuffer("jump", "ITSNIL") --4-18-20 WE DONT USE THAT PART OF THE BUFFER
			end
			player:AddTag("jump_key_dwn") --DST CHANGE, MOVING THIS INTO PART OF THE CHECK
			player.components.keydetector.holdingjump = true
			--4-23-20 EXTRA BAGGAGE
			player.sg:AddStateTag("listen_for_jump")
			player:DoTaskInTime(0, function() 
				player.sg:RemoveStateTag("listen_for_jump")
			end)
			
		else --DST CHANGE 7-22-17 -REDOING THE WAY THESE CONTROLLER BUTTONS ARE HANDLED
			player:RemoveTag("jump_key_dwn") --THIS TAG IS USED FOR JUMP RELATED THINGS IN CODE, AND IS TRIGGERED BY BOTH JUMP AND TAPJUMP KEYS
			player.components.keydetector.holdingjump = false  --THIS REFERS ONLY TO THE JUMP KEY, SO THAT JUMPS CAN STILL HAPPEN IF UP IS PRESSED WITH TAPJUMP AND JUMP IS PRESSED
		end
	end
	
	AddModRPCHandler(modname, "jump1erc", jump1)
	GLOBAL.TheInput:AddControlHandler(jump, function() if UsingController() then SendModRPCToServer(MOD_RPC[modname]["jump1erc"]) end end)
	GLOBAL.TheInput:AddControlHandler(jump_alt, function() if UsingController() then SendModRPCToServer(MOD_RPC[modname]["jump1erc"]) end end)
	
		
		--BLOCK
	local function block1(player)
	if player:HasTag("lockcontrols") then return end
	if not player:HasTag("wantstoblock") then --7-22-17 LOL THIS FEELS LIKE KIND OF A DUMB FIX BUT I GUESS IT'S THE BEST WAY TO FIX IT
		player:PushEvent("block_key")
		
		if not player:HasTag("trytech_window") then
			player:AddTag("trytech")
			player:AddTag("trytech_window")
			player:DoTaskInTime(0.4, function() --1-19-17 CHANGING BOTH FROM 0.3 TO 0.4 TO ACCOUNT FOR DELAYED LANDING  
				player:RemoveTag("trytech")		--9-20-17 I FIXED DELAYED LANDING, SHOULDNT I PUT THIS BACK NOW? --NAH
				player:DoTaskInTime(0.4, function()
					player:RemoveTag("trytech_window")
				end)
			end)
		end
		
		if player.sg:HasStateTag("can_ood") then
			player.sg:GoToState("block_startup")
			player:AddTag("wasrunning")
		end
		
		if player.sg:HasStateTag("must_roll") then
			player.sg:GoToState("roll_forward")
		end
		
		--7-17-17 AN EARLY LISTENER FOR ROLLS 
		-- if player:HasTag("listen_for_roll") or player:HasTag("must_roll") then --8--11-orsomething-  ACTUALLY, NAH. FORGET THAT. NO BOUNDARIES.
		-- if player.components.keydetector:GetLeftRight(player) ~= "none" then
		if player:HasTag("listen_for_roll") then --8-14-17 LETS REALLY TIGHTEN SOME SCREWS
			player:PushEvent("roll", {key = player.components.keydetector:GetLeftRight(player)}) --DONT FORGET TO PASS PLAYER INTO THE KEYDETECTOR FN!
			player.components.stats:SetKeyBuffer("roll", player.components.keydetector:GetLeftRight(player))
		end
		
		player:AddTag("wantstoblock")
		
	else 
		player:RemoveTag("wantstoblock")
	end
	end
	
	AddModRPCHandler(modname, "block1erc", block1)
	GLOBAL.TheInput:AddControlHandler(block, function() if UsingController() then SendModRPCToServer(MOD_RPC[modname]["block1erc"]) end end)
	GLOBAL.TheInput:AddControlHandler(block_alt, function() if UsingController() then SendModRPCToServer(MOD_RPC[modname]["block1erc"]) end end)
	
	
	
	
	--ATTACK
	local function attack1(player, forcesmash)
	if player:HasTag("lockcontrols") then return end
	-- print("CONTROLLER ATTACK BTN", player.components.keydetector.controllerbound)
	-- if not player.components.keydetector.controllerbound then return end --7-27-17
	-- if GLOBAL.TheInput:IsControlPressed(attackc) then
	if not player.components.keydetector.holdingattack then --LOL
		if not player.components.keydetector.holdingattack then --THE HELD BUTTON TESTER ISNT ON THE CONTROLLER YET
		-- print("SHWING", player, player.components.keydetector:GetBufferKey(player), player.components.keydetector:GetUp())
		-- print("SHWING", player, player.components.keydetector:GetUp(player), self.holdingup, player.components.keydetector.holdingup) --TRUE ALSE TRUE (WITH NEUTRAL)
		player:PushEvent("attack_key")
		player:AddTag("atk_key_dwn")
		
		--4-23-20 HAVE 1 FRAME LISTENERS ON BOTH THE ATK AND JUMP KEY. IF EITHER KEYHANDLER DETECTS THE OTHER WAS JUST PRESSED, CANCEL WHATEVER TO BUFFER A JUMP AIREAL
		player.sg:AddStateTag("listen_for_atk")
		player:DoTaskInTime(0, function() --IT'S SAFER TO DO THIS AS A STATETAG SO THAT IF USERS ARE HIT OUT OF IT, IT WILL REMOVE ITSELF
			player.sg:RemoveStateTag("listen_for_atk")
		end)
		
		local tapsmash = player.components.stats.tapsmash --11-29-21
		
		--IN THAT ONE FRAME WINDOW, IF THE JUMP KEY IS PRESSED, WE'LL CANCEL THE ATTACK AND SET IT TO A JUMP WITH BUFFERED ATTACK INSTEAD
		if player.sg:HasStateTag("listen_for_jump") then
			--11-10-20 IF THEY HAVE TAPJUMP ENABLED, AND THEY BUFFERED THE UP KEY, WE SHOULD ASSUME THIS WAS MEANT TO BE AN UPSMASH
			if player.components.stats.tapjump and player.components.keydetector:GetBufferKey(player) == "up" and  player:HasTag("listen_for_usmash") then
				if tapsmash then
					player:PushEvent("cstick_up")
					player.components.stats:SetKeyBuffer("cstick_up")
				else --11-29-21 UNLESS THEY HAVE TAPSMASH DISABLED. THEN ASSUME UPTILT (ATTACK AS NORMAL)
					player:PushEvent("throwattack", {key = player.components.keydetector:GetBufferKey(player)})
					player.components.stats:SetKeyBuffer("throwattack", player.components.keydetector:GetBufferKey(player))
				end
			else
				-- print("---- FORCE RE-JUMP from atk----", player.components.keydetector:GetBufferKey(player))
				player.components.stats:SetKeyBuffer("jump", player.components.keydetector:GetBufferKey(player))
			end

		--4-18-20 TESTING NEW BUFFERABLE JUMP-AIRIALS (IF CURRENT BUFFERKEY = JUMP, DONT OVERWRITE IT, BUT ADD A KEY TO IT TO BUFFER AIRIAL)
		elseif player.components.stats.event == "jump" and player.components.stats.buffertick >= 1 then
			--ACTUALLY NO DON'T REFRESH IT, JUST ADD THE ATTACK KEY. OTHERWISE MASHING ATTACK COULD EXTEND THE BUFFER A TON
			player.components.stats.key = player.components.keydetector:GetBufferKey(player)
		
		
		elseif (forcesmash and player.components.keydetector:GetUp(player)) or (player:HasTag("listen_for_usmash") and tapsmash) then
			player:PushEvent("cstick_up")
			player.components.stats:SetKeyBuffer("cstick_up")
		elseif (forcesmash and player.components.keydetector:GetDown(player)) or (player:HasTag("listen_for_dsmash") and tapsmash) then
			player:PushEvent("cstick_down")
			player.components.stats:SetKeyBuffer("cstick_down")
		elseif forcesmash or (player:HasTag("listen_for_smash") and tapsmash) then --or player.sg:HasStateTag("must_fsmash") then
			-- player:PushEvent("cstick_forward")
			-- player.components.stats:SetKeyBuffer("cstick_forward", {key = player.components.keydetector:GetLeftRight(player)}) --7-17-17
			player:PushEvent("cstick_side", {key = player.components.keydetector:GetLeftRight(player)}) --7-20-17 THIS WILL MAKE DIRECTIONAL C-STICK BUFFERING SO MUCH EASIER
			player.components.stats:SetKeyBuffer("cstick_side", player.components.keydetector:GetLeftRight(player)) --7-17-17
		
		else
			player:PushEvent("throwattack", {key = player.components.keydetector:GetBufferKey(player)}) --3-19-17 THE DST VERSION
			player.components.stats:SetKeyBuffer("throwattack", player.components.keydetector:GetBufferKey(player))
		end
		end
		player.components.keydetector.holdingattack = true
	else
		player:RemoveTag("atk_key_dwn") 
		if player.sg:HasStateTag("chargingfsmash") then
			-- player:DoTaskInTime(0.1, function() --NO WHY WOULD I DO THIS???
				-- player.sg:GoToState("fsmash")
			-- end)
			player.sg:GoToState("fsmash")
		elseif player.sg:HasStateTag("chargingdsmash") then
			player.sg:GoToState("dsmash")
		elseif player.sg:HasStateTag("chargingusmash") then
			player.sg:GoToState("usmash")
		elseif player.sg:HasStateTag("chargingmisc") then --THIS IS AN EXTRA ATTACK-BUTTON-UP HANDLER JUST FOR MODDERS <3  --6-11-17 WAIT WHEN DID I MAKE THIS? HOW DOES IT WORK???
			player.sg:GoToState("misc")
		end
		player.components.keydetector.holdingattack = false
	end
	end
	
	AddModRPCHandler(modname, "attack1erc", attack1)
	GLOBAL.TheInput:AddControlHandler(attackc, function() if UsingController() then SendModRPCToServer(MOD_RPC[modname]["attack1erc"]) end end)
	
	--9-1-21 A VERSION FOR SMASH ATTACKS. RUNS THE SAME FUNCTION AS THE ATTACK BUTTON BUT WITH AN EXTRA BOOL PASSED IN
	AddModRPCHandler(modname, "smash1erc", attack1)
	GLOBAL.TheInput:AddControlHandler(smash, function() if UsingController() then SendModRPCToServer(MOD_RPC[modname]["smash1erc"], true) end end)
	
	
	--9-10 FOR GRABBING
	local function grab1(player)
	if player:HasTag("lockcontrols") then return end
	-- if GLOBAL.TheInput:IsControlPressed(grab) then --7-22-17 I GUESS GRAB BUTTON HAS NEVER NEEDED TO HAVE A RELEASE CHECK ANYWAYS?... SURE, LETS LEAVE IT LIKE THIS
		if not player.components.keydetector.holdinggrab then
			player:PushEvent("throwattack", {key = "block"})
			-- player.components.stats:SetKeyBuffer("jump", player.components.keydetector:GetBufferKey(player)) --9-10 TODOLIST THE FIX LIST --MAKE GRABS BUFFERABLE
		end
		player.components.keydetector.holdinggrab = true
	-- else
		player.components.keydetector.holdinggrab = false
	-- end
	end
	
	AddModRPCHandler(modname, "grab1erc", grab1)
	GLOBAL.TheInput:AddControlHandler(grab, function() if UsingController() then SendModRPCToServer(MOD_RPC[modname]["grab1erc"]) end end)
	GLOBAL.TheInput:AddControlHandler(grab_alt, function() if UsingController() then SendModRPCToServer(MOD_RPC[modname]["grab1erc"]) end end)




	--CSTICK UP
	local function cup1(player)
	if player:HasTag("lockcontrols") then return end
	-- if GLOBAL.TheInput:IsControlPressed(cstick_up) then
	if not player:HasTag("holdingcup") then --7-22-17 DST CHANGE I GUESS IM JUST ADDING SPECIFIC TAGS FOR CSTICK CHECKS
		player:AddTag("atk_key_dwn")
		player:PushEvent("cstick_up")
		player:PushEvent("attack_key")
		--4-23-20 HAVE 1 FRAME LISTENERS ON BOTH THE ATK AND JUMP KEY. IF EITHER KEYHANDLER DETECTS THE OTHER WAS JUST PRESSED, CANCEL WHATEVER TO BUFFER A JUMP AIREAL
		player.sg:AddStateTag("listen_for_atk")
		player:DoTaskInTime(0, function() --IT'S SAFER TO DO THIS AS A STATETAG SO THAT IF USERS ARE HIT OUT OF IT, IT WILL REMOVE ITSELF
			player.sg:RemoveStateTag("listen_for_atk")
		end)
		if player.components.stats.event == "jump" and player.components.stats.buffertick >= 1 then --4-18-20 FOR JUMP-BUFFERED AIREALS
			player.components.stats.key = "up" --IN CASE JUMP IS BUFFERING
		else
			player.components.stats:SetKeyBuffer("cstick_up")
		end
		player:AddTag("holdingcup") 
		-- TheWorld.components.ambientlighting:CycleBlue()  -----0000000000000
	else
		player:RemoveTag("atk_key_dwn")
		if player.sg:HasStateTag("chargingusmash") then
			player.sg:GoToState("usmash")
		end
		player:RemoveTag("holdingcup")
	end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "cup1erc", cup1)
	GLOBAL.TheInput:AddControlHandler(cstick_up, function() if UsingController() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cup1erc"]) end end)
	
	

	--CSTICK DOWN
	local function cdown1(player)
	if player:HasTag("lockcontrols") then return end
	-- if GLOBAL.TheInput:IsControlPressed(cstick_down) then
	if not player:HasTag("holdingcdown") then
		player:AddTag("atk_key_dwn")
		player:PushEvent("cstick_down")
		player:PushEvent("attack_key")
		
		--4-23-20 HAVE 1 FRAME LISTENERS ON BOTH THE ATK AND JUMP KEY. IF EITHER KEYHANDLER DETECTS THE OTHER WAS JUST PRESSED, CANCEL WHATEVER TO BUFFER A JUMP AIREAL
		player.sg:AddStateTag("listen_for_atk")
		player:DoTaskInTime(0, function() --IT'S SAFER TO DO THIS AS A STATETAG SO THAT IF USERS ARE HIT OUT OF IT, IT WILL REMOVE ITSELF
			player.sg:RemoveStateTag("listen_for_atk")
		end)
		if player.components.stats.event == "jump" and player.components.stats.buffertick >= 1 then --4-18-20 FOR JUMP-BUFFERED AIREALS
			player.components.stats.key = "down" --IN CASE JUMP IS BUFFERING
		else
			player.components.stats:SetKeyBuffer("cstick_down")
		end
		player:AddTag("holdingcdown")
	else
		player:RemoveTag("atk_key_dwn")
		if player.sg:HasStateTag("chargingdsmash") then
			player.sg:GoToState("dsmash")
		end
		player:RemoveTag("holdingcdown")
	end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "cdown1erc", cdown1)
	GLOBAL.TheInput:AddControlHandler(cstick_down, function() if UsingController() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cdown1erc"]) end end)
	
	
	
	--CSTICK LEFT --THESE FUNCTIONS ACTUALLY PUSH EVENTS FOR FORWARD AND BACKWARD INSTEAD OF LEFT AND RIGHT --NOT ANYMORE THEY DONT!!
	local function cleft1(player)
	if player:HasTag("lockcontrols") then return end
	if not player:HasTag("holdingcleft") then
		player:AddTag("atk_key_dwn")
		player:PushEvent("cstick_side", {key = "left", key2 = "stick"}) --1-1-22 FORGOT TO MAKE THESE "STICK" KEYS.
		player:PushEvent("attack_key")
		--4-23-20 HAVE 1 FRAME LISTENERS ON BOTH THE ATK AND JUMP KEY. IF EITHER KEYHANDLER DETECTS THE OTHER WAS JUST PRESSED, CANCEL WHATEVER TO BUFFER A JUMP AIREAL
		player.sg:AddStateTag("listen_for_atk")
		player:DoTaskInTime(0, function() --IT'S SAFER TO DO THIS AS A STATETAG SO THAT IF USERS ARE HIT OUT OF IT, IT WILL REMOVE ITSELF
			player.sg:RemoveStateTag("listen_for_atk")
		end)
		if player.components.stats.event == "jump" and player.components.stats.buffertick >= 1 then --4-18-20 FOR JUMP-BUFFERED AIREALS
			player.components.stats.key = player.components.keydetector:GetCStickDirection(player, "left") --IN CASE JUMP IS BUFFERING
		else
			player.components.stats:SetKeyBuffer("cstick_side", "left", "stick")
		end
		player:AddTag("holdingcleft")
	else
		player:RemoveTag("atk_key_dwn")
		if player.sg:HasStateTag("chargingfsmash") then
			player.sg:GoToState("fsmash")
		end
		player:RemoveTag("holdingcleft")
	end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "cleft1erc", cleft1)
	GLOBAL.TheInput:AddControlHandler(cstick_left, function() if UsingController() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cleft1erc"]) end end)
	
	
	
	--CSTICK RIGHT
	local function cright1(player)
	if player:HasTag("lockcontrols") then return end
	if not player:HasTag("holdingcright") then
		player:AddTag("atk_key_dwn")
		player:PushEvent("cstick_side", {key = "right", key2 = "stick"})
		player:PushEvent("attack_key")
		--4-23-20 HAVE 1 FRAME LISTENERS ON BOTH THE ATK AND JUMP KEY. IF EITHER KEYHANDLER DETECTS THE OTHER WAS JUST PRESSED, CANCEL WHATEVER TO BUFFER A JUMP AIREAL
		player.sg:AddStateTag("listen_for_atk")
		player:DoTaskInTime(0, function() --IT'S SAFER TO DO THIS AS A STATETAG SO THAT IF USERS ARE HIT OUT OF IT, IT WILL REMOVE ITSELF
			player.sg:RemoveStateTag("listen_for_atk")
		end)
		if player.components.stats.event == "jump" and player.components.stats.buffertick >= 1 then --4-18-20 FOR JUMP-BUFFERED AIREALS
			player.components.stats.key = player.components.keydetector:GetCStickDirection(player, "right") --IN CASE JUMP IS BUFFERING
		else
			player.components.stats:SetKeyBuffer("cstick_side", "right", "stick")
		end
		player:AddTag("holdingcright")
	else
	player:RemoveTag("atk_key_dwn")
		if player.sg:HasStateTag("chargingfsmash") then
			player.sg:GoToState("fsmash")
		end
		player:RemoveTag("holdingcright")
	end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "cright1erc", cright1)
	GLOBAL.TheInput:AddControlHandler(cstick_right, function() if UsingController() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cright1erc"]) end end)
	
	
	local function special1(player)
	if player:HasTag("lockcontrols") then return end
	-- if not player.components.keydetector.controllerbound then return end --7-27-17
	-- if GLOBAL.TheInput:IsControlPressed(specialc) then
	if not player:HasTag("spc_key_dwn") then
		player:PushEvent("throwspecial", {key = player.components.keydetector:GetBufferKey(player), key2 = player.Transform:GetRotation()}) --4-5 ADDING ADDITIONAL DATA FOR KEY BUFFERING
			player.components.stats:SetKeyBuffer("throwspecial", player.components.keydetector:GetBufferKey(player), player.Transform:GetRotation()) 
			--TODOLIST  TEST TO SEE IF EVENT = "TROWATTACK" AND IF BUFFERTICK >= 3 AND IF IT IS, THEN THROW A GRAB EVENT INSTEAD
		player:AddTag("spc_key_dwn")
	else
		player:RemoveTag("spc_key_dwn") 
	end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "special1erc", special1)
	GLOBAL.TheInput:AddControlHandler(specialc, function() if UsingController() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["special1erc"]) end end)

	
	
	
	
	--DOWN
	local function down1(player) --, adown)
	if player:HasTag("lockcontrols") then return end
	-- if not player.components.keydetector.controllerbound then return end
	-- if GLOBAL.TheInput:IsControlPressed(down) then
	--player.components.keydetector.analogdown = adown --1-14-22 REMOVING BECAUSE ONLY CLIENT SHOULD TRACK THIS
	if not player.components.keydetector.holdingdown then
		player:PushEvent("down")
		if player.sg:HasStateTag("canoos") then
			-- player:DoTaskInTime(0.1, function() --?????WHY WAS IT LIKE THIS??
				-- player.sg:GoToState("spotdodge")
			-- end)
			player.sg:GoToState("spotdodge")
		else
			player:PushEvent("duck")
		end
		player:AddTag("listen_for_dsmash")
		player:DoTaskInTime((2*GLOBAL.FRAMES), function()
			player:RemoveTag("listen_for_dsmash")
		end)
	-- end
	player.components.keydetector.holdingdown = true
	else
		if player.sg:HasStateTag("ducking") then
			-- player.sg:GoToState("idle")
		end
		player.components.keydetector.holdingdown = false
	end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "down1erc", down1)
	GLOBAL.TheInput:AddControlHandler(down, function() if UsingController() then 
		--SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["down1erc"], GLOBAL.TheInput:GetAnalogControlValue(down)) 
		--1-14-22
		-- GLOBAL.TheInput:GetAnalogControlValue(down)
		-- DownAnalogCheck(key, mem, fn)
		-- analogdowndwn = DownAnalogCheck(down, analogdowndwn, function() SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["down1erc"])  end) 
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["down1erc"])
	end end)
	
	
	
	
	--OH RIGHT I FORGOT ABOUT CONTROLLER MOVEMENT
	--LEFT
	local function left1(player, aleft)
	if player:HasTag("lockcontrols") then return end
	-- if GLOBAL.TheInput:IsControlPressed(left) then
	-- if not player.components.keydetector.controllerbound then return end --7-27-17
	-- player.components.keydetector.analogleft = aleft --7-23-17 
	if not player.components.keydetector.holdingleft then
		-- print("STAHP", holdingleft)
		player:PushEvent("left")
		if player.components.launchgravity:GetRotationValue() == 1 then --1-6 FORWARD AND BACKWARD DETECTORS
			player:PushEvent("forward_key")
		else
			player:PushEvent("backward_key")
		end
		if not player.components.launchgravity:GetIsAirborn() then
			-- player:RemoveTag("listen_for_dashr")  --NOT FOR THE CONTROLLER VERSION!!
			player:RemoveTag("listen_for_tapr")
			if player:HasTag("listen_for_dash") and player:HasTag("listen_for_tap") and not player.sg:HasStateTag("dashing") and not player.sg:HasStateTag("busy") then
				player:PushEvent("dash", {key = "left"})
				-- player:AddTag("dashing") --1-14-22 WHAT AM I DOING?? THIS DOESNT DO ANYTHING
			end
			
			-- print("FLICK DASH DETECTION", player.components.keydetector:GetAnalogLeft(player))
			--8-27 FLICK DASH DETECTION
			-- if GLOBAL.TheInput:GetAnalogControlValue(left) >= 0.55 then 
			-- if player.components.keydetector:GetAnalogLeft(player) >= 0.55 then --7-23-17 DST CHANGE-- FIRST USE OF THE NEW ANALOG CONTROL VALUE OBTAINING
			if aleft >= 0.55 then  --7-23-17 HOLD UP, OKAY ALL THE FLICK VALUES ARE WAY LOWER THAN THEY WERE IN DS
				player:PushEvent("dash", {key = "left"})
				-- player:AddTag("dashing")
			end
			-- if player.components.stats.autodash == true then --9-30-21 REWORKING AUTO DASH. REMOVING FROM CONTROLS
				-- player:PushEvent("dash", {key = "left"}) 
			-- end
			
			player:AddTag("listen_for_smash")
			player:AddTag("listen_for_roll") --7-17-17 EARLY ROLL WINDOW LISTENER
			player:DoTaskInTime(0.5, function() --2-7-17 CHANGING FROM 0.3 TO 0.5
				player:RemoveTag("listen_for_dash")
			end)
			player:DoTaskInTime((2*GLOBAL.FRAMES), function()
				player:RemoveTag("listen_for_smash")
				player:RemoveTag("listen_for_roll") --7-17-17
			end)

			-- 7-17-17 LETS BUFFER SOME DODGES
			if player.components.keydetector:GetBlock(player) then
				player:PushEvent("roll", {key = player.components.keydetector:GetLeftRight(player)})
				-- player.components.stats:SetKeyBuffer("roll", player.components.keydetector:GetLeftRight(player)) --8-11-17 ALWAYS RETURNS "NONE"??? GETTING REAL SICK OF YOUR CRAP 
				player.components.stats:SetKeyBuffer("roll", "left") --8-11-17 ALRIGHT. YOU KNOW WHAT?? FINE. BE LIKE THAT. THEN LETS SEE YOU GET PAST THIS  --YEA. THATS WHAT I THOUGHT
				-- print("BIG GREY TRUNK FOR THE HEK", player.components.keydetector:GetLeftRight(player))
			end
		end
		player.components.keydetector.holdingleft = true
		player.components.keydetector.holdingright = false
		-- end
	else
		if player.sg:HasStateTag("dashing") then
			--player.sg:GoToState("dash_stop")
			player:PushEvent("dash_stop")
		else
			player:AddTag("listen_for_tap")
			player:DoTaskInTime((4*GLOBAL.FRAMES), function()
				-- player:RemoveTag("listen_for_dash")
				player:RemoveTag("listen_for_tap")
			end)
		end
		player:RemoveTag("wasrunning")
		player.components.keydetector.holdingleft = false
	end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "left1erc", left1)
	GLOBAL.TheInput:AddControlHandler(leftc, function() 
		if UsingController() then 
			SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["left1erc"], GLOBAL.TheInput:GetAnalogControlValue(leftc)) 
			-- analogleftdwn = DownAnalogCheck(leftc, analogleftdwn, function() SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["left1erc"])  end) 
			-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["left1erc"])
		end 
	end)
	



	-- local function right1(player)
	local function right1(player, aright)	--7-23-17 LETS TRY A LITTLE CUSTOM PARAMITER STUFF...   --I CANT BELEIVE I TRIED HEALTH ROCKS BEFORE I TRIED THIS
	if player:HasTag("lockcontrols") then return end
	-- if not player.components.keydetector.controllerbound then return end --7-27-17 IT SEEMS CONTROLHANDLERS ARE KEYHANDLERS, AND THIS WILL RUN TWICE IF ONE IS PLUGGED IN WITHOUT THIS CHECKER HERE
	-- if GLOBAL.TheInput:IsControlPressed(right) then
	-- player.components.keydetector.analogright = aright --7-23-17 THIS KEEPS THEM CONSISTANTLY UP TO DATE WHEN THE STICK IS MOVED IN THAT DIRECTION!! SMART STUFF, ME! WHY THANK YOU, ME.
	if not player.components.keydetector.holdingright then
	player:PushEvent("right")
	if player.components.launchgravity:GetRotationValue() == -1 then
		player:PushEvent("forward_key")
	else
		player:PushEvent("backward_key")
	end
	if not player.components.launchgravity:GetIsAirborn() then
		-- player:RemoveTag("listen_for_dash")
		player:RemoveTag("listen_for_tap")
		if player:HasTag("listen_for_dashr") and player:HasTag("listen_for_tapr") and not player.sg:HasStateTag("dashing") and not player.sg:HasStateTag("busy") then
			--player.sg:GoToState("dash")
			player:PushEvent("dash", {key = "right"})
			-- player:AddTag("dashing")
		end
		-- player:AddTag("listen_for_dashr")
		--8-27 FLICK DASH DETECTION
		-- if player.components.keydetector:GetAnalogRight(player) >= 0.55 then --7-23-17 DST CHANGE -JUST KIDDING ITS THIS ONE
		if aright >= 0.55 then
			player:PushEvent("dash", {key = "right"})
		end
		--1-14-22 OK IT'S SUPPOSED TO BE THE ONE ABOVE, BUT THAT ONE IS SUPER LAGGY SO LET'S TEMPORARILY USE THIS ONE
		-- if player.components.stats.autodash == true then --11-9-17 AUTO-DASH
			-- player:PushEvent("dash", {key = "right"}) 
		-- end
		
		player:AddTag("listen_for_smash")
		player:AddTag("listen_for_roll") --7-17-17 EARLY ROLL WINDOW LISTENER
		player:DoTaskInTime(0.5, function() 
			player:RemoveTag("listen_for_dashr")
		end)
		player:DoTaskInTime((2*GLOBAL.FRAMES), function()
			player:RemoveTag("listen_for_smash")
			player:RemoveTag("listen_for_roll") --7-17-17
		end)

		-- 7-17-17 LETS BUFFER SOME DODGES
		if player.components.keydetector:GetBlock(player) then
			player:PushEvent("roll", {key = player.components.keydetector:GetLeftRight(player)})
			player.components.stats:SetKeyBuffer("roll", "right") --8-11-17
		end
	end
	player.components.keydetector.holdingright = true
	player.components.keydetector.holdingleft = false
	-- end
	else
		if player.sg:HasStateTag("dashing") then
			-- player.sg:GoToState("dash_stop")
			player:PushEvent("dash_stop")
		else
			player:AddTag("listen_for_tapr")
			player:DoTaskInTime((4*GLOBAL.FRAMES), function()
				-- player:RemoveTag("listen_for_dashr")
				player:RemoveTag("listen_for_tapr")
			end)
		end
		player:RemoveTag("wasrunning")
		player.components.keydetector.holdingright = false
	end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "right1erc", right1)
	-- GLOBAL.TheInput:AddControlHandler(right, function() SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["right1erc"]) end)
	GLOBAL.TheInput:AddControlHandler(rightc, function() 
		if UsingController() then 
			SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["right1erc"], GLOBAL.TheInput:GetAnalogControlValue(rightc)) 
			-- print("ANLOG: ", analogrightdwn)
			-- analogrightdwn = DownAnalogCheck(rightc, analogrightdwn, function() SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["right1erc"])  end) 
			-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["right1erc"])
		end 
	end)
	--7-23-17 YESSSS THIS FIXES IT!! NOW JUST ADD IT TO THE KEYDETECTOR VALUES SO IT STAYS CONSTANTLY UPDATED!
	
	
	
	
	]]
	

		
		
	-- else --------7-18-17 OKAY, ANY NORMAL KEYBOARD KEYHANDLERS ARE ONLY APPLIED IF NO CONTROLLER IS DETECTED--------
	-- NAH LETS JUST APPLY THEM BOTH
	--==================================================================================================================================================================
	
	--1-19-22 OK THIS ONE'S GONNA GET A BIT WEIRD.
	GLOBAL.TheInput:AddControlHandler(GLOBAL.CONTROL_MAP, function() 
		if UsingController() then 
			if not specialdwn then
				-- print("BACK BUTTON", GLOBAL.TheFrontEnd:GetActiveScreen(), GLOBAL.TheFrontEnd:GetFocusWidget())
				GLOBAL.ThePlayer:PushEvent("cornermenu_focus")
			end
		end 
	end)
	
	
	
	
	--
	local attack =  GLOBAL.KEY_N
	local special =  GLOBAL.KEY_M
	-- local grab = 44 --KEY_COMMA
	local grab = GLOBAL.KEY_PERIOD --46
	local smash = 44 --KEY_COMMA
	local jump =  GLOBAL.KEY_SPACE  --32
	-- local block = 306 --LCONTROL  --KEY_LSHIFT --INCOMPATIBLE WHILE NUMPAD IS IN USE OR ESLE RIP PLAYER2
	local block = GLOBAL.KEY_LSHIFT --402
	-- local block2 = GLOBAL.KEY_LSHIFT --JUST FOR EASE OF USE
	local up = GLOBAL.KEY_W --119
	local down = GLOBAL.KEY_S --115
	local left = GLOBAL.KEY_A --97
	local right = GLOBAL.KEY_D --100
	local cstick_up = GLOBAL.KEY_U --117
	local cstick_down = GLOBAL.KEY_J --106
	local cstick_left = GLOBAL.KEY_H --104
	local cstick_right = GLOBAL.KEY_K --107
	
	--11-24-20 TESTING OUT THE ABILITY TO PULL GLOBAL VARIABLES FROM OTHER MOD SETTINGS.
	if GLOBAL.MODCONTROLS == true then
		print("PULLING SMASH CONTROLS FROM EXTERNAL MOD SETTINGS!")
		attack = GLOBAL.SMASHCONTROLS.ATTACK
		special = GLOBAL.SMASHCONTROLS.SPECIAL
		smash = GLOBAL.SMASHCONTROLS.SMASH
		grab = GLOBAL.SMASHCONTROLS.GRAB
		jump =  GLOBAL.SMASHCONTROLS.JUMP
		block = GLOBAL.SMASHCONTROLS.BLOCK
		up = GLOBAL.SMASHCONTROLS.UP
		down = GLOBAL.SMASHCONTROLS.DOWN
		left = GLOBAL.SMASHCONTROLS.LEFT
		right = GLOBAL.SMASHCONTROLS.RIGHT
		cstick_up = GLOBAL.SMASHCONTROLS.CSTICK_UP
		cstick_down = GLOBAL.SMASHCONTROLS.CSTICK_DOWN
		cstick_left = GLOBAL.SMASHCONTROLS.CSTICK_LEFT
		cstick_right = GLOBAL.SMASHCONTROLS.CSTICK_RIGHT
	
	else
		print("NO SMASHCONTROLS FOUND. USING DEFAULT CONTROLS.")
	end
	
	
	--MERGING WITH CONTROLLER CONTROLS.
	local cattackc = GLOBAL.CONTROL_CONTROLLER_ACTION --A
	local cspecialc = GLOBAL.CONTROL_CONTROLLER_ALTACTION
	local cgrab = GLOBAL.CONTROL_ROTATE_RIGHT --RIGHT TRIGGER
	local cgrab_alt = GLOBAL.CONTROL_ROTATE_LEFT --LB
	local cjump = GLOBAL.CONTROL_USE_ITEM_ON_ITEM  --X -DEFAULT
	local cjump_alt = GLOBAL.KEY_1
	local cblock = GLOBAL.CONTROL_MAP_ZOOM_IN --L TRIGGER  --IT APPEARS HAVING THIS SET AS THE SAME KEY THAT OPENS CRAFTING MAKES BIG PROBLEMS. SET CRAFTING TO A DIFFERENT BUTTON TO FIX IT
	local cblock_alt = GLOBAL.CONTROL_MAP_ZOOM_OUT --R TRIGGER
	local cup = GLOBAL.CONTROL_MOVE_UP
	local cdown = GLOBAL.CONTROL_MOVE_DOWN
	local cleftc = GLOBAL.CONTROL_MOVE_LEFT
	local crightc = GLOBAL.CONTROL_MOVE_RIGHT
	local ccstick_up = GLOBAL.CONTROL_INVENTORY_UP
	local ccstick_down = GLOBAL.CONTROL_INVENTORY_DOWN
	local ccstick_left = GLOBAL.CONTROL_INVENTORY_LEFT
	local ccstick_right = GLOBAL.CONTROL_INVENTORY_RIGHT
	local csmash = GLOBAL. CONTROL_CONTROLLER_ATTACK --.CONTROL_INVENTORY_DROP --DPAD-DOWN
	--9-1-21 AND EVENTUALLY WE'LL MAKE THIS SOME SORT OF "NOT-BOUND" DEFAULT WITH "CONTROL_OPEN_DEBUG_MENU"
	
	--11-25-20 EXTERNAL CUSTOM CONTROLS FOR CONTROLLERS
	if GLOBAL.MODCONTROLS == true then
		cattackc = GLOBAL.SMASHCONTROLS.CTL_ATTACK
		cspecialc = GLOBAL.SMASHCONTROLS.CTL_SPECIAL
		csmash = GLOBAL.SMASHCONTROLS.CTL_SMASH
		cgrab = GLOBAL.SMASHCONTROLS.CTL_GRAB
		cjump =  GLOBAL.SMASHCONTROLS.CTL_JUMP
		cblock = GLOBAL.SMASHCONTROLS.CTL_BLOCK
		cgrab_alt = GLOBAL.SMASHCONTROLS.CTL_GRAB_ALT
		cjump_alt =  GLOBAL.SMASHCONTROLS.CTL_JUMP_ALT
		cblock_alt = GLOBAL.SMASHCONTROLS.CTL_BLOCK_ALT
		--AS MUCH AS I'D LIKE TO LET PLAYERS REASSIGN MOVEMENT CONTROLS TO SOMETHING LIKE DPAD, OUR ANALOG CHECKERS WILL WIG OUT IF ITS SET TO SOMETING THATS NOT A STICK
	end
	--1-14-22
	local analogupdwn = false
	local analogdowndwn = false
	local analogleftdwn = false
	local analogrightdwn = false
	
	
	
	--1-14-22 WE REALLY SHOULDN'T LET THE SERVER BE THE ONE CHECKING IF A KEY IS HELD DOWN OR NOT. WE'RE SENDING WAY TOO MANY RPCS BY HOLDING DOWN KEYS
	--HANDLE THIS CHECK CLIENTSIDE AND ONLY SEND AN RPC WHEN WE PRESS A KEY DOWN SO WE AREN'T REPEATING THE RPC A BUNCH
	local jumpdwn = false
	local blockdwn = false
	local atkdwn = false
	local grabdwn = false
	local specialdwn = false
	local smashdwn = false
	local updwn = false
	local downdwn = false
	local leftdwn = false
	local rightdwn = false
	
	
	-- local cattackcdwn = false
	-- local cspecialcdwn = false
	-- local cgrabdwn = false
	-- local cgrab_altdwn = false
	-- local cjumpdwn = false
	-- local cjump_altdwn = false
	-- local cblockdwn = false
	-- local cblock_altdwn = false
	-- local cupdwn = false
	local cdowndwn = false
	local cleftcdwn = false
	local crightcdwn = false
	local ccstick_updwn = false
	local ccstick_downdwn = false
	local ccstick_leftdwn = false
	local ccstick_rightdwn = false
	local csmashdwn = false
	
	
	
	
	
	local function jump1(player)
	player.components.keydetector.holdingjump = true
	if player:HasTag("lockcontrols") then return end --10-8-17 DST- THIS IS BEING ADDED TO ALL KEYBOARD KEY LISTNERS TO PREVENT THEM FROM ACTIVATING WHILE CHATTING
		-- if not player:HasTag("jump_key_dwn") then --!!! IT !!MUST!! BE DEFINED AS PLAYER!! SELF.INST WILL JUST REFER TO THE HOST
		-- if not player.components.keydetector.holdingjump == true then --6-9-20
			-- print("JUMP BUTTON")
			if player.sg:HasStateTag("listen_for_atk") then --4-23-20 OKAY, LETS TRY THAT AGAIN
				-- print("---- FORCE RE-JUMP ----")
				--player.components.stats:SetKeyBuffer("jump", player.components.keydetector:GetBufferKey(player)) 
				player.components.stats:SetKeyBuffer("jump", player.components.stats.key) --4-24-20 ACTUALLY, KEEP THE KEY BUFFER THE SAME, THE ATTACKS WILL SET THOSE
			else
			
				player:PushEvent("jump")
				player.components.stats:SetKeyBuffer("jump", "ITSNIL") --4-18-20 REMOVING THE KEYBUFFER CHECK, SINCE WE DONT USE IT HERE  --player.components.keydetector:GetBufferKey(player)
			end
		-- end
		player:AddTag("jump_key_dwn") --1-14-22 WAIT I GUESS THERE ARE REASONS FOR US TO USE THIS ONE. FINE. YOU GET TO STAY. FOR NOW
		
		
		--4-23-20 EXTRA BAGGAGE
		player.sg:AddStateTag("listen_for_jump")
		player:DoTaskInTime(0, function() 
			player.sg:RemoveStateTag("listen_for_jump")
		end)
	end
	local function jump2(player)
		player.components.keydetector.holdingjump = false
		if player:HasTag("lockcontrols") then return end
		player:RemoveTag("jump_key_dwn")
	end
	
	AddModRPCHandler(modname, "jump1er", jump1)
	-- GLOBAL.TheInput:AddKeyDownHandler(jump, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[modname]["jump1er"]) end)
	--10-9-17 A TEST VERSION FROM SOME DRAGO MOD THIG
	GLOBAL.TheInput:AddKeyDownHandler(jump, function() --*ROARS OF FURY* IS THIS REALLY THE ANSWER?? THIS DOESNT EVEN MAKE SENSE, ALSJDHFA. ALL DAY, THIS TOOK ALL DAY
		if not GLOBAL.IsPaused() then
			if not jumpdwn then
				SendModRPCToServer(MOD_RPC[modname]["jump1er"])
				-- print("JUMP RPC")
				jumpdwn = true
			end
		end
	end)
	
	AddModRPCHandler(modname, "jump2er", jump2)
	GLOBAL.TheInput:AddKeyUpHandler(jump, function() 
		if not GLOBAL.IsPaused() then 
			SendModRPCToServer(MOD_RPC[modname]["jump2er"])
			jumpdwn = false
		end 
	end)
	
	
	
	-- AddModRPCHandler(modname, "jump1erc", jump1)
	--1-25-22 CONTROLLER VERSION SHOULD CALL THE KEYBOARD VERSION!! APPARENTLY IT'S DIFFERENT BY LIKE 1 LINE OF CODE, BUT MAYBE THAT'S BETTER...
	GLOBAL.TheInput:AddControlHandler(cjump, --function() if UsingController() then SendModRPCToServer(MOD_RPC[modname]["jump1erc"]) end 
		-- RunControlWithCheck(key, cdown, cup) --NEW AND IMPROVED!~
		-- function() cjumpdwn = RunControlWithCheck(cjumpdwn, "jump1er", "jump2er") --NEW AND IMPROVED!~
		function() RunControlDown(cjump, "jump1er", "jump2er")  --1-27-22 NEWER AND IMPROVEDER!
	end)
	GLOBAL.TheInput:AddControlHandler(cjump_alt, function() RunControlDown(cjump_alt, "jump1er", "jump2er") end)
	
	
	
	
	
	--BLOCK
	local function block1(player)
	if player:HasTag("lockcontrols") then return end
	-- if not player:HasTag("holdingblock") then --1-1-2018 REUSEABLE (DS AND CONTROLER) TO PREVENT BUFFERED AIRDODGES
		player:PushEvent("block_key")
		if not player:HasTag("trytech_window") then
			player:AddTag("trytech")
			player:AddTag("trytech_window")
			player:DoTaskInTime(0.4, function() --1-19-17 CHANGING BOTH FROM 0.3 TO 0.4 TO ACCOUNT FOR DELAYED LANDING
				player:RemoveTag("trytech")
				player:DoTaskInTime(0.4, function()
					player:RemoveTag("trytech_window")
				end)
			end)
		end
		
		if player.sg:HasStateTag("can_ood") then
			player.sg:GoToState("block_startup")
			player:AddTag("wasrunning")
		end
		
		--7-17-17 AN EARLY LISTENER FOR ROLLS 
		-- print("IS LISTENFORROLL ACTIVE?   ", player:HasTag("listen_for_roll"))
		if player:HasTag("listen_for_roll") then
			player:PushEvent("roll", {key = player.components.keydetector:GetLeftRight(player)}) --DONT FORGET TO PASS PLAYER INTO THE KEYDETECTOR FN!
			player.components.stats:SetKeyBuffer("roll", player.components.keydetector:GetLeftRight(player))
		end
		
		player:AddTag("wantstoblock")
		-- player:AddTag("holdingblock") --1-1-2018 REUSEABLE- LITERALLY THE SAME THING AS WANTS TO BLOCK BUT WHATEVER
	-- end
	end
	local function block2(player)
	if player:HasTag("lockcontrols") then return end
		player:RemoveTag("wantstoblock")
		-- player:RemoveTag("holdingblock") --1-1-2018 REUSEABLE-
	end
	
	
	--1-14-22 THIS KEY IN PARTICULAR WORKS DIFFERENT THAN ALL THE REST. HOLDING IT DOWN WILL NOT CONTINUE TO SEND RPC REQUESTS
	--I THINK THAT'S JUST THE WEIRD NATURE OF THE SHIFT KEY, SPECIFIC TO THE COMPUTER HARDWARE, NOT THE PROGRAM
	AddModRPCHandler(modname, "block1er", block1)
	GLOBAL.TheInput:AddKeyDownHandler(block, function() if not GLOBAL.IsPaused() then 
		-- print("BLOCKER RPC")
		-- SendModRPCToServer(MOD_RPC[modname]["block1er"]) 
		blockdwn = RunWithKeyCheck(blockdwn, function() SendModRPCToServer(MOD_RPC[modname]["block1er"])  end)
	end end)
	
	AddModRPCHandler(modname, "block2er", block2)
	GLOBAL.TheInput:AddKeyUpHandler(block, function() if not GLOBAL.IsPaused() then 
		SendModRPCToServer(MOD_RPC[modname]["block2er"]) 
		blockdwn = false
	end end)
	
	GLOBAL.TheInput:AddControlHandler(cblock, function() RunControlDown(cblock, "block1er", "block2er") end)
	GLOBAL.TheInput:AddControlHandler(cblock_alt, function() RunControlDown(cblock_alt, "block1er", "block2er") end)

	
	
	--ATTACK
	local function attack1(player, forcesmash) --9-1-21 ADDING forcesmash TO FINALLY ALLOW A UNIQUE SMASH BUTTON
	player.components.keydetector.holdingattack = true
	if player:HasTag("lockcontrols") then return end
		-- if not player.components.keydetector.holdingattack then --THE HELD BUTTON TESTER ISNT ON THE CONTROLLER YET
		-- print("SHWING", player, player.components.keydetector:GetBufferKey(player), player.components.keydetector:GetUp())
		-- print("SHWING", player.components.keydetector:GetBufferKey(player)) --TRUE ALSE TRUE (WITH NEUTRAL)
		player:PushEvent("attack_key")
		player:AddTag("atk_key_dwn")
		
		local tapsmash = player.components.stats.tapsmash --11-29-21
		local tapjump = player.components.stats.tapjump
		
		--4-23-20 POWER MOVE - HAVE 1 FRAME LISTENERS ON BOTH THE ATK AND JUMP KEY. IF EITHER KEYHANDLER DETECTS THE OTHER WAS JUST PRESSED, CANCEL WHATEVER TO BUFFER A JUMP AIREAL
		player.sg:AddStateTag("listen_for_atk")
		player:DoTaskInTime(0, function() --IT'S SAFER TO DO THIS AS A STATETAG SO THAT IF USERS ARE HIT OUT OF IT, IT WILL REMOVE ITSELF
			player.sg:RemoveStateTag("listen_for_atk")
		end)
		--IN THAT ONE FRAME WINDOW, IF THE JUMP KEY IS PRESSED, WE'LL CANCEL THE ATTACK AND SET IT TO A JUMP WITH BUFFERED ATTACK INSTEAD
		if player.sg:HasStateTag("listen_for_jump") then
			--11-10-20 IF THEY HAVE TAPJUMP ENABLED, AND THEY BUFFERED THE UP KEY, WE SHOULD ASSUME THIS WAS MEANT TO BE AN UPSMASH
			if player.components.stats.tapjump and player.components.keydetector:GetUp(player) and  player:HasTag("listen_for_usmash") then
				if tapsmash or forcesmash then
					-- print("TAPJUMP UPSMASH!")
					local isbackward = (player.components.keydetector:GetBackward(player) and "backward" or nil)
					player:PushEvent("cstick_up", {key = isbackward})
					player.components.stats:SetKeyBuffer("cstick_up", isbackward)
				else --11-29-21 UNLESS THEY HAVE TAPSMASH DISABLED. THEN ASSUME UPTILT (ATTACK AS NORMAL)
					-- print("TAPJUMP UPTILT!")
					player:PushEvent("throwattack", {key = player.components.keydetector:GetBufferKey(player)})
					player.components.stats:SetKeyBuffer("throwattack", player.components.keydetector:GetBufferKey(player))
				end
			else
				-- print("---- FORCE RE-JUMP from atk----", player.components.keydetector:GetBufferKey(player))
				player.components.stats:SetKeyBuffer("jump", player.components.keydetector:GetBufferKey(player))
			end
		
		--4-18-20 TESTING NEW BUFFERABLE JUMP-AIRIALS (IF CURRENT BUFFERKEY = JUMP, DONT OVERWRITE IT, BUT ADD A KEY TO IT TO BUFFER AIRIAL)
		elseif player.components.stats.event == "jump" and player.components.stats.buffertick >= 1 then
			--1-29-22 SPECIAL CASE! IF TAPJUMP IS ENABLED AND THIS IS AN UP-ATTACK, ASSUME WE WANT AN UPTILT INSTEAD OF A JUMP BUFFERED UAIR
			if tapjump and player.components.keydetector:GetUp(player) then
				if forcesmash or (player:HasTag("listen_for_usmash") and tapsmash) then
					local isbackward = (player.components.keydetector:GetBackward(player) and "backward" or nil)
					player:PushEvent("cstick_up", {key = isbackward})
					player.components.stats:SetKeyBuffer("cstick_up", isbackward)
				else
					player:PushEvent("throwattack", {key = player.components.keydetector:GetBufferKey(player)}) --3-19-17 THE DST VERSION
					player.components.stats:SetKeyBuffer("throwattack", player.components.keydetector:GetBufferKey(player))
				end
			else
				--ACTUALLY NO DON'T REFRESH IT, JUST ADD THE ATTACK KEY. OTHERWISE MASHING ATTACK COULD EXTEND THE BUFFER A TON
				player.components.stats.key = player.components.keydetector:GetBufferKey(player)
			end
		
		
		elseif (forcesmash and player.components.keydetector:GetUp(player)) or (player:HasTag("listen_for_usmash") and tapsmash) then
			local isbackward = (player.components.keydetector:GetBackward(player) and "backward" or nil)
			player:PushEvent("cstick_up", {key = isbackward})
			player.components.stats:SetKeyBuffer("cstick_up", isbackward)
			-- print("UP SMASH!!", player.components.keydetector:GetBufferKey(player))
		elseif (forcesmash and player.components.keydetector:GetDown(player)) or (player:HasTag("listen_for_dsmash") and tapsmash) then
			player:PushEvent("cstick_down")
			player.components.stats:SetKeyBuffer("cstick_down")
		elseif forcesmash or (player:HasTag("listen_for_smash") and tapsmash) then --or player.sg:HasStateTag("must_fsmash") then --11-29-21 GET THIS OUTTA HERE, AINT NO ONE FORCING SMASHES
			-- player:PushEvent("cstick_forward")
			-- player.components.stats:SetKeyBuffer("cstick_forward", {key = player.components.keydetector:GetLeftRight(player)}) --7-17-17
			-- player:PushEvent("cstick_side") --7-20-17 THIS WILL MAKE DIRECTIONAL C-STICK BUFFERING SO MUCH EASIER
			player:PushEvent("cstick_side", {key = player.components.keydetector:GetLeftRight(player)}) --12-10-17 ADDING THIS CHECK FOR DIRECTIONAL INPUT --REUSEABLE
			player.components.stats:SetKeyBuffer("cstick_side", player.components.keydetector:GetLeftRight(player)) --7-17-17
			-- print("I C-STICKED SIDE")
		else
			-- player:PushEvent("throwattack")
			-- player:AddTag("atk_key_dwn")
			-- {hitstun = self.hitstun+self.hitlag}
			-- player:PushEvent("throwattack", {key = player.components.keydetector:GetBufferKey(player)}) --4-5 ADDING ADDITIONAL DATA FOR KEY BUFFERING
			-- player.components.stats:SetKeyBuffer("throwattack", player.components.keydetector:GetBufferKey(player))
			player:PushEvent("throwattack", {key = player.components.keydetector:GetBufferKey(player)}) --3-19-17 THE DST VERSION
			player.components.stats:SetKeyBuffer("throwattack", player.components.keydetector:GetBufferKey(player))
			-- print("I SWUNG MY SWORD")
		end
		-- end
	end
	
	local function attack2(player)
	player.components.keydetector.holdingattack = false
	if player:HasTag("lockcontrols") then return end
		player:RemoveTag("atk_key_dwn")
	end
	
	AddModRPCHandler(modname, "attack1er", attack1)
	GLOBAL.TheInput:AddKeyDownHandler(attack, function() if not GLOBAL.IsPaused() then 
		-- print("ATTACK RPC")
		-- SendModRPCToServer(MOD_RPC[modname]["attack1er"]) 
		atkdwn = RunWithKeyCheck(atkdwn, function() SendModRPCToServer(MOD_RPC[modname]["attack1er"])  end)
	end end)
	
	AddModRPCHandler(modname, "attack2er", attack2)
	GLOBAL.TheInput:AddKeyUpHandler(attack, function() if not GLOBAL.IsPaused() then 
		SendModRPCToServer(MOD_RPC[modname]["attack2er"]) 
		atkdwn = false
	end end)
	
	GLOBAL.TheInput:AddControlHandler(cattackc, function() RunControlDown(cattackc, "attack1er", "attack2er") end)
	
	--9-1-21 A VERSION FOR SMASH ATTACKS. RUNS THE SAME FUNCTION AS THE ATTACK BUTTON BUT WITH AN EXTRA BOOL PASSED IN
	AddModRPCHandler(modname, "smash1er", attack1)
	GLOBAL.TheInput:AddKeyDownHandler(smash, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[modname]["smash1er"], true) end end)
	AddModRPCHandler(modname, "smash2er", attack2)
	GLOBAL.TheInput:AddKeyUpHandler(smash, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[modname]["smash2er"]) end end)
	
	GLOBAL.TheInput:AddControlHandler(csmash, function() 
		-- print("SMASH DOWN?", GLOBAL.TheInput:IsControlPressed(csmash))
		RunControlDown(csmash, "attack1er", "attack2er", true) 
	end)
	
	
	
	--9-10 FOR GRABBING
	local function grab1(player)
	player.components.keydetector.holdinggrab = true
	if player:HasTag("lockcontrols") then return end
		player:PushEvent("throwattack", {key = "block", key2 = (player.components.keydetector:GetBackward(player) and "backward" or nil)})
		player.components.stats:SetKeyBuffer("throwattack", "block", (player.components.keydetector:GetBackward(player) and "backward" or nil))
	end
	local function grab2(player)
		player.components.keydetector.holdinggrab = false
	end
	
	AddModRPCHandler(modname, "grab1er", grab1)
	GLOBAL.TheInput:AddKeyDownHandler(grab, function(arg1, arg2) if not GLOBAL.IsPaused() then 
		-- SendModRPCToServer(MOD_RPC[modname]["grab1er"]) 
		grabdwn = RunWithKeyCheck(grabdwn, function() SendModRPCToServer(MOD_RPC[modname]["grab1er"])  end)
		-- print("GRAB RPC")
		-- print(arg1, arg2) --nil, nil :(
	end end)
	
	AddModRPCHandler(modname, "grab2er", grab2)
	GLOBAL.TheInput:AddKeyUpHandler(grab, function() if not GLOBAL.IsPaused() then 
		SendModRPCToServer(MOD_RPC[modname]["grab2er"])
		grabdwn = false
	end end)
	
	GLOBAL.TheInput:AddControlHandler(cgrab, function(arg1, arg2) RunControlDown(cgrab, "grab1er", "grab2er") end)
	GLOBAL.TheInput:AddControlHandler(cgrab_alt, function() RunControlDown(cgrab_alt, "grab1er", "grab2er") end)
	-- print(arg1, arg2) --true, 1




	--CSTICK UP
	local function cup1(player)
	if player:HasTag("lockcontrols") then return end
		player:AddTag("atk_key_dwn")
		player:PushEvent("cstick_up")
		player:PushEvent("attack_key") --10-20-17 ADDED THESE BECAUSE QUICK-TAP DIRECTIONAL ATTACK KEYS CAN SOMETIMES BE THESE --REUSEABLE
		--4-23-20 HAVE 1 FRAME LISTENERS ON BOTH THE ATK AND JUMP KEY. IF EITHER KEYHANDLER DETECTS THE OTHER WAS JUST PRESSED, CANCEL WHATEVER TO BUFFER A JUMP AIREAL
		player.sg:AddStateTag("listen_for_atk")
		player:DoTaskInTime(0, function() --IT'S SAFER TO DO THIS AS A STATETAG SO THAT IF USERS ARE HIT OUT OF IT, IT WILL REMOVE ITSELF
			player.sg:RemoveStateTag("listen_for_atk")
		end)
		if (player.components.stats.event == "jump" and player.components.stats.buffertick >= 1 and player.components.stats.key2 ~= "tapup") or player.sg:HasStateTag("listen_for_jump") then --4-18-20 FOR JUMP-BUFFERED AIREALS
			player.components.stats.key = "up" --IN CASE JUMP IS BUFFERING
		else
			player.components.stats:SetKeyBuffer("cstick_up")
		end
		-- print("STAHP")
		-- TheWorld.components.ambientlighting:CycleBlue()  -----0000000000000
	end
	
	local function cup2(player)
	if player:HasTag("lockcontrols") then return end	
		player:RemoveTag("atk_key_dwn")
		if player.sg:HasStateTag("chargingusmash") then --4-18-20 WAIT AM I REALLY STILL DOING THINGS LIKE THIS??? DEF CONSIDER REMOVING THIS
			player.sg:GoToState("usmash")
		end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "cup1er", cup1)
	GLOBAL.TheInput:AddKeyDownHandler(cstick_up, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cup1er"]) end end)
	
	AddModRPCHandler(TUNING.MODNAME, "cup2er", cup2)
	GLOBAL.TheInput:AddKeyUpHandler(cstick_up, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cup2er"]) end end)
	GLOBAL.TheInput:AddControlHandler(ccstick_up, function() ccstick_updwn = RunControlWithCheck(ccstick_updwn, "cup1er", "cup2er") end)
	

	--CSTICK DOWN
	local function cdown1(player)
	if player:HasTag("lockcontrols") then return end
		player:AddTag("atk_key_dwn")
		player:PushEvent("attack_key")
		
		--4-23-20 HAVE 1 FRAME LISTENERS ON BOTH THE ATK AND JUMP KEY. IF EITHER KEYHANDLER DETECTS THE OTHER WAS JUST PRESSED, CANCEL WHATEVER TO BUFFER A JUMP AIREAL
		player.sg:AddStateTag("listen_for_atk")
		player:DoTaskInTime(0, function() --IT'S SAFER TO DO THIS AS A STATETAG SO THAT IF USERS ARE HIT OUT OF IT, IT WILL REMOVE ITSELF
			player.sg:RemoveStateTag("listen_for_atk")
		end)
		if (player.components.stats.event == "jump" and player.components.stats.buffertick >= 1) or player.sg:HasStateTag("listen_for_jump") then --4-18-20 FOR JUMP-BUFFERED AIREALS
			player.components.stats.key = "down" --IN CASE JUMP IS BUFFERING
			-- print("---- FORCE RE-JUMP from atk----", player.components.keydetector:GetBufferKey(player))
		else
			player:PushEvent("cstick_down")
			player.components.stats:SetKeyBuffer("cstick_down")
		end
	end
	local function cdown2(player)
	if player:HasTag("lockcontrols") then return end
		player:RemoveTag("atk_key_dwn")
		if player.sg:HasStateTag("chargingdsmash") then
			player.sg:GoToState("dsmash")
		end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "cdown1er", cdown1)
	GLOBAL.TheInput:AddKeyDownHandler(cstick_down, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cdown1er"]) end end)
	
	AddModRPCHandler(TUNING.MODNAME, "cdown2er", cdown2)
	GLOBAL.TheInput:AddKeyUpHandler(cstick_down, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cdown2er"]) end end)
	GLOBAL.TheInput:AddControlHandler(ccstick_down, function() ccstick_downdwn = RunControlWithCheck(ccstick_downdwn, "cdown1er", "cdown2er") end)
	
	
	
	--CSTICK LEFT --THESE FUNCTIONS ACTUALLY PUSH EVENTS FOR FORWARD AND BACKWARD INSTEAD OF LEFT AND RIGHT
	local function cleft1(player)
	if player:HasTag("lockcontrols") then return end
		player:AddTag("atk_key_dwn")
		player:PushEvent("attack_key")
		--4-23-20 HAVE 1 FRAME LISTENERS ON BOTH THE ATK AND JUMP KEY. IF EITHER KEYHANDLER DETECTS THE OTHER WAS JUST PRESSED, CANCEL WHATEVER TO BUFFER A JUMP AIREAL
		player.sg:AddStateTag("listen_for_atk")
		player:DoTaskInTime(0, function() --IT'S SAFER TO DO THIS AS A STATETAG SO THAT IF USERS ARE HIT OUT OF IT, IT WILL REMOVE ITSELF
			player.sg:RemoveStateTag("listen_for_atk")
		end)
		if (player.components.stats.event == "jump" and player.components.stats.buffertick >= 1) or player.sg:HasStateTag("listen_for_jump") then --4-18-20 FOR JUMP-BUFFERED AIREALS
			player.components.stats.key = player.components.keydetector:GetCStickDirection(player, "left") --NEW FN FOR RETURNIGN FORWARD/BACKWARD FROM CSTICK DIRECTIONS
		else
			player:PushEvent("cstick_side", {key = "left", key2 = "stick"}) --1-1-18 ADDED "STICK" DATA TO IDENTIFY IF THE INPUT WAS FROM THE CSTICK ITSELF OR THE QUICK-TAP DIR+ATTACK
			player.components.stats:SetKeyBuffer("cstick_side", "left", "stick")
		end
	end
	local function cleft2(player)
	if player:HasTag("lockcontrols") then return end
		player:RemoveTag("atk_key_dwn")
		if player.sg:HasStateTag("chargingfsmash") then
			player.sg:GoToState("fsmash")
		end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "cleft1er", cleft1)
	GLOBAL.TheInput:AddKeyDownHandler(cstick_left, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cleft1er"]) end end)
	
	AddModRPCHandler(TUNING.MODNAME, "cleft2er", cleft2)
	GLOBAL.TheInput:AddKeyUpHandler(cstick_left, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cleft2er"]) end end)
	GLOBAL.TheInput:AddControlHandler(ccstick_left, function() ccstick_leftdwn = RunControlWithCheck(ccstick_leftdwn, "cleft1er", "cleft2er") end)
	
	
	--CSTICK RIGHT
	local function cright1(player)
	if player:HasTag("lockcontrols") then return end
		player:AddTag("atk_key_dwn")
		player:PushEvent("attack_key")
		--4-23-20 HAVE 1 FRAME LISTENERS ON BOTH THE ATK AND JUMP KEY. IF EITHER KEYHANDLER DETECTS THE OTHER WAS JUST PRESSED, CANCEL WHATEVER TO BUFFER A JUMP AIREAL
		player.sg:AddStateTag("listen_for_atk")
		player:DoTaskInTime(0, function() --IT'S SAFER TO DO THIS AS A STATETAG SO THAT IF USERS ARE HIT OUT OF IT, IT WILL REMOVE ITSELF
			player.sg:RemoveStateTag("listen_for_atk")
		end)
		if (player.components.stats.event == "jump" and player.components.stats.buffertick >= 1) or player.sg:HasStateTag("listen_for_jump") then --4-18-20 FOR JUMP-BUFFERED AIREALS
			player.components.stats.key = player.components.keydetector:GetCStickDirection(player, "right") --IN CASE JUMP IS BUFFERING
		else
			player:PushEvent("cstick_side", {key = "right", key2 = "stick"})
			player.components.stats:SetKeyBuffer("cstick_side", "right", "stick")
		end
	end
	local function cright2(player)
	if player:HasTag("lockcontrols") then return end
	player:RemoveTag("atk_key_dwn")
		if player.sg:HasStateTag("chargingfsmash") then
			player.sg:GoToState("fsmash")
		end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "cright1er", cright1)
	GLOBAL.TheInput:AddKeyDownHandler(cstick_right, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cright1er"]) end end)
	
	AddModRPCHandler(TUNING.MODNAME, "cright2er", cright2)
	GLOBAL.TheInput:AddKeyUpHandler(cstick_right, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cright2er"]) end end)
	GLOBAL.TheInput:AddControlHandler(ccstick_right, function() ccstick_rightdwn = RunControlWithCheck(ccstick_rightdwn, "cright1er", "cright2er") end)
	
	
	
	
	
	local function special1(player)
	if player:HasTag("lockcontrols") then return end
		--11-7-17 REUSEABLE - WAIT!!! WHAT IF I... ADDED MORE DATA? LIKE INITIAL DIRECTION, FOR THROWSPECIAL TO COMPARE TO SEE IF IT'S DIRECTION HAS CHANGED SINCE THE KEY WAS PRESSED
		player:PushEvent("throwspecial", {key = player.components.keydetector:GetBufferKey(player), key2 = player.Transform:GetRotation()}) --11-7-17 INTRODUCING! KEY2! BRILLIANT. SHOULDVE USED THIS FOR ROLLING
		player.components.stats:SetKeyBuffer("throwspecial", player.components.keydetector:GetBufferKey(player), player.Transform:GetRotation())  --GOTTA ADD IT IN THE SETKEYBUFFER TOO!
		--TODOLIST  TEST TO SEE IF EVENT = "TROWATTACK" AND IF BUFFERTICK >= 3 AND IF IT IS, THEN THROW A GRAB EVENT INSTEAD
		player:AddTag("spc_key_dwn")
		
	end
	
	local function special2(player)
	if player:HasTag("lockcontrols") then return end
		player:RemoveTag("spc_key_dwn") 
	end
	
	AddModRPCHandler(TUNING.MODNAME, "special1er", special1)
	GLOBAL.TheInput:AddKeyDownHandler(special, function() if not GLOBAL.IsPaused() then 
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["special1er"]) 
		specialdwn = RunWithKeyCheck(specialdwn, function() SendModRPCToServer(MOD_RPC[modname]["special1er"])  end)
	end end)
	
	AddModRPCHandler(TUNING.MODNAME, "special2er", special2)
	GLOBAL.TheInput:AddKeyUpHandler(special, function() if not GLOBAL.IsPaused() then 
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["special2er"]) 
		specialdwn = false
	end end)
	GLOBAL.TheInput:AddControlHandler(cspecialc, function() RunControlDown(cspecialc, "special1er", "special2er") end)
	
	
	--UP
	local function up1(player)
	player.components.keydetector.holdingup = true  --DST CHANGE-- THIS ONE WORKS!!!
	player.components.keydetector.holdingdown = false
	if player:HasTag("lockcontrols") then return end
	-- if not player.components.keydetector.holdingup then
		player:PushEvent("up")
		player:AddTag("listen_for_usmash")
		player:DoTaskInTime((2*GLOBAL.FRAMES), function()
			player:RemoveTag("listen_for_usmash")
		end)
		
		--6-9-20 OK THERE HAS TO BE A DUPLICATE OF THE JUMP FUNCTION HERE BECAUSE OF TAPJUMP LISTENERS... IM SURE THERE IS A BETTER WAY TO DO THIS BUT I JUST WANT THIS DONE
		if player.components.stats.tapjump and player.components.jumper.currentdoublejumps > 0 then
			-- if not player:HasTag("jump_key_dwn") then --DONT NEED THIS FOR TAPJUMP
			if player.sg:HasStateTag("listen_for_atk") then
				player.components.stats:SetKeyBuffer("jump", player.components.stats.key, "tapup") --4-24-20 ACTUALLY, KEEP THE KEY BUFFER THE SAME, THE ATTACKS WILL SET THOSE
			else
				player:PushEvent("jump", {key2 = "tapup"}) --2-1-22 PASSING IN TAPUP TO SIGNIFY THAT WE'VE JUMPED USING TAPJUMP
				player.components.stats:SetKeyBuffer("jump", "ITSNIL", "tapup") --4-18-20 REMOVING THE KEYBUFFER CHECK, SINCE WE DONT USE IT HERE  --player.components.keydetector:GetBufferKey(player)
			end
			-- player.components.keydetector.tapup = true --2-1-22 TO SIGNIFY THAT WE'VE JUMPED USING TAPJUMP
			-- end
			-- player:AddTag("jump_key_dwn")
			--4-23-20 EXTRA BAGGAGE
			player.sg:AddStateTag("listen_for_jump")
			player:DoTaskInTime(0, function() 
				player.sg:RemoveStateTag("listen_for_jump")
			end)
		end
	-- end
	-- holdingup = true --DST CHANGE-- USING THE ONE BELOW INSTEAD OF THIS ONE
	end
	local function up2(player)
		player.components.keydetector.holdingup = false
	end
	
	AddModRPCHandler(TUNING.MODNAME, "up1er", up1)
	GLOBAL.TheInput:AddKeyDownHandler(up, function() if not GLOBAL.IsPaused() then 
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["up1er"]) 
		updwn = RunWithKeyCheck(updwn, function() SendModRPCToServer(MOD_RPC[modname]["up1er"])  end)
	end end)
	
	AddModRPCHandler(TUNING.MODNAME, "up2er", up2)
	GLOBAL.TheInput:AddKeyUpHandler(up, function() if not GLOBAL.IsPaused() then 
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["up2er"]) 
		updwn = false
	end end)
	--I GUESS THIS ONE WAS SO CONTROLLER SENSITIVE IT GETS IT'S OWN UNIQUE METHOD OF HANDLING IT THAT ISNT A CONTROLHANDLER
	
	
	--TAPJUMP  --NVM, CANT DO IT THIS WAY BECAUSE GETPLAYER DOESNT LISTEN FOR THE CLIENT. PUTTING IT UP IN THE UP FN
	--[[
	--6-9-20 ADDING IN A MORE CONVENTIONAL METHOD  --IF TAPJUMP=ENABLED, UP ALSO CALLS THE JUMP FUNCTION
	AddModRPCHandler(modname, "tapjump1er", jump1)
	GLOBAL.TheInput:AddKeyDownHandler(up, function() 
		if not GLOBAL.IsPaused() and GLOBAL.ThePlayer.components.stats.tapjump then 
			SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["tapjump1er"])
		end
	end)
	
	AddModRPCHandler(modname, "tapjump2er", jump2)
	GLOBAL.TheInput:AddKeyUpHandler(up, function() 
		if not GLOBAL.IsPaused() and GLOBAL.ThePlayer.components.stats.tapjump then 
			SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["tapjump2er"])
		end
	end)
	]]
	
	
	
	--DOWN
	local function down1(player)
	player.components.keydetector.holdingdown = true
	player.components.keydetector.holdingup = false 
	if player:HasTag("lockcontrols") then return end
	-- if not player.components.keydetector.holdingdown then
		player:PushEvent("down")
		if player.sg:HasStateTag("canoos") then
			player.sg:GoToState("spotdodge")
		else
			player:PushEvent("duck")
		end
		player:AddTag("listen_for_dsmash")
		player:DoTaskInTime((2*GLOBAL.FRAMES), function()
			player:RemoveTag("listen_for_dsmash")
		end)
	-- end
	end
	
	local function down2(player)
		player.components.keydetector.holdingdown = false
	end
	
	AddModRPCHandler(TUNING.MODNAME, "down1er", down1)
	GLOBAL.TheInput:AddKeyDownHandler(down, function() if not GLOBAL.IsPaused() then 
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["down1er"]) 
		downdwn = RunWithKeyCheck(downdwn, function() SendModRPCToServer(MOD_RPC[modname]["down1er"])  end)
	end end)
	
	AddModRPCHandler(TUNING.MODNAME, "down2er", down2)
	GLOBAL.TheInput:AddKeyUpHandler(down, function() if not GLOBAL.IsPaused() then 
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["down2er"])
		downdwn = false
	end end)
	GLOBAL.TheInput:AddControlHandler(cdown, function() cdowndwn = RunControlWithCheck(cdowndwn, "down1er", "down2er") end)
	
	
	
	
	
	--LEFT
	local function left1(player, aleft)
	player.components.keydetector.holdingleft = true --10-14-17 OH OK, THIS NEEDS TO BE UP HERE FOR ROLLS IN DST
	player.components.keydetector.holdingright = false --12-31-21 TO COMBAT THE BUG WHERE SOMEONES DIRECTIONAL KEY GETS "LOCKED" IN ONE DIRECTION AND THEYRE TOO STUPID TO TAP THE KEY TO UNDO IT
	if player:HasTag("lockcontrols") then return end
	-- if not player.components.keydetector.holdingleft then
	player:PushEvent("left") --1-25-22 W.. WHY WAS THIS ONE WAY UP HERE AGAIN?
	if player.components.launchgravity:GetRotationValue() == 1 then --1-6 FORWARD AND BACKWARD DETECTORS
		player:PushEvent("forward_key")
	else
		player:PushEvent("backward_key")
	end
	if not player.components.launchgravity:GetIsAirborn() then
		-- print("ALEFT?", aleft)
		if not aleft then player:RemoveTag("listen_for_dashr") end
		player:RemoveTag("listen_for_tapr")
		if (aleft and aleft >= 0.55) or (player:HasTag("listen_for_dash") and player:HasTag("listen_for_tap")) and not player.sg:HasStateTag("dashing") then --4-17-20 LETS TRY IGNORING BUSY 
			-- player:PushEvent("dash") --8-29-20 REMOVING SO THAT THE DASH EVENT ISNT PUSHED TWICE IN A ROW WITH THE BUFFER
			--4-17-20 TESTING A NEW BUFFERABLE KEYHANDLER THAT LETS YOU BUFFER DASHING! WOW I HAVENT BEEN TO THIS PART OF CODE IN A WHILE.. DONT BREAK ANYTHING PLS
			player.components.stats:SetKeyBuffer("dash", "left") --OH I DONT THINK I USE THE "LEFT/RIGHT" KEY2 VARIABLE ANYWHERE BUT ONE DAY I MIGHT
		end
		if not aleft then player:AddTag("listen_for_dash") end
		player:AddTag("listen_for_smash")
		player:AddTag("listen_for_roll") --7-17-17 EARLY ROLL WINDOW LISTENER
		player:DoTaskInTime(0.5, function() --2-7-17 CHANGING FROM 0.3 TO 0.5
			player:RemoveTag("listen_for_dash")
		end)
		player:DoTaskInTime((2*GLOBAL.FRAMES), function()
			player:RemoveTag("listen_for_smash")
			player:RemoveTag("listen_for_roll") --7-17-17
		end)
		-- 7-17-17 LETS BUFFER SOME DODGES
		if player.components.keydetector:GetBlock(player) then
			player:PushEvent("roll", {key = player.components.keydetector:GetLeftRight(player)})
			player.components.stats:SetKeyBuffer("roll", "left")
		end
	end
	-- end
	end
	local function left2(player)
	player.components.keydetector.holdingleft = false
	if player:HasTag("lockcontrols") then return end
		if player.sg:HasStateTag("dashing") then
			player:PushEvent("dash_stop")
		else
			player:AddTag("listen_for_tap")
			player:DoTaskInTime((4*GLOBAL.FRAMES), function()
				player:RemoveTag("listen_for_tap")
			end)
		end
		player:RemoveTag("wasrunning")
	end
	
	AddModRPCHandler(TUNING.MODNAME, "left1er", left1)
	GLOBAL.TheInput:AddKeyDownHandler(left, function() if not GLOBAL.IsPaused() then 
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["left1er"]) 
		leftdwn = RunWithKeyCheck(leftdwn, function() SendModRPCToServer(MOD_RPC[modname]["left1er"])  end)
	end end)
	
	AddModRPCHandler(TUNING.MODNAME, "left2er", left2)
	GLOBAL.TheInput:AddKeyUpHandler(left, function() if not GLOBAL.IsPaused() then 
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["left2er"]) 
		leftdwn = false
	end end)
	GLOBAL.TheInput:AddControlHandler(cleftc, function() if UsingController() then 
		cleftcdwn = RunControlWithCheck(cleftcdwn, "left1er", "left2er", GLOBAL.TheInput:GetAnalogControlValue(cleftc)) 
	end end)
	


	local function right1(player, aright)
	player.components.keydetector.holdingright = true
	player.components.keydetector.holdingleft = false --12-31-21
	if player:HasTag("lockcontrols") then return end
	-- if not player.components.keydetector.holdingright then
	player:PushEvent("right")
	-- print("RIGHT KEEEY")
	if player.components.launchgravity:GetRotationValue() == -1 then
		player:PushEvent("forward_key")
	else
		player:PushEvent("backward_key")
	end
	if not player.components.launchgravity:GetIsAirborn() then
		if not aright then player:RemoveTag("listen_for_dash") end
		player:RemoveTag("listen_for_tap")
		if (aright and aright >= 0.55) or (player:HasTag("listen_for_dashr") and player:HasTag("listen_for_tapr")) and not player.sg:HasStateTag("dashing") then
			-- player:PushEvent("dash") --8-29-20 REMOVING SO THAT THE DASH EVENT ISNT PUSHED TWICE IN A ROW WITH THE BUFFER
			player.components.stats:SetKeyBuffer("dash", "right") --4-17-20 TESTING A NEW BUFFERABLE KEYHANDLER THAT LETS YOU BUFFER DASHING
		end
		-- if player.components.stats.autodash == true then --11-9-17 TESTING AUTO-DASH
			-- player:PushEvent("dash") 
		-- end
		if not aright then player:AddTag("listen_for_dashr") end
		player:AddTag("listen_for_smash")
		player:AddTag("listen_for_roll") --7-17-17 EARLY ROLL WINDOW LISTENER
		player:DoTaskInTime(0.5, function() 
			player:RemoveTag("listen_for_dashr")
		end)
		player:DoTaskInTime((2*GLOBAL.FRAMES), function()
			player:RemoveTag("listen_for_smash")
			player:RemoveTag("listen_for_roll") --7-17-17
		end)
		-- 7-17-17 LETS BUFFER SOME DODGES
		if player.components.keydetector:GetBlock(player) then
			player:PushEvent("roll", {key = player.components.keydetector:GetLeftRight(player)})
			player.components.stats:SetKeyBuffer("roll", "right")
		end
	end
	-- end
	end
	local function right2(player)
	player.components.keydetector.holdingright = false
	if player:HasTag("lockcontrols") then return end
		if player.sg:HasStateTag("dashing") then
			player:PushEvent("dash_stop")
		else
			player:AddTag("listen_for_tapr")
			player:DoTaskInTime((4*GLOBAL.FRAMES), function()
				player:RemoveTag("listen_for_tapr")
			end)
		end
		player:RemoveTag("wasrunning")
	end
	
	AddModRPCHandler(TUNING.MODNAME, "right1er", right1)
	GLOBAL.TheInput:AddKeyDownHandler(right, function() if not GLOBAL.IsPaused() then 
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["right1er"]) 
		rightdwn = RunWithKeyCheck(rightdwn, function() SendModRPCToServer(MOD_RPC[modname]["right1er"])  end)
	end end)
	
	AddModRPCHandler(TUNING.MODNAME, "right2er", right2)
	GLOBAL.TheInput:AddKeyUpHandler(right, function() if not GLOBAL.IsPaused() then 
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["right2er"]) 
		rightdwn = false
	end end)
	GLOBAL.TheInput:AddControlHandler(crightc, function() if UsingController() then 
		crightcdwn = RunControlWithCheck(crightcdwn, "right1er", "right2er", GLOBAL.TheInput:GetAnalogControlValue(crightc)) 
	end end)
	
	
	--DST- JUST AN EASIER BLOCK BUTTON --WHAT ARE THESE STILL DOING HERE?? THOSE KEYS WERENT EVEN DEFINED
	-- GLOBAL.TheInput:AddKeyDownHandler(block2, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["block1er"]) end end)
	-- GLOBAL.TheInput:AddKeyUpHandler(block2, function() if not GLOBAL.IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["block2er"]) end end)
	
	
	
	
	
	
	
	local cattack2 = GLOBAL.KEY_2  --[50] --A
	local cspecial2 = GLOBAL.KEY_3
	local cgrab2 = GLOBAL.KEY_4 --RIGHT TRIGGER
	-- local cgrab_alt = GLOBAL.CONTROL_ROTATE_LEFT --LB
	-- local cjump = GLOBAL.CONTROL_USE_ITEM_ON_ITEM  --X -DEFAULT
	-- local cjump_alt = GLOBAL.KEY_1
	-- local cblock = GLOBAL.CONTROL_MAP_ZOOM_IN --L TRIGGER  --IT APPEARS HAVING THIS SET AS THE SAME KEY THAT OPENS CRAFTING MAKES BIG PROBLEMS. SET CRAFTING TO A DIFFERENT BUTTON TO FIX IT
	-- local cblock_alt = GLOBAL.CONTROL_MAP_ZOOM_OUT --R TRIGGER
	-- local cup = GLOBAL.CONTROL_MOVE_UP
	-- local cdown = GLOBAL.CONTROL_MOVE_DOWN
	-- local cleftc = GLOBAL.CONTROL_MOVE_LEFT
	-- local crightc = GLOBAL.CONTROL_MOVE_RIGHT
	-- local ccstick_up = GLOBAL.CONTROL_INVENTORY_UP
	-- local ccstick_down = GLOBAL.CONTROL_INVENTORY_DOWN
	-- local ccstick_left = GLOBAL.CONTROL_INVENTORY_LEFT
	-- local ccstick_right = GLOBAL.CONTROL_INVENTORY_RIGHT
	-- local csmash = GLOBAL. CONTROL_CONTROLLER_ATTACK 
	
	-- GLOBAL.TheInput:OnControlMapped(deviceId, controlId, inputId, hasChanged) --deviceId, controlId, inputId, hasChanged
	--WTF EVEN IS INPUTID? I DONT THINK IT ACTUALLY MATTERS... WAIT, MAYBE IT NEEDS TO ALWAYS BE THIS
	-- local inputid = 0xFFFFFFFF
	-- GLOBAL.TheInput:OnControlMapped(deviceId, controlId, inputId, hasChanged)
	
	-- GLOBAL.TheInput:AddControlHandler(cspecialc, function() RunControlDown(cspecial2, "special1er", "special2er") end)
	-- local guid, data, enabled = GLOBAL.TheInputProxy:SaveControls(1)
	-- print("SAVE CONTROLS", guid, data, enabled)
	
	
	--1311794729	CQAAAAYAAAABAAAAAIAAAAAAAAAAAAAAAQAAAAAQAAAAAAAAAQAAAAAgAAAAAAAAAQAAAAABAAAAAAAAAgAAAAQAAAABAAAAAQAAAEAAAAAAAAAAAQAAAAACAAAAAAAAAgAAAAUAAAABAAAAAQAAAIAAAAAAAAAAAQAAAAEAAAAAAAAAAQAAAAIAAAAAAAAAAQAAAAQAAAAAAAAAAQAAAAgAAAAAAAAAAQAAACAAAAAAAAAAAQAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAUAAAABAAAAAgAAAAQAAAABAAAAAQAAAAgAAAAAAAAAAQAAAAIAAAAAAAAAAQAAAABAAAAAAAAAAQAAAABAAAAAAAAAAQAAAAAQAAAAAAAAAQAAAAQAAAAAAAAAAQAAAAEAAAAAAAAAAQAAAAAgAAAAAAAAAQAAAACAAAAAAAAAAgAAAAQAAAABAAAAAgAAAAUAAAABAAAAAgAAAAIAAAAAAAAAAgAAAAIAAAABAAAAAQAAAAABAAAAAAAAAQAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAgAAAAAAAAAABAAAAAEAAAAAAAAABAAAAAIAAAAAAAAABAAAAQAAAAAAAAAABAAAAgAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAIAAAAAAAAAAQAAAAIAAAABAAAAAAAAAAIAAAABAAAAAQAAAAIAAAACAAAAAAAAAAIAAAACAAAAAQAAAAIAAAADAAAAAAAAAAIAAAADAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=	true	

end

AddSimPostInit( applykeyhandlers )



	

--9-22-17 NOW USING JUST ONE RPC. THE ONE THAT TELLS THE SERVER THAT THE PLAYER HAS CHOSEN.
AddModRPCHandler(modname, "confirmcharselect", function (player, team)

	player:AddTag("readyfreddy")
	local anchor = GLOBAL.TheSim:FindFirstEntityWithTag("anchor")
	--local team = "auto"
	if team then
		anchor.components.gamerules:ReserveTeam(player, team)
	end
	-- {reserver = player, team = "auto"}
end)


--5-22-20 ANOTHER RPC - IF PLAYERS FAIL TO SELECT A CHARACTER OR JUST WANT TO SPECTATE
local function bailchar(player)
	player:AddTag("select_bailed")
	--IF THEYRE A STORED WINNER, REVOKE THEIR WINNER-STAYS PRIVELEGES
	local anchor = GLOBAL.TheSim:FindFirstEntityWithTag("anchor")
	anchor.components.gamerules:RetireBailedWinner(player)
end
AddModRPCHandler(modname, "bail_charselect", bailchar) 


--3-4-19 OK THERE ARE A LOT MORE BUTTONS ON THIS MENU THAN I THOUGHT. CAN I GET A GENERIC BUTTON HANDLER? NUTHIN FANCY
--local function genericmenuhandle(player) --OH RIGHT I FORGOT YOU CAN JUST DO IT LIKE THE WAY BELOW. SHORTCUT
AddModRPCHandler(modname, "gen_menu_handler", function (player, menuinput)
	local anchor = GLOBAL.TheSim:FindFirstEntityWithTag("anchor")
	--I MEAN THIS ISNT A "KEY" AND THIS SEEMS LIKE A WEIRD WAY TO DO IT, BUT... I HATE MENUS SO WHATEVER WORKS
	--anchor:PushEvent("menu_input", {key = player.components.keydetector.menukey})
	--player.components.keydetector.menukey = nil
	--NO NO, THATS SILLY. BETTER IDEA. TACKY IDEA, BUT SIMPLER IDEA.
	
	
	if menuinput == "horde" then --THIS IS DEPRECIATED AT THIS POINT. IF USED, WILL START HORDE MODE AT WHATEVER LEVEL WAS PREVIOUSLY SELECTED
		anchor.components.hordes:PrepareHordeMode()
	--8-19-20 WE WANT THE DIFFERENT BUTTONS TO START DIFFERENT LEVELS OF HORDE MODE
	elseif menuinput == "horde1" then 
		anchor.components.hordes:PrepareHordeMode(1) --WE NOW PASS IN THE LEVEL WE WANT TO START
	elseif menuinput == "horde2" then 
		anchor.components.hordes:PrepareHordeMode(2)
	elseif menuinput == "horde3" then 
		anchor.components.hordes:PrepareHordeMode(3)
	elseif  menuinput == "vs_harold" then
		anchor.components.gamerules.cpulevel = 10
	elseif  menuinput == "retry_horde" then --MAN I LOVE THIS GENERIC INPUT HANDLER SO MUCH
		anchor.components.hordes:RetryHordeMode()
	elseif  menuinput == "quit_horde" then
		anchor.components.hordes:EndHordeMode()
	elseif  menuinput == "begin_session" then --8-21-20
		anchor.components.gamerules:BeginSession()
	elseif menuinput == "disconnecting" then
		player:AddTag("flag_disconnect")
	end
end)
--SO NOW WHENEVER YOU WANT THE PLAYER TO SEND A MENU BUTTON THING TO THE SERVER, USE THIS: SendModRPCToServer(MOD_RPC[modname]["gen_menu_handler"])
--BUT SET player.components.keydetector.menukey TO THE KEY YOU WANT FIRST


--8-20-20 CHANGE THE CPU DIFFICULTY FROM THE MENU
AddModRPCHandler(modname, "set_cpu_lvl", function (player, difvalue)
	local anchor = GLOBAL.TheSim:FindFirstEntityWithTag("anchor")
	anchor.components.gamerules.cpulevel = difvalue
	-- print("ALTERING CPU LEVEL: ", difvalue)
end)


--8-21-20
AddModRPCHandler(modname, "setservergamemode", function (player, mode)
	local anchor = GLOBAL.TheSim:FindFirstEntityWithTag("anchor")
	local old_gamemode = anchor.components.gamerules.gamemode
	anchor.components.gamerules.gamemode = mode
	print("--ALTERING SERVER GAMEMODE: ", mode)
	
	--IF WE'RE ON A CHARACTER SELECT SCREEN (PREP PHASE) WE SHOULD JUST RESTART THE GAME RIGHT AWAY, RIGHT?
	local matchstate = anchor.components.gamerules.matchstate
	if (matchstate == "prep" or matchstate == "endgame") and old_gamemode ~= mode then --ALSO ENDGAME, SINCE HORDE VICTORYS END UP THERE
		anchor.components.gamerules:StageReset()
	end
	
	--I THINK WE CAN SAFELY DO THIS INSTANTLY
	if mode == "PRACTICE" then
		anchor.components.gamerules:ChangeMatchState("lobby")
	end
	
	--1-23-22 A LITTLE MORE FORCEFULLY NOW...
	if mode == "PRACTICE_FORCE" then
		anchor.components.gamerules:ChangeMatchState("lobby")
		anchor.components.gamerules:StageReset()
	end
	
	if mode == "HORDE" and  matchstate == "endgame" then --ALSO ENDGAME, SINCE HORDE VICTORYS END UP THERE
		anchor.components.gamerules:StageReset()
	end
	
	--IF WE ARE SWITCHING OFF OF HORDE MODE, DOUBLE CHECK THAT THIS GETS TURNED OFF!!
	if mode ~= "HORDE" then --WAIT, BUT THIS SAYS VS-AI?...
		anchor.components.gamerules.hordemode = false
	end
end)


AddModRPCHandler(modname, "setpvpoptions", function (player, option, value)
	-- local anchor = GLOBAL.TheSim:FindFirstEntityWithTag("anchor")
	-- anchor.components.gamerules.gamemode = mode
	print("--SETTING PVP SETTINGS: ", option, value)
	
	--
	if option == "fightercount" then
		GLOBAL.TUNING.SMASHUP.MATCHSIZE = value
		for i, v in ipairs(GLOBAL.AllPlayers) do v.smashmatchsizenetvar:set(value) end
	end
	
	if option == "livescount" then
		GLOBAL.TUNING.SMASHUP.MATCHLIVES = value
		for i, v in ipairs(GLOBAL.AllPlayers) do v.smashmatchlivesnetvar:set(value) end
	end
	--
	if option == "teams" then
		GLOBAL.TUNING.SMASHUP.TEAMS = value
		for k, v in pairs(GLOBAL.AllPlayers) do v.smashteamsnetvar:set(value) end
	end
	if option == "teamselect" then
		GLOBAL.TUNING.SMASHUP.TEAMSELECT = value
		for k, v in pairs(GLOBAL.AllPlayers) do v.smashteamselectnetvar:set(value) end
	end
	if option == "teamsizecr" then
		GLOBAL.TUNING.SMASHUP.TEAMSSIZECR = value
		for k, v in pairs(GLOBAL.AllPlayers) do v.smashteamsizecrnetvar:set(value) end
	end
	if option == "teamfill" then
		GLOBAL.TUNING.SMASHUP.OPENTEAMFILL = value
		for k, v in pairs(GLOBAL.AllPlayers) do v.smashopenteamfillnetvar:set(value) end
	end
	
	--/SIGH- WELL THIS ONLY UPDATES THE SERVER END, BUT MANY OF THESE ARE NEEDED ON THE CLIENT END TOO.
end)

--THEN I GUESS WE'LL DO THAT.
local function settingslister(inst) 
	
	inst.smashmatchsizenetvar = GLOBAL.net_byte(inst.GUID, "a_thing1", "matchsettingdirty") 
	inst.smashmatchlivesnetvar = GLOBAL.net_byte(inst.GUID, "a_thing2", "matchsettingdirty") 
	inst.smashteamsnetvar = GLOBAL.net_byte(inst.GUID, "a_thing3", "matchsettingdirty") 
	inst.smashteamselectnetvar = GLOBAL.net_byte(inst.GUID, "a_thing4", "matchsettingdirty") 
	inst.smashteamsizecrnetvar = GLOBAL.net_byte(inst.GUID, "a_thing5", "matchsettingdirty") 
	inst.smashopenteamfillnetvar = GLOBAL.net_byte(inst.GUID, "a_thing6", "matchsettingdirty") 
	
	inst.smashmatchsizenetvar:set(GLOBAL.TUNING.SMASHUP.MATCHSIZE)
	inst.smashmatchlivesnetvar:set(GLOBAL.TUNING.SMASHUP.MATCHLIVES) 
	inst.smashteamsnetvar:set(GLOBAL.TUNING.SMASHUP.TEAMS) 
	inst.smashteamselectnetvar:set(GLOBAL.TUNING.SMASHUP.TEAMSELECT) 
	inst.smashteamsizecrnetvar:set(GLOBAL.TUNING.SMASHUP.TEAMSSIZECR) 
	inst.smashopenteamfillnetvar:set(GLOBAL.TUNING.SMASHUP.OPENTEAMFILL)
	
end
AddPlayerPostInit(settingslister)





	
	
	

	
--10-7-17 DST- THIS WILL STORE CONTROL PREFERENCES CLIENT-SIDE SO THAT THEY DONT RESET WHEN RESPAWNING.
GLOBAL.Preftapjump = "on"
GLOBAL.Prefautodash = "on"
GLOBAL.Preftapjump_p2 = "on" --10-25-20
GLOBAL.Preftiltstick = "smash" --1-13-22
GLOBAL.Prefmusic = "on"
GLOBAL.Unlocklevel = "0" --10-13-21
GLOBAL.Skinchoice = nil --1-12-22


--11-25-20 OH. OK. THATS WAY MORE CONVENIENT
-- GLOBAL.MODCONTROLS = GLOBAL.KnownModIndex:IsModEnabled("workshop-2298228108") --THE SMASHUP CONTROLS MOD
GLOBAL.MODCONTROLS = GLOBAL.KnownModIndex:IsModEnabled("workshop-2298228108") --12-4-21 AND THEN THEY CHANGED THE MOD STRUCTURE
-- GLOBAL.MODCONTROLS = GLOBAL.KnownModIndex:IsModEnabled("Smashup Custom Controls")

if GLOBAL.MODCONTROLS and GLOBAL.MODCONTROLS == true then
	GLOBAL.Preftapjump = GLOBAL.SMASHCONTROLS.TAPJUMP_DEF
	GLOBAL.Prefautodash = GLOBAL.SMASHCONTROLS.AUTODASH_DEF -- or "on"
	GLOBAL.Preftiltstick = GLOBAL.SMASHCONTROLS.TILTSTICK_DEF
end



--10-7-17 MAKING SOME IMPROVEMENTS.
local function rectrl(player, pref) --NOW THE TAPJUMPPREF GLOBAL IS PASSED IN FOR IT TO CHOOSE
	-- if player.components.stats.tapjump == false then
	if pref == "on" then
		player.components.stats.tapjump = true
	else
		player.components.stats.tapjump = false
	end
	-- print("SETTING TAPJUMP PREF", pref, player)
	-- print("WHATS MY TAPJUMP??", pref, GLOBAL.Preftapjump, player)
end
AddModRPCHandler(modname, "rectrler", rectrl)


local function respectate(player) --1-18-22
	local anchor = GLOBAL.TheSim:FindFirstEntityWithTag("anchor")
	anchor.components.gamerules:ToggleSpectateOnly(player)
end
AddModRPCHandler(modname, "respectator", respectate)


--FOR SETTING AUTODASH --WOW THAT WAS FAST
local function reautodash(player, pref) 
	-- print("SETTING AUTODASH PREF", pref, player)
	if pref == "on" then
		player.components.stats.autodash = true
	else
		player.components.stats.autodash = false
	end
end
AddModRPCHandler(modname, "reautodash", reautodash)


local function retiltstick(player, pref) 
	-- print("SETTING TILTSTICK PREF", pref, player)
	player.components.stats.tiltstick = pref
end
AddModRPCHandler(modname, "retiltstick", retiltstick)



--1-13-22 REMOVING THIS SINCE THIS SHOULD ONLY NEED TO BE TRACKED CLIENTSIDE
--[[
local function controllerchecker(player, value) 
	if not player.components.keydetector then 
		return end --6-15-20 CAUSED A CRASH SO THIS SHOULD PREVENT IT
	
	player.components.keydetector.controllerbound = value
	-- player.components.keydetector.controllerbound = value
end
AddModRPCHandler(modname, "controllerchecker", controllerchecker)
]]

--SHOW OTHER PLAYERS WHO ARE TYPING STUFF
local function speechpreview(player, value) 
	if player.components.talker then
		player.components.talker:Say(". . .", 8, true)
	end
	
	--1-1-22 ALSO FORCEABLY UNPRESS ANY MOVEMENT KEYS PLEASE
	if player.components.keydetector then
		player.components.keydetector.holdingright = false
		player.components.keydetector.holdingleft = false
	end
end
AddModRPCHandler(modname, "speechpreview", speechpreview)


--1-12-22
local function skinselector(player, value) 
	player.components.stats.skinnum = value
	-- print("SKINSELECTOR RPC", value)
end
AddModRPCHandler(modname, "skinselector", skinselector)


	
	
	
	--I had a lot of trouble with netvariables okay?

--8-31-17 -ALRIGHT, GIVING IT ANOTHER TRY -- AAH YEESSSS IT WOOORKS. JUST DONT FORGET TO UPDATE THE BADGES
--5-22-17 DST-- THIS HUD WILL BE THE DEATH OF ME I SWEAR --VERSION FROM PARTY HUDS  --NO! ABSOLUTELY NOTHING WORKS
--server functions
local function onhealthdelta(inst, data)
	--I GUESS THIS ONE JUST DOES NOTHING?
end

-- When somebody's health changes, it triggers the badges health update
local function oncustomhpbadgedirty(inst)
	-- print("ONCUSTOMHPBADGEDIRTY. CUSTOM HP HAS CHNGED SOMEWHERE", inst.customhpbadgepercent:value())
	if GLOBAL.ThePlayer then --1-3-22 APPARENTLY, THEPLAYER CAN BE NIL SOMETIMES (PROBABLY AS PPL ARE CONNECTING) SO JUST TO BE SAFE...
		GLOBAL.ThePlayer.UpdateBadges() 	--IM THROWING UPDATEBADGES IN THE STATUSDISPLAYS FILE TO CATCH IT
	end
end


local function customhppostinit(inst)
	-- Net variable that stores between 0-255; more info in netvars.lua
	-- GUID of entity, unique identifier of variable, event pushed when variable changes
	-- Event is pushed to the entity it refers to, server and client side wise

	--9-1-17 THIS NETVAR IS ACTUALLY CHANGED IN PERCENT.LUA IN DODAMAGE() NOW.
	-- inst.customhpbadgepercent = GLOBAL.net_byte(inst.GUID, "customhpbadge.percent", "customhpbadgedirty") --THIS ONE IS TOO SMALL!!! DOES WEIRD THINGS PAST 255
	inst.customhpbadgepercent = GLOBAL.net_ushortint(inst.GUID, "customhpbadge.percent", "customhpbadgedirty")

	inst.customhpbadgelives = GLOBAL.net_byte(inst.GUID, "customhpbadge.lives", "customhpbadgedirty") --9-2-17 --JUST RUN THE SAME AS HP I GUESS
	
	--1-31-22
	inst.skinnumnetvar = GLOBAL.net_byte(inst.GUID, "dummy.skins", "skinnumchange") --9-2-17 --JUST RUN THE SAME AS HP I GUESS
	inst.skinnamenetvar = GLOBAL.net_string(inst.GUID, "dummy.skinames", "skinnamechange") --9-2-17 --JUST RUN THE SAME AS HP I GUESS

	
	-- Server (master simulation) reacts to health and changes the net variable
	if GLOBAL.TheWorld.ismastersim then
		inst:ListenForEvent("percentdelta", onhealthdelta)	
	end

	-- Dedicated server is dummy player, only players hosting or clients have the badges
	-- Only them react to the event pushed when the net variable changes
	if not GLOBAL.TheNet:IsDedicated() then
		inst:ListenForEvent("customhpbadgedirty", oncustomhpbadgedirty)
		--HEY WAIT THIS IS FOR ON DEATH NOT ON HEALTH!?!?!?
		-- inst:ListenForEvent("ondeathdeltadirty", ondeathdeltadirty)
		
		--9-2-17 HEY, LETS TRY ONE FOR LIVES TOO
		-- inst:ListenForEvent("customhpbadgedirty", oncustomhpbadgedirty) --YOU JUST RE-MADE THE EXACT SAME THING...
		--10-10-20 YOU SURE DID!! AND ITS BEEN RUNNING THIS TWICE ALL THE WAY BACK SINCE 2017, YA NITWIT! >:[
		--SO.. HOW DOES THE LIVES BADGE ACTUALLY GET UPDATED?? /SHRUG/ I GUESS I WONT QUESTION IT
		
		--1-31-22
		inst:ListenForEvent("skinnumchange", function(inst) 
			if inst and inst.components and inst.components.stats then 
				inst.components.stats.skinnum = inst.skinnumnetvar:value()
			end
		end)
		
		inst:ListenForEvent("skinnamechange", function(inst) 
			if inst and inst.components and inst.components.stats then 
				inst.components.stats.buildname = inst.skinnamenetvar:value()
			end
		end)
	end
end
-- Apply function on player entity post initialization
AddPlayerPostInit(customhppostinit) --OH.... I FORGOT TO TURN IT ON






	
--10-6-17 LETS SEE IF I CAN DO THIS TWICE... AYYYY! TOOK ME A WHILE BUT I DID IT!
local function ongamesetdirty(inst)
	if inst and inst.EndGameScreen then
		inst.EndGameScreen()
	end
end

local function onpostgamedirty(inst)
	if inst and inst.PostGameOptions then --9-29-20 MAYBE??...
		inst.PostGameOptions() --8-15-20
	end
end

--1-20-22 MAYBE THIS TIME WE'LL ALMOST USE THESE CORRECTLY
local function ongamerstatusdirty(inst)
	if GLOBAL.ThePlayer and inst == GLOBAL.ThePlayer then
		local val = inst.gamerstatus:value()
		if val == "remote_select_string" then
			GLOBAL.ThePlayer:PushEvent("show_select_screen")
		end
	end
end


local function gamesetpostinit(inst)
	inst.gamesetnetvar = GLOBAL.net_string(inst.GUID, "gamesetvar.winner", "gamesetdirty")
	-- inst.gamesetnetvar:set("MISSING") --HAS TO BE NUMBER (BECAUSE ITS DEFINED AS A BYTE)
	
	--8-15-20 FOR A DIFFERENT KIND OF ENDGAME THAT DISPLAYS A MENU INSTEAD
	inst.postgamenetvar = GLOBAL.net_string(inst.GUID, "postgamevar.ted", "postgamedirty")
	
	--1-20-22
	inst.gamerstatus = GLOBAL.net_string(inst.GUID, "balogna", "gamerstatusdirty")
	
	-- Dedicated server is dummy player, only players hosting or clients have the badges
	-- Only them react to the event pushed when the net variable changes
	if not GLOBAL.TheNet:IsDedicated() then
		inst:ListenForEvent("gamesetdirty", ongamesetdirty)
		inst:ListenForEvent("postgamedirty", onpostgamedirty)
		inst:ListenForEvent("unlocktierdirty", onunlocktierdirty)
		
		--1-20-22 LETS TRY A NEW NETVAR THAT DOES A FEW USEFUL THINGS. MAINLY, TELLS A CLIENT WHAT MENUS THEY SHOULD BE SHOWING WHEN THEY LOAD IN.
		inst:ListenForEvent("gamerstatusdirty", ongamerstatusdirty)
	end
	
end
-- Apply function on player entity post initialization
AddPlayerPostInit(gamesetpostinit)





--10-8-17 AND A THIRD TIME?
--JUMBOTRON IS A SIMPLE TEXT SCREEN LIKE A COPY OF GAMESET BUT FOR ANY TEXT. BASICALLY A SUPER NETANNOUNCE FOR CLIENTS
local function onjumbotrondirty(inst)
	if GLOBAL.ThePlayer and GLOBAL.ThePlayer.ShowJumboMessage then --IN THE RARE, RAREST OF CASES WHERE THE CHARACTER SELECT BEGINS RIGHT AS WE GET A PROMPT
		GLOBAL.ThePlayer.ShowJumboMessage() --PASSES INTO THE JUMBOTRON.LUA WIDGET
	end
end

local function onjumboheaderdirty(inst)
	if GLOBAL.ThePlayer and GLOBAL.ThePlayer.ShowJumboHeaderMessage then
		GLOBAL.ThePlayer.ShowJumboHeaderMessage() 
	end
end


local function jumbotronpostinit(inst)

	inst.jumbotronmessage = GLOBAL.net_string(inst.GUID, "jumbo.text", "jumbotrondirty")
	inst.jumbotronheader = GLOBAL.net_string(inst.GUID, "jumbo.text2", "jumbotronheaderdirty")
	
	-- Dedicated server is dummy player, only players hosting or clients have the badges
	-- Only them react to the event pushed when the net variable changes
	if not GLOBAL.TheNet:IsDedicated() then
		inst:ListenForEvent("jumbotrondirty", onjumbotrondirty)
		inst:ListenForEvent("jumbotronheaderdirty", onjumboheaderdirty)
	end
	
end
-- Apply function on player entity post initialization
AddPlayerPostInit(jumbotronpostinit)





--10-17-17 ONE MORE FOR BRINGING UP THE CONTROLS SCREEN
local function oncontrolscreendirty(inst)
	if GLOBAL.ThePlayer and GLOBAL.ThePlayer.ShowControlScreen then
		GLOBAL.ThePlayer.ShowControlScreen() --PASSES INTO THE JUMBOTRON.LUA WIDGET
	end
end

local function contrlscreenpostinit(inst)

	inst.controlscreennetvar = GLOBAL.net_string(inst.GUID, "control.text", "controlscreendirty")
	
	if not GLOBAL.TheNet:IsDedicated() then
		inst:ListenForEvent("controlscreendirty", oncontrolscreendirty)
	end
	
end
-- Apply function on player entity post initialization
AddPlayerPostInit(contrlscreenpostinit)


--AM... I DOING THIS RIGHT? AM I SUPPOSED TO MAKE A SEPERATE INIT FUNCTION LIKE THIS FOR EVERY NETVAR? OR AM I DUMB AND I SHOULD BE PUTTING THESE ALL IN ONE POSTINIT FN

--12-7-17 OKAY OKAY, ANOTHER ONE. FOR THE CINNIMATIC (HOW DO YOU SPELL THAT???) CAMERA PAN WHEN THE ROUND STARTS
local function oncambumpdirty(inst)
	GLOBAL.TheCamera:RoundStartBump()
	
	--1-21-22 NOW MIGHT BE A GOOD TIME TO NUDGE THEIR CURSOR OUT OF THE WAY
	if GLOBAL.TheSim then
		local w,h = GLOBAL.TheSim:GetScreenSize()
		GLOBAL.TheInputProxy:SetOSCursorPos(w-1, h-1)
	end
end

local function onminibumpdirty(inst)
	GLOBAL.TheCamera:MiniBump()	--THIS IS VERY EFFECTIVE AT MAKING THE GRUE FLASHES MORE VISIBLE AT ANGLES
end

local function cambumppostinit(inst)

	inst.cambumpnetvar = GLOBAL.net_string(inst.GUID, "uhdoweneedthis.text", "cambumpdirty")
	inst.minibumpnetvar = GLOBAL.net_string(inst.GUID, "perhapsthis.text", "minibumpdirty")
	--SO DO WE ONLY NEED THE EVENT LISTENER FOR THIS ONE?? OR THE NET VARIABLE?
	
	if not GLOBAL.TheNet:IsDedicated() then
		inst:ListenForEvent("cambumpdirty", oncambumpdirty)
		inst:ListenForEvent("minibumpdirty", onminibumpdirty)
	end
end
AddPlayerPostInit(cambumppostinit)



--12-26-17 LETS DO SOME TIMER RELATED ONES
local function onsunresetdirty(inst)
	-- GLOBAL.TheWorld:PushEvent("ms_nextcycle") --NOO THIS WILL HAPPEN EVERY TIME
	local segs = { day = 1, dusk = 0, night = 0, time = 30} --BRING OUT THE SUNSHINE!
	GLOBAL.TheWorld:PushEvent("ms_setclocksegs", segs)
	-- print("HERE COMES THE SUN!")
end

local function sunresetpostinit(inst) --HEY UM- TYPO?? THESE ARE THE SAME NAME
	-- inst.minibumpnetvar = GLOBAL.net_string(inst.GUID, "perhapsthis.text", "minibumpdirty")
	--SO DO WE ONLY NEED THE EVENT LISTENER FOR THIS ONE?? OR THE NET VARIABLE?  
	--YES YOU DO!! THIS IS CURRENTLY DOING NOTHING CLIENTSIDE
	if not GLOBAL.TheNet:IsDedicated() then
		inst:ListenForEvent("sunresetdirty", onsunresetdirty)
	end
end
AddPlayerPostInit(sunresetpostinit)



--5-23-20 NOW FOR SOME CHARACTER SELECT FORCE ENDS
local function onselecttimeoutdirty(inst)
	-- print("onselecttimeoutdirty")
	if GLOBAL.ThePlayer then
		GLOBAL.ThePlayer:PushEvent("force_end_charselect_dirty") --EVENT LISTENED FOR CLIENTSIDE BY THE SELECT MENU
	end
end

local function speakselfdirty(inst)
	
	-- print("GET PING", inst, GLOBAL.TheNet:GetAveragePing())
	if GLOBAL.ThePlayer and inst == GLOBAL.ThePlayer then
		SendModRPCToServer(MOD_RPC[modname]["checkping"], GLOBAL.TheNet:GetAveragePing())
	end
	
	-- print("speakselfdirty")
	if inst and inst.mypingnetvar then
		--1-25-22 CAN WE SHOUT OUT OUR PING AS WELL?
		-- local sayhi = tostring(inst:GetDisplayName()).."\n".."(ping: "..tostring(math.max(0, GLOBAL.TheNet:GetAveragePing()))..")"
		inst:DoTaskInTime(0.5, function()
			local sayhi = tostring(inst:GetDisplayName()).."\n".."(ping: "..tostring(math.max(0, inst.mypingnetvar:value()))..")"
			inst.components.talker:Say(sayhi, 5, true) --NOICE. DIDN'T EXPECT THIS TO WORK HONESTLY
		end)
	end
end

local function selecttimeoutpostinit(inst)
	--OK SO THESE ARBITRARY NET LISTENER VALUES ARE MANDITORY. YOU CANT JUST LISTEN FOR AN EVENT, YOU HAVE TO SET A NET VALUE :/
	inst.timeoutnetvar = GLOBAL.net_string(inst.GUID, "dummy1.text", "force_end_charselect")
	--ALSO; NEVER USE THE SAME "dummy1.text" VALUE ON ANOTHER NETVAR OR THE GAME WILL CRASH
	
	inst.speakselfnetvar = GLOBAL.net_string(inst.GUID, "dummyhi.text", "speak_self")
	inst.mypingnetvar = GLOBAL.net_ushortint(inst.GUID, "dummy.ping", "nothing")
	
	if not GLOBAL.TheNet:IsDedicated() then --VVV EVENT PUSHED BY SMASHGAMELOGIC AT THE END OF THE SELECT TIMER
		inst:ListenForEvent("force_end_charselect", onselecttimeoutdirty)
		
		inst:ListenForEvent("speak_self", speakselfdirty)
	end
end
AddPlayerPostInit(selecttimeoutpostinit)


--2-4-22 
AddModRPCHandler(modname, "checkping", function (player, value)
	-- print("--CHECKING PING: ", player, value)
	player.mypingnetvar:set(math.max(0,value)) 
end)







--AND ONE TO REVERT PLAYER'S CHARACTER SELECTIONS IF THE MATCH WASNT ABLE TO START CORRECTLY THE FIRST TIME
local function onrevertcharselectdirty(inst)
	-- print("revert_charselect_dirty")
	GLOBAL.Reincarne = "spectator2"
	if GLOBAL.ThePlayer then
		GLOBAL.ThePlayer:PushEvent("revert_charselect_dirty") --EVENT LISTENED FOR CLIENTSIDE BY THE SELECT MENU
	end
end

local PopupDialogScreen 	= require("screens/popupdialog")
local function revertcharselectpostinit(inst)
	--OK SO THESE ARBITRARY NET LISTENER VALUES ARE MANDITORY. YOU CANT JUST LISTEN FOR AN EVENT, YOU HAVE TO SET A NET VALUE :/
	inst.revertnetvar = GLOBAL.net_string(inst.GUID, "dummy2.text", "revert_charselect")
	inst.stagegenmsgnetvar = GLOBAL.net_string(inst.GUID, "dummy5.text", "stagegen_msg")
	
	if not GLOBAL.TheNet:IsDedicated() then --VVV EVENT PUSHED BY SMASHGAMELOGIC AT THE END OF THE SELECT TIMER
		inst:ListenForEvent("revert_charselect", onrevertcharselectdirty)
		
		inst:ListenForEvent("stagegen_msg", function()
			local text = GLOBAL.STRINGS.SMSH.STAGEGEN_MSG
			--"Almost Ready..."
			local hunt_message = PopupDialogScreen( GLOBAL.STRINGS.SMSH.HUNT_MSG_1, text, {{text=GLOBAL.STRINGS.SMSH.HUNT_MSG_2, cb = function() GLOBAL.TheFrontEnd:PopScreen() end}} )
			hunt_message.text:SetPosition(5, 0, 0)
			hunt_message.menu:SetPosition(0, -80, 0) 
			GLOBAL.TheFrontEnd:PushScreen( hunt_message )
		end)
	end
end
AddPlayerPostInit(revertcharselectpostinit)



--10-13-21 HAVING A UNIQUE NETVAR TO KEEP TRACK OF IF THE BONUS CHARACTER SHOULD BE AVAILABLE OR NOT BECAUSE IM TOO DUMB TO PULL THOSE VALUES PROPERLY
local function unlockstatus(inst) 
	
	inst.unlockstatusnetvar = GLOBAL.net_byte(inst.GUID, "dummy4.text", "unlockstatusdirty") --unlockstatusdirty WILL REMAIN UNUSED
	--SO WE HAVE THE VALUE, BUT WE DON'T NEED TO LIKE, RUN AN EVENT OR ANYTHING... CAN WE JUST SKIP THE EVENT HANDLER? I'M GONNA TRY IT
	--AND WE'LL JUST REFERENCE THE VALUE WHEN WE NEED IT
	--YEA, BECAUSE WE DON'T EVEN NEED AN EVENT TO PUSH THE UPDATED VALUES TO CLIENTS, BECAUSE THEY WILL ALWAYS RESPAWN BEFORE THEY SEE THE CHARACTER SELECT SCREEN (AND WE WILL APPLY IT THEN)

	-- WAIT A SEC... WHY EVEN MAKE IT A NETVAR IF IT'S A STATIC VALUE THAT WON'T CHANGE AND ISN'T REFERENCED BY OTHERS?? JUST FOLLOW IN TAPJUMPPREF FOOTSTEPS. MAKE IT A GLOBAL.
	-- GLOBAL.Unlocklevel = value
	--NO WAIT... PRETTY SURE IT'S BECAUSE WE WANT TO PULL SERVER VALUE TO THE CLIENT, AND NOT THE OTHER WAY AROUND...
end
AddPlayerPostInit(unlockstatus)


--1-27-22 REMEMBER OUT OLD MUSIC LEVELS FOR LATER
GLOBAL.TUNING.SMASHUP.OLD_MUSIC_VOLUME = GLOBAL.TheMixer:GetLevel( "set_music" )
--1-31-21 START UP THE BATTLE MUSIC!

local function battlemusicpostinit(inst)
	
	--ALRIGHT FINE, I GUESS THIS WAS KIND OF A WEIRD DESIGN CHOICE. IF MUSIC IS OFF, LEAVE IT OFF BY DEFAULT.
	if GLOBAL.TheMixer:GetLevel( "set_music" ) == 0 then
		GLOBAL.Prefmusic = "off"
	else
		--THEIR MUSIC SETTINGS? FORGET IT. TURN THIS ON UNLESS THEY CLICKY THE BUTTON THAT SAYS NO.
		GLOBAL.TheMixer:SetLevel("set_music", GLOBAL.TheMixer:GetLevel( "set_sfx" ) ) --PULL FROM THE CURRENT SFX VOLUME
	end
	
	inst.battlemusicnetvar = GLOBAL.net_string(inst.GUID, "dummy3.text", "playbattlemusicdirty")
	--1-31-21 DOES THIS WORK??
	local lastsong = "SHUFFLE"
	
	if not GLOBAL.TheNet:IsDedicated() then
		inst:ListenForEvent("playbattlemusicdirty", function()
			-- ThePlayer:PushEvent("triggeredevent", { name = "pigking", duration = 100 }) --WE CAN DO BETTER THAN THIS
			-- GLOBAL.ThePlayer.battlemusicnetvar:value()
			
			if GLOBAL.Prefmusic == "off" then
				return end
			
			local request = inst.battlemusicnetvar:value()
			if request == lastsong and request ~= "SHUFFLE" then
				return end
			
			lastsong = request
			
			local _soundemitter = GLOBAL.TheFocalPoint.SoundEmitter --TAKEN STRAIGHT FROM DYNAMICMUSIC.LUA. HOPEFULY THIS HAS INITIALIZED BY NOW
			local SMASHUP_MUSIC_POOL =
			{
				"dontstarve/music/music_pigking_minigame",
				-- "dontstarve/music/music_epicfight_stalker", -- A LITTLE TOO EPIC. GOOD BOSS FIGHT THOUGH
				-- "dontstarve/music/music_epicfight_stalker_b",
				-- "dontstarve/music/music_epicfight_antlion",
				"dontstarve/music/music_epicfight_3", --MAYBE THIS ONE - YEA P GOOD
				-- "dontstarve/music/music_epicfight_4",
				"dontstarve/music/music_epicfight_toadboss", --NICE
				-- "saltydog/music/malbatross",
				-- "dontstarve/music/music_epicfight_crabking", --MAYBE
				-- "dontstarve/music/music_epicfight_ruins",
				-- "dontstarve/music/music_epicfight_5a", --maybe?
				"dontstarve/music/music_epicfight_5b", --A BETTER MAYBE - SURE
				-- "dontstarve/music/music_epicfight_moonbase",
				-- "dontstarve/music/music_epicfight_moonbase_b", --PROBABLY NOT
				-- "dontstarve/music/music_epicfight", --KINDA QUIET, BUT OK I GUESS
				-- "dontstarve/music/music_epicfight_winter", --EH MAYBE
				-- "dontstarve_DLC001/music/music_epicfight_spring",
				"dontstarve_DLC001/music/music_epicfight_summer", --AIGHT THIS ONES PRETTY GOOD
				"dontstarve/music/music_danger", --YA KNOW, THIS NEW ONE AINT HALF BAD...
				"dontstarve/music/music_danger", --ILL EVEN PUT IT IN TWICE
				"dontstarve/music/music_danger_winter", --NOT REALLY SURE ABOUT THIS ONE TBH. GUESS ILL PUT IT IN ONCE
				"dontstarve_DLC001/music/music_danger_spring", --A CLASSIC JAM. IM' DOUBLING IT
				"dontstarve_DLC001/music/music_danger_spring",
				"dontstarve_DLC001/music/music_danger_summer", --ALSO NOT BAD. ILL THROW IN TWO
				"dontstarve_DLC001/music/music_danger_summer",
				-- "yotc_2020/music/race", --AWW, DOESNT EXIST ANYMORE
			}
			local shuffle = math.random(#SMASHUP_MUSIC_POOL)
			-- print("PLAYING TRACK: ", shuffle, SMASHUP_MUSIC_POOL[shuffle])
			local music = SMASHUP_MUSIC_POOL[shuffle]
			
			--IF WE REQUEST A SPECIFIC SONG, PLAY THAT INSTEAD
			if request ~= "SHUFFLE" then
				music = request
				-- print("REQUESTING A SONG: ", request)
			end
			
			_soundemitter:KillSound("busy") --END THE OLD TRACK BEFORE REQUESTING A NEW ONE
			_soundemitter:PlaySound(music, "busy") --IF WE SET IT AS "BUSY", THE GAME AUTOMATICALLY CLEARS IT ON PLAYER DESPAWN
			_soundemitter:SetParameter("busy", "intensity", 2) --DOESN'T GO HIGHER THAN 1, I GUESS
		end)
	end
	
end
AddPlayerPostInit(battlemusicpostinit)








