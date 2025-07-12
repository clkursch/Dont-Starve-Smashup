require "brains/spiderbrain"
require "stategraphs/SGspider"

local assets =
{
	Asset("ANIM", "anim/ds_spider_basic.zip"),
	Asset("ANIM", "anim/spider_build.zip"),
	Asset("SOUND", "sound/spider.fsb"),
	Asset( "ANIM", "anim/spider_fighter_build.zip" ), --8-18
	--7-16-18 -AH HA!!! YOU CAN ADD SPRITER FILES WITH ANIMATIONS SEPERATELY FROM IT'S BUILD AND BANK!!
	--AS LONG AS YOU REMOVE THE ATLAS AND BUILD FROM THE ZIP FILE IN THE ANIM FOLDER, IT WILL BE ADDED ONTO WHATEVER BANK ITS NAMED AFTER
	Asset( "ANIM", "anim/spider_fighter_extra.zip" ), --7-16-18 --ADDITIONAL ANIMS LIKE THE SPIT
	Asset( "ANIM", "anim/spider_baby.zip" ), --2-25-17
	Asset( "ANIM", "anim/spider_harold.zip" ), --4-23-17  >:3c
	-- Asset( "ANIM", "anim/DS_spider2_caves.zip" ), --6-10-18 SOLEY FOR THE SPIDER SPITTER ANIMATION
	Asset("ANIM", "anim/ds_spider_basic.zip"), --7-15-18 --MAYBE THIS ONE IS MORE UP TO DATE?
	Asset("ANIM", "anim/ds_spider_caves.zip"), 
}

local warrior_assets =
{
	Asset("ANIM", "anim/ds_spider_basic.zip"),
	Asset("ANIM", "anim/ds_spider_warrior.zip"),
	Asset("ANIM", "anim/spider_warrior_build.zip"),
	Asset("SOUND", "sound/spider.fsb"),
}
    
    
local prefabs =
{
	"spidergland",
    "monstermeat",
    "silk",
}

local function NormalRetarget(inst)
    local targetDist = TUNING.SPIDER_TARGET_DIST
    -- if inst.components.knownlocations:GetLocation("investigate") then
        -- targetDist = TUNING.SPIDER_INVESTIGATETARGET_DIST
    -- end
    return FindEntity(inst, targetDist, 
        function(guy) 
            if inst.components.combat:CanTarget(guy)
               and not (inst.components.follower and inst.components.follower.leader == guy) then
                return guy:HasTag("character")
            end
    end)
end

local function WarriorRetarget(inst)
    return FindEntity(inst, TUNING.SPIDER_WARRIOR_TARGET_DIST, function(guy)
		return (guy:HasTag("character") or guy:HasTag("pig"))
               and inst.components.combat:CanTarget(guy)
               and not (inst.components.follower and inst.components.follower.leader == guy)
	end)
end

local function FindWarriorTargets(guy)
	return (guy:HasTag("character") or guy:HasTag("pig"))
               and inst.components.combat:CanTarget(guy)
               and not (inst.components.follower and inst.components.follower.leader == guy)
end

local function keeptargetfn(inst, target)
   return target
          and target.components.combat
          and target.components.health
          and not target.components.health:IsDead()
          and not (inst.components.follower and inst.components.follower.leader == target)
end

local function ShouldSleep(inst)
    return false
	-- return GetClock():IsDay()
           -- and not (inst.components.combat and inst.components.combat.target)
           -- and not (inst.components.homeseeker and inst.components.homeseeker:HasHome() )
           -- and not (inst.components.burnable and inst.components.burnable:IsBurning() )
           -- and not (inst.components.follower and inst.components.follower.leader)
end

local function ShouldWake(inst)
    return false
	-- return GetClock():IsNight()
           -- or (inst.components.combat and inst.components.combat.target)
           -- or (inst.components.homeseeker and inst.components.homeseeker:HasHome() )
           -- or (inst.components.burnable and inst.components.burnable:IsBurning() )
           -- or (inst.components.follower and inst.components.follower.leader)
           -- or (inst:HasTag("spider_warrior") and FindEntity(inst, TUNING.SPIDER_WARRIOR_WAKE_RADIUS, function(...) return FindWarriorTargets(inst, ...) end ))
end

local function DoReturn(inst)
	if inst.components.homeseeker and inst.components.homeseeker.home and inst.components.homeseeker.home.components.childspawner then
		inst.components.homeseeker.home.components.childspawner:GoHome(inst)
	end
end

local function StartDay(inst)
	if inst:IsAsleep() then
		DoReturn(inst)	
	end
end


