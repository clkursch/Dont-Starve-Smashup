--require("stategraphs/fighterstates") --3-6-17

local trace = function() end


--4-5 KEY BUFFER  --SHOULD I MAKE THIS A STATS.LUA FUNCTION?... NAH. THIS IS PROBABLY FASTER ANYWAYS  --NO I REALLY SHOULD THOUGH. THIS IS SILLY
local function TickBuffer(inst)

	-- inst:PushEvent(inst.components.stats.event, {key = inst.components.stats.key})
	inst:PushEvent(inst.components.stats.event, {key = tostring(inst.components.stats.key), key2 = inst.components.stats.key2})
	inst.components.stats.buffertick = inst.components.stats.buffertick - 1
	-- print("TICK", inst.components.stats.event, inst.components.stats.buffertick)
end

   
local events=
{
	--10-14 TESTING SOME KEYDETECTOR STUFF OUT
	--inst:DoPeriodicTask(0.25, )
	
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
		inst.components.stats.buffertick = 0
	end),
	
	
	EventHandler("jump", function(inst, data)
		local is_busy = inst.sg:HasStateTag("busy")
		local can_jump = inst.sg:HasStateTag("can_jump")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local used_first_jump = inst.components.jumper.jumping == 1 and inst.components.jumper.doublejumping == 0
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		
		-- if can_jump or can_oos or can_ood or not is_busy then
			-- if used_first_jump then 
				-- inst.sg:GoToState("doublejump")
			-- else
				-- --inst.components.jumper:Jump()  --11-16, REMOVING FOR CROUCH TIMES
				-- --inst.sg:GoToState("jump")  --11-5 EVENTUALLY I'LL NEED TO USE THIS INSTEAD OF THAT ^
				-- --inst.sg:GoToState("highjump")  --NO THATS THE OLD BROKEN FUNCTION
				-- inst.sg:GoToState("highleap")
				-- print("HOW HIGH")
			-- end
		-- end

		--1-5 NEW JUMP SYSTEM SO CRAP DOESNT HIT THE FAN WHEN TRYING TO LEAVEGROUND() ON LAUNCHES
		-- if (can_jump and not is_airborn) or (not is_busy and not is_airborn) or ((can_jump or can_oos or can_ood) and not is_airborn) then
			-- inst.sg:GoToState("highleap")
		-- elseif (can_jump and inst.components.jumper.currentdoublejumps >= 1) or (not is_busy and inst.components.jumper.currentdoublejumps >= 1) then
			-- inst.sg:GoToState("doublejump")
		-- end
		
		if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event ~= "jump" then
			return end
			
		if inst.sg:HasStateTag("listen_for_atk") and inst.components.stats.event == "jump" then
			return end
		
		--4-23-20 - NEW SYSTEM TO INTEGRATE BUFFERED AIREALS
		if data.key and data.key == "ITSNIL" then --ALRIGHT YOU LITTLE- IF IT COMES BACK "ISNIL" HARDCODE THIS THING TO NIL BECAUSE SENDING IN NIL ISNT WORKING
			data.key = nil --THIS MAKES ME UNBELEIVABLY PISSED THAT THIS WORKS
		end
		if (can_jump and not is_airborn) or (not is_busy and not is_airborn) or ((can_jump or can_oos or can_ood) and not is_airborn) then
			-- if data.key and data.key ~= nil then --BASICALLY, IF AN ATTACK KEY WAS PRESSED ALONG WITH JUMP, SET THE BUFFER TO ATTACK AFTER THE JUMP
				-- inst.components.stats:SetKeyBuffer("throwattack", data.key)
			-- end
			-- inst.sg:GoToState("highleap") --AND THEN JUMP
			-- inst:PushEvent("throwattack", {key = data.key})
			if data.key and data.key ~= nil then --BASICALLY, IF AN ATTACK KEY WAS PRESSED ALONG WITH JUMP, SET THE BUFFER TO ATTACK AFTER THE JUMP
				inst.sg:GoToState("highleap")
				inst.components.stats:SetKeyBuffer("throwattack", data.key, data.key2)
			else
				inst.sg:GoToState("highleap")
			end
		elseif (can_jump and inst.components.jumper.currentdoublejumps >= 1) or (not is_busy and inst.components.jumper.currentdoublejumps >= 1) then
			-- inst.sg:GoToState("doublejump")
			-- if data.key and data.key ~= nil then --SAME HERE
				-- inst.components.stats:SetKeyBuffer("throwattack", data.key)
				-- inst:PushEvent("throwattack", {key = data.key})
			-- end
			if data.key and data.key ~= nil then --SAME HERE
				inst.sg:GoToState("doublejump")
				inst.components.stats:SetKeyBuffer("throwattack", data.key, data.key2)
				inst:PushEvent("throwattack", {key = data.key, key2 = data.key2})
			else
				inst.sg:GoToState("doublejump")
			end
		elseif (can_jump or not is_busy) and is_airborn and data.key and data.key ~= nil then 
			inst.components.stats.event = "throwattack"
		end
		
		--4-23-20 INTERESTING, SOMTIMES THE BUFFER CAN RUN THIS AGAIN AND DETECT A BUFFERED ATTACK, EVEN AFTER THE JUMP STATE HAS STARTED WITHOUT ONE... LETS TRY AND RIG IT 
		if (inst.sg.currentstate.name == "highleap" or inst.sg.currentstate.name == "doublejump") and inst.sg.timeinstate == 0 then
			if data.key and data.key ~= nil then --SAME, BUT NOW YOU'RE ALREADY JUMPING SO JUST SET THE BUFFER
				inst.components.stats:SetKeyBuffer("throwattack", data.key, data.key2)
			end
		end
	
	
	end),
	
	
	
	EventHandler("singlejump", function(inst, data)
		local is_busy = inst.sg:HasStateTag("busy")
		local can_jump = inst.sg:HasStateTag("can_jump")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local used_first_jump = inst.components.jumper.jumping == 1 and inst.components.jumper.doublejumping == 0
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		
		--1-5 NEW JUMP SYSTEM SO CRAP DOESNT HIT THE FAN WHEN TRYING TO LEAVEGROUND() ON LAUNCHES
		if (can_jump and not is_airborn) or (not is_busy and not is_airborn) or ((can_jump or can_oos or can_ood) and not is_airborn) then
			inst.sg:GoToState("singlejump")
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
			
		-- print("STOP LEAVING ME HANDING")
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
		
		-- print("IS IT THEE?", is_busy, is_falling)
		-- if not is_busy and is_airborn and can_grab_ledge then
		if no_grab_ledge and not autosnap then
			--DO NOTHING
		elseif (can_grab_ledge or (not is_busy and is_falling)) and not pressing_down and not inst:HasTag("hitfrozen") then --8-29 ADDED CHECK FOR HITFROZEN TO FIX A BUG THAT CAUSED PHYSICS TO RESUME ON LEDGEGRAB
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
			-- elseif data.key == "none" then --LATE-8-11-17 ALRIGHT, NO MORE OF THIS. BUFFER MUST HAVE A DIRECTION, OR NO ROLLING ALLOWED
			--11-29-20 THESE VERSIONS ARE FOR AI ONLY
			elseif data.key == "forward" then
				inst.components.locomotor:FaceTarget(inst.components.stats.opponent)
				inst.sg:GoToState("roll_forward")
			elseif data.key == "backward" then
				inst.components.locomotor:FaceTarget(inst.components.stats.opponent)
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("roll_forward")
			
			else
				--ITS A TRAP! DONT REACT TO THIS
				--1-15-22 OKAY. I SAW THIS... NOW WHAT? I WAS JUST TRYING TO BLOCK, NOT DODGE. SEEMED TO WORK OUT OK
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
		local can_dash = inst.sg:HasStateTag("candash") and not no_running 
		local pivoting = inst.sg:HasStateTag("pivoting")
		
		
		--11-28-20 IF WE'RE AN NPC, USE THIS INSTEAD
		if inst:HasTag("dummynpc") then
			local can_ood = inst.sg:HasStateTag("can_ood")
			local is_dashing = inst.sg:HasStateTag("dashing")
			local is_airborn = inst.components.launchgravity:GetIsAirborn()
			if (can_ood or not is_busy) and not is_airborn and not is_dashing then
				inst.sg:GoToState("dash")
			end
			return end
		
		local pressing_forward = inst.components.keydetector:GetForward(inst)
		local foxtrot = inst.sg:HasStateTag("foxtrot")
		
		--1-14-22 CHECK DIRECTION FOR BUFFERED DASHES
		local facedir = inst.components.launchgravity:GetRotationFunction()
		if data.key and data.key ~= facedir then
			--inst.components.locomotor:TurnAround()
			pressing_forward = false
		end
		
		
		if foxtrot and not pressing_forward then
			inst.sg:GoToState("run_stop")
		elseif foxtrot and not no_running then 
			-- print("ANOTHER BONUS DASH")
			inst.sg:GoToState("dash")
		elseif (not is_busy and not no_running) or can_dash then
			if not pressing_forward then
				inst.components.locomotor:TurnAround()
			end
			-- print("BONUS DASH")
			inst.sg:GoToState("dash_start")
			inst.components.hitbox:MakeFX("dahswoosh", 0.5, 1.5, 1, 1, 1, 0.8, 7, 1)
			inst.components.hitbox:MakeFX("slide1", 0.5, 0, 0.1, 0.5, 0.5, 1, 10, 0)
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
			-- print("NANER PEELS")
		else
			--DO NOTHING
			--inst.sg:GoToState("dash_stop")
		end
		
		
	end),
	
    EventHandler("locomote", function(inst)
		local is_jumping = inst.components.launchgravity:GetIsAirborn()
		
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
        
		if is_jumping then
			
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
		-- local must_fsmash = inst.sg:HasStateTag("must_fsmash")
		-- local must_usmash = inst.sg:HasStateTag("must_usmash")
		-- local must_dsmash = inst.sg:HasStateTag("must_dsmash")
		-- local must_ftilt = inst.sg:HasStateTag("must_ftilt")
		local pivoting = inst.sg:HasStateTag("pivoting")
		
		--4-23-20 IF THE USER PRESSED JUMP ON THE SAME FRAME, CANCEL THE ATTACK.
		if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event == "jump" then
			-- print("--CANCELLING THE ATTACK--")
			return end
			
		if can_oos then
			inst.sg:GoToState("grab")
			
			--THESE ARE DUMB AND OUTDATED. LETS GET RID OF THEM 8-29-20
		-- elseif must_fsmash then
			-- inst.sg:GoToState("fsmash_start")
		-- elseif must_usmash then
			-- inst.sg:GoToState("usmash_start")
		-- elseif must_dsmash then
			-- inst.sg:GoToState("dsmash_start")
		-- elseif must_ftilt then --WAIT WE REALLY STILL USE THIS?? ARE YOU FOR REAL?
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
				inst.sg:GoToState("uptilt")
		
        --if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
		-- elseif not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
		elseif not inst.sg:HasStateTag("busy") or can_attack then --12-4
		
		
		
		--DETECTS IF AIRBORN FOR AIREALS
			--local airial = inst.components.highjumper:IsJumping()    --GetFallingSpeed()
			--local airial = inst.components.jumper:GetIsJumping()
			-- local airial = inst.components.launchgravity:GetIsAirborn()
			
			-- local can_oos = inst.sg:HasStateTag("canoos")
			-- local can_ood = inst.sg:HasStateTag("can_ood")
			-- print("ATTACK--", data.key, data.key2)
			if can_oos or (data.key == "block" and not airial) then
				if data.key2 == "backward" then inst.components.locomotor:TurnAround() end
				inst.sg:GoToState("grab")
				-- inst.sg:GoToState("testgrab1") --4-14-20 THIS IS ONLY FOR TESTING!!! PUT THIS BACK WHEN YOURE DONE
			
			elseif airial then
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
				
				--11-28-20 FOR CPU INPUTS
				if data.key == "fsmash" then
				-- inst.sg:GoToState("attack")
					inst.sg:GoToState("fsmash_start")
				elseif data.key == "usmash" then
					inst.sg:GoToState("usmash_start")
				
				elseif data.key == "up" or data.key == "diagonalf" then 
					inst.sg:GoToState("uptilt")
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
						inst.sg:GoToState("uptilt")
					else
						inst.sg:GoToState("ftilt")
					end
				else
				
				--inst.sg:GoToState("attack")
				inst.sg:GoToState("jab1")
				-- inst.sg:GoToState("dev_post_hitlag2")
				-- inst.sg:GoToState("dev_animframes")
				-- inst.sg:GoToState("dev_multihitlag")
				-- inst.sg:GoToState("dev_axereplica")
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
			
		if data and data.key == "backward" and not (is_busy or airial) then --2-1-22
			inst.components.locomotor:TurnAround()
		end
		
		-- print("TAP JUMP?", inst.sg:HasStateTag("can_usmash"), can_ood, inst.components.stats.tapjump, is_busy, airial)
		if (inst.sg:HasStateTag("can_usmash") and inst.components.stats.tapjump or can_ood) or not is_busy and not airial then
			if tiltstick == "smash" then
				inst.sg:GoToState("usmash_start")
			else
				inst.sg:GoToState("uptilt")
			end
		elseif not inst.sg:HasStateTag("busy") and airial then
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
	
	--WE USE C-STICK SIDE EVENTS INSTEAD
	--[[
	EventHandler("cstick_forward", function(inst, data)
		
		local airial = inst.components.launchgravity:GetIsAirborn()
		local must_fsmash = inst.sg:HasStateTag("must_fsmash")
		
		print("COMPANY HALT", data.key, inst.components.launchgravity:GetRotationFunction())
		
		if must_fsmash then --7-17-17 GETTINF RID OF   --7-18-17 NO WAIT BRINGING BACK FOR THE CONTROLLERS SPECIFICALLY
			inst.sg:GoToState("fsmash_start")	
		elseif not inst.sg:HasStateTag("busy") and not airial then
			--7-20-17 FORGET ALL THIS!!! MAKING A CSTICK_SIDE EVENT HANDLER FOR BUFFERED DIRECTIONS
			-- if data.key == inst.components.launchgravity:GetRotationFunction() or (data.key ~= "right" and data.key ~= "left") then  --IF ITS SOMETHIN WEIRD, JUST IGNORE IT. IT'LL GET BORED AND LEAVE
				-- --DO NOTHING
			-- elseif data.key and data.key ~= inst.components.launchgravity:GetRotationFunction() then
				-- inst.components.locomotor:TurnAround()
			-- end
			
			inst.sg:GoToState("fsmash_start")	
		elseif not inst.sg:HasStateTag("busy") and airial then
			inst.sg:GoToState("fair")
		end
	end),
	
	EventHandler("cstick_backward", function(inst, data) --THAT STUPID S
		
		local airial = inst.components.launchgravity:GetIsAirborn()
		local must_fsmash = inst.sg:HasStateTag("must_fsmash")
		-- print("BLADE")
		
		-- if must_fsmash then   --7-17-17 GETTING RID OF
			-- inst.sg:GoToState("fsmash_start")	
		-- else
		if not inst.sg:HasStateTag("busy") and not airial then
			
			--7-16-17 FIXING DIRECTIONAL CSTICK BUFFERING FOR TURNAROUNDS MID-BUFFER --7-20-17 NO NEVERMIND THIS
			-- inst.components.playercontroller_1:CheckBufferDir() --NO FORGET THIS
			-- if data.key == inst.components.launchgravity:GetRotationFunction() or (data.key ~= "right" and data.key ~= "left") then  --IF ITS SOMETHIN WEIRD, JUST IGNORE IT. IT'LL GET BORED AND LEAVE
				-- --DO NOTHING
			-- elseif data.key and data.key ~= inst.components.launchgravity:GetRotationFunction() then
				-- inst.components.locomotor:TurnAround()
			-- end
		
			inst.components.locomotor:TurnAround() --OK WE'RE TURNING AROUND TWICE I GUESS
			inst.sg:GoToState("fsmash_start")	
		elseif not inst.sg:HasStateTag("busy") and airial then
			inst.sg:GoToState("bair")
			-- print("THIMBIT")
		end
	end),
	]]
	
	
	--7-20-17 NEW CSTICK LISTENER TO ALLOW DIRECTIONAL BUFFEREING OUT OF CHANGING DIRECTIONS
	EventHandler("cstick_side", function(inst, data)	
		local airial = inst.components.launchgravity:GetIsAirborn()
		local must_fsmash = inst.sg:HasStateTag("must_fsmash")
		local is_forward = (data.key == inst.components.launchgravity:GetRotationFunction())
		local valid_key = (data.key == "left" or data.key == "right")
		local tiltstick = inst.components.stats.tiltstick
		
		--4-23-20 IF THE USER PRESSED JUMP ON THE SAME FRAME, CANCEL THE ATTACK.
		if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event == "jump" then
			if is_forward and valid_key then 
				inst.components.stats.key = "forward"
			else
				inst.components.stats.key = "backward"
			end
			return end
		
		-- if must_fsmash and is_forward then  --ITS GOOD TO LEAVE THIS HERE OR ELSE DASH ATTACKS GET WIERD
			-- inst.sg:GoToState("fsmash_start")
		--9-7-21 NAH FORGET WHATEVER THAT THING IS MEANT TO BE. CHECK FOR DASH ATTACK INSTEAD.
		if inst.sg:HasStateTag("can_ood") and is_forward then --9-7-21
			if inst.sg:HasStateTag("sliding") then
				if tiltstick == "smash" then
					inst.sg:GoToState("fsmash_start") --ALLOW THEM TO SMASH DURING PIVOTS 
				else
					inst.sg:GoToState("ftilt")
				end
			else
				inst.sg:GoToState("dash_attack")
			end				
		
		elseif not inst.sg:HasStateTag("busy") and not airial then
			--TURN AROUND IF NOT FACING THE SAME WAY THE BUFFERED DIRECTION KEY WAS
			if not is_forward and valid_key then --MAKE SURE THAT THE KEY DIDNT JUST COME IN AS TABLE GIBBERISH INSTEAD OF THE OPPOSITE DIRECTION
				inst.components.locomotor:TurnAround()
			end
			if tiltstick == "smash" then
				inst.sg:GoToState("fsmash_start")
			else
				inst.sg:GoToState("ftilt")
			end
			
		elseif not inst.sg:HasStateTag("busy") and airial then
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
					inst.sg:GoToState("uspecial_wilson")
				else
					--WARN THEM THAT THEY GOT NO RECOVERY --THIS NEEDS TO GO IN ALL SPOTS
					inst.components.hitbox:Blink(inst, 1,   0.6, 0.3, 0.3, 0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
				end
			elseif data.key == "diagonalf" then		--ADDING DIAGONALS  --TODOLIST: FIX THIS SO IT'S LIKE EVERYONE ELSE'S
				if inst.components.stats.norecovery == false then
					if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
					inst.sg:GoToState("uspecial_wilson")
				else
						--WARN THEM THAT THEY GOT NO RECOVERY --THIS NEEDS TO GO IN ALL SPOTS
						inst.components.hitbox:Blink(inst, 1,   0.6, 0.3, 0.3, 0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
				end
			elseif data.key == "diagonalb" then
				if inst.components.stats.norecovery == false then
					if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
					inst.components.locomotor:TurnAround()
					inst.sg:GoToState("uspecial_wilson")
				else
					--WARN THEM THAT THEY GOT NO RECOVERY --THIS NEEDS TO GO IN ALL SPOTS
					inst.components.hitbox:Blink(inst, 1,   0.6, 0.3, 0.3, 0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
				end
			-- end
			elseif data.key == "down" then
				inst.sg:GoToState("dspecial")
			elseif data.key == "forward" then
				-- print("BOOMERANG FACECHECK", )
				if data.key2 and data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
				inst.sg:GoToState("fspecial")
			elseif data.key == "backward" then
				if data.key2 and data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("fspecial")
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
        name = "wakeup",

        onenter = function(inst)
            inst.components.playercontroller:Enable(false)
            inst.AnimState:PlayAnimation("wakeup")
            inst.components.health:SetInvincible(true)
        end,
        
        onexit = function(inst)
            inst.components.playercontroller:Enable(true)
            inst.components.health:SetInvincible(false)
        end,
        
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },

    },


    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        
		--FIXED IDLE ANIMATION
		onenter = function(inst)
			inst.AnimState:PlayAnimation("idle")
				--12-7
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			
			if inst.components.stats and inst.components.launchgravity then	--4-6 I GUESS THIS IS FOR IN CASE NOT ALL COMPONENTS HAVE FINISHED LOADING YET???
				if inst.components.launchgravity:GetIsAirborn() then --4-6 MOVING IT DOWN HERE SEEMED TO FIX IT
					inst.sg:GoToState("air_idle")
				elseif inst.components.keydetector and inst.components.keydetector:GetDown(inst) then
					inst.sg:GoToState("duck")
				end
			end
		end,
        
        ontimeout= function(inst)
            inst.sg:GoToState("funnyidle")
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
			
			TimeEvent(3*FRAMES, function(inst)
                PlayFootstep(inst)
            end),
            
			TimeEvent(10*FRAMES, function(inst) --6
                PlayFootstep(inst)
                
				--6-8-20 TRYING OUT A BIG CHANGE IN THE WAY BASIC MOVEMENT IS HANDLED
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
	
	--[[
    State{
        
        name = "run",
        tags = {"moving", "running", "canrotate", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
            inst.components.locomotor:RunForward()
			inst.AnimState:PushAnimation("run")
			inst:PushEvent("swaphurtboxes", {preset = "walking"})
        end,
        
        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline=
        {
            --6-8-20 TESTING OUT A NEW MOVEMENT OPTION
			TimeEvent(4*FRAMES, function(inst)
				inst.sg:GoToState("dash")
            end),
			
			TimeEvent(7*FRAMES, function(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
                
				--inst.components.locomotor.throttle = 1
            end),
            TimeEvent(15*FRAMES, function(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
                
            end),
        },
        
        events=
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("run") end ),
			-- EventHandler("animover", function(inst) inst.sg:GoToState("dash") end ), --6-8-20... LETS GIVE THIS A SHOT...
        },
    },
	]]
	
	
	--9-26-20 RUNNING 2, THE SEQUEL. FOR HOLDING DOWN TO PREVENT DASHING
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
                -- PlayFootstep(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
				--CHECK IF WE'RE HOLDING DOWN ON THE KEYPAD. 
				-- CheckWalkImpulse(inst) --10-13-21 NOT ANYMORE
            end),
            TimeEvent(15*FRAMES, function(inst)
                -- PlayFootstep(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
				-- CheckWalkImpulse(inst)
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
        
        events=
        {   
            --EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),        
        },
        
    },
	
	
	
	--@@@ ADDING DASHING
	State{
        
        name = "dash_start",
        tags = {"moving", "running", "canrotate", "dashing", "can_usmash", "can_special_attack", "can_ood", "busy", "can_dashdance", "foxtrot", "must_fsmash", "must_roll", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
			inst.components.locomotor.throttle = 0
			inst.components.locomotor:DashForward()
			inst.AnimState:PlayAnimation("dash")
			
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
					-- inst:PushEvent("roll")
				end
				-- inst.components.hitbox:MakeFX("stars", -1.6, 1.0, 0.1, 1, 0.7, 0.8, 2, 0)
			end
        end,

        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
				-- inst.sg:RemoveStateTag("must_roll")
			end),
			TimeEvent(2*FRAMES, function(inst)
				inst.sg:RemoveStateTag("must_fsmash")
				inst.sg:RemoveStateTag("must_roll")
			end),
			
            TimeEvent(7*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.2, 0.2, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst:PushEvent("dash") --WHY DO WE DO IT LIKE THIS AGAIN?... 8-28-20
				-- inst.sg:GoToState("dash")
			end),
            TimeEvent(15*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.5, 0.5, 0.8, 5, 0)
				-- inst:PushEvent("block_key")
            end),
			 TimeEvent(20*FRAMES, function(inst)
				--inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.5, 0.5, 1, 5, 0)
            end),
        },
        
        events=
        {   
			
			EventHandler("block_key", function(inst)   --9-7  DOESNT WORK?... FIX THIS --THEFIXLIST
					inst.sg:GoToState("roll_forward")
			end ), 
			--8-29-20 FOR EARLY SMASH ATTACKS. THIS 7 FRAME WINDOW IS AWEFULLY GENEROUS... BUT I DONT THINK ITS GAME BREAKING
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
            --inst.components.locomotor:RunForward()
			inst.components.locomotor:DashForward()
			--inst.AnimState:SetMultColour(1,1,1,0.2)
            --inst.AnimState:PlayAnimation("run_loop")
			inst.AnimState:PlayAnimation("dash")
			-- inst.components.hitbox:MakeFX("dahswoosh", 0, 1, -1, 1, 1, 0.8, 7, 1)
			--inst.components.hitbox:MakeFX("sidesplash_med_up", 0, 1, -1, 1, 1, 0.8, 7, 1)
			
			inst:PushEvent("swaphurtboxes", {preset = "dashing"})
			inst.sg.mem.foosteps = 0
            
        end,
        
        onupdate = function(inst)
            inst.components.locomotor:DashForward()
        end,

        timeline=
        {
            TimeEvent(7*FRAMES, function(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
                
				--inst.components.hitbox:MakeFX("dahswoosh", 0, 1, -1, 1, 1, 0.8, 7, 1)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.2, 0.2, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
            end),
            TimeEvent(15*FRAMES, function(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
                
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
		-- tags = {"canrotate", "dashing", "busy_", "sliding", "can_special_attack", "can_ood", "can_jump", "keylistener", "keylistener2", "can_attack"}, --, "candash"
        tags = {"canrotate", "dashing", "sliding", "keylistener", "keylistener2", "can_attack"}, --, "candash"
        
        onenter = function(inst) 
			inst.AnimState:PlayAnimation("dash_pst")
			inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1, 1, 0.5, 0.8, 10, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
            
        end,

        timeline=
        {
			-- TimeEvent(1*FRAMES, function(inst) inst:PushEvent("dash_stop") end), --1-8 REPLACING ALL THESE WEIRD EVENT PUSHERS WITH KEY LISTENER EVENT HANDLERS
			TimeEvent(2*FRAMES, function(inst) inst:PushEvent("swaphurtboxes", {preset = "idle"}) end),
			
			TimeEvent(4*FRAMES, function(inst)
				-- inst:PushEvent("dash_stop")
				inst.sg:RemoveStateTag("keylistener")
				-- inst.sg:RemoveStateTag("can_ood")
				
            end),
			TimeEvent(6*FRAMES, function(inst)
				--inst.sg:RemoveStateTag("sliding") --12-31 I THINK THIS IS CAUSING PROBLEMS
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
					inst.components.locomotor:TurnAround() --6-8-20 NOW WE NEED AN EXTRA ONE
					inst.sg:GoToState("pivot_dash")
				end
			end ),        
        },
        
        
    },
	
	State{
        
        name = "pivot_dash",
        tags = {"canrotate", "busy", "sliding", "can_special_attack", "can_ood", "pivoting", "must_fsmash", "must_ftilt"}, --, "candash"
        
        onenter = function(inst) 
			inst.Physics:SetMotorVel(0,0,0) --3-17 ADDED TO FIX SOME WEIRD REVERSE MOMENTUM BUG
			inst.components.locomotor:TurnAround()
			inst.AnimState:PlayAnimation("dash_pivot_new")
			-- inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1, 0.5, 0.5, 1, 10, 0)
			inst.components.hitbox:MakeFX("slide1", -1.6, 0.0, 0.1, 1, 0.5, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			
			-- inst.components.hurtboxes:ShiftHurtboxes(-0.5, 0) --NOPE CANT USE THAT HERE
			
			inst.Physics:SetFriction(.8)
			-- inst.components.stats.ResetFriction()
			
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
			inst.AnimState:SetTime(1*FRAMES) --LOOKS BETTER ON DEDICATED SERVERS
			
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
				inst.sg:RemoveStateTag("noairmoving") --8-24
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
        
        events=
        {
            --EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        }, 
        
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
			
			-- inst.SoundEmitter:PlaySound("dontstarve/wilson/use_break")
			-- inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_linebreak")
			-- inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_straw")
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
			inst.Physics:SetActive(true) 
			inst.components.hurtboxes:SpawnPlayerbox(0, 0.7, 0.35, 0.7, 0)
        end,
        
		timeline =
        {
			TimeEvent(1*FRAMES, function(inst) 
				if not inst:HasTag("noledgeinvuln") then
					inst.sg:AddStateTag("intangible")
					-- inst.Physics:SetActive(false) --8-27 NEVERMIND, FIXED THIS UP IN THE EVENT HANDLER
					
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
			-- inst.AnimState:PlayAnimation("ledge_getup") --THIS ANIMATION LOOKS WAY TOO EARLY. LETS DELAY IT
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
				-- inst.Physics:SetActive(true)
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
			-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			inst.Physics:SetActive(true)
			inst.components.locomotor:Teleport(-0.5, -2, 0)
			inst.components.launchgravity:Launch(0, 0, 0)
			inst.AnimState:PlayAnimation("idle")
        end,
		
		timeline =
        {
			TimeEvent(1*FRAMES, function(inst)
				-- inst.AnimState:PlayAnimation("idle_air")
				inst.sg:GoToState("air_idle")
			end),
		},
    },
	
	
	State{
        name = "ledge_jump",
		tags = {"busy", "intangible"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_jump")
			inst.Physics:SetActive(false) --CAREFUL WITH THIS
        end,
		
		onexit = function(inst)
			-- inst.AnimState:PlayAnimation("duck_000")
			-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})
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
		tags = {"busy", "intangible", "nolandingstop"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_getup")
			-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			inst.Physics:SetActive(false) --CAREFUL WITH THIS
        end,
        
		timeline =
        {
			TimeEvent(6*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				inst.AnimState:PlayAnimation("rolling")
				inst.components.locomotor:RunForward() --11-11-17 MUCH CLEANER AND CONSISTANT METHOD FOR ROLLING
				inst.components.locomotor:Teleport(0, 0.1, 0) --MAYBE A TELEPORT IS NEEDED TO AVOID BUMPING INTO THE LIP OF THE LEDGE
				-- inst.components.locomotor:Motor(12, 0, 9) --THIS DIDNT MATCH UP WELL WITH THE ANIMATION. LETS TRY SOMETHING ELSE
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
			inst.Physics:SetActive(false) --CAREFUL WITH THIS
        end,
		
		onexit = function(inst)
			inst.Physics:SetActive(true) 
        end,
        
		timeline =
        {
			TimeEvent(5*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				-- inst.AnimState:PlayAnimation("dash_attack")
				inst.components.jumper:ScootForward(8)
			end),
			
			TimeEvent(8*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("woosh1", 0.2, 0.6, 0.2,   1.8, 2.5,   0.8, 4, 0)
				
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetDamage(4)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SetLingerFrames(2)
				
				-- inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				
				-- inst.components.hitbox:MakeDisjointed()
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
            --inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("duck_000")
			inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			--inst.components.locomotor:Clear()
			-- inst:ShowGiftItemPopUp(true)
			-- inst:ShowSelectScreenPopUp(true)
			-- inst:ShowWardrobePopUp(true)
			
			-- inst.components.giftreceiver:SelectOpen() --NOPE
			
        end,
        
		timeline =
        {
			-- TimeEvent(2*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("busy") 
			-- end),
		},
    },
	
	
	State{
        name = "highleap",
		tags = {"can_usmash", "can_upspec", "no_running", "no_blocking", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jump")
			inst.components.locomotor:Clear()
			
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
        end,
		
		onexit = function(inst)
            inst.components.stats.jumpspec = nil
        end,
        
		timeline =
        {
			TimeEvent(2*FRAMES, function(inst) --10-19-17 APPLY THIS TO EVERYONE LATER.
				inst.sg:RemoveStateTag("busy") 
				inst:AddTag("listenforfullhop") --11-10-20 MOVING THE LOCATION OF THIS TAG 
				inst.components.jumper:Jump(inst) --LETS BUMP THIS DOWN A LINE OR TWO
				inst.sg:RemoveStateTag("prejump")
				inst.sg:RemoveStateTag("can_usmash")
				--11-16, SHORT HOPS ARE DIFFICULT AS HEcc TO DO BUT IT ALL WORKS FOR NOW
				
				--10-20-17 A NEW IMPROVED ATTEMPT AT FULLHOP REGISTRATION.
				-- inst:AddTag("listenforfullhop")
				-- inst.sg:AddStateTag("prejump") --ON EXIT, IF PLAYER IS STILL IN PREJUMP, DONT EVEN LISTEN FOR FULLHOP
				inst:DoTaskInTime(2*FRAMES, function(inst) --NOW ALWAYS CHECKS IN 4 FRAMES
					inst.components.jumper:CheckForFullHop()
				end)
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0.1, 0.2)
				-- inst.components.jumper:CheckForFullHop()
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
	
	--11-28-20 CPU VERSION OF SINGLEJUMP
	State{
        name = "singlejump",
		tags = {"can_usmash", "can_upspec", "no_running", "no_blocking", "jumping", "busy", "savejump"}, --YOU KNOW WHAT, IM GONNA ADD BUSY AND SEE WHAT HAPPENS 1-3-17   --FIX IT SO ITS NOT BUSY
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jump") --jump
			inst.components.locomotor:Clear()
        end,
        
		timeline =
        {
			TimeEvent(1*FRAMES, function(inst) 
				inst.components.jumper:Jump(inst)
				-- inst.sg:RemoveStateTag("busy") 
				inst.sg:RemoveStateTag("can_usmash")
				
				--A NEW IMPROVED FULLHOP REGISTRATION.
				inst:AddTag("listenforfullhop")
				inst:DoTaskInTime(1*FRAMES, function(inst) --SPIDERS ARE SPECIAL, THEIR REGISTRY GETS CKECKED IN ONLY ONE FRAME
					inst.components.jumper:CheckForFullHop()
					inst.components.stats.jumpspec = "full"
				end)
			end),
			TimeEvent(2*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("savejump") --1-14-17 SO HE DOESNT INSTANTLY WASTE HIS DOUBLE JUMP
			end),
			
			TimeEvent(17*FRAMES, function(inst) 
				-- inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
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
			-- inst.AnimState:PlayAnimation("jump_maybe_001")
			-- inst.AnimState:PlayAnimation("jump")
			inst.AnimState:PlayAnimation("doublejump_001")
			-- inst.components.jumper:Jump()
			inst.components.jumper:DoubleJump(inst) --1-5 --DST- AND ALSO ADD INST TO ALL INSTANCES OF DOUBLEJUMP
			inst.components.hitbox:MakeFX("ground_bounce", 0, 1, -1, 1, 1, 0.8, 7, 1)
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			
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
        
        onenter = function(inst, hitstun, direction) --WHAAAAAAT? YOU CAN ONLY HAVE ONE MODIFIER??? UGH.
			
			--11-9-16 DISABLING FOR NOW. ITS A LITTLE ANOYING
			-- if inst.prefab ~= "wes" then
                -- local sound_name = inst.soundsname or inst.prefab
			    -- local sound_event = "dontstarve/characters/"..sound_name.."/hurt"
                -- inst.SoundEmitter:PlaySound(inst.hurtsoundoverride or sound_event, "yell")
            -- end
			
			inst.components.stats.norecovery = false
			--DST CHANGE!!!- CLIENTS HAVE VERSIONS WITH LESS EVENT HANDLERS AND NO ONENTER PARAMETERS. LET APPLY THAT TO OURS--
			
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
				--inst.sg:RemoveStateTag("busy")
				--inst.sg:GoToState("idle")
				--inst.sg:GoToState("nair")
				inst:PushEvent("swaphurtboxes", {preset = "hitstun2"})
				inst.AnimState:PlayAnimation("tumble_fall")
				inst.sg:AddStateTag("can_jump")
				inst.sg:RemoveStateTag("di_movement_only")
				inst.sg:RemoveStateTag("noairmoving")
				inst.sg:RemoveStateTag("reeling") --10-20-18 TREAT ALL PLAYER GRAVITIES THE SAME WHILE REELING!
				
				--3-15 GONNA TRY AND ADD SOMETHING THAT CANCELS OUT MOMENTUM SO YOU ARENT FORCED TO JUMP TO SURVIVE
				inst.components.jumper:AirStall(2, 1)
			end)
			
			inst.task_attackstun = inst:DoTaskInTime((attack_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:AddStateTag("can_attack")
				-- inst.AnimState:SetMultColour(1,0.5,1,1)
			end)
			inst.task_dodgestun = inst:DoTaskInTime((dodge_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:RemoveStateTag("busy")
				-- inst.AnimState:SetMultColour(1,1,1,1)
				-- inst.sg:RemoveStateTag("di_movement_only")
				
			end)
        end,

        onexit = function(inst)
			if ISGAMEDST and TheWorld.ismastersim then --11-26-17
				inst.task_hitstun:Cancel()
				inst.task_attackstun:Cancel()
				inst.task_dodgestun:Cancel()
			end
			-- inst.AnimState:SetMultColour(1,1,1,1)
        end,
	
        
        timeline =
        {
			TimeEvent(6*FRAMES, function(inst) 
				-- inst:PushEvent("swaphurtboxes", {preset = "hitstun1"})
				-- inst.SoundEmitter:PlaySound("shut_ur_mouf") --10-26-16 DARN. I TRIED
				inst.SoundEmitter:KillSound("yell") --10-26-16  WOA!!! IT WORKS!!!... A LITTLE TOO WELL. NOW IT JUST SOUNDS OFF --OKAY NEVERMIND THIS SOUNDS WEIRD IM DISABLING IT
			end),
			
        },
		
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
            --inst.AnimState:SetMultColour(1,1,1,0.2)
			--inst.AnimState:PlayAnimation("wakeup")
			inst.AnimState:PlayAnimation("clumsy_land")  --clumsy_land_004
			inst.components.hitbox:MakeFX("ground_bounce", -0.5, 0.1, -1, 1.5, 1.5, 0.8, 10, 0)
			inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/explode")
			inst:PushEvent("swaphurtboxes", {preset = "grounded"})
        end,

        onexit = function(inst)
            --inst.components.locomotor:Stop()
            --inst.components.locomotor:EnableGroundSpeedMultiplier(true)
			--inst.components.blocker:StopConsuming()
			--inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline =
        {
            --local tumble_lock = inst.components.hitbox:GetTumbleTime()
			--print(tumble_lock)
			--TimeEvent((inst.components.hitbox:GetTumbleTime())*FRAMES, function(inst) 
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0, 0.5)
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0, -0.5)
				inst.sg:GoToState("grounded") --9-9 MOVING IT DOWN HERE TO FIX GROUNDED GETUP LAG
			end),
			
			-- TimeEvent(20*FRAMES, function(inst) --9-9 THIS IS THE WRONG NUMBER YOU IDIOT! YOU FORGOT 
				-- --inst.sg:RemoveStateTag("intangible")
				-- --inst.AnimState:SetMultColour(1,1,1,1)
				-- --inst.sg:GoToState("getup")
				-- inst.sg:GoToState("grounded")
			-- end),
			
            TimeEvent(14*FRAMES, --9-9 THIS IS THE WRONG NUMBER YOU IDIOT! YOU FORGOT TO HALF IT --26
				function(inst)
				--CHECK FOR IF STILL HOLDING SHEILD
                    inst.sg:RemoveStateTag("busy")
					--inst.sg:GoToState("idle")
				end),
        },
        
    },
	
	State{
        name = "grounded",
        tags = {"busy", "prone", "grounded", "nogetup"},  --9-9 WHAT DOES PRONE DO AGAIN? I FORGET
        
        onenter = function(inst, target)
            --inst.AnimState:SetMultColour(1,1,1,0.2)
			--inst.AnimState:PlayAnimation("pickup")
			inst.AnimState:PlayAnimation("grounded")
			inst:PushEvent("swaphurtboxes", {preset = "grounded"})
        end,
        
        timeline =
        {
		
			TimeEvent(2*FRAMES, function(inst)  --5
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
            --inst.AnimState:SetMultColour(1,1,1,0.2)
			--inst.AnimState:PlayAnimation("pickup")
			inst.AnimState:PlayAnimation("getup1_000")
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
        name = "getup_attack",
        tags = {"attack", "busy", "intangible", "grounded"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("getup_attack_001")
            
        end,
		
		onexit = function(inst)

        end,
        
        timeline=
        {
			TimeEvent(5*FRAMES, function(inst)
				-- inst.components.hitbox:SetAngle(80)
				-- inst.components.hitbox:SetBaseKnockback(40)
				-- inst.components.hitbox:SetGrowth(70)
				-- inst.components.hitbox:SetDamage(4)
				--12-15-18 -WOW, EVERYTHING ABOVE HAS BEEN REALLY WRONG FOR A REALLY LONG TIME
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(90)
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SetSize(0.8, 0.5)
				
				inst.components.hitbox:SpawnHitbox(1, 0.2, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(0.8, 0.5)
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(-1, 0.2, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			end),
			
            TimeEvent(17*FRAMES, function(inst)  --17?? THAT WAS WAY TOO FAST
			-- inst.sg:RemoveStateTag("attack") 
			-- inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			
			end),
        },
        
    },
	
	
	State{
        name = "tech_getup", 
        tags = {"busy", "intangible", "teching"},
        
        onenter = function(inst, target)
            inst.AnimState:SetMultColour(1,1,1,0.3)
			--inst.AnimState:PlayAnimation("pickup")
			inst.AnimState:PlayAnimation("landing") --tech0_003
			--inst:AddTag("grounded")
			inst.components.hitbox:MakeFX("slide1", -0.2, 0, 1, 1.5, 1.5, 1, 10, 0)
			inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        end,

        onexit = function(inst)
			inst.AnimState:SetMultColour(1,1,1,1)
			--inst:RemoveTag("grounded")
        end,
        
        timeline =
        {
			TimeEvent(10*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst.AnimState:SetMultColour(1,1,1,1)
				inst.sg:GoToState("idle")
			end),
        },
        
    },
	
	
	-- State{
        -- name = "tech_forward_roll", 
        -- tags = {"busy", "intangible", "teching"},
        
        -- onenter = function(inst, target)
            -- inst.AnimState:SetMultColour(1,1,1,0.5)
			-- --inst.AnimState:PlayAnimation("pickaxe_pre")
			-- inst.AnimState:PlayAnimation("rolling")
			-- inst:AddTag("rolling")
        -- end,

        -- onexit = function(inst)
			-- inst.AnimState:SetMultColour(1,1,1,1)
			-- inst:RemoveTag("rolling")
        -- end,
        
        -- timeline =
        -- {
		   
			 -- TimeEvent(2*FRAMES, function(inst)
				-- inst:AddTag("rolling")
				-- inst.sg:AddStateTag("intangible")
		     -- end),
		   
		   
		   -- TimeEvent(12*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("intangible")
				-- inst.AnimState:SetMultColour(1,1,1,1)
				
			-- end),
			-- TimeEvent(12*FRAMES, function(inst) 
				-- inst:RemoveTag("rolling")
				
			-- end),
            
			-- TimeEvent(15*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("busy")
				-- inst.sg:GoToState("idle")
			-- end),
		-- },
        
    -- },
	
	
	--NEW TECH-ROLLS THAT USE THE UPDATED FUNCTS
	State{
        name = "tech_forward_roll", 
        tags = {"busy", "intangible", "teching"},
        
        onenter = function(inst, target)
			inst.components.hitbox:Blink(inst, 2,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			inst.AnimState:PlayAnimation("rolling")
			inst.AnimState:SetTime(2*FRAMES)
			-- inst:AddTag("rolling")
			
			inst.sg:AddStateTag("intangible")
				inst.components.locomotor:Motor(12, 0, 7)
				inst.components.hitbox:MakeFX("slide1", -0.8, 0, 1, 1.5, 1.5, 1, 10, 0)
        end,

        onexit = function(inst)
			inst.components.locomotor:Clear()
			if inst.motortask then
				inst.motortask:Cancel() --I SHOULD REALLY SET THESE UP TO CANCEL THEMSELVES ON STATE CHANGE, ITS GONNA CONFUSE MODDERS --TODOLIST
			end
        end,
			
        
        timeline =
        {
		   
			TimeEvent(2*FRAMES, function(inst)
				-- inst.sg:AddStateTag("intangible")
				-- inst.components.locomotor:Motor(14, 0, 7)
				-- inst.components.hitbox:MakeFX("slide1", -0.8, 0, 1, 1.5, 1.5, 1, 10, 0)
				inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
			end),
		   
		   
		    TimeEvent(12*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst.AnimState:SetMultColour(1,1,1,1)
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
				
				inst.components.locomotor:Stop()
				inst.components.jumper:ScootForward(7)
				
			end),
            
			TimeEvent(18*FRAMES, function(inst) --15
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
		},
        
    },
	
	
	
	State{
        name = "tech_backward_roll", 
        tags = {"busy", "intangible", "teching"},
        
        onenter = function(inst, target)
			inst.components.hitbox:Blink(inst, 2,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			inst.AnimState:PlayAnimation("backward_tech")
			-- inst.AnimState:SetTime(2*FRAMES)
			-- inst:AddTag("rolling")
			
			inst.sg:AddStateTag("intangible")
				-- inst.components.locomotor:Motor(12, 0, 7)
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
		   
			TimeEvent(2*FRAMES, function(inst)
				inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
			end),
			
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
				inst.AnimState:SetMultColour(1,1,1,1)
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
				
				inst.components.locomotor:Stop()
				inst.components.jumper:ScootForward(-7)
				-- inst.AnimState:SetTime(22*FRAMES)
				-- inst.AnimState:PlayAnimation("tech0_003")
				-- inst.AnimState:SetTime(2*FRAMES)
				
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
				-- inst.sg:GoToState("idle") --AH AH! THIS CANCELS THE BUFFERED KEY. LETS PUSH IT BACK A FRAME TO GIVE THE BUFFER ONE FRAME TO SQUEEZE AN ACTION IN 3-27-19
				--ACTUALLY... LETS DO SOMETHING... NEW..
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
            --inst.AnimState:PlayAnimation("wakeup")
			inst.AnimState:PlayAnimation("clumsy_land")
			inst.components.hitbox:MakeFX("ground_bounce", -0.5, 0.1, -1, 2.5, 2.5, 0.8, 10, 0)
			inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/shotexplo")
			inst:PushEvent("swaphurtboxes", {preset = "grounded"})

			--inst:DoTaskInTime(4.7, function(inst) inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt", "bodyfall") end )
        end,
        
		timeline =
        {
			TimeEvent(30*FRAMES, function(inst) 
				inst.sg:GoToState("getup")  
			end),
			------------------------MAKE BOUNCE RINGS SPAWN IT'LL BE SUPER COOL --------------------------- TODOLIST
		},

    },

	
	State{
        name = "block_startup", 
        tags = {"busy", "tryingtoblock", "blocking", "can_parry", "canoos"},
        
        onenter = function(inst, target)
			--inst.AnimState:PlayAnimation("build_pre")
			inst.AnimState:PlayAnimation("block_startup")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			
			--inst.AnimState:SetMultColour(0,1,1,1)
        end,

        onexit = function(inst)
            --inst.components.locomotor:Stop()
            --inst.components.locomotor:EnableGroundSpeedMultiplier(true)
			--inst.components.blocker:StopConsuming()
			--inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline =
        {
			
			--11-17, CHANGING TO FRAME 1 ACTIVATION TO MATCH SMASH GAMES
			-- TimeEvent(1*FRAMES, function(inst) 
				-- inst.sg:AddStateTag("can_parry")
				-- inst.sg:AddStateTag("blocking")
				-- --inst.sg:RemoveStateTag("intangible")
				-- --inst.AnimState:SetMultColour(1,1,1,1)
				-- inst.AnimState:SetMultColour(1,1,0,1)
			-- end),
			
            TimeEvent(3*FRAMES,
				function(inst)
                    inst.sg:RemoveStateTag("busy")
					inst.sg:GoToState("block")
				end),
        },
    },
	
	State{
        name = "block",  
        tags = {"canrotate", "blocking", "tryingtoblock", "canoos", "no_running"},   --12-30 ADDED NO_RUNNING. SEEMS TO WORK WELL
        
        onenter = function(inst, target)
            --inst.components.locomotor:Stop()
            --inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            --inst.components.combat:StartAttack()
            -- inst.AnimState:PlayAnimation("give")
			
			--inst.AnimState:PlayAnimation("build_pre")
			-- inst.AnimState:PlayAnimation("idle")
			inst.AnimState:PlayAnimation("block")
			
			-- inst.components.blocker:StartConsuming()
			
            --inst.sg.statemem.target = target
        end,

        onexit = function(inst)
            --inst.components.locomotor:Stop()
            --inst.components.locomotor:EnableGroundSpeedMultiplier(true)
			--inst.components.blocker:StopConsuming()
			--inst.components.blocker.consuming = false
			--inst.AnimState:SetMultColour(1,1,1,1)  --ILL NEED TO FIX THIS EVENTUALLY
        end,
        
        timeline =
        {
            --TimeEvent(0*FRAMES, function(inst) self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0) end),
			
            -- --TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Jump")) end),
            -- TimeEvent(8*FRAMES, function(inst) inst.Physics:SetMotorVelOverride(20,0,0) end),
           -- -- TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
            -- TimeEvent(19*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
			
            TimeEvent(50*FRAMES,
				function(inst)
                    --inst.Physics:ClearMotorVelOverride()
					--inst.components.locomotor:Stop()
				end),
        },
        
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
			-- inst.components.hitbox:MakeFX("shockwave_parry", 0.5, 1.5, 1, 1.5, 1, 1, 8)
			inst.components.hitbox:MakeFX("shockwave_parry", 0.5, 1.5, 1, 1, 1.8, 1, 12, 1)
			inst.AnimState:PlayAnimation("block")
			--inst.AnimState:SetMultColour(0,1,1,1)
			inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_forcefield_armour_dull")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_unbreakable")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")
			inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
			
			inst.sg:SetTimeout(timeout)
        end,

        onexit = function(inst)
			--inst.components.blocker.consuming = false
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
		
		ontimeout = function(inst)
			inst.sg:RemoveStateTag("busy")
			inst.sg:AddStateTag("canoos")
        end,
		
    },
	
	--3-23, ITS ABOUT TIME I RE-DID THIS AWEFUL STATE.
	-- State{
        -- name = "block_stunned",
        -- tags = {"blocking", "tryingtoblock", "busy", "block_stunned"},  
        
        -- onenter = function(inst, target)
			-- inst.AnimState:PlayAnimation("blockstunned_long")
			-- inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_dull")
			-- --inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")  --MAYBE FOR WEAK ONES
			-- --inst.SoundEmitter:PlaySound("dontstarve/common/place_ground")
			-- --inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_unbreakable")
			-- --inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_stone")  --SMALL DRUM SOUND.MAYBE GOOD FOR HITS TOO -NAH
			-- --inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")
		
			
			-- --dontstarve/common/teleportworm/travel
        -- end,

        
        -- timeline =
        -- {
            -- --TimeEvent(0*FRAMES, function(inst) self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0) end),
			
           -- -- -- TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
            
			-- TimeEvent(50*FRAMES, function(inst)   --FOR THE LOVE OF GOD FIX THIS ALREADY
				-- if inst:HasTag("wantstoblock") then
					-- inst.sg:GoToState("block_unstunned")
				-- else
					-- inst.sg:GoToState("block_stop")
				-- end
			-- end),
			
    
        -- },
    -- },
	
	
	--3-22 NEW VERSION
	State{
        name = "block_stunned",
        tags = {"blocking", "tryingtoblock", "busy", "block_stunned"},  
        
        onenter = function(inst, timeout)
			inst.AnimState:PlayAnimation("blockstunned") --blockstunned_long
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
	
	
	
	--!!!!!! 10-16-16  OKAY, THIS CAN'T BE RIGHT. I THINK I MESSED UP SHIELDS. THESE EXTRA TWO BUSY FRAMES CANNOT BE RIGHT. LOOK INTO THIS!!!!! --TODOLIST --THEFIXLIST
	State{
        name = "block_unstunned",
        tags = {"blocking", "tryingtoblock", "busy"},  
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("blockstunned_resume")
			--inst.AnimState:SetMultColour(1,1,0,1)
			
		if inst:HasTag("wantstoblock") then --1-20-17 SO THIS STATE IS JUST POINTLESS NOW I GUESS?
				inst.sg:GoToState("block")
			else
				inst.sg:GoToState("block_stop")
			end
        end,

        
        timeline =
        {
            --TimeEvent(0*FRAMES, function(inst) self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0) end),
			
           -- -- TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
            
			TimeEvent(2*FRAMES, function(inst) --8-19 HOLD ON... THIS CAN'T BE RIGHT, CAN IT? --CHANGING THE 2 FRAMES TO 0 FRAMES --IT DIDN'T SEEM TO CHANGE ANYTHING?... PUTTING IT BACK TO 2 I GUESS
				-- if inst:HasTag("wantstoblock") then --1-20-17 NAH, NAH, I GOTTA GET RID OF THIS. MOVING THIS UP TO ONENTER.
					-- inst.sg:GoToState("block")
				-- else
					-- inst.sg:GoToState("block_stop")
				-- end
			end),
			
    
        },
    },
	
	State{
        name = "block_stop",  
        tags = {"tryingtoblock", "busy"},  --"blocking", 
        
        onenter = function(inst, target)
			-- inst.AnimState:PlayAnimation("run_pst")
			inst.AnimState:PlayAnimation("block_drop")
        end,
		
		onupdate = function(inst)
			--CHEAP HOTFIX TO ENSURE THIS STATE DOESN'T ADD EXTRA FRAMES TO THE ENDLAG
        end,
		
        timeline =
        {
			TimeEvent(3*FRAMES, function(inst) --6
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	
	State{
        name = "brokegaurd",  
        tags = {"busy", "intangible", "dizzy", "ignoreglow", "noairmoving"},
        
		
		-- onupdate = function(inst)
			-- --YOU SHOULD PROBABLY REMOVE THIS ONCE HITLAG IS FIXED
        -- end,
		
        onenter = function(inst, target)

			inst.AnimState:PlayAnimation("tumble_up_000")
			inst.SoundEmitter:PlaySound("dontstarve/common/destroy_magic")
			-- inst.components.launchgravity:Launch(-4, 20) --DOESNT HAPPEN DURING HITLAG BECAUSE PHYSICS IS DISABLED
			inst.AnimState:SetAddColour(1,1,0,0.6)
        end,

        onexit = function(inst)
			--inst.AnimState:SetAddColour(0,0,0,0)
        end,
        
        timeline =
        {
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.launchgravity:Launch(0, 20)
				inst.AnimState:SetAddColour(0,0,0,0)
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
				--inst.AnimState:PlayAnimation("wakeup")
				inst.sg:RemoveStateTag("intangible")
			end),
			
			
            TimeEvent(150*FRAMES,
				function(inst)
                    --inst.Physics:ClearMotorVelOverride()
					--inst.components.locomotor:Stop()
					--inst.sg:GoToState("idle") --11-17 GONNA NEED THIS LATER
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
			-- inst.AnimState:PlayAnimation("run_pst")
			inst.AnimState:PlayAnimation("getup1_000")
        end,
		
		onexit = function(inst)
        end,
        timeline =
        {
			--TimeEvent(1*FRAMES, function(inst) inst.sg:RemoveStateTag("blocking") end),
            
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

			--inst.AnimState:PlayAnimation("build_pre")
			inst.AnimState:PlayAnimation("spotdodge")
        end,

        onexit = function(inst)
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline =
        {
            TimeEvent(1*FRAMES, function(inst) 
				inst.sg:AddStateTag("intangible")
				inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst.AnimState:SetMultColour(1,1,1,1)
			end),
			
            TimeEvent(14*FRAMES,
				function(inst)
				--CHECK FOR IF STILL HOLDING SHEILD
                    inst.sg:RemoveStateTag("busy")
					inst.sg:GoToState("idle")
				end),
        },
        
    },
	
	State{
        name = "roll_forward", 
        tags = {"dodging", "busy", "nopredict"},  
        
        onenter = function(inst, target)
            -- inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
			--inst.AnimState:PlayAnimation("chop_pre")
			inst.AnimState:PlayAnimation("rolling")
			inst.components.hitbox:Blink(inst, 4,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			
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
            --TimeEvent(0*FRAMES, function(inst) self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0) end),
			
           -- -- TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
		   
			TimeEvent(1*FRAMES, function(inst)
				-- inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
				inst.sg:AddStateTag("intangible")
				-- inst.task_1 = inst:DoPeriodicTask(0.1, function(inst)
					-- inst.Physics:SetMotorVel(14, 0, 0) --10
				-- end)
		    end),
		      
			  
			 TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0, -0.2,   1.0, 1.0,   0.6, 8, 0)
				--inst:AddTag("rolling")
				
				-- inst.task_1 = inst:DoPeriodicTask(0.1, function(inst)
						-- inst.Physics:SetMotorVel(10, 0, 0)
					-- end)
				--end
				
				-- inst.sg:AddStateTag("intangible")
				--inst:Sleep(3)
				
				-- inst:DoTaskInTime(3, function(inst)
							-- inst.task:Cancel()
						-- end)
		     end),
		   
		   --WHY IS THIS EVEN HERE NOW???
		   TimeEvent(3*FRAMES, function(inst) 
			
				-- while inst:HasTag("rolling") do
					-- inst.Physics:SetMotorVel(10, 0, 0)
				-- end
				-- inst:StartThread(function()
					-- while inst:HasTag("rolling") do
						-- --Sleep(5)
						-- print "something"
					-- end
				-- end)
				
				--TRIED TO DO SOME STUFF BUT NOTHIN 10-20
				--inst:DoPeriodicTask(0.1, function()
				--rolley = inst:DoPeriodicTask(0.1, function()
				--11-20 WOW I MADE A HUGE MESS DOWN THERE
				-- inst.task_1 = inst:DoPeriodicTask(0.1, function(inst)
					-- --if inst:HasTag("rolling") then
						-- inst.Physics:SetMotorVel(10, 0, 0)
						-- print("GAAAAD DANIT")
						
						-- -- inst:DoTaskInTime(3, function(inst)
							-- -- -- if inst.task then
								-- -- print("END TASK NOW")
								-- -- -- inst.task:Cancel()
								-- -- -- inst.task = nil
							-- -- -- end
							-- -- --inst:CancelAllPendingTasks()
							-- -- inst.Physics:SetMotorVel(0, 0, 0)
						
						-- -- end)
						-- --inst.task:Sleep(10)
						-- inst:DoTaskInTime(2, function(inst)
							-- --inst.task_1:Cancel()
							-- print("GAAAAD DANIT")
						-- end)
						-- --inst.task:Cancel()
					-- --end
					
					-- -- if self.task then
						-- -- print("END TASK NOW")
						-- -- self.task:Cancel()
						-- -- self.task = nil
					-- -- end
				-- end)
				 
			end),
			
			TimeEvent(4*FRAMES, function(inst)
				inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
		    end),
			
			TimeEvent(6*FRAMES, function(inst) --7
				inst.task_1:Cancel()
			end),
            
			TimeEvent(8*FRAMES, function(inst) 
				-- inst.task_1:Cancel()
				inst.sg:RemoveStateTag("intangible")
				--inst:RemoveTag("rolling")
				--inst.components.locomotor:TurnAround()
				inst.components.hitbox:MakeFX("slide1", 1.5, 0, -0.2,   -0.8, 0.8,   0.6, 8, 0)
				inst.AnimState:SetMultColour(1,1,1,1)
			end),
			
			TimeEvent(9*FRAMES, function(inst) --10
				inst.components.locomotor:Stop()
				inst.components.jumper:ScootForward(10)
			end),
			
			TimeEvent(13*FRAMES, function(inst) 

				-- inst.components.locomotor:TurnAround()

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
			-- inst.AnimState:PlayAnimation("spotdodge_air") --OK BUT THIS LOOKS PRETTY UGLY
			inst.AnimState:PlayAnimation("airdodge")
			inst.components.launchgravity:SetLandingLag(10)
        end,

        onexit = function(inst)
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline =
        {		
		   TimeEvent(1*FRAMES, function(inst) 
				inst.sg:AddStateTag("intangible")
				inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
			end),
            
			TimeEvent(15*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst.AnimState:SetMultColour(1,1,1,1)
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

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true) --THE HECK IS THIS HERE FOR?
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
			inst.SoundEmitter:PlaySound("smash_sounds/grab/grab1") --12-16-18 -NEW GRAB SOUND
			inst.components.stats.opponent.Physics:SetActive(false)
			inst.Physics:Stop()
        end,
		
		onexit = function(inst)
			if not inst.components.stats:GetOpponent() then return end
			inst.components.stats.opponent.Physics:SetActive(true)
			--1-23-21 SO IF THIS HAPPENS TO AN OPPONENT WHO HAS JUST LOGGED OUT (OR MAXCLONE THAT JUST DESPAWNED) THIS WILL INSTANTLY CRASH DUE TO STALE REFERENCE...
			--THIS COULD GET COMPLICATED. BUT WE PROBABLY SHOULD ADRESS THIS CORRECTLY.
			--1-30-21 ALRIGHT, I HANDLED IT A BIT DIFFERENTLY. WHEN SOMEONE IS DESPAWNED, THE GAME CHECKS FOR THE "HANDLING_OPPONENT" TAG AND TAKES CARE OF THINGS
		end,
        
        timeline =
        {
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
				--if not inst.components.stats:GetOpponent(true) then return end
				-- inst.components.stats.opponent.sg:GoToState("rebound", 10)
				inst.components.stats.opponent:PushEvent("clank", {rebound = 10})
			end),
			EventHandler("end_grab", function(inst)
				-- inst.sg:GoToState("rebound", 10)
				inst:PushEvent("clank", {rebound = 10})
			end),
        },
    },
	
	
	--4-14-20 TESTING FOR THE MAJOR TIMELINE SCRAMBLE BUG
	State{
        name = "testgrab1",
        tags = {"busy", "grabbing"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("grabbing")
			inst.SoundEmitter:PlaySound("smash_sounds/grab/grab1") --12-16-18 -NEW GRAB SOUND
			--inst.components.stats.opponent.Physics:SetActive(false)
        end,
		
		onexit = function(inst)
			--inst.components.stats.opponent.Physics:SetActive(true)
		end,
        
		-- onupdate = function(inst)
			
		-- end,
		
        timeline =
        {
			
			TimeEvent(1*FRAMES, function(inst)
                inst.components.talker:Say("testgrab1 - 1")
			end),
			
			TimeEvent(5*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 5") end),
			TimeEvent(10*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 10") end),
			TimeEvent(15*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 15") end),
			TimeEvent(20*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 20") end),
			TimeEvent(25*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 25") end),
			TimeEvent(30*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 30") end),
			TimeEvent(35*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 35") end),
			TimeEvent(40*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 40") end),
			TimeEvent(45*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 45") end),
			TimeEvent(50*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 50") end),
			TimeEvent(55*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 55") end),
			
            TimeEvent(60*FRAMES, function(inst)
                inst.sg:GoToState("testthrow1")
			end),
        },
		 events=
        {
            EventHandler("forward_key", function(inst) 
				inst.sg:GoToState("testthrow1")
			end),
			EventHandler("down", function(inst) 
				inst.sg:GoToState("fthrow")
			end),
        },
    },
	
	
	
	State{
        name = "testthrow1",
        tags = {"attack", "busy"},
        
        onenter = function(inst, target)
			inst.components.stats:GetOpponent()
			inst.AnimState:PlayAnimation("throwing_000")
			inst.AnimState:Resume()
        end,
		
		onupdate = function(inst)
			
		end,
        
        timeline =
        {
			TimeEvent(5*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 5") end),
			TimeEvent(10*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 10") end),
			TimeEvent(15*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 15") end),
			TimeEvent(20*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 20") end),
			TimeEvent(25*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 25") end),
			TimeEvent(30*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 30") end),
			TimeEvent(35*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 35") end),
			TimeEvent(40*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 40") end),
			TimeEvent(45*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 45") end),
			TimeEvent(50*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 50") end),
			TimeEvent(55*FRAMES, function(inst) inst.components.talker:Say("testgrab1 - 55") end),
			
			
			
			TimeEvent(8*FRAMES, function(inst)   --16
				inst.components.stats:GetOpponent()
				--inst.components.stats.opponent.AnimState:PlayAnimation("clumsy_land")
			end),
			
			--WAIT.. WTF IS THIS?? WHY DO I HAVE A FRAME 0 TIME EVENT?
			-- TimeEvent(0*FRAMES, function(inst)   --16
				-- local pos = Vector3(inst.Transform:GetWorldPosition())
				-- inst.components.stats.opponent.Transform:SetPosition((pos.x), (pos.y + 1.5), (pos.z))
				-- inst.components.stats.opponent.sg:GoToState("thrown")
				-- inst.components.stats.opponent.components.launchgravity:Launch(-2, -4, 0)
			-- end),

			
			
			TimeEvent(9*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetAngle(60) 
				inst.components.hitbox:SetBaseKnockback(80)
				inst.components.hitbox:SetGrowth(60)

				inst.components.hitbox:SetSize(2)
				inst.components.hitbox:SetLingerFrames(2)
				
				
				inst.components.hitbox:SpawnHitbox(2, 0, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			TimeEvent(60*FRAMES, function(inst)
				inst.sg:GoToState("idle") 
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
		
		onexit = function(inst) --12-30-21 GRAB CANCELS NEED TO GO BOTH WAYS!
			if inst.components.stats.opponent and inst.components.stats.opponent:IsValid() then
				inst.components.stats.opponent:PushEvent("end_grab")
			end
		end,
		
		timeline =
        {
            TimeEvent(90*FRAMES, function(inst) --1-3-22 NEW SAFTEY NET AUTO REFRESHES THEM AFTER 3 SECONDS
				inst.sg:GoToState("rebound", 10) --SHOULD BE FINE AS LONG AS NO ONE HAS A THROW ANIMATION LONGER THAN 30 FRAMES
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
			if anim then
				inst.AnimState:PlayAnimation(anim)
			end
        end,
    },
	
	
	
	State{
        name = "fthrow",
        tags = {"attack", "busy", "handling_opponent"},
        
        onenter = function(inst, target)
			-- inst.components.stats:GetOpponent()
			if not inst.components.stats:GetOpponent(true) then return end
			inst.AnimState:PlayAnimation("throwing_000")
			inst.AnimState:Resume()
        end,
        
        timeline =
        {
            
			TimeEvent(8*FRAMES, function(inst)   --16
				inst.components.stats:GetOpponent(true)
				inst.components.stats.opponent.AnimState:PlayAnimation("clumsy_land")
			end),
			
			TimeEvent(0*FRAMES, function(inst)   --16
				local pos = Vector3(inst.Transform:GetWorldPosition())
				inst.components.stats.opponent.Transform:SetPosition((pos.x), (pos.y + 1.5), (pos.z))  -- + self.zoffset
				--self.inst.AnimState:Resume()
				--self.inst.sg:GoToState("throw")
				inst.components.stats.opponent.sg:GoToState("thrown")
				inst.components.stats.opponent.components.launchgravity:Launch(-2, -4, 0)
			end),

			
			
			TimeEvent(9*FRAMES, function(inst)  
				--10-25-17 LETS MAKE A BETTER THROW. THIS ONES KINDA LIKE SAMUS'S
				-- inst.components.hitbox:SetDamage(6)
				-- inst.components.hitbox:SetAngle(80) 
				-- inst.components.hitbox:SetBaseKnockback(80)
				-- inst.components.hitbox:SetGrowth(50)
				
				inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetAngle(60) 
				inst.components.hitbox:SetBaseKnockback(80)
				inst.components.hitbox:SetGrowth(60)

				inst.components.hitbox:SetSize(2)
				inst.components.hitbox:SetLingerFrames(2)
				
				
				inst.components.hitbox:SpawnHitbox(2, 0, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			TimeEvent(19*FRAMES, function(inst)   --30
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
			
			inst.components.stats:GetOpponent(true)
			inst.AnimState:PlayAnimation("throwing_000")
			inst.AnimState:Resume()
			
			inst.components.locomotor:TurnAround()
			inst.components.stats.opponent.components.locomotor:TurnAround()
			inst.components.jumper:ScootForward(-6)
			inst:AddTag("refresh_softpush") --3-2-17 HOPEFULLY FIXES THE WEIRD LEDGETHROWING THING --IT DID
        end,
        
        timeline =
        {
			TimeEvent(8*FRAMES, function(inst)
				inst.components.stats:GetOpponent(true)
				inst.components.stats.opponent.AnimState:PlayAnimation("clumsy_land")
			end),
			
			TimeEvent(0*FRAMES, function(inst)
				local pos = Vector3(inst.Transform:GetWorldPosition())
				inst.components.stats.opponent.Transform:SetPosition((pos.x), (pos.y + 1.5), (pos.z))  -- + self.zoffset
				--self.inst.AnimState:Resume()
				--self.inst.sg:GoToState("throw")
				inst.components.stats.opponent.sg:GoToState("thrown")
				inst.components.stats.opponent.components.launchgravity:Launch(-2, -4, 0)
			end),

			
			
			TimeEvent(9*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(98)
				inst.components.hitbox:SetGrowth(55)
				inst.components.hitbox:SetSize(2)
				inst.components.hitbox:SetLingerFrames(2)
				
				
				inst.components.hitbox:SpawnHitbox(2, 0, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			TimeEvent(20*FRAMES, function(inst)
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
        tags = {"busy", "helpless", "ll_medium", "can_grab_ledge"},  
        
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
				-- inst.AnimState:SetMultColour(0.5,0.5,0.5,1)
				
			local damage_modifier = (6.6+rebound*0.558) / 2
			
			inst.task_rebound = inst:DoTaskInTime((damage_modifier*FRAMES), function(inst) --12-4
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
        tags = {"attack", "notalking", "busy", "ll_medium", "autocancel"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("fair")
			-- inst.AnimState:PlayAnimation("wickerfair")
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			-- inst.components.hurtboxes:ShiftHurtboxes(0, 0.6) --THIS MAKES IT LOOK WEIRD. FIX IT LATER. --THEFIXLIST
			inst.components.launchgravity:SetLandingLag(7)
		end,
        
        timeline=
        {
            --TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
			
			TimeEvent(1*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("autocancel") 
				inst.components.hurtboxes:ShiftHurtboxes(0, 0.5)
			end),
			
			TimeEvent(5*FRAMES, function(inst) --3
				inst.components.hitbox:SetKnockback(9, 12)
				inst.components.hitbox:SetDamage(5) --10
				-- inst.components.hitbox:SetAngle(55) --SAKURAAAIIII!
				inst.components.hitbox:SetAngle(45) --30 2-7-17
				-- inst.components.hitbox:SetBaseKnockback(98)
				inst.components.hitbox:SetBaseKnockback(70) --80 2-7-17
				inst.components.hitbox:SetGrowth(35)
				inst.components.hitbox:SetHitLag(0.3)
				inst.components.hitbox:SetCamShake(0.3)
				inst.components.hitbox:SetHighlight(0.3)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.7) --0.8
				inst.components.hitbox:SetLingerFrames(2) --2
				
				inst.components.hitbox:MakeDisjointed()
				-- inst.components.hitbox:SpawnHitbox(1, 2.3, 0) 
				-- inst.components.hitbox:SpawnHitbox(0.9, 2.3, 0)
				inst.components.hitbox:SpawnHitbox(0.6, 2.3, 0) --11-1-17 IM MOVING THIS BACK QUITE A BIT
				--inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/swipe")
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				
				-- inst.components.hitbox:SetSize(0.5)
				-- inst.components.hitbox:SetLingerFrames(5)
				-- inst.components.hitbox:SpawnHitbox(1, 1, 0) 
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				-- inst.components.hitbox:SetKnockback(12, 9)
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetSize(1)

				inst.components.hitbox:SetAngle(270)
				
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.35, 1, 0) 
				
				
				inst.components.hurtboxes:ShiftHurtboxes(0, 0.5)
				
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "fair"})
				
				--inst.components.hitbox:SetKnockback(10, 8)
				inst.components.hitbox:SetKnockback(0, -25)
				inst.components.hitbox:SetDamage(8) --14
				inst.components.hitbox:SetAngle(270) --SAKURAAAIIII!
				inst.components.hitbox:SetBaseKnockback(65) --80 --98
				inst.components.hitbox:SetGrowth(35)
				inst.components.hitbox:SetSize(0.8)
				inst.components.hitbox:SetHitLag(0.4)
				inst.components.hitbox:SetCamShake(0.5)
				inst.components.hitbox:SetHighlight(0.5)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetLingerFrames(2)--3
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.0, -0.5, 0) ---0.5
				--inst.components.hitbox:ContinueHitbox(1.5, -1.5, 0) 
				
				--11-11-17 I WANT ONE MORE SET FOR SOURSPOTS COVERING CLOSE TO HIS LANDINGS
				inst.components.hitbox:SetDamage(5) 
				inst.components.hitbox:SetAngle(45) 
				inst.components.hitbox:SetBaseKnockback(70)
				inst.components.hitbox:SetGrowth(35)
				inst.components.hitbox:SetSize(0.4)
				inst.components.hitbox:SetLingerFrames(4)
				inst.components.hitbox:SpawnHitbox(0.4, 0, 0)
				
				
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(4) --14
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetSize(0.4)
				
				inst.components.hitbox:SetLingerFrames(2)--3
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.0, -0.5, 0) ---0.5
				--inst.components.hitbox:ContinueHitbox(1.5, -1.5, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
            TimeEvent(16*FRAMES, function(inst)   --16
			-- inst.sg:RemoveStateTag("attack") 
			-- inst.sg:RemoveStateTag("busy")
			inst.sg:GoToState("air_idle")
			
			end),
        },
        
        events=
        {
            -- EventHandler("animover", function(inst) --FIXING THAT BUG THAT SHOWED UP IN THE HITBOX DEMO
                -- inst.sg:GoToState("air_idle")
            -- end),
        },
    },
	
	
	State{
        name = "bair",
        tags = {"attack", "notalking", "busy", "ll_medium", "force_direction"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("bair_retry")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.components.launchgravity:SetLandingLag(6)
        end,
		
		onexit = function(inst)

        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("woosh1", -0.2, 0.6, -0.2,   -1.6, 3,   0.7, 4, 0.4,   0, 0, 0, 1)
				--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
			
				inst:PushEvent("swaphurtboxes", {preset = "grounded"})
				
				inst.components.hitbox:SetDamage(14) --OKAY NO MORE TREES
				inst.components.hitbox:SetAngle(-315) --135) --45
				inst.components.hitbox:SetBaseKnockback(15)
				inst.components.hitbox:SetGrowth(106)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(0)
				
				inst.components.hitbox:SpawnHitbox(-1.2, 0.25, 0) 
				inst.components.hitbox:SpawnHitbox(-0.4, 0.25, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
			
				inst:PushEvent("swaphurtboxes", {preset = "grounded"})
				
				inst.components.hitbox:SetDamage(12) --THEIR ORIGINAL DAMAGE
				inst.components.hitbox:SetBaseKnockback(12)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(-1.2, 0.25, 0) 
				inst.components.hitbox:SpawnHitbox(-0.4, 0.25, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			
			TimeEvent(8*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			end),
			
            TimeEvent(16*FRAMES, function(inst) 
			-- inst.sg:RemoveStateTag("attack") 
			-- inst.sg:RemoveStateTag("busy")
			inst.sg:GoToState("air_idle")
			
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("air_idle")
            end),
        },
    },
	
	
	State{
        name = "dair",
        tags = {"attack", "notalking", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("dair_retry") --dair --flair4
			-- inst.components.launchgravity:SetLandingLag(10) --15
			inst.components.launchgravity:SetLandingLag(4, nil, "dair_pst")
            
        end,
		
		onexit = function(inst)

        end,
		
		-- onupdate = function(inst) --IMPORTANT!!! ONPUDATE FUNCTIONS !CANNOT! BE USED IN CONJUNCTION WITH STATES THAT CAN RECEIVE HITLAG (ANY MOVE WITH HITBOXES OR ARMOR)
			-- -- print("MUH ANGLE", inst.Physics:GetAngle())
				-- print("MUH ANGLE", inst.components.launchgravity:GetAngle())
				-- -- inst.sg.timelineindex,
			-- --self.inst.Physics:GetVelocity()
        -- end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				inst.components.hitbox:MakeFX("woosh1down", 0.1, 0.35, 0.1,   1.2, 0.7,   0.9, 5, 0,   0,0,0, 1)
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				--inst.components.hitbox:SetKnockback(10, 8)
				inst.components.hitbox:SetKnockback(0, 3)
				inst.components.hitbox:SetDamage(3.5)
				-- inst.components.hitbox:SetAngle(270) --AAAAH WHATEVER, ILL FIX IT LATER
				inst.components.hitbox:SetAngle(366) --THEEEEERE WE GO
				inst.components.hitbox:SetBaseKnockback(42)
				inst.components.hitbox:SetGrowth(10)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:AddSuction(0.15, 0, -0.4)
				
				inst.components.hitbox:SpawnHitbox(0, -0.4, 0) 
				inst.components.hitbox:SpawnHitbox(0, 0.3, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				-- inst.components.hitbox:MakeFX("punchwoosh", 0, -0.4, 0.2,   0.5, 0.5,   0.7, 3, 0.0,  0,0,0,  1)
				-- inst.components.hitbox:MakeFX("woosh1down", -0.1, 0.35, 0.1,   1.0, 0.7,   0.9, 5, 0,   0,0,0, 1)
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				inst.components.hitbox:MakeFX("woosh1down", -0.1, 0.35, 0.1,   1.2, 0.7,   0.9, 5, 0,   0,0,0, 1)
			end),
			
			TimeEvent(8*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0, -0.4, 0) 
				inst.components.hitbox:SpawnHitbox(0, 0.3, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				-- print("KICK2")
				-- inst.components.hitbox:MakeFX("punchwoosh", 0, -0.4, 0.2,   0.5, 0.5,   0.7, 3, 0.0,  0,0,0,  1)
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				inst.components.hitbox:MakeFX("woosh1down", 0.1, 0.35, 0.1,   1.2, 0.7,   0.9, 5, 0,   0,0,0, 1)
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0, -0.4, 0) 
				inst.components.hitbox:SpawnHitbox(0, 0.3, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				-- print("KICK3")
				-- inst.components.hitbox:MakeFX("punchwoosh", 0, -0.4, 0.2,   0.5, 0.5,   0.7, 3, 0.0,  0,0,0,  1)
				inst.components.hitbox:MakeFX("woosh1down", -0.1, 0.35, 0.1,   1.2, 0.7,   0.9, 5, 0,   0,0,0, 1)
			end),
			
			
			TimeEvent(13*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				-- inst.components.hitbox:MakeFX("woosh1down", -0.1, 0.35, 0.1,   1.0, 0.7,   0.9, 5, 0,   0,0,0, 1)
				-- ^^^^^
			end),
			
			TimeEvent(16*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0, -0.4, 0) 
				inst.components.hitbox:SpawnHitbox(0, 0.3, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				-- print("KICK3")
				-- inst.components.hitbox:MakeFX("punchwoosh", 0, -0.4, 0.2,   0.5, 0.5,   0.7, 3, 0.0,  0,0,0,  1)
			end),
			
			TimeEvent(17*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				inst.components.hitbox:MakeFX("woosh1down", 0.1, 0.35, 0.1,   1.2, 0.7,   0.9, 5, 0,   0,0,0, 1)
			end),
			
			TimeEvent(20*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(270) --AAAAH WHATEVER, ILL FIX IT LATER
				inst.components.hitbox:SetBaseKnockback(10)
				inst.components.hitbox:SetGrowth(130)
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0, -0.5, 0) 
				inst.components.hitbox:SpawnHitbox(0, 0.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				-- print("KICK4")
				inst.components.hitbox:MakeFX("punchwoosh", 0, -0.4, 0.2,   0.5, 0.5,   0.7, 3, 0.0,  0,0,0,  1)
			end),
			
            TimeEvent(30*FRAMES, function(inst) 
			-- inst.sg:RemoveStateTag("attack") 
			-- inst.sg:RemoveStateTag("busy")
			inst.sg:GoToState("air_idle")
			
			end),
        },
        
        -- events=
        -- {
            -- EventHandler("ground_check", function(inst)  --hit_ground
				-- -- print("STAR IS MY FAVORITE UGXIE HIGHLANDER FRIEND")
                -- -- inst.sg:GoToState("ll_medium_getup", 30)
				
				-- --9-8 LETS GIVE THIS A TRY --NOPE DOESNT WORK --EEYYYYYYY NOW IT WORKS!!! 
				-- inst.components.hitbox:AddNewHit()
				
				-- inst.components.hitbox:SetDamage(2.5)
				-- inst.components.hitbox:SetAngle(270) --AAAAH WHATEVER, ILL FIX IT LATER
				-- inst.components.hitbox:SetBaseKnockback(10)
				-- inst.components.hitbox:SetGrowth(130)
				-- inst.components.hitbox:SetSize(0.7)
				-- inst.components.hitbox:SpawnHitbox(0, 0.5, 0) 
				-- -- inst.components.hitbox:SpawnHitbox(0, 0.5, 0) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				-- -- inst.sg:GoToState("ll_medium_getup", 10)
				-- inst:DoTaskInTime(0, function(inst) inst.sg:GoToState("ll_medium_getup", 10) end )
            -- end),
        -- },
    },
	
	
	State{
        name = "dair_pst",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("landing") --"nair"
			
			inst.components.hitbox:SetDamage(2.5)
			inst.components.hitbox:SetAngle(270) --AAAAH WHATEVER, ILL FIX IT LATER
			inst.components.hitbox:SetBaseKnockback(10)
			inst.components.hitbox:SetGrowth(130)
			inst.components.hitbox:SetSize(0.7)
			inst.components.hitbox:SpawnHitbox(0, 0.5, 0) 
			-- inst.components.hitbox:SpawnHitbox(0, 0.5, 0) 
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
            
        end,
		
        
        timeline=
        {
            TimeEvent(10*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	State{
        name = "nair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("nair_loop") --"nair"
			--inst.AnimState:PlayAnimation("uspecial")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			-- inst.components.jumper:AirStall(2, 2)
			-- inst.components.jumper:AirDrag(0.1, 0.1, 0.1, 2000) --it works c:
            
        end,
		
		onexit = function(inst)

        end,
        
        timeline=
        {
            TimeEvent(2*FRAMES, function(inst) 
						
				inst.components.hitbox:MakeFX("spinwoosh", 0, 1, 0,  1, 1,  0.7, 5, 0,  0,0,0, 1)
				inst.components.hitbox:MakeFX("spinwoosh2", 0, 1, -1, 0.8, 0.8, 0.7, 5, 0,  0,0,0, 1)
				-- (fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
				inst.components.launchgravity:SetLandingLag(5)
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				--inst.components.hitbox:SetKnockback(10, 8)
				inst.components.hitbox:SetKnockback(2, 5)
				inst.components.hitbox:SetDamage(8)
				-- inst.components.hitbox:SetAngle(45) --SAKURAI
				-- inst.components.hitbox:SetAngle(361) 
				inst.components.hitbox:SetAngle(55) --2-7-17 OOOOH BOY IS IT REALLY A GOOD IDEA TO BUFF THIS??
				inst.components.hitbox:SetBaseKnockback(40) --20  --1-2-18 CHANGING TO INCREASE HITSTUN
				inst.components.hitbox:SetGrowth(70) --100
				inst.components.hitbox:SetHitLag(0.2)
				inst.components.hitbox:SetCamShake(0.2)
				inst.components.hitbox:SetHighlight(0.2)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.5) --1.5
				
				inst.components.hitbox:SetLingerFrames(50)
				
				-- inst.components.hitbox:SpawnHitbox(0, 1, 0) 
				-- inst.components.hitbox:SpawnHitbox(-0.8, 1, 0)
				-- inst.components.hitbox:SpawnHitbox(0.8, 1, 0)
				
				inst.components.hitbox:SetSize(1.2, 0.5)
				inst.components.hitbox:SpawnHitbox(0, 0.75, 0)
				
				--inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/attack_whoosh")
				-- inst.components.hitbox:MakeFX("spinwoosh", 0, 1, 0, 1, 1, 0.7, 3)
			-- inst.components.hitbox:MakeFX("spinwoosh2", 0, 1, -1, 0.8, 0.8, 0.7, 3)
			-- inst.components.hitbox:MakeFX("shockwave_side", 0, 0, 0.1, 1, 1, 1, 3)
			-- inst.components.hitbox:MakeFX("shockwave_side", 0, 1, 1, 0.8, 0.8, 1, 8, 1)
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
            TimeEvent(16*FRAMES, function(inst) 
			-- inst.sg:RemoveStateTag("attack") 
			-- inst.sg:RemoveStateTag("busy")
			inst.sg:GoToState("air_idle")
			
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                -- inst.sg:GoToState("air_idle")
				inst.AnimState:PlayAnimation("nair_loop")
            end),
        },
    },
	
	--[[
	State{
        name = "nair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("nair_loop") --"nair"
			--inst.AnimState:PlayAnimation("uspecial")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			-- inst.components.jumper:AirStall(2, 2)
			-- inst.components.jumper:AirDrag(0.1, 0.1, 0.1, 2000) --it works c:
			inst.Physics:SetActive(false)
            
        end,
		
		onexit = function(inst)
			inst.Physics:SetActive(true)
        end,
        
        timeline=
        {
            -- TimeEvent(2*FRAMES, function(inst) 
						
				-- -- inst.components.hitbox:MakeFX("spinwoosh", 0, 1, 0,  1, 1,  0.7, 5, 0,  0,0,0, 1)
				-- -- inst.components.hitbox:MakeFX("spinwoosh2", 0, 1, -1, 0.8, 0.8, 0.7, 5, 0,  0,0,0, 1)
				-- -- (fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
				-- inst.components.launchgravity:SetLandingLag(5)
			-- end),
			
			TimeEvent(1*FRAMES, function(inst) 
				-- inst.components.hitbox:MakeFX("sidesplash_med_down2", -0.3, 1.0, 0.1,   1.5, 1.5,   0.0, 8, 0.6,   0.2,0.2,0.2, 1)
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("dair", 0.4, 2, 0.4,    0.85, 0.85,    1, 30,    0, 1,1,1,  0, "spider_harold", "spiderfighter")
				inst.components.hitbox:MakeFX("sidesplash_med_down2", -0.1, 1.0, 0.1,   1.5, 1.5,   0.0, 8, 0.7,   0.2,0.2,0.2, 1)
				inst.AnimState:PlayAnimation("tumble_back")
				
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("woosh1down", 0.75, 2.75, 0.2,   1.8, 1.4,   0.0, 5, 1,   0.2,0.2,0.2, 0) --75
				inst.components.hitbox:MakeFX("woosh1down", 0.15, 2.75, 0.2,   1.0, 1.4,   0.0, 5, 1,   0.2,0.2,0.2, 0) --15
				-- inst.components.hitbox:MakeFX("woosh1down", 0.42, 2.78, 0.2,   4.4, 1.4,   0.0, 5, 1,   0.2,0.2,0.2, 0) --15
			end),
			
			
            TimeEvent(30*FRAMES, function(inst) 
			-- inst.sg:RemoveStateTag("attack") 
			-- inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("air_idle")
			
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                -- inst.sg:GoToState("air_idle")
				inst.AnimState:PlayAnimation("nair_loop")
            end),
        },
    },
	
	]]--
	
	
	State{
        name = "uair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            -- inst.AnimState:PlayAnimation("utilt_retry")
			inst.AnimState:PlayAnimation("uair_wilson")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.components.launchgravity:SetLandingLag(5)
		end,
		
		onexit = function(inst)

        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("half_circle_up_woosh_med", -0.2, 1.0, -0.2,   2.7, 2.5,   0.6, 8, 0.0,  1, 1, 1,   1) 
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(65) --75
				inst.components.hitbox:SetBaseKnockback(30) --10
				inst.components.hitbox:SetGrowth(110) --120
				inst.components.hitbox:SetSize(1.0)
				
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(-0.7, 1.1, 0) 
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
			
				inst.components.hitbox:SetSize(1.0)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(0.6, 1.3, 0) 
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
			
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(0.9, 0.6, 0) 
			end),
			
            TimeEvent(21*FRAMES, function(inst) 
			-- inst.sg:RemoveStateTag("attack") 
			-- inst.sg:RemoveStateTag("busy")
			inst.sg:GoToState("air_idle")
			
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("air_idle")
            end),
        },
    },
	
	State{
        name = "jab1",
        tags = {"attack", "short", "busy"}, 
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jab1")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			
			--inst.components.hitbox:MakeFX("portal_spin", 0, 3, 1, 1, 1.5, 1, 90, 0)
			-- for k, v in pairs(getmetatable(inst.Physics).__index) do print(k, v) end
			-- for k, v in pairs(getmetatable(TheSim).__index) do print(k, v) end
			-- for k, v in pairs(getmetatable(TheInputProxy).__index) do print(k, v) end
			
			inst:PushEvent("swaphurtboxes", {preset = "leanf"})
		
		end,
        
        timeline=
        {
            
			
			TimeEvent(2*FRAMES, function(inst)
				--inst.components.hitbox:SetKnockback(1, 6)
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(5)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetDamage(3)
				inst.components.hitbox:SetSize(0.6, 0.4)
				inst.components.hitbox:SetLingerFrames(0)
				inst.components.hitbox:AddSuction(0.5, 1.1, -0.5)
				inst.components.hitbox:SpawnHitbox(1.1, 1.2, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
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
        tags = {"attack", "listen_for_attack", "busy", "short"}, 
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jab_2")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)	
				inst.components.hurtboxes:ShiftHurtboxes(0.5, 0) 
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(5)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetDamage(2)
				inst.components.hitbox:AddSuction(0.5, 1.1, -1)
				
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(1.3, 0.5, 0) 
				 
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.sg:AddStateTag("jab2")
			end),
			
            TimeEvent(14*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")	
				inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                -- inst.sg:GoToState("idle")
            end),
			EventHandler("attack_key", function(inst)
				if inst.sg:HasStateTag("jab2") then
					inst.sg:GoToState("jab3")
				end
            end),
        },
    },
	
	State{
        name = "jab3",
        tags = {"attack", "jab3", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jab_3")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
            inst:PushEvent("swaphurtboxes", {preset = "leanf"})
        end,
		
		onupdate = function(inst)
			local blep = 7
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetDamage(4)
				inst.components.hitbox:SetSize(0.5)
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0)  
			end),
			
			TimeEvent(3*FRAMES, function(inst)
				inst.components.hitbox:SetSize(1.2)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.9, 1.2, 0) 
			end),
			
            TimeEvent(18*FRAMES, function(inst) 
				inst.sg:GoToState("idle")			
			end),
        },
        
    },
	
	
	
	State{
        name = "dash_attack",
        tags = {"busy", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dash_attack")
			inst.Physics:SetFriction(.5)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/explo")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
        end,
		
		onexit = function(inst)
			--inst.Physics:SetFriction(.9)
			inst.components.stats:ResetFriction()
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				inst:PushEvent("swaphurtboxes", {preset = "sliding"})
			end),
			
			TimeEvent(3*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(70)
				inst.components.hitbox:SetBaseKnockback(100)
				inst.components.hitbox:SetGrowth(43)
				inst.components.hitbox:SetSize(0.75, 0.3)  
				inst.components.hitbox:SetLingerFrames(4)
				inst.components.hitbox:SpawnHitbox(0.5, 0.2, 0) 
				
				inst.components.hitbox:MakeFX("slide1", 1, 0, 1, 1.5, 1.5, 1, 20, 0)
			end),
			
			TimeEvent(8*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetBaseKnockback(80)
				inst.components.hitbox:SetSize(0.3, 0.3)  
				inst.components.hitbox:SetLingerFrames(3)

				inst.components.hitbox:SpawnHitbox(0.8, 0.2, 0) 
				
			end),
			
            TimeEvent(19*FRAMES, function(inst)  --30
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			
			TimeEvent(20*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")				
				-- inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
	
	
	State{
        name = "ftilt",
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("ftilt_new")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")

            inst:PushEvent("swaphurtboxes", {preset = "leanf"})
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
				inst.components.hitbox:MakeFX("woosh1", 0.2, 1.0, 0.1,   2, 2,   0.8, 4, 0)
				
			end),
			
			TimeEvent(3*FRAMES, function(inst)
				inst:PushEvent("swaphurtboxes", {preset = "leanf"})
				
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(40) --35
				inst.components.hitbox:SetGrowth(90) --110
				inst.components.hitbox:SetSize(0.9, 0.3)
				inst.components.hitbox:SetLingerFrames(2)
				
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.3, 0.75, 0)  
				
				inst.components.hurtboxes:ShiftHurtboxes(0.5, 0)
			end),
			
			TimeEvent(11*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(-0.5, 0)
			end),
			
            TimeEvent(18*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
				inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {

        },
    },
	
	
	State{
        name = "dtilt",
        tags = {"attack", "spammy", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dtilt")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
            -- print("NO GETTING AROUND THIS-", inst.customhpbadgepercent:value()) --turns out there is getting around it
			
			-- local anchor = TheSim:FindFirstEntityWithTag("anchor")
			-- local testplayer = "player" .. tostring(math.random())
			-- anchor.components.gamerules:AddToQue(testplayer)
			-- TheNet:Announce(tostring(testplayer))
        end,
        
        timeline=
        {
            --TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:SetBlockDamage(1)
				inst.components.hitbox:SetKnockback(0, 40)
				inst.components.hitbox:SetDamage(2) --10 --60
				inst.components.hitbox:SetAngle(80)  --50 --64
				inst.components.hitbox:SetBaseKnockback(9)  --70
				inst.components.hitbox:SetGrowth(100)  --23
				
				inst.components.hitbox:SetHitLag(0.4)
				inst.components.hitbox:SetCamShake(0.4)
				inst.components.hitbox:SetHighlight(4)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.55, 0.35)  --0.3  --5 OH GOD NOT 5
				
				inst.components.hitbox:SpawnHitbox(0.9, 0.15, 0) --1.1 KEEPS MISSING
			end),
			
			TimeEvent(5*FRAMES, function(inst) --7
				-- inst.components.stats.opponent:PushEvent("jump")	 --YEA, NO
				TheFrontEnd:ShowSavingIndicator() --WHY IS THIS HERE????
			end),
			
            TimeEvent(8*FRAMES, function(inst) --7
				inst.sg:RemoveStateTag("attack") 
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")				
			end),
        },
    },
	
	
	State{
        name = "uptilt",
        tags = {"attack", "notalking", "abouttoattack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("utilt_retry")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
            
        end,
        
        timeline=
        {
            TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("half_circle_up_woosh_med", -0.2, 1.0, -0.2,   2.7, 2.5,   0.6, 8, 0.0,  1, 1, 1,   1) 
			end),
			TimeEvent(4*FRAMES, function(inst)
			
				inst.components.hitbox:SetDamage(6) --7
				inst.components.hitbox:SetAngle(96)
				inst.components.hitbox:SetBaseKnockback(80) --60 
				inst.components.hitbox:SetGrowth(50) --70 1-2-18
				inst.components.hitbox:SetSize(0.8) --1
				
				inst.components.hitbox:SpawnHitbox(-0.8, 1.2, 0)

			end),
			
			TimeEvent(5*FRAMES, function(inst)
				inst.components.hitbox:SetSize(1.0) --0.8
				inst.components.hitbox:SpawnHitbox(0.6, 1.2, 0)
			end),
			
			TimeEvent(7*FRAMES, function(inst)
				inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			end),
			
			TimeEvent(13*FRAMES, function(inst)
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			
            TimeEvent(15*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	
	
	
	State{
        name = "uspecial_wilson",
        tags = {"attack", "busy", "redeemrecovery", "recovery", "can_grab_ledge", "reducedairacceleration", "nolandingstop", "nopredict", "force_direction"},
        
        onenter = function(inst)
            --inst.AnimState:PlayAnimation("punch")
			inst.AnimState:PlayAnimation("utilt_002")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
            
			
			--10-18-17 GONNA ADD A SNEAKY LITTLE CHECK FOR GROUND TO MAKE IT EASIER TO GET THE GROUNDED VERSION WITH TAPJUMP
			local yhight = inst.components.launchgravity:GetHeight()
			if yhight <= 0.50 then --HEY, THIS IS ACTUALLY PRETTY GOOD... MIGHT DO THIS WITH ALL OF THEM!
				inst.components.launchgravity:Launch(0, 0)
				inst.sg:AddStateTag("wasgrounded")
			end
        end,
		
		onexit = function(inst)
			--DONT FORGET TO PUT THEM BACK TO DEFAULT
			inst.components.hurtboxes:ReplaceLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0) --(xpos, ypos, sizex, sizey, shape)
		end,
        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 
			
				if not inst.components.launchgravity:GetIsAirborn() then
					if inst.components.keydetector:GetBackward(inst) then inst.components.locomotor:TurnAround() end --LET HIM TURN BEFORE THE SCOOT
					--10-18-17 GIVING HIM THIS LIL SCOOT FORWARD IF HE'S ON THE GROUND
					inst.components.jumper:ScootForward(13) --HEHEE! PERFECT~
				end
			end),
			
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("punchwoosh", 0.8, 1.2, -0.4,   1.0, 1.0,   0.5, 4, 0.4,  0, 0, 0,   0) 
			end),
			
			
			
			TimeEvent(3*FRAMES, function(inst)
			
				if inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
				
				
				inst.components.hitbox:SetDamage(10) --12 OLD  --18 RYU'S
				inst.components.hitbox:SetAngle(72) --80 -LETS TRY MOVING THIS BACK A LITTLE.. IT WAS GETTING TOO CLOSE
				inst.components.hitbox:SetBaseKnockback(88) --80 OLD
				inst.components.hitbox:SetGrowth(55) --69 OLD
				inst.components.hitbox:SetSize(0.8)
				inst.components.hitbox:SetProperty(-1) --MAKE DISJOINTED. JUST BECAUSE HE DESERVES IT
				inst.components.hitbox:SetLingerFrames(3)
				
				--10-18-17 ALRIGHT, THE AIR VERSION HAS TO BE TONED DOWN A LITTLE
				if inst.components.launchgravity:GetIsAirborn() then
					inst.components.hitbox:SetDamage(8)
					inst.components.hitbox:SetGrowth(45)
					-- inst.components.hitbox:Blink(inst, 5,   1, 1, 1,   0.2)
				end
				
				
				
				-- inst.components.hitbox:SetOnHit(function() 
					-- -- local opponent = inst.components.stats:GetOpponent()
					-- if inst.sg:HasStateTag("redeemrecovery") then
						-- inst.sg:RemoveStateTag("recovery")
						-- inst.AnimState:SetAddColour(1,1,0,0.6)
						-- -- inst:DoTaskInTime(0.1, function(inst) inst.AnimState:SetAddColour(1,1,0,0.6) end )
						-- inst:DoTaskInTime(0.2, function(inst) inst.AnimState:SetAddColour(0,0,0,0) end )
					-- end
				-- end) 
				
				inst.components.hitbox:SpawnHitbox(0.5, 1, 0)

				
				inst.components.launchgravity:Launch(4, 24) --4, 24
				inst.components.stats.norecovery = true
			end),
			
			TimeEvent(5*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(3)
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(60) 
				inst.components.hitbox:SetGrowth(69)
				inst.components.hitbox:SetSize(0.3)
				inst.components.hitbox:SetLingerFrames(8) --15?? UM NO
				
				inst.components.hitbox:SpawnHitbox(0.5, 1.4, 0)

				
				inst.components.launchgravity:Launch(4, 24)
				if not inst.sg:HasStateTag("wasgrounded") then
					inst.sg:RemoveStateTag("redeemrecovery")
					inst.sg:RemoveStateTag("nolandingstop")
				end
				if inst.sg:HasStateTag("sweetspotted") and inst.sg:HasStateTag("wasgrounded") then inst.components.hitbox:MakeFX("smoke_puff_3", 0.6, 1.6, -0.2,   2.5, 2.5,   0.8, 12, 0,  0.0, 0.0, 0.0) end
			end),
			
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("redeemrecovery")
				inst.sg:RemoveStateTag("nolandingstop")
				if inst.sg:HasStateTag("sweetspotted") and inst.sg:HasStateTag("wasgrounded") then inst.components.hitbox:MakeFX("smoke_puff_3", 0.7, 2.0, -0.2,   1.5, 1.5,   0.8, 12, 0,  0.0, 0.0, 0.0) end
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				if inst.sg:HasStateTag("sweetspotted") and inst.sg:HasStateTag("wasgrounded") then inst.components.hitbox:MakeFX("smoke_puff_3", 0.8, 2.2, -0.2,   1, 1,   0.8, 12, 0,  0.0, 0.0, 0.0) end
				inst.components.launchgravity:Launch(4, 15) --1-25-17 A SECOND SLOWER-DOWN
			end),
			
			TimeEvent(8*FRAMES, function(inst) 
				if inst.sg:HasStateTag("sweetspotted") and inst.sg:HasStateTag("wasgrounded") then inst.components.hitbox:MakeFX("smoke_puff_3", 0.6, 1.8, 0.2,   2, 2,   0.8, 12, 0,  0.0, 0.0, -0.0) end
			end),
			
            TimeEvent(10*FRAMES, function(inst) 
				if inst.sg:HasStateTag("wasgrounded") and not inst.sg:HasStateTag("recovery") then
					inst.sg:RemoveStateTag("attack")
					inst.sg:RemoveStateTag("busy")
				end
			
			end),
			
			TimeEvent(20*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("reducedairacceleration") 
				--11-16-17 AT THE PEAK OF HIS JUMP, BUMP UP HIS LEDGEGRAB BOXES JUST A BIT.
				inst.components.hurtboxes:ReplaceLedgeGrabBox(0.0, 1.7, 1.5, 0.8, 0) --(xpos, ypos, sizex, sizey, shape)
			end),
			
			TimeEvent(24*FRAMES, function(inst) 
				if inst.sg:HasStateTag("recovery") then
					inst.sg:GoToState("freefall")
				end
			
			end),
        },
        
        events=
        {
			EventHandler("on_hit", function(inst)
                if inst.sg:HasStateTag("redeemrecovery") then
					inst.sg:RemoveStateTag("recovery")
					inst.sg:AddStateTag("sweetspotted")
					-- inst.AnimState:SetAddColour(1,1,0,0.6)
					if inst.sg:HasStateTag("wasgrounded") then
						inst:DoTaskInTime(0.1, function(inst) inst.AnimState:SetAddColour(1,1,0,0.6) end )
						inst:DoTaskInTime(0.2, function(inst) inst.AnimState:SetAddColour(0,0,0,0) end )
						
						inst.components.hitbox:MakeFX("smoke_puff_1", 0.5, 0.6, 0.2,   2.3, 2.3,   0.8, 15, 0,  0.0, 0.0, 0.0)
					end
				end
            end),
			
			
			EventHandler("ground_check", function(inst)
                inst.sg:AddStateTag("wasgrounded")
            end),
			
			
        },
    },
	
	
	
	
	
	--9-8 NSPECIAL
	State{
        name = "nspecial",
        tags = {"busy", "nolandingstop", "scary", "reducedairacceleration"}, --, "chargingfsmash"},

        onenter = function(inst)
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			inst.AnimState:PlayAnimation("charging_fsmash")
			inst.components.hitbox:SetDamage(13) --13  --19 --40 NO MORE WARLOCK PUNCHES -9-1
			inst.components.hitbox:SetAngle(45) --LETS INCREASE THE ANGLE THE LONGER ITS HELD
			inst.components.stats.storagevar1 = 1.0 --BASE DAMAGE
			inst.components.stats.storagevar2 = 1.0 --KB SCALING
			inst.components.stats.storagevar3 = 0
			inst.components.stats.storagevar4 = 0 --SELF DAMAGE
            
        end,
		
		timeline=
        {
			
            TimeEvent(10*FRAMES, function(inst) 
				inst.sg:GoToState("nspecial_charge")
			end),
        },
		
	},
	
	State{
        name = "nspecial_charge",
        tags = {"attack", "scary", "busy", "nolandingstop", "fastcharge", "noairmoving"},
        
        onenter = function(inst)
			if inst.components.keydetector and not inst.components.keydetector:GetSpecial(inst) then --:HasTag("atk_key_dwn")
				inst.sg:GoToState("nspecial_poof")
			else
			
			-- inst:AddComponent("colourtweener")
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.colourtweener:StartTween({1,0.5,0.5,1}, 2, nil)
			
			end
            
        end,
		
		onexit = function(inst)
            inst.components.colourtweener:EndTween()
			inst.AnimState:SetMultColour(1,1,1,1)
			
        end,
		
		onupdate = function(inst)  --1-11
            -- inst.components.hitbox:MultiplyDamage(1.0113)
			
			if inst.components.keydetector and not inst.components.keydetector:GetSpecial(inst) then
				inst.sg:GoToState("nspecial_poof")
			end
			
			if not inst.sg:HasStateTag("nocharge") then
				inst.components.hitbox:MultiplyDamage(1+ (0.015*0.38)) --0.33
				inst.components.stats.storagevar1 = inst.components.stats.storagevar1 + 0.025
				
				if inst.sg:HasStateTag("fastcharge") then
					inst.components.hitbox:MultiplyDamage(1+ (0.015*0.66))
					inst.components.stats.storagevar1 = inst.components.stats.storagevar1 + 0.015
				else
					inst.components.stats.storagevar4 = inst.components.stats.storagevar4 + 0.26
				end
			end
			
			-- print("THE DAAAHHMIDGE", inst.components.stats.storagevar4)
        end,
        
        timeline=
        {
			
			--WE'LL DO 3 STAGES ACTUALLY. FIRST STAGE JUST ADDS ARMOR AND DOESNT CHANGE THE CHARGE OR ENDLAG
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("glint_ring_1", 0.6, 1.0, 0.2,   0.8, 0.8,   0.0, 8, 0.5,  1, 0, 0,   1) 
				inst.components.stats.storagevar3 = 1 --GIVE ARMOR
			end),
			
			-- TimeEvent(1*FRAMES, function(inst) --9-5 WHY IS THIS AT 7? CHANGING TO 1
				-- inst.sg:AddStateTag("chargingdsmash")
			-- end),
			
			-- TimeEvent(11*FRAMES, function(inst) 
				-- local x,y,z = inst.Transform:GetWorldPosition()
				-- inst.Transform:SetPosition( (x + 0.01), y, z )
			-- end),
			
			-- TimeEvent(13*FRAMES, function(inst) 
				-- local x,y,z = inst.Transform:GetWorldPosition()
				-- inst.Transform:SetPosition( (x - 0.01), y, z )
			-- end),
			
			
			TimeEvent(15*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.01), y, z )
			end),
			
			TimeEvent(17*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.01), y, z )
			end),
			
			TimeEvent(19*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.01), y, z )
				-- inst.sg:RemoveStateTag("flag") --AFTER THIS POINT, THE FULL ENDLAG ANIMATION MUST PLAY
				inst.components.stats.storagevar3 = 2 --ALL THE REST
				inst.components.hitbox:MakeFX("glint_ring_1", 0.6, 1.0, 0.2,   0.8, 0.8,   0.0, 8, 0.5,  1, 0, 0,   1) 
			end),
			
			TimeEvent(21*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.01), y, z )
			end),
			
			TimeEvent(23*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
				inst.components.hitbox:SetAngle(60) --2-22-17 LETS BUMP UP THE ANGLE A BIT
			end),
			
			TimeEvent(25*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.02), y, z )
			end),
			
			TimeEvent(27*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
			end),
			
			TimeEvent(29*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.02), y, z )
			end),
			
			TimeEvent(31*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
				inst.sg:RemoveStateTag("fastcharge") --CHARGING SLOWS DOWN SLIGHTLY AFTER THIS POINT
				-- inst.components.hitbox:MakeFX("glint_ring_2", 0.6, 1.0, 0.2,   0.8, 0.8,   0.8, 8, 0.8,  0.9, 0, 0,   1) 
			end),
			
			TimeEvent(33*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.02), y, z )
			end),
			
			TimeEvent(35*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
			end),
			
			TimeEvent(37*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.02), y, z )
			end),
			
			TimeEvent(39*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
			end),
			
			TimeEvent(41*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.02), y, z )
				inst.sg:RemoveStateTag("fastcharge") --CHARGING SLOWS DOWN SLIGHTLY AFTER THIS POINT
				-- inst.components.hitbox:MakeFX("glint_ring_2", 0.6, 1.0, 0.2,   0.8, 0.8,   0.8, 8, 0.8,  0.9, 0, 0,   1) 
				inst.components.hitbox:SetAngle(70) --2-22-17 LETS BUMP UP THE ANGLE A BIT
			end),
			
			TimeEvent(43*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
			end),
			
			
			-- TimeEvent(35*FRAMES, function(inst) 
				-- local x,y,z = inst.Transform:GetWorldPosition()
				-- inst.Transform:SetPosition( (x + 0.04), y, z )
			-- end),
			-- TimeEvent(37*FRAMES, function(inst) 
				-- local x,y,z = inst.Transform:GetWorldPosition()
				-- inst.Transform:SetPosition( (x - 0.04), y, z )
			-- end),
			-- TimeEvent(39*FRAMES, function(inst) 
				-- local x,y,z = inst.Transform:GetWorldPosition()
				-- inst.Transform:SetPosition( (x + 0.04), y, z )
			-- end),
			-- TimeEvent(41*FRAMES, function(inst) 
				-- local x,y,z = inst.Transform:GetWorldPosition()
				-- inst.Transform:SetPosition( (x - 0.04), y, z )
			-- end),
			-- TimeEvent(43*FRAMES, function(inst) 
				-- local x,y,z = inst.Transform:GetWorldPosition()
				-- inst.Transform:SetPosition( (x + 0.04), y, z )
			-- end),
			-- TimeEvent(45*FRAMES, function(inst) 
				-- local x,y,z = inst.Transform:GetWorldPosition()
				-- inst.Transform:SetPosition( (x - 0.04), y, z )
			-- end),
			
			TimeEvent(45*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.04), y, z )
			end),
			
			TimeEvent(47*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.04), y, z )
			end),
			TimeEvent(49*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.04), y, z )
			end),
			TimeEvent(51*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.04), y, z )
			end),
			TimeEvent(53*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.04), y, z )
			end),
			TimeEvent(55*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.04), y, z )
			end),
			TimeEvent(57*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.04), y, z )
			end),
			
			TimeEvent(61*FRAMES, function(inst) 
				-- inst.sg:GoToState("dsmash")
				inst.sg:AddStateTag("nocharge")
				inst.components.hitbox:MakeFX("glint", 0.6, 1.0, 0.2,   0.8, 0.8,   0.8, 8, 0.8,  0.0, 0, 0,   1)
				inst.AnimState:SetMultColour(1,0.5,0.5,1)
			end),
			
			TimeEvent(90*FRAMES, function(inst) 
				inst.sg:GoToState("nspecial_poof")
			end),
			
        },
        
        events=
        {
			-- EventHandler("throwdsmash", function(inst) inst.sg:GoToState("dsmash") end ),
        },
    },
	
	
	
	State{
        name = "nspecial_poof",
        tags = {"attack", "nolandingstop", "busy", "abouttoattack", "noairmoving"}, --, "armor"},
        
        onenter = function(inst)
			
			inst.components.colourtweener:EndTween()
			inst.AnimState:SetMultColour(1,1,1,1)
			
			--1-17-22 THIS MOVE WILL ONLY GET ARMOR IF IT WAS CHARGED FOR LONG ENOUGH
			if inst.components.stats.storagevar3 > 0 then
				inst.sg:AddStateTag("armor")
			end
        end,
		
		onexit = function(inst)
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.AnimState:SetTime(0*FRAMES) --12-6-17 HOPEFULLY FIXES SOME DST BUG FOR MOONWALKING
        end,
        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 
				--INTANGIBILITY IS ACTUALLY WEAKER HERE BECAUSE THIS WILL LIKELY MEAN A TRADE
				if inst.components.stats.storagevar3 == 0 then
					inst.sg:AddStateTag("intangible")
				end
				
				inst.SoundEmitter:PlaySound("dontstarve/common/destroy_smoke")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hot_explo")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hot_explo")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/rook/step")
				
				local sizer = inst.components.stats.storagevar1
				inst.components.hitbox:MakeFX("poof_nuke", (1 - math.sqrt(sizer)), (-0.2 * (sizer*sizer)), 0.2,   (sizer*1.3), math.sqrt(sizer),   1, 100)
			
				inst.AnimState:PlayAnimation("potion_poof") --("fsmash_000")
			end),
			
			TimeEvent(2*FRAMES, function(inst)
				--1-9-22 DAMAGE OURSELVES
				inst.components.percent:DoDamage(-inst.components.stats.storagevar4)
				
				if inst.components.stats.storagevar3 == 0 then
					inst.sg:RemoveStateTag("intangible")
				end
				
				local sizer = inst.components.stats.storagevar1
				
				TheCamera:Shake("FULL", .3, .03, .2*inst.components.stats.storagevar1)
				inst.components.hitbox.property = -6
			
				inst.components.hitbox:SetBlockDamage(5)
				inst.components.hitbox:SetBaseKnockback(65) --30 --9-8 THIS IS WHAT IT WAS AT
				inst.components.hitbox:SetGrowth(100 + inst.components.stats.storagevar2)   --78  --100  --9-8 THIS IS WHAT IT WAS AT
				-- inst.components.hitbox:SetBaseKnockback(30) --DEDEDES JET HAMMER
				inst.components.hitbox:SetSize(1*math.sqrt(sizer))
				
				inst.components.hitbox:SetLingerFrames(3) --10
				-- inst.components.hitbox:MakeDisjointed() --7-8-17 WE ARE MAKING IT MORE THAN JUST DISJOINTED. SO DONT USE THIS. IT SETS THE PROPERTY TO 1
				inst.components.hitbox:SpawnHitbox(0.4, 1.3, 0)
				
				inst.components.hitbox.property = -6
				inst.components.hitbox:SpawnHitbox(0.4 + inst.components.stats.storagevar1, 1, 0)
				inst.components.hitbox.property = -6
				inst.components.hitbox:SpawnHitbox(0.4 - inst.components.stats.storagevar1, 1, 0)
				
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			TimeEvent(3*FRAMES, function(inst) --48
				inst.sg:RemoveStateTag("armor")
			end),
			
			TimeEvent(6*FRAMES, function(inst) --LITTLE SMOKE RING HITBOXES PAST MID-CHARGE POINT
				-- if inst.components.stats.storagevar3 == 1 then
					inst.components.hitbox:SetDamage(5) --25
					inst.components.hitbox:SetAngle(80)
					inst.components.hitbox:SetBaseKnockback(60)
					inst.components.hitbox:SetGrowth(50)
					inst.components.hitbox:SetLingerFrames(6)
					inst.components.hitbox:SetSize(2.5, 1)
					
					inst.components.hitbox:SetHitFX("invisible", "dontstarve/common/fireOut")
					
					inst.components.hitbox:SetOnHit(function()
						inst.components.stats.opponent.components.hitbox:MakeFX("smoke_puff_1", 0, 1.6, 0.5,   1.5, 1.5,   1, 27, 0,  0,0,0)
						
					end)
					
					inst.components.hitbox.property = -6
					inst.components.hitbox:SpawnHitbox(0, 3, 0)
				-- end
			end),
			
			TimeEvent(9*FRAMES, function(inst) --MORE SMOKE RING DAMAGE
				if inst.components.stats.storagevar3 == 2 then
					inst.components.hitbox:SetDamage(2) --25
					inst.components.hitbox:SetAngle(80)
					inst.components.hitbox:SetBaseKnockback(60)
					inst.components.hitbox:SetGrowth(50)
					inst.components.hitbox:SetLingerFrames(6)
					inst.components.hitbox:SetSize(3.5, 1)
					
					inst.components.hitbox:SetHitFX("invisible", "dontstarve/common/fireOut")
					
					inst.components.hitbox:SetOnHit(function()
						inst.components.stats.opponent.components.hitbox:MakeFX("smoke_puff_1", 0, 1.6, 0.5,   1.5, 1.5,   1, 27, 0,  0,0,0)
						-- inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
					end)
					
					inst.components.hitbox.property = -6
					inst.components.hitbox:SpawnHitbox(0, 4.5, 0)
				end
			end),
			
			
            TimeEvent(34*FRAMES, function(inst) --32
				inst.AnimState:SetTime(38*FRAMES)
				if inst.components.stats.storagevar3 < 2 then
					inst.components.hitbox:SetDamage(5)
					inst.sg:RemoveStateTag("attack") 
					inst.sg:RemoveStateTag("busy")
				end
			end),
			
			TimeEvent(44*FRAMES, function(inst) --48
				inst.components.stats.storagevar3 = 0
				inst.sg:RemoveStateTag("attack") 
				inst.sg:RemoveStateTag("busy")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.AnimState:PlayAnimation("idle")
            end),
        },
    },
	
	
	
	
	
	State{
        name = "fspecial",
        tags = {"attack", "notalking", "abouttoattack", "busy", "nolandingstop", "can_grab_ledge", "reducedairacceleration"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("nspecial_retry")
			-- inst.AnimState:PlayAnimation("nspecial")
			
			if inst.components.stats.storagereference1 and inst.components.stats.storagereference1:IsValid() then
				inst.sg:GoToState("boomerang_dud")
			end
			-- print("NOT FEELING SO HOT", inst.components.stats.storagereference1)
            
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				if inst.components.keydetector and inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				-- local testbox = SpawnPrefab("nitre")
				-- inst.components.hitbox:SpawnAIFearBox(testbox, 2, 1, 1, 60)
				
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("can_grab_ledge")
			end),

			TimeEvent(7*FRAMES, function(inst) --10
				-- inst.AnimState:PlayAnimation("nspecial_retry")
			
				inst.components.hitbox:SetKnockback(15, 12)
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(63) --70
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(50)
				inst.components.hitbox:SetSize(0.4) --1
				inst.components.hitbox:SetLingerFrames(150)
				
				inst.components.hitbox:SetProjectileAnimation("boomerang", "boomerang", "spin_loop")
				inst.components.hitbox:SetProjectileSpeed(8, 0.5)
				inst.components.hitbox:SetProjectileDuration(130) --REDUCING FROM 150
				
				inst.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_throw")
				
				local projectile = SpawnPrefab("basicprojectile") --8-30 USING LUCY AS A TEST SUBJECT FOR THE BOOMERANG EFFECT
		
				inst.components.stats.storagereference1 = projectile
				projectile.components.projectilestats.yhitboxoffset = 0.8
				
				-- 10-28-17 --ON HIT, CHECK TO SEE WHAT DIRECTION ITS GOING
				inst.components.hitbox:SetOnPreHit(function() 
					local xvel, yvel = projectile.Physics:GetVelocity()
					local facedir = projectile.components.launchgravity:GetRotationFunction()
					
					if (xvel < 0 and facedir == "left") or (xvel > 0 and facedir == "right") then --IF TRAVELING BACKWARDS
						for i, v in ipairs(projectile.components.hitbox.hitboxtable) do --WOW. THIS IS GETTING COMPLICATED
							v.components.hitboxes.kbangle = 110 --HIT BACKWARDS
						end
					else
						for i, v in ipairs(projectile.components.hitbox.hitboxtable) do
							v.components.hitboxes.kbangle = 70
						end
					end
				end)
				
				inst.components.hitbox:SpawnProjectile(0.8, -0.5, 0, projectile)
				
				projectile.Transform:SetScale(1.25, 0.7, 1)
				projectile:RemoveTag("deleteonhit")
				projectile.components.projectilestats:DoBoomerang(0.7, 0.3, 7, 5) --(flytime, accel, maxreturnspeedx, maxreturnspeedy)
				
			end),
			
            TimeEvent(21*FRAMES, function(inst)  --25
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				-- inst.sg:GoToState("idle")
			end),
        },
        
        -- events=
        -- {
            -- EventHandler("animover", function(inst)
                -- inst.sg:GoToState("idle")
            -- end),
        -- },
    },
	
	
	
	State{
        name = "boomerang_dud",
        tags = {"attack", "notalking", "abouttoattack", "busy", "nolandingstop", "reducedairacceleration"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("nspecial_retry_dud")
			inst.AnimState:SetTime(3*FRAMES)
        end,
        
        timeline=
        {
            TimeEvent(18*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
    },
	

	
	State{
        name = "dspecial",
        tags = {"attack", "busy", "nolandingstop"},  
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dspecial")
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			-- print("OK, SO AM I ON THE GROUND OR NOT?", inst.components.launchgravity:GetIsAirborn())
			inst.components.jumper:UnFastFall()
			-- inst.components.launchgravity:SetLandingLag(8) --IM ACTUALLY GOING TO GIVE THIS SOME LANDING LAG BECAUSE SPAMMING FROM THE GROUND SEEMS STUPID
		end,
        
        timeline=
        {
            
			
			TimeEvent(1*FRAMES, function(inst) 
				if inst.components.keydetector:GetBackward(inst) then --FIRST THINGS FIRST. TURN AROUND
					inst.components.locomotor:TurnAround()
				end
				
				--11-8-17 ALRIGHT- LETS FIX THIS MESS
				inst.components.launchgravity:SetLandingLag(8) --NOW LANDING LAG MUST BE ENABLED DOWN HERE
				inst.sg:RemoveStateTag("nolandingstop") --THE PLAN IS TO ENABLE LANDING AND SET THE BUFFER TO DOWNSPECIAL AGAIN SO IT WILL IMMEDIATLY REPLAY
				-- inst.components.stats:SetKeyBuffer("throwspecial", inst.components.keydetector:GetBufferKey(inst), inst.Transform:GetRotation())
				--SET LANDING LAG ON THE NEXT TICK
				
				--YOU KNOW WHAT?... IM NOT REALLY SURE IF THIS IS EVEN STILL A BUG. WELL, IF I ENCOUNTER IT AGAIN, I'LL COME BACK
				--YEP. IT HAPPENED AGAIN. ADDING "NOLANDINGSTOP" BACK INTO THE TAG LIST
			end),
			
			TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				if not inst.components.launchgravity:GetIsAirborn() then
					inst.components.launchgravity:Launch(0,16,0) --17 -11-8-17 LETS BUMP THIS UP A BIT
					--11-12-17- BUT IF ON THE GROUND, GIVE REDUCED AIR MOVEMENT
					inst.sg:AddStateTag("wasgrounded") --JUST SOMETHING FOR THIS STATE, USELESS ANYWHERE ELSE
				end
			end),
			
			TimeEvent(4*FRAMES, function(inst)
				if not inst:HasTag("potionhopped") then
					inst.components.launchgravity:Launch(0,14,0) --12
					
					--11-8-17 -IM MAKING THE HOP HIGHER IF YOU'RE FALLIN FAST ENOUGH
					local xvel, yvel = inst.Physics:GetVelocity()
					if yvel <= -10 then
						inst.components.launchgravity:Launch(0,18,0) --A BEEFIER JUMP
					end
					
					inst:AddTag("potionhopped") --THIS TAG IS REMOVED VIA EVENT LISTENER IN HIS PREFAB FILE
				end
				
			end),

			TimeEvent(5*FRAMES, function(inst)
				--11-12-17 IF IT WAS GROUNDED, LESSEN THEIR MOVEMENT A BIT
				if inst.sg:HasStateTag("wasgrounded") then --SINCE GROUNDED POGO SEEMED A LITTLE CRAZY
					inst.sg:AddStateTag("reducedairacceleration")
				end
			
				inst.components.hitbox:SetDamage(2) --25
				inst.components.hitbox:SetAngle(110)
				inst.components.hitbox:SetBaseKnockback(70)
				inst.components.hitbox:SetGrowth(50)
				inst.components.hitbox:SetSize(0.4) --1
				inst.components.hitbox:SetLingerFrames(150)
				inst.components.hitbox:SetProperty(5) --3-4-17 --THERE. THIS ITSELF DOESNT DO KNOCKBACK
				
				inst.components.hitbox:SetProjectileAnimation("projectile_lucy", "projectile_lucy", "potion_spin")
				inst.components.hitbox:SetProjectileSpeed(0, -7)
				inst.components.hitbox:SetProjectileDuration(150)
				
				inst.components.launchgravity:SetLandingLag(12) --OKAY I ACTUALLY NEED TO CRANK UP LANDING LAG PAST THROWING THE POTION BECAUSE HE CAN THROW IT AGAIN TOO FAST
				
				inst.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_throw")
				
				local projectile = SpawnPrefab("basicprojectile") --8-30 USING LUCY AS A TEST SUBJECT FOR THE BOOMERANG EFFECT
				
				projectile:RemoveTag("deleteonhit")
				projectile:RemoveTag("deleteonclank") --1-2-21 EXPERIMENTAL, FOR PROJECTILES ONLY
				projectile.Transform:SetScale(1.0, 1.0, 1)
				
				projectile:DoTaskInTime(0.42, function()
					projectile.components.projectilestats:BePhysicsBased()
					projectile.Physics:SetDamping(0.0)
					projectile.Physics:ClearMotorVelOverride()
					--inst.Physics:SetDamping(-0.2)
					projectile.Physics:SetFriction(.7) 
					projectile.Physics:SetMass(0.9)
					projectile.Physics:SetRestitution(0)
				end)
				
				projectile:DoPeriodicTask(0.2, function()
					projectile.components.hitbox:MakeFX("smoke_puff_3", -0.0, 0.0, 0.2,   1, 1,   0.8, 12, 0,  0.0, 0.0, 0.0)
				end)
				
				
				local function Splode(inst)
					if inst:HasTag("alreadyimpacted") then
						return end --WE ALREADY SPLODED ONCE, DON'T DO IT AGAIN
					
					inst.components.hitbox:AddNewHit()
					inst.components.hitbox:SetDamage(6)
					inst.components.hitbox:SetPriority(12)
					inst.components.hitbox:SetSize(1.4)
					inst.components.hitbox:SetLingerFrames(3)
					
					TheCamera:Shake("FULL", .1, .02, .15)
					inst.components.hitbox:MakeFX("smoke_puff_1", -0.2, 0.6, 0.2,   2.3, 2.3,   0.8, 15, 0,  0.0, 0.0, 0.0)
					
					inst.SoundEmitter:PlaySound("dontstarve/common/destroy_pot")
					-- inst.components.hitbox:SetProjectileSpeed(0, 0) 
					
					inst.sg:GoToState("explode")
					inst:Hide() --11-24-20 SAME THING AS PLAYING A BLANK ANIMATION BUT IT DOESNT WHINE ABOUT IT IN THE DEBUG LOG
					
				end
				
				
				local function OnCollide(inst, object)
					if object:HasTag("stage") and not inst:HasTag("alreadyimpacted") then
						Splode(inst)
					end
				end
				
				
				projectile:ListenForEvent("clank", function() --overpowered(?)
					print("CLANK EVENT?")
					Splode(projectile)
				end)
				
				projectile:ListenForEvent("overpowered", function() 
					print("OVERPOWER EVENT")
					Splode(projectile)
				end)
				
				projectile:ListenForEvent("on_hitted", function() 
					print("I'M HIT")
					Splode(projectile)
				end)
				
				projectile:ListenForEvent("got_reflected", function() 
					print("IM REFLECTED")
					projectile.components.projectilestats:BePhysicsBased()
					projectile.Physics:SetDamping(0.0)
					projectile.Physics:ClearMotorVelOverride()
					projectile.Physics:SetFriction(.7) 
					projectile.Physics:SetMass(0.9)
					projectile.Physics:SetRestitution(0)
					--LAUNCH UP
					projectile.Physics:SetVel(0, 20, 0)
				end)
				
				
				inst.components.hitbox:SetOnHit(function() 
					Splode(projectile)
				end)
				
				projectile.Physics:SetCollisionCallback(OnCollide)
				
				inst.components.hitbox:SpawnProjectile(-0.2, -0.6, 0, projectile)
				
				
				
				--7-8-17 OHHHH I NEED TO RESET IT OR ELSE IM NOT DOING ANYTHING ON HIT??
				-- inst.components.hitbox:SetOnHit(function() end)
				
			end),
			
			TimeEvent(12*FRAMES, function(inst) inst.components.locomotor:SlowFall(0.2, 4) end),
			
			TimeEvent(15*FRAMES, function(inst)
				inst.sg:AddStateTag("can_grab_ledge")
			end),
			
            TimeEvent(20*FRAMES, function(inst) --25
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("air_idle")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                --inst.sg:GoToState("idle")
            end),
        },
    },
	
	
	
	--FSMASH
	State{
        name = "fsmash_start",
        tags = {"busy", "scary"}, --, "chargingfsmash"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("fsmash_wilson_charge")
			inst.components.jumper:ScootForward(-5)
            inst.components.hitbox:SetDamage(17)
        end,
		
		timeline=
        {
			
            TimeEvent(7*FRAMES, function(inst)  --6
				inst.sg:GoToState("fsmash_charge")
			end),
        },
		
	},
	
	State{
        name = "fsmash_charge",
        tags = {"attack", "scary", "f_charge", "busy"}, --, "chargingfsmash"},
        
        onenter = function(inst)
			
			if not inst:HasTag("atk_key_dwn") then
				inst.sg:GoToState("fsmash")
			else
			
			-- inst:AddComponent("colourtweener")
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
			inst.AnimState:PlayAnimation("fsmash_wilson_new")
        end,
		
        timeline=
        {
           -- ") end),
			TimeEvent(3*FRAMES, function(inst)
				inst.components.jumper:ScootForward(6)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			end),
			
			TimeEvent(5*FRAMES, function(inst)
				
				--10-25-17 OHHH, THE ABOVE USED TO BE LINK'S. HERE. LETS TRY RYU'S
				-- inst.components.hitbox:SetDamage(16)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(25)  
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1, 1, 0) 
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.6, 1, 0)
			end),
			
			
			TimeEvent(15*FRAMES, function(inst) 
				inst.AnimState:SetTime(20*FRAMES)
			end),
			
			
            TimeEvent(25*FRAMES, function(inst) 
				-- print("FINAL LAP --------", (inst.sg.timeinstate/FRAMES))
				-- print("49 STATE END")
				--print("FINAL LAP --------", inst.sg.timelineindex, (inst.sg.timeinstate/FRAMES)) --TIMELINEINDEX DOESNT SEEM TO WORK
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
				
				
			
			end),
        },
    },
	
	
	--DSMASH
	State{
        name = "dsmash_start",
        tags = {"busy"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("dsmash_wilson_charge")
			inst:PushEvent("swaphurtboxes", {preset = "landing"})
			inst.components.hitbox:SetDamage(10)
			inst.components.stats.storagevar1 = 1.0
			inst.components.visualsmanager:Shimmy(0, 0.02, 10)
        end,
		
		timeline=
        {
            TimeEvent(2*FRAMES, function(inst) 
				inst.sg:GoToState("dsmash_charge")
			end),
        },
		
	},
	
	State{
        name = "dsmash_charge",
        tags = {"attack", "scary", "d_charge", "busy", "fastcharge"},
        
        onenter = function(inst)
			if not inst:HasTag("atk_key_dwn") then
				inst.sg:GoToState("dsmash")
			else
			-- inst:AddComponent("colourtweener")
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
        tags = {"attack", "notalking", "busy", "abouttoattack"},
        
        onenter = function(inst)
			local sizer = inst.components.stats.storagevar1
			-- inst.components.hitbox:MakeFX("poof_nuke", 0, -0.3, 0.2,   1.0, 1.0,   1, 90)
			-- inst.components.hitbox:MakeFX("poof_nuke", (1 - math.sqrt(sizer)), (-0.2 * (sizer*sizer)), 0.2,   inst.components.stats.storagevar1, math.sqrt(sizer),   1, 100)
		
			inst.AnimState:PlayAnimation("dsmash_wilson")
			inst.components.hitbox:MakeFX("woosh1downd", 0.4, 0.6, 0.1,   1.4, 0.9,   0.0, 7, 0,  1,0.5,0,  1)
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
				inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
			end),
			
			TimeEvent(2*FRAMES, function(inst)
			
				inst.components.hitbox:MakeFX("taunt", 1.4, 0.3, 0.2,   -0.22, 0.4,   1, 5, 0,  0,0,0, 0, "dragonfly_fx", "dragonfly_fx") 
				inst.components.stats.lastfx.AnimState:SetTime(25*FRAMES)
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
				
				-- local sizer = inst.components.stats.storagevar1
				-- inst.components.hitbox:SetDamage(10)
				-- inst.components.hitbox:SetDamage(inst.components.stats.storagevar2) --TAKE THE DAMAGE SAVED AT THE TOP
				inst.components.hitbox:SetAngle(35)  --BASED OFF SAMUS DSMASH
				inst.components.hitbox:SetBaseKnockback(60) --70
				inst.components.hitbox:SetGrowth(50) --46
				inst.components.hitbox:SetSize(0.8)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetHitFX("default", "dontstarve/common/fireOut")
				
				inst.components.hitbox:SpawnHitbox(1.40, 0.0, 0) 
				
			end),
			
			TimeEvent(5*FRAMES, function(inst)
				
				--SOME SICK NEW FX
				inst.components.hitbox:MakeFX("atk", 0.7, 0.3, 0.2,   -0.22, 0.20,   1, 10, 0,  0,0,0, 1, "dragonfly_fx", "dragonfly_fx") 
				inst.components.stats.lastfx.AnimState:SetTime(14*FRAMES)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/deciduous/drake_pop_large")
				
				inst.components.hitbox:SetDamage(5) --BASED OFF MARIO FIREBALL
				inst.components.hitbox:SetAngle(65) --361
				inst.components.hitbox:SetBaseKnockback(55)
				inst.components.hitbox:SetGrowth(20)
				inst.components.hitbox:SetSize(0.5, 0.3)
				inst.components.hitbox:SetLingerFrames(3) 
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(0.5, 0.1, 0) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(7*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(35)  --BASED OFF SAMUS DSMASH
				inst.components.hitbox:SetBaseKnockback(60) --70
				inst.components.hitbox:SetGrowth(50) --46
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(3) 
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(-1.0, 0.0, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				
				--AND THEN MORE LINGERING FIRE
				inst.components.hitbox:SetDamage(5) --BASED OFF MARIO FIREBALL
				inst.components.hitbox:SetAngle(361) 
				inst.components.hitbox:SetBaseKnockback(55)
				inst.components.hitbox:SetGrowth(20)
				inst.components.hitbox:SetSize(0.8, 0.3)
				inst.components.hitbox:SetLingerFrames(4) 
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.0, 0.1, 0) 
				
			end),
			
            TimeEvent(22*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	State{
        name = "usmash_start",
        tags = {"busy"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("usmash_wilson_charge")
			inst:PushEvent("swaphurtboxes", {preset = "landing"})
			inst.components.hitbox:SetDamage(5) --IS IT NORMAL TO BE THIS SMALL???
        end,
		
		timeline=
        {

			
			TimeEvent(3*FRAMES, function(inst) 
				inst.sg:GoToState("usmash_charge")
			end),
        },
		
	},
	
	State{
        name = "usmash_charge",
        tags = {"attack", "u_charge", "busy"},
        
        onenter = function(inst)
			-- inst:AddComponent("colourtweener")
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
			inst.AnimState:PlayAnimation("usmash_wilson")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
			inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			
			--10-26-17 OKAY WE'RE GONNA TRY SOMETHING DIFFERENT... 
			inst.components.stats.storagevar2 = inst.components.hitbox.dam --SET THIS AS THE CURRENT DAMAGE VALUES
			-- print("HERES THE DAMAGE", inst.components.stats.storagevar2, inst.components.hitbox.dam)
			
			inst.components.hitbox:MakeFX("taunt", -0.2, 2.3, 0.2,   -0.2, 0.5,   1, 10, 0,  0,0,0, 0, "dragonfly_fx", "dragonfly_fx") 
			inst.components.stats.lastfx.AnimState:SetTime(3*FRAMES)
		end,
		
		onupdate = function(inst)
            
        end,
		
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(1.5)
				-- inst.components.hitbox:SetAngle(366) 
				inst.components.hitbox:SetAngle(135) 
				inst.components.hitbox:SetBaseKnockback(15) 
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetSize(1.1, 0.75)
				
				inst.components.hitbox:AddSuction(0.1, -0.3, 0) --power, sucpx, sucpy
				inst.components.hitbox:SetHitFX("invisible", "dontstarve/common/fireOut")
				
				inst.components.hitbox:SpawnHitbox(0.0, 1.5, 0) --2.5
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
				
				--2-5-22 SECOND SCOOPER HITBOX
				inst.components.hitbox:SetSize(1.4, 0.3)
				inst.components.hitbox:SpawnHitbox(0.2, 0.9, 0)
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetDamage(1.5)
				inst.components.hitbox:SetAngle(90)
				inst.components.hitbox:SetSize(0.85)
				inst.components.hitbox:AddSuction(0.3, 0.0, 0)
				inst.components.hitbox:SpawnHitbox(0.0, 1.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0.0, 1.5, 0) 
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0.0, 1.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
			end),
			
			TimeEvent(11*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0.0, 1.5, 0) 
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
			end),
			
			TimeEvent(13*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				-- inst.components.hitbox:SetOnHit(function() 
					-- inst.AnimState:SetTime(13*FRAMES)
				-- end)
				
				inst.components.hitbox:SpawnHitbox(0.0, 1.5, 0) 
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
				inst.components.hitbox:MakeFX("taunt", -0.1, 2.5, -0.2,   0.4, 0.8,   1, 11, 0,  0,0,0, 0, "dragonfly_fx", "dragonfly_fx") 
				inst.components.hitbox:MakeFX("taunt", -0.1, 2.7, 0.2,   0.2, 0.4,   1, 11, 0,  0,0,0, 0, "dragonfly_fx", "dragonfly_fx") 
				
			end),
			
			TimeEvent(15*FRAMES, function(inst) --15
				inst.components.hitbox:AddNewHit()
				
				-- inst.components.hitbox:SetDamage(4) --IS IT NORMAL TO BE THIS SMALL???
				inst.components.hitbox:SetDamage(inst.components.stats.storagevar2) --TAKE THE DAMAGE SAVED AT THE TOP
				inst.components.hitbox:SetAngle(80) 
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(140) 
				inst.components.hitbox:SetSize(1)
				inst.components.hitbox:SetHitFX("invisible", "dontstarve_DLC001/creatures/deciduous/drake_pop_large")
				
				inst.components.hitbox:SpawnHitbox(0.1, 2.3, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/deciduous/drake_pop_large")
			end),
			
			TimeEvent(25*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			
            TimeEvent(35*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack") 
				inst.sg:RemoveStateTag("busy") 
				inst.sg:GoToState("idle")
			end),
        },
        
        -- events=
        -- {
            -- EventHandler("animover", function(inst)
                -- inst.sg:GoToState("idle")
				-- -- inst.AnimState:PlayAnimation("chop_pst")
				-- --inst.sg:RemoveStateTag("busy")
            -- end),
        -- },
    }, 
	
	
	
	
	--DEVELOPER TEST STATES
	--
	State{
        name = "dev_post_hitlag",
        tags = {"busy", "no_air_transition"},
        
        onenter = function(inst)
            --inst.AnimState:PlayAnimation("punch")
			--inst.AnimState:PlayAnimation("shovel_loop")
			inst.AnimState:PlayAnimation("dtilt")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
            -- print("NO GETTING AROUND THIS-", inst.customhpbadgepercent:value()) --turns out there is getting around it
			
			-- local anchor = TheSim:FindFirstEntityWithTag("anchor")
			-- local testplayer = "player" .. tostring(math.random())
			-- anchor.components.gamerules:AddToQue(testplayer)
			-- TheNet:Announce(tostring(testplayer))
        end,
        
        timeline=
        {
             -- TimeEvent(1*FRAMES, function(inst) print("dev_post_hitlag", "1") end),
			
			-- TimeEvent(2*FRAMES, function(inst) print("dev_post_hitlag", "2") end),
			
			TimeEvent(6*FRAMES, function(inst) 
				print("dev_post_hitlag", "6")
				inst.components.hitbox:SetDamage(8) --10 --60
				inst.components.hitbox:SetAngle(80)  --50 --64
				inst.components.hitbox:SetBaseKnockback(9)  --70
				inst.components.hitbox:SetGrowth(100)  --23

				--inst.components.hitbox:SetSize(0.6)
				-- inst.components.hitbox:SetSize(0.3)  --0.3  --5 OH GOD NOT 5
				inst.components.hitbox:SetSize(0.55, 0.35)  --0.3  --5 OH GOD NOT 5
				
				--inst.components.hitbox:MakeFX("lucy_archwoosh", xoffset, yoffset, xsize, ysize, alpha, duration)
				--inst.components.hitbox:MakeFX("lucy_archwoosh", 2, 1, 1, 1, 1, 4) --WHY IS THIS EVEN HERE???
				-- inst.components.hitbox:SpawnHitbox(1, 0.1, 0)
				-- inst.components.hitbox:SpawnHitbox(0.2, 0.1, 0) 
				inst.components.hitbox:SpawnHitbox(0.9, 0.15, 0) --1.1 KEEPS MISSING
				--inst.sg:RemoveStateTag("abouttoattack")
			end),
			
			TimeEvent(8*FRAMES, function(inst) 
				print("dev_post_hitlag", "8")
				inst.components.launchgravity:Launch(5, 16)
			end),
			
			-- TimeEvent(3*FRAMES, function(inst) print("dev_post_hitlag", "3") end),
			-- TimeEvent(4*FRAMES, function(inst) print("dev_post_hitlag", "4") end),
			-- TimeEvent(5*FRAMES, function(inst) print("dev_post_hitlag", "5") end),
			-- TimeEvent(6*FRAMES, function(inst) print("dev_post_hitlag", "6") end),
			-- TimeEvent(7*FRAMES, function(inst) print("dev_post_hitlag", "7") end),
			-- TimeEvent(8*FRAMES, function(inst) print("dev_post_hitlag", "8") end),
			TimeEvent(9*FRAMES, function(inst) print("dev_post_hitlag", "9") end),
			TimeEvent(10*FRAMES, function(inst) print("dev_post_hitlag", "10") end),
			TimeEvent(11*FRAMES, function(inst) print("dev_post_hitlag", "11") end),
			
			TimeEvent(12*FRAMES, function(inst) --7
				print("dev_post_hitlag", "12")
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0.9, 0.15, 0)
			end),
			
			TimeEvent(13*FRAMES, function(inst) print("dev_post_hitlag", "13") end),
			TimeEvent(14*FRAMES, function(inst) print("dev_post_hitlag", "14") end),
			
            TimeEvent(15*FRAMES, function(inst) --7
				print("dev_post_hitlag", "15")
				inst.sg:RemoveStateTag("attack") 
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
        name = "dev_post_hitlag2",
        tags = {"busy", "no_air_transition"},
        
        onenter = function(inst)
            --inst.AnimState:PlayAnimation("punch")
			--inst.AnimState:PlayAnimation("shovel_loop")
			inst.AnimState:PlayAnimation("dtilt")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
            -- print("NO GETTING AROUND THIS-", inst.customhpbadgepercent:value()) --turns out there is getting around it
			
			-- local anchor = TheSim:FindFirstEntityWithTag("anchor")
			-- local testplayer = "player" .. tostring(math.random())
			-- anchor.components.gamerules:AddToQue(testplayer)
			-- TheNet:Announce(tostring(testplayer))
        end,
        
        timeline=
        {
             -- TimeEvent(1*FRAMES, function(inst) print("dev_post_hitlag", "1") end),
			
			-- TimeEvent(2*FRAMES, function(inst) print("dev_post_hitlag", "2") end),
			
			TimeEvent(26*FRAMES, function(inst) 
				print("dev_post_hitlag", "26")
				inst.components.hitbox:SetDamage(8) --10 --60
				inst.components.hitbox:SetAngle(80)  --50 --64
				inst.components.hitbox:SetBaseKnockback(9)  --70
				inst.components.hitbox:SetGrowth(100)  --23

				--inst.components.hitbox:SetSize(0.6)
				-- inst.components.hitbox:SetSize(0.3)  --0.3  --5 OH GOD NOT 5
				inst.components.hitbox:SetSize(0.55, 0.35)  --0.3  --5 OH GOD NOT 5
				
				--inst.components.hitbox:MakeFX("lucy_archwoosh", xoffset, yoffset, xsize, ysize, alpha, duration)
				--inst.components.hitbox:MakeFX("lucy_archwoosh", 2, 1, 1, 1, 1, 4) --WHY IS THIS EVEN HERE???
				-- inst.components.hitbox:SpawnHitbox(1, 0.1, 0)
				-- inst.components.hitbox:SpawnHitbox(0.2, 0.1, 0) 
				inst.components.hitbox:SpawnHitbox(0.9, 0.15, 0) --1.1 KEEPS MISSING
				--inst.sg:RemoveStateTag("abouttoattack")
			end),
			
			TimeEvent(27*FRAMES, function(inst) 
				print("dev_post_hitlag", "27")
				inst.components.launchgravity:Launch(5, 16)
			end),
			
			TimeEvent(1*FRAMES, function(inst) print("dev_post_hitlag", "1") end),
			TimeEvent(2*FRAMES, function(inst) print("dev_post_hitlag", "2") end),
			TimeEvent(3*FRAMES, function(inst) print("dev_post_hitlag", "3") end),
			TimeEvent(4*FRAMES, function(inst) print("dev_post_hitlag", "4") end),
			TimeEvent(5*FRAMES, function(inst) print("dev_post_hitlag", "5") end),
			TimeEvent(6*FRAMES, function(inst) print("dev_post_hitlag", "6") end),
			TimeEvent(7*FRAMES, function(inst) print("dev_post_hitlag", "7") end),
			TimeEvent(8*FRAMES, function(inst) print("dev_post_hitlag", "8") end),
			TimeEvent(9*FRAMES, function(inst) print("dev_post_hitlag", "9") end),
			TimeEvent(10*FRAMES, function(inst) print("dev_post_hitlag", "10") end),
			TimeEvent(11*FRAMES, function(inst) print("dev_post_hitlag", "11") end),
			TimeEvent(12*FRAMES, function(inst) print("dev_post_hitlag", "12") end),
			TimeEvent(13*FRAMES, function(inst) print("dev_post_hitlag", "13") end),
			TimeEvent(14*FRAMES, function(inst) print("dev_post_hitlag", "14") end),
			TimeEvent(15*FRAMES, function(inst) print("dev_post_hitlag", "15") end),
			TimeEvent(16*FRAMES, function(inst) print("dev_post_hitlag", "16") end),
			TimeEvent(17*FRAMES, function(inst) print("dev_post_hitlag", "17") end),
			TimeEvent(18*FRAMES, function(inst) print("dev_post_hitlag", "18") end),
			TimeEvent(19*FRAMES, function(inst) print("dev_post_hitlag", "19") end),
			TimeEvent(20*FRAMES, function(inst) print("dev_post_hitlag", "20") end),
			TimeEvent(21*FRAMES, function(inst) print("dev_post_hitlag", "21") end),
			TimeEvent(22*FRAMES, function(inst) print("dev_post_hitlag", "22") end),
			TimeEvent(23*FRAMES, function(inst) print("dev_post_hitlag", "23") end),
			TimeEvent(24*FRAMES, function(inst) print("dev_post_hitlag", "24") end),
			TimeEvent(25*FRAMES, function(inst) print("dev_post_hitlag", "25") end),
			-- TimeEvent(26*FRAMES, function(inst) print("dev_post_hitlag", "26") end),
			-- TimeEvent(27*FRAMES, function(inst) print("dev_post_hitlag", "27") end),
			TimeEvent(28*FRAMES, function(inst) print("dev_post_hitlag", "28") end),
			TimeEvent(29*FRAMES, function(inst) print("dev_post_hitlag", "29") end),
			TimeEvent(30*FRAMES, function(inst) print("dev_post_hitlag", "30") end),
			TimeEvent(31*FRAMES, function(inst) print("dev_post_hitlag", "31") end),
			TimeEvent(32*FRAMES, function(inst) print("dev_post_hitlag", "32") end),
			TimeEvent(33*FRAMES, function(inst) print("dev_post_hitlag", "33") end),
			TimeEvent(34*FRAMES, function(inst) print("dev_post_hitlag", "34") end),
			TimeEvent(35*FRAMES, function(inst) print("dev_post_hitlag", "35") end),
			TimeEvent(36*FRAMES, function(inst) print("dev_post_hitlag", "36") end),
			TimeEvent(37*FRAMES, function(inst) print("dev_post_hitlag", "37") end),
			TimeEvent(38*FRAMES, function(inst) print("dev_post_hitlag", "38") end),
			TimeEvent(39*FRAMES, function(inst) print("dev_post_hitlag", "39") end),
			-- TimeEvent(40*FRAMES, function(inst) print("dev_post_hitlag", "40") end),
			TimeEvent(41*FRAMES, function(inst) print("dev_post_hitlag", "41") end),
			TimeEvent(42*FRAMES, function(inst) print("dev_post_hitlag", "42") end),
			TimeEvent(43*FRAMES, function(inst) print("dev_post_hitlag", "43") end),
			TimeEvent(44*FRAMES, function(inst) print("dev_post_hitlag", "44") end),
			
			TimeEvent(40*FRAMES, function(inst) --7
				print("dev_post_hitlag", "40")
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0.9, 0.15, 0)
			end),
			

			
            TimeEvent(45*FRAMES, function(inst) --7
				print("dev_post_hitlag", "45")
				inst.sg:RemoveStateTag("attack") 
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")				
			end),
        },
		
		onupdate = function(inst)
            -- inst.components.hitbox:MultiplyDamage(1.0113)
			print("LELP")
        end,
        
        events=
        {
            -- EventHandler("animover", function(inst)
                -- inst.sg:GoToState("idle")
            -- end),
        },
    },
	
	
	State{
        name = "dev_animframes",
        tags = {"busy", "no_air_transition"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dsmash_wilson")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
            -- print("NO GETTING AROUND THIS-", inst.customhpbadgepercent:value()) --turns out there is getting around it

        end,
        
        timeline=
        {
			-- TimeEvent(2*FRAMES, function(inst) inst.AnimState:SetTime(4*FRAMES) print("2") end),
			-- TimeEvent(3*FRAMES, function(inst) inst.AnimState:SetTime(4*FRAMES) print("3") end),
			TimeEvent(4*FRAMES, function(inst) inst.AnimState:SetTime(10*FRAMES) print("9") end),
			-- TimeEvent(12*FRAMES, function(inst) inst.AnimState:SetTime(4*FRAMES) print("12") end),
			-- TimeEvent(15*FRAMES, function(inst) inst.AnimState:SetTime(4*FRAMES) print("15") end),
			-- TimeEvent(18*FRAMES, function(inst) inst.AnimState:SetTime(4*FRAMES) print("18") end),
			-- TimeEvent(21*FRAMES, function(inst) inst.AnimState:SetTime(4*FRAMES) print("21") end),
			-- TimeEvent(24*FRAMES, function(inst) inst.AnimState:SetTime(4*FRAMES) print("24") end),
			
			-- TimeEvent(12*FRAMES, function(inst) inst.AnimState:SetTime(6*FRAMES) print("1") end),
			
			TimeEvent(2*FRAMES, function(inst) 
				-- inst.AnimState:SetTime(4*FRAMES)
				-- print("6")
				inst.components.hitbox:SetDamage(20) --10 --60
				inst.components.hitbox:SetAngle(80)  --50 --64
				inst.components.hitbox:SetBaseKnockback(9)  --70
				inst.components.hitbox:SetGrowth(100)  --23

				inst.components.hitbox:SetSize(0.55, 0.35)  --0.3  --5 OH GOD NOT 5
				
				inst.components.hitbox:SpawnHitbox(0.9, 0.15, 0) --1.1 KEEPS MISSING
			end),
			
			-- TimeEvent(8*FRAMES, function(inst) 
				-- inst.AnimState:SetTime(1*FRAMES)
			-- end),
			
			
            TimeEvent(35*FRAMES, function(inst) --7
				print("dev_post_hitlag", "15")
				inst.sg:RemoveStateTag("attack") 
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
        name = "dev_multihitlag",
        tags = {"busy", "no_air_transition"},
        
        onenter = function(inst)
            -- inst.AnimState:PlayAnimation("nspecial_retry")
			inst.AnimState:PlayAnimation("backward_tech")
        end,
		
		onupdate = function(inst)
            -- inst.components.hitbox:MultiplyDamage(1.0113)
			print("LELP")
        end,
        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(1.5)
				-- inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetAngle(366) 
				inst.components.hitbox:SetBaseKnockback(12) 
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetSize(1.0, 0.75)
				
				inst.components.hitbox:AddSuction(0.5, -0.3, 1.5)
				inst.components.hitbox:SetHitFX("invisible", "dontstarve/common/fireOut")
				
				
				
				
				inst.components.hitbox:SpawnHitbox(0.0, 1.5, 0) --2.5
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				-- inst.components.hitbox:SetDamage(1.5)
				inst.components.hitbox:SetAngle(90)
				inst.components.hitbox:SetSize(0.85)
				inst.components.hitbox:AddSuction(0.5, 1.0, 0)
				inst.components.hitbox:SpawnHitbox(1.0, 1.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				-- inst.components.hitbox:AddSuction(0, 1.0, 1.0)
				inst.components.hitbox:SpawnHitbox(1.0, 1.5, 0) 
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				-- inst.components.hitbox:AddSuction(0, 1.0, 1.0)
				inst.components.hitbox:SpawnHitbox(1.0, 1.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				-- inst.components.hitbox:AddSuction(0, 1.0, 1.0)
				inst.components.hitbox:SpawnHitbox(1.0, 1.5, 0) 
			end),
			
			TimeEvent(11*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				-- inst.components.hitbox:AddSuction(0, 1.0, 1.0)
				inst.components.hitbox:SpawnHitbox(1.0, 1.5, 0) 
			end),
			
			TimeEvent(13*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(1.0, 1.5, 0) 
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(1.0, 1.5, 0) 
			end),
			
			TimeEvent(17*FRAMES, function(inst) --15
				inst.components.hitbox:AddNewHit()
				
				-- inst.components.hitbox:SetDamage(4) --IS IT NORMAL TO BE THIS SMALL???
				inst.components.hitbox:SetDamage(15) --TAKE THE DAMAGE SAVED AT THE TOP
				inst.components.hitbox:SetAngle(80) 
				inst.components.hitbox:SetBaseKnockback(50)
				-- inst.components.hitbox:SetGrowth(140) 
				inst.components.hitbox:SetSize(5, 1)
				inst.components.hitbox:SetHitFX("invisible", "dontstarve_DLC001/creatures/deciduous/drake_pop_large")
				
				inst.components.hitbox:SpawnHitbox(1.1, 2.3, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/deciduous/drake_pop_large")
			end),
			
			TimeEvent(21*FRAMES, function(inst) 
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
	
	
	--IT... IT JUST WORKS NOW. FOR NO REASON. NOTHING I CHANGED INTERACTED WITH IT AT ALL
	State{
        name = "dev_axereplica",
        tags = {"busy", "no_air_transition"},
        
        onenter = function(inst)
            -- inst.AnimState:PlayAnimation("nspecial_retry")
			inst.AnimState:PlayAnimation("backward_tech")
			
			--HECK!! JUST TRANSFORM INTO WOODIE. WEREBEAVER IN REVERSE
			-- inst.AnimState:SetBank("spiderfighter") --spider_spitter
			-- inst.AnimState:SetBuild("newwoodie") --spider_harold  --DS_spider2_caves
			-- inst.AnimState:PlayAnimation("wsmash_positive_woodie_swing")
        end,
		
		onupdate = function(inst)
            inst.components.hitbox:MultiplyDamage(1.0113)
			print("LELP")
        end,
        
        timeline=
        {
            --[[
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(3.5)
				-- inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetAngle(366) 
				inst.components.hitbox:SetBaseKnockback(15) 
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetSize(1.0, 0.75)
				
				inst.components.hitbox:AddSuction(0.5, -0.3, 1.5)
				inst.components.hitbox:SetHitFX("invisible", "dontstarve/common/fireOut")
				
				inst.components.hitbox:SpawnHitbox(0.0, 1.5, 0)
			end),
			
			TimeEvent(11*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				-- inst.components.hitbox:SetDamage(1.5)
				inst.components.hitbox:SetAngle(90)
				inst.components.hitbox:SetSize(0.85)
				inst.components.hitbox:AddSuction(0.5, 1.0, 0)
				inst.components.hitbox:SpawnHitbox(1.0, 1.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
			end),
			
			
			
			-- TimeEvent(13*FRAMES, function(inst) 
				-- inst.components.hitbox:AddNewHit()
				-- inst.components.hitbox:SpawnHitbox(1.0, 1.5, 0) 
			-- end),
			
			TimeEvent(17*FRAMES, function(inst) --15
				inst.components.hitbox:AddNewHit()
				
				-- inst.components.hitbox:SetDamage(4) --IS IT NORMAL TO BE THIS SMALL???
				inst.components.hitbox:SetDamage(15) --TAKE THE DAMAGE SAVED AT THE TOP
				inst.components.hitbox:SetAngle(80) 
				inst.components.hitbox:SetBaseKnockback(50)
				-- inst.components.hitbox:SetGrowth(140) 
				inst.components.hitbox:SetSize(5, 1)
				inst.components.hitbox:SetHitFX("invisible", "dontstarve_DLC001/creatures/deciduous/drake_pop_large")
				
				inst.components.hitbox:SpawnHitbox(1.1, 2.3, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/deciduous/drake_pop_large")
			end),
			]]
			
			
			TimeEvent(4*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.components.jumper:ScootForward(8)
			end),
			
			TimeEvent(5*FRAMES, function(inst)
				inst.components.hitbox:SetAngle(55)
				-- inst.components.hitbox:SetBaseKnockback(10)
				-- inst.components.hitbox:SetGrowth(55)
				-- inst.components.hitbox:SetDamage(10)
				
				--7-8-17
				inst.components.hitbox:SetBaseKnockback(15)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetDamage(3.5) --5
				inst.components.hitbox:SetBlockDamage(5)
				inst.components.hitbox:AddSuction(0.5, 1.5, 0)
				

				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:SetLingerFrames(2)
				
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.components.hitbox:MakeFX("lucy_archwoosh", 3, 1, 1, 1, 1, 0.4, 8) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1, 1, 0) 
				
				inst.components.hitbox:SetBlockDamage(5)
				inst.components.hitbox:AddSuction(0.5, 1.5, 0)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(2, 1, 0)
			end),
			
			TimeEvent(9*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.components.jumper:ScootForward(8)
			end),
			
			TimeEvent(11*FRAMES, function(inst)
				--inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.components.hitbox:MakeFX("lucy_archwoosh", 3, 1, 1, 1, 1, 0.4, 4)
				
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SetBlockDamage(5)
				inst.components.hitbox:AddSuction(0.5, 1.5, -0.3)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1, 1, 0) 
				
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SetBlockDamage(5)
				inst.components.hitbox:AddSuction(0.5, 1.5, -0.3)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(2, 1, 0) 
			end),
			
			-- TimeEvent(19*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				-- inst.components.jumper:ScootForward(8)
			-- end),
			
			TimeEvent(17*FRAMES, function(inst) 
				inst.components.hitbox:SetAngle(48)
				inst.components.hitbox:SetBaseKnockback(85) 
				inst.components.hitbox:SetGrowth(85)
				-- inst.components.hitbox:SetDamage(13)
				inst.components.hitbox:SetDamage(13)
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:SetLingerFrames(3)

				inst.components.hitbox:MakeFX("lucy_archwoosh", 3, 1, 1, 1, 1, 0.4, 8) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1, 1, 0) 
				
					inst.components.hitbox:SetLingerFrames(3)
					inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(2, 1, 0)
				
				inst.sg:RemoveStateTag("scary")
			end),
			
			TimeEvent(40*FRAMES, function(inst) 
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
	
}







CommonStates.AddFrozenStates2(states)
CommonStates.AddRespawnPlatform(states)
CommonStates.AddDropSpawn(states)

--ssh clkursch@machine.secs.oakland.edu
--machine = beatles
--/home/machine

    
return StateGraph("wilson", states, events, "idle") --, actionhandlers)

