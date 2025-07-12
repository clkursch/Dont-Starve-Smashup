
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {
		Asset( "ANIM", "anim/newwes.zip" ),
		Asset( "ANIM", "anim/reflectorbox.zip" ), --SINCE HE USES THIS IN HIS ANIMATIONS
		-- Asset( "ANIM", "anim/newwesblue.zip" ), --DOESNT EXIST DUMMY
		Asset( "ANIM", "anim/newwesblue.zip" ), --HIS ALT SKIN
		Asset( "ANIM", "anim/newwesgreyscale.zip" ),
		Asset( "ANIM", "anim/newwesyellow.zip" ),
}

local function onswaphurtboxes(inst, data)

	inst.components.hurtboxes:ResetHurtboxes()
	if data == "idle" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.45, 1.15) --A BIT SMALLER
	end
	if data == "leanf" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.45, 0.6)
		inst.components.hurtboxes:SpawnHurtbox(.2, 1.1, 0.45, 0.5)
	end
	if data == "walking" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.5, 1.15)
	end
	if data == "dashing" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.5, 0.5)
		inst.components.hurtboxes:SpawnHurtbox(.5, 0.7, 0.45, 0.55)
	end
	if data == "ducking" then
		inst.components.hurtboxes:SpawnHurtbox(0.05, 0.0, 0.5, 0.7)
	end
	
	if data == "forward" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.65, 0.5)
		inst.components.hurtboxes:SpawnHurtbox(.4, 0.9, 0.6, 0.5)
	end

	if data == "grounded" then
		inst.components.hurtboxes:SpawnHurtbox(-0.3, 0.0, 1.15, 0.28)
	end
	if data == "air_idle" then
		inst.components.hurtboxes:SpawnHurtbox(0.05, -0.1, 0.5, 0.9)
	end
	if data == "flipping" then
		inst.components.hurtboxes:SpawnHurtbox(-0.1, -0.2, 0.7, 0)
	end
	
	if data == "landing" then
		inst.components.hurtboxes:SpawnHurtboxTemp(0.35, 0.75, 0.45, 0, 4)
		inst.components.hurtboxes:SpawnHurtbox(0.15, 0.0, 0.7, 0.60)
	end
	
	if data == "dspec" then
		-- inst.components.hurtboxes:CreateHurtbox(0.4, 0.2, 0.5, 0.8)
		-- inst.components.hurtboxes:CreateHurtbox(1.2, 0.0, 0.9)
		-- inst.components.hurtboxes:CreateHurtbox(2.0, 0.25, 0.2)
		
		inst.components.hurtboxes:SpawnHurtbox(0.1, 0.5, 0.4, 0.7)
		inst.components.hurtboxes:SpawnHurtbox(0.0, 0.0, 0.2, 0.3)
	end
	
	if data == "fair" then
		inst.components.hurtboxes:SpawnHurtbox(0.3, 0.3, 0.7, 0.7)
	end
	
	if data == "hitstun1" then
		inst.components.hurtboxes:SpawnHurtbox(0, 0.0, 0.45, 0.6)
		inst.components.hurtboxes:SpawnHurtbox(-0.2, 1.2, 0.45, 0.5)
	end
	if data == "hitstun2" then
		inst.components.hurtboxes:SpawnHurtbox(-0.3, 0.7, 1.0, 0.4)
		inst.components.hurtboxes:SpawnHurtbox(0.4, 0.0, 0.4)
	end
	if data == "hitstun3" then
		inst.components.hurtboxes:SpawnHurtbox(0.2, 0.2, 0.7, 0.8)
	end
	if data == "ledge_hanging" then
		inst.components.hurtboxes:SpawnHurtbox(-0.2, -1.7, 0.3, 0.7)
	end
end


--CUSTOM SKINNER, WHICH AUTO SWITCHES TO A DIFFERENT SKIN IF A DITTO IS PRESENT
local function Reskinner(inst)
    -- local ents = AllPlayers --TheSim:FindEntities(0,0,0, 100, {"player"})
	local reskinloop = true
	
	while reskinloop == true do
		reskinloop = false
		local openslot = true
		for k, v in pairs(AllPlayers) do --SEARCH THROUGH ALL CURRENT PLAYERS ON SCREEN
			--IF ANY OF THEM ARE THE SAME PLAYER AS US AND HAVE THE SAME SKIN  --WOW INST.PREFAB HASNT REGISTERED YET. GUESS WE GOTTA HARDCODE??
			print("SKINFO", v, v.prefab, v.components.stats.skinnum, inst.components.stats.skinnum,  v ~= inst)
			if v ~= inst and v.prefab == "newwes" and v.components.stats.skinnum == inst.components.stats.skinnum then 
				-- inst.components.stats.buildname = "newwes_blue" --GIVE OURSELVES THIS OTHER SKIN
				inst.components.stats.skinnum = inst.components.stats.skinnum + 1 
				openslot = false
				print("THATS MY SKIN")
			end
		end
		if openslot == true then
			reskinloop = false --DONT GO BACK FOR ANOTHER ROUND!
		end
	end
