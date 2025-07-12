--require("stategraphs/fighterstates") --SOME ADDITIONAL UNIVERSAL STATES. YOU CAN OVEWRITE THEM BY COPYING THEM INTO YOUR STATEGRAPH AND EDITING THEM, IF WANTED.


--FOR KEY-BUFFERS. DON'T TOUCH THIS
local function TickBuffer(inst)
	inst:PushEvent(inst.components.stats.event, {key = tostring(inst.components.stats.key), key2 = inst.components.stats.key2})
	inst.components.stats.buffertick = inst.components.stats.buffertick - 1
end


local function SoundPath(inst, event)
    local creature = "spider"

    if inst:HasTag("spider_warrior") then
        creature = "spiderwarrior"
    elseif inst:HasTag("spider_hider") or inst:HasTag("spider_spitter") then
        creature = "cavespider"
    else
        creature = "spider"
    end
    return "dontstarve/creatures/" .. creature .. "/" .. event
end


   
local events=
{
	--UPDATEING EVERYTHING - DON'T TOUCH UNLESS YOU KNOW WHAT YOU'RE DOING
	EventHandler("update_stategraph", function(inst)
		if not TheWorld.ismastersim then
			return end
		local wantstoblock = inst:HasTag("wantstoblock")
		local is_tryingtoblock = inst.sg:HasStateTag("tryingtoblock")
		local is_blocking = inst.sg:HasStateTag("blocking")
		local is_parrying = inst.sg:HasStateTag("parrying")
		local atk_key_dwn = inst:HasTag("atk_key_dwn")
		local f_charge = inst.sg:HasStateTag("f_charge")
		local u_charge = inst.sg:HasStateTag("u_charge")
		local d_charge = inst.sg:HasStateTag("d_charge")
		local no_blocking = inst.sg:HasStateTag("no_blocking")
		
		local is_jumping = inst.components.launchgravity:GetIsAirborn()
		
		--[[
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local center_stage = anchor.components.gamerules.center_stage
		local mypos, myposy = inst.Transform:GetWorldPosition()
		local dist = 0
		
		if mypos < 0 then
			dist = mypos - anchor.components.gamerules.lledgepos
		else
			dist = mypos - anchor.components.gamerules.rledgepos
		end
		
		print("MYDIST", dist, myposy)
		]]
		
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
		
		--TELLS CPU WHEN TARGET HAS FINISHED A MOVE AND IS READY FOR A NEW ONE 
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
		local is_ducking = inst.sg:HasStateTag("ducking")
		
		
		if wantstoblock and not is_tryingtoblock and not is_jumping then --1-3-22 ADDED IS_JUMPING SO THEY WONT BLOCK MIDAIR
			inst.sg:GoToState("block_startup")
		end
		
		if is_tryingtoblock and not is_busy and not wantstoblock and not is_jumping then
			if is_parrying then
				inst.sg:GoToState("idle")
			else
				inst.sg:GoToState("block_stop")
			end
		end
		
		if is_ducking and inst.components.keydetector:GetDown(inst) == false then 
			inst.sg:GoToState("idle")
		end
		
	
	end),
	
	EventHandler("clearbuffer", function(inst)
		inst.components.stats.buffertick = 0
	end),
	
	
	EventHandler("jump", function(inst, data) --4-18-20 ADDING DATA TO RECOGNIZE BUFFERED ATTACKS 
		local is_busy = inst.sg:HasStateTag("busy")
		local can_jump = inst.sg:HasStateTag("can_jump")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		
		if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event ~= "jump" then
			return end
			
		if inst.sg:HasStateTag("listen_for_atk") and inst.components.stats.event == "jump" then
			return end

		if data.key and data.key == "ITSNIL" then
			data.key = nil
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
		if (inst.sg.currentstate.name == "highleap" or inst.sg.currentstate.name == "doublejump") and inst.sg.timeinstate == 0 then
			if data.key and data.key ~= nil then 
				inst.components.stats:SetKeyBuffer("throwattack", data.key)
			end
		end
	
	end),
	
	EventHandler("air_transition", function(inst) --TRANSITION FROM GROUND TO AIR (USUALLY VIA STEPPING OFF A CLIFF)
		local is_busy = inst.sg:HasStateTag("busy")
		local no_air_transition = inst.sg:HasStateTag("no_air_transition")
		local used_first_jump = inst.components.jumper.jumping == 1 and inst.components.jumper.doublejumping == 0
		
		if not (inst.sg:HasStateTag("hanging") and not inst.components.launchgravity.islaunched) and not no_air_transition or not is_busy then
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
		local pressing_tostage = inst.components.keydetector:HoldingTowardsStage(inst)
		
		if no_grab_ledge and not autosnap then
			--DO NOTHING
		elseif (can_grab_ledge or (not is_busy and is_falling)) and not (pressing_down or pressing_tostage) and not inst:HasTag("hitfrozen") then 
			inst.components.launchgravity:HitGround()
			inst.components.jumper.jumping = 0
			inst.components.jumper.doublejumping = 0
			inst.sg:GoToState("grab_ledge", data.ledgeref)
		end
	end),
	
	--THESE EVENTS ARE FOR LEFT & RIGHT ARROW KEY PRESSES (OR JOYSTICK)  PROBABLY SHOULDVE MADE THE NAME MORE CLEAR
	EventHandler("left", function(inst)
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
	
	
	EventHandler("roll", function(inst, data)
		local is_busy = inst.sg:HasStateTag("busy")
		local can_oos = inst.sg:HasStateTag("canoos")
		local was_running = inst:HasTag("wasrunning")
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		local must_roll = inst.sg:HasStateTag("must_roll") 
		
		local facedir = inst.components.launchgravity:GetRotationFunction()
		if ((not is_busy or can_oos) and not was_running and not is_airborn) or must_roll then
			if data.key == facedir then
				inst.sg:GoToState("roll_forward")
			elseif data.key == "left" or data.key == "right" then
				--FACING THE WRONG DIRECTION, BUT IS STILL A VALID DIRECTION
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("roll_forward")
			elseif data.key == "none" then --LATE-8-11-17 ALRIGHT, NO MORE OF THIS. BUFFER MUST HAVE A DIRECTION, OR NO ROLLING ALLOWED
				-- ???
			else
				--ITS A TRAP! DONT REACT TO THIS
				inst.components.hitbox:MakeFX("half_circle_backward_woosh", 0.3, 1.0, 0.1,  -1.5, 2.1,   1, 6, 0) --IF YOU SEE THIS, SOMETHING WENT WRONG
			end
		end
	end),
	
	
	EventHandler("tech", function(inst)
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
	
	
	EventHandler("dash", function(inst, data)
		local is_busy = inst.sg:HasStateTag("busy")
		local no_running = inst.sg:HasStateTag("no_running")
		local can_dash = inst.sg:HasStateTag("candash") and not no_running 
		local pressing_forward = inst.components.keydetector:GetForward(inst)
		local foxtrot = inst.sg:HasStateTag("foxtrot")
		
		--1-14-22 CHECK DIRECTION FOR BUFFERED DASHES
		local facedir = inst.components.launchgravity:GetRotationFunction()
		if data.key and data.key ~= facedir then
			pressing_forward = false
		end
		
		if foxtrot and not pressing_forward then
			inst.sg:GoToState("run_stop")
		elseif foxtrot and not no_running then 
			inst.sg:GoToState("dash")
		elseif (not is_busy and not no_running) or can_dash then
			if not pressing_forward then
				inst.components.locomotor:TurnAround()
			end
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
			if can_dashdance then
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("dash_start")
			elseif inst.sg:HasStateTag("dashing") then
				inst.sg:GoToState("pivot_dash")
			end
		elseif not inst.sg:HasStateTag("sliding") and not can_dashdance and not no_running then
			inst.sg:GoToState("dash_stop")
		end
	end),
	
	--BASIC MOVEMENT. I WOULDN'T TOUCH THIS BECAUSE EVEN I DON'T KNOW HOW THIS WORKS
    EventHandler("locomote", function(inst)
		local is_jumping = inst.components.launchgravity:GetIsAirborn()
        local is_attacking = inst.sg:HasStateTag("attack")
        local is_busy = inst.sg:HasStateTag("busy")
        if is_busy then return end
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()
		local can_oos = inst.sg:HasStateTag("canoos")
		local is_prone = inst.sg:HasStateTag("prone")
		local no_running = inst.sg:HasStateTag("no_running")
		local was_running = inst:HasTag("wasrunning")
        
		if is_jumping then
			--inst.components.locomotor:FlyForward() --I DON'T THINK THIS IS EVEN USED
		elseif is_moving and not should_move and not no_running then
            if is_running then
                inst.sg:GoToState("run_stop")
            else
                inst.sg:GoToState("walk_stop")
            end
        elseif (not is_moving and should_move) or (is_moving and should_move and is_running ~= should_run) then
			--I DONT ACTUALLY KNOW IF THIS LOGIC IS USED ANYMORE?...
			if can_oos and not was_running then
				inst.sg:GoToState("roll_forward")
			elseif is_prone then
                inst.sg:GoToState("roll_forward")
            elseif should_run and not is_busy then
                inst.sg:GoToState("run_start")
            else
                inst.sg:GoToState("walk_start")
            end
        end 
    end),
    


    EventHandler("attacked", function(inst, data)
		--WOW WE ACTUALLY STILL USE THIS HUH?
		--inst.SoundEmitter:PlaySound("dontstarve/wilson/hit") --MAYBE ONE DAY I'LL BRING THIS BACK. BUT IT WAS ANNOYING 
		if inst.sg:HasStateTag("hanging") then
			--11-12-17 IF HOLDING LEDGE, TELEPORT THEM DOWN BY THEIR HIEGHT BEFORE CONTINUING AS NORMAL
			inst.components.locomotor:Teleport(-0.5, -inst.components.stats.height, 0)
		end
		inst.sg:GoToState("hit", data.hitstun)
	end),

    
    EventHandler("death", function(inst)
        -- DECLAWED
    end),

       
    EventHandler("wakeup", function(inst) --UNUSED, FOR NOW...
            inst.sg:GoToState("wakeup")
       end), 
       
    
		
		
	--THIS EVENT FIRES WHEN THE ATTACK BUTTON IS PRESSED!  --YOU MIGHT WANT TO EDIT THIS ONE, BUT BE CAREFUL WITH IT.
	--WHEN ATK IS PRESSED, WE ALSO PASS IN THE DIRECTIONAL KEY WE ARE HOLDING AS DATA.KEY
	EventHandler("throwattack", function(inst, data)
		local airial = inst.components.launchgravity:GetIsAirborn()  --FOR ANYONE NOT ON THE GROUND (OR LEDGE)
		local can_attack = inst.sg:HasStateTag("can_attack") --TAG THAT LETS US ATTACK EVEN IF THE BUSY STATE-TAG IS ON
		local can_oos = inst.sg:HasStateTag("canoos")  --OOS = OUT-OF-SHIELD
		local can_ood = inst.sg:HasStateTag("can_ood") --OOD = OUT-OF-DASH
		local is_prone = inst.sg:HasStateTag("prone")  --ON THE FLOOR AFTER BEING ATTACKED
		local listen_for_attack = inst.sg:HasStateTag("listen_for_attack")
		local jab1 = inst.sg:HasStateTag("jab1")
		local jab2 = inst.sg:HasStateTag("jab2")
		local pivoting = inst.sg:HasStateTag("pivoting") --WHEN CHANGING DIRECTIONS WHILE DASHING
		
		--4-23-20 IF THE USER PRESSED JUMP ON THE SAME FRAME, CANCEL THE ATTACK.
		if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event == "jump" then
			return end
			
		--ATTACK EVENTS THAT CAN BE CANCELED OUT OF A BUSY STATE:
		if can_oos then
			inst.sg:GoToState("grab")
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
		elseif inst.sg:HasStateTag("can_usmash") and inst.components.stats.tapjump and (data.key == "up" or data.key == "diagonalf" or data.key == "diagonalb") then
			inst.sg:GoToState("uptilt")
        --NORMAL ATTACK EVENTS
		elseif not inst.sg:HasStateTag("busy") or can_attack then --12-4
			if can_oos or (data.key == "block" and not airial) then
				if data.key2 == "backward" then inst.components.locomotor:TurnAround() end
				inst.sg:GoToState("grab")
			
			--DETECTS IF AIRBORN FOR AIREALS
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
				
			--GROUNDED NORMALS	
			else
				-- inst.components.locomotor:Stop() --WHY WOULD WE STOP?
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
				else --NO OTHER BUTTONS HELD; GO TO JAB
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
				if inst.components.keydetector:GetBackward(inst) and data.key2 ~= "stick" then --1-1-18 BACK AGAIN! INPUTS DIRECTLY FROM THE STICK SHOULD NOT BE CHECKED FOR BACKWARDS, SO DRIFTBACK/FAIR CAN EXIST
					inst.sg:GoToState("bair")
				else	--BUT IF NOT, WE HAVE NO CHOICE BUT TO ASSUME IT WAS MEANT TO BE FORWARD
					inst.sg:GoToState("fair")
				end
			end
		end
	end),
	
	--BASICALLY EXACTLY LIKE THROWATTACK. BUT THIS ONE IS FOR SPECIAL ATTACKS
	EventHandler("throwspecial", function(inst, data)
		local can_special_attack = inst.sg:HasStateTag("can_special_attack")
	
		--10-18-17 NEW CHECKER THAT ALLOWS FOR UPSPEC JUMPCANCELING
		if not inst.sg:HasStateTag("busy") or can_special_attack or (inst.sg:HasStateTag("can_upspec") and (data.key == "up" or data.key == "diagonalf" or data.key == "diagonalb")) then
			-- if inst.components.keydetector:GetUp() then
			if data.key == "up" then
				inst.sg:GoToState("uspecial")
			elseif data.key == "diagonalf" then
				if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
				inst.sg:GoToState("uspecial")
			elseif data.key == "diagonalb" then
				if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end 
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("uspecial")
			elseif data.key == "down" then
				inst.sg:GoToState("dspecial")
			elseif data.key == "forward" then
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
			else
				inst.sg:GoToState("nspecial")
			end
		end
	end),
	
	EventHandler("block_key", function(inst)
		local airial = inst.components.launchgravity:GetIsAirborn(inst)

		if airial and not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("airdodge")
		end
	end),
	
	
	--HAPPENS WHEN TWO GROUNDED ATTACKS OF SIMILAR POWER COLLIDE
	EventHandler("clank", function(inst, data)
		local airial = inst.components.launchgravity:GetIsAirborn()
		inst.components.hitbox:FinishMove()
		if not airial then
			inst.sg:GoToState("rebound", data.rebound)
		end
	end),
	
	--WHEN YOU GET HIT BY AN ATTACK POWERFUL ENOUGH TO LAUNCH YOU FAR
	EventHandler("do_tumble", function(inst, data)
		if inst.sg:HasStateTag("hanging") then
			--IF HOLDING LEDGE, TELEPORT THEM DOWN BY THEIR HIEGHT BEFORE CONTINUING AS NORMAL
			inst.components.locomotor:Teleport(-0.5, -inst.components.stats.height, 0)
			inst.sg:GoToState("tumble", data.hitstun)
		else
			inst.sg:GoToState("tumble", data.hitstun)
		end
	end),
	
	
	--THESE TWO STATES ARE NOT STORED IN THIS STATEGRAPH. THEY ARE STORED IN FIGHTERSTATES IN THE SMASHUP MOD FOLDER.
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
        name = "sleep",
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep")
            inst.components.playercontroller:Enable(false)
            inst.components.health:SetInvincible(true)
        end,

        onexit=function(inst)
            inst.components.health:SetInvincible(false)
            inst.components.playercontroller:Enable(true)
        end,

    },

    
	--IDLE
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
        {   --THIS JUST MEANS THE STATE WILL REPEAT OVER AND OVER AGAIN AFTER THE ANIMATION FINISHES
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),        
        },
    },
	
	--AIR IDLE
	State{
        name = "air_idle",
        tags = {"idle"},
		onenter = function(inst)
			inst.AnimState:PlayAnimation("idle_air")
			-- inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
		end,
    },

    
    
    
    --RUN_START
    State{
        name = "run_start",
        tags = {"moving", "running", "canrotate"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("walk_loop")
			inst.components.locomotor.throttle = 0
			inst.components.locomotor:RunForward()
            inst.sg.mem.foosteps = 0
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,
        
        timeline=
        {
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            
			
			TimeEvent(1*FRAMES, function(inst)
                inst.sg:AddStateTag("ignore_ledge_barriers")
				inst.sg:RemoveStateTag("must_roll")
            end),
			
			TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            
			TimeEvent(6*FRAMES, function(inst) --YOU CAN ADJUST THE NUMBER OF THIS FRAME SO THE SOUND MATCHES YOUR ANIMATION
                PlayFootstep(inst) --PLAYS THE FOOTSTEP SOUND
            end),
			
			TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
			
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
	
	--RUN
    State{
        name = "run",
        tags = {"moving", "running", "canrotate", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
            inst.components.locomotor:RunForward()
			inst.AnimState:PushAnimation("walk_loop")
			-- inst:PushEvent("swaphurtboxes", {preset = "walking"})
        end,
        
        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline=
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
		},
        
        events=
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("run") end ),        
        },
        
        
    },
    
	--RUN_STOP
    State{
        name = "run_stop",
        tags = {"canrotate", "idle", "candash", "can_grab_ledge"},
        
        onenter = function(inst) 
            inst.AnimState:PlayAnimation("walk_pst")
        end,
		
		timeline=
        {
            TimeEvent(4*FRAMES, function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
	
	-- DASH_START
	State{
        name = "dash_start",
        tags = {"moving", "running", "canrotate", "dashing", "can_usmash", "can_special_attack", "can_ood", "busy", "can_dashdance", "foxtrot", "must_roll", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
			inst.components.locomotor.throttle = 0
			inst.components.locomotor:DashForward()
			inst.AnimState:PlayAnimation("walk_loop", true)
			inst.components.hitbox:MakeFX("dahswoosh", 0.5, 1.5, 1, 1, 1, 0.8, 7, 1)
			inst.components.hitbox:MakeFX("slide1", 0.5, 0, 0.1, 0.5, 0.5, 1, 10, 0)
			-- inst:PushEvent("swaphurtboxes", {preset = "dashing"})
        end,
        
        onupdate = function(inst)
			if inst.components.keydetector:GetForward(inst) then
				inst.components.locomotor:DashForward()
			end
			
			if inst.components.keydetector:GetBlock(inst) then
				if inst.sg:HasStateTag("must_roll") then
					inst.sg:GoToState("roll_forward")
					inst.components.hitbox:MakeFX("stars", -1.6, 1.0, 0.1, 1, 0.7, 0.8, 2, 0)
				end
			end
        end,

        timeline=
        {
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
			
			TimeEvent(2*FRAMES, function(inst)
				inst.sg:RemoveStateTag("must_fsmash")
				inst.sg:RemoveStateTag("must_roll")
			end),
			 TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
			
            TimeEvent(7*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.2, 0.2, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst:PushEvent("dash") 
				inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider"))
			end),
        },
        
        events=
        {   
			EventHandler("block_key", function(inst)
				inst.sg:GoToState("roll_forward")
			end ), 
			EventHandler("down", function(inst) 
				inst.sg:GoToState("run") 
			end ),
			EventHandler("cstick_side", function(inst, data)   
				inst.components.locomotor:FaceDirection(data.key) --1-27-22
				inst.sg:GoToState("fsmash_start")
			end), 
        },
    },
	
	--DASH
	State{
        name = "dash",
        tags = {"moving", "running", "canrotate", "can_special_attack", "dashing", "can_usmash", "can_ood", "busy", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
			inst.components.locomotor:DashForward()
			-- inst.AnimState:PlayAnimation("walk_loop")
			-- inst:PushEvent("swaphurtboxes", {preset = "dashing"})
        end,
        
        onupdate = function(inst)
            inst.components.locomotor:DashForward()
        end,

        timeline=
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
        },
        
        events=
        {   
            EventHandler("animover", function(inst) 
				inst.AnimState:PlayAnimation("walk_loop")
				inst.sg:GoToState("dash") 
			end ), --THIS STATE IS ACTUALLY ANIMATION DEPENDANT!! JUST LIKE IN REGULAR SMASH BROS. MAKE A LONG ANIMATION TO HAVE A LONG STARTUP!
			
			EventHandler("block_key", function(inst) --4-7 FOR MANUAL BLOCK OUT OF DASH ACTIVATION
				inst.sg:GoToState("block_startup") 
			end ),
			
			EventHandler("down", function(inst) 
				inst.sg:GoToState("run") 
			end ),
        },
    },
	
	--DASH_STOP
	State{
        
        name = "dash_stop",
        tags = {"canrotate", "dashing", "sliding", "keylistener", "keylistener2"},
        
        onenter = function(inst) 
			inst.AnimState:PlayAnimation("walk_pst")
			inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1, 1, 0.5, 0.8, 10, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
            
        end,

        timeline=
        {
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
	
	--DASH-TURNAROUND
	State{
        
        name = "pivot_dash",
        tags = {"canrotate", "busy", "sliding", "can_special_attack", "can_ood", "pivoting"},
        
        onenter = function(inst) 
			inst.Physics:SetMotorVel(0,0,0)
			inst.components.locomotor:TurnAround()
			-- inst.AnimState:PlayAnimation("dash_pivot_new") --???
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
				if inst.components.keydetector:GetForward(inst) then
					inst:PushEvent("dash")
				end
            end),
            TimeEvent(8*FRAMES, function(inst)
				inst.sg:GoToState("idle")
            end),
        },    
    },

   
    
    --HIT  --THE BASIC FLINCH STATE. APART FROM THE ANIMATION NAME, YOU REALLY SHOULDN'T BE EDITING THIS ONE
    State{
        name = "hit",
        tags = {"busy", "inknockback", "no_air_transition", "nolandingstop", "ignore_ledge_barriers", "noairmoving"},
        
        onenter = function(inst, hitstun)
			inst.AnimState:PlayAnimation("hit")
			inst.components.stats.norecovery = false
			
			local hitstun = hitstun 
			if ISGAMEDST and not TheWorld.ismastersim then
				return --DONT HAVE CLIENTS RUN ANYTHING BELOW THIS LINE. LET THE SERVER HANDLE HITSTUN
			end
			
			local cancel_modifier = hitstun 
			
			inst.task_hitstun = inst:DoTaskInTime((hitstun*FRAMES), function(inst) 
				inst.sg:RemoveStateTag("noairmoving")
				inst.sg:AddStateTag("can_jump")
				inst.sg:AddStateTag("can_attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
				--AI SPECIFIC
				-- inst:AddTag("wantstoblock")
				-- inst.components.aifeelings.escapemode = true 
				-- inst.components.aifeelings:AddFear(0.0)   --7-6 USELESS????
			end)
            inst:ClearBufferedAction()     
        end,
		
		onexit = function(inst)
			if ISGAMEDST and TheWorld.ismastersim then 
				inst.task_hitstun:Cancel()
			end
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline =
        {
            TimeEvent(2*FRAMES, function(inst)   --??
				inst.SoundEmitter:KillAllSounds()  
            end),
        },        
               
    },
	
	
	--TUMBLE --PRETTY MUCH THE SAME AS THE "HIT" STATE, BUT FOR STRINGER ATTACKS
	State{
        name = "tumble", 
        tags = {"busy", "tumbling", "noairmoving", "di_movement_only", "no_air_transition", "ignore_ledge_barriers", "reeling"},
        
        onenter = function(inst, hitstun, direction)
			--SPIDERS ONLY HAVE ONE TUMBLE ANIMATION, SO SKIP ALL THE EXTRA STUFF
			inst.AnimState:PlayAnimation("tumble_spin")

			if ISGAMEDST and not TheWorld.ismastersim then
				return
			end
			
			local dodge_cancel_modifier = hitstun 
			if dodge_cancel_modifier >= hitstun + 30 then
				dodge_cancel_modifier = hitstun + 30
			end
			
			inst.task_hitstun = inst:DoTaskInTime((hitstun*FRAMES), function(inst) 
				inst.sg:AddStateTag("can_jump")
				inst.sg:RemoveStateTag("di_movement_only")
				inst.sg:RemoveStateTag("noairmoving")
				inst.components.jumper:AirStall(2, 1)
				inst.sg:RemoveStateTag("reeling") --10-20-18 TREAT ALL PLAYER GRAVITIES THE SAME WHILE REELING!
				inst.sg:AddStateTag("can_attack")
			end)
			
			inst.task_dodgestun = inst:DoTaskInTime((dodge_cancel_modifier*FRAMES), function(inst)
				inst.sg:RemoveStateTag("busy")
				-- inst.components.aifeelings.readytech = 0.3 --AI SPECIFIC
			end)
        end,

        onexit = function(inst)
			if ISGAMEDST and TheWorld.ismastersim then
				inst.task_hitstun:Cancel()
				inst.task_dodgestun:Cancel()
				inst.AnimState:Resume() 
				-- inst.components.aifeelings.readytech = 0 --AI SPECIFIC
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
    
    
	--LEDGE_GRAB
	State{
        name = "grab_ledge",
		tags = {"busy", "hanging", "resting", "nolandingstop", "no_air_transition"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_grab")
			inst.SoundEmitter:PlaySound("smash_sounds/grab/grab1")
			inst:ForceFacePoint(ledgeref.Transform:GetWorldPosition())
			local x, y, z = ledgeref.Transform:GetWorldPosition()
			inst.Transform:SetPosition( x-(0.25*inst.components.launchgravity:GetRotationValue()), y, z )
			
			inst:PushEvent("swaphurtboxes", {preset = "ledge_hanging"})
			--THIS IS A TINY TEMPORARY HURTBOX WHERE THE HAND MEETS THE LEDGE. MOST CHARACTERS ARE FINE WITH JUST THIS AND THE SINGLE TORSO HURTBOX
			inst.components.hurtboxes:SpawnTempHurtbox(-0.2, -0.1, 0.6, 0, 140)  --(xpos, ypos, size, ysize, frames, property)
			inst.components.hitbox:MakeFX("glint_ring_1", -0.1, -0.1, 0.2,   0.8, 0.8,   0.5, 5, 0.8,  0, 0, 0) 
			inst.components.launchgravity:Launch(0, 0, 0)
			inst.Physics:SetActive(false) --CAREFUL WITH THIS! THIS FREEZES YOU AS A PHYSICS OBJECT
			inst.components.hurtboxes:SpawnPlayerbox(0, -1.3, 0.35, 0.7, 0)
		end,
		
		onexit = function(inst)
			inst.Physics:SetActive(true) 
			inst.components.hurtboxes:SpawnPlayerbox(0, 0.3, 0.35, 0.7, 0)
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
        end,
        
		timeline =
        {
			TimeEvent(1*FRAMES, function(inst) 
				if not inst:HasTag("noledgeinvuln") then
					inst.sg:AddStateTag("intangible")
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
	
	--LEDGE_GETUP
	State{
        name = "ledge_getup",
		tags = {"busy", "intangible", "nolandingstop"},
        
        onenter = function(inst, ledgeref)
			inst.Physics:SetActive(false)
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
		
		-- events=
        -- {
            -- EventHandler("animover", function(inst) inst.AnimState:PlayAnimation("idle") end),
        -- },
    },
	
	--LEDGE_DROP
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
	
	--LEDGE_GETUP_JUMP
	State{
        name = "ledge_jump",
		tags = {"busy", "intangible"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_getup")
			inst.Physics:SetActive(false)
        end,
		
		onexit = function(inst)
			inst.Physics:SetActive(true) 
        end,
        
		timeline =
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("jump")
			end),
			
			TimeEvent(4*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				inst.components.launchgravity:Launch(1, inst.components.stats.jumpheight, 0)
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
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
	
	--LEDGE_GETUP_ROLL
	State{
        name = "ledge_roll",
		tags = {"busy", "intangible", "nolandingstop", "no_air_transition"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_attack")
			inst.Physics:SetActive(false) 
        end,
		
		onexit = function(inst)
			inst.Physics:SetActive(true)
        end,
        
		timeline =
        {
			TimeEvent(4*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("rolling")
			end),
			
			TimeEvent(6*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				-- inst.AnimState:PlayAnimation("rolling")
				inst.components.locomotor:RunForward()
				inst.components.locomotor:Teleport(0.3, 0.1, 0) --TELEPORT TO AVOID BUMPING INTO THE LIP OF THE LEDGE
				inst.components.locomotor:Motor(15, 0, 7)
			end),
			TimeEvent(15*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			TimeEvent(17*FRAMES, function(inst) 
				inst.components.jumper:ScootForward(8)
			end),
			TimeEvent(25*FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
		},
    },
	
	--LEDGE_GETUP_ATTACK
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
				inst.components.hitbox:MakeFX("half_circle_up_woosh", 0.8, 0, 0.1,  3.5, 3.5,   1, 10, 0)
			end),
			
			TimeEvent(10*FRAMES, function(inst)
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetDamage(4)
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0)
				inst.components.hitbox:SpawnHitbox(2.0, 0.5, 0) 
			end),
			
			TimeEvent(12*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
			end),
			
			TimeEvent(27*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
		},
    },
	
	--DUCK
	State{
        name = "duck", --GOOSE
		tags = {"idle", "ducking"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("landing") --I DIDNT GIVE HIM AN ANIMATION FOR THAT
			inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			
        end,
		
		onexit = function(inst)
			inst.AnimState:Resume()
        end,
		
		--SOME ANIM ADJUSTMENTS BECAUSE HAROLD DOESNT HAVE A REAL DUCK ANIMATION
		timeline =
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.AnimState:Pause()
			end),
		},
    },
	
	
	--JUMP  --THIS IS JUST THE JUMP STATE. I DUNNO WHY I GAVE IT A WEIRD NAME
	State{
        name = "highleap",
		tags = {"can_usmash", "can_upspec", "no_running", "no_blocking", "busy"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("jump")
			inst.components.locomotor:Clear()
			inst:AddTag("refresh_softpush")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
        end,
		
		onexit = function(inst)
            inst.components.stats.jumpspec = nil
        end,
        
		timeline =
        {
			TimeEvent(2*FRAMES, function(inst)--THIS TIME EVENT DETERMINES THE "JUMP-SQUAT" FRAMES OF A FIGHTER. THE AVERAGE IS 2. BUT YOU COULD MAKE IT 1 FRAME QUICKER/SLOWER
				inst.sg:RemoveStateTag("busy") 
				inst:AddTag("listenforfullhop")
				inst.components.jumper:Jump(inst)
				inst.sg:RemoveStateTag("prejump")
				inst.sg:RemoveStateTag("can_usmash")

				inst:DoTaskInTime(2*FRAMES, function(inst)
					inst.components.jumper:CheckForFullHop()
				end)
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0.1, 0.2)
			end),
		},

        events=
        {
            EventHandler("animover", function(inst)
				inst.sg:GoToState("air_idle") 
			end ),
        },
    },
	
	--DOUBLEJUMP
	State{
        name = "doublejump",
		tags = {"jumping"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("doublejump")
			inst.components.jumper:DoubleJump(inst)
			inst.components.hitbox:MakeFX("ground_bounce", 0, 1, -1, 1, 1, 0.8, 7, 1)
			-- inst:PushEvent("swaphurtboxes", {preset = "idle"})
			
        end,
        
		timeline =
        {	
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0.1, 0.2)
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
	
	
	
	--CLUMSY_LAND (FROM A TUMBLE WITH NO TECH)
	State{
        name = "land_clumsy",
        tags = {"busy", "grounded", "nogetup"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("clumsy_land")  
			inst.components.hitbox:MakeFX("ground_bounce", -0.5, 0.1, -1, 1.5, 1.5, 0.8, 10, 0)
			inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
			-- inst:PushEvent("swaphurtboxes", {preset = "grounded"})
        end,
        
        timeline =
        {
			TimeEvent(9*FRAMES, function(inst) --9-9 A LITTLE DIFFERENT FROM PLAYER SGS BECAUSE I DONT HAVE TO WORRY ABOUT BOUNCE ANIMATIONS AND HITBOXES
				inst.sg:GoToState("grounded")
			end),
        },
    },
	
	--GROUNDED (PRONE)
	State{
        name = "grounded",
        tags = {"busy", "prone", "grounded", "nogetup"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("clumsy_land")  
			inst.AnimState:SetTime(22*FRAMES)
			-- inst:PushEvent("swaphurtboxes", {preset = "grounded"})
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
					inst.sg:GoToState("tech_forward_roll")
				end
            end),
			
			EventHandler("backward_key", function(inst)
				if not inst.sg:HasStateTag("nogetup") then
					inst.sg:GoToState("tech_backward_roll")
				end
            end),
        },
    },
	
	--GETUP
	State{
        name = "getup",
        tags = {"busy", "grounded"}, 
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("getup")
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
	
	--GETUP_ATTACK
	State{
        name = "getup_attack", --THIS IS AN IMPORTANT STATE. I'D RECCOMEND LEAVING THIS ONE ALONE, APART FROM THE VISUALS
        tags = {"attack", "busy", "intangible", "grounded"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("getup_attack")
			inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow, alpha)
        end,
        
        timeline=
        {
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetDamage(6) --PLAYER'S GETUP DOES MORE THAN AI GETUP. I GUESS? //SHRUG/
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SetSize(1.8, 0.5)
				inst.components.hitbox:SpawnHitbox(0, 0.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			end),
			
            TimeEvent(17*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	--TECH-LAND
	State{
        name = "tech_getup", 
        tags = {"busy", "intangible", "teching"},
        
        onenter = function(inst, target)
			inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow, alpha)
			--I GOT LAZY AND JUST SET THE TECH ANIMATION AS THEIR REGULAR LANDING ANIMATION --BUT FEEL FREE TO CREATE YOUR OWN TECH ANIMATION TO USE INSTEAD
			inst.AnimState:PlayAnimation("landing") 
			inst.components.hitbox:MakeFX("slide1", -0.2, 0, 1, 1.5, 1.5, 1, 10, 0)
			inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        end,
        
        timeline =
        {
			TimeEvent(10*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst.sg:GoToState("idle")
			end),
        },
        
    },
	
	
	--TECH-ROLL
	State{
        name = "tech_forward_roll", 
        tags = {"busy", "intangible", "teching"},
        
        onenter = function(inst, target)
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
				inst.components.jumper:ScootForward(7) --THE NUMBER VALUE HERE DETERMINES THE SPEED AND DISTANCE OF THE ROLL
				--THE STRENGTH AND TIMING OF THESE SCOOTS ARE CUSTOMIZED TO MATCH EACH CHARACTER ANIMATION AND FRICTION VALUES
				--FEEL FREE TO ADJUST THIS STATE AS YOU SEE FIT
			end),
            
			TimeEvent(18*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
		},
		
		events=
        {
			-- EventHandler("on_punished", function(inst)
				-- inst.components.aifeelings.ftechmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.ftechmod, -5)
			-- end),
        },
    },
	
	
	--TECH-BACKWARDS
	State{
        name = "tech_backward_roll", 
        tags = {"busy", "intangible", "teching"},
        
        onenter = function(inst, target)
			inst.components.locomotor:TurnAround()
			inst.components.hitbox:Blink(inst, 2,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			inst.AnimState:PlayAnimation("rolling")
			inst.AnimState:SetTime(2*FRAMES)
			
			inst.sg:AddStateTag("intangible")
			inst.components.locomotor:Motor(12, 0, 7)
			inst.components.hitbox:MakeFX("slide1", -0.8, 0, 1, 1.0, 1.0, 1, 10, 0)
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
				inst.AnimState:SetMultColour(1,1,1,1)
				inst.components.locomotor:TurnAround()
				inst.components.locomotor:Stop()
				inst.components.jumper:ScootForward(-7)
				
			end),
            
			TimeEvent(18*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
		},
    },
	
	
	--LANDING LAG --THIS IS THE LANDING LAG STATE. THIS IS A REALLY WEIRD NAME FOR IT, I KNOW
	State{
        name = "ll_medium_getup",
        tags = {"busy", "can_grab_ledge"}, 
        
        onenter = function(inst, llframes) --HERE WE PASS IN THE NUMBER OF FRAMES WE WANT THIS STATE TO LAST FOR
			inst.AnimState:PlayAnimation("landing")
			-- inst:PushEvent("swaphurtboxes", {preset = "landing"})
			
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
	
	
	--METEOR --WHEN YOU SLAM THE GROUND SO HARD YOU HAVE TO DO AN EXTENDED, UNTECHABLE GETUP ANIMATION
	State{
        name = "meteor",
        tags = {"busy", "grounded"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("clumsy_land")
			inst.components.hitbox:MakeFX("ground_bounce", -0.5, 0.1, -1, 2.5, 2.5, 0.8, 10, 0)
			inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
			-- inst:PushEvent("swaphurtboxes", {preset = "grounded"})
        end,
        
		timeline =
        {
			TimeEvent(30*FRAMES, function(inst) 
				inst.sg:GoToState("getup")  
			end),
		},
    },

	--BLOCK_STARTUP
	State{	--THE BLOCK STATES ARE CRUCIAL AND SHOULD NOT BE ALTERED!! (EXCEPT FOR THE ANIMATION NAME, IF YOU WANT)
        name = "block_startup", 
        tags = {"busy", "tryingtoblock", "blocking", "can_parry", "canoos"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("cower")
        end,
        
        timeline =
        {
            TimeEvent(3*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("block")
			end),
        },
    },
	
	--BLOCK
	State{
        name = "block",
        tags = {"canrotate", "blocking", "tryingtoblock", "canoos", "no_running"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("cower_loop")
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
	
	
	--PARRY --AKA; POWER SHIELD
	State{
        name = "parry",
        tags = {"canrotate", "blocking", "tryingtoblock", "parrying", "busy"},
        
        onenter = function(inst, timeout)
			inst.components.hitbox:MakeFX("shockwave_parry", 0.5, 1.5, 1, 1, 1.8, 1, 12, 1)
			inst.AnimState:PlayAnimation("cower_loop")
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
	
	--BLOCKSTUN
	State{
        name = "block_stunned",
        tags = {"blocking", "tryingtoblock", "busy", "block_stunned"},
        
        onenter = function(inst, timeout)
			inst.AnimState:PlayAnimation("cower_loop")
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
	
	--BLOCK_UNSTUN
	State{
        name = "block_unstunned",
        tags = {"blocking", "tryingtoblock", "busy"},
        
        onenter = function(inst, target)
			-- inst.AnimState:PlayAnimation("blockstunned_resume")
			
			if inst:HasTag("wantstoblock") then
				inst.sg:GoToState("block")
			else
				inst.sg:GoToState("block_stop")
			end
        end,
    },
	
	-- BLOCK_STOP
	State{
        name = "block_stop",
        tags = {"tryingtoblock", "busy"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("cower_pst")
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
	
	
	--SHIELDBREAK
	State{
        name = "brokegaurd",  
        tags = {"busy", "intangible", "dizzy", "ignoreglow", "noairmoving"},
		
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("death")
			inst.SoundEmitter:PlaySound("dontstarve/common/destroy_magic")
			inst.AnimState:SetAddColour(1,1,0,0.6)
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
				inst.sg:RemoveStateTag("intangible")
			end),
			
            TimeEvent(150*FRAMES, function(inst)
				inst.AnimState:SetAddColour(1,0.5,0,0.6)
				inst.sg:RemoveStateTag("busy")
			end),
        },
    },
	
	
	--DIZZY --THE DIZZY STATE AFTER A SHIELD-BREAK SHOULD ALWAYS LAST 150 FRAMES
	State{
        name = "dizzy",  
        tags = {"dizzy", "busy"},  
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("death")
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
				-- inst.AnimState:PlayAnimation("dizzy") 
				inst.components.hitbox:MakeFX("stars", 0, 2.5, 1, 1, 1, 1, 65, 0.2)  --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			end),
        },
    },
	
	--SPOTDODGE
	State{
        name = "spotdodge",
        tags = {"intangible", "dodging", "busy"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("spotdodge")
			local x, y, z = inst.Transform:GetWorldPosition()
			print("MYPOS", x, y, math.floor(z*100))
        end,
        
        timeline =
        {
            TimeEvent(1*FRAMES, function(inst) 
				inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow)
				inst.sg:AddStateTag("intangible")
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
			end),
			
            TimeEvent(14*FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	--ROLL_FORWARD
	State{
        name = "roll_forward", 
        tags = {"dodging", "busy", "nopredict"},  
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("evade") --eat
			inst.components.locomotor:TurnAround()
			inst.task_1 = inst:DoPeriodicTask(0.1, function(inst)
				inst.Physics:SetMotorVel(-14, 0, 0)
			end)
			
			inst.components.hitbox:Blink(inst, 4,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
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
				inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
				inst.sg:AddStateTag("intangible")
		    end),
		    
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0, -0.2,   1.0, 1.0,   0.6, 8, 0)
		    end),
		   
			TimeEvent(4*FRAMES, function(inst)
				inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
		    end),
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.task_1:Cancel()
			end),
            
			TimeEvent(8*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst.components.hitbox:MakeFX("slide1", 1.5, 0, -0.2,   -0.8, 0.8,   0.6, 8, 0)
				inst.AnimState:SetMultColour(1,1,1,1)
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.locomotor:Stop()
				inst.components.jumper:ScootForward(-10)
			end),
			
			
            TimeEvent(14*FRAMES,
				function(inst)
				--CHECK FOR IF STILL HOLDING SHEILD  --TODOLIST
					inst:PushEvent("finishrolling") --8-14
                    inst.sg:RemoveStateTag("busy")
					inst.sg:GoToState("idle")
				end),
        },
        
    },
	
	--AIRDODGE
	State{
        name = "airdodge",
        tags = {"dodging", "busy", "airdodging", "ll_medium"}, 
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("spotdodge")
			inst.components.launchgravity:SetLandingLag(10)
        end,

        timeline =
        {		
		   TimeEvent(1*FRAMES, function(inst) 
				inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow)
				inst.sg:AddStateTag("intangible")
			end),
            
			TimeEvent(15*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
			end),
			
            TimeEvent(20*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("air_idle")
			end),
        },
        
    },
	
	--GRAB
	State{
        name = "grab",
        tags = {"busy", "grabbing", "short"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("grab")
        end,
        
        timeline =
        {
			TimeEvent(4*FRAMES, function(inst) 
				--SPIDERS GOT WEIRDLY LOW GRABS
				inst.components.hitbox:SetSize(0.6) 
				inst.components.hitbox:SpawnGrabbox(0.66, 0.6, 0)  
				
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:SpawnGrabbox(0.8, 1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			end),

            TimeEvent(15*FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	--GRABBING --WHEN THEY HAVE AN OPPONENT HELD
	State{
        name = "grabbing",
        tags = {"busy", "grabbing", "handling_opponent"},
        
        onenter = function(inst, target)
			inst.components.locomotor:Stop()
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
            TimeEvent(5*FRAMES, function(inst)
				inst.components.stats.opponent.components.locomotor:FaceTarget(inst) --FACE US AGAIN IN CASE THINGS GOT WEIRD WITH THE GRAB RANGE
			end),
			
			TimeEvent(60*FRAMES, function(inst) --IF THEY WAIT TO LONG TO THROW, IT WILL AUTOMATICALLY FORWARD-THROW
				inst.sg:GoToState("fthrow")
			end),
        },
		 events=
        {
            --I WAS LAZY AND GAVE MOST CHARACTERS ONLY TWO DIFFERENT THROWS. YOU ARE FREE TO ADD MORE THROWS YOURSELF. ITS AS EASY AS COPY/PASTING AN EXISTING THROW AND RENAMING IT
			EventHandler("forward_key", function(inst) 
				inst.sg:GoToState("fthrow")
			end),
			EventHandler("down", function(inst) --SO A DOWN-THROW INPUT JUST DOES A FORWARD-THROW, BECAUSE I DIDNT MAKE A DOWN-THROW
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
	
	
	--GRABBED --IN THE GRABBED STATE, YOU ARE RESTRAINED AND CANNOT MOVE OR ACT UNTIL YOU ARE HIT WITH AN ATTACK
	State{
        name = "grabbed",
        tags = {"busy", "nolandingstop"},
        
        onenter = function(inst, anim) --OPTIONAL CUSTOM ANIMATION NAME TO PASS IN
			inst.AnimState:PlayAnimation("grabbed", true)
			-- if anim then --WE REALLY SHOULDN'T. I DONT REALLY MAKE CUSTOM ANIMS FOR SPIDERS
				-- inst.AnimState:PlayAnimation(anim)
			-- end
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
    },
	
	
	--RAGDOLL IS A CUSTOM STATE USED FOR WEIRD SPECIAL ATTACKS THAT GRAB OR RESTRAIN ENEMIES IN AN UNUSUAL MANNER. SIMMILAR TO THE "GRABBED" STATE, BUT NO LIMITATIONS
	--ATTACKS THAT PUT ENEMIES IN THE RAGDOLL STATE ENSURE THEY REMAIN IN THAT STATE UNTIL THEY TAKE DAMAGE, OR FORCEABLY SWITCHED TO DIFFERENT STATES VIA CODE
	State{
        name = "ragdoll",  
        tags = {"busy", "no_air_transition", "nolandingstop"},
        
        onenter = function(inst, anim)
			if anim then
				inst.AnimState:PlayAnimation(anim)
				--10-13-20 SPIDERS DONT HAVE THIS ANIMATION AND IM TOO LAZY TO RE-COMPILE THEIR ANIMS
				if anim == "restrained" then
					inst.AnimState:PlayAnimation("grabbed")
				end
			end
        end,
		
		--IF YOU HAVE AN ATTACK THAT FORCES AN OPPONENT INTO THE RAGDOLL STATE, MAKE SURE THERE ARE NO SITUATIONS IN WHICH THEY WOULD REMAIN TRAPPED IN IT
    },
	
	
	--THROWS ARE KINDA WEIRD. SINCE YOU CANT JUST ANIMATE AN ENEMIES THROWN ANIMATION, YOU USUALLY HAVE TO GET CREATIVE AND USE PHYSICS SHOVING TO MOVE THEM AROUND FOR THE ANIMATIONS
	--VERY MUCH LIKE EARLY SPRITE-BASED STREER FIGHTER THROWS
	--FTHROW
	State{
        name = "fthrow",
        tags = {"attack", "busy", "handling_opponent"},
        
        onenter = function(inst, target)
			inst.components.stats:GetOpponent()
			inst.AnimState:PlayAnimation("dash_attack")
			inst.AnimState:Resume()
        end,
        
        timeline =
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.components.stats.opponent.sg:GoToState("thrown")
			end),

			TimeEvent(5*FRAMES, function(inst)   
				inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetAngle(73) 
				inst.components.hitbox:SetBaseKnockback(55) 
				inst.components.hitbox:SetGrowth(40)
				inst.components.hitbox:SetSize(1.5)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(1.5, 0, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
				-- inst:AddTag("autofollowup") --7-9-17
			end),
			
			TimeEvent(12*FRAMES, function(inst)
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
	
	
	
	--BTHROW
	State{
        name = "bthrow",
        tags = {"attack", "busy", "handling_opponent"},
        
        onenter = function(inst, target)
			inst.components.stats:GetOpponent()
			inst.AnimState:PlayAnimation("dash_attack")
			inst.AnimState:Resume()
			
			inst.components.locomotor:TurnAround()
			inst.components.stats.opponent.components.locomotor:TurnAround()
			inst.components.jumper:ScootForward(-6)
			inst:AddTag("refresh_softpush") --3-2-17 HOPEFULLY FIXES THE WEIRD LEDGETHROWING THING --IT DID
        end,
        
        timeline =
        {
			--JUST A TURNAROUND FTHROW LOL
			TimeEvent(0*FRAMES, function(inst)
				inst.components.stats.opponent.components.locomotor:Teleport(-1.3, 0, 0)
				inst.components.stats.opponent.sg:GoToState("thrown")
			end),

			TimeEvent(5*FRAMES, function(inst)   
				inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetAngle(73) 
				inst.components.hitbox:SetBaseKnockback(55) 
				inst.components.hitbox:SetGrowth(40)
				inst.components.hitbox:SetSize(1.5)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(1.5, 0, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
				-- inst:AddTag("autofollowup") --7-9-17
			end),
			
			TimeEvent(12*FRAMES, function(inst)
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
        tags = {"busy", "no_air_transition", "nolandingstop", "can_grab_ledge"},
        
        timeline =
        {
			TimeEvent(30*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy") --JUST AN EMERGENCY BACKUP
			end),
        },
    },
	
	
	--FREEFALL
	State{ --MOST FIGHTERS GO INTO FREEFALL AFTER USING A RECOVERY MOVE. IN FREEFALL, YOU CANT ACT UNTIL YOU HIT THE GROUND (OR LEDGE) OR GET HIT
        name = "freefall",  
        tags = {"busy", "helpless", "ll_medium", "can_grab_ledge"},
        
        onenter = function(inst, target)
			if not inst.components.launchgravity:GetIsAirborn() then
				inst.sg:GoToState("idle")
			else
				inst.AnimState:PlayAnimation("death")
				inst.AnimState:SetMultColour(0.5,0.5,0.5,1)
				inst.components.launchgravity:SetLandingLag(10)
			end
        end,
		
		onexit = function(inst, target)
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
    },
	
	--HAPPENS WHEN TWO ATTACKS CLANK. I WOULDNT MESS WITH THIS STATE 
	State{
        name = "rebound",  
        tags = {"busy"},
        
        onenter = function(inst, rebound)
			inst.AnimState:PlayAnimation("hit")
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
			TimeEvent(60*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy") --TWO SECOND FAILSAFE
			end),
        },
    },
	
	--FAIR
	State{
        name = "fair",
        tags = {"attack", "force_direction", "busy", "ll_medium"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("fair")
			inst.components.launchgravity:SetLandingLag(8)
			inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt"))
		end,
        
        timeline=
        {
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("half_circle_forward_woosh", 0.5, 0.7, 0.2,   2.0, 1.2,   0.8, 6, 0.5,    0, 0, 0,   1) 
				--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(9)
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(95) --98
				inst.components.hitbox:SetGrowth(45) --35
				inst.components.hitbox:SetSize(0.50)
				inst.components.hitbox:SetLingerFrames(2) --2
				
				inst.components.hitbox:SpawnHitbox(0.35, 0.8, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(0.8)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0.65, 0.3, 0) 
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				--10-20-20 THIS IS NOW A SOURSPOT
				inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(0.6, -0.2, 0) ---0.5
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
            TimeEvent(20*FRAMES, function(inst)
				-- inst.sg:RemoveStateTag("attack") 
				-- inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("air_idle")
			end),
        },
    },
	
	--BAIR
	State{
        name = "bair",
        tags = {"attack", "busy", "ll_medium"}, 
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("bair") 
			inst.components.launchgravity:SetLandingLag(8, "ll_bair") --SPECIFYING A CUSTOM ANIMATION FOR THIS ONE!
			inst.components.hitbox:MakeFX("woosh1", 0.0, 0.4, -0.2,   -1.6, 3,   0.7, 4, 0.4,   0, 0, 0, 1)
		end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(14)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(98)
				inst.components.hitbox:SetGrowth(45)
				inst.components.hitbox:SetSize(0.6, 0.5)
				inst.components.hitbox:SetLingerFrames(3) 
				
				inst.components.hitbox:SpawnHitbox(-0.8, 0.1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
			end),
			
			TimeEvent(11*FRAMES, function(inst)
				inst.components.launchgravity:SetLandingLag(8) --SAME BUT WITH REGULAR LANDING ANIMATION
			end),
			
            TimeEvent(24*FRAMES, function(inst)
				-- inst.sg:RemoveStateTag("attack") 
				-- inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("air_idle")
			end),
        },
    },
	
	--DAIR
	State{
        name = "dair",
        tags = {"attack", "notalking", "busy", "ll_medium"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("dair")
			inst.components.launchgravity:SetLandingLag(12)
		end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				inst.components.hitbox:MakeFX("woosh1down", 0.35, 0.75, 0.2,   2.0, 1.4,   0.0, 5, 1,   0.2,0.2,0.2, 1)
				inst.components.hitbox:MakeFX("woosh1down", -0.35, 0.75, 0.2,   2.0, 1.4,   0.0, 5, 1,   1,1,1, 1)
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(14)
				inst.components.hitbox:SetAngle(270)
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(78)
				inst.components.hitbox:SetSize(0.8, 0.4)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(0.0, -0.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
			end),
			
			--NEW LATE HIT OF DAIR (SINGLE TURNIP DAIR)
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(4)
				
				inst.components.hitbox:SpawnHitbox(0.0, -0.1, 0) 
			end),
			
			
            TimeEvent(21*FRAMES, function(inst)  
				-- inst.sg:RemoveStateTag("attack") 
				-- inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("air_idle")
			end),
        },
    },
	
	--NAIR
	State{
        name = "nair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("spin_pre")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.components.launchgravity:SetLandingLag(5)
			inst.AnimState:PlayAnimation("nair_pre")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt"))
        end,
        
        timeline=
        {
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("spinwoosh",   0.0,  0.3, -0.2,  0.8, 0.6,   0.8, 8, 0,   -0.8, -0.8, -0.8,  2) 
				inst.components.hitbox:MakeFX("spinwoosh2", -0.1, 0.25, 0.2,   0.75, 0.4,   0.8, 8, 0,  -0.8, -0.8, -0.8,  2)
				-- inst.components.hitbox:MakeFX("square", 0.9, 0.6, -0.3,   0.6, 2,   0.6, 4, 0,   -0.0, -0.6, -0.6) 
			
				inst.components.hitbox:SetDamage(9)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(1.2, 0.4) 
				
				inst.components.hitbox:SetLingerFrames(8)
				inst.components.hitbox:SpawnHitbox(0, 0.2, 0)
				
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetLingerFrames(8)
				
				inst.components.hitbox:SpawnHitbox(0, 0.2, 0)
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("spinwoosh",   0.0,  0.3, -0.2,  0.8, 0.6,   0.8, 8, 0,   -0.8, -0.8, -0.8,  2) 
				inst.components.hitbox:MakeFX("spinwoosh2", -0.1, 0.25, 0.2,   0.75, 0.4,   0.8, 8, 0,  -0.8, -0.8, -0.8,  2)
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("spinwoosh",   0.0,  0.3, -0.2,  0.8, 0.6,   0.8, 8, 0,   -0.8, -0.8, -0.8,  2) 
				inst.components.hitbox:MakeFX("spinwoosh2", -0.1, 0.25, 0.2,   0.75, 0.4,   0.8, 8, 0,  -0.8, -0.8, -0.8,  2)
			end),
			
            TimeEvent(18*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("attack") 
				-- inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("air_idle")
			end),
        },
		
		events=
        {
			EventHandler("animover", function(inst) inst.AnimState:PlayAnimation("spintest_000") end),
        },
    },
	
	--UAIR
	State{
        name = "uair",
        tags = {"attack", "notalking", "busy", "ll_medium"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("uair")
			inst.components.launchgravity:SetLandingLag(5)
		end,
        
        timeline=
        {
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(55) 
				inst.components.hitbox:SetBaseKnockback(98)
				inst.components.hitbox:SetGrowth(35)
				inst.components.hitbox:SetSize(0.75)
				inst.components.hitbox:SetLingerFrames(3) --2
				
				inst.components.hitbox:SpawnHitbox(0.0, 1.0, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
			end),
			
            TimeEvent(16*FRAMES, function(inst)
				-- inst.sg:RemoveStateTag("attack") 
				-- inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("air_idle")
			end),
        },
    },
	
	--JAB1
	State{
        name = "jab1",
        tags = {"attack", "short", "busy"}, 
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jab_1_old")
		end,
        
        timeline=
        {
			
			TimeEvent(2*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(10)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetDamage(2.5) 
				inst.components.hitbox:SetSize(0.7, 0.5)
				inst.components.hitbox:SetLingerFrames(0)
				
				inst.components.hitbox:AddSuction(0.7, 0.4, 0)
				inst.components.hitbox:SpawnHitbox(0.85, 0.4, 0)  
			end),
			
			TimeEvent(5*FRAMES, function(inst)
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
        tags = {"attack", "busy", "short"}, 
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jab_2")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst)	
				inst.components.hurtboxes:ShiftHurtboxes(0.5, 0) 
				
				inst.components.hitbox:SetDamage(1.5)
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(13)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetSize(0.75)
				
				inst.components.hitbox:AddSuction(0.5, 0.5, 0)
				inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0) 
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.sg:AddStateTag("jab2")
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.sg:AddStateTag("jab2")
			end),
			
			-- TimeEvent(7*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("attack")
				-- inst.sg:RemoveStateTag("busy")				
				-- inst.sg:GoToState("jab3")
			-- end),
			
            TimeEvent(16*FRAMES, function(inst) 
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
					inst.sg:GoToState("jab3")
				end
            end),
        },
    },
	
	
	
	State{
        name = "jab3",
        tags = {"attack", "jab3", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dash_attack")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt"))

            -- inst:PushEvent("swaphurtboxes", {preset = "leanf"})
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 				
				inst.components.jumper:ScootForward(7)
			end),
			
			
			TimeEvent(3*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(4)   --7
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetSize(0.75)
				inst.components.hitbox:SetLingerFrames(5)
				
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.9, 0.6, 0)  
			end),
			
			
            TimeEvent(40*FRAMES, function(inst) 
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
	
	
	--DASH ATTACK
	State{
        name = "dash_attack",
        tags = {"busy", "force_direction"},
        
        onenter = function(inst)
			-- inst.sg:GoToState("usmash")
			inst.AnimState:PlayAnimation("dash_attack") --taunt
			inst.Physics:SetFriction(.5)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/explo")
			-- inst:PushEvent("swaphurtboxes", {preset = "sliding"})
        end,
		
		onexit = function(inst)
			inst.components.stats:ResetFriction()
        end,
        
        timeline=
        {
			TimeEvent(5*FRAMES, function(inst)
				inst.components.jumper:ScootForward(8)
				
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(65) --80
				inst.components.hitbox:SetBaseKnockback(75) --100
				inst.components.hitbox:SetGrowth(80) --43
				inst.components.hitbox:SetSize(0.65)--(0.75, 0.3)  
				
				inst.components.hitbox:SetLingerFrames(2)

				inst.components.hitbox:SpawnHitbox(0.6, 0.8, 0) 
				
				-- inst.components.hitbox:MakeFX("slide1", 1, 0, 1, 1.5, 1.5, 1, 20, 0)
			end),
			
			TimeEvent(7*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(65)
				inst.components.hitbox:SetGrowth(85)
				inst.components.hitbox:SetSize(0.55)
				
				inst.components.hitbox:SetLingerFrames(3)

				inst.components.hitbox:SpawnHitbox(0.6, 0.8, 0) 
			end),
			
            TimeEvent(23*FRAMES, function(inst) 
				-- inst.components.jumper:ScootForward(8)
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
			
			end),
        },
        
        -- events=
        -- {
           -- EventHandler("on_punished", function(inst)
				-- inst.components.aifeelings.dashattackmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.dashattackmod, -5)
			-- end),
			
			-- EventHandler("on_hit", function(inst)
				-- inst.components.aifeelings.dashattackmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.dashattackmod, 5)
			-- end),
        -- },
    },
	
	
	
	--FTILT
	State{
        name = "ftilt", --THIS IS TECHNICALLY "DTILT" FOR THE AI SPIDERS. BUT THAT MOVE SUCKS SO DONT GIVE IT TO PLAYERS
        tags = {"busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("ftilt") 
        end,

        timeline=
        {
			TimeEvent(1*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("woosh1", 0, 0.6, -0.2,   1.7, 2,   0.7, 5, 0.4,   0, 0, 0, 1)
			end),
			
			TimeEvent(3*FRAMES, function(inst) --7
				inst.components.hitbox:SetDamage(6)   --7
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetSize(0.75, 0.45)
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(1.3, 0.3, 0)  
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
				
			end),
			
            TimeEvent(19*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
        },
    },
	
	--DTILT
	State{
        name = "dtilt",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("ftilt") 
        end,

        timeline=
        {
			TimeEvent(1*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("woosh1", 0, 0.6, -0.2,   1.7, 2,   0.7, 5, 0.4,   0, 0, 0, 1)
			end),
			
			TimeEvent(3*FRAMES, function(inst) --7
				inst.components.hitbox:SetDamage(6)   --7
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetSize(0.75, 0.45)
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(1.3, 0.3, 0)  
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
				
			end),
			
            TimeEvent(19*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
        },
    },
	
	--UTILT
	State{
        name = "utilt",
        tags = {"attack", "notalking", "abouttoattack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jab_2")
        end,

        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(110)
				inst.components.hitbox:SetBaseKnockback(18)
				inst.components.hitbox:SetGrowth(110)
				inst.components.hitbox:SetSize(0.65, 0.25)
				inst.components.hitbox:SetLingerFrames(1)
				
				inst.components.hitbox:SpawnHitbox(0.8, 0.2, 0)  
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
			end),
			
			
			TimeEvent(3*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(90)
				inst.components.hitbox:SetBaseKnockback(16)
				inst.components.hitbox:SetGrowth(110)
				inst.components.hitbox:SetSize(0.65)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0.4, 1.3, 0) 
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(5)   
				inst.components.hitbox:SetAngle(110) 
				inst.components.hitbox:SetBaseKnockback(16)
				inst.components.hitbox:SetGrowth(110)
				inst.components.hitbox:SetSize(0.55)
				inst.components.hitbox:SpawnHitbox(-0.3, 1.2, 0) 
			end),
			
			--11-14-22 PLAYER SPECIFIC JUMP CANCEL. YOUR WELCOME
			TimeEvent(10*FRAMES, function(inst) 
				inst.sg:AddStateTag("can_ju")
			end),
			
            TimeEvent(13*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
        },
    },
	
	
	
	
	--USPECIAL
	State{
        name = "uspecial",
        tags = {"attack", "busy", "reducedairacceleration", "autosnap", "can_grab_ledge", "no_fastfalling"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("fsmash_charge")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt"))
        end,
		
		onexit = function(inst)
			--DONT FORGET TO PUT THEM BACK TO DEFAULT
			inst.components.hurtboxes:ReplaceLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0) --(xpos, ypos, sizex, sizey, shape)
		end,
        
        timeline=
        {
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.jumper:AirStall()
				inst.components.launchgravity:AirOnlyLaunch(0,3,0)
				inst.components.locomotor:SlowFall(0.5, 13)
			end),
			
			TimeEvent(4*FRAMES, function(inst) inst.AnimState:SetAddColour(0.4,0.4,0,0.4) inst.components.hitbox:MakeFX("ground_bounce", 0, 1, 1, 1, 1.0, 1, 8, 1) end),
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.AnimState:SetAddColour(0,0,0,0) 
				inst.components.hitbox:MakeFX("ground_bounce", 0, 1, 1, 1, 1, 1, 8, 1)
				inst.AnimState:PlayAnimation("uspec1")
				inst.SoundEmitter:PlaySound(SoundPath(inst, "Jump"))
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.launchgravity:Launch(0, 28)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				inst.components.hitbox:MakeFX("ground_bounce", 0, 1, 1, 1.5, 1.5, 1, 8, 1)
			end),
			
			TimeEvent(10*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("ground_bounce", 0, 1, 1, 0.5, 0.5, 1, 8, 0.5)
			end),
			
			TimeEvent(13*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("ground_bounce", 0, 1, 1, 0.5, 0.5, 1, 8, 0.5)
			end),
			
			TimeEvent(16*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("ground_bounce", 0, 1, 1, 0.5, 0.5, 1, 8, 0.5)
				
			end),
			
			TimeEvent(17*FRAMES, function(inst) 
				inst.components.launchgravity:AirOnlyLaunch(0,10,0)
				inst.sg:RemoveStateTag("can_grab_ledge")
			end),
			
			TimeEvent(19*FRAMES, function(inst) 
				inst.AnimState:PlayAnimation("nair")
			end),
			
			TimeEvent(21*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(1)
				inst.components.hitbox:SetAngle(366) --THEEEEERE WE GO
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(1.35, 0.4)
				
				inst.components.hitbox:AddSuction(0.15, 0, -0.5)
				inst.components.hitbox:SpawnHitbox(0, 0.2, 0) --2.5
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				--2-11-18 LETS BUFF THIS POOR LIL GUYS USPEC YET AGAIN. BIGGER GRABBOX -DST CHANGE  BUT NOT EXCLUSEIVELY
				inst.components.hurtboxes:ReplaceLedgeGrabBox(0.4, 1.7, 2.0, 0.8, 0) --(xpos, ypos, sizex, sizey, shape)
				inst.components.locomotor:SlowFall(0.2, 12)
			end),
			
			TimeEvent(22*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0, 0.2, 0) 
			end),
			
			TimeEvent(23*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0, 0.2, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				inst.components.hitbox:MakeFX("spinwoosh",   0.0,  0.3, -0.2,  0.8, 0.6,   0.8, 8, 0,   -0.8, -0.8, -0.8,  0) 
				inst.components.hitbox:MakeFX("spinwoosh2", -0.1, 0.25, 0.2,   0.75, 0.4,   0.8, 8, 0,  -0.8, -0.8, -0.8,  0)
			end),
			
			TimeEvent(24*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0, 0.2, 0) 
			end),
			
			TimeEvent(25*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0, 0.2, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				inst.components.hitbox:MakeFX("spinwoosh",   0.0,  0.3, -0.2,  0.8, 0.6,   0.8, 8, 0,   -0.8, -0.8, -0.8,  0) 
				inst.components.hitbox:MakeFX("spinwoosh2", -0.1, 0.25, 0.2,   0.75, 0.4,   0.8, 8, 0,  -0.8, -0.8, -0.8,  0)
			end),
			
			TimeEvent(26*FRAMES, function(inst)
				inst.components.hitbox:AddNewHit()
				
				inst.components.hitbox:SetKnockback(2, 5)
				inst.components.hitbox:SetDamage(9)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(1.5, 0.4) --1.5
				
				inst.components.hitbox:SetLingerFrames(6)
				
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetBaseKnockback(15)
				inst.components.hitbox:SpawnHitbox(0, 0.2, 0)
				
				inst.components.hitbox:MakeFX("spinwoosh",   0.0,  0.3, -0.2,  0.8, 0.6,   0.8, 8, 0,   -0.8, -0.8, -0.8,  0) 
				inst.components.hitbox:MakeFX("spinwoosh2", -0.1, 0.25, 0.2,   0.75, 0.4,   0.8, 8, 0,  -0.8, -0.8, -0.8,  0)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				inst.sg:RemoveStateTag("autosnap")
				inst.sg:AddStateTag("can_grab_ledge")
			end),
			
            TimeEvent(40*FRAMES, function(inst) 
				inst.sg:GoToState("freefall")
			end),
		},
		
		events=
        {
            EventHandler("animover", function(inst) 
				inst.AnimState:PlayAnimation("nair") 
			end),
        },
    },
	
	
	--NSPECIAL
	State{
        name = "nspecial",
        tags = {"attack", "notalking", "abouttoattack", "busy", "nolandingstop"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("spit_offset") --I HAD TO BUILD THIS ANIMATION LIKE A BLIND MADMAN
			inst.components.jumper:AirDrag(0.3, 0.3, 0.2, 20) --mspeed, mfall, maccel, duration
			--LETS TRY AN AIRSTALL FOR THE PLAYERS
			inst.SoundEmitter:PlaySound(SoundPath(inst, "wakeUp"))
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				if inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
			end),

			TimeEvent(11*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_flesh_lrg_dull")
				inst.AnimState:SetTime(15*FRAMES)
			end),

			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(9) 
				inst.components.hitbox:SetAngle(55) 
				inst.components.hitbox:SetBaseKnockback(50) 
				inst.components.hitbox:SetGrowth(80) 
				inst.components.hitbox:SetSize(0.5) 
				inst.components.hitbox:SetLingerFrames(120)
				
				inst.components.hitbox:SetProjectileAnimation("spider_spit", "spider_spit", "idle")
				inst.components.hitbox:SetProjectileSpeed(9, 0.4)
				inst.components.hitbox:SetProjectileDuration(45)
				
				local projectile = SpawnPrefab("basicprojectile")
				projectile.Transform:SetScale(1.0, 1.0, 1.0)
				inst.components.hitbox:SpawnProjectile(0.3, 0.2, 0, projectile)
			end),
			
            TimeEvent(28*FRAMES, function(inst) --34
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	
	
	
	--FSPECIAL
	State{
        name = "fspecial",
        tags = {"attack", "force_trade", "force_direction", "busy", "nolandingstop", "no_air_transition", "canrotate", "no_fastfalling", "reducedairacceleration"}, 
        
        onenter = function(inst)
			inst.AnimState:SetBank("spider") 
			inst.AnimState:PlayAnimation("warrior_atk")
			-- inst.components.locomotor:Motor(20, 1, 12)
			inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt"))
            inst.SoundEmitter:PlaySound(SoundPath(inst, "Jump"))
            
        end,
		
		onexit = function(inst)
			inst.AnimState:Resume()
			inst.AnimState:SetBank("spiderfighter")
			inst.components.locomotor:Clear()
			if inst.motortask then
				inst.motortask:Cancel() --I SHOULD REALLY SET THESE UP TO CANCEL THEMSELVES ON STATE CHANGE, ITS GONNA CONFUSE MODDERS --TODOLIST
			end
        end,
		
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) inst.AnimState:SetAddColour(0.4,0.4,0,0.4) end),
			TimeEvent(3*FRAMES, function(inst) inst.AnimState:SetAddColour(0,0,0,0) end),
			TimeEvent(4*FRAMES, function(inst) inst.components.launchgravity:AirOnlyLaunch(1,4,0) end),
			
			TimeEvent(8*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				
				inst.components.hitbox:SetDamage(7) --8
				inst.components.hitbox:SetAngle(60)
				inst.components.hitbox:SetBaseKnockback(70)
				inst.components.hitbox:SetGrowth(88)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(10)
				inst.components.hitbox:SetPriority(10) --8-28 FIRST ATTEMPT AT PRIORITY --AND IT WORKS. FIRST TRY. WOW
				
				inst.components.hitbox:SpawnHitbox(0.8, 1, 0) 
				inst.components.hitbox:MakeFX("slide1", 0.5, 0, 0.1, 0.5, 0.5, 1, 10, 0)
			end),
			
			--9-19-20 ISSUES WITH THIS ONE!!! I THINK HITTING SOMEONE ON FRAME 9 IS CAUSING THE SUPER SLIDE BUG
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.locomotor:Motor(30, 0, 8)
			end),
			
			TimeEvent(11*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("dahswoosh", 0, 1, -0.5,   2, 0.7,   0.6, 10, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			end),
			
			TimeEvent(14*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("dahswoosh", 0, 1, 0.5,   2, 0.7,   0.6, 10, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			end),
			
			TimeEvent(17*FRAMES, function(inst)
				inst.sg:AddStateTag("can_grab_ledge")
				inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1, 0.8, 0.8, 1, 10, 0)
				inst.components.jumper:AirStall()
				inst.components.locomotor:SlowFall(0.1, 13)
				inst.components.jumper:ScootForward(8) --IF WE'VE HIT SOMEONE, SOMETIMES THOSE EXTRA MOTER FRAMES OVERLAP THIS!!
			end),
			
			TimeEvent(18*FRAMES, function(inst) 
				if inst.components.launchgravity:GetIsAirborn() then 
					inst.components.launchgravity:AirOnlyLaunch(2,4,0)
					inst.AnimState:Resume()
					inst.AnimState:SetBank("spiderfighter")
					inst.AnimState:PlayAnimation("rolling")
				else
					inst.components.jumper:ScootForward(5) --THIS FIXES THE SUPER LONG LUNGE
				end
			end),
			
			TimeEvent(20*FRAMES, function(inst) 
				inst.sg:AddStateTag("can_grab_ledge")
				if not inst.components.launchgravity:GetIsAirborn() then 
					inst.AnimState:Pause()
				end
			end),
			
			TimeEvent(30*FRAMES, function(inst) 
				inst.AnimState:Resume()
				inst.sg:RemoveStateTag("reducedairacceleration")
			end),
			
            TimeEvent(37*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				-- inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {
            -- EventHandler("on_punished", function(inst)
				-- inst.components.aifeelings.fspecialmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.fspecialmod, -5)
			-- end), 
			
			-- EventHandler("on_hit", function(inst)
				-- inst.components.aifeelings.fspecialmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.fspecialmod, 5)
			-- end),
        },
    },
	
	

	--DSPECIAL   --IDK MAN, JUST TAUNT I GUESS?
	State{
        name = "dspecial",
        tags = {"busy", "armor", "nolandingstop"}, --1-16-22 ALRIGHT ALRIGHT. JUST FOR FUNSIES
        
        onenter = function(inst)
			--LETS NOT FALL ASLEEP IN THE AIR
			--BUT LET PLAYERS DO IT IN THE AIR
			-- if inst.components.launchgravity:GetIsAirborn() then 
				-- return end --I GUESS??
			
			
			inst.AnimState:PlayAnimation("taunt")
			inst.SoundEmitter:PlaySound(SoundPath(inst, "scream"))
			
		end,
		
		onexit = function(inst)
			inst:RemoveTag("heavy") 
		end,
		
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.sg:RemoveStateTag("armor")
			end),
			
			TimeEvent(30*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
        },
        
        events=
        {
            EventHandler("attacked", function(inst)
				if inst.sg:HasStateTag("armor") then --JUST A FUN VISUAL
					inst.components.visualsmanager:Blink(inst, 4,   1, 1, 1,   0.3, 0.5) --Blink(inst, duration, r, g, b, glow, alpha)
				end
            end),
        },
    },
	
	
	
	--ALL SMASH ATTACKS HAVE 3 SEPERATE STATES. A STARTUP, A CHARGE, AND THEN THE ACTUAL ATTACK
	--FSMASH
	State{
        name = "fsmash_start",
        tags = {"busy", "scary"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("fsmash_charge")
			inst.components.hitbox:SetDamage(18)
			-- inst.components.locomotor:FaceTarget(inst.components.stats.opponent) --AI SPECIFIC -STILL QUESTIONABLE EVEN FOR AI
            inst.components.hitbox:MakeFX("glint", -0.2, 0.6, 0.1,   0.9, 0.9,   0.5, 6, 0.8,  0, 0, 0,   1) 
			--(fxname, xoffset, yoffset, zoffset,    xsize, ysize,    alpha, duration, glow,   r, g, b,    stick, build, bank)
        end,
		
		timeline=
        {
            TimeEvent(8*FRAMES, function(inst)
				inst.sg:GoToState("fsmash_charge")
			end),
			TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
            TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt")) end),
        },
		
		events=
        {
			-- EventHandler("on_punished", function(inst)
				-- inst.components.aifeelings.baitsmashmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.baitsmashmod, -5)
			-- end),
			-- EventHandler("on_hit", function(inst)
				-- inst.components.aifeelings.baitsmashmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.baitsmashmod, 5)
			-- end),
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
			-- inst:RemoveTag("chargesmash") --AI SPECIFIC
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
			EventHandler("throwsmash", function(inst) inst.sg:GoToState("fsmash") end ),
			--AI SPECIFIC
			-- EventHandler("on_punished", function(inst)
				-- inst.components.aifeelings.baitsmashmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.baitsmashmod, -5)
			-- end),
			-- EventHandler("on_hit", function(inst)
				-- inst.components.aifeelings.baitsmashmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.baitsmashmod, 5)
			-- end),
        },
    },
	
	
	State{
        name = "fsmash",
        tags = {"attack", "notalking", "busy", "abouttoattack", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("fsmash")
        end,
		
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(0.4, 0)
			end),
			
			TimeEvent(3*FRAMES, function(inst) --7
				inst.components.hitbox:MakeFX("punchwoosh", 1.3, 1.0, -0.2,   1.3, 1.3,   0.5, 4, 0.4,  0, 0, 0,   1) 
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(60)  --PIKACHU'S
				inst.components.hitbox:SetGrowth(75)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(1, 1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
				
				inst.components.hitbox:SetSize(1.0)
				inst.components.hitbox:SpawnHitbox(1.5, 1.0, 0)  
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(-0.7, 0)
			end),
			
            TimeEvent(20*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
        },
		
		events=
        {
            -- EventHandler("on_punished", function(inst)
				-- inst.components.aifeelings.baitsmashmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.baitsmashmod, -5)
			-- end),
			
			-- EventHandler("on_hit", function(inst)
				-- inst.components.aifeelings.baitsmashmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.baitsmashmod, 5)
			-- end),
        },
    },
	
	
	--DSMASH  --SO UH, I DIDNT MAKE AN ANIMATION FOR SPIDERS. SO WE JUST GONNA WING IT
	State{
        name = "dsmash_start",
        tags = {"busy"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("sleep_pre")
			inst.components.hitbox:SetDamage(13)
        end,
		
		timeline=
        {
            TimeEvent(6*FRAMES, function(inst) 
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
				inst.components.colourtweener:StartTween({1,0,0,1}, 2, nil)
				inst.AnimState:Pause()
			end
        end,
		
		onexit = function(inst)
            inst.components.colourtweener:EndTween()
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.visualsmanager:EndShimmy()
			inst.AnimState:Resume()
        end,
		
		onupdate = function(inst)
            inst.components.hitbox:MultiplyDamage(1.0113)
        end,
        
        timeline=
        {
			TimeEvent(10*FRAMES, function(inst)
				inst.components.visualsmanager:Shimmy(0.02, 0.02, 10)
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
			inst.AnimState:Resume()
			-- inst.components.hitbox:MakeFX("woosh1", 0, 0.1, -0.1,   1.1, 1.0,   0.9, 6, 0.2, 0,0,0, 1)
			-- inst.components.hitbox:MakeFX("woosh1", 0, 0.1, -0.1,   -1.1, 1.0,   0.9, 6, 0.2, 0,0,0, 1)
			inst.components.hitbox:MakeFX("spinwoosh",   0.0,  0.3, -0.2,  1.0, 0.75,   0.8, 8, 0,   -0.8, -0.8, -0.8,  2) 
			inst.components.hitbox:MakeFX("spinwoosh2", -0.1, 0.25, 0.2,   0.95, 0.5,   0.8, 8, 0,  -0.8, -0.8, -0.8,  2)
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				inst.AnimState:PlayAnimation("spintest_000", true)
				
			end),
			
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:SetAngle(35) --55
				inst.components.hitbox:SetBaseKnockback(65)
				inst.components.hitbox:SetGrowth(90)
				inst.components.hitbox:SetSize(1.5, 0.2)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0, 0, 0)
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.AnimState:PlayAnimation("landing")
			end),
			
            TimeEvent(25*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
		
	},
	
	
	--USMASH
	State{
        name = "usmash_start",
        tags = {"busy", "scary"}, 

        onenter = function(inst)
			inst.components.hitbox:SetDamage(18)
			-- inst.sg:GoToState("usmash") --AI SPECIFIC - HAROLD DOESNT CHARGE THESE. HE JUST THROWS THEM OUT
			-- inst.components.locomotor:FaceTarget(inst.components.stats.opponent) --DONT THINK THIS REALLY MATTERS DOES IT?
			inst.AnimState:PlayAnimation("usmash")
            inst.components.hitbox:MakeFX("glint", -0.2, 0.6, 0.1,   0.9, 0.9,   0.5, 6, 0.8,  0, 0, 0,   1) 
			inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack"))
        end,
		
		timeline=
        {
            TimeEvent(6*FRAMES, function(inst) 
				inst.sg:GoToState("usmash_charge")
			end),
        },
	},
	
	State{
        name = "usmash_charge",
        tags = {"attack", "u_charge", "busy"},
        
        onenter = function(inst)
			inst.AnimState:Pause()
			inst.components.colourtweener:StartTween({1,0,0,1}, 1, nil)
			-- if not inst:HasTag("chargesmash") then --AI SPECIFIC
				-- inst.sg:GoToState("usmash")
			-- end
        end,
		
		onupdate = function(inst)
            inst.components.hitbox:MultiplyDamage(1.0113)
        end,
		
		onexit = function(inst)
            inst.components.colourtweener:EndTween()
			inst.components.visualsmanager:EndShimmy()
			inst.AnimState:SetMultColour(1,1,1,1)
			-- inst:RemoveTag("chargesmash") --AI SPECIFIC
			inst.AnimState:Resume()
        end,
        
        timeline=
        {
			TimeEvent(10*FRAMES, function(inst) 
				inst.components.visualsmanager:Shimmy(0, 0.02, 10)
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
        tags = {"attack", "notalking", "busy", "abouttoattack", "scary"}, 
        
        onenter = function(inst)
			-- inst.AnimState:PlayAnimation("usmash")
			--NO, JUST RESUME
        end,
		
        timeline=
        {
            -- TimeEvent(2*FRAMES, function(inst)
				-- inst.components.hurtboxes:ShiftHurtboxes(0.4, 0) --??
			-- end),
			
			--ADDED 6 FRAMES TO THE PLAYER'S STARTUP STATE. GOTTA SUBTRACT 6 FRAMES FROM THE SWING
			
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(1)
				inst.components.hitbox:SetAngle(120) 
				inst.components.hitbox:SetBaseKnockback(15) 
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.7)
				
				inst.components.hitbox:AddSuction(0.3, 0.5, 0.0) --(power, x, y)
				inst.components.hitbox.property = 4
				
				inst.components.hitbox:SpawnHitbox(0, 0.8, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetSize(1.3)
				inst.components.hitbox.property = 4
				inst.components.hitbox:SpawnHitbox(0, 0.8, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox.property = 4
				inst.components.hitbox:SpawnHitbox(0, 0.8, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox.property = 4
				inst.components.hitbox:SpawnHitbox(0, 0.8, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(13*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox.property = 4
				inst.components.hitbox:SpawnHitbox(0, 0.8, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(18*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(88)
				inst.components.hitbox:SetBaseKnockback(25)
				inst.components.hitbox:SetGrowth(210) 
				inst.components.hitbox:SetSize(1.4)
				
				inst.components.hitbox:SpawnHitbox(0, 1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				inst.sg:RemoveStateTag("scary")
			end),
			
            TimeEvent(36*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
		},
    },
}




CommonStates.AddFrozenStates2(states)
CommonStates.AddRespawnPlatform(states)
CommonStates.AddDropSpawn(states)
    
return StateGraph("wilson", states, events, "idle") --, actionhandlers)