local function OnEntitySleep(inst)
	-- if GetClock():IsDay() then
		-- DoReturn(inst)
	-- end
end

local function SummonFriends(inst, attacker)
	local den = GetClosestInstWithTag("spiderden",inst, TUNING.SPIDER_SUMMON_WARRIORS_RADIUS)
	if den and den.components.combat and den.components.combat.onhitfn then
		den.components.combat.onhitfn(den, attacker)
	end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, function(dude)
        return dude:HasTag("spider")
               and not dude.components.health:IsDead()
               and dude.components.follower
               and dude.components.follower.leader == inst.components.follower.leader
    end, 10)
end

local function StartNight(inst)
    inst.components.sleeper:WakeUp()
end


--6-10-18 A SIMPLE WAY TO REMOVE THE NOW-DEAD SPIDER CORPSES LAYING AROUND
local function RemoveSpider(inst)
	inst.components.hurtboxes:RemoveAllHurtboxes()
	TheSim:FindFirstEntityWithTag("anchor").components.gamerules:CleanOpponentList(inst) --1-30-21
	
	if inst.brain then --1-3-22 APPARENTLY IT'S POSSIBLE FOR THESE GUYS TO NOT HAVE BRAINS?? (IT WAS RIGHT AS I WAS KOd)
		inst.brain:Stop()
	end
	
	if inst.components.hoverbadge then --6-10-18 OH YEA. GET RID OF THESE THINGS TOO
		inst.components.hoverbadge:RemoveAllBadges()
	end
	
	inst:Remove()
end



