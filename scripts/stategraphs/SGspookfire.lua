require("stategraphs/commonstates")
local xrange = 27
local xhieght = 0.5 --I SPELLED IT WRONG AGAIN

--LOL WHY DID I GIVE THIS A STATEGRAPH??  
--OH RIGHT, BECAUSE LOTS OF HITBOXES

--WAIT CAN I DO FUNCTIONS UP HERE???? --OH HECK YEA I CAN!!!
local function DoFire(inst)
	local xrange = 27 --THESE GET DEVIDED BY 10 TO GET A DECIMAL PLACE
	inst.components.hitbox:MakeFX("lower", (math.random(-xrange,xrange) / 10), (math.random(3,7) / 10), 0.2,   0.2, 0.2,   0.8, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")

end

local function GetRed(inst)
	if inst.components.stats.team == "red" then
		return 0.45
	else
		return 0
	end
end

local function GetBlue(inst)
	if inst.components.stats.team == "blue" then
		return 0.45
	else
		return 0
	end
end


local events=
{
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
        name = "fire",
        tags = {"idle", "force_direction", "spammy"},
        onenter = function(inst)
            -- inst.AnimState:PushAnimation("idle", true)
            -- inst.sg:SetTimeout(GetRandomWithVariance(10, 5) )
            -- inst.SoundEmitter:KillAllSounds()
			
			-- inst:AddTag("alreadyimpacted")
			-- inst.components.projectilestats:SetProjectileSpeed(0, 0)
			
			-- inst.components.hitbox:FinishMove()
			-- inst.components.hitbox:ResetMove()
			-- inst.components.hitbox:MakeFX("lower", 0.9, 0.3, 0,   0.2, 0.2,   1, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
			-- DoFire(inst)
			
			inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
			inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_haunt")
			inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_haunt")
			
			-- inst:AddTag("forcedirection")
			
			--11-10-16 OKAY, LOOKS LIKE I GOTTA ADD LOCOMOTOR COMPS
			inst:AddComponent("locomotor")
			
			
			
			--OKAY, I NEED TO DO A COUPLE STARTER SHADOWS AD DEFINED LOCATIONS
			
			inst.components.hitbox:MakeFX("lower", ((xrange) / 10), (math.random(3,7) / 10), 0.2,   0.2, 0.2,   0.8, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
			inst.components.hitbox:MakeFX("lower", ((-xrange) / 10), (math.random(3,7) / 10), 0.2,   0.2, 0.2,   0.8, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
			inst.components.hitbox:MakeFX("lower", ((xrange) / 20), (math.random(3,7) / 10), 0.2,   0.2, 0.2,   0.8, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
			inst.components.hitbox:MakeFX("lower", ((-xrange) / 20), (math.random(3,7) / 10), 0.2,   0.2, 0.2,   0.8, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
        end,
                
        -- ontimeout = function(inst)
			-- -- inst.sg:GoToState("rumble")
        -- end,
		
		
		timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
				-- inst.components.hitbox:MakeFX("lower", 0.6, 0.2, 0,   0.2, 0.2,   1, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
				-- inst.components.hitbox:MakeFX("lower", (math.random(-xrange,xrange) / 10), (math.random(1,5) / 10), 0,   0.2, 0.2,   1, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
				DoFire(inst)
				DoFire(inst)
				
			end),
			TimeEvent(2*FRAMES, function(inst)
				DoFire(inst)
				DoFire(inst)
				-- inst.components.hitbox:MakeFX("square", 0.8, 0.8, -0.2,   5.2, 1.0,   0.3, 30, 0,   -0.5, -0.5, -0.5) 
				-- inst.components.hitbox:MakeFX("square", 0.0, 0.8, -0.2,   4.0, 0.8,   0.1, 30, 0,   -0.5, -0.5, -0.5, 1)
			end),
			
			TimeEvent(3*FRAMES, function(inst)
				-- inst.components.hitbox:MakeFX("lower", 0.9, 0.3, 0,   0.2, 0.2,   1, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
				--math.random(2,3) --OOOOHOO! GENIUS!
				-- inst.components.hitbox:MakeFX("lower", (math.random(-28,28) / 10), (math.random(1,5) / 10), 0,   0.2, 0.2,   1, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
				DoFire(inst)
				-- inst.components.hitbox:SetDamage(1.2) --BOWSER'S FIRE BREATH
				-- inst.components.hitbox:SetAngle(55)
				-- inst.components.hitbox:SetBaseKnockback(20)
				-- inst.components.hitbox:SetGrowth(30)
				
				inst.components.hitbox:SetDamage(1.0) --LUCARIO'S AURASPHERE
				inst.components.hitbox:SetAngle(83)
				inst.components.hitbox:SetBaseKnockback(10)
				inst.components.hitbox:SetGrowth(50)
				inst.components.hitbox:SetProperty(6) --OH NOW IT WORKS  --WHY DOES THIS NOT WORK???? THIS DOESNT MAKE SENSE??? --WHATEVER. FINE. YOU WIN. I'LL USE THE OLD METHOD 
				--DST CHANGE- ADD SUCTION TO THE Y AXIS ONLY -REUSEABLE 10-28-17
				inst.components.hitbox:AddSuction(0.5, nil, -0.5) 
				-- inst.components.hitbox.property = 6
				
				inst.components.hitbox:SetHitFX("invisible", "dontstarve/common/fireOut") --????
				inst.SoundEmitter:PlaySound("dontstarve/common/fireBurstLarge")
				
				inst.components.hitbox:SetSize(2.8, 0.5)
				
				inst.components.hitbox:SpawnHitbox(0.0, xhieght, 0)
				
			end),
			
			TimeEvent(6*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("square", 0.0, 0.8, -0.2,   4.0, 0.8,   0.1, 30, 0,   -0.5 + GetRed(inst), -0.5, -0.5 + GetBlue(inst), 1)
				
				DoFire(inst)
				DoFire(inst)
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetProperty(6)
				inst.components.hitbox:SetLingerFrames(3)
				inst.components.hitbox:SetSize(2.8, 0.5)
				
				inst.components.hitbox:SpawnHitbox(0.0, xhieght, 0)
			end),
			
			TimeEvent(9*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("square", 0.0, 0.8, -0.2,   5.4, 1.0,   0.2, 30, 0,   -0.5 + GetRed(inst), -0.5, -0.5 + GetBlue(inst), 1) ---W-...WHY??? WHY DOES "STICK" NEED TO BE SET TO 1 FOR IT TO SHOW UP???
				--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				DoFire(inst)
				DoFire(inst)
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetProperty(6)
				
				inst.components.hitbox:SpawnHitbox(0.0, xhieght, 0)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
			end),
			
			TimeEvent(12*FRAMES, function(inst) --THIS IS ALL I REALLY NEED
				DoFire(inst)
				DoFire(inst)
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetProperty(6)
				inst.components.hitbox:SpawnHitbox(0.0, xhieght, 0)
			end),
			
			TimeEvent(15*FRAMES, function(inst)
				DoFire(inst)
				DoFire(inst)
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0.0, xhieght, 0)
			end),
			
			TimeEvent(18*FRAMES, function(inst)
				DoFire(inst)
				DoFire(inst)
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0.0, xhieght, 0)
			end),
			
			TimeEvent(21*FRAMES, function(inst)
				DoFire(inst)
				DoFire(inst)
				
				inst.components.hitbox:SetDamage(3.0)
				inst.components.hitbox:SetAngle(83)
				inst.components.hitbox:SetBaseKnockback(50 + (inst.components.stats.storagevar1 * 10))
				inst.components.hitbox:SetGrowth(50)
				inst.components.hitbox:SetProperty(6)
				inst.components.hitbox:SetSize(2.8, 0.7) --10-18-17 THIS ONE NEEDS TO BE HIGHER -REUSEABLE
				
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0.0, xhieght+0.1, 0)
			end),

            TimeEvent(30*FRAMES, function(inst) 
				inst:CancelAllPendingTasks()
				inst:Remove()
				
			end),
        },
		
    },
	
	
	--OKAY THIS THING IS TOO GOOD AT COMBOING INTO ITSELF IN THE AIR. WE NEED TO MAKE AN AIR VERSION THAT'S SHORTER
	State{
        name = "fire_air",
        tags = {"idle", "force_direction", "spammy"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
			inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_haunt")
			inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_haunt")
			
			--11-10-16 OKAY, LOOKS LIKE I GOTTA ADD LOCOMOTOR COMPS
			inst:AddComponent("locomotor")
			
			--OKAY, I NEED TO DO A COUPLE STARTER SHADOWS AD DEFINED LOCATIONS
			inst.components.hitbox:MakeFX("lower", ((xrange) / 10), (math.random(3,7) / 10), 0.2,   0.2, 0.2,   0.8, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
			inst.components.hitbox:MakeFX("lower", ((-xrange) / 10), (math.random(3,7) / 10), 0.2,   0.2, 0.2,   0.8, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
			inst.components.hitbox:MakeFX("lower", ((xrange) / 20), (math.random(3,7) / 10), 0.2,   0.2, 0.2,   0.8, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
			inst.components.hitbox:MakeFX("lower", ((-xrange) / 20), (math.random(3,7) / 10), 0.2,   0.2, 0.2,   0.8, 25, 0,  0, 0, 0,   1, "blocker_sanity_fx", "blocker_sanity_fx")
        end,
                
		
		timeline=
        {
			TimeEvent(1*FRAMES, function(inst)
				DoFire(inst)
				DoFire(inst)
			end),
			
			TimeEvent(2*FRAMES, function(inst)
				DoFire(inst)
				DoFire(inst)
			end),
			
			TimeEvent(3*FRAMES, function(inst)
				DoFire(inst)
				
				inst.components.hitbox:SetDamage(1.0) --LUCARIO'S AURASPHERE
				inst.components.hitbox:SetAngle(83)
				inst.components.hitbox:SetBaseKnockback(10)
				inst.components.hitbox:SetGrowth(50)
				inst.components.hitbox:SetProperty(6)
				--DST CHANGE- ADD SUCTION TO THE Y AXIS ONLY -REUSEABLE 10-28-17
				inst.components.hitbox:AddSuction(0.5, nil, -0.5) 
				-- inst.components.hitbox.property = 6
				
				inst.components.hitbox:SetHitFX("invisible", "dontstarve/common/fireOut") --????
				inst.SoundEmitter:PlaySound("dontstarve/common/fireBurstLarge")
				inst.components.hitbox:SetSize(2.8, 0.5)
				inst.components.hitbox:SpawnHitbox(0.0, xhieght, 0)
			end),
			
			TimeEvent(6*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("square", 0.0, 0.8, -0.2,   4.0, 0.8,   0.1, 24, 0,   -0.5 + GetRed(inst), -0.5, -0.5 + GetBlue(inst), 1)
				
				DoFire(inst)
				DoFire(inst)
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetProperty(6)
				inst.components.hitbox:SetLingerFrames(3)
				inst.components.hitbox:SetSize(2.8, 0.5)
				
				inst.components.hitbox:SpawnHitbox(0.0, xhieght, 0)
			end),
			
			TimeEvent(9*FRAMES, function(inst)
				inst.components.hitbox:MakeFX("square", 0.0, 0.8, -0.2,   5.4, 1.0,   0.2, 24, 0,   -0.5 + GetRed(inst), -0.5, -0.5 + GetBlue(inst), 1) ---W-...WHY??? WHY DOES "STICK" NEED TO BE SET TO 1 FOR IT TO SHOW UP???
				--(fxname, xoffset, yoffset, zoffset, xsize, ysize, alpha, duration, glow)
				DoFire(inst)
				DoFire(inst)
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetProperty(6)
				
				inst.components.hitbox:SpawnHitbox(0.0, xhieght, 0)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
			end),
			
			TimeEvent(12*FRAMES, function(inst) --THIS IS ALL I REALLY NEED
				DoFire(inst)
				DoFire(inst)
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SetProperty(6)
				inst.components.hitbox:SpawnHitbox(0.0, xhieght, 0)
			end),
			
			TimeEvent(15*FRAMES, function(inst)
				DoFire(inst)
				DoFire(inst)
				
				inst.components.hitbox:SetDamage(3.0)
				inst.components.hitbox:SetAngle(83)
				inst.components.hitbox:SetBaseKnockback(50 + (inst.components.stats.storagevar1 * 10))
				inst.components.hitbox:SetGrowth(50)
				inst.components.hitbox:SetProperty(6)
				inst.components.hitbox:SetSize(2.8, 0.7) --10-18-17 THIS ONE NEEDS TO BE HIGHER -REUSEABLE
				
				inst.components.hitbox:AddNewHit()
				inst.components.hitbox:SpawnHitbox(0.0, xhieght+0.1, 0)
			end),

            TimeEvent(24*FRAMES, function(inst) 
				inst:CancelAllPendingTasks()
				inst:Remove()
				
			end),
        },
		
    },
}


return StateGraph("spookfire", states, events, "idle")