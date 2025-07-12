--require("stategraphs/fighterstates")

local trace = function() end

-- local trainbehavior = "evade" --MAKING THIS A GLOBAL


--10-3-17- A MINI INSTANCE OF THE RECOVERY BEHAVIOR WITHOUT NEEDING TO IMPLIMENT AN ENTIRE BRAIN.
local function CheckForEdge(inst)

	for k,v in pairs(inst.components.inventory.equipslots) do
		if v.components.inventoryitem and v.components.inventoryitem.foleysound then
			inst.SoundEmitter:PlaySound(v.components.inventoryitem.foleysound)
		end
	end

    if inst.prefab == "wx78" then
        inst.SoundEmitter:PlaySound("dontstarve/movement/foley/wx78")
    end

end




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

local actionhandlers = 
{
    ActionHandler(ACTIONS.CHOP, 
        function(inst) 
            if not inst.sg:HasStateTag("prechop") then 
                if inst.sg:HasStateTag("chopping") then
                    return "chop"
                else
                    return "chop_start"
                end
            end 
        end),
    ActionHandler(ACTIONS.MINE, 
        function(inst) 
            if not inst.sg:HasStateTag("premine") then 
                if inst.sg:HasStateTag("mining") then
                    return "mine"
                else
                    return "mine_start"
                end
            end 
        end),
    ActionHandler(ACTIONS.HAMMER, 
        function(inst) 
            if not inst.sg:HasStateTag("prehammer") then 
                if inst.sg:HasStateTag("hammering") then
                    return "hammer"
                else
                    return "hammer_start"
                end
            end 
        end),
	ActionHandler(ACTIONS.TERRAFORM,
		function(inst)
			return "terraform"
		end), 
	
	ActionHandler(ACTIONS.DIG, 
        function(inst) 
            if not inst.sg:HasStateTag("predig") then 
                if inst.sg:HasStateTag("digging") then
                    return "dig"
                else
                    return "dig_start"
                end
            end 
        end),        
    ActionHandler(ACTIONS.NET, 
        function(inst)
            if not inst.sg:HasStateTag("prenet") then 
                if inst.sg:HasStateTag("netting") then
                    return "bugnet"
                else
                    return "bugnet_start"
                end
            end
        end),        
    ActionHandler(ACTIONS.FISH, "fishing_pre"),
    
    ActionHandler(ACTIONS.FISHOCEAN, "fish_ocean"),

	ActionHandler(ACTIONS.FERTILIZE, "doshortaction"),
	ActionHandler(ACTIONS.TRAVEL, "doshortaction"),
    ActionHandler(ACTIONS.LIGHT, "give"),
    ActionHandler(ACTIONS.UNLOCK, "give"),
    ActionHandler(ACTIONS.TURNOFF, "give"),
    ActionHandler(ACTIONS.TURNON, "give"),
    ActionHandler(ACTIONS.ADDFUEL, "doshortaction"),
    ActionHandler(ACTIONS.REPAIR, "dolongaction"),
    
    ActionHandler(ACTIONS.READ, "book"),

    ActionHandler(ACTIONS.MAKEBALLOON, "makeballoon"),
    ActionHandler(ACTIONS.DEPLOY, "doshortaction"),
    ActionHandler(ACTIONS.STORE, "doshortaction"),
    ActionHandler(ACTIONS.DROP, "doshortaction"),
    ActionHandler(ACTIONS.MURDER, "dolongaction"),
   	ActionHandler(ACTIONS.ACTIVATE, 
        function(inst, action)
            if action.target.components.activatable then
                if action.target.components.activatable.quickaction then
                    return "doshortaction"
                else
                    return "dolongaction"
                end
            end
        end),
    ActionHandler(ACTIONS.PICK, 
        function(inst, action)
            if action.target.components.pickable then
                if action.target.components.pickable.quickpick then
                    return "doshortaction"
                else
                    return "dolongaction"
                end
            end
        end),
        
    ActionHandler(ACTIONS.SLEEPIN, 
		function(inst, action)
			if action.invobject then
                if action.invobject.onuse then
                    action.invobject.onuse()
                end
				return "bedroll"
			else
				return "doshortaction"
			end
		
		end),

    ActionHandler(ACTIONS.TAKEITEM, "dolongaction" ),
    
    ActionHandler(ACTIONS.BUILD, "dolongaction"),
    ActionHandler(ACTIONS.SHAVE, "shave"),
    ActionHandler(ACTIONS.COOK, "dolongaction"),
    ActionHandler(ACTIONS.PICKUP, "doshortaction"),
    ActionHandler(ACTIONS.CHECKTRAP, "doshortaction"),
    ActionHandler(ACTIONS.RUMMAGE, "doshortaction"),
    ActionHandler(ACTIONS.BAIT, "doshortaction"),
    ActionHandler(ACTIONS.HEAL, "dolongaction"),
    ActionHandler(ACTIONS.SEW, "dolongaction"),
    ActionHandler(ACTIONS.TEACH, "dolongaction"),
    ActionHandler(ACTIONS.RESETMINE, "dolongaction"),
    ActionHandler(ACTIONS.EAT, 
        function(inst, action)
            if inst.sg:HasStateTag("busy") then
                return nil
            end
            local obj = action.target or action.invobject
            if not (obj and obj.components.edible) then
                return nil
            end
            
            if obj.components.edible.foodtype == "MEAT" then
                return "eat"
            else
                return "quickeat"
            end
        end),
    ActionHandler(ACTIONS.GIVE, "give"),
    ActionHandler(ACTIONS.PLANT, "doshortaction"),
    ActionHandler(ACTIONS.HARVEST, "dolongaction"),
    ActionHandler(ACTIONS.PLAY, function(inst, action)
        if action.invobject then
            if action.invobject:HasTag("flute") then
                return "play_flute"
            elseif action.invobject:HasTag("horn") then
                return "play_horn"
            end
        end
    end),
    ActionHandler(ACTIONS.JUMPIN, "jumpin"),
    ActionHandler(ACTIONS.DRY, "doshortaction"),
    ActionHandler(ACTIONS.CASTSPELL, "castspell"),
    ActionHandler(ACTIONS.BLINK, "quicktele"),
    ActionHandler(ACTIONS.COMBINESTACK, "doshortaction"),
}

   
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
			-- print("MOBIILE. ME TOO")
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
						inst.sg:GoToState("airdodge")
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
		
			--if is_tryingtoblock and can_oos and not is_busy and not wantstoblock then
			-- if is_tryingtoblock and not is_busy and not wantstoblock then
				-- if is_parrying then
					-- inst.sg:GoToState("idle")
				-- else
					-- inst.sg:GoToState("block_stop")
				-- end
			-- end
			-- if f_charge then
				-- print("YOU")
			-- end
			-- if f_charge then
				-- print("YOU")
			-- end
			-- if atk_key_dwn then
				-- print("GET OFFA MY CLOUD")
			-- end
			
			if f_charge and not atk_key_dwn then
				inst.sg:GoToState("fsmash")
			elseif u_charge and not atk_key_dwn then
				inst.sg:GoToState("usmash")
			end
		end

		-- inst:AddTag("wantstoblock")
	end),
	
	
	EventHandler("clearbuffer", function(inst)
		inst.components.stats.buffertick = 0
	end),
	
	
	EventHandler("jump", function(inst)
		local is_busy = inst.sg:HasStateTag("busy")
		local can_jump = inst.sg:HasStateTag("can_jump")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local nojumping = inst.sg:HasStateTag("nojumping") --FOR WES ONLY, NOT IN ANY OTHER STATEGRAPHS
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
		if (can_jump and not is_airborn) or (not is_busy and not is_airborn) or ((can_jump or can_oos or can_ood) and not is_airborn) then
			inst.sg:GoToState("highleap")
		elseif ((can_jump and inst.components.jumper.currentdoublejumps >= 1) or (not is_busy and inst.components.jumper.currentdoublejumps >= 1)) and not nojumping then
			inst.sg:GoToState("doublejump")
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
		
		-- print("IS IT THEE?", is_busy, is_falling)
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
	
	EventHandler("dash", function(inst)
		local is_busy = inst.sg:HasStateTag("busy")
		local no_running = inst.sg:HasStateTag("no_running")
		local can_dash = inst.sg:HasStateTag("candash") and not no_running --WILL THIS FIX IT? --1-8
		local pivoting = inst.sg:HasStateTag("pivoting")
		local pressing_forward = inst.components.keydetector:GetForward(inst)
		local foxtrot = inst.sg:HasStateTag("foxtrot")
		
		if foxtrot and not pressing_forward then
			inst.sg:GoToState("run_stop")
		elseif foxtrot and not no_running then --WILL THIS FIX IT? --1-8
			inst.sg:GoToState("dash")
		elseif (not is_busy and not no_running) or can_dash then
			-- inst.sg:GoToState("dash")
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
        if is_attacking or is_busy then return end
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
    
    EventHandler("transform_werebeaver", function(inst, data)
        if inst.components.beaverness then
            TheCamera:SetDistance(14)
            inst.sg:GoToState("werebeaver")

        end
    end),

    EventHandler("blocked", function(inst, data)
        if not inst.components.health:IsDead() then
            if inst.sg:HasStateTag("shell") then
                inst.sg:GoToState("shell_hit")
            end
        end
    end),

    EventHandler("attacked", function(inst, data)
					--print("THE HECK MAAAAN???-----")
		-- if not inst.components.health:IsDead() then
			if data.attacker and data.attacker:HasTag("insect") then
                local is_idle = inst.sg:HasStateTag("idle")
                if not is_idle then
                    -- avoid stunlock when attacked by bees/mosquitos
                    -- don't go to full hit state, just play sounds

                    inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")        
                    
                    if inst.prefab ~= "wes" then
                        local sound_name = inst.soundsname or inst.prefab
                        local sound_event = "dontstarve/characters/"..sound_name.."/hurt"
                        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride or sound_event)
                    end
                    return
                end
			end
            -- if inst.sg:HasStateTag("shell") then   --@@@@@ OOOH SNAP
                -- inst.sg:GoToState("shell_hit")
            -- else
                -- inst.sg:GoToState("hit")
            -- end
			
			if inst.sg:HasStateTag("shell") then   --@@@@@ OOOH SNAP
                inst.sg:GoToState("shell_hit")
            -- elseif inst:HasTag("terminal_vel") then --WAIT...WHY IS THIS EVEN HERE?
				-- inst.sg:GoToState("meteor")
			elseif inst.sg:HasStateTag("hanging") then
				--11-12-17 IF HOLDING LEDGE, TELEPORT THEM DOWN BY THEIR HIEGHT BEFORE CONTINUING AS NORMAL
				inst.components.locomotor:Teleport(-0.5, -inst.components.stats.height, 0)
				inst.sg:GoToState("hit", data.hitstun) 
			else
                --inst.sg:GoToState("hit")
				-- print("KINKSHAME A CABBAGE", data.hitstun)
				inst.sg:GoToState("hit", data.hitstun) --12-4
            end
		-- end
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

    --[[EventHandler("dowhiff", function(inst)
        if not inst.components.health:IsDead() then
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
--]]

    EventHandler("equip", function(inst, data)
        if inst.sg:HasStateTag("idle") then
			if data.eslot == EQUIPSLOTS.HANDS then
				inst.sg:GoToState("item_out")
			else
				inst.sg:GoToState("item_hat")
			end
        end
    end),
    
    EventHandler("unequip", function(inst, data)
        
        if inst.sg:HasStateTag("idle") then
        
			if data.eslot == EQUIPSLOTS.HANDS then
				inst.sg:GoToState("item_in")
			else
				inst.sg:GoToState("item_hat")
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

    EventHandler("ontalk", function(inst, data)
        -- if inst.sg:HasStateTag("idle") then
            -- if inst.prefab == "wes" then
				-- inst.sg:GoToState("mime")
            -- else
				-- inst.sg:GoToState("talk", data.noanim)
			-- end
        -- end
        
    end),

       
    EventHandler("wakeup",
        function(inst)
            inst.sg:GoToState("wakeup")
        end),        
    EventHandler("powerup",
        function(inst)
            if GetTick() > 0 then
                inst.sg:GoToState("powerup")
            end
        end),        
    EventHandler("powerdown",
        function(inst)
            inst.sg:GoToState("powerdown")
        end),        
       
    EventHandler("readytocatch",
		function(inst)
			inst.sg:GoToState("catch_pre")
		end),        
        
    EventHandler("toolbroke",
		function(inst, data)
			inst.sg:GoToState("toolbroke", data.tool)
		end),        

    EventHandler("torchranout",
        function(inst, data)
            if not inst.components.inventory:IsItemEquipped(data.torch) then
                local sameTool = inst.components.inventory:FindItem(function(item)
                    return item.prefab == data.torch.prefab
                end)
                if sameTool then
                    inst.components.inventory:Equip(sameTool)
                end
            end
        end),

    EventHandler("armorbroke",
		function(inst, data)
			inst.sg:GoToState("armorbroke", data.armor)
		end),        
        
    EventHandler("fishingcancel",
		function(inst)
		    if inst.sg:HasStateTag("fishing") then
			    inst.sg:GoToState("fishing_pst")
			end
		end),
		
		
	--@@@@@@ MY OWN EVEN HANDLER
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
		
		
			
		if can_oos then
			inst.sg:GoToState("grab")
			
		elseif must_fsmash then
			inst.sg:GoToState("fsmash_start")
		elseif must_usmash then
			-- inst.sg:GoToState("usmash_start")
		elseif must_dsmash then
			inst.sg:GoToState("dsmash_start")
		elseif must_ftilt then
			inst.sg:GoToState("ftilt") --ftilt
			
		elseif can_ood then
			inst.sg:GoToState("dash_attack")
			-- inst.sg:GoToState("dash_grab")
		elseif is_prone then
			inst.sg:GoToState("getup_attack")
			
		elseif listen_for_attack then
			if jab1 then
				inst.sg:GoToState("jab2")
			elseif jab2 then 
				inst.sg:GoToState("jab3")
			end
		--end
		
        --if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
		-- elseif not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
		elseif not inst.sg:HasStateTag("busy") or can_attack then --12-4
		
			
			if (can_oos or data.key == "block") and not airial then --4-5 ADDING BUFFER BLOCK
			 inst.sg:GoToState("grab")
			elseif can_ood then
				inst.sg:GoToState("dtilt")
			
			--if airial and not airial == 0 then
			elseif airial then
				
				--if inst.components.keydetector:GetDown(inst) then --4-5 REPLACING THE OLD METHOD WITH THE NEW BUFFER METHOD
				if data.key == "backward" or data.key == "diagonalb" then 
					inst.sg:GoToState("bair")
				elseif data.key == "forward" or data.key == "diagonalf" then --AH-HAH!! DIAGONALS --11-7-16
					inst.sg:GoToState("fair")
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
					inst.sg:GoToState("uptilt")
				elseif data.key == "down" then
					inst.sg:GoToState("downtilt")
				elseif data.key == "forward" then
					inst.sg:GoToState("ftilt")
				elseif data.key == "backward" or data.key == "diagonalb" then
					if not inst.components.keydetector:GetForward(inst) then
						inst.components.locomotor:TurnAround()
					end
					inst.sg:GoToState("ftilt")
				else
				
				--inst.sg:GoToState("attack")
				inst.sg:GoToState("jab1")
				end
				
			end
			
        end
    end),
	
	
	--CSTICK
	EventHandler("cstick_up", function(inst)
		
		local airial = inst.components.launchgravity:GetIsAirborn()
		local can_attack = inst.sg:HasStateTag("can_attack")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local is_tryingtoblock = inst.sg:HasStateTag("tryingtoblock")  --721
		
		if can_ood then
			-- inst.sg:GoToState("usmash_start")
		elseif not inst.sg:HasStateTag("busy") and not is_tryingtoblock and not airial then
			-- inst.sg:GoToState("usmash_start")
		elseif not inst.sg:HasStateTag("busy") and airial then
			inst.sg:GoToState("uair")
		end
		
		--inst.sg:HasStateTag("busy")
		
	
	end),
	
	EventHandler("cstick_down", function(inst)
		-- print("I WANT MY CEREAL")
		
		local airial = inst.components.launchgravity:GetIsAirborn()
		local can_ood = inst.sg:HasStateTag("can_ood")
		local is_tryingtoblock = inst.sg:HasStateTag("tryingtoblock")  --721
		
		if can_ood then
			inst.sg:GoToState("dash_attack")	
		elseif not inst.sg:HasStateTag("busy") and not is_tryingtoblock and not airial then
			inst.sg:GoToState("dsmash_start")	
		elseif not inst.sg:HasStateTag("busy") and airial then
			inst.sg:GoToState("dair")
		else
			-- print("I WANT MY bagel")
		end
		
	end),
	
	-- EventHandler("cstick_forward", function(inst)
		
		-- local airial = inst.components.launchgravity:GetIsAirborn()
		-- local must_fsmash = inst.sg:HasStateTag("must_fsmash")
		
		-- print("COMPANY HALT")
		
		-- if must_fsmash then
			-- inst.sg:GoToState("fsmash_start")	
		-- elseif not inst.sg:HasStateTag("busy") and not airial then
			-- inst.sg:GoToState("fsmash_start")	
		-- elseif not inst.sg:HasStateTag("busy") and airial then
			-- inst.sg:GoToState("fair")
		-- end
	-- end),
	
	-- EventHandler("cstick_backward", function(inst) --THAT STUPID S
		
		-- local airial = inst.components.launchgravity:GetIsAirborn()
		-- local must_fsmash = inst.sg:HasStateTag("must_fsmash")
		-- -- print("BLADE")
		
		-- if must_fsmash then
			-- inst.sg:GoToState("fsmash_start")	
		-- elseif not inst.sg:HasStateTag("busy") and not airial then
			-- inst.components.locomotor:TurnAround()
			-- inst.sg:GoToState("fsmash_start")	
		-- elseif not inst.sg:HasStateTag("busy") and airial then
			-- inst.sg:GoToState("bair")
			-- -- print("THIMBIT")
		-- end
	-- end),
	
	
	--7-20-17 NEW CSTICK LISTENER TO ALLOW DIRECTIONAL BUFFEREING OUT OF CHANGING DIRECTIONS
	EventHandler("cstick_side", function(inst, data)
		local is_tryingtoblock = inst.sg:HasStateTag("tryingtoblock")  --721
		local is_busy = inst.sg:HasStateTag("busy") or is_tryingtoblock --721 7-21-17 JUST THROWING THIS ON BUSY BC IM LAZY. AND THERE ARE ONLY A FEW INSTANCES IN WHICH TRYINGTOBLOCK NEEDS UNBUSY
		local airial = inst.components.launchgravity:GetIsAirborn()
		local must_fsmash = inst.sg:HasStateTag("must_fsmash")
		local is_forward = (data.key == inst.components.launchgravity:GetRotationFunction())
		local valid_key = (data.key == "left" or data.key == "right")
		
		if must_fsmash and is_forward then  --7-20-17 ITS GOOD TO LEAVE THIS HERE OR ELSE DASH ATTACKS GET WIERD
			inst.sg:GoToState("fsmash_start")	
		
		elseif not is_busy and not airial then
			--TURN AROUND IF NOT FACING THE SAME WAY THE BUFFERED DIRECTION KEY WAS
			if not is_forward and valid_key then --MAKE SURE THAT THE KEY DIDNT JUST COME IN AS TABLE GIBBERISH INSTEAD OF THE OPPOSITE DIRECTION
				inst.components.locomotor:TurnAround()
			end
			inst.sg:GoToState("fsmash_start")
			
		elseif not is_busy and airial then
			if not is_forward and valid_key then 
				inst.sg:GoToState("bair")
			else --BUT IF IT DOES COME IN AS TABLE GISBBERISH, JUST ASSUME IT WAS MEANT TO BE FORWARD, WHATEVER
				inst.sg:GoToState("fair") 
			end
		end
	end),
	
	EventHandler("throwspecial", function(inst, data)
		local can_special_attack = inst.sg:HasStateTag("can_special_attack")
		local airial = inst.components.launchgravity:GetIsAirborn()
		local is_tryingtoblock = inst.sg:HasStateTag("tryingtoblock")
		
		if not (inst.sg:HasStateTag("busy") or is_tryingtoblock) or can_special_attack then  --721
			-- if inst.components.keydetector:GetUp(inst) then
			if data.key == "up" or data.key == "diagonalf" then
				inst.sg:GoToState("uspecial")
			elseif data.key == "diagonalb" then
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("uspecial")
			elseif data.key == "down" then
				-- inst.sg:GoToState("dspecial") --DONT
			elseif data.key == "forward" then
				if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --11-7-17 IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
				inst.sg:GoToState("fspecial")
			elseif data.key == "backward" then
				if data.key2 ~= inst.Transform:GetRotation() then inst.components.locomotor:TurnAround() end --IF PLAYER HAS SOMEHOW CHAGED DIRECTION, TURN THEM BACK AROUND
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
		-- inst.sg:GoToState("respawn_platform")
		inst.sg:GoToState("air_idle") --WHEN I LEFT OFF, THIS WAS STILL GOING TO RESPAWN PLATFORM
	end),
}



local statue_symbols = 
{
    "ww_head",
    "ww_limb",
    "ww_meathand",
    "ww_shadow",
    "ww_torso",
    "frame",
    "rope_joints",
    "swap_grown"
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
        name = "powerup",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("powerup")
            inst.components.health:SetInvincible(true)
        end,
        
        onexit = function(inst)
            inst.components.health:SetInvincible(false)
            
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    State{
        name = "powerdown",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("powerdown")
            inst.components.health:SetInvincible(true)
        end,
        
        onexit = function(inst)
            inst.components.health:SetInvincible(false)
            
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    
    State{
        name = "caveenter",
        
        onenter = function(inst)
            inst.components.playercontroller:Enable(false)
            inst.AnimState:PlayAnimation("enter")
            inst.components.health:SetInvincible(true)
        end,
        
        onexit = function(inst)
            inst.components.playercontroller:Enable(true)
            inst.components.health:SetInvincible(false)
        end,
        
        timeline=
        {
            TimeEvent(11*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
            end),
		},        
        
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },

    },    
    
    State{
        name = "failadventure",
        
        onenter = function(inst)
            inst.components.playercontroller:Enable(false)
            inst.AnimState:PlayAnimation("wakeup")
        end,
        
        onexit = function(inst)
            inst.components.playercontroller:Enable(true)
            inst.components.talker:Say(GetString(inst.prefab, "ANNOUNCE_ADVENTUREFAIL"))
        end,
        
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },

    },    
    
    State{
        name = "rebirth",
        
        onenter = function(inst)
            inst.components.playercontroller:Enable(false)
            inst.AnimState:PlayAnimation("rebirth")
            
            inst.components.hunger:Pause()
            for k,v in pairs(statue_symbols) do
                inst.AnimState:OverrideSymbol(v, "wilsonstatue", v)
            end
        end,
        
        timeline=
        {
            TimeEvent(16*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/common/dropwood")
            end),
            TimeEvent(45*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/common/dropwood")
            end),
            TimeEvent(92*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/common/rebirth")
            end),
        },
        
        onexit = function(inst)
            inst.components.hunger:Resume()
            for k,v in pairs(statue_symbols) do
                inst.AnimState:ClearOverrideSymbol(v)
            end
        
            inst.components.playercontroller:Enable(true)
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

    State{
        name = "sleepin",
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep")
            inst.components.locomotor:Stop()
            --inst.Controller:Enable(false)
            --inst.AnimState:Hide()
            inst:PerformBufferedAction()             
        end,
        
        onexit= function(inst)
            --inst.Controller:Enable(true)
            --inst.AnimState:Show()
        end,

    },
    
    State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:Hide("swap_arm_carry")
            inst.AnimState:PlayAnimation("death")
        end,
    },

    State{
        name = "idle",
        tags = {"idle", "canrotate"},
		
		--FIXED IDLE ANIMATION
		onenter = function(inst)
			inst.AnimState:PlayAnimation("meat_idle")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			-- inst:PushEvent("idle_detect") --12-12
			-- inst.AnimState:Pause()
			-- print("NETGAMEMODE", TheNet:GetDefaultGameMode())
			
			
			
			--TEST HITBOX
			--
			inst.components.hitbox:SetDamage(7)   --7
			inst.components.hitbox:SetAngle(75)
			-- inst.components.hitbox:SetBaseKnockback(18)
			-- inst.components.hitbox:SetGrowth(110)
			inst.components.hitbox:SetBaseKnockback(90)
			inst.components.hitbox:SetGrowth(30)
			inst.components.hitbox:SetSize(0.65, 0.25)
			inst.components.hitbox:SetLingerFrames(10000)
			
			-- inst.components.hitbox:MakeDisjointed()
			-- inst.components.hitbox:SpawnHitbox(1.8, 1.2, 0) 
			

			
			
			if inst.components.stats and inst.components.launchgravity then	--4-6 I GUESS THIS IS FOR IN CASE NOT ALL COMPONENTS HAVE FINISHED LOADING YET???
				if inst.components.launchgravity:GetIsAirborn() then --4-6 MOVING IT DOWN HERE SEEMED TO FIX IT
					inst.sg:GoToState("air_idle")
				elseif inst.components.keydetector and inst.components.keydetector:GetDown(inst) then
					inst.sg:GoToState("duck")
				end
			end
			
		end,
		
		 events=
        {   
            -- EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),        
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
        
        ontimeout= function(inst)
            --inst.sg:GoToState("funnyidle")
        end,
    },

    State{
        
        name = "funnyidle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
        
			
			if inst.components.temperature:GetCurrent() < 5 then
				inst.AnimState:PlayAnimation("idle_shiver_pre")
				inst.AnimState:PushAnimation("idle_shiver_loop")
				inst.AnimState:PushAnimation("idle_shiver_pst", false)
			elseif inst.components.hunger:GetPercent() < TUNING.HUNGRY_THRESH then
                inst.AnimState:PlayAnimation("hungry")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hungry")    
            elseif inst.components.sanity:GetPercent() < .5 then
				inst.AnimState:PlayAnimation("idle_inaction_sanity")
            else
                inst.AnimState:PlayAnimation("idle_inaction")
            end
        end,

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end ),
        },
        
    },
    
    
    State{ name = "chop_start",
        tags = {"prechop", "chopping", "working"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation(inst.prefab == "woodie" and "woodie_chop_pre" or "chop_pre")
        end,
        
        events=
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end ),
            EventHandler("animover", function(inst) inst.sg:GoToState("chop") end),
        },
    },
    
    State{
        name = "chop",
        tags = {"prechop", "chopping", "working"},
        onenter = function(inst)
			inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation(inst.prefab == "woodie" and "woodie_chop_loop" or "chop_loop")            
        end,
        
        timeline=
        {
            TimeEvent(2*FRAMES, function(inst) 
                if inst.prefab == "woodie" then
                    inst:PerformBufferedAction() 
                end
            end),

            TimeEvent(5*FRAMES, function(inst)
                if inst.prefab == "woodie" then
                    inst.sg:RemoveStateTag("prechop")
                end
            end),

            TimeEvent(10*FRAMES, function(inst)
                if inst.prefab == "woodie" and
                   (TheInput:IsControlPressed(CONTROL_PRIMARY) or TheInput:IsControlPressed(CONTROL_ACTION) or TheInput:IsControlPressed(CONTROL_CONTROLLER_ACTION)) and 
                    inst.sg.statemem.action and 
                    inst.sg.statemem.action:IsValid() and 
                    inst.sg.statemem.action.target and 
                    inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and 
                    inst.sg.statemem.action.target.components.workable then
                        inst:ClearBufferedAction()
                        inst:PushBufferedAction(inst.sg.statemem.action)
                end
            end),

            
            TimeEvent(5*FRAMES, function(inst) 
                if inst.prefab ~= "woodie" then
                    inst:PerformBufferedAction() 
                end
            end),


            TimeEvent(9*FRAMES, function(inst)
                if inst.prefab ~= "woodie" then
                    inst.sg:RemoveStateTag("prechop")
                end
            end),
            
            TimeEvent(14*FRAMES, function(inst)
                if inst.prefab ~= "woodie" and
                    (TheInput:IsMouseDown(MOUSEBUTTON_LEFT) or TheInput:IsControlPressed(CONTROL_ACTION) or TheInput:IsControlPressed(CONTROL_CONTROLLER_ACTION)) and 
                    inst.sg.statemem.action and 
                    inst.sg.statemem.action:IsValid() and 
                    inst.sg.statemem.action.target and 
                    inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and 
                    inst.sg.statemem.action.target.components.workable then
                        inst:ClearBufferedAction()
                        inst:PushBufferedAction(inst.sg.statemem.action)
                end
            end),

            TimeEvent(16*FRAMES, function(inst) 
                inst.sg:RemoveStateTag("chopping")
            end),

        },
        
        events=
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end ),
            EventHandler("animover", function(inst) 
                --inst.AnimState:PlayAnimation("chop_pst") 
                inst.sg:GoToState("idle")
            end ),
            
        },        
    },
    
    
    State{ name = "mine_start",
        tags = {"premine", "working"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickaxe_pre")
        end,
        
        events=
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end ),
            EventHandler("animover", function(inst) inst.sg:GoToState("mine") end),
        },
    },
    
    State{
        name = "mine",
        tags = {"premine", "mining", "working"},
        onenter = function(inst)
			inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("pickaxe_loop")
        end,

        timeline=
        {
            TimeEvent(9*FRAMES, function(inst) 
                if inst.sg.statemem.action and inst.sg.statemem.action.target then
					local fx = SpawnPrefab("mining_fx")
					fx.Transform:SetPosition(inst.sg.statemem.action.target:GetPosition():Get())
				end
                inst:PerformBufferedAction() 
                inst.sg:RemoveStateTag("premine") 
                inst.SoundEmitter:PlaySound("dontstarve/wilson/use_pick_rock")
            end),
            
            TimeEvent(14*FRAMES, function(inst)
				if (TheInput:IsControlPressed(CONTROL_PRIMARY) or
				   TheInput:IsControlPressed(CONTROL_ACTION)  or TheInput:IsControlPressed(CONTROL_CONTROLLER_ACTION)) and 
					inst.sg.statemem.action and 
					inst.sg.statemem.action.target and 
					inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and 
					inst.sg.statemem.action.target.components.workable then
						inst:ClearBufferedAction()
						inst:PushBufferedAction(inst.sg.statemem.action)
				end
            end),
            
        },
        
        events=
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end ),
            EventHandler("animover", function(inst) 
                inst.AnimState:PlayAnimation("pickaxe_pst") 
                inst.sg:GoToState("idle", true)
            end ),
            
        },        
    },
    
    
    State{ name = "hammer_start",
        tags = {"prehammer", "working"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickaxe_pre")
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("hammer") end),
        },
    },
    
    State{
        name = "hammer",
        tags = {"prehammer", "hammering", "working"},
        onenter = function(inst)
			inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("pickaxe_loop")
        end,

        timeline=
        {
            TimeEvent(9*FRAMES, function(inst) 
                inst:PerformBufferedAction() 
                inst.sg:RemoveStateTag("prehammer") 
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
            end),
            
            TimeEvent(14*FRAMES, function(inst)
            
				if (TheInput:IsControlPressed(CONTROL_SECONDARY) or
				   TheInput:IsControlPressed(CONTROL_ACTION) or TheInput:IsControlPressed(CONTROL_CONTROLLER_ALTACTION)) and 
					inst.sg.statemem.action and 
					inst.sg.statemem.action.target and 
					inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action, true) and 
					inst.sg.statemem.action.target.components.workable then
						inst:ClearBufferedAction()
						inst:PushBufferedAction(inst.sg.statemem.action)
				end
            end),
            
        },
        
        events=
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end ),
            EventHandler("animover", function(inst) 
                inst.AnimState:PlayAnimation("pickaxe_pst") 
                inst.sg:GoToState("idle", true)
            end ),
        },        
    }, 
    
    State{
        name = "hide",
        tags = {"idle", "hiding"},
        onenter = function(inst)
            
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("hide")
			inst.SoundEmitter:PlaySound("dontstarve/movement/foley/hidebush")
            inst:AddTag("notarget")
        end,
        
        onexit = function(inst)
            inst:RemoveTag("notarget")
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("hide_idle") end),
        },
    },

    State{
        name = "hide_idle",
        tags = {"idle", "hiding"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("hide_idle", true)
            inst:AddTag("notarget")
        end,
        
        onexit = function(inst)
            inst:RemoveTag("notarget")
        end,
        
    },

    State{
        name = "shell_enter",
        tags = {"idle", "hiding", "shell"},
        onenter = function(inst)            
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("hideshell")
            
        end,
        timeline =
        {
            TimeEvent(6*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/movement/foley/hideshell")    
            end),
        },        
        
        onexit = function(inst)

        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("shell_idle") end),
        },
    },

    State{
        name = "shell_idle",
        tags = {"idle", "hiding", "shell"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("hideshell_idle", true)
        end,
        
        onexit = function(inst)
        end,
        
    },

    State{
        name = "shell_hit",
        tags = {"busy", "hiding", "shell"},
        
        onenter = function(inst)
            inst:ClearBufferedAction()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")        
            inst.AnimState:PlayAnimation("hitshell")
            --local sound_name = inst.soundsname or inst.prefab
            --local sound_event = "dontstarve/characters/"..sound_name.."/hurt"
            --inst.SoundEmitter:PlaySound(sound_event)
            inst.components.locomotor:Stop()         
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("shell_idle") end ),
        }, 
        
        timeline =
        {
            TimeEvent(3*FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },        
               
    },

	State{ name = "terraform",
		tags = {"busy"},
		
		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("shovel_pre")
			inst.AnimState:PushAnimation("shovel_loop")
			inst.AnimState:PushAnimation("shovel_pst", false)
		end,
		
        timeline=
        {
            TimeEvent(25*FRAMES, function(inst) 
                inst:PerformBufferedAction() 
                inst.sg:RemoveStateTag("busy") 
                inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
            end),
		},
        
        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
	},
	
	State{ name = "dig_start",
        tags = {"predig", "working"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("shovel_pre")
        end,
        
        events=
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end ),
            EventHandler("animover", function(inst) inst.sg:GoToState("dig") end),
        },
    },
    
    State{
        name = "dig",
        tags = {"predig", "digging", "working"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("shovel_loop")
			inst.sg.statemem.action = inst:GetBufferedAction()
        end,

        timeline=
        {
            TimeEvent(15*FRAMES, function(inst) 
--[[                if inst.sg.statemem.action and inst.sg.statemem.action.target then
					local fx = SpawnPrefab("shovel_dirt")
					fx.Transform:SetPosition( inst.sg.statemem.action.target.Transform:GetWorldPosition() )
				end
--]]                
                inst:PerformBufferedAction() 
                inst.sg:RemoveStateTag("predig") 
                inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                
            end),
            
            TimeEvent(35*FRAMES, function(inst)
				if (TheInput:IsMouseDown(MOUSEBUTTON_RIGHT) or
				   TheInput:IsControlPressed(CONTROL_ACTION)  or TheInput:IsControlPressed(CONTROL_CONTROLLER_ACTION)) and 
					inst.sg.statemem.action and 
					inst.sg.statemem.action.target and 
					inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action, true) and
					inst.sg.statemem.action.target.components.workable then
						inst:ClearBufferedAction()
						inst:PushBufferedAction(inst.sg.statemem.action)
				end
            end),
            
        },
        
        events=
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end ),
            EventHandler("animover", function(inst) 
                inst.AnimState:PlayAnimation("shovel_pst") 
                inst.sg:GoToState("idle", true)
            end ),
            
        },        
    },       

   State{ name = "bugnet_start",
        tags = {"prenet", "working"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("bugnet_pre")
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("bugnet") end),
        },
    },
    
    State{
        name = "bugnet",
        tags = {"prenet", "netting", "working"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("bugnet")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_bugnet")
        end,

        timeline=
        {
            TimeEvent(10*FRAMES, function(inst) 
                inst:PerformBufferedAction() 
                inst.sg:RemoveStateTag("prenet") 
                inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
            end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle", true)
            end ),
        },        
    },       
    
    State {
        name = "fish_ocean",
        tags = {"busy", "fishing"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:Hide("RIPPLES")
            inst.AnimState:PlayAnimation("fishing_pre") --24
            inst.AnimState:PushAnimation("fishing_idle") --38
            inst.AnimState:PushAnimation("fishing_idle") 
            inst.AnimState:PushAnimation("bite_heavy_pre") --4
            inst.AnimState:PushAnimation("bite_heavy_loop") --13
            inst.AnimState:PushAnimation("bite_heavy_loop")
            inst.AnimState:PushAnimation("fish_catch", false) --13
        end,

        timeline = 
        {
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_cast") end),
            TimeEvent(15*FRAMES, function(inst) inst:PerformBufferedAction() end),
            
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_baitsplash") end),

            TimeEvent(100*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishinwater", "splash")
                inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_strain", "strain")
            end),
            
            TimeEvent(130*FRAMES, function(inst) 
                inst.SoundEmitter:KillSound("splash")
                inst.SoundEmitter:KillSound("strain")
            end),

            TimeEvent(138*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishcaught") end),

            TimeEvent(143*FRAMES, function(inst) inst.sg:RemoveStateTag("fishing") end),
            TimeEvent(149*FRAMES, function(inst)
                local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if equippedTool and equippedTool.components.fishingrod then
                    equippedTool.components.fishingrod:CollectFlotsam()
                end
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },

    },
    
   State{ name = "fishing_pre",
        tags = {"prefish", "fishing"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:Show("RIPPLES")
            inst.AnimState:PlayAnimation("fishing_pre")
        end,
        
        timeline = 
        {
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_cast") end),
            TimeEvent(15*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_baitsplash")
                inst.sg:GoToState("fishing")
            end ),
        },        
    },
    
    State{
        name = "fishing",
        tags = {"fishing"},
        onenter = function(inst, pushanim)
            if pushanim then
                if type(pushanim) == "string" then
                    inst.AnimState:PlayAnimation(pushanim)
                end
                inst.AnimState:PushAnimation("fishing_idle", true)
            else
                inst.AnimState:PlayAnimation("fishing_idle", true)
            end
            local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equippedTool and equippedTool.components.fishingrod then
                equippedTool.components.fishingrod:WaitForFish()
            end
        end,
        
        events=
        {
            EventHandler("fishingnibble", function(inst) inst.sg:GoToState("fishing_nibble") end ),
        },
    },
    
    State{ name = "fishing_pst",
        tags = {},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("fishing_pst")
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },
    
    State{
        name = "fishing_nibble",
        tags = {"fishing", "nibble"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("bite_light_pre")
            inst.AnimState:PushAnimation("bite_light_loop", true)
            inst.sg:SetTimeout(1 + math.random())
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishinwater", "splash")
        end,
        
        onexit = function(inst)
            inst.SoundEmitter:KillSound("splash")
        end,
        
        ontimeout = function(inst)
            inst.sg:GoToState("fishing", "bite_light_pst")
        end,
        
        events = 
        {
            EventHandler("fishingstrain", function(inst) inst.sg:GoToState("fishing_strain") end),
        },
    }, 
    
    State{
        name = "fishing_strain",
        tags = {"fishing"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("bite_heavy_pre")
            inst.AnimState:PushAnimation("bite_heavy_loop", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishinwater", "splash")
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_strain", "strain")
        end,
        
        onexit = function(inst)
            inst.SoundEmitter:KillSound("splash")
            inst.SoundEmitter:KillSound("strain")
        end,
        
        events = 
        {
            EventHandler("fishingcatch", function(inst, data)
                inst.sg:GoToState("catchfish", data.build)
            end),
            EventHandler("fishingloserod", function(inst)
                inst.sg:GoToState("loserod")
            end),

        },
    },
    
    State{
        name = "catchfish",
        tags = {"fishing", "catchfish", "busy"},
        onenter = function(inst, build)
            inst.AnimState:PlayAnimation("fish_catch")
           -- print("Using ", build, " to swap out fish01")
            inst.AnimState:OverrideSymbol("fish01", build, "fish01")
            
            -- inst.AnimState:OverrideSymbol("fish_body", build, "fish_body")
            -- inst.AnimState:OverrideSymbol("fish_eye", build, "fish_eye")
            -- inst.AnimState:OverrideSymbol("fish_fin", build, "fish_fin")
            -- inst.AnimState:OverrideSymbol("fish_head", build, "fish_head")
            -- inst.AnimState:OverrideSymbol("fish_mouth", build, "fish_mouth")
            -- inst.AnimState:OverrideSymbol("fish_tail", build, "fish_tail")
        end,
        
        onexit = function(inst)
            inst.AnimState:ClearOverrideSymbol("fish01")
            -- inst.AnimState:ClearOverrideSymbol("fish_body")
            -- inst.AnimState:ClearOverrideSymbol("fish_eye")
            -- inst.AnimState:ClearOverrideSymbol("fish_fin")
            -- inst.AnimState:ClearOverrideSymbol("fish_head")
            -- inst.AnimState:ClearOverrideSymbol("fish_mouth")
            -- inst.AnimState:ClearOverrideSymbol("fish_tail")
        end,

        timeline=
        {
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishcaught") end),
            TimeEvent(10*FRAMES, function(inst) inst.sg:RemoveStateTag("fishing") end),
            TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishland") end),
            TimeEvent(24*FRAMES, function(inst)
                local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if equippedTool and equippedTool.components.fishingrod then
                    equippedTool.components.fishingrod:Collect()
                end
            end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")
            end ),
        },        
    },       
    
    State{
        name = "loserod",
        tags = {"busy"},
        onenter = function(inst)
            local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equippedTool and equippedTool.components.fishingrod then
                equippedTool.components.fishingrod:Release()
                equippedTool:Remove()
            end
            inst.AnimState:PlayAnimation("fish_nocatch")
        end,

        timeline=
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_lostrod") end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")
            end ),
        },        
    },       
    
    
   State{
        name = "eat",
        tags ={"busy"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            local is_gear = inst:GetBufferedAction() and inst:GetBufferedAction().invobject and inst:GetBufferedAction().invobject.components.edible and inst:GetBufferedAction().invobject.components.edible.foodtype == "GEARS"

            if not is_gear then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/eat", "eating")    
            end
            
            inst.AnimState:PlayAnimation("eat")
            inst.components.hunger:Pause()
        end,

        timeline=
        {
            
            TimeEvent(28*FRAMES, function(inst) 
                inst:PerformBufferedAction() 
            end),
            
            TimeEvent(30*FRAMES, function(inst) 
                inst.sg:RemoveStateTag("busy")
            end),
            
            TimeEvent(70*FRAMES, function(inst) 
	            inst.SoundEmitter:KillSound("eating")    
	        end),
            
        },        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
        
        onexit= function(inst)
            inst.SoundEmitter:KillSound("eating")    
            inst.components.hunger:Resume()
        end,
    },    
    
   State{
        name = "quickeat",
        tags ={"busy"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            local is_gear = inst:GetBufferedAction() and inst:GetBufferedAction().invobject and inst:GetBufferedAction().invobject.components.edible and inst:GetBufferedAction().invobject.components.edible.foodtype == "GEARS"
            if not is_gear then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/eat", "eating")    
            end
            inst.AnimState:PlayAnimation("quick_eat")
            inst.components.hunger:Pause()
        end,

        timeline=
        {
            TimeEvent(12*FRAMES, function(inst) 
                inst:PerformBufferedAction() 
                inst.sg:RemoveStateTag("busy")
            end),
        },        
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
        
        onexit= function(inst)
            inst.SoundEmitter:KillSound("eating")    
            inst.components.hunger:Resume()
        end,
    },    
        
    
   State{
        name = "talk",
        tags = {"idle", "talking"},
        
        onenter = function(inst, noanim)
            inst.components.locomotor:Stop()
            if not noanim then
                inst.AnimState:PlayAnimation("dial_loop", true)
            end
            
            if inst.talksoundoverride then
                 inst.SoundEmitter:PlaySound(inst.talksoundoverride, "talk")
            else
                local sound_name = inst.soundsname or inst.prefab
                inst.SoundEmitter:PlaySound("dontstarve/characters/"..sound_name.."/talk_LP", "talk")
            end

            inst.sg:SetTimeout(1.5 + math.random()*.5)
        end,
        
        ontimeout = function(inst)
            inst.SoundEmitter:KillSound("talk")
            inst.sg:GoToState("idle")
        end,
        
        onexit = function(inst)
            inst.SoundEmitter:KillSound("talk")
        end,
        
        events=
        {
            EventHandler("donetalking", function(inst) inst.sg:GoToState("idle") end),
        },
    }, 
    
   State{
        name = "mime",
        tags = {"idle", "talking"},
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            
            
            for k = 1, math.random(2,3) do
				local aname = "mime" .. tostring(math.random(8))
				if k == 1 then
					inst.AnimState:PlayAnimation(aname, false)
				else
					inst.AnimState:PushAnimation(aname, false)
				end
            end
        end,
        
        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },           

    State{
        name = "doshortaction",
        tags = {"doing", "busy"},
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickup")
            inst.sg:SetTimeout(6*FRAMES)
        end,
        
        
        timeline=
        {
            TimeEvent(4*FRAMES, function( inst )
                inst.sg:RemoveStateTag("busy")
            end),
            TimeEvent(10*FRAMES, function( inst )
            inst.sg:RemoveStateTag("doing")
            inst.sg:AddStateTag("idle")
            end),
        },
        
        ontimeout = function(inst)
            inst:PerformBufferedAction()
            
        end,
        
        events=
        {
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end ),
        },
    },
    
    
    State{
        name = "dolongaction",
        tags = {"doing", "busy"},
        
        timeline=
        {
            TimeEvent(4*FRAMES, function( inst )
                inst.sg:RemoveStateTag("busy")
            end),
        },
        
        onenter = function(inst, timeout)
            
            inst.sg:SetTimeout(timeout or 1)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make")
            
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end,
        
        ontimeout= function(inst)
            inst.AnimState:PlayAnimation("build_pst")
            inst.sg:GoToState("idle", false)
            inst:PerformBufferedAction()
        end,
        
        onexit= function(inst)
            inst.SoundEmitter:KillSound("make")
        end,
        
    },

    State{
        name = "makeballoon",
        tags = {"doing"},
        
        onenter = function(inst, timeout)
            
            inst.sg:SetTimeout(timeout or 1)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/common/balloon_make", "make")
            inst.SoundEmitter:PlaySound("dontstarve/common/balloon_blowup")
            
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end,
        
        ontimeout= function(inst)
            inst.AnimState:PlayAnimation("build_pst")
            inst.sg:GoToState("idle", false)
            inst:PerformBufferedAction()
        
        end,
        
        onexit= function(inst)
            inst.SoundEmitter:KillSound("make")
        end,
    },    
    
    State{
        name = "shave",
        tags = {"doing", "shaving"},
        
        onenter = function(inst)
            local timeout = 1
            inst.sg:SetTimeout(timeout)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/shave_LP", "shave")
            
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end,
        
        ontimeout = function(inst)
            inst:PerformBufferedAction()
            inst.AnimState:PlayAnimation("build_pst")
            inst.sg:GoToState("idle", false)
        end,
        
        onexit= function(inst)
            inst.SoundEmitter:KillSound("shave")
        end,
        
    },

   

    State{
        name = "enter_onemanband",
        tags = {"doing", "playing", "idle"},

        onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("idle_onemanband1_pre")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")
        end,

        onexit = function(inst)
        end,

        events = 
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("play_onemanband") end),
        },
    },

    State{
        name = "play_onemanband",
        tags = {"doing", "playing", "idle"},

        onenter = function(inst)

            inst.components.locomotor:Stop()
            --inst.AnimState:PlayAnimation("idle_onemanband1_pre")
            inst.AnimState:PlayAnimation("idle_onemanband1_loop")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")
        end,

        onexit = function(inst)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if math.random() <= 0.15 then
                    inst.sg:GoToState("play_onemanband_stomp") -- go into stomp
                else
                    inst.sg:GoToState("play_onemanband")-- loop state again
                end
            end),
        },
    },

    State{
        name = "play_onemanband_stomp",
        tags = {"doing", "playing", "idle"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("idle_onemanband1_pst")
            inst.AnimState:PushAnimation("idle_onemanband2_pre")
            inst.AnimState:PushAnimation("idle_onemanband2_loop")
            inst.AnimState:PushAnimation("idle_onemanband2_pst", false)  
            inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband") 
        end,

        onexit = function(inst)
        end,

        timeline=
        {
            TimeEvent(20*FRAMES, function( inst )
                inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")                
            end),

            TimeEvent(25*FRAMES, function( inst )
                inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")                
            end),
            
            TimeEvent(30*FRAMES, function( inst )
                inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")                
            end),

            TimeEvent(35*FRAMES, function( inst )
                inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")                
            end),
        },

        events = 
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle") 
            end),
        },
    },

    State{
        name = "play_flute",
        tags = {"doing", "playing"},
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("flute")
            inst.AnimState:OverrideSymbol("pan_flute01", "pan_flute", "pan_flute01")
            inst.AnimState:Hide("ARM_carry") 
            inst.AnimState:Show("ARM_normal")
            if inst.components.inventory.activeitem and inst.components.inventory.activeitem.components.instrument then
                inst.components.inventory:ReturnActiveItem()
            end
        end,
        
        onexit = function(inst)
            inst.SoundEmitter:KillSound("flute")
            if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                inst.AnimState:Show("ARM_carry") 
                inst.AnimState:Hide("ARM_normal")
            end
        end,
        
        timeline=
        {
            TimeEvent(30*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/flute_LP", "flute")
                inst:PerformBufferedAction()
            end),
            TimeEvent(85*FRAMES, function(inst)
                inst.SoundEmitter:KillSound("flute")
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
        name = "play_horn",
        tags = {"doing", "playing"},
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("horn")
            inst.AnimState:OverrideSymbol("horn01", "horn", "horn01")
            --inst.AnimState:Hide("ARM_carry") 
            inst.AnimState:Show("ARM_normal")
            if inst.components.inventory.activeitem and inst.components.inventory.activeitem.components.instrument then
                inst.components.inventory:ReturnActiveItem()
            end
        end,
        
        onexit = function(inst)
            if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                inst.AnimState:Show("ARM_carry") 
                inst.AnimState:Hide("ARM_normal")
            end
        end,
        
        timeline=
        {
            TimeEvent(21*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/horn_beefalo")
                inst:PerformBufferedAction()
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
        name = "book",
        tags = {"doing"},
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("book")
            inst.AnimState:OverrideSymbol("book_open", "player_actions_uniqueitem", "book_open")
            inst.AnimState:OverrideSymbol("book_closed", "player_actions_uniqueitem", "book_closed")
            inst.AnimState:OverrideSymbol("book_open_pages", "player_actions_uniqueitem", "book_open_pages")
            --inst.AnimState:Hide("ARM_carry") 
            inst.AnimState:Show("ARM_normal")
            if inst.components.inventory.activeitem and inst.components.inventory.activeitem.components.book then
                inst.components.inventory:ReturnActiveItem()
            end
            inst.SoundEmitter:PlaySound("dontstarve/common/use_book")
        end,
        
        onexit = function(inst)
            if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                inst.AnimState:Show("ARM_carry") 
                inst.AnimState:Hide("ARM_normal")
            end
            if inst.sg.statemem.book_fx then
                inst.sg.statemem.book_fx:Remove()
                inst.sg.statemem.book_fx = nil
            end
        end,
        
        timeline=
        {
            TimeEvent(0, function(inst)
                local fxtoplay = "book_fx"
                if inst.prefab == "waxwell" then
                    fxtoplay = "waxwell_book_fx" 
                end       
                local fx = SpawnPrefab(fxtoplay)
                local pos = inst:GetPosition()
                fx.Transform:SetRotation(inst.Transform:GetRotation())
                fx.Transform:SetPosition( pos.x, pos.y - .2, pos.z ) 
                inst.sg.statemem.book_fx = fx
            end),

            TimeEvent(58*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/book_spell")
                inst:PerformBufferedAction()
                inst.sg.statemem.book_fx = nil
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
        name = "blowdart",
        tags = {"attack", "notalking", "abouttoattack"},
        
        onenter = function(inst)
            inst.sg.statemem.target = inst.components.combat.target
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("dart")
            
            if inst.components.combat.target then
                if inst.components.combat.target and inst.components.combat.target:IsValid() then
                    inst:FacePoint(Point(inst.components.combat.target.Transform:GetWorldPosition()))
                end
            end
        end,
        
        timeline=
        {
            TimeEvent(8*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot")
            end),
            TimeEvent(10*FRAMES, function(inst)
                inst.sg:RemoveStateTag("abouttoattack")
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot")
            end),
            TimeEvent(20*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    
    State{
        name = "throw",
        tags = {"attack", "notalking", "abouttoattack"},
        
        onenter = function(inst)
            inst.sg.statemem.target = inst.components.combat.target
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("throw")
            
            if inst.components.combat.target then
                if inst.components.combat.target and inst.components.combat.target:IsValid() then
                    inst:FacePoint(inst.components.combat.target.Transform:GetWorldPosition())
                end
            end
            
        end,
        
        timeline=
        {
            TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
            TimeEvent(11*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    
    State{
        name = "catch_pre",
        tags = {"notalking", "readytocatch"},
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("catch_pre")
            inst:PerformBufferedAction()
            inst.sg:SetTimeout(2)
        end,
        
        ontimeout= function(inst)
            inst.sg:GoToState("idle")
        end,
        
        events=
        {
            EventHandler("catch", function(inst)
                inst.sg:GoToState("catch")
            end),
        },
    },
    
    State{
        name = "catch",
        tags = {"busy", "notalking"},
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("catch")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_catch")
        end,
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    
    State{
        name = "attack",
        tags = {"attack", "notalking", "abouttoattack", "busy"},
        
        onenter = function(inst)
		
			--DETECTS IF AIRBORN FOR AIREALS
			--local airial = inst.components.highjumper:IsJumping()    --GetFallingSpeed()
			local airial = inst.components.launchgravity:GetIsAirborn()
			
			--if airial and not airial == 0 then
			if airial then
				-- print("I BELEIVE I CAN FLY")
				inst.sg:RemoveStateTag("busy")
			else
				-- print("I CANT BELEIVE ITS NOT BUTTER")
				inst.components.locomotor:Stop()
				
			end
		
		
		
			--print(debugstack())
            inst.sg.statemem.target = inst.components.combat.target
            inst.components.combat:StartAttack()
            --inst.components.locomotor:Stop()  --MOVING UP THERE
            local weapon = inst.components.combat:GetWeapon()
            local otherequipped = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
				

            if weapon then
                inst.AnimState:PlayAnimation("atk")
				if weapon:HasTag("icestaff") then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_icestaff")
				elseif weapon:HasTag("shadow") then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_nightsword")
                elseif weapon:HasTag("firestaff") then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
                else
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
                end
            elseif otherequipped and (otherequipped:HasTag("light") or otherequipped:HasTag("nopunch")) then
                inst.AnimState:PlayAnimation("atk")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
            else
				inst.sg.statemem.slow = true
                inst.AnimState:PlayAnimation("punch")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
            end
            
            if inst.components.combat.target then
                inst.components.combat:BattleCry()
                if inst.components.combat.target and inst.components.combat.target:IsValid() then
                    inst:FacePoint(Point(inst.components.combat.target.Transform:GetWorldPosition()))
                end
            end
            
        end,
        
        timeline=
        {
            TimeEvent(8*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
            TimeEvent(12*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
			end),				
            TimeEvent(13*FRAMES, function(inst)
				if not inst.sg.statemem.slow then
					inst.sg:RemoveStateTag("attack")
				end
            end),
            TimeEvent(24*FRAMES, function(inst)
				if inst.sg.statemem.slow then
					inst.sg:RemoveStateTag("attack")
				end
            end),
            
            
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                --inst.sg:GoToState("idle")   --WHO NEEDS THIS? I DONT! PROBABLY
            end ),
        },
    },    
   
    
    
    State{
        name = "run_start",
        tags = {"moving", "running", "canrotate"},
        
        onenter = function(inst)
			inst.components.locomotor.throttle = 0
			inst.sg:GoToState("run") --WHY WAIT
			inst.components.locomotor:RunForward()
            --inst.AnimState:PlayAnimation("run_pre")
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
            end),
            
			TimeEvent(4*FRAMES, function(inst)
                PlayFootstep(inst)
                DoFoleySounds(inst)
            end),
        },        
        
    },

    State{
        
        name = "run",
        tags = {"moving", "running", "canrotate", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
		
			--inst.components.locomotor.throttle = 0.5
			-- inst.components.locomotor.throttle = 0
            inst.components.locomotor:RunForward()
            --inst.AnimState:PlayAnimation("run_loop")
			inst.AnimState:PlayAnimation("wickerrun")
			
			inst:PushEvent("swaphurtboxes", {preset = "walking"})
			--SET RUNSPEED TO ZERO
            
        end,
        
        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline=
        {
            TimeEvent(7*FRAMES, function(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
                DoFoleySounds(inst)
				--inst.components.locomotor.throttle = 1
            end),
            TimeEvent(15*FRAMES, function(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
                DoFoleySounds(inst)
            end),
        },
        
        events=
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("run") end ),        
        },
        
        
    },
    
    State{
    
        name = "run_stop",
        tags = {"canrotate", "idle", "candash"}, --@@ ADDED BUSY --NAH
        
        onenter = function(inst) 
            -- inst.components.locomotor:Stop()   --@@@@@ OH THIS COULD BE BAD  --6 MONTHS LATER, IM TAKING IT AWAY
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
            EventHandler("animover", function(inst)
				-- inst:PushEvent("dash") 
				--inst.sg:GoToState("dash")
				
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
        },
        
        
    },
	
	
	State{
        
        name = "dash_stop",
        tags = {"canrotate", "dashing", "busy", "sliding", "can_special_attack", "can_ood", "can_jump", "keylistener", "keylistener2"}, --, "candash"
        
        onenter = function(inst) 
			inst.AnimState:PlayAnimation("dash_pst")
			inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1, 1, 0.5, 0.8, 10, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
            
        end,

        timeline=
        {
			-- TimeEvent(1*FRAMES, function(inst) inst:PushEvent("dash_stop") end), --1-8 REPLACING ALL THESE WEIRD EVENT PUSHERS WITH KEY LISTENER EVENT HANDLERS
			-- TimeEvent(2*FRAMES, function(inst) inst:PushEvent("dash_stop") end),
			-- TimeEvent(3*FRAMES, function(inst) inst:PushEvent("dash_stop") end),
			
			TimeEvent(4*FRAMES, function(inst)
				-- inst:PushEvent("dash_stop")
				inst.sg:RemoveStateTag("keylistener")
				inst.sg:RemoveStateTag("can_ood")
				
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
			TimeEvent(8*FRAMES, function(inst)
				inst.sg:AddStateTag("candash")
				if inst.components.keydetector:GetForward(inst) then --LETS TRY THIS ONE... NICELY DONE, ME! WHY THANK YOU, ME
					inst:PushEvent("dash")
				end
            end),
            TimeEvent(10*FRAMES, function(inst)
				inst.sg:GoToState("idle")
            end),
        },    
    },

   
    State{
        name="item_hat",
        tags = {"idle"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("item_hat")
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },    
    State{
        name="item_in",
        tags = {"idle"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("item_in")
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },    
    State{
        name="item_out",
        tags = {"idle"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("item_out")
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },    


    State{
        name = "give",
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("give") 
        end,
        
        timeline =
        {
            TimeEvent(13*FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },        

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },   
    
	State{
        name = "bedroll",
        
		--tags = {"busy"},

        onenter = function(inst)
            inst.components.playercontroller:Enable(false)
            inst.components.locomotor:Stop()
            inst.components.health:SetInvincible(true)
			if GetClock():IsDay() then

                local tosay = "ANNOUNCE_NODAYSLEEP"
                if GetWorld():IsCave() then
                    tosay = "ANNOUNCE_NODAYSLEEP_CAVE"
                end

				inst.sg:GoToState("idle")
				inst.components.talker:Say(GetString(inst.prefab, tosay))
				return
			end
		
	
			local danger = FindEntity(inst, 10, function(target) return target:HasTag("monster") or target.components.combat and target.components.combat.target == inst end)
            local hounded = GetWorld().components.hounded

			if hounded and (hounded.warning or hounded.timetoattack <= 0) then
				danger = true
			end
			if danger then
				inst.sg:GoToState("idle")
				inst.components.talker:Say(GetString(inst.prefab, "ANNOUNCE_NODANGERSLEEP"))
				return
			end

			-- you can still sleep if your hunger will bottom out, but not absolutely
			if inst.components.hunger.current < TUNING.CALORIES_MED then
				inst.sg:GoToState("idle")
				inst.components.talker:Say(GetString(inst.prefab, "ANNOUNCE_NOHUNGERSLEEP"))
				return
			end
            
            inst.AnimState:PlayAnimation("bedroll")
             
        end,
        
        onexit = function(inst)
            inst.components.health:SetInvincible(false)
            inst.components.playercontroller:Enable(true)
        	inst.AnimState:ClearOverrideSymbol("bedroll")          
        end,
        
        
        timeline=
        {
            TimeEvent(20*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/wilson/use_bedroll")
            end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) 
                if GetClock():IsDay() then
                    local tosay = "ANNOUNCE_NODAYSLEEP"
                    if GetWorld():IsCave() then
                        tosay = "ANNOUNCE_NODAYSLEEP_CAVE"
                    end
                    inst.sg:GoToState("wakeup")
                    inst.components.talker:Say(GetString(inst.prefab, tosay))
                    return
                elseif inst:GetBufferedAction() then
                    inst:PerformBufferedAction() 
                else
                    inst.sg:GoToState("wakeup")
                end

                end ),
        },
    },       

    
    State{
        name = "hit",
        tags = {"busy", "inknockback", "no_air_transition", "nolandingstop", "ignore_ledge_barriers", "noairmoving"},
        
        onenter = function(inst, hitstun)
			inst.AnimState:PlayAnimation("flinch2")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			
			if ISGAMEDST and not TheWorld.ismastersim then --11-26-17
				return --CLIENTS DONT RUN BELOW THIS LINE
			end
			
			local cancel_modifier = hitstun 
			inst.task_hitstun = inst:DoTaskInTime((hitstun*FRAMES), function(inst) 
				inst.sg:RemoveStateTag("noairmoving")
				inst.sg:AddStateTag("can_jump")
				inst.sg:AddStateTag("can_attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
				-- inst.AnimState:SetMultColour(1,1,0.5,1)
				inst.components.visualsmanager:Blink(inst, 2,   1, 0, 1,   0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
				
				if trainbehavior == "evade" then
					inst.sg:GoToState("doublejump")
				end
			end)
            inst:ClearBufferedAction()     
        end,
		
		onexit = function(inst)
			if ISGAMEDST and TheWorld.ismastersim then --11-26-17
				inst.task_hitstun:Cancel()
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
        name = "toolbroke",
        tags = {"busy"},
        onenter = function(inst, tool)
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_break")
            inst.AnimState:Hide("ARM_carry") 
            inst.AnimState:Show("ARM_normal") 
            local brokentool = SpawnPrefab("brokentool")
            brokentool.Transform:SetPosition(inst.Transform:GetWorldPosition() )
            inst.sg.statemem.tool = tool
        end,
        
        onexit = function(inst)
		    local sameTool = inst.components.inventory:FindItem(function(item)
		        return item.prefab == inst.sg.statemem.tool.prefab
		    end)
		    if sameTool then
		        inst.components.inventory:Equip(sameTool)
		    end

            if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                inst.AnimState:Show("ARM_carry") 
                inst.AnimState:Hide("ARM_normal")
            end

        end,
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end ),
        },
    },
    
    State{
        name = "armorbroke",
        tags = {"busy"},
        onenter = function(inst, armor)
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_armour_break")
            inst.sg.statemem.armor = armor
        end,
        
        onexit = function(inst)
		    local sameArmor = inst.components.inventory:FindItem(function(item)
		        return item.prefab == inst.sg.statemem.armor.prefab
		    end)
		    if sameArmor then
		        inst.components.inventory:Equip(sameArmor)
		    end
        end,
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end ),
        },
    },
    
	State{
        name = "teleportato_teleport",
        tags = {"busy"},
		onenter = function(inst)
            inst.components.locomotor:StopMoving()
			inst.components.playercontroller:Enable(false)
			inst.components.health:SetInvincible(true)
			inst.AnimState:PlayAnimation("teleport")
			TheCamera:SetDistance(20)
			inst.HUD:Hide()
		end,

        onexit = function(inst)
            inst.HUD:Show()
            inst.components.playercontroller:Enable(true)
            inst.components.health:SetInvincible(false)
        end,

		timeline = {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_pulled")
			end),
			TimeEvent(82*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_under")
			end),
		},
	},
        
	State{
        name = "amulet_rebirth",
        tags = {"busy"},
        onenter = function(inst)
			GetClock():MakeNextDay()
			inst.components.playercontroller:Enable(false)
            inst.AnimState:PlayAnimation("amulet_rebirth")
            TheCamera:SetDistance(14)
            inst.HUD:Hide()
            inst.AnimState:OverrideSymbol("FX", "player_amulet_resurrect", "FX")
        end,
        
        onexit= function(inst)
			inst.components.hunger:SetPercent(2/3)
			inst.components.health:Respawn(TUNING.RESURRECT_HEALTH)
	        
	        if inst.components.sanity then
				inst.components.sanity:SetPercent(.5)
			end
			
			local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
			if item and item.prefab == "amulet" then
				item = inst.components.inventory:RemoveItem(item)
				if item then
					item:Remove()
					item.persists = false
				end
			end
			--SaveGameIndex:SaveCurrent()
			inst.HUD:Show()
			TheCamera:SetDefault()
			inst.components.playercontroller:Enable(true)
            inst.AnimState:ClearOverrideSymbol("FX")
			
        end,
        
		timeline =
        {
            TimeEvent(0*FRAMES, function(inst)
                inst.stafflight = SpawnPrefab("staff_castinglight")
                local pos = inst:GetPosition()
                local colour = {150/255, 46/255, 46/255}
                inst.stafflight.Transform:SetPosition(pos.x, pos.y, pos.z)
                inst.stafflight.setupfn(inst.stafflight, colour, 1.7, 1)           

            end),

			TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/rebirth_amulet_raise") end),
			TimeEvent(60*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/rebirth_amulet_poof") end),
        
            TimeEvent(80*FRAMES, function(inst)
				local pos = Vector3(inst.Transform:GetWorldPosition())
				local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, 10)
				for k,v in pairs(ents) do
					if v ~= inst and v.components.sleeper then
						v.components.sleeper:GoToSleep(20)
					end
				end
				
				
            end),
        },        
                   
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },    


    State{
        name = "jumpin",
        tags = {"doing", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("jump")

			inst:DoTaskInTime(4.7, function(inst) inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt", "bodyfall") end )
        end,
        
		timeline =
        {
			-- this is just hacked in here to make the sound play BEFORE the player hits the wormhole
			TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/teleportworm/travel", "wormhole_travel") end),
		},

        events=
        {
            EventHandler("animover", function(inst)
				inst:PerformBufferedAction()
				inst.sg:GoToState("idle") 
			end ),
        },
    },

    State{
        name = "castspell",
        tags = {"doing", "busy", "canrotate"},

        onenter = function(inst)
            inst.components.playercontroller:Enable(false)
            inst.AnimState:PlayAnimation("staff") 
            local colourizefx = function(staff)
                return staff.fxcolour or {1,1,1}
            end
            inst.components.locomotor:Stop()
            --Spawn an effect on the player's location
            inst.stafffx = SpawnPrefab("staffcastfx")            

            local pos = inst:GetPosition()
            local staff = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.stafffx.Transform:SetPosition(pos.x, pos.y, pos.z)
            local colour = colourizefx(staff)

            inst.stafffx.Transform:SetRotation(inst.Transform:GetRotation())
            inst.stafffx.AnimState:SetMultColour(colour[1], colour[2], colour[3], 1)
        end,

        onexit = function(inst)
            inst.components.playercontroller:Enable(true)
            if inst.stafffx then
                inst.stafffx:Remove()
            end
        end,

        timeline = 
        {
            TimeEvent(13*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/use_gemstaff") 
            end),
            TimeEvent(0*FRAMES, function(inst)
                inst.stafflight = SpawnPrefab("staff_castinglight")
                local staff = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                local pos = inst:GetPosition()
                local colour = staff.fxcolour or {1,1,1}
                inst.stafflight.Transform:SetPosition(pos.x, pos.y, pos.z)
                inst.stafflight.setupfn(inst.stafflight, colour, 1.9, .33)                

            end),
            TimeEvent(53*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle") 
            end ),
        },

    },

    State{
        name = "werebeaver",
        tags = {"busy"},
        onenter = function(inst)
			inst.components.beaverness.doing_transform = true
            inst.Physics:Stop() 
            inst.components.playercontroller:Enable(false)           
            inst.AnimState:PlayAnimation("transform_pre")
            inst.components.health:SetInvincible(true)
        end,
        
        onexit = function(inst)
			if not inst.components.beaverness:IsBeaver() then
				inst.components.beaverness.makebeaver(inst)
			end
			inst.components.health:SetInvincible(false)
			inst.components.playercontroller:Enable(true)
			inst.components.beaverness.doing_transform = false
        end,

        events =
        {
            EventHandler("animover", function(inst)
	            inst.components.beaverness.makebeaver(inst)
                inst.sg:GoToState("transform_pst")
            end ),
        } 
    },   

    State{
        name = "quicktele",
        tags = {"doing", "busy", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("atk")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
        end,

        timeline = 
        {
            TimeEvent(8*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle") 
            end ),
        },
    }, 
	--[[
	State{
        name = "attack",  --warrior_
        tags = {"attack", "canrotate", "busy", "jumping"},
        
        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.components.combat:StartAttack()
            --inst.AnimState:PlayAnimation("warrior_atk")
            inst.sg.statemem.target = target
        end,

        onexit = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
        end,
        
        timeline =
        {
            --TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt")) end),
            --TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Jump")) end),
            TimeEvent(8*FRAMES, function(inst) inst.Physics:SetMotorVelOverride(20,0,0) end),
           -- TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
            TimeEvent(19*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
            TimeEvent(20*FRAMES,
				function(inst)
                    inst.Physics:ClearMotorVelOverride()
					inst.components.locomotor:Stop()
				end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
	]]--
	
	State{
        name = "highjump",  --warrior_
        tags = {"canrotate"},  --"attack", "busy", "jumping"
        
        onenter = function(inst, target)
            --inst.components.locomotor:Stop()
            --inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            --inst.components.combat:StartAttack()
            --inst.AnimState:PlayAnimation("warrior_atk")
            --inst.sg.statemem.target = target
        end,

        onexit = function(inst)
            --inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
        end,
        
        timeline =
        {
            --TimeEvent(0*FRAMES, function(inst) self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0) end),
			TimeEvent(0*FRAMES, function(inst) inst.Physics:SetMotorVel((10 + 1) * 1, 0, 10) end),
			
			TimeEvent(10*FRAMES, function(inst) inst.Physics:SetMotorVel((10 + 1) * 1, 0, 5) end),
			TimeEvent(20*FRAMES, function(inst) inst.Physics:SetMotorVel((10 + 1) * 1, 0, 0) end),
			TimeEvent(30*FRAMES, function(inst) inst.Physics:SetMotorVel((10 + 1) * 1, 0, -5) end),
			TimeEvent(40*FRAMES, function(inst) inst.Physics:SetMotorVel((10 + 1) * 1, 0, -10) end),
			
            -- --TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Jump")) end),
            -- TimeEvent(8*FRAMES, function(inst) inst.Physics:SetMotorVelOverride(20,0,0) end),
           -- -- TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
            -- TimeEvent(19*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
			
            TimeEvent(50*FRAMES,
				function(inst)
                    inst.Physics:ClearMotorVelOverride()
					--inst.components.locomotor:Stop()
				end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
	
	State{
        name = "jump", 
        tags = {"jumping"}, 
        
        onenter = function(inst, target)
			--inst.AnimState:PlayAnimation("ll_med_002")
			--WHY DID I MAKE THIS STATE?
        end,
        
        timeline =
        {
			TimeEvent(2*FRAMES, function(inst) 
				inst:PushEvent("jump")
				inst.components.jumper:Jump(inst)
			end),
        },
        
    },
	
	
	State{
        name = "idle_air",
        tags = {"can_grab_ledge"}, --idle
        onenter = function(inst, pushanim)
		
		--00000000000000 WAIT WHY DID I MAKE TWO OF THESE
		
		inst.AnimState:PlayAnimation("idle")
            
            --inst.components.locomotor:Stop()   --@@@@@ REMOVING

            -- local equippedArmor = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)

            -- -- if equippedArmor and equippedArmor:HasTag("shell") then
            -- --     inst.sg:GoToState("shell_enter")
            -- --     return
            -- -- end
            
    -- --         local equippedHat = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    -- --         if equippedHat and equippedHat:HasTag("hide") then
				-- -- inst.sg:GoToState("hide")
				-- -- return
    -- --         end
            

            -- if equippedArmor and equippedArmor:HasTag("band") then
                -- inst.sg:GoToState("enter_onemanband")
                -- return
            -- end

            -- local anims = {}
            
            -- local anim = "idle_loop"
            
            -- if not inst.components.sanity:IsSane() then
				-- table.insert(anims, "idle_sanity_pre")
				-- table.insert(anims, "idle_sanity_loop")
            -- elseif inst.components.temperature:IsFreezing() then
				-- table.insert(anims, "idle_shiver_pre")
				-- table.insert(anims, "idle_shiver_loop")
            -- else
				-- table.insert(anims, "idle_loop")
            -- end
            
            -- if pushanim then
                -- for k,v in pairs (anims) do
					-- inst.AnimState:PushAnimation(v, k == #anims)
				-- end
            -- else
                -- inst.AnimState:PlayAnimation(anims[1], #anims == 1)
                -- for k,v in pairs (anims) do
					-- if k > 1 then
						-- inst.AnimState:PushAnimation(v, k == #anims)
					-- end
				-- end
            -- end
            
            -- inst.sg:SetTimeout(math.random()*4+2)
        end,
        
        -- ontimeout= function(inst)
            -- inst.sg:GoToState("funnyidle")
        -- end,
    },
	
	State{
        name = "grab_ledge",
		tags = {"busy", "hanging", "no_running", "nolandingstop"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_grab")
			inst.SoundEmitter:PlaySound("smash_sounds/grab/grab1") --12-16-18 -NEW GRAB SOUND
			
			inst:ForceFacePoint(ledgeref.Transform:GetWorldPosition())
			local x, y, z = ledgeref.Transform:GetWorldPosition()
			inst.Transform:SetPosition( x-(0.25*inst.components.launchgravity:GetRotationValue()), y-0, z ) -- -1.5
			
			inst:PushEvent("swaphurtboxes", {preset = "ledge_hanging"})
			inst.components.hurtboxes:SpawnTempHurtbox(-0.2, -0.1, 0.6, 0, 140)  --(xpos, ypos, size, ysize, frames, property)
			inst.components.hitbox:MakeFX("glint_ring_1", -0.1, -0.1, 0.2,   0.8, 0.8,   0.5, 5, 0.8,  0, 0, 0) 
			
			inst.components.launchgravity:Launch(0, 0, 0) --3-17 SO YOU DONT RESUME PREVIOUS MOMENTUM
			inst.Physics:SetActive(false) --CAREFUL WITH THIS
        end,
		
		onexit = function(inst)
			inst.Physics:SetActive(true) 
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
			TimeEvent(15*FRAMES, function(inst)
				inst.components.launchgravity:Launch(0, 0, 0)			
				inst.Physics:SetActive(true)
				inst.Physics:SetActive(false) 
			end),
			TimeEvent(31*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
			end),
			TimeEvent(25*FRAMES, function(inst)  --JUST PULL YOURSELF AUTOMATICALLY
				inst.sg:GoToState("ledge_getup") 
			end),
			-- TimeEvent(140*FRAMES, function(inst) 
				-- -- print("NEW SELF COORDINATES", inst.Transform:GetWorldPosition())
				-- inst.sg:GoToState("ledge_drop")
			-- end),
		},
		
		events=
        {
            -- EventHandler("jump", function(inst)
				-- inst.sg:GoToState("ledge_jump") 
			-- end ),
			-- EventHandler("forward_key", function(inst)
				-- inst.sg:GoToState("ledge_getup") 
			-- end ),
			-- EventHandler("backward_key", function(inst)
				-- inst.sg:GoToState("ledge_drop") 
			-- end ),
			-- EventHandler("down", function(inst)
				-- inst.sg:GoToState("ledge_drop") 
			-- end ),
			-- EventHandler("block_key", function(inst)
				-- inst.sg:GoToState("ledge_roll") 
			-- end ),
			-- EventHandler("attack_key", function(inst)
				-- inst.sg:GoToState("ledge_attack") 
			-- end ),
        },
    },
	
	State{
        name = "ledge_getup",
		tags = {"busy", "intangible", "nolandingstop", "no_running"},
        
        onenter = function(inst, ledgeref)
			-- inst.AnimState:PlayAnimation("ledge_getup") --NOT YET! THIS ANIMATION IS TOO FAST
			inst.Physics:SetActive(false) --CAREFUL WITH THIS
        end,
		
		onexit = function(inst)
			-- inst.AnimState:PlayAnimation("duck_000")
			-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			inst.Physics:SetActive(true) 
        end,
        
		timeline =
        {
			-- TimeEvent(8*FRAMES, function(inst)
				-- inst.Physics:SetActive(true)
				-- inst.components.jumper:ScootForward(8)
				-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			-- end),
			
			-- TimeEvent(5*FRAMES, function(inst)
				-- inst.Physics:SetActive(true)
				-- inst.components.jumper:ScootForward(8)
				-- inst:PushEvent("swaphurtboxes", {preset = "idle"})
			-- end),
			
			TimeEvent(6*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("ledge_getup")
				inst.components.hitbox:Blink(inst, 2,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			end),
			
			-- TimeEvent(7*FRAMES, function(inst)
				-- inst.Physics:SetActive(true)
				-- inst.components.jumper:ScootForward(8)
				-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			-- end),
			
			TimeEvent(10*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				inst.components.jumper:ScootForward(8)
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			
			TimeEvent(15*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
				-- inst.Physics:SetActive(true)
			end),
			TimeEvent(16*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
		},
		
		events=
        {
            EventHandler("animover", function(inst) inst.AnimState:PlayAnimation("meat_idle") end),
        },
		
    },
	
	
	State{
        name = "ledge_drop",
		tags = {"hanging"},
        
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
				inst.components.launchgravity:Launch(5, 18, 0)
				inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			end),
			TimeEvent(6*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
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
		
		onexit = function(inst)
			inst.Physics:SetActive(true)
			if inst.task_1 then
				inst.task_1:Cancel()
			end
        end,
        
		timeline =
        {
			TimeEvent(6*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				inst.AnimState:PlayAnimation("rolling")
				inst.components.locomotor:RunForward() --11-11-17 LETS SEE IF THIS FIXES THE WONKY GETUP ROLLS
				-- inst.components.jumper:ScootForward(10)
				inst.task_1 = inst:DoPeriodicTask(0.1, function(inst)
						inst.Physics:SetMotorVel(12, 0, 0)
					end)
			end),
			TimeEvent(15*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
				-- inst.sg:GoToState("air_idle")
			end),
			TimeEvent(16*FRAMES, function(inst)
				inst.task_1:Cancel()
			end),
			TimeEvent(25*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
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
			
			TimeEvent(10*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
				-- inst.components.jumper:ScootForward(8)
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
				inst.components.hitbox:SetLingerFrames(1)
				
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0)
				inst.components.hitbox:SpawnHitbox(2.0, 0.5, 0) 
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
		tags = {"can_usmash", "can_upspec", "no_running", "no_blocking"}, 
        
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
			TimeEvent(1*FRAMES, function(inst) 
				inst.components.jumper:Jump(inst)
				-- inst.sg:RemoveStateTag("busy") 
				inst.sg:RemoveStateTag("can_usmash")
			end),
			TimeEvent(3*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy") 
				inst.components.jumper:CheckForFullHop()
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
			EventHandler("throwspecial", function(inst)
				if inst.components.keydetector:GetUp(inst) then
					inst.sg:GoToState("uspecial")
				end
			end ),
        },
    },
	
	State{
        name = "doublejump",
		tags = {"jumping", "nojumping"},
        
        onenter = function(inst)
			-- inst.AnimState:PlayAnimation("jump_maybe_001")
			inst.AnimState:PlayAnimation("flinch2")
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
        tags = {"busy", "tumbling", "noairmoving", "di_movement_only", "no_air_transition", "ignore_ledge_barriers", "reeling"}, --"noairmoving" --NAH PUTTING THIS BACK IN I THINK I NEED IT --1-8
        
        onenter = function(inst, hitstun, direction)
			
			if ISGAMEDST and not TheWorld.ismastersim then --11-26-17
				return --CLIENTS DONT RUN BELOW THIS LINE
			end
			
			local angle = inst.components.launchgravity:GetAngle() * DEGREES
			
			if inst.components.launchgravity:GetAngle() <= 50 then
				inst.AnimState:PlayAnimation("tumble_back")
			elseif inst.components.launchgravity:GetAngle() >= 240 and inst.components.launchgravity:GetAngle() <= 300 then
				inst.AnimState:PlayAnimation("tumble_down")
			else
				inst.AnimState:PlayAnimation("tumble_up_000")
			end
			
			
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
				inst.sg:AddStateTag("can_attack")
				inst.components.visualsmanager:Blink(inst, 4,   1, 0, 1,   0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
			
				
				--3-15 GONNA TRY AND ADD SOMETHING THAT CANCELS OUT MOMENTUM SO YOU ARENT FORCED TO JUMP TO SURVIVE
				-- inst.components.hitbox:MakeFX("glint_ring_1", -0.1, -0.1, 0.2,   1.5, 1.5,   0.5, 20, 0.8,  0, 0, 0) 
				inst.components.jumper:AirStall(2, 1)
				
				if trainbehavior == "evade" then
					inst.sg:GoToState("doublejump")
				end
			end)
			
			inst.task_dodgestun = inst:DoTaskInTime((dodge_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:RemoveStateTag("busy")
				inst.sg:RemoveStateTag("reeling") --10-20-18 TREAT ALL PLAYER GRAVITIES THE SAME WHILE REELING!
				
			end)
        end,

        onexit = function(inst)
			
			if ISGAMEDST and TheWorld.ismastersim then 
				inst.task_hitstun:Cancel()
				inst.task_dodgestun:Cancel()
			end
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline =
        {
			TimeEvent(3*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "hitstun1"})
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
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0, 0.35)
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(0, -0.35)
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
		
		onexit = function(inst)
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline =
        {
		
			TimeEvent(2*FRAMES, function(inst)
				inst.sg:RemoveStateTag("nogetup")
				inst.AnimState:SetMultColour(1,0.5,1,1)
				if trainbehavior == "evade" then
					inst:PushEvent("forward_key")
				end
			end),
				
			TimeEvent(6*FRAMES, function(inst)
				inst.AnimState:SetMultColour(1,1,1,1)
			end),

            TimeEvent(25*FRAMES, function(inst) --60
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
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(90)
				inst.components.hitbox:SetSize(2)
				
				inst.components.hitbox:SpawnHitbox(1, 0, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(2)
				
				inst.components.hitbox:SpawnHitbox(-1, 0, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			end),
			
            TimeEvent(25*FRAMES, function(inst) 
			-- inst.sg:RemoveStateTag("attack") 
			-- inst.sg:RemoveStateTag("busy")
			inst.sg:GoToState("idle")
			
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
				inst.AnimState:PlayAnimation("meat_idle")
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
				inst.AnimState:PlayAnimation("tech0_003")
				inst.AnimState:SetTime(2*FRAMES)
				inst.components.hitbox:MakeFX("slide1", -0.8, 0, 1, 1.5, 1.5, 1, 10, 0)
			end),
		   
		    TimeEvent(12*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst.AnimState:SetMultColour(1,1,1,1)
				
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
	
	
	-- State{
        -- name = "tech_backward_roll", 
        -- tags = {"busy", "intangible", "teching"},
        
        -- onenter = function(inst, target)
            -- inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
			-- --inst.AnimState:PlayAnimation("pickaxe_pre")
			-- inst.AnimState:PlayAnimation("backward_tech")
			-- --inst:AddTag("rolling")
        -- end,

        -- onexit = function(inst)
			-- inst.AnimState:SetMultColour(1,1,1,1)
			-- --inst:RemoveTag("rolling")
			-- inst.task_2:Cancel()
        -- end,
        
        -- timeline =
        -- {
		   
			 -- TimeEvent(2*FRAMES, function(inst)
				-- --inst:AddTag("rolling")
				-- inst.sg:AddStateTag("intangible")
				-- -- inst.task_2 = inst:DoPeriodicTask(0.1, function(inst)
						-- -- inst.Physics:SetMotorVel(-10, 0, 0)
					
				-- -- end)
		     -- end),
		   
			-- TimeEvent(5*FRAMES, function(inst)
				-- inst.task_2 = inst:DoPeriodicTask(0.1, function(inst)
						-- inst.Physics:SetMotorVel(-10, 0, 0)
					
				-- end)
		     -- end),
			 
			-- TimeEvent(12*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("intangible")
				-- inst.AnimState:SetMultColour(1,1,1,1)
				
				
			-- end),
			-- TimeEvent(17*FRAMES, function(inst) 
				-- inst.task_2:Cancel()
				-- inst.AnimState:PlayAnimation("tech0_003")
				-- inst.components.hitbox:MakeFX("slide1", -0.8, 0, 1, 1.5, 1.5, 1, 10, 0)
				
			-- end),
            
			-- TimeEvent(35*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("busy")
				-- inst.sg:GoToState("idle")
			-- end),
		-- },
        
    -- },
	
	
	State{
        name = "ll_medium_getup",
        tags = {"busy"}, 
        
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
				inst.sg:GoToState("idle")
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

        events=
        {
            EventHandler("animover", function(inst)
				--inst.sg:GoToState("idle") 
			end ),
        },
    },
	
	
	--ANOTHER DITTO
	-- State{
        -- name = "grounded", 
        -- tags = {"busy", "cangetup", "intangible"},
        
        -- onenter = function(inst, target)
            -- inst.AnimState:SetMultColour(1,1,1,0.3)
			-- inst.AnimState:PlayAnimation("grounded")
			-- inst:AddTag("grounded")
        -- end,

        -- onexit = function(inst)
			-- inst.AnimState:SetMultColour(1,1,1,1)
			-- inst:RemoveTag("grounded")
        -- end,
        
        -- timeline =
        -- {
			-- TimeEvent(20*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("intangible")
				-- inst.AnimState:SetMultColour(1,1,1,1)
			-- end),
			
            -- TimeEvent(50*FRAMES,
				-- function(inst)
					-- inst.sg:GoToState("getup")
				-- end),
        -- },
        
    -- },
	
	State{
        name = "block_startup", 
        tags = {"busy", "tryingtoblock", "blocking", "can_parry", "canoos"},
        
        onenter = function(inst, target)
			--inst.AnimState:PlayAnimation("build_pre")
			inst.AnimState:PlayAnimation("wicker_block_startup")
			
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
        tags = {"blocking", "tryingtoblock", "busy", "block_stunned"},  --"attack", "busy", "jumping"
        
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
        tags = {"blocking", "tryingtoblock", "busy"},  --"attack", "busy", "jumping"
        
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
            
			TimeEvent(300*FRAMES, function(inst)
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
                    inst.sg:RemoveStateTag("busy")
					-- inst.sg:GoToState("idle")
				end),
        },
        
    },
	
	
	State{
        name = "airdodge",
        tags = {"dodging", "busy", "airdodging", "ll_medium"}, 
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("spotdodge")
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
        name = "grab",  --warrior_
        tags = {"busy", "grabbing"},  --"attack", "busy", "jumping"
        
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
				inst.components.hitbox:SetSize(0.5) --0.5 
				inst.components.hitbox:SetLingerFrames(20)
			
				inst.components.hitbox:SpawnGrabbox(1, 1, 0)  --1,1,0
				-- inst.components.hitbox:SpawnGrabbox(5, 6, 0)
				-- inst.components.hurtboxes:SpawnPlayerbox(8, 4, 3, 6, 0)  --1,1,2
				-- inst.components.hurtboxes:CreateHurtbox(4, 4, 4.2)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(8)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetDamage(7)   --7
				inst.components.hitbox:SetSize(4, 4)
				inst.components.hitbox:SetLingerFrames(20)

				-- inst.components.hitbox:SpawnHitbox(4, 4, 0) 
				
				-- inst.components.hitbox:SetSize(4)
				-- inst.components.hitbox:SpawnHitbox(4, 4, 0) 
				
				-- inst.components.hurtboxes:SpawnTempHurtbox(4, 4, 1, 1, 140)  --(xpos, ypos, size, ysize, frames, property)
				
				-- inst.components.hurtboxes:SpawnPlayerbox(4, 0, 0.25, 0.5, 0)
				
				
				
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
        name = "grabbing",  --warrior_
        tags = {"busy", "grabbing"},  --"attack", "busy", "jumping"
        
        onenter = function(inst, target)
            --inst.components.locomotor:Stop()
			--inst.AnimState:PlayAnimation("give")
			inst.AnimState:PlayAnimation("grabbing")
						--inst.SoundEmitter:PlaySound("dontstarve/common/break_iceblock")
			-- inst.SoundEmitter:PlaySound("dontstarve/wilson/use_break")
			-- inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_linebreak")
			-- inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_straw")
			inst.SoundEmitter:PlaySound("smash_sounds/grab/grab1")
			inst.components.stats.opponent.Physics:SetActive(false)
        end,
		
		onexit = function(inst)
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
				inst.components.stats.opponent.sg:GoToState("rebound", 10)
			end),
        },
    },
	
	
	State{
        name = "grabbed",  --warrior_
        tags = {"busy", "nolandingstop"},  --"attack", "busy", "jumping"
        
        onenter = function(inst, target)
            --inst.components.locomotor:Stop()
            --inst.AnimState:PlayAnimation("chop_pre")
			--inst.AnimState:PlayAnimation("idle_shiver_pre")
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
        tags = {"attack", "busy"},
        
        onenter = function(inst, target)
			inst.components.stats:GetOpponent()
			inst.AnimState:PlayAnimation("throwing_000")
			inst.AnimState:Resume()
        end,
        
        timeline =
        {
            --TimeEvent(0*FRAMES, function(inst) self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0) end),
			
			TimeEvent(8*FRAMES, function(inst)   --16
				inst.components.stats:GetOpponent()
				inst.components.stats.opponent.AnimState:PlayAnimation("clumsy_land")
			end),
			
			TimeEvent(1*FRAMES, function(inst)   --16
				local pos = Vector3(inst.Transform:GetWorldPosition())
				inst.components.stats.opponent.Transform:SetPosition((pos.x), (pos.y + 1.5), (pos.z))  -- + self.zoffset
				--self.inst.AnimState:Resume()
				--self.inst.sg:GoToState("throw")
				inst.components.stats.opponent.sg:GoToState("thrown")
				inst.components.stats.opponent.components.launchgravity:Launch(-2, -4, 0)
			end),

			
			
			TimeEvent(12*FRAMES, function(inst)   --16
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
			
			TimeEvent(30*FRAMES, function(inst)   --16
				inst.sg:GoToState("idle") 
			end),
			
        },
        
        events=
        {
            EventHandler("on_hitted", function(inst)
				inst.components.stats.opponent.sg:GoToState("rebound", 10)
			end),
        },
    },
	
	State{
        name = "bthrow",
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst, target)
			
			inst.components.stats:GetOpponent()
			inst.AnimState:PlayAnimation("wickerbthrow")
			inst.AnimState:Resume()
			
			-- inst.components.locomotor:TurnAround()
			-- inst.components.stats.opponent.components.locomotor:TurnAround()
        end,
        
        timeline =
        {
            --TimeEvent(0*FRAMES, function(inst) self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0) end),
			
			TimeEvent(8*FRAMES, function(inst)   --16
				inst.components.stats:GetOpponent()
				-- inst.components.stats.opponent.AnimState:PlayAnimation("clumsy_land")
			end),
			
			TimeEvent(7*FRAMES, function(inst)   --16
				-- local pos = Vector3(inst.Transform:GetWorldPosition())
				-- inst.components.stats.opponent.Transform:SetPosition((pos.x), (pos.y + 1.5), (pos.z))  -- + self.zoffset
				--self.inst.AnimState:Resume()
				--self.inst.sg:GoToState("throw")
				inst.components.stats.opponent.sg:GoToState("thrown")
				inst.components.stats.opponent.components.launchgravity:Launch(8, 12, 0)
			end),

			
			
			TimeEvent(12*FRAMES, function(inst)   --16
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(138) --150 IS TOO LOW, TOO HARD TO RECOVER
				inst.components.hitbox:SetBaseKnockback(90) --98
				inst.components.hitbox:SetGrowth(25) --35
				inst.components.hitbox:SetSize(2)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:AddEmphasis(-5)
				
				
				inst.components.hitbox:SpawnHitbox(0, 2, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			TimeEvent(30*FRAMES, function(inst)   --16
				inst.sg:GoToState("idle") 
			end),
			
        },
        
        events=
        {
			EventHandler("on_hitted", function(inst)
				inst.components.stats.opponent.sg:GoToState("rebound", 10)
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
			inst.components.launchgravity:SetLandingLag(10)
		end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst)   --16
				inst.components.hitbox:MakeFX("glint_ring_1", 1.35, 0.6, 0.1,   1.0, 1.0,   0.5, 5, 0.8,  0, 0, 0,   1) 
				--(fxname, xoffset, yoffset, zoffset,    xsize, ysize,    alpha, duration, glow,   r, g, b,    stick, build, bank)
				
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(361) 
				inst.components.hitbox:SetBaseKnockback(20) --7
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.6, 0.4)
				inst.components.hitbox:SetLingerFrames(4) --2
				
				inst.components.hitbox:SpawnHitbox(0.35, 0.5, 0) 
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
				inst.components.hitbox:SetDamage(17)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(24)
				inst.components.hitbox:SetGrowth(115) --95
				inst.components.hitbox:SetSize(0.35)
				inst.components.hitbox:SetLingerFrames(2) --2
				
				inst.components.hitbox:SetHitFX("glint_ring_1", "dontstarve/wilson/hit") --2
				
				inst.components.hitbox:SetOnHit(function() 
					inst.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
					inst.SoundEmitter:PlaySound("dontstarve/HUD/research_available")
					inst.components.hitbox:MakeFX("idle", 1.35, 0.6, 0.1,   1.5, 1.5,   0.5, 5, 0.8,  0, 0, 0,   1, "impact", "impact") 
				end)
				
				inst.components.hitbox:SpawnHitbox(1.35, 0.6, 0)
				
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
        tags = {"attack", "notalking", "busy", "ll_medium"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("wickerbair")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.components.launchgravity:SetLandingLag(6)
			
        end,
		
		onexit = function(inst)

        end,
        
        timeline=
        {
            --TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
			--TimeEvent(7*FRAMES, function(inst) inst.components.hitbox:SpawnHitbox(3, -3, 3) inst.sg:RemoveStateTag("abouttoattack") end),
			TimeEvent(3*FRAMES, function(inst) 
			
				-- inst:PushEvent("swaphurtboxes", {preset = "grounded"})
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				inst.components.hitbox:MakeFX("punchwoosh", -1.2, 1.35, -0.4,   1.0, 1.0,   0.5, 4, 0.4,  0, 0, 0,   1) 
				
				--inst.components.hitbox:SetKnockback(10, 8)
				inst.components.hitbox:SetKnockback(15, 12)
				inst.components.hitbox:SetDamage(13) 
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(25)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(-1.2, 0.35, 0) 
				-- inst.components.hitbox:SpawnHitbox(-0.4, 0.35, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			
			TimeEvent(8*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			end),
			
            TimeEvent(17*FRAMES, function(inst) 
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
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("wicker_dair") 
			inst.components.launchgravity:SetLandingLag(14)
			
			-- inst.Transform:SetScale(0.85, 0.85, 0.85)
			-- inst.AnimState:SetBank("spiderfighter")
			-- inst.AnimState:SetBuild("spider_fighter_build")
			-- inst.AnimState:PlayAnimation("dair") 
            
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
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				inst.components.hitbox:MakeFX("woosh1down", 0.1, 0.95, 0.1,   1.6, 1.6,   0.9, 5, 0,   0,0,0, 1)
			end),
			
			-- TimeEvent(2*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				-- inst.components.hitbox:MakeFX("woosh1down", 0.35, 0.75, 0.2,   2.0, 1.4,   0.0, 5, 1,   0.2,0.2,0.2, 1)
				-- inst.components.hitbox:MakeFX("woosh1down", -0.35, 0.75, 0.2,   2.0, 1.4,   0.0, 5, 1,   1,1,1, 1)
			-- end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(270) --AAAAH WHATEVER, ILL FIX IT LATER
				inst.components.hitbox:SetBaseKnockback(10)
				inst.components.hitbox:SetGrowth(130)
				-- inst.components.hitbox:SpawnHitbox(0, -0.5, 0) 
				-- inst.components.hitbox:SpawnHitbox(0, 0.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				inst.components.hitbox:SetSize(0.5, 0.45)
				--inst.components.hitbox:SetSize(15) --12-1 FOR TEST PURPOSES ONLY
				
				inst.components.hitbox:SpawnHitbox(0, -0.3, 0) 
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
		
		onexit = function(inst)

        end,
        
        timeline=
        {
			
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(22)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(1.1, 0.35) --(0.75, 0.5) -- (1.5, 1)  --1.5
				
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(0.55, 0.35, 0) 
				
				
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(15)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.75, 0.35) --(0.75, 0.5) -- (1.5, 1)  --1.5
				
				inst.components.hitbox:SetLingerFrames(14)
				
				inst.components.hitbox:SpawnHitbox(0.35, 0.3, 0)
			end),
			
            TimeEvent(20*FRAMES, function(inst) 
				inst.sg:GoToState("air_idle")
			
			end),
        },
        
        events=
        {

        },
    },
	
	
	State{
        name = "uair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("wickeruair")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.components.launchgravity:SetLandingLag(10)
        end,
		
		onexit = function(inst)

        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(1)
				inst.components.hitbox:SetAngle(366) --THEEEEERE WE GO
				inst.components.hitbox:SetBaseKnockback(30) --CHANGE IT BACK TO 30
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.75)
				
				inst.components.hitbox:AddSuction(0.2, 0, 1.5)
				
				inst.components.hitbox:SpawnHitbox(0, 2.1, 0) --2.5
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0, 2.1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0, 2.1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0, 2.1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0, 2.1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				
				inst.components.hitbox:SetDamage(4)
				inst.components.hitbox:SetAngle(80) --AAAAH WHATEVER, ILL FIX IT LATER
				inst.components.hitbox:SetBaseKnockback(45) --50 THIS KILLS WAY TOO EARLY
				inst.components.hitbox:SetGrowth(140) 
				inst.components.hitbox:SetSize(1)
				
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
	
	State{
        name = "jab1",
        tags = {"attack", "listen_for_attack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("wicker_jab1")
			-- inst.AnimState:PlayAnimation("wickerdownb")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
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
				
				inst.components.hitbox:SpawnHitbox(0.7, 0.8, 0) --2.5
			end),
			
            TimeEvent(12*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("canjab")
			
			end),
			
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
				
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetDamage(4)   --7
				-- inst.components.hitbox:SetSize(0.75)
				inst.components.hitbox:SetSize(0.8, 0.6)
				
				inst.components.hitbox:SpawnHitbox(0.75, 1, 0) 
				
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
        name = "jab3",
        tags = {"attack", "jab3", "busy"},
        
        onenter = function(inst)
			if inst.prefab == "player2pref" then
				inst.AnimState:PlayAnimation("jab_3_woodie")
			else
			inst.AnimState:PlayAnimation("jab_3")
			end
			
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")

            inst:PushEvent("swaphurtboxes", {preset = "leanf"})
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetDamage(4)   --7
				inst.components.hitbox:SetHitLag(0.3)
				inst.components.hitbox:SetCamShake(0.3)
				inst.components.hitbox:SetHighlight(0.3)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.5)
				inst.components.hitbox:SetLingerFrames(5)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0)  
			end),
			
			TimeEvent(5*FRAMES, function(inst)
				--inst.components.hitbox:SetKnockback(10, 15)
				inst.components.hitbox:SetKnockback(30, 45)
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(45)
				inst.components.hitbox:SetGrowth(80)
				inst.components.hitbox:SetDamage(4)   --7
				inst.components.hitbox:SetHitLag(0.3)
				inst.components.hitbox:SetCamShake(0.3)
				inst.components.hitbox:SetHighlight(0.3)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(1.6)
				inst.components.hitbox:SetLingerFrames(5)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.9, 1.6, 0) 
				
				inst.sg:AddStateTag("jab1") 
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
	
	
	
	State{
        name = "dash_attack",
        tags = {"busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dash_attack")
			inst.Physics:SetFriction(.5)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/explo")
			inst:PushEvent("swaphurtboxes", {preset = "sliding"})
        end,
		
		onexit = function(inst)
			--inst.AnimState:PlayAnimation("dash_attack")
			--inst.Physics:SetFriction(.9)
			inst.components.stats:ResetFriction()
        end,
        
        timeline=
        {
			TimeEvent(5*FRAMES, function(inst)
				inst.components.hitbox:SetKnockback(5, 15)
				inst.components.hitbox:SetKnockback(12, 12)
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(100)
				inst.components.hitbox:SetGrowth(43)
				inst.components.hitbox:SetHitLag(0.2)
				inst.components.hitbox:SetCamShake(0.2)
				inst.components.hitbox:SetHighlight(0.2)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.5)
				inst.components.hitbox:SetLingerFrames(12)
				
				inst.components.hitbox:SpawnHitbox(0.75, 0.2, 0) 
				
				-- inst.components.hitbox:MakeFX("slide1", 1, 0, 1, 1.5, 1.5, 1, 20, 0)
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
        },
    },
	
	
	
	
	
	State{
        name = "ftilt",
        tags = {"attack", "busy"},
        
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
				inst.components.hitbox:SetSize(1.0, 0.3)
				inst.components.hitbox:SetLingerFrames(0)

				inst.components.hitbox:SpawnHitbox(0.7, 0.95, 0)  
			end),
			
            TimeEvent(18*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
			end),
        },
    },
	
	
	
	
	State{
        name = "downtilt",
        tags = {"attack", "notalking", "busy"},
        
        onenter = function(inst)
            --inst.AnimState:PlayAnimation("punch")
			--inst.AnimState:PlayAnimation("shovel_loop")
			inst.AnimState:PlayAnimation("dtilt")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
            
        end,
        
        timeline=
        {
            --TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:SetBlockDamage(1)
				--inst.components.hitbox:SetKnockback(2, 10)
				-- inst.components.hitbox:SetKnockback(0, 40)
				-- inst.components.hitbox:SetGrowth(110)
				-- inst.components.hitbox:SetDamage(10)
				--MARIO UP SMASH
				inst.components.hitbox:SetKnockback(0, 40)
				-- inst.components.hitbox:SetGrowth(94)
				-- inst.components.hitbox:SetDamage(14)
				inst.components.hitbox:SetDamage(5) --10 --60
				inst.components.hitbox:SetAngle(80)  --50 --64
				inst.components.hitbox:SetBaseKnockback(15)  --70
				inst.components.hitbox:SetGrowth(100)  --23
				
				-- inst.components.hitbox:SetDamage(14) --10 --60  --MARIOS USMASH
				-- inst.components.hitbox:SetAngle(83)  --50 --64
				-- inst.components.hitbox:SetBaseKnockback(32)  --70
				-- inst.components.hitbox:SetGrowth(94)  --23
				
				-- inst.components.hitbox:SetDamage(5) --10 --60
				-- inst.components.hitbox:SetAngle(80)  --50 --64
				-- inst.components.hitbox:SetBaseKnockback(35)  --70
				-- inst.components.hitbox:SetGrowth(80)  --23
				
				inst.components.hitbox:SetHitLag(0.4)
				inst.components.hitbox:SetCamShake(0.4)
				inst.components.hitbox:SetHighlight(4)
				inst.components.hitbox:DoFlash(0)
				--inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetSize(0.75, 0.3)  --0.3  --5 --OH GOD NOT 5
				
				--inst.components.hitbox:MakeFX("lucy_archwoosh", xoffset, yoffset, xsize, ysize, alpha, duration)
				--inst.components.hitbox:MakeFX("lucy_archwoosh", 2, 1, 1, 1, 1, 4) --WHY IS THIS EVEN HERE???
				-- inst.components.hitbox:SpawnHitbox(1, 0.1, 0)
				-- inst.components.hitbox:SpawnHitbox(0.2, 0.1, 0) 
				inst.components.hitbox:SpawnHitbox(1, 0.2, 0) 
				--inst.sg:RemoveStateTag("abouttoattack")
			end),
			
            TimeEvent(10*FRAMES, function(inst) --7
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
			TimeEvent(3*FRAMES, function(inst)
			
			inst.components.hitbox:SetKnockback(7, 20)
				inst.components.hitbox:SetDamage(10) --18 RYU'S
				inst.components.hitbox:SetAngle(85)
				inst.components.hitbox:SetBaseKnockback(80)
				inst.components.hitbox:SetGrowth(69)
				
				-- inst.components.hitbox:SetSize(1.5) --FINALLY GETTING AROUND TO MAKING THIS FAIR
				-- inst.components.hitbox:SpawnHitbox(0.5, 1, 0)
				
				--SOURSPOT?
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetSize(0.2)
				inst.components.hitbox:SpawnHitbox(0.6, 0.35, 0)
				
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SpawnHitbox(0.7, 0.35, 0)

			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(1.0)
				inst.components.hitbox:SpawnHitbox(0.65, 1, 0)
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
        tags = {"attack", "notalking", "nolandingstop", "busy", "noairmoving", "no_fastfalling"},
        
        onenter = function(inst)
			-- inst.AnimState:PlayAnimation("nspecial_retry")
			inst.AnimState:PlayAnimation("wicker_fspecial")
            
        end,
        
        timeline=
        {
			TimeEvent(28*FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
			
        },
        
    },
	
	
	
	
	
	State{
        name = "uspecial",
        tags = {"attack", "busy", "can_grab_ledge", "no_air_transition", "no_fastfalling"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("tumble_up_000")
            
			-- inst.components.locomotor:SlowFall(0.5, 13)
			-- inst.components.hitbox:MakeFX("book_fx_90s", -0.4, 0.6, -0.2,   0.5, 0.5,   1, 15, 0,  0,0,0, 1, "book_fx", "book_fx")
			inst.components.hitbox:MakeFX("punchwoosh", 0, 1.35, 0.3,   2.0, 2.0,   0.5, 4, 0.4,  0, 0, 0,   1) 
        end,
		
        
        timeline=
        {
		
			TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				if inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
				inst.components.launchgravity:AirOnlyLaunch(5, 18)
			end),
			
			TimeEvent(10*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				-- inst.components.hitbox:MakeFX("punchwoosh", 0, 1.35, 0.2,   2.0, 2.0,   0.5, 4, 0.4,  0, 0, 0,   1) 
			end),
			
			
            TimeEvent(80*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				-- inst.sg:GoToState("freefall")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                -- inst.AnimState:PlayAnimation("wickerupb")
            end),
			
        },
    },
	
	
	State{
        name = "dspecial",
        tags = {"attack", "notalking", "abouttoattack", "busy", "nolandingstop", "no_air_transition"}, 
        
        onenter = function(inst)
            --inst.AnimState:PlayAnimation("punch")
			inst.AnimState:PlayAnimation("fspecial")
			
			
			local Harold = SpawnPrefab("spiderfighter_queen")
			Harold:AddComponent("stats")
					
			Harold:AddTag("player2")
			-- inst:RemoveTag("player2")
					
			local nemisis = TheSim:FindFirstEntityWithTag("player") --7-6 JUST LOCK ON TO ME PLEASE
			Harold.components.stats.opponent = nemisis
			
			local x, y, z = GetPlayer().Transform:GetWorldPosition()
			-- GetPlayer().components.gamerules:SpawnPlayer(p1, x+1, y, z-5)
			
			GetPlayer().components.gamerules:SpawnPlayer(Harold, x+1, y, z-5)
			
			
			
			
			-- Harold.AnimState:PlayAnimation("idle")
			Harold.sg:GoToState("uspecial")
            
        end,
		
		onexit = function(inst)
			if inst.motortask then
				inst.motortask:Cancel() --I SHOULD REALLY SET THESE UP TO CANCEL THEMSELVES ON STATE CHANGE, ITS GONNA CONFUSE MODDERS --TODOLIST
			end
        end,
		
        timeline=
        {
            --TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
			TimeEvent(3*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(55)
				inst.components.hitbox:SetDamage(4) --10
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.6)
				inst.components.hitbox:SetLingerFrames(10)
				
				-- inst.components.hitbox:SpawnHitbox(0, 1, 0) 
				
				inst.components.hitbox:MakeFX("square", 0, 1, -0.5,   2, 0.7,   0.4, 8, 0,   -0.2, -0.4, -0.4) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				
			end),
			
			
            TimeEvent(28*FRAMES, function(inst)  --30
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
        
    },
	
	
	
	State{
        name = "nspecial",
        tags = {"attack", "abouttoattack", "busy", "nolandingstop", "no_air_transition", "reducedairacceleration"}, 
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("wickerdownb")     
			
			local fxtoplay = "book_fx"
                if inst.prefab == "waxwell" then
                    fxtoplay = "waxwell_book_fx" 
                end       
                -- local fx = SpawnPrefab(fxtoplay)
                -- local pos = inst:GetPosition()
                -- fx.Transform:SetRotation(inst.Transform:GetRotation())
                -- fx.Transform:SetPosition( pos.x, pos.y - .2, pos.z ) 
                -- inst.sg.statemem.book_fx = fx
				
			inst.SoundEmitter:PlaySound("dontstarve/common/use_book")  --WHY DOES THE SOUND SEEM TO COME OUT FASTER IN THE SOUND TEST?...
			
			-- inst.components.hitbox:MakeFX("book_fx_90s", -0.3, 0.5, -0.2,   1, 1, 1,    58, 0,  0,0,0, 0, "book_fx", "book_fx")
			
			
        end,
		
		onexit = function(inst)

        end,
		
        timeline=
        {
			
			TimeEvent(10*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("book_fx_90s", -0.2, 0.6, -0.2,   0.8, 0.8,   1, 27, 0,  0,0,0, 1, "book_fx", "book_fx")
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
            
        end,
		
		timeline=
        {
			
            TimeEvent(6*FRAMES, function(inst) 
				inst.sg:GoToState("fsmash_charge")
			end),
        },
		
	},
	
	State{
        name = "fsmash_charge", "scary",
        tags = {"attack", "notalking", "f_charge", "busy"}, --, "chargingfsmash"},
        
	
		
        onenter = function(inst)
            --inst.AnimState:PlayAnimation("punch")
			-- inst.AnimState:PlayAnimation("chop_pre")
			--inst.AnimState:PlayAnimation("charging_fsmash_007")  --NOW HANDLED BY STARTUP
			
			if not inst:HasTag("atk_key_dwn") then
				inst.sg:GoToState("fsmash")
			else
			
			inst:AddComponent("colourtweener")
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.colourtweener:StartTween({1,0,0,1}, 1, nil)
			
			inst.AnimState:OverrideSymbol("swap_object", "swap_hammer", "swap_hammer")
            inst.AnimState:Show("ARM_carry") 
            inst.AnimState:Hide("ARM_normal")
			end
            
        end,
		
		onexit = function(inst)
            inst.components.colourtweener:EndTween()
			inst.AnimState:SetMultColour(1,1,1,1)
			
			inst.AnimState:Hide("ARM_carry") 
            inst.AnimState:Show("ARM_normal")
			inst.AnimState:ClearOverrideSymbol("swap_object")
        end,
        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/HUD/health_up")
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
 --function() inst:DoTaskInTime(45*FRAMES, LerpOut) end)
				--local player = GetPlayer()
				--local x,y,z = player.Transform:GetWorldPosition()
				--player.Transform:SetPosition( x, y, z )
				
				--local player = GetPlayer()
				
				inst.sg:AddStateTag("chargingfsmash")
				--local shaker = 0.01
				
				-- local x,y,z = inst.Transform:GetWorldPosition()
				-- inst.Transform:SetPosition( (x + 0.01), y, z )
			end),
			
			-- TimeEvent(9*FRAMES, function(inst) 
				-- local x,y,z = inst.Transform:GetWorldPosition()
				-- inst.Transform:SetPosition( (x - 0.01), y, z )
				-- inst:PushEvent("tester")
				-- 
			-- end),
			
			TimeEvent(11*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.01), y, z )
			end),
			
			TimeEvent(13*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.01), y, z )
			end),
			
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
				inst:PushEvent("tester")
				
			end),
			
			TimeEvent(21*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.01), y, z )
			end),
			
			TimeEvent(23*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
				inst:PushEvent("tester")
				
			end),
			
			TimeEvent(25*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.02), y, z )
				inst:PushEvent("tester")
				
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
				inst:PushEvent("tester")
				
				inst.sg:GoToState("fsmash")
			end),
			
			TimeEvent(33*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.02), y, z )
			end),
			TimeEvent(35*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.04), y, z )
			end),
			TimeEvent(37*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.04), y, z )
			end),
			TimeEvent(39*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.04), y, z )
				inst:PushEvent("tester")
				
			end),
			TimeEvent(41*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.04), y, z )
			end),
			TimeEvent(43*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.04), y, z )
			end),
			TimeEvent(45*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.04), y, z )
			end),
			TimeEvent(55*FRAMES, function(inst) 
				-- inst.sg:GoToState("fsmash") --ITS ONLY 1 SECOND, NOT TWO
				inst:PushEvent("tester")
				
			end),
			
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                --inst.sg:GoToState("idle")
            end),
			EventHandler("throwfsmash", function(inst) inst.sg:GoToState("fsmash") end ),
        },
    },
	
	State{
        name = "fsmash",
        tags = {"attack", "notalking", "busy", "abouttoattack", "force_direction"},
        
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
			
				inst.components.hitbox:SetDamage(14)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(92)
				inst.components.hitbox:SetHitLag(0.2)
				inst.components.hitbox:SetCamShake(0.2)
				inst.components.hitbox:SetHighlight(0.2)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:MakeDisjointed()
				-- inst.components.hitbox:SetProperty(6)
				inst.components.hitbox:SetSize(1.1, 0.25)
				inst.components.hitbox:SetLingerFrames(4)
				
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				-- inst.components.hitbox:MakeFX("lucy_archwoosh", 3, 1, 1, 1, 1, 0.4, 8) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
				
				inst.components.hitbox:SpawnHitbox(1.8, 0.9, 0) 
				
				-- inst.components.hitbox:SetLingerFrames(2)
				-- inst.components.hitbox:SpawnHitbox(2, 1, 0)
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(-0.7, 0)
			end),
			
			
            TimeEvent(20*FRAMES, function(inst) 
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
        tags = {"busy", "scary"}, --, "chargingfsmash"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("wickerdsmash_charge")
			inst.components.hitbox:SetDamage(40)  
            
        end,
		
		timeline=
        {
			
            TimeEvent(10*FRAMES, function(inst) 
				inst.sg:GoToState("dsmash_charge")
			end),
        },
		
	},
	
	State{
        name = "dsmash_charge",
        tags = {"attack", "scary", "d_charge", "busy", "chargingdsmash"}, --, "chargingfsmash"},
        --3-24 I GUESS CHARGINGDSMASH TAG HAS ITS USES IN PLAYER1CONTROLER
	
		
        onenter = function(inst)
            --inst.AnimState:PlayAnimation("punch")
			-- inst.AnimState:PlayAnimation("chop_pre")
			--inst.AnimState:PlayAnimation("charging_fsmash_007")  --NOW HANDLED BY STARTUP
			
			if not inst:HasTag("atk_key_dwn") then
				inst.sg:GoToState("dsmash")
			else
			
			inst:AddComponent("colourtweener")
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.colourtweener:StartTween({1,0,0,1}, 1, nil)
			
			inst.AnimState:OverrideSymbol("swap_object", "swap_hammer", "swap_hammer")
            inst.AnimState:Show("ARM_carry") 
            inst.AnimState:Hide("ARM_normal")
			end
            
        end,
		
		onexit = function(inst)
            inst.components.colourtweener:EndTween()
			inst.AnimState:SetMultColour(1,1,1,1)
			
			inst.AnimState:Hide("ARM_carry") 
            inst.AnimState:Show("ARM_normal")
			inst.AnimState:ClearOverrideSymbol("swap_object")
        end,
		
		onupdate = function(inst)  --1-11
            inst.components.hitbox:MultiplyDamage(1.0113)
        end,
        
        timeline=
        {
            --TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
			--TimeEvent(10*FRAMES, function(inst) inst.components.hitbox:SpawnHitbox(0, 0, 0) inst.sg:RemoveStateTag("abouttoattack") end),
            --TimeEvent(15*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
			
			TimeEvent(7*FRAMES, function(inst) 

				
				inst.sg:AddStateTag("chargingdsmash")

			end),
			

			TimeEvent(11*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.01), y, z )
			end),
			
			TimeEvent(13*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.01), y, z )
			end),
			
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
				inst:PushEvent("tester")
				
			end),
			
			TimeEvent(21*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.01), y, z )
			end),
			
			TimeEvent(23*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
				inst:PushEvent("tester")
				
			end),
			
			TimeEvent(25*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.02), y, z )
				inst:PushEvent("tester")
				
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
				inst:PushEvent("tester")
				
				inst.sg:GoToState("dsmash")
			end),
			
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                --inst.sg:GoToState("idle")
            end),
			EventHandler("throwdsmash", function(inst) inst.sg:GoToState("dsmash") end ),
        },
    },
	
	State{
        name = "dsmash",
        tags = {"attack", "notalking", "busy", "abouttoattack"},
        
        onenter = function(inst)
			-- inst.SoundEmitter:PlaySound("dontstarve/common/destroy_smoke")

			inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hot_explo")

			inst.SoundEmitter:PlaySound("dontstarve/creatures/rook/step")
			
		
			inst.AnimState:PlayAnimation("wickerdsmash")
			inst.components.colourtweener:EndTween()
			inst.AnimState:SetMultColour(1,1,1,1)
			
			inst.AnimState:OverrideSymbol("swap_object", "swap_hammer", "swap_hammer")
            inst.AnimState:Show("ARM_carry") 
            inst.AnimState:Hide("ARM_normal")
            
        end,
		
		onexit = function(inst)
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
        
        timeline=
        {
            --TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
			TimeEvent(2*FRAMES, function(inst)
			
				TheCamera:Shake("FULL", .2, .02, .2)
			
				inst.components.hitbox:SetBlockDamage(5)
				--inst.components.hitbox:SetKnockback(17, 20)
				inst.components.hitbox:SetAngle(30)
				inst.components.hitbox:SetBaseKnockback(30) --40
				inst.components.hitbox:SetGrowth(100)
				-- inst.components.hitbox:SetDamage(40)  --40
				inst.components.hitbox:SetHitLag(0.5)
				inst.components.hitbox:SetCamShake(0.6)
				inst.components.hitbox:SetHighlight(1)
				inst.components.hitbox:DoFlash(0) --FLASH DOESNT WORK AS WELL FOR ATTACKS ANYMORE
				inst.components.hitbox:SetSize(1.3)
				
				inst.components.hitbox:SetLingerFrames(3) --10
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.4, 1.3, 0)
				
				inst.components.hitbox:SetSize(1.0)
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.4, 1, 0) 
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-0.6, 1, 0)
				
				-- inst.SoundEmitter:PlaySound("dontstarve/rain/thunder_close")
				inst.components.hitbox:MakeFX("idle", -0.6, 0.0, -0.2,   0.6, 0.6,   1, 20, 0,  0, 0, 0,   0, "marsh_bush", "marsh_bush") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
				inst.components.hitbox:MakeFX("idle", 0.6, 0.0, -0.2,   0.6, 0.6,   1, 20, 0,  0, 0, 0,   0, "marsh_bush", "marsh_bush") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
					
				
				
				inst.sg:RemoveStateTag("abouttoattack") 
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
        tags = {"busy"}, --},

        onenter = function(inst)
			--inst.AnimState:PlayAnimation("charging_fsmash_007")
			-- inst.AnimState:PlayAnimation("usmash_charge_dillop")
			
			if not inst:HasTag("atk_key_dwn") then
				inst.sg:GoToState("usmash")
			else
			-- inst.AnimState:PlayAnimation("usmash_charge")
				inst.AnimState:PlayAnimation("dsmash_charge")
			
			-- inst.components.hitbox:MakeFX("grid", 0, 0, 0.1, 2, 2, 1, 90, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			end
			-------------IT DODNT WORK-------------------00000000000000000000000
            
        end,
		
		timeline=
        {
			
            TimeEvent(2*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "landing"})
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
            --inst.AnimState:PlayAnimation("punch")
			-- inst.AnimState:PlayAnimation("chop_pre")
			--inst.AnimState:PlayAnimation("charging_usmash_007")  --NOW HANDLED BY STARTUP
			inst:AddComponent("colourtweener")
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.components.colourtweener:StartTween({1,0,0,1}, 1, nil)
			
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hatch_crack")
			-- inst.SoundEmitter:PlaySound("dontstarve/common/trap_teeth_trigger")
			-- inst.SoundEmitter:PlaySound("dontstarve/common/fixed_stonefurniture")
			-- inst.SoundEmitter:PlaySound("dontstarve/HUD/XP_bar_fill_fast")
-- inst.SoundEmitter:PlaySound("dontstarve/HUD/XP_bar_fill_slow")
-- inst.SoundEmitter:PlaySound("dontstarve/HUD/collect_newitem")
-- inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_linebreak")
-- inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")
-- inst.SoundEmitter:PlaySound("dontstarve/HUD/XP_bar_fill_unlock")
			
			--inst.AnimState:Pause() --NOOO
            
        end,
		
		onexit = function(inst)
            inst.components.colourtweener:EndTween()
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.AnimState:Resume()
        end,
        
        timeline=
        {
            --TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
			--TimeEvent(10*FRAMES, function(inst) inst.components.hitbox:SpawnHitbox(0, 0, 0) inst.sg:RemoveStateTag("abouttoattack") end),
            --TimeEvent(15*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
			TimeEvent(1*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/HUD/health_up")
			end),
			TimeEvent(3*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hatch_crack")
			end),
			
			
			TimeEvent(10*FRAMES, function(inst) 
 --function() inst:DoTaskInTime(45*FRAMES, LerpOut) end)
				--local player = GetPlayer()
				--local x,y,z = player.Transform:GetWorldPosition()
				--player.Transform:SetPosition( x, y, z )
				
				--local player = GetPlayer()
				
				inst.sg:AddStateTag("chargingusmash")
				
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.02), y, z )
			end),
			
			TimeEvent(11*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
			end),
			
			TimeEvent(13*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.02), y, z )
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
			end),
			
			TimeEvent(17*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.02), y, z )
			end),
			
			TimeEvent(19*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.02), y, z )
			end),
			
			TimeEvent(21*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.02), y, z )
			end),
			
			TimeEvent(23*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.05), y, z )
			end),
			
			TimeEvent(25*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.05), y, z )
			end),
			
			TimeEvent(27*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.05), y, z )
			end),
			
			TimeEvent(29*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x - 0.05), y, z )
			end),
			
			TimeEvent(31*FRAMES, function(inst) 
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition( (x + 0.05), y, z )
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
            
        end,
		
        
        timeline=
        {
            --TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
			TimeEvent(1*FRAMES, function(inst)
				
				inst.components.hitbox:SetBlockDamage(5)
				inst.components.hitbox:SetDamage(2)--17
				inst.components.hitbox:SetAngle(70)
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(86)
				
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.3)
				
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0.5, 1, 0)
				
				
				
				inst.components.hitbox:SetBlockDamage(5)
				--inst.components.hitbox:SetKnockback(17, 20)
				inst.components.hitbox:SetDamage(17)--17
				inst.components.hitbox:SetAngle(70)
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(86)
				
				inst.components.hitbox:SetHitLag(0.5)
				inst.components.hitbox:SetCamShake(0.6)
				inst.components.hitbox:SetHighlight(1)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.9)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(1.5, 1, 0) 
				
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
			
				--!!!! IMPORTANT!!!!! --12-29  FOR MULTI-HITBOX ATTACKS LIKE THESE, HITBOXES DONT ALWAYS RETAIN THE CORRECT "LAST HITBOX VALUE" FROM HITBOXES CREATED ON THE SAME FRAME
				--TO ENSURE HITBOX VALUES ARENT TAKEN FROM THE INCORECT HITBOX SPAWNED ON THE SAME FRAME, RE-ESTABLISH HITBOX VALUES BEFORE SPAWNING THE NEW HITBOX
				
				--THESE WERE ADDED AND FIXED THE HITBOX VALUE PROBLEM
				-------------------------------------------------------------------
				inst.components.hitbox:SetBlockDamage(5)
				--inst.components.hitbox:SetKnockback(17, 20)
				inst.components.hitbox:SetDamage(17)--17
				inst.components.hitbox:SetAngle(70)
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(86)
				
				inst.components.hitbox:SetHitLag(0.5)
				inst.components.hitbox:SetCamShake(0.6)
				inst.components.hitbox:SetHighlight(1)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.9)
				------------------------------------------------------------------
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:SpawnHitbox(0.7, 2.7, 0)
				-- inst.components.hitbox:SpawnHitbox(3, 1, 0)  --FOR TESTING 12-29
			end),
			
			TimeEvent(4*FRAMES, function(inst)
				--THE TINY HIT
				inst.components.hitbox:SetBlockDamage(5)
				inst.components.hitbox:SetDamage(2)--17
				inst.components.hitbox:SetAngle(70)
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(86)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.3)
				
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(-0.5, 1, 0)
				
				--BACK TO THE BIG HIT
				inst.components.hitbox:SetBlockDamage(5)
				inst.components.hitbox:SetDamage(17)--17
				inst.components.hitbox:SetAngle(70)
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(86)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(0.9)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(-1.2, 2, 0) 
				-- inst.components.hitbox:SpawnHitbox(3, 1, 0)  --FOR TESTING 12-29 --WAIT NO THIS ONE IS FINE???
				
				inst:PushEvent("swaphurtboxes", {preset = "hitstun1"})
				inst.components.hurtboxes:ShiftHurtboxes(-0.5, 0)
			end),
			
			TimeEvent(6*FRAMES, function(inst)
				
				--ADDED TO FIX HITBOX VALUE PROBLEMS --12-29
				inst.components.hitbox:SetBlockDamage(5)
				inst.components.hitbox:SetDamage(17)--17
				inst.components.hitbox:SetAngle(70)
				inst.components.hitbox:SetBaseKnockback(50)
				inst.components.hitbox:SetGrowth(86)
				inst.components.hitbox:SetSize(0.9)
				
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetLingerFrames(3)
				inst.components.hitbox:SpawnHitbox(-2, 0.3, 0)
				
				TheCamera:Shake("FULL", .2, .02, .2)
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_dull")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				
				inst.components.hitbox:MakeFX("shovel_dirt", -2, 0, 0.1, 1, 1, 1, 10, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst.components.hitbox:MakeFX("shovel_dirt", -1.8, 0, 0.1, -1, 1, 1, 10, 0)
				
				inst.components.hitbox:MakeFX("ground_smash", -2, -0.1, 0.1, 1.5, 1.5, 1, 20, 0)
				--inst.components.hitbox:MakeFX("ground_crack", -2, 0.1, 0.2, 1, 3, 1, 20, 0) --AWW MAN THIS EFFECT LOOKS LIKE CRAP
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
				-- inst.AnimState:PlayAnimation("chop_pst")
				--inst.sg:RemoveStateTag("busy")
            end),
        },
    },
    
}

CommonStates.AddFrozenStates2(states)
CommonStates.AddRespawnPlatform(states)
CommonStates.AddDropSpawn(states)
    
return StateGraph("wilson", states, events, "idle") --, actionhandlers)

