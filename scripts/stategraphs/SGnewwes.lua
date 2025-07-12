--require("stategraphs/fighterstates") --3-6-17

local trace = function() end

local function DoFoleySounds(inst)

	-- for k,v in pairs(inst.components.inventory.equipslots) do
		-- if v.components.inventoryitem and v.components.inventoryitem.foleysound then
			-- inst.SoundEmitter:PlaySound(v.components.inventoryitem.foleysound)
		-- end
	-- end

    if inst.prefab == "wx78" then
        inst.SoundEmitter:PlaySound("dontstarve/movement/foley/wx78")
    end

end

--4-5 KEY BUFFER  --SHOULD I MAKE THIS A STATS.LUA FUNCTION?... NAH. THIS IS PROBABLY FASTER ANYWAYS
local function TickBuffer(inst)
	-- print("TICK", inst.components.stats.event, inst.components.stats.buffertick)
	-- inst:PushEvent(inst.components.stats.event, {key = inst.components.stats.key})
	inst:PushEvent(inst.components.stats.event, {key = tostring(inst.components.stats.key), key2 = inst.components.stats.key2})
	inst.components.stats.buffertick = inst.components.stats.buffertick - 1
	-- 
end

   
local events=
{
	--UPDATEING EVERYTHING
	EventHandler("update_stategraph", function(inst)
		if not TheWorld.ismastersim then
			return end
		local wantstoblock = inst:HasTag("wantstoblock")
		local is_tryingtoblock = inst.sg:HasStateTag("tryingtoblock")
		local is_blocking = inst.sg:HasStateTag("blocking")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local is_parrying = inst.sg:HasStateTag("parrying")
		local atk_key_dwn = inst:HasTag("atk_key_dwn")
		local f_charge = inst.sg:HasStateTag("f_charge")
		local u_charge = inst.sg:HasStateTag("u_charge")
		local d_charge = inst.sg:HasStateTag("d_charge")
		local no_blocking = inst.sg:HasStateTag("no_blocking")
		
		local is_jumping = inst.components.launchgravity:GetIsAirborn()
		
		local is_attacking = inst.sg:HasStateTag("attack")
        local is_busy = inst.sg:HasStateTag("busy")
		
		if f_charge and not atk_key_dwn then
			inst.sg:GoToState("fsmash")
		end
		if u_charge and not atk_key_dwn then
			inst.sg:GoToState("usmash")
		end
		if d_charge and not atk_key_dwn then
			inst.sg:GoToState("dsmash")
		end
		
		if inst.components.stats.buffertick >= 1 then
			TickBuffer(inst)
		end
		
		--9-5 --TELLS CPU WHEN TARGET HAS FINISHED A MOVE AND IS READY FOR A NEW ONE --ADD THIS TO WICKER TOO!!!!!
		if not is_busy and not is_blocking then
			inst:PushEvent("readyforaction") --ACTUALLY JUST FOR CPU
			if inst.components.stats.opponent and (inst.components.stats.opponent.components.stats.opponent and inst.components.stats.opponent.components.stats.opponent == inst) then
				inst.components.stats.opponent:PushEvent("targetnewstate")
			end
		end
		
		inst:RemoveTag("motoring") --4-20 ADDED TO FIX BOTH WOODIES CHOPPY SIDE-B AND LEDGE WALK-OFF PHYSICS AT THE SAME TIME
		
        if is_busy then return end
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()
		local is_ducking = inst.sg:HasStateTag("ducking") --7-29-17 LETS FIX THAT WEIRD INFINITE DUCKING BUG
		
		
		--DST CHANGE-- 6-7-17  I THINK THIS BLOCK RIGHT HERE IS CAUSING MOST OF THE CLIENT SIDE ANIMATION ISSUES
		-- if (TheWorld and TheWorld.ismastersim) or not TheWorld then --DID THIS REALLY WORK? --NOT FOR REGULAR DS
		if not inst.components.stats:DSTCheck() or (inst.components.stats:DSTCheck() and (TheWorld and TheWorld.ismastersim)) then
			if wantstoblock and not is_busy and not is_tryingtoblock then
				if is_jumping then
					-- inst.sg:GoToState("airdodge") --1-1-2018 NAH... I THINK NON-BUFFERED BLOCK-KEY EVENTS SHOULD BE FINE
				elseif not no_blocking then
					inst.sg:GoToState("block_startup")
				end
			end
			
			--DST CHANGE 7-22-17 ALSO GONNA THROW THIS UP IN HERE AS I THINK TIS IS CAUSING PROBLEMS TOO
			if is_tryingtoblock and not is_busy and not wantstoblock then
				if is_parrying then
					inst.sg:GoToState("idle")
				else
					inst.sg:GoToState("block_stop")
				end
			end
			
			if is_ducking and inst.components.keydetector:GetDown(inst) == false then --7-29-17
				inst.sg:GoToState("idle")
			end
		end
		
		
		if f_charge and not atk_key_dwn then
			inst.sg:GoToState("fsmash")
		elseif u_charge and not atk_key_dwn then
			inst.sg:GoToState("usmash")
		end
	
	end),
	
	EventHandler("clearbuffer", function(inst)
		-- print("CLEARBUFFER EVENT")
		-- inst.components.stats.buffertick = 0
	end),
	
	
	EventHandler("jump", function(inst, data) --4-18-20 ADDING DATA TO RECOGNIZE BUFFERED ATTACKS 
		local is_busy = inst.sg:HasStateTag("busy")
		local can_jump = inst.sg:HasStateTag("can_jump")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local used_first_jump = inst.components.jumper.jumping == 1 and inst.components.jumper.doublejumping == 0
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		
		--1-29-22 LIKE THE SAME THING FOR THROWATTACK, BUT REVERSE. FOR UPTILTS WITH TAPJUMP
		if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event ~= "jump" then
			-- print("CANCELLING JUMP!")
			return end
			
		if inst.sg:HasStateTag("listen_for_atk") and inst.components.stats.event == "jump" then
			-- print("CANCELLING THIS JUMP SO WE CAN REPLACE IT WITH AN ATTACK-JUMP!")
			return end

		--4-19-20 ALRIGHT YOU LITTLE- IF IT COMES BACK "ISNIL" HARDCODE THIS THING TO NIL BECAUSE SENDING IN NIL ISNT WORKING
		if data.key and data.key == "ITSNIL" then
			data.key = nil --THIS MAKES ME UNBELEIVABLY PISSED THAT THIS WORKS
		end
		-- print("BUFFERED ATTACK: ", data.key)
		--1-5 NEW JUMP SYSTEM SO CRAP DOESNT HIT THE FAN WHEN TRYING TO LEAVEGROUND() ON LAUNCHES
		if (can_jump and not is_airborn) or (not is_busy and not is_airborn) or ((can_jump or can_oos or can_ood) and not is_airborn) then
			--4-18-20 
			
			-- print("DATA KEY? ", data.key)
			if data.key and data.key ~= nil then --BASICALLY, IF AN ATTACK KEY WAS PRESSED ALONG WITH JUMP, SET THE BUFFER TO ATTACK AFTER THE JUMP
				inst.sg:GoToState("highleap")
				inst.components.stats:SetKeyBuffer("throwattack", data.key)
				-- print("BUFFERED AIRIAL", data.key)
			else
				inst.sg:GoToState("highleap")
			end
			
		elseif (can_jump and inst.components.jumper.currentdoublejumps >= 1) or (not is_busy and inst.components.jumper.currentdoublejumps >= 1) then
			
			if data.key and data.key ~= nil then --SAME HERE
				inst.sg:GoToState("doublejump")
				inst.components.stats:SetKeyBuffer("throwattack", data.key)
				inst:PushEvent("throwattack", {key = data.key})
			else
				inst.sg:GoToState("doublejump")
			end
			
		--1-30-22 WE BUFFERED AN ATTACK JUMP, BUT WE CAN'T JUMP, SO JUST ATTACK..RIGHT?	
		elseif (can_jump or not is_busy) and is_airborn and data.key and data.key ~= nil then 
			-- print("WE CAN'T JUMP! SO MAKE AN ATTACK")
			inst.components.stats.event = "throwattack"
		end
		
		--4-23-20 INTERESTING, SOMTIMES THE BUFFER CAN RUN THIS AGAIN AND DETECT A BUFFERED ATTACK, EVEN AFTER THE JUMP STATE HAS STARTED WITHOUT ONE... LETS TRY AND RIG IT 
		if (inst.sg.currentstate.name == "highleap" or inst.sg.currentstate.name == "doublejump") and inst.sg.timeinstate == 0 then
			--ANOTHER DATA SET 
			if data.key and data.key ~= nil then 
				inst.components.stats:SetKeyBuffer("throwattack", data.key)
				-- print("BUFFERED AIRIAL2", data.key)
			end
		end
	
	end),
	
	EventHandler("air_transition", function(inst)
		local is_busy = inst.sg:HasStateTag("busy")
		local no_air_transition = inst.sg:HasStateTag("no_air_transition")
		local used_first_jump = inst.components.jumper.jumping == 1 and inst.components.jumper.doublejumping == 0
		
		-- inst.components.launchgravity:LeaveGround()
		
		if not (inst.sg:HasStateTag("hanging") and not inst.components.launchgravity.islaunched) and not no_air_transition or not is_busy then --FIX THIS LATER --TODOLIST --FINALTDL
			
			inst.sg:GoToState("air_idle")
			-- inst.components.launchgravity.islaunched = true
		end
		inst.components.launchgravity:LeaveGround()
		inst:AddTag("no_grab_ledge")
		inst:DoTaskInTime(0.3, function(inst)
			inst:RemoveTag("no_grab_ledge")
		end)
	end),
	
	
	EventHandler("colourtweener_end", function(inst)
		inst.AnimState:SetMultColour(1,1,1,1)
	end),
	
	EventHandler("duck", function(inst)
		local is_busy = inst.sg:HasStateTag("busy")
		local can_duck = inst.sg:HasStateTag("can_duck")
		local no_fastfalling = inst.sg:HasStateTag("no_fastfalling")
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		
		if can_duck or not is_busy and not is_airborn then
			inst.sg:GoToState("duck")
		elseif is_airborn and not no_fastfalling then
			inst.components.jumper:FastFall()
		end
	end),

	
	EventHandler("grab_ledge", function(inst, data)
		local is_busy = inst.sg:HasStateTag("busy")
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		local can_grab_ledge = inst.sg:HasStateTag("can_grab_ledge")
		local autosnap = inst.sg:HasStateTag("autosnap")
		local no_grab_ledge = inst:HasTag("no_grab_ledge")
		local is_falling = inst.components.launchgravity:GetVertSpeed() <= 0
		local pressing_down = inst.components.keydetector:GetDown(inst)
		local pressing_tostage = inst.components.keydetector:HoldingTowardsStage(inst)
		
		-- print("IS IT THEE?", is_busy, is_falling)
		-- if not is_busy and is_airborn and can_grab_ledge then
		if no_grab_ledge and not autosnap then
			--DO NOTHING
		--8-29 ADDED CHECK FOR HITFROZEN TO FIX A BUG THAT CAUSED PHYSICS TO RESUME ON LEDGEGRAB 	--10-22-18 --WELL GUESS WHAT BUD, ITS STILL BROKEN! GET BACK IN THERE AND FIX IT
		elseif (can_grab_ledge or (not is_busy and is_falling)) and not (pressing_down or pressing_tostage) and not inst:HasTag("hitfrozen") then 
		-- print("GIVE IT TO ME")
			inst.components.launchgravity:HitGround()
			inst.components.jumper.jumping = 0
			inst.components.jumper.doublejumping = 0
			inst.sg:GoToState("grab_ledge", data.ledgeref)
		end
	end),
	
	EventHandler("left", function(inst)
		local is_dashing = inst.sg:HasStateTag("dashing") --DASHIN GOOD LOOKS 
		local foxtrot = inst.sg:HasStateTag("foxtrot")
		local can_oos = inst.sg:HasStateTag("canoos")
		local was_running = inst:HasTag("wasrunning")
		
		if foxtrot and inst.components.keydetector:GetBackward(inst) then 
			inst.components.locomotor:TurnAround()
			inst.sg:GoToState("dash_start")
		end
		if can_oos and inst.components.keydetector:GetForward(inst) and not was_running then
			inst.sg:GoToState("roll_forward")
			-- inst:PushEvent("roll", {key = "left"}) --7-29-17 CAN... YOU PUSH EVENTS IN EVENTS???
		elseif can_oos and inst.components.keydetector:GetBackward(inst) and not was_running then
			inst.components.locomotor:TurnAround()
			inst.sg:GoToState("roll_forward")
			-- inst:PushEvent("roll", {key = "right"})
		end
	end),
	EventHandler("right", function(inst)
		local is_dashing = inst.sg:HasStateTag("dashing")
		local foxtrot = inst.sg:HasStateTag("foxtrot")
		local can_oos = inst.sg:HasStateTag("canoos")
		local was_running = inst:HasTag("wasrunning")
		
		if foxtrot and inst.components.keydetector:GetBackward(inst) then 
			inst.components.locomotor:TurnAround()
			inst.sg:GoToState("dash_start")
		end
		if can_oos and inst.components.keydetector:GetForward(inst) and not was_running then
			inst.sg:GoToState("roll_forward")
		elseif can_oos and inst.components.keydetector:GetBackward(inst) and not was_running then
			inst.components.locomotor:TurnAround()
			inst.sg:GoToState("roll_forward")
		end
	end),
	
	
	--7-17-17 
	EventHandler("roll", function(inst, data)
		-- local is_dashing = inst.sg:HasStateTag("dashing")
		local is_busy = inst.sg:HasStateTag("busy")
		local can_oos = inst.sg:HasStateTag("canoos")
		local was_running = inst:HasTag("wasrunning")
		local is_airborn = inst.components.launchgravity:GetIsAirborn() --8-14-17 NO YOU CANT ROLL IN THE AIR
		local must_roll = inst.sg:HasStateTag("must_roll") --8-11 ADDED TO IMPROVE ROLL CONSISTAMCEY, ALONG WITH ADDING MUSTROLL TO DASH FRAMES
		
		
		local facedir = inst.components.launchgravity:GetRotationFunction()
		-- print("LETS ROLL", data.key, facedir)
		-- inst.components.locomotor:Clear()--7-29-17 WILL THIS HELP? --NOPE
		
		
		
		if ((not is_busy or can_oos) and not was_running and not is_airborn) or must_roll then
			-- print("LETS ROCK AND ROLL")
			if data.key == facedir then
				inst.sg:GoToState("roll_forward")
			elseif data.key == "left" or data.key == "right" then
				--FACING THE WRONG DIRECTION, BUT IS STILL A VALID DIRECTION
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("roll_forward")
			elseif data.key == "none" then --LATE-8-11-17 ALRIGHT, NO MORE OF THIS. BUFFER MUST HAVE A DIRECTION, OR NO ROLLING ALLOWED
				-- inst.sg:GoToState("roll_forward") --8-11-17 ALRIGHT, WHATEVER. IF IT COMES BACK WITH NONE, JUST ASSUME IT WAS ROLL FORWARD
				--8-11-17 --TODO- NO THIS WONT WORK. MAKE A NEW GETLEFTRIGH() FN WITH A 5 SECOND BUFFER 
			else
				--ITS A TRAP! DONT REACT TO THIS
				inst.components.hitbox:MakeFX("half_circle_backward_woosh", 0.3, 1.0, 0.1,  -1.5, 2.1,   1, 6, 0) --IF YOU SEE THIS, SOMETHING WENT WRONG
			end
		end
	end),
	
	
	EventHandler("tech", function(inst)
		local is_busy = inst.sg:HasStateTag("busy")
		local can_oos = inst.sg:HasStateTag("canoos")
		local pressing_forward = inst.components.keydetector:GetForward(inst)
		local pressing_backward = inst.components.keydetector:GetBackward(inst)
		
				
		if pressing_forward then
			inst.sg:GoToState("tech_forward_roll")
		elseif pressing_backward then
			inst.sg:GoToState("tech_backward_roll")
		else
			inst.sg:GoToState("tech_getup")
		end
	
	end),
	
	EventHandler("attack_cancel", function(inst)
		local is_listening_for_attack = inst.sg:HasStateTag("listen_for_attack")
		local can_oos = inst.sg:HasStateTag("canoos")
		local pressing_forward = inst.components.keydetector:GetForward(inst)
		
				
		if pressing_forward then
			inst.sg:GoToState("tech_forward_roll")
		else
			inst.sg:GoToState("tech_getup")
		end
	
	end),
	
	EventHandler("dash", function(inst, data)
		local is_busy = inst.sg:HasStateTag("busy")
		local no_running = inst.sg:HasStateTag("no_running")
		local can_dash = inst.sg:HasStateTag("candash") and not no_running --WILL THIS FIX IT? --1-8
		local pivoting = inst.sg:HasStateTag("pivoting")
		local pressing_forward = inst.components.keydetector:GetForward(inst)
		local foxtrot = inst.sg:HasStateTag("foxtrot")
		
		--1-14-22 CHECK DIRECTION FOR BUFFERED DASHES
		local facedir = inst.components.launchgravity:GetRotationFunction()
		if data.key and data.key ~= facedir then
			pressing_forward = false
		end
		if foxtrot and not pressing_forward then
			inst.sg:GoToState("run_stop")
		elseif foxtrot and not no_running then --WILL THIS FIX IT? --1-8
			inst.sg:GoToState("dash")
		elseif (not is_busy and not no_running) or can_dash then
			if not pressing_forward then
				inst.components.locomotor:TurnAround()
			end
			inst.sg:GoToState("dash_start")
			inst.components.hitbox:MakeFX("dahswoosh", 0.5, 1.5, 1, 1, 1, 0.8, 7, 1)
			inst.components.hitbox:MakeFX("slide1", 0.5, 0, 0.1, 0.5, 0.5, 1, 10, 0)
		else
			--DO NOTHING!
		end
	
	end),
	
	EventHandler("dash_stop", function(inst)
		local pressing_backward = inst.components.keydetector:GetBackward(inst)
		local can_dashdance = inst.sg:HasStateTag("can_dashdance")
		local no_running = inst.sg:HasStateTag("no_running")
		
		if not inst.sg:HasStateTag("dashing") then 
			return end
		
		if pressing_backward then
			-- inst.components.locomotor:TurnAround()
			--inst.PushEvent("dash")
			if can_dashdance then
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("dash_start")
			elseif inst.sg:HasStateTag("dashing") then
				inst.sg:GoToState("pivot_dash")
			end
		elseif not inst.sg:HasStateTag("sliding") and not can_dashdance and not no_running then
			inst.sg:GoToState("dash_stop")
		--elseif can_dashdance then
			-- inst.sg:GoToState("idle")
		else
			--DO NOTHING
			--inst.sg:GoToState("dash_stop")
		end
		
		
	end),
	
    EventHandler("locomote", function(inst)
		local is_jumping = inst.components.launchgravity:GetIsAirborn()
		
		--print(is_jumping)
		
        local is_attacking = inst.sg:HasStateTag("attack")
        local is_busy = inst.sg:HasStateTag("busy")
        if is_busy then return end
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()
		
		local wantstoblock = inst:HasTag("wantstoblock")
		local is_tryingtoblock = inst.sg:HasStateTag("tryingtoblock")
		local is_blocking = inst.sg:HasStateTag("blocking")
		local can_oos = inst.sg:HasStateTag("canoos")
		local is_prone = inst.sg:HasStateTag("prone")
		local no_running = inst.sg:HasStateTag("no_running")
		local was_running = inst:HasTag("wasrunning")
        
		--@@@@@@@@
		if is_jumping then
			--print("YEA IM TOTES JUMPING")
			--inst.components.locomotor:FlyForward() --OH MAN
			--inst:PushEvent("locomote") --OH BOY INFINITY LOOP
		elseif is_moving and not should_move and not no_running then
            if is_running then
                inst.sg:GoToState("run_stop")
            else
                inst.sg:GoToState("walk_stop")
            end
        elseif (not is_moving and should_move) or (is_moving and should_move and is_running ~= should_run) then
		
			--10-14 DODGING
			if can_oos and not was_running then
				--inst.sg:GoToState("spotdodge")
				inst.sg:GoToState("roll_forward")
			--end
			elseif is_prone then--and not is_busy then
                inst.sg:GoToState("roll_forward")
            elseif should_run and not is_busy then
                inst.sg:GoToState("run_start")
            else
                inst.sg:GoToState("walk_start")
            end
        end 
    end),
    
    

    EventHandler("attacked", function(inst, data)
			if inst.sg:HasStateTag("hanging") then
				--11-12-17 IF HOLDING LEDGE, TELEPORT THEM DOWN BY THEIR HIEGHT BEFORE CONTINUING AS NORMAL
				inst.components.locomotor:Teleport(-0.5, -inst.components.stats.height, 0)
				inst.sg:GoToState("hit", data.hitstun) 
			else
				inst.sg:GoToState("hit", data.hitstun) --12-4
            end
	end),

    
    
    EventHandler("death", function(inst)
        -- inst.components.playercontroller:Enable(false)
        -- inst.sg:GoToState("death")
        -- inst.SoundEmitter:PlaySound("dontstarve/wilson/death")    
        
		-- local sound_name = inst.soundsname or inst.prefab
        -- if inst.prefab ~= "wes" then
			-- inst.SoundEmitter:PlaySound("dontstarve/characters/"..sound_name.."/death_voice")    
		-- end
        
    end),
	
	
	EventHandler("throwattack", function(inst, data)
		
		local airial = inst.components.launchgravity:GetIsAirborn()
		local can_attack = inst.sg:HasStateTag("can_attack")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local is_prone = inst.sg:HasStateTag("prone")
		local listen_for_attack = inst.sg:HasStateTag("listen_for_attack")
		local jab1 = inst.sg:HasStateTag("jab1")
		local jab2 = inst.sg:HasStateTag("jab2")
		local must_fsmash = inst.sg:HasStateTag("must_fsmash")
		local must_usmash = inst.sg:HasStateTag("must_usmash")
		local must_dsmash = inst.sg:HasStateTag("must_dsmash")
		local must_ftilt = inst.sg:HasStateTag("must_ftilt")
		local pivoting = inst.sg:HasStateTag("pivoting")
		
		--4-23-20 IF THE USER PRESSED JUMP ON THE SAME FRAME, CANCEL THE ATTACK.
		-- print("ATTACK KEY EVENT...", inst.sg:HasStateTag("listen_for_jump"), inst.components.stats.event)
		if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event == "jump" then
			-- print("--CANCELING ATTACK--") --THIS IS WHAT HAPPENS WHEN OUR AIREAL IS REPLACED WITH A NAIR
			return end
			
		if can_oos then
			inst.sg:GoToState("grab")
			
		-- elseif must_fsmash then
			-- inst.sg:GoToState("fsmash_start")
		-- elseif must_usmash then
			-- inst.sg:GoToState("usmash_start")
		-- elseif must_dsmash then
			-- inst.sg:GoToState("dsmash_start")
		-- elseif must_ftilt then
			-- inst.sg:GoToState("ftilt") --ftilt
			
		elseif can_ood then
			-- inst.sg:GoToState("dash_attack")
			-- inst.sg:GoToState("dash_grab")
			if data.key == "block" then
				inst.sg:GoToState("grab")
			elseif pivoting then --8-29-20
				inst.sg:GoToState("ftilt")
			else
				inst.sg:GoToState("dash_attack")
			end
			
		elseif is_prone then
			inst.sg:GoToState("getup_attack")
			
		elseif listen_for_attack then
			if jab1 then
				inst.sg:GoToState("jab2")
			elseif jab2 then 
				inst.sg:GoToState("jab3")
			end
		--end
		elseif inst.sg:HasStateTag("can_usmash") and inst.components.stats.tapjump and (data.key == "up" or data.key == "diagonalf" or data.key == "diagonalb") then
			inst.sg:GoToState("utilt")
        --if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
		-- elseif not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
		elseif not inst.sg:HasStateTag("busy") or can_attack then --12-4
			
			if can_oos or (data.key == "block" and not airial) then
				if data.key2 == "backward" then inst.components.locomotor:TurnAround() end
				inst.sg:GoToState("grab")
			
			--if airial and not airial == 0 then
			elseif airial then
				--inst.sg:RemoveStateTag("busy")
				--inst.sg:GoToState("fair")  --I NEED TO TEST THE PUNCHY ONE
				--inst.sg:GoToState("jab1")
				
				if data.key == "backward" then 
					inst.sg:GoToState("bair")
				elseif data.key == "diagonalb" then 
					if inst.components.stats.tapjump then
						inst.sg:GoToState("bair")
					else
						inst.sg:GoToState("uair")
					end
				elseif data.key == "forward" then 
					inst.sg:GoToState("fair")
				elseif data.key == "diagonalf" then
					if inst.components.stats.tapjump then
						inst.sg:GoToState("fair")
					else
						inst.sg:GoToState("uair")
					end
				elseif data.key == "down" then
					inst.sg:GoToState("dair")
				elseif data.key == "up" then
					inst.sg:GoToState("uair")
				else
					inst.sg:GoToState("nair")
				end
				inst.components.jumper:UnFastFall()
			else
				inst.components.locomotor:Stop()
				if data.key == "up" or data.key == "diagonalf" then 
					inst.sg:GoToState("utilt")
				elseif data.key == "down" then
					if inst.components.keydetector:GetBackward(inst) then
						inst.components.locomotor:TurnAround() --SINCE WE HAVE NO DOWNWARD DIAG DETECTOR, WE GOTTA TAKE SHORTCUTS
					end
					inst.sg:GoToState("dtilt")
				elseif data.key == "forward" then
					inst.sg:GoToState("ftilt")
				elseif data.key == "backward" or data.key == "diagonalb" then
					if not inst.components.keydetector:GetForward(inst) then --2-7-17 IF HOLDING BACKWARD WHEN BUFFER KICKED IN, RUNNING WOULD CAUSE YOU TO TURN AROUND FIRST, MAKING YOU TURN TWICE
						inst.components.locomotor:TurnAround()
					end
					if data.key == "diagonalb" then
						inst.sg:GoToState("utilt")
					else
						inst.sg:GoToState("ftilt")
					end
				else
				
				--inst.sg:GoToState("attack")
				inst.sg:GoToState("jab1")
				end
				
			end
			
        end
    end),
	
	
	--CSTICK
	EventHandler("cstick_up", function(inst, data)
		local airial = inst.components.launchgravity:GetIsAirborn()
		local can_attack = inst.sg:HasStateTag("can_attack")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local is_busy = inst.sg:HasStateTag("busy") and not can_attack
		local tiltstick = inst.components.stats.tiltstick
		
		--4-23-20 IF THE USER PRESSED JUMP ON THE SAME FRAME, CANCEL THE ATTACK.
		if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event == "jump" then
			inst.components.stats.key = "up"
			return end
		
		if data and data.key == "backward" and not (is_busy or airial) then
			inst.components.locomotor:TurnAround()
		end
			
		if (inst.sg:HasStateTag("can_usmash") and inst.components.stats.tapjump or can_ood) or not is_busy and not airial then
			if tiltstick == "smash" then
				inst.sg:GoToState("usmash_start")
			else
				inst.sg:GoToState("utilt")
			end
		elseif not is_busy and airial then
			inst.sg:GoToState("uair")
		end
	end),
	
	EventHandler("cstick_down", function(inst, data)
		local airial = inst.components.launchgravity:GetIsAirborn()
		local can_attack = inst.sg:HasStateTag("can_attack")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local is_busy = inst.sg:HasStateTag("busy") and not can_attack
		local tiltstick = inst.components.stats.tiltstick
		
		--4-23-20 IF THE USER PRESSED JUMP ON THE SAME FRAME, CANCEL THE ATTACK.
		if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event == "jump" then
			inst.components.stats.key = "down"
			-- print("--CANCELLING THE ATTACK--")
			return end
		
		if data and data.key == "backward" and not (is_busy or airial) then
			inst.components.locomotor:TurnAround()
		end
		
		if can_ood then
			inst.sg:GoToState("dash_attack")	
		elseif not is_busy and not airial then
			if tiltstick == "smash" then
				inst.sg:GoToState("dsmash_start")
			else
				inst.sg:GoToState("dtilt")
			end
		elseif not is_busy and airial then
			inst.sg:GoToState("dair")
		end
	end),
	
	
	--7-20-17 NEW CSTICK LISTENER TO ALLOW DIRECTIONAL BUFFEREING OUT OF CHANGING DIRECTIONS
	EventHandler("cstick_side", function(inst, data)	
		local airial = inst.components.launchgravity:GetIsAirborn()
		local must_fsmash = inst.sg:HasStateTag("must_fsmash")
		local is_forward = (data.key == inst.components.launchgravity:GetRotationFunction())
		local valid_key = (data.key == "left" or data.key == "right")
		local can_attack = inst.sg:HasStateTag("can_attack")
		local is_busy = inst.sg:HasStateTag("busy") and not can_attack
		local tiltstick = inst.components.stats.tiltstick
		
		-- if must_fsmash and is_forward then  --ITS GOOD TO LEAVE THIS HERE OR ELSE DASH ATTACKS GET WIERD
			-- inst.sg:GoToState("fsmash_start")
		if inst.sg:HasStateTag("can_ood") and is_forward then --9-7-21
			if inst.sg:HasStateTag("sliding") then
				if tiltstick == "smash" then
					inst.sg:GoToState("fsmash_start")
				else
					inst.sg:GoToState("ftilt")
				end
			else
				inst.sg:GoToState("dash_attack")
			end	
		
		elseif not is_busy and not airial then
			--TURN AROUND IF NOT FACING THE SAME WAY THE BUFFERED DIRECTION KEY WAS
			if not is_forward and valid_key then --MAKE SURE THAT THE KEY DIDNT JUST COME IN AS TABLE GIBBERISH INSTEAD OF THE OPPOSITE DIRECTION
				inst.components.locomotor:TurnAround()
			end
			if tiltstick == "smash" then
				inst.sg:GoToState("fsmash_start")
			else
				inst.sg:GoToState("ftilt")
			end
			
		elseif not is_busy and airial then
			if not is_forward and valid_key then 
				inst.sg:GoToState("bair")
			else --BUT IF IT DOES COME IN AS TABLE GISBBERISH, JUST ASSUME IT WAS MEANT TO BE FORWARD, WHATEVER
				-- if inst.components.keydetector:GetBackward(inst) then --NO! LETS AT LEAST CHECK AND SEE IF THEY ARE CURRENTLY HOLDING BACKWARDS
				if inst.components.keydetector:GetBackward(inst) and data.key2 ~= "stick" then --1-1-18 BACK AGAIN! INPUTS DIRECTLY FROM THE STICK SHOULD NOT BE CHECKED FOR BACKWARDS, SO DRIFTBACK/FAIR CAN EXIST
					inst.sg:GoToState("bair")
				else	--BUT IF NOT, WE HAVE NO CHOICE BUT TO ASSUME IT WAS MEANT TO BE FORWARD
					inst.sg:GoToState("fair")
				end
			end
		end
	end),
	
	
	EventHandler("throwspecial", function(inst, data)
		local can_special_attack = inst.sg:HasStateTag("can_special_attack")
	
		-- if not inst.sg:HasStateTag("busy") or can_special_attack then
		--10-18-17 NEW CHECKER THAT ALLOWS FOR UPSPEC JUMPCANCELING
		if not inst.sg:HasStateTag("busy") or can_special_attack or (inst.sg:HasStateTag("can_upspec") and (data.key == "up" or data.key == "diagonalf" or data.key == "diagonalb")) then
			-- if inst.components.keydetector:GetUp() then
			if data.key == "up" then
				if inst.components.stats.norecovery == false then
					inst.sg:GoToState("uspecial")
				else
					--WARN THEM THAT THEY GOT NO RECOVERY --THIS NEEDS TO GO IN ALL SPOTS
					inst.components.hitbox:Blink(inst, 1,   0.6, 0.3, 0.3, 0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
				end
			elseif data.key == "diagonalf" then		--ADDING DIAGONALS  --TODOLIST: FIX THIS SO IT'S LIKE EVERYONE ELSE'S
				if inst.components.stats.norecovery == false then
					if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
					inst.sg:GoToState("uspecial")
				else
						--WARN THEM THAT THEY GOT NO RECOVERY --THIS NEEDS TO GO IN ALL SPOTS
						inst.components.hitbox:Blink(inst, 1,   0.6, 0.3, 0.3, 0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
				end
			elseif data.key == "diagonalb" then
				if inst.components.stats.norecovery == false then
					if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
					inst.components.locomotor:TurnAround()
					inst.sg:GoToState("uspecial")
				else
					--WARN THEM THAT THEY GOT NO RECOVERY --THIS NEEDS TO GO IN ALL SPOTS
					inst.components.hitbox:Blink(inst, 1,   0.6, 0.3, 0.3, 0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
				end
			-- end
			elseif data.key == "down" then
				inst.sg:GoToState("dspecial")
			elseif data.key == "forward" then
				-- print("IM KEY2!!", data.key2)
				--ANOTHERNOTHER SPECIAL CASE FOR WES- HIS FSPECIAL DOESN'T PUT HIM INTO FREEFALL, BUT LIKE BAYONETTA'S, HE ONLY GETS ONE SWING IN EACH DIRECTION UNTIL LANDING.
				-- if data.key2 == -1 then
					-- if inst.components.stats.storagevar2 == "used_left_swing" then
						-- --WARN THEM THAT THEY GOT NO RECOVERY --THIS NEEDS TO GO IN ALL SPOTS
						-- inst.components.hitbox:Blink(inst, 1,   0.6, 0.3, 0.3, 0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
						-- print("IM BLINKING!!")
					-- else
						-- inst.components.stats.storagevar2 = "used_left_swing" --ITS BEEN USED!
					-- end
				-- end
				
				if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
					-- inst.sg:GoToState("fspecial") --NORMALLY ITS JUST THIS, AND NONE OF THIS OTHER NONSENSE AROUND IT...
					--SPECIAL CASE HERE FOR WES. DONT LET HIM CANCEL HIS ROPE-SWING INTO ANOTHER ROPE-SWING (UNLESS ITS A REVERSE SWING)
					if not inst.sg:HasStateTag("ropeswinging") then
						inst.sg:GoToState("fspecial")
					end
			elseif data.key == "backward" then
				if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
				--SPECIAL CASE HERE FOR WES. DONT LET HIM CANCEL HIS ROPE-SWING INTO ANOTHER ROPE-SWING (UNLESS ITS A REVERSE SWING)
					if not inst.sg:HasStateTag("ropeswinging") then
						inst.components.locomotor:TurnAround()
						inst.sg:GoToState("fspecial")
					end
				-- inst.components.locomotor:TurnAround()
				-- inst.sg:GoToState("fspecial")
			else
				inst.sg:GoToState("nspecial")
			end
		end
		
		
	
	end),
	
	--1-1-2018 AIRDODGES WILL NOW ONLY ACTIVATE FROM DIRECT BUTTON PRESSES, NOT BY HOLDING OR BUFFERING THEM.
	EventHandler("block_key", function(inst)
		local airial = inst.components.launchgravity:GetIsAirborn(inst)

		if airial and not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("airdodge")
		end
	end),
	
	
	EventHandler("clank", function(inst, data)
	local airial = inst.components.launchgravity:GetIsAirborn()
		--8-26 WHEN WE LAST LEFT OFF, ARMOR PROOVED TO WORK, BUT THE CLANK EVENT OF THE REBOUND STATE IS CAUSING THE ARTIFICIAL HITLAG TO BREAK !!!!! --FIXED IT!!!
		inst.components.hitbox:FinishMove() --IS THIS REDUNDANT? --NOPE WE NEED THIS
		if not airial then
			inst.sg:GoToState("rebound", data.rebound)
		end
	end),
	
	EventHandler("do_tumble", function(inst, data)
		-- inst.sg:GoToState("tumble", data.hitstun, data.direction) --ONLY SENDS THE HITSTUN DADA. DATA.DIRECTION DOES NOTHING
		if inst.sg:HasStateTag("hanging") then
			--11-12-17 IF HOLDING LEDGE, TELEPORT THEM DOWN BY THEIR HIEGHT BEFORE CONTINUING AS NORMAL
			inst.components.locomotor:Teleport(-0.5, -inst.components.stats.height, 0)
			inst.sg:GoToState("tumble", data.hitstun)
		else
			inst.sg:GoToState("tumble", data.hitstun)
		end
	end),
	
	EventHandler("freeze", function(inst, data)
		inst.sg:GoToState("frozen")
	end),
	
	EventHandler("respawn", function(inst, data)
		inst.sg:GoToState("respawn_platform")
	end),
}




local states= 
{
	
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("idle")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			
			if inst.components.stats and inst.components.launchgravity then	
				if inst.components.launchgravity:GetIsAirborn() then
					inst.sg:GoToState("air_idle")
				elseif inst.components.keydetector and inst.components.keydetector:GetDown(inst) then
					inst.sg:GoToState("duck")
				end
			end
		end,
        
		
		 events=
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),        
        },
    },
	
	--AIR IDLE
	State{
        name = "air_idle",
        tags = {"idle"},
        
		--FIXED IDLE ANIMATION
		onenter = function(inst)
			inst.AnimState:PlayAnimation("idle_air")
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
		end,
    },
    
    
    State{
        name = "run_start",
        tags = {"moving", "running", "canrotate"}, 
        
        onenter = function(inst)
			inst.components.locomotor.throttle = 0
			-- inst.sg:GoToState("run") --WHY WAIT  --9-7 OKAY WHY WOULD I DO THIS WHAT AM I STUPID???
			inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run") --run_pre
            inst.sg.mem.foosteps = 0
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        events=
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("run") end ),        
        },
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
                inst.sg:AddStateTag("ignore_ledge_barriers")
				inst.sg:RemoveStateTag("must_roll")
            end),
            
			TimeEvent(6*FRAMES, function(inst)
                PlayFootstep(inst)
                DoFoleySounds(inst)
            end),
			
			TimeEvent(10*FRAMES, function(inst)
                if inst.components.keydetector:GetForward(inst) then
					--TRYING SOMETHING ELSE OUT TO WORKAROUND AUTODASHING
					if inst.components.keydetector:CheckWalkImpulse(inst) then
						inst.sg:GoToState("run")
					else
						inst.sg:GoToState("dash")
					end
				end
            end),
        },        
        
    },

    State{
        
        name = "run",
        tags = {"moving", "running", "canrotate", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
            inst.components.locomotor:RunForward()
			inst.AnimState:PushAnimation("run")
			inst:PushEvent("swaphurtboxes", {preset = "walking"})
			inst.sg.mem.foosteps = 0
        end,
        
        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline=
        {
            TimeEvent(7*FRAMES, function(inst)
                inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
            end),
            TimeEvent(15*FRAMES, function(inst)
                inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
            end),
        },
        
        events=
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("run") end ),        
        },
        
        
    },
    
    State{
    
        name = "run_stop",
        tags = {"canrotate", "idle", "candash", "can_grab_ledge"},
        
        onenter = function(inst) 
            inst.AnimState:PlayAnimation("run_pst")
        end,
		
		timeline=
        {
        
            TimeEvent(4*FRAMES, function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
	
	
	
	
	State{
        
        name = "dash_start",
        tags = {"moving", "running", "canrotate", "dashing", "can_usmash", "can_special_attack", "can_ood", "busy", "can_dashdance", "foxtrot", "must_fsmash", "must_roll", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
			inst.components.locomotor.throttle = 0
			inst.components.locomotor:DashForward()
			inst.AnimState:PlayAnimation("dash_naruto")
			
			inst.components.hitbox:MakeFX("dahswoosh", 0.5, 1.5, 1, 1, 1, 0.8, 7, 1) --8-25 GOD DANGIT I JUST REALIZED I SPELLED IT WRONG
			inst.components.hitbox:MakeFX("slide1", 0.5, 0, 0.1, 0.5, 0.5, 1, 10, 0)
			
			inst:PushEvent("swaphurtboxes", {preset = "dashing"})
        end,
        
        onupdate = function(inst)
			if inst.components.keydetector:GetForward(inst) then
				inst.components.locomotor:DashForward()
			end
			
			if inst.components.keydetector:GetBlock(inst) then --8-11-17 SOMETHING TO HELP COMBAT THE DASH BUG
				if inst.sg:HasStateTag("must_roll") then
					inst.sg:GoToState("roll_forward")
					inst.components.hitbox:MakeFX("stars", -1.6, 1.0, 0.1, 1, 0.7, 0.8, 2, 0)
				end
			end
        end,

        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.sg:RemoveStateTag("must_fsmash")
				inst.sg:RemoveStateTag("must_roll")
			end),
			
            TimeEvent(7*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.2, 0.2, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst:PushEvent("dash") 
			end),
        },
        
        events=
        {   
			EventHandler("block_key", function(inst)
				inst.sg:GoToState("roll_forward")
			end ), 
			
			--8-29-20 FOR EARLY SMASH ATTACKS. 
			EventHandler("cstick_side", function(inst, data)   
				inst.components.locomotor:FaceDirection(data.key) --1-27-22
				inst.sg:GoToState("fsmash_start")
			end),   
			
			EventHandler("down", function(inst) 
				inst.sg:GoToState("run") 
			end ),
        },
        
        
    },
	
	
	State{
        
        name = "dash",
        tags = {"moving", "running", "canrotate", "can_special_attack", "dashing", "can_usmash", "can_ood", "busy", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
			inst.components.locomotor:DashForward()
			inst.AnimState:PlayAnimation("dash_naruto")
			inst:PushEvent("swaphurtboxes", {preset = "dashing"})
			inst.sg.mem.foosteps = 0
        end,
        
        onupdate = function(inst)
            inst.components.locomotor:DashForward()
        end,

        timeline=
        {
            TimeEvent(1*FRAMES, function(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst) --, inst.sg.mem.foosteps < 5 and 1 or .6)
                DoFoleySounds(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.2, 0.2, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
            end),
            TimeEvent(7*FRAMES, function(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst) --, inst.sg.mem.foosteps < 5 and 1 or .6)
                DoFoleySounds(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.5, 0.5, 0.8, 5, 0)
            end),
        },
        
        events=
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("dash") end ), --THIS STATE IS ACTUALLY ANIMATION DEPENDANT!! JUST LIKE IN REGULAR SMASH BROS. MAKE A LONG ANIMATION TO HAVE A LONG STARTUP!
			
			EventHandler("block_key", function(inst) --4-7 FOR MANUAL BLOCK OUT OF DASH ACTIVATION
				inst.sg:GoToState("block_startup") 
			end ),
			
			EventHandler("down", function(inst)
				inst.sg:GoToState("run") 
			end ),
        },
        
        
    },
	
	
	State{
        
        name = "dash_stop",
        tags = {"canrotate", "dashing", "sliding", "keylistener", "keylistener2"}, --CANROTATE IS NEEDED HERE!
        
        onenter = function(inst) 
			inst.AnimState:PlayAnimation("dash_pst")
			inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1, 1, 0.5, 0.8, 10, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
            
        end,

        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "idle"}) 
			end),
			
			TimeEvent(4*FRAMES, function(inst)
				inst.sg:RemoveStateTag("keylistener")
				inst.sg:RemoveStateTag("can_ood")
				
            end),
			TimeEvent(10*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:RemoveStateTag("can_ood")
            end),
            TimeEvent(12*FRAMES, function(inst)
				inst.sg:GoToState("idle")
            end),
        },
        
        events=
        {   
            EventHandler("backward_key", function(inst) 
				if inst.sg:HasStateTag("keylistener") then
					inst.components.locomotor:TurnAround()
					inst.sg:GoToState("pivot_dash")
				end
			end ),        
        },
        
        
    },
	
	State{
        
        name = "pivot_dash",
        tags = {"canrotate", "busy", "sliding", "can_special_attack", "can_ood", "pivoting", "must_fsmash", "must_ftilt"},
        
        onenter = function(inst) 
			inst.Physics:SetMotorVel(0,0,0)
			inst.components.locomotor:TurnAround()
			inst.AnimState:PlayAnimation("dash_pivot_new")
			inst.components.hitbox:MakeFX("slide1", -1.6, 0.0, 0.1, 1, 0.5, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			inst.Physics:SetFriction(.8)
			inst.components.jumper:ScootForward(-8)
        end,
		
		onexit = function(inst)
			inst.components.stats:ResetFriction()
        end,

        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(-0.5, 0)
            end),
			TimeEvent(2*FRAMES, function(inst)
				inst.sg:RemoveStateTag("must_fsmash")
            end),
			TimeEvent(6*FRAMES, function(inst)
				inst.sg:AddStateTag("candash")
				if inst.components.keydetector:GetForward(inst) then --LETS TRY THIS ONE... NICELY DONE, ME! WHY THANK YOU, ME
					inst:PushEvent("dash")
				end
            end),
            TimeEvent(8*FRAMES, function(inst)
				inst.sg:GoToState("idle")
            end),
        },    
    },
	
	
	
    State{
        name = "hit",
        tags = {"busy", "inknockback", "no_air_transition", "nolandingstop", "ignore_ledge_barriers", "noairmoving"},
        
        onenter = function(inst, hitstun)
			inst.AnimState:PlayAnimation("flinch2")
			inst.components.stats.norecovery = false
			inst.AnimState:SetTime(1*FRAMES)
			
			
			--DST CHANGE!!!- CLIENTS HAVE VERSIONS WITH LESS EVENT HANDLERS AND NO ONENTER PARAMETERS. LET APPLY THAT TO OURS--
			local hitstun = hitstun --10-14-17 WAIT WHAT??? I FORGET WHAT THAT MEANS... OH WELL.
			-- if not hitstun then --11-26-17 NO YOU FOOL!! THIS IS CAUSING CLIENTS TO SEE THEIR CHARACTERS GO TO IDLE IN 80 FRAMES
				-- hitstun = 80
			if ISGAMEDST and not TheWorld.ismastersim then --11-26-17
				return --INSTEAD, JUST DONT HAVE CLIENTS RUN ANYTHING BELOW THIS LINE. LET THE SERVER HANDLE HITSTUN
			end
			
			local attack_cancel_modifier = hitstun --* 0.9
			local dodge_cancel_modifier = hitstun --* 1.2
			
			inst.task_hitstun = inst:DoTaskInTime((hitstun*FRAMES), function(inst) --12-4
				inst.sg:RemoveStateTag("noairmoving")
				inst.sg:AddStateTag("can_jump")
			end)
			
			inst.task_attackstun = inst:DoTaskInTime((attack_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:AddStateTag("can_attack")
			end)
			inst.task_dodgestun = inst:DoTaskInTime((dodge_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end)
            inst:ClearBufferedAction()     
        end,
		
		onexit = function(inst)
			if ISGAMEDST and TheWorld.ismastersim then --11-26-17
				inst.task_hitstun:Cancel()
				inst.task_attackstun:Cancel()
				inst.task_dodgestun:Cancel()
			end
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline =
        {
            TimeEvent(2*FRAMES, function(inst)   --HAVE VOICE CUT OFF --TODOLIST
				inst.SoundEmitter:KillAllSounds()  
            end),
			
			TimeEvent(20*FRAMES, function(inst)   --CHANGE THIS LATER --TODOLIST
                --inst.sg:RemoveStateTag("busy")
            end),
        },        
               
    },
    
	
	
	State{
        name = "grab_ledge",
		tags = {"busy", "hanging", "resting", "nolandingstop", "no_air_transition"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_grab")
			inst.SoundEmitter:PlaySound("smash_sounds/grab/grab1")
			
			inst:ForceFacePoint(ledgeref.Transform:GetWorldPosition())
			local x, y, z = ledgeref.Transform:GetWorldPosition()
			inst.Transform:SetPosition( x-(0.25*inst.components.launchgravity:GetRotationValue()), y-0, z ) -- -1.5
			
			inst:PushEvent("swaphurtboxes", {preset = "ledge_hanging"})
			inst.components.hurtboxes:SpawnTempHurtbox(-0.2, -0.1, 0.6, 0, 140)  --(xpos, ypos, size, ysize, frames, property)
			inst.components.hitbox:MakeFX("glint_ring_1", -0.1, -0.1, 0.2,   0.8, 0.8,   0.5, 5, 0.8,  0, 0, 0) 
			inst.components.launchgravity:Launch(0, 0, 0) --3-17 SO YOU DONT RESUME PREVIOUS MOMENTUM
			inst.Physics:SetActive(false) --CAREFUL WITH THIS
			inst.components.hurtboxes:SpawnPlayerbox(0, -1.7, 0.35, 0.7, 0)
        end,
		
		onexit = function(inst)
			inst.components.launchgravity:Launch(0, 0, 0)
			inst.Physics:SetActive(true) 
			inst.components.hurtboxes:SpawnPlayerbox(0, 0.7, 0.35, 0.7, 0)
        end,
        
		timeline =
        {
			TimeEvent(1*FRAMES, function(inst) 
				if not inst:HasTag("noledgeinvuln") then
					inst.sg:AddStateTag("intangible")
					--11-14-17 PREVENTS PLAYERS FROM REGRABBING THE LEDGE WITH INTANGIBILITY. PUTTING IN STATEGRAPHS SO VISIBILITY SHOWS UP FOR CLIENTS TOO
					inst:AddTag("noledgeinvuln")
					if inst.ledgeregrabbingtask then
						inst.ledgeregrabbingtask:Cancel()
						inst.ledgeregrabbingtask = nil
					end
					
					inst.ledgeregrabbingtask = inst:DoTaskInTime(4, function(inst) --ADD IT BACK AFTER 4 SECONDS
						inst:RemoveTag("noledgeinvuln")
					end)
				end
			end),
			TimeEvent(10*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("resting")
			end),
			TimeEvent(31*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
			end),
			TimeEvent(140*FRAMES, function(inst) 
				inst.sg:GoToState("ledge_drop")
			end),
		},
		
		events=
        {
            EventHandler("jump", function(inst)
				if not inst.sg:HasStateTag("resting") then inst.sg:GoToState("ledge_jump") end
			end ),
			EventHandler("forward_key", function(inst)
				if not inst.sg:HasStateTag("resting") then inst.sg:GoToState("ledge_getup") end
			end ),
			EventHandler("backward_key", function(inst)
				if not inst.sg:HasStateTag("resting") then inst.sg:GoToState("ledge_drop") end
			end ),
			EventHandler("down", function(inst)
				if not inst.sg:HasStateTag("resting") then inst.sg:GoToState("ledge_drop") end
			end ),
			EventHandler("block_key", function(inst)
				if not inst.sg:HasStateTag("resting") then inst.sg:GoToState("ledge_roll") end
			end ),
			EventHandler("attack_key", function(inst)
				if not inst.sg:HasStateTag("resting") then inst.sg:GoToState("ledge_attack") end
			end ),
        },
    },
	
	State{
        name = "ledge_getup",
		tags = {"busy", "intangible", "nolandingstop"},
        
        onenter = function(inst, ledgeref)
			--inst.AnimState:PlayAnimation("ledge_getup")
			inst.Physics:SetActive(false) --CAREFUL WITH THIS
        end,
		
		onexit = function(inst)
			inst.Physics:SetActive(true) 
        end,
        
		timeline =
        {
			TimeEvent(5*FRAMES, function(inst)
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
				inst.AnimState:PlayAnimation("ledge_getup") --DELAYED TO MORE CLOSELY MATCH INVULN FRAMES
			end),
			
			TimeEvent(12*FRAMES, function(inst)
				inst.components.locomotor:Teleport(0.3, 0.1, 0)
				inst.Physics:SetActive(true)
				inst.components.jumper:ScootForward(8)
			end),
			
			TimeEvent(15*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
			end),
			TimeEvent(16*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				--inst.sg:GoToState("idle")
			end),
		},
		
		events=
        {
            EventHandler("animover", function(inst) inst.AnimState:PlayAnimation("idle") end),
        },
    },
	
	
	State{
        name = "ledge_drop",
		tags = {"hanging", "no_fastfalling"},
        
        onenter = function(inst)
			
			inst:AddTag("no_grab_ledge")
			inst:DoTaskInTime(0.5, function(inst)
				inst:RemoveTag("no_grab_ledge")
			end)
			inst.Physics:SetActive(true)
			inst.components.locomotor:Teleport(-0.5, -2, 0)
			inst.components.launchgravity:Launch(0, 0, 0)
			inst.AnimState:PlayAnimation("idle")
        end,
		
		timeline =
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.sg:GoToState("air_idle")
			end),
		},
    },
	
	
	State{
        name = "ledge_jump",
		tags = {"busy", "intangible"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_jump")
			-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			inst.Physics:SetActive(false) --CAREFUL WITH THIS
        end,
		
		onexit = function(inst)
			inst.Physics:SetActive(true) 
        end,
        
		timeline =
        {
			TimeEvent(4*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				inst.components.launchgravity:Launch(1, inst.components.stats.jumpheight, 0)
				inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			end),
			TimeEvent(6*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
			end),
			TimeEvent(7*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
			TimeEvent(30*FRAMES, function(inst)
				inst.sg:GoToState("air_idle")
			end),
		},
    },
	
	State{
        name = "ledge_roll",
		tags = {"busy", "intangible", "nolandingstop", "no_air_transition"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_getup")
			inst.Physics:SetActive(false) --CAREFUL WITH THIS
        end,
        
		timeline =
        {
			TimeEvent(6*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				inst.AnimState:PlayAnimation("rolling")
				inst.components.locomotor:RunForward()
				inst.components.locomotor:Teleport(0.3, 0.1, 0) --TELEPORT TO AVOID BUMPING INTO THE LIP OF THE LEDGE
				inst.components.locomotor:Motor(15, 0, 7)
			end),
			TimeEvent(15*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			TimeEvent(17*FRAMES, function(inst) --11-14-17 ALSO ADDING THIS TO PREVENT THE SLIDING
				inst.components.jumper:ScootForward(8)
			end),
			TimeEvent(25*FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
		},
    },
	
	State{
        name = "ledge_attack",
		tags = {"busy", "intangible", "nolandingstop"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_attack")
			inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			inst.Physics:SetActive(false)
        end,
		
		onexit = function(inst)
			inst.Physics:SetActive(true) 
        end,
        
		timeline =
        {
			TimeEvent(5*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				inst.components.jumper:ScootForward(8)
			end),
			
			TimeEvent(8*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("woosh1", 0.2, 0.6, 0.2,   1.8, 2.5,   0.8, 4, 0)
			
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetDamage(4)
				inst.components.hitbox:SetHitLag(0.3)
				inst.components.hitbox:SetCamShake(0.3)
				inst.components.hitbox:SetHighlight(0.3)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0)
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SpawnHitbox(2.0, 0.5, 0) 
			end),
			
			TimeEvent(10*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
			end),
			
			TimeEvent(27*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
		},
    },
	
	
	State{
        name = "duck",
		tags = {"idle", "ducking"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("duck")
			inst:PushEvent("swaphurtboxes", {preset = "ducking"})
        end,
    },
	
	
	State{
        name = "highleap",
		tags = {"can_usmash", "can_upspec", "no_running", "no_blocking", "busy"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("jump")
			inst.components.locomotor:Clear()
			inst:AddTag("refresh_softpush") --LETS KEEP THESE GUYS FROM SLIDING?
			
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
        end,
		
		onexit = function(inst)
            inst.components.stats.jumpspec = nil
        end,
        
		timeline =
        {
			TimeEvent(2*FRAMES, function(inst) --10-11-18 -WES'S IS GONNA BE 1 FRAME FASTER
				inst.sg:RemoveStateTag("busy") 
				inst:AddTag("listenforfullhop")
				inst.components.jumper:Jump(inst) --LETS BUMP THIS DOWN A LINE OR TWO
				inst.sg:RemoveStateTag("prejump")
				inst.sg:RemoveStateTag("can_usmash")
				--11-16, SHORT HOPS ARE DIFFICULT AS HEcc TO DO BUT IT ALL WORKS FOR NOW

				
				inst:DoTaskInTime(2*FRAMES, function(inst)
					inst.components.jumper:CheckForFullHop()
				end)
			end),
			
			-- TimeEvent(2*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("can_usmash")
			-- end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0.1, 0.2)
			end),
			
			TimeEvent(17*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			end),
		},

        events=
        {
            EventHandler("animover", function(inst)
				inst.sg:GoToState("air_idle") 
			end ),
        },
    },
	
	State{
        name = "doublejump",
		tags = {"jumping"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("flip")
			inst.components.jumper:DoubleJump(inst)
			inst.components.hitbox:MakeFX("ground_bounce", 0, 1, -1, 1, 1, 0.8, 7, 1)
			inst:PushEvent("swaphurtboxes", {preset = "flipping"})
			
        end,
        
		timeline =
        {	
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0.1, 0.2)
			end),
			
			TimeEvent(17*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			end),
		},
        events=
        {
            EventHandler("animover", function(inst)
				inst.sg:GoToState("air_idle") 
			end ),
        },
    },
	
	
	State{
        name = "tumble", 
        tags = {"busy", "tumbling", "noairmoving", "di_movement_only", "no_air_transition", "ignore_ledge_barriers", "reeling"},
        
        onenter = function(inst, hitstun, direction)
			inst.components.stats.norecovery = false

			if ISGAMEDST and not TheWorld.ismastersim then --11-26-17
				return --INSTEAD, JUST DONT HAVE CLIENTS RUN ANYTHING BELOW THIS LINE. LET THE SERVER HANDLE HITSTUN
			end
			
			local angle = inst.components.launchgravity:GetAngle() * DEGREES
			
			if inst.components.launchgravity:GetAngle() <= 50 then
				inst.AnimState:PlayAnimation("tumble_back")
				inst:PushEvent("swaphurtboxes", {preset = "hitstun3"})
			elseif inst.components.launchgravity:GetAngle() >= 240 and inst.components.launchgravity:GetAngle() <= 300 then
				inst.AnimState:PlayAnimation("tumble_down")
			else
				inst.AnimState:PlayAnimation("tumble_up_000")
				inst:PushEvent("swaphurtboxes", {preset = "hitstun1"})
			end
			
			local attack_cancel_modifier = hitstun --* 0.9 --3-4-17 YOU KNOW WHAT.... LETS GIVE IT A SHOT WITHOUT THESE
			local dodge_cancel_modifier = hitstun --* 1.2
			if dodge_cancel_modifier >= hitstun + 30 then
				dodge_cancel_modifier = hitstun + 30
			end
			
			
			--local dodge_cancel_modifier = (((hitstun * 2.5) /2)) --no thats weird
			
			inst.task_hitstun = inst:DoTaskInTime((hitstun*FRAMES), function(inst) --12-4
				inst:PushEvent("swaphurtboxes", {preset = "hitstun2"})
				inst.AnimState:PlayAnimation("tumble_fall")
				inst.sg:AddStateTag("can_jump")
				inst.sg:RemoveStateTag("di_movement_only")
				inst.sg:RemoveStateTag("noairmoving")
				--3-15 GONNA TRY AND ADD SOMETHING THAT CANCELS OUT MOMENTUM SO YOU ARENT FORCED TO JUMP TO SURVIVE
				inst.components.jumper:AirStall(2, 1)
				inst.sg:RemoveStateTag("reeling") --10-20-18 --DONT LET WES TAKE LIKE 50% LESS VERTICAL KNOCKBACK
			end)
			
			inst.task_attackstun = inst:DoTaskInTime((attack_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:AddStateTag("can_attack")
			end)
			inst.task_dodgestun = inst:DoTaskInTime((dodge_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:RemoveStateTag("busy")
			end)
        end,

        onexit = function(inst)
			if ISGAMEDST and TheWorld.ismastersim then
				inst.task_hitstun:Cancel()
				inst.task_attackstun:Cancel()
				inst.task_dodgestun:Cancel()
			end
        end,
		
		events=
        {
            EventHandler("block_key", function(inst)
				inst:AddTag("cantech")
				inst:DoTaskInTime(3*FRAMES, function(inst) inst:RemoveTag("cantech") end )
            end),
        },
        
    },
	
	State{
        name = "land_clumsy",
        tags = {"busy", "grounded", "nogetup"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("clumsy_land")  
			inst.components.hitbox:MakeFX("ground_bounce", -0.5, 0.1, -1, 1.5, 1.5, 0.8, 10, 0)
			inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/explode")
			inst:PushEvent("swaphurtboxes", {preset = "grounded"})
        end,
        
        timeline =
        {
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0, 0.5)
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0, -0.5)
				inst.sg:GoToState("grounded") 
			end),
			
            TimeEvent(14*FRAMES, function(inst)
				--CHECK FOR IF STILL HOLDING SHEILD
                inst.sg:RemoveStateTag("busy")
			end),
        },
        
    },
	
	State{
        name = "grounded",
        tags = {"busy", "prone", "grounded", "nogetup"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("grounded")
			inst:PushEvent("swaphurtboxes", {preset = "grounded"})
        end,
        
        timeline =
        {
		
			TimeEvent(2*FRAMES, function(inst)
				inst.sg:RemoveStateTag("nogetup")
			end),

            TimeEvent(60*FRAMES, function(inst)
				inst.sg:GoToState("getup")
			end),
        },
		
		events=
        {
            EventHandler("up", function(inst)
				if not inst.sg:HasStateTag("nogetup") then
					inst.sg:GoToState("getup")
				end
            end),
			
			EventHandler("attack_key", function(inst)
				if not inst.sg:HasStateTag("nogetup") then
					inst.sg:GoToState("getup_attack")
				end
            end),
			
			EventHandler("forward_key", function(inst)
				if not inst.sg:HasStateTag("nogetup") then
					-- inst.sg:GoToState("roll_forward")
					inst.sg:GoToState("tech_forward_roll")
				end
            end),
			
			EventHandler("backward_key", function(inst)
				if not inst.sg:HasStateTag("nogetup") then
					-- inst.components.locomotor:TurnAround()
					-- inst.sg:GoToState("roll_forward")
					inst.sg:GoToState("tech_backward_roll")
				end
            end),
        },
    },
	
	
	State{
        name = "getup",
        tags = {"busy", "grounded"}, 
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("getup1")
        end,
        
        timeline =
        {
			TimeEvent(2*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
			end),
			
            TimeEvent(5*FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
        },
        
    },
	
	
	State{
        name = "getup_attack", --THIS IS AN IMPORTANT STATE. I'D RECCOMEND LEAVING THIS ONE ALONE, APART FROM THE VISUALS
        tags = {"attack", "busy", "intangible", "grounded"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("getup_attack")
			inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow, alpha)
        end,
        
        timeline=
        {
			TimeEvent(5*FRAMES, function(inst)
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(90)
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetSize(0.8, 0.5)
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(1, 0.2, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			end),
			--GETUP ATTACKS USUALLY HIT EITHER ONE SIDE AT A TIME, OR BOTH SIDES AT ONCE
			--EITHER WAY, DON'T BE SHY WITH THE RANGE OF THESE ATTACKS. THEY NEED TO EXTRA BE LONG TO CLEAR ENOUGH SPACE ON BOTH SIDES OF YOUR CHARACTER
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(90)
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetSize(0.8, 0.5)
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(-1, 0.2, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			end),
			
            TimeEvent(17*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	State{
        name = "tech_getup", 
        tags = {"busy", "intangible", "teching"},
        
        onenter = function(inst, target)
            -- inst.components.hitbox:Blink(inst, 2,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow, alpha)
			--I GOT LAZY AND JUST SET THE TECH ANIMATION AS THEIR REGULAR LANDING ANIMATION
			--BUT FEEL FREE TO CREATE YOUR OWN TECH ANIMATION TO USE INSTEAD
			inst.AnimState:PlayAnimation("landing") 
			inst.components.hitbox:MakeFX("slide1", -0.2, 0, 1, 1.5, 1.5, 1, 10, 0)
			inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        end,
        
        timeline =
        {
			TimeEvent(10*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				-- inst.AnimState:SetMultColour(1,1,1,1)
				inst.sg:GoToState("idle")
			end),
        },
        
    },
	
	
	--NEW TECH-ROLLS THAT USE THE UPDATED FUNCTS
	State{
        name = "tech_forward_roll", 
        tags = {"busy", "intangible", "teching"},
        
        onenter = function(inst, target)
			-- inst.components.hitbox:Blink(inst, 2,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow, alpha)
			inst.AnimState:PlayAnimation("rolling")
			inst.AnimState:SetTime(2*FRAMES)
			inst.components.locomotor:Motor(12, 0, 7)
			inst.components.hitbox:MakeFX("slide1", -0.8, 0, 1, 1.5, 1.5, 1, 10, 0)
        end,

        onexit = function(inst)
			inst.components.locomotor:Clear()
			if inst.motortask then
				inst.motortask:Cancel()
			end
        end,
			
        
        timeline =
        {
		   
		    TimeEvent(12*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
				
				inst.components.locomotor:Stop()
				inst.components.jumper:ScootForward(7)
				--THE STRENGTH AND TIMING OF THESE SCOOTS ARE CUSTOMIZED TO MATCH EACH CHARACTER ANIMATION
				--FEEL FREE TO ADJUST THIS STATE AS YOU SEE FIT
			end),
            
			TimeEvent(18*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
		},
    },
	
	
	
	State{
        name = "tech_backward_roll", 
        tags = {"busy", "intangible", "teching"},
        
        onenter = function(inst, target)
			-- inst.components.hitbox:Blink(inst, 2,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow, alpha)
			inst.AnimState:PlayAnimation("backward_tech")
			inst.sg:AddStateTag("intangible")
			inst.components.hitbox:MakeFX("slide1", -0.8, 0, 1, 1.5, 1.5, 1, 10, 0)
        end,

        onexit = function(inst)
			inst.components.locomotor:Clear()
			if inst.motortask then
				inst.motortask:Cancel()
			end
        end,
        
        timeline =
        {
			
			TimeEvent(3*FRAMES, function(inst)
				inst.components.locomotor:Motor(-18, 0, 5)
				inst.AnimState:SetTime(9*FRAMES)
			end),
		    
			TimeEvent(10*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("landing")
				inst.AnimState:SetTime(2*FRAMES)
				inst.components.hitbox:MakeFX("slide1", -0.8, 0, 1, 1.5, 1.5, 1, 10, 0)
			end),
		   
		    TimeEvent(12*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
				
				inst.components.locomotor:Stop()
				inst.components.jumper:ScootForward(-7)
			end),
            
			TimeEvent(18*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
		},
        
    },
	
	
	
	State{
        name = "ll_medium_getup",
        tags = {"busy", "can_grab_ledge"}, 
        
        onenter = function(inst, llframes)
			inst.AnimState:PlayAnimation("landing") --("ll_med")
			inst:PushEvent("swaphurtboxes", {preset = "landing"})
			
			if inst.components.launchgravity.llanim then
				inst.AnimState:PlayAnimation(inst.components.launchgravity.llanim)
			end
			
			if not llframes then
				llframes = 10
			end
			
			inst.task_ll = inst:DoTaskInTime((llframes*FRAMES), function(inst) --12-4
				inst.sg:RemoveStateTag("busy")
				-- inst.sg:GoToState("idle")
				if inst.components.stats:CheckForBufferedMove(inst) == false then --3-27-19 IF YOU HAVE A MOVE BUFFERED, GO TO IT. ELSE, JUST GO TO IDLE
					inst.sg:GoToState("idle")
				end
			end)
        end,
		onexit = function(inst)
			inst.task_ll:Cancel()
        end,     
    },
	
	
	State{
        name = "meteor",
        tags = {"busy", "grounded"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("clumsy_land")
			inst.components.hitbox:MakeFX("ground_bounce", -0.5, 0.1, -1, 2.5, 2.5, 0.8, 10, 0)
			inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
			inst:PushEvent("swaphurtboxes", {preset = "grounded"})
        end,
        
		timeline =
        {
			TimeEvent(30*FRAMES, function(inst) 
				inst.sg:GoToState("getup")  
			end),
		},
    },

	
	State{	--THIS IS A CRUCIAL STATE AND SHOULD NOT BE ALTERED!! (EXCEPT FOR THE ANIMATION, IF YOU WANT)
        name = "block_startup", 
        tags = {"busy", "tryingtoblock", "blocking", "can_parry", "canoos"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("block_startup")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
        end,
        
        timeline =
        {
            TimeEvent(3*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("block")
			end),
        },
    },
	
	State{
        name = "block",
        tags = {"canrotate", "blocking", "tryingtoblock", "canoos", "no_running"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("block")
        end,
        
        events=
        {
			EventHandler("down", function(inst) 
				inst.sg:GoToState("spotdodge")
			end),
			
			EventHandler("jump", function(inst)
				inst:RemoveTag("wantstoblock")
            end),
			
			EventHandler("attack_key", function(inst)
				inst.sg:GoToState("grab")
            end),
			
			EventHandler("forward_key", function(inst)
				inst.sg:GoToState("roll_forward")
            end),
			
			EventHandler("backward_key", function(inst)
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("roll_forward")
            end),
        },
    },
	
	
	State{
        name = "parry",
        tags = {"canrotate", "blocking", "tryingtoblock", "parrying", "busy"},
        
        onenter = function(inst, timeout)
			inst.components.hitbox:MakeFX("shockwave_parry", 0.5, 1.5, 1, 1, 1.8, 1, 12, 1)
			inst.AnimState:PlayAnimation("block")
			inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_forcefield_armour_dull")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_unbreakable")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")
			inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
			
			inst.sg:SetTimeout(timeout)
        end,

        onexit = function(inst)
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
		
		ontimeout = function(inst)
			inst.sg:RemoveStateTag("busy")
			inst.sg:AddStateTag("canoos")
        end,
		
    },
	
	
	State{
        name = "block_stunned",
        tags = {"blocking", "tryingtoblock", "busy", "block_stunned"},
        
        onenter = function(inst, timeout)
			inst.AnimState:PlayAnimation("blockstunned")
			inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_dull")
			inst.sg:SetTimeout(timeout or 1)
        end,
		
		ontimeout= function(inst)
            if inst:HasTag("wantstoblock") then
				inst.sg:GoToState("block_unstunned")
			else
				inst.sg:GoToState("block_stop")
			end
        end,
		
    },
	
	
	State{
        name = "block_unstunned",
        tags = {"blocking", "tryingtoblock", "busy"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("blockstunned_resume")
			
			if inst:HasTag("wantstoblock") then
				inst.sg:GoToState("block")
			else
				inst.sg:GoToState("block_stop")
			end
        end,
    },
	
	State{
        name = "block_stop",
        tags = {"tryingtoblock", "busy"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("block_drop")
        end,
		
		onupdate = function(inst)
			--CHEAP HOTFIX TO ENSURE THIS STATE DOESN'T ADD EXTRA FRAMES TO THE ENDLAG
        end,
		
        timeline =
        {
			TimeEvent(3*FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	
	State{
        name = "brokegaurd",  
        tags = {"busy", "intangible", "dizzy", "ignoreglow", "noairmoving"},
		
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("tumble_up_000")
			inst.SoundEmitter:PlaySound("dontstarve/common/destroy_magic")
			inst.AnimState:SetAddColour(1,1,0,0.6)
        end,
        
        timeline =
        {
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.launchgravity:Launch(0, 20)
				inst.AnimState:SetAddColour(0,0,0,0)
				inst.sg:RemoveStateTag("blocking")
			end),
			
			TimeEvent(10*FRAMES, function(inst) 
				inst.AnimState:SetAddColour(1,1,0,0.6)
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				inst.AnimState:SetAddColour(0,0,0,0)
			end),
			
			TimeEvent(20*FRAMES, function(inst) 
				inst.AnimState:SetAddColour(1,1,0,0.6)
			end),
			
			TimeEvent(25*FRAMES, function(inst) 
				inst.AnimState:SetAddColour(0,0,0,0)
			end),
			
			TimeEvent(50*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
			end),
			
            TimeEvent(150*FRAMES, function(inst)
				inst.AnimState:SetAddColour(1,0.5,0,0.6)
				inst.sg:RemoveStateTag("busy")
			end),
        },
        
        events=
        {
            --EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
	
	State{
        name = "dizzy",  
        tags = {"dizzy", "busy"},  
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("getup1")
        end,
		
        timeline =
        {
			TimeEvent(150*FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
        },
		
		 events=
        {
            EventHandler("animover", function(inst) 
				inst.AnimState:PlayAnimation("dizzy") 
				inst.components.hitbox:MakeFX("stars", 0, 2.5, 1, 1, 1, 1, 65, 0.2)  --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			end),
        },
    },
	
	State{
        name = "spotdodge",
        tags = {"intangible", "dodging", "busy"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("spotdodge")
        end,

        -- onexit = function(inst)
			-- inst.AnimState:SetMultColour(1,1,1,1)
        -- end,
        
        timeline =
        {
            TimeEvent(1*FRAMES, function(inst) 
				inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow)
				inst.sg:AddStateTag("intangible")
				-- inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				-- inst.AnimState:SetMultColour(1,1,1,1)
			end),
			
            TimeEvent(14*FRAMES, function(inst)
			--CHECK FOR IF STILL HOLDING SHEILD
				-- inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	State{
        name = "roll_forward", 
        tags = {"dodging", "busy", "nopredict"},  
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("rolling")
			-- inst.components.hitbox:Blink(inst, 4,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			
			inst.task_1 = inst:DoPeriodicTask(0.1, function(inst)
					inst.Physics:SetMotorVel(14, 0, 0) --10
				end)
        end,

        onexit = function(inst)
			--inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.locomotor:Clear()
			if inst.task_1 then
				inst.task_1:Cancel()
			end
        end,
        
        timeline =
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow)
				inst.sg:AddStateTag("intangible")
		    end),
		      
			  
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0, -0.2,   1.0, 1.0,   0.6, 8, 0)
		    end),
		   

			-- TimeEvent(4*FRAMES, function(inst)
				-- inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
		    -- end),
			
			TimeEvent(6*FRAMES, function(inst) --7
				inst.task_1:Cancel()
			end),
            
			TimeEvent(8*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
				inst.components.hitbox:MakeFX("slide1", 1.5, 0, -0.2,   -0.8, 0.8,   0.6, 8, 0)
				-- inst.AnimState:SetMultColour(1,1,1,1)
			end),
			
			TimeEvent(9*FRAMES, function(inst) --10
				inst.components.locomotor:Stop()
				inst.components.jumper:ScootForward(10)
			end),
			
            TimeEvent(14*FRAMES,
				function(inst)
				--CHECK FOR IF STILL HOLDING SHEILD  --TODOLIST
					inst.components.locomotor:TurnAround()
                    inst.sg:RemoveStateTag("busy")
					inst.sg:GoToState("idle")
				end),
        },
    },
	
	
	State{
        name = "airdodge",
        tags = {"dodging", "busy", "airdodging", "ll_medium"}, 
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("airdodge")
			inst.components.launchgravity:SetLandingLag(10)
        end,

        -- onexit = function(inst)
			-- inst.AnimState:SetMultColour(1,1,1,1)
        -- end,
        
        timeline =
        {		
		   TimeEvent(1*FRAMES, function(inst) 
				inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow)
				inst.sg:AddStateTag("intangible")
				-- inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
			end),
            
			TimeEvent(15*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				-- inst.AnimState:SetMultColour(1,1,1,1)
			end),
			
            TimeEvent(20*FRAMES,
				function(inst)
				--CHECK FOR IF STILL HOLDING SHEILD
                    inst.sg:RemoveStateTag("busy")
					inst.sg:GoToState("air_idle")
				end),
        },
        
    },
	
	--!!!!!!! STANDERDIZE GRABS http://www.ssbwiki.com/grab   ---!! TODOLIST
	
	
	State{
        name = "grab",
        tags = {"busy", "grabbing", "short"},
        
        onenter = function(inst, target)
            --inst.components.locomotor:Stop()
			--inst.AnimState:PlayAnimation("give")
			inst.AnimState:PlayAnimation("grab")
			-- inst.components.hurtboxes:SpawnPlayerbox(0, 0.7, 0.35, 0.7, 0)
        end,

        onexit = function(inst)
            --inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true) --THE HECK IS THIS HERE FOR?
        end,
        
        timeline =
        {
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(0.5)
				inst.components.hitbox:SetLingerFrames(1)
			
				inst.components.hitbox:SpawnGrabbox(0.8, 1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				
				
				
			end),

            TimeEvent(15*FRAMES,
				function(inst)
                    inst.sg:GoToState("idle")
				end),
        },
    },
	
	
	State{
        name = "dash_grab", 
        tags = {"busy", "grabbing"},  
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("grab")

        end,
        
        timeline =
        {
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(1)
			
				inst.components.hitbox:SpawnGrabbox(0.5, 1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")	
				
			end),

            TimeEvent(15*FRAMES,
				function(inst)
                    inst.sg:GoToState("idle")
				end),
        },
    },
	
	State{
        name = "grabbing",
        tags = {"busy", "grabbing", "handling_opponent"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("grabbing")
			inst.SoundEmitter:PlaySound("smash_sounds/grab/grab1")
			inst.Physics:Stop()
			inst.components.stats.opponent.Physics:SetActive(false)
        end,
		
		onexit = function(inst)
			if not inst.components.stats:GetOpponent() then return end
			inst.components.stats.opponent.Physics:SetActive(true)
		end,
        
        timeline =
        {
			-- TimeEvent(9*FRAMES, function(inst) 
				-- inst.components.hitbox:SpawnGrabbox(1.5, 0, 0) 
				-- --inst.sg:RemoveStateTag("abouttoattack") 
			-- end),

            TimeEvent(60*FRAMES,
				function(inst)
                    inst.sg:GoToState("fthrow")
				end),
        },
		 events=
        {
            EventHandler("forward_key", function(inst) 
				inst.sg:GoToState("fthrow")
			end),
			EventHandler("down", function(inst) 
				inst.sg:GoToState("fthrow")
			end),
			EventHandler("backward_key", function(inst) 
				inst.sg:GoToState("bthrow")
			end),
			EventHandler("up", function(inst) 
				inst.sg:GoToState("bthrow")
			end),
			EventHandler("on_punished", function(inst)
				inst.components.stats:GetOpponent()
				inst.components.stats.opponent:PushEvent("clank", {rebound = 10})
			end),
			EventHandler("end_grab", function(inst)
				inst:PushEvent("clank", {rebound = 10})
			end),
        },
    },
	
	
	State{
        name = "grabbed",  
        tags = {"busy", "nolandingstop"},  
        
        onenter = function(inst, anim)
            inst.AnimState:PlayAnimation("grabbed")
			
			if anim then
				inst.AnimState:PlayAnimation(anim)
			end
        end,
        
		onexit = function(inst)
			if inst.components.stats.opponent and inst.components.stats.opponent:IsValid() then
				inst.components.stats.opponent:PushEvent("end_grab")
			end
		end,
		
		timeline =
        {
            TimeEvent(90*FRAMES, function(inst) --1-3-22 NEW SAFTEY NET AUTO REBOUNDS THEM AFTER 3 SECONDS
				inst.sg:GoToState("rebound", 10)
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.AnimState:PlayAnimation("grabbed") end),
        },
    },
	
	
	--10-10-16 NEW STATE FOR CUSTOM GRABS AND SUCH
	State{
        name = "ragdoll",  
        tags = {"busy", "no_air_transition", "nolandingstop"}, --REMOVING CANGRABLEDGE
        
        onenter = function(inst, anim)
            --PLAYERS MUST REMAIN RAGDOLLS DURING THIS STATE
			-- inst.components.stats.opponent.Physics:SetActive(true)
			if anim then
				inst.AnimState:PlayAnimation(anim)
			end
        end,
		
		onexit = function(inst)
			-- inst.components.stats.opponent.Physics:SetActive(true)
		end,
        
        events=
        {
            -- EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
	
	
	
	State{
        name = "fthrow",
        tags = {"attack", "busy", "handling_opponent"},
        
        onenter = function(inst, target)
			inst.components.stats:GetOpponent()
			inst.AnimState:PlayAnimation("fthrow")
			inst.AnimState:Resume()
        end,
        
        timeline =
        {
            --TimeEvent(0*FRAMES, function(inst) self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0) end),
			
			-- TimeEvent(8*FRAMES, function(inst)   --16
				-- inst.components.stats:GetOpponent()
				-- inst.components.stats.opponent.AnimState:PlayAnimation("clumsy_land")
			-- end),
			
			-- TimeEvent(0*FRAMES, function(inst)   --16
				-- local pos = Vector3(inst.Transform:GetWorldPosition())
				-- inst.components.stats.opponent.Transform:SetPosition((pos.x), (pos.y + 1.5), (pos.z))  -- + self.zoffset
				-- --self.inst.AnimState:Resume()
				-- --self.inst.sg:GoToState("throw")
				-- inst.components.stats.opponent.sg:GoToState("thrown")
				-- inst.components.stats.opponent.components.launchgravity:Launch(-2, -4, 0)
			-- end),
			
			
			
			TimeEvent(9*FRAMES, function(inst)
				
				inst.components.hitbox:SetDamage(2)
				inst.components.hitbox:SetAngle(60) 
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(100)

				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(2)
				
				
				inst.components.hitbox:SpawnHitbox(1.5, 1.2, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
				
				
				--(fxname, xoffset, yoffset, zoffset,					 xsize, ysize, alph, dur, glw,    r, g, b,  stick, build, bank)
				--inst.components.hitbox:MakeFX("flap_loop", 0, 2, -0.2,   0.5, 0.5,     1, 14, 0,       0, 0, 0,   1, "crow_build", "crow")
				inst.components.hitbox:MakeFX("pop",        1.7, 0, 0.6,   0.8, 0.8,     0, 10, 0.0,    1,0,0,    1, "balloon", "balloon")
				--THE BALLOON WONT BE VISIBLE UNTIL WE CHOOSE IT'S SHAPE I THINK
				inst.components.stats.lastfx.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", "balloon_1")
				inst.components.stats.lastfx.AnimState:SetTime(1*FRAMES)
				inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
				
			end),
			
			TimeEvent(18*FRAMES, function(inst)
				inst.sg:GoToState("idle") 
			end),
			
        },
        
        events=
        {
            EventHandler("on_punished", function(inst)
				if not inst.components.stats:GetOpponent() then return end
				inst.components.stats.opponent:PushEvent("clank", {rebound = 10})
			end),
        },
    },
	
	State{
        name = "bthrow",
        tags = {"attack", "busy", "handling_opponent", "force_direction"},
        
        onenter = function(inst, target)
			
			inst.components.stats:GetOpponent()
			inst.AnimState:PlayAnimation("bthrow")
			inst.AnimState:Resume()
			inst:AddTag("refresh_softpush") --3-2-17 HOPEFULLY FIXES THE WEIRD LEDGETHROWING THING --IT DID
        end,
        
        timeline =
        {
			TimeEvent(4*FRAMES, function(inst)   --16
				local pos = Vector3(inst.Transform:GetWorldPosition())
				inst.components.stats.opponent.Transform:SetPosition((pos.x+(0.5*inst.components.launchgravity:GetRotationValue())), (pos.y + 0.5), (pos.z))  -- + self.zoffset
				--self.inst.AnimState:Resume()
				--self.inst.sg:GoToState("throw")
				inst.components.stats.opponent.sg:GoToState("thrown")
				inst.components.stats.opponent.components.launchgravity:Launch(15, 12, 0)
			end),

			
			
			TimeEvent(7*FRAMES, function(inst)   --16

				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(136) --46
				inst.components.hitbox:SetBaseKnockback(98)
				inst.components.hitbox:SetGrowth(45) --35
				inst.components.hitbox:SetSize(1)
				inst.components.hitbox:SetLingerFrames(2)
				
				
				inst.components.hitbox:SpawnHitbox(-0.6, 0.8, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			TimeEvent(18*FRAMES, function(inst)   --16
				inst.sg:GoToState("idle") 
			end),
			
        },
        
        events=
        {
        
        },
    },
	
	State{
        name = "thrown",  
        tags = {"busy", "no_air_transition", "nolandingstop", "can_grab_ledge"}, --ADDING A CANGRABLEDGE IN CASE THROWS HAPPEN OVER EDGES
        
        onenter = function(inst, target)
            --PLAYERS MUST REMAIN RAGDOLLS DURING THIS STATE
        end,
        
        timeline =
        {
			TimeEvent(30*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy") --JUST AN EMERGENCY BACKUP
			end),
        },
    },
	
	State{
        name = "freefall",  
        tags = {"busy", "helpless", "ll_medium", "can_grab_ledge", "no_fastfalling"},  --1-9-22 JUST FOR WES~ NO FASTFALLING
        
        onenter = function(inst, target)
			if not inst.components.launchgravity:GetIsAirborn() then
				inst.sg:GoToState("idle")
			else
				inst.AnimState:PlayAnimation("helpless")
				inst.AnimState:SetMultColour(0.5,0.5,0.5,1)
				inst.components.launchgravity:SetLandingLag(10)
			end
        end,
		onexit = function(inst, target)
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline =
        {
			
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.AnimState:PlayAnimation("helpless") end),
        },
    },
	
	State{
        name = "rebound",  
        tags = {"busy"},
        
        onenter = function(inst, rebound)

				inst.AnimState:PlayAnimation("rebound")
				
			local damage_modifier = (6.6+rebound*0.558) / 2
			
			inst.task_rebound = inst:DoTaskInTime((damage_modifier*FRAMES), function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end)
        end,
		onexit = function(inst, target)
			inst.task_rebound:Cancel()
        end,
        
        timeline =
        {	
			TimeEvent(1*FRAMES, function(inst) 
				-- inst.AnimState:PlayAnimation("rebound")
			end),
			TimeEvent(60*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy") --JUST AN EMERGENCY BACKUP
			end),
        },
    },
	
	
	State{
        name = "fair",
        tags = {"attack", "notalking", "busy", "ll_medium"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("fair_kick")
			-- inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			-- inst.components.hurtboxes:ShiftHurtboxes(0, 0.6)
		end,
		
		onexit = function(inst)
			inst.components.stats:ResetFallingSpeed()
		end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.launchgravity:SetLandingLag(7, "ll_fair", "fair_pst")
				inst.components.hurtboxes:ShiftHurtboxes(0, 0.5)
				-- inst.components.locomotor:SlowFall(-0.2, 6) --WAIT DID THIS JUST INCREASE THE FALLINGSPEED
				
				--1-8-22 APPARENTLY I HAD THE SAME IDEA A WHILE AGO BUT MESSED UP THE EXECUTION. LETS TRY THAT AGAIN
				inst.components.stats.fallingspeed = 0.25
				local xvel, yvel = inst.Physics:GetVelocity()
				-- print("yvel", yvel)
				if yvel <= -0.25 then
					inst.components.stats.fallingspeed = -yvel/10
				end
			end),
			
			TimeEvent(5*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				inst.components.hitbox:SetDamage(1.5)
				inst.components.hitbox:SetAngle(366) 
				inst.components.hitbox:SetBaseKnockback(20) 
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetSize(0.7) --0.8
				inst.components.hitbox:SetLingerFrames(2) --2
				inst.components.hitbox:AddSuction(0.4, 1.0, 0.3)
				
				inst.components.hitbox:SpawnHitbox(0.8, 0.8, 0)
			end),
			
			TimeEvent(8*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				inst.components.hitbox:AddNewHit() --HIT AGAIN
				inst.components.hitbox:SetLingerFrames(2) 
				inst.components.hitbox:AddSuction(0.4, 1.0, 0.3)
				
				inst.components.hitbox:SpawnHitbox(0.8, 0.8, 0)
			end),
			
			TimeEvent(11*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				inst.components.hitbox:AddNewHit() 
				inst.components.hitbox:SetLingerFrames(2) 
				inst.components.hitbox:AddSuction(0.4, 1.0, 0.3)
				inst.components.hitbox:SpawnHitbox(0.8, 0.8, 0)
			end),
			
			TimeEvent(14*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				inst.components.hitbox:AddNewHit() --HIT AGAIN
				inst.components.hitbox:SetLingerFrames(2) 
				inst.components.hitbox:AddSuction(0.4, 0.8, 0.3)
				inst.components.hitbox:SpawnHitbox(0.8, 0.8, 0)
			end),
			
			TimeEvent(18*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				-- inst.components.hitbox:MakeFX("woosh1", 0.2, 0.7, -0.2,   1.7, 2,   0.9, 7, 0)
				inst.components.hitbox:AddNewHit() --HIT AGAIN
				inst.components.hitbox:SetDamage(5) --4
				inst.components.hitbox:SetAngle(361) 
				inst.components.hitbox:SetBaseKnockback(55) 
				inst.components.hitbox:SetGrowth(145) --145
				inst.components.hitbox:SetSize(0.9)
				inst.components.hitbox:SetLingerFrames(2)
				inst.AnimState:SetTime(18*FRAMES)
				
				inst.components.hitbox:AddSuction(0.5, 1.0, 0.3)
				inst.components.hitbox:SpawnHitbox(0.8, 0.8, 0)
				
				inst.components.launchgravity:SetLandingLag(7)
			end),
			
			TimeEvent(20*FRAMES, function(inst)
				inst.components.stats:ResetFallingSpeed()
			end),
			
            TimeEvent(25*FRAMES, function(inst)   --16
				inst.sg:GoToState("air_idle")
			end),
        },
		
		--LET THE CANCEL THE SLOWFALL IF THEY WANT
		events=
        {
            EventHandler("down", function(inst)
				inst.components.stats:ResetFallingSpeed()
            end),
        },
    },
	
	
	--MOST CHARACTERS WON'T HAVE THIS, BUT THIS IS A CUSTOM LANDING-LAG STATE FOR WES THAT HAS A HITBOX ON IT AS AN ATTACK FINISHER
	State{
        name = "fair_pst",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			-- inst.components.hitbox:MakeFX("woosh1upd", -0.1, 0.2, -0.2,   1.3, 1.5,   1, 6, 0.5)
			inst:PushEvent("swaphurtboxes", {preset = "landing"})
            inst.AnimState:PlayAnimation("ll_fair")
        end,
		
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 
				inst.components.jumper:ScootForward(8)
				inst.components.hitbox:SetDamage(3)
				inst.components.hitbox:SetAngle(45) 
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(160)
				inst.components.hitbox:SetSize(0.5, 0.8)
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:SpawnHitbox(0.7, 0.8, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			
			TimeEvent(10*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	
	
	
	State{
        name = "bair",
        tags = {"attack", "busy", "ll_medium", "force_direction"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("bair_wes")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			inst.components.launchgravity:SetLandingLag(5)
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				-- inst.components.hitbox:MakeFX("woosh1", -0.2, 0.6, -0.2,   -1.6, 3,   0.7, 4, 0.4,   0, 0, 0, 1)
				--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
			
				inst:PushEvent("swaphurtboxes", {preset = "grounded"})
				
				inst.components.hitbox:SetDamage(10) 
				inst.components.hitbox:SetAngle(-361) 
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(130)
				inst.components.hitbox:SetSize(0.8, 0.4)
				inst.components.hitbox:SetLingerFrames(1)
				
				-- inst.components.hitbox:SetOnPostHit(function() 
					-- inst.components.locomotor:FaceWithMe(inst.components.stats.opponent)
				-- end)
				
				inst.components.hitbox:SpawnHitbox(-0.7, 0.3, 0) 
				-- inst.components.hitbox:SpawnHitbox(-0.4, 0.25, 0) 
				-- inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
			
				-- inst:PushEvent("swaphurtboxes", {preset = "grounded"})
				
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetLingerFrames(9)
				inst.components.hitbox:SetSize(0.7, 0.3)
				
				inst.components.hitbox:SpawnHitbox(-0.7, 0.3, 0) 
				-- inst.components.hitbox:SpawnHitbox(-1.2, 0.25, 0) 
				-- inst.components.hitbox:SpawnHitbox(-0.4, 0.25, 0) 
				-- inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			
			TimeEvent(8*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			end),
			
            TimeEvent(18*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("attack") 
				-- inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("air_idle")
			
			end),
        },
    },
	
	
	State{
        name = "dair",
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("corkscrew_start")
        end,
		
        
        timeline=
        {
			
			TimeEvent(4*FRAMES, function(inst)
				
				inst.components.launchgravity:SetLandingLag(7)
				
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(290)
				inst.components.hitbox:SetBaseKnockback(10)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.8)
				inst.components.hitbox:SetLingerFrames(5)
				inst.components.hitbox:AddEmphasis(-3) --MAKE IT FEEL A BIT MORE LIKE MELEE?
				-- inst.components.hitbox:AddSuction(0.15, 0, -0.4)
				
				inst.components.hitbox:SpawnHitbox(0.4, -0.1, 0)
				inst.components.hitbox:SpawnHitbox(-0.1, 0.6, 0) 
				-- inst.components.hitbox:SpawnHitbox(0, 0.3, 0) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				inst.SoundEmitter:PlaySound("dontstarve/common/twirl")
				
				-- inst.components.hitbox:MakeFX("punchwoosh", 0, -0.4, 0.2,   0.5, 0.5,   0.7, 3, 0.0,  0,0,0,  1)
				-- inst.components.hitbox:MakeFX("woosh1down", -0.1, 0.35, 0.1,   1.0, 0.7,   0.9, 5, 0,   0,0,0, 1)
			end),
			
			
			
			TimeEvent(10*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(361) 
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(100)
				-- inst.components.hitbox:SetSize(1, 0.6)
				inst.components.hitbox:SetLingerFrames(4)
				
				inst.components.hitbox:SpawnHitbox(0.4, -0.1, 0)
				inst.components.hitbox:SpawnHitbox(-0.2, 0.7, 0) 
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				inst.sg:AddStateTag("stopspinning")
				inst.AnimState:PlayAnimation("corkscrew_pst") 
			end),
			
            TimeEvent(22*FRAMES, function(inst) 
				inst.sg:GoToState("air_idle")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)  --hit_ground
				-- print("STAR IS MY FAVORITE UGXIE HIGHLANDER FRIEND")
				if not inst.sg:HasStateTag("stopspinning") then
					inst.AnimState:PlayAnimation("corkscrew")
				end
            end),
        },
    },
	
	
	
	
	State{
        name = "nair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("nair_kick") --"nair"
			--inst.AnimState:PlayAnimation("uspecial")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			-- inst.components.jumper:AirStall(2, 2)
			-- inst.components.jumper:AirDrag(0.1, 0.1, 0.1, 2000) --it works c:
            
        end,
        
        timeline=
        {
			
			TimeEvent(2*FRAMES, function(inst)  --DELAYING A FRAME BC THIS MOVE IS PRETTY OP
				inst.components.launchgravity:SetLandingLag(3)
				
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(15) 
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SetSize(0.9, 0.4)
				inst.components.hitbox:SpawnHitbox(0.3, 0.3, 0)
				
			end),
			
			
			TimeEvent(3*FRAMES, function(inst)  --THE LATE HIT SOURSPOT
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetBaseKnockback(5) 
				inst.components.hitbox:SetSize(0.75, 0.35)
				inst.components.hitbox:SetLingerFrames(8)
				
				inst.components.hitbox:SpawnHitbox(0.3, 0.25, 0)
			end),
			
            TimeEvent(16*FRAMES, function(inst) 
				inst.sg:GoToState("air_idle")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                -- inst.sg:GoToState("air_idle")
				inst.AnimState:PlayAnimation("idle_air")
            end),
        },
    },
	
	
	State{
        name = "uair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("uair")
            -- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.components.launchgravity:SetLandingLag(4)
		end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(9.5) --7
				inst.components.hitbox:SetAngle(75) 
				inst.components.hitbox:SetBaseKnockback(10)
				inst.components.hitbox:SetGrowth(120) --135
				inst.components.hitbox:SetSize(0.8)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(0.7, 0.7, 0)
				
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(1.1)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0.3, 1.5, 0) 
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(0.8)
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(-0.7, 0.7, 0) 
				--  
			end),
			
            TimeEvent(16*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("air_idle") --WAIT, WHAT IS THIS DOING HERE?...
            end),
        },
    },
	
	State{
        name = "jab1",
        tags = {"attack", "short", "busy", "noclanking"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jab1")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			
			inst:PushEvent("swaphurtboxes", {preset = "leanf"})
            
			inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
		end,
        
        timeline=
        {
			
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(15) --15
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetDamage(3) --3
				-- inst.components.hitbox:SetSize(1.6, 0.4) --1-14, THE FIRST SQUARE HITBOX TEST
				inst.components.hitbox:SetSize(0.6, 0.4)
				inst.components.hitbox:SetLingerFrames(0) --3
				inst.components.hitbox:AddSuction(0.5, 1.1, 0) --TURN THESE BACK ON LATER
				
				inst.components.hitbox:SpawnHitbox(1.1, 1.2, 0) 
				
			end),
			
			TimeEvent(4*FRAMES, function(inst)
				inst.sg:AddStateTag("jab1") 
			end),
			
            TimeEvent(12*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
			
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
			EventHandler("attack_key", function(inst)
				if inst.sg:HasStateTag("jab1") then
					inst.sg:GoToState("jab2")
				end
            end),
        },
    },
	
	State{
        name = "jab2",
        tags = {"attack", "busy", "short", "noclanking"}, --"noclanking"
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jab_2")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)	
				inst.components.hurtboxes:ShiftHurtboxes(0.5, 0)
				
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(5)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetDamage(2)
				inst.components.hitbox:AddSuction(0.5, 0.3, -1.0)
				
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(2)--3
				
				-- inst.components.hitbox.property = 4
				
				inst.components.hitbox:SpawnHitbox(1.3, 0.5, 0) 
				
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.sg:AddStateTag("jab2")
			end),
			
            TimeEvent(30*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
			
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
			EventHandler("attack_key", function(inst)
				if inst.sg:HasStateTag("jab2") then
					inst.sg:GoToState("jabinf")
				end
            end),
        },
    },
	
	
	State{
        name = "jabinf",
        tags = {"attack", "busy", "spammy", "noclanking"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jab_inf_play")
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			inst.components.hitbox:MakeFX("woosh1", 0.2, 0.7, 0.2,   1.3, 1.3,   0.9, 7, 0)
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)	
				inst.components.hitbox:MakeFX("woosh1", 0.2, 1.1, 0.2,   1.3, 1.3,   0.9, 7, 0)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				inst.components.hitbox:SetAngle(65)
				inst.components.hitbox:SetBaseKnockback(5)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetDamage(0.7)
				
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(2)--3
				
				-- inst.components.hitbox.property = 4
				
				inst.components.hitbox:AddSuction(1.5, nil, -0.8) --power, x, y
				inst.components.hitbox:SpawnHitbox(1.5, 1.2, 0) 
				
			end),
			
			TimeEvent(5*FRAMES, function(inst)	
				inst.components.hitbox:AddNewHit() --HIT AGAIN
				inst.components.hitbox:MakeFX("woosh1", 0.2, 1.4, 0.2,   1.3, 1.3,   0.9, 7, 0)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				inst.components.hitbox:AddSuction(1.5, nil, -0.8)  --LEAVING X AS NIL MEANS THEIR X POSITION WONT BE SUCKED AT ALL. PREVENTING AN INFINATE JAB
				inst.components.hitbox:SpawnHitbox(1.5, 1.2, 0) 
			end),
			
						
			--4-18-20 MID-WAY LISTENER, LET THEM CANCEL INTO JAB_FINAL EARLY IF THEY ARENT HOLDING THE KEY
			TimeEvent(6*FRAMES, function(inst) 
				if inst.sg:HasStateTag("listen") then
					-- DO NOTHING! THIS TIME...
				else
					inst.sg:GoToState("jab3")
				end
				
				
			end),
			
			TimeEvent(8*FRAMES, function(inst)	
				inst.components.hitbox:AddNewHit() --HIT AGAIN
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				-- inst.components.hitbox:MakeFX("woosh1", 0.2, 0.8, 0.2,   1.0, 1,   0.9, 7, 0)
				inst.components.hitbox:AddSuction(1.5, nil, -0.8)
				inst.components.hitbox:SpawnHitbox(1.5, 1.2, 0) 
			end),
			
			-- TimeEvent(11*FRAMES, function(inst)	
				-- inst.components.hitbox:AddNewHit() --HIT AGAIN
				
				-- inst.components.hitbox:AddSuction(0.3, 0.5, -1.3)
				-- inst.components.hitbox:SpawnHitbox(1.5, 1.2, 0) 
			-- end),
			
			-- TimeEvent(15*FRAMES, function(inst) 
				-- inst.sg:AddStateTag("listen")
			-- end),
			
            TimeEvent(9*FRAMES, function(inst) 
				if inst.sg:HasStateTag("listen") then
					inst.sg:GoToState("jabinf")
				else
					inst.sg:GoToState("jab3")
				end
				
				
			end),
        },
        
        events=
        {
			EventHandler("attack_key", function(inst)
				inst.sg:AddStateTag("listen")
            end),
        },
    },
	
	
	
	State{
        name = "jab3",
        tags = {"attack", "jab3", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("ftilt_chop")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
            inst:PushEvent("swaphurtboxes", {preset = "leanf"})
			inst.components.jumper:ScootForward(8)
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(0.5, 0)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(60)
				inst.components.hitbox:SetDamage(4)   
				inst.components.hitbox:SetSize(0.9)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(1.5, 1.0, 0)  
			end),
			
			TimeEvent(14*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(-0.5, 0)
			end),
			
            TimeEvent(18*FRAMES, function(inst) 
				inst.sg:GoToState("idle")			
			end),
        },
        
    },
	
	
	
	State{
        name = "dash_attack",
        tags = {"busy", "attack", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dash_nair")
			inst.Physics:SetFriction(.1) --YEP
			inst.components.hitbox:MakeFX("slide1", 0.6, 0, 0.2, 1, 1, 1, 6, 0)
			
			-- --7-14-19 -SOMETIMES, A BUG OCCURS WHERE ENTERING THE STATE WHILE NO KEYS ARE HELD DOWN WILL CAUSE YOUR SPEED TO DROP TO ZERO. DONT DO THAT
			--OH! ITS BECAUSE THE DASH WOULD SOMETIMES POWER THROUGH THE SCOOT-FORWARD-8 ON FRAME0 ENTER. SO UH. DONT DO THAT I GUESS
			-- inst.components.jumper:ScootForward(-8)
			
			-- inst.components.hitbox:MakeFX("punchwoosh", 1.4, 1, 0.1,  2.3, 1.5,   1, 10, 1)
			-- inst.components.hitbox:MakeFX("woosh1", 0.2, 0.5, 0.1,   1.2, 1.3,   0.8, 4, 0)
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/explo")
			-- inst:PushEvent("swaphurtboxes", {preset = "sliding"})
        end,
		
		
		
		onexit = function(inst)
			--inst.AnimState:PlayAnimation("dash_attack")
			--inst.Physics:SetFriction(.9)
			inst.components.stats:ResetFriction()
        end,
        
        timeline=
        {
		
			TimeEvent(1*FRAMES, function(inst)
				--7-14-19 -SOMETIMES, A BUG OCCURS WHERE ENTERING THE STATE WHILE NO KEYS ARE HELD DOWN WILL CAUSE YOUR SPEED TO DROP TO ZERO. DONT DO THAT
				-- local xvel, yvel = inst.Physics:GetVelocity()
				-- if math.abs(xvel) <= 2 then 
					-- inst.components.jumper:ScootForward(10) 
				-- end
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
				inst.components.jumper:ScootForward(0)
				inst.components.jumper:ScootForward(9)
			end),
			
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("woosh1", -0.2, 0.9, -0.1,   1.4, 1.0,   0.9, 6, 0.2, 0,0,0, 1)
				
				inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetAngle(50) --45 --75 --THIS IS A LITTLE OP COMBO STARTER
				inst.components.hitbox:SetBaseKnockback(90)
				inst.components.hitbox:SetGrowth(43)

				inst.components.hitbox:SetLingerFrames(5)
				
				inst.components.hitbox:SetSize(0.6, 0.2)
				inst.components.hitbox:SpawnHitbox(0.8, 0.9, 0)
				
				-- inst.components.hitbox:MakeFX("slide1", 1, 0, 0.2, 1, 1, 1, 4, 0)
			end),

            TimeEvent(10*FRAMES, function(inst)  --12				
				-- inst.sg:GoToState("dash_stop")
				inst.components.stats:ResetFriction()
				inst.components.hitbox:MakeFX("slide1", 0.7, 0, 0.1, 1, 0.5, 0.8, 10, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst.AnimState:PlayAnimation("dash_nair_pst")
			end),
			
			TimeEvent(14*FRAMES, function(inst)				
				inst.sg:AddStateTag("can_jump")
			end),
			
			TimeEvent(18*FRAMES, function(inst)				
				inst.sg:RemoveStateTag("busy")
			end),
        },
    },
	
	
	
	
	State{
        name = "ftilt",
        tags = {"busy", "attack", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("ftilt")
        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				inst:PushEvent("swaphurtboxes", {preset = "leanf"})
				inst.components.hurtboxes:ShiftHurtboxes(0.5, 0)
				
				inst.components.hitbox:MakeFX("woosh1", 0.2, 1.0, -0.2,   1.8, 2,   0.8, 4, 0)
										--name    ---x, y, z-5   -width/height -glow, duration, ?stick
			
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(100) 
				inst.components.hitbox:SetSize(0.4, 0.2) --x, y
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(0.7, 0.8, 0)
			end),
			
			
			TimeEvent(4*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(9)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(100) 
				inst.components.hitbox:SetSize(0.8, 0.3) --x, y
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(1.2, 0.9, 0)  --x, y, z
				
				-- inst.components.hurtboxes:ShiftHurtboxes(0.5, 0)
			end),
			
			TimeEvent(11*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(-0.5, 0)
			end),
			
            TimeEvent(16*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
				inst.sg:RemoveStateTag("attack")
				-- inst.sg:GoToState("idle")	
			end),
        },
    },
	
	
	State{
        name = "dtilt",
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dtilt_snake")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
        end,
		
		onexit = function(inst)
			inst.components.hurtboxes:SpawnPlayerbox(0, 0.7, 0.35, 0.7, 0)
        end,
        
        timeline=
        {
			
			TimeEvent(1*FRAMES, function(inst) 
				inst.components.jumper:ScootForward(15)
				inst:PushEvent("swaphurtboxes", {preset = "grounded"})
				inst.components.hurtboxes:SpawnPlayerbox(0, 0.1, 0.7, 0.35, 0)
			end),
			
			TimeEvent(2*FRAMES, function(inst) 
				
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(70)
				inst.components.hitbox:SetBaseKnockback(80)
				inst.components.hitbox:SetGrowth(60)
				inst.components.hitbox:SetSize(0.6, 0.3)
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(0.2, 0, 0)
				--inst.sg:RemoveStateTag("abouttoattack")
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.jumper:ScootForward(8)
			end),
			
			TimeEvent(4*FRAMES, function(inst) --7
				-- inst.components.jumper:ScootForward(8)
				
				inst.components.hitbox:SetSize(1.3, 0.4)
				inst.components.hitbox:SetAngle(60)
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(0.5, 0.1, 0)
			end),
			
			TimeEvent(19*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			
            TimeEvent(22*FRAMES, function(inst) --7
				-- inst.sg:RemoveStateTag("attack") 
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")				
			end),
        },
        
        events=
        {
            -- EventHandler("animover", function(inst)
                -- inst.sg:GoToState("idle")
            -- end),
        },
    },
	
	
	State{
        name = "utilt",
        tags = {"attack", "notalking", "abouttoattack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("utilt_wes")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
            
        end,
        
        timeline=
        {
            TimeEvent(3*FRAMES, function(inst) 
				-- inst.components.hitbox:MakeFX("half_circle_up_woosh_med", -0.2, 1.0, -0.2,   2.7, 2.5,   0.6, 8, 0.0,  1, 1, 1,   1) 
			end),
			TimeEvent(4*FRAMES, function(inst)
			
				inst.components.hitbox:SetDamage(5) --7
				inst.components.hitbox:SetAngle(86)
				inst.components.hitbox:SetBaseKnockback(90) --60 
				inst.components.hitbox:SetGrowth(15) --70 1-2-18
				-- inst.components.hitbox:SetSize(0.8) --1
				-- inst.components.hitbox:SpawnHitbox(-0.8, 1.2, 0)
				-- inst.components.hitbox:SpawnHitbox(0.6, 1.2, 0)
				
				inst.components.hitbox:SetSize(1.5, 0.7) --0.8
				inst.components.hitbox:SpawnHitbox(0, 0.8, 0)

			end),
			
			TimeEvent(5*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetGrowth(60)
				inst.components.hitbox:SetSize(0.8) --0.8
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:SpawnHitbox(0, 2.5, 0)
			end),
			
            TimeEvent(13*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	
	
	
	State{
        name = "uspecial",
        tags = {"attack", "busy", "no_air_transition", "nolandingstop", "no_fastfalling"},
        
        onenter = function(inst) --THIS HAPPENS ON FRAME 1
			inst.AnimState:PlayAnimation("umbrellafly") --ANIMATION NAME
			if inst.components.launchgravity:GetIsAirborn() then
				
				--10-18-17 GONNA ADD A SNEAKY LITTLE CHECK FOR GROUND TO MAKE IT EASIER TO GET THE GROUNDED VERSION WITH TAPJUMP
				-- local yhight = inst.components.launchgravity:GetHeight()
				-- if yhight <= 0.50 then --HEY, THIS IS ACTUALLY PRETTY GOOD... MIGHT DO THIS WITH ALL OF THEM!
					-- inst.components.launchgravity:Launch(0, 0)
				-- end
				
				local xvel, yvel = inst.Physics:GetVelocity()
				if yvel <= 1 then --ONLY AIR STALL IF THEY ABOUT TO START FALLING
					inst.components.jumper:AirStall() --DON'T ROB THEM OF THEIR DOUBLE JUMP IF THEY ARE TRAVELING UPWARD
				else
					inst.components.jumper:AirStall(2, 1.5)
				end
				inst.components.locomotor:SlowFall(-0.2, 5)
			end
		end,
		
		onexit = function(inst) 
			inst.components.stats.fallingspeed = 3.1
			--DONT FORGET TO PUT THEM BACK TO DEFAULT
			inst.components.hurtboxes:ReplaceLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0) --(xpos, ypos, sizex, sizey, shape)
        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst) --FRAME 3
				if inst.components.keydetector:GetBackward(inst) then --LET THEM B-REVERSE IT
					inst.components.locomotor:TurnAround()
				end
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/swipe")
			end),
			
			--
			TimeEvent(5*FRAMES, function(inst)
				--SHRINK THE LEDGEGRAB BOXES JUST A BIT
				inst.components.hurtboxes:ReplaceLedgeGrabBox(0, 1.7, 1.1, 0.5, 0) --(xpos, ypos, sizex, sizey, shape)
				
				inst.components.hitbox:SetDamage(3)
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetSize(0.9, 0.6) --1.1 1.2 --RADIUS OF HITBOX
				inst.components.hitbox:SetLingerFrames(2) --HOW MANY FRAMES HITBOX IS ACTIVE FOR
				inst.components.hitbox:AddSuction(0.5, 0.5, 1.5) --(power, x, y)
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(0.5, 1.5, 0) --(X,Y,Z) POSITION OF HITBOX (AND SPAWNS IT)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetSize(0.5)
				inst.components.hitbox:SpawnHitbox(0.2, 0.8, 0)				
				
				-- inst.components.launchgravity:Launch(4, 30) --X,Y POWER
				inst.components.locomotor:Motor(3, 16, 9) --(xvel, yvel, duration)
			end),
			
			
			-- TimeEvent(6*FRAMES, function(inst)
				-- --SHRINK THE LEDGEGRAB BOXES JUST A BIT
				-- inst.components.hurtboxes:ReplaceLedgeGrabBox(0, 1.7, 1.1, 0.5, 0) --(xpos, ypos, sizex, sizey, shape)
				
				-- -- inst.components.launchgravity:Launch(4, 30) --X,Y POWER
				-- inst.components.locomotor:Motor(3, 16, 9) --(xvel, yvel, duration)
			-- end),
			
			TimeEvent(8*FRAMES, function(inst) --FRAME 3
				inst.components.hitbox:AddNewHit() --HIT AGAIN
				inst.components.hitbox:SetDamage(1)
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetSize(0.9, 0.6)
				inst.components.hitbox:SetLingerFrames(1) --HOW MANY FRAMES HITBOX IS ACTIVE FOR
				inst.components.hitbox:AddSuction(0.3, 0.2, 2.5) 
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(0.2, 2.5, 0)
			end),
			
			-- TimeEvent(9*FRAMES, function(inst) --FRAME 3
				-- inst.components.hitbox:AddNewHit() --HIT AGAIN
				-- inst.components.hitbox:MakeDisjointed()
				-- inst.components.hitbox:SpawnHitbox(0.2, 2.5, 0)
			-- end),
			
			TimeEvent(11*FRAMES, function(inst) --FRAME 3
				inst.components.hitbox:AddNewHit() --HIT AGAIN
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.2, 2.5, 0)
			end),
			
			
			TimeEvent(14*FRAMES, function(inst) --FRAME 3
				inst.AnimState:PlayAnimation("umbrellafall_pop")
				inst.components.hitbox:MakeFX("punchwoosh", 0.1, 3.0, -0.5,   1.2, 0.8,   0.5, 5, 0.1,  0, 0, 0,   1) 
											--("flap_loop", 0, 2, -0.2,      0.5, 0.5,     1, 14, 0,    0, 0, 0,   1, "crow_build", "crow")
				
				inst.components.hitbox:AddNewHit() --HIT AGAIN
				inst.components.hitbox:SetDamage(4)
				inst.components.hitbox:SetAngle(81)
				inst.components.hitbox:SetSize(0.9, 0.9)
				-- inst.components.hitbox:SetBaseKnockback(90)
				-- inst.components.hitbox:SetGrowth(15)
				
				--1-9-22 OK A LITTLE TOO STRONG, GIVEN HOW HIGH HE CAN Get
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(180)
				inst.components.hitbox:SetAngle(60)
				
				inst.components.hitbox:AddEmphasis(5)
				inst.components.hitbox:AddSuction(0.3, 0.2, 2.5)
				inst.components.hitbox:MakeDisjointed()
				inst.components.locomotor:Motor(0, 14, 1)
				
				inst.sg:AddStateTag("can_grab_ledge")

				inst.components.hitbox:SpawnHitbox(0.2, 2.5, 0)
			end),
			
			TimeEvent(16*FRAMES, function(inst)
				-- inst.AnimState:PlayAnimation("umbrellafall")
				inst.components.stats.fallingspeed = 0.2
				inst.sg:RemoveStateTag("nolandingstop")
				inst.components.launchgravity:SetLandingLag(10)
				inst.sg:AddStateTag("reducedairacceleration")
			end),
			
			TimeEvent(20*FRAMES, function(inst)
				--11-16-17 AT THE PEAK OF HIS JUMP, BUMP UP HIS LEDGEGRAB BOXES JUST A BIT.
				inst.components.hurtboxes:ReplaceLedgeGrabBox(0.2, 2.5, 1.1, 0.5, 0) --(xpos, ypos, sizex, sizey, shape)
			end),
			
			
			TimeEvent(35*FRAMES, function(inst)  --AFTER THIS POINT, THEY CAN CANCEL THE UMBRELLA
				inst.sg:AddStateTag("can_umbrella_drop") 
			end),
        },
		
		
		events=
        {
            EventHandler("down", function(inst)
                if inst.sg:HasStateTag("can_umbrella_drop") then --BUT ONLY LET THEM DROP AFTER WE'VE SAID THEY CAN
					inst.components.launchgravity:Launch(0, 1) --GIVE EM A LITTLE BOOT SO THEY CANT GO STRAIGHT INTO FASTFALL
					inst.sg:GoToState("freefall")
				end
            end),
			
			EventHandler("animover", function(inst)
                inst.AnimState:PlayAnimation("umbrellafall_rep")
            end),
        },
		
		
    },
	
	
	
	
	
	State{
        name = "nspecial",
        tags = {"attack", "notalking", "abouttoattack", "busy", "nolandingstop", "reducedairacceleration"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("nspecial")
			-- inst.components.jumper:AirStall(2, 2)
			inst.components.jumper:AirDrag(0.3, 0.3, 0.2, 20) --mspeed, mfall, maccel, duration
			
			-- inst.SoundEmitter:PlaySound("dontstarve/common/balloon_make", "make") --OH GOD IT LOOPS
            inst.SoundEmitter:PlaySound("dontstarve/common/balloon_blowup")
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				if inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
			end),

			TimeEvent(17*FRAMES, function(inst)
				
				--SPAWN A BALLOON BEHIND THEM
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(62)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(400)
				
				inst.components.hitbox:SetProjectileAnimation("balloon", "balloon", "hit") --NO CUSTOM ANIMATIONS FOR THESE! I TOOK ALL THE EXISTING ANIMATIONS RIGHT FROM THE GAME
				inst.components.hitbox:SetProjectileSpeed(0, 1.8)
				inst.components.hitbox:SetProjectileDuration(330)
				inst.components.hitbox:SetHitFX("none", "dontstarve/common/balloon_pop")
				
				local balloon = SpawnPrefab("basicprojectile")
				
				balloon:RemoveTag("deleteonhit")
				balloon:RemoveTag("force_direction") --SO THE BALLON DOESNT ALWAYS HIT ENEMIES FORWARDS
				-- balloon:RemoveEventCallback("clank", function() end) --IDK IF THIS IS THE RIGHT WAY TO REMOVE A LISTENER
				balloon.Transform:SetScale(0.8, 0.8, 0.8)
				balloon.components.projectilestats.yhitboxoffset = 1.3
				
				inst.components.hitbox:SetOnHit(function() 
					balloon.AnimState:PlayAnimation("pop", true)
					balloon.AnimState:SetTime(4*FRAMES)
					balloon.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
					-- balloon.sg:GoToState("explode")
					balloon.Transform:SetScale(1, 1, 1)

					inst:DoTaskInTime(8*FRAMES, function(inst) --6-30-17 DONT WE NEED THIS CUZ EXPLODE DOESNT REMOVE IT AUTOMATICALLY?
						balloon:Remove()
					end)
				end)
				
				
				balloon:ListenForEvent("clank", function() --overpowered
					balloon.AnimState:PlayAnimation("pop")
					-- balloon.AnimState:SetTime(4*FRAMES)
					balloon.AnimState:Resume()
					balloon.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
					-- balloon.sg:GoToState("explode")
					balloon.Transform:SetScale(1, 1, 1)
					-- print("POP")

					inst:DoTaskInTime(6*FRAMES, function(inst) --6-30-17 DONT WE NEED THIS CUZ EXPLODE DOESNT REMOVE IT AUTOMATICALLY?
						balloon:Remove()
					end)
				
				end)
				
				
								
				-- balloon.components.projectilestats.yhitboxoffset = 1.3 --SINCE THE BALLOON IS ACTUALLY WAY UP HIGH
				--DOES IT NEED ITS COLORS SET OR SOMETHING?
				-- balloon.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", "balloon_"..tostring(inst.balloon_num)) --THERE ARE 4 DIFF KINDS (OR 5?)
				balloon.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", "balloon_1")
				-- balloon.colour_idx = math.random(#colours)
				-- balloon.AnimState:SetMultColour(1,0,0,1)
				
				--4-25-20 DETERMINE BALLOON COLOR BASED ON SKIN
				local r = 0
				local g = 0
				local b = 0
				
				if inst.components.stats.buildname == "newwesblue" then
					b = 1
				elseif inst.components.stats.buildname == "newwesgreyscale" then
					r = 0.3
					g = 0.3
					b = 0.3
				elseif inst.components.stats.buildname == "newwesyellow" then
					r = 1
					g = 1
				else
					r = 1
				end
				balloon.AnimState:SetMultColour(r,g,b,1)
				
				
				balloon:DoTaskInTime(0.5, function(balloonref) 
					balloon.AnimState:PlayAnimation("idle", true)
				end)
				
				
				inst.components.hitbox:SpawnProjectile(1.1, 0, 0, balloon)
				balloon.components.stats:TintTeamColor(0.5)
			end),
			
			
            TimeEvent(25*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	
	
	
	
	
	--PART 1 - DETERMINE IF WE SHOULD JUMP FIRST BEFORE SWINGING
	State{
        name = "fspecial",
		tags = {"busy", "no_air_transition", "no_fastfalling"},
        
        onenter = function(inst)
            inst.components.launchgravity:SetLandingLag(10)
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			inst.SoundEmitter:PlaySound("dontstarve/common/balloon_blowup")
			
			--10-24-18 -SURPRISE! IF YOU'VE ALREADY SWING IN THIS DIRECTION, GET POPPED
			--ANOTHERNOTHER SPECIAL CASE FOR WES- HIS FSPECIAL DOESN'T PUT HIM INTO FREEFALL, BUT LIKE BAYONETTA'S, HE ONLY GETS ONE SWING IN EACH DIRECTION UNTIL LANDING.
			if inst.components.stats.storagevar2 == "used_both_swings" then
				inst.components.hitbox:Blink(inst, 5,   0.8, 0.3, 0.3, 0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
				inst.sg:AddStateTag("get_popped")
			elseif inst.components.launchgravity:GetRotationFunction(inst) == "left" then
				if inst.components.stats.storagevar2 == "used_left_swing" then
					--WARN THEM THAT THEY GOT NO RECOVERY --THIS NEEDS TO GO IN ALL SPOTS
					inst.components.hitbox:Blink(inst, 5,   0.8, 0.3, 0.3, 0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
					inst.sg:AddStateTag("get_popped")
				elseif inst.components.stats.storagevar2 == "used_right_swing" then
					inst.components.stats.storagevar2 = "used_both_swings"
				else
					inst.components.stats.storagevar2 = "used_left_swing" --ITS BEEN USED!
				end
			
			elseif inst.components.launchgravity:GetRotationFunction(inst) == "right" then
				if inst.components.stats.storagevar2 == "used_right_swing" then
					inst.components.hitbox:Blink(inst, 5,   0.8, 0.3, 0.3, 0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
					inst.sg:AddStateTag("get_popped")
				elseif inst.components.stats.storagevar2 == "used_left_swing" then
					inst.components.stats.storagevar2 = "used_both_swings"
				else
					inst.components.stats.storagevar2 = "used_right_swing" --ITS BEEN USED!
				end
			end
			
			--11-8-17 -IF WE'RE TRAVELING DOWN FAST ENOUGH, JUST START SWINGING RIGHT AWAY
			local xvel, yvel = inst.Physics:GetVelocity()
			if yvel <= -1 and not inst.sg:HasStateTag("get_popped") then
				inst.AnimState:PlayAnimation("ropeswing_short") --PLAY THE FAST ANIMATION
				inst.sg:GoToState("fspecial_swing")
			else
				inst.AnimState:PlayAnimation("ropeswing") --PLAY THE SLOW ANIMATION
				inst.components.launchgravity:Launch(7, 20)
			end
            
        end,
        
		timeline =
        {
			TimeEvent(6*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("can_grab_ledge")
				inst.sg:AddStateTag("nolandingstop")
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/swhoosh")
				
			end),
			
			TimeEvent(9*FRAMES, function(inst)  --OKAY, NOW THAT WE'VE DONE THE JUMP, GO TO THE SWING STATE
				if not inst.sg:HasStateTag("get_popped") then --BUT ONLY IF HE HASNT USED HIS SWING YET!
					inst.sg:GoToState("fspecial_swing")
				else
					inst.AnimState:PlayAnimation("ropeswing_helpless")
					inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
					inst.components.hitbox:MakeFX("pop", 1.2, 1.1, 0,   1, 1,   1, 14, 0,  0, 0, 0,   0, "balloon", "balloon")
					
					inst.components.stats.lastfx.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", "balloon_1")
					inst.components.stats.lastfx.AnimState:SetMultColour(1,0,0,1)
					inst.components.stats.lastfx.AnimState:SetTime(2*FRAMES)
				end
			end),
			
			--IF YOUR BALLOON POPPED, RIP YOU LOL
			TimeEvent(13*FRAMES, function(inst)  --OKAY, NOW THAT WE'VE DONE THE JUMP, GO TO THE SWING STATE
				inst.sg:RemoveStateTag("nolandingstop")
				inst.sg:AddStateTag("can_grab_ledge")
			end),
			
			TimeEvent(30*FRAMES, function(inst)
				inst.sg:AddStateTag("can_jump")
			end),
			
			TimeEvent(40*FRAMES, function(inst)  --OKAY, IF YOURE STILL ALIVE YOU CAN MOVE NOW
				inst.sg:RemoveStateTag("busy")
			end),
		},
    },
	
	
	State{
        name = "fspecial_swing",
        tags = {"attack", "busy", "no_air_transition", "no_fastfalling", "noairmoving", "ropeswinging", "force_trade", "force_direction"}, --"nolandingstop", 
        
        onenter = function(inst)
            -- inst.AnimState:PlayAnimation("ropeswing")
			-- inst.components.launchgravity:Launch(7, 20)
			inst.components.stats.gravity = -2.3 -- -2.3 --HAHAA!!
			--GIVE EM A LITTLE BOOST
			inst.components.launchgravity:Launch(17, -14)   --(17, -12)
			inst.components.launchgravity:SetLandingLag(7) --BUT IF THEY HIT THE GROUND TOO EARLY, PUNISH THEM
        end,
		
		onexit = function(inst)
            inst.components.stats.gravity = inst.components.stats.basegravity
        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(4)
				inst.components.hitbox:SetAngle(63) --70
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(50)
				inst.components.hitbox:SetSize(0.5) --1
				inst.components.hitbox:SetLingerFrames(3)
				
				inst.components.hitbox:SetOnHit(function() 
					if not inst.components.stats.opponent.sg:HasStateTag("blocking") then
						-- inst.components.hitbox:Blink(inst, 2,   1, 1, 1,   0.2)
						inst.sg:AddStateTag("sweetspotted")
					end
				end)
				
				inst.components.hitbox:SpawnHitbox(-0.6, 0.3, 0)
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				--ARE YOU ABOUT TO SLAM INTO A WALL?
				-- print("MUST I GO FAST?", inst.components.launchgravity:GetHorSpeed(inst) )
				if math.abs(inst.components.launchgravity:GetHorSpeed(inst)) <= 1 then  --IF THEY AINT MOVIN, ASSUME THEY'VE HIT A WALL!
					inst.components.hitbox:MakeFX("pop",  1.5, 1, 0.6,   0.8, 0.8,     1, 10, 1,    0,0,0,    0, "balloon", "balloon")
					--THE BALLOON WONT BE VISIBLE UNTIL WE CHOOSE IT'S SHAPE I THINK
					inst.components.stats.lastfx.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", "balloon_1")
					inst.components.stats.lastfx.AnimState:SetTime(5*FRAMES)
					inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
					
					inst.sg:GoToState("wall_slam")
				end
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetAngle(63) --70
				inst.components.hitbox:SetBaseKnockback(100)
				inst.components.hitbox:SetGrowth(50)
				inst.components.hitbox:SetSize(0.8) --1
				inst.components.hitbox:SetLingerFrames(4) --7
				
				inst.components.hitbox:SpawnHitbox(0.6, 0, 0)
			end),
			
			TimeEvent(8*FRAMES, function(inst) 
				if math.abs(inst.components.launchgravity:GetHorSpeed(inst)) <= 1 then  --IF THEY AINT MOVIN, ASSUME THEY'VE HIT A WALL!
					inst.components.hitbox:MakeFX("pop",  0, 2, 0.6,   0.8, 0.8,     1, 10, 1,    0,0,0,    0, "balloon", "balloon")
					inst.components.stats.lastfx.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", "balloon_1")
					inst.components.stats.lastfx.AnimState:SetTime(5*FRAMES)
					inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
				
					inst.sg:GoToState("wall_slam")
				end
			end),
			
			
			--5-8-20 TRYING TO MAKE LATE HITS LINK BETTER WITH THIS MOVE
			TimeEvent(10*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetAngle(70) --70
				inst.components.hitbox:SetBaseKnockback(90)
				inst.components.hitbox:SetGrowth(50)
				inst.components.hitbox:SetSize(0.7) --1
				inst.components.hitbox:SetLingerFrames(4)
				
				inst.components.hitbox:SpawnHitbox(0.7, 0, 0)
			end),
			
			
			TimeEvent(11*FRAMES, function(inst) 
				if math.abs(inst.components.launchgravity:GetHorSpeed(inst)) <= 1 then  --IF THEY AINT MOVIN, ASSUME THEY'VE HIT A WALL!
					inst.components.hitbox:MakeFX("pop",  -1.5, 1, 0.6,   0.8, 0.8,     1, 10, 1,    0,0,0,    0, "balloon", "balloon")
					inst.components.stats.lastfx.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", "balloon_1")
					inst.components.stats.lastfx.AnimState:SetTime(5*FRAMES)
					inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
					
					inst.sg:GoToState("wall_slam")
				end
			end),
			
			TimeEvent(14*FRAMES, function(inst)
				inst.components.stats.gravity = inst.components.stats.basegravity
				inst.components.launchgravity:Launch(7, 15)
				if inst.components.keydetector:GetBackward(inst) then
					inst.components.launchgravity:Launch(2, 17)
				end
				
				inst.sg:RemoveStateTag("noairmoving")
				inst.sg:RemoveStateTag("nolandingstop")
			end),
			
			TimeEvent(16*FRAMES, function(inst)
				inst.components.launchgravity:SetLandingLag(1) --OKAY NOW YOU CAN LAND FREELY
				
				--SPAWN A BALLOON BEHIND THEM
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(62)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(400)
				
				inst.components.hitbox:SetProjectileAnimation("balloon", "balloon", "hit") --NO CUSTOM ANIMATIONS FOR THESE! I TOOK ALL THE EXISTING ANIMATIONS RIGHT FROM THE GAME
				inst.components.hitbox:SetProjectileSpeed(0, 1.8)
				inst.components.hitbox:SetProjectileDuration(330)
				inst.components.hitbox:SetHitFX("none", "dontstarve/common/balloon_pop")
				
				local balloonref = SpawnPrefab("basicprojectile")
				
				balloonref:RemoveTag("deleteonhit")
				balloonref:RemoveTag("force_direction") --SO THE BALLON DOESNT ALWAYS HIT ENEMIES FORWARDS
				balloonref.Transform:SetScale(0.8, 0.8, 0.8)
				balloonref.components.projectilestats.yhitboxoffset = 1.3  --SINCE THE BALLOON IS ACTUALLY WAY UP HIGH
				
				--DOES IT NEED ITS COLORS SET OR SOMETHING?
				-- balloonref.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", "balloon_"..tostring(inst.balloon_num)) --THERE ARE 4 DIFF KINDS (OR 5?)
				balloonref.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", "balloon_1")
				-- balloonref.colour_idx = math.random(#colours)
				--balloonref.AnimState:SetMultColour(1,0,0,1)
				
				--4-25-20 DETERMINE BALLOON COLOR BASED ON SKIN
				local r = 0
				local g = 0
				local b = 0
				
				if inst.components.stats.buildname == "newwesblue" then
					b = 1
				elseif inst.components.stats.buildname == "newwesgreyscale" then
					r = 0.3
					g = 0.3
					b = 0.3
				elseif inst.components.stats.buildname == "newwesyellow" then
					r = 1
					g = 1
				else
					r = 1
				end
				balloonref.AnimState:SetMultColour(r,g,b,1)
				
				balloonref:DoTaskInTime(0.7, function(balloonref) 
					balloonref.AnimState:PlayAnimation("idle")
				end)
				
				inst.components.hitbox:SetOnHit(function() 
					balloonref.AnimState:PlayAnimation("pop", true)
					balloonref.AnimState:SetTime(4*FRAMES)
					balloonref.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
					-- balloonref.sg:GoToState("explode")
					balloonref.Transform:SetScale(1, 1, 1)

					inst:DoTaskInTime(8*FRAMES, function(inst) --6-30-17 DONT WE NEED THIS CUZ EXPLODE DOESNT REMOVE IT AUTOMATICALLY?
						balloonref:Remove()
					end)
				end)
				
				inst.components.hitbox:SpawnProjectile(-2, -1.2, 0, balloonref) 
				balloonref.components.stats:TintTeamColor(0.5)
				--OKAY... WHAT ABOUT AN FX?
				-- inst.components.hitbox:MakeFX("idle", 0.5, 1.4, 0,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "balloon", "balloon")
				
				--OK THEN A REAL BALOON???
				-- local balloon = SpawnPrefab("balloon")
				-- balloon.Transform:SetPosition(0,0,0)
			end),
			
			TimeEvent(21*FRAMES, function(inst) 
				inst.sg:AddStateTag("can_grab_ledge")
				
				--IF THEY HIT SOMEONE DURING THE SWING, REWARD THEM
				if inst.sg:HasStateTag("sweetspotted") then
					-- inst.components.hitbox:Blink(inst, 2,   1, 1, 1,   0.2)
					-- inst.components.visualsmanager:Blink(inst, 5,   1, 1, 1,   0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
					-- inst.sg:RemoveStateTag("busy")
					inst.sg:AddStateTag("can_attack")
					inst.sg:AddStateTag("can_jump")
				end
			end),
			
            TimeEvent(28*FRAMES, function(inst) 
				-- inst.components.visualsmanager:Blink(inst, 5,   1, 0, 1,   0.5, 1)
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
			
			TimeEvent(33*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("ropeswinging") --OKAY NOW THEY MAY TRY AGAIN
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.AnimState:PlayAnimation("ropeswing_pst") --idle_air
            end),
        },
    },
	
	
	State{
        name = "wall_slam",
        tags = {"busy", "nolandingstop", "ropeswinging", "noairmoving"}, --SWINGING, JUST FOR WES
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("faceplant")
			inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
			inst.components.hitbox:Blink(inst, 1,   0.6, 0.3, 0.3, 0.5, 1)
			inst.components.hitbox:MakeFX("side_ground_bounce", 0,0.5,0.5,   1.5, 1.5,    0.8, 6, 1)
			TheCamera:Shake("HORIZONTAL", .2, .02, .3) --(type, duration, speed, scale)
			
			-- inst.components.locomotor:SlowFall(0.1, 6)
			inst.components.locomotor:SlowFall(-0.2, 9)
			inst.Physics:Stop()
        end,
        
        timeline=
        {	
			TimeEvent(18*FRAMES, function(inst)  --HOPE YOU SAVED YOUR JUMP!~
				inst.sg:RemoveStateTag("busy")
			end),
        },
    },
	
	
	
	State{
        name = "dspecial",
        tags = {"busy", "nolandingstop", "no_air_transition", "intangible", "noairmoving", "no_fastfalling", "force_trade"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("reflect_box")
			inst.components.locomotor:Stop()
			inst.components.launchgravity:AirOnlyLaunch(0, 5)
			inst:PushEvent("swaphurtboxes", {preset = "dspec"})
			
			inst:AddTag("heavy") --JUST FOR A MOMENT TO KEEP US FROM SLIDING AWAY
			
			-- inst.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
			-- TheFocalPoint.SoundEmitter:PlaySound("dontstarve/wilson/equip_item")
			-- TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
			local camprefab = TheSim:FindFirstEntityWithTag("cameraprefab")
			camprefab.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
			
			
            inst.components.hitbox:MakeFX("waggle", 0, 0.50, 0.2,   3.2, 3.2,   0.5, 3, 0,  0,0,5, 1, "reflectorbox", "reflectorbox") 
			-- inst.components.jumper:AirStall()
			-- print("OK, SO AM I ON THE GROUND OR NOT?", inst.components.launchgravity:GetIsAirborn())
			-- inst.components.jumper:UnFastFall()
		end,
		
		onexit = function(inst)
			inst:RemoveTag("heavy") --OKAY NOW GET RID OF IT
		end,
		
        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 
				inst.components.locomotor:SlowFall(-0.2, 6)
				inst.Physics:Stop()
				
				inst.components.hitbox:SetOnHit(function() 
					inst.SoundEmitter:PlaySound("dontstarve/HUD/research_available")
				end)
				
				inst.components.hitbox:SetDamage(5) --7 --BUT THERE ARE NO SPACIES, SO THIS DOESNT DO MUCH!
				inst.components.hitbox:SetAngle(85)
				inst.components.hitbox:SetBaseKnockback(70)
				inst.components.hitbox:SetGrowth(60)
				inst.components.hitbox:SetSize(0.65) --1
				inst.components.hitbox:SetLingerFrames(0)
				inst.components.hitbox:SetProperty(-7) --REFLECTS PROJECTILES
				inst.components.hitbox:AddEmphasis(-3) --MAKE IT FEEL A BIT MORE LIKE MELEE?
				
				--1-8-22 OK, THIS 0-TO-DEATH NEEDS TO BE ADDRESSED. ANGLE DOWN IF IN THE AIR
				if inst.components.launchgravity:GetIsAirborn() then
					inst.components.hitbox:SetAngle(45)
				end
				
				inst.components.hitbox:SpawnHitbox(0, 1.3, 0)
			end),
			
			TimeEvent(2*FRAMES, function(inst) 
				--OKAY NOW ONE THAT DOESN'T HIT PEOPLE
				inst.components.hitbox:SetDamage(0) --25
				-- inst.components.hitbox:SetAngle(85)
				inst.components.hitbox:SetBaseKnockback(0)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetSize(0.7, 1.0) --1
				inst.components.hitbox:SetProperty(7)
				inst.components.hitbox:SetLingerFrames(150)
				inst.components.hitbox:SetHitFX("none", "none") --THIS REFLECTOR SHOULD NOT PLAY ANY SOUNDS WHEN HITTING A PERSON
				
				--I GUESS WE NEED TO OVERWRITE THIS TOO
				inst.components.hitbox:SetOnHit(function() 
					--DON'T PLAY THE SOUND
				end)
				
				if inst.components.keydetector:GetBackward(inst) then --FIRST THINGS FIRST. TURN AROUND
					inst.components.locomotor:TurnAround()
				end
				
				
				inst.sg:RemoveStateTag("intangible") 
				-- inst.components.hitbox:MakeFX("idle", 0, 0.7, 0.2,   3, 3,   1, 3, 0,  0,0,0, 0, "reflectorbox", "reflectorbox") 
				inst.components.hitbox:SpawnHitbox(0, 0.5, 0)
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst:RemoveTag("heavy") --OKAY NOW GET RID OF IT
				inst.sg:AddStateTag("can_jump") --JUMP OUT OF REFLECTOR!
			end),
			

			-- TimeEvent(6*FRAMES, function(inst)
				-- print("MANUAL TAG")
				-- if not inst.components.keydetector:GetSpecial(inst) then
					-- inst.sg:GoToState("reflect_end")
				-- end
			-- end),
			
			TimeEvent(8*FRAMES, function(inst)
				inst.components.locomotor:SlowFall(0.2, 15)
			end),
			
			TimeEvent(20*FRAMES, function(inst)
				inst.sg:AddStateTag("can_grab_ledge")
			end),
			
			TimeEvent(150*FRAMES, function(inst)
				inst.sg:AddStateTag("not_reflecting")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
				-- print("ANIMOVER")
				inst.AnimState:PlayAnimation("reflect_box_loop")
				if not inst.sg:HasStateTag("not_reflecting") then
					inst.components.hitbox:MakeFX("idle", 0, 0.50, 0.2,   2.7, 3.0,   1, 5, 0,  0,0,0, 1, "reflectorbox", "reflectorbox") 
				end
				if not inst.components.keydetector:GetSpecial(inst) then
					inst.sg:GoToState("reflect_end")
				end
            end),
			
			EventHandler("reflected_something", function(inst)
				inst.components.hitbox:MakeFX("waggle", 0, 0.50, 0.2,   3.2, 3.2,   0.5, 3, 0,  0,0,5, 1, "reflectorbox", "reflectorbox") 
				inst.SoundEmitter:PlaySound("dontstarve/HUD/research_available", "flirp")
				-- TheFocalPoint.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_return")
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_return", "flirp")
				-- inst.SoundEmitter:SetVolume("flirp", 10000)
				-- TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/tool_slip")
				local camprefab = TheSim:FindFirstEntityWithTag("cameraprefab")
				camprefab.SoundEmitter:PlaySound("dontstarve/common/tool_slip")
            end),
        },
    },
	
	
	State{
        name = "reflect_end",
        tags = {"busy", "can_jump", "nolandingstop"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("reflect_box_pst")
			-- inst.components.locomotor:SlowFall(0.1, 6)
        end,
        
        timeline=
        {
            TimeEvent(9*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	
	--FSMASH
	State{
        name = "fsmash_start",
        tags = {"busy", "scary"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("crosschop_charge")
			-- inst.components.jumper:ScootForward(-5)
            inst.components.hitbox:SetDamage(14)
        end,
		
		timeline=
        {
			
            TimeEvent(2*FRAMES, function(inst)
				inst.sg:GoToState("fsmash_charge")
			end),
        },
		
	},
	
	State{
        name = "fsmash_charge",
        tags = {"attack", "scary", "f_charge", "busy", "scary"},
        
        onenter = function(inst)
			
			if not inst:HasTag("atk_key_dwn") then
				inst.sg:GoToState("fsmash")
			else
			
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.colourtweener:StartTween({1,0,0,1}, 1, nil)

			end
            
        end,
		
		onupdate = function(inst)
            inst.components.hitbox:MultiplyDamage(1.0113)
        end,
		
		onexit = function(inst)
            inst.components.colourtweener:EndTween()
			inst.AnimState:SetMultColour(1,1,1,1)
			
			inst.components.visualsmanager:EndShimmy()
        end,
        
        timeline=
        {
            
			TimeEvent(10*FRAMES, function(inst) 
				inst.components.visualsmanager:Shimmy(0.02, 0.02, 10)
			end),
			
			TimeEvent(31*FRAMES, function(inst) 
				inst.sg:GoToState("fsmash")
			end),
		
        },
        
        events=
        {
			EventHandler("throwfsmash", function(inst)
				inst.sg:GoToState("fsmash")
			end ),
        },
    },
	
	
	State{
        name = "fsmash",
        tags = {"attack", "notalking", "busy", "abouttoattack", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("crosschop")
			-- inst.AnimState:SetTime(5*FRAMES)
			inst.components.jumper:ScootForward(15)
        end,
		
        timeline=
        {
           -- ") end),
			TimeEvent(1*FRAMES, function(inst)
				-- inst.components.jumper:ScootForward(12)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			end),
			
			TimeEvent(3*FRAMES, function(inst)
				inst.components.jumper:ScootForward(7)
				
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(30)  
				inst.components.hitbox:SetGrowth(84)
				inst.components.hitbox:SetSize(0.8, 0.5)
				inst.components.hitbox:SetLingerFrames(1)

				inst.components.hitbox:SpawnHitbox(1.2, 1, 0) 
				
				
				--SOURSPOT CUZ PEOPLE HATE WHIFFING PEOPLE RIGHT IN FRONT OF THEM
				inst.components.hitbox:SetDamage(10) 
				inst.components.hitbox:SetAngle(361) 
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(130)
				inst.components.hitbox:SetSize(0.5)
				
				inst.components.hitbox:SpawnHitbox(0.3, 1, 0) 
			end),
			
			
            TimeEvent(23*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("attack")
				-- inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	--DSMASH
	State{
        name = "dsmash_start",
        tags = {"busy"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("dsmash_charge")
			inst.components.hitbox:SetDamage(14)
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
        end,
		
		timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 
				inst.sg:GoToState("dsmash_charge")
			end),
        },
		
	},
	
	State{
        name = "dsmash_charge",
        tags = {"attack", "scary", "d_charge", "busy"},
        
        onenter = function(inst)
			if not inst:HasTag("atk_key_dwn") then
				inst.sg:GoToState("dsmash")
			else
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.colourtweener:StartTween({1,0,0,1}, 2, nil)
			end
        end,
		
		onexit = function(inst)
            inst.components.colourtweener:EndTween()
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.visualsmanager:EndShimmy()
        end,
		
		onupdate = function(inst)
            inst.components.hitbox:MultiplyDamage(1.0113)
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.components.visualsmanager:Shimmy(0, 0.02, 10)
			end),
			
			TimeEvent(31*FRAMES, function(inst) 
				inst.sg:GoToState("dsmash")
			end),
        },
        
        events=
        {
			EventHandler("throwdsmash", function(inst) inst.sg:GoToState("dsmash") end ),
        },
    },
	
	State{
        name = "dsmash",
        tags = {"attack", "busy"},
		
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dsmash")
			inst.components.hitbox:MakeFX("woosh1", 0, 0.1, -0.1,   1.1, 1.0,   0.9, 6, 0.2, 0,0,0, 1)
			inst.components.hitbox:MakeFX("woosh1", 0, 0.1, -0.1,   -1.1, 1.0,   0.9, 6, 0.2, 0,0,0, 1)
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(2*FRAMES, function(inst)
				-- inst:PushEvent("swaphurtboxes", {preset = "landing"})
				
				inst.components.hitbox:SetAngle(35)
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(90)
				
				inst.components.hitbox:SetSize(1.3, 0.2)
				
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0, 0, 0)
			end),
			
			-- TimeEvent(3*FRAMES, function(inst)
				-- inst.components.hitbox:MakeFX("lucy_spinwoosh2", 0.2, 0.2, -0.5,   1.2, 0.6,   1, 8)
			-- end),
				
			-- TimeEvent(4*FRAMES, function(inst)
				-- inst.components.hitbox:SetSize(1, 0.3)
				-- inst.components.hitbox:SetLingerFrames(3)
				-- inst.components.hitbox:MakeDisjointed()
				-- inst.components.hitbox:SpawnHitbox(-0.8, 0.3, 0)
			-- end),

			
            TimeEvent(22*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
		
	},
	
	
	
	State{
        name = "usmash_start",
        tags = {"busy"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("flipkick_charge")
			inst.components.hitbox:SetDamage(13)
        end,
		
		timeline=
        {
			
			TimeEvent(1*FRAMES, function(inst) 
				inst.sg:GoToState("usmash_charge")
			end),
        },
		
	},
	
	State{
        name = "usmash_charge",
        tags = {"attack", "u_charge", "busy"},
        
        onenter = function(inst)
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.colourtweener:StartTween({1,0,0,1}, 1, nil)
			
			inst.components.visualsmanager:Shimmy(0, 0.02, 10)
        end,
		
		onupdate = function(inst)
            inst.components.hitbox:MultiplyDamage(1.0113)
        end,
		
		onexit = function(inst)
            inst.components.colourtweener:EndTween()
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.visualsmanager:EndShimmy()
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hatch_crack")
			end),
			TimeEvent(31*FRAMES, function(inst) 
				inst.sg:GoToState("usmash")
			end),
        },
        
        events=
        {
			EventHandler("throwusmash", function(inst) inst.sg:GoToState("usmash") end ),
        },
    },
	
	
	State{
        name = "usmash",
        tags = {"attack", "notalking", "busy", "abouttoattack"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("flipkick")
			-- inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
		end,
		
        timeline=
        {
			
			TimeEvent(2*FRAMES, function(inst) 
				-- inst.components.hitbox:SetDamage(7)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
				inst.components.hitbox:SetAngle(60) 
				inst.components.hitbox:SetBaseKnockback(10)
				inst.components.hitbox:SetGrowth(132)
				inst.components.hitbox:SetSize(0.8)
				inst.components.hitbox:SpawnHitbox(0.7, 0.4, 0)
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(1.1)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0.3, 1.1, 0) 
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(0.8)
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:SpawnHitbox(-0.7, 0.5, 0) 
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "landing"})
			end),
			
			
			TimeEvent(23*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			
            TimeEvent(27*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack") 
				inst.sg:RemoveStateTag("busy") 
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                -- inst.sg:GoToState("idle")
				-- inst.AnimState:PlayAnimation("chop_pst")
				--inst.sg:RemoveStateTag("busy")
            end),
        },
    }, 
}







CommonStates.AddFrozenStates2(states)
CommonStates.AddRespawnPlatform(states)
CommonStates.AddDropSpawn(states)

--ssh clkursch@machine.secs.oakland.edu
--machine = beatles
--/home/machine

    
return StateGraph("wilson", states, events, "idle") --, actionhandlers)

