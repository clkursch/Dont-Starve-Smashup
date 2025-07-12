--require("stategraphs/fighterstates")

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
		
		--9-5 --TELLS CPU WHEN TARGET HAS FINISHED A MOVE AND IS READY FOR A NEW ONE
		if not is_busy and not is_blocking then
			inst:PushEvent("readyforaction") --ACTUALLY JUST FOR CPU
			if inst.components.stats.opponent and (inst.components.stats.opponent.components.stats.opponent and inst.components.stats.opponent.components.stats.opponent == inst) then
				inst.components.stats.opponent:PushEvent("targetnewstate")
			end
		end
		
		inst:RemoveTag("motoring") --4-20 ADDED TO FIX BOTH WOODIES CHOPPY SIDE-B AND LEDGE WALK-OFF PHYSICS AT THE SAME TIME
		
        if not (is_attacking or is_busy) then --return end --4-13 TBH THIS CAN JUST GO BACK TO THE WAY IT WAS IN SGBRAWLER
			local is_moving = inst.sg:HasStateTag("moving")
			local is_running = inst.sg:HasStateTag("running")
			local should_move = inst.components.locomotor:WantsToMoveForward()
			local should_run = inst.components.locomotor:WantsToRun()
			local is_ducking = inst.sg:HasStateTag("ducking") --7-29-17
			
			
			-- if (TheWorld and TheWorld.ismastersim) or not TheWorld then --DID THIS REALLY WORK?
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
		local nojumping = inst.sg:HasStateTag("nojumping") --FOR WES ONLY, NOT IN ANY OTHER STATEGRAPHS
		local used_first_jump = inst.components.jumper.jumping == 1 and inst.components.jumper.doublejumping == 0
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		
		if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event ~= "jump" then
			return end
			
		if inst.sg:HasStateTag("listen_for_atk") and inst.components.stats.event == "jump" then
			return end
		
		--4-23-20 - NEW SYSTEM TO INTEGRATE BUFFERED AIREALS --(YES, WE NEED ALL OF THIS, I TESTED)
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
		
		-- if not is_busy and is_airborn and can_grab_ledge then
		if no_grab_ledge and not autosnap then
			--DO NOTHING
		elseif (can_grab_ledge or (not is_busy and is_falling)) and not pressing_down and not inst:HasTag("hitfrozen") then
			inst.components.launchgravity:HitGround()
			inst.components.jumper.jumping = 0
			inst.components.jumper.doublejumping = 0
			inst.sg:GoToState("grab_ledge", data.ledgeref)
		end
	end),
	
	EventHandler("left", function(inst)
		local is_dashing = inst.sg:HasStateTag("dashing") --DASHIN GOOD LOOKS  --4-5 WHY DID I WRITE THAT?
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
				--8-11-17 --TODO- NO THIS WONT WORK. MAKE A NEW GETLEFTRIGH() FN WITH A 5 SECOND BUFFER 
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
		--local is_jumping = inst.sg:HasStateTag("jumping") or inst.sg:HasStateTag("inknockback")
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

    EventHandler("doattack", function(inst)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("attack") then
            local weapon = inst.components.combat and inst.components.combat:GetWeapon()
            if weapon and weapon:HasTag("blowdart") then
                inst.sg:GoToState("blowdart")
            elseif weapon and weapon:HasTag("thrown") then
                inst.sg:GoToState("throw")
            else
                inst.sg:GoToState("attack")
            end
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
	
	
	EventHandler("throwattack", function(inst, data) --4-5 ADDING ADDITION DATA FOR ATEMPT KEY BUFFERING
		
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
		
			
			if (can_oos or data.key == "block") and not airial then --4-5 ADDING BUFFER BLOCK
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
					if not inst.components.keydetector:GetForward(inst) then
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
				inst.sg:GoToState("uptilt")
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
		local airial = inst.components.launchgravity:GetIsAirborn()
		local is_tryingtoblock = inst.sg:HasStateTag("tryingtoblock")
		
		if not inst.sg:HasStateTag("busy") or can_special_attack or (inst.sg:HasStateTag("can_upspec") and (data.key == "up" or data.key == "diagonalf" or data.key == "diagonalb")) then
			-- if inst.components.keydetector:GetUp(inst) then
			if data.key == "up" or data.key == "diagonalf" then
				inst.sg:GoToState("uspecial")
			elseif data.key == "diagonalb" then
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
			
			--11-7-16 SECOND CHECK FOR DIAGONALS IN THE AIR
			-- if airial then   --7-21-17 PRETTY SURE THIS WAS BUILT INTO THE ABOVE LIST
				-- if data.key == "diagonalf" then
					-- inst.sg:GoToState("uspecial")
				-- elseif data.key == "diagonalb" then
					-- inst.components.locomotor:TurnAround()
					-- inst.sg:GoToState("uspecial")
				-- end
			-- end
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
        
		onenter = function(inst)
			inst.AnimState:PlayAnimation("wickeridle")
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
			inst.AnimState:PlayAnimation("wickeridleair")
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
		end,
        
    },
	
    
    State{
        name = "run_start",
        tags = {"moving", "running", "canrotate"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("wickerrun")
			inst.components.locomotor.throttle = 0
			-- inst.sg:GoToState("run") --WHY WAIT
			inst.components.locomotor:RunForward()
            --inst.AnimState:PlayAnimation("run_pre")
            inst.sg.mem.foosteps = 0
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
                inst.sg:AddStateTag("ignore_ledge_barriers")
            end),
            
			TimeEvent(4*FRAMES, function(inst)
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
            --inst.AnimState:PlayAnimation("run_loop")
			inst.AnimState:PlayAnimation("wickerrun")
			
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
	
	
	
	
	State{
        
        name = "dash_start",
        tags = {"moving", "running", "canrotate", "dashing", "can_usmash", "can_special_attack", "can_ood", "busy", "can_dashdance", "foxtrot", "must_fsmash", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
			inst.components.locomotor.throttle = 0
			inst.components.locomotor:DashForward()
			inst.AnimState:PlayAnimation("wickerdash") --wickerrun
			
			inst.components.hitbox:MakeFX("dahswoosh", 0.5, 1.5, 1, 1, 1, 0.8, 7, 1)
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
			TimeEvent(2*FRAMES, function(inst)
				inst.sg:RemoveStateTag("must_fsmash")
			end),
			
            TimeEvent(7*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.2, 0.2, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst:PushEvent("dash") 
			end),
            TimeEvent(15*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.5, 0.5, 0.8, 5, 0)
				
            end),
			 TimeEvent(20*FRAMES, function(inst)
				--inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.5, 0.5, 1, 5, 0)
            end),
        },
        
        events=
        {   
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
			inst.AnimState:PlayAnimation("wickerdash")
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
			inst.Physics:SetMotorVel(0,0,0)
			inst.components.locomotor:TurnAround()
			inst.AnimState:PlayAnimation("dash_pivot_new")
			-- inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1, 0.5, 0.5, 1, 10, 0)
			inst.components.hitbox:MakeFX("slide1", -1.6, 0.0, 0.1, 1, 0.5, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			
			-- inst.components.hurtboxes:ShiftHurtboxes(-0.5, 0) --NOPE CANT USE THAT HERE
			
			-- inst.Physics:SetFriction(.6)
			-- inst.components.stats.ResetFriction()
			
			-- inst.components.jumper:ScootForward(-8)
            
        end,
		
		onexit = function(inst)
			-- inst.components.stats:ResetFriction()
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
				if inst.components.keydetector:GetForward(inst) then --LETS TRY THIS ONE...
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
            -- inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")  
            --inst.AnimState:PlayAnimation("hit")
			inst.AnimState:PlayAnimation("flinch2")
			inst.AnimState:SetTime(1*FRAMES)
			
			
			if ISGAMEDST and not TheWorld.ismastersim then --11-26-17
				return --CLIENTS DONT RUN BELOW THIS LINE
			end
			
			
			
			local attack_cancel_modifier = hitstun --* 0.9
			local dodge_cancel_modifier = hitstun --* 1.2
			
			inst.task_hitstun = inst:DoTaskInTime((hitstun*FRAMES), function(inst) --12-4
				inst.sg:RemoveStateTag("noairmoving") --8-24
				
				inst.sg:AddStateTag("can_jump")
				-- inst.AnimState:SetMultColour(1,1,0.5,1)
			end)
			
			inst.task_attackstun = inst:DoTaskInTime((attack_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:AddStateTag("can_attack")
				-- inst.AnimState:SetMultColour(1,0.5,1,1)
			end)
			inst.task_dodgestun = inst:DoTaskInTime((dodge_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
				-- inst.AnimState:SetMultColour(1,1,1,1)
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
		tags = {"busy", "hanging", "no_running", "resting", "nolandingstop", "no_air_transition"},
        
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
			inst.AnimState:PlayAnimation("ledge_attack")
			inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			inst.Physics:SetActive(false) --CAREFUL WITH THIS

			
        end,
		
		onexit = function(inst)
			-- inst.AnimState:PlayAnimation("duck_000")
			-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})
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
				inst.components.hitbox:SetDamage(4)   --7
				inst.components.hitbox:SetHitLag(0.3)
				inst.components.hitbox:SetCamShake(0.3)
				inst.components.hitbox:SetHighlight(0.3)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:SetLingerFrames(2)
				
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0)
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SpawnHitbox(2.0, 0.5, 0) 
			end),
			
			TimeEvent(10*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
				-- inst.components.jumper:ScootForward(8)
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
			inst.AnimState:PlayAnimation("duck_wicker")
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
			inst.AnimState:PlayAnimation("wickerjump")
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
				inst:AddTag("listenforfullhop")
				inst.components.jumper:Jump(inst) --LETS BUMP THIS DOWN A LINE OR TWO
				inst.sg:RemoveStateTag("prejump")
				inst.sg:RemoveStateTag("can_usmash")
				
				--10-20-17 A NEW IMPROVED ATTEMPT AT FULLHOP REGISTRATION.
				-- inst.sg:AddStateTag("prejump") --ON EXIT, IF PLAYER IS STILL IN PREJUMP, DONT EVEN LISTEN FOR FULLHOP
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
		tags = {"jumping", "nojumping"},
        
        onenter = function(inst)
			-- inst.AnimState:PlayAnimation("jump_maybe_001")
			inst.AnimState:PlayAnimation("wickerjump")
			-- inst.components.jumper:Jump()
			inst.components.jumper:DoubleJump(inst) --1-5
			inst.components.hitbox:MakeFX("ground_bounce", 0, 1, -1, 1, 1, 0.8, 7, 1)
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			
        end,
        
		timeline =
        {	
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0.1, 0.2)
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("nojumping")
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
			
			
			local angle = inst.components.launchgravity:GetAngle() * DEGREES
			
			if inst.components.launchgravity:GetAngle() <= 50 then
				inst.AnimState:PlayAnimation("tumble_back")
			elseif inst.components.launchgravity:GetAngle() >= 240 and inst.components.launchgravity:GetAngle() <= 300 then
				inst.AnimState:PlayAnimation("tumble_down")
			else
				inst.AnimState:PlayAnimation("tumble_up_000")
			end
			
			if ISGAMEDST and not TheWorld.ismastersim then --11-26-17
				return --CLIENTS DONT RUN BELOW THIS LINE
			end
			
			local attack_cancel_modifier = hitstun --* 0.9
			local dodge_cancel_modifier = hitstun --* 1.2
			if dodge_cancel_modifier >= hitstun + 30 then
				dodge_cancel_modifier = hitstun + 30
			end
			
			
			--local dodge_cancel_modifier = (((hitstun * 2.5) /2)) --no thats weird
			
			inst.task_hitstun = inst:DoTaskInTime((hitstun*FRAMES), function(inst) --12-4
				--inst.sg:RemoveStateTag("busy")
				--inst.sg:GoToState("idle")
				--inst.sg:GoToState("nair")
				--inst.AnimState:SetMultColour(0.5,1,1,1)
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
            --TimeEvent(0*FRAMES, function(inst) self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0) end),
			
           -- -- TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
            --local tumble_lock = inst.components.hitbox:GetTumbleTime()
			--print(tumble_lock)
			
			
			TimeEvent(3*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "hitstun1"})
			end),
			
			--TimeEvent((inst.components.hitbox:GetTumbleTime())*FRAMES, function(inst) 
			TimeEvent(20*FRAMES, function(inst) 
				--inst.sg:RemoveStateTag("intangible")
				
			end),
			
            TimeEvent(26*FRAMES,
				function(inst)
				--CHECK FOR IF STILL HOLDING SHEILD
                    --inst.sg:RemoveStateTag("busy")
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
        tags = {"busy"}, 
        
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
				inst.sg:GoToState("grounded")
			end),
        },
        
    },
	
	State{
        name = "grounded",
        tags = {"busy", "prone", "grounded", "nogetup"}, 
        
        onenter = function(inst, target)
            --inst.AnimState:SetMultColour(1,1,1,0.2)
			--inst.AnimState:PlayAnimation("pickup")
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
			inst.AnimState:PlayAnimation("landing")
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
				inst.motortask:Cancel() --I SHOULD REALLY SET THESE UP TO CANCEL THEMSELVES ON STATE CHANGE, ITS GONNA CONFUSE MODDERS --TODOLIST
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
			inst.AnimState:PlayAnimation("ll_med")
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
			inst.AnimState:PlayAnimation("wicker_block_startup")
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
			inst.AnimState:PlayAnimation("wicker_block")
			
			inst.components.blocker:StartConsuming()
			
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
            --EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
			EventHandler("down", function(inst) 
				inst.sg:GoToState("spotdodge")
			end),
			
			EventHandler("jump", function(inst)
				-- inst.sg:GoToState("idk")
				-- inst:PushEvent("clearbuffer")
				-- inst.components.stats.buffertick = 0
				inst:RemoveTag("wantstoblock") --1-20-17 PERFECT c:
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
		
		ontimeout = function(inst)	--NVM, I FIXED IT  THIS SEEMS TO BE INCONSISTANT WITH ACTUAL BLOCKSTUN. WHEN HIT WITH HEAVIER ATTACKS, HALFWAY THROUGH THE HITSTUN, IT WEARS OFF AND SHE TRIES TO MOVE BUT IS STILL FROZEN
			inst.sg:RemoveStateTag("busy")
			inst.sg:AddStateTag("canoos")
        end,
		
		 timeline =
        {
            
			TimeEvent(3*FRAMES, function(inst)   --NVM, I FIXED IT --AS SOON AS HITLAG IS FIXED, CHANGE THIS SO THAT THE PARRY STATE IS NEVER BUSY
				-- inst.sg:RemoveStateTag("busy")
			end),
			
    
        },
        
        events=
        {
            --EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
	
	--3-23, ITS ABOUT TIME I RE-DID THIS AWEFUL STATE.
	--3-22 NEW VERSION
	State{
        name = "block_stunned",
        tags = {"blocking", "tryingtoblock", "busy", "block_stunned"},  
        
        onenter = function(inst, timeout)
			inst.AnimState:PlayAnimation("wicker_blockstunned") --blockstunned_long
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
			inst.AnimState:PlayAnimation("wicker_blockstunned_resume")
			--inst.AnimState:SetMultColour(1,1,0,1)
			
			if inst:HasTag("wantstoblock") then --1-19-17 THIS IS WHERE IT BELONGED -I GUESS?? --SO NOW WHAT IS THE PURPOS OF THIS STATE????
				inst.sg:GoToState("block")
			else
				inst.sg:GoToState("block_stop")
			end
        end,

        
        timeline =
        {
            
			-- TimeEvent(2*FRAMES, function(inst)     --1-19-17 FINALLY REMOVING THIS FROM WHERE IT DIDNT BELONG
				-- if inst:HasTag("wantstoblock") then
					-- inst.sg:GoToState("block")
				-- else
					-- inst.sg:GoToState("block_stop")
				-- end
			-- end),
			
    
        },
    },
	
	State{
        name = "block_stop",
        tags = {"tryingtoblock", "busy"},  --"blocking", 
        
        onenter = function(inst, target)
			-- inst.AnimState:PlayAnimation("run_pst")
			inst.AnimState:PlayAnimation("wicker_block_drop")
        end,
		
		onupdate = function(inst)
			--CHEAP HOTFIX TO ENSURE THIS STATE DOESN'T ADD EXTRA FRAMES TO THE ENDLAG
        end,
        
        timeline =
        {
			-- TimeEvent(1*FRAMES, function(inst) inst.sg:RemoveStateTag("blocking") end), --REMOVING 1-22
            
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
			inst.AnimState:PlayAnimation("wickerdodge")
			inst.components.hitbox:Blink(inst, 4,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			-- inst.components.locomotor:TurnAround()
			
			-- inst.task_1 = inst:DoPeriodicTask(0.1, function(inst)
					-- inst.Physics:SetMotorVel(-14, 0, 0) --10
				-- end)
        end,

        onexit = function(inst)
			inst.components.locomotor:Clear()
			if inst.task_1 then
				inst.task_1:Cancel()
			end
        end,
        
        timeline =
        {
		   
			TimeEvent(1*FRAMES, function(inst)
				-- inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
				inst.sg:AddStateTag("intangible")
				inst.task_1 = inst:DoPeriodicTask(0.1, function(inst)
					inst.Physics:SetMotorVel(14, 0, 0)
				end)
		    end),
		      
			  
			 TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", -0.3, 0, -0.2,   1.0, 1.0,   0.6, 8, 0)
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
				-- inst.components.hitbox:MakeFX("slide1", 1.5, 0, -0.2,   -0.8, 0.8,   0.6, 8, 0)
				inst.AnimState:SetMultColour(1,1,1,1)
			end),
			
			TimeEvent(9*FRAMES, function(inst)
				inst.components.locomotor:Stop()
				
				inst.components.jumper:ScootForward(7) --10
			end),
			
			
			
			
            TimeEvent(16*FRAMES,
				function(inst)
				--CHECK FOR IF STILL HOLDING SHEILD  --TODOLIST
					inst.components.locomotor:TurnAround()
                    -- inst.sg:RemoveStateTag("busy")
					inst.sg:GoToState("idle")
				end),
        },
        
    },
	
	
	State{
        name = "airdodge",
        tags = {"dodging", "busy", "airdodging", "ll_medium"}, 
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("spotdodge_air")
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
        tags = {"busy", "grabbing"}, 
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("grab")
        end,

        onexit = function(inst)
            --inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true) --THE HECK IS THIS HERE FOR?
        end,
        
        timeline =
        {
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(0.5) --0.5 
				inst.components.hitbox:SetLingerFrames(20)
			
				inst.components.hitbox:SpawnGrabbox(0.5, 1, 0)  --1,1,0
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(8)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetDamage(7)   --7
				inst.components.hitbox:SetSize(4, 4)
				inst.components.hitbox:SetLingerFrames(20)

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
			-- inst.components.stats.opponent.Physics:SetActive(false)
        end,

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true) --THE HECK IS THIS HERE FOR?
			-- inst.components.stats.opponent.Physics:SetActive(true)
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
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("grabbed")
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
			inst.AnimState:PlayAnimation("wicker_jab2")
			inst.AnimState:Resume()
        end,
        
        timeline =
        {
			TimeEvent(2*FRAMES, function(inst)   
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(48)
				inst.components.hitbox:SetGrowth(84)
				inst.components.hitbox:SetSize(1)

				inst.components.hitbox:SpawnHitbox(1, 1, 0) 
			end),
			
			TimeEvent(18*FRAMES, function(inst)   --16
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
        tags = {"attack", "busy", "force_direction", "handling_opponent"},
        
        onenter = function(inst, target)
			inst.components.stats:GetOpponent()
			inst.AnimState:PlayAnimation("wickerbthrow")
			inst.AnimState:Resume()
        end,
        
        timeline =
        {
			TimeEvent(7*FRAMES, function(inst)
				inst.components.stats:GetOpponent()
				inst.components.stats.opponent.sg:GoToState("thrown")
				inst.components.stats.opponent.components.launchgravity:Launch(10, 12, 0)
			end),

			
			
			TimeEvent(12*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(138) --42-138 --150 IS TOO LOW, TOO HARD TO RECOVER
				inst.components.hitbox:SetBaseKnockback(90) --98
				inst.components.hitbox:SetGrowth(25) --35
				inst.components.hitbox:SetSize(2)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:AddSuction(1, -0.1, 1.2)
				
				inst.components.hitbox:AddEmphasis(-5)
				
				inst.components.hitbox:SpawnHitbox(0, 2, 0) 
			end),
			
			TimeEvent(23*FRAMES, function(inst)
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
			TimeEvent(60*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy") --JUST AN EMERGENCY BACKUP
			end),
        },
    },
	
	
	State{
        name = "fair",
        tags = {"attack", "notalking", "busy", "ll_medium"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("wickerfair")
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
		end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)   --16
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				inst.components.launchgravity:SetLandingLag(10)
			end),
			
			TimeEvent(3*FRAMES, function(inst)   --16
				inst.components.hitbox:MakeFX("glint_ring_1", 1.35, 0.65, 0.1,   0.5, 0.5,   0.3, 5, 0.7,  0, 0, 0,   1) 
				--(fxname, xoffset, yoffset, zoffset,    xsize, ysize,    alpha, duration, glow,   r, g, b,    stick, build, bank)
				
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(361) 
				inst.components.hitbox:SetBaseKnockback(25) --7
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.4, 0.3)
				inst.components.hitbox:SetLingerFrames(4) 
				
				inst.components.hitbox:SpawnHitbox(0.35, 0.5, 0)  --(0.35, 0.5, 0) 
			end),
			
            TimeEvent(4*FRAMES, function(inst) 
				-- inst.components.hitbox:SetDamage(7)
				-- inst.components.hitbox:SetAngle(361) 
				-- inst.components.hitbox:SetBaseKnockback(7)
				-- inst.components.hitbox:SetGrowth(100)
				-- inst.components.hitbox:SetSize(0.6, 0.3)
				-- inst.components.hitbox:SetLingerFrames(3) --2
				
				-- inst.components.hitbox:SpawnHitbox(0.35, 0.6, 0) 
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				
				
				-- inst.components.hitbox:SetDamage(12)
				-- inst.components.hitbox:SetAngle(46)
				-- inst.components.hitbox:SetBaseKnockback(30)
				-- inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetDamage(15) --17 --10-19-17 AIGHT IMA EDIT THESE JUST A BIT
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(26) --24
				inst.components.hitbox:SetGrowth(115) 
				inst.components.hitbox:SetSize(0.35) --35
				inst.components.hitbox:SetLingerFrames(2) --2
				
				inst.components.hitbox:SetHitFX("glint_ring_1", "dontstarve/wilson/hit") --2
				
				inst.components.hitbox:SetOnHit(function() 
					inst.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
					inst.SoundEmitter:PlaySound("dontstarve/HUD/research_available")
					inst.components.hitbox:MakeFX("idle", 1.35, 0.6, 0.1,   1.5, 1.5,   0.5, 5, 0.8,  0, 0, 0,   1, "impact", "impact") 
				end)
				
				inst.components.hitbox:SpawnHitbox(1.15, 0.5, 0) --(1.35, 0.6, 0)
				
			end),
		
			
            TimeEvent(18*FRAMES, function(inst)   --16
				-- inst.sg:RemoveStateTag("attack") 
				-- inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("air_idle")
			
			end),
        },
    },
	
	
	State{
        name = "bair",
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("wickerbair")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.components.launchgravity:SetLandingLag(6)
        end,
        
        timeline=
        {
            TimeEvent(4*FRAMES, function(inst) 
			
				-- inst:PushEvent("swaphurtboxes", {preset = "grounded"})
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				inst.components.hitbox:MakeFX("punchwoosh", -1.2, 1.0, -1.5,   1.0, 1.0,   0.5, 4, 0.4,  0, 0, 0,   1) 
				
				inst.components.hitbox:SetDamage(13) 
				inst.components.hitbox:SetAngle(-361)
				inst.components.hitbox:SetBaseKnockback(25)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.7, 0.75)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-0.8, 0.5, 0) 
				-- inst.components.hitbox:SpawnHitbox(-0.4, 0.35, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			
			TimeEvent(8*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			end),
			
            TimeEvent(21*FRAMES, function(inst) 
				inst.sg:GoToState("air_idle")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                -- inst.sg:GoToState("air_idle")
            end),
        },
    },
	
	
	State{
        name = "dair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("wicker_dair") 
			
        end,
		
		onexit = function(inst)

        end,
		
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.launchgravity:SetLandingLag(8)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				inst.components.hitbox:MakeFX("woosh1down", 0.1, 0.95, 0.1,   1.6, 1.6,   0.9, 5, 0,   0,0,0, 1)
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(270) 
				inst.components.hitbox:SetBaseKnockback(15)
				inst.components.hitbox:SetGrowth(130)
				inst.components.hitbox:SetLingerFrames(1)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				inst.components.hitbox:SetSize(0.5, 0.65)
				--inst.components.hitbox:SetSize(15) --12-1 FOR TEST PURPOSES ONLY
				
				inst.components.hitbox:SpawnHitbox(0, -0.2, 0) 
				-- inst.components.hitbox:SpawnHitbox(0, 0.5, 0) 
					
			end),
			
			
            TimeEvent(20*FRAMES, function(inst) 
			-- inst.sg:RemoveStateTag("attack") 
			-- inst.sg:RemoveStateTag("busy")
			inst.sg:GoToState("air_idle")
			
			end),
        },
        
    },
	
	
	State{
        name = "nair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("wickernair")
			--inst.AnimState:PlayAnimation("uspecial")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			
			inst.components.launchgravity:SetLandingLag(4)
            
        end,
        
        timeline=
        {
			
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(22)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(1.1, 0.35) --(0.75, 0.5) -- (1.5, 1)  --1.5
				
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(0.55, 0.35, 0) 
				
				
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(80)--361
				inst.components.hitbox:SetBaseKnockback(15)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.75, 0.35) --(0.75, 0.5) -- (1.5, 1)  --1.5
				
				inst.components.hitbox:SetLingerFrames(14)
				
				inst.components.hitbox:SpawnHitbox(0.35, 0.3, 0)
			end),
			
            TimeEvent(16*FRAMES, function(inst) 
				inst.AnimState:PlayAnimation("idle_air")
			end),
			
			TimeEvent(18*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
			end),
			
			TimeEvent(20*FRAMES, function(inst) 
				inst.sg:GoToState("air_idle")
			end),
        },
    },
	
	
	State{
        name = "uair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("wickeruair")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			-- inst.components.launchgravity:SetLandingLag(10)
			inst.components.launchgravity:SetLandingLag(4, nil, "uair_pst")
        end,
		
		onexit = function(inst)

        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(1)
				inst.components.hitbox:SetAngle(366) --THEEEEERE WE GO
				inst.components.hitbox:SetBaseKnockback(30) --CHANGE IT BACK TO 30
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetSize(0.8)
				
				inst.components.hitbox:AddSuction(0.6, 0, 0.7) --power, x, y
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.5, 1.2, 0) --2.5
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				-- inst.components.hitbox:AddSuction(0.4, 0, 1.2) --power, x, y
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0, 2.1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:AddSuction(0.6, 0, 0.7) --power, x, y
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0, 2.1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0, 2.1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0, 2.1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(45) --50 THIS KILLS WAY TOO EARLY
				inst.components.hitbox:SetGrowth(120) --140
				inst.components.hitbox:SetSize(1)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0, 2.3, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
            TimeEvent(23*FRAMES, function(inst) 
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
	
	--10-30-24 - LET'S RAISE THIS CEILING A BIT...
	State{
        name = "uair_pst",
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("landing")
			inst.components.hitbox:SetDamage(5)
			inst.components.hitbox:SetAngle(50)--245
			inst.components.hitbox:SetBaseKnockback(30)
			inst.components.hitbox:SetGrowth(70)
			inst.components.hitbox:SetSize(1)
			inst.components.hitbox:SetLingerFrames(2)
			
			inst.components.hitbox:AddSuction(0.8, 0.5, 0) --power, x, y
			
			inst.components.hitbox:MakeDisjointed()
			inst.components.hitbox:SpawnHitbox(0, 2.1, 0)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
            
        end,
		
        
        timeline=
        {
            TimeEvent(5*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
			end),
			
			TimeEvent(8*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	State{
        name = "jab1",
        tags = {"attack", "listen_for_attack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("wicker_jab1")
			-- inst.AnimState:PlayAnimation("wickerdownb")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				-- for k, v in pairs(getmetatable(GetPlayer().AnimState).__index) do print(k, v) end
				-- for k, v in pairs(getmetatable(TheWorld.Map).__index) do print(k, v) end   
				-- for k, v in pairs(getmetatable(TheNet).__index) do print(k, v) end   
			
			inst:PushEvent("swaphurtboxes", {preset = "leanf"})
        end,
        
        timeline=
        {
           TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(1)
				inst.components.hitbox:SetAngle(78) 
				inst.components.hitbox:SetBaseKnockback(15) --40??
				inst.components.hitbox:SetGrowth(0) --100
				inst.components.hitbox:SetSize(0.6, 0.3)
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:AddEmphasis(5)
				inst.components.hitbox:AddSuction(0.4, 0.5, 0)
				
				inst.components.hitbox:SpawnHitbox(0.7, 0.8, 0) --2.5
			end),
			
            -- TimeEvent(12*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("canjab")
			-- end),
			
			TimeEvent(14*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.sg:AddStateTag("canjab")				
			end),
        },
        
        events=
        {
            -- EventHandler("animover", function(inst)
                -- inst.sg:GoToState("idle")
            -- end),
        },
		
		events=
        {
            EventHandler("attack_key", function(inst)
				if inst.sg:HasStateTag("canjab") then
					inst.sg:GoToState("jab2")
				end
            end),
        },
    },
	
	State{
        name = "jab2",
        tags = {"attack", "listen_for_attack", "busy"}, --"noclanking"
        
        onenter = function(inst)

			inst.AnimState:PlayAnimation("wicker_jab2")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)	
				-- inst.components.hurtboxes:ShiftHurtboxes(0.5, 0) --12-19 THIS IS REALLY DUMB THAT I HAVE TO DO THIS
				
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetDamage(4)   --7
				-- inst.components.hitbox:SetSize(0.75)
				inst.components.hitbox:SetSize(0.8, 0.6)
				inst.components.hitbox:AddEmphasis(0)
				
				inst.components.hitbox:SpawnHitbox(0.80, 1, 0) 
				
				-- inst.sg:AddStateTag("jab2") 
			end),
			
            TimeEvent(14*FRAMES, function(inst) 
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
        name = "dash_attack",
        tags = {"busy", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("wicker_dashattack")
			inst.AnimState:SetTime(1*FRAMES) --EHH, I MADE THIS ANIMATION START UP TOO SLOW
			-- inst.Physics:SetFriction(.5)
			inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			-- inst:PushEvent("swaphurtboxes", {preset = "sliding"})
        end,
		
		onexit = function(inst)
			inst.components.stats:ResetFriction()
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.jumper:ScootForward(12)
				inst.Physics:SetFriction(.9)		
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("woosh1", 0.5, 0.9, -0.1,   0.9, 1.8,   0.9, 5, 0,  0,0,0,  1)
				inst:PushEvent("swaphurtboxes", {preset = "leanf"})
			end),
			
			TimeEvent(4*FRAMES, function(inst)
				inst.components.jumper:ScootForward(6)
				
				inst.components.hitbox:SetDamage(8) --BASED OFF LUCARIO'S DASH ATTACK
				inst.components.hitbox:SetAngle(50)
				inst.components.hitbox:SetBaseKnockback(70)
				inst.components.hitbox:SetGrowth(75)
				inst.components.hitbox:SetSize(0.8, 0.3)
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(0.85, 0.9, 0) 
				
				
				--AND THEN A LINGERING WEAK HIT
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetSize(0.7, 0.2)
				inst.components.hitbox:SetLingerFrames(3)
				inst.components.hitbox:SpawnHitbox(0.85, 0.9, 0) 
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "idle"})			
			end),
			
            TimeEvent(22*FRAMES, function(inst) 
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
	
	
	
	
	
	State{
        name = "ftilt",
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst)
		
			inst.AnimState:PlayAnimation("wickerftilt2")
			inst.AnimState:SetTime(1*FRAMES)
			
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")

            inst:PushEvent("swaphurtboxes", {preset = "leanf"})
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("woosh1", 0.2, 1.0, 0.1,   1.6, 1.8,   0.9, 5, 0)				
			end),
			
			TimeEvent(3*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(1.15, 0.3)
				inst.components.hitbox:SetLingerFrames(0)

				inst.components.hitbox:SpawnHitbox(0.8, 0.95, 0)  
			end),
			
            TimeEvent(18*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
			end),
        },
    },
	
	
	
	
	State{
        name = "dtilt",
        tags = {"attack", "force_direction", "busy"},
        
        onenter = function(inst)
			
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
            inst:PushEvent("swaphurtboxes", {preset = "ducking"})
        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("dtilt")
				inst.components.hitbox:SetDamage(7) 
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(20)  --15
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.65, 0.3)
				inst.components.hitbox:SpawnHitbox(0.9, 0.2, 0) 
			end),
			
            TimeEvent(9*FRAMES, function(inst) --7
				inst.sg:GoToState("idle")				
			end),
        },
    },
	
	
	State{
        name = "uptilt",
        tags = {"attack", "notalking", "abouttoattack", "busy"},
        
        onenter = function(inst)
            --inst.AnimState:PlayAnimation("punch")
			inst.AnimState:PlayAnimation("wickerutilt")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			inst.components.hitbox:MakeFX("half_circle_backward_woosh", 0.3, 1.0, 0.1,  -1.5, 2.1,   1, 6, 0)
            
        end,
        
        timeline=
        {
            --TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
			TimeEvent(2*FRAMES, function(inst)
				
				inst.components.hitbox:SetDamage(10) --18 RYU'S
				inst.components.hitbox:SetAngle(85)
				inst.components.hitbox:SetBaseKnockback(80)
				inst.components.hitbox:SetGrowth(69)
				
				-- inst.components.hitbox:SetSize(1.5) --FINALLY GETTING AROUND TO MAKING THIS FAIR
				-- inst.components.hitbox:SpawnHitbox(0.5, 1, 0)
				
				--SOURSPOT? --NAH
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetSize(0.3)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.6, 0.35, 0)
				
				-- inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.7, 0.35, 0)

			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetSize(1.0)
				inst.components.hitbox:SpawnHitbox(0.65, 1, 0)
				inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			end),
			
			
            TimeEvent(20*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                --inst.sg:GoToState("idle")
            end),
        },
    },
	
	State{
        name = "fspecial",
        tags = {"attack", "notalking", "nolandingstop", "busy", "noairmoving", "no_fastfalling", "force_direction"},
        
        onenter = function(inst)
			-- inst.AnimState:PlayAnimation("nspecial_retry")
			inst.AnimState:PlayAnimation("wicker_fspecial")
            
        end,
        
        timeline=
        {
			
			TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				if inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
				inst.components.jumper:AirStall(2, 1) --OKAY, WE SHOULD MAKE AN ACTUAL USE OUT OF THIS!!!!---
				-- inst.components.launchgravity:Launch(0,7,0) --7-9-17
				-- inst.components.launchgravity:AirOnlyLaunch(0,7,0)
				inst.sg:AddStateTag("reducedairacceleration")
				
			end),
			
			
			TimeEvent(6*FRAMES, function(inst)
				
				inst.components.hitbox:SetDamage(9)
				inst.components.hitbox:SetAngle(49)
				inst.components.hitbox:SetBaseKnockback(70)
				inst.components.hitbox:SetGrowth(35)
				
				
				inst.components.hitbox:SetSize(0.4, 1)
				inst.components.hitbox:SetLingerFrames(0)
				--inst.components.hitbox:SetProperty(5)
				--ADD SOME UPWARD SUCTION SO THE PROJECTILE IS MORE LIKELY TO SLIDE UNDER THEM
				-- inst.components.hitbox:AddSuction(0.7, 1.2, 1.4) --power, x, y
				inst.components.hitbox:AddSuction(0.7, 1.4, nil) --power, x, y
				inst.components.hitbox:MakeDisjointed()
				
				
				inst.components.hitbox:SetOnPostHit(function() 
					local opponent = inst.components.stats.opponent
					if not opponent.sg:HasStateTag("blocking") and not opponent:HasTag("nofreezing") then
						opponent:PushEvent("freeze")
						--7-30-17 THIS WILL PREVENT THE ICE SPAM. HOPEFULLY
						opponent:AddTag("nofreezing")
						opponent:DoTaskInTime(2, function()
							opponent:RemoveTag("nofreezing") 
						end)
					end
				end)
				
				inst.components.hitbox:SpawnHitbox(0.2, 1.4, 0) 
			end),
			
			
			TimeEvent(7*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("spike1", 1.5, 0, 0.3,   -1.2, 0.8,   1, 8, 0,  0, 0, 0,   0, "deerclops_icespike", "deerclops_icespike")
				local camprefab = TheSim:FindFirstEntityWithTag("cameraprefab") --SO IT PLAYS A BIT CLOSER
				camprefab.SoundEmitter:PlaySound("dontstarve/wilson/attack_icestaff")
				
				inst.components.hitbox:AddEmphasis(3)
				-- inst.components.hitbox:SetHitFX("default", "dontstarve/common/gem_shatter")
				inst.components.hitbox:SetSize(1.1)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.85, 0.6, 0) 
			end),
			
			
			
			
			TimeEvent(8*FRAMES, function(inst)
				inst:PushEvent("swaphurtboxes", {preset = "forward"})
				inst.components.hurtboxes:ShiftHurtboxes(0.5, 0)
				inst.components.hitbox:AddEmphasis(3)
				inst.components.hitbox:SetSize(1.0, 0.3)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.3, 0.2, 0) 
			end),
			
			
			
			
			TimeEvent(9*FRAMES, function(inst)
				-- inst.components.locomotor:SlowFall(0.5, 8) --7-9-17    --8-4-17 NO GET RID OF THIS IT SUCKS
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/ice_small")
				
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_icestaff")
				-- TheFocalPoint.SoundEmitter:PlaySound("dontstarve/wilson/attack_icestaff")
				-- local camprefab = TheSim:FindFirstEntityWithTag("cameraprefab")
				
				
				inst.components.hitbox:SetDamage(4)
				inst.components.hitbox:SetAngle(90)
				inst.components.hitbox:SetBaseKnockback(7)
				inst.components.hitbox:SetGrowth(0) --LAUNCH VALUES ARE SET IN THE FREEZE STATE ITSELF (BAD IDEA) SO WE CAN JUST DO WHAT WE WANT WITH THESE
				
				inst.components.hitbox:SetSize(0.4)
				inst.components.hitbox:SetLingerFrames(90)
				-- inst.components.hitbox:SetProperty(5) --ONPOSTHIT DOESNT WORK WITH THIS
				inst.components.hitbox:AddSuction(0, 0, 0)
				
				
				local projectile = SpawnPrefab("basicprojectile")
				
				inst.components.hitbox:SetProjectileAnimation("projectile", "staff_projectile", "ice_spin_loop")
				inst.components.hitbox:SetProjectileSpeed(12, 0.4)
				if inst.components.launchgravity:GetIsAirborn() then
					inst.components.hitbox:SetProjectileSpeed(9, -4)
				end
				
				inst.components.hitbox:SetProjectileDuration(30) --250 IS SO LONG. DONT GIVE IT SO MUCH RANGE
				-- projectile:RemoveTag("deleteonhit") --NO, THIS IS A BIT TOO POWERFUL
				
				-- projectile.components.projectilestats.yhitboxoffset = 1 --NOT ANYMORE, WE FIXED THE ANIMATION
				projectile.Transform:SetScale(1, 1, 1)
				
				--1-11-22 IF WE'RE ALREADY FROZEN, DON'T DO ANY KNOCKBACK SO WE DON'T UNFREEZE
				inst.components.hitbox:SetOnPreHit(function() 
					local opponent = projectile.components.stats.opponent
					--IF THE OPPONENT WAS FREEZING, SET OUR KB TO 0 
					if opponent.sg and opponent.sg:HasStateTag("frozen") then
						for k, v in pairs(projectile.components.hitbox.hitboxtable) do --WOW. THIS IS GETTING COMPLICATED
							v.components.hitboxes.scale = 0
							v.components.hitboxes.base = 0
						end
					end
				end)
				
				inst.components.hitbox:SetOnPostHit(function() 
					local opponent = projectile.components.stats.opponent
					-- opponent.sg:GoToState("frozen")
					if not opponent.sg:HasStateTag("blocking") and not opponent:HasTag("nofreezing") then
						opponent:PushEvent("freeze")
						-- opponent.components.jumper:AirStall(2, 2)
						-- opponent.components.launchgravity:AirOnlyLaunch(0,15,0)
						
						--7-30-17 THIS WILL PREVENT THE ICE SPAM. HOPEFULLY
						opponent:AddTag("nofreezing")
						opponent:DoTaskInTime(2, function()
							opponent:RemoveTag("nofreezing") 
						end)
					end
				end)
				
				
				
				if inst.components.launchgravity:GetIsAirborn() then
					inst.components.hitbox:SpawnProjectile(0.3, 0, 0, projectile) --WHY IS THIS SPAWNING IN THE CENTER????
				else
					inst.components.hitbox:SpawnProjectile(0.3, -0.8, 0, projectile) 
				end
				
			end),
			
			
			
			
			TimeEvent(28*FRAMES, function(inst)
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
				-- inst.components.hurtboxes:ShiftHurtboxes(-0.5, 0)
			end),
			
			TimeEvent(31*FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
			
			
        },
        
    },
	
	
	State{
        name = "uspecial",
        tags = {"attack", "busy", "can_grab_ledge", "no_air_transition", "no_fastfalling", "nolandingstop"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("wicker_bookcharge")
			inst.components.launchgravity:Launch(0, 2)
            -- inst.components.launchgravity:AirOnlyLaunch(0, 4)
			-- inst.components.locomotor:SlowFall(0.5, 13)
			-- inst.components.jumper:AirStall(0.8, 1) --??? TF IS IT DOING???
			inst.components.hitbox:MakeFX("book_fx_90s", -0.4, 0.6, -0.2,   0.5, 0.5,   1, 15, 0,  0,0,0, 1, "book_fx", "book_fx")
			--11-8-17 NOW SHE GETS DIFFERENT LEDGEGRAB BOXES
			-- inst.components.hurtboxes:RemoveAllGrabboxes()
			inst.components.hurtboxes:ReplaceLedgeGrabBox(0.2, 1.3, 0.8, 0.6, 0) --(xpos, ypos, sizex, sizey, shape)
		end,
		
		onupdate = function(inst)
			if inst.components.keydetector:GetUp(inst) then 
				if inst.components.launchgravity:GetVertSpeed() <= 6 then
					inst.components.launchgravity:Push(0,2,0)
				end
			end
			if inst.components.launchgravity:GetVertSpeed() <= -7 then --4-22-17  --LETS GIVE HER A MAX FALLING SPEED TOO SO SHE DOESNT FALL LIKE A ROCK
				inst.components.launchgravity:Push(0,2,0)
			end
        end,
		
		onexit = function(inst)
			--11-8-17 BUT DONT FORGET TO PUT THEM BACK TO DEFAULT
			-- inst.components.hurtboxes:RemoveAllGrabboxes()
			inst.components.hurtboxes:ReplaceLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0) --(xpos, ypos, sizex, sizey, shape)
			
			inst.components.hitbox:SetDamage(1) --25
			inst.components.hitbox:SetAngle(80)
			inst.components.hitbox:SetBaseKnockback(30)
			inst.components.hitbox:SetGrowth(62)
			inst.components.hitbox:SetSize(0.3) --1
			inst.components.hitbox:SetLingerFrames(120)
			inst.components.hitbox:SetProperty(5) --THERE. THIS ITSELF DOESNT DO KNOCKBACK
			
			inst.components.hitbox:SetProjectileAnimation("crow", "crow_build", "flap_loop") --NO CUSTOM ANIMATIONS FOR THESE! I TOOK ALL THE EXISTING ANIMATIONS RIGHT FROM THE GAME
			inst.components.hitbox:SetProjectileSpeed(2, 20)
			inst.components.hitbox:SetProjectileDuration(60)
			
			
			local projectile = SpawnPrefab("basicprojectile")
			projectile:RemoveTag("deleteonhit")
			projectile.Transform:SetScale(0.6, 0.6, 0.6)
			projectile:DoPeriodicTask(0.5, function(projectile) 
				projectile.AnimState:PlayAnimation("flap_loop")
			end)
			
			local projectile2 = SpawnPrefab("basicprojectile")
			projectile2:RemoveTag("deleteonhit")
			projectile2.Transform:SetScale(0.6, 0.6, 0.6)
			projectile2:DoPeriodicTask(0.5, function(projectile2) 
				projectile2.AnimState:PlayAnimation("flap_loop")
			end)
			
			local projectile3 = SpawnPrefab("basicprojectile")
			projectile3:RemoveTag("deleteonhit")
			projectile3.Transform:SetScale(0.6, 0.6, 0.6)
			projectile3:DoPeriodicTask(0.5, function(projectile3) 
				projectile3.AnimState:PlayAnimation("flap_loop")
			end)

			
			inst.components.hitbox:SpawnProjectile(0, 2, 0, projectile) 
			inst.components.hitbox:SpawnProjectile(0.4, 1.4, 0, projectile2) 
			inst.components.hitbox:SpawnProjectile(-0.4, 1.3, 0, projectile3) 
        end,
		
        
        timeline=
        {
		
			TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				if inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
				inst.components.launchgravity:AirOnlyLaunch(0, 4)
			end),
			
			TimeEvent(10*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.components.hitbox:MakeFX("punchwoosh", 0, 1.35, 0.2,   2.0, 2.0,   0.5, 4, 0.4,  0, 0, 0,   1) 
				inst.AnimState:PlayAnimation("wickerupb")
				inst.components.hitbox:MakeFX("flap_loop", 0.5, 1.4, 0,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
				inst.components.hitbox:MakeFX("flap_loop", 0, 2, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow")
				inst.components.hitbox:MakeFX("flap_loop", -0.55, 1.4, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow")
				--WOW THESE SOUNDS ARE PITIFULLY LOW... I WONDER IF THIS COULD WORK? -WELL MAYBE IT HELPS A LITTLE. BUT THE CAMPREFAB IS ACTUALLY STILL SOMEWHAT DISTANT FROM THE ACTUAL CAMERA
				local camprefab = TheSim:FindFirstEntityWithTag("cameraprefab")
				camprefab.SoundEmitter:PlaySound("dontstarve/birds/takeoff_crow")
				camprefab.SoundEmitter:PlaySound("dontstarve/birds/chirp_crow")
				camprefab.SoundEmitter:PlaySound("dontstarve/birds/flyin")
				camprefab.SoundEmitter:PlaySound("dontstarve/birds/takeoff_robin")
				
				inst.components.launchgravity:Launch(0, 5)
				inst.sg:RemoveStateTag("nolandingstop")
			end),
			
			TimeEvent(15*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.components.hitbox:MakeFX("flap_loop", 0.5, 1.4, 0,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
				inst.components.hitbox:MakeFX("flap_loop", 0, 2, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow")
				inst.components.hitbox:MakeFX("flap_loop", -0.55, 1.4, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow")
				
			end),
			TimeEvent(30*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.components.hitbox:MakeFX("flap_loop", 0.5, 1.4, 0,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
				inst.components.hitbox:MakeFX("flap_loop", 0, 2, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow")
				inst.components.hitbox:MakeFX("flap_loop", -0.55, 1.4, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow")
			end),
			TimeEvent(45*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.components.hitbox:MakeFX("flap_loop", 0.5, 1.4, 0,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
				inst.components.hitbox:MakeFX("flap_loop", 0, 2, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow")
				inst.components.hitbox:MakeFX("flap_loop", -0.55, 1.4, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow")
			end),
			TimeEvent(60*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.components.hitbox:MakeFX("flap_loop", 0.5, 1.4, 0,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
				inst.components.hitbox:MakeFX("flap_loop", 0, 2, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow")
				inst.components.hitbox:MakeFX("flap_loop", -0.55, 1.4, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow")
			end),
			TimeEvent(75*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.components.hitbox:MakeFX("flap_loop", 0.5, 1.4, 0,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
				inst.components.hitbox:MakeFX("flap_loop", 0, 2, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow")
				inst.components.hitbox:MakeFX("flap_loop", -0.55, 1.4, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "crow_build", "crow")
			end),
			
			
			
			
			
			
            TimeEvent(80*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("freefall")
			
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.AnimState:PlayAnimation("wickerupb")
            end),
			
			EventHandler("down", function(inst)
				inst.sg:GoToState("freefall") 
				-- inst.components.jumper:UnFastFall() --4-22-17 YEA DONT HIT THE GROUND LIKE A METEOR
				inst.components.launchgravity:AirOnlyLaunch(0, 1)
			end ),
			
        },
    },
	
	
	--10-20-17 MOVING TENTICLE TO ITS OWN SPECIAL.
	State{
        name = "dspecial",
        tags = {"attack", "abouttoattack", "busy", "nolandingstop", "no_air_transition", "reducedairacceleration"}, 
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("wickerdownb")         
			inst.SoundEmitter:PlaySound("dontstarve/common/use_book")  --WHY DOES THE SOUND SEEM TO COME OUT FASTER IN THE SOUND TEST?...
			-- inst.components.hitbox:MakeFX("book_fx_90s", -0.3, 0.5, -0.2,   1, 1, 1,    58, 0,  0,0,0, 0, "book_fx", "book_fx")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
					
		end,
		
		
        timeline=
        {
			
			TimeEvent(3*FRAMES, function(inst) 
				-- local xvel, yvel = inst.Physics:GetVelocity()
				-- if yvel <= -0.1 then
					-- inst.components.hitbox:MakeFX("ground_bounce", 0, -0.6,-0.3,   1.0,1.0,  0.3, 11, 0.3)
				-- end
				inst.components.jumper:AirStall(10, 1)
				inst.components.locomotor:SlowFall(0.1, 30)
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				local xvel, yvel = inst.Physics:GetVelocity()
				if yvel <= -0.1 then
					inst.components.hitbox:MakeFX("ground_bounce", 0, -0.6,-0.3,   1.0,1.0,  0.3, 11, 0.3)
				end
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				local xvel, yvel = inst.Physics:GetVelocity()
				if yvel <= -0.1 then
					inst.components.hitbox:MakeFX("ground_bounce", 0, -0.6,-0.3,   1.0,1.0,  0.3, 11, 0.3)
				end
			end),
			
			TimeEvent(14*FRAMES, function(inst) 
				local xvel, yvel = inst.Physics:GetVelocity()
				if yvel <= -0.1 then
					inst.components.hitbox:MakeFX("ground_bounce", 0, -0.6,-0.3,   1.0,1.0,  0.3, 11, 0.3)
				end
			end),
			
			TimeEvent(19*FRAMES, function(inst) 
				local xvel, yvel = inst.Physics:GetVelocity()
				if yvel <= -0.1 then
					inst.components.hitbox:MakeFX("ground_bounce", 0, -0.6,-0.3,   1.0,1.0,  0.3, 11, 0.3)
				end
			end),
			
			TimeEvent(24*FRAMES, function(inst) 
				local xvel, yvel = inst.Physics:GetVelocity()
				if yvel <= -0.1 then
					inst.components.hitbox:MakeFX("ground_bounce", 0, -0.6,-0.3,   1.0,1.0,  0.3, 11, 0.3)
				end
			end),
			
			
			
			TimeEvent(10*FRAMES, function(inst) 
				--FIRST CHECK AND SEE IF WE CAN EVEN SPAWN A TENTACLE
				--REQUIREMENTS TO SPAWN A TENTACLE:
				--1. You cant already have one onscreen
				--2. You must be over solid ground
				--3. You must have at least one charge remaining
				local anchor = TheSim:FindFirstEntityWithTag("anchor")
				local mypos, myposy = inst.Transform:GetWorldPosition()
				-- print("SUSHI CHECK", inst.components.stats.storagevar1, inst.components.stats.storagereference1, inst.components.stats.storagereference1 and inst.components.stats.storagereference1:IsValid(), (mypos <= anchor.components.gamerules.lledgepos or mypos >= anchor.components.gamerules.rledgepos - 0))
				
				if inst.components.stats.storagevar1 <= 0 or
					(inst.components.stats.storagereference1 and inst.components.stats.storagereference1:IsValid()) or
					(mypos <= anchor.components.gamerules.lledgepos or mypos >= anchor.components.gamerules.rledgepos - 0) then
					
					inst.sg:GoToState("dspecial_dud")
				end
				
				
				inst.components.hitbox:MakeFX("book_fx_90s", -0.2, 0.6, -0.2,   0.8, 0.8,   1, 27, 0,  0,0,0, 1, "book_fx", "book_fx")
				inst.SoundEmitter:PlaySound("dontstarve/common/use_book_light")
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/common/book_spell")
			end),
			
			
			TimeEvent(20*FRAMES, function(inst) --3-31 CHANGING TO 20
			
				--FIRST MAKE SURE WE DONT ALREADY HAVE ONE
				if inst.components.stats.storagereference1 and inst.components.stats.storagereference1:IsValid() then
					--DO NOTHING! YOU ALREAY HAVE A TENTICAL
				else
					--1/11/22 YOU KNOW WHAT, JUST GET RID OF THIS FOR NOW. LETS SEE HOW THIS PLAYS OUT...
					--inst.components.stats.storagevar1 = inst.components.stats.storagevar1 - 1 
					--TENTACLE
					inst.components.stats.storagereference1 = SpawnPrefab("tentacle")
					local tentacle = inst.components.stats.storagereference1
					-- tentacle:SetStategraph("SGtentacle_turret") --12-16-18 CHANGED SG NAME TO AVOID CRASHES WITH EXISTING TENTACLES WHEN SPAWNING INTO A WORLD
					tentacle:AddTag("fighter")
					tentacle:AddComponent("stats")
					tentacle.components.stats.master = inst
					inst.components.stats.slave = tentacle --THIS WONT CAUSE HITBOX PROBLEMS, RIGHT?..
					tentacle.components.stats.team = inst.components.stats.team --12-30-21 DONT FORGET THIS!
					tentacle:AddComponent("hitbox")
					tentacle:AddComponent("hurtboxes") --7-14-19 OH THIS IS A TOUGH ONE... OKAY SO SHOULD THIS HAVE HURTBOXES OR NOT? HOW ABOUT WE LEAVE IT HERE AND JUST NOT SPAWN ANY HURTBOXES
					tentacle:AddComponent("launchgravity")
					tentacle:AddComponent("jumper")
					
					--7-15-18 HOPEFULY THIS WILL HELP ANY CRASHING RELATED TO AI TRYING TO TARGET IT
					tentacle:AddTag("notarget")
					tentacle:AddTag("nofreezing")
					tentacle.persists = false --1-27-22
					
					local x, y, z = inst.Transform:GetWorldPosition()
					y = 0
					z = 0
					tentacle.Transform:SetPosition(x - (1 * inst.components.launchgravity:GetRotationValue()), y + 0, z + 0)
					tentacle.Transform:SetScale(0.7, 0.7, 0.7)
					
					--1-21-22 GIVE IT A TEAM COLORED TINT, IF APPLICABLE
					tentacle.components.stats:TintTeamColor(0.4)
					
					--LIFE_OVER TAG MAKES IT DESPAWN AFTER IT'S FINISHED WITH IT'S CURRENT STATE
					tentacle:DoTaskInTime(8, function(tentacle) --4-5
						tentacle:AddTag("life_over")
					end)
					
					--3-27-22 ADDING A GLINT TO LET PLAYERS KNOW IT'S READY AGAIN.
					inst:DoTaskInTime(15, function(inst) --4-5
						-- (fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
						-- inst.components.hitbox:MakeFX("glint_ring_1", 0.2, 1.5, 0.3,   0.8, 0.8,   1, 7, 0,  1, 0, 1,   2) 
						inst.components.hitbox:MakeFX("glint_ring_1", 0.2, 1.5, 0.3,   0.8, 0.8,   0, 7, 0.5,  1, 0, 0,   2) 
			
					end)
				end
			end),
			
			
			TimeEvent(26*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("punchwoosh", 0.6, 2.05, -0.3,   -1.0, 1.0,   0.5, 4, 0.4,  0, 0, 0,   1) 
				inst.SoundEmitter:PlaySound("dontstarve/common/use_book_close")
			end),
			
			TimeEvent(45*FRAMES, function(inst) 
				inst.AnimState:PlayAnimation("wicker_book_pst")
			end),
			
            TimeEvent(52*FRAMES, function(inst)  --6-25-17 CHANGING THIS FROM 40 BC ITS WAY TOO LOW
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	
	
	State{
        name = "dspecial_dud",
        tags = {"busy", "nolandingstop", "no_air_transition"},

        onenter = function(inst)
			-- inst.AnimState:PlayAnimation("rise_cancel")
			
			-- inst.components.hitbox:Blink(inst, 10,   0.6, 0.3, 0.3, 0, 1) --Blink(inst, duration, r, g, b, glow, alpha)
			-- inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_despawn")
			-- inst.SoundEmitter:PlaySound("dontstarve/sanity/shadowhand_snuff")
        end,
		
		timeline=
        {
            TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				if inst.components.keydetector and inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				--GIVE THEM A HINT AS TO WHY THEY CAN'T SPAWN
				if inst.components.stats.storagevar1 <= 0 then
					inst.components.talker:Say("0 Charges left")
				end
				
				inst.components.hitbox:Blink(inst, 10,   0.6, 0.3, 0.3, 0, 1) --Blink(inst, duration, r, g, b, glow, alpha)
				inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_despawn")
				inst.SoundEmitter:PlaySound("dontstarve/sanity/shadowhand_snuff")
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.AnimState:PlayAnimation("wicker_book_pst")
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
		
	},
	
	
	
	State{
        name = "nspecial",
        tags = {"attack", "busy", "nolandingstop", "no_air_transition", "noairmoving"}, 
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("wickerdownb")     
			
			inst.SoundEmitter:PlaySound("dontstarve/common/use_book")  --WHY DOES THE SOUND SEEM TO COME OUT FASTER IN THE SOUND TEST?...
			-- inst.components.hitbox:MakeFX("book_fx_90s", -0.3, 0.5, -0.2,   1, 1, 1,    58, 0,  0,0,0, 0, "book_fx", "book_fx")
        end,
		
		
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				if inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				-- local xvel, yvel = inst.Physics:GetVelocity()
				-- if yvel <= -0.1 then
					-- inst.components.hitbox:MakeFX("ground_bounce", 0, -0.6,-0.3,   1.0,1.0,  0.3, 11, 0.3)
				-- end
				inst.components.jumper:AirStall(10, 1)
				inst.components.locomotor:SlowFall(0.1, 30)
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				local xvel, yvel = inst.Physics:GetVelocity()
				if yvel <= -0.1 then
					inst.components.hitbox:MakeFX("ground_bounce", 0, -0.6,-0.3,   1.0,1.0,  0.3, 11, 0.3)
				end
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				local xvel, yvel = inst.Physics:GetVelocity()
				if yvel <= -0.1 then
					inst.components.hitbox:MakeFX("ground_bounce", 0, -0.6,-0.3,   1.0,1.0,  0.3, 11, 0.3)
				end
			end),
			
			TimeEvent(14*FRAMES, function(inst) 
				local xvel, yvel = inst.Physics:GetVelocity()
				if yvel <= -0.1 then
					inst.components.hitbox:MakeFX("ground_bounce", 0, -0.6,-0.3,   1.0,1.0,  0.3, 11, 0.3)
				end
			end),
			
			TimeEvent(19*FRAMES, function(inst) 
				local xvel, yvel = inst.Physics:GetVelocity()
				if yvel <= -0.1 then
					inst.components.hitbox:MakeFX("ground_bounce", 0, -0.6,-0.3,   1.0,1.0,  0.3, 11, 0.3)
				end
			end),
			
			TimeEvent(24*FRAMES, function(inst) 
				local xvel, yvel = inst.Physics:GetVelocity()
				if yvel <= -0.1 then
					inst.components.hitbox:MakeFX("ground_bounce", 0, -0.6,-0.3,   1.0,1.0,  0.3, 11, 0.3)
				end
			end),
			
			
			
			
			TimeEvent(10*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("book_fx_90s", -0.2, 0.6, -0.2,   0.8, 0.8,   1, 27, 0,  0,0,0, 1, "book_fx", "book_fx")
				inst.SoundEmitter:PlaySound("dontstarve/common/use_book_light")
				
				
				--10-19-17 A SHADOW ON THE GROUND TO WARN THE PLAYER
				inst.components.hitbox:MakeFX("circle", 7, -0.2, 0,   1, 1,   0.7, 50, 0,   0,0,0, 1, "visible_hitbox", "visible_hitbox") 
				
										--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				local shadow = inst.components.stats.lastfx
				
				shadow.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround ) --PASTES THE CIRCLE ONTO THE GROUND INSTEAD OF STANDING UPRIGHT
				shadow.AnimState:SetMultColour(0,0,0,0.6)
				shadow:AddComponent("stats") --JUST FOR THE TINT LOL
				shadow.components.stats.team = inst.components.stats.team
				shadow.components.stats:TintTeamColor(0.15)
				
				local sizemult = 2 --SLOWLY INCREASE SHADOWS SIZE
				shadow:DoPeriodicTask(1*FRAMES, function(inst)
					shadow.Transform:SetScale(sizemult, sizemult, sizemult)
					sizemult = sizemult + 0.05
				end)
				
				local owner = inst
				shadow:DoTaskInTime(10*FRAMES, function(inst) --IF SHE WAS SLAPPED OUT OF STATE BEFORE THE METEOR SPAWNED, CANCEL THE SHADOW
					if owner.sg and owner.sg.currentstate.name ~= "nspecial" then --(FIXED!) OH!! WILL CRASH IF WICKER HAS DESPAWNED BEFORE METEOR SHOWS
						shadow:Remove()
					end
				end)
				
				shadow:DoTaskInTime(35*FRAMES, function(inst)
					shadow:Remove()
				end)
				
			end),
			
			
			
			TimeEvent(20*FRAMES, function(inst) --3-31 CHANGING TO 20
				inst.sg:AddStateTag("can_grab_ledge")
				
				inst.SoundEmitter:PlaySound("dontstarve/common/book_spell")
                -- inst:PerformBufferedAction()
                inst.sg.statemem.book_fx = nil
				
				
				--METEOR
				
				inst.components.hitbox:SetDamage(18) --25
				inst.components.hitbox:SetAngle(300)
				inst.components.hitbox:SetBaseKnockback(50) --30
				inst.components.hitbox:SetGrowth(100) --62
				inst.components.hitbox:SetSize(1.8) --2
				inst.components.hitbox:SetLingerFrames(120)
				

				inst.components.hitbox:SetProjectileAnimation("meteor", "meteor", "idle") --THE ANIMATION I EDITED
				inst.components.hitbox:SetProjectileSpeed(10, -22)
				inst.components.hitbox:SetProjectileDuration(60)
				
				local projectile = SpawnPrefab("basicprojectile")
				projectile:RemoveTag("deleteonhit")
				projectile.Transform:SetScale(1, 1.1, 0.9)
					
				inst.components.hitbox:SetOnHit(function() 
					projectile.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/bodyfall_dirt")
				end)
				
				projectile.components.stats.owner = projectile
				

				
				local function OnCollide(inst, object)
					if object:HasTag("stage") and not inst:HasTag("alreadyimpacted") then
						inst:AddTag("alreadyimpacted")
						inst.AnimState:Resume()
						inst.AnimState:PlayAnimation("egg_crash")
						-- projectile.Transform:SetScale(1.2, 0.9, 0.9) --SIGH- OK, I REALLY HAVE TO MAKE IT SMALLER
						projectile.Transform:SetScale(1.1, 0.65, 0.65) --8-4-17
						TheCamera:Shake("FULL", .3, .03, .3)
						
						inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
						inst.SoundEmitter:PlaySound("dontstarve/common/powderkeg_explo")

						-- inst.components.hitbox:SetProjectileSpeed(0, 0) --12-15-16 OH RIGHT, I MADE A NEW COMPONENT FOR THIS
						projectile.components.projectilestats:SetProjectileSpeed(0, 0)
						inst.components.hitbox:FinishMove()
						inst.components.hitbox:ResetMove()
						--inst:RemoveTag("force_direction") --8-4-17 AH HA!! SO THIS IS WHAT WAS CAUSING THE WEIRD ANGLES
						--I'M PRETTY SURE WE WANT THIS TAG THOUGH
						
						projectile:AddTag("no_reflecting")
						
						--8-4-17 THIS IS JUST A SWEETSPOT NOW, AND MUCH SMALLER--
						-- projectile.components.hitbox:SetBlockDamage(5) --IT DOES NOT NEED TO BE THIS STRONG
						projectile.components.hitbox:SetDamage(12) 
						projectile.components.hitbox:SetAngle(75) --30 --OLD
						projectile.components.hitbox:SetBaseKnockback(60) --50
						projectile.components.hitbox:SetGrowth(70) --70
						-- projectile.components.hitbox:SetSize(4, 0.7) --THE OLD SIZE WAS TOO BIG
						projectile.components.hitbox:SetSize(2.7, 0.7)
						
						projectile.components.hitbox:SetLingerFrames(2) 
						-- projectile.components.hitbox:MakeDisjointed()
						projectile.components.hitbox:MakeGroundOnly()
						projectile.components.hitbox:SpawnHitbox(-0.1, 0.7, 0)
						
						
						
						--8-4-17 NEW SOURSPOT (REPLACING MOST OF THE OLD RANGE) MAKING THE RANGE WAAAY SMALLER. THE OLD RANGE WIL BECOME A SOURSPOT
						-- projectile.components.hitbox:SetSize(4, 0.7) --THE OLD SIZE WAS TOO BIG
						projectile.components.hitbox:SetDamage(7)  
						projectile.components.hitbox:SetAngle(55) --30
						projectile.components.hitbox:SetBaseKnockback(50) 
						projectile.components.hitbox:SetGrowth(70)
						projectile.components.hitbox:SetSize(3.4, 0.7) --3.2
						
						projectile.components.hitbox:SetLingerFrames(2) 
						-- projectile.components.hitbox:MakeDisjointed()
						projectile.components.hitbox:MakeGroundOnly()
						projectile.components.hitbox:SpawnHitbox(-0.1, 0.7, 0)
						
						
						--SUPER SOURSPOT THATS LIKE YOSHI'S LANDING STARS--
						projectile.components.hitbox:SetDamage(4)  
						projectile.components.hitbox:SetAngle(30)
						projectile.components.hitbox:SetBaseKnockback(25)  --8
						projectile.components.hitbox:SetGrowth(0) --65 YEA BUT GOTTA MAKE IT WAY SMALLER BC SMASHUPS DUMB KB 
						projectile.components.hitbox:SetSize(3.85, 0.7) --3.7
						projectile.components.hitbox:SetLingerFrames(2) 
						-- projectile.components.hitbox:MakeDisjointed()
						projectile.components.hitbox:MakeGroundOnly()
						projectile.components.hitbox:SpawnHitbox(-0.1, 0.7, 0)
						
						
						
						projectile:DoTaskInTime(10*FRAMES, function(projectile) --2
							projectile.components.hitbox:FinishMove()
							projectile:Remove()
						
						end)
					end
				end
				
				projectile.Physics:SetCollisionCallback(OnCollide) 
				inst.components.hitbox:SpawnProjectile(2, 12, 0, projectile) 
				projectile.components.stats:TintTeamColor(0.4)
			end),
			
			
			TimeEvent(26*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("punchwoosh", 0.6, 2.05, -0.3,   -1.0, 1.0,   0.5, 4, 0.4,  0, 0, 0,   1) 
				inst.SoundEmitter:PlaySound("dontstarve/common/use_book_close")
				inst.sg:RemoveStateTag("noairmoving")
				inst.sg:RemoveStateTag("reducedairacceleration")
			end),
			
			TimeEvent(45*FRAMES, function(inst) 
				inst.AnimState:PlayAnimation("wicker_book_pst")
			end),
			
            TimeEvent(52*FRAMES, function(inst)  --6-25-17 CHANGING THIS FROM 40 BC ITS WAY TOO LOW
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
        
    },
	
	
	--FSMASH
	State{
        name = "fsmash_start",
        tags = {"busy", "scary"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("wickerfcharge")
            inst.components.hitbox:SetDamage(14)
        end,
		
		timeline=
        {
            TimeEvent(6*FRAMES, function(inst) 
				inst.sg:GoToState("fsmash_charge")
			end),
        },
	},
	
	State{
        name = "fsmash_charge",
        tags = {"attack", "notalking", "f_charge", "busy", "scary"}, 
        
        onenter = function(inst)
			if not inst:HasTag("atk_key_dwn") then
				inst.sg:GoToState("fsmash")
			else
				inst.AnimState:SetMultColour(1,1,1,1)
				inst.components.visualsmanager:Shimmy(0, 0.02, 10)
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
				inst.components.colourtweener:StartTween({1,0,0,1}, 1, nil)
			end),
			
			TimeEvent(31*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
				inst:PushEvent("tester")
				inst.sg:GoToState("fsmash")
			end),
        },
        
        events=
        {
			EventHandler("throwfsmash", function(inst) inst.sg:GoToState("fsmash") end ),
        },
    },
	
	State{
        name = "fsmash",
        tags = {"attack", "busy", "abouttoattack", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("wickerfsmash")
        end,
		
        timeline=
        {
            TimeEvent(2*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(0.4, 0)
			end),
			
			TimeEvent(3*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(0.3, 0)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(92)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetSize(1.1, 0.25)
				inst.components.hitbox:SetLingerFrames(4)
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
				
				inst.components.hitbox:SpawnHitbox(1.8, 0.9, 0) 
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(-0.7, 0)
			end),
			
			
            TimeEvent(22*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {
            -- EventHandler("animover", function(inst)
                -- --inst.sg:GoToState("idle")
            -- end),
        },
    },
	
	
	
	
	
	--DSMASH
	State{
        name = "dsmash_start",
        tags = {"busy", "scary"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("wickerdsmash_charge")
			inst.components.hitbox:SetDamage(13) --NO PLEASE NOT 40
			inst:PushEvent("swaphurtboxes", {preset = "ducking"})
        end,
		
		timeline=
        {
            TimeEvent(2*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/common/use_book_light")
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.sg:GoToState("dsmash_charge")
			end),
        },
		
	},
	
	State{
        name = "dsmash_charge",
        tags = {"attack", "scary", "d_charge", "busy"},
	
        onenter = function(inst)
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.colourtweener:StartTween({1,0,0,1}, 1, nil)
			inst.components.visualsmanager:Shimmy(0, 0.02, 10)
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
			TimeEvent(7*FRAMES, function(inst) 
				inst.sg:AddStateTag("chargingdsmash")
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
			inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hot_explo")
			inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
			inst.AnimState:PlayAnimation("wickerdsmash")
        end,
		
		onexit = function(inst)
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/common/use_book_close")
				-- TheCamera:Shake("FULL", .2, .02, .3)
			
				--BASED ON PALUTENAS
				inst.components.hitbox:SetAngle(60)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(103)
				inst.components.hitbox:SetSize(1.3)
				
				-- inst.components.hitbox:SetLingerFrames(1)
				-- inst.components.hitbox:MakeDisjointed()
				-- inst.components.hitbox:SpawnHitbox(0.4, 1.3, 0)
				
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.75, 0.2, 0) 
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-0.75, 0.2, 0)
				
				-- inst.SoundEmitter:PlaySound("dontstarve/rain/thunder_close")
				inst.components.hitbox:MakeFX("idle", -0.6, 0.0, -0.2,   0.6, 0.6,   1, 20, 0,  0, 0, 0,   0, "marsh_bush", "marsh_bush") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
				inst.components.hitbox:MakeFX("idle", 0.6, 0.0, -0.2,   0.6, 0.6,   1, 20, 0,  0, 0, 0,   0, "marsh_bush", "marsh_bush") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
			end),
			
			
			--TimeEvent(20*FRAMES, function(inst) inst.AnimState:PlayAnimation("pickaxe_pst") end),
            TimeEvent(25*FRAMES, function(inst) 
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
        name = "usmash_start",
        tags = {"busy"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("wickerdsmash_charge")
            inst.components.hitbox:SetDamage(11)  --MAKING MORE LIKE PALUTENA'S, BUT ONLY INCREASING DAMAGE ON THE BOTTOM
        end,
		
		timeline=
        {
            TimeEvent(2*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "ducking"})
				inst.SoundEmitter:PlaySound("dontstarve/common/use_book_light")
			end),
			
			TimeEvent(10*FRAMES, function(inst) 
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
			TimeEvent(8*FRAMES, function(inst) 
				inst.sg:AddStateTag("chargingusmash")
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
			inst.AnimState:PlayAnimation("wickerdsmash")
        end,
        
        timeline=
        {
            TimeEvent(2*FRAMES, function(inst)
				
				TheCamera:Shake("FULL", .2, .03, .2)
				inst.SoundEmitter:PlaySound("dontstarve/common/use_book_close")
				
				--MAYBE AT SOME POINT I'LL MAKE IT A PROJECTILE...
				--LOL WHY IS THIS A TASKINTIME?
				inst:DoTaskInTime(0, function()
					--10-26-17 CHANGED TO SPAWN ONLY ONE LIGHTNING
					inst.SoundEmitter:PlaySound("dontstarve/rain/thunder_close", nil, 1)
					
					--MAKE IT LOUDER
					local camprefab = TheSim:FindFirstEntityWithTag("cameraprefab")
					camprefab.SoundEmitter:PlaySound("dontstarve/rain/thunder_close")
					--OH SNAP! WHAT A FIND. TURNS OUT I WAS RIGHT ABOUT THEFOCALPOINT
					-- TheFocalPoint.SoundEmitter:PlaySound("dontstarve/rain/thunder_close", nil, 1)
					--OH, BUT DISTANCE STILL AFFECTS IT I GUESS...
					
					--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
					inst.components.hitbox:MakeFX("anim", 0, 0, 0.1,   0.5, 1,   1, 10, 1,  0, 0, 0,   0, "lightning", "lightning") 
					inst.components.hitbox:MakeFX("anim", 0, 0, 0.1,   0.5, 1,   1, 10, 1,  0, 0, 0,   0, "lightning", "lightning") 
					-- TheCamera:Shake("FULL", .2, .03, .3)
					
					--THE BOTTOM HITBOX HAS THE INCREASED DAMAGE
					-- inst.components.hitbox:SetDamage(11)
					inst.components.hitbox:SetAngle(70)
					inst.components.hitbox:SetBaseKnockback(55)
					inst.components.hitbox:SetGrowth(85)
					inst.components.hitbox:SetSize(0.8, 3.5)
					inst.components.hitbox:SetLingerFrames(2)
					inst.components.hitbox.property = -6
					
					inst.components.hitbox:SpawnHitbox(0, 1.65, 0) 
					
					
					--AND THEN ANOTHER ONE TO COVER THE HIGHER ONES
					inst.components.hitbox:SetDamage(7)
					inst.components.hitbox:SetAngle(70)
					inst.components.hitbox:SetBaseKnockback(50) --70 -I NEED TO JUST TONE THIS WAAAY DOWN, IT KILLS WAY TOO EARLY
					inst.components.hitbox:SetGrowth(65)
					inst.components.hitbox:SetSize(0.9, 12)
					inst.components.hitbox:SetLingerFrames(2)
					inst.components.hitbox.property = -6
					
					inst.components.hitbox:SpawnHitbox(0, 6, 0) 
					
				end)
					
				
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			
            TimeEvent(25*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack") 
				inst.sg:RemoveStateTag("busy") 
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
				--inst.sg:RemoveStateTag("busy")
            end),
        },
    },
    
}

CommonStates.AddFrozenStates2(states)
CommonStates.AddRespawnPlatform(states)
CommonStates.AddDropSpawn(states)
    
return StateGraph("wilson", states, events, "idle") --, actionhandlers)

