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
}

local states=
{

   
    State{
        name = "idle",
        tags = {"idle"}, 
        onenter = function(inst)
            -- inst.AnimState:PushAnimation("idle", true)
            -- inst.sg:SetTimeout(GetRandomWithVariance(10, 5) )
            -- inst.SoundEmitter:KillAllSounds()
        end,
                
        ontimeout = function(inst)
			-- inst.sg:GoToState("rumble")
        end,
    },
	
	
	
	State{
        name = "explode", --A BASIC STATE THAT CREATES A HITBOX AT IT'S CENTER AND STOPS ALL MOVEMENT ON ENTERING THE STATE
        tags = {"idle", "force_trade"}, --"noclanking"
        onenter = function(inst)
            
			inst:AddTag("alreadyimpacted") --FOR MOST GROUND IMPACT CHECKERS LIKE WICKER'S METEOR (EVEN THOUGH HERS IS BUILT IN AND DOESN'T SPECIFICALLY USE THE EXPLODE STATE)
			inst.components.projectilestats:SetProjectileSpeed(0, 0)
			
			-- inst.components.hitbox:FinishMove()
			-- inst.components.hitbox:ResetMove()
			
			-- inst.components.hitbox:SpawnHitbox(0, 0, 0)
        end,
		
		timeline=
        {
			TimeEvent(1*FRAMES, function(inst)  --3-5-17 I HAD TO ADD A FRAME TO THIS BECAUSE IT WASNT REGISTERING ANYMORE.
				inst.components.hitbox:FinishMove()
				inst.components.hitbox:ResetMove()
				inst.components.hitbox:SpawnHitbox(0, 0, 0)
			end),
			
			TimeEvent(10*FRAMES, function(inst)
				-- print("REMOVING EXPLOSIVE")
				inst:Remove()
			end),
        },
        
    },
    
        
    
}


return StateGraph("projectile", states, events, "idle")