local function create_common(Sim)
	local inst = CreateEntity()
	
	-- inst:ListenForEvent( "daytime", function(i, data) StartDay( inst ) end, GetWorld())	
	inst.OnEntitySleep = OnEntitySleep
	
    inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLightWatcher()
	-- local shadow = inst.entity:AddDynamicShadow()
	-- shadow:SetSize( 1.5, .5 )
    -- inst.Transform:SetFourFaced()
	inst.entity:AddNetwork() --DST
	
	inst.Transform:SetTwoFaced() --9-6
    
    
    ----------
    
    inst:AddTag("monster")
    inst:AddTag("hostile")
	inst:AddTag("scarytoprey")    
    inst:AddTag("canbetrapped")    
    
    MakeCharacterPhysics(inst, 10, .5)

    
    inst:AddTag("spider")
    inst.AnimState:SetBank("spider")
    inst.AnimState:PlayAnimation("idle")
    
    -- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
	inst.components.locomotor:SetSlowMultiplier( 1 ) --ISN'T HALF THIS CRAP NORMAL DS STUFF ANYWAYS?
	inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
  
    inst:SetStateGraph("SGspider")
    
   
    
    
	inst:AddComponent("aifeelings")
	-- inst.components.aifeelings.ailevel = 10
	
	
	
	---------ADDING THE REST IN HERE--------
	inst:AddTag("fighter")
	inst:AddTag("cpu")
	
	inst:AddComponent("stats")
	
	
	--4-1-19 THAT RIGHT. NEED TA SET THESE UP HERE SO CLIENTS WHO JOIN THE SERVER CAN. YOU KNOW. SEE :/
	inst:AddComponent("hitbox")
	inst:AddComponent("hurtboxes")
	inst:AddComponent("launchgravity")
	inst:AddComponent("jumper")
	inst:AddComponent("colourtweener")
	--OH RIGHT. THESE TOO
	inst:AddComponent("percent")
	-- inst.components.percent:DoDamage(100) --WELL MAYBE NOT THIS PART
	
	
	inst.components.stats.bankname = "spiderfighter" --11-3-16 YOU SHOULD USE THIS TO SET ANIMS NOW, BECAUSE OTHER PARTS OF THE GAME NEED THESE ANIM FILE NAMES
	inst.components.stats.buildname = "spider_fighter_build"
	
	-- FOR THE FACE THAT SHOWS UP ON THE HUD --
	inst.components.stats.facepath = "minimap/minimap_data.xml"
	inst.components.stats.facefile = "spiderden.png"
	
	
	
	inst:AddComponent("visualsmanager") --2-10-18 SHINY NEW ONE!~ REUSEABLE DST
	
	--DST CHANGE- THESE ARE NEEDED FOR THE SPIDERS TOO!
	inst.customhpbadgelives = net_byte(inst.GUID, "customhpbadge.lives", "customhpbadgedirty")
	inst.customhpbadgepercent = net_ushortint(inst.GUID, "customhpbadge.percent", "customhpbadgedirty")
	
	inst:AddTag("nonplayerfighter") --DST CHANGE- FOR PREFABS THAT ARE FIGHTERS BUT NOT PLAYERCOMMON PREFABS
	
	
	
	--1-31-22 AN ATTEMPT TO GET SERVER SIDE PLAYERS TO SEE THESE BADGES
	if not TheWorld.ismastersim then
		inst.spawntask = inst:DoPeriodicTask(0.5, function()
			local anchor = TheSim:FindFirstEntityWithTag("anchor") --THANK GOD THIS WORKED, UGH.
			print("ATTEMPTING TO DIRTY SPAWN SPIDERFIGHTER", anchor, GetTime())
			if not anchor then  --SLOWPOKE COMPUTER. END HERE AND RETRY IN A SEC
				print("ANCHOR STILL NOT DETECTED. TRY AGAIN")
				return end 
			
			local x, y, z = anchor.Transform:GetWorldPosition()
			print("ANCHOR FOUND! SPAWNING SPIDER HUD")
			anchor.components.gamerules:SpawnPlayer(inst, x, y, z, true)
			inst.spawntask:Cancel() --AND END THE SPAWNTASK SO IT DOESNT LOOP
			inst.spawntask = nil
		end)
	end
	
	
	--DST CHANGE- WHERE DO THESE GO AGAIN? LETS JUST SLAP EM IN HERE--------
	----3-8-19 -ALRIGHT ALRIGHT LETS CLEAN THIS UP NOW THAT DEDICATED SERVERS CANT READ ANY OF THIS. TOO MUCH CRAP
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.persists = false --3-9-19 -THESE ARE TECHNICALLY HANDLED AS PLAYERS NOW. THEY NEED TO BE REMOVED FROM THE WORLD WHEN EVERYONE ELSE LEAVES
	
    
    inst:AddComponent("follower")
    
   
    ---------------------        
    MakeMediumBurnableCharacter(inst, "body")
    MakeMediumFreezableCharacter(inst, "body")
    inst.components.burnable.flammability = TUNING.SPIDER_FLAMMABILITY
    ---------------------       
    
    
    ------------------
    inst:AddComponent("health")

    ------------------
    
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    
    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)

    ------------------
    
    inst:AddComponent("eater")
   
	inst.AnimState:SetBank(inst.components.stats.bankname)
	inst.AnimState:SetBuild(inst.components.stats.buildname)

    inst.components.health:SetMaxHealth(TUNING.SPIDER_HEALTH)

    inst.components.combat:SetDefaultDamage(TUNING.SPIDER_DAMAGE)
    -- inst.components.combat:SetAttackPeriod(TUNING.SPIDER_ATTACK_PERIOD)
	inst.components.combat:SetAttackPeriod(1)
    -- inst.components.combat:SetRetargetFunction(1, NormalRetarget) --4-3-19 HOPE DISABLING DOESNT CRASH THE GAME
    inst.components.combat:SetHurtSound("dontstarve/creatures/spider/hit_response")
	inst.components.combat.attackrange = 3.4

    inst.components.locomotor.walkspeed = TUNING.SPIDER_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.SPIDER_RUN_SPEED
	
	inst.components.locomotor.dashspeed = 1.8 * 5 --1.6
	
	-- inst.components.locomotor.runspeed = TUNING.SPIDER_RUN_SPEED * 2
	
	
	inst.components.stats.jumpheight = 19
	inst.components.stats.gravity = 1
	inst.components.stats.fallingspeed = 1.5
	inst.components.stats.weight = 85 --68 --98
	
	inst.components.stats.numberofdoublejumps = 1 --oh.... --10
	
	inst.components.visualsmanager:CustomUpdate(inst) --KICKSTART IT
	
	inst:DoTaskInTime(0, function()
		inst.components.hurtboxes:CreateHurtbox(2.5, 0, 0.6) --1.8, 0, 0.5
		inst.components.hurtboxes:SpawnPlayerbox(0, 0.3, 0.35, 0.7, 0) --(xpos, ypos, size, sizey, shape)    --35, 0.5
		-- inst.components.hurtboxes:SpawnPlayerbox(0, 1.6, 0.25, 0.5, 0)
	end)
	
	-- inst:AddComponent("percent")
	inst.components.percent:DoDamage(100)

	
	
	
	inst.components.stats.sizemultiplier = 0.85
	inst.Transform:SetScale(0.85, 0.85, 0.85)
	
	-- print("HOW MANY JUMPS DOES I HAVE", inst.components.jumper.currentdoublejumps)
	-- print("HOW MANY JUMPS DOES I HAVE", inst.components.stats.numberofdoublejumps)
	
		-- inst:AddComponent("playercontroller_1")
	-- inst:AddComponent("keydetector")

	--inst.components.jumper:SetAirealMovementSpeed(15)
	
	inst:DoTaskInTime(0, function()
		inst.components.jumper:ApplyGroundChecker()
	end)
	
	inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	
	
	inst.Physics:SetDamping(0.0) 
	inst.Physics:SetFriction(.6) 
	inst.Physics:SetMass(0.9)
	inst.Physics:SetRestitution(0)
	
	inst:AddComponent("blocker")
	inst.components.blocker:SetGaurdEndurance()
	
	inst:AddComponent("hoverbadge")
	inst.components.hoverbadge:TestBadge()
	
	--12-31-21 DOES IT WORK BETTER IF WE ADD AN EXTRA SECOND TO IT? IT MIGHT, SINCE THIS ACTUALLY SEEMED TO WORK FOR PLAYERS
	--NO, FORGET THAT. TOO STUPID
	-- inst:DoTaskInTime(0.3, function() 
		-- inst:AddComponent("hoverbadge")
		-- inst.components.hoverbadge:TestBadge()
	-- end)
	
	inst:AddComponent("talker")
	
	
	inst.sg:GoToState("taunt")
	
	-- inst:DoPeriodicTask(0, function()
		-- inst:PushEvent("update_stategraph")
	-- end)
	
    -- local brain = require "brains/spiderbrain"
    -- inst:SetBrain(brain)
	
	-- local newbrain = require "brains/spiderfighterbrain"
    -- inst:SetBrain(newbrain)

    -- inst:ListenForEvent("attacked", OnAttacked)
    -- inst:ListenForEvent("dusktime", function() StartNight(inst) end, GetWorld())
	

	inst:ListenForEvent("on_hitted", function(inst, data) 
		-- print("NOBODY WILL EVER KNOW MY TRUE NAME IS SAGE", data.hitbox.components.hitboxes.dam)
		inst.components.aifeelings:ConfidenceBoost(-data.hitbox.components.hitboxes.dam)
	
	end)
	
	inst:ListenForEvent("on_hit", function(inst, data) 
		inst.components.aifeelings:ConfidenceBoost(data.hitbox.components.hitboxes.dam)
	end)
	
	
	--6-10-18 SET EVERYTHING UP TO REMOVE ITSELF WHEN IT DIES
	-- inst:ListenForEvent("outofhp", RemoveSpider)
	inst:ListenForEvent("outoflives", RemoveSpider)
	-- inst:ListenForEvent("outofhp", function(inst)
		-- print("IM OUT OF HP")
		-- -- RemoveSpider(inst)
		-- inst.sg:GoToState("death") --LET THE DEATH ANIMATION PLAY OUT FIRST
	-- end)
	-- inst:ListenForEvent("outoflives", function(inst)
		-- print("IM OUT OF LIVES!!!")
		-- RemoveSpider(inst)
	-- end)
	
	inst:AddTag("refresh_softpush") --CAN THESE GUYS STOP SLIDING AROUND LIKE THAT PLEASE???
	

    return inst
