require("stategraphs/commonstates")

local actionhandlers =
{
}

local function TickBuffer(inst)

	inst:PushEvent(inst.components.stats.event, {key = inst.components.stats.key})
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
		local no_blocking = inst.sg:HasStateTag("no_blocking")
		
		local is_jumping = inst.components.launchgravity:GetIsAirborn()
		
		local is_attacking = inst.sg:HasStateTag("attack")
        local is_busy = inst.sg:HasStateTag("busy")
		
		
		--CPU SPECIFIC STUFF
		local wantstojab = inst:HasTag("wantstojab")
		

		--I TOOK A LOT OF STUFF OUT SO IT DOESNT GET CROWDED. BUT ADD MORE IN AS NEEDED
		
		if inst.components.stats.buffertick >= 1 then
			TickBuffer(inst)
		end
		
		--8-23
		-- if not is_busy then
			-- inst:PushEvent("readyforaction")
		-- end
		
		--9-6 NEWER VERSION THAT INCLUDES BOTH CPU AND PLAYER VERSIONS
		if not is_busy and not is_blocking then
			inst:PushEvent("readyforaction") --ACTUALLY JUST FOR CPU
			if inst.components.stats.opponent then --and (inst.components.stats.opponent.components.stats.opponent and inst.components.stats.opponent.components.stats.opponent == inst) then
			-- if inst.components.stats.opponent and (inst.components.stats.opponent.components.stats.opponent and inst.components.stats.opponent.components.stats.opponent == inst) then
				inst.components.stats.opponent:PushEvent("targetnewstate")
			end
		end
		
		
        if is_busy then return end
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()
		
		
		
		if wantstoblock and not is_busy and not is_tryingtoblock then
			if is_jumping then
				-- inst.sg:GoToState("airdodge") --8-17 REMOVING BECAUSE IT'S GETTING ANNOYING
			elseif not no_blocking then
				inst.sg:GoToState("block_startup")
			end
			--^^^ ITS NORMALLY THAT
			
			-- inst.sg:GoToState("block_startup")
		end
		--if is_tryingtoblock and can_oos and not is_busy and not wantstoblock then
		if is_tryingtoblock and not is_busy and not wantstoblock and not is_jumping then  --WHEN LAST LEFT OFF, WAS GETTING RID OF THIS SO PARRY DOESNT AUTO ATTACK
			if is_parrying then
				inst.sg:GoToState("idle")
			else
				inst.sg:GoToState("block_stop")
			end
		end
		
		--3-14
		if wantstojab then --or can_attack then
			inst.sg:GoToState("jab1")
			inst:RemoveTag("wantstojab")
		end
		
		-- print("EVERYTHING PIZZA")
		
	end),
	
	EventHandler("clearbuffer", function(inst)
		inst.components.stats.buffertick = 0
	end),
	
	
	EventHandler("throwattack", function(inst, data)
	
		local airial = inst.components.launchgravity:GetIsAirborn()
		local can_attack = inst.sg:HasStateTag("can_attack")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		
		
		if not inst.sg:HasStateTag("busy") or can_attack or can_ood then
		
			if data.key == "fspecial" then
				inst.sg:GoToState("fspecial")
			elseif data.key == "uspecial" then
				inst.sg:GoToState("uspecial")
			elseif data.key == "dspecial" then
				inst.sg:GoToState("dspecial")
			
			elseif airial then
				if data.key == "forward" then
					inst.sg:GoToState("fair")
				elseif data.key == "up" then
					inst.sg:GoToState("uair")
				else
					inst.sg:GoToState("nair")
				end
			
			elseif data.key == "fsmash" then
				-- inst.sg:GoToState("attack")
				inst.sg:GoToState("fsmash_start")
			elseif data.key == "usmash" then
				inst.sg:GoToState("usmash_start")
			elseif data.key == "block" then
				inst.sg:GoToState("grab")
			else
				inst.sg:GoToState("jab1")
				-- inst.sg:GoToState("grab")
			end
		end
	
	end),
	
	
	--11-28-20 THE SPIDER NEEDS ONE FOR SPECIALS TOO
	EventHandler("throwspecial", function(inst, data)
		local can_special_attack = inst.sg:HasStateTag("can_special_attack")
	
		if not inst.sg:HasStateTag("busy") or can_special_attack or (inst.sg:HasStateTag("can_upspec") and (data.key == "up")) then
			if data.key == "forward" then
				inst.sg:GoToState("fspecial")
			elseif data.key == "up" then
				inst.sg:GoToState("uspecial")
			else
				inst.sg:GoToState("nspecial")
			end
		end
	end),
	
	
	EventHandler("roll", function(inst, data) --7-1 NEW EVENT HANDLER
	
		local is_busy = inst.sg:HasStateTag("busy")
		local airial = inst.components.launchgravity:GetIsAirborn()
		local is_dashing = inst.sg:HasStateTag("dashing")
		local foxtrot = inst.sg:HasStateTag("foxtrot")
		local can_oos = inst.sg:HasStateTag("canoos")
		local was_running = inst:HasTag("wasrunning")
		
		
		if not airial and (can_oos or not is_busy) then
			if data.key == "forward" then
				inst.components.locomotor:FaceTarget(inst.components.stats.opponent)
				inst.sg:GoToState("roll_forward")
			else
				inst.components.locomotor:FaceTarget(inst.components.stats.opponent)
				inst.components.locomotor:TurnAround()
				inst.sg:GoToState("roll_forward")
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
			-- inst.sg:GoToState("highleap")
			-- print("LEAVEGROUND 1")
		-- elseif (can_jump and inst.components.jumper.currentdoublejumps >= 1) or (not is_busy and inst.components.jumper.currentdoublejumps >= 1) then
			-- inst.sg:GoToState("doublejump")
			-- print("LEAVEGROUND 2")
			inst.components.locomotor:Clear()
			inst.sg:GoToState("uspecial")
		end
	
	end),
	
	
	EventHandler("jump", function(inst, data)
		local is_busy = inst.sg:HasStateTag("busy")
		local can_jump = inst.sg:HasStateTag("can_jump")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local used_first_jump = inst.components.jumper.jumping == 1 and inst.components.jumper.doublejumping == 0
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		

		--1-5 NEW JUMP SYSTEM SO CRAP DOESNT HIT THE FAN WHEN TRYING TO LEAVEGROUND() ON LAUNCHES
		if (can_jump and not is_airborn) or (not is_busy and not is_airborn) or ((can_jump or can_oos or can_ood) and not is_airborn) then
			inst.sg:GoToState("uspecial")
			
		elseif (can_jump and inst.components.jumper.currentdoublejumps >= 1) or (not is_busy and inst.components.jumper.currentdoublejumps >= 1) then
			inst.sg:GoToState("doublejump")
			
		end
		
	end),
	
	
	
	--7-19 NEW EVENT FOR CPU DASHING BC DASHING IS KINDA WIERD FOR THEM
	EventHandler("dash", function(inst)
		local is_busy = inst.sg:HasStateTag("busy")
		local can_oos = inst.sg:HasStateTag("canoos")
		local can_ood = inst.sg:HasStateTag("can_ood")
		local is_dashing = inst.sg:HasStateTag("dashing")
		local is_airborn = inst.components.launchgravity:GetIsAirborn()
		
		if (can_oos or can_ood or not is_busy) and not is_airborn and not is_dashing then
			inst.sg:GoToState("dash") --NO DASHING
		end
	
	end),
	
	
	--8-7
	EventHandler("block_key", function(inst)
		local is_busy = inst.sg:HasStateTag("busy")
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
	
	
	EventHandler("outofhp", function(inst, data)
		-- print("IM DEAD!!!")
		-- inst.brain:Stop()
		inst.components.aifeelings:HostBrainContact(inst, "stop") --THIS ONE WORKS IN DST, BLOCKS CLIENTS FROM ENTERING 4-5-19 DST
		inst.sg:GoToState("death")
	end),
}


local function SoundPath(inst, event) --NEED TO ADD THIS I GUESS
    local creature = "spiderqueen"
    return "dontstarve/creatures/" .. creature .. "/" .. event
end

