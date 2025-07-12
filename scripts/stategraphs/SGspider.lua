require("stategraphs/commonstates")
--require("stategraphs/fighterstates") --WILL THIS BE A PROBLEM


--KEY BUFFER  --7-5 ADDING TO HAROLD
local function TickBuffer(inst)
	inst:PushEvent(inst.components.stats.event, {key = inst.components.stats.key})
	inst.components.stats.buffertick = inst.components.stats.buffertick - 1
end

local events=
{
    --UPDATEING EVERYTHING
	EventHandler("update_stategraph", function(inst)
		
		--3-1-22 ACTUALLY, WILL THIS WORK? I'M CURIOUS TO TRY...
		if not TheWorld.ismastersim then
			return end
		
		local wantstoblock = inst:HasTag("wantstoblock")
		local is_tryingtoblock = inst.sg:HasStateTag("tryingtoblock")
		local is_blocking = inst.sg:HasStateTag("blocking")
		local is_parrying = inst.sg:HasStateTag("parrying") --1-3-22 I MIGHT BE WRONG, BUT I FEEL LIKE WE COULD DO WITHOUT THIS
		-- local no_blocking = inst.sg:HasStateTag("no_blocking") --THIS WAS SILLY
		local is_jumping = inst.components.launchgravity:GetIsAirborn()
        local is_busy = inst.sg:HasStateTag("busy")
		
		--CPU SPECIFIC STUFF
		--I TOOK A LOT OF STUFF OUT SO IT DOESNT GET CROWDED. BUT ADD MORE IN AS NEEDED
		
		if inst.components.stats.buffertick >= 1 then
			TickBuffer(inst)
		end
		
		--TELLS CPU WHEN TARGET HAS FINISHED A MOVE AND IS READY FOR A NEW ONE 
		if not is_busy and not is_blocking then
			inst:PushEvent("readyforaction") --ACTUALLY JUST FOR CPU
			if inst.components.stats.opponent then --and (inst.components.stats.opponent.components.stats.opponent and inst.components.stats.opponent.components.stats.opponent == inst) then
				inst.components.stats.opponent:PushEvent("targetnewstate")
			end
		end
		
		
        if is_busy then 
			return end
       
        -- local should_move = inst.components.locomotor:WantsToMoveForward()
        -- local should_run = inst.components.locomotor:WantsToRun()
		-- print("--I'M NOT BUSY!--", wantstoblock, is_tryingtoblock, is_jumping)
		if wantstoblock and not is_tryingtoblock and not is_jumping then --1-3-22 ADDED IS_JUMPING SO THEY WONT BLOCK MIDAIR
			inst.sg:GoToState("block_startup")
		end
		
		if is_tryingtoblock and not is_busy and not wantstoblock and not is_jumping then  --WHEN LAST LEFT OFF, WAS GETTING RID OF THIS SO PARRY DOESNT AUTO ATTACK
			--1-3-22 I FEEL LIKE I COULD PAIR THIS DOWN, I'M SURE THE PARRY STATE REMOVES THE BUSY TAG. BUT MAYBE FORCING HIM INTO IDLE HELPS JUMPSTART AN AGRESSIVE PUNISH BEHAVIOR
			--CHANGED MY MIND. F OFF --OH WAIT NO LOL I REMEMBER WHY THIS IS HERE NOW
			if is_parrying then
				inst.sg:GoToState("idle")
			else
				inst.sg:GoToState("block_stop")
			end
			-- inst.sg:GoToState("block_stop")
		end
	end),
	
	
	
	
	
	
	
	
	
	
	EventHandler("clearbuffer", function(inst)
		inst.components.stats.buffertick = 0
	end),
	
	
	--7-31 SINGLE JUMP FOR CPUS
	EventHandler("singlejump", function(inst, data)
		local is_busy = inst.sg:HasStateTag("busy")
		local can_jump = inst.sg:HasStateTag("can_jump")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local used_first_jump = inst.components.jumper.jumping == 1 and inst.components.jumper.doublejumping == 0
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		

		--1-5 NEW JUMP SYSTEM SO CRAP DOESNT HIT THE FAN WHEN TRYING TO LEAVEGROUND() ON LAUNCHES
		if (can_jump and not is_airborn) or (not is_busy and not is_airborn) or ((can_jump or can_oos or can_ood) and not is_airborn) then
			inst.sg:GoToState("highleap")
		end
	
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

		--1-5 NEW JUMP SYSTEM SO CRAP DOESNT HIT THE FAN WHEN TRYING TO LEAVEGROUND() ON LAUNCHES
		if (can_jump and not is_airborn) or (not is_busy and not is_airborn) or ((can_jump or can_oos or can_ood) and not is_airborn) then
			inst.sg:GoToState("highleap")
		elseif inst.components.jumper.currentdoublejumps >= 1 and (can_jump or not is_busy) then
			inst.sg:GoToState("doublejump")
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
		-- local pressing_down = inst.components.keydetector:GetDown()
		
		if no_grab_ledge and not autosnap then
			--DO NOTHING
		-- elseif (can_grab_ledge or (not is_busy and is_falling)) and not pressing_down and not inst:HasTag("hitfrozen") then
		elseif (can_grab_ledge or (not is_busy and is_falling)) and not inst:HasTag("hitfrozen") then --GETTING RID OF "PRESSING DOWN" FOR NOW
			inst.components.launchgravity:HitGround()
			inst.components.jumper.jumping = 0
			inst.components.jumper.doublejumping = 0
			inst.sg:GoToState("grab_ledge", data.ledgeref)
		end
	end),
	
	
	EventHandler("throwattack", function(inst, data)
	
		local airial = inst.components.launchgravity:GetIsAirborn()
		local can_attack = inst.sg:HasStateTag("can_attack")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		
		-- print("STATUS REPORT", data.key, can_ood)
		
		if can_oos or (data.key == "block" and (can_ood or not inst.sg:HasStateTag("busy")) and not airial) then
			inst.sg:GoToState("grab")
			inst:PushEvent("on_swing")
		elseif can_ood then
			-- (data.key == "block" and (can_ood or not inst.sg:HasStateTag("busy"))) then
			if data.key == "fspecial" then
				inst.sg:GoToState("fspecial")
			elseif data.key == "nspecial" then
				inst.sg:GoToState("nspecial")
			elseif data.key == "usmash" then
				inst.sg:GoToState("usmash_start")
			elseif data.key == "forward" then
				inst.sg:GoToState("ftilt")
			else
				-- print("WHAT AM I TO YOU??? -----------", inst.components.aifeelings.ailevel)
				if inst.components.aifeelings.ailevel <=3 then --DUMMIES GET THE BAD ATTACK
					inst.sg:GoToState("ftilt")
				else
					inst.sg:GoToState("dash_attack")
				end
			end
			inst:PushEvent("on_swing")
		elseif not inst.sg:HasStateTag("busy") or can_attack then
		
			if data.key == "fspecial" then
				inst.sg:GoToState("fspecial")
			elseif data.key == "nspecial" then
				inst.sg:GoToState("nspecial")
			elseif data.key == "uspecial" then
				inst.sg:GoToState("uspecial")
			
			elseif airial then
				if data.key == "forward" then
					inst.sg:GoToState("fair")
				elseif data.key == "up" then
					inst.sg:GoToState("uair")
				elseif data.key == "backward" then
					inst.sg:GoToState("bair")
				elseif data.key == "down" then
					inst.sg:GoToState("dair")
				else
					inst.sg:GoToState("nair")
				end
				inst.components.jumper:UnFastFall()
			elseif data.key == "fsmash" then
				-- inst.sg:GoToState("attack")
				inst.sg:GoToState("fsmash_start")
			elseif data.key == "usmash" then
				inst.sg:GoToState("usmash_start")
			elseif data.key == "down" then
				inst.sg:GoToState("dtilt")
			elseif data.key == "up" then
				inst.sg:GoToState("utilt")
			elseif data.key == "backward" then
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("dtilt")
			elseif data.key == "block" then
				inst.sg:GoToState("grab")
			else
				inst.sg:GoToState("jab1")
				-- inst.sg:GoToState("grab")
			end
			inst:PushEvent("on_swing")
		end
	
	end),
	
	
	--11-28-20 THE SPIDER NEEDS ONE FOR SPECIALS TOO
	EventHandler("throwspecial", function(inst, data)
		local can_special_attack = inst.sg:HasStateTag("can_special_attack")
	
		--10-18-17 NEW CHECKER THAT ALLOWS FOR UPSPEC JUMPCANCELING
		if not inst.sg:HasStateTag("busy") or can_special_attack or (inst.sg:HasStateTag("can_upspec") and (data.key == "up")) then
			if data.key == "forward" then
				inst.sg:GoToState("fspecial")
			elseif data.key == "up" then
				inst.sg:GoToState("uspecial")
			else
				inst.sg:GoToState("nspecial")
			end
			inst:PushEvent("on_swing")
		end
	end),
	
	
	--11-29-20 FOR SPIDERS ALSO
	EventHandler("cstick_up", function(inst)
		local airial = inst.components.launchgravity:GetIsAirborn()
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		
		if (inst.sg:HasStateTag("can_usmash") or can_ood) or (not inst.sg:HasStateTag("busy") and not airial) then --NO MORE USMASH OUT OF SHIELD. REPLACING WITH CANUPSMASH
			inst.sg:GoToState("usmash_start")
			inst:PushEvent("on_swing")
		elseif not inst.sg:HasStateTag("busy") and airial then
			inst.sg:GoToState("uair")
			inst:PushEvent("on_swing")
		end
	end),
	
	
	EventHandler("roll", function(inst, data) --7-1 NEW EVENT HANDLER
	
		local is_busy = inst.sg:HasStateTag("busy")
		local airial = inst.components.launchgravity:GetIsAirborn()
		local is_dashing = inst.sg:HasStateTag("dashing")
		local foxtrot = inst.sg:HasStateTag("foxtrot")
		local can_oos = inst.sg:HasStateTag("canoos")
		local was_running = inst:HasTag("wasrunning")
		
		-- print("ROLLING -----", can_oos)
		
		-- if foxtrot and inst.components.keydetector:GetBackward() then 
			-- inst.components.locomotor:TurnAround()
			-- inst.sg:GoToState("dash_start")
		-- end
		-- if can_oos and not was_running then
			-- inst.sg:GoToState("roll_forward")
		-- elseif can_oos and not was_running then
			-- inst.components.locomotor:TurnAround()
			-- inst.sg:GoToState("roll_forward")
		-- end
		
		if not airial and (can_oos or not is_busy) then
			-- print("ROLLING FOR REAL")
			if data.key == "forward" then
				inst.components.locomotor:FaceTarget(inst.components.stats.opponent)
				inst.sg:GoToState("roll_forward")
				-- print("ROLLING NEAR")
			else
				inst.components.locomotor:FaceTarget(inst.components.stats.opponent)
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("roll_forward")
				-- print("ROLLING FAR")
			end
		end
		
	end),
	
	
	
	
	EventHandler("attacked", function(inst, data)  --ADDING DATA
        -- if not inst.components.health:IsDead() then 
            if inst:HasTag("spider_warrior") or inst:HasTag("spider_spitter") then
                if not inst.sg:HasStateTag("attack") then -- don't interrupt attack or exit shield
                    -- inst.sg:GoToState("hit") -- can still attack
					inst.sg:GoToState("hit", data.hitstun)
                end
            elseif not inst.sg:HasStateTag("shield") then
                --inst.sg:GoToState("hit_stunlock")  -- can't attack during hit reaction --MAKING UNIVERSAL HIT STATE
				
				inst.sg:GoToState("hit", data.hitstun)
            end
        -- end 
		
		-- inst.components.locomotor.directwalking = false --I NEED TO STOP THE SPIDERS FROM AIRWALKING AFTER BEING HIT
		-- inst.components.locomotor:SetBufferedAction(nil)
		-- inst.components.locomotor:Stop()
		
    end),
	
	
	
	EventHandler("do_tumble", function(inst, data)
		inst.sg:GoToState("tumble", data.hitstun, data.direction) --ONLY SENDS THE HITSTUN DADA. DATA.DIRECTION DOES NOTHING
	end),
	
	
    EventHandler("doattack", function(inst, data) 
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") and data and data.target  then 
            if inst:HasTag("spider_warrior") and
            inst:GetDistanceSqToInst(data.target) > TUNING.SPIDER_WARRIOR_MELEE_RANGE*TUNING.SPIDER_WARRIOR_MELEE_RANGE then
                --Do leap attack
                inst.sg:GoToState("warrior_attack", data.target) 
            elseif inst:HasTag("spider_spitter") and
            inst:GetDistanceSqToInst(data.target) > TUNING.SPIDER_SPITTER_MELEE_RANGE*TUNING.SPIDER_SPITTER_MELEE_RANGE then
                --Do spit attack
                inst.sg:GoToState("spitter_attack", data.target)
            else
                inst.sg:GoToState("attack", data.target) 
            end
        end 
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    EventHandler("entershield", function(inst) inst.sg:GoToState("shield") end),
    EventHandler("exitshield", function(inst) inst.sg:GoToState("shield_end") end),
	
	
	
	
	
	
	
	
	
	
	
	
	--7-19 NEW EVENT FOR CPU DASHING BC DASHING IS KINDA WIERD FOR THEM
	EventHandler("dash", function(inst)
		local is_busy = inst.sg:HasStateTag("busy")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local is_dashing = inst.sg:HasStateTag("dashing")
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		-- print("MUSH, YA LAZY MONGREL!", is_busy, is_dashing)
		
		--CAN_OOS? ARE YOU SURE?...
		if (can_oos or can_ood or not is_busy) and not is_airborn and not is_dashing then
			inst.sg:GoToState("dash")
		end
	
	end),
	
	
	--1-16-22 ANOTHER WEIRD MANUAL CPU THING 
	EventHandler("dash_stop", function(inst)
		local is_dashing = inst.sg:HasStateTag("dashing")
		local is_sliding = inst.sg:HasStateTag("sliding")

		if is_dashing and not is_sliding then
			inst.sg:GoToState("dash_stop")
		end
	
	end),
	
	
	--8-7
	EventHandler("block_key", function(inst)
		local is_busy = inst.sg:HasStateTag("busy")
		-- local can_oos = inst.sg:HasStateTag("canoos")
		-- local can_ood = inst.sg:HasStateTag("can_ood")
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		
		if (not is_busy) and is_airborn then
			inst.sg:GoToState("airdodge")
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
		
		
		if is_jumping then
			--inst.components.locomotor:FlyForward() --OH MAN
		elseif is_moving and not should_move and not no_running then
            -- if is_running then
                -- inst.sg:GoToState("run_stop")
            -- else
                -- inst.sg:GoToState("walk_stop")
            -- end
		end
		
		
		if not inst.sg:HasStateTag("busy") then
            
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
			local no_running = inst.sg:HasStateTag("no_running")
			
			
            if not inst.sg:HasStateTag("attack") and not is_jumping and is_moving ~= wants_to_move then
                if wants_to_move and not no_running then
                    inst.sg:GoToState("premoving")
                else
                    -- inst.sg:GoToState("idle")
                end
            end
			
        end
		
    end),   


	EventHandler("respawn", function(inst, data)
		inst.sg:GoToState("respawn_platform")
	end),
	
	
	EventHandler("taunt", function(inst, data)
		local is_busy = inst.sg:HasStateTag("busy")
		local is_jumping = inst.components.launchgravity:GetIsAirborn()
		local is_running = inst.sg:HasStateTag("running")
		
		if not is_jumping and (not is_busy or is_running) then
			inst.sg:GoToState("taunt")
			inst:PushEvent("on_swing")
		end
	end),
	
	
	--6-30-18 --LOL TAKE A NAP
	EventHandler("sleep", function(inst, data)
		local is_busy = inst.sg:HasStateTag("busy")
		local is_jumping = inst.components.launchgravity:GetIsAirborn()
		local is_running = inst.sg:HasStateTag("running")
		
		if not is_jumping and (not is_busy or is_running) then
			inst.sg:GoToState("sleep")
			inst:PushEvent("on_swing")
			inst:DoTaskInTime(4, function(inst) --CAREFUL ABOUT USING THESE IN STATEGRAPH EVENTS... THINGS COULD GET MESSY BETWEEN STATE TRANSITIONS
				inst:PushEvent("wakeup") --IT SHOULD BE FINE IF YOU JUST PUSH AN EVENT THO
			end)
		end
	end),
	
	EventHandler("wakeup", function(inst, data)
		if inst.sg:HasStateTag("sleeping") then
			inst.sg:GoToState("wake")
		end
	end),
	
	
	EventHandler("outofhp", function(inst, data)
		-- print("IM DEAD!!!")
		-- inst.brain:Stop()
		inst.components.aifeelings:HostBrainContact(inst, "stop") --THIS ONE WORKS IN DST, BLOCKS CLIENTS FROM ENTERING 4-5-19 DST
		-- inst.sg:GoToState("death")
		-- inst:CancelAllPendingTasks() --THIS COULD CAUSE SOME GOOFY BUGS
		
		--STOP DRIFTING AWAY!!
		inst:RemoveTag("holdleft")
		inst:RemoveTag("holdright")
		
		inst:DoTaskInTime(0, function(inst)
			inst.sg:GoToState("death")
		end)
	end),
}

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

local states=
{
    
    
    -- State{
        -- name = "death",
        -- tags = {"busy"},
        
        -- onenter = function(inst)
            -- inst.SoundEmitter:PlaySound(SoundPath(inst, "die"))
            -- inst.AnimState:PlayAnimation("death")
            -- inst.Physics:Stop()
            -- RemovePhysicsColliders(inst)            
            -- inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
        -- end,

    -- },    
	
	
	
	State{
        name = "death",
        tags = {"busy", "intangible", "no_air_transition", "nolandingstop", "ll_medium", "ignoreglow"},
        
        onenter = function(inst)
            inst.SoundEmitter:PlaySound(SoundPath(inst, "die"))  
			inst.AnimState:PlayAnimation("death") 			
			-- inst:CancelAllPendingTasks() --THIS COULD CAUSE SOME GOOFY BUGS
			-- inst:DoTaskInTime(0, function(inst)
			inst.AnimState:SetMultColour(0.5,0.5,0.5,1)
			
			inst.components.launchgravity:SetLandingLag(40, "ll_bair")
			
			
        end,
		
		onexit = function(inst)
            -- inst.sg:GoToState("death")	--THERE IS NO ESCAPE >:3c --oops this is an infinate loop
			-- inst:PushEvent("outofhp") --CLOSE ENOUGH, I GUESS
			-- inst:Remove() --I GUESS?... --NO NO, LET THE UTILITY EVENT HANDLERS TAKE CARE OF THIS
			-- TheWorld:PushEvent("ms_playerdespawnanddelete", inst) --DST CHANGE -HIDE THE BODY!
			TheSim:FindFirstEntityWithTag("anchor").components.gamerules:KOPlayer(inst, "silent")
			-- inst:PushEvent("outoflives") --ASSUMING THAT IF THEYRE IN THIS STATE, THEY ONLY HAD 1 LIFE TO BEGIN WITH
		end,
		
		timeline=
        {
            TimeEvent(12*FRAMES, function(inst) 
				local x, y, z = inst.Transform:GetWorldPosition()
				-- Death FX
				SpawnPrefab("die_fx").Transform:SetPosition(x, y, z)
			end),
			
			-- TimeEvent(25*FRAMES, function(inst) 
				-- inst.components.hitbox:MakeFX("smoke_puff_1", 0.0, 0.6, 0.2,   2.0, 2.0,   0.8, 10, 0,  0.5, 0.5, 0.5,   1)
			-- end),
			
			TimeEvent(13*FRAMES, function(inst) 
				-- TheSim:FindFirstEntityWithTag("anchor").components.gamerules:KOPlayer(inst, "silent")
				inst.sg:GoToState("decay")
			end),
        },
    }, 
	
	--6-10-18 A STATE WHERE THEY ARE "DEAD" BUT NOT YET REMOVED FROM THE WORLD,
		--SINCE GAMERULES TAKES 2 SECONDS TO DECIDE WETHER OR NOT TO RESPAWN THEM
		--BUT WE DONT WANT THEIR BODY LAYING AROUND FOR SO LONG, IT MIGHT CONFUSE THE PLAYER
	State{
        name = "decay",
        tags = {"busy", "intangible", "no_air_transition", "nolandingstop", "ll_medium", "ignoreglow"},
        onenter = function(inst)
			inst.AnimState:SetMultColour(0,0,0,0) --MAKE THEM INVISIBLE SO THE PLAYER DOESNT THINK THEYRE ALIVE
        end,
		timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 
				-- inst.AnimState:PlayAnimation("death")
			end),
        },
    }, 
	
	
	
	
	
	
	
	State{
        name = "block_startup", 
        tags = {"busy", "tryingtoblock", "blocking", "can_parry", "canoos"},
        
        onenter = function(inst, target)
			-- inst.AnimState:PlayAnimation("block_startup")
			inst.AnimState:PlayAnimation("cower" )
        end,
        
        timeline =
        {
			--11-17, CHANGING TO FRAME 1 ACTIVATION TO MATCH SMASH GAMES
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
			-- inst.AnimState:PlayAnimation("block")
			inst.AnimState:PlayAnimation("cower_loop" )
			
			inst.components.blocker:StartConsuming()
        end,
    },
	
	
	State{
        name = "parry",
        tags = {"canrotate", "blocking", "tryingtoblock", "parrying", "busy"},
        
        onenter = function(inst, timeout)
			-- inst.components.hitbox:MakeFX("shockwave_parry", 0.5, 1.5, 1, 1.5, 1, 1, 8)
			inst.components.hitbox:MakeFX("shockwave_parry", 0.5, 1.5, 1, 1, 1.8, 1, 12, 1)
			inst.AnimState:PlayAnimation("cower_loop")
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
	
	
	-- State{
        -- name = "block_stunned",
        -- tags = {"blocking", "tryingtoblock", "busy", "block_stunned"},  --"attack", "busy", "jumping"
        
        -- onenter = function(inst, target)
			-- -- inst.AnimState:PlayAnimation("blockstunned_long")
			-- inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_dull")
        -- end,

        -- timeline =
        -- {
			-- TimeEvent(50*FRAMES, function(inst)   --FOR THE LOVE OF GOD FIX THIS ALREADY
				-- if inst:HasTag("wantstoblock") then
					-- inst.sg:GoToState("block_unstunned")
				-- else
					-- inst.sg:GoToState("block_stop")
				-- end
			-- end),
        -- },
    -- },
	
	State{
        name = "block_stunned", --7-6 LAST LEFT OFF UPDATING THIS BLOCKSTUN STATE TO THE NEW ONE BC I THINK HE WAS GETTING STUCK IN A NON "CANOOS" BLOCK STATE
        tags = {"blocking", "tryingtoblock", "busy", "block_stunned"},  --"attack", "busy", "jumping"
        onenter = function(inst, timeout)
			inst.AnimState:PlayAnimation("cower_loop") --blockstunned_long
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
			-- inst.AnimState:PlayAnimation("blockstunned_resume")
			--inst.AnimState:SetMultColour(1,1,0,1)
			if inst:HasTag("wantstoblock") then
				inst.sg:GoToState("block")
			else
				inst.sg:GoToState("block_stop")
			end
        end,

        
        timeline =
        {
			TimeEvent(2*FRAMES, function(inst)
				-- if inst:HasTag("wantstoblock") then
					-- inst.sg:GoToState("block")
				-- else
					-- inst.sg:GoToState("block_stop")
				-- end
			end),	
    
        },
    },
	
	State{
        name = "block_stop",  
        tags = {"tryingtoblock", "busy", "canoos"},  --YOU KNOW WHAT. LETS JUST GIVE HIM ONE FRAME OF "CAN_OOS" TO LET HIM DO ALL THAT GRABBY STUFF BEFORE DROPPING SHIELDS
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("cower_pst") --block_drop
        end,
		
		onupdate = function(inst)
			--CHEAP HOTFIX TO ENSURE THIS STATE DOESN'T ADD EXTRA FRAMES TO THE ENDLAG
        end,
        
        timeline =
        {
			TimeEvent(1*FRAMES, function(inst) --ONLY HAROLD GETS THIS ONE FRAM OF CANOOS ON HIS BLOCK-STOP STATE
				inst.sg:RemoveStateTag("canoos")
				
				-- inst.brain:Start() --1-2-17 LETS TRY JUMP-STARTING HIS BRAIN, BECAUSE SOMETIMES IT TAKES A SECOND FOR HIS BRAIN CYCLE TO GET BACK TO CHASEANDFIGHT --HMM, NO, IT RESETS BEHAVIOR VARIABLES...
				-- inst.brain:ForceUpdate() --THERE WE GO >:3c   1-7-17 --NOPE NEVERMIND IT DOESN'T WORK
				-- inst.brain:OnStart() --THEEEERE WE GO  --1-18-17 NNNOOOOOPE, ALSO DOESNT WORK
				-- inst.brain:ForceRefresh() --1-18-17 THEEEEEEEEEERE WE GO
				inst.components.aifeelings:HostBrainContact(inst, "refresh") --THIS ONE WORKS IN DST, BLOCKS CLIENTS FROM ENTERING 4-5-19 DST
			end),
			
			TimeEvent(3*FRAMES, function(inst) --6
				inst.sg:GoToState("idle")
				inst.components.stats:PushMoveBuffer()
				-- inst.AnimState:SetMultColour(1,1,0,1)
			end),
        },
    },
	
	
	State{
        name = "brokegaurd",  
        tags = {"busy", "intangible", "dizzy", "ignoreglow", "noairmoving"},
		
        onenter = function(inst, target)

			inst.AnimState:PlayAnimation("death")
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
					inst.AnimState:SetAddColour(1,0.5,0,0.6)
					inst.sg:RemoveStateTag("busy")
				end),
        },
    },
	
	State{
        name = "dizzy",  
        tags = {"dizzy", "busy"},  
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("death")
			inst.components.hitbox:MakeFX("stars", 0.5, 2.5, 1, 1, 1, 1, 65, 0.2)
        end,
		
		onexit = function(inst)
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
				inst.components.hitbox:MakeFX("stars", 0.5, 2.5, 1, 1, 1, 1, 65, 0.2)  --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
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
        name = "roll_forward", 
        tags = {"dodging", "busy"},  
        
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
            --TimeEvent(0*FRAMES, function(inst) self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0) end),
			
           -- -- TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
		   
			TimeEvent(1*FRAMES, function(inst)
				inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
				inst.sg:AddStateTag("intangible")
				-- inst.task_1 = inst:DoPeriodicTask(0.1, function(inst)
					-- inst.Physics:SetMotorVel(-14, 0, 0)
				-- end)
		    end),
		      
			  
			 TimeEvent(2*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0, -0.2,   1.0, 1.0,   0.6, 8, 0)
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
				inst.components.jumper:ScootForward(-10)
			end),
			
            TimeEvent(14*FRAMES,
				function(inst)
				--CHECK FOR IF STILL HOLDING SHEILD  --TODOLIST
					inst.sg:RemoveStateTag("busy")
					inst.sg:RemoveStateTag("dodging")
					inst:PushEvent("finishrolling") --8-14
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
	
	
	
	
	
	
    
    State{
        name = "premoving",
        tags = {"moving", "running", "canrotate"},
        
        onenter = function(inst)
            -- inst.components.locomotor:WalkForward()
			inst.components.locomotor.throttle = 0
			inst.components.locomotor:RunForward()
			-- inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")

        end,
        
        timeline=
        {
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider")) end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },
    
    State{
        name = "moving",
        tags = {"moving", "running", "canrotate", "ignore_ledge_barriers"},
        
        onenter = function(inst)
            -- inst.components.locomotor:RunForward()
			local ang = 180 --inst.Transform:GetRotation()
			-- inst.components.locomotor:RunInDirection(ang, true) --2-15
			-- inst.components.locomotor.throttle = 0
			-- inst.components.locomotor:RunForward()
			
            inst.AnimState:PushAnimation("walk_loop")
        end,
		
		onupdate = function(inst)
			-- if inst.components.keydetector:GetForward() then
				-- inst.components.locomotor:WalkForward()
				inst.components.locomotor:RunForward()
				local ang = inst.Transform:GetRotation()
			inst.components.locomotor:RunInDirection(ang) --2-15
			-- end
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
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
        
    },
	
	
	State{
        name = "run_stop", --8-14 IM MAKIN THIS SIGNIFICANTLY DIFFERENT THAN THE SINGLE PLAYER VERSION
        tags = {"canrotate", "busy", "can_grab_ledge"}, --, "idle", "candash"}, 
        
        onenter = function(inst) 
           
            inst.AnimState:PlayAnimation("walk_pst") --eat_pst
        end,
		
		timeline=
        {
        
            TimeEvent(4*FRAMES, function(inst)
                inst.sg:GoToState("idle")
            end),
        },
        
    },
	
	
	
	
	--DASHING
	State{
        
        name = "dash_start",
        tags = {"moving", "running", "canrotate", "dashing", "can_usmash", "can_special_attack", "can_ood", "busy", "can_dashdance", "foxtrot", "must_fsmash", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
			inst.components.locomotor.throttle = 0
			inst.components.locomotor:DashForward()
			inst.AnimState:PlayAnimation("walk_loop")
			
			inst.components.hitbox:MakeFX("dahswoosh", 0.5, 1.5, 1, 1, 1, 0.8, 7, 1)
			inst.components.hitbox:MakeFX("slide1", 0.5, 0, 0.1, 0.5, 0.5, 1, 10, 0)
			
			-- inst:PushEvent("swaphurtboxes", {preset = "dashing"})
        end,
        
        -- onupdate = function(inst)
			-- if inst.components.keydetector:GetForward() then
				-- inst.components.locomotor:DashForward()
			-- end
        -- end,

        timeline=
        {
			-- TimeEvent(2*FRAMES, function(inst)
				-- inst.sg:RemoveStateTag("must_fsmash")
			-- end),
			
            TimeEvent(7*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.2, 0.2, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				-- print("GENOSU")
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
			EventHandler("halt", function(inst)
				inst.sg:GoToState("dash_stop") 
			end ),
        },
        
        
    },
	
	
	State{
        
        name = "dash",
        tags = {"moving", "running", "canrotate", "can_special_attack", "dashing", "can_usmash", "can_ood", "busy", "ignore_ledge_barriers"},
        
        onenter = function(inst) 
			inst.components.locomotor:DashForward()
			inst.AnimState:PlayAnimation("walk_loop")
			
			-- inst:PushEvent("swaphurtboxes", {preset = "dashing"})
			-- inst.sg.mem.foosteps = 0
            
        end,
        
        onupdate = function(inst)
            inst.components.locomotor:DashForward()
			-- print("FOR BRAIN TESTING ON 1-3")
			-- inst.brain:ForceUpdate()
			-- inst.brain:R()
			-- inst.brain.lastthinktime = 0
        end,

        timeline=
        {
            -- TimeEvent(7*FRAMES, function(inst)
				-- inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                -- PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
                -- DoFoleySounds(inst)
				-- --inst.components.hitbox:MakeFX("dahswoosh", 0, 1, -1, 1, 1, 0.8, 7, 1)
				-- inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.2, 0.2, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
            -- end),
            -- TimeEvent(15*FRAMES, function(inst)
				-- inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                -- PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
                -- DoFoleySounds(inst)
				-- inst.components.hitbox:MakeFX("slide1", 1, 0.0, 0.1, 0.5, 0.5, 0.8, 5, 0)
            -- end),
        },
        
        events=
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("dash") end ),
			
			EventHandler("block_key", function(inst) --4-7 FOR MANUAL BLOCK OUT OF DASH ACTIVATION
				inst.sg:GoToState("block_startup") 
			end ),
			
			EventHandler("halt", function(inst)    --8-7 TO ALLOW MANUAL HALTING
				inst.sg:GoToState("dash_stop") 
			end ),
			
			EventHandler("on_punished", function(inst)
				inst.components.aifeelings.blockapproachmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.blockapproachmod, 20)
			end),
        },
        
        
    },
	
	
	State{
        
        name = "dash_stop",
        tags = {"canrotate", "dashing", "busy", "sliding", "can_special_attack", "can_ood", "can_jump", "keylistener", "keylistener2"}, --, "candash"
        
        onenter = function(inst) 
			-- inst.AnimState:PlayAnimation("dash_pst")
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
        tags = {"canrotate", "busy", "sliding", "can_special_attack", "can_ood", "pivoting", "must_fsmash", "must_ftilt"},
        
        onenter = function(inst) 
			inst.Physics:SetMotorVel(0,0,0)
			inst.components.locomotor:TurnAround()
			inst.AnimState:PlayAnimation("dash_attack")
			-- inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1, 0.5, 0.5, 1, 10, 0)
			inst.components.hitbox:MakeFX("slide1", -1.6, 0.0, 0.1, 1, 0.5, 0.8, 5, 0) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			-- inst.components.hurtboxes:ShiftHurtboxes(-0.5, 0) --NOPE CANT USE THAT HERE
			-- inst.Physics:SetFriction(.6)
			-- inst.components.stats.ResetFriction()
			-- inst.components.jumper:ScootForward(-8)
            
        end,
		
		onexit = function(inst)
			-- inst.components.stats:ResetFriction()
			inst.AnimState:Resume()
        end,

        timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(-0.5, 0)
            end),
			TimeEvent(2*FRAMES, function(inst)
				inst.sg:RemoveStateTag("must_fsmash")
				inst.AnimState:Pause()
            end),
			TimeEvent(6*FRAMES, function(inst)
				inst.sg:AddStateTag("candash")
				inst:PushEvent("dash")
            end),
            TimeEvent(8*FRAMES, function(inst)
				inst.sg:GoToState("idle")
            end),
        },    
    },
	
	
	
	
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
        
        events=
        {
           EventHandler("on_punished", function(inst)
				inst.components.aifeelings.dashattackmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.dashattackmod, -5)
			end),
			
			EventHandler("on_hit", function(inst)
				inst.components.aifeelings.dashattackmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.dashattackmod, 5)
			end),
        },
    },
	
	
	
	
    
    
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        
        -- ontimeout = function(inst)
			-- inst.sg:GoToState("taunt")
        -- end,
        
        onenter = function(inst, start_anim)
            --inst.Physics:Stop()
            
			if inst.components.launchgravity and inst.components.launchgravity:GetIsAirborn() then 
				inst.sg:GoToState("air_idle")
			else
            
				inst.AnimState:PlayAnimation("idle", true)
				
				-- inst:PushEvent("readyforaction") --8-6 --IT...WORKS???   --1-1-17 AAAAND I GOTTA TURN IT OFF -??? DO I??..
			end
			
            -- if inst.LightWatcher:GetLightValue() > 1 then
                -- inst.AnimState:PlayAnimation("cower" )
                -- inst.AnimState:PushAnimation("cower_loop", true)
            -- else
                -- if start_anim then
                    -- inst.AnimState:PlayAnimation(start_anim)
                    -- inst.AnimState:PushAnimation("idle", true)
                -- else
                    -- inst.AnimState:PlayAnimation("idle", true)
                -- end
            -- end
        end,
    },
	
	
	State{
        name = "air_idle",
        tags = {"can_grab_ledge", "idle"}, --idle
        onenter = function(inst, pushanim)

			inst.AnimState:PlayAnimation("idle_air_retry")

        end,
    },
	
	
	
	
	
	
	
	State{
        name = "highleap",
		tags = {"can_usmash", "can_upspec", "no_running", "no_blocking", "jumping", "busy", "savejump"}, --YOU KNOW WHAT, IM GONNA ADD BUSY AND SEE WHAT HAPPENS 1-3-17   --FIX IT SO ITS NOT BUSY
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jump") --jump
			inst.components.locomotor:Clear()
        end,
		
		onexit = function(inst)
			-- inst.AnimState:Resume()
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
			inst.AnimState:PlayAnimation("doublejump") --jump
			inst.components.jumper:DoubleJump(inst) --1-5
			inst.components.hitbox:MakeFX("ground_bounce", 0, 1, -1, 1, 1, 0.8, 7, 1)
        end,
		
		onexit = function(inst)
			-- inst.AnimState:Resume()
        end,
        
		timeline =
        {	
			TimeEvent(9*FRAMES, function(inst)  --15
				-- inst.AnimState:Pause()
			end),
		},
        events=
        {
            EventHandler("animover", function(inst)
				-- inst.sg:GoToState("air_idle") 
			end ),
        },
    },	
	
	
	
	
	
	
	--LEDGE STUFF
	State{
        name = "grab_ledge",
		tags = {"busy", "hanging", "nolandingstop", "no_air_transition"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_grab")
			inst.SoundEmitter:PlaySound("smash_sounds/grab/grab1")
			
			inst:ForceFacePoint(ledgeref.Transform:GetWorldPosition())
			local x, y, z = ledgeref.Transform:GetWorldPosition()
			inst.Transform:SetPosition( x-(0.25*inst.components.launchgravity:GetRotationValue()), y-0, z ) -- -1.5
			
			inst:PushEvent("swaphurtboxes", {preset = "ledge_hanging"})
			inst.components.hurtboxes:SpawnTempHurtbox(-0.2, -0.1, 0.3, 0, 140)  --(xpos, ypos, size, ysize, frames, property)
			inst.components.hitbox:MakeFX("glint_ring_1", -0.1, -0.1, 0.2,   0.8, 0.8,   0.5, 5, 0.8,  0, 0, 0) 
			
			inst.components.launchgravity:Launch(0, 0, 0) --3-17 SO YOU DONT RESUME PREVIOUS MOMENTUM
			inst.Physics:SetActive(false) --CAREFUL WITH THIS
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
				inst.sg:AddStateTag("intangible")
			end),
			TimeEvent(10*FRAMES, function(inst) 
				inst.sg:AddStateTag("can_act")
			end),
			TimeEvent(31*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
			end),
			TimeEvent(90*FRAMES, function(inst) 
				inst.sg:GoToState("ledge_drop")
			end),
		},
		
		events=
        {
            EventHandler("jump_ledge", function(inst)
				if inst.sg:HasStateTag("can_act") then inst.sg:GoToState("ledge_jump") end
			end ),
			EventHandler("forward_key", function(inst)
				if inst.sg:HasStateTag("can_act") then inst.sg:GoToState("ledge_getup") end
			end ),
			EventHandler("backward_key", function(inst)
				if inst.sg:HasStateTag("can_act") then inst.sg:GoToState("ledge_drop") end
			end ),
			EventHandler("down", function(inst)
				if inst.sg:HasStateTag("can_act") then inst.sg:GoToState("ledge_drop") end
			end ),
			EventHandler("block_key", function(inst)
				if inst.sg:HasStateTag("can_act") then inst.sg:GoToState("ledge_roll") end
			end ),
			EventHandler("attack_key", function(inst)
				if inst.sg:HasStateTag("can_act") then inst.sg:GoToState("ledge_attack") end
			end ),
        },
    },
	
	State{
        name = "ledge_getup",
		tags = {"busy", "intangible", "nolandingstop"},
        
        onenter = function(inst, ledgeref)
			-- print("WOA!")
			--inst.AnimState:PlayAnimation("ledge_getup")
			-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			inst.Physics:SetActive(false) --CAREFUL WITH THIS

			
        end,
		
		onexit = function(inst)
			-- inst.AnimState:PlayAnimation("duck_000")
			-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			inst.Physics:SetActive(true) 
        end,
        
		timeline =
        {
			
			TimeEvent(9*FRAMES, function(inst)
				inst:PushEvent("swaphurtboxes", {preset = "idle"})
				inst.AnimState:PlayAnimation("ledge_getup") --DELAYED TO MORE CLOSELY MATCH INVULN FRAMES
			end),
			
			TimeEvent(11*FRAMES, function(inst)
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
		
		-- events=
        -- {
            -- EventHandler("animover", function(inst) inst.AnimState:PlayAnimation("idle") end),
        -- },
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
			-- print("WOA!")
			-- inst.AnimState:PlayAnimation("ledge_jump")
			inst.AnimState:PlayAnimation("ledge_getup")
			-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})

			
			inst.Physics:SetActive(false) --CAREFUL WITH THIS

			
        end,
		
		onexit = function(inst)
			-- inst.AnimState:PlayAnimation("duck_000")
			-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			inst.Physics:SetActive(true) 
        end,
        
		timeline =
        {
			TimeEvent(2*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("jump")
			end),
			TimeEvent(4*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				inst.components.launchgravity:Launch(1, 18, 0)
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
		tags = {"busy", "hanging", "intangible", "nolandingstop"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_attack")
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
			TimeEvent(4*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("rolling")
			end),
			TimeEvent(6*FRAMES, function(inst)
				inst.Physics:SetActive(true)
				-- inst.AnimState:PlayAnimation("rolling")
				-- inst.components.launchgravity:Launch(5, 21, 0)
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
		tags = {"busy", "hanging", "intangible", "nolandingstop"},
        
        onenter = function(inst, ledgeref)
			inst.AnimState:PlayAnimation("ledge_attack")
			-- inst:PushEvent("swaphurtboxes", {preset = "ducking"})
			inst.Physics:SetActive(false) --CAREFUL WITH THIS

			
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
				-- inst.sg:RemoveStateTag("intangible")
				inst.components.hitbox:MakeFX("half_circle_up_woosh", 0.8, 0, 0.1,  3.5, 3.5,   1, 10, 0)
				
			end),
			
			TimeEvent(10*FRAMES, function(inst) --WHAT ARE THE ATTACK VALUES OF GETUP ATTACKS??? ITS NOT LISTED ANYWHERE!!
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetDamage(4)   --7
				inst.components.hitbox:SetSize(0.7)
				inst.components.hitbox:SetProperty(-6)
				inst.components.hitbox:SetLingerFrames(2)
				
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0)
				inst.components.hitbox:SetProperty(-6)
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
	
	
	
	
	
	--GRAB STUFF
	
	
	State{
        name = "grab",  
        tags = {"busy", "grabbing"},
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("grab") --eat
        end,

        -- onexit = function(inst)
            -- inst.components.locomotor:EnableGroundSpeedMultiplier(true) --THE HECK IS THIS HERE FOR?
        -- end,
        
        timeline =
        {
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetSize(0.6) --0.5
				inst.components.hitbox:SpawnGrabbox(0.66, 0.5, 0)  --0.72
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
				
			end),

            TimeEvent(15*FRAMES, function(inst)
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
            TimeEvent(30*FRAMES, function(inst)
				inst.sg:GoToState("fthrow")
			end),
        },
		
		events=
        {
            EventHandler("on_punished", function(inst)
				inst.components.stats:GetOpponent()
				inst.components.stats.opponent:PushEvent("clank", {rebound = 10})
			end),
			EventHandler("end_grab", function(inst)
				inst:PushEvent("clank", {rebound = 10})
			end),
			
			EventHandler("forward_key", function(inst)
				inst.sg:GoToState("fthrow")
			end),
			EventHandler("backward_key", function(inst)
				inst.sg:GoToState("bthrow")
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
				--10-13-20 SPIDERS DONT HAVE THIS ANIMATION AND IM TOO LAZY TO RE-COMPILE THEIR ANIMS
				if anim == "restrained" then
					inst.AnimState:PlayAnimation("grabbed")
				end
			end
        end,
		
    },
	
	
	
	State{
        name = "fthrow",
        tags = {"attack", "busy", "handling_opponent", "throwing"},
        
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
				
				-- 7-9-17 YOU KNOW WHAT. LETS TRY A DIFFERENT ANGLE
				inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetAngle(73) --75
				inst.components.hitbox:SetBaseKnockback(55) --98
				inst.components.hitbox:SetGrowth(40)
				inst.components.hitbox:SetSize(1.5)
				inst.components.hitbox:SetLingerFrames(2)
				
				
				inst.components.hitbox:SpawnHitbox(1.5, 0, 0) 
				inst.sg:RemoveStateTag("abouttoattack") 
				
				inst:AddTag("autofollowup") --7-9-17
			end),
			
			TimeEvent(12*FRAMES, function(inst)   --15
				inst.sg:GoToState("idle") 
				-- print("FTHROW FRAME 12!!")
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
        tags = {"attack", "busy", "handling_opponent", "throwing"},
        
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
				inst:AddTag("autofollowup") --7-9-17
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
        
        events=
        {
            -- EventHandler("animover", function(inst) inst.AnimState:PlayAnimation("helpless") end),
        },
    },
	
	
	State{
        name = "rebound",  
        tags = {"busy"},  
        
        onenter = function(inst, rebound)
			-- inst.AnimState:PlayAnimation("rebound")
				
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
        name = "ll_medium_getup",
        tags = {"busy", "can_grab_ledge"}, 
        
        onenter = function(inst, llframes)
			inst.AnimState:PlayAnimation("landing")
			
			if inst.components.launchgravity.llanim then
				inst.AnimState:PlayAnimation(inst.components.launchgravity.llanim)
			end
			-- inst:PushEvent("swaphurtboxes", {preset = "landing"})
			
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
        name = "eat",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat")
        end,
        
        events=
        {
            EventHandler("animover", function(inst)
                if inst:PerformBufferedAction() then
                    inst.sg:GoToState("eat_loop")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },  
    
    
	State{
        name = "born",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("taunt")
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },      
    
    State{
        name = "eat_loop",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_loop", true)
            inst.sg:SetTimeout(1+math.random()*1)
        end,
        
        ontimeout = function(inst)
            inst.sg:GoToState("idle", "eat_pst")
        end,       
    },  

    State{
        name = "taunt",
        tags = {"busy"},
        
        onenter = function(inst)
			-- inst.sg:GoToState("nair")
            --inst.Physics:Stop()
			inst.AnimState:SetBank("spider")
            inst.AnimState:PlayAnimation("taunt") --"frametest  --spintest_000 --taunt
            inst.SoundEmitter:PlaySound(SoundPath(inst, "scream"))
			-- inst.components.hitbox:MakeFX("spinwoosh", 0, 0.3, 0, 0.8, 0.6, 0.4, 2) 
			-- inst.components.hitbox:MakeFX("spinwoosh2", -0.1, 0.25, -1, 0.75, 0.4, 0.7, 2)
			-- inst:PushEvent("throwattack") --HAH!! MAKES THE NODE THINK YOU ATTACKED SO IT CAN PICK ANOTHER ATTACK
        end,
		
		onexit = function(inst)
			inst.AnimState:SetBank("spiderfighter") --CAUSED A STALE COMPONENT ERROR ONCE???...
        end,
		
		 timeline=
        {
			TimeEvent(40*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
			end),
        },
        
        events=
        {
			EventHandler("animover", function(inst) 
				-- inst.sg:RemoveStateTag("busy") 
				-- inst.sg:GoToState("idle")
				-- inst.sg:GoToState("nspecial")
			end),
			
        },
    },




	State{
        name = "taunt",
        tags = {"busy"},
        
        onenter = function(inst)
			-- inst.sg:GoToState("nair")
            --inst.Physics:Stop()
			inst.AnimState:SetBank("spider")
            inst.AnimState:PlayAnimation("taunt") --"frametest  --spintest_000 --taunt
            inst.SoundEmitter:PlaySound(SoundPath(inst, "scream"))
			-- inst.components.hitbox:MakeFX("spinwoosh", 0, 0.3, 0, 0.8, 0.6, 0.4, 2) 
			-- inst.components.hitbox:MakeFX("spinwoosh2", -0.1, 0.25, -1, 0.75, 0.4, 0.7, 2)
			-- inst:PushEvent("throwattack") --HAH!! MAKES THE NODE THINK YOU ATTACKED SO IT CAN PICK ANOTHER ATTACK
        end,
		
		onexit = function(inst)
			inst.AnimState:SetBank("spiderfighter") --CAUSED A STALE COMPONENT ERROR ONCE???...
        end,
		
		 timeline=
        {
			TimeEvent(40*FRAMES, function(inst) 
				-- inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
			end),
        },
        
        events=
        {
			EventHandler("animover", function(inst) 
				-- inst.sg:RemoveStateTag("busy") 
				-- inst.sg:GoToState("idle")
				-- inst.sg:GoToState("nspecial")
			end),
			
        },
    },
	
	
	
	--10-31-30 FOR TEMPORARY SLEEPY STARTERS
	State{
        name = "napping",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep_loop")
        end,
		
		 timeline=
        {
			TimeEvent(900*FRAMES, function(inst) 
				inst.sg:GoToState("wake")			
			end),
        },
        
    },
	
	
	--11-28-18 GIVING HAROLD HIS OWN "ENTRANCE" STATE TO KEEP HIM FROM GETTING ANTSY DURING THE COUNTDOWN
	State{
        name = "patient_spawn",
        tags = {"busy", "nolandingstop", "no_running", "no_air_transition"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("taunt") --A GENTLEMANS BOW
			inst.AnimState:PushAnimation("idle")
        end,
		
		-- onexit = function(inst)
			-- inst.AnimState:SetBank("spiderfighter") --CAUSED A STALE COMPONENT ERROR ONCE???...
        -- end,
		
		onupdate = function(inst)
			if TheSim:FindFirstEntityWithTag("anchor").components.gamerules.matchstate == "running" then
				inst.sg:RemoveStateTag("busy")	
			end
        end,
		
		 timeline=
        {
			TimeEvent(20*FRAMES, function(inst) 
				--FREEZE!!
				-- v.AnimState:Pause() 
				-- v.Physics:SetActive(false)
			end),
        },
        
        events=
        {
			EventHandler("animover", function(inst) 
				-- inst.sg:RemoveStateTag("busy") 
				-- inst.sg:GoToState("idle")
			end),
			
        },
    },
	
    
    State{
        name = "investigate",
        tags = {"busy"},
        
        onenter = function(inst)
            --inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "scream"))
        end,
        
        events=
        {
            EventHandler("animover", function(inst)
                inst:PerformBufferedAction()
                inst.sg:GoToState("idle")
            end),
        },
    },    
	
	
	
	
	
	
	
	----------ATTACKS
	
	State{
        name = "jab1",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
            --inst.Physics:Stop()
            -- inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("jab_1_old")
        end,
        
        timeline=
        {
            
			TimeEvent(2*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt"))
				
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(10)
				-- inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetDamage(2.5) 
				
				inst.components.hitbox:SetSize(0.7, 0.5)--(1.0, 0.3)
				inst.components.hitbox:SetLingerFrames(0)
				
				inst.components.hitbox:AddSuction(0.7, 0.4, 0)

				inst.components.hitbox:SpawnHitbox(0.85, 0.4, 0)  
			end),
			
			TimeEvent(5*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("jab2")				
			end),
			
			
        },
        
        events=
        {
            -- EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
	
	
	State{
        name = "jab2",
        tags = {"attack", "listen_for_attack", "busy"}, --"noclanking"
        
        onenter = function(inst)

			inst.AnimState:PlayAnimation("jab_2")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
        end,
        
        timeline=
        {
			TimeEvent(3*FRAMES, function(inst)	
				inst.components.hurtboxes:ShiftHurtboxes(0.5, 0) 
				
				inst.components.hitbox:SetDamage(1.5)
				inst.components.hitbox:SetAngle(80) --361
				inst.components.hitbox:SetBaseKnockback(13)
				-- inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetGrowth(0)
				inst.components.hitbox:SetSize(0.75)
				
				inst.components.hitbox:AddSuction(0.5, 0.5, 0)
				
				inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0) 
				
				inst.sg:AddStateTag("jab2") 
			end),
			
			TimeEvent(5*FRAMES, function(inst)
				inst.components.hitbox:SetSize(1)
				inst.components.hitbox:SpawnHitbox(0.7, 0.7, 0)
			end),
			
            TimeEvent(7*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")				
				inst.sg:GoToState("jab3")
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("jab3")
            end),
        },
    },
	
	State{
        name = "jab3",
        tags = {"attack", "jab3", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("dash_attack")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")

            inst:PushEvent("swaphurtboxes", {preset = "leanf"})
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
	
	
	
	
	--THIS ONE IS THE CRAPPY SLOW ONE ONLY USED BY BABY SPIDERS
	State{
        name = "ftilt", --WE CAN MAKE THIS FASTER FOR THE REGULAR SPIDERS
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("fsmash_charge")

        end,
		
		
        timeline=
        {
			TimeEvent(10*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("fsmash")
			end),
			
			TimeEvent(11*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(0.4, 0)
			end),
			
			TimeEvent(13*FRAMES, function(inst) --7
			
				inst.components.hitbox:SetDamage(6)   --7
				inst.components.hitbox:SetAngle(55) --361
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetSize(0.75)
				inst.components.hitbox:SetLingerFrames(3) --WTF MAN, 5 FRAMES??
				
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.6, 0.6, 0) 
				
				-- inst.components.hitbox:AddNewHit() --8-6 UM, WHY WAS THIS HERE????
				inst.components.hitbox:SpawnHitbox(0.7, 1, 0) 
				
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
				
				inst.components.hitbox:SetSize(0.75) --1.2
				inst.components.hitbox:SpawnHitbox(1.0, 1.0, 0) 
			end),
			
			TimeEvent(25*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(-0.3, 0)
			end),
			
			
            TimeEvent(40*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				-- inst.sg:GoToState("idle")
			end),
        },
    },
	
	
	
	State{
        name = "dtilt",
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("ftilt") --jab_1
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
				
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(1.3, 0.3, 0)  
				
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
				
			end),
			
            TimeEvent(19*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
        },
        
        events=
        {

        },
    },
	
	
	
	State{
        name = "utilt",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jab_2") --jab_1
        end,

        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) --7
				inst.components.hitbox:SetDamage(7)   --7
				inst.components.hitbox:SetAngle(110)
				inst.components.hitbox:SetBaseKnockback(18)
				inst.components.hitbox:SetGrowth(110)
				inst.components.hitbox:SetSize(0.65, 0.25)
				inst.components.hitbox:SetLingerFrames(1)
				
				-- inst.components.hitbox:MakeDisjointed()
				inst.components.hitbox:SpawnHitbox(0.8, 0.2, 0)  
				
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
			end),
			
			
			TimeEvent(3*FRAMES, function(inst) --7
				
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetAngle(90)
				inst.components.hitbox:SetBaseKnockback(16)
				inst.components.hitbox:SetGrowth(110)
				inst.components.hitbox:SetSize(0.65)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(0.4, 1.3, 0) 
				
				
				
				-- inst.components.hitbox:SetLingerFrames(2)
				-- inst.components.hitbox:SpawnHitbox(2, 1, 0)
			end),
			
			TimeEvent(4*FRAMES, function(inst) --7
				inst.components.hitbox:SetDamage(5)   --7
				inst.components.hitbox:SetAngle(110) --84
				inst.components.hitbox:SetBaseKnockback(16)
				inst.components.hitbox:SetGrowth(110)
				inst.components.hitbox:SetSize(0.55)
				inst.components.hitbox:SpawnHitbox(-0.3, 1.2, 0) 
			end),
			
            TimeEvent(13*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
        },
        
        events=
        {

        },
    },
	
	
	
	
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
				inst.components.hitbox:SetDamage(9) --10 IS PRETTY HIGH, METHINKS
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
				
				-- JUST FOR THE THUMBNAIL!!
				-- inst.components.hitbox:MakeFX("woosh1down", 0.35, 0.75, 0.2,   2.0, 1.4,   0.0, 5, 1,   0.2,0.2,0.2, 1)
				-- inst.components.hitbox:MakeFX("woosh1down", -0.35, 0.75, 0.2,   2.0, 1.4,   0.0, 5, 1,   1,1,1, 1)
				
				-- inst.components.locomotor:Teleport(0, 1, 0)
				-- inst.components.hitbox:SetDamage(18)
				-- inst.components.hitbox:SetBaseKnockback(40) --FROM 20, BUT ONLY FOR THUMBNAIL
				-- inst.components.hitbox:SetSize(4)
				-- inst.components.hitbox:AddSuction(1, 0.2, -3) --(power, x, y)
				-- inst.components.hitbox:SpawnHitbox(-0.2, -0.5, 0)

				inst.components.hitbox:SpawnHitbox(0.0, -0.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				
				-- inst.components.hitbox:SetSize(0.5)
				-- inst.components.hitbox:SetLingerFrames(5)
				-- inst.components.hitbox:SpawnHitbox(1, 1, 0) 
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
	
	
	
	State{
        name = "nspecial",
        tags = {"attack", "notalking", "abouttoattack", "busy", "nolandingstop", "canrotate"},
        
        onenter = function(inst)
			-- inst.AnimState:SetBuild("DS_spider2_caves") --7-15-18 OH LORD. I GUESS IN DST THEIR BUILD NAME IS JUST COMPLETELY DIFFERENT
			-- inst.AnimState:SetBank("spider_spitter") --7-16-18 -MAYBE WE WON'T NEED THIS NOW THAT WE HAVE A NEW BUILD?
			-- inst.AnimState:PlayAnimation("spit")
			-- inst.AnimState:PlayAnimation("spit_comp") --PROBABLY ISNT FINISHED YET
			inst.components.locomotor:FaceTarget(inst.components.stats.opponent)
			inst.AnimState:PlayAnimation("spit_offset") --I HAD TO BUILD THIS ANIMATION LIKE A BLIND MADMAN
			inst.SoundEmitter:PlaySound(SoundPath(inst, "wakeUp"))
		end,
        
        timeline=
        {

			TimeEvent(2*FRAMES, function(inst) --THIS ALLOWS YOU TO TURNAROUND IN THE VERY BEGINNING OF YOUR SPECIAL ATTACK
				-- if inst.components.keydetector:GetBackward() then
					-- inst.components.locomotor:TurnAround()
				-- end
				inst.sg:RemoveStateTag("canrotate")
			end),
			
			TimeEvent(11*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_flesh_lrg_dull")
				inst.AnimState:SetTime(15*FRAMES)
			end),

			TimeEvent(12*FRAMES, function(inst) --22
				
				inst.components.hitbox:SetDamage(9) 
				inst.components.hitbox:SetAngle(55) --50
				inst.components.hitbox:SetBaseKnockback(50) --30
				inst.components.hitbox:SetGrowth(80) --73
				inst.components.hitbox:SetSize(0.5) --1
				inst.components.hitbox:SetLingerFrames(120)
				
				inst.components.hitbox:SetProjectileAnimation("spider_spit", "spider_spit", "idle")
				inst.components.hitbox:SetProjectileSpeed(9, 0.4)
				inst.components.hitbox:SetProjectileDuration(45)
				
				local projectile = SpawnPrefab("basicprojectile")
				projectile.Transform:SetScale(1.0, 1.0, 1.0)
				inst.components.hitbox:SpawnProjectile(0.3, 0.0, 0, projectile)
			end),
			
            TimeEvent(28*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {
            -- EventHandler("on_punished", function(inst)   --I DONT KNOW IF I SHOULD DO ONPUNISH FEAR HERE, BECAUSE HE CANT GAIN CONFIDENCE ON HITTING WITH A PROJECTILE
				-- inst.components.aifeelings.fspecialmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.fspecialmod, -5)
			-- end), 
			
			-- EventHandler("on_hit", function(inst)
				-- inst.components.aifeelings.fspecialmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.fspecialmod, 5)
			-- end),
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
				inst.components.jumper:ScootForward(8)
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
			end),
			
            TimeEvent(37*FRAMES, function(inst)  --40
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				-- inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {
            EventHandler("on_punished", function(inst)
				inst.components.aifeelings.fspecialmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.fspecialmod, -5)
			end), 
			
			EventHandler("on_hit", function(inst)
				inst.components.aifeelings.fspecialmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.fspecialmod, 5)
			end),
        },
    },
	
	
	
	
	
	--9-6
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
	
    
    State{
        name = "attack",
        tags = {"attack", "busy"},
        
        onenter = function(inst, target)
            --inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
            inst.sg.statemem.target = target
        end,
        
        timeline=
        {
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt")) end),
            
			TimeEvent(22*FRAMES, function(inst) 
				-- inst.components.combat:DoAttack(inst.sg.statemem.target)
				-- inst.SoundEmitter:PlaySound(SoundPath(inst, "Jump"))
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(120)  --130
				inst.components.hitbox:SetGrowth(35)
				inst.components.hitbox:SetDamage(9)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(1.5)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(1, 1, 0) 
			end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) 
				inst.sg:GoToState("idle") 
				-- inst.components.stats:SetMoveBuffer("roll")
				inst.components.stats:PushMoveBuffer()
			end),
        },
    },

    State{
        name = "warrior_attack",
        tags = {"attack", "canrotate", "busy", "jumping"},
        
        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("warrior_atk")
            inst.sg.statemem.target = target
        end,

        onexit = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
        end,
        
        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt")) end),
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Jump")) end),
            TimeEvent(8*FRAMES, function(inst) inst.Physics:SetMotorVelOverride(20,0,0) end),
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
            TimeEvent(19*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
            TimeEvent(20*FRAMES,
				function(inst)
                    inst.Physics:ClearMotorVelOverride()
					inst.components.locomotor:Stop()
				end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("taunt") end),
        },
    },

    State{
        name = "spitter_attack",
        tags = {"attack", "canrotate", "busy", "spitting"},

        onenter = function(inst, target)
            if inst.weapon and inst.components.inventory then 
                inst.components.inventory:Equip(inst.weapon)
            end
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("spit")
        end,

        onexit = function(inst)
            if inst.components.inventory then
                inst.components.inventory:Unequip(EQUIPSLOTS.HANDS)
            end
        end,

        timeline =
        {
            TimeEvent(7*FRAMES, function(inst) 
            inst.SoundEmitter:PlaySound(SoundPath(inst, "spit_web")) end),

            TimeEvent(21*FRAMES, function(inst) inst.components.combat:DoAttack()
            inst.SoundEmitter:PlaySound(SoundPath(inst, "spit_voice"))
             end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("taunt") end),
        },
    },

	
	
	
	
    State{
        name = "hit",
		tags = {"busy", "inknockback", "no_air_transition", "nolandingstop", "ignore_ledge_barriers", "noairmoving"},
        
        onenter = function(inst, hitstun)
            inst.AnimState:PlayAnimation("hit")
            
			if ISGAMEDST and not TheWorld.ismastersim then
				return --DONT HAVE CLIENTS RUN ANYTHING BELOW THIS LINE. LET THE SERVER HANDLE HITSTUN
			end
			
			inst.task_hitstun = inst:DoTaskInTime((hitstun*FRAMES), function(inst) 
				inst.sg:RemoveStateTag("noairmoving") 
				inst.sg:AddStateTag("can_jump")
				inst.sg:AddStateTag("can_attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
				--AI SPECIFIC
				inst:AddTag("wantstoblock") --THIS WAS A REAL STUPID THING TO DO, YA KNOW
				inst.components.aifeelings.escapemode = true 
				inst.components.aifeelings:AddFear(0.0)   --7-6 USELESS????
			end)
            inst:ClearBufferedAction()
        end,
		
		timeline =
        {
            TimeEvent(7*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound(SoundPath(inst, "spit_web"))  --??
			end),
        },
        
		--OHHHHH..... OK. THIS EXPLAINS IT
        onexit = function(inst)
			if ISGAMEDST and TheWorld.ismastersim then 
				inst.task_hitstun:Cancel()
			end
			inst.AnimState:SetMultColour(1,1,1,1)
        end,
    },
	
	
	State{
        name = "tumble", 
        tags = {"busy", "inknockback", "tumbling", "noairmoving", "di_movement_only", "no_air_transition", "ignore_ledge_barriers", "reeling"}, 
        
        onenter = function(inst, hitstun, direction) 
			--SPIDERS ONLY HAVE ONE TUMBLE ANIMATION, SO SKIP ALL THE EXTRA STUFF
			inst.AnimState:PlayAnimation("tumble_spin") --HAROLD ONLY GOT ONE ANIMATION FOR THIS
			
			if ISGAMEDST and not TheWorld.ismastersim then
				return
			end
			
			local dodge_cancel_modifier = hitstun
			if dodge_cancel_modifier >= hitstun + 30 then
				dodge_cancel_modifier = hitstun + 30
			end
			--local dodge_cancel_modifier = (((hitstun * 2.5) /2)) --no thats weird
			
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
				inst.components.aifeelings.readytech = 0.3 --AI SPECIFIC
			end)
        end,

        onexit = function(inst)
			if ISGAMEDST and TheWorld.ismastersim then
				inst.task_hitstun:Cancel()
				inst.task_dodgestun:Cancel()
				inst.AnimState:Resume()
				inst.components.aifeelings.readytech = 0 --AI SPECIFIC
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
	
	
	
	
	--GROUNDED
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
		
			TimeEvent(5*FRAMES, function(inst)
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
					inst.components.locomotor:TurnAround()
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
			inst.AnimState:PlayAnimation("getup")
        end,
        
        timeline =
        {
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
			inst.components.hitbox:Blink(inst, 4,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
            inst.AnimState:PlayAnimation("getup_attack")
        end,
        
        timeline=
        {
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(40)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetDamage(5)
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
	
	
	
	
	State{
        name = "tech_forward_roll", 
        tags = {"busy", "intangible", "teching"},
        
        onenter = function(inst, target)
			inst.components.hitbox:Blink(inst, 2,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
			inst.AnimState:PlayAnimation("rolling")
			inst.AnimState:SetTime(2*FRAMES)
			
			inst.sg:AddStateTag("intangible")
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
			TimeEvent(2*FRAMES, function(inst)
				inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
			end),
		   
		   
		    TimeEvent(12*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst.AnimState:SetMultColour(1,1,1,1)
				
				inst.components.locomotor:Stop()
				inst.components.jumper:ScootForward(7)
				
			end),
            
			TimeEvent(18*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
		},
        
		events=
        {
			EventHandler("on_punished", function(inst)
				inst.components.aifeelings.ftechmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.ftechmod, -5)
			end),
        },
    },
	
	
	
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
		   
			TimeEvent(2*FRAMES, function(inst)
				inst.AnimState:SetMultColour(0.5,0.5,0.5,0.5)
			end),
		   
		   
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
	
	
	State{
        name = "tech_getup", 
        tags = {"busy", "intangible", "teching"},
        
        onenter = function(inst, target)
            -- inst.AnimState:SetMultColour(1,1,1,0.3)
			inst.components.hitbox:Blink(inst, 2,   1, 1, 1,   0.2) --Blink(inst, duration, r, g, b, glow)
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
			TimeEvent(2*FRAMES, function(inst) 
				inst.AnimState:SetMultColour(1,1,1,0.3)
			end),
			
			TimeEvent(10*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("intangible")
				inst.AnimState:SetMultColour(1,1,1,1)
				inst.sg:GoToState("idle")
			end),
        },
        
    },
	
	
	
	
	
    
    State{
        name = "hit_stunlock",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.SoundEmitter:PlaySound(SoundPath(inst, "hit_response"))
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()            
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },  

    State{
        name = "shield",
        tags = {"busy", "shield"},

        onenter = function(inst)
            --If taking fire damage, spawn fire effect. 
            inst.components.health:SetAbsorbAmount(TUNING.SPIDER_HIDER_SHELL_ABSORB)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hide")
            inst.AnimState:PushAnimation("hide_loop")
        end,

        onexit = function(inst)
            inst.components.health:SetAbsorbAmount(0)
        end,
    },

    State{
        name = "shield_end",
        tags = {"busy", "shield"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("unhide")            
        end,

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end ),
        },
    }, 

    State{
        name = "dropper_enter",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("enter")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/descend")            
        end,

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("taunt") end ),
        },



    },
	
	
	
	
	--FSMASH
	State{
        name = "fsmash_start",
        tags = {"busy", "scary"},

        onenter = function(inst)
			inst.AnimState:PlayAnimation("fsmash_charge")
			inst.components.hitbox:SetDamage(18)
			inst.components.locomotor:FaceTarget(inst.components.stats.opponent) --AI SPECIFIC
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
			EventHandler("on_punished", function(inst)
				inst.components.aifeelings.baitsmashmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.baitsmashmod, -5)
			end),
			EventHandler("on_hit", function(inst)
				inst.components.aifeelings.baitsmashmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.baitsmashmod, 5)
			end),
        },
		
	},
	
	State{
        name = "fsmash_charge",
        tags = {"attack", "scary", "f_charge", "busy"},
	
        onenter = function(inst)
			inst.components.colourtweener:StartTween({1,0,0,1}, 1, nil)
			if not inst:HasTag("chargesmash") then
				inst.sg:GoToState("fsmash")
			end
        end,
		
		onupdate = function(inst)  
            inst.components.hitbox:MultiplyDamage(1.0113)
        end,
		
		onexit = function(inst)
            inst.components.colourtweener:EndTween()
			inst.components.visualsmanager:EndShimmy()
			inst.AnimState:SetMultColour(1,1,1,1)
			inst:RemoveTag("chargesmash") --AI SPECIFIC
			inst.AnimState:Resume()
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
			EventHandler("on_punished", function(inst)
				inst.components.aifeelings.baitsmashmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.baitsmashmod, -5)
			end),
			EventHandler("on_hit", function(inst)
				inst.components.aifeelings.baitsmashmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.baitsmashmod, 5)
			end),
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
            EventHandler("on_punished", function(inst)
				inst.components.aifeelings.baitsmashmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.baitsmashmod, -5)
			end),
			
			EventHandler("on_hit", function(inst)
				inst.components.aifeelings.baitsmashmod = inst.components.aifeelings:EncourageUse(inst.components.aifeelings.baitsmashmod, 5)
			end),
        },
    },
	
	
	
	
	
	
	--USMASH
	State{
        name = "usmash_start",
        tags = {"busy", "scary"}, 

        onenter = function(inst)
			inst.components.hitbox:SetDamage(18)
			inst.sg:GoToState("usmash") --AI SPECIFIC - HAROLD DOESNT CHARGE THESE. HE JUST THROWS THEM OUT
			-- inst.components.locomotor:FaceTarget(inst.components.stats.opponent) --DONT THINK THIS REALLY MATTERS DOES IT?
			inst.AnimState:PlayAnimation("usmash")
            inst.components.hitbox:MakeFX("glint", -0.2, 0.6, 0.1,   0.9, 0.9,   0.5, 6, 0.8,  0, 0, 0,   1) 
			inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack"))
        end,
		
		timeline=
        {
            TimeEvent(15*FRAMES, function(inst) 
				inst.sg:GoToState("usmash_charge")
			end),
        },
	},
	
	State{
        name = "usmash_charge",
        tags = {"attack", "u_charge", "busy", "scary"}, 
	
        onenter = function(inst)
			inst.AnimState:Pause()
			inst.components.colourtweener:StartTween({1,0,0,1}, 1, nil)
			if not inst:HasTag("chargesmash") then --AI SPECIFIC
				inst.sg:GoToState("usmash")
			end
			inst.components.visualsmanager:Shimmy(0, 0.02, 10)
        end,
		
		onupdate = function(inst)
            inst.components.hitbox:MultiplyDamage(1.0113)
        end,
		
		onexit = function(inst)
            inst.components.colourtweener:EndTween()
			inst.components.visualsmanager:EndShimmy()
			inst.AnimState:SetMultColour(1,1,1,1)
			inst:RemoveTag("chargesmash") --AI SPECIFIC
			inst.AnimState:Resume()
        end,
        
        timeline=
        {
            TimeEvent(31*FRAMES, function(inst) 
				inst.sg:GoToState("usmash")
			end),
        },
        
        events=
        {
			EventHandler("throwsmash", function(inst) inst.sg:GoToState("usmash") end ),
        },
    },
	
	State{
        name = "usmash",
        tags = {"attack", "notalking", "busy", "abouttoattack", "scary"}, 
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("usmash")

        end,
		
        timeline=
        {
            TimeEvent(2*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(0.4, 0)
			end),
			
			TimeEvent(8*FRAMES, function(inst) 
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
			
			TimeEvent(10*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetSize(1.3)
				inst.components.hitbox.property = 4
				inst.components.hitbox:SpawnHitbox(0, 0.8, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(12*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox.property = 4
				inst.components.hitbox:SpawnHitbox(0, 0.8, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(15*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox.property = 4
				inst.components.hitbox:SpawnHitbox(0, 0.8, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(19*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox.property = 4
				inst.components.hitbox:SpawnHitbox(0, 0.8, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			end),
			
			TimeEvent(24*FRAMES, function(inst) 
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
			
            TimeEvent(42*FRAMES, function(inst) 
				inst.sg:GoToState("idle")
			end),
		},
    },
}

--WHY DO YOU STILL HAVE THESE -oh right i gave them to you
CommonStates.AddSleepStates(states,
{
	starttimeline = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "fallAsleep")) end ),
	},
	sleeptimeline = 
	{
		TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "sleeping")) end ),
	},
	waketimeline = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "wakeUp")) end ),
	},
})
CommonStates.AddFrozenStates2(states)
CommonStates.AddRespawnPlatform(states)
CommonStates.AddDropSpawn(states)

-- return StateGraph("spider", states, events, "idle", actionhandlers)
return StateGraph("spider", states, events, "idle") --DST CHANGE