end



local function create_spider(Sim)
    local inst = create_common(Sim)
	
	--PUT THEIR BUILD ABOVE EVERYTHING ELSE, BUT DONT DECLARE THOSE
	inst.AnimState:SetBuild("spider_harold")
	inst.components.stats.displayname = "Harold" --11-27-20
	
	if not TheWorld.ismastersim then
        return inst
    end
	
	-- inst.components.aifeelings.ailevel = 10
	inst.components.aifeelings.ailevel = 10 --5 --DECLARE LEVEL BEFORE THE BRAIN STARTS UP
	
	local newbrain = require "brains/spiderfighterbrain"
    inst:SetBrain(newbrain)

    -- inst:ListenForEvent("attacked", OnAttacked)
    -- inst:ListenForEvent("dusktime", function() StartNight(inst) end, GetWorld())
	
	inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0) --sizey -shape
	

    return inst
end



local function create_mediumspider(Sim)
    local inst = create_common(Sim)
	
	inst.AnimState:SetBuild("spider_warrior_build")
	inst.components.stats.displayname = "Spider Warrior"
	
	if not TheWorld.ismastersim then
        return inst
    end
	
	inst.components.aifeelings.ailevel = 6 --5 --DECLARE LEVEL BEFORE THE BRAIN STARTS UP
	
	local newbrain = require "brains/spiderfighterbrain"
    inst:SetBrain(newbrain)

    -- inst:ListenForEvent("attacked", OnAttacked)
    -- inst:ListenForEvent("dusktime", function() StartNight(inst) end, GetWorld())
	
	
	-- inst.AnimState:SetBuild("spider_harold")
	
	inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0) --sizey -shape
	

    return inst
