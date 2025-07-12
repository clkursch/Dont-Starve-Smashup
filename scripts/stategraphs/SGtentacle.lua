require("stategraphs/commonstates")

local events=
{
    --4-4-19 LOL WAIT HOW LONG HAS THE TENTACLE HAD THE ABILITY TO GET HIT??
	-- EventHandler("attacked", function(inst) if inst.components.health:GetPercent() > 0 and not inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("attack") then inst.sg:GoToState("hit") end end),
    CommonHandlers.OnFreeze(),
		
	--5-28-20 OK THEN, LETS TRY IT LIKE THIS
	EventHandler("tentacle_attack", function(inst)
		if not (inst.sg:HasStateTag("busy") or inst:HasTag("life_over")) then
			-- print("TNT: ATTACK FROM EVENTHANDLER")
			inst.sg:GoToState("attack")
		end
	end)
}

local states=
{

	--WHY DID I MAKE THIS THE LIFE-OVER STATE?
    State{
        name = "rumble",
        tags = {"invisible"},
        onenter = function(inst)
			-- print("ALMOST OVER...")
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_rumble_LP", "tentacle")
            -- inst.AnimState:PushAnimation("ground_loop", true)
			inst.AnimState:PlayAnimation("atk_pst")
			inst.AnimState:SetTime(27*FRAMES) --7-8-17
			inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_disappear")
			inst.AnimState:PushAnimation("ground_pst", true)
            -- inst.sg:SetTimeout(GetRandomWithVariance(10, 5) )
			-- inst.sg:SetTimeout(3) 
			--1-27-22 ALRIGHT, TENTACLE IS NOT BEHAVING. TIME TO DO THINGS THE OLD FASHIONED WAY.
			inst:DoTaskInTime(8, function() --3-27-22 CHANGING FROM 4
				inst.SoundEmitter:KillSound("tentacle")
				-- inst.components.stats.master.storagereference1 = nil
				inst:Remove()
			end)
        end,
		--USING TIMEOUTS IS A BAD IDEA...
        -- ontimeout = function(inst)
			-- inst.SoundEmitter:KillSound("tentacle")
			-- inst.components.stats.master.storagereference1 = nil
			-- inst:Remove() -- 4-5
        -- end,
		-- timeline=
        -- {
			-- TimeEvent(90*FRAMES, function(inst)
				-- inst.SoundEmitter:KillSound("tentacle")
				-- inst.components.stats.master.storagereference1 = nil
				-- print("COMMIT NOT FEEL SO GOOD")
				-- inst:Remove()
			-- end),
        -- },
    },
   
    -- State{
        -- name = "idle",
        -- tags = {"idle", "invisible"},
        -- onenter = function(inst)
            -- inst.AnimState:PushAnimation("idle", true)
            -- inst.sg:SetTimeout(GetRandomWithVariance(10, 5) )
            -- inst.SoundEmitter:KillAllSounds()
        -- end,
                
        -- ontimeout = function(inst)
			-- inst.sg:GoToState("rumble")
        -- end,
    -- },
    
	
	--THIS IS ESSENTIALLY IT'S IDLE STATE NOW
    State{
        name = "taunt",
        tags = {"taunting"},
        onenter = function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_rumble_LP", "tentacle")
			inst.SoundEmitter:SetParameter( "tentacle", "state", 0) --WAIT... WHAT IS THIS???
			
			--IF WE AREN'T A SMASHUP TENTACLE (EXISTING IN THE WORLD BEFORE THE STAGE WAS CREATED) DONT RUN ANY OF THIS
			if not inst.components.stats then
				return end
			
			inst.components.combat.range = 12
			inst.components.combat.attackrange = 3.5
			if not ISGAMEDST then --10-19-17 I WONDER IF THIS WORKS?
				inst.components.combat:SetAttackPeriod(0.1) --3-31 INCREASING RETARGET SPEED BC ITS A BIT SLOW
				inst.components.combat:SetRetargetFunction(0.1, inst.components.combat.targetfn)
				-- inst.components.combat:SetKeepTargetFunction(true) --NEVER LOSES TARGET (UM IS THIS SUCH A GOOD IDEA?) --WAIT THIS CRASHES THE GAME
				inst.components.combat:SetKeepTargetFunction() --3-31 I THINK THIS FIXES?? NOT SURE --11-14-20 YES MY DUMB INEXPERIENCED CHILD. THIS REMOVES THE TARGET FN
			end
            
			inst.AnimState:PlayAnimation("atk_idle")
			
			--[[
			for i, v in ipairs(AllPlayers) do
				print("TEAM SETUP", inst.components.stats.team, v.components.stats.team)
				if inst.components.stats and v ~= inst.components.stats.master and (inst.components.stats.team == nil or (inst.components.stats.team ~= v.components.stats.team)) then
					-- inst.components.combat.target = v
					print("TARGET FOUND", v, v.components.stats.team)
					inst.components.stats.opponent = v
				end
			end
			]]
			--12-30-21 I SEE THE PROBLEM. THESE DONT COUNT AS PLAYERS.
			local anchor = TheSim:FindFirstEntityWithTag("anchor")
			-- print("ARE WE REAL?", inst.components.stats.team, anchor, #anchor.components.gamerules.livingplayers)
			
			--1-1-22 ALRIGHT, WE NEED TO ACCOUNT FOR MORE THAN 1 OPPONENT, DOOFUS
			inst.components.stats.storagevar1 = {} --WE'LL USE THIS AS OUR TABLE TO STORE THEM
			
			if anchor and anchor.components.gamerules then
				--12-30-21 SO WE WANT TO TAKE THE TABLE THAT CONTAINS ALL LIVING PLAYERS, UNLESS IT'S EMPTY (LIKE IN LOBBY MODE) THEN WE JUST TAKE ALL PLAYERS
				local cyclecheck = anchor.components.gamerules.livingplayers
				if #cyclecheck == 0 then
					cyclecheck = AllPlayers
				end
				
				--1-9-22 OK IT SEEMS THAT USING THE "ipairs" VERSION OF THE LOOP WAS BREAKING THE GAME, BUT NORMAL "pairs" WORKS FINE
				--SLIGHTLY WORRYING BECAUSE I ALWAYS ASSUMED THOSE WORKED THE SAME... BUT OK...
				for k, v in pairs(cyclecheck) do
					-- print("TEAM SETUP", inst.components.stats.team, v.components.stats.team)
					-- print("VARIABLE CHECK", inst.components.stats, v ~= inst.components.stats.master, (inst.components.stats.team == nil or (inst.components.stats.team ~= v.components.stats.team)))
					if inst.components.stats and v ~= inst.components.stats.master and (inst.components.stats.team == nil or (inst.components.stats.team ~= v.components.stats.team)) then
						-- print("TARGET FOUND", v, v.components.stats.team)
						-- inst.components.stats.opponent = v
						table.insert(inst.components.stats.storagevar1, v)
						
					end
				end
			
			
			end
			
			
			
        end,


		
		
		--10-5-17 DST CHANGE - A LITTLE SPLASH OF THE ATTACK NODE SHOVED INTO THE STATEGRAPH FOR THE DST VERSION. COULD ALSO BE REUSEABLE
		onupdate = function(inst)
			
			if not inst.components.stats then --12-31-21 ANOTHER SAFEGAURD AGAINST NON-SMASHUP TENTACLES
				return end 
			
			
			--1-1-22 RUN FOR EACH POTENTIAL OPPONENT
			for k, v in pairs(inst.components.stats.storagevar1) do
			
				local opponent = v --inst.components.stats.opponent
				
				if opponent and opponent:IsValid() then
					-- print("CURRENT OPPONENT:", opponent)
					--GONNA MAKE A MINI RECREATION OF A PIECE OF HAROLD'S CHASEANDFIGHT
					local myposx, myposy = inst.Transform:GetWorldPosition()
					local oppx, oppy = opponent.Transform:GetWorldPosition()
					local dist = distsq(myposx, myposy, oppx, oppy)
					
					if dist <= 12 and not inst.sg:HasStateTag("attack") then
						-- inst.sg:GoToState("attack") --STRAIGHT TO ATTACK
						inst:PushEvent("tentacle_attack") --5-28-20 THEERE WE GO. MUCH BETTER. FOR SOME REASON
					end
				end
			end
			
            
			if inst:HasTag("life_over") then
				inst.sg:GoToState("rumble") --TIMES UP, TIME TO DESPAWN
			
			--WE'RE STILL USING COMBAT COMPONENTS HERE?? HM. WELL OK THEN
			-- 12-30-21 NO FORGET THAT! THAT WILL OVERRIDE OUR REAL CHECKERS. GET IT OUTTA HERE
			--[[ 
			elseif inst.components.combat:CanAttack() and not inst.sg:HasStateTag("busy") then
				-- inst.sg:GoToState("attack") --STRAIGHT TO ATTACK SO IT DOESNT PLAY THAT EMERGE ANIMATION
				inst:PushEvent("tentacle_attack")
				]]
			end
			
			

        end,
		
		
		events=
        {
            EventHandler("animover", function(inst) 
				inst.sg:GoToState("taunt") 
			end),
        },
    },
    
	
	
	--5-28-20 NEW STATE THAT THE TENTICAL WILL SPAWN IN
	State{
        name ="emerge",
		tags = {"busy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_emerge")
            inst.AnimState:PlayAnimation("atk_pre")
        end,
        events=
        {
			EventHandler("animover", function(inst) inst.SoundEmitter:KillAllSounds() inst.sg:GoToState("taunt") end),
        },
    },
	
	
    
    State{ 
        name = "attack",
        tags = {"attack", "busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("atk_loop")
            inst.AnimState:PushAnimation("atk_idle", true)
			-- print("tnt: ONENTER ATTACK STATE")
        end,
        
        timeline=
        {
            
			--THE GOOFY ANIMATION DOESNT MATCH UP GREAT WITH THE HITBOXES. LETS ADD ONE EXTRA LITTLE BACK-SWING HITBOX
			TimeEvent(4*FRAMES, function(inst) 
				inst.components.hitbox:SetAngle(120) 
				inst.components.hitbox:SetBaseKnockback(18) 
				inst.components.hitbox:SetGrowth(50) 
				inst.components.hitbox:SetDamage(2)
				inst.components.hitbox:SetSize(1.8, 0.5)
				inst.components.hitbox:SetLingerFrames(1) 
				
				inst.components.hitbox:AddSuction(0.15, 0, 0) --(power, sucpx, sucpy) --TOPUTBACK 0.3
				inst.components.hitbox.property = -6 --10-24-20 NO MORE ROGUE HITBOX
				
				inst.components.hitbox:SpawnHitbox(0.5, 0.5, 0) 
			end),
			
			
			
			TimeEvent(6*FRAMES, function(inst)
				-- print("tnt: WILL YOU AT LEAST SWING????")
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack") 
			end),
			
			TimeEvent(7*FRAMES, function(inst) 
				inst.components.hitbox:AddNewHit()
				-- print("tnt: FIRST SWING")
				
				inst.components.hitbox:SetAngle(120) --200
				inst.components.hitbox:SetBaseKnockback(18) --20
				inst.components.hitbox:SetGrowth(50) --0  --100
				inst.components.hitbox:SetDamage(6)
				inst.components.hitbox:SetSize(2.5)
				inst.components.hitbox:SetLingerFrames(3) --2
				
				inst.components.hitbox:AddSuction(0.15, 0, 0) --(power, sucpx, sucpy) --TOPUTBACK 0.3
				
				-- inst.components.hitbox:MakeRogue()
				-- inst.components.hitbox.property = -2 --ROGUE, BUT ALSO DISJOINTED --DST REUSEABLE-
				inst.components.hitbox.property = -6 --10-24-20 NO MORE ROGUE HITBOX
				
				--10-28-17 DST REUSEABLE - THROW WICKER AWAY FURTHER SO SHE CANT FOLLOW UP
				-- if (xvel < 0 and facedir == "left") or (xvel > 0 and facedir == "right") then --IF TRAVELING BACKWARDS
					-- for i, v in ipairs(projectile.components.hitbox.hitboxtable) do --WOW. THIS IS GETTING COMPLICATED
						-- v.components.hitboxes.kbangle = 110 --HIT BACKWARDS
					-- end
				-- else
					-- for i, v in ipairs(projectile.components.hitbox.hitboxtable) do
						-- v.components.hitboxes.kbangle = 70
					-- end
				-- end
				
				
				--10-24-20 THIS IS TOO WEIRD. I'M REWORKING THE TENTACLE TO NOT DO SELF-DAMAGE AND HAVE LIMMITED SPAWNS INSTEAD
				--[[  
				--11-8-17 -REUSEABLE - I HAVE ABSOLUTELY NO RECCOLECTION OF CREATING THE ABOVE FUNCTION, BUT LETS TRY AGAIN
				inst.components.hitbox:SetOnPostHit(function() 
					print("tnt: ONPOSTHIT FN")
					if inst.components.stats.opponent == inst.components.stats.master then
						inst.components.stats.opponent.components.launchgravity:Launch(15, 10, 0)
					end
				end)
				]]
				
				inst.components.hitbox:SpawnHitbox(0, 1.3, 0) 
				
				-- inst.components.hitbox:AddNewHit()
				-- inst.components.hitbox:SpawnHitbox(1, 1, 0) 
			
			end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack") end),
            
			TimeEvent(17*FRAMES, function(inst) 
				-- print("tnt: SECOND SWING")
				-- inst.components.combat:DoAttack() 
				inst.components.hitbox:SetAngle(80)
				inst.components.hitbox:SetBaseKnockback(85)  --100 YEA THIS HAS GOTTA COME WAY DOWN --120  --130
				inst.components.hitbox:SetGrowth(40) --35
				inst.components.hitbox:SetDamage(9)
				inst.components.hitbox:DoFlash(0)
				inst.components.hitbox:SetSize(1.7)
				inst.components.hitbox:SetLingerFrames(2)
				inst.components.hitbox.property = -6
				
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0, 1, 0) 
				
			end),
			
			
            TimeEvent(18*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
			
			-- TimeEvent(50*FRAMES, function(inst) inst.AnimState:PlayAnimation("atk_pst") end),
			
			TimeEvent(50*FRAMES, function(inst) 
				-- if inst.components.combat.target and inst.components.combat:CanAttack() then
					-- inst.sg:GoToState("attack") 
				-- else
					-- inst.sg:GoToState("taunt")
				-- end
				--FORGET ALL THAT NONSENSE, JUST GO TO TAUNT AND LET US CHECK AGAIN OURSELVES
				inst.sg:GoToState("taunt")
			end),
			
        },
        
		
		--OKAY I GOTTA MAKE THE END LAG HIGHER CUZ THIS TENTACLE GONNA JUGGLE PEOPLE FO DAYS
        -- events=
        -- {
            -- EventHandler("animqueueover", function(inst) 
                -- if inst.components.combat.target then
                    -- inst.sg:GoToState("attack") 
                -- else
                    -- inst.sg:GoToState("attack_post") 
                -- end
            -- end),
        -- },
    },
    
	
    --CURRENTLY UNUSED IN SMASHUP 
	State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_death_VO")
            inst.AnimState:PlayAnimation("death")
            RemovePhysicsColliders(inst)            
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
        end,
        
        
        events =
        {
            EventHandler("animover", function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_splat")
			end ),
        },        
    },
    
	
    --CURRENTLY UNUSED IN SMASHUP 
    State{
        name = "hit",
        tags = {"busy", "hit"},
        
        onenter = function(inst)
            --inst.SoundEmitter:PlaySound("dontstarve/pig/grunt")
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_hurt_VO")
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("attack") end),
        },
    },    
    
}
CommonStates.AddFrozenStates(states)
    
-- return StateGraph("tentacle", states, events, "idle")
return StateGraph("tentacle", states, events, "emerge")

