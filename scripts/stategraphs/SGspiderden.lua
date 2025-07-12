require("stategraphs/commonstates")

local events=
{
    -- EventHandler("attacked", function(inst) if inst.components.health:GetPercent() > 0 and not inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("attack") then inst.sg:GoToState("hit") end end),
    -- EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    -- CommonHandlers.OnFreeze(),
    -- EventHandler("newcombattarget", function(inst,data)
            
            -- if inst.sg:HasStateTag("idle") and data.target then
                -- inst.sg:GoToState("taunt")
            -- end
        -- end)
	EventHandler("on_hitted", function(inst, data)
		-- inst.AnimState:PlayAnimation("cocoon_small_hit")
		--10-3-20 OUR HIT ANIMATION NEEDS TO DEPEND ON OUR SIZE (AS A TAG SET IN THE PREFAB FILE)
		if inst:HasTag("large_den") then
			inst.AnimState:PlayAnimation("cocoon_large_hit")
		elseif inst:HasTag("medium_den") then
			inst.AnimState:PlayAnimation("cocoon_medium_hit")
		else
			inst.AnimState:PlayAnimation("cocoon_small_hit")
		end
	end),
	
	EventHandler("do_tumble", function(inst, data) --SHOULDN'T* ACTUALLY HAPPEN BECAUSE IT HAS ARMOR ON EVERYTHING
		inst.AnimState:PlayAnimation("cocoon_small_hit")
	end),
	
	
	EventHandler("make_child", function(inst, data)
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("dspecial")
		end
	end),
	
	
	EventHandler("outofhp", function(inst, data)
		print("IM DEAD!!!")
		-- inst:DoTaskInTime(0, function()
			-- inst.sg:GoToState("death")
		-- end)
		inst.sg:GoToState("death")
	end),
}