end


--WE DONT USE THIS ONE
local function create_warrior(Sim)
    local inst = create_common(Sim)
    
    inst.AnimState:SetBuild("spider_warrior_build")

    inst:AddTag("spider_warrior")

    inst.components.health:SetMaxHealth(TUNING.SPIDER_WARRIOR_HEALTH)

    inst.components.combat:SetDefaultDamage(TUNING.SPIDER_WARRIOR_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.SPIDER_WARRIOR_ATTACK_PERIOD + math.random()*2)
    inst.components.combat:SetRange(TUNING.SPIDER_WARRIOR_ATTACK_RANGE, TUNING.SPIDER_WARRIOR_HIT_RANGE)
    inst.components.combat:SetRetargetFunction(2, WarriorRetarget)
    inst.components.combat:SetHurtSound("dontstarve/creatures/spiderwarrior/hit_response")
    
    inst.components.locomotor.walkspeed = TUNING.SPIDER_WARRIOR_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.SPIDER_WARRIOR_RUN_SPEED
	
	-- inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED
    return inst
end



local function create_easyspider(Sim)
    local inst = create_common(Sim)
	
	inst.components.stats.displayname = "Spider"
	
	if not TheWorld.ismastersim then
        return inst
    end
	
	inst.components.percent.maxhp = 25
	inst.components.aifeelings.ailevel = 3
	
	inst.components.locomotor.dashspeed = 1.5 * 5 --EASY SPIDER, SOMEWHERE IN BETWEEN
	
	inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0)
	
	local newbrain = require "brains/dumbspiderbrain"
    inst:SetBrain(newbrain)
	

    return inst
end


local function create_babyspider(Sim)
    local inst = create_common(Sim)
	
	--THESE COUNT AS VISUAL CHANGES THAT NEED TO APPLY
	inst.components.stats.sizemultiplier = 0.65
	inst.Transform:SetScale(0.65, 0.65, 0.65)
	inst.AnimState:SetBuild("spider_baby")
	
	if not TheWorld.ismastersim then
        return inst
    end
	
	
	inst.components.percent.maxhp = 15
	
	--MAKE THEM WAAAAY SLOWER
	inst.components.locomotor.dashspeed = 1.2 * 5 --1.6
	
	--LETS MAKE THEM LIGHTER AND FLOATIER TOO
	inst.components.stats.jumpheight = 17 --20
	inst.components.stats.gravity = 0.7
	inst.components.stats.fallingspeed = 1.2 --1.5
	inst.components.stats.weight = 70 --85
	
	inst.components.stats.air_speed = 0.9 * 5 --0.9 --1.15
	
	inst.components.aifeelings.ailevel = 1
	
	inst:AddTag("ignore_heavy_boxes") --7-1-18 --LET THE BABIES WALK FREELY PAST QUEENS AND DENS
	

	
	local newbrain = require "brains/dumbspiderbrain"
    inst:SetBrain(newbrain)
	

    return inst
end





--LETS CREATE SOME GOOFY SPECIAL CASES FOR SINGLEPLAYER HORDE MODE
local function create_sleepy_easy(Sim)
    local inst = create_easyspider(Sim)
	
	if not TheWorld.ismastersim then
        return inst
    end
	
	inst.sg:GoToState("sleep")

    return inst
end

local function create_sleepy_medium(Sim)
    local inst = create_mediumspider(Sim)
	
	if not TheWorld.ismastersim then
        return inst
    end
	
	-- inst.sg:GoToState("sleep")
	inst.sg:GoToState("napping")

    return inst
end




--return Prefab( "forest/monsters/spider", create_spider, assets, prefabs),
return Prefab( "forest/monsters/spiderfighter", create_spider, assets, prefabs),
	Prefab( "forest/monsters/spiderfighter_easy", create_easyspider, assets, prefabs),
	Prefab( "forest/monsters/spiderfighter_medium", create_mediumspider, assets, prefabs),
	Prefab( "forest/monsters/spiderfighter_baby", create_babyspider, assets, prefabs),
    Prefab( "forest/monsters/spider_warrior", create_warrior, warrior_assets),
	--AND NOW SOME FUN ONES  (DONT FORGET THE COMMA BETWEEN ALL BUT THE LAST ONE)
	Prefab( "forest/monsters/spiderfighter_sleepy_easy", create_sleepy_easy, assets, prefabs),
	Prefab( "forest/monsters/spiderfighter_sleepy_medium", create_sleepy_medium, assets, prefabs)