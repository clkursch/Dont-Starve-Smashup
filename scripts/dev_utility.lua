

--TABLE OF CONTENTS:

--sound test
--trailer 
--code snippers

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local FRAMES = GLOBAL.FRAMES

--UNCOMMENT TO ENABLE SOUND TESTS
-- chargefkey = GLOBAL.KEY_F 
-- throwfkey = GLOBAL.KEY_T
-- soundcycle = GLOBAL.KEY_F




local soundtestRR = {


"dontstarve/wilson/attack_nightsword",
 "dontstarve/common/rebirth",



"dontstarve/common/place_ground",
"dontstarve/creatures/krampus/kick_impact",
"dontstarve/wilson/hit",
"dontstarve/creatures/deerclops/bodyfall_dirt",


"dontstarve/impacts/impact_fur_armour_dull", --LIGHT THWAPPING SOUND	 --MAYBE LIGHT THWAP HIT?
"dontstarve/impacts/impact_wood_armour_dull",   --LIGHT, BUT WOODY
"dontstarve/common/destroy_stone",    --MAYBE HEAVY HITSOUND BUT CRUMBLES REAL LOUD
"dontstarve/common/destroy_stone", --HEAVY HIT MAYBE
"dontstarve/wilson/rock_break",  --ROCK BREAK	--MIX FOR HEAVY HIT SOUND?	BUT SOUNDS DISTANT AND HIGH
"dontstarve/common/place_ground", --MAYBE FOR SHEILDS  --ACTUALLY THIS IS A GREAT SMALL HIT SOUND --PERFECT SMALL SLICE SOUND!!

--ALMOST EVEN FOR HEAVY HITSOUND. NOT AS DRAMATIC BUT FASTER, BUT A BIT HIGHER
 "dontstarve/common/place_structure_stone", --HOUSE --^^^^ A SLIGHTLY DULLER VERSION OF THIS, BUT ALSO SOFTER

 --SAME. A LITTLE FASTER BUT SOFTER
  "dontstarve/common/rebirth",		--DECENT HEAVY PUNCH SOUND? --NICE AND FAST/SHARP BUT A BIT HIGH
  
  --ALL GOOD HEAVY HITSOUNDS OMG
  "dontstarve/common/resurrectionstone_break", --LEGO CRASH  --DECENT HEAVY HIT SOUND
  
  --JESUS ALMOST IDENTICLE TO HEAVY HITSUND BUT SLIGHTLY FASTER AND STRANGE RING TONE TO IT
  "dontstarve/wilson/use_armour_break",  --BREAKING WOOD/MAYBE BONE --TRY AS HITSOUND
  
  --CURRENT --WAIT...OK MOVE TESE ALL DOWN DANGIT
"dontstarve/creatures/rocklobster/explode",  --A LITTLE SOFT AND GRAVVELY   --MEH ROCK SMASH  --WOULD HONESTLY MAKE AN ALRIGHT HIT SOUND --MAYBE HEAVY BLOCK SOUND?
  
  "dontstarve/creatures/deerclops/bodyfall_dirt", --!! A LITLE SLOW AND HUGE SOUNDING --TREE FALLING  --ACTUALLY SOUNDS LIKE A GREAT HEAVY PUNCH
  
  
  "dontstarve/creatures/krampus/kick_impact",  --OOOOH! PERFECT MEDIUM HITSOUND!!!!
"dontstarve/creatures/krampus/bag_impact",	--ANOTHER GOOD HITSOUND???  --FOR SLIGHTLY HEAVIER ATTACKS THAN THE PREVIOUS
  
  "dontstarve/common/balloon_pop",	--POSSIBLE HITSOUND? --MAYBE FOR SLAPS
  
  
"dontstarve"
}


--3-22 FINALLY A PROPER WORKING SOUND TEST
local soundtest = {

	--10-24-20 NEW LAVA_ARENA SOUNDS!
	"dontstarve/common/stone_drop",
	"dontstarve/common/twirl", --MUUCH FASTER VERSION OF THE BOOMERANG TWIRL SOUND
	"dontstarve/common/lava_arena/fireball", --EH, TOO QUIET
	"dontstarve/characters/woodie/moose/slide",
	--OH I GUESS THATS IT...
	
	--local breaking = SpawnPrefab("ground_chunks_breaking") --spawn break effect
    --breaking.Transform:SetPosition(pt.x, 0, pt.z)

	"dontstarve_DLC001/creatures/moose/swhoosh", --slow, dull laggy woosh. same as dragonfly? --nope different, not as cool
	"dontstarve/creatures/together/deer/swish",  --REALLY SLOW HEAVY swingtt
	"dontstarve_DLC001/creatures/dragonfly/swipe", --REALLY COOL NEW SWIPE -SWORD (SORTA THIN/PAPER-ISH SWIPE?)
	"dontstarve_DLC001/creatures/bearger/dustpoof", --INTERESTING SOFT POOF. KINDA LIKE WILSONS USPEC, BUT DIFFERENT
	"dontstarve/creatures/together/antlion/sfx/break_spike", --REALLY agressive heavy woosh (almost sounds like a soft hit)
	"dontstarve_DLC001/creatures/bearger/swhoosh",  --long heavy woosh with slow startup
	
	
	
	--8-5-17 HOOOO BOY. ITS BEEN OVER A YEAR. LETS TAKE A LOOK AT THESE NEW SOUNDS
	"dontstarve/creatures/together/stalker/minion/hit", --cool litle magic hitsound
	"dontstarve_DLC001/creatures/moose/flap", --decent tiny hitsound if made louder
	"dontstarve_DLC001/creatures/moose/swhoosh", --same as dragonfly?
	"dontstarve_DLC001/creatures/moose/lay",
	"dontstarve/creatures/together/bee_queen/attack", --puncturing a cynderblock with a spear
	"dontstarve/creatures/together/deer/swish",  --really delayed but good swing
	"dontstarve/creatures/together/deer/bodyfall",
	"dontstarve/creatures/together/deer/bodyfall_2",
	"dontstarve/creatures/together/deer/footstep",
	"dontstarve/creatures/deerclops/attack",
	"dontstarve/creatures/deerclops/swipe",
	"dontstarve/creatures/eyeballturret/pop", --breaking a jack in the box
	"dontstarve/creatures/eyeballturret/charge", --actually decent short charge sound
	"dontstarve/creatures/eyeballturret/shoot", --space laser
	"dontstarve_DLC001/common/firesupressor_chuff", 
	"dontstarve_DLC001/common/firesupressor_shoot", --high cloud puff
	"dontstarve/tentacle/smalltentacle_attack", --lil baby tenticle
	
	"dontstarve/creatures/rocklobster/clawsnap_small",
	"dontstarve/creatures/rocklobster/clawsnap", --block sound?
	"dontstarve/creatures/rocklobster/foley",
	
	
	"dontstarve/creatures/worm/bite",
	"dontstarve/creatures/worm/emerge",
	"dontstarve_DLC001/creatures/dragonfly/blink",
	"dontstarve_DLC001/creatures/dragonfly/land", --SOMETHIN NEAT -RECORD SCRATCH/SMASH?
	"dontstarve_DLC001/creatures/dragonfly/swipe", --REALLY COOL NEW SWIPE -SWORD (SORTA THIN/PAPER-ISH SWIPE?)
	
	"dontstarve_DLC001/creatures/lightninggoat/jacobshorn", --LIGHTER TEZLA COILS
	"dontstarve_DLC001/creatures/lightninggoat/hoof", --lil frog poke, idk
	"dontstarve_DLC001/creatures/lightninggoat/shocked_electric", --EXACTLY WHAT IT SOUNDS LIKE
	"dontstarve_DLC001/creatures/lightninggoat/headbutt", --really weird swipe.. no buildup, too choppy
	
	
	"dontstarve/creatures/rook_minotaur/pawground",
	"dontstarve/creatures/rook_minotaur/liedown",
	"dontstarve/creatures/rook_minotaur/step", --REEEAALL DEEP THUD
	
	"dontstarve_DLC001/creatures/bearger/step_soft", --REAL TINY THUD SOUNDS
	"dontstarve_DLC001/creatures/bearger/step_stomp", --REAL TINY THUD SOUNDS
	"dontstarve_DLC001/creatures/bearger/groundpound",
	"dontstarve_DLC001/creatures/bearger/dustpoof", --INTERESTING SOFT POOF. KINDA LIKE WILSONS USPEC, BUT DIFFERENT
	"dontstarve/creatures/together/toad_stool/death_fall", --kinda gross heavy splat sound
	"dontstarve/creatures/together/toad_stool/infection_attack",
	"dontstarve/creatures/together/toad_stool/infection_attack_pre",  --very muffled old news camera flash sound
	"dontstarve/creatures/together/toad_stool/spore_shoot", --kinsa like tha "plunk" of a grenade launcher, but still punchy
	
	"dontstarve_DLC001/creatures/deciduous/drake_pop_small", --same as small hitsound
	"dontstarve_DLC001/creatures/deciduous/drake_pop_large", --slightl longer --possible flame re-hit sound?
	
	"dontstarve_DLC001/creatures/deciduous/drake_jump",
	"dontstarve_DLC001/creatures/deciduous/drake_attack", --lol wtf?
	"dontstarve_DLC001/creatures/deciduous/drake_intoground",
	
	"dontstarve/creatures/together/antlion/sfx/break_spike", --REALLY agressive heavy woosh
	"dontstarve/creatures/together/antlion/cast_pre",
	"dontstarve/creatures/together/antlion/cast_post",
	"dontstarve/creatures/together/antlion/sfx/ground_break",
	"dontstarve/creatures/together/antlion/rub",
	"dontstarve/creatures/together/antlion/bodyfall_death", --distant soft poof
	
	"dontstarve_DLC001/creatures/bearger/swhoosh",  --long heavy woosh with slow startup
	"dontstarve_DLC001/creatures/bearger/attack",
	
	--MISC
	"dontstarve/creatures/together/toad_stool/channeling_LP", --?? gurgling --oh god it doesnt stop
	
	--8-5-17 SWEET NEW SHADOW BOSS THINGY SOUNDS
	"dontstarve/creatures/together/klaus/step", --NICE DEEP THUD
	"dontstarve/creatures/together/klaus/swipe",
	"dontstarve/creatures/together/klaus/scratch",
	"dontstarve/creatures/together/klaus/bodyfall", --SOFTER DEEP THUD
	"dontstarve/creatures/together/klaus/hit",
	"dontstarve/creatures/together/klaus/bodyfall_dirt",
	"dontstarve_DLC001/creatures/bearger/groundpound",  --AIGHT, THIS IS IT. THE HEAVIEST POUND SOUND YOU WILL GET
	"dontstarve/creatures/together/klaus/attack_3",
	"dontstarve/creatures/together/klaus/bite",  --REAL SHARP SNAP. SHARPER THAN FISHING POLE BREAK
	

	--OLDER SOUNDS
	"dontstarve/wilson/attack_nightsword", --MAGIC GRUNT SOUND
	"dontstarve/common/destroy_magic",
	-- "dontstarve/common/throne/thronemagic", --oh god
	"dontstarve/common/ancienttable_activate",
	"dontstarve/common/ancienttable_craft", --BUNCHA EERIE GROANS
	"dontstarve/common/ancienttable_repair",
	"dontstarve/common/throne/thronedisappear", 
	"dontstarve/common/shrine/shrine_click",
	"dontstarve/characters/wx78/spark",
	"dontstarve/characters/wx78/levelup",
	"dontstarve/ghost/bloodpump",
	"dontstarve/ghost/ghost_use_bloodpump", --INTERESTING HIT SOUND POOF --WOA. LIKE A SUPER NEAT POOFING DISSAPPEAR SOUND
	"dontstarve/ghost/ghost_get_bloodpump",
	"dontstarve/ghost/ghost_haunt", 
	"dontstarve/wilson/attack_icestaff",
	"dontstarve/wilson/dig",   --I'D SAY THIS IS A PRETTY DECENT. YET UNUSED, HITSOUND FOR SHARP OBJECTS
	"dontstarve/HUD/collect_newitem",
	"dontstarve/HUD/collect_resource",
	"dontstarve/HUD/get_gold",
	"dontstarve/HUD/health_down", --SMASH CHARGE NOISE???
	"dontstarve/HUD/health_up", --SMASH CHARGE NOISE!!!
	"dontstarve/HUD/research_available",
	"dontstarve/HUD/research_unlock", --4-11 ANOTHER HITSOUND
	"dontstarve",
	"dontstarve",
	"dontstarve",
	"dontstarve",
	"dontstarve",
	
	-- /rain/thunder_close
	-- /rain/thunder_far
	
	
	
	"dontstarve/common/destroy_stone",    --MAYBE HEAVY HITSOUND BUT CRUMBLES REAL LOUD
	-- "dontstarve/creatures/worm/bite", 
	-- "dontstarve/wilson/boomerang_throw"
	
	"dontstarve/common/fishingpole_linebreak",
	-- "dontstarve/common/fixed_stonefurniture",
	-- "dontstarve/common/makeFriend",
	-- "dontstarve/common/maxlightAddFuel",
	-- "dontstarve/creatures/worm/bite", --BULL DOG GROWL/CAVE BITE
	"dontstarve/impacts/impact_fur_armour_dull", --LIGHT THWAPPING SOUND	 --MAYBE LIGHT THWAP HIT?
	"dontstarve/impacts/impact_mech_med_dull",	--LOWER METAL BONK SOUND		
	-- "dontstarve/impacts/impact_mech_med_sharp",	 --NICE METAL CLANK		
	-- "dontstarve/impacts/impact_shell_armour_dull",	 --METAL BONGO CLONK. POSSIBLE SHILED		
	"dontstarve/impacts/impact_wood_armour_dull",
	"dontstarve/impacts/impact_forcefield_armour_dull",				
	-- "dontstarve/maxwell/shadowmax_appear",	--MYSTERIOUS WUB-WOOSH SOUND		
	"dontstarve/wilson/attack_whoosh",
	"dontstarve/wilson/hit",   --NICE HEAVY PUNCH SOUND
	-- "dontstarve/wilson/use_axe_tree",
	"dontstarve/common/deathpoof",  --TINY WHOOF
	"dontstarve/common/destroy_stone", --HEAVY HIT MAYBE
	-- "dontstarve/common/break_iceblock"
	
	
	
	-- "dontstarve/common/maxlightOut",
 -- "dontstarve/common/maxwellportal_activate",
-- "dontstarve/common/maxwellportal_shutdown",
"dontstarve/common/object_dissappear",
-- "dontstarve/creatures/egg/egg_hatch",
-- "dontstarve/impacts/impact_metal_armour_dull",	 --HIGHER METAL BONK SOUND		
-- "dontstarve/impacts/impact_metal_armour_sharp",	 --HIGH METAL CLINK
-- "dontstarve/maxwell/shadowmax_despawn",			--ANOTHER MYSTERIOUS WUB-WOOSH SOUND	
"dontstarve/wilson/hit_armour",	 --TREE CHOP			--LIGHT HIT SOUND?
"dontstarve/wilson/rock_break",  --ROCK BREAK			--MIX FOR HEAVY HIT SOUND?
-- "dontstarve/common/destroy_magic",  --PERFECT SHEILD BREAK NOISE
"dontstarve/common/fireBurstSmall",  --MAAAYBE FOR HEAVY SWING
-- "dontstarve/charlie/attack",  --DRAMATIC SLO MO SOUND EFFECT
"dontstarve/creatures/krampus/kick_whoosh",   --PERCEFT JAB WOOSH
"dontstarve/wilson/attack_whoosh",  --WEIRD WOOSH
-- "dontstarve/wilson/boomerang_return", --TWIRL
-- "dontstarve/wilson/equip_item_gold"  --BLING



"dontstarve/common/place_ground", --MAYBE FOR SHEILDS  --ACTUALLY THIS IS A GREAT SMALL HIT SOUND --PERFECT SMALL SLICE SOUND!!
 "dontstarve/common/place_structure_stone", --HOUSE
"dontstarve/common/place_structure_wood",  --TILE ROOF CLACK --MAAAYBE MID-MEDIUM ATTACK
-- "dontstarve/common/popcorn",
"dontstarve/impacts/impact_tree_lrg_dull", --WOODEN THUNK
"dontstarve/movement/bodyfall_dirt",				
"dontstarve/wilson/attack_firestaff",	 --DIFFERENT WOOSH	--BUT DECENT	
-- "dontstarve/wilson/fireball_explo", --ACTUAL FIRE
-- "dontstarve/wilson/hit_unbreakable",  --HIGH HEAVY CLANG
-- "dontstarve/wilson/torch_swing",   --/wilson/use_torch
-- "dontstarve/common/gem_shatter",
-- "dontstarve/common/destroy_smoke", --MAYBE FOR POTION
"dontstarve/creatures/rocklobster/attack_whoosh", --PERFECT HEAVY WOOSH
"dontstarve/creatures/krampus/bag_swing",  --PERFECT MEDIUM SWING
-- "dontstarve/wilson/hit_straw" --MAYBE BETTER CHARGE SOUND?


-- "dontstarve/common/powderkeg_explo", --HOOOO BOY THATS A BIG EXPLOSION
 "dontstarve/common/rebirth",		--DECENT HEAVY PUNCH SOUND?
"dontstarve/common/repair_stonefurniture",
"dontstarve/common/resurrectionstone_break", --LEGO CRASH  --DECENT HEAVY HIT SOUND
-- "dontstarve/tentacle/smalltentacle_attack",		--SWISH	 ---HEY USE THIS ONE MORE ITS A GOOD SWISH	
"dontstarve/wilson/attack_nightsword",  --MAGIC GRUNT SOUND				
-- "dontstarve/wilson/hit_metal", --SMALL TOY ZILAPHONE CLANK
"dontstarve/wilson/use_armour_break",  --BREAKING WOOD/MAYBE BONE
-- "dontstarve/common/destroy_pot",  --GLASS SHATTERING
"dontstarve/creatures/rocklobster/explode",  --MEH ROCK SMASH  --WOULD HONESTLY MAKE AN ALRIGHT HIT SOUND --MAYBE HEAVY BLOCK SOUND?
"dontstarve/creatures/rocklobster/attack_whoosh", --PERFECT HEAVY WOOSH
-- "dontstarve",

-- "dontstarve/common/resurrectionstone_activate",
 -- "dontstarve/common/trap_teeth_trigger", --CLANG
-- "dontstarve/common/use_book", 
-- "dontstarve/common/vegi_smash",

-- "dontstarve/common/meteor_spawn",  --JET ENGINE
 -- "dontstarve/common/meteor_impact",  --ODDLY FREIGHT TRAIN
-- "dontstarve/creatures/chester/boing", --BOING
-- "dontstarve/creatures/chester/chomp",

-- "dontstarve/creatures/deerclops/walk",
 "dontstarve/creatures/deerclops/swipe", --PAPER CUT  --LONG LASTING DELAYED-ISH SWIPE
"dontstarve/creatures/deerclops/bodyfall_dirt", --TREE FALLING  --ACTUALLY SOUNDS LIKE A GREAT HEAVY PUNCH
-- "dontstarve/creatures/egg/egg_hatch_crack"  --TEETH CLACK



-- "dontstarve/creatures/worm/bite",

-- "dontstarve/music/gramaphone_danger",
-- "dontstarve/music/gramaphone_creepyforest",
-- "dontstarve/music/gramaphone_dawn",
-- "dontstarve/music/gramaphone_drstyle",
-- "dontstarve/music/gramaphone_efs",
-- "dontstarve/music/gramaphone_end",
-- "dontstarve/music/music_danger",
-- "dontstarve/music/music_dusk_stinger",
-- "dontstarve/music/music_dusk_stinger crazy",
-- "dontstarve/music/music_epicfight",
-- "dontstarve/music/music_test_parm",
-- "dontstarve/sanity/shadowhand_creep",  --OH GOD ITS ON A LOOP
-- "dontstarve/sanity/shadowhand_retreat",
-- "dontstarve/sanity/shadowhand_snuff",
-- "dontstarve/sanity/shadowrock_up",
-- "dontstarve/sanity/shadowrock_down",
-- "dontstarve/common/rebirth_amulet_poof",  --SUDDEN MYSTICAL POOF
-- "dontstarve/common/clouds", 
-- "dontstarve/common/windsound",
-- "dontstarve/maxwell/breakchains",  --VERY CREEPY SCRAPING BEFORE A CRASH


-- "dontstarve/creatures/monkey/chest_pound", --THEYRE GOOD FOR LIGHT HIT SOUND BUT OH GOD THEYRE SO QUIET
-- "dontstarve/creatures/monkey_nightmare/chest_pound",

-- inst.SoundEmitter:PlaySound("dontstarve/common/clouds", "windsound")  --WHATS THIS???

-- "dontstarve/creatures/monkey"..inst.soundtype.."/chest_pound" --HEY WHATS THIS??? COULD BE USED AS A LOW HITSOUND?
-- inst.SoundEmitter:PlaySound("dontstarve/maxwell/breakchains") 


-- "dontstarve/creatures/monkey/attack",
-- "dontstarve/creatures/monkey/hurt",
"dontstarve/creatures/monkey/throw",	--ITS A SLIGHTLY QUIETER DEFAULT-WOOSH SOUND. PERFECT
-- "dontstarve/creatures/monkey/poopsplat",  
-- "dontstarve/creatures/monkey/barrel_rattle",
-- "dontstarve/creatures/monkey_nightmare/attack",
-- "dontstarve/creatures/monkey_nightmare/hurt",
-- "dontstarve/creatures/mosquito/mosquito_explo",
-- "dontstarve/creatures/pengull/slide_dirt",
-- "dontstarve/creatures/rocklobster/clawsnap",  --LITTLE TINK SOUND
-- "dontstarve/creatures/rocklobster/clawsnap_small",
-- "dontstarve/creatures/rocklobster/attack",
-- "dontstarve/creatures/rocklobster/hurt",
-- "dontstarve",

-- "dontstarve/creatures/rocklobster/explode",
-- "dontstarve/creatures/rocklobster/attack_whoosh", --EVEN DEEPER DEFAULT ATTACK WOOSH
-- "dontstarve/creatures/slurtle/shatter",
-- "dontstarve/creatures/slurtle/mound_explode",
-- "dontstarve/creatures/teenbird/attack",
-- "dontstarve/creatures/teenbird/peck",
"dontstarve/creatures/krampus/kick_impact",  --OOOOH! PERFECT MEDIUM HITSOUND!!!!
"dontstarve/creatures/krampus/bag_impact",	--ANOTHER GOOD HITSOUND???
"dontstarve/creatures/krampus/kick_whoosh",	--IS THIS THE SAME AS THE BAG WOOSH?
"dontstarve/tentacle/tentacle_sliced",		--WOA THIS SOUNDS LIKE SOME CRAZY SAMURAI SWORD
-- "dontstarve/wilson/blowdart_impact_fire",
-- "dontstarve/wilson/blowdart_impact_sleep",
-- "dontstarve/wilson/boomerang_catch",	--WAY TOO QUIET TO BE ANYTHING


-- "dontstarve/impacts/impact_mound_lrg_dull",
"dontstarve/common/balloon_pop",	--POSSIBLE HITSOUND?

-- "dontstarve/common/destroy_pot",
-- "dontstarve/common/book_spell", --WHY SO QUIET?
"dontstarve"
	
	
}

