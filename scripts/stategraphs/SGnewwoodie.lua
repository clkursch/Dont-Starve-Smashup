--require("stategraphs/fighterstates") --3-6-17

local trace = function() end

local function DoFoleySounds(inst)

	for k,v in pairs(inst.components.inventory.equipslots) do
		if v.components.inventoryitem and v.components.inventoryitem.foleysound then
			inst.SoundEmitter:PlaySound(v.components.inventoryitem.foleysound)
		end
	end

    if inst.prefab == "wx78" then
        inst.SoundEmitter:PlaySound("dontstarve/movement/foley/wx78")
    end

end

--4-5 KEY BUFFER  --SHOULD I MAKE THIS A STATS.LUA FUNCTION?... NAH. THIS IS PROBABLY FASTER ANYWAYS
local function TickBuffer(inst)

	inst:PushEvent(inst.components.stats.event, {key = inst.components.stats.key, key2 = inst.components.stats.key2})
	inst.components.stats.buffertick = inst.components.stats.buffertick - 1
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
		local is_ducking = inst.sg:HasStateTag("ducking") --7-29-17
		
		
		-- if (TheWorld and TheWorld.ismastersim) or not TheWorld then --FOR DST ANIMATION BUGS
		if not inst.components.stats:DSTCheck() or (inst.components.stats:DSTCheck() and (TheWorld and TheWorld.ismastersim)) then
			if wantstoblock and not is_busy and not is_tryingtoblock then
				if is_jumping then
					-- inst.sg:GoToState("airdodge")
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
		
		if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event ~= "jump" then
			return end
			
		if inst.sg:HasStateTag("listen_for_atk") and inst.components.stats.event == "jump" then
			return end
		
		--4-23-20 - NEW SYSTEM TO INTEGRATE BUFFERED AIREALS
		if data.key and data.key == "ITSNIL" then --ALRIGHT YOU LITTLE- IF IT COMES BACK "ISNIL" HARDCODE THIS THING TO NIL BECAUSE SENDING IN NIL ISNT WORKING
			data.key = nil --THIS MAKES ME UNBELEIVABLY PISSED THAT THIS WORKS
		end
		if (can_jump and not is_airborn) or (not is_busy and not is_airborn) or ((can_jump or can_oos or can_ood) and not is_airborn) then
			if data.key and data.key ~= nil then --BASICALLY, IF AN ATTACK KEY WAS PRESSED ALONG WITH JUMP, SET THE BUFFER TO ATTACK AFTER THE JUMP
				inst.sg:GoToState("highleap")
				inst.components.stats:SetKeyBuffer("throwattack", data.key)
			else
				inst.sg:GoToState("highleap")
			end
		elseif (can_jump and inst.components.jumper.currentdoublejumps >= 1) or (not is_busy and inst.components.jumper.currentdoublejumps >= 1) then
			inst.sg:GoToState("doublejump")
			if data.key and data.key ~= nil then --SAME HERE
				inst.sg:GoToState("doublejump")
				inst.components.stats:SetKeyBuffer("throwattack", data.key)
				inst:PushEvent("throwattack", {key = data.key})
			else
				inst.sg:GoToState("doublejump")
			end
		elseif (can_jump or not is_busy) and is_airborn and data.key and data.key ~= nil then 
			inst.components.stats.event = "throwattack"
		end
		--4-23-20 INTERESTING, SOMTIMES THE BUFFER CAN RUN THIS AGAIN AND DETECT A BUFFERED ATTACK, EVEN AFTER THE JUMP STATE HAS STARTED WITHOUT ONE... LETS TRY AND RIG IT 
		if (inst.sg.currentstate.name == "highleap" or inst.sg.currentstate.name == "doublejump") and inst.sg.timeinstate == 0 then
			if data.key and data.key ~= nil then --SAME, BUT NOW YOU'RE ALREADY JUMPING SO JUST SET THE BUFFER
				inst.components.stats:SetKeyBuffer("throwattack", data.key)
			end
		end
	end),
	
	EventHandler("air_transition", function(inst)
		local is_busy = inst.sg:HasStateTag("busy")
		local no_air_transition = inst.sg:HasStateTag("no_air_transition")
		local used_first_jump = inst.components.jumper.jumping == 1 and inst.components.jumper.doublejumping == 0
		
		if not (inst.sg:HasStateTag("hanging") and not inst.components.launchgravity.islaunched) and not no_air_transition or not is_busy then --FIX THIS LATER --TODOLIST --FINALTDL
			inst.sg:GoToState("air_idle")
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
		
		-- if not is_busy and is_airborn and can_grab_ledge then
		if no_grab_ledge and not autosnap then
			--DO NOTHING
		elseif (can_grab_ledge or (not is_busy and is_falling)) and not pressing_down and not inst:HasTag("hitfrozen") then --8-29 ADDED CHECK FOR HITFROZEN TO FIX A BUG THAT CAUSED PHYSICS TO RESUME ON LEDGEGRAB
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
		elseif can_oos and inst.components.keydetector:GetBackward(inst) and not was_running then
			inst.components.locomotor:TurnAround()
			inst.sg:GoToState("roll_forward")
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
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
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
			else
				--ITS A TRAP! DONT REACT TO THIS
				inst.components.hitbox:MakeFX("half_circle_backward_woosh", 0.3, 1.0, 0.1,  -1.5, 2.1,   1, 6, 0)
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
		
		-- if pivoting then
		-- end
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
		---@@@@@@@ ADDED JUMPING
		--print("DO THE LOCOMOTION")
		--local is_jumping = inst.sg:HasStateTag("jumping") or inst.sg:HasStateTag("inknockback")
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
	
	--@@@@@@ MY OWN EVEN HANDLER
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
		if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event == "jump" then
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
			
		elseif inst.sg:HasStateTag("can_usmash") and inst.components.stats.tapjump and (data.key == "up" or data.key == "diagonalf" or data.key == "diagonalb") then
			inst.sg:GoToState("uptilt")
		
        --if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
		-- elseif not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
		elseif not inst.sg:HasStateTag("busy") or can_attack then --12-4
		
			
			if (can_oos or data.key == "block") and not airial then
				if data.key2 == "backward" then inst.components.locomotor:TurnAround() end
				inst.sg:GoToState("grab")
			elseif can_ood then
				inst.sg:GoToState("dtilt")
			
			--if airial and not airial == 0 then
			elseif airial then
				
				if data.key == "backward" then 
					inst.sg:GoToState("bair")
				elseif data.key == "diagonalb" then 
					if inst.components.stats.tapjump then
						inst.sg:GoToState("bair")
					else
						inst.sg:GoToState("uair_2")
					end
				elseif data.key == "forward" then 
					inst.sg:GoToState("fair")
				elseif data.key == "diagonalf" then
					if inst.components.stats.tapjump then
						inst.sg:GoToState("fair")
					else
						inst.sg:GoToState("uair_2")
					end
				elseif data.key == "down" then
					inst.sg:GoToState("dair")
				elseif data.key == "up" then
					inst.sg:GoToState("uair_2")
				else
					-- inst.sg:GoToState("nair")
					inst.sg:GoToState("uair")
				end
				inst.components.jumper:UnFastFall()
			else
				inst.components.locomotor:Stop()
				
				--OLD REMOVING 10-13
				-- if inst.components.keydetector:GetUTilt() then 
					-- inst.sg:GoToState("uptilt")
					-- print("SHORYUKEN")
				-- elseif inst:HasTag("dtilt") then
					-- inst.sg:GoToState("dtilt")
				-- else
				
				
				if data.key == "up" or data.key == "diagonalf" then 
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
		local is_busy = inst.sg:HasStateTag("busy") and not can_attack --8-29-20 JUST FOR TEMPLATE. ADD TO OTHERS LATER, BUT NOT REQUIRED
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
				inst.sg:GoToState("uptilt")
			end
		elseif not is_busy and airial then
			inst.sg:GoToState("uair_2")
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
		local is_tryingtoblock = inst.sg:HasStateTag("tryingtoblock")  --721
		local is_busy = inst.sg:HasStateTag("busy") or is_tryingtoblock --721 7-21-17 JUST THROWING THIS ON BUSY BC IM LAZY. AND THERE ARE ONLY A FEW INSTANCES IN WHICH TRYINGTOBLOCK NEEDS UNBUSY
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
		
		-- if must_fsmash and is_forward then  --7-20-17 ITS GOOD TO LEAVE THIS HERE OR ELSE DASH ATTACKS GET WIERD
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
		local is_tryingtoblock = inst.sg:HasStateTag("tryingtoblock") --721
		
		if not inst.sg:HasStateTag("busy") or can_special_attack or (inst.sg:HasStateTag("can_upspec") and (data.key == "up" or data.key == "diagonalf" or data.key == "diagonalb")) then
			-- if inst.components.keydetector:GetUp() then
			if data.key == "up" then
				inst.sg:GoToState("uspecial")
			elseif data.key == "diagonalf" then		--ADDING DIAGONALS  --TODOLIST: FIX THIS SO IT'S LIKE EVERYONE ELSE'S
				if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
				inst.sg:GoToState("uspecial")
			elseif data.key == "diagonalb" then
				if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("uspecial")
			elseif data.key == "down" then
				inst.sg:GoToState("dspecial")
			elseif data.key == "forward" then
				if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
				inst.sg:GoToState("fspecial")
			elseif data.key == "backward" then
				if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
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
        
		--FIXED IDLE ANIMATION
		onenter = function(inst)
			inst.AnimState:PlayAnimation("idle")
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
        
		
		--FIXED IDLE ANIMATION
		onenter = function(inst)
			inst.AnimState:PlayAnimation("idle_air")
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
		end,
		
    },

    
    State{
        name = "run_start",
        tags = {"moving", "running", "canrotate", "must_roll"},
        
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

        -- events=
        -- {   
            -- EventHandler("animover", function(inst) inst.sg:GoToState("run") end ),        
        -- },
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
                inst.sg:AddStateTag("ignore_ledge_barriers")
				inst.sg:RemoveStateTag("must_roll")
            end),
            
			TimeEvent(6*FRAMES, function(inst)
                PlayFootstep(inst)
                DoFoleySounds(inst)
				-- inst.sg:GoToState("run")
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
        end,

        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.sg:RemoveStateTag("must_roll")
			end),
			TimeEvent(2*FRAMES, function(inst)
				inst.sg:RemoveStateTag("must_fsmash")
			end),
			
            TimeEvent(7*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.2, 0.2, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst:PushEvent("dash") 
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
            EventHandler("animover", function(inst)
				-- inst:PushEvent("dash") 
				--inst.sg:GoToState("dash")
				
			end ),
			
			EventHandler("block_key", function(inst)   --9-7  DOESNT WORK?... FIX THIS --THEFIXLIST
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
                DoFoleySounds(inst)
				--inst.components.hitbox:MakeFX("dahswoosh", 0, 1, -1, 1, 1, 0.8, 7, 1)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.2, 0.2, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
            end),
            TimeEvent(15*FRAMES, function(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
                DoFoleySounds(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.5, 0.5, 0.8, 5, 0)
            end),
        },
        
        events=
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("dash") end ),
			
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
        tags = {"canrotate", "dashing", "sliding", "keylistener", "keylistener2"},
        
        onenter = function(inst) 
			inst.AnimState:PlayAnimation("dash_pst")
			inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1, 1, 0.5, 0.8, 10, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
            
        end,

        timeline=
        {
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
					inst.components.locomotor:TurnAround()
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
				if inst.components.keydetector:GetForward(inst) then
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
			
			
			if ISGAMEDST and not TheWorld.ismastersim then --11-26-17
				return --CLIENTS DONT RUN BELOW THIS LINE
			end
			
			local attack_cancel_modifier = hitstun * 0.9
			local dodge_cancel_modifier = hitstun * 1.2
			
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
        end,
        
        timeline =
        {
            TimeEvent(2*FRAMES, function(inst)   --HAVE VOICE CUT OFF --TODOLIST
				inst.SoundEmitter:KillAllSounds()  
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
			-- inst.AnimState:PlayAnimation("ledge_getup")
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
		tags = {"busy", "hanging", "intangible"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_jump")
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
		tags = {"busy", "intangible", "nolandingstop"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_getup")
			inst.Physics:SetActive(false) --CAREFUL WITH THIS
        end,
        
		timeline =
        {
			TimeEvent(6*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				inst.AnimState:PlayAnimation("rolling")
				inst.components.locomotor:RunForward() --11-11-17 MUCH CLEANER AND CONSISTANT METHOD FOR ROLLING
				inst.components.locomotor:Teleport(0, 0.1, 0) --MAYBE A TELEPORT IS NEEDED TO AVOID BUMPING INTO THE LIP OF THE LEDGE
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
			inst.AnimState:PlayAnimation("woodie_ledge_attack")
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
			
			TimeEvent(10*FRAMES, function(inst)
				-- inst.sg:RemoveStateTag("intangible")
				-- inst.components.jumper:ScootForward(8)
				inst.components.hitbox:MakeFX("half_circle_up_woosh", 0.8, 0, 0.1,  3.5, 3.5,   1, 10, 0)
				
			end),
			
			TimeEvent(11*FRAMES, function(inst) --WHAT ARE THE ATTACK VALUES OF GETUP ATTACKS??? ITS NOT LISTED ANYWHERE!!
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetDamage(4)   --7
				inst.components.hitbox:SetHitLag(0.3)
				inst.components.hitbox:SetCamShake(0.3)
				inst.components.hitbox:SetHighlight(0.3)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0)
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SpawnHitbox(2.0, 0.5, 0) 
			end),
			
			TimeEvent(13*FRAMES, function(inst)
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
				inst:AddTag("listenforfullhop") --10-20-17 A NEW IMPROVED ATTEMPT AT FULLHOP REGISTRATION.
				inst.components.jumper:Jump(inst) --LETS BUMP THIS DOWN A LINE OR TWO
				inst.sg:RemoveStateTag("can_usmash")
				
				inst:DoTaskInTime(2*FRAMES, function(inst) --NOW ALWAYS CHECKS IN 4 FRAMES
					inst.components.jumper:CheckForFullHop()
				end)
			end),
			
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
			inst.AnimState:PlayAnimation("doublejump")
			-- inst.components.jumper:Jump()
			inst.components.jumper:DoubleJump(inst) --1-5
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
        
        onenter = function(inst, hitstun, direction)
			
			inst.components.stats.norecovery = false
			
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
			
			if ISGAMEDST and not TheWorld.ismastersim then --11-26-17
				return --CLIENTS DONT RUN BELOW THIS LINE
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
				inst.sg:RemoveStateTag("reeling") --10-20-18 TREAT ALL PLAYER GRAVITIES THE SAME WHILE REELING!
				
				--3-15 GONNA TRY AND ADD SOMETHING THAT CANCELS OUT MOMENTUM SO YOU ARENT FORCED TO JUMP TO SURVIVE
				inst.components.jumper:AirStall(2, 1)
			end)
			
			inst.task_attackstun = inst:DoTaskInTime((attack_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:AddStateTag("can_attack")
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
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
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
			inst.AnimState:PlayAnimation("clumsy_land")  --clumsy_land_004
			inst.components.hitbox:MakeFX("ground_bounce", -0.5, 0.1, -1, 1.5, 1.5, 0.8, 10, 0)
			inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
			--inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/explode")
			inst:PushEvent("swaphurtboxes", {preset = "grounded"})
        end,

        onexit = function(inst)

        end,
        
        timeline =
        {
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0, 0.5)
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0, -0.5)
				inst.sg:GoToState("grounded") --9-9 MOVING IT DOWN HERE TO FIX GROUNDED GETUP LAG
			end),
			
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
            --TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
			--TimeEvent(7*FRAMES, function(inst) inst.components.hitbox:SpawnHitbox(3, -3, 3) inst.sg:RemoveStateTag("abouttoattack") end),
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
			
			TimeEvent(9*FRAMES, function(inst) 
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
            inst.AnimState:SetMultColour(1,1,1,0.3)
			--inst.AnimState:PlayAnimation("pickup")
			inst.AnimState:PlayAnimation("tech0_003")
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
				inst.AnimState:PlayAnimation("tech0_003")
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
			inst.AnimState:PlayAnimation("block_startup_woodie")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			-- inst.components.blocker:StartConsuming()
			
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
        tags = {"canrotate", "blocking", "tryingtoblock", "canoos", "no_running"},  --"attack", "busy", "jumping" --12-30 ADDED NO_RUNNING. SEEMS TO WORK WELL
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("block_woodie")
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
			-- inst.components.hitbox:MakeFX("shockwave_parry", 0.5, 1.5, 1, 1.5, 1, 1, 8)
			inst.components.hitbox:MakeFX("shockwave_parry", 0.5, 1.5, 1, 1, 1.8, 1, 12, 1)
			inst.AnimState:PlayAnimation("block_woodie")
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
	

	
	--3-22 NEW VERSION
	State{
        name = "block_stunned",
        tags = {"blocking", "tryingtoblock", "busy", "block_stunned"},  --"attack", "busy", "jumping"
        
        onenter = function(inst, timeout)
			inst.AnimState:PlayAnimation("blockstunned_woodie") --blockstunned_long
			inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_dull")
			-- print("BLOCKSTUNNED TIMEOUT", timeout)
			inst.sg:SetTimeout(timeout or 1)
        end,
		
		ontimeout= function(inst)
            -- print("TIMEOUT REACHED! BLOCKSTUN HAS ENDED")
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
			inst.AnimState:PlayAnimation("blockstunned_resume_woodie")
			-- print("STATE: BLOCK_UNSTUNNED")
			
			if inst:HasTag("wantstoblock") then --1-20-17 SO THIS STATE IS JUST POINTLESS NOW I GUESS?
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
			inst.AnimState:PlayAnimation("block_drop_woodie")
			-- print("BLOCK_STOP")
        end,
		
		onupdate = function(inst)
			--CHEAP HOTFIX TO ENSURE THIS STATE DOESN'T ADD EXTRA FRAMES TO THE ENDLAG
        end,
        
        timeline =
        {
			TimeEvent(3*FRAMES, function(inst)
				inst.sg:GoToState("idle")
				-- print("GO TO IDLE")
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
				--inst.AnimState:PlayAnimation("wakeup")
				inst.sg:RemoveStateTag("intangible")
			end),
			
            TimeEvent(150*FRAMES, function(inst)
				inst.sg:GoToState("idle") --11-17 GONNA NEED THIS LATER
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
				inst.components.hitbox:MakeFX("stars", 0.5, 2.5, 1, 1, 1, 1, 65, 0.2)  --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
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
        tags = {"dodging", "busy"},  
        
        onenter = function(inst, target)
            -- inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
			--inst.AnimState:PlayAnimation("chop_pre")
			inst.AnimState:PlayAnimation("rolling")
			inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			
			-- inst.task_1 = inst:DoPeriodicTask(0.1, function(inst)
					-- inst.Physics:SetMotorVel(14, 0, 0) --10
				-- end)
				
			inst.components.locomotor:Motor(14, 0, 6) 
        end,

        onexit = function(inst)
			--inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.locomotor:Clear()
			-- if inst.task_1 then
				-- inst.task_1:Cancel()
			-- end
			if inst.motortask then
				inst.motortask:Cancel()
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
		     end),
		   
			TimeEvent(4*FRAMES, function(inst)
				inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
		    end),
			
			TimeEvent(6*FRAMES, function(inst) --7
				-- inst.task_1:Cancel()
			end),
            
			TimeEvent(8*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst.components.hitbox:MakeFX("slide1", 1.5, 0, -0.2,   -0.8, 0.8,   0.6, 8, 0)
				inst.AnimState:SetMultColour(1,1,1,1)
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
			inst.AnimState:PlayAnimation("airdodge") --spotdodge_air
			inst.components.launchgravity:SetLandingLag(10)
        end,

        onexit = function(inst)
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline =
        {		
           -- -- TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
		   TimeEvent(1*FRAMES, function(inst) 
				inst.sg:AddStateTag("intangible")
				-- inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
				-- inst.components.hitbox:Blink(inst, 4,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
				inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow, alpha)
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

        end,

        onexit = function(inst)
            --inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true) --THE HECK IS THIS HERE FOR?
        end,
        
        timeline =
        {
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(0.5)
			
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
			inst.SoundEmitter:PlaySound("smash_sounds/grab/grab1")
			inst.components.stats.opponent.Physics:SetActive(false)
			inst.Physics:Stop()
        end,
		
		onexit = function(inst)
			if not inst.components.stats:GetOpponent() then return end
			inst.components.stats.opponent.Physics:SetActive(true)
		end,
        
        timeline =
        {

            TimeEvent(60*FRAMES, function(inst)
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
        tags = {"busy", "nolandingstop"},  --"attack", "busy", "jumping"
        
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
			
			
			TimeEvent(6*FRAMES, function(inst)

				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(55) 
				inst.components.hitbox:SetBaseKnockback(98)
				inst.components.hitbox:SetGrowth(35)
				inst.components.hitbox:SetSize(1)
				inst.components.hitbox:SetLingerFrames(2)

				inst.components.hitbox:SpawnHitbox(1, 1, 0) 
			end),
			
			TimeEvent(15*FRAMES, function(inst)
				-- inst.AnimState:PlayAnimation("fthrow")
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
			inst.AnimState:PlayAnimation("throwing_000")
			inst.AnimState:Resume()
			
			inst.components.locomotor:TurnAround()
			inst.components.stats.opponent.components.locomotor:TurnAround()
			inst.components.jumper:ScootForward(-6)
			inst:AddTag("refresh_softpush") --3-2-17 HOPEFULLY FIXES THE WEIRD LEDGETHROWING THING --IT DID
        end,
        
        timeline =
        {
            --TimeEvent(0*FRAMES, function(inst) self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0) end),
			
			TimeEvent(8*FRAMES, function(inst)   --16
				inst.components.stats:GetOpponent()
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

			
			
			TimeEvent(9*FRAMES, function(inst)   --16
				-- inst.components.hitbox:SetKnockback(10, 15)
				-- --inst.components.hitbox:SetKnockback(0, -25)
				-- inst.components.hitbox:SetHitLag(0.4)
				-- inst.components.hitbox:SetCamShake(0.5)
				-- inst.components.hitbox:SetHighlight(0.5)
				inst.components.hitbox:SetKnockback(9, 12)
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(55) --SAKURAAAIIII!
				inst.components.hitbox:SetBaseKnockback(98)
				inst.components.hitbox:SetGrowth(35)
				inst.components.hitbox:SetHitLag(0.3)
				inst.components.hitbox:SetCamShake(0.3)
				inst.components.hitbox:SetHighlight(0.3)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(2)
				inst.components.hitbox:SetLingerFrames(2)
				
				
				inst.components.hitbox:SpawnHitbox(2, 0, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			TimeEvent(20*FRAMES, function(inst)   --16
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
        tags = {"busy", "helpless", "ll_medium", "can_grab_ledge"},  --"attack", "busy", "jumping"
        
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
        tags = {"busy"},  --"attack", "busy", "jumping"
        
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
        tags = {"attack", "notalking", "busy", "ll_medium", "autocancel", "force_direction"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("fair")
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			-- inst.components.hurtboxes:ShiftHurtboxes(0, 0.6) --THIS MAKES IT LOOK WEIRD. FIX IT LATER. --THEFIXLIST
			inst.components.launchgravity:SetLandingLag(9)
		end,
        
        timeline=
        {
			
			TimeEvent(2*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("autocancel")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/swish")
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(10) --7-31-17 GOING DOWN FROM 12 CUZ THATS PRETTY CRAZY
				inst.components.hitbox:SetAngle(50)  --361
				inst.components.hitbox:SetBaseKnockback(30) 
				inst.components.hitbox:SetGrowth(100)
				
				-- inst.components.hitbox:SetSize(0.4)	--SHOULDER HITBOX
				-- inst.components.hitbox:SetLingerFrames(2)
				-- inst.components.hitbox:SpawnHitbox(0.3, 0.6, 0)

				inst.components.hitbox:SetSize(1)
				inst.components.hitbox:SetLingerFrames(0)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.9, 1.7, 0)  --(1.2, 2.0, 0)  --(1, 2.5, 0) 
				--inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/swipe")
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
			end),
			
			TimeEvent(8*FRAMES, function(inst)
				
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				-- inst.components.hitbox:SpawnHitbox(1.8, 0.4, 0)  --(1.5, 1, 0)
				inst.components.hitbox:SpawnHitbox(1.5, 0.4, 0)
				
				inst:PushEvent("swaphurtboxes", {preset = "fair"})
				
			end),
			
			-- TimeEvent(9*FRAMES, function(inst) 
				-- inst.components.hitbox:SetLingerFrames(2)
				-- inst.components.hitbox:MakeDisjointed()
				-- inst.components.hitbox:SpawnHitbox(1.5, -0.2, 0)  --(1.0, -0.5, 0) 
			-- end),
			
			TimeEvent(10*FRAMES, function(inst)  --11
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(1)--3
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.7, -0.4, 0)  --(1.0, -0.5, 0)
				--WE SHOULD HOPE TO AVOID SPAWNING HITBOXES SO LOW INTO THE NEGATIVES LIKE THIS FOR NON DOWN-AIRS
			end),
			
			TimeEvent(18*FRAMES, function(inst)   --AUTOCANCEL KICKS IN REAL EARLY, LIKE IKE'S DOES
				inst.sg:AddStateTag("autocancel")
			end),
			
            TimeEvent(23*FRAMES, function(inst)   --16 --21
				inst.sg:GoToState("air_idle")
			end),
        },
    },
	
	
	State{
        name = "bair",
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("bair")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.components.launchgravity:SetLandingLag(6)
        end,
        
        timeline=
        {
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("woosh1", -0.2, 0.6, -0.2,   -1.2, 2.0,   0.7, 4, 0.4,   0, 0, 0, 1)
				--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				
				inst.components.hitbox:SetDamage(12)
				inst.components.hitbox:SetAngle(-361)  --(45)
				inst.components.hitbox:SetBaseKnockback(35)
				inst.components.hitbox:SetGrowth(100)

				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-1.5, 0.35, 0) 
				inst.components.hitbox:SpawnHitbox(-0.4, 0.35, 0) 
			end),
			
			
			TimeEvent(11*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(4)
				inst.components.hitbox:SetAngle(80)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-1.5, 0.35, 0) 
				inst.components.hitbox:SpawnHitbox(-0.4, 0.35, 0) 
			end),
			
			
            TimeEvent(25*FRAMES, function(inst) 
				inst.sg:GoToState("air_idle")
			end),
        },
    },
	
	
	State{
        name = "dair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("dair")
			
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.launchgravity:SetLandingLag(8) --12 --15 --OK ACUALLY LETS GIVE IT JUST CRAZY LOW LANDING LAG. WHY NOT -12-14-18
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				-- inst.components.hitbox:MakeFX("woosh1down", 0.6, 0.95, 0.1,   1.6, 0.0,   0.9, 5, 0,   0,0,0, 1)
				inst.components.hitbox:MakeFX("woosh1down", 0.6, 0.95, 0.1,   1.6, 2.0,   0.0, 5, 0,   0.8,0,0, 1)
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(13)
				inst.components.hitbox:SetAngle(270)
				inst.components.hitbox:SetBaseKnockback(10)
				inst.components.hitbox:SetGrowth(90)
 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:SetSize(0.7, 0.8) --0.5,0.5
				
				inst.components.hitbox:SpawnHitbox(1.2, 0.6, 0) 
			end),
			
			TimeEvent(8*FRAMES, function(inst) 
				
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SetSize(0.6, 0.85) --0.4, 0.85
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.6, -0.4, 0) 
			end),
			
			
            TimeEvent(23*FRAMES, function(inst)  --26
				inst.sg:GoToState("air_idle")
			
			end),
        },
    },
	
	
	State{
        name = "nair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("nair")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.AnimState:SetTime(2*FRAMES)
            
        end,
		
        
        timeline=
        {
            TimeEvent(2*FRAMES, function(inst) 
				inst.components.launchgravity:SetLandingLag(5)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/swipe")
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(9)
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.6)
				
				-- inst.components.hitbox:SetLingerFrames(9)
				-- inst.components.hitbox:MakeDisjointed()
				-- inst.components.hitbox:SpawnHitbox(0.2, 0.5, 0)
				
				-- inst.components.hitbox:MakeFX("shockwave_side", 0, 1, 1, 0.8, 0.8, 1, 8, 1)
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(0.85)
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:MakeDisjointed()
				-- inst.components.hitbox:SpawnHitbox(1.0, 1.5, 0)
				inst.components.hitbox:SpawnHitbox(0.70, 1.25, 0)
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.1, 0.7, 0)
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.0, 0.1, 0)
			end),
			
			TimeEvent(8*FRAMES, function(inst) 
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.6, -0.3, 0)
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-0.1, -0.5, 0)
			end),
			
			TimeEvent(10*FRAMES, function(inst) 
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-0.4, -0.5, 0)
			end),
			
			TimeEvent(11*FRAMES, function(inst) 
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-0.7, -0.25, 0)
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-0.75, 0.75, 0)
			end),
			
			
            TimeEvent(22*FRAMES, function(inst) 
				inst.sg:GoToState("air_idle")
			end),
        },
		
		-- events= --HE KEEPS TURNING INVISIBLE SO IM JUST GONNA THROW THIS ON THE END FOR THIS ONE MOVE
        -- {
            -- EventHandler("animover", function(inst) 
                -- inst.sg:GoToState("air_idle")
            -- end),
        -- },
    },
	
	
	State{
        name = "uair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("uair")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.components.launchgravity:SetLandingLag(3)
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("woosh1upd", 0.0, 0.5, 0.1,   0.8, 1.5,   0.9, 7, 1,  0,0,0,  1)
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hurtboxes:SpawnHurtboxTemp(-0.65, 0.3, 0.5, 0, 12)
				
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(85) 
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.55,0.72)
				
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(0.33, 0.8, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
            TimeEvent(13*FRAMES, function(inst) 
			-- inst.sg:RemoveStateTag("attack") 
			-- inst.sg:RemoveStateTag("busy")
			inst.sg:GoToState("air_idle")
			
			end),
        },
        
        -- events=
        -- {
            -- EventHandler("animover", function(inst)
                -- inst.sg:GoToState("air_idle")
            -- end),
        -- },
    },
	
	
	State{
        name = "uair_2",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("uair_2")
        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/swish")
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				inst.components.launchgravity:SetLandingLag(8)
				inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				-- inst.components.hurtboxes:SpawnHurtboxTemp(0.65, 0.6, 0.5, 0, 12)
				
				inst.components.hitbox:SetDamage(11)
				inst.components.hitbox:SetAngle(80) 
				inst.components.hitbox:SetBaseKnockback(55)
				inst.components.hitbox:SetGrowth(80) --94
				inst.components.hitbox:SetSize(0.9)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(1.0, 1.3, 0) 
				
				--AND A SOURSPOT
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(3)
				inst.components.hitbox:SpawnHitbox(0, 0.8, 0) 
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(11)
				inst.components.hitbox:SetSize(1.1)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(0.2, 2.1, 0) 
			end),
			
			TimeEvent(8*FRAMES, function(inst) 
				
				inst.components.hitbox:SetSize(0.9)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(-1.4, 1.6, 0) 
			end),
			
            TimeEvent(28*FRAMES, function(inst) 
				inst.sg:GoToState("air_idle")
			
			end),
        },
        
    },
	
	State{
        name = "jab1",
        tags = {"attack", "short", "busy"}, --"armor"
        
        onenter = function(inst)
            -- inst.sg.statemem.target = inst.components.combat.target
            -- inst.components.combat:StartAttack()
            -- inst.components.locomotor:Stop()
            --inst.AnimState:PlayAnimation("punch")
			--inst.AnimState:PlayAnimation("idle_6 close enough_004")
			inst.AnimState:PlayAnimation("jab1")
			-- inst.AnimState:PlayAnimation("wickerdownb")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			--inst.components.hitbox:MakeFX("portal_spin", 0, 3, 1, 1, 1.5, 1, 90, 0)
			inst:PushEvent("swaphurtboxes", {preset = "leanf"})
		end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(5) --15
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetDamage(2) --3
				inst.components.hitbox:SetSize(0.6, 0.4)
				inst.components.hitbox:SetLingerFrames(1) --3
				
				inst.components.hitbox:AddSuction(0.5, 1.1, -0.5)
				inst.components.hitbox:SpawnHitbox(1.1, 1.2, 0) 

			end),
			
			TimeEvent(4*FRAMES, function(inst)
				inst.sg:AddStateTag("jab1") 
			end),
			
            TimeEvent(12*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
				-- inst.sg:GoToState("idle")
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
        tags = {"attack", "listen_for_attack", "busy", "short"}, --"noclanking"
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jab_2")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)	
				inst.components.hurtboxes:ShiftHurtboxes(0.5, 0) --12-19 THIS IS REALLY DUMB THAT I HAVE TO DO THIS
				
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(10)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetDamage(2)
				
				inst.components.hitbox:AddSuction(0.5, 1.1, -1)
				
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox.property = 4
				
				inst.components.hitbox:SpawnHitbox(1.3, 0.5, 0) 
				
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.sg:AddStateTag("jab2")
			end),
			
            TimeEvent(18*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
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
			inst.AnimState:PlayAnimation("jab_3_woodie")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.components.jumper:ScootForward(8)

            inst:PushEvent("swaphurtboxes", {preset = "leanf"})
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(90)
				inst.components.hitbox:SetDamage(7)   --7
				inst.components.hitbox:SetSize(0.5)
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.5, 2.2, 0)  
			end),
			
			TimeEvent(3*FRAMES, function(inst)
				
				--inst.components.hitbox:SetKnockback(10, 15)
				inst.components.hitbox:SetKnockback(30, 45)
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(90)
				inst.components.hitbox:SetDamage(8)   --7
				inst.components.hitbox:SetSize(1.5)
				inst.components.hitbox:SetLingerFrames(3)
				
				inst.components.hitbox:MakeDisjointed()
				-- inst.components.hitbox:SpawnHitbox(1.4, 0.7, 0) 
				
				inst.sg:AddStateTag("jab1") 
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.jumper:ScootForward(2)
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				TheCamera:Shake("FULL", .20, .01, .2) --Camera:Shake(type, duration, speed, scale) 
				inst.components.hitbox:MakeFX("anim", 2, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.components.hitbox:MakeFX("ground_smash", 2.5, -0.1, 0.2, -1.5, 1.5, 1, 12, 0)
				
				inst.components.hitbox:SetSize(1.4, 1.2)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(1.5, 0.7, 0) 
			end),
			
            TimeEvent(20*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
			end),
			
			TimeEvent(25*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
        
    },
	
	
	
	State{
        name = "dash_attack",
        tags = {"busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("woodie_dash_attack")
			-- inst.Physics:SetFriction(.5)
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/explo")
			-- inst:PushEvent("swaphurtboxes", {preset = "sliding"})
			
        end,
		
        
        timeline=
        {
			
			TimeEvent(2*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("half_circle_forward_woosh", 1.4, 1, 0.1,  2.3, 1.5,   1, 10, 1)
			end),
			
			TimeEvent(4*FRAMES, function(inst)
				-- inst.components.hitbox:SetKnockback(5, 15)
				-- inst.components.hitbox:SetKnockback(12, 12)
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(60)
				inst.components.hitbox:SetBaseKnockback(80)
				inst.components.hitbox:SetGrowth(60)
				inst.components.hitbox:SetSize(1.3, 0.8)  
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(1.3, 0.7, 0) 
			end),
			
			
			TimeEvent(21*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			
			
            TimeEvent(22*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
			end),
			
			TimeEvent(25*FRAMES, function(inst) 
				inst.sg:GoToState("idle")				
			end),
        },
    },
	
	
	State{
        name = "ftilt",
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst)
			
			-- 11-17-17 SLUETH WORK
			-- local dummy = TheSim:FindFirstEntityWithTag("punchingbag")
			-- local dummy = TheSim:FindFirstEntityWithTag("wilson")
			-- local x, y, z = inst.Transform:GetWorldPosition()
			-- if dummy and dummy ~= inst then
				-- dummy.Transform:SetPosition( x+1.5, y, z )
				-- dummy.sg:GoToState("idle")
				-- dummy.components.launchgravity:Launch(0, 0, 0)
			-- end
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			inst.AnimState:PlayAnimation("ftilt") --DONT BE A DUMMY, JUST MAKE A SECOND STATE WITH RE-FTILT
        end,
        
        timeline=
        {
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
				inst.components.hitbox:MakeFX("woosh1", 0.2, 0.6, 0.1,   1.7, 2,   0.8, 4, 0)
			end),
			
			TimeEvent(5*FRAMES, function(inst) --3
				inst.components.hitbox:SetDamage(11)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(40) --35
				inst.components.hitbox:SetGrowth(90) --110
				inst.components.hitbox:SetSize(1.25, 0.3)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SetOnHit(function() 
					inst.AnimState:SetTime(8*FRAMES)
				end)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.35, 0.75, 0)  
			end),
			
            TimeEvent(13*FRAMES, function(inst) --20
				-- inst.sg:RemoveStateTag("attack")
				-- inst.sg:RemoveStateTag("busy")
				
				inst.sg:AddStateTag("retilt")
			end),
			
			TimeEvent(20*FRAMES, function(inst) --20
				inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {
            EventHandler("throwattack", function(inst)
                if inst.sg:HasStateTag("retilt") and not inst.components.keydetector:GetBackward(inst) then
					
					inst:AddTag("skiptiltanim")
					inst.sg:GoToState("re-ftilt")
					-- inst.AnimState:Pause() --PAUSE AT THE APEX OF THE SWING
					inst:DoTaskInTime(5*FRAMES, function(inst) --ITS GOTTA WAIT A SEC
						-- inst.sg:AddStateTag("skiptiltanim")
						inst:RemoveTag("skiptiltanim")
					end)
				end
            end),
        },
    },
	
	
	
	State{
        name = "re-ftilt",
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("ftilt")
			inst.AnimState:SetTime(3*FRAMES)
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
				inst.components.hitbox:MakeFX("woosh1", 0.2, 0.6, 0.1,   1.7, 2,   0.8, 4, 0)
			end),
			
			TimeEvent(2*FRAMES, function(inst) --3
				inst.components.hitbox:SetDamage(7) --OK IM NOT HAVING EVERY HIT AFTER THAT ALSO DO 12 DAMAGE
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(40) --35
				inst.components.hitbox:SetGrowth(90) --110
				inst.components.hitbox:SetSize(1, 0.3)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.45, 0.75, 0)  
			end),
			
            TimeEvent(10*FRAMES, function(inst)
				inst.sg:AddStateTag("retilt")
			end),
			
			TimeEvent(17*FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {
            EventHandler("throwattack", function(inst)
                if inst.sg:HasStateTag("retilt") and not inst.components.keydetector:GetBackward(inst) then
					inst.sg:GoToState("re-ftilt")
				end
            end),
        },
    },
	
	
	
	
	
	State{
        name = "dtilt",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dtilt")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hurtboxes:SpawnHurtboxTemp(0.7, 0.5, 0.5, 0, 9)
				
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(77)
				inst.components.hitbox:SetBaseKnockback(85) --70
				inst.components.hitbox:SetGrowth(50) --70

				inst.components.hitbox:SetSize(1, 0.35)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.4, 0.15, 0)
			end),
			
            TimeEvent(13*FRAMES, function(inst) --15
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
        name = "uptilt",
        tags = {"attack", "notalking", "abouttoattack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("utilt")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh") 
        end,
        
        timeline=
        {
			
			TimeEvent(4*FRAMES, function(inst)
			
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(92)
				inst.components.hitbox:SetBaseKnockback(60)
				inst.components.hitbox:SetGrowth(100)
				
				inst.components.hitbox:AddSuction(0.2, 0.0, 2.0)
				
				inst.components.hitbox:SetSize(0.9, 0.3)
				inst.components.hitbox:SpawnHitbox(0.2, 0.7, 0)

			end),
			
			TimeEvent(5*FRAMES, function(inst)
				-- inst.components.hitbox:SetSize(1.0, 0.3)
				inst.components.hitbox:SetSize(1.0, 0.3)
				inst.components.hitbox:SpawnHitbox(0.1, 1.8, 0)
			end),
			
			TimeEvent(6*FRAMES, function(inst)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetLingerFrames(4)
				inst.components.hitbox:SetSize(1.1, 0.5)
				-- inst.components.hitbox:SpawnHitbox(0.0, 1.8, 0)
				inst.components.hitbox:SpawnHitbox(0.0, 2.2, 0)
			end),
			
            TimeEvent(20*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	State{
        name = "nspecial",
        tags = {"attack", "busy", "nolandingstop", "noairmoving"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("nspecial_axe")
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				if inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
			end),

			TimeEvent(10*FRAMES, function(inst)
				
				inst.components.hitbox:SetDamage(18) --WII FIT TRAINER FULLY CHARGED SHOT
				inst.components.hitbox:SetAngle(55) --50
				inst.components.hitbox:SetBaseKnockback(30) --30
				inst.components.hitbox:SetGrowth(70) --73
				inst.components.hitbox:SetSize(0.7) --8
				inst.components.hitbox:SetLingerFrames(120)
				
				
				inst.components.hitbox:SetProjectileAnimation("projectile_lucy", "projectile_lucy", "idle")
				inst.components.hitbox:SetProjectileSpeed(7, 0.3)
				inst.components.hitbox:SetProjectileDuration(30)
				
				--3-31-22 HOHOHO THE MEMES
				if inst.components.stats.buildname == "newwoodielucy" then
					inst.components.hitbox:SetProjectileAnimation("projectile_woodie", "projectile_woodie", "idle")
				end
				
				
				-- inst.components.hitbox:SpawnProjectile(2, 1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_throw")
				
				local projectile = SpawnPrefab("basicprojectile") --8-30 USING LUCY AS A TEST SUBJECT FOR THE BOOMERANG EFFECT
				projectile.components.projectilestats.yhitboxoffset = -0.3 --7-1-18 --BECAUSE SOMEHOW THIS GOT WAY HIGHER THAN IT SHOULD BE?
				
				--11-25-21 DOES THIS NOT HAPPEN BY DEFAULT?? I GUESS NOT
				projectile.components.stats.owner = inst
				
				--11-24-21 MAKE LUCY SAY SOMETHING!
				inst.components.hitbox:SetOnHit(function() 
					local opponent = projectile.components.stats.opponent
					local owner = projectile.components.stats.owner
					if opponent.sg and not opponent.sg:HasStateTag("blocking") then
						inst.sg:AddStateTag("hitconfirm")
					end
				end)
				
				inst.components.hitbox:SpawnProjectile(1.5, 0.8, 0, projectile)
				projectile.components.stats:TintTeamColor(0.6)
			end),
			
			TimeEvent(30*FRAMES, function(inst) 
				inst.AnimState:PlayAnimation("nspecial_pst")
			end),
			
			TimeEvent(36*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")  --BLING
				inst.SoundEmitter:PlaySound("dontstarve/wilson/equip_item")  --12-3-21 I GUESS THIS MAKES MORE SENSE..
			end),
			
			TimeEvent(38*FRAMES, function(inst) 
				--12-3-21 IF WE DID HIT SOMEONE, GIVE US LUCY'S VOICE AND SAY SOMETHING REAL QUICK.
				if inst.sg:HasStateTag("hitconfirm") then
					inst.components.talker.colour = Vector3(.9, .4, .4)
					-- inst.components.talker:Say("GOTTEM", 1)
					local lucytalklist = STRINGS.LAVALUCY.struckenemy
					inst.components.talker:Say(lucytalklist[math.random(#lucytalklist)], 1) --I WANTED TO USE STRINGS.LUCY.on_chopped, BUT IT'D BE WEIRD IF SHE CALLED ALL ENEMIES TREES...
					inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/lucytalk_LP", "lucytalk")
					
					inst:DoTaskInTime(1, function()
						inst.SoundEmitter:KillSound("lucytalk")
						inst.components.talker.colour = Vector3(1, 1, 1)
					end)
				end
			end),
			
            TimeEvent(50*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
			
			TimeEvent(60*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	State{
        name = "uspecial",
        tags = {"attack", "busy", "can_grab_ledge", "scary", "nolandingstop", "force_trade"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("uspecial")
			
			--10-18-17 GONNA ADD A SNEAKY LITTLE CHECK FOR GROUND TO MAKE IT EASIER TO GET THE GROUNDED VERSION WITH TAPJUMP
			local yhight = inst.components.launchgravity:GetHeight()
			if yhight <= 0.50 then --HEY, THIS IS ACTUALLY PRETTY GOOD... MIGHT DO THIS WITH ALL OF THEM!
				--inst.components.launchgravity:Launch(0, 0)
			end
			
            inst.components.jumper:AirStall(3, 3)
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
        end,
		
        
        timeline=
        {
		
			TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				inst.components.launchgravity:AirOnlyLaunch(0, 10) --MOVING THIS SLIGHTLY LATER
				if inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
			end),
			
			TimeEvent(3*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/swhoosh")
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/swipe")
				inst.components.hitbox:MakeFX("lucy_spinwoosh", 0, 1.5, 0, 1.5, 1, 1, 8)
				
				inst.components.hitbox:SetDamage(14)
				inst.components.hitbox:SetAngle(47)
				inst.components.hitbox:SetBaseKnockback(60)
				inst.components.hitbox:SetGrowth(85)
				
				inst.components.hitbox:SetSize(0.8)
				inst.components.hitbox:SetLingerFrames(3) --26
				
				
				--5-2-17 OKAY, LETS CHANGE THIS WHOLE AIR THING BC ITS WAY TOO STRONG OFF THE TOP
				if inst.components.launchgravity:GetIsAirborn() then
					inst.components.hitbox:SetDamage(8)
					inst.components.hitbox:SetAngle(47)
					inst.components.hitbox:SetBaseKnockback(40)
					inst.components.hitbox:SetGrowth(145)
				end
				
				--THIS ONE SHOULD BE AT THE TOP
				inst.components.hitbox:SpawnHitbox(0, 1.4, 0)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.4, 1.0, 0)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-1.4, 1.0, 0)
				-- print("TIME AND SPACE42", (inst.sg.timeinstate/FRAMES))
				
				inst.components.launchgravity:AirOnlyLaunch(0, 13) --10
			end),
			
			TimeEvent(6*FRAMES, function(inst)
				--1-8-22 MAKE THE POST-HIT LAUNCH WEAKER. (BASICALLY, GIVE IT THE AIR HITBOXES
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(47)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(145)
				inst.components.hitbox:SetLingerFrames(23)
				
				inst.components.hitbox:SpawnHitbox(0, 1.4, 0)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.4, 1.0, 0)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-1.4, 1.0, 0)
				
				
				inst.components.hitbox:MakeFX("lucy_spinwoosh2", 0, 1.2, -1, 0.8, 0.8, 1, 8)
				inst.components.launchgravity:AirOnlyLaunch(0, 13)
			end),
			
			TimeEvent(8*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/swipe")
			end),
			
			TimeEvent(10*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/swipe")
				inst.components.hitbox:MakeFX("lucy_spinwoosh", 0, 1.5, 0, 1.5, 1, 1, 8)
				inst.components.launchgravity:AirOnlyLaunch(0, 13)
				-- print("TIME AND SPACE10", (inst.sg.timeinstate/FRAMES))
			end),
			
			TimeEvent(14*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("lucy_spinwoosh2", 0, 1.2, -1, 0.8, 0.8, 1, 8)
				inst.components.launchgravity:AirOnlyLaunch(0, 13)
			end),
			
			TimeEvent(13*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/swipe")
			end),
			
			TimeEvent(18*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("lucy_spinwoosh", 0, 1.5, 0, 1.5, 1, 1, 8)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/swipe")
				inst.components.launchgravity:AirOnlyLaunch(0, 10)
			end),
			
			TimeEvent(22*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("lucy_spinwoosh2", 0, 1.2, -1, 0.8, 0.8, 1, 8)
				inst.components.launchgravity:AirOnlyLaunch(0, 8)
			end),
			
			TimeEvent(24*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/swipe")
			end),
			
			TimeEvent(25*FRAMES, function(inst)
				inst.sg:AddStateTag("reducedairacceleration")
			end),
			
			
			--[[
			TimeEvent(26*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
				inst.components.hitbox:MakeFX("lucy_spinwoosh", 0, 1.5, 0, 1.5, 1, 1, 8)
				inst.components.launchgravity:AirOnlyLaunch(0, 10)
			end),
			
			TimeEvent(30*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("lucy_spinwoosh2", 0, 1.2, -1, 0.8, 0.8, 1, 8)
				inst.components.launchgravity:AirOnlyLaunch(0, 10)
			end),
			
			TimeEvent(34*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
				inst.components.hitbox:MakeFX("lucy_spinwoosh", 0, 1.5, 0, 1.5, 1, 1, 8)
				inst.components.launchgravity:AirOnlyLaunch(0, 10)
			end),
			]]
			
			TimeEvent(31*FRAMES, function(inst)
				inst.sg:AddStateTag("dontrepeat")
				inst.sg:RemoveStateTag("scary")
				inst.AnimState:PlayAnimation("upspec_post")
			end),
			
			
			
            TimeEvent(41*FRAMES, function(inst)  --49
				if inst.components.launchgravity:GetIsAirborn() then
					inst.sg:RemoveStateTag("busy")
					inst.sg:GoToState("freefall")
				else
					-- inst.AnimState:PlayAnimation("upspec_post")
					inst.AnimState:PlayAnimation("run_pst")
				end
				
			end),
			
			TimeEvent(45*FRAMES, function(inst)  
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("freefall")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
               if not inst.sg:HasStateTag("dontrepeat") then --I DONT WANT IT TO KEEP LOOPING NEAR THE END
					inst.AnimState:PlayAnimation("uspecial")
			   end
            end),
        },
    },
	
	
	State{
        name = "fspecial",
        tags = {"attack", "force_trade", "abouttoattack", "busy", "nolandingstop", "no_air_transition", "noclanking", "force_direction"}, 
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("fspecial_pre")
            inst:PushEvent("swaphurtboxes", {preset = "dashing"})
        end,
		
		onexit = function(inst)
			inst.components.locomotor:Clear()
			if inst.motortask then
				inst.motortask:Cancel() --I SHOULD REALLY SET THESE UP TO CANCEL THEMSELVES ON STATE CHANGE, ITS GONNA CONFUSE MODDERS --TODOLIST
			end								--7-26-17 DONE!! MOTORS WILL NOW AUTOCANCEL ITSELF ON STATE END
        end,
		
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				if inst.components.keydetector:GetBackward(inst) then --THIS ALLOWS YOU TO TURNAROUND
					inst.components.locomotor:TurnAround()
				end
				
				--[[ 1-9-22 NO, THIS IS TOO MUCH FOR WOODIE. HE IS NOT A RUSHDOWN CHARACTER.
				if not inst.components.launchgravity:GetIsAirborn() then
					inst.sg:AddStateTag("was_grounded")
				end
				]]
				
				inst.components.jumper:AirStall(3, 3)
				inst.components.hitbox:MakeFX("glint_ring_1", 0.6, 1.3, 0.2,   1.0, 1.0,   0.0, 8, 0.5,  1, 0, 0,   1)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/swhoosh") --12-19-18 DST ONLY SOUND (WELL, TECHNICALLY ROG)
			end),
			
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.locomotor:Motor(20, 1, 10) --(xvel, yvel, duration)
				inst.components.hitbox:MakeFX("dahswoosh", 0, 1, -0.5,   0.8, 0.5,   0.6, 5, 0)
			end),
			
			
			TimeEvent(10*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				
				inst.components.hitbox:SetAngle(75) --65
				inst.components.hitbox:SetBaseKnockback(25) --15 -WAS WAAAY TOO SMALL
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetDamage(4)
				inst.components.hitbox:SetPriority(-5) --LOL, EASY TO INTERUPT

				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(5) --10
				
				inst.components.hitbox:SpawnHitbox(0.2, 1, 0) 
				
				-- inst.components.hitbox:MakeFX("square", 0, 1, -0.5,   2, 0.7,   0.4, 8, 0,   -0.2, -0.4, -0.4) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst.components.hitbox:MakeFX("square", 0, 1, -0.5,   2, 0.7,   0.5, 8, 0,   -0.0, -0.6, -0.6)
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("square", 0, 1, -0.5,   2, 0.7,   0.5, 8, 0,   -0.0, -0.6, -0.6) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst.sg:AddStateTag("can_woodhop")
			end),
			
			TimeEvent(14*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("square", 0, 1, -0.5,   2, 0.7,   0.5, 8, 0,   -0.0, -0.6, -0.6) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			end),
			
			TimeEvent(16*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("square", 0, 1, -0.5,   2, 0.7,   0.5, 8, 0,   -0.0, -0.6, -0.6)--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				--2-7-22 THIS CHANGE WAS PRETTY MUCH PURELY VISUAL
				inst.components.hitbox:AddSuction(0.5, 2.5, 0)
				inst.components.hitbox:SetAngle(30)
				inst.components.hitbox:SetLingerFrames(1)
				-- inst.components.hitbox:SetOnHit(function()
					-- inst.components.hitbox:MakeFX("idle", 1.35, 0.6, 0.1,   1.5, 1.5,   0.5, 5, 0.8,  0, 0, 0,   1, "impact", "impact")
				-- end)
				inst.components.hitbox:SpawnHitbox(0.2, 1, 0) 
			end),
			
			-- TimeEvent(18*FRAMES, function(inst) 
				-- inst.components.hitbox:MakeFX("square", 0, 1, -0.5,   2, 0.7,   0.5, 8, 0,   -0.0, -0.6, -0.6) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			-- end),
			
			TimeEvent(17*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("can_woodhop")
			end),
			
			TimeEvent(18*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("square", 0, 1, -0.5,   2, 0.7,   0.5, 8, 0,   -0.0, -0.6, -0.6)
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
				inst.AnimState:PlayAnimation("fspecial_swing")
				inst.components.hitbox:FinishMove()
				inst.components.hitbox:AddNewHit()
			
				inst.components.hitbox:SetAngle(48)
				inst.components.hitbox:SetBaseKnockback(85)  --130
				inst.components.hitbox:SetGrowth(85)
				inst.components.hitbox:SetDamage(13)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(1.4, 0.6)
				inst.components.hitbox:SetLingerFrames(3)
				
				inst.components.hitbox:SetOnHit(function()
					-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
					inst.components.hitbox:MakeFX("idle", 1.35, 0.6, 0.1,   1.5, 1.5,   0.5, 5, 0.8,  0, 0, 0,   1, "impact", "impact")
					inst.components.hitbox:MakeFX("glint_ring_1", 1.3, 1.3, 0.5,   2.5, 2.5,   0.4, 8, 0.5,  1, 0, 0,   1) 
				end)
				inst.components.hitbox:AddSuction(0.5, 2.5, 0)
				
				inst.components.hitbox:AddEmphasis(5)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.components.hitbox:MakeFX("lucy_archwoosh", 3, 1.5, 0.2,   0.8, 1,   0.4, 6) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				
				inst.components.hitbox:SpawnHitbox(1.2, 1, 0) 
				
				-- inst.components.jumper:AirStall()
				-- inst.components.jumper:ScootForward(3)
				-- inst.components.launchgravity:AirOnlyLaunch(0,6,0)
				if inst.components.launchgravity:GetIsAirborn() then
					inst.components.launchgravity:AirOnlyLaunch(1,6,0)
				else
					inst.components.jumper:AirStall()
				end
				
				-- inst.components.locomotor:SlowFall(0.5, 13)
				
			end),
			
			TimeEvent(19*FRAMES, function(inst) 
				-- inst.components.launchgravity:AirOnlyLaunch(0,6,0)
			end),
			
			TimeEvent(23*FRAMES, function(inst) 
				-- inst.components.launchgravity:AirOnlyLaunch(3,3,0)
				inst.components.jumper:AirStall()
				inst.components.locomotor:SlowFall(0.5, 13)
			end),
			
			TimeEvent(15*FRAMES, function(inst)  -- (30) --7-13-17 NAH. ITS REALLY GOOD THIS WAY. LETS LET THEM GRAB EARLIER BEFORE THE SWING COMES OUT
				inst.sg:AddStateTag("can_grab_ledge")
			end),
			
			TimeEvent(34*FRAMES, function(inst) 
				if inst.components.launchgravity:GetIsAirborn() then
					inst.sg:GoToState("freefall")
				end
			end),
			
            TimeEvent(40*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
				inst.sg:GoToState("freefall")
			end),
        },
		
		onupdate = function(inst)
            local ben = false --JUST SO THIS FN ISNT NIL --(PRETTY SURE WE FIXED THE NEED FOR THIS, RIGHT?)
        end,
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.AnimState:PlayAnimation("fspecial") --PLAY THE LOOPED VERSION
            end),
			
			EventHandler("jump", function(inst)
                if inst.sg:HasStateTag("was_grounded") and inst.sg:HasStateTag("can_woodhop") then
					inst.sg:GoToState("wood_hop")
				end
            end),
        },
    },
	
	
	--ALLOW WOODIE TO HOP OUT OF FSPEC
	State{
        name = "wood_hop",
		tags = {"busy", "no_air_transition", "nolandingstop"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jump")
			inst.Physics:Stop()
			--WE WERE JUST MOTORING, SO WE NEED TO MAKE SURE WE HIT THE GROUND FIRST
			inst.components.launchgravity:HitGround()
			--"dontstarve/creatures/krampus/kick_impact"
			
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/explode")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_impact")
			
			
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
        end,
		
		onexit = function(inst)
            inst.components.stats.jumpspec = nil
        end,
        
		timeline =
        {
			TimeEvent(2*FRAMES, function(inst) --10-19-17 APPLY THIS TO EVERYONE LATER.
				
				
				--OK JUST LETTING HIM JUMP MIGHT BE WAY TOO GOOD
				--[[
				inst:AddTag("listenforfullhop") --10-20-17 A NEW IMPROVED ATTEMPT AT FULLHOP REGISTRATION.
				inst.components.jumper:Jump(inst) --LETS BUMP THIS DOWN A LINE OR TWO
				inst.sg:RemoveStateTag("can_usmash")
				
				inst:DoTaskInTime(2*FRAMES, function(inst) --NOW ALWAYS CHECKS IN 4 FRAMES
					inst.components.jumper:CheckForFullHop()
				end)
				]]
				inst.components.launchgravity:Launch(5,14,0)
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy") 
				inst.sg:RemoveStateTag("nolandingstop") 
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
        name = "dspecial",
        tags = {"attack", "busy", "no_air_transition"},   --, "nolandingstop" --WAIT TO MAKE SURE THE FALL HAS STARTED BEFORE WE ALLOW THE CRASH LANDING
        
		onenter = function(inst)
            inst.AnimState:PlayAnimation("dspecial")
			inst.components.launchgravity:SetLandingLag(10, nil, "axepound") --12-8-17 TRYING OUT THE NEW LANDINGLAG STATE IDENTIFIER. WILL GO STRAIGHT TO THAT STATE ON LAND
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
        end,
		
		timeline=
        {
			
			TimeEvent(1*FRAMES, function(inst) 
				if inst.components.keydetector:GetBackward(inst) then --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
					inst.components.locomotor:TurnAround()
				end
				-- inst.components.jumper:AirStall()
				-- inst.components.launchgravity:AirOnlyLaunch(0,7,0)
				inst.components.launchgravity:Launch(0,12,0) --WHY AIR ONLY? MAKES THE GROUNDED VERSION LOOK WIERDER
				inst.components.locomotor:SlowFall(0.2, 6) 
			end),
			
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(270) 
				inst.components.hitbox:SetBaseKnockback(35) --25
				inst.components.hitbox:SetGrowth(80)
				inst.components.hitbox:SetSize(0.8, 0.3)
				inst.components.hitbox:SetLingerFrames(100)
				inst.components.hitbox:MakeDisjointed()
				
				-- inst.components.hitbox:SpawnHitbox(0.7, 0.1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
			end),
			
			--11-4-17 TEST VERSION
			-- TimeEvent(10*FRAMES, function(inst)  --HOOO BOY. I HOPE I DONT EVER HAVE TO COME BACK TO THIS. BAD TIMES...
				-- -- inst.components.jumper:AirStall()
				-- -- inst.sg:AddStateTag("nolandingstop")
				-- inst.components.launchgravity:AirOnlyLaunch(0,-18,0) --MAKE ATTACK COME OUT FRAME 12
				-- -- inst.components.jumper:FastFall()
			-- end),
			
			TimeEvent(10*FRAMES, function(inst) 
				inst.components.hitbox:SpawnHitbox(0.7, 0.1, 0)
				
				inst.components.jumper:AirStall()
				-- inst.sg:AddStateTag("nolandingstop") --NOT ANYMORE!
				inst.components.launchgravity:AirOnlyLaunch(0,-8,0)
				inst.components.jumper:FastFall()
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("square", 0.9, 0.6, -0.3,   0.6, 2,   0.6, 4, 0,   -0.0, -0.6, -0.6) 
			end),
			
			TimeEvent(14*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("square", 0.9, 0.6, -0.3,   0.6, 2,   0.6, 4, 0,   -0.0, -0.6, -0.6) 
			end),
			
			TimeEvent(16*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("square", 0.9, 0.6, -0.3,   0.6, 2,   0.6, 4, 0,   -0.0, -0.6, -0.6) 
			end),
			
			TimeEvent(18*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("square", 0.9, 0.6, -0.3,   0.6, 2,   0.6, 4, 0,   -0.0, -0.6, -0.6) 
			end),
			
			TimeEvent(20*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("square", 0.9, 0.6, -0.3,   0.6, 2,   0.6, 4, 0,   -0.0, -0.6, -0.6) 
			end),
			
			TimeEvent(22*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("square", 0.9, 0.6, -0.3,   0.6, 2,   0.6, 4, 0,   -0.0, -0.6, -0.6) 
			end),
			
            TimeEvent(60*FRAMES, function(inst) 
				inst.sg:GoToState("air_idle")
			end),
        },
        
        events=
        {
            -- EventHandler("hit_ground", function(inst)
				-- print("STAR_ IS MY FAVORITE UGXIE HIGHLANDER FRIEND")
                -- inst.sg:GoToState("ll_medium_getup", 30)
            -- end),
			
			--[[   --DONT NEED THIS ANYMORE, WE HAVE LLSTATE TO TAKE CARE OF THAT
			 EventHandler("ground_check", function(inst)  --hit_ground
				-- print("STAR IS MY FAVORITE UGXIE HIGHLANDER FRIEND")
                inst.sg:GoToState("ll_medium_getup", 25)
				inst.AnimState:PlayAnimation("dspecial_land")
				
				inst.components.hitbox:AddNewHit()
				
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(55) 
				inst.components.hitbox:SetBaseKnockback(80)
				inst.components.hitbox:SetGrowth(110)
				inst.components.hitbox:SetSize(0.8, 0.8)
				inst.components.hitbox:SetLingerFrames(3)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.0, 0.5, 0) 
				
				-- inst.components.hitbox:SpawnHitbox(0, 0.5, 0) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				-- inst.sg:GoToState("ll_medium_getup", 10)
				-- inst:DoTaskInTime(0, function(inst) inst.sg:GoToState("ll_medium_getup", 10) end )
				
				
				inst.components.hitbox:MakeFX("ground_smash", 1, -0.1, 0.1, 1.5, 1.5, 1, 20, 0)
				-- inst.components.hitbox:MakeFX("ground_bounce", 1, 0.1, -0.1, 1, 0.6, 0.8, 7, 0)
				inst.components.hitbox:MakeFX("square", 0.9, 0.6, -0.3,   0.7, 1,   0.6, 4, 0,   -0.0, -0.6, -0.6) 
				
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				TheCamera:Shake("FULL", .20, .02, .2)
				inst.components.hitbox:MakeFX("anim", 1, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.components.hitbox:MakeFX("ground_smash", 1, 0.1, 0.1, -1.5, 1.5, 1, 12, 0)
            end),
			]]--
        },
    },
	
	
	State{
        name = "axepound",
        tags = {"busy", "scary", "scary"},

        onenter = function(inst)
                -- inst.sg:GoToState("ll_medium_getup", 25)
				inst.AnimState:PlayAnimation("dspecial_land")
				-- inst:PushEvent("swaphurtboxes", {preset = "landing"})
				--LETS TRY SOMETHING UNIQUE...
				inst:PushEvent("swaphurtboxes", {preset = "none"})
				inst.components.hurtboxes:SpawnHurtboxTemp(0.35, 0.75, 0.45, 0, 4)
				inst.components.hurtboxes:SpawnHurtbox(0.45, 0.0, 0.9, 0.60)
				
				-- inst.components.hitbox:AddNewHit()
				
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(55) 
				inst.components.hitbox:SetBaseKnockback(80)
				inst.components.hitbox:SetGrowth(110)
				inst.components.hitbox:SetSize(0.8, 0.8)
				inst.components.hitbox:SetLingerFrames(3)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.0, 0.5, 0) 
				
				inst.components.hitbox:MakeFX("ground_smash", 1, -0.1, 0.1, 1.5, 1.5, 1, 20, 0)
				-- inst.components.hitbox:MakeFX("ground_bounce", 1, 0.1, -0.1, 1, 0.6, 0.8, 7, 0)
				inst.components.hitbox:MakeFX("square", 0.9, 0.6, -0.3,   0.7, 1,   0.6, 4, 0,   -0.0, -0.6, -0.6) 
				
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				TheCamera:Shake("FULL", .20, .02, .2)
				inst.components.hitbox:MakeFX("anim", 1, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.components.hitbox:MakeFX("ground_smash", 1, 0.1, 0.1, -1.5, 1.5, 1, 12, 0)
				
        end,
		
		timeline=
        {
            --
			TimeEvent(17*FRAMES, function(inst)
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			
			TimeEvent(24*FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
        },
	},
	
	
	
	
	
	
	--FSMASH
	State{
        name = "fsmash_start",
        tags = {"busy", "scary", "scary"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("wsmash_positive_woodie")
			inst.components.hitbox:SetDamage(13)
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
        tags = {"attack", "scary", "f_charge", "busy"},
        
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
			TimeEvent(10*FRAMES, function(inst) --8-6-23 OOPS FIXED THIS
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
        tags = {"attack", "busy", "abouttoattack", "force_direction", "scary"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("wsmash_positive_woodie_swing")
			--SINCE THIS SMASH HAS MULTIPLE HITS, WE ONLY WANT THE LAST HIT TO TAKE THE CHARGED DAMAGE
			inst.components.stats.storagevar2 = inst.components.hitbox.dam --SET THIS AS THE CURRENT DAMAGE VALUES
        end,
		
		-- onupdate = function(inst)
            -- print("TIMELINE", (inst.sg.timeinstate/FRAMES))
        -- end,
        
        timeline=
        {
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
			
			TimeEvent(17*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.components.jumper:ScootForward(8)
			end),
			
			TimeEvent(19*FRAMES, function(inst) 
				inst.AnimState:SetTime(21*FRAMES)
				inst.components.hitbox:SetAngle(45) --48 SEEMS KINDA HIGH. GONNA LOWER IT A BIT
				inst.components.hitbox:SetBaseKnockback(82)  --85
				inst.components.hitbox:SetGrowth(90)
				-- inst.components.hitbox:SetDamage(13)
				inst.components.hitbox:SetDamage(inst.components.stats.storagevar2)
				inst.components.hitbox:SetSize(0.9)
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
    },
	
	
	--DSMASH
	State{
        name = "dsmash_start",
        tags = {"busy", "scary"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("dsmash_start")
			inst.components.hitbox:SetDamage(10)
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
        tags = {"attack", "scary", "d_charge", "busy", "chargingdsmash"},
        
        onenter = function(inst)
			
			-- if not inst:HasTag("atk_key_dwn") then
				-- inst.sg:GoToState("dsmash")
			-- else
				inst.AnimState:SetMultColour(1,1,1,1)
				inst.components.colourtweener:StartTween({1,0,0,1}, 2, nil)
			-- end  
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
        tags = {"attack", "notalking", "busy", "scary"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dsmash")
			inst.components.colourtweener:EndTween()
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/swhoosh")
        end,
		
		onexit = function(inst)
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				-- inst.components.hitbox:SetBlockDamage(5)
				-- inst.components.hitbox:SetDamage(10)
				
				inst.components.hitbox:SetAngle(55) --YEA 55 PERFECT --BUT 361 TOO LOW?  --65 NAH. BAD ANGLE. BARELY SAFE ON HIT
				inst.components.hitbox:SetBaseKnockback(65) --50 IS WAY TOO WEAK
				inst.components.hitbox:SetGrowth(90)
				
				inst.components.hitbox:SetSize(1, 0.3)
				
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.8, 0.3, 0)
			end),
			
			TimeEvent(3*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("lucy_spinwoosh2", 0.2, 0.2, -0.5,   1.2, 0.6,   1, 8)
			end),
				
			TimeEvent(4*FRAMES, function(inst)
				inst.components.hitbox:SetSize(1.5, 0.3)
				inst.components.hitbox:SetLingerFrames(3)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-0.8, 0.3, 0)
			end),
			
			TimeEvent(6*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("lucy_spinwoosh", 0, 0.38, 0, 1.4, 0.8, 0.7, 8)
			end),
			
			TimeEvent(9*FRAMES, function(inst)
				inst.components.hitbox:SetSize(1.8, 0.3)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.8, 0.3, 0)
			end),
			
            TimeEvent(25*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	State{
        name = "usmash_start",
        tags = {"busy", "scary"}, --},

        onenter = function(inst)
			inst.components.hitbox:SetDamage(18) --SWEETSPOTS GET +5 ADDED TO THEM --11-2-24 NEVERMIND NO MORE SOURSPOT
			inst.AnimState:PlayAnimation("usmash_charge")
        end,
		
		timeline=
        {
            TimeEvent(2*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "landing"})
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.sg:GoToState("usmash_charge")
			end),
        },
		
	},
	
	State{
        name = "usmash_charge",
        tags = {"attack", "u_charge", "busy", "scary"},
        
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
				inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hatch_crack")
			end),
			TimeEvent(3*FRAMES, function(inst) 
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
			inst.AnimState:PlayAnimation("usmash")  
			
			--STORE THEM AS 2 DIFFERENT VALUES. 1 FOR SOURSPOT, 1 FOR SWEETSPOT
			-- inst.components.stats.storagevar1 = inst.components.hitbox.dam
			-- inst.components.stats.storagevar2 = inst.components.hitbox.dam + 4
			--NEVERMIND, NO MORE SOURSPOT
        end,
		
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				
				inst.components.hitbox:SetAngle(70)
				inst.components.hitbox:SetBaseKnockback(60)
				inst.components.hitbox:SetGrowth(86)
				inst.components.hitbox:SetSize(0.7)
				
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0.0, 0.6, 0)
				
				--BIG HIT
				-- inst.components.hitbox:SetDamage(inst.components.stats.storagevar2) --THE NORMAL VALUE BUT +5
				inst.components.hitbox:SetSize(0.9)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(1.4, 1, 0) 
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
			
				--!!!! IMPORTANT!!!!! --12-29-2015  FOR MULTI-HITBOX ATTACKS LIKE THESE, HITBOXES DONT ALWAYS RETAIN THE CORRECT "LAST HITBOX VALUE" FROM HITBOXES CREATED ON THE SAME FRAME
				--TO ENSURE HITBOX VALUES ARENT TAKEN FROM THE INCORECT HITBOX SPAWNED ON THE SAME FRAME, RE-ESTABLISH HITBOX VALUES BEFORE SPAWNING THE NEW HITBOX
				-- -- A MESSAGE FROM 10-27-2017, THESE HITBOX ISSUES WERE FIXED LONG AGO. THANKS c:
				
				--THESE WERE ADDED AND FIXED THE HITBOX VALUE PROBLEM
				-------------------------------------------------------------------
				-- inst.components.hitbox:SetBlockDamage(5)
				--inst.components.hitbox:SetKnockback(17, 20)
				-- inst.components.hitbox:SetDamage(inst.components.stats.storagevar2)
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetSize(0.9)
				------------------------------------------------------------------
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:SpawnHitbox(0.9, 1.8, 0)
			end),
			
			TimeEvent(4*FRAMES, function(inst)
				--THE TINY HIT
				-- inst.components.hitbox:SetDamage(inst.components.stats.storagevar1)--12
				-- inst.components.hitbox:SetSize(0.3)
				-- inst.components.hitbox:SetLingerFrames(2)
				-- inst.components.hitbox:SpawnHitbox(-0.5, 1, 0)
				
				--BACK TO THE BIG HIT
				-- inst.components.hitbox:SetBlockDamage(5)
				-- inst.components.hitbox:SetDamage(inst.components.stats.storagevar2)
				inst.components.hitbox:SetSize(0.9)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(-1.2, 2, 0) 
				-- inst.components.hitbox:SpawnHitbox(3, 1, 0)  --FOR TESTING 12-29 --WAIT NO THIS ONE IS FINE???
				
				inst:PushEvent("swaphurtboxes", {preset = "hitstun1"})
				inst.components.hurtboxes:ShiftHurtboxes(-0.5, 0)
			end),
			
			TimeEvent(6*FRAMES, function(inst)
				inst.AnimState:SetTime(9*FRAMES)
				-- inst.components.hitbox:SetDamage(inst.components.stats.storagevar2)
				inst.components.hitbox:SetSize(0.9)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetLingerFrames(3)
				inst.components.hitbox:SpawnHitbox(-2, 0.3, 0)
				
				TheCamera:Shake("FULL", .2, .02, .2)
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_dull")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				
				inst.components.hitbox:MakeFX("anim", -2, 0, 0.1,   1, 1,   1, 10, 0, 0,0,0, 0, "shovel_dirt", "shovel_dirt") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst.components.hitbox:MakeFX("anim", -1.8, 0, 0.1, -1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				
				inst.components.hitbox:MakeFX("ground_smash", -2, -0.1, 0.1, 1.5, 1.5, 1, 20, 0)
				--inst.components.hitbox:MakeFX("ground_crack", -2, 0.1, 0.2, 1, 3, 1, 20, 0) --AWW MAN THIS EFFECT LOOKS LIKE CRAP
			end),
			
            TimeEvent(23*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack") 
				inst.sg:RemoveStateTag("busy") 
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    
}







CommonStates.AddFrozenStates2(states)
CommonStates.AddRespawnPlatform(states)
CommonStates.AddDropSpawn(states)

    
return StateGraph("woodie", states, events, "idle") --, actionhandlers)