end


-- This initializes for both clients and the host
local common_postinit = function(inst) 
	
	-- Reskinner(inst)
	
	inst.components.stats.altskins = NEWWES_SKINS
	inst.components.stats.bankname = "newwes"  --"newwes" 
	-- inst.components.stats.buildname = "newwes"
	-- inst.components.stats.buildname = NEWWES_SKINS[inst.components.stats.skinnum]
	
	-- Reskinner(inst) --11-19-17 CHECK FOR AUTO-RESKIN
	
	-- inst.AnimState:SetBank(inst.components.stats.bankname) --MOVING THIS TO PLAYERCOMMON
	-- inst.AnimState:SetBuild(inst.components.stats.buildname)
	
	inst.components.stats.facepath = "minimap/minimap_data.xml"
	inst.components.stats.facefile = "wes.png" --THE NAME OF THE FILE FOR THE LIVES COUNTER (IF ONE DOESN'T EXIST IN GAME, YOU'LL NEED TO MAKE ONE)

	inst.components.stats.sizemultiplier = 1
	inst.Transform:SetScale(inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier,inst.components.stats.sizemultiplier)
	
	-- inst.components.stats.stategraphname = "SGnewwes" --SGbrawlerv1- NOT ANYMORE!!!
	inst:SetStateGraph("SGnewwes")
		
	-- inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0) --sizey -shape     (0.4, 1.7, 1.5, 0.5, 0)
	-- inst.components.hurtboxes:SpawnPlayerbox(0, 0.5, 0.35, 0.75, 0) --2-8 CHANGING FROM 0.25 TO 0.35
	-- inst.components.hurtboxes:CreateHurtbox(2.5, 0, 0.6) --1.8, 0, 0.5
	-- inst.components.hurtboxes:CreateHurtbox(1.5, 0, 1.2) --1.8, 0, 0.5
	
	
	-- choose which sounds this character will play
	inst.soundsname = "wilson" --IF YOUR CHARACTER WILL BE USING VOICE SOUNDS, FOR WHATEVER REASON. IF NOT, IGNORE THIS
end

-- This initializes for the host only
local master_postinit = function(inst)

	
	inst.components.stats.gravity = 1.5  --1.7 --FALCOS   --MARIOS: 0.87
	inst.components.stats.fallingspeed = 2.8 --3.1 --FALCOS   MARIO: 1.5
	inst.components.stats.fastfallingspeedincrease = 0.15  --MELEE SPACIES HAVE A MUCH LOWER FASTFALL INCREASE
	inst.components.stats.basefallingspeed = 2.8 --3.1 --OH... ITS CUZ YOU NEED THIS ONE TOO...
	inst.components.stats.weight = 70   --MARIO: 98
	inst.components.stats.air_friction = 0.02 --MELEE FALCO
	
	inst.components.stats.jumpheight = 24 --25 --20 DEFAULT
	inst.components.stats.doublejumpheight = 24 --25 --20 DEFAULT
	inst.components.stats.shorthopheight = 13 --12 DEFAULT
	inst.components.stats.air_speed = 1.15 * 5 --1.05 * 5
	
	--THE REAL VALUES
	inst.components.hurtboxes:CreateLedgeGrabBox(0.4, 1.7, 1.5, 0.5, 0)
	inst.components.hurtboxes:SpawnPlayerbox(0, 0.7, 0.35, 0.7, 0)
	
	
	inst.components.locomotor.runspeed = 1.3 * 5 --6
	inst.components.locomotor.dashspeed = 2.0 * 5 --MARIOS: 1.6  

	inst:ListenForEvent("swaphurtboxes", function(inst, data)
		onswaphurtboxes(inst, data.preset)
	end)
	
	
	-- a minimap icon must be specified
	-- inst.MiniMapEntity:SetIcon( "kaji.tex" )
	inst.MiniMapEntity:SetIcon( "newwes.tex" )
	inst.soundsname = "wilson"
	
	--10-21-18 FOR CHARACTER SPECIFIC LANDING ACTIONS.
	--ADDITIONAL CODE THAT WILL RUN WHEN YOUR CHARACTER HITS THE GROUND (or grabs a ledge)
	inst.components.launchgravity.onlandingfn = function() 
		--REFRESH HIS FSPECIAL SWING STATUS ON HITTING THE GROUND
		inst.components.stats.storagevar2 = "left_swing_free"
		inst.components.stats.storagevar3 = "right_swing_free"
	end
	
	--3-27-22 GIVE HIM THESE BACK WHEN HE RESPAWNS
	inst:ListenForEvent("onko", function() 
		inst.components.stats.storagevar2 = "left_swing_free"
		inst.components.stats.storagevar3 = "right_swing_free"
	end)
	
	
end



return MakePlayerCharacter("newwes", nil, assets, common_postinit, master_postinit, nil)
