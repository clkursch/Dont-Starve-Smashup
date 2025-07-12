require "prefabutil"
local assets =
{
	Asset("ANIM", "anim/spider_egg_sac.zip"),
    Asset("SOUND", "sound/spider.fsb"),
}

local function ondeploy(inst, pt) 
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spider_egg_sack")
    local tree = SpawnPrefab("spiderden") 
    if tree then 
        tree.Transform:SetPosition(pt.x, pt.y, pt.z) 
        inst.components.stackable:Get():Remove()
    end 
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


local function fn(Sim)
	local inst = CreateEntity()
		local trans = inst.entity:AddTransform()
		local anim = inst.entity:AddAnimState()
		inst.entity:AddGroundCreepEntity()
		inst.entity:AddNetwork()

		inst.entity:AddSoundEmitter()

		inst.data = {}

		MakeObstaclePhysics(inst, .5)

		local minimap = inst.entity:AddMiniMapEntity()
		minimap:SetIcon( "spiderden.png" )

		anim:SetBank("spider_cocoon")
		anim:SetBuild("spider_cocoon")
		anim:PlayAnimation("cocoon_small", true)
		anim:HideSymbol("bedazzled_flare") -- WHY IS THIS ON BY DEFAULT >:(

		inst:AddTag("structure")
	    inst:AddTag("hostile")
		inst:AddTag("spiderden")
		inst:AddTag("hive")
		
		--10-19-20 SO ATTACK OVERLAY WONT SHIFT THEIR Z AXIS OFF THE BACKGROUND
		inst:AddTag("ignore_overlay")

		-------------------
		-- inst:AddComponent("health")
		-- inst.components.health:SetMaxHealth(200)

		-------------------
		-- inst:AddComponent("childspawner")
		-- inst.components.childspawner.childname = "spider"
		-- inst.components.childspawner:SetRegenPeriod(TUNING.SPIDERDEN_REGEN_TIME)
		-- inst.components.childspawner:SetSpawnPeriod(TUNING.SPIDERDEN_RELEASE_TIME)

		-- inst.components.childspawner:SetSpawnedFn(onspawnspider)
		-- inst:ListenForEvent("creepactivate", SpawnInvestigators)


		-- inst:SetPrefabName("spiderden")
		inst:SetPrefabName("spiderfightereggsack")
	
	
	--FIGHTER STUFF--
	MakeCharacterPhysics(inst, 5, .5)
	
	inst:AddTag("fighter")
	inst:AddTag("nograbbing") --TRY TO AVOID USING THIS. ONLY USE STATE-TAG VERSIONS OF THIS (DON'T WANT TO FORCE ON-HIT FUNCTIONS TO CHECK FOR BOTH VERSIONS OF NO-GRABBING TAGS EVERY TIME)
	
	inst:AddComponent("stats")
	inst:AddComponent("locomotor") 
	
	inst:AddComponent("hitbox")
	inst:AddComponent("hurtboxes")
	inst:AddComponent("launchgravity")
	inst:AddComponent("jumper")
	inst:AddComponent("colourtweener")
	
	inst:AddComponent("percent")
	-- inst.components.percent:DoDamage(100)
	inst.components.percent.hpmode = true
	inst.components.percent.maxhp = 40
	
	-- FOR THE FACE THAT SHOWS UP ON THE HUD --
	inst.components.stats.facepath = "minimap/minimap_data.xml"
	inst.components.stats.facefile = "spiderden.png"
	
	inst.components.stats.team = "spiderclan" --ANY SPIDERS SHE SPAWNS CANNOT HIT HER
	
	inst:SetStateGraph("SGspiderden")
	inst:AddComponent("visualsmanager")
	
	
	inst.components.stats.numberofdoublejumps = 0
	
	inst:AddTag("spider") --WAIT WHY IS IT A SPIDER?...
	inst:AddTag("armor")
	
	inst:AddTag("nohud") --6-10-18
	inst:AddTag("nonplayerfighter") --DST CHANGE- FOR PREFABS THAT ARE FIGHTERS BUT NOT PLAYERCOMMON PREFABS
	
	
	--DST CHANGE- WHERE DO THESE GO AGAIN? LETS JUST SLAP EM IN HERE--------
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	
	inst.persists = false --3-9-19 -THESE ARE TECHNICALLY HANDLED AS PLAYERS NOW. THEY NEED TO BE REMOVED FROM THE WORLD WHEN EVERYONE ELSE LEAVES
	
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(200)
	
	
	inst:DoTaskInTime(0, function()
		inst.components.hurtboxes:CreateHurtbox(5.0, 0, 1.2) 
		inst.components.hurtboxes:SpawnPlayerbox(0, 0.3, 0.8, 1.0, 0) --(xpos, ypos, size, sizey, shape)    --35, 0.5
	end)
	
	inst.Transform:SetScale(1.0, 1.0, 1.0)
	
	inst:DoTaskInTime(0, function()
		inst.components.jumper:ApplyGroundChecker()
	end)
	
	inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	
	
	inst.Physics:SetDamping(0.0) 
	inst.Physics:SetFriction(1.0) 
	inst.Physics:SetMass(10.0)
	inst.Physics:SetRestitution(0)
	
	inst:AddComponent("hoverbadge")
	inst.components.hoverbadge:TestBadge()
	
	inst:AddComponent("spiderspawner")
	inst.components.spiderspawner:InitiateSpawner(0)
	inst.components.spiderspawner.autobirth = true
	inst.components.spiderspawner.babytype = "easy"
	inst.components.spiderspawner.newkidtimer = 6
	inst.components.spiderspawner.respawnrate = 12
	
	inst:AddComponent("blocker")
	inst.components.blocker:SetGaurdEndurance()
	
	inst:AddComponent("talker")
	
	inst:AddTag("cpu")
	inst:AddTag("heavy") --6-17-18 MEANS IT CANNOT BE PUSHED AROUND
	
	
	inst:ListenForEvent("outoflives", RemoveSpider)
    

    return inst
end



--7-3-20 MORE SIZES!!
local function create_tier2(Sim)
    local inst = fn(Sim)
	 --BIGGERER
	--THE LARGER TEIR ANIM DIDNT SHOW UP EARLIER??? MAYBE THIS WILL HELP
	-- inst:DoTaskInTime(0.2, function()
		inst.AnimState:PlayAnimation("cocoon_medium", true)
	-- end)
	--10-3-20 NO IT'S BECAUSE IT PLAYS ITS ANIMATION BASED ON THE NAME. THE EVENT HANDLER IS IN THE STATEGRAPH
	inst:AddTag("medium_den")
	
	if not TheWorld.ismastersim then
        return inst
    end
	inst.components.spiderspawner.maxkids = 4
	inst.components.spiderspawner.newkidtimer = 6
	inst.components.spiderspawner.respawnrate = 12
	
    return inst
end


local function create_tier3(Sim)
    local inst = fn(Sim)
	 --BIGGERER
		inst.AnimState:PlayAnimation("cocoon_large", true)
	--10-3-20 
	inst:AddTag("large_den")
	
	if not TheWorld.ismastersim then
        return inst
    end
	inst.components.spiderspawner.maxkids = 5
	inst.components.spiderspawner.newkidtimer = 5
	inst.components.spiderspawner.respawnrate = 10
	
    return inst
end



--A VERSION OF TIER1 THAT ONLY SPAWNS BABIES
local function create_tier0(Sim)
    local inst = fn(Sim)
	
	if not TheWorld.ismastersim then
        return inst
    end
	inst.components.spiderspawner.maxkids = 6 --MAKING THE MAX REALLY HIGH CUZ THEY EASY
	inst.components.spiderspawner.babytype = "easy"
    return inst
end


return Prefab( "common/inventory/spiderfightereggsack", fn, assets),
	Prefab( "common/inventory/spiderfightereggsack_tier0", create_tier0, assets),
	Prefab( "common/inventory/spiderfightereggsack_tier2", create_tier2, assets),
	Prefab( "common/inventory/spiderfightereggsack_tier3", create_tier3, assets),
	MakePlacer( "common/spidereggsack_placer", "spider_cocoon", "spider_cocoon", "cocoon_small" ) 