local fxtest = {

--HEYYYY WHO'S READY FOR ROUND TWO OF THIS LAVA ARENA UPDATE??
"lavaarena_portal_player_fx",
"lavaarena_player_revive_from_corpse_fx", --REALLY FANCY ANGELIC BLING NOISE
"ember_short_fx",
"lavaarena_creature_teleport_smoke_fx_1",
"lavaarena_creature_teleport_smoke_fx_2", --LIKE AFTERMATH OF A BIG EXPLOSION
"lavaarena_creature_teleport_smoke_fx_3",
"shadowstrike_slash_fx", --YO!!!! THEYRE LIKE OFICIAL VERSIONS OF THE SWOOSHES I HAVE. BUT MUCH THINNER
"shadowstrike_slash2_fx",
"pandorachest_reset",


"lightning_rod_fx",
"frogsplash",
"waterballoon_splash",
"spat_splash_fx_full",
"small_puff",
"sand_puff",
"sand_puff_large_front",
"sand_puff_large_back", --PUFFS LOOK GOOD, BUT ARE A LITTLE HIGH UP
"shadow_puff_large_back",
"mining_fx", --ROCKY VERSION OF THE DIG FX
"pine_needles_chop",
"statue_transition",
"shadow_despawn",
"mole_move_fx", --MAYBE A PAUSED VERSION COULD BE USED AS LEDGES??
"emote_fx", --TADAA!!
"spawn_fx_small",
"icespike_fx_1", --TIME TO PUT THIS ON WICKERS ICE ROD
"icespike_fx_4",
"shock_fx",
"groundpound_fx", --JUST A REALLY BIG MINEFX
"firesplash_fx", --OH MY! FANTASTIC
"tauntfire_fx",
"attackfire_fx", --AWESOME HOTROD SLIDING FLAMES, BUT COME OUT QUTE LATE
"vomitfire_fx",
"lucy_ground_transform_fx", --VERY SUDDEN EXPLOSION OF GOOFY LOOKING YELLOW FIRE
-- "lucy_transform_fx", --??? CRASHES WHEN USED
"sinkhole_warn_fx_1",
"cavein_debris",
"sleepbomb_burst" --ANOTHER GOOFY POOF

}

local count = 1 --3-22 LOOK TEACHER IM USING WHAT I LEARNED IN VISUAL BASIC CLASS TODAY 
local count2 = 1

if chargefkey and not GLOBAL.IsPaused() then
	local TheInput = GLOBAL.TheInput
	GLOBAL.TheInput:AddKeyDownHandler(chargefkey, function()
		local player = GLOBAL.ThePlayer
		
		if not player then return end
			
			
			--THIS IS FOR SOUND TESTING
			player.SoundEmitter:PlaySound(soundtest[count]) --THATS ALL I NEEDED?
			count = count + 1  --PRESS "T" TO ADVANCE TO THE NEXT SOUND
			print("------- SOUND TABLE POSITION:", count)
			
			--   !!!!!!!PRESS "T" TO ADVANCE TO THE NEXT SOUND!!!!!!!  
			
			
			
			--HERE'S A VERSION THAT TESTS VISUAL FX INSTEAD
			--[[
			local fxtoplay = (fxtest[count])    
			local fx = GLOBAL.SpawnPrefab(fxtoplay)
			-- local pos = inst:GetPosition()
			-- fx.Transform:SetRotation(inst.Transform:GetRotation())
			-- fx.Transform:SetPosition( pos.x, pos.y - .2, pos.z ) 
			fx.Transform:SetPosition(0,0,0 ) 
			-- inst.sg.statemem.book_fx = fx
			]]
		
	end)
end

if throwfkey and not GLOBAL.IsPaused() then
	local TheInput = GLOBAL.TheInput
	GLOBAL.TheInput:AddKeyDownHandler(throwfkey, function()
		local player = GLOBAL.ThePlayer
		
		-- count = count + 1
		player.SoundEmitter:PlaySound(soundtest[count])
	end)
end








