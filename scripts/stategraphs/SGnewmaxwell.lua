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
	
	--9--9-17 LETS SEE IF THIS MAKES THE CLONE PLAYABLE
	if inst.components.stats.slave and inst.components.stats.slave:IsValid() and not inst.components.stats.slave:HasTag("heel") and not inst.components.stats.slave.sg:HasStateTag("jumping") then
		inst.components.stats.slave:PushEvent(inst.components.stats.event, {key = inst.components.stats.key, key2 = inst.components.stats.key2})
	end
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
		
		--9-14-17 OKAY, MAXWELL IS GETTING SOME STUFF SPECIFICALLY FOR DST MAXCLONES
		if inst.components.stats:DSTCheck() and inst.components.stats.master and inst.components.stats.master:IsValid() then
			local master = inst.components.stats.master
			--OH... THIS IS SMALLER THAN I THOUGHT IT WOULD BE
			wantstoblock = master:HasTag("wantstoblock")
			atk_key_dwn = master:HasTag("atk_key_dwn")
		end
		
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
		
		--11-19-17 SPECIAL CASE FOR MAXCLONES TO RETURN TO THEIR MASTER WHILE THEY ARE HOLDING DOWNB
		local master = inst.components.stats.master
		if master and master:IsValid() and inst.components.keydetector then
			local pressing_down = inst.components.keydetector:GetDown(inst.components.stats.master)
			local pressing_b = inst.components.keydetector:GetSpecial(inst.components.stats.master)
			
			--[[
			if pressing_down and pressing_b then
				--START COUNTING THIS HIDDEN METER UP. WHEN ITS PAST 25, MIND CONTROL WILL KICK IN
				inst.components.stats.storagevar2 = inst.components.stats.storagevar2 + 1
				
				if inst.components.stats.storagevar2 >= 25 then
					inst:AddTag("heel") --LIKE A DOG, YA KNOW?
				end
				
				if inst.components.stats.storagevar2 >= 50 then inst.components.stats.storagevar2 = 50 end
			elseif not pressing_b then 
				--DECREASE THE METER BACL TO 0
				if inst.components.stats.storagevar2 > 0 then 
					inst.components.stats.storagevar2 = inst.components.stats.storagevar2 - 1
					inst:RemoveTag("heel")
					inst:RemoveTag("holdleft") --DONT FORGET TO REMOVE THESE TOO, YA DUMMY
					inst:RemoveTag("holdright")
				end
			end
			]]
			
			--JESUS TAKE THE WHEEL
			if inst:HasTag("heel") then
				local myposx, myposy = inst.Transform:GetWorldPosition()
				local oppx, oppy = master.Transform:GetWorldPosition()
				local is_airborn = inst.components.launchgravity:GetIsAirborn()
				--TURN AUTORUN ON, REGARDLESS OF OUR MASTER'S SETTINGS
				inst.components.stats.autodash = true
				inst.components.keydetector.holdingdown = false --KINDA WEIRD BUT WE NEED TO SET THIS BECAUSE DOWN-B MEANS IT THINKS THIS IS PRESSED
				
				
				--FIRST TAKE CARE OF SOME THINGS
				if inst.sg:HasStateTag("hanging") then
					inst:PushEvent("forward_key") --PULL SELF UP FROM LEDGE --WHY DONT THIS WORK???
				
				elseif inst.sg:HasStateTag("prone") then
					inst:PushEvent("up")
				
				elseif is_airborn then
					
					inst:RemoveTag("holdleft")
					inst:RemoveTag("holdright")
					inst.components.keydetector.holdingleft = false
					inst.components.keydetector.holdingright = false
					--REMOVE ALL FORMS OF CONTROL AND SIMPLY DRIFT WHATEVER DIRECTION OUR OWNER IS IN -SIDENOTE- THIS WILL MESS WITH KEYDETCTOR STUFF, IF USED
					if (myposx) >= (oppx) then
						inst:AddTag("holdright")
					else
						inst:AddTag("holdleft")
					end
					
					if myposy <= -3.0 then --USE YOUR JUMP TO RECOVER, IF YOU HAVE IT
						inst:PushEvent("jump")
					end
				
				else --IF GROUNDED
					
					--IF ABLE TO, FACE THE MASTER, AND THEN STROLL FORWARD
					if not inst.sg:HasStateTag("busy") then
						-- if myposx*inst.components.launchgravity:GetRotationValue() >= oppx*inst.components.launchgravity:GetRotationValue() then
							-- inst.components.locomotor:TurnAround()
							-- inst.sg:GoToState("stroll_forward")
						-- else
							-- inst.sg:GoToState("stroll_forward")
						-- end
						--1-18-22 HERE, JUST USE YOUR LEGS LIKE A NORMAL PERSON
						if myposx < oppx then
							inst.components.keydetector.holdingleft = true
							inst.components.keydetector.holdingright = false
						else
							inst.components.keydetector.holdingleft = false
							inst.components.keydetector.holdingright = true
						end
						
					end
					
					--1-18-22 IF WE'RE CLOSE ENOUGH TO MASTER AND ON THE GROUND, END THE HEEL
					--FIND OUR HORIZONTAL DIFFERENCE 
					local xdiff = math.abs(myposx - oppx)
					if xdiff < 3.5 then 
						inst:RemoveTag("holdleft")
						inst:RemoveTag("holdright")
						inst.components.keydetector.holdingleft = false
						inst.components.keydetector.holdingright = false
						inst.components.stats.autodash = master.components.stats.autodash
						inst:RemoveTag("heel")
						inst:PushEvent("dash_stop")
						inst.components.hitbox:MakeFX("glint_ring_2", 0, 2.2, 0.2,   1.7, 1.7,   0.5, 8, 0.8,  0,0,0) 
						inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_despawn")
					end
				end
			end
			
			-- should_move = master.components.locomotor:WantsToMoveForward()
			-- should_run = master.components.locomotor:WantsToRun()
			-- was_running = master:HasTag("wasrunning")
		end
		
		inst:RemoveTag("motoring") --4-20 ADDED TO FIX BOTH WOODIES CHOPPY SIDE-B AND LEDGE WALK-OFF PHYSICS AT THE SAME TIME
		
        if not (is_attacking or is_busy) then --return end --4-13 TBH THIS CAN JUST GO BACK TO THE WAY IT WAS IN SGBRAWLER
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
		end

		
	end),
	
	
	EventHandler("clearbuffer", function(inst)
		inst.components.stats.buffertick = 0
	end),
	
	
	EventHandler("jump", function(inst, data)
		local is_busy = inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("nojumping") --9-21-17 DST- A "nojumping" WORKAROUND FOR A MAXCLONE THAT MADE HIM JUMP FOREVER
		local can_jump = inst.sg:HasStateTag("can_jump")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local used_first_jump = inst.components.jumper.jumping == 1 and inst.components.jumper.doublejumping == 0
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		-- print("I'M JUMP", inst)

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
		local pressing_down = inst.components.keydetector and inst.components.keydetector:GetDown(inst)
		
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
		local pressing_forward = inst.components.keydetector and inst.components.keydetector:GetForward(inst)
		local foxtrot = inst.sg:HasStateTag("foxtrot")
		
		if inst.components.launchgravity:GetIsAirborn() then
			return end --DON'T DASH IN THE AIR, NITWIT
		
		
		--1-14-22 CHECK DIRECTION FOR BUFFERED DASHES
		local facedir = inst.components.launchgravity:GetRotationFunction()
		
		--9-14-17 DST CHANGE - FOR MAXWELL'S CLONES
		--[[
		if inst.components.stats.master and inst.components.stats.master:IsValid() then
			pressing_forward = inst.components.keydetector and inst.components.keydetector:GetForward(inst.components.stats.master)
			--11-19-17 DASH FIX- MUST TEST FOR MASTERS OPPOSITE DIRECTIONAL KEY IF FACING DIFFERENT DIRECTIONS
			if inst.components.launchgravity:GetRotationFunction() ~= inst.components.stats.master.components.launchgravity:GetRotationFunction() then
				pressing_forward = inst.components.keydetector and inst.components.keydetector:GetBackward(inst.components.stats.master)
			end
			--1-14-22 A BIT DIFFERENT FOR MAXCLONES
			facedir = inst.components.stats.master.components.launchgravity:GetRotationFunction()
		end
		]]
		
		--1-14-22 A BIT DIFFERENT FOR MAXCLONES
		if data.key and data.key ~= facedir then
			--inst.components.locomotor:TurnAround()
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
			-- else
			elseif inst.sg:HasStateTag("dashing") then --WHY WASNT IT THIS WAY TO BEGIN WITH?
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
		
		--9-14-17 OKAY, MAXWELL IS GETTING SOME STUFF SPECIFICALLY FOR DST MAXCLONES --ACTUALLY NEVERMIND THIS MAKES IT WORSE
		-- if inst.components.stats:DSTCheck() and inst.components.stats.master and inst.components.stats.master:IsValid() then
			-- local master = inst.components.stats.master
			
			-- should_move = master.components.locomotor:WantsToMoveForward()
			-- should_run = master.components.locomotor:WantsToRun()
			-- was_running = master:HasTag("wasrunning")
		-- end
		
		
        
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

    
	EventHandler("throwattack", function(inst, data) --4-5 ADDING ADDITION DATA FOR ATEMPT KEY BUFFERING
		
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
			return end
		
		--FOR THE CLONE'S GRAB KEY 
		if inst:HasTag("wantstoblock") or data.key == "block" then 
			if inst.components.stats.slave and inst.components.stats.slave:IsValid() then
				inst.components.stats.slave:PushEvent("throwattack", {key = "block"})
			end
		end
		
		
		-- !! A SPECIAL CASE FOR MAXWELL CLONES FOR DIRECTIONAL INPUTS REGARDING FACING FIRECTION VS THE MASTER'S DIRECTION
		--11-19-17 THIS CHECKS IF THE ENTITY IS A CLONE, AND IF THE MASTER IS FACING THE OTHER WAY, LISTEN FOR THE REVERSE DIRECTION KEY.
		local function MaxKeyCheck(inst, position, datakey)
			if inst.components.stats.master and inst.components.stats.master:IsValid() then
				local masterface = inst.components.stats.master.components.launchgravity:GetRotationFunction()
				local cloneface = inst.components.launchgravity:GetRotationFunction()
				
				if masterface ~= cloneface then --IF TURNED AROUND, THEN-
					if position == "forward" and datakey == "backward" then return true 
					elseif position == "backward" and datakey == "forward" then return true
					elseif position == "diagonalb" and datakey == "diagonalf" then return true
					elseif position == "diagonalf" and datakey == "diagonalb" then return true
					else return false end --NONE OF THESE COMBINATIONS WAS MET, SO THE KEYPRESS MUST BE FALSE
				else
					if position == datakey then return true else return false end--	WE'RE FACING THE SAME WAY ANYWAY, JUST CHECK IT THE NORMAL WAY
				end
			else
				if position == datakey then return true else return false end--NO MASTER, JUST CHECK IT THE NORMAL WAY
			end
		end
			
		-- if inst.sg:HasStateTag("can_usmash") or can_ood then --NO MORE USMASH OUT OF SHIELD. REPLACING WITH CANUPSMASH
			 -- inst.sg:GoToState("usmash_start") --THE HECK IS THIS HERE FOR???? GET RID OF THIS
		if can_oos then
			inst.sg:GoToState("grab")
		-- elseif must_fsmash then
			-- inst.sg:GoToState("fsmash_start")
		-- elseif must_usmash then
			-- inst.sg:GoToState("usmash_start")
		-- elseif must_dsmash then
			-- inst.sg:GoToState("dsmash_start")
		-- elseif must_ftilt then
			-- inst.sg:GoToState("jab3") --ftilt
			
		elseif can_ood then
			if data.key == "block" then
				inst.sg:GoToState("grab")
			elseif pivoting then --8-29-20
				inst.sg:GoToState("ftilt")
			else
				inst.sg:GoToState("dash_attack")
				-- inst.sg:GoToState("dash_grab")
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
				-- if MaxKeyCheck(inst, "backward", data.key) or MaxKeyCheck(inst, "diagonalb", data.key) then --11-19-17 A CHANGE FOR MAXWELL CLONES
					-- inst.sg:GoToState("bair")
				-- elseif MaxKeyCheck(inst, "forward", data.key) or MaxKeyCheck(inst, "diagonalf", data.key) then
					-- inst.sg:GoToState("fair")
					
				if MaxKeyCheck(inst, "backward", data.key) then 
					inst.sg:GoToState("bair")
				elseif MaxKeyCheck(inst, "diagonalb", data.key) then 
					if inst.components.stats.tapjump then
						inst.sg:GoToState("bair")
					else
						inst.sg:GoToState("uair")
					end
				elseif MaxKeyCheck(inst, "forward", data.key) then 
					inst.sg:GoToState("fair")
				elseif MaxKeyCheck(inst, "diagonalf", data.key) then
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
				
				--11-19-17 THE GROUNDED VERSIONS OF THESE SEEM TO WORK FINE WITHOUT THE SPECIAL TESTERS. I'LL LEAVE THEM AS IS
				if data.key == "up" or MaxKeyCheck(inst, "diagonalf", data.key) then 
					inst.sg:GoToState("uptilt")
				elseif data.key == "down" then
					if inst.components.keydetector:GetBackward(inst) then
						inst.components.locomotor:TurnAround() --SINCE WE HAVE NO DOWNWARD DIAG DETECTOR, WE GOTTA TAKE SHORTCUTS
					end
					inst.sg:GoToState("dtilt")
				elseif data.key == "forward" then
					inst.sg:GoToState("ftilt")
				elseif data.key == "backward" or MaxKeyCheck(inst, "diagonalb", data.key) then
					if not inst.components.keydetector:GetForward(inst) then
						inst.components.locomotor:TurnAround()
					end
					if MaxKeyCheck(inst, "diagonalb", data.key) then
						inst.sg:GoToState("uptilt")
					else
						inst.sg:GoToState("ftilt")
					end
				else
				
				--inst.sg:GoToState("attack")
				inst.sg:GoToState("jab1")
				end
				
			end
			
			
            --local weapon = inst.components.combat and inst.components.combat:GetWeapon()
            --if weapon and weapon:HasTag("blowdart") then
                -- inst.sg:GoToState("blowdart")
            -- elseif weapon and weapon:HasTag("thrown") then
                -- inst.sg:GoToState("throw")
            -- else
                -- inst.sg:GoToState("attack")
            -- end
        end
    end),
	
	
	--CSTICK
	EventHandler("cstick_up", function(inst, data)
		local airial = inst.components.launchgravity:GetIsAirborn()
		local can_attack = inst.sg:HasStateTag("can_attack")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local is_busy = inst.sg:HasStateTag("busy") and not can_attack
		local tiltstick = inst.components.stats.tiltstick
		inst:PushEvent("up") --FOR UPTHROW
		
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
		inst:PushEvent("down")
		
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
		
		--FOR THROWS FOR MAXCLONES
		if is_forward then
			inst:PushEvent("forward_key")
		else
			inst:PushEvent("backward_key")
		end
		
		--4-23-20 IF THE USER PRESSED JUMP ON THE SAME FRAME
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
		
		if inst:HasTag("maxclone") then
			return end
			
		--OKAY, LETS TRY THIS. IF CURRENT ROTATION DOES NOT MATCH THE ROTATION FROM THE TIME OF KEYPRESS, TURN AROUND
		-- if data.direction ~= inst.Transform:GetRotation() then --I'VE NEVER TRIED ADDING MORE THAN ONE SET OF DATA BEFORE. IS IT EVEN POSSIBLE?
			-- inst.components.locomotor:TurnAround() 
		-- end
	
		if not inst.sg:HasStateTag("busy") or can_special_attack or (inst.sg:HasStateTag("can_upspec") and (data.key == "up" or data.key == "diagonalf" or data.key == "diagonalb")) then
			-- if inst.components.keydetector:GetUp() then
			if data.key == "up" or data.key == "diagonalf" then
				inst.sg:GoToState("uspecial")
			elseif data.key == "diagonalb" then
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("uspecial")
			elseif data.key == "down" then
				inst.sg:GoToState("dspecial")
			elseif data.key == "forward" then
			
				--OKAY, LETS TRY THIS. IF CURRENT ROTATION DOES NOT MATCH THE ROTATION FROM THE TIME OF KEYPRESS, TURN AROUND
				if data.key2 ~= inst.Transform:GetRotation() then --I'VE NEVER TRIED ADDING MORE THAN ONE SET OF DATA BEFORE. IS IT EVEN POSSIBLE?
					inst.components.locomotor:TurnAround() 
				end
				inst.sg:GoToState("fspecial") --11-7-17 SPECIALS SEEM TO NOT TURN AROUND SOMETIMES. LETS FIX THAT
			
			elseif data.key == "backward" then
				if data.key2 ~= inst.Transform:GetRotation() then --EXCELLENT! IT WORKS! KEY2 HAS NOW BEEN ADDED TO THE KEYBUFFER, AND MUST BE ADDED TO EVERYONES STATEGRAPH
					inst.components.locomotor:TurnAround() 
				end
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("fspecial")
			else
				inst.sg:GoToState("nspecial")
			end
			
			--11-7-16 SECOND CHECK FOR DIAGONALS IN THE AIR
			if airial then
				if data.key == "diagonalf" then
					inst.sg:GoToState("uspecial")
				elseif data.key == "diagonalb" then
					inst.components.locomotor:TurnAround()
					inst.sg:GoToState("uspecial")
				end
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
			inst.AnimState:PlayAnimation("run")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
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
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
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
        tags = {"moving", "running", "canrotate", "dashing", "can_usmash", "can_special_attack", "can_ood", "busy", "can_dashdance", "foxtrot", "must_fsmash", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
			inst.components.locomotor.throttle = 0
			inst.components.locomotor:DashForward()
			-- inst.AnimState:PlayAnimation("dash") --run
			inst.AnimState:PlayAnimation("run") --I LIKE HIS RUN ANIMATION BETTER
			
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
			-- inst.AnimState:PlayAnimation("dash")
			inst.AnimState:PushAnimation("run", true) --I LIKE THIS ANIMATION BETTER
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
            TimeEvent(3*FRAMES, function(inst)
				-- inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                -- PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
                PlayFootstep(inst,1)
				-- DoFoleySounds(inst)
				--inst.components.hitbox:MakeFX("dahswoosh", 0, 1, -1, 1, 1, 0.8, 7, 1)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.2, 0.2, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
            end),
            TimeEvent(13*FRAMES, function(inst)
				-- inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                -- PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
				PlayFootstep(inst,1)
                -- DoFoleySounds(inst)
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
			inst.AnimState:PlayAnimation("dash_pivot")
			-- inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1, 0.5, 0.5, 1, 10, 0)
			inst.components.hitbox:MakeFX("slide1", -1.6, 0.0, 0.1, 1, 0.5, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
            
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
			inst.AnimState:SetTime(1*FRAMES)
			
			if ISGAMEDST and not TheWorld.ismastersim then --11-26-17
				return --CLIENTS DONT RUN BELOW THIS LINE
			end
			
			local attack_cancel_modifier = hitstun * 1 --0.9
			local dodge_cancel_modifier = hitstun * 1 --1.2
			
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
				inst.AnimState:SetMultColour(1,1,1,1)
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
			
			TimeEvent(20*FRAMES, function(inst)   --CHANGE THIS LATER --TODOLIST
                --inst.sg:RemoveStateTag("busy")
            end),
        },        
               
    },
    
	
	State{
        name = "grab_ledge",
		tags = {"busy", "hanging", "no_running", "resting", "nolandingstop", "no_air_transition"}, --ADDING "RESTING" STATE PLAYERS MUST WAIT TO DO ANYTHING
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_grab")
			inst.SoundEmitter:PlaySound("smash_sounds/grab/grab1")
			
			--DST CHANGE-- STOP THIS GUY FROM DOING THIS ALREADY
			if ISGAMEDST then
				inst:ForceFacePoint(0, 0, 0) --SINCE SINGLEPLAYER VERSION ISNT READY YET
			else
				inst:ForceFacePoint(ledgeref.Transform:GetWorldPosition())
			end
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
			inst.components.hurtboxes:SpawnPlayerbox(0, 0.7, 0.35, 1.7, 0)
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
			TimeEvent(5*FRAMES, function(inst) --8
				inst.AnimState:PlayAnimation("ledge_getup")
			end),
			
			TimeEvent(10*FRAMES, function(inst) --8
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
				inst.sg:GoToState("idle")
			end),
		},
		
		events=
        {
            -- EventHandler("animover", function(inst) inst.AnimState:PlayAnimation("idle") end),
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
			inst.Physics:SetActive(true) 
        end,
        
		timeline =
        {
			TimeEvent(4*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				inst.components.launchgravity:Launch(1, inst.components.stats.jumpheight, 0)
				inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
				inst.AnimState:PlayAnimation("jump")
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
		
		onexit = function(inst)
			inst.Physics:SetActive(true)
			-- if inst.task_1 then
				-- inst.task_1:Cancel()
			-- end
        end,
        
		timeline =
        {
			TimeEvent(6*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				inst.AnimState:PlayAnimation("rolling")
				inst.components.locomotor:RunForward() --11-11-17 LETS SEE IF THIS FIXES THE WONKY GETUP ROLLS
				inst.components.locomotor:Teleport(0, 0.1, 0) --MAYBE A TELEPORT IS NEEDED TO AVOID BUMPING INTO THE LIP OF THE LEDGE
				inst.components.locomotor:Motor(12, 0, 9) --LETS USE THIS INSTEAD OF THAT OLD UGLY VERSION
				--AH! THIS WORKED FANTASTICALLY! TOO WELL, IN FACT. NOW WE NEED TO REDUCE THE MOTOR LENGTH
				-- inst.components.jumper:ScootForward(10)
				-- inst.task_1 = inst:DoPeriodicTask(0.1, function(inst)
						-- inst.Physics:SetMotorVel(12, 0, 0)
					-- end)
			end),
			TimeEvent(15*FRAMES, function(inst)
				inst.sg:RemoveStateTag("intangible")
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
			end),
			TimeEvent(16*FRAMES, function(inst)
				-- inst.task_1:Cancel()
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
			
			TimeEvent(13*FRAMES, function(inst)
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
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SetLingerFrames(2)
				
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0)
				inst.components.hitbox:SetProperty(-6)
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
		tags = {"can_usmash", "can_upspec", "no_running", "no_blocking", "nojumping", "busy", "jumping"},
        
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
			TimeEvent(2*FRAMES, function(inst) --4-11-20 CHANGING FROM 3 BACK TO 2 BECAUSE HIS ANIMATION WAS OFF AND IM TOO LAZY TO CHANGE IT
				inst.sg:RemoveStateTag("busy") 
				inst:AddTag("listenforfullhop")
				inst.components.jumper:Jump(inst) --LETS BUMP THIS DOWN A LINE OR TWO
				inst.sg:RemoveStateTag("can_usmash")
				
				--10-20-17 A NEW IMPROVED ATTEMPT AT FULLHOP REGISTRATION.
				inst:DoTaskInTime(2*FRAMES, function(inst) --NOW ALWAYS CHECKS IN 4 FRAMES
					inst.components.jumper:CheckForFullHop()
				end)
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				-- if not inst:HasTag("maxclone") then --DST- FOR A MAXCLONE SPECIFIC BUG
					-- inst.sg:RemoveStateTag("nojumping")  --IT WORKS, BUT JUMPING IN QUICK SUCCESSION CAN DESYNC THEM SOMETIMES...
				-- end
				inst.components.jumper:CheckForFullHop()
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("nojumping")  --DST
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
				if inst.components.keydetector:GetUp() then
					if inst:HasTag("maxclone") then return end
					inst.sg:GoToState("uspecial") --THE CLONE CANT DO THIS!!
				end
			end ),
        },
    },
	
	State{
        name = "doublejump",
		tags = {"jumping"},
        
        onenter = function(inst)
			-- inst.AnimState:PlayAnimation("jump_maybe_001")
			inst.AnimState:PlayAnimation("doublejump")
			-- inst.components.jumper:Jump()
			inst.components.jumper:DoubleJump(inst) --1-5
			inst.components.hitbox:MakeFX("ground_bounce", 0, 1, -1, 1, 1, 0.8, 7, 1)
			inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
			inst.components.hurtboxes:ShiftHurtboxes(-0.4, -0.2)
        end,
        
		timeline =
        {	
			TimeEvent(3*FRAMES, function(inst) 
				-- inst.components.hurtboxes:ShiftHurtboxes(0.3, 0.4)
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
			
			-- print("ME", inst.components.launchgravity:GetAngle())
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
			
			local attack_cancel_modifier = hitstun * 1  --0.9
			local dodge_cancel_modifier = hitstun * 1  --1.2
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
				-- inst.AnimState:SetMultColour(1,1,0.5,1)
				
				--3-15 GONNA TRY AND ADD SOMETHING THAT CANCELS OUT MOMENTUM SO YOU ARENT FORCED TO JUMP TO SURVIVE
				inst.components.jumper:AirStall(2, 1)
			end)
			
			inst.task_attackstun = inst:DoTaskInTime((attack_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:AddStateTag("can_attack")
				-- inst.AnimState:SetMultColour(1,0.5,1,1)
			end)
			inst.task_dodgestun = inst:DoTaskInTime((dodge_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:RemoveStateTag("busy")
				inst.AnimState:SetMultColour(1,1,1,1)
				
			end)
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
			
			TimeEvent(3*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "hitstun1"})
			end),
			
			TimeEvent(20*FRAMES, function(inst) 
				
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
			inst.AnimState:PlayAnimation("clumsy_land")
			inst.components.hitbox:MakeFX("ground_bounce", -0.5, 0.1, -1, 1.5, 1.5, 0.8, 10, 0)
			inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
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
	
	
	State{
        name = "getup",
        tags = {"busy", "grounded"}, 
        
        onenter = function(inst, target)
            --inst.AnimState:SetMultColour(1,1,1,0.2)
			--inst.AnimState:PlayAnimation("pickup")
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
	
	
	State{
        name = "getup_attack",
        tags = {"attack", "busy", "intangible", "grounded"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("getup_attack")
            
        end,
        
        timeline=
        {
            --TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
			--TimeEvent(7*FRAMES, function(inst) inst.components.hitbox:SpawnHitbox(3, -3, 3) inst.sg:RemoveStateTag("abouttoattack") end),
			TimeEvent(6*FRAMES, function(inst) 
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(90)
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetSize(0.8, 0.5)
				inst.components.hitbox:SetSize(2, 1)
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(0, 0.2, 0) 
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
			-- inst.AnimState:PlayAnimation("tech0_003")
			--inst:AddTag("grounded")
			inst.AnimState:PlayAnimation("landing_lag")
			inst:PushEvent("swaphurtboxes", {preset = "landing"})
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
			
			inst.components.locomotor:Motor(12, 0, 7)
			inst.components.hitbox:MakeFX("slide1", -0.8, 0, 1, 1.5, 1.5, 1, 10, 0)
        end,
        
        timeline =
        {
		   
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
        name = "tech_backward_roll", --PASTED FROM HAROLD'S ROLL
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
		   
			TimeEvent(2*FRAMES, function(inst)
				inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
			end),
		   
		   
		    TimeEvent(12*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst.AnimState:SetMultColour(1,1,1,1)
				inst.components.locomotor:TurnAround()
				inst.components.locomotor:Stop()
				inst.components.jumper:ScootForward(-7)
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
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
			inst.AnimState:PlayAnimation("landing_lag")
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
			inst.AnimState:PlayAnimation("block_startup")
			inst:PushEvent("swaphurtboxes", {preset = "blocking"})
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
        end,
        
        timeline =
        {
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
			inst:PushEvent("swaphurtboxes", {preset = "blocking"})
			inst.AnimState:PlayAnimation("block")
			inst.components.blocker:StartConsuming()
        end,
        
        timeline =
        {
            TimeEvent(50*FRAMES,
				function(inst)
				
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
	
	
	
	--10-16-16   IS... IS THIS SUPPOSED TO BE LIKE THIS?
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

        
        timeline =
        {
			TimeEvent(2*FRAMES, function(inst)
				
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
			-- TimeEvent(1*FRAMES, function(inst) inst.sg:RemoveStateTag("blocking") end), --REMOVING 1-22
            
			TimeEvent(3*FRAMES, function(inst) --6
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
			inst.AnimState:PlayAnimation("getup")
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
			inst.AnimState:PlayAnimation("dodge")
			if not inst:HasTag("maxclone") then
				inst.components.hitbox:Blink(inst, 4,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			end
			inst.components.locomotor:TurnAround()
			
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
					inst.Physics:SetMotorVel(-14, 0, 0)
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
				inst.components.jumper:ScootForward(-7) --10
			end),
			
			
			
			
            TimeEvent(16*FRAMES,
				function(inst)
				--CHECK FOR IF STILL HOLDING SHEILD  --TODOLIST
					-- inst.components.locomotor:TurnAround()
                    inst.sg:RemoveStateTag("busy")
					inst.sg:GoToState("idle")
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
        name = "grab",
        tags = {"busy", "grabbing"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("grab")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})

        end,
        
        timeline =
        {
			TimeEvent(4*FRAMES, function(inst) 
				
				-- inst.components.hitbox:SetSize(0.5) --THIS GRAB DOESNT GRAB ENEMIES VERY CLOSE TO HIM. 
				-- inst.components.hitbox:SetLingerFrames(1)
				-- inst.components.hitbox:SpawnGrabbox(1, 1, 0)
				
				--11-9-17 --MUCH BETTER!
				inst.components.hitbox:SetSize(0.6) --ACTUALLY, 7 MIGHT BE TOO BIG
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:SpawnGrabbox(0.7, 1, 0)
				
				
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			end),

            TimeEvent(15*FRAMES, function(inst)
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
            -- inst.components.locomotor:EnableGroundSpeedMultiplier(true) --THE HECK IS THIS HERE FOR?
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
			EventHandler("backward_key", function(inst) 
				inst.sg:GoToState("bthrow")
			end),
			
			EventHandler("down", function(inst) 
				inst.sg:GoToState("uthrow")
			end),
			EventHandler("up", function(inst) 
				inst.sg:GoToState("uthrow")
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
    },
	
	
	State{
        name = "fthrow",
        tags = {"attack", "busy", "handling_opponent"},
        
        onenter = function(inst, target)
			-- inst.components.stats:GetOpponent()
			inst.AnimState:PlayAnimation("utilt")
			inst.AnimState:Resume()
        end,
        
        timeline =
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("utilt")
				inst.AnimState:Resume()
			end),

			
			TimeEvent(3*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(98)
				inst.components.hitbox:SetGrowth(35)
				
				inst.components.hitbox:SetSize(1, 2)
				inst.components.hitbox:SetLingerFrames(3)
				
				inst.components.hitbox:SpawnHitbox(2, 2, 0)  
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
        name = "uthrow",
        tags = {"attack", "busy", "handling_opponent"},
        
        onenter = function(inst, target)
			inst.components.stats:GetOpponent()
			-- inst.AnimState:PlayAnimation("fthrow")
			-- inst.AnimState:Resume()
        end,
        
        timeline =
        {
			
			TimeEvent(1*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("handpunch", 1.5, 0, 0.3,   1.5, 1.3,   1, 20, 0,  0, 0, 0,   0, "shadow_figures", "shadow_figures")
				inst.AnimState:PlayAnimation("fthrow")
				inst.AnimState:Resume()
			end),
			
			
			TimeEvent(3*FRAMES, function(inst)   
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(85) 
				inst.components.hitbox:SetBaseKnockback(98)
				inst.components.hitbox:SetGrowth(35)

				inst.components.hitbox:SetSize(1, 1)
				inst.components.hitbox:SetLingerFrames(3)
				
				
				inst.components.hitbox:SpawnHitbox(1.5, 1, 0)  
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
        tags = {"attack", "busy", "ignoreglow", "handling_opponent"}, --4-11-20 REMOVING "FORCE DIRECTION" FIXED THE BACKWARDS LAUNCH I SUPPOSE
        
        onenter = function(inst, target)
			inst.components.stats:GetOpponent()
			-- inst.AnimState:PlayAnimation("bthrow")
			-- inst.components.stats.opponent.components.launchgravity:Launch(0, 0, 0) --?????
			inst.AnimState:Resume()
        end,
        
        timeline =
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("bthrow")
				
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(140) 
				-- inst.components.hitbox:SetAngle(55)  --CONFIRMED!! REDUCED X LAUNCH HAPPENS WITH FORWARD LAUNCH TOO!!
				inst.components.hitbox:SetBaseKnockback(100) 
				inst.components.hitbox:SetGrowth(25) 
				inst.components.hitbox:SetSize(1)
				inst.components.hitbox:SetLingerFrames(3)
				
				inst.components.hitbox:AddEmphasis(-4) --EVEN -6 STILL REDUCES IT
				--AH HA!... IT MUST BE THE NEGATIVE HITSTUN CAUSING THE TUMBLE STATE TO END AND PUSH THE AIR STALL EARLY!... SO, HOW DO I FIX THAT?...
				--NOPE... AIR STALL ISN'T BEING PUSHED TOO EARLY... THEN WHAT IS IT?!?!?
				--EVEN REMOVING THE INITIAL HITBOX PAUSE DOESN'T HELP??? WHAT IS GOING ON???
				--JESUS CRUST EVEN REMOVING ABSOLUTELY ALL HITBOX PROCEDURES EXCEPT THE LAUNCH CAUSES THIS TO HAPPEN
				--X KB- 14.66 BUT...ITS NORMALLY THAT MUCH ANYWAYS..... WHYYY????? -TOTAL-127
				--ALRIGHT. FORGET IT THEN. LETS TRY THIS.
				-- inst.components.hitbox:SetOnPreHit(function()  --NOPE. THIS ALSO DOESNT HELP
					-- inst.components.stats.opponent.components.launchgravity:Launch(0, 0, 0) --PERHAPS THIS WILL REFRESH WHATEVER WEIRD FORCE IS CAUSING THIS???
				-- end)
				
				
				inst.components.hitbox:SetHitFX("none", "dontstarve/wilson/attack_whoosh")
				
				inst.components.hitbox:SetOnPostHit(function()  --NOPE. THIS ALSO DOESNT HELP
					inst.components.locomotor:FaceWithMe(inst.components.stats.opponent)
				end)
				
				inst.components.hitbox:SpawnHitbox(1, 1, 0) 
			end),
			
			TimeEvent(24*FRAMES, function(inst)
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
			inst.AnimState:PlayAnimation("fair")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			inst.components.launchgravity:SetLandingLag(10)
		end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst)   --16
				-- inst.components.hitbox:MakeFX("glint_ring_1", 1.35, 0.6, 0.1,   1.2, 1.2,   0.5, 5, 0.8,  0, 0, 0,   1) 
				--(fxname, xoffset, yoffset, zoffset,    xsize, ysize,    alpha, duration, glow,   r, g, b,    stick, build, bank)
			
			end),
			
            TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(361) 
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(80)
				inst.components.hitbox:SetSize(0.8, 0.4)
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(1.95, 1, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				
				--WELL, NOW THAT HIS ANIMATION IS CHANGED, HE NO LONGER HAS ONE OF THESE!
				inst.components.hitbox:SetDamage(12)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(90)
				inst.components.hitbox:SetSize(0.35)
				inst.components.hitbox:SetLingerFrames(1) 
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SetHitFX("glint_ring_2", "default") --2
				
				inst.components.hitbox:SetOnHit(function() 
					-- inst.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
					-- inst.SoundEmitter:PlaySound("dontstarve/HUD/research_available")
					-- inst.components.hitbox:MakeFX("idle", 1.35, 0.6, 0.1,   1.5, 1.5,   0.5, 5, 0.8,  0, 0, 0,   1, "impact", "impact") 
				end)
				
				inst.components.hitbox:SpawnHitbox(3.35, 1, 0)
				
				inst:PushEvent("swaphurtboxes", {preset = "fair"})
				
			end),
			
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(361) 
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(80)
				inst.components.hitbox:SetSize(0.8, 0.4)
				inst.components.hitbox:SetLingerFrames(1) 
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetHitFX("default", "default") --SET IT BACK TO DEFAULT FOR THE REST OF THE HITBOXES
				
				inst.components.hitbox:SpawnHitbox(1.75, 0.4, 0) 

				inst.components.hitbox:SetDamage(12)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(90)
				inst.components.hitbox:SetSize(0.35)
				inst.components.hitbox:SetLingerFrames(1) 
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(2.85, 0.4, 0)
				
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(361) 
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(80)
				inst.components.hitbox:SetSize(0.8, 0.4)
				inst.components.hitbox:SetLingerFrames(1) 
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(0.75, 0.4, 0) 
				
			end),
		
			
            TimeEvent(17*FRAMES, function(inst)   --16
				-- inst.sg:RemoveStateTag("attack") 
				-- inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("air_idle")
			
			end),
        },
    },
	
	
	State{
        name = "bair",
        tags = {"attack", "busy", "ll_medium"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("bair")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst) 
				-- inst.components.launchgravity:SetLandingLag(12) 
				inst.components.launchgravity:SetLandingLag(10) 
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
				inst.components.hurtboxes:ShiftHurtboxes(0, 0.6)
				
				-- inst:PushEvent("swaphurtboxes", {preset = "grounded"})
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				-- inst.components.hitbox:MakeFX("punchwoosh", -1.2, 1.35, -0.2,   1.0, 1.0,   0.5, 4, 0.4,  0, 0, 0,   1) 
				
				inst.components.hitbox:SetDamage(12) 
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(35)
				inst.components.hitbox:SetGrowth(90)
				inst.components.hitbox:SetSize(0.55,0.85)
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(-0.7, 0.5, 0) 
			end),
			
			TimeEvent(4*FRAMES, function(inst) 

				inst.components.hitbox:SetSize(0.7, 1.1)
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(-1.9, 0.6, 0)  --(-2.4, 0.8, 0) 
			end),
			
			TimeEvent(5*FRAMES, function(inst) 

				inst.components.hitbox:SetSize(1.1, 0.65)
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(-2.4, 1.9, 0)   --(-2.4, 1.6, 0)
			end),
			
			TimeEvent(6*FRAMES, function(inst) 

				inst.components.hitbox:SetSize(1.1, 0.4)
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(-2, 3.0, 0) 
			end),
			
			
			TimeEvent(8*FRAMES, function(inst) 
				-- inst:PushEvent("swaphurtboxes", {preset = "air_idle"})
				-- inst.components.hurtboxes:ShiftHurtboxes(0, 0.6)
			end),
			
            TimeEvent(25*FRAMES, function(inst) 
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
        tags = {"attack", "busy", "no_fastfalling"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("dair") --flair4
			inst.components.launchgravity:SetLandingLag(14)
        end,
        
        timeline=
        {
			
			TimeEvent(1*FRAMES, function(inst) 
				inst.components.jumper:AirStall()
				inst.components.launchgravity:AirOnlyLaunch(0,6,0)
				-- inst.components.hitbox:MakeFX("raise", 0.0, 0.8, -0.2,   0.5, 0.5,   0.6, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
				
				inst.components.locomotor:SlowFall(0.2, 6) 
			end),
			
			TimeEvent(6*FRAMES, function(inst)  --IF HE TOUCHES THE GROUND BEFORE THE ACTUAL DOWNWARD PLUNGE, GO THROUGH NORMAL LANDING LAG
				inst.sg:AddStateTag("nolandingstop")
			end),
			
			TimeEvent(8*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(14)
				inst.components.hitbox:SetAngle(270) 
				inst.components.hitbox:SetBaseKnockback(25)
				inst.components.hitbox:SetGrowth(80)
				inst.components.hitbox:SetSize(0.5, 1)
				inst.components.hitbox:SetLingerFrames(10)
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(0, 0.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				-- inst.components.jumper:AirStall()
				inst.components.launchgravity:AirOnlyLaunch(0,-8,0)
				inst.components.jumper:FastFall()
			end),
			
			TimeEvent(18*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(12)
				inst.components.hitbox:SetAngle(65) 
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(80)
				inst.components.hitbox:SetSize(0.5, 0.8)
				inst.components.hitbox:SetLingerFrames(30)
				inst.components.hitbox:MakeDisjointed()
				
				inst.components.hitbox:SpawnHitbox(0, 0.4, 0) 
			end),
			
            TimeEvent(60*FRAMES, function(inst) 
				inst.sg:GoToState("air_idle")
			end),
        },
        
        events=
        {
            -- EventHandler("hit_ground", function(inst) --WAIT THIS SHOULDNT BE HERE
				-- print("STAR IS MY FAVORITE UGXIE HIGHLANDER FRIEND")
                -- inst.sg:GoToState("ll_medium_getup", 30)
            -- end),
			
			 EventHandler("ground_check", function(inst)  --hit_ground
				-- print("STAR IS MY FAVORITE UGXIE HIGHLANDER FRIEND")
                inst.sg:GoToState("ll_medium_getup", 22)
				inst.AnimState:PlayAnimation("dair_lag")
				
				-- inst:PushEvent("swaphurtboxes", {preset = "idle"})
				--ACTUALLY, ILL MAKE MY OWN
				inst.components.hurtboxes:ResetHurtboxes()
				inst.components.hurtboxes:SpawnHurtbox(0.0, 0.0, 0.35, 1.2)
				-- inst.components.hitbox:AddNewHit()
				
				inst.components.hitbox:SetDamage(4)
				inst.components.hitbox:SetAngle(60) --AAAAH WHATEVER, ILL FIX IT LATER
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(130)
				inst.components.hitbox:SetSize(1.0, 0.3)
				-- inst.components.hitbox:SpawnHitbox(0, -0.0, 0) 
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0, 0.0, 0) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				-- inst.sg:GoToState("ll_medium_getup", 10)
				-- inst:DoTaskInTime(0, function(inst) inst.sg:GoToState("ll_medium_getup", 10) end )
				
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				TheCamera:Shake("FULL", .20, .01, .2)
				inst.components.hitbox:MakeFX("ground_smash", 0, -0.1, 0.1, 1.5, 1.5, 1, 20, 0)
				inst.components.hitbox:MakeFX("ground_bounce", -0.2, 0.1, -1, 1, 1, 0.8, 7, 0)
				
            end),
        },
    },
	
	
	State{
        name = "nair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("nair")
			--inst.AnimState:PlayAnimation("uspecial")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.components.launchgravity:SetLandingLag(4)
            
        end,
        
        timeline=
        {
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(22)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.75, 0.35) --(0.75, 0.5) -- (1.5, 1)  --1.5
				
				inst.components.hitbox:SetLingerFrames(0)
				
				inst.components.hitbox:SpawnHitbox(0.35, 0.3, 0)
				
				
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(15)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(0.75, 0.35) --(0.75, 0.5) -- (1.5, 1)  --1.5
				
				inst.components.hitbox:SetLingerFrames(15)
				
				inst.components.hitbox:SpawnHitbox(0.35, 0.3, 0)
				
				inst.sg:RemoveStateTag("abouttoattack") 
			end),
			
            TimeEvent(25*FRAMES, function(inst) 
				inst.sg:GoToState("air_idle")
			
			end),
        },
    },
	
	
	State{
        name = "uair",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			
            inst.AnimState:PlayAnimation("uair")
            
			inst.components.launchgravity:SetLandingLag(8)
			
        end,
		
		onexit = function(inst)

        end,
        
        timeline=
        {
			TimeEvent(4*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(13)
				inst.components.hitbox:SetAngle(88)
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(78)
				inst.components.hitbox:SetSize(0.65, 1.0)
				inst.components.hitbox:SetLingerFrames(1)
				
				-- inst.components.hitbox:AddSuction(0.2, 0, 2.5)
				
				inst.components.hitbox:SpawnHitbox(0, 2.0, 0) --2.5
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				
				inst.components.hitbox:SetDamage(9)
				inst.components.hitbox:SetAngle(88)
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(78)
				inst.components.hitbox:SetSize(0.5, 0.8)
				inst.components.hitbox:SetLingerFrames(3)
				
				-- inst.components.hitbox:AddSuction(0.2, 0, 2.5)
				
				inst.components.hitbox:SpawnHitbox(0, 2.8, 0) --2.5
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(6*FRAMES, function(inst) 
				
			end),
			
            TimeEvent(30*FRAMES, function(inst) 
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
			inst.AnimState:PlayAnimation("jab1")
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			
			-- inst:PushEvent("swaphurtboxes", {preset = "leanf"})
            inst:PushEvent("swaphurtboxes", {preset = "idle"})
				
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst) 
				inst.components.hurtboxes:SpawnTempHurtbox(0.3, 1.5, 0.6, 0.8, 8)  --(xpos, ypos, size, ysize, frames, property)
				-- inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_fur_armour_dull")
				-- inst.components.hitbox:SetDamage(1)
				-- inst.components.hitbox:SetAngle(80)
				-- inst.components.hitbox:SetBaseKnockback(30)
				-- inst.components.hitbox:SetGrowth(100)
				-- inst.components.hitbox:SetSize(0.5, 0.8)
				-- inst.components.hitbox:SetLingerFrames(3)
				inst.components.hitbox:SetDamage(1)
				inst.components.hitbox:SetAngle(85)
				inst.components.hitbox:SetBaseKnockback(35)
				inst.components.hitbox:SetGrowth(10)
				inst.components.hitbox:SetSize(0.6, 0.8)
				inst.components.hitbox:SetLingerFrames(3)
				
				inst.components.hitbox:SpawnHitbox(0.75, 0.35, 0) --2.5				
			end),
			
			TimeEvent(4*FRAMES, function(inst) 
				inst.sg:AddStateTag("canjab")				
			end),
			TimeEvent(12*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("canjab")				
			end),
			
            TimeEvent(13*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("attack")
				-- inst.sg:RemoveStateTag("busy")	
				inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {
            EventHandler("attack_key", function(inst)
				if inst.sg:HasStateTag("canjab") then
					inst.sg:GoToState("jab2")
				end
				-- inst:PushEvent(inst.components.stats.event, {key = inst.components.stats.key, key2 = inst.components.stats.key2}) 
				inst.components.stats:SetKeyBuffer("throwattack", nil, nil, 8)
            end),
        },
    },
	
	State{
        name = "jab2",
        tags = {"attack", "listen_for_attack", "busy"},
        
        onenter = function(inst)

			inst.AnimState:PlayAnimation("jab2")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			inst.components.jumper:ScootForward(6)
			
        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst)	
				-- inst.components.hurtboxes:ShiftHurtboxes(0.5, 0) --12-19 THIS IS REALLY DUMB THAT I HAVE TO DO THIS
				
				inst.components.hitbox:SetAngle(70) --80
				inst.components.hitbox:SetBaseKnockback(20) --20
				inst.components.hitbox:SetGrowth(0) --100
				inst.components.hitbox:SetDamage(2)
				inst.components.hitbox:SetSize(0.4, 0.8)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SetHitFX("sidesplash_med_up2", "default") --2
				
				inst.components.hitbox.property = 4
				
				inst.components.hitbox:AddSuction(0.4, 0.6, 0)
				
				inst.components.hitbox:SpawnHitbox(0.6, 1.5, 0)
				
				-- inst.sg:AddStateTag("jab2") 
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.sg:AddStateTag("canjab")
			end),
			
            TimeEvent(16*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")				
				inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {
            EventHandler("attack_key", function(inst)
				if inst.sg:HasStateTag("canjab") then
					inst.sg:GoToState("jab3")
				end
            end),
        },
    },
	
	State{
        name = "jab3",
        tags = {"attack", "jab3", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jab3")
			
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
            -- inst:PushEvent("swaphurtboxes", {preset = "leanf"})
			inst.components.jumper:ScootForward(-4)
        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(1.2, 0.6)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(1.3, 1.7, 0) 
				
				-- inst.components.hitbox:MakeDisjointed()
				-- inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0)  
			end),
			
            TimeEvent(20*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
			end),
			TimeEvent(24*FRAMES, function(inst) 				
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	
	State{
        name = "dash_attack",
        tags = {"busy", "force_direction"},
        
        onenter = function(inst)
			inst.components.jumper:ScootForward(15)
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
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(100)
				inst.components.hitbox:SetGrowth(43)
				inst.components.hitbox:SetSize(0.6, 0.4)
				inst.components.hitbox:SetLingerFrames(3)
				
				inst.components.hitbox:SpawnHitbox(0.65, 0.2, 0) 
				
				
				inst.components.hitbox:SetDamage(4)
				inst.components.hitbox:SetSize(0.5)
				inst.components.hitbox:SetLingerFrames(10)
				inst.components.hitbox:SpawnHitbox(0.5, 0.2, 0) 
				
				inst.components.hitbox:MakeFX("slide1", 0.7, 0.2, 1, 1.2, 1.0, 1, 15, 0)
			end),
			
			
			TimeEvent(11*FRAMES, function(inst) 
				inst.AnimState:SetTime(17*FRAMES)
			end),
			
			TimeEvent(15*FRAMES, function(inst) inst:PushEvent("swaphurtboxes", {preset = "idle"}) end),
			
            TimeEvent(22*FRAMES, function(inst)  --30
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
		
			inst.AnimState:PlayAnimation("ftilt")
			
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst)
				-- inst.AnimState:SetTime(4*FRAMES) --SPEED UP THAT ANIMATION. FOOT DOESNT COME OUT FAST ENOUGH
				-- inst.components.hitbox:SetDamage(7)
				-- inst.components.hitbox:SetAngle(361)
				-- inst.components.hitbox:SetBaseKnockback(15) --8??? JEEZ
				-- inst.components.hitbox:SetGrowth(90) --100
				-- inst.components.hitbox:SetSize(1.0, 0.3)
				-- inst.components.hitbox:SetLingerFrames(0)
				-- inst.components.hitbox:SpawnHitbox(0.7, 0.95, 0) 
				
				
				--BASED OFF OF LINKS
				inst.components.hitbox:SetDamage(9)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(60) 
				inst.components.hitbox:SetGrowth(72) --100
				inst.components.hitbox:SetSize(1.3, 0.3)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(0.9, 0.95, 0)  
				
				inst:PushEvent("swaphurtboxes", {preset = "ftilt"})
			end),
			
			TimeEvent(6*FRAMES, function(inst)
				inst.components.hurtboxes:SpawnTempHurtbox(0.8, 0.6, 0.7, 0.5, 8)
			end),
			
            TimeEvent(18*FRAMES, function(inst) 
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
        name = "dtilt",
        tags = {"attack", "notalking", "busy", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dtilt")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			inst:PushEvent("swaphurtboxes", {preset = "ducking"})
            
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(7)
				inst.components.hitbox:SetAngle(70)
				inst.components.hitbox:SetBaseKnockback(60)
				inst.components.hitbox:SetGrowth(60)
				inst.components.hitbox:SetSize(0.5, 0.4)
				
				inst.components.hitbox:SpawnHitbox(0.5, 0.2, 0) 
			end),
			
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetAngle(50)
				inst.components.hitbox:SetBaseKnockback(65)
				inst.components.hitbox:SetGrowth(60)
				inst.components.hitbox:SetSize(0.85, 0.4)
				
				inst.components.hitbox:SpawnHitbox(1.5, 0.2, 0) 
				
			end),
			
            TimeEvent(14*FRAMES, function(inst) --7
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
        tags = {"attack", "busy"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("utilt")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			
			inst.components.hitbox:MakeFX("half_circle_backward_woosh", 0.3, 1.6, 0.1,  -2.5, 3.1,   1, 6, 0)
            
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("utilt")
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			end),
			
			TimeEvent(3*FRAMES, function(inst)
			
				inst.components.hitbox:SetDamage(8) --18 RYU'S
				inst.components.hitbox:SetAngle(82)
				inst.components.hitbox:SetBaseKnockback(65)
				inst.components.hitbox:SetGrowth(84)
				inst.components.hitbox:SetSize(0.6, 1.5) --2
				
				inst.components.hitbox:SpawnHitbox(0.9, 1, 0)
			end),
			
			TimeEvent(4*FRAMES, function(inst)
				inst.components.hitbox:SetSize(0.3)
				
				inst.components.hitbox:SpawnHitbox(1.5, 1.3, 0)
			end),

            TimeEvent(20*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			
			end),
        },
    },
	
	
	
	
	State{
        name = "nspecial",
        tags = {"attack", "movehand", "busy", "nolandingstop", "reducedairacceleration"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("nspecial")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			inst.components.stats.storagevar4 = math.min(inst.components.stats.storagevar4 + 1, 4)
			
        end,
		
        
        timeline=
        {
			
			TimeEvent(1*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("lower", -0.3, 1.3, 0.1,   0.1, 0.2,   1, 25, 0,  0, 0, 0,   0, "blocker_sanity_fx", "blocker_sanity_fx")
			end),
			
			TimeEvent(2*FRAMES, function(inst) 
				if inst.components.keydetector and inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
				inst.components.hitbox:MakeFX("lower", 0.1, 1.3, 0.1,   0.15, 0.2,   1, 25, 0,  0, 0, 0,   0, "blocker_sanity_fx", "blocker_sanity_fx")
			end),
			TimeEvent(3*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("lower", 0.6, 1.3, 0.1,   0.2, 0.2,   1, 25, 0,  0, 0, 0,   0, "blocker_sanity_fx", "blocker_sanity_fx")
			end),
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("lower", 1.2, 1.3, 0.1,   0.2, 0.2,   1, 25, 0,  0, 0, 0,   0, "blocker_sanity_fx", "blocker_sanity_fx")
			end),
			TimeEvent(5*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("lower", 1.8, 1.1, 0.1,   0.2, 0.2,   1, 25, 0,  0, 0, 0,   0, "blocker_sanity_fx", "blocker_sanity_fx")
			end),
			TimeEvent(6*FRAMES, function(inst) 
				-- inst.components.hitbox:MakeFX("lower", 2.1, 1.7, 0.1,   0.2, 0.2,   1, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
				inst.components.hitbox:MakeFX("lower", 2.6, 1.0, 0.1,   0.3, 0.3,   1, 25, 0,  0, 0, 0,   0, "blocker_sanity_fx", "blocker_sanity_fx")
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("lower", 3.2, 0.8, 0.1,   0.3, 0.3,   1, 25, 0,  0, 0, 0,   0, "blocker_sanity_fx", "blocker_sanity_fx")
			end),
			TimeEvent(8*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("lower", 4.0, 0.8, 0.1,   0.3, 0.3,   1, 25, 0,  0, 0, 0,   0, "blocker_sanity_fx", "blocker_sanity_fx")
			end),
			
			TimeEvent(9*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("lower", 5.0, 0.7, 0.1,   0.3, 0.3,   1, 25, 0,  0, 0, 0,   0, "blocker_sanity_fx", "blocker_sanity_fx")
			end),
			TimeEvent(10*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("lower", 6.6, 0.6, 0.1,   0.3, 0.3,   1, 25, 0,  0, 0, 0,   0, "blocker_sanity_fx", "blocker_sanity_fx")
				-- inst.components.hitbox:MakeFX("lower", 1.8, 0.8, 0.1,   0.3, 0.3,   1, 25, 0,  0, 0, 0,   0, "blocker_sanity_fx", "blocker_sanity_fx")
				-- inst.components.hitbox:MakeFX("square", 3.8, 0.8, -0.2,   4.8, 1.0,   0.1, 30, 0,   -0.5, -0.5, -0.5) 
			end),
			
			
			TimeEvent(14*FRAMES, function(inst) --12
				
					--4-24-20 HEY DONT FORGET TO SET THIS BEFORE CREATING A PROJECTILE
					inst.components.hitbox:SetProjectileDuration(35)
					
					--7-30-17 DST CHANGE, LETS MAKE IT SOMETHING ELSE THAT WORKS WITH DST PREFAB CREATION
					local skittle = SpawnPrefab("basicprojectile") --OH. THATS BETTER
					skittle:RemoveTag("deleteonhit") --OH RIGHT. BECAUSE ITS A PROJECTILE NOW
					skittle:RemoveTag("deleteonclank")
					skittle.components.stats.master = inst
					skittle.components.stats.team = inst.components.stats.team --1-18-22
					
					skittle:SetStateGraph("SGspookfire")
					--7-12-25 IT'S NOW DIFFERENT IF HE'S IN THE AIR
					if inst.components.launchgravity:GetIsAirborn() then
						skittle.sg:GoToState("fire_air")
					else
						skittle.sg:GoToState("fire")
					end
					skittle.AnimState:PlayAnimation("dontplayone") --lol    
					
					local x, y, z = inst.Transform:GetWorldPosition()
					skittle.Transform:SetPosition(x + (4 * inst.components.launchgravity:GetRotationValue()), y + 0, z + 0)
					skittle.Transform:SetScale(0.7, 0.7, 0.7)
					skittle.Physics:SetActive(false) 
					skittle.components.stats:TintTeamColor(0.6)
					--1-30-22
					skittle.components.stats.storagevar1 = inst.components.stats.storagevar4
					
					inst.components.locomotor:FaceWithMe(skittle) --FACE MY DIRECTION
					inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
					
			end),

			
            TimeEvent(40*FRAMES, function(inst) 
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
	
	
	
	State{
        name = "fspecial",
        tags = {"attack", "busy", "nolandingstop", "reducedairacceleration"}, --"movehand", 
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("tometest")
            -- inst.components.stats.storagevar1 = 6
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			inst.components.stats.storagevar1 = 4 --10-27-17 MAKING IT START A BIT CLOSER
        end,
		
		
		onupdate = function(inst)
			if inst.components.keydetector:GetSpecial(inst) or inst:HasTag("holdspecial") then 
				if inst.sg:HasStateTag("movehand") then
					-- inst.components.stats.storagevar1 = inst.components.stats.storagevar1 + 0.5
					inst.components.stats.storagevar1 = inst.components.stats.storagevar1 + 0.35 --10-27-17 SLOWING DOWN THE HAND MOVEMENT
				end
			elseif inst.sg:HasStateTag("ready") then
				
				inst.sg:GoToState("fspecial_hand")
				
			end
			if inst.sg:HasStateTag("movehand") then
				--WE'LL SPAWN A WHITE SHADOW AROUND THE BLACK ONE TO MAKE IT MORE OBVIOUS
				-- inst.components.hitbox:MakeFX("shadow", inst.components.stats.storagevar1, 0, -0.15,   3.5, 1.2,   1, 2, 1,  0, 0, 0,   2, "shadow_figures", "shadow_figures") 
				-- inst.components.hitbox:MakeFX("shadow", inst.components.stats.storagevar1, 0, 0.3,   3, 1,   1, 2, 0,  0, 0, 0,   2, "shadow_figures", "shadow_figures") 
				--10-29-17 DST CHANGE - THESE RAPIDLY SPAWNED FX DONT LOOK CORRECT CLIENTSIDE. LETS TRY SOMETHING ELSE
				inst.components.hitbox:MakeFX("shadow_outlined", inst.components.stats.storagevar1, 0, 0.3,   3, 1,   1, 2, 0,  0, 0, 0,   2, "shadow_figures", "shadow_figures")
			end
		end,
		
        
        timeline=
        {
           --SLOWLY SPAWN THE SHADOW TO GIVE PLAYERS TIME TO SEE WHERE IT IS SHOWING UP
			TimeEvent(1*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("shadow", inst.components.stats.storagevar1, 0, -0.15,   1, 0.3,   1, 2, 1,  0, 0, 0,   1, "shadow_figures", "shadow_figures") 
				inst.components.hitbox:MakeFX("shadow", inst.components.stats.storagevar1, 0, 0.3,   0.8, 0.2,   1, 2, 0,  0, 0, 0,   1, "shadow_figures", "shadow_figures") 
				if inst.components.keydetector:GetBackward(inst) then --IN CASE YOU HAD THE WRONG DIRECTION
					inst.components.locomotor:TurnAround()
				end
			end),
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("shadow", inst.components.stats.storagevar1, 0, -0.15,   2, 0.6,   1, 2, 1,  0, 0, 0,   1, "shadow_figures", "shadow_figures") 
				inst.components.hitbox:MakeFX("shadow", inst.components.stats.storagevar1, 0, 0.3,   1.8, 0.5,   1, 2, 0,  0, 0, 0,   1, "shadow_figures", "shadow_figures") 
			end),
			TimeEvent(3*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("shadow", inst.components.stats.storagevar1, 0, -0.15,   2.8, 0.9,   1, 2, 1,  0, 0, 0,   1, "shadow_figures", "shadow_figures") 
				inst.components.hitbox:MakeFX("shadow", inst.components.stats.storagevar1, 0, 0.3,   2.5, 0.7,   1, 2, 0,  0, 0, 0,   1, "shadow_figures", "shadow_figures") 
			end),
			
			TimeEvent(4*FRAMES, function(inst) --6
				inst.sg:AddStateTag("movehand")
			end),
			
			TimeEvent(8*FRAMES, function(inst) --12 --15
				inst.sg:AddStateTag("ready")
			end),
            TimeEvent(49*FRAMES, function(inst) 
				inst.sg:GoToState("fspecial_hand")

			end),
        },
        
        events=
        {
            -- EventHandler("animover", function(inst)
                -- --inst.sg:GoToState("idle")
            -- end),
        },
    },
	
	
	
	
	
	State{
        name = "fspecial_hand",
        tags = {"attack", "movehand", "force_trade", "busy", "nolandingstop", "reducedairacceleration"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("tometest_pt2")
			-- inst.components.stats.storagevar1 = inst.components.stats.storagevar1 * inst.components.launchgravity:GetRotationValue()
        end,
		
		
        
        timeline=
        {
           
			
			
			TimeEvent(0*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_icestaff")
				local camprefab = TheSim:FindFirstEntityWithTag("cameraprefab")
				camprefab.SoundEmitter:PlaySound("dontstarve/wilson/attack_icestaff")
				
				-- inst.components.jumper:ScootForward(8)
				-- inst.components.hitbox:MakeFX("handgrab", inst.components.stats.storagevar1, 0, -0.3,   -1.2, 1.2,   1, 30, 0,  0, 0, 0,   1, "shadow_figures", "shadow_figures") 
				inst.components.hitbox:MakeFX("handgrab", inst.components.stats.storagevar1, 0, -0.3,   -1.5, 1.5,   1, 8, 0,  0, 0, 0,   2, "shadow_figures", "shadow_figures") 
				--(fxname, xoffset, yoffset, zoffset,    xsize, ysize,    alpha, duration, glow,    r, g, b, stick, build, bank)        --^^^ MAKING THIS A 2. ITS MY NEW STUPID METHOD FOR INSTA-FADING FX
				inst.sg:RemoveStateTag("movehand")
			end),
			
			TimeEvent(8*FRAMES, function(inst) --9
				
				inst.components.hitbox:SetDamage(0) --25
				-- inst.components.hitbox:SetAngle(110)
				-- inst.components.hitbox:SetBaseKnockback(70)
				-- inst.components.hitbox:SetGrowth(50)
				inst.components.hitbox:SetAngle(110)
				inst.components.hitbox:SetBaseKnockback(0)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetSize(1.2, 0.7) --1
				inst.components.hitbox:SetLingerFrames(3)
				
				inst.components.hitbox:SetProperty(-5)
				-- inst.components.hitbox.property = 4
				
				inst.AnimState:SetTime(7*FRAMES)
				
				--10-27-16
				inst.components.hitbox:MakeFX("handgrab_retreat", inst.components.stats.storagevar1, 0, 0.3,   -1.55, 1.55,   1, 30, 0,  0, 0, 0,   0, "shadow_figures", "shadow_figures")
				local retreatingfx = inst.components.stats.lastfx --GRAB A REF OF THAT FX SO WE CAN REMOVE IT ON HIT
				
				inst.components.hitbox:SetOnHit(function() 
					--11-4-20 PROBABLY SHOULD HAVE HAD THIS IN HERE A WHILE AGO
					if inst.components.stats.opponent:HasTag("structure") or inst.components.stats.opponent:HasTag("nograbbing") then
						return end
						
						-- retreatingfx:Remove() --UR OUTTA HERE --NEVERMIND I NEED THAT
						retreatingfx.AnimState:SetTime(0*FRAMES)
						
						--11-11-17 LETS MAKE BOTH OF THEIR ENDLAGS A LITTLE LONGER IF THEY'VE HIT SOMEONE
						inst.sg:AddStateTag("hooked")
					
						inst.AnimState:SetTime(6*FRAMES)
						-- inst.components.hitbox:MakeFX("smoke_puff_1", -0.2, 0.6, 0.2,   2.3, 2.3,   0.8, 15, 0,  0.0, 0.0, 0.0)
						inst.components.hitbox:MakeFX("closedfist", inst.components.stats.storagevar1, 0, 0.3,   -1.55, 1.55,   1, 30, 0,  0, 0, 0,   0, "shadow_figures", "shadow_figures") 
						
						-- inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
						inst.SoundEmitter:PlaySound("dontstarve/common/destroy_pot")
						
					inst.components.stats.opponent.sg:GoToState("ragdoll", "restrained") --restrained
					
					local opponent = inst.components.stats.opponent
					local locationval = inst.components.stats.storagevar1 * inst.components.launchgravity:GetRotationValue()
					local sizescale = opponent.components.stats.sizemultiplier --10-13-20 LETS RESTORE THEM TO THEIR ACTUAL SIZE
					
					opponent.Transform:SetScale(sizescale,sizescale,sizescale)
					opponent.components.locomotor:FaceTarget(inst)
					opponent.Physics:Stop()
					opponent.components.launchgravity:Launch(0, 0, 0)
					opponent.Physics:SetActive(false)
					opponent.AnimState:Pause()
					local pos = Vector3(opponent.Transform:GetWorldPosition())
					local mypos = Vector3(inst.Transform:GetWorldPosition())
					
					opponent.Transform:SetPosition((mypos.x + locationval), (pos.y + 0.0), (pos.z))
					
					
					local del = 0 --DELAY FOR FINE TUNING
					
					-- inst:DoTaskInTime(4*FRAMES, function(inst)
						pos = Vector3(opponent.Transform:GetWorldPosition()) --RE-CALCULATES POS BECAUSE OF MOVEMENT
						-- opponent.Transform:SetPosition((pos.x), (pos.y + 0.2), (pos.z))
					-- end)
					opponent.Transform:SetPosition((pos.x), (pos.y + 0.3), (pos.z))
					inst:DoTaskInTime(1*FRAMES, function(inst)
						opponent.Transform:SetPosition((pos.x), (pos.y + 0.4), (pos.z))
					
					end)
					inst:DoTaskInTime(2*FRAMES, function(inst)
						opponent.Transform:SetPosition((pos.x), (pos.y + 0.6), (pos.z))
					end)
					
					inst:DoTaskInTime(3*FRAMES, function(inst) --4
						opponent.Transform:SetPosition((pos.x), (pos.y + 0.7), (pos.z))
					end)
					
					inst:DoTaskInTime(7*FRAMES, function(inst) --12
						opponent.Physics:SetActive(true)
						inst.components.stats.opponent.Physics:Stop()
					end)
					
					inst:DoTaskInTime(12*FRAMES, function(inst) --18
						opponent.Transform:SetScale(1,0.8,1)
						-- opponent.Physics:SetActive(true)
					end)
					
					inst:DoTaskInTime(13*FRAMES, function(inst) --19
						opponent.Transform:SetScale(1,0.4,1)
					
					end)
					
					inst:DoTaskInTime(14*FRAMES, function(inst) --20
						opponent.Transform:SetScale(1,0.0,1)
					end)
					
					
					
					inst:DoTaskInTime(15*FRAMES, function(inst) --25
						inst.components.hitbox:MakeFX("handgrab_slow", 1.5, 0, -0.3,   1.5, 1.5,   1, 8, 0,  0, 0, 0,   0, "shadow_figures", "shadow_figures") --SIZE USED TO BE 1, 1
						opponent.Transform:SetScale(1,0.1,1)
						mypos = Vector3(inst.Transform:GetWorldPosition())
						opponent.Transform:SetPosition((mypos.x + (1.5* inst.components.launchgravity:GetRotationValue())), (mypos.y + 0), (mypos.z))
					end)
					
					inst:DoTaskInTime(17*FRAMES, function(inst) --27
						opponent.Transform:SetScale(1,0.5,1)
					end)
					inst:DoTaskInTime(18*FRAMES, function(inst) --28
						opponent.Transform:SetScale(1,0.8,1)
					end)
					inst:DoTaskInTime(19*FRAMES, function(inst) --29
						-- opponent.Transform:SetScale(1,1,1)
						local sizescale = opponent.components.stats.sizemultiplier --10-13-20 LETS RESTORE THEM TO THEIR ACTUAL SIZE
						opponent.Transform:SetScale(sizescale,sizescale,sizescale)
					end)
					
					inst:DoTaskInTime(22*FRAMES, function(inst) --35
						opponent.AnimState:Resume()
						opponent.sg:GoToState("rebound", 33) --15
					end)
					
						
				end)
				
				
				inst.components.hitbox:SpawnHitbox(inst.components.stats.storagevar1, 1.2, 0) --0.6
				
			end),


			-- TimeEvent(15*FRAMES, function(inst) 
				-- inst.AnimState:SetTime(20*FRAMES)
			-- end),
			
			-- TimeEvent(25*FRAMES, function(inst) 
				-- inst.AnimState:SetTime(33*FRAMES)
			-- end),
			
			--10-27-17 OKAY, BUT AT THIS POINT, YOU SHOULD REALLY JUST SPEED UP THE ANIMATIONS
			--I THINK 30 FRAMES IS GOOD. BUT MAYBE THE ANIMATION IS QUICKER IF YOU MISS??
            TimeEvent(30*FRAMES, function(inst) --40
				if not inst.sg:HasStateTag("hooked") then --11-11-17 IF HE'S CAUGHT SOMEONE, MAKE THE ENDLAG A BIT LONGER
					inst.sg:GoToState("idle")
				end
			end),
			
			TimeEvent(36*FRAMES, function(inst)
					inst.sg:GoToState("idle")
			end),
        },
        
    },
	
	
	
	
	
	
	State{
        name = "uspecial",
        tags = {"attack", "nolandingstop", "busy", "can_grab_ledge", "no_air_transition", "ignoreglow"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("uspecial")
            inst:PushEvent("swaphurtboxes", {preset = "idle"})
        end,
		
		onupdate = function(inst)
			local up = 0
			local down = 0
			local forward = 0
			local backward = 0
			if inst.components.keydetector:GetUp(inst) then up = 0.35 end
			if inst.components.keydetector:GetDown(inst) then down = -0.35 end
			if inst.components.keydetector:GetForward(inst) then forward = 0.45 end
			if inst.components.keydetector:GetBackward(inst) then backward = -0.45 end
			
			
			if inst.sg:HasStateTag("teleporting") then
				inst.components.locomotor:Teleport((0+forward+backward), (0+up+down), 0)
				inst.Physics:Stop() --TO PREVENT FALLING DURING TELEPORTATION
			end
        end,
		
		onexit = function(inst)
			inst.Physics:SetActive(true)
			inst.components.hurtboxes:RemoveAllGrabboxes() --AND RESIZE THE LEDGEGRABBOXES
			inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 2.2, 1.5, 0.8, 0)
        end,
		
        
        timeline=
        {
		
			TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				if inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
				inst.components.launchgravity:AirOnlyLaunch(0, 7)
				inst.components.hurtboxes:RemoveAllGrabboxes() --CHANGE HIS LEDGEGRABBOXES A BIT
				inst.components.hurtboxes:CreateLedgeGrabBox(0.0, 2.0, 1.0, 0.8, 0) --(xpos, ypos, sizex, sizey, shape)
			end),
			
			TimeEvent(5*FRAMES, function(inst)
				-- inst.sg:AddStateTag("teleporting")
				inst.Physics:Stop() 
				-- inst.Physics:SetActive(false) --NO WAIT THIS CANNOT BE INACTIVE BECAUSE HE WILL PHASE THROUGH THE GROUND LIKE THIS
				-- inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
				-- inst.SoundEmitter:PlaySound("dontstarve/common/object_dissappear")
				-- inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_despawn")
				-- inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_appear")
				inst.SoundEmitter:PlaySound("dontstarve/maxwell/disappear")
				local fx = SpawnPrefab("maxwell_smoke")
				local pos = inst:GetPosition()
                fx.Transform:SetRotation(inst.Transform:GetRotation())
				local offset = (0.2*inst.components.launchgravity:GetRotationValue())
                fx.Transform:SetPosition( pos.x - offset, pos.y - .2, pos.z + 0.2 ) 
			end),
			
			TimeEvent(6*FRAMES, function(inst)
				inst.sg:AddStateTag("intangible")
			end),
			
			TimeEvent(9*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("invisible") --IT ISNT A REAL ANIMATION LOL
				inst.sg:AddStateTag("invisible")
			end),
			
			TimeEvent(10*FRAMES, function(inst)
				inst.sg:AddStateTag("teleporting")
			end),
			
			TimeEvent(29*FRAMES, function(inst) --GIVE PHYSICS A SEC TO REALIGN ITSELF
				inst.sg:RemoveStateTag("teleporting") 
				inst.components.locomotor:Teleport(0, 0.1, 0) --HOPEFULLY PREVENTS HIM FROM BEING TOO DEEP IN THE GROUND TO REGISTER LANDING --IT DOES!
			end),
			
			TimeEvent(30*FRAMES, function(inst)
				-- inst.sg:RemoveStateTag("teleporting")
				inst.sg:RemoveStateTag("intangible")
				inst.sg:RemoveStateTag("invisible")
				-- inst.SoundEmitter:PlaySound("dontstarve/common/rebirth_amulet_poof")
				-- inst.AnimState:PlayAnimation("uspecial")
				inst.SoundEmitter:PlaySound("dontstarve/maxwell/disappear")
				local fx = SpawnPrefab("maxwell_smoke")
				local pos = inst:GetPosition()
                fx.Transform:SetRotation(inst.Transform:GetRotation())
                local offset = (0.2*inst.components.launchgravity:GetRotationValue())
                fx.Transform:SetPosition( pos.x - offset, pos.y + .5, pos.z + 0.2 ) 
				inst.components.launchgravity:AirOnlyLaunch(0, 10)
				-- inst.AnimState:PlayAnimation("idle")
			end),
			
			TimeEvent(33*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("uspecial2")
			end),
			
			TimeEvent(34*FRAMES, function(inst)
				inst.sg:RemoveStateTag("nolandingstop")
			end),
			

			TimeEvent(45*FRAMES, function(inst) 
				inst.sg:GoToState("freefall")
			end),
        },
    },
	
	
	
	
	
	
	State{
        name = "dspecial",
        tags = {"busy", "nolandingstop"}, 
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dspecial")  
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			
			local fxtoplay = "book_fx"
                if inst.prefab == "waxwell" then
                    fxtoplay = "waxwell_book_fx" 
                end       
              
			
			if inst.components.stats.slave and inst.components.stats.slave:IsValid() then
				if inst.components.keydetector and inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
				
				--DONT LET THE CLONE WALK FORWARD IF THEY ARE BUSY OR AIRBORN
				if not (inst.components.stats.slave.sg:HasStateTag("busy") or inst.components.stats.slave.components.launchgravity:GetIsAirborn()) and not inst.components.launchgravity:GetIsAirborn() then
					inst.components.locomotor:FaceWithMe(inst.components.stats.slave)
					inst.components.stats.slave.sg:GoToState("stroll_forward")
					inst.sg:GoToState("command")
				elseif inst.components.stats.slave.components.launchgravity:GetIsAirborn() then
					inst.sg:GoToState("recall")
				else
					inst.sg:GoToState("idle")
					
					inst.components.stats.slave.components.stats.storagevar2 = 35
				end
			else
				inst.SoundEmitter:PlaySound("dontstarve/common/use_book")  --WHY DOES THE SOUND SEEM TO COME OUT FASTER IN THE SOUND TEST?...
			end
			
			
        end,
		
		onexit = function(inst)
			
			if inst.components.stats.slave and inst.components.stats.slave:IsValid() then
				if inst.sg:HasStateTag("cancel_clone") then
					inst.components.stats.slave.sg:GoToState("rise_cancel") --WILL THERE BE EXCEPTIONS THAT COULD CRASH THE GAME???
				end
			end
			
        end,
		
        timeline=
        {
			
			TimeEvent(0*FRAMES, function(inst)  --10
				-- inst.components.hitbox:MakeFX("book_fx_90s", -0.2, 0.6, -0.2,   0.8, 0.8,   1, 27, 0,  0,0,0, 1, "book_fx", "book_fx")
				-- inst.sg:AddStateTag("cancel_clone")
				inst.components.hitbox:MakeFX("shadow", 2.5, 0, 0.3,   2, 2,   0.5, 1, 0,  0, 0, 0,   1, "shadow_figures", "shadow_figures") 
			end),
			
			TimeEvent(1*FRAMES, function(inst)  --10
				-- inst.components.hitbox:MakeFX("book_fx_90s", -0.2, 0.6, -0.2,   0.8, 0.8,   1, 27, 0,  0,0,0, 1, "book_fx", "book_fx")
				inst.sg:AddStateTag("cancel_clone")
				inst.components.hitbox:MakeFX("shadow", 2.5, 0, 0.3,   3, 3,   0.8, 1, 0,  0, 0, 0,   1, "shadow_figures", "shadow_figures")
				-- inst.components.hitbox:MakeFX("idle_loop", 3.0, 0, 0.3,   1, 0.5,   0.6, 3, 0,  0, 0, 0,   1, "nightmarefuel", "nightmarefuel")				
			end),
			
			
			TimeEvent(2*FRAMES, function(inst) --14
				if inst.components.keydetector and inst.components.keydetector:GetBackward(inst) then
					inst.components.locomotor:TurnAround()
				end
				
				inst.components.hitbox:MakeFX("shadow", 2.5, 0, 0.3,   4, 4,   0.8, 4, 0,  0, 0, 0,   1, "shadow_figures", "shadow_figures")
				local maxclone = SpawnPrefab("newmaxwell") --HECK YA, WE CAN FINALLY USE THE REAL ONE
				
				--THIS SHOULD JUST HAPPEN BUT WHATEV
				maxclone:SetStateGraph("SGnewmaxwell")
				maxclone.AnimState:SetBank("newmaxwell")
				maxclone.AnimState:SetBuild("newmaxwellclone")
				
				inst.components.stats.buildname = "newmaxwellclone" --1-5-22
				maxclone:DoTaskInTime(1.2, function()
					maxclone.AnimState:SetBank("newmaxwell")
					maxclone.AnimState:SetBuild("newmaxwellclone")
				end)
				
				--12-31-21 FACE THE SAME DIRECTION AS US, PLEASE
				inst.components.locomotor:FaceWithMe(maxclone)
				
				--OK THE REST OF THIS CAN HAPPEN FOR BOTH VERSIONS
				maxclone:AddTag("nohud")
				maxclone:AddTag("maxclone")
				maxclone:AddTag("dummynpc") --9-14-17 DST TO DETIRMINE IF THE CHARACTER IS A LITERAL CHARACTER NOT CONTROLLED BY A USER
				maxclone:AddTag("customspawn") --DST I SHOULDNT NEED THIS ALSO BUT OH WELL
				
				
				
				
				inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_craft") 
				
				--I GUESS WE JUST CONSTANTLY RE-APPLY HIS COLOR VALUE
				maxclone:DoPeriodicTask(0, function()
					if maxclone.components.percent:GetPercent() > 60 then
						maxclone.AnimState:SetMultColour(0,0,0,0.40)
					else
						maxclone.AnimState:SetMultColour(0,0,0,0.7)
					end
				end)
				
				maxclone:DoPeriodicTask(15*FRAMES, function()
					maxclone.components.percent:DoSilentDamage(-1)
					if maxclone.components.percent:GetPercent() > 75 then
						if maxclone:IsValid() then
							-- TheWorld:PushEvent("ms_playerdespawnanddelete", maxclone)
							local x, y, z = maxclone.Transform:GetWorldPosition()
							SpawnPrefab("die_fx").Transform:SetPosition(x, y+1, z)
							maxclone.SoundEmitter:PlaySound("dontstarve/ghost/ghost_use_bloodpump")
							TheSim:FindFirstEntityWithTag("anchor").components.gamerules:KOPlayer(maxclone, "silent")
						end
					elseif maxclone.components.percent:GetPercent() > 60 then
						-- maxclone.components.hitbox:MakeFX("lower", 0, 2, 0.2,   0.2, 0.2,   0.8, 25, 0,  0, 0, 0,   0, "blocker_sanity_fx", "blocker_sanity_fx")
						maxclone.components.hitbox:MakeFX("smoke_puff_3", -0.0, 2, -0.2,   1.5, 1.5,   0.8, 8, 0,  0.0, 0.0, 0.0)
					end
					
					--inst.components.hitbox:MakeFX("lower", ((xrange) / 10), (math.random(3,7) / 10), 0.2,   0.2, 0.2,   0.8, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
					--TheSim:FindFirstEntityWithTag("anchor").components.gamerules:KOPlayer(inst, "silent")
				end)

				--1-5-22 IM BETTING ONLY THE HOST NEEDS TO RUN THIS
				if TheWorld.ismastersim then 
					
					maxclone.components.stats.master = inst
					inst.components.stats.slave = maxclone
					maxclone.components.stats.tapjump = inst.components.stats.tapjump --NEEDED FOR TAPJUMP STUFF
					--NEW STUFF TO PREVENT THEM FROM HITTING THE SAME ENEMY AT THE SAME TIME
					inst.components.stats.hitscorepartner = maxclone --DST CHANGE 9-7-17
					maxclone.components.stats.hitscorepartner = inst
					maxclone.components.stats.team = inst.components.stats.team --10-3-20 DONT FORGET THIS!
					maxclone.components.stats.lives = 1
					

					maxclone:ListenForEvent("right", function()
						if maxclone:HasTag("heel") then return end --1-18-22 DON'T LISTEN TO THESE KEYS IF HE'S TAKING HIS OWN CONTROL
						if inst:HasTag("listen_for_dashr") and inst:HasTag("listen_for_tapr") and not maxclone.sg:HasStateTag("dashing") and not maxclone.sg:HasStateTag("busy") then
							maxclone:PushEvent("dash")
							maxclone:AddTag("dashing")
						end
					end)
					
					maxclone:ListenForEvent("left", function()
						if maxclone:HasTag("heel") then return end 
						if inst:HasTag("listen_for_dash") and inst:HasTag("listen_for_tap") and not maxclone.sg:HasStateTag("dashing") and not maxclone.sg:HasStateTag("busy") then
							maxclone:PushEvent("dash")
							maxclone:AddTag("dashing")
						end
					end)
					
					inst:ListenForEvent("right", function() --9-14-17 MAXCLONE CAN'T HEAR OUR KEYPRESS EVENTS, SO NOW WE NEED TO RELAY THEM TO HIM
						if maxclone:HasTag("heel") then return end 
						maxclone:PushEvent("right") 
						if maxclone.sg:HasStateTag("dashing") then maxclone:PushEvent("dash_stop") end --9-20-17 SOMETHING SNEAKY TO REPLICATE A KEYHANDLER FN IN MODMAIN
					end)
					inst:ListenForEvent("left", function()
						if maxclone:HasTag("heel") then return end 
						maxclone:PushEvent("left")
						if maxclone.sg:HasStateTag("dashing") then maxclone:PushEvent("dash_stop") end
					end)
					inst:ListenForEvent("down", function() 			if maxclone:HasTag("heel") then return end  maxclone:PushEvent("down") end)
					inst:ListenForEvent("up", function() 			if maxclone:HasTag("heel") then return end  maxclone:PushEvent("up") end)
					inst:ListenForEvent("attack_key", function() 	if maxclone:HasTag("heel") then return end  maxclone:PushEvent("attack_key") end)
					inst:ListenForEvent("block_key", function() 	if maxclone:HasTag("heel") then return end  maxclone:PushEvent("block_key") end) --WAIT WHAT??? WHY DID I DO THIS???
					inst:ListenForEvent("forward_key", function() 	if maxclone:HasTag("heel") then return end  
						if inst.components.launchgravity:GetRotationFunction() == maxclone.components.launchgravity:GetRotationFunction() then
							maxclone:PushEvent("forward_key") 
						else
							maxclone:PushEvent("backward_key") 
						end
					end)
					inst:ListenForEvent("backward_key", function() 	if maxclone:HasTag("heel") then return end  
						if inst.components.launchgravity:GetRotationFunction() == maxclone.components.launchgravity:GetRotationFunction() then
							maxclone:PushEvent("backward_key") 
						else
							maxclone:PushEvent("forward_key") 
						end
					end)
					inst:ListenForEvent("duck", function()			if maxclone:HasTag("heel") then return end  maxclone:PushEvent("duck") end)
					-- inst:ListenForEvent("jump", function(inst, data)		if maxclone:HasTag("heel") then return end  maxclone:PushEvent("jump", {key = data and data.key or nil}) end)
					inst:ListenForEvent("throwattack", function(inst, data)	if maxclone:HasTag("heel") then return end  maxclone:PushEvent("throwattack", {key = data.key, key2 = data.key2 or nil}) end)
					
					
					-- --FOR THE GRAB KEY --ALRIGHT, THIS DOESNT WORK
					-- inst:ListenForEvent("attack_key", function() 
						-- if inst:HasTag("wantstoblock") then 
							-- -- maxclone:PushEvent("throwattack", {key = "block"})
							-- maxclone:AddTag("wantstoblock") 
							-- maxclone:PushEvent("attack_key")
						-- end
					-- end)
					
					
					
					maxclone:DoTaskInTime(1.3, function()
						maxclone.AnimState:SetBank("newmaxwell")
						maxclone.AnimState:SetBuild("newmaxwellclone")
						maxclone:RemoveTag("lockcontrols")
						maxclone.components.stats.basefallingspeed = inst.components.stats.basefallingspeed
						maxclone.components.stats.fallingspeed = inst.components.stats.fallingspeed
						maxclone.components.keydetector.controllerbound = inst.components.keydetector.controllerbound
						maxclone.components.keydetector.upanalog = inst.components.keydetector.upanalog
						
						maxclone:DoPeriodicTask(0, function() --9-14-17
							if maxclone:HasTag("heel") then return end 

							--ALRIGHT, LETS JUST TRANSFER ALL KEY-HOLDING VALUES TO MAXCLONE AT ALL TIMES
							if inst.components.keydetector.holdingleft == true then 
								maxclone.components.keydetector.holdingleft = true else maxclone.components.keydetector.holdingleft = false
							end
							if inst.components.keydetector.holdingright == true then 
								maxclone.components.keydetector.holdingright = true else maxclone.components.keydetector.holdingright = false
							end
							if inst.components.keydetector.holdingup == true then 
								maxclone.components.keydetector.holdingup = true else maxclone.components.keydetector.holdingup = false
							end
							if inst.components.keydetector.holdingdown == true then 
								maxclone.components.keydetector.holdingdown = true else maxclone.components.keydetector.holdingdown = false
							end
							if inst.components.keydetector.holdinggrab == true then 
								maxclone.components.keydetector.holdinggrab = true else maxclone.components.keydetector.holdinggrab = false
							end
							if inst.components.keydetector.holdingjump == true then --1-14-22
								maxclone.components.keydetector.holdingjump = true else maxclone.components.keydetector.holdingjump = false
							end
							
							if inst:HasTag("jump_key_dwn") then maxclone:AddTag("jump_key_dwn") else maxclone:RemoveTag("jump_key_dwn") end
							if inst:HasTag("atk_key_dwn") then maxclone:AddTag("atk_key_dwn") else maxclone:RemoveTag("atk_key_dwn") end
							if inst:HasTag("wantstoblock") then maxclone:AddTag("wantstoblock") else maxclone:RemoveTag("wantstoblock") end
							
							-- if inst.components.keydetector.holdingleft == false and inst.components.keydetector.holdingright == false and maxclone.sg:HasStateTag("dashing") then
								-- maxclone:PushEvent("dash_stop")
								-- maxclone:RemoveTag("wasrunning")
							-- end
							if maxclone.components.keydetector.holdingleft == false and maxclone.components.keydetector.holdingright == false and maxclone.sg:HasStateTag("dashing") then
								if not maxclone.sg:HasStateTag("sliding") then
									maxclone:PushEvent("dash_stop")
								end
								maxclone:RemoveTag("wasrunning")
							end
						end)
					end)
					
					maxclone:ListenForEvent("onko", function() --REMOVE SELF ON DEATH
						TheWorld:PushEvent("ms_playerdespawnanddelete", maxclone)
					end)
					inst:ListenForEvent("onko", function() --REMOVE CLONE ON DEATH
						if maxclone:IsValid() then
							TheWorld:PushEvent("ms_playerdespawnanddelete", maxclone)
						end
					end)
					
					local x, y, z = inst.Transform:GetWorldPosition()
					local anchor = TheSim:FindFirstEntityWithTag("anchor")
					anchor.components.gamerules:SpawnPlayer(maxclone, x+(3*inst.components.launchgravity:GetRotationValue()), y, z, true) --TRUE TO SPECIFY CUSTOM SPAWN
					maxclone.sg:GoToState("rise")
					--maxclone.components.percent:DoSilentDamage(-20)
				end
				
			end),
			
			TimeEvent(5*FRAMES, function(inst)  --12
				inst.components.hitbox:MakeFX("idle_loop", 2.8, 0, 0.3,   1.7, 0.7,   0.7, 15, 0,  0, 0, 0,   1, "nightmarefuel", "nightmarefuel")
			end),
			
			TimeEvent(20*FRAMES, function(inst)  
				inst.components.percent:DoSilentDamage(-1)
			end),
			TimeEvent(22*FRAMES, function(inst)  
				inst.components.percent:DoSilentDamage(-1)
			end),
			TimeEvent(25*FRAMES, function(inst)  
				inst.components.percent:DoSilentDamage(-1)
			end),
			TimeEvent(28*FRAMES, function(inst)  
				inst.components.percent:DoSilentDamage(-1)
			end),
			TimeEvent(30*FRAMES, function(inst)  
				inst.components.percent:DoSilentDamage(-1)
			end),
			TimeEvent(32*FRAMES, function(inst)  
				inst.components.percent:DoSilentDamage(-1)
			end),
			TimeEvent(35*FRAMES, function(inst)  
				inst.components.percent:DoSilentDamage(-1)
			end),
			TimeEvent(38*FRAMES, function(inst)  
				inst.components.percent:DoSilentDamage(-1)
			end),
			TimeEvent(40*FRAMES, function(inst)  
				inst.components.percent:DoSilentDamage(-1)
			end),
			TimeEvent(42*FRAMES, function(inst)  
				inst.components.percent:DoDamage(-1)
			end),
			
			TimeEvent(45*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("cancel_clone")
				inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_appear")
				inst.components.hitbox:MakeFX("glint_ring_1", 1.0, 2.4, 0.2,   1.5, 1.5,   1.0, 8, 0.0,  -1, -1, -1,   1) 
			end),
			
            TimeEvent(65*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
				
				-- local fx = SpawnPrefab("sanity_lower")
				-- local pos = inst:GetPosition()
				-- fx.Transform:SetPosition(pos.x, pos.y, pos.z)
				-- PlayFX(inst:GetPosition(), "blocker_sanity_fx", "blocker_sanity_fx", "lower") 
				-- inst.components.hitbox:MakeFX("punchwoosh", 0.6, 2.05, -0.3,   -1.0, 1.0,   0.5, 4, 0.4,  0, 0, 0,   1) 
				-- inst.components.hitbox:MakeFX("lower", 0.4, 1.4, 0,   1, 1,   1, 14, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx") --OH. IT'S JUST A SHORTER VERSION OF THE NEW ANIMATION.
				-- inst.components.hitbox:MakeFX("lower", 0.4, 1.4, 0,   1, 1,   1, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
				
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                --inst.sg:GoToState("idle")
            end),
        },
    },
	
	
	--THE STATE WHERE MAXWELL COMMANDS HIS CLONE TO WALK FORWARD
	State{
        name = "command",
        tags = {"busy", "nolandingstop"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("nspecial")
			inst.AnimState:SetTime(10*FRAMES)
			inst.components.locomotor:SlowFall(0.3, 40) 
			-- inst.SoundEmitter:PlaySound("dontstarve/common/rebirth_amulet_poof")
			-- inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_activate")
			-- inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_use_bloodpump")
			-- inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_appear")
			inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_activate", "magicsound")
        end,
		
		timeline=
        {
			TimeEvent(4*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("glint_ring_2", 0.0, 2.1, 0.2,   1.2, 1.2,   1.0, 8, 0.0,  -1, -1, -1,   1) 
			end),
			
			TimeEvent(8*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("glint_ring_2", 0.6, 2.1, 0.2,   1.2, 1.2,   1.0, 8, 0.0,  -1, -1, -1,   1) 
				inst.SoundEmitter:KillSound("magicsound")
			end),
			
			TimeEvent(12*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("glint_ring_2", 1.4, 2.1, 0.2,   1.2, 1.2,   1.0, 8, 0.0,  -1, -1, -1,   1) 
			end),
			
			TimeEvent(25*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
		
	},
	
	
	State{ --11-21-17 - VERY SIMILAR TO COMMAND EXCEPT YOU ARE CALLING IT TOWARD YOU
        name = "recall",
        tags = {"busy", "nolandingstop"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("recall")
			-- inst.AnimState:SetTime(10*FRAMES)
			
			-- inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_craft") 
			-- inst.SoundEmitter:PlaySound("dontstarve/common/rebirth_amulet_poof")
			-- inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_activate")
			inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_appear")
			inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_activate", "magicsound")
		
			
			--LET THEM KNOW THEYVE DONE SOMETHING
			inst.components.hitbox:MakeFX("glint_ring_2", 0.7, 2.9, 0.2,   1.2, 1.2,   1.0, 8, 0.0,  -1, -1, -1,   1) 
			inst.components.locomotor:SlowFall(0.3, 40) 
        end,
		
		timeline=
        {
			TimeEvent(4*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("glint_ring_2", 0.7, 2.4, 0.2,   1.2, 1.2,   1.0, 8, 0.0,  -1, -1, -1,   1) 
			end),
			
			TimeEvent(8*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("glint_ring_2", 0.7, 2.1, 0.2,   1.2, 1.2,   1.0, 8, 0.0,  -1, -1, -1,   1) 
				
				--FORGET ALL THIS WEIRD STUFF ABOUT HOLDING DOWN-B, JUST ACTIVATE IT ONCE AND LET IT COME TO YOU.
				if inst.components.stats.slave and inst.components.stats.slave:IsValid() then
					inst.components.stats.slave:AddTag("heel")
				end
				inst.SoundEmitter:KillSound("magicsound")
			end),
			
			
			TimeEvent(25*FRAMES, function(inst)  --IF YOU ARE STILL HOLDING THE SPECIAL KEY, GO RIGHT BACK INTO THE STATE
				-- if inst.components.keydetector:GetSpecial(inst) then
					-- inst.sg:GoToState("recall")
				-- else
				inst.sg:GoToState("idle")
				-- end
			end),
        },
		
	},
	
	
	
	State{
        name = "rise",
        tags = {"busy", "intangible", "nolandingstop", "no_air_transition", "ignoreglow"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("rise")
			inst.components.locomotor:SlowFall(0.3, 30) 
        end,
		
		timeline=
        {
			TimeEvent(16*FRAMES, function(inst)  --10
				inst.components.hitbox:MakeFX("idle_loop", 0.2, 0, 0.3,   1.0, 0.5,   0.6, 25, 0,  0, 0, 0,   1, "nightmarefuel", "nightmarefuel")				
			end),
			TimeEvent(36*FRAMES, function(inst)  --10
				inst.components.hitbox:MakeFX("idle_loop", 0.2, 0, 0.3,   0.7, 0.3,   0.5, 15, 0,  0, 0, 0,   1, "nightmarefuel", "nightmarefuel")				
			end),
            TimeEvent(55*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
			end),
			
			TimeEvent(65*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
        },
		
	},
	
	State{
        name = "rise_cancel",
        tags = {"busy", "intangible", "nolandingstop", "no_air_transition", "ignoreglow"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("rise_cancel")
			inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_despawn")
			inst.SoundEmitter:PlaySound("dontstarve/sanity/shadowhand_snuff")
        end,
		
		timeline=
        {
            TimeEvent(25*FRAMES, function(inst) 
				inst:CancelAllPendingTasks()
				--table.remove(self.livingplayers, k)
				if inst.components.stats:DSTCheck() then --10-18-17 IS THIS EVEN THE RIGHT WAY TO DESPAWN THE IN DST?
					local anchor = TheSim:FindFirstEntityWithTag("anchor")
					anchor.components.gamerules:RemoveFromPlayerTable(inst)
				else
					GetPlayer().components.gamerules:RemoveFromPlayerTable(inst) --10-18-17 HUN THIS AINT GONNA FLY IN DST
				end
				inst:Remove()
			end),
        },
		
	},
	
	
	State{
        name = "disperse",
        tags = {"busy", "intangible", "nolandingstop", "no_air_transition", "ignoreglow"},

        onenter = function(inst) --7-9-17 GET RID OF THE CLONE ON DEATH, OR ELSE IT WONT BE YOURS ANYMORE
			inst.AnimState:PlayAnimation("flinch2")
        end,
		
		timeline=
        {
            TimeEvent(5*FRAMES, function(inst) 
				inst.AnimState:PlayAnimation("none")
				inst.SoundEmitter:PlaySound("dontstarve/maxwell/disappear")
				local fx = SpawnPrefab("maxwell_smoke")
				local pos = inst:GetPosition()
				fx.Transform:SetRotation(inst.Transform:GetRotation())
				local offset = (0.2*inst.components.launchgravity:GetRotationValue())
				fx.Transform:SetPosition( pos.x - offset, pos.y - .2, pos.z + 0.2 ) 
			end),
			
			
			TimeEvent(8*FRAMES, function(inst) 
				inst:CancelAllPendingTasks()
				--table.remove(self.livingplayers, k)
				GetPlayer().components.gamerules:RemoveFromPlayerTable(inst)
				inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_despawn")
				inst:Remove()
			end),
        },
		
	},
	
	
	State{
        
        name = "stroll_forward",
        tags = {"moving", "running", "canrotate", "busy", "can_jump", "can_attack"}, --"ignore_ledge_barriers"
        
        onenter = function(inst) 
			inst.components.locomotor.throttle = 1
            inst.components.locomotor:RunForward()
			inst.AnimState:PlayAnimation("run")
			inst:PushEvent("swaphurtboxes", {preset = "walking"})
			inst.components.hitbox:MakeFX("glint", 0, 2.2, 0.2,   1.7, 1.7,   1.0, 8, 0.0,  -1, -1, -1,   1) 
        end,
        
        onupdate = function(inst)
            inst.components.locomotor:DashForward()
        end,

        timeline=
        {
            -- TimeEvent(4*FRAMES, function(inst) inst.components.hitbox:MakeFX("glint", 0, 2.2, 0.2,   1.7, 1.7,   1.0, 8, 0.0,  -1, -1, -1,   1)  end),
			TimeEvent(9*FRAMES, function(inst) inst.components.hitbox:MakeFX("glint", 0, 2.2, 0.2,   1.7, 1.7,   1.0, 8, 0.0,  -1, -1, -1,   1) end),
			TimeEvent(17*FRAMES, function(inst) inst.components.hitbox:MakeFX("glint", 0, 2.2, 0.2,   1.7, 1.7,   1.0, 8, 0.0,  -1, -1, -1,   1) end),
			-- TimeEvent(16*FRAMES, function(inst) inst.components.hitbox:MakeFX("glint", 0, 2.2, 0.2,   1.7, 1.7,   1.0, 8, 0.0,  -1, -1, -1,   1) end),
			
			
			TimeEvent(18*FRAMES, function(inst)
				inst.sg:GoToState("run_stop")
            end),
        },
        
        events=
        {   
            -- EventHandler("animover", function(inst) inst.sg:GoToState("run_stop") end ),        
        },
    },
	
	
	
	--FSMASH
	State{
        name = "fsmash_start",
        tags = {"busy", "scary"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("fcharge")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			inst.components.hitbox:SetDamage(16)
        end,
		
		timeline=
        {
            TimeEvent(6*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "ftilt"})
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
				inst.components.colourtweener:StartTween({1,0,0,1}, 1, nil)
				inst.components.visualsmanager:Shimmy(0, 0.02, 10)
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
           TimeEvent(1*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/HUD/health_up")
			end),
			
			TimeEvent(31*FRAMES, function(inst) 
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
        tags = {"attack", "notalking", "busy", "abouttoattack", "force_direction", "scary", "force_trade"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("fsmash")
			inst.components.stats.storagevar3 = inst.components.hitbox.dam --STORE THE DAMAGE AS A VARIABLE
        end,

        timeline=
        {
            TimeEvent(2*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(0.4, 0)
			end),
			
			TimeEvent(5*FRAMES, function(inst)
				inst:PushEvent("swaphurtboxes", {preset = "lunge"})
				inst.components.hurtboxes:ShiftHurtboxes(1.0, 0)
				
				
				inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
			
				-- inst.components.hitbox:SetDamage(16)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(115)
				inst.components.hitbox:SetSize(1, 0.5)
				inst.components.hitbox:SetLingerFrames(1)
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SetProperty(-6)
				-- inst.components.hitbox.property = 6
				
				inst.components.hitbox:SetOnHit(function() 
					inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_nightsword")
				end)
				
				inst.components.hitbox:SpawnHitbox(2, 0.9, 0) 
				
				inst.sg:RemoveStateTag("scary")
				
			end),
			
			TimeEvent(6*FRAMES, function(inst)
				
			
				-- inst.components.hitbox:SetDamage(14)
				inst.components.hitbox:SetDamage(inst.components.stats.storagevar3 * 0.875) --11-9-21
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(30)
				inst.components.hitbox:SetGrowth(115)
				inst.components.hitbox:SetSize((7/4), 0.5)
				inst.components.hitbox:SetLingerFrames(1)
				inst.components.hitbox:SetProperty(-6)
				-- inst.components.hitbox:MakeDisjointed()
				
				-- inst.components.hitbox:MakeFX("lucy_archwoosh", 3, 1, 1, 1, 1, 0.4, 8) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				
				inst.components.hitbox:SpawnHitbox(3.5, 0.9, 0) 

			end),
			
			TimeEvent(25*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(-0.5, 0)
			end),
			
			TimeEvent(35*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
				inst.components.hurtboxes:ShiftHurtboxes(0.5, 0)
			end),
			
			
            TimeEvent(40*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
				
				
			
			end),
        },
    },
	
	
	
	--DSMASH
	State{
        name = "dsmash_start",
        tags = {"busy", "scary"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("dsmash_charge")
			inst:PushEvent("swaphurtboxes", {preset = "idle"})
			inst.components.hitbox:SetDamage(10)  
			
        end,
		
		timeline=
        {
            TimeEvent(4*FRAMES, function(inst) 
				inst.sg:GoToState("dsmash_charge")
			end),
        },
		
	},
	
	State{
        name = "dsmash_charge",
        tags = {"attack", "scary", "d_charge", "busy"},
        --3-24-16 I GUESS CHARGINGDSMASH TAG HAS ITS USES IN PLAYER1CONTROLER
		--10-27-17 WAIT WHAT DO YOU MEAN?? I JUST SPENT THE LAST 30 MINUTES MAKING IT AN OBSOLETE TAG, MY OLD SELF BETTER BE WRONG ABOUT THAT
	
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
				-- inst.SoundEmitter:PlaySound("dontstarve/HUD/health_up")
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
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:SetAngle(31)
				inst.components.hitbox:SetBaseKnockback(70) --40
				inst.components.hitbox:SetGrowth(46)
				inst.components.hitbox:SetSize(0.7, 1.3)
				
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
				inst.components.hitbox:SetOnHit(function() 
					inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_nightsword")
				end)
				
				inst.components.hitbox:SetLingerFrames(2) --10
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.1, 0.6, 0)
			end),
			
			TimeEvent(3*FRAMES, function(inst)
				inst:PushEvent("swaphurtboxes", {preset = "dashing"})
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				TheCamera:Shake("FULL", .20, .01, .2) --Camera:Shake(type, duration, speed, scale) 
				inst.components.hitbox:MakeFX("anim", 1, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.components.hitbox:MakeFX("ground_smash", 1, 0.1, 0.1, -2, 1.5, 1, 12, 0)
			end),
			
			
			TimeEvent(10*FRAMES, function(inst)
				inst.AnimState:SetTime(12*FRAMES)
			end),
			
			TimeEvent(13*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(-1, 0)
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
				
				inst.components.hitbox:SetDamage((inst.components.hitbox.dam + 4))
				inst.components.hitbox:SetAngle(60) --48
				inst.components.hitbox:SetBaseKnockback(40) --40
				inst.components.hitbox:SetGrowth(100)
				
				inst.components.hitbox:AddNewHit()
				-- inst.components.hitbox:SetSize(0.8, 1.3)
				inst.components.hitbox:SetSize(1.1)
				inst.components.hitbox:SetLingerFrames(3) 
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-1.7, 0.5, 0)
			end),
			
			
			--LINGERING UPPER HIT
			TimeEvent(18*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage((inst.components.hitbox.dam + 0))
				inst.components.hitbox:SetAngle(60) --48
				inst.components.hitbox:SetBaseKnockback(40) --40
				inst.components.hitbox:SetGrowth(95) --THIS KILLS KINDA EARLY...
				
				inst.components.hitbox:SetSize(1.2, 0.7)
				inst.components.hitbox:SetLingerFrames(6) 
				inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(-2.3, 2.0, 0)
			end),
			
            TimeEvent(34*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack") 
				inst.sg:RemoveStateTag("busy") 
				inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	State{
        name = "usmash_start",
        tags = {"busy", "scary", "nopredict"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("usmash_charge")
			inst.components.hitbox:SetDamage(20)

        end,
		
		onexit = function(inst)
			inst.AnimState:Resume()
        end,
		
		timeline=
        {
			TimeEvent(1*FRAMES, function(inst) 
				-- inst.AnimState:SetTime(3*FRAMES) --STARTING AT FRAME 3 AND GOING BACKWARDS
			end),
			TimeEvent(2*FRAMES, function(inst) 
				-- inst.AnimState:SetTime(2*FRAMES)
			end),
			TimeEvent(4*FRAMES, function(inst) 
				-- inst.AnimState:SetTime(1*FRAMES)
				-- inst.AnimState:Pause()
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst:PushEvent("swaphurtboxes", {preset = "dashing"})
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
				-- inst.SoundEmitter:PlaySound("dontstarve/HUD/health_up")
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
			-- inst.components.hitbox:MakeFX("skitterbite", 0.4, 1.9, 0.3,   -0.8, 0.8,   1, 20, 0,  0, 0, 0,   0, "shadow_figures", "shadow_figures")
			inst.components.hitbox:MakeFX("skitterbite", 0.5, 1.9, 0.4,   -1.2, 1.2,   1, 20, 0,  0, 0, 0,   0, "shadow_figures", "shadow_figures") --NAH MAN. LETS MAKE THIS THING HUGE
        end,
		
        
        timeline=
        {
            TimeEvent(5*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_activate")
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
				inst.components.hurtboxes:SpawnTempHurtbox(-0.3, 2, 0.6, 0.8, 140)  --(xpos, ypos, size, ysize, frames, property)
				
			end),
			
			TimeEvent(8*FRAMES, function(inst)
				-- inst.SoundEmitter:PlaySound("dontstarve/tentacle/smalltentacle_attack")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/klaus/bite")
				inst.SoundEmitter:PlaySound("dontstarve/common/rebirth_amulet_poof")
				
				-- inst.components.hitbox:SetDamage(20)
				inst.components.hitbox:SetAngle(90)
				inst.components.hitbox:SetBaseKnockback(30) --50
				inst.components.hitbox:SetGrowth(85)
				
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox.property = -6 --JUST CUZ.
				inst.components.hitbox:SetSize(1)
				
				inst.components.hitbox:SetOnHit(function() 
					inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_use_bloodpump")
				end)
				inst.components.hitbox:AddSuction(0.6, 0.8, 2.8)
				
				inst.components.hitbox:SetLingerFrames(3)
				inst.components.hitbox:SpawnHitbox(0.6, 3.0, 0)
				
			end),
			
			
			TimeEvent(10*FRAMES, function(inst)
				inst.components.hitbox:SetAngle(90)
				inst.components.hitbox:SetBaseKnockback(30) --50
				inst.components.hitbox:SetGrowth(85)
				
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox.property = -6 --JUST CUZ.
				inst.components.hitbox:SetSize(1.3)
				
				inst.components.hitbox:SetOnHit(function() 
					inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_use_bloodpump")
				end)
				inst.components.hitbox:AddSuction(0.6, 0.8, 2.8)
				
				inst.components.hitbox:SetLingerFrames(3)
				inst.components.hitbox:SpawnHitbox(0.6, 4, 0)
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