local states=
{
    
	--11-28-20 MAYBE SHE JUST NEEDS A QUICK SECOND TO INITIALIZE BEFORE JUMPING INTO HER SPAWN STATE. --NOPE DOESNT HELP
	State{
		name = "pre-spawn",
        tags = {"busy", "nointerrupt", "no_air_transition", "nolandingstop", "intangible", "ignoreglow"},

        onenter = function(inst, cb)
            -- inst.AnimState:PlayAnimation("none_lol")
		end,

		timeline=
        {
			TimeEvent(10*FRAMES, function(inst) 
				inst.sg:GoToState("in_eggsack")
			end),
        },
    },
	
	
	--6-30-18 --SHE'S JUST A STRUCTURE AT FIRST... RIGHT?
	--I DONT UNDERSTAND HOW THIS STATE LOOKS SO MESSED UP ON DEDICATED SERVERS??? DO WE JUST NEED TO PAD IT WITH A SPAWN-IN STATE?
	State{
		name = "in_eggsack",
        tags = {"busy", "nointerrupt", "no_air_transition", "armor", "slumbering"}, --"SLUMBERING" IS A 1-OFF STATETAG REMOVED ONCE SHE'S BEEN SMACKED ONCE, SO SHE DOESNT GO INTO BIRTH MULTIPLE TIMES

        onenter = function(inst, cb)
            -- inst.AnimState:PlayAnimation("none_lol")
			
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/emerge_voice")
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/emerge_foley")
			
			--WAIT WAIT! NOT QUITE... HITBOXES HAVENT FINISHED INITIALIZING YET!!!
			-- inst.components.hitbox:MakeFX("cocoon_large", 0, 0, 0.3,   1, 1,   1, 600, 0,  0, 0, 0,   1, "spider_cocoon", "spider_cocoon") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
			-- inst.components.hitbox:MakeFX("flap_loop", 0, 2, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "spider_cocoon", "spider_cocoon")
			-- inst.components.hitbox:MakeFX("flap_loop", -0.55, 1.4, -0.2,   0.5, 0.5,   1, 14, 0,  0, 0, 0,   1, "spider_cocoon", "spider_cocoon")
			
			--1-31-21 CUT THE MUSIC!... IRIE SILENCE
			for k,v in pairs(AllPlayers) do
				v.battlemusicnetvar:set("")
			end
		end,

		timeline=
        {
			TimeEvent(15*FRAMES, function(inst) 
				inst.components.hitbox:MakeFX("cocoon_large", 0, 0, 0.3,   1, 1,   1, 6000, 0,  0, 0, 0,   2, "spider_cocoon", "spider_cocoon") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
				inst.components.percent:SetAbsorbAmount(0.5) --ONLY TAKE HALF DAMAGE DURING THE STARTUP ANIMATION
				
				inst.components.stats.lastfx.AnimState:HideSymbol("bedazzled_flare") --10-18-21 DONT BEDAZZLE THE QUEEN PLS
			end),
			
			TimeEvent(150*FRAMES, function(inst) 
				inst.components.percent:SetAbsorbAmount(0.5) --ONLY TAKE HALF DAMAGE DURING THE STARTUP ANIMATION
				inst.sg:GoToState("emerge")
			end),
        },


        events=
        {
			EventHandler("on_hitted", function(inst)
				if inst.sg:HasStateTag("slumbering") then
					inst:DoTaskInTime(1.5, function(inst) --CAREFUL ABOUT USING THESE IN STATEGRAPH EVENTS... THINGS COULD GET MESSY BETWEEN STATE TRANSITIONS
						-- inst.sg:GoToState("birth")
						inst.components.percent:SetAbsorbAmount(0.5) --ONLY TAKE HALF DAMAGE DURING THE STARTUP ANIMATION
						inst.sg:GoToState("emerge")
					end)
					inst.sg:RemoveStateTag("slumbering")
				end
			end),
        },
    },
	
	
	
	
	State{
		name = "emerge",
        tags = {"busy", "nointerrupt", "no_air_transition", "armor"},

        onenter = function(inst, cb)
			inst.AnimState:PlayAnimation("emerge") --DAYUM THIS LOOKS CREEPY. ITS PERFECT
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/emerge_voice")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/emerge_foley")
			
			-- inst.components.hitbox:MakeFX("cocoon_large", 0, 0, 0.3,   1, 1,   1, 90, 0,  0, 0, 0,   1, "spider_cocoon", "spider_cocoon") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
			inst.components.hitbox:MakeFX("cocoon_large_hit", 0, 0, 0.3,   1, 1,   1, 90, 0,  0, 0, 0,   1, "spider_cocoon", "spider_cocoon") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
			inst.components.stats.lastfx.AnimState:HideSymbol("bedazzled_flare") --1-3-21 MORE BEDAZZLE
			
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
			inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
			-- inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/dustpoof")
			TheCamera:Shake("FULL", .2, .02, .3)
			
		end,

		timeline=
        {
			TimeEvent(13*FRAMES, function(inst) 
				TheCamera:Shake("FULL", .2, .02, .3)	
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
				-- inst.SoundEmitter:PlaySound("dontstarve/common/powderkeg_explo")
				
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt")
			end),
			
			TimeEvent(30*FRAMES, function(inst) 
				TheCamera:Shake("FULL", .2, .02, .2)
				-- inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
			end),
			
			TimeEvent(45*FRAMES, function(inst) 
				inst.sg:GoToState("emerge_2")
			end),
			
			-- TimeEvent(60*FRAMES, function(inst) 
				-- -- inst.sg:RemoveStateTag("busy") 
				-- -- inst.sg:GoToState("birth")
				-- inst.components.hitbox:MakeFX("cocoon_large_burst", 0, 0, 0.3,   1, 1,   1, 90, 0,  0, 0, 0,   1, "spider_cocoon", "spider_cocoon") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
				-- --IT NEEDS TO PLAY THE END TOO
				-- inst.components.stats.lastfx.AnimState:PushAnimation("cocoon_large_burst_pst")
			-- end),
			
			-- TimeEvent(90*FRAMES, function(inst) 
				-- inst.sg:GoToState("birth")
			-- end),
        },


        events=
        {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("emerge_2")
				-- inst.AnimState:PlayAnimation("emerge")
				-- inst.AnimState:PushAnimation("atk")
			end),
        },
    },
	
	
	State{
		name = "emerge_2",
        tags = {"busy", "nointerrupt", "no_air_transition", "armor"},

        onenter = function(inst, cb)
			inst.components.hitbox:MakeFX("cocoon_large_burst", 0, 0, 0.3,   1, 0.8,   1, 30, 0,  0, 0, 0,   1, "spider_cocoon", "spider_cocoon") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
			--IT NEEDS TO PLAY THE END TOO
			-- inst.components.stats.lastfx.AnimState:PushAnimation("cocoon_large_burst_pst")
				
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
			inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
			-- inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/dustpoof")
			TheCamera:Shake("FULL", .2, .02, .2)
			
		end,

		timeline=
        {
			TimeEvent(5*FRAMES, function(inst) 
				TheCamera:Shake("FULL", .2, .03, .2)	
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
			end),
			
			TimeEvent(10*FRAMES, function(inst) 
				TheCamera:Shake("FULL", .2, .03, .2)	
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
			end),
			
			TimeEvent(13*FRAMES, function(inst) 
				TheCamera:Shake("FULL", .2, .03, .3)	
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
				-- inst.SoundEmitter:PlaySound("dontstarve/common/powderkeg_explo")
				
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt")
				-- inst.components.hitbox:MakeFX("idle", 0.0, 0.4, 0.4,   0.6, 0.6,   1, 20, 0,  0, 0, 0,   0, "splash_spiderweb", "splash_spiderweb")
			end),
			
			TimeEvent(17*FRAMES, function(inst) 
				-- inst.sg:GoToState("birth")
				inst.sg:GoToState("birth_jump")
			end),
			
        },


        events=
        {
			-- EventHandler("animover", function(inst)
				-- inst.sg:GoToState("emerge")
				-- inst.AnimState:PlayAnimation("emerge")
				-- -- inst.AnimState:PushAnimation("atk")
			-- end),
        },
    },
	
	
	
	State{
		name = "birth_jump",
        tags = {"busy", "nointerrupt", "no_air_transition", "armor", "reducedairacceleration", "noairmoving", "nolandingstop", "intangible", "ignoreglow"},
		--8-19-18 -FOR SOME REASON, ARMOR DOING WEIRD THINGS TO THIS ARMOR? SO IM REMOVIN IT

        onenter = function(inst, cb)
            inst.AnimState:PlayAnimation("enter_jump")
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/emerge_voice")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/emerge_foley")
			
			inst.components.hitbox:MakeFX("cocoon_large_burst_pst", 0, 0, 0.3,   1, 0.8,   1, 7, 0,  0, 0, 0,   0, "spider_cocoon", "spider_cocoon") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
			
			inst.components.hitbox:MakeFX("idle", 0.0, 0.4, -0.4,   0.6, 0.6,   1, 20, 0,  0, 0, 0,   0, "splash_spiderweb", "splash_spiderweb")
			inst.components.hitbox:MakeFX("cocoon_dead", 0, 0, -0.2,   1, 1,   1, 60, 0,  0, 0, 0,   0, "spider_cocoon", "spider_cocoon")
			

			inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/dustpoof")
			TheCamera:Shake("FULL", .2, .02, .3)
			
		end,

		timeline=
        {
			TimeEvent(1*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			end),
			
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.launchgravity:Launch(0, 18)
				TheCamera:Shake("FULL", .2, .02, .2)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
			end),
        },


        events=
        {
			EventHandler("ground_check", function(inst)  --hit_ground
				inst.sg:GoToState("crash_intro") --LETS JUST DO THIS INSTEAD
            end),
        },
    },
	
	State{
        name = "crash_intro",
        tags = {"attack", "busy", "armor"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("landing")
				
				
				TheCamera:Shake("FULL", .3, .03, .3)	
				inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
				inst.SoundEmitter:PlaySound("dontstarve/common/powderkeg_explo")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt")
				
				inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1,   -2, 2,   0.8, 10, 0)
				inst.components.hitbox:MakeFX("slide1", -1.5, 0, 0.1,   2, 2,   0.8, 10, 0) 
				--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst.components.hitbox:MakeFX("anim", -2, 0, 0.1,   1, 1,   1, 10, 0, 0,0,0, 0, "shovel_dirt", "shovel_dirt") 
				inst.components.hitbox:MakeFX("anim", -1.8, 0, 0.1, -1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				
				inst.components.hitbox:SetDamage(11)
				inst.components.hitbox:SetAngle(50) --AAAAH WHATEVER, ILL FIX IT LATER
				inst.components.hitbox:SetBaseKnockback(80)
				inst.components.hitbox:SetGrowth(70)
				inst.components.hitbox:SetSize(3, 1.0)
				inst.components.hitbox:SpawnHitbox(-0.5, 0.25, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
			
				--1-31-21 WHY DO I HEAR BOSS MUSIC?
				for k,v in pairs(AllPlayers) do
					v.battlemusicnetvar:set("dontstarve/music/music_epicfight_stalker") 
				end
				--CAN WE REALLY CALL THIS FROM THE SPIDER QUEENS STATEGRAPH? MAYBE
				--IS IT A GOOD IDEA? MAYBE NOT
        end,

        
        timeline=
        {
            TimeEvent(30*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("scream")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
				-- TheCamera:Shake("FULL", .2, .02, .3)
				TheCamera:Shake("FULL", 1.5, .02, 0.2)	 --LEAVE THE SCREAM OUT UNTIL WE FIX THE CAMERA SHAKE
			end),
			
			TimeEvent(80*FRAMES, function(inst) --40 --GIVE THIS A LOOONG ENDLAG TO MAKE UP FOR HOW HARD IT IS TO DODGE THIS THING
				--REMOVE THE INTRO ARMOR
				inst.components.percent:SetAbsorbAmount(0)
				
				inst.components.spiderspawner.readyfornewkids = false
				inst.components.spiderspawner.newkidtimer = 5 --GIVE THEM A SEC
				-- inst.components.spiderspawner:InitiateSpawner(5)
				
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
			
        },
    },
	
	
	--10-5-21 SPECIAL STATE THAT MAY OR MAY NOT BE USED IN THE TRAILER
	State{
		name = "trailer_jump",
        tags = {"busy", "nointerrupt", "no_air_transition", "armor", "reducedairacceleration", "noairmoving", "nolandingstop", "intangible", "ignoreglow"},

        onenter = function(inst, cb)
            inst.AnimState:PlayAnimation("enter_jump")
		end,

		timeline=
        {
			TimeEvent(1*FRAMES, function(inst) 
				inst.components.launchgravity:Launch(7, -12)
			end),
			
			TimeEvent(2*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(270)
				inst.components.hitbox:SetBaseKnockback(60) --60
				inst.components.hitbox:SetGrowth(60) --80
				inst.components.hitbox:SetSize(2.5, 1)
				inst.components.hitbox:SetLingerFrames(13)
				inst.components.hitbox:SpawnHitbox(-0.6, 2.0, 0) --2.5
			end),
        },

        events=
        {
			EventHandler("ground_check", function(inst)  --hit_ground
				inst.sg:GoToState("crash_intro_2") --LETS JUST DO THIS INSTEAD
            end),
        },
    },
	
	State{
        name = "crash_intro_2",
        tags = {"attack", "busy", "armor"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("landing")
			TheCamera:Shake("FULL", .3, .03, .3)	
			inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
			inst.SoundEmitter:PlaySound("dontstarve/common/powderkeg_explo")
			inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt")
			
			inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1,   -2, 2,   0.8, 10, 0)
			inst.components.hitbox:MakeFX("slide1", -1.5, 0, 0.1,   2, 2,   0.8, 10, 0) 
			--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
			inst.components.hitbox:MakeFX("anim", -2, 0, 0.1,   1, 1,   1, 10, 0, 0,0,0, 0, "shovel_dirt", "shovel_dirt") 
			inst.components.hitbox:MakeFX("anim", -1.8, 0, 0.1, -1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
			
			inst.components.hitbox:SetDamage(11)
			inst.components.hitbox:SetAngle(50) --AAAAH WHATEVER, ILL FIX IT LATER
			inst.components.hitbox:SetBaseKnockback(80)
			inst.components.hitbox:SetGrowth(70)
			inst.components.hitbox:SetSize(3, 1.0)
			inst.components.hitbox:SpawnHitbox(-0.5, 0.25, 0) 
			inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
        end,

        
        timeline=
        {
            TimeEvent(13*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("scream")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
				-- TheCamera:Shake("FULL", .2, .02, .3)
				TheCamera:Shake("FULL", 1.5, .02, 0.2)	 --LEAVE THE SCREAM OUT UNTIL WE FIX THE CAMERA SHAKE
			end),
        },
    },
	
	
	
	
	State{
		name = "birth",
        tags = {"busy", "nointerrupt", "no_air_transition", "armor"},

        onenter = function(inst, cb)
            inst.AnimState:PlayAnimation("enter")
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/emerge_voice")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/emerge_foley")
			
			inst.components.hitbox:MakeFX("cocoon_large_burst_pst", 0, 0, 0.3,   1, 0.8,   1, 7, 0,  0, 0, 0,   0, "spider_cocoon", "spider_cocoon") --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
			
			inst.components.hitbox:MakeFX("idle", 0.0, 0.4, -0.4,   0.6, 0.6,   1, 20, 0,  0, 0, 0,   0, "splash_spiderweb", "splash_spiderweb")
			inst.components.hitbox:MakeFX("cocoon_dead", 0, 0, -0.2,   1, 1,   1, 60, 0,  0, 0, 0,   0, "spider_cocoon", "spider_cocoon")
			

			inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/dustpoof")
			TheCamera:Shake("FULL", .2, .02, .3)
			
		end,

		timeline=
        {
			TimeEvent(20*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/dustpoof")
				TheCamera:Shake("FULL", .2, .03, .4)	
				inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
				inst.SoundEmitter:PlaySound("dontstarve/common/powderkeg_explo")
				-- inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt")
				
				inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1,   -2, 2,   0.8, 10, 0)
				inst.components.hitbox:MakeFX("slide1", -1.5, 0, 0.1,   2, 2,   0.8, 10, 0) 
			end),
			
			TimeEvent(45*FRAMES, function(inst) 
				-- TheCamera:Shake("FULL", .8, .01, .2)	 --LEAVE THE SCREAM OUT UNTIL WE FIX THE CAMERA SHAKE
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
			end),
			
			TimeEvent(60*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy") 
			end),
        },


        events=
        {
			EventHandler("animover", function(inst)
				-- inst.sg:GoToState("idle")
				inst.AnimState:PlayAnimation("taunt")
				inst.AnimState:PushAnimation("atk")
			end),
        },
    },
	
    
    State{
        name = "death",
        tags = {"busy", "intangible", "no_air_transition", "nolandingstop"},
        
        onenter = function(inst)
            -- inst.SoundEmitter:PlaySound(SoundPath(inst, "die"))
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt")
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/die")
            -- inst.AnimState:PlayAnimation("death_90s") --I DONT UNDERSTAND WHY THIS DOESNT WORK?????
			inst.AnimState:PlayAnimation("death")
            -- inst.Physics:Stop()
            -- RemovePhysicsColliders(inst)            
            -- inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
        end,
		
		timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 
				-- inst.AnimState:PlayAnimation("death")
			end),
			
			TimeEvent(18*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/dustpoof")
				TheCamera:Shake("FULL", .2, .03, .4)	
				inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
				-- inst.SoundEmitter:PlaySound("dontstarve/common/powderkeg_explo")
				-- inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/die")
				
				inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1,   -2, 2,   0.8, 10, 0)
				inst.components.hitbox:MakeFX("slide1", -1.5, 0, 0.1,   2, 2,   0.8, 10, 0) 
			end),
			
			TimeEvent(60*FRAMES, function(inst) 
				-- GetPlayer().components.gamerules:KOPlayer(inst, "silent") --DST CHANGE -HIDE THE BODY!
				TheSim:FindFirstEntityWithTag("anchor").components.gamerules:KOPlayer(inst, "silent")
				-- inst.components.hitbox:MakeFX("cocoon_dead", 0.0, 0.0, 0.0,   -1, 1,   1, 30, 0,  0, 0, 0,   0, "spider_cocoon", "spider_cocoon") 
			end),
        },

    }, 








		--SPIDER QUEEN ATTACKS--
	State{
        name = "fsmash_start",
        tags = {"attack", "notalking", "busy", "abouttoattack", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("atk")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
        end,
		

        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(0.4, 0)
			end),
			
			TimeEvent(28*FRAMES, function(inst) 
				
				inst.components.hitbox:SetDamage(19)
				
				inst.components.hitbox:SetAngle(60)
				inst.components.hitbox:SetBaseKnockback(70)  --130
				inst.components.hitbox:SetGrowth(84)
				inst.components.hitbox:SetSize(1.3)
				inst.components.hitbox:SetLingerFrames(2)
				
				-- inst.components.hitbox:AddNewHit() --8-6 UM, WHY WAS THIS HERE????
				inst.components.hitbox:SpawnHitbox(1.8, 1.5, 0) 
				
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				-- inst.components.hitbox:MakeFX("lucy_archwoosh", 3, 1, 1, 1, 1, 0.4, 8) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
				
			end),
			
			TimeEvent(30*FRAMES, function(inst) 
				
				--7-15-18 LETS ADD A LITTLE MORE FLAIR
				local dist = 2 --HOW FAR AWAY THE THUD FX SHOULD APPEAR
				inst.components.hitbox:MakeFX("ground_smash", 1.5, 0.1, 0.1, 2, 1.5, 1, 20, 0)
				inst.components.hitbox:MakeFX("anim", 1.5, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				TheCamera:Shake("FULL", .20, .02, .2)
				inst.components.hitbox:MakeFX("anim", 2.2, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.components.hitbox:MakeFX("ground_smash", 2.2, 0.1, 0.1, -2, 1.5, 1, 20, 0)
				
				
				inst.components.hitbox:SetSize(1.7, 1) --1.2
				inst.components.hitbox:SpawnHitbox(1.7, 0.5, 0)
			end),
			
			TimeEvent(45*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(-0.7, 0)
			end),
			
			
            TimeEvent(60*FRAMES, function(inst)  --70
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				-- inst.sg:GoToState("idle")
				
				
			
			end),
        },
        
    },
	
	
	
	
	
	--BOTH SIDES
	State{
        name = "dsmash",
        tags = {"attack", "notalking", "busy", "abouttoattack", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("atk_duo")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
        end,
		

        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(0.4, 0)
			end),
			
			TimeEvent(28*FRAMES, function(inst)
				
				inst.components.hitbox:SetDamage(19)
				
				inst.components.hitbox:SetAngle(60)
				inst.components.hitbox:SetBaseKnockback(70)  --130
				inst.components.hitbox:SetGrowth(84)
				inst.components.hitbox:SetSize(1.3)
				inst.components.hitbox:SetLingerFrames(2)
				
				-- inst.components.hitbox:AddNewHit() --8-6 UM, WHY WAS THIS HERE????
				inst.components.hitbox:SpawnHitbox(1.8, 1.5, 0) 
				
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				-- inst.components.hitbox:MakeFX("lucy_archwoosh", 3, 1, 1, 1, 1, 0.4, 8) --(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
				
			end),
			
			TimeEvent(30*FRAMES, function(inst) 
				
				--7-15-18 LETS ADD A LITTLE MORE FLAIR
				local dist = 2 --HOW FAR AWAY THE THUD FX SHOULD APPEAR
				inst.components.hitbox:MakeFX("ground_smash", 1.5, 0.1, 0.1, 2, 1.5, 1, 20, 0)
				inst.components.hitbox:MakeFX("anim", 1.5, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				TheCamera:Shake("FULL", .20, .02, .2)
						inst.components.hitbox:MakeFX("anim", 2.2, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.components.hitbox:MakeFX("ground_smash", 2.2, 0.1, 0.1, -2, 1.5, 1, 20, 0)
				
				
				inst.components.hitbox:SetSize(1.5, 1) --1.2
				inst.components.hitbox:SpawnHitbox(1.7, 0.5, 0)
			end),
			
			
			
			TimeEvent(41*FRAMES, function(inst) 
				
				inst.sg:RemoveStateTag("force_direction")
				inst.components.hitbox:SetDamage(18)
				
				inst.components.hitbox:SetAngle(60)
				inst.components.hitbox:SetBaseKnockback(70)
				inst.components.hitbox:SetGrowth(84)
				inst.components.hitbox:SetSize(1.3)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(-1.7, 1.0, 0) 

				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
			end),
			
			TimeEvent(43*FRAMES, function(inst) 
				
				--SMASHY SMASHY
				inst.components.hitbox:MakeFX("ground_smash", -2.2, 0.1, 0.1, 2, 1.5, 1, 20, 0)
				inst.components.hitbox:MakeFX("anim", -2.2, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				TheCamera:Shake("FULL", .20, .02, .2)
			end),
			
			
            TimeEvent(65*FRAMES, function(inst)  --80
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				-- inst.sg:GoToState("idle")
			end),
        },
        
        events=
        {

        },
    },
	
	
	
	
	State{ --LONG
        name = "ftilt",
        tags = {"attack", "notalking", "busy", "abouttoattack", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("atk_long")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
        end,
		

        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(0.4, 0)
			end),
			
			--LETS ADD A LIL SCOOT IN THERE
			TimeEvent(27*FRAMES, function(inst)
				inst.components.jumper:ScootForward(12)
			end),
			
			TimeEvent(28*FRAMES, function(inst)
			
				
				inst.components.hitbox:SetDamage(17) --19
				
				inst.components.hitbox:SetAngle(45)
				inst.components.hitbox:SetBaseKnockback(70)  --130
				inst.components.hitbox:SetGrowth(70) --84
				inst.components.hitbox:SetSize(1.2, 0.5)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(1.5, 0.8, 0) 
				
				inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				
			end),
			
			TimeEvent(30*FRAMES, function(inst)
				inst.components.hitbox:SetSize(1.8, 0.5)
				inst.components.hitbox:SetLingerFrames(4)
				
				inst.components.hitbox:SpawnHitbox(3.5, 0.9, 0) 
			end),
			
			
			TimeEvent(45*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(-0.7, 0)
			end),
			
			
            TimeEvent(65*FRAMES, function(inst) --80 LETS LEAVE A LITTLE LESS TIME TO RETALIATE
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				-- inst.sg:GoToState("idle")
				
				
			
			end),
        },
        
        events=
        {

        },
    },
	
	
	
	--MULTISMASH - FLURRY OF ATTACKS
	State{
        name = "fspecial",
        tags = {"attack", "notalking", "busy", "abouttoattack", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("atk_flurry")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
        end,
		

        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst)
				inst.components.hurtboxes:ShiftHurtboxes(0.4, 0)
			end),
			
			TimeEvent(41*FRAMES, function(inst) --7
				
				inst.components.hitbox:SetDamage(15)
				inst.components.hitbox:SetAngle(60)
				inst.components.hitbox:SetBaseKnockback(55)  
				inst.components.hitbox:SetGrowth(80)
				inst.components.hitbox:SetSize(1.3)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(1.8, 1.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
				
				--AND MAYBE SCOOT FORWARD JUST A BIT?...
				inst.components.jumper:ScootForward(6)
			end),
			
			TimeEvent(43*FRAMES, function(inst) 
				
				--7-15-18 LETS ADD A LITTLE MORE FLAIR
				local dist = 2 --HOW FAR AWAY THE THUD FX SHOULD APPEAR
				inst.components.hitbox:MakeFX("ground_smash", 1.5, 0.1, 0.1, 2, 1.5, 1, 20, 0)
				inst.components.hitbox:MakeFX("anim", 1.5, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				TheCamera:Shake("FULL", .20, .02, .2)
				inst.components.hitbox:MakeFX("anim", 2.2, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.components.hitbox:MakeFX("ground_smash", 2.2, 0.1, 0.1, -2, 1.5, 1, 20, 0)
				
				
				inst.components.hitbox:SetSize(1.7, 1) --1.2
				inst.components.hitbox:SpawnHitbox(1.7, 0.5, 0)
			end),
			
			
			
			
			--ANOTHER SWING
			TimeEvent(56*FRAMES, function(inst) --7
				inst.components.hitbox:SetSize(1.3)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(1.8, 1.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
				inst.components.jumper:ScootForward(6)
			end),
			
			TimeEvent(58*FRAMES, function(inst) 
				local dist = 2
				inst.components.hitbox:MakeFX("ground_smash", 1.5, 0.1, 0.1, 2, 1.5, 1, 20, 0)
				inst.components.hitbox:MakeFX("anim", 1.5, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				TheCamera:Shake("FULL", .20, .02, .2)
				inst.components.hitbox:MakeFX("anim", 2.2, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.components.hitbox:MakeFX("ground_smash", 2.2, 0.1, 0.1, -2, 1.5, 1, 20, 0)
				
				inst.components.hitbox:SetSize(1.7, 1) --1.2
				inst.components.hitbox:SpawnHitbox(1.7, 0.5, 0)
			end),
			
			
			--AAAAND ANOTHER ONE
			--ANOTHER SWING
			TimeEvent(73*FRAMES, function(inst) --7
				inst.components.hitbox:SetSize(1.3)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(1.8, 1.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
				inst.components.jumper:ScootForward(6)
			end),
			
			TimeEvent(75*FRAMES, function(inst) 
				local dist = 2
				inst.components.hitbox:MakeFX("ground_smash", 1.5, 0.1, 0.1, 2, 1.5, 1, 20, 0)
				inst.components.hitbox:MakeFX("anim", 1.5, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				TheCamera:Shake("FULL", .20, .02, .2)
				inst.components.hitbox:MakeFX("anim", 2.2, 0, 0.1, 1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				inst.components.hitbox:MakeFX("ground_smash", 2.2, 0.1, 0.1, -2, 1.5, 1, 20, 0)
				
				inst.components.hitbox:SetSize(1.7, 1) --1.2
				inst.components.hitbox:SpawnHitbox(1.7, 0.5, 0)
			end),
			
			
			
			
			TimeEvent(95*FRAMES, function(inst) 
				inst.components.hurtboxes:ShiftHurtboxes(-0.7, 0)
			end),
			
            TimeEvent(110*FRAMES, function(inst)
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
        },
        
        events=
        {

        },
    },
	
	
	
	State{ --SUPERJUMP
        name = "uspecial",
        tags = {"attack", "busy", "reducedairacceleration", "nolandingstop", "no_air_transition"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("jump")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_swing")
			
			-- inst.components.launchgravity:SetLandingLag(5)
			
			-- inst.AnimState:PlayAnimation("nair") --("taunt") --spintest_000
            -- inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt"))
			-- inst.components.hitbox:MakeFX("spinwoosh", 0, 0.3, 0, 0.8, 0.6, 0.4, 2) 
			-- inst.components.hitbox:MakeFX("spinwoosh2", -0.1, 0.25, -1, 0.75, 0.4, 0.7, 2)
			-- inst.components.hitbox:MakeFX("shockwave_side", 0, 1, 1, 0.8, 0.8, 1, 8, 1)
			
        end,
        
        timeline=
        {
			TimeEvent(1*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
			end),
			
			TimeEvent(2*FRAMES, function(inst) 
				-- inst.components.hitbox:MakeFX("spinwoosh", 0, 0.3, 0, 0.8, 0.6, 0.4, 2) 
				-- inst.components.hitbox:MakeFX("spinwoosh2", -0.1, 0.25, -1, 0.75, 0.4, 0.7, 2)
				-- inst.components.jumper:AirStall()
				-- inst.components.hitbox:MakeFX("shockwave_side", 0, 0, 1,  1, 0.8,   1, 8, 1)
				inst.components.launchgravity:Launch(0, 25)
				TheCamera:Shake("FULL", .2, .02, .2)
				-- inst.SoundEmitter:PlaySound(SoundPath(inst, "Jump"))
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
			end),
			
			-- TimeEvent(4*FRAMES, function(inst) inst.AnimState:SetAddColour(0.4,0.4,0,0.4) inst.components.hitbox:MakeFX("ground_bounce", 0, 1, 1, 1, 1.0, 1, 8, 1) end),
			
			TimeEvent(6*FRAMES, function(inst) 
				-- inst.AnimState:SetAddColour(0,0,0,0) 
				-- inst.components.hitbox:MakeFX("ground_bounce", 0, 1, 1, 1, 1, 1, 8, 1)
				-- inst.AnimState:PlayAnimation("jump")
				inst.SoundEmitter:PlaySound(SoundPath(inst, "Jump"))
			end),
			
			
			TimeEvent(7*FRAMES, function(inst) 
				-- inst.components.launchgravity:Launch(0, 30)
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				-- inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff")
				-- inst.components.hitbox:MakeFX("ground_bounce", 0, 1, 1, 1.5, 1.5, 1, 8, 1)
			end),
			
			
			--AN EARLY ONE TO KNOCK THEM OUT OF THE WAY FIRST?...
			-- TimeEvent(15*FRAMES, function(inst) 
				-- inst.components.hitbox:SetDamage(5)
				-- inst.components.hitbox:SetAngle(45) --
				-- inst.components.hitbox:SetBaseKnockback(60)  --NO NO NO THIS KILLS AT 0
				-- inst.components.hitbox:SetGrowth(60)
				-- inst.components.hitbox:SetSize(2.0, 1)
				-- inst.components.hitbox:SetLingerFrames(8)
				
				
				-- inst.components.hitbox:SpawnHitbox(-0.6, 2.5, 0) --2.5
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				-- -- inst.components.locomotor:SlowFall(0.2, 12)
			-- end),
			
			
			--7-19-18 -THIS WAS THE ORIGINAL UNALTERED ONE, I BELIEVE
			-- TimeEvent(25*FRAMES, function(inst) 
				-- inst.components.hitbox:SetDamage(15)
				-- inst.components.hitbox:SetAngle(270)
				-- inst.components.hitbox:SetBaseKnockback(80) --60
				-- inst.components.hitbox:SetGrowth(60)  --80
				-- inst.components.hitbox:SetSize(2.0, 1)
				-- inst.components.hitbox:SetLingerFrames(200)
				
				-- inst.components.hitbox:SpawnHitbox(-0.6, 2.5, 0) --2.5
			-- end),
			
			
			--HERE, WE'LL ADD THIS ONTO THE END OF THE ATTACK, BUT AT A LOWER DAMAGE SCALE, SO BEING PANCAKED ON THE GROUND DOESNT HURT SO BAD
			-- TimeEvent(37*FRAMES, function(inst) 
				-- inst.components.hitbox:SetDamage(10)
				-- inst.components.hitbox:SetAngle(270)
				-- inst.components.hitbox:SetBaseKnockback(80)
				-- inst.components.hitbox:SetGrowth(60)
				-- inst.components.hitbox:SetSize(1.8, 0.5) --CANT HELP BUT FEEL LIKE THIS SIZE ISN'T CHANGING.....
				-- inst.components.hitbox:SetLingerFrames(200)
				
				-- inst.components.hitbox:SpawnHitbox(-0.6, 1.5, 0) --2.5
			-- end),
			
			
			--7-19-18 -AH HA!! I FOUND THE VERSION IN THIS LAPTOP'S SINGLEPLAYER SPIDERQUEEN SG!! THIS ONE WAS GOOD
			TimeEvent(25*FRAMES, function(inst)  --JUST A LITTLE LOVE TAP
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(55)
				inst.components.hitbox:SetBaseKnockback(20)
				inst.components.hitbox:SetGrowth(60) 
				inst.components.hitbox:SetSize(2.5, 1)
				inst.components.hitbox:SetLingerFrames(2)
				
				inst.components.hitbox:SpawnHitbox(-0.6, 2.0, 0) --2.5
			end),
			
			TimeEvent(27*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(10)
				inst.components.hitbox:SetAngle(270)
				inst.components.hitbox:SetBaseKnockback(60) --60
				inst.components.hitbox:SetGrowth(60) --80
				inst.components.hitbox:SetSize(2.5, 1)
				inst.components.hitbox:SetLingerFrames(13)
				
				inst.components.hitbox:SpawnHitbox(-0.6, 2.0, 0) --2.5
			end),
			
			
			TimeEvent(40*FRAMES, function(inst) 
				inst.components.hitbox:SetDamage(15)
				inst.components.hitbox:SetAngle(270)
				inst.components.hitbox:SetBaseKnockback(60) --60
				inst.components.hitbox:SetGrowth(20) --80
				inst.components.hitbox:SetSize(2.5, 1)
				inst.components.hitbox:SetLingerFrames(200)
				
				inst.components.hitbox:SpawnHitbox(-0.6, 1.5, 0) --2.5
			end),
			
			
			
			
            TimeEvent(50*FRAMES, function(inst) 
				-- inst.sg:GoToState("freefall")
				-- inst.components.hitbox:MakeFX("shockwave_side", 0, 0, 1,  1, 5,   1, 8, 1)
				inst.sg:RemoveStateTag("busy")
			end),
		},
		
		events=
        {
            EventHandler("ground_check", function(inst)  --hit_ground
				inst.sg:GoToState("crashlanding") --LETS JUST DO THIS INSTEAD
            end),
        },
    },
	
	
	
	State{ --CRASH LANDING
        name = "crashlanding",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("landing")
				
				
				TheCamera:Shake("FULL", .3, .03, .3)	
				inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
				inst.SoundEmitter:PlaySound("dontstarve/common/powderkeg_explo")
				inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_clay_wall_sharp")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt")
				
				inst.components.hitbox:MakeFX("slide1", 1, 0, 0.1,   -2, 2,   0.8, 10, 0)
				inst.components.hitbox:MakeFX("slide1", -1.5, 0, 0.1,   2, 2,   0.8, 10, 0) 
				--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				inst.components.hitbox:MakeFX("anim", -2, 0, 0.1,   1, 1,   1, 10, 0, 0,0,0, 0, "shovel_dirt", "shovel_dirt") 
				inst.components.hitbox:MakeFX("anim", -1.8, 0, 0.1, -1, 1, 1, 10, 0,  0,0,0, 0, "shovel_dirt", "shovel_dirt")
				--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				
				
				
				inst.components.hitbox:SetDamage(11)
				inst.components.hitbox:SetAngle(70) --AAAAH WHATEVER, ILL FIX IT LATER
				inst.components.hitbox:SetBaseKnockback(80)
				inst.components.hitbox:SetGrowth(100)
				inst.components.hitbox:SetSize(3, 1.2)
				inst.components.hitbox:SpawnHitbox(-0.4, 0.25, 0) 
				-- inst.components.hitbox:SpawnHitbox(0, 0.5, 0) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/kick_whoosh")
				
				-- inst.AnimState:PlayAnimation("distress_pst_90s")
				
				-- inst.components.hitbox:SetDamage(5)
				-- inst.components.hitbox:SetLingerFrames(2)
				-- inst.components.hitbox:SpawnHitbox(-0.5, 0.25, 0) --GIVE EM A TINY AFTER-AFTER SHOCK

        end,

        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst)
				inst.components.hitbox:SetDamage(5)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox:SpawnHitbox(-0.4, 0.25, 0) --GIVE EM A TINY AFTER-AFTER SHOCK
			end),
			
			TimeEvent(55*FRAMES, function(inst) --40 --GIVE THIS A LOOONG ENDLAG TO MAKE UP FOR HOW HARD IT IS TO DODGE THIS THING
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
			
        },
        
        events=
        {

        },
    },
	
	
	
	
	
	--[[
	State{
		name = "dspecial",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst, cb)
            -- inst.Physics:Stop()
            -- inst.components.locomotor:Stop()
			-- local angle = TheCamera:GetHeadingTarget()*DEGREES -- -22.5*DEGREES
			-- inst.Transform:SetRotation(angle / DEGREES)
            -- inst.AnimState:PlayAnimation("poop_90s")
			inst.AnimState:PlayAnimation("poop")
			-- print("MY BRAIN STRING??", inst:GetBrainString())
			
			-- print("TIME FOR SOME BRAIN SURGERY!!", inst.brain.bt.root.children.queenfight.chosenattack)
			
			-- for i,node in ipairs(inst.brain.bt.root.children) do
				-- -- print("WHATS A NODE?? I HAVE NODE-I-DEA!...", node.name, i)
				-- -- print("NODE-I-DEA!...", inst.brain.bt.root.children[5].chosenattack) --GAAAAAASP. IT WORKED
			-- end

        end,

		timeline=
        {
            TimeEvent(26*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short") 
				inst.AnimState:SetTime(46*FRAMES)
			end),
            TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end), --50
            -- TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end), --60
            TimeEvent(35*FRAMES, function(inst) --64

				inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley")
				
				-- local Harold = SpawnPrefab("spiderfighter_baby")  --"spiderfighter"  --"spiderfighter_easy"
				-- -- Harold:AddComponent("stats")
				-- -- local nemisis = TheSim:FindFirstEntityWithTag("player") --7-6 JUST LOCK ON TO ME PLEASE
				-- -- Harold.components.stats.opponent = nemisis
				-- local x, y, z = inst.Transform:GetWorldPosition()
				-- GetPlayer().components.gamerules:SpawnPlayer(Harold, x-(1*inst.components.launchgravity:GetRotationValue()), y, z-0)
				
				-- -- Harold.AnimState:PlayAnimation("idle")
				-- Harold.sg:GoToState("taunt")
				-- Harold.components.stats.team = "spiderclan"
				-- Harold.components.stats.lives = 1 --NO RESPAWNING
				
				-- Harold.components.percent.hpmode = true
				-- -- Harold.components.percent.maxhp = 18
				
				--6-26-18 OKAY, TIME TO REDO THIS
				-- local baby = SpawnPrefab("spiderfighter_baby")
				-- local x, y, z = inst.Transform:GetWorldPosition()
				
				-- baby:AddTag("dummynpc") --9-14-17 DST TO DETIRMINE IF THE CHARACTER IS A LITERAL CHARACTER NOT CONTROLLED BY A USER
				-- baby:AddTag("customspawn")
				-- baby:AddTag("noplayeranchor")
				
				-- baby.components.percent.currentpercent = 20
				-- baby.components.stats.team = "spiderclan" --SET THEIR STATS TO RESPECTIVE HORDE MODE STATS
				-- baby.components.stats.lives = 1
				
				-- TheSim:FindFirstEntityWithTag("anchor").components.gamerules:SpawnPlayer(baby, x+(1*inst.components.launchgravity:GetRotationValue()), y, z+2, true) 
				
				-- inst.components.spiderspawner:InsertIntoKidTable(baby)
				-- baby:ListenForEvent("onko", function() 
					-- inst.components.spiderspawner:RemoveKid(baby)
				-- end)
				
				--KAPOOF!! LETS MAKE IT EVEN EASIER.
				inst.components.spiderspawner:SpawnBaby(inst)
			end),
			
			
			TimeEvent(50*FRAMES, function(inst) --AND THEN ANOTHER ONE! >:3c
				inst.components.spiderspawner:SpawnBaby(inst)
			end),
			
			TimeEvent(80*FRAMES, function(inst) --80
				-- inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
        },

        events=
        {
			-- EventHandler("animover", function(inst)
				-- inst.sg:RemoveStateTag("busy")
				-- -- inst.sg:GoToState("idle") 
			-- end),
        },
    },
	]]
	
	
	--ACTUALLY, LETS SPLIT IT INTO TWO
	State{
		name = "dspecial",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst, cb)
			inst.AnimState:PlayAnimation("poop")
        end,

		timeline=
        {
            TimeEvent(26*FRAMES, function(inst) 
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short") 
				-- inst.AnimState:SetTime(46*FRAMES)
			end),
            -- TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),
			
			--ARE THEY STANDING IN FRONT OF US? SWAT THEM AWAY
			TimeEvent(20*FRAMES, function(inst)
				inst.sg:AddStateTag("can_jab") --TELLS THE BRAIN WE ARE ALLOWED TO JAB NOW
			end),
			
			
			TimeEvent(50*FRAMES, function(inst)
				 inst.sg:GoToState("make_babeh") 
			end),
        },

        events=
        {
			-- EventHandler("animover", function(inst)
				-- inst.sg:RemoveStateTag("busy")
				-- -- inst.sg:GoToState("idle") 
			-- end),
        },
    },
	
	
	
	State{
		name = "make_babeh",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst, cb)
			inst.AnimState:PlayAnimation("poop")
			inst.AnimState:SetTime(50*FRAMES)
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short") 
        end,

		timeline=
        {
            
			TimeEvent(5*FRAMES, function(inst) --64
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley")
				
				--KAPOOF!! LETS MAKE IT EVEN EASIER.
				inst.components.spiderspawner:SpawnBaby(inst)
				inst.components.spiderspawner.readyfornewkids = false
				-- inst.components.spiderspawner.newkidtimer = 15
				inst.components.spiderspawner.newkidtimer = inst.components.spiderspawner.newkidtimer + 8
			end),
			
			
			TimeEvent(25*FRAMES, function(inst) 
				--HOW MANY CHILDREN ARE ON SCREEN? SHOULD WE SPAWN MORE?
				local babycount = inst.components.spiderspawner:GetNumberOfKids()
				-- print("BABIES DETECTED:", babycount)
				
				if babycount < 3 then 
					-- inst.sg:AddStateTag("more_babies")
					inst.sg:GoToState("make_babeh") 
				end
	
			end),
			
			TimeEvent(40*FRAMES, function(inst) --80
				-- inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
			end),
        },

        events=
        {
			EventHandler("percentdelta", function(inst) --CANT USE HITTED BECAUSE THE ARMOR ABSORBS IT
				inst.components.spiderspawner.readyfornewkids = false
				inst.components.spiderspawner.newkidtimer = inst.components.spiderspawner.newkidtimer + 6
				inst.sg:GoToState("hit") 
				--11-28-20 THIS IS A MUCH CLEARER VISUAL HINT THAT SHE'S VULNERABLE HERE
				inst.components.visualsmanager:Blink(inst, 5,   0.8, 0.5, 0.5,   0.5, 1) --Blink(inst, duration, r, g, b, glow, alpha)
			end),
        },
    },
	
	
	
	
	--A LIL PUNCH TO SWAT THEM AWAY
	State{
        name = "jab", --CALLED FROM QUEENFIGHT.LUA
        tags = {"attack", "busy", "force_direction"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("atk_jab")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short") 
        end,
		

        timeline=
        {
			TimeEvent(15*FRAMES, function(inst) --7
				inst.components.hitbox:SetDamage(8)
				inst.components.hitbox:SetAngle(361)
				inst.components.hitbox:SetBaseKnockback(45)
				inst.components.hitbox:SetGrowth(80) 
				-- inst.components.hitbox:SetSize(1.6)
				inst.components.hitbox:SetLingerFrames(2)
				-- inst.components.hitbox:SpawnHitbox(1.8, 0.8, 0) 
				inst.components.hitbox:SetSize(1.5, 1) 
				inst.components.hitbox:SpawnHitbox(1.5, 0.5, 0)
				
				-- inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/swipe")
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack")
			end),
			
            TimeEvent(17*FRAMES, function(inst)  --70
				-- inst.sg:RemoveStateTag("attack")
				-- inst.sg:RemoveStateTag("busy")
				--11-28-20 ACTUALLY, LETS CHEAT AND JUMP BACK INTO A SHORTER VERSION OF THIS MOVE
				inst.sg:GoToState("dspecial_shortened") 
			end),
        },
    },
	
	
	--A SHORTENED VERSION TO RETURN TO AFTER JABBING ONCE
	State{
		name = "dspecial_shortened",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst, cb)
			inst.AnimState:PlayAnimation("poop")
        end,

		timeline=
        {
			--ARE THEY STANDING IN FRONT OF US? SWAT THEM AWAY
			TimeEvent(15*FRAMES, function(inst)
				inst.sg:AddStateTag("can_jab") --TELLS THE BRAIN WE ARE ALLOWED TO JAB NOW
			end),
			
			TimeEvent(20*FRAMES, function(inst)
				 inst.sg:GoToState("make_babeh") 
			end),
        },
    },
	
	
	
	
	State{
        
        name = "dash",
        tags = {"moving", "running", "canrotate", "dashing", "can_ood"}, --"busy" --"ignore_ledge_barriers" DONT LET HER WALK OFF THE EDGE
        
        onenter = function(inst) 
			inst.components.locomotor:DashForward()
			inst.AnimState:PlayAnimation("walk_loop")
			
			-- inst:PushEvent("swaphurtboxes", {preset = "dashing"})
			-- inst.sg.mem.foosteps = 0
            
        end,
        
        onupdate = function(inst)
            inst.components.locomotor:DashForward()
        end,

        timeline=
        {

			
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(32*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(38*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
        },
        
        events=
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("dash") end ),
			
			EventHandler("block_key", function(inst) --4-7 FOR MANUAL BLOCK OUT OF DASH ACTIVATION
				inst.sg:GoToState("block_startup") 
			end ),
			
			EventHandler("halt", function(inst)    --8-7 TO ALLOW MANUAL HALTING
				-- inst.sg:GoToState("dash_stop") --THE QUEEN DOESNT HAVE ONE
				inst.sg:GoToState("idle")  
			end ),
			
        },
        
        
    },
	
	
	
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
        tags = {"blocking", "tryingtoblock", "busy"},  --"attack", "busy", "jumping"
        
        onenter = function(inst, target)
			-- inst.AnimState:PlayAnimation("blockstunned_resume")
			--inst.AnimState:SetMultColour(1,1,0,1)
        end,

        
        timeline =
        {
			TimeEvent(2*FRAMES, function(inst)
				if inst:HasTag("wantstoblock") then
					inst.sg:GoToState("block")
				else
					inst.sg:GoToState("block_stop")
				end
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
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk")) end),
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
        
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk")) end),
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk")) end),
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk")) end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "walk")) end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
        
    },
	
    
    
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        
        onenter = function(inst, start_anim)
            --inst.Physics:Stop()
            
			if inst.components.launchgravity and inst.components.launchgravity:GetIsAirborn() then 
				inst.sg:GoToState("air_idle")
			else
            
				inst.AnimState:PlayAnimation("idle", true)
				
				inst:PushEvent("readyforaction") --8-6 --IT...WORKS???
			end
			
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
		tags = {"can_usmash", "can_upspec", "no_running", "no_blocking"}, --FIXED!!   --FIX IT SO ITS NOT BUSY
        
        onenter = function(inst)
			-- inst.AnimState:PlayAnimation("jump") --jump
			inst.components.locomotor:Clear()
			
			inst.sg:GoToState("uspecial") --SHE HAS NO REGULAR JUMPS. ONLY GIANT LEAPS
        end,
        
		timeline =
        {

			TimeEvent(1*FRAMES, function(inst)  
				inst.components.jumper:Jump() --WELL THIS IS GOING TO NEED TO HAPPEN EVENTUALLY, RIGHT?
			end),
			
		},
    },
	
	
	State{
        name = "doublejump",
		tags = {"jumping"},
        
        onenter = function(inst)
			inst.AnimState:PlayAnimation("jump") --jump
			inst.components.jumper:DoubleJump() --1-5
			inst.components.hitbox:MakeFX("ground_bounce", 0, 1, -1, 1, 1, 0.8, 7, 1)
			
			inst.sg:GoToState("uspecial") --SHE HAS NO REGULAR JUMPS. ONLY GIANT LEAPS
        end,
        
		timeline =
        {	
			TimeEvent(9*FRAMES, function(inst)  --15
				-- inst.AnimState:Pause()
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
            --inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
        end,
        
        timeline =
        {
			
            TimeEvent(50*FRAMES,
				function(inst)
				end),
        },
        
        events=
        {
            -- EventHandler("animover", function(inst) inst.AnimState:PlayAnimation("grabbed") end),
        },
    },
	
	
	--QUEEN PROBABLY WON'T HAVE MOST ANIMATIONS FOR CUSTOM RAGDOLLS BUT WE NEED THE STATE ANYWAYS
	State{
        name = "ragdoll",  
        tags = {"busy", "no_air_transition", "nolandingstop"},
        
        onenter = function(inst, anim)
			if anim then
				inst.AnimState:PlayAnimation(anim)
			end
        end,
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
        
    },
	
	
	State{
        name = "rebound",  
        tags = {"busy"},  --"attack", "busy", "jumping"
        
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
        tags = {"busy"}, 
        
        onenter = function(inst, llframes)
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
				inst.sg:GoToState("idle")
			end)
        end,
		onexit = function(inst)
			inst.task_ll:Cancel()
        end,     
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
        name = "taunt",
        tags = {"busy"},
        
        onenter = function(inst)
			-- inst.sg:GoToState("nair")
            --inst.Physics:Stop()
			-- inst.AnimState:SetBank("spider")
            inst.AnimState:PlayAnimation("taunt") --spintest_000
            inst.SoundEmitter:PlaySound(SoundPath(inst, "scream"))
			inst.components.hitbox:MakeFX("spinwoosh", 0, 0.3, 0, 0.8, 0.6, 0.4, 2) 
			inst.components.hitbox:MakeFX("spinwoosh2", -0.1, 0.25, -1, 0.75, 0.4, 0.7, 2)
        end,
		
		onexit = function(inst)
			-- inst.AnimState:SetBank("spiderfighter")
        end,
        
        events=
        {
            -- EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
			EventHandler("animover", function(inst) inst.sg:RemoveStateTag("busy") end),
			-- inst.sg:RemoveStateTag("busy")
        },
    },    
    
	
	
	
	
	
	
	
	----------ATTACKS
	
	
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


	--HERS IS DIFFERENT
    State{
        name = "hit",
		tags = {"busy", "no_air_transition", "nolandingstop", "ignore_ledge_barriers", "noairmoving"},
        
        onenter = function(inst, hitstun)
            inst.AnimState:PlayAnimation("hit")
            inst:ClearBufferedAction()
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
        end,
		
		timeline =
        {
            TimeEvent(18*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
			end),

        },
    },
	
	
	State{
        name = "tumble", 
        tags = {"busy", "inknockback", "tumbling", "noairmoving", "di_movement_only", "no_air_transition", "ignore_ledge_barriers", "reeling"},
        
        onenter = function(inst, hitstun, direction) 

			local angle = inst.components.launchgravity:GetAngle() * DEGREES
			
			print("ME", inst.components.launchgravity:GetAngle())
			if inst.components.launchgravity:GetAngle() <= 50 then
				inst.AnimState:PlayAnimation("death")
			elseif inst.components.launchgravity:GetAngle() >= 240 and inst.components.launchgravity:GetAngle() <= 300 then
				inst.AnimState:PlayAnimation("death") --down
			else
				inst.AnimState:PlayAnimation("death") --up
			end
			
			
			local attack_cancel_modifier = hitstun * 0.9
			local dodge_cancel_modifier = hitstun * 1.2
			if dodge_cancel_modifier >= hitstun + 30 then
				dodge_cancel_modifier = hitstun + 30
			end
			
			
			--local dodge_cancel_modifier = (((hitstun * 2.5) /2)) --no thats weird
			
			inst.task_hitstun = inst:DoTaskInTime((hitstun*FRAMES), function(inst) --12-4
				-- inst.AnimState:PlayAnimation("tumble_fall")
				inst.sg:AddStateTag("can_jump")
				inst.sg:RemoveStateTag("di_movement_only")
				inst.sg:RemoveStateTag("noairmoving")
				inst.sg:RemoveStateTag("reeling") --10-20-18 TREAT ALL PLAYER GRAVITIES THE SAME WHILE REELING!
				
				--3-15 GONNA TRY AND ADD SOMETHING THAT CANCELS OUT MOMENTUM SO YOU ARENT FORCED TO JUMP TO SURVIVE
				inst.components.jumper:AirStall(2, 1)
			end)
			
			inst.task_attackstun = inst:DoTaskInTime((attack_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:AddStateTag("can_attack")
				inst.AnimState:SetMultColour(1,0.5,1,1)
			end)
			inst.task_dodgestun = inst:DoTaskInTime((dodge_cancel_modifier*FRAMES), function(inst) --12-4
				inst.sg:RemoveStateTag("busy")
				inst.AnimState:SetMultColour(1,1,1,1)
				-- inst.sg:RemoveStateTag("di_movement_only")
				
			end)
        end,

        onexit = function(inst)
			inst.task_hitstun:Cancel()
			inst.task_attackstun:Cancel()
			inst.task_dodgestun:Cancel()
			inst.AnimState:SetMultColour(1,1,1,1)
			inst.AnimState:Resume()
        end,
		
		timeline =
        {
            TimeEvent(6*FRAMES, function(inst) 
				inst.AnimState:Pause()
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
	
	
	
	
	--GROUNDED
	State{
        name = "land_clumsy",  --warrior_
        tags = {"busy", "grounded", "nogetup"},
        
        onenter = function(inst, target)
			-- inst.AnimState:PlayAnimation("clumsy_land")  --clumsy_land_004
			inst.components.hitbox:MakeFX("ground_bounce", -0.5, 0.1, -1, 1.5, 1.5, 0.8, 10, 0)
			inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
			-- inst:PushEvent("swaphurtboxes", {preset = "grounded"})
        end,
        
        timeline =
        {
			
			TimeEvent(9*FRAMES, function(inst) --9-9 IS A LITTLE DIFFERENT FROM PLAYER SGS BECAUSE I DONT HAVE TO WORRY ABOUT BOUNCE ANIMATIONS AND HITBOXES
				--inst.sg:RemoveStateTag("intangible")
				--inst.AnimState:SetMultColour(1,1,1,1)
				--inst.sg:GoToState("getup")
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
			-- inst.AnimState:PlayAnimation("grounded")
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
					inst.sg:GoToState("roll_forward")
					-- inst.sg:GoToState("tech_forward_roll")
				end
            end),
			
			EventHandler("backward_key", function(inst)
				if not inst.sg:HasStateTag("nogetup") then
					inst.components.locomotor:TurnAround()
					inst.sg:GoToState("roll_forward")
					-- inst.sg:GoToState("tech_backward_roll")
				end
            end),
        },
        
    },
	
	
	State{
        name = "getup",
        tags = {"busy", "grounded"}, 
        
        onenter = function(inst, target)
			inst.AnimState:PlayAnimation("getup1_000")
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
	
	
	
	
	
    
}

CommonStates.AddSleepStates(states,
	{
		sleeptimeline = {
	        TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/sleeping") end),
		},
	},
	{
		onsleep = function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/fallasleep")
		end,
		onwake = function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/wakeup")
		end
	}
)


CommonStates.AddWalkStates(states,
{
	walktimeline = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(32*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(38*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
	},
})

CommonStates.AddFrozenStates(states)


-- return StateGraph("spiderqueen", states, events, "idle", actionhandlers)
return StateGraph("spider", states, events, "in_eggsack") --DST CHANGE