local function DoWesScript1()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	-- local x, y, z = anchor.Transform:GetWorldPosition()
	
	
	local p1 = GLOBAL.SpawnPrefab("smashtemplate") --("wx78")  --("wilson") --("spider") --("player2pref") --"spiderfighter"
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	--DO WE ACTUALLY WANT TO REGISTER THEM? EH SURE WHY NOT
	-- anchor.components.gamerules:SpawnPlayer(p1, x, y, z, true) --TRUE TO SPECIFY CUSTOM SPAWN
	
	
	local p2 = GLOBAL.SpawnPrefab("newwoodie")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	-- anchor.components.gamerules:SpawnPlayer(p2, x, y, z, true) --TRUE TO SPECIFY CUSTOM SPAWN
	
	
	
	
	
	-- maxclone:AddTag("noplayeranchor")
	p1.components.percent:DoDamage(-60) --SET INITIAL DAMAGE
	
	
	--DONT REMEMBER WHY, BUT THE SPAWN SETUP STUFF HAPPENS A FEW SECONDS AFTER THEY SPAWN
	
	--GIVE THE STARTUP A SEC
	-- p1:DoTaskInTime((1*FRAMES), function(p1) 
		-- p2.Transform:SetPosition( x-4.2, y, z ) --4
		-- p1.Transform:SetPosition( x+4.5, y, z )
		-- p1.sg:GoToState("idle")

		-- p1.components.percent:DoDamage(-25)
	-- end)
	
	
	local function CreatePropBalloon(inst, x, y, swap)
		inst.components.hitbox:SetDamage(5)
		inst.components.hitbox:SetAngle(55)
		inst.components.hitbox:SetBaseKnockback(50)
		inst.components.hitbox:SetGrowth(62)
		inst.components.hitbox:SetSize(0.6)
		inst.components.hitbox:SetLingerFrames(400)
		
		inst.components.hitbox:SetProjectileAnimation("balloon", "balloon", "idle") --NO CUSTOM ANIMATIONS FOR THESE! I TOOK ALL THE EXISTING ANIMATIONS RIGHT FROM THE GAME
		inst.components.hitbox:SetProjectileSpeed(0, 1)
		inst.components.hitbox:SetProjectileDuration(360)
		inst.components.hitbox:SetHitFX("empty", "dontstarve/common/balloon_pop")
		
		local balloon = GLOBAL.SpawnPrefab("basicprojectile")
		
		balloon:RemoveTag("deleteonhit")
		balloon:RemoveTag("force_direction") --SO THE BALLON DOESNT ALWAYS HIT ENEMIES FORWARDS
		-- balloon:RemoveEventCallback("clank", function() end) --IDK IF THIS IS THE RIGHT WAY TO REMOVE A LISTENER
		balloon.Transform:SetScale(0.8, 0.8, 0.8)
		balloon.components.projectilestats.yhitboxoffset = 1.3
		
		balloon:ListenForEvent("overpowered", function()
			balloon.AnimState:PlayAnimation("pop")
			balloon.AnimState:SetTime(4*FRAMES)
			balloon.AnimState:Resume()
			balloon.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
			-- balloon.sg:GoToState("explode")
			balloon.Transform:SetScale(1, 1, 1)

			inst:DoTaskInTime(6*FRAMES, function(inst) --6-30-17 DONT WE NEED THIS CUZ EXPLODE DOESNT REMOVE IT AUTOMATICALLY?
				balloon:Remove()
			end)
		
		end)
		
		
		balloon.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", swap) --"balloon_1"
		balloon.AnimState:SetMultColour(1,0,0,1)
		-- balloon:DoTaskInTime(0.5, function(balloonref) 
			balloon.AnimState:PlayAnimation("idle", true)
		-- end)
		inst.components.hitbox:SpawnProjectile(x, y, 0, balloon)
	end
	
	
	
	
	anchor:DoTaskInTime(((0 + 60)*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p1.Transform:SetPosition(x-2.5, y+0, z)
		p2.Transform:SetPosition(x+7, y+0, z)
		
		-- p1:PushEvent("displaynamedelta", {myself=self.owner})
		p1:PushEvent("alterdisplayname", {name="wes"})
		p2:PushEvent("alterdisplayname", {name="woodie"})
		
		--SPECIAL SLOW PAN CAMERA ACROSS THE FIELD
		local rail = GLOBAL.SpawnPrefab("basicprojectile") --LETS MAKE A MOVING RAIL FOR THE CAMERA TO ATTACH TO
		rail.Transform:SetPosition(x-16, y+0.5, z-2) --12
		rail.components.hitbox:FinishMove() --DDONT ACTUALY HIT ANYTHING PLS
		-- rail.components.locomotor:Motor(1.9, 0, 90) --(xvel, yvel, duration)
		rail.components.projectilestats.xprojectilespeed = 1.9
		rail.components.projectilestats.yprojectilespeed = 0.5
		rail.components.projectilestats:SetProjectileDuration(150)
		rail.Physics:SetFriction(0)
		
		-- p2.sg:GoToState("ragdoll")
		-- p2.sg:AddStateTag("intangible")
		
		-- GLOBAL.TheCamera:CutsceneMode(true) --THIS JUST LOCKS THE CAM IN PLACE
		GLOBAL.TheCamera:SetTarget(rail) --ATTACH THE CAMERA TO THE RAIL
		
		
		-- p1.components.locomotor:TurnAround()
		-- p1.sg:GoToState("nspecial")
		
		--CREATE SOME PRE-EXISTING BALLOONS
		CreatePropBalloon(p1, 4.3, 0,  "balloon_1")
		CreatePropBalloon(p1, 2.1, -0.3,  "balloon_2")
		CreatePropBalloon(p1, -2.1, 0.3,  "balloon_4")
		CreatePropBalloon(p1, 3.5, 0.1,  "balloon_3")
		CreatePropBalloon(p1, 5.1, -0.5,  "balloon_4")
		CreatePropBalloon(p1, -4.2, -0.3,  "balloon_2")
		CreatePropBalloon(p1, -7.5, 0.2,  "balloon_3")
	end)
	
	
	local t1 = 90
	
	anchor:DoTaskInTime(((t1 + 53)*FRAMES), function() 
		p1.components.locomotor:TurnAround()
		-- p1.AnimState:PlayAnimation("nspecial")
		-- p1.AnimState:SetTime(15*FRAMES)
		p1.sg:GoToState("nspecial")
	end)
	
	anchor:DoTaskInTime(((t1 + 85)*FRAMES), function() 
		p1.components.locomotor:TurnAround()
		p1.sg:GoToState("nspecial")
	end)
	
	
	anchor:DoTaskInTime(((t1 + 82)*FRAMES), function() 
		p2.components.locomotor:TurnAround()
		p2:PushEvent("throwspecial")
	end)
	
end


local function DoWesScript2()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	-- local x, y, z = anchor.Transform:GetWorldPosition()
	
	
	local p1 = GLOBAL.SpawnPrefab("smashtemplate") --("wx78")  --("wilson") --("spider") --("player2pref") --"spiderfighter"
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	--DO WE ACTUALLY WANT TO REGISTER THEM? EH SURE WHY NOT
	-- anchor.components.gamerules:SpawnPlayer(p1, x, y, z, true) --TRUE TO SPECIFY CUSTOM SPAWN
	
	
	local p2 = GLOBAL.SpawnPrefab("newwoodie")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	-- anchor.components.gamerules:SpawnPlayer(p2, x, y, z, true) --TRUE TO SPECIFY CUSTOM SPAWN
	
	-- p1.components.percent:DoDamage(60) --SET INITIAL DAMAGE
	
	
	
	
	
	anchor:DoTaskInTime((60*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p1.Transform:SetPosition(x-10, y+0, z)
		p2.Transform:SetPosition(x+3, y+0, z)
		
		p2.components.percent:DoDamage(-40)
		
		-- p1.components.locomotor:TurnAround()
		-- p1.sg:GoToState("nspecial")
		
		
		-- p1:PushEvent("backward_key")
		-- p1.components.locomotor:TurnAround()
		p1.sg:GoToState("dash")
		p1:AddTag("holdleft")
		-- p2:AddTag("holdright")
		
	end)
	
	anchor:DoTaskInTime((61*FRAMES), function() 
		p2.components.locomotor:TurnAround()
		p2:PushEvent("throwspecial")
	end)
	
	anchor:DoTaskInTime((76*FRAMES), function() 
		-- p1.components.locomotor:TurnAround()
		p1.sg:GoToState("dspecial")
		p1:PushEvent("throwspecial", {key = "down"})
		-- p1.components.keydetector.holding = true --GUESS I NEVER MADE ONE OF THESE FOR SPECIAL BUTTON?
		p1:AddTag("spc_key_dwn") --DOESNT WORK ANYWAYS? HUH
		--OH WELL, ILL JUST HARDCODE IT FOR NOW AND FIX IT LATER --WHAT COULD POSSIBLY GO WRONG
	end)
	
	anchor:DoTaskInTime((91*FRAMES), function() 
		p1.sg:GoToState("reflect_end")
	end)
	
	
	local t1 = 95
	
	anchor:DoTaskInTime(((t1 + 5)*FRAMES), function() 
		p1.sg:GoToState("dash")
	end)
	
	anchor:DoTaskInTime(((t1 + 25)*FRAMES), function() 
		p1:PushEvent("jump")
		-- p1.components.keydetector.holdingup_full = true
		p1.components.stats.jumpspec = "full"
	end)
	
	anchor:DoTaskInTime(((t1 + 38)*FRAMES), function() 
		-- p2.sg:GoToState("dash")
		p2:AddTag("trytech_window")
		p2:AddTag("trytech")
	end)
	
	anchor:DoTaskInTime(((t1 + 46)*FRAMES), function() 
		p1:PushEvent("throwattack")
	end)
	
	anchor:DoTaskInTime(((t1 + 59)*FRAMES), function() 
		p1:PushEvent("throwattack", {key = "down"})
		p1.components.stats:SetKeyBuffer("throwattack", "down")
	end)
end


--FANCY FINISHER
local function DoWesScript3()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	
	local p1 = GLOBAL.SpawnPrefab("smashtemplate")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	
	
	local p2 = GLOBAL.SpawnPrefab("newwilson")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	
	-- p1.components.percent:DoDamage(60) --SET INITIAL DAMAGE
	
	local t1 = 6
	
	anchor:DoTaskInTime((t1+32*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p1.Transform:SetPosition(x+1.3, y+0, z) --10
		p2.Transform:SetPosition(x+11, y+0, z)
		
		p2.components.percent:DoDamage(-50)
		
		-- p1.components.locomotor:TurnAround()
		-- p2:AddTag("holdright")
		
		--ACTUALLY WHAT IF WE...
		p2.Transform:SetPosition(x+15.5, y+2, z)
		p2:AddTag("holdright")
		p2.sg:GoToState("dspecial_wilson")
	end)
	
	anchor:DoTaskInTime((t1+34*FRAMES), function() 
		p2.sg:GoToState("dspecial_wilson")
	end)
	
	
	
	anchor:DoTaskInTime((t1+50*FRAMES), function() 
		p2:RemoveTag("holdright")
	end)
	
	anchor:DoTaskInTime((t1+33*FRAMES), function() 
		p1.sg:GoToState("dash")
		p1:AddTag("holdleft")
	end)
	
	anchor:DoTaskInTime((t1+53*FRAMES), function() 
		p1:PushEvent("jump")
	end)
	
	
	
	anchor:DoTaskInTime((t1+62*FRAMES), function() 
		p1:PushEvent("throwattack", {key = "up"})
		p1:AddTag("holdleft")
	end)
	
	anchor:DoTaskInTime((t1+75*FRAMES), function() 
		-- p1:PushEvent("dash") --OK THEN
		p1.sg:GoToState("dash")
	end)
	
	anchor:DoTaskInTime((t1+76*FRAMES), function() 
		p1:AddTag("holdleft")
		-- p1.components.stats:SetKeyBuffer("jump")
		p1.components.stats.jumpspec = "full"
		p1:PushEvent("jump")
	end)
	
	anchor:DoTaskInTime((t1+82*FRAMES), function() 
		p1.sg:GoToState("dspecial")
		p1:PushEvent("throwspecial", {key = "down"})
		p1:AddTag("spc_key_dwn") --DOESNT WORK ANYWAYS? HUH
	end)
	
	anchor:DoTaskInTime((t1+85*FRAMES), function() 
		p1:PushEvent("jump")
		p1.components.stats:SetKeyBuffer("jump", "ITSNIL") -- :/ --, "down")
	end)
	
	anchor:DoTaskInTime((t1+91*FRAMES), function() 
		p1:PushEvent("throwattack", {key = "down"})
	end)
	
	-- anchor:DoTaskInTime((t1+120*FRAMES), function() 
		-- -- p1:PushEvent("throwattack", {key = "down"})
		-- -- p1:RemoveTag("holdleft")
	-- end)
	
	
	anchor:DoTaskInTime((t1+119*FRAMES), function() 
		p1:RemoveTag("holdleft")
		-- p1:AddTag("holdright")
		p1:PushEvent("throwspecial", {key = "forward"})
	end)
end


local function DoWesScript4() --BTROW INTO BALLOON
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	-- local p1 = GLOBAL.SpawnPrefab("smashtemplate")
	local p1 = GLOBAL.SpawnPrefab("newwes")
	p1:AddTag("customspawn")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	
	
	local p2 = GLOBAL.SpawnPrefab("newwilson")
	p2:AddTag("customspawn")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	
	
	local function CreatePropBalloon(inst, x, y, swap)
		inst.components.hitbox:SetDamage(5)
		inst.components.hitbox:SetAngle(55)
		inst.components.hitbox:SetBaseKnockback(50)
		inst.components.hitbox:SetGrowth(62)
		inst.components.hitbox:SetSize(0.6)
		inst.components.hitbox:SetLingerFrames(400)
		
		inst.components.hitbox:SetProjectileAnimation("balloon", "balloon", "idle") --NO CUSTOM ANIMATIONS FOR THESE! I TOOK ALL THE EXISTING ANIMATIONS RIGHT FROM THE GAME
		inst.components.hitbox:SetProjectileSpeed(0, 2)
		inst.components.hitbox:SetProjectileDuration(360)
		inst.components.hitbox:SetHitFX("empty", "dontstarve/common/balloon_pop")
		
		local balloon = GLOBAL.SpawnPrefab("basicprojectile")
		
		inst.components.hitbox:SetOnHit(function() 
			balloon.AnimState:PlayAnimation("pop", true)
			balloon.AnimState:SetTime(4*FRAMES)
			balloon.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
			-- balloon.sg:GoToState("explode")
			balloon.Transform:SetScale(1, 1, 1)

			inst:DoTaskInTime(8*FRAMES, function(inst) --6-30-17 DONT WE NEED THIS CUZ EXPLODE DOESNT REMOVE IT AUTOMATICALLY?
				balloon:Remove()
			end)
		end)
		
		balloon:RemoveTag("deleteonhit")
		balloon:RemoveTag("force_direction") --SO THE BALLON DOESNT ALWAYS HIT ENEMIES FORWARDS
		-- balloon:RemoveEventCallback("clank", function() end) --IDK IF THIS IS THE RIGHT WAY TO REMOVE A LISTENER
		balloon.Transform:SetScale(0.8, 0.8, 0.8)
		balloon.components.projectilestats.yhitboxoffset = 1.3
		
		balloon.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", swap) --"balloon_1"
		balloon.AnimState:SetMultColour(1,0,0,1)
		-- balloon:DoTaskInTime(0.5, function(balloonref) 
			balloon.AnimState:PlayAnimation("idle", true)
		-- end)
		inst.components.hitbox:SpawnProjectile(x, y, 0, balloon)
	end
	
	
	anchor:DoTaskInTime((60*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		-- p1.Transform:SetPosition(x+7, y+0, z)
		-- p2.Transform:SetPosition(x+6, y+0, z)
		
		anchor.components.gamerules:SpawnPlayer(p1, x+7, y, z, true)
		anchor.components.gamerules:SpawnPlayer(p2, x+6, y, z, true)
		
		
		p1.components.percent:DoDamage(-45)
		p2.components.percent:DoDamage(-40)
		
		--CREATE SOME PRE-EXISTING BALLOONS
		CreatePropBalloon(p1, 5.6, 2.6,  "balloon_1")
		
		p1.components.locomotor:TurnAround()
		-- p2:AddTag("holdright")
		
	end)
	
	
	local t1 = 30
	anchor:DoTaskInTime(((t1+62)*FRAMES), function() 
		p1:PushEvent("throwattack", {key = "block"})
		-- p1:AddTag("holdleft")
	end)
	
	anchor:DoTaskInTime(((t1+68)*FRAMES), function() 
		-- p1:PushEvent("dash") --OK THEN
		p1:PushEvent("backward_key")
		p1.components.stats:SetKeyBuffer("backward_key")
	end)
	
	anchor:DoTaskInTime(((t1+90)*FRAMES), function() 
		-- p1:AddTag("holdleft")
		-- p1.components.stats:SetKeyBuffer("jump")
		-- p1.components.locomotor:TurnAround()
		p1.components.stats.jumpspec = "full"
		p1:PushEvent("jump")
	end)
	
	anchor:DoTaskInTime(((t1+94)*FRAMES), function() 
		p1:PushEvent("jump")
		-- p1.components.stats:SetKeyBuffer("jump", "ITSNIL")
	end)
	
	
	
	
	anchor:DoTaskInTime(((t1+103)*FRAMES), function() 
		p1:PushEvent("throwattack", {key = "backward"})
	end)
end


--JUMP ICE INTO FSPECIAL KICK
local function DoWesScript5()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local p1 = GLOBAL.SpawnPrefab("smashtemplate")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	local p2 = GLOBAL.SpawnPrefab("newwicker")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	
	-- p1.components.percent:DoDamage(60) --SET INITIAL DAMAGE
	
	anchor:DoTaskInTime((40*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p1.Transform:SetPosition(x+10.5, y+0, z)
		p2.Transform:SetPosition(x-1, y+0, z)
		
		p2.components.percent:DoDamage(-15)
		
		p2.components.locomotor:TurnAround()
		-- p2:AddTag("holdright")
		
	end)
	
	anchor:DoTaskInTime((1+64*FRAMES), function() 
		p1.components.locomotor:TurnAround()
		p1.sg:GoToState("dash")
		-- p1:PushEvent("dash")
		
		p2:PushEvent("throwspecial", {key = "forward"})
		-- p1:PushEvent("throwattack", {key = "up"})
		-- p1:AddTag("holdleft")
	end)
	
	anchor:DoTaskInTime((1+75*FRAMES), function() --78 WORKS TOO
		-- p1:PushEvent("dash") --OK THEN
		-- p1.sg:GoToState("dash")
		p1:PushEvent("throwspecial", {key = "backward"})
		p2:AddTag("holdleft")
	end)
	
	
	local t1 = 130
	
	anchor:DoTaskInTime(((t1 + 10)*FRAMES), function() 
		p1:PushEvent("throwattack", {key = "up"})
		p1.components.stats:SetKeyBuffer("throwattack", "up")
	end)
	
	anchor:DoTaskInTime(((t1 + 28)*FRAMES), function() 
		-- p1.sg:GoToState("dspecial")
		-- p1:PushEvent("throwattack", {key = "up"})
		-- p1.components.stats:SetKeyBuffer("throwattack", "up")
		
		-- p1:PushEvent("throwattack", {key = "forward"})
		-- p1.components.stats:SetKeyBuffer("throwattack", "forward")
		p1.components.stats.jumpspec = "full"
		p1:PushEvent("jump")
		p1:AddTag("holdright")
		-- p1:PushEvent("jump", {key = "forward"})
		-- p1.components.stats:SetKeyBuffer("jump", "forward")
	end)
	
	anchor:DoTaskInTime(((t1 + 30)*FRAMES), function() 
		p1:PushEvent("throwattack", {key = "forward"})
		p1.components.stats:SetKeyBuffer("throwattack", "forward")
	end)
	
	--[[
	anchor:DoTaskInTime((76*FRAMES), function() 
		p1:AddTag("holdleft")
		-- p1.components.stats:SetKeyBuffer("jump")
		p1.components.stats.jumpspec = "full"
		p1:PushEvent("jump")
	end)
	
	anchor:DoTaskInTime((82*FRAMES), function() 
		p1.sg:GoToState("dspecial")
		p1:PushEvent("throwspecial", {key = "down"})
		p1:AddTag("spc_key_dwn") --DOESNT WORK ANYWAYS? HUH
	end)
	
	anchor:DoTaskInTime((85*FRAMES), function() 
		p1:PushEvent("jump")
		p1.components.stats:SetKeyBuffer("jump", "ITSNIL") -- :/ --, "down")
	end)
	
	anchor:DoTaskInTime((91*FRAMES), function() 
		p1:PushEvent("throwattack", {key = "down"})
	end)
	
	-- anchor:DoTaskInTime((120*FRAMES), function() 
		-- -- p1:PushEvent("throwattack", {key = "down"})
		-- -- p1:RemoveTag("holdleft")
	-- end)
	
	
	anchor:DoTaskInTime((120*FRAMES), function() 
		-- p1:RemoveTag("holdleft")
		-- p1:AddTag("holdright")
		p1:PushEvent("throwspecial", {key = "forward"})
	end)
	]]
end


--WILSON WES SMACK BACK AND FOURTH
local function DoWesScript6()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")

	local p2 = GLOBAL.SpawnPrefab("newwilson")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	
	local p1 = GLOBAL.SpawnPrefab("smashtemplate")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	
	
	anchor:DoTaskInTime(((0 + 60)*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p1.Transform:SetPosition(x-7, y+0, z)
		p2.Transform:SetPosition(x-6, y+0, z)
		p2.components.locomotor:TurnAround()
		
		-- p1:PushEvent("displaynamedelta", {myself=self.owner})
		p1:PushEvent("alterdisplayname", {name="wes"})
		p2:PushEvent("alterdisplayname", {name="wilson"})
		
		p1.components.percent:DoDamage(-50) --SET INITIAL DAMAGE
		p2.components.percent:DoDamage(-50) --SET INITIAL DAMAGE
		
		local rail = GLOBAL.SpawnPrefab("basicprojectile") --SPECIAL CAMERA SPOT
		rail.Transform:SetPosition(x-6.5, y+0.5, z-2) --12
		rail.components.hitbox:FinishMove() --DDONT ACTUALY HIT ANYTHING PLS
		rail.components.projectilestats.xprojectilespeed = 0
		rail.components.projectilestats.yprojectilespeed = 0
		rail.components.projectilestats:SetProjectileDuration(150)
		rail.Physics:SetFriction(0)
		-- GLOBAL.TheCamera:CutsceneMode(true) --THIS JUST LOCKS THE CAM IN PLACE
		GLOBAL.TheCamera:SetTarget(rail) --ATTACH THE CAMERA TO THE RAIL
		--ACTUALLY, MAYBE NOT YET?
		
		
		-- p1.components.locomotor:TurnAround()
	end)
	
	
	local t1 = 60
	
	anchor:DoTaskInTime(((t1 + 10)*FRAMES), function() 
		p1:PushEvent("throwattack", {key = "block"})
	end)
	
	anchor:DoTaskInTime(((t1 + 16)*FRAMES), function() 
		p1:PushEvent("forward_key")
	end)
	
	anchor:DoTaskInTime(((t1 + 65)*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p2.Transform:SetPosition(x-5.5, y+0, z)
		
		--REPOS CAMERA
		p1.Transform:SetPosition(x-7.2, y+0, z)
		-- p2.Transform:SetPosition(x-6.2, y+0, z)
		local rail = GLOBAL.SpawnPrefab("basicprojectile") --SPECIAL CAMERA SPOT
		rail.Transform:SetPosition(x-6.8, y+0.5, z-2) --12
		GLOBAL.TheCamera:SetTarget(rail) 
	end)
	
	anchor:DoTaskInTime(((t1 + 68)*FRAMES), function() 
		p2:PushEvent("cstick_side", {key = "right"})
	end)
	
	
	
end


--DOWNSMASH MAXCLONES
local function DoWesScript7()
	
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	
	local p2 = GLOBAL.SpawnPrefab("newmaxwell")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	
	local p1 = GLOBAL.SpawnPrefab("smashtemplate")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	
	
	anchor:DoTaskInTime(((0 + 40)*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p1.Transform:SetPosition(x+4, y+0, z)
		p2.Transform:SetPosition(x+2.5, y+0, z)
		-- p2.components.locomotor:TurnAround()
		
		-- p1:PushEvent("displaynamedelta", {myself=self.owner})
		p1:PushEvent("alterdisplayname", {name="wes"})
		p2:PushEvent("alterdisplayname", {name="wilson"})
		
		p1.components.percent:DoDamage(-50) --SET INITIAL DAMAGE
		p2.components.percent:DoDamage(-50) --SET INITIAL DAMAGE
		
	end)
	
	
	local t1 = 40
	
	anchor:DoTaskInTime(((t1 + 10)*FRAMES), function() 
		p2:PushEvent("throwspecial", {key = "down"})
	end)
	
	-- anchor:DoTaskInTime(((t1 + 40)*FRAMES), function() 
		-- p1:PushEvent("throwattack", {key = "block"})
	-- end)
	
	-- anchor:DoTaskInTime(((t1 + 16)*FRAMES), function() 
		-- p1:PushEvent("forward_key")
	-- end)
	
	anchor:DoTaskInTime(((t1 + 95)*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p2.Transform:SetPosition(x+1, y+0, z)
		-- p2.components.locomotor:TurnAround()
		p2.sg:GoToState("stroll_forward") --WELL THATS CONVENIENT.
		
		local p3 = TheSim:FindFirstEntityWithTag("maxclone")
		p3.components.percent:DoDamage(-50)
		p3:PushEvent("cstick_side", {key = "right"})
	end)
	
	anchor:DoTaskInTime(((t1 + 101)*FRAMES), function() 
		p1:PushEvent("cstick_down")
	end)
	
	
	
end


--FOR THE THUMBNAIL
local function DoWesScript8() --BTROW INTO BALLOON
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local p1 = GLOBAL.SpawnPrefab("smashtemplate")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	
	
	local p2 = GLOBAL.SpawnPrefab("newwilson")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	
	
	local function CreatePropBalloon(inst, x, y, swap)
		inst.components.hitbox:SetDamage(0)
		inst.components.hitbox:SetAngle(55)
		inst.components.hitbox:SetBaseKnockback(0)
		inst.components.hitbox:SetGrowth(62)
		inst.components.hitbox:SetSize(0.6)
		inst.components.hitbox:SetLingerFrames(400)
		
		inst.components.hitbox:SetProjectileAnimation("balloon", "balloon", "idle") --NO CUSTOM ANIMATIONS FOR THESE! I TOOK ALL THE EXISTING ANIMATIONS RIGHT FROM THE GAME
		inst.components.hitbox:SetProjectileSpeed(0, 1)
		inst.components.hitbox:SetProjectileDuration(360)
		inst.components.hitbox:SetHitFX("empty", "dontstarve/common/balloon_pop")
		
		local balloon = GLOBAL.SpawnPrefab("basicprojectile")
		
		-- inst.components.hitbox:SetOnHit(function() 
			-- balloon.AnimState:PlayAnimation("pop", true)
			-- balloon.AnimState:SetTime(4*FRAMES)
			-- balloon.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
			-- -- balloon.sg:GoToState("explode")
			-- balloon.Transform:SetScale(1, 1, 1)

			-- inst:DoTaskInTime(8*FRAMES, function(inst) --6-30-17 DONT WE NEED THIS CUZ EXPLODE DOESNT REMOVE IT AUTOMATICALLY?
				-- balloon:Remove()
			-- end)
		-- end)
		
		balloon:RemoveTag("deleteonhit")
		balloon:RemoveTag("force_direction") --SO THE BALLON DOESNT ALWAYS HIT ENEMIES FORWARDS
		-- balloon:RemoveEventCallback("clank", function() end) --IDK IF THIS IS THE RIGHT WAY TO REMOVE A LISTENER
		balloon.Transform:SetScale(0.8, 0.8, 0.8)
		balloon.components.projectilestats.yhitboxoffset = 1.3
		
		balloon.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", swap) --"balloon_1"
		balloon.AnimState:SetMultColour(1,0,0,1)
		-- balloon:DoTaskInTime(0.5, function(balloonref) 
			balloon.AnimState:PlayAnimation("idle", true)
		-- end)
		inst.components.hitbox:SpawnProjectile(x, y, 0, balloon)
		--AND THEN CANCLE IT SO IT DOESNT ACTUALLY HIT ANYONE
		balloon.components.hitbox:FinishMove()
	end
	
	
	anchor:DoTaskInTime((40*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p1.Transform:SetPosition(x-5, y+0, z)
		p2.Transform:SetPosition(x-3.2, y+0, z)
		
		p1.components.percent:DoDamage(-45)
		p2.components.percent:DoDamage(-40)
		
		--CREATE SOME PRE-EXISTING BALLOONS
		CreatePropBalloon(p1, 3.6, 4.1,  "balloon_1")
		CreatePropBalloon(p1, -0.5, 3.1,  "balloon_2")
		CreatePropBalloon(p1, -0.1, 1.1,  "balloon_3")
		CreatePropBalloon(p1, 2.4, 1.7,  "balloon_4")
		
		p1.components.locomotor:TurnAround()
		p1.components.stats.fallingspeed = 0 --lol
		p1.components.stats.gravity = 0.9
		p1.components.stats.jumpheight = 18
		-- p2:AddTag("holdright")
		
		--LETS JUST ERASE THIS FOR A SEC
		local portal = TheSim:FindFirstEntityWithTag("portal")
		portal.AnimState:SetMultColour(0,0,0,0)
		
	end)
	
	
	local t1 = 40
	
	anchor:DoTaskInTime(((t1+10)*FRAMES), function() 
		-- p1.components.locomotor:TurnAround()
		p1.components.stats.jumpspec = "full"
		p1:PushEvent("jump")
		
		-- p2.components.stats.jumpspec = "full"
		-- p2:PushEvent("jump")
	end)
	
	anchor:DoTaskInTime(((t1+12)*FRAMES), function() 
		p2.components.stats.jumpspec = "full"
		p2:PushEvent("jump")
		p1:PushEvent("throwattack", {key = "forward"})
	end)
	
	-- anchor:DoTaskInTime(((t1+22)*FRAMES), function() 
		-- p1:PushEvent("throwattack", {key = "backward"})
	-- end)
	
	--HMM, WHAT ABOUT...
	anchor:DoTaskInTime(((t1+22)*FRAMES), function() 
		p1.components.locomotor:TurnAround()
		-- p1:PushEvent("throwattack", {key = "forward"})
	end)
	
	anchor:DoTaskInTime(((t1+38)*FRAMES), function() --32
		p2.AnimState:PlayAnimation("tumble_back", true)
		p2.AnimState:SetAddColour(0,0,0,0)
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p2.Transform:SetPosition(x-3.2, y+4, z)
	end)
	
end


local function DoHitstunTest()
	
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	
	local p2 = GLOBAL.SpawnPrefab("newwilson")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	
	local p1 = GLOBAL.SpawnPrefab("newwilson")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	
	local p3 = GLOBAL.SpawnPrefab("newwilson")
	p3:AddComponent("keydetector")
	p3:AddComponent("playercontroller_1")
	
	
	anchor:DoTaskInTime(((0 + 40)*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p1.Transform:SetPosition(x+4, y+0, z)
		p2.Transform:SetPosition(x+6.3, y+2.5, z)
		p3.Transform:SetPosition(x+8, y+0, z)
		-- p2.components.locomotor:TurnAround()
		p1:PushEvent("alterdisplayname", {name="wes"})
		p2:PushEvent("alterdisplayname", {name="wilson"})
		
		p1.components.percent:DoDamage(-50) --SET INITIAL DAMAGE
		p2.components.percent:DoDamage(-50) --SET INITIAL DAMAGE
		
	end)
	
	
	local t1 = 40
	
	anchor:DoTaskInTime(((t1 + 0)*FRAMES), function() 
		p1.sg:GoToState("nspecial_wilson")
		-- p1.sg:GoToState("nspecial_poof")
		-- p2.sg:GoToState("nair")
	end)
	
	anchor:DoTaskInTime(((t1 + 2)*FRAMES), function() 
		p1.sg:GoToState("nspecial_poof")
	end)
	
	anchor:DoTaskInTime(((t1 + 3)*FRAMES), function() 
		p3.components.locomotor:TurnAround()
		p3.sg:GoToState("jab1")
	end)
	
end



local function DoHitTest()
	
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local p2 = GLOBAL.SpawnPrefab("newwes")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	local p1 = GLOBAL.SpawnPrefab("newwilson")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	
	anchor:DoTaskInTime(((0 + 40)*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p1.Transform:SetPosition(x+4, y+0, z)
		p2.Transform:SetPosition(x+5, y+0, z)
		-- p3.Transform:SetPosition(x+8, y+0, z)
		p2.components.locomotor:TurnAround()
	end)
	local t1 = 40
	
	anchor:DoTaskInTime(((t1 + 3)*FRAMES), function() 
		p2.sg:GoToState("jab1")
	end)
	
end





--IMPORTING SOME OLD MAXWELL TRAILER STUFF

--10-28-16 TIME TO START MAXWELL'S TRAILER
local function DoGrabberTrailer()

	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local p1 = GLOBAL.SpawnPrefab("newwoodie")
	p1:AddTag("customspawn")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	local p2 = GLOBAL.SpawnPrefab("newmaxwell")
	p2:AddTag("customspawn")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	local p3 = nil
	
	anchor.components.gamerules:SpawnPlayer(p1, x+1, y, z, true)
	anchor.components.gamerules:SpawnPlayer(p2, x+1, y, z, true)
	
	-- p2.AnimState:SetBank("newwilson")
	-- p2.AnimState:SetBuild("newwilson")
	-- p2.Transform:SetScale(1,1,1)
	
	--GIVE THE STARTUP A SEC
	p1:DoTaskInTime((1*FRAMES), function(p1) 
		p1.Transform:SetPosition( x-1, y, z ) --4
		p2.Transform:SetPosition( x-7.2, y, z+0.1 ) --4
		p1.sg:GoToState("idle")
		-- p2.components.locomotor:TurnAround()

		p1.components.percent:DoDamage(-65)
	end)

	
	
	
	
	p1:DoTaskInTime((15*FRAMES), function(p1) 
		-- p1:PushEvent("jump")
		p2.components.stats:SetKeyBuffer("throwspecial", "forward")
	end)
	
	p1:DoTaskInTime((16*FRAMES), function(p1) 
		-- p1:AddTag("holdleft")
	end)
	
	p1:DoTaskInTime((23*FRAMES), function(p1) 
		-- p1:PushEvent("throwattack")
	end)
	
	p1:DoTaskInTime((45*FRAMES), function(p1) 
		-- p1:PushEvent("throwattack", {key = "down"})
		-- p1.components.stats:SetKeyBuffer("throwattack", "down") 
	end)
	
	p1:DoTaskInTime((55*FRAMES), function(p1) 
		-- p1:PushEvent("throwattack", {key = "up"})
		-- p1.components.stats:SetKeyBuffer("throwattack", "up") 
	end)
	
	
	
end




local function DoCrossSlash()
	
	
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local p1 = GLOBAL.SpawnPrefab("newwicker")
	p1:AddTag("customspawn")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	local p2 = GLOBAL.SpawnPrefab("newmaxwell")
	p2:AddTag("customspawn")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	local p3 = nil
	
	anchor.components.gamerules:SpawnPlayer(p1, x+1, y, z, true)
	anchor.components.gamerules:SpawnPlayer(p2, x+1, y, z, true)
	
	
	-- p1.AnimState:SetBank("newwilson")
	-- p1.AnimState:SetBuild("newwickerbottom")
	-- p1:SetStateGraph("SGnewwickerbottom")
	-- p2.Transform:SetScale(1,1,1)
	
	--GIVE THE STARTUP A SEC
	p1:DoTaskInTime((1*FRAMES), function(p1) 
		p2.Transform:SetPosition( x-0.2, y, z ) 
		p1.Transform:SetPosition( x+6, y, z )
		p1.sg:GoToState("idle")
		p1.components.locomotor:TurnAround()
		-- p2.components.stats:SetKeyBuffer("throwspecial", "down")
		p2:PushEvent("throwspecial", {key = "down"})

		p1.components.percent:DoDamage(-45)
	end)
	
	p1:DoTaskInTime((5*FRAMES), function(p1) 
		p2.Transform:SetPosition( x-3.2, y, z ) 
		p1.sg:GoToState("idle")

		p3 = TheSim:FindFirstEntityWithTag("maxclone")
		-- p3.Transform:SetPosition( x-3.2, y, z )
	end)

	
	
	
	
	p1:DoTaskInTime((40*FRAMES), function(p1) 
		p3.Transform:SetPosition( x-0.2, y, z )
	end)
	
	p1:DoTaskInTime((16*FRAMES), function(p1) 
		-- p1:AddTag("holdleft")
	end)
	
	p1:DoTaskInTime((23*FRAMES), function(p1) 
		-- p1:PushEvent("throwattack")
	end)
	
	p1:DoTaskInTime((45*FRAMES), function(p1) 
		-- p1:PushEvent("throwattack", {key = "down"})
		-- p1.components.stats:SetKeyBuffer("throwattack", "down") 
	end)
	
	
	
	p1:DoTaskInTime((70*FRAMES), function(p1) 
		-- p2.components.stats:SetKeyBuffer("throwattack") 
		-- p2.sg:GoToState("dash")
		
		p3.sg:GoToState("stroll_forward")
		-- p2.sg:GoToState("stroll_forward")
		-- p2.components.stats:SetKeyBuffer("throwspecial", "forward")
		p2:AddTag("holdspecial")		
		p2.sg:GoToState("fspecial")
	end)
	
	p1:DoTaskInTime((80*FRAMES), function(p1) 
		p1.sg:GoToState("nspecial") 
	end)
	
	p1:DoTaskInTime((89*FRAMES), function(p1) 
		p2:RemoveTag("holdspecial")
	end)
	p2:DoTaskInTime((95*FRAMES), function(p2) 
		p3.sg:GoToState("run_stop")
	end)
	
	-- p2:DoTaskInTime((110*FRAMES), function(p2) 
		-- p3.components.locomotor:TurnAround()
		-- p3.sg:GoToState("stroll_forward")
	-- end)
	
	-- p2:DoTaskInTime((125*FRAMES), function(p2) 
		-- p3:PushEvent("cstick_forward")
	-- end)
	
	p2:DoTaskInTime((105*FRAMES), function(p2) 
		p3.components.locomotor:TurnAround()
		p3.sg:GoToState("stroll_forward")
	end)
	
	-- p2:DoTaskInTime((108*FRAMES), function(p2) 
		-- p2.sg:GoToState("run_stop")
	-- end)
	
	p2:DoTaskInTime((110*FRAMES), function(p2)
		p3.sg:GoToState("idle")
		-- p3:PushEvent("cstick_forward")
		p3:PushEvent("cstick_side", {key = "right"})
		p3:AddTag("atk_key_dwn")
	end)
	
	p1:DoTaskInTime((130*FRAMES), function(p1) 
		p3:RemoveTag("atk_key_dwn")
	end)
	
end



local function DoDoubleFinisher(p1, p2)

	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local p1 = GLOBAL.SpawnPrefab("newmaxwell")
	p1:AddTag("customspawn")
	local p2 = GLOBAL.SpawnPrefab("newwoodie")
	p2:AddTag("customspawn")
	local p3 = nil
	-- p1.components.percent:DoDamage(60) --SET INITIAL DAMAGE
	
	-- p1.Transform:SetPosition(x+9.1, y+0, z)
	-- p2.Transform:SetPosition(x-1, y+0, z)
	anchor.components.gamerules:SpawnPlayer(p1, x+9.1, y, z, true)
	anchor.components.gamerules:SpawnPlayer(p2, x-1, y, z, true)
	

	--GIVE THE STARTUP A SEC
	p1:DoTaskInTime((1*FRAMES), function(p1) 
		-- p2.Transform:SetPosition( x-7.2, y, z ) --4
		p1.Transform:SetPosition( x-6.0, y, z )
		p1.sg:GoToState("idle")
		p2:PushEvent("throwspecial", {key = "down"})

		-- p1.components.percent:DoDamage(-51)
		p1.components.percent:DoDamage(-68) --FAIR VERSION
	end)
	
	p1:DoTaskInTime((5*FRAMES), function(p1) 
		p2.Transform:SetPosition( x-3.5, y, z ) --4
		p1.sg:GoToState("idle")

		p3 = TheSim:FindFirstEntityWithTag("maxclone")
		-- p3.Transform:SetPosition( x-3.2, y, z )
	end)

	
	
	
	
	p1:DoTaskInTime((10*FRAMES), function(p1) 
		p3.Transform:SetPosition( x-10.8, y, z )
		p3.components.locomotor:TurnAround()
	end)
	
	p1:DoTaskInTime((40*FRAMES), function(p1) 
		p2.SoundEmitter:KillAllSounds() 
	end)
	
	p1:DoTaskInTime((50*FRAMES), function(p1) 
		p2.components.locomotor:TurnAround()
		p2.sg:GoToState("duck")
		p3.sg:GoToState("duck")
	end)
	
	p1:DoTaskInTime((55*FRAMES), function(p1) 
		p2:PushEvent("throwattack", {key = "down"})
		-- p1.components.stats:SetKeyBuffer("throwattack", "down") 
		-- p2.components.locomotor:TurnAround()
		p2.sg:GoToState("downtilt")
		p3:PushEvent("throwattack", {key = "down"})
		p3.sg:GoToState("downtilt")
	end)
	


	--NEW FAIR VERSION
	p1:DoTaskInTime((5*FRAMES), function(p1)	
		p1:DoTaskInTime((74*FRAMES), function(p1) 
			-- p2.components.locomotor:TurnAround()
			-- p3.components.locomotor:TurnAround()
		end)
		
		p1:DoTaskInTime((75*FRAMES), function(p1) 
			-- p2.components.stats.jumpspec = "full"
			p2:AddTag("holdright")
			p2:PushEvent("jump")
			
			-- p2.components.stats:SetKeyBuffer("throwattack", "backward")
			-- p3.components.stats.jumpspec = "full"
			p3:AddTag("holdright")
			p3:PushEvent("jump")
			
			-- p3.components.stats:SetKeyBuffer("throwattack", "backward")
		end)
		p1:DoTaskInTime((77*FRAMES), function(p1) 
			p2.components.stats:SetKeyBuffer("throwattack", "forward")
			p3.components.stats:SetKeyBuffer("throwattack", "forward")
		end)
		
		-----
		p1:DoTaskInTime((100*FRAMES), function(p1)  --98 --106
			p2.components.stats.jumpspec = "full"
			p3.components.stats:SetKeyBuffer("jump") 
			p2.components.stats:SetKeyBuffer("jump") 
		end)
		
		p1:DoTaskInTime((111*FRAMES), function(p1) 
			-- p3:RemoveTag("holdright")
		end)
		
		p1:DoTaskInTime((116*FRAMES), function(p1) --112
			p1:AddTag("holdleft")
			p1.components.stats:SetKeyBuffer("jump") 
		end)
		
		
		p2:DoTaskInTime((121*FRAMES), function(p2)  --117
			-- p3.components.locomotor:TurnAround()
			-- p3.sg:GoToState("stroll_forward")
			p3.components.stats:SetKeyBuffer("throwattack", "down")
			p2.components.stats:SetKeyBuffer("throwattack", "down")
		end)
	end)
end











--RELEASE TRAILER STUFF!



--SPAWN SPIDER STUFF (COPIED FROM HOARD.LUA)


--PASTE THIS INTO HORDE MODE WHEN IN USE
-- function Hordes:SetupTier1()
	-- local wavedata = {
		-- {name="spiderfighter_medium", posx=-4.1, perc=60, mode="hp"},
		-- {name="spiderfightereggsack", posx=-5, perc=50, mode="hp"},
	-- }
	-- table.insert(self.waveslots, wavedata)
-- end


local function SpawnSpider(pref, hp, x2, y2, z)
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local Pawn = GLOBAL.SpawnPrefab(pref) 
	Pawn:AddTag("dummynpc")
	Pawn:AddTag("customspawn")
	Pawn:AddTag("noplayeranchor")
	Pawn.components.stats.team = "spiderclan"
	Pawn.components.percent.hpmode = true
	Pawn.components.percent.maxhp = hp
	Pawn:AddTag("nohud")
	local zoffset = 0
	if Pawn:HasTag("spiderden") then
		zoffset = -0.4 --10-17-20 ADDING ZOFFSET TO DENS SO THEY DONT OVERLAP AND HIDE THE SPIDERS
	end
	anchor.components.gamerules:SpawnPlayer(Pawn, x+(x2), y+y2, z+zoffset, true)
	return Pawn
end





local function DoHorde1()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local p1 = GLOBAL.SpawnPrefab("newwilson")
	p1:AddTag("customspawn")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	local p2 = GLOBAL.SpawnPrefab("newwoodie")
	p2:AddTag("customspawn")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	
	-- p1.components.percent:DoDamage(60) --SET INITIAL DAMAGE
	
	-- p1.Transform:SetPosition(x+9.1, y+0, z)
	-- p2.Transform:SetPosition(x-1, y+0, z)
	anchor.components.gamerules:SpawnPlayer(p1, x+8.5, y, z, true)
	anchor.components.gamerules:SpawnPlayer(p2, x-1, y, z, true)
	
	
	-- anchor.components.hordes:PrepareHordeMode(1) --PREPARES A FAKE HORDE MODE LEVEL
	
	
	anchor:DoTaskInTime((20*FRAMES), function() 
		local Pawn = SpawnSpider("spiderfighter_medium", 45, 6.1, 0)
		local Pawn2 = SpawnSpider("spiderfighter_easy", 45, 1.1, 0)
		local pegg = SpawnSpider("spiderfightereggsack", 45, 7.0, 0)
	end)
	
	
	
	--local ps = TheSim:FindFirstEntityWithTag("spider")
	--local pegg = TheSim:FindFirstEntityWithTag("spiderden")
	
	anchor:DoTaskInTime((25*FRAMES), function() 
		-- p1.Transform:SetPosition(x+9.1, y+5, z)
	end)
	
	anchor:DoTaskInTime((28*FRAMES), function() 
		-- p1:PushEvent("throwattack", {key = "forward"})
	end)
	
	
	anchor:DoTaskInTime((30*FRAMES), function() 
		p2.components.locomotor:TurnAround()
		p2:PushEvent("throwspecial", {key = "forward"})
		
		
	end)
	
	anchor:DoTaskInTime((40*FRAMES), function() 
		p1.components.locomotor:TurnAround()
		-- p1:PushEvent("throwspecial", {key = "down"})
		p1.components.stats:SetKeyBuffer("throwattack", "forward")
	
		p2.Transform:SetPosition(x-5, y+0, z)
	end)
	
	
	anchor:DoTaskInTime((70*FRAMES), function() 
		p1:PushEvent("throwspecial", {key = "down"})
	end)
	
	
	
	
	anchor:DoTaskInTime((100*FRAMES), function() 
		-- p1.components.stats:SetKeyBuffer("throwspecial", "down")
		-- p1.components.stats:SetKeyBuffer("throwattack")
		p1.components.stats:SetKeyBuffer("throwspecial")
		p1:AddTag("spc_key_dwn")
	end)
	
	-- anchor:DoTaskInTime((102*FRAMES), function() 
		-- p1:RemoveTag("spc_key_dwn")
	-- end)
	
	anchor:DoTaskInTime((77*FRAMES), function() 
		p2.components.stats:SetKeyBuffer("cstick_up")
	end)
	
	anchor:DoTaskInTime((88*FRAMES), function() 
		p1.components.stats:SetKeyBuffer("throwattack", "forward")
		
	end)
	
end





local function DoHorde2()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local p1 = GLOBAL.SpawnPrefab("newwicker")
	p1:AddTag("customspawn")
	
	anchor.components.gamerules:SpawnPlayer(p1, x+2, y, z, true)
	
	local Pawn = SpawnSpider("spiderfighter_medium", 45, -6.1, 0)
	local pegg = SpawnSpider("spiderfightereggsack", 45, -7.0, 0)
	local Pawn2 = SpawnSpider("spiderfighter_easy", 25, -10.7, 0)
	
	anchor:DoTaskInTime((34*FRAMES), function() 
		p1.components.locomotor:TurnAround()
		p1:PushEvent("throwspecial")
	end)
	
	
	anchor:DoTaskInTime((40*FRAMES), function() 
		
		Pawn.sg:GoToState("taunt")
		Pawn2.sg:GoToState("wakeup")
	end)
	
	
	anchor:DoTaskInTime((70*FRAMES), function() 
		-- Pawn2.sg:GoToState("wakeup")
	end)
end




local function DoHorde3()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local p1 = GLOBAL.SpawnPrefab("newwicker")
	p1:AddTag("customspawn")
	p1.AnimState:SetBuild("nothing")
	
	anchor.components.gamerules:SpawnPlayer(p1, x+2, y, z, true)
	
	-- local Pawn = SpawnSpider("spiderfighter_medium", 45, -6.1, 0)
	Pawn = nil
	local pegg = SpawnSpider("spiderfightereggsack_tier2", 45, -5.0, 0)
	local Pawn2 = SpawnSpider("spiderfighter_easy", 25, -10.7, 0)
	Pawn2:AddTag("heavy")
	local Pawn3 = SpawnSpider("spiderfighter_easy", 25, -10.7, 0)
	Pawn3:AddTag("heavy")
	Pawn3.sg:GoToState("ragdoll")
	
	anchor:DoTaskInTime((20*FRAMES), function() 
		p1.AnimState:SetBuild("nothing")
		Pawn3.AnimState:SetBuild("nothing")
	end)
	
	anchor:DoTaskInTime((50*FRAMES), function() 
		
		
		Pawn = SpawnSpider("spiderfighter_medium", 45, -3.5, 0)
		Pawn:AddTag("heavy")
		
		Pawn.sg:GoToState("taunt")
		Pawn2.sg:GoToState("wakeup")
	end)
end





--11-10-21 I'VE ACCIDENTALLY CREATED A CONSISTANTLY REPEATABLE RARE BUG INVOLVING... IDK, WEIRD DISJOINTED HIT STUFF
--LOOK INTO THIS LATER
--[[
local function DoDisjointBug()
	
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local p1 = GLOBAL.SpawnPrefab("newmaxwell")
	p1:AddTag("customspawn")
	local p2 = GLOBAL.SpawnPrefab("newwicker")
	p2:AddTag("customspawn")
	p2.components.percent:DoDamage(-50)
	p1.Transform:SetPosition(x+1, y+0, z)
	p2.Transform:SetPosition(x-9, y+0, z)

	anchor.components.gamerules:SpawnPlayer(p1, x+1, y, z, true)
	anchor.components.gamerules:SpawnPlayer(p2, x-9, y, z, true)
	anchor:DoTaskInTime((5*FRAMES), function() 
		p1.components.locomotor:TurnAround()
		p1:PushEvent("throwspecial", {key = "down"})
		p2:PushEvent("throwspecial", {key = "down"})
	end)
	
	anchor:DoTaskInTime((70*FRAMES), function() 
		p1:AddTag("holdright")
		p1.components.keydetector.holdingright = true
	end)
	anchor:DoTaskInTime((90*FRAMES), function() 
		p2.components.stats:SetKeyBuffer("throwattack", "forward")
	end)
	anchor:DoTaskInTime((95*FRAMES), function() 
		p1.components.keydetector.holdingright = false
		p1.sg:GoToState("idle")
		p1:PushEvent("cstick_side", {key = "right"})
	end)
end
]]





--WICKER+MAXWELL EXCHANGE
local function DoWickerwell()
	
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local p1 = GLOBAL.SpawnPrefab("newmaxwell")
	p1:AddTag("customspawn")
	-- p1:AddComponent("keydetector") --I'M PRETTY SURE WE DON'T NEED THESE IF WE SPECIFY CUSTOMSPAWN...
	-- p1:AddComponent("playercontroller_1")
	local p2 = GLOBAL.SpawnPrefab("newwicker")
	p2:AddTag("customspawn")
	-- p2:AddComponent("keydetector")
	-- p2:AddComponent("playercontroller_1")
	-- p1.components.percent:DoDamage(60) --SET INITIAL DAMAGE
	p2.components.percent:DoDamage(-50)
	
	p1.Transform:SetPosition(x+1, y+0, z)
	p2.Transform:SetPosition(x-9, y+0, z)
	
	anchor.components.gamerules:SpawnPlayer(p1, x+1, y, z, true)
	anchor.components.gamerules:SpawnPlayer(p2, x-9, y, z, true)
	
	anchor:DoTaskInTime((5*FRAMES), function() 
		p1.components.locomotor:TurnAround()
		p1:PushEvent("throwspecial", {key = "down"})
		-- p2:PushEvent("throwspecial", {key = "down"})
	end)
	
	anchor:DoTaskInTime((60*FRAMES), function() 
		p2:PushEvent("throwspecial", {key = "down"})
	end)
	
	
	anchor:DoTaskInTime((70*FRAMES), function() 
		-- p1.Transform:SetPosition(x+2.5, y+0, z)
		-- p1.sg:GoToState("dash")
		p1:AddTag("holdright")
		-- p1.components.keydetector:TurnAround()
		p1.components.keydetector.holdingright = true
	end)
	
	
	anchor:DoTaskInTime((92*FRAMES), function() 
		p2.components.stats:SetKeyBuffer("throwattack", "forward")
	end)
	
	anchor:DoTaskInTime((95*FRAMES), function() 
		p1:PushEvent("throwattack", {key = "block"})
		
		p1.components.keydetector.holdingright = false
		-- p1.sg:GoToState("idle")
		-- p1:PushEvent("cstick_side", {key = "right"})
	end)
	
	anchor:DoTaskInTime((115*FRAMES), function() 
		p1.sg:GoToState("idle")
		p1:PushEvent("cstick_side", {key = "right"})
	end)
	
	anchor:DoTaskInTime((125*FRAMES), function() 
		p1.sg:AddStateTag("intangible")
		p1.sg:AddStateTag("ignoreglow")
	end)
end




local function DoWesJabs()
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local p1 = GLOBAL.SpawnPrefab("newwes")
	p1:AddTag("customspawn")
	local p2 = GLOBAL.SpawnPrefab("newwes")
	p2:AddTag("customspawn")
	local p3 = GLOBAL.SpawnPrefab("newwes")
	p3:AddTag("customspawn")
	-- p1.components.percent:DoDamage(60) --SET INITIAL DAMAGE
	
	-- p1.Transform:SetPosition(x+9.1, y+0, z)
	-- p2.Transform:SetPosition(x-1, y+0, z)
	anchor.components.gamerules:SpawnPlayer(p1, x-2.2, y, z, true)
	anchor.components.gamerules:SpawnPlayer(p2, x+2.2, y, z, true)
	-- anchor.components.gamerules:SpawnPlayer(p3, x+0, y, z, true)
	p3.Transform:SetPosition(x+0, y+0, z)
	
	p2.components.locomotor:TurnAround()
	p1.sg:GoToState("jabinf")
	p2.sg:GoToState("jabinf")
	
	
	anchor:DoPeriodicTask((5*FRAMES), function() 
		p1.sg:AddStateTag("listen")
		p2.sg:AddStateTag("listen")
	end)
	
end



local function DoWoodieSheildbreak()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local p1 = GLOBAL.SpawnPrefab("newwilson")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	p1:AddTag("wantstoblock")
	local p2 = GLOBAL.SpawnPrefab("newwoodie")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	
	-- p1.components.percent:DoDamage(60) --SET INITIAL DAMAGE
	
	anchor:DoTaskInTime((40*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p1.Transform:SetPosition(x-1.7, y+0, z)
		p2.Transform:SetPosition(x+1.3, y+0, z)
		
		p1.components.percent:DoDamage(-40)
		p2.components.locomotor:TurnAround()
	end)
	
	anchor:DoTaskInTime((75*FRAMES), function() 
		p1:RemoveTag("wantstoblock")
	end)
	
	
	anchor:DoTaskInTime((82*FRAMES), function() 
		p2:PushEvent("cstick_side", {key = "right"})
		
		p1:AddTag("wantstoblock")
	end)
	
end



local function DoWoodieWesPunish()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local p1 = GLOBAL.SpawnPrefab("newwes")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	local p2 = GLOBAL.SpawnPrefab("newwoodie")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	
	-- p1.components.percent:DoDamage(60) --SET INITIAL DAMAGE
	
	anchor:DoTaskInTime((40*FRAMES), function() 
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		local x, y, z = anchor.Transform:GetWorldPosition()
		p1.Transform:SetPosition(x-7.7, y+0, z)
		p2.Transform:SetPosition(x+1.3, y+0, z)
		
		p1.components.percent:DoDamage(-40)
		p2.components.locomotor:TurnAround()
	end)
	
	
	anchor:DoTaskInTime((1+75*FRAMES), function() 
		p1:PushEvent("throwspecial", {key = "backward"})
		p1:AddTag("holdright")
		p2:AddTag("holdleft")
		
		p2:AddTag("wantstoblock")
	end)
	
	
	local t1 = 128
	
	anchor:DoTaskInTime(((t1 + 10)*FRAMES), function() 
		-- p1:PushEvent("throwattack", {key = "up"})
		-- p1.components.stats:SetKeyBuffer("throwattack", "up")
		
		p2.components.stats.jumpspec = "full"
		p2:PushEvent("jump")
		-- p2:AddTag("holdright")
		p2:RemoveTag("wantstoblock")
		
	end)
	
	anchor:DoTaskInTime(((t1 + 15)*FRAMES), function() 
		p2:PushEvent("throwattack", {key = "up"})
	end)
	
	anchor:DoTaskInTime(((t1 + 17)*FRAMES), function() 
		p2:RemoveTag("holdleft")
	end)
	
	anchor:DoTaskInTime(((t1 + 31)*FRAMES), function() 
		p2:PushEvent("throwspecial", {key = "up"})
		p2.components.stats:SetKeyBuffer("throwspecial", "up")
	end)
	
	
end


local function DoWesReflect()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	
	local p1 = GLOBAL.SpawnPrefab("newwes")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	p1:AddTag("customspawn")
	local p2 = GLOBAL.SpawnPrefab("newwoodie")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	p2:AddTag("customspawn")
	local p3 = GLOBAL.SpawnPrefab("newwicker")
	p3:AddComponent("keydetector")
	p3:AddComponent("playercontroller_1")
	p3:AddTag("customspawn")
	
	-- p1.components.percent:DoDamage(60) --SET INITIAL DAMAGE
	
	
	anchor:DoTaskInTime((10*FRAMES), function() 
		
		p1.Transform:SetPosition(x+2.5, y+6, z)
		-- p2.Transform:SetPosition(x-2, y+0, z)
		-- p3.Transform:SetPosition(x+3, y+0, z)
		anchor.components.gamerules:SpawnPlayer(p2, x-3, y, z, true)
		anchor.components.gamerules:SpawnPlayer(p3, x+5, y, z, true)
		
		
		-- p1.components.stats:SetKeyBuffer("throwattack", "up")
		p1.components.launchgravity:Launch(0, 20)
		
		p2.components.percent:DoDamage(-35)
		p2.components.locomotor:TurnAround()
	end)
	
	
	anchor:DoTaskInTime((26*FRAMES), function() 
		p1.Transform:SetPosition(x+2.5, y+6, z)
		
		p1.components.stats:SetKeyBuffer("throwattack", "up")
		p1.components.launchgravity:Launch(-4, 0)
	end)
	
	
	
	
	anchor:DoTaskInTime((32*FRAMES), function() 
		p2.components.locomotor:TurnAround()
		p2:PushEvent("throwspecial")
		--p2.components.locomotor:TurnAround()
		
	end)
	
	anchor:DoTaskInTime((36*FRAMES), function() 
		p3:PushEvent("throwspecial", {key = "forward"})
	end)
	
	anchor:DoTaskInTime((45*FRAMES), function() 
		p1.components.stats:SetKeyBuffer("throwspecial", "down")
		p1:PushEvent("throwspecial", {key = "down"})
		p1:AddTag("spc_key_dwn")
	end)
	
end



local function DoAllTogetherNow()
	
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local p1 = GLOBAL.SpawnPrefab("newwicker")
	p1:AddTag("customspawn")
	-- p1:AddComponent("keydetector")
	-- p1:AddComponent("playercontroller_1")
	local p2 = GLOBAL.SpawnPrefab("newmaxwell")
	p2:AddTag("customspawn")
	-- p2:AddComponent("keydetector")
	-- p2:AddComponent("playercontroller_1")
	
	anchor.components.gamerules:SpawnPlayer(p1, x+1, y, z, true)
	anchor.components.gamerules:SpawnPlayer(p2, x+1, y, z, true)
	
	
	--GIVE THE STARTUP A SEC
	p1:DoTaskInTime((5*FRAMES), function(p1) 
		p2.Transform:SetPosition( x+2.2, y, z ) 
		p1.Transform:SetPosition( x+6.2, y, z )
		p1.sg:GoToState("idle")
		p1.components.locomotor:TurnAround()
		-- p2.components.stats:SetKeyBuffer("throwspecial", "down")
		-- p2:PushEvent("throwspecial", {key = "down"})

		p1.components.percent:DoDamage(-45)
	end)

	p1:DoTaskInTime((20*FRAMES), function(p1) 
		-- p2.components.stats:SetKeyBuffer("throwattack") 
		-- p2:AddTag("holdspecial")		
		p2.sg:GoToState("fspecial")
	end)
	
	p1:DoTaskInTime((30*FRAMES), function(p1) 
		p1.sg:GoToState("nspecial") 
	end)
	
	p2:DoTaskInTime((65*FRAMES), function(p2)
		-- print("ONE")
		p2.components.stats:SetKeyBuffer("throwattack") 
	end)
	
	p2:DoTaskInTime((72*FRAMES), function(p2)
		-- print("TWO")
		p2:PushEvent("attack_key")
		-- p2.components.stats:SetKeyBuffer("throwattack") 
	end)
	
	p2:DoTaskInTime((80*FRAMES), function(p2)
		-- print("THREE")
		-- p2.components.stats:SetKeyBuffer("throwattack") 
		p2:PushEvent("attack_key")
	end)
	
	
	
	
	
	
	--
	local p3 = GLOBAL.SpawnPrefab("newwilson")
	p3:AddTag("customspawn")
	-- p3:AddComponent("keydetector") --I'M PRETTY SURE WE DON'T NEED THESE IF WE SPECIFY CUSTOMSPAWN...
	-- p3:AddComponent("playercontroller_1")
	local p4 = GLOBAL.SpawnPrefab("newwoodie")
	p4:AddTag("customspawn")
	-- p4:AddComponent("keydetector")
	-- p4:AddComponent("playercontroller_1")
	
	anchor.components.gamerules:SpawnPlayer(p3, x-2, y, z, true)
	anchor.components.gamerules:SpawnPlayer(p4, x-6, y, z, true)
	p3.components.locomotor:TurnAround()
	
	
	anchor:DoTaskInTime((20*FRAMES), function() 
		-- p2.components.stats:SetKeyBuffer("throwattack") 
		-- p2:AddTag("holdspecial")		
		p3.components.stats.jumpspec = "full"
		p3:PushEvent("jump")
		p3:AddTag("holdleft")
	end)
	
	anchor:DoTaskInTime((22*FRAMES), function() 	
		p4.sg:GoToState("fspecial")
	end)
	
	anchor:DoTaskInTime((24*FRAMES), function() 
		p3.sg:GoToState("dspecial")
	end)
	
	anchor:DoTaskInTime((28*FRAMES), function() 
		p3:RemoveTag("holdleft")
	end)
	
	anchor:DoTaskInTime((41*FRAMES), function() 
		-- print("STEP 2")
		-- p3.components.stats:SetKeyBuffer("throwspecial", "down")
		p3.components.stats:SetKeyBuffer("throwattack", "forward")
	end)
	
	anchor:DoTaskInTime((66*FRAMES), function() 
		-- print("STEP 3")
		-- p3.components.stats:SetKeyBuffer("throwspecial", "down")
		p3.components.stats:SetKeyBuffer("throwattack", "down")
	end)
	
	anchor:DoTaskInTime((75*FRAMES), function() 
		-- print("STEP 4")
		p3.components.stats:SetKeyBuffer("throwspecial", "up")
	end)
	
	anchor:DoTaskInTime((90*FRAMES), function() 
		-- print("STEP 5")
		p3.components.stats:SetKeyBuffer("throwattack")
	end)
	
	
end



local function DoQueenSlam()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local p1 = GLOBAL.SpawnPrefab("newwilson")
	p1:AddTag("customspawn")
	local p2 = GLOBAL.SpawnPrefab("newwoodie")
	p2:AddTag("customspawn")
	
	
	-- p1.Transform:SetPosition(x+9.1, y+0, z)
	-- p2.Transform:SetPosition(x-1, y+0, z)
	anchor.components.gamerules:SpawnPlayer(p1, x-3, y+5, z, true)
	p1.components.percent:DoDamage(-60) --SET INITIAL DAMAGE
	p1.sg:GoToState("fair")
	p1.components.stats:SetKeyBuffer("throwattack", "forward")
	anchor.components.gamerules:SpawnPlayer(p2, x-1.5, y, z, true)
	p2.components.locomotor:TurnAround()
	p2:AddTag("wantstoblock")
	
	
	
	local Pawn = GLOBAL.SpawnPrefab("spiderfighter_queen") 
	Pawn:AddTag("dummynpc")
	Pawn:AddTag("customspawn")
	Pawn:AddTag("noplayeranchor")
	Pawn.components.stats.team = "spiderclan"
	Pawn.components.percent.hpmode = true
	Pawn.components.percent.maxhp = 45
	Pawn:AddTag("nohud")
	
	-- anchor.components.gamerules:SpawnPlayer(Pawn, x-(10.1), y+15, z, true)
	Pawn.Transform:SetPosition(x-8.6, y+10, z)
	Pawn.sg:GoToState("trailer_jump")
	
	
	
	--local ps = TheSim:FindFirstEntityWithTag("spider")
	--local pegg = TheSim:FindFirstEntityWithTag("spiderden")
	
	anchor:DoTaskInTime((5*FRAMES), function() 
		
		p1.sg:GoToState("fair")
		p1.components.stats:SetKeyBuffer("throwattack", "forward")
		p1.components.launchgravity:Launch(0, -10)
	end)
	
	
	anchor:DoTaskInTime((14*FRAMES), function() 
		p2:RemoveTag("wantstoblock")
		-- p1:RemoveTag("player")
		
	end)
	
	anchor:DoTaskInTime((18*FRAMES), function() 
		anchor.components.gamerules:RemoveFromPlayerTable(p1)
		local sx, sy, sz = Pawn.Transform:GetWorldPosition()
		anchor.components.gamerules:SpawnPlayer(Pawn, sx, sy, sz, true)
	end)
	
end





local function DoCamTest()
	
	--STEP 1: FIND THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	local p1 = GLOBAL.SpawnPrefab("newwilson")
	p1:AddTag("customspawn")
	p1:AddComponent("keydetector")
	p1:AddComponent("playercontroller_1")
	local p2 = GLOBAL.SpawnPrefab("newwoodie")
	p2:AddTag("customspawn")
	p2:AddComponent("keydetector")
	p2:AddComponent("playercontroller_1")
	

	-- anchor.components.gamerules:SpawnPlayer(p1, x+16, y+20, z, true)
	-- anchor.components.gamerules:SpawnPlayer(p2, x+16, y-12, z, true)
	anchor.components.gamerules:SpawnPlayer(p1, x+25, y+0, z, true)
	anchor.components.gamerules:SpawnPlayer(p2, x-25, y-0, z, true)
	
	
	-- anchor.components.hordes:PrepareHordeMode(1) --PREPARES A FAKE HORDE MODE LEVEL
	
	
	-- anchor:DoTaskInTime((20*FRAMES), function() 
		-- local Pawn = SpawnSpider("spiderfighter_medium", 45, 6.1, 0)
		-- local Pawn2 = SpawnSpider("spiderfighter_easy", 45, 1.1, 0)
		-- local pegg = SpawnSpider("spiderfightereggsack", 45, 7.0, 0)
	-- end)
	
	
	
end









--========================================================================
--11-4-21 ENABLE THIS WHEN RECORDING TRAILERS!
GLOBAL.TRAILERMODE = false 
-- GLOBAL.TRAILERMODE = true 
-- spawnkey = GLOBAL.KEY_G  --TURN OFF WHEN NOT IN USE

--5-4-20 LETS LIKE... MAKE TRAILER SCRIPTS A LITTLE MORE NORMAL.
--RUN THE SCRIPTS TO SPAWN TRAILER ASSETS
if spawnkey then
	local TheInput = GLOBAL.TheInput
	GLOBAL.TheInput:AddKeyDownHandler(spawnkey, function()
		
		
		--OR, JUST CHANGE THE SKIN ON THE TRAINING DUMMY.
		-- local DUMMYSWAP = true
		local DUMMYSWAP = false
		
		if DUMMYSWAP then
		local dummy = GLOBAL.TheSim:FindFirstEntityWithTag("dummynpc")
		local skinreplace = "newwoodie"
		dummy.AnimState:SetBank(skinreplace)
		dummy.AnimState:SetBuild(skinreplace)
		dummy:SetStateGraph("SG"..skinreplace) 
			return end
		
		
		--REMOVE ANY EXISTING EXTRA PLAYERS FROM THE BOARD FIRST 
		local anchor = GLOBAL.TheSim:FindFirstEntityWithTag("anchor")
		-- anchor.components.gamerules:KOPlayer(inst, "silent")
		
		
		
		for i, v in ipairs(GLOBAL.AllPlayers) do
			if v ~= GLOBAL.ThePlayer then --EXCEPT THE MAIN PLAYER. THAT'LL KINDA CRASH THE GAME
				GLOBAL.TheWorld:PushEvent("ms_playerdespawnanddelete", v) 
				
				--9-4-17 REMOVE ALL PLAYERS FROM ALL TABLES.
				anchor.components.gamerules:RemoveFromPlayerTable(v) --2-7-17 FIXES THE TEAM-GAME-SET I GUESS
				anchor.components.gamerules:RemoveFromGame(v) --DO WE NEED THIS ONE
			end
			
			--THINGS TO DO TO PLAYER
			-- if v == GLOBAL.ThePlayer then
				-- v:RemoveTag("lockcontrols")
				-- local x, y, z = v.Transform:GetWorldPosition()
				-- anchor.components.gamerules:SpawnPlayer(v, x, y, z, true)
			-- end
		end
		anchor.components.gamerules:ClearBoard()
		
		
		
		
		-- DoWesScript1()
		-- DoWesScript2()
		-- DoWesScript3()
		-- DoWesScript4()
		-- DoWesScript5()
		-- DoWesScript6()
		-- DoWesScript7()
		-- DoWesScript8()
		
		-- DoWickerwell()
		-- DoHorde1()
		-- DoHorde2()
		-- DoHorde3()
		-- DoQueenSlam() --Done
		-- DoWesJabs()
		-- @ DoWoodieSheildbreak()
		DoAllTogetherNow()
		-- DoCamTest()
		
		-- @ DoWoodieWesPunish()
		-- DoWesReflect()
		
		
		-- DoGrabberTrailer()
		--@ DoCrossSlash()
		--@ DoWesScript4()
		
		
		--SCRIPTED ACTION SEQUENCE FOR THE TRAILER
		--DoWilsonWeaveCombo(p1, creature) 
		-- DoSheildBreakerCombo(p1, creature)
		--DoCherobeCombo(p1, creature)
		--DoRunningStart(p1, creature)
		-- DoSlipperStarter(p1, creature)
		-- DoTentKiller(p1, creature)
		-- DoGrabberTrailer(p1, creature)
		-- DoCrossSlash(p1, creature)
		-- DoDoubleFinisher(p1, creature)
		-- DoFireStopper(p1, creature)
		--player:DoTaskInTime(1, function() DoSheildBreakerCombo(p1, creature) end)
		
		
		--player.HUD.controls.clock:Hide() --JUST KIDDING WE USE THIS NOW
		-- GLOBAL.ThePlayer.HUD.controls.crafttabs:Hide() --HOW COME I CANT SEEM TO MAKE THIS WORK OUTSIDE THIS THING?
		-- GLOBAL.ThePlayer.HUD.controls.containerroot_side:Hide()
		GLOBAL.ThePlayer.HUD.controls.inv:Hide() --11-8-16 AAAAH HAAAA!!! FOUND YA YOU LITTLE CRITTER
		--WHY CANT I SEEM TO GET THIS TO WORK OUTSIDE OF MODMAIN??
	end)
end









------------------------DST CODE SNIPPETS

-- inst:DoTaskInTime( 1, function()
	-- GLOBAL.c_save()
	-- inst:DoTaskInTime( 5, function()
		-- GLOBAL.c_reset(true)
	-- end)                
-- end)



		--FROM SIMUTIL. USE TO ERODE DEAD THINGS I THINK
-- function ErodeAway(inst, erode_time)
    -- local time_to_erode = erode_time or 1
    -- local tick_time = TheSim:GetTickTime()

    -- if inst.DynamicShadow ~= nil then
        -- inst.DynamicShadow:Enable(false)
    -- end

    -- inst:StartThread(function()
        -- local ticks = 0
        -- while ticks * tick_time < time_to_erode do
            -- local erode_amount = ticks * tick_time / time_to_erode
            -- inst.AnimState:SetErosionParams(erode_amount, 0.1, 1.0)
            -- ticks = ticks + 1
            -- Yield()
        -- end
        -- inst:Remove()
    -- end)
-- end



-- Death FX
        -- SpawnPrefab("die_fx").Transform:SetPosition(x, y, z)
		
		
--SHAKEALLCAMERAS

--CHECK OUT TARGETINDICATOR WIDGET FOR STUFF ABOUT AUTOMATICALLY GETTING ATLAS AND BUILDS

-- if inst.AnimState:AnimDone() then





-- local function FastForwardFX(inst, pct)
    -- if inst._task ~= nil then
        -- inst._task:Cancel()
    -- end
    -- local len = inst.AnimState:GetCurrentAnimationLength()
    -- pct = math.clamp(pct, 0, 1)
    -- inst.AnimState:SetTime(len * pct)
    -- inst._task = inst:DoTaskInTime(len * (1 - pct) + 2 * FRAMES, inst.Remove)
-- end

--WOA. JUST TAKE A LOOK AT POLLEN.LUA IN GENERAL. AMAZING


-------------------

-- UFP = axINP + bxOUT + cxENQ + dxMAS + exINT



	------GET METADADA TABLE LISTS------


--ANIMSTATE
--[[
[00:08:37]: MY BRAIN STRING??		
[00:08:37]: TASK INFO	table: 185DDD40	
[00:08:37]: start	15.53333414346	
[00:08:37]: SetLayer	function: 1EFDCAE0	
[00:08:37]: SetRayTestOnBB	function: 1EFDD110	
[00:08:37]: IsCurrentAnimation	function: 1EFDD6E0	
[00:08:37]: SetFinalOffset	function: 1EFDD770	
[00:08:37]: SetManualBB	function: 1EFDDB60	
[00:08:37]: SetHighlightColour	function: 1EFDD5C0	
[00:08:37]: SetOrientation	function: 1EFDDBC0	
[00:08:37]: GetSymbolPosition	function: 1EFDDAA0	
[00:08:37]: ClearSymbolExchanges	function: 1EFDE160	
[00:08:37]: Hide	function: 1EFDD2C0	
[00:08:37]: SetSortOrder	function: 1EFDDB30	
[00:08:37]: ClearOverrideSymbol	function: 1EFDD050	
[00:08:37]: BuildHasSymbol	function: 1EFDCAB0	
[00:08:37]: SetBloomEffectHandle	function: 1EFDDB00	
[00:08:37]: SetDepthWriteEnabled	function: 1EFDCBA0	
[00:08:37]: SetDepthTestEnabled	function: 1EFDD2F0	
[00:08:37]: SetSymbolExchange	function: 1EFDDE00	
[00:08:37]: AddOverrideBuild	function: 1EFDD200	
[00:08:37]: Show	function: 1EFDD230	
[00:08:37]: PlayAnimation	function: 1EFDCB70	
[00:08:37]: SetTime	function: 1EFDD3B0	
[00:08:37]: SetSortWorldOffset	function: 1EFDD7A0	
[00:08:37]: SetClientsideBuildOverride	function: 1EFDDEC0	
[00:08:37]: OverrideItemSkinSymbol	function: 1EFDD1D0	
[00:08:37]: Pause	function: 1EFDD440	
[00:08:37]: SetHaunted	function: 1EFDD950	
[00:08:37]: SetClientSideBuildOverrideFlag	function: 1EFDDDD0	
[00:08:37]: Resume	function: 1EFDD260	
[00:08:37]: FastForward	function: 1EFDDD70	
[00:08:37]: SetDeltaTimeMultiplier	function: 1EFDD590	
[00:08:37]: SetDepthBias	function: 1EFDDB90	
[00:08:37]: ClearAllOverrideSymbols	function: 1EFDD530	
[00:08:37]: SetErosionParams	function: 1EFDD9B0	
[00:08:37]: GetCurrentAnimationTime	function: 1EFDD980	
[00:08:37]: ShowSymbol	function: 1EFDD0E0	
[00:08:37]: GetCurrentAnimationLength	function: 1EFDD710	
[00:08:37]: GetMultColour	function: 1EFDD890	
[00:08:37]: OverrideSymbol	function: 1EFDD4A0	
[00:08:37]: SetPercent	function: 1EFDD320	
[00:08:37]: OverrideMultColour	function: 1EFDD650	
[00:08:37]: SetAddColour	function: 1EFDD560	
[00:08:37]: ClearBloomEffectHandle	function: 1EFDD8F0	
[00:08:37]: SetLightOverride	function: 1EFDD8C0	
[00:08:37]: SetScale	function: 1EFDCB10	
[00:08:37]: SetBank	function: 1EFDCA50	
[00:08:37]: SetMultiSymbolExchange	function: 1EFDDDA0	
[00:08:37]: OverrideShade	function: 1EFDDA10	
[00:08:37]: AssignItemSkins	function: 1EFDD170	
[00:08:37]: GetCurrentFacing	function: 1EFDDC80	
[00:08:37]: SetBuild	function: 1EFDCA20	
[00:08:37]: ClearOverrideBuild	function: 1EFDD9E0	
[00:08:37]: PushAnimation	function: 1EFDD4D0	
[00:08:37]: GetAddColour	function: 1EFDDAD0	
[00:08:37]: SetSkin	function: 1EFDCC30	
[00:08:37]: OverrideSkinSymbol	function: 1EFDD020	
[00:08:37]: SetMultColour	function: 1EFDD380	
[00:08:37]: AnimDone	function: 1EFDD410	
[00:08:37]: HideSymbol	function: 1EFDD0B0
]]





--THEWORLD.GROUND
--[[
[01:58:39]: SetUndergroundRenderLayer	function: 326ED890	
[01:58:39]: SetOverlayLerp	function: 326ED740	
[01:58:39]: GetTileCenterPoint	function: 326EDD40	
[01:58:39]: AddRenderLayer	function: 326ED7A0	
[01:58:39]: RegisterGroundTargetBlocker	function: 60948B38	
[01:58:39]: GetIslandAtPoint	function: 326EDEF0	
[01:58:39]: Replace	function: 326ED710	
[01:58:39]: GetSize	function: 326ED9E0	
[01:58:39]: CanDeployWallAtPoint	function: 60948CD8	
[01:58:39]: GetRandomPointsForSite	function: 326EDF50	
[01:58:39]: CanDeployPlantAtPoint	function: 60948998	
[01:58:39]: SetPhysicsWallDistance	function: 326EDD70	
[01:58:39]: VisitTile	function: 326ED920	
[01:58:39]: SetOverlayTexture	function: 326ED650	
[01:58:39]: SetImpassableType	function: 326ED4A0	
[01:58:39]: CanDeployRecipeAtPoint	function: 60948A18	
[01:58:39]: CanPlaceTurfAtPoint	function: 609489F8	
[01:58:39]: SetFromString	function: 326ED620	
[01:58:39]: TileVisited	function: 326ED530	
[01:58:39]: Finalize	function: 326ED9B0	
[01:58:39]: IsPassableAtPoint	function: 609489B8	
[01:58:39]: CanDeployAtPoint	function: 60948938	
[01:58:39]: CanTerraformAtPoint	function: 60948AD8	
[01:58:39]: GetNumWalkableTiles	function: 326EDDD0	
[01:58:39]: SetNavSize	function: 326EDB00	
[01:58:39]: IsDeployPointClear	function: 63CD4380	
[01:58:39]: GetNumVisitedTiles	function: 326EDFE0	
[01:58:39]: IsGroundTargetBlocked	function: 63CD4308	
[01:58:39]: SetOverlayColor2	function: 326EDD10	
[01:58:39]: CanPlantAtPoint	function: 60948AF8	
[01:58:39]: SetOverlayColor0	function: 326ED5C0	
[01:58:39]: IsAboveGroundAtPoint	function: 60948C98	
[01:58:39]: RegisterTerraformExtraSpacing	function: 60948C78	
[01:58:39]: Fill	function: 326ED6E0	
[01:58:39]: GetTileCoordsAtPoint	function: 326ED6B0	
[01:58:39]: RegisterDeployExtraSpacing	function: 60948A98	
[01:58:39]: GetEntitiesOnTileAtPoint	function: 326EDB90	
[01:58:39]: GetTileXYAtPoint	function: 326EDA70	
[01:58:39]: GetTile	function: 326ED8F0	
[01:58:39]: SetNavFromString	function: 326EDDA0	
[01:58:39]: GetTileAtPoint	function: 326ED830	
[01:58:39]: GetStringEncode	function: 326ED470	
[01:58:39]: SetTile	function: 326ED950	
[01:58:39]: GetNavStringEncode	function: 326EDBC0	
[01:58:39]: SetOverlayColor1	function: 326EDBF0	
[01:58:39]: ResetVisited	function: 326ED860	
[01:58:39]: SetSize	function: 326ED7D0	
[01:58:39]: RebuildLayer	function: 326ED560	
[01:58:39]: IsPointNearHole	function: 60948B58	
[01:58:39]: CanPlacePrefabFilteredAtPoint	function: 609489D8










--- OBJECT.ENTITY

[00:02:31]: SetIsPredictingMovement	function: 0B947898	
[00:02:31]: AddRoadManager	function: 30FE4538	
[00:02:31]: MoveToFront	function: 0B947D48	
[00:02:31]: AddImage	function: 30FE3A58	
[00:02:31]: AddFollower	function: 30FE3C18	
[00:02:31]: AddAnimState	function: 30FE3418	
[00:02:31]: GetParent	function: 0B947A48	
[00:02:31]: AddShardClient	function: 30FE36B8	
[00:02:31]: Show	function: 0B947CE8	
[00:02:31]: SetParent	function: 0B947358	
[00:02:31]: AddEnvelopeManager	function: 30FE3DF8	
[00:02:31]: SetClickable	function: 0B947D18	
[00:02:31]: AddMapGenSim	function: 30FE3398	
[00:02:31]: GetDebugString	function: 0B947B08	
[00:02:31]: FlattenMovementPrediction	function: 0B947C88	
[00:02:31]: AddLabel	function: 30FE39B8	
[00:02:31]: AddPhysics	function: 30FE3658	
[00:02:31]: Retire	function: 0B947748	
[00:02:31]: SetPrefabName	function: 0B947538	
[00:02:31]: WorldToLocalSpace	function: 0B9476B8	
[00:02:31]: CanPredictMovement	function: 0B947B98	
[00:02:31]: IsVisible	function: 0B947C28	
[00:02:31]: SetCanSleep	function: 0B9479E8	
[00:02:31]: AddLight	function: 30FE3478	
[00:02:31]: LocalToWorldSpaceIncParent	function: 0B947718	
[00:02:31]: GetPrefabName	function: 0B947418	
[00:02:31]: AddTextEditWidget	function: 30FE4378	
[00:02:31]: AddNetwork	function: 1E48E2C0	
[00:02:31]: SetSelected	function: 0B947B38	
[00:02:31]: AddTextWidget	function: 30FE4038	
[00:02:31]: AddPostProcessor	function: 30FE4318	
[00:02:31]: AddTag	function: 0B947808	
[00:02:31]: EnableMovementPrediction	function: 0B947DD8	
[00:02:31]: AddWaveComponent	function: 30FE44D8	
[00:02:31]: Hide	function: 0B9478C8	
[00:02:31]: LocalToWorldSpace	function: 0B947298	
[00:02:31]: GetName	function: 0B947388	
[00:02:31]: AddGroundCreepEntity	function: 30FE4438	
[00:02:31]: SetName	function: 0B947598	
[00:02:31]: AddGroundCreep	function: 30FE4578	
[00:02:31]: AddMapExplorer	function: 30FE3B18	
[00:02:31]: AddDebugRender	function: 30FE40B8	
[00:02:31]: HasTag	function: 0B9477D8	
[00:02:31]: AddSoundEmitter	function: 30FE35D8	
[00:02:31]: AddLightWatcher	function: 30FE3FD8	
[00:02:31]: AddClientSleepable	function: 30FE34F8	
[00:02:31]: FrustumCheck	function: 0B947E38	
[00:02:31]: AddGraphicsOptions	function: 30FE44F8	
[00:02:31]: AddFontManager	function: 30FE40F8	
[00:02:31]: AddVideoWidget	function: 30FE4018	
[00:02:31]: AddImageWidget	function: 30FE4358	
[00:02:31]: AddUITransform	function: 30FE37B8	
[00:02:31]: AddMiniMap	function: 30FE3F78	
[00:02:31]: SetPristine	function: 0B947BC8	
[00:02:31]: IsValid	function: 0B9475C8	
[00:02:31]: AddMiniMapEntity	function: 30FE3FB8	
[00:02:31]: SetAABB	function: 0B947508	
[00:02:31]: CallPrefabConstructionComplete	function: 0B947A18	
[00:02:31]: AddShadowManager	function: 30FE32B8	
[00:02:31]: SetInLimbo	function: 0B9479B8	
[00:02:31]: GetGUID	function: 0B947838	
[00:02:31]: AddDynamicShadow	function: 30FE3EF8	
[00:02:31]: AddStaticShadow	function: 30FE3D18	
[00:02:31]: AddAccountManager	function: 30FE4738	
[00:02:31]: AddParticleEmitter	function: 30FE3D98	
[00:02:31]: MoveToBack	function: 0B947AD8	
[00:02:31]: AddMap	function: 30FE3918	
[00:02:31]: AddPathfinder	function: 30FE3A98	
[00:02:31]: RemoveTag	function: 0B947658	
[00:02:31]: AddTwitchOptions	function: 30FE45B8	
[00:02:31]: AddTransform	function: 30FE3118	
[00:02:31]: AddMapLayerManager	function: 30FE4758	
[00:02:31]: AddShardNetwork	function: 30FE3378	
[00:02:31]: FlushLocalDirtyNetVars	function: 0B9478F8	
[00:02:31]: IsAwake	function: 0B947268	
[00:02:31]: AddVFXEffect	function: 30FE3E58	





---TheNet

[00:00:47]: GetServerLANOnly	function: 13364130	
[00:00:47]: SetAllowNewPlayersToConnect	function: 133649D0	
[00:00:47]: DoneLoadingMap	function: 13364190	
[00:00:47]: GetDefaultMaxPlayers	function: 133643D0	
[00:00:47]: SetIsMatchStarting	function: 13366470	
[00:00:47]: GetServerIsDedicated	function: 13365A20	
[00:00:47]: PrintNetwork	function: 133635F0	
[00:00:47]: SetDefaultMaxPlayers	function: 13364520	
[00:00:47]: ViewNetFriends	function: 13365570	
[00:00:47]: SetDefaultGameMode	function: 133642E0	
[00:00:47]: GetClientMetricsForUser	function: 133650F0	
[00:00:47]: GetServerIsClientHosted	function: 13365660	
[00:00:47]: TruncateSnapshotsInClusterSlot	function: 13365420	
[00:00:47]: SystemMessage	function: 13363590	
[00:00:47]: GetWorldSessionFile	function: 13364BB0	
[00:00:47]: DownloadServerDetails	function: 13363FB0	
[00:00:47]: GetCurrentSnapshot	function: 13365240	
[00:00:47]: SearchLANServers	function: 13363AA0	
[00:00:47]: GetDefaultGameMode	function: 13363D10	
[00:00:47]: GetServerEvent	function: 13363EC0	
[00:00:47]: GetDefaultServerName	function: 133640A0	
[00:00:47]: GetLocalUserName	function: 13365C30	
[00:00:47]: GetAveragePing	function: 13363290	
[00:00:47]: IsSearchingServers	function: 133641C0	
[00:00:47]: IsClanIDValid	function: 13364850	
[00:00:47]: GetUserSessionFileInClusterSlot	function: 13364A90	
[00:00:47]: SearchServers	function: 133636B0	
[00:00:47]: DeleteUserSession	function: 133651E0	
[00:00:47]: BeginSession	function: 13363E60	
[00:00:47]: GetDefaultEncodeUserPath	function: 13364580	
[00:00:47]: SetDefaultLANOnlyServer	function: 13364970	
[00:00:47]: Talker	function: 13363200	
[00:00:47]: GetServerListings	function: 133638F0	
[00:00:47]: StartServer	function: 13363470	
[00:00:47]: GetServerMaxPlayers	function: 13363B00	
[00:00:47]: AnnounceDeath	function: 13363530	
[00:00:47]: GetCloudServerId	function: 13366620	
[00:00:47]: GetUserID	function: 133652D0	
[00:00:47]: GetLanguageCode	function: 133658D0	
[00:00:47]: IsWhiteListed	function: 13365EA0	
[00:00:47]: AutoJoinLanServer	function: 13363CB0	
[00:00:47]: GetWorldSessionFileInClusterSlot	function: 13364DF0	
[00:00:47]: GetIsMasterSimulation	function: 13362C90	
[00:00:47]: NotifyAuthenticationFailure	function: 133654E0	
[00:00:47]: SetCloudServerInitiatorUserId	function: 133642B0	
[00:00:47]: GetBlacklist	function: 13363920	
[00:00:47]: GetServerListingReadDirty	function: 133636E0	
[00:00:47]: SendModRPCToServer	function: 13362DE0	
[00:00:47]: GetPlayerSaveLocationInClusterSlot	function: 13364E50	
[00:00:47]: SendWorldResetRequestToServer	function: 13363410	
[00:00:47]: HasPendingConnection	function: 133631D0	
[00:00:47]: SendWorldSaveRequestToMaster	function: 133633B0	
[00:00:47]: Announce	function: 13363620	
[00:00:47]: GetIsHosting	function: 13362F30	
[00:00:47]: SetBlacklist	function: 133639E0	
[00:00:47]: GetDefaultClanAdmins	function: 13364760	
[00:00:47]: CleanupSessionCache	function: 13365030	
[00:00:47]: StartClient	function: 13363320	
[00:00:47]: GetAutosaverEnabled	function: 13364250	
[00:00:47]: GetServerClanID	function: 13363A70	
[00:00:47]: GetServerHasPassword	function: 133653F0	
[00:00:47]: StopSearchingServers	function: 13363F80	
[00:00:47]: Kick	function: 133632C0	
[00:00:47]: SetDefaultServerLanguage	function: 13364340	
[00:00:47]: GetAllowNewPlayersToConnect	function: 13364B20	
[00:00:47]: GetCountryCode	function: 133658A0	
[00:00:47]: CancelCloudServerRequest	function: 133630E0	
[00:00:47]: GetAllowIncomingConnections	function: 13364D30	
[00:00:47]: AllowConnections	function: 133665F0	
[00:00:47]: GetChildProcessError	function: 13366650	
[00:00:47]: JoinParty	function: 13365B40	
[00:00:47]: GetServerPVP	function: 133641F0	
[00:00:47]: GetServerDescription	function: 13365300	
[00:00:47]: GetSessionIdentifier	function: 13364C10	
[00:00:47]: RemoveFromWhiteList	function: 13365BA0	
[00:00:47]: GetChildProcessStatus	function: 13366200	
[00:00:47]: SetDefaultPvpSetting	function: 133644C0	
[00:00:47]: SetIsWorldSaving	function: 13366140	
[00:00:47]: LoadPermissionLists	function: 13365A80	
[00:00:47]: UpdatePlayingWithFriends	function: 133635C0	
[00:00:47]: SetIsClientInWorld	function: 13365C90	
[00:00:47]: SetDefaultServerPassword	function: 133644F0	
[00:00:47]: IncrementSnapshot	function: 133650C0	
[00:00:47]: SetServerPassword	function: 133646A0	
[00:00:47]: SetIsWorldResetting	function: 13365CF0	
[00:00:47]: SetDefaultFriendsOnlyServer	function: 13364D90	
[00:00:47]: AddToWhiteList	function: 13365AE0	
[00:00:47]: GetIsClient	function: 13362D20	
[00:00:47]: DownloadServerMods	function: 13365F30	
[00:00:47]: GetDefaultFriendsOnlyServer	function: 13364310	
[00:00:47]: IsNetIDPlatformValid	function: 13365F60	
[00:00:47]: ServerModsDownloadCompleted	function: 13365720	
[00:00:47]: SerializeUserSession	function: 13364CD0	
[00:00:47]: ServerModSetup	function: 13365E70	
[00:00:47]: SetDefaultClanInfo	function: 133647F0	
[00:00:47]: BeginServerModSetup	function: 13365FF0	
[00:00:47]: GetPVPEnabled	function: 13364F40	
[00:00:47]: ServerModCollectionSetup	function: 13366020	
[00:00:47]: DeserializeUserSession	function: 13364880	
[00:00:47]: AnnounceResurrect	function: 13363140	
[00:00:47]: GetPartyTable	function: 13365FC0	
[00:00:47]: EncodeUserPath	function: 13365060	
[00:00:47]: GetPartyChatHistory	function: 13365E40	
[00:00:47]: IsOnlineMode	function: 13365480	
[00:00:47]: DeleteCluster	function: 13363D40	
[00:00:47]: GetDefaultLANOnlyServer	function: 13364A60	
[00:00:47]: SetPartyServer	function: 13365E10	
[00:00:47]: SetAllowIncomingConnections	function: 13364BE0	
[00:00:47]: ListSnapshots	function: 13365000	
[00:00:47]: LeaveParty	function: 13365D50	
[00:00:47]: SendLobbyCharacterRequestToServer	function: 13363380	
[00:00:47]: CallRPC	function: 13362CC0	
[00:00:47]: IsDedicated	function: 13363E30	
[00:00:47]: GetDefaultServerLanguage	function: 13364400	
[00:00:47]: GetServerGameMode	function: 13363710	
[00:00:47]: OnPlayerHistoryUpdated	function: 13365D80	
[00:00:47]: SetDefaultServerDescription	function: 13364820	
[00:00:47]: GetFriendsList	function: 13365510	
[00:00:47]: GetDefaultVoteEnabled	function: 13364940	
[00:00:47]: GetItemsBranch	function: 13366320	
[00:00:47]: GetPlayerCount	function: 13365870	
[00:00:47]: GetDeferredServerShutdownRequested	function: 13365840	
[00:00:47]: StopBroadcastingServer	function: 13365810	
[00:00:47]: SetDeferredServerShutdownRequested	function: 133656C0	
[00:00:47]: GetDefaultServerIntention	function: 13364070	
[00:00:47]: GetServerHasPresentAdmin	function: 133659F0	
[00:00:47]: IsDedicatedOfflineCluster	function: 13364010	
[00:00:47]: GetIsServerAdmin	function: 133657E0	
[00:00:47]: GetDefaultPvpSetting	function: 13364550	
[00:00:47]: GetUserSessionFile	function: 13364CA0	
[00:00:47]: NotifyLoadingState	function: 13365630	
[00:00:47]: GetIsServer	function: 13362C60	
[00:00:47]: SendRemoteExecute	function: 13365600	
[00:00:47]: GenerateClusterToken	function: 13365990	
[00:00:47]: ViewNetProfile	function: 13365780	
[00:00:47]: IsNetOverlayEnabled	function: 13365540	
[00:00:47]: GetServerListing	function: 13365A50	
[00:00:47]: GetServerModNames	function: 13365900	
[00:00:47]: GetServerFriendsOnly	function: 133638C0	
[00:00:47]: GetServerModsDescription	function: 13365360	
[00:00:47]: GetServerName	function: 13364F70	
[00:00:47]: SetWorldGenData	function: 13364B50	
[00:00:47]: BanForTime	function: 13363980	
[00:00:47]: GetServerListingFromActualIndex	function: 13363890	
[00:00:47]: GetDefaultClanOnly	function: 13364700	
[00:00:47]: GetClientTableForUser	function: 13364EB0	
[00:00:47]: SetSeason	function: 13364B80	
[00:00:47]: SetClientCacheSessionIdentifier	function: 13364EE0	
[00:00:47]: GetCloudServerRequestState	function: 13363440	
[00:00:47]: DeserializeAllLocalUserSessions	function: 13365270	
[00:00:47]: ListSnapshotsInClusterSlot	function: 13365090	
[00:00:47]: DiceRoll	function: 13363650	
[00:00:47]: TruncateSnapshots	function: 13364F10	
[00:00:47]: JoinServerResponse	function: 133634A0	
[00:00:47]: Ban	function: 133632F0	
[00:00:47]: TryDefaultEncodeUserPath	function: 133645B0	
[00:00:47]: SendWorldRollbackRequestToServer	function: 13363170	
[00:00:47]: GetNetworkStatistics	function: 13365C00	
[00:00:47]: DeleteSession	function: 13363DA0	
[00:00:47]: GetPing	function: 13363260	
[00:00:47]: SetCurrentSnapshot	function: 133652A0	
[00:00:47]: GetServerModsEnabled	function: 13365390	
[00:00:47]: GetServerIntention	function: 13363800	
[00:00:47]: IsVoiceActive	function: 13363BF0	
[00:00:47]: Vote	function: 13363C50	
[00:00:47]: AnnounceVoteResult	function: 13363A10	
[00:00:47]: Disconnect	function: 13363830	
[00:00:47]: SerializeWorldSession	function: 13364AC0	
[00:00:47]: SendRPCToServer	function: 13362F60	
[00:00:47]: StopVote	function: 13363C20	
[00:00:47]: DeserializeUserSessionInClusterSlot	function: 133648B0	
[00:00:47]: StartVote	function: 13363770	
[00:00:47]: SetPlayerMuted	function: 13363740	
[00:00:47]: IsConsecutiveMatchForPlayer	function: 133661A0	
[00:00:47]: SendSpawnRequestToServer	function: 133630B0	
[00:00:47]: SetCheckVersionOnQuery	function: 13364100	
[00:00:47]: SendSlashCmdToServer	function: 13362D50	
[00:00:47]: GetDefaultClanID	function: 13364610	
[00:00:47]: GetClientTable	function: 13364FA0	
[00:00:47]: ReportListing	function: 13363110	
[00:00:47]: SetGameData	function: 13364DC0	
[00:00:47]: Say	function: 133633E0	
[00:00:47]: GetServerClanOnly	function: 13363860	
[00:00:47]: SetLobbyCharacter	function: 13363560	
[00:00:47]: SetServerTags	function: 13364A30	
[00:00:47]: PartyChat	function: 13365B70	
[00:00:47]: StartCloudServerRequestProcess	function: 13363080	
[00:00:47]: GetDefaultServerPassword	function: 133643A0	
[00:00:47]: SendResumeRequestToServer	function: 13363350	
[00:00:47]: InviteToParty	function: 13365DB0	
[00:00:47]: GetDefaultServerDescription	function: 13364370	
[00:00:47]: SetDefaultServerName	function: 13363CE0	
[00:00:47]: SetDefaultServerIntention	function: 13364040








TheInputProxy
[00:01:55]: GetInputDeviceCount	function: 00000000165E1A90	
[00:01:55]: LoadControls	function: 00000000165E1D10	
[00:01:55]: SetCursorVisible	function: 00000000165E21D0	
[00:01:55]: EnableVibration	function: 00000000165E1E90	
[00:01:55]: MapControl	function: 00000000165E10D0	
[00:01:55]: GetLastActiveControllerIndex	function: 00000000165E0F10	
[00:01:55]: IsInputDeviceEnabled	function: 00000000165E1B90	
[00:01:55]: UnMapControl	function: 00000000165E14D0	
[00:01:55]: LoadDefaultControlMapping	function: 00000000165E1CD0	
[00:01:55]: StopMappingControls	function: 00000000165E1090	
[00:01:55]: GetOSCursorPos	function: 00000000165E26D0	
[00:01:55]: SetOSCursorPos	function: 00000000165E2050	
[00:01:55]: LoadCurrentControlMapping	function: 00000000165E1590	
[00:01:55]: FlushInput	function: 00000000165E1150	
[00:01:55]: IsAnyInputDeviceConnected	function: 00000000165E1890	
[00:01:55]: IsInputDeviceConnected	function: 00000000165E1B50	
[00:01:55]: GetLocalizedControl	function: 00000000165E1750	
[00:01:55]: HasMappingChanged	function: 00000000165E0F90	
[00:01:55]: CancelMapping	function: 00000000165E1490	
[00:01:55]: AddVibration	function: 00000000165E2210	
[00:01:55]: StartMappingControls	function: 00000000165E0F50	
[00:01:55]: GetInputDeviceType	function: 00000000165E0D90	
[00:01:55]: EnableInputDevice	function: 00000000165E1AD0	
[00:01:55]: RemoveVibration	function: 00000000165E1DD0	
[00:01:55]: ApplyControlMapping	function: 00000000165E1850	
[00:01:55]: StopVibration	function: 00000000165E1ED0	
[00:01:55]: SaveControls	function: 00000000165E1110	
[00:01:55]: IsAnyControllerConnected	function: 00000000165E1390	
[00:01:55]: IsAnyControllerActive	function: 00000000165E0E90	
[00:01:55]: GetInputDeviceName	function: 00000000165E1310

]]



--!!!! LOOK I FOUND WALLS!!!!!
--[[local function InitializePathFinding(inst)
    local x, _, z = inst.Transform:GetWorldPosition()
    TheWorld.Pathfinder:AddWall(x - 0.5, 0, z - 0.5)
    TheWorld.Pathfinder:AddWall(x - 0.5, 0, z + 0.5)
    TheWorld.Pathfinder:AddWall(x + 0.5, 0, z - 0.5)
    TheWorld.Pathfinder:AddWall(x + 0.5, 0, z + 0.5)
end

local function OnRemove(inst)
    local x, _, z = inst.Transform:GetWorldPosition()
    TheWorld.Pathfinder:RemoveWall(x - 0.5, 0, z - 0.5)
    TheWorld.Pathfinder:RemoveWall(x - 0.5, 0, z + 0.5)
    TheWorld.Pathfinder:RemoveWall(x + 0.5, 0, z - 0.5)
    TheWorld.Pathfinder:RemoveWall(x + 0.5, 0, z + 0.5)
end




--HEY DINGUS YOU NEVER NOTICED THIS IN CAMERAS???
 --listen dist
    local lx = dx*(-self.distance*.1) + self.currentpos.x
    local ly = dy*(-self.distance*.1) + self.currentpos.y
    local lz = dz*(-self.distance*.1) + self.currentpos.z
	--print (lx, ly, lz, self.distance)
    TheSim:SetListener(lx, ly, lz, dx, dy, dz, ux, uy, uz)
	
--COULD THIS BE WHAT DETERMINES SOUND DISTANCE AND WAVE RENDERING???



HEY CHECK OUT player_common_extensions

 inst.components.health.canheal = true
    if not GetGameModeProperty("no_hunger") then
        inst.components.hunger:Resume()
    end
	
	
	
SOME SOUND VOLUME STUFF! FROM PLAYERHUD.LUA
TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/clouds", "windsound")
local p = easing.outCubic(dist_percent - cutoff, 0, 1, 1 - cutoff)
TheFocalPoint.SoundEmitter:SetVolume("windsound", p)




--THIS SEEMS SHIFTY AS HECK BUT WOW THATS NEAT (FROM GLOBALPAUSE MOD)
GLOBAL.package.loaded["librarymanager"] = nil
local AutoSubscribeAndEnableWorkshopMods = GLOBAL.require("librarymanager")
if GLOBAL.IsWorkshopMod(modname) then
    AutoSubscribeAndEnableWorkshopMods({"workshop-1378549454"})
else
    --if the Gitlab Versions dont exist fallback on workshop version
    local GEMCORE = GLOBAL.KnownModIndex:GetModActualName("[API] Gem Core - GitLab Version") or "workshop-1378549454"
    AutoSubscribeAndEnableWorkshopMods({GEMCORE})
end





--HEY HEY LOOKIE HERE. you can SORT TABLES. found in stategraph.lua

        local function pred(a,b)
            return a.time < b.time
        end
        table.sort(self.timeline, pred)
		
		
--FUNNY THING, THE HUD IS ACTUALLY A PREFAB. OR AT LEAST IT USES ONE FOR ASSET LOADING
--TRY EDITING THE HUD PREFAB TO REMOVE ASSETS SO THINGS ARE INVISIBLE




--HEY WAIT, THEFOCALPOINT CAN PLAY SOUNDS... SHOULD WE BE PLAYING QUIET SOUNDS FROM HERE???
TheFocalPoint.SoundEmitter:PlaySound("dontstarve/wilson/equip_item")  --from playercommon



--MAYBE AN EASIER WAY TO HANDLE THESE WHEN TOO LAZY FOR ARRAYS
if inst.sg.statemem.projectiledelay > FRAMES then
	inst.sg.statemem.projectilesound =
		(equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
		(equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
		"dontstarve/wilson/attack_weapon"


--THIS CAN PROBABLY BE USED TO CONTROL SOUND VOLUME! DUNNO IF THAT MEANS WE CAN MAKE IT LOUDER THO
inst.SoundEmitter:SetParameter("loop", "intensity", 1)


--FOUND THIS IN THE MODMAIN OF "CRAFT-POT" MOD BY IVANX AND IT IS HONESTLY FASCINATING...

local function FollowCameraPostInit(inst)
  local old_can_control = inst.CanControl
  inst.CanControl = function(inst, ...)
    return old_can_control(inst, ...) and not GetPlayer().HUD.controls.foodcrafting:IsFocused()
  end
end

-- follow camera modification is required to cancel the scrolling
AddClassPostConstruct("cameras/followcamera", FollowCameraPostInit)



--WHAT IS THIS THING??? WEEIRD, BUT COOL.... FROM THE ARTIFICIAL WILSON MOD
local AddKeyHandler = TheInput["AddKey"..(down and "Down" or "Up").."Handler"]
return AddKeyHandler(TheInput, key:lower():byte(), handler_fn)


--COULD COME IN HANDY. MAYBE NOT FOR SMASHUP THOUGH.
AddPrefabPostInitAny?
It applies to all prefabs, maybe just check if it has a tag or component that applies
]]


