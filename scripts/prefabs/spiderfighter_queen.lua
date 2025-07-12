require "stategraphs/SGspiderfighter_queen"

local assets =
{
	Asset("SOUND", "sound/spider.fsb"),
	Asset( "ANIM", "anim/spiderfighter_queen.zip" ), --8-18
}
    
    
local prefabs =
{
	"spidergland",
    "monstermeat",
    "silk",
}

local function NormalRetarget(inst)
    local targetDist = TUNING.SPIDER_TARGET_DIST
    -- if inst.components.knownlocations:GetLocation("investigate") then --DST I GUESS??
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


--6-10-18 A SIMPLE WAY TO REMOVE THE NOW-DEAD SPIDER CORPSES LAYING AROUND
local function RemoveSpider(inst)
	inst.components.hurtboxes:RemoveAllHurtboxes()
	TheSim:FindFirstEntityWithTag("anchor").components.gamerules:CleanOpponentList(inst) --1-30-21
		
	if inst.components.hoverbadge then --6-10-18 OH YEA. GET RID OF THESE THINGS TOO
		inst.components.hoverbadge:RemoveAllBadges()
	end
	
	inst:Remove()
end



local function create_spider(Sim)
    -- local inst = create_common(Sim)
	--6-27-18 LETS TAKE "CREATE COMMON" OUT OF THIS AND JUST START FROM SCRATCH
	local inst = CreateEntity()
	inst.OnEntitySleep = OnEntitySleep
	
    inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLightWatcher()
	-- local shadow = inst.entity:AddDynamicShadow() --1-30-21 SHE SHOULDN'T HAVE A SHADOW
	-- shadow:SetSize( 1.5, .5 )
    -- inst.Transform:SetFourFaced()
	inst.Transform:SetTwoFaced() --9-6
	inst.entity:AddNetwork() --DST
    
    
    ----------
    
    inst:AddTag("monster")
    inst:AddTag("hostile")
	inst:AddTag("scarytoprey")      
    
    MakeCharacterPhysics(inst, 10, .5)

    
    inst:AddTag("spider")
	inst:AddTag("armor")
	
	inst:AddTag("fighter")
	inst:AddTag("nograbbing") --TRY TO AVOID USING THIS. ONLY USE STATE-TAG VERSIONS OF THIS (DON'T WANT TO FORCE ON-HIT FUNCTIONS TO CHECK FOR BOTH VERSIONS OF NO-GRABBING TAGS EVERY TIME)
	
	inst:AddComponent("stats")
	
	--3-31-19 LETS PUT THESE BACK HERE AND SEE IF THIS HELPS
	inst:AddComponent("hitbox")
	inst:AddComponent("hurtboxes")
	inst:AddComponent("launchgravity")
	inst:AddComponent("jumper")
	inst:AddComponent("colourtweener")
	
	inst:AddComponent("percent")
	
	
	inst.components.stats.team = "spiderclan" --ANY SPIDERS SHE SPAWNS CANNOT HIT HER
	
	inst.components.stats.bankname = "spiderfighter_queen" --11-3-16 YOU SHOULD USE THIS TO SET ANIMS NOW, BECAUSE OTHER PARTS OF THE GAME NEED THESE ANIM FILE NAMES
	inst.components.stats.buildname = "spiderfighter_queen" --spider_queen_build
	
	inst.AnimState:SetBank(inst.components.stats.bankname)
	inst.AnimState:SetBuild(inst.components.stats.buildname)
	
	inst:AddComponent("visualsmanager") --2-10-18 SHINY NEW ONE!~ REUSEABLE DST
	
	--DST CHANGE- THESE ARE NEEDED FOR THE SPIDERS TOO!
	inst.customhpbadgelives = net_byte(inst.GUID, "customhpbadge.lives", "customhpbadgedirty")
	inst.customhpbadgepercent = net_ushortint(inst.GUID, "customhpbadge.percent", "customhpbadgedirty")
	
	inst:AddTag("nonplayerfighter") --DST CHANGE- FOR PREFABS THAT ARE FIGHTERS BUT NOT PLAYERCOMMON PREFABS
	
	
	--DST CHANGE- WHERE DO THESE GO AGAIN? LETS JUST SLAP EM IN HERE--------
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.persists = false --3-9-19 -THESE ARE TECHNICALLY HANDLED AS PLAYERS NOW. THEY NEED TO BE REMOVED FROM THE WORLD WHEN EVERYONE ELSE LEAVES
	
	
	--10-18-21 I'M PRETTY SURE ALL THIS CAN HAPPEN DOWN HERE. CLIENTS SHOULDN'T NEED THIS.
	-----------------------------------
	-- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
	inst.components.locomotor:SetSlowMultiplier( 1 )
	inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
  
	inst:SetStateGraph("SGspiderfighter_queen")
	
	---------------------        
    MakeMediumBurnableCharacter(inst, "body")
    MakeMediumFreezableCharacter(inst, "body")
    inst.components.burnable.flammability = TUNING.SPIDER_FLAMMABILITY
    ---------------------       
    
	inst:AddComponent("aifeelings")
	-----------------------------------
	
	
	
	
	
	------------------
    inst:AddComponent("health")

    ------------------
    
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
	
	

    inst.components.health:SetMaxHealth(TUNING.SPIDER_HEALTH)

    inst.components.combat:SetDefaultDamage(TUNING.SPIDER_DAMAGE)
    -- inst.components.combat:SetAttackPeriod(TUNING.SPIDER_ATTACK_PERIOD)
	inst.components.combat:SetAttackPeriod(1)
    inst.components.combat:SetRetargetFunction(1, NormalRetarget)
    inst.components.combat:SetHurtSound("dontstarve/creatures/spider/hit_response")
	inst.components.combat.attackrange = 3.4

    inst.components.locomotor.walkspeed = TUNING.SPIDER_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.SPIDER_RUN_SPEED
	
	inst.components.locomotor.dashspeed = 1.0 * 5 --6-30
	
	

	inst.components.stats.jumpheight = 20
	inst.components.stats.gravity = 1
	inst.components.stats.fallingspeed = 1.5
	inst.components.stats.weight = 68 --98
	
	inst.components.stats.numberofdoublejumps = 1 --oh.... --10
	
	
	---3-31-19 OH THATS RIGHT... WE DID THIS ALL FUNNY SO WE ACTUALLY DO NEED THESE ADDED UP THERE
	-- inst:AddComponent("hitbox")
	-- inst:AddComponent("hurtboxes")
	-- inst:AddComponent("launchgravity")
	-- inst:AddComponent("jumper")
	-- inst:AddComponent("colourtweener")
	
	inst.components.percent:DoDamage(100)
	inst.Transform:SetScale(0.85, 0.85, 0.85)
	
	--1-26-22 SLAPPING THIS IN HERE BY DEFAULT SO SPAWNING ONE IN IS STILL KILLABLE
	inst.components.percent.hpmode = true
	inst.components.percent.maxhp = 350
	inst:AddTag("nohud")
	
	inst:DoTaskInTime(0, function()
		inst.components.hurtboxes:CreateHurtbox(6.8, 0, 1.6) 
		inst.components.hurtboxes:CreateHurtbox(4.5, -1.5, 1) 
		inst.components.hurtboxes:CreateHurtbox(4.5, 1.0, 1) 
		inst.components.hurtboxes:SpawnPlayerbox(0, 0.5, 1.2, 1.0, 0) --(xpos, ypos, size, sizey, shape)    --35, 0.5
		-- inst.components.hurtboxes:SpawnPlayerbox(0, 1.6, 0.25, 0.5, 0)
	end)
	
	inst:DoTaskInTime(0, function()
		inst.components.jumper:ApplyGroundChecker()
	end)
	
	inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	
	
	inst.Physics:SetDamping(0.0) 
	inst.Physics:SetFriction(.6) 
	inst.Physics:SetMass(0.9)
	inst.Physics:SetRestitution(0)
	
	inst:AddComponent("hoverbadge")
	inst.components.hoverbadge:TestBadge()
	
	inst:AddComponent("blocker")
	inst.components.blocker:SetGaurdEndurance()
	
	inst:AddComponent("talker")
    inst:AddComponent("eater")
    inst.components.eater.strongstomach = true -- can eat monster meat!
	
	----QUEEN SPECIFIC----
	inst:AddTag("cpu")
	inst:AddComponent("spiderspawner")
	inst:AddTag("heavy") --6-27-18 DST CHANGE --MAKE IT HARD TO PUSH AROUND
	inst:AddTag("nofreezing") --7-15-18 --FREEZING DOESN'T WORK WELL WITH THIS CHARACTER
	-- inst:StartUpdatingComponent("spiderspawner")
	inst.components.spiderspawner.babytype = "easy" --2-2-22 THEY CAN HANDLE IT
	inst.components.spiderspawner:InitiateSpawner(10)
	
	--6-10-18 SET EVERYTHING UP TO REMOVE ITSELF WHEN IT DIES
	inst:ListenForEvent("outoflives", RemoveSpider)
	

	--OH YEA. DONT FORGET THE BRAIN. KIND OF IMPORTANT
	local newbrain = require "brains/queenbossbrain"
    inst:SetBrain(newbrain)
	
	inst.components.aifeelings.ailevel = 1 --I GUESS QUEEN IS LEVEL 1, BY ALL OTHER BEHAVIORAL STANDARDS

    return inst
end


return Prefab( "forest/monsters/spiderfighter_queen", create_spider, assets, prefabs)