local states=
{


   
    State{
        name = "idle",
        tags = {"idle"},
        onenter = function(inst)
            -- inst.AnimState:PushAnimation("cocoon_small", true)
			-- inst.AnimState:PlayAnimation("cocoon_small")
            -- inst.sg:SetTimeout(GetRandomWithVariance(10, 5) )
            inst.SoundEmitter:KillAllSounds()
        end,
                
        -- ontimeout = function(inst)
			-- inst.sg:GoToState("rumble")
        -- end,
    },
    
    
	
	
	-- State{
        -- name = "predeath",
        -- tags = {"busy"},
        
        -- onenter = function(inst)
			-- inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
        -- end,
		
		-- timeline=
        -- {
            -- TimeEvent(5*FRAMES, function(inst) 
				-- inst.sg:GoToState("death")
			-- end),
        -- },
	-- },
		
		
    
	State{
        name = "death",
        tags = {"busy", "intangible"},
        
        onenter = function(inst)
            inst.components.hitbox:MakeFX("idle", 0.0, 0.4, 0.4,   0.6, 0.6,   1, 20, 0,  0, 0, 0,   0, "splash_spiderweb", "splash_spiderweb") 
			-- inst.components.hitbox:MakeFX("idle", 2.6, 0.4, 0.2,   0.6, 0.6,   1, 20, 0,  0, 0, 0,   0, "silk", "silk") 
										--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow, r, g, b, stick, build, bank)
            inst.AnimState:PlayAnimation("cocoon_dead")
            -- RemovePhysicsColliders(inst)            
            -- inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition())) 

			
			-- inst.Physics:ClearCollisionMask()

			-- inst.SoundEmitter:KillSound("loop")

			inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
        end,
		
		timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 
				inst.AnimState:PlayAnimation("cocoon_dead")
				
				--SPAWN A LIL SPIDER INSIDE THE DEN.
				-- local Pawn = SpawnPrefab("spiderfighter_easy")
				-- local x, y, z = inst.Transform:GetWorldPosition()
				-- GetPlayer().components.gamerules:SpawnPlayer(Pawn, x, y, z)
				
			end),
			
			TimeEvent(10*FRAMES, function(inst) 
				TheSim:FindFirstEntityWithTag("anchor").components.gamerules:KOPlayer(inst, "silent")
				inst.components.hitbox:MakeFX("cocoon_dead", 0.0, 0.0, 0.0,   -1, 1,   1, 30, 0,  0, 0, 0,   0, "spider_cocoon", "spider_cocoon") 
			end),
			
			TimeEvent(60*FRAMES, function(inst) 
				TheSim:FindFirstEntityWithTag("anchor").components.gamerules:KOPlayer(inst, "silent")
			end),
        },
        
        
        events =
        {
            EventHandler("animover", function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_splat")
			end ),
        },        
    },
	
	
	
	
	
	State{
		name = "dspecial",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst, cb)
            -- inst.AnimState:PlayAnimation("poop_90s")

        end,

		timeline=
        {

            -- TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end), --50
            -- TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end), --60
            TimeEvent(10*FRAMES, function(inst) --64

				
				-- local baby = SpawnPrefab("spiderfighter_baby")  --"spiderfighter"  --"spiderfighter_easy"
				
				local baby = nil --TO BE DETERMINED
				if inst.components.spiderspawner.babytype == "baby" then
					baby = SpawnPrefab("spiderfighter_baby")
				elseif inst.components.spiderspawner.babytype == "easy" then
					baby = SpawnPrefab("spiderfighter_easy")
				elseif inst.components.spiderspawner.babytype == "medium" then
					baby = SpawnPrefab("spiderfighter_medium")
				end
				
				
				local x, y, z = inst.Transform:GetWorldPosition()
				
				
				baby:AddTag("dummynpc") --DST TO DETIRMINE IF THE CHARACTER IS A LITERAL CHARACTER NOT CONTROLLED BY A USER
				baby:AddTag("customspawn")
				baby:AddTag("nohud") --6-10-18
				baby:AddTag("babyspider") --NOT TO BE CONFUSED WITH THE ACTUAL LVL1 "BABY SPIDER" BUILD
				--THIS TAG JUST SIGNIFIES THAT IT WAS BORN FROM A SPAWNER, AND SPAWNERS ONLY COUNT SPIDERS FROM SPAWNERS
		
				-- self.inst.components.gamerules:SpawnPlayer(baby, x+(v.posx), y, z+2) --DST CHANGE -- ITS NOT 5 ANYMORE
				-- TheSim:FindFirstEntityWithTag("anchor").components.gamerules:SpawnPlayer(baby, x-(1*inst.components.launchgravity:GetRotationValue()), y, z-0)
				TheSim:FindFirstEntityWithTag("anchor").components.gamerules:SpawnPlayer(baby, x-(1*inst.components.launchgravity:GetRotationValue()), y, z+0.1)
				
				
				
				-- baby.AnimState:PlayAnimation("idle")
				baby.sg:GoToState("taunt")
				baby.components.stats.team = "spiderclan"
				baby.components.stats.lives = 1 --NO RESPAWNING
				
				baby.components.percent.hpmode = true
				-- baby.components.percent.maxhp = 18
				
				inst.components.spiderspawner:InsertIntoKidTable(baby)
				baby:ListenForEvent("onko", function() 
					inst.components.spiderspawner:RemoveKid(baby)
				end)
			end),
			
			TimeEvent(15*FRAMES, function(inst) --80
				inst.sg:GoToState("idle")
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
    
        
    -- State{
        -- name = "hit",
        -- tags = {"busy", "hit"},
        
        -- onenter = function(inst)
            -- --inst.SoundEmitter:PlaySound("dontstarve/pig/grunt")
            -- inst.AnimState:PlayAnimation("hit")
            -- inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_hurt_VO")
        -- end,
        
        -- events=
        -- {
            -- EventHandler("animover", function(inst) inst.sg:GoToState("attack") end),
        -- },
        
    -- },    
    
}
CommonStates.AddFrozenStates(states)
    
-- return StateGraph("tentacle", states, events, "idle")
return StateGraph("spiderden", states, events, "idle")

