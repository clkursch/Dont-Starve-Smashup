
--3-27-22 LOADING TIPS... WILL THIS WORK?
local IsTheFrontEnd = GLOBAL.rawget(GLOBAL, "TheFrontEnd")

if IsTheFrontEnd then
	GLOBAL.STRINGS.UI.LOADING_SCREEN_LORE_TIPS = {}
	GLOBAL.STRINGS.UI.LOADING_SCREEN_CONTROL_TIPS_NOT_CONSOLE = {}
	GLOBAL.STRINGS.UI.LOADING_SCREEN_CONTROL_TIPS_CONSOLE = {}
	GLOBAL.STRINGS.UI.LOADING_SCREEN_OTHER_TIPS = {} --11-14-22 WE MISSED ONE! LETS JUST AXE IT
	--11-14-22 THIS IS A CONSTANT THAT IT'S TRYING TO PULL CONTROLS FROM! MAYBE WE CAN AXE THIS TO FIX THE CRASHING
	GLOBAL.LOADING_SCREEN_CONTROL_TIP_KEYS = {}

	local currloc = GLOBAL.GetCurrentLocale()
	-- local setlanguage = GLOBAL.TUNING.SMASHUP.LANGUAGE
	--SNAPPING TILLS HANDLES THIS REALLY WELL
	if currloc ~= nil and currloc.code == "zh" then
		setlanguage = "sch"
	end

	-- if setlanguage == "sch" then
	-- elseif setlanguage == "ru" then
	-- end
end
	--REMOVE THE OLD LOADING TIPS. WE HAVE OUR OWN...
	GLOBAL.STRINGS.UI.LOADING_SCREEN_CONTROL_TIPS = {
		TIP_RECOVERY = "Use your recovery move by pressing [Special Attack] while holding [Up] to give yourself a boost and avoid falling to your death!",
		TIP_DODGE = "Press Left or Right while blocking to perform a roll, which can be used to dodge attacks and projectiles.",
		TIP_SMASHUP3 = "At the peak of a jump, press [Down] to quickly increase your falling speed with fastfall. Use this to get back to the ground more quickly or throw off your opponent's followup attacks.",
		TIP_SMASHUP4 = "Small attacks might not always be enough to KO an opponent at high percent! Certain attacks like Smash Attacks scale better at high percents to finish off opponents that have taken a lot of damage. ",
		TIP_SMASHUP5 = "You can use the directional [C-stick] attack buttons to perform a down-air attack without fastfalling, or a forward-air attack while moving backwards.",
		TIP_SMASHUP6 = "You can't grab ledges while performing aerial attacks, so don't mash buttons near the ledge!",
		TIP_SMASHUP7 = "Once the timer reaches zero, Charlie comes out to finish off the remaining fighters! Players at higher percents will be launched harder, but you could tip the scales by knocking your opponent into the air at just the right moment.",
		TIP_SMASHUP8 = "If you're sent into a tumble by an attack, pressing Block right before you hit the ground will perform a Tech, which will quickly put you back on your feet instead of laying on the ground.",
		TIP_SMASHUP9 = "Holding Block will prevent you from taking damage, but you can still be grabbed! And keep an eye on your Block meter; you'll be dizzy if it ever reaches 0!",
		TIP_SMASHUP10 = "Enable in-game music from the controls menu! If your music volume is set to 0, it will be off by default.",
		TIP_SMASHUP11 = "Enable Team Battles in the PvP menu from the lobby to separate players into teams of Red vs Blue with team colored auras.",
		TIP_SMASHUP12 = "Tap-Jump is enabled by default, which means pressing [Up] will perform a jump. This can make it hard to do up-tilts from the ground, and you can disable it from the Settings menu in the top left.",
		TIP_SMASHUP13 = "Auto-Dash is enabled by default, which means that running forward for a short time will cause the character to dash. This can be disabled from the Settings menu in the top left. You can always dash instantly by double-tapping Left or Right.",
		TIP_SMASHUP14 = "If you want to change your control layout, you can download the 'Smashup Custom Controls' mod from the steam workshop.",
		TIP_SMASHUP15 = "After using a Recovery move (Up-Special) you'll be put into a helpless state until you touch the ground again. Grabbing the ledge before your recovery move ends can make it harder for an opponent to take advantage of your helpless state.",


	}


	--
	--


	GLOBAL.STRINGS.UI.LOADING_SCREEN_SURVIVAL_TIPS =
	{
		TIP_WOODIE1 = "Woodie's Axe throw (Neutral special) is a powerful offstage finisher, but it will leave you wide open if you aren't careful.",
		TIP_WOODIE2 = "The first swing of Woodie's spinning Up-Special attack is much stronger if used on the ground.",
		TIP_WOODIE3 = "Woodie's Forward Smash has very high block damage and can almost completely break an opponent's guard.",
		TIP_WOODIE4 = "The swing at the end of Woodie's Forward-Special charge is much more powerful than the bash at the start of the attack.",
		TIP_WOODIE5 = "Woodie's Neutral-Air attack is one of his few attacks that doesn't use Lucy. It's very short ranged, but its fast speed makes it ideal for setting up combos.",
		
		TIP_WILSON1 = "Wilson's Neutral Special attack is unimpressive if uncharged, but its range and power increase tremendously with just a little bit of charging. He also has armor as he releases the blast. Charge it too long, and you might damage yourself too!",
		TIP_WILSON2 = "Wilson's Down-Special gives you a big vertical boost in the air, effectively giving you an extra jump. Use this to help you recover, extend your aerial mobility, and escape juggles.",
		TIP_WILSON3 = "Wilson's Up-Special, if used on the ground, is a great combo starter. If you land a hit, you can immediately follow up with another attack!",
		TIP_WILSON4 = "Wilson's Down-Smash has a very low launch angle, which can recovery very difficult for opponents if you hit them right at the ledge.",
		TIP_WILSON5 = "Wilson's boomerang (Side-Special) can only hit each opponent once, but unlike most projectiles, it can keep flying and continue to hit other opponents.",
		
		--"",
		TIP_WICKERBOTTOM1 = "Wickerbottom's Forward-Air attack is exceptionally powerful if you hit with the very tip of her shoe.",
		TIP_WICKERBOTTOM2 = "Reading Wickerbottom's spellbooks causes her to stall in the air. This can be useful for mixing up your landing, making it harder for enemies to juggle you with aerial attacks.",
		TIP_WICKERBOTTOM3 = "Wickerbottom's recovery move, Up-Special, can get her back on stage from almost anywhere. But it also leaves her wide open during the flight, so don't take too long...",
		TIP_WICKERBOTTOM4 = "Wickerbottom's Up-Smash summons a lightning strike that reaches all the way to the top of the sky! Use this to catch enemies that try and jump over you.",
		
		--"",
		TIP_MAXWELL1 = "Maxwell's Down-Special summons a shadow puppet that shares your controls. The puppet can't do special attacks, so you can freely control the puppet while Maxwell performs special attacks.",
		TIP_MAXWELL2 = "As Maxwell, using Down-Special while a shadow puppet is out will send the puppet forward. If used in the air, the puppet will retreat to Maxwell's position.",
		TIP_MAXWELL3 = "Maxwell's Up-Special teleports him in the direction you choose. It's great for recovery, but it's also great for teleporting away from followup attacks or getting past projectiles.",
		TIP_MAXWELL4 = "Maxwell's Up-Smash is one of the strongest in the game, but its tall height means it won't hit most opponents on the ground. (Unless the opponent is also Maxwell...)",
		--"",
		TIP_WES1 = "Wes's Forward-Air is a fast-hitting bicycle kick that also allows him to temporarily slow his fall.",
		TIP_WES2 = "Wes's fast falling speed can make him harder to hit, but it also makes it very easy for him to accidentally fall offstage. Be careful!",
		TIP_WES3 = "Wes great mobility is offset by his light weight, which makes him easier to launch than other fighters.",
		TIP_WES4 = "Wes's Box (Down-Special) can reflect any projectile! But it doesn't protect him from melee attacks.",
		TIP_WES5 = "Wes's Down-Tilt attack slinks forward like a snake while bringing him very low to the ground. It can even slide under some projectiles!",


		-- This tip needed for non-binded controls fallback tip string
		-- TIP_BIND_CONTROLS = "Play with Controls Settings in the Options Menu to fit your control needs.",
	}


















--SO CAN WE JUST LIKE... ADD LEVELS?... LIKE RIGHT HERE?
-- IF YOU'RE HOSTING A DEDICATED SERVER, YOURE GOING TO WANT TO COPY/PASTE ALLLL OF THE BELOW AddLevel{} INTO A "leveldataoverride.lua" FILE IN YOUR MASTER SHARD FOLDER
-- JUST REPLACE "AddLevel(LEVELTYPE.SURVIVAL,"  WITH "return" AND YOURE GOOD TO GO. PROBABLY. (OR JUST GENERATE ONE IN SINGLEPLAYER AND COPY THE FILE IT GENERATES)
AddLevel(LEVELTYPE.SURVIVAL, { 
    id = "GM_SMASHUP",
    name = "SMASHUP",
    desc = "SMASHUP",
    version = 3,
    location = "forest", -- this is actually the prefab name --?? STILL UNSURE WHAT THEY MEAN BY THIS --oh I forget each world has its own prefab. the world's prefab is forest
    overrides = {
        --task_set = "PillowWorld",
        --start_location = "forest_pillowstart", 
		--task_set = "default_modified",
		task_set = "classic", --6-15-20 I THINK WE CAN USE THIS TO FORCE THE "NON-ROG" MAP TYPE AND REDUCE NUMBER OF REQUIRED PREFABS TO MESS US UP.
		--WOW THIS MAKES IT GENERATE REALLY FAST. BRAVO
		
		boons = "never",
		touchstone = "never",
		traps = "never",
		poi = "never",
		protected = "never",
		roads="never", --GTFO
		
		--AIGHT... HERE WE GO
		spiders = "never",     
		hounds = "never",      
		houndmound = "never",  
		merm = "never", 
		tentacles = "never",   
		chess = "never",
		lureplants = "never",  
		walrus = "never",      
		liefs = "never",
		deciduousmonster = "never",
		krampus = "never",     
		bearger = "never",     
		deerclops = "never",   
		goosemoose = "never",  
		dragonfly = "never",   
		antliontribute = "never",  
		rabbits = "never",     
		moles = "never",
		butterfly = "never",   
		birds = "never",
		buzzard = "never",     
		catcoon = "never",     
		perd = "never", 
		pigs = "never", 
		lightninggoat = "never",   
		beefalo = "never",     
		beefaloheat = "never", 
		hunt = "never", 
		alternatehunt = "never",   
		penguins = "never",    
		ponds = "never",
		bees = "never", 
		angrybees = "never",   
		tallbirds = "never",   
		flowers = "never",     
		grass = "never",
		sapling = "never",     
		marshbush = "never",   
		tumbleweed = "never",  
		reeds = "never",
		trees = "never",
		flint = "never",
		rock = "never", 
		rock_ice = "never",    
		meteorspawner = "never",   
		meteorshowers = "never",   
		berrybush = "never",   
		carrot = "never",   
		mushroom = "never",    
		cactus = "never",      
		world_size = "small", 
		branching = "default", 
		loop = "default",      
		specialevent = "none", 
		autumn = "verylongseason", 
		winter = "noseason",
		spring = "noseason",
		summer = "noseason",   
		season_start = "default",  
		day = "onlyday",
		weather = "never",     
		lightning = "never",   
		earthquakes = "never", 
		frograin = "never",    
		wildfires = "never",   
		regrowth = "veryslow", 
		disease_delay = "none",  
		petrification = "none",
    },
    numrandom_set_pieces = 0,
    random_set_pieces = 
    {
    },
    background_node_range = {0,0},
    required_prefabs = {
        "multiplayer_portal",
    },
})




AddTaskSet("default_modified", {
		name = "TEST SMASH",
        location = "forest",
		tasks = {	--default_tasks,
			"For a nice walk",
		}, 
		numoptionaltasks = 0,
        valid_start_tasks = {
		},
		set_pieces = {
		},
	})
	
	
	
	
--WAIT SO CAN YOU JUST LIKE. CHANGE THE SERVER SETTINGS MENUS. WITH CODE? FROM HERE?

local require = GLOBAL.require
local package = GLOBAL.package 
--RANDOM QUESTION FOR NOBODY WHO WILL SEE IT: WHY DO SO MANY PEOPLE MAKE "_G=GLOBAL" A LOCAL VARIABLE? IS IT SIMPLE TO SAVE SPACE EVEN WHEN ITS ALREADY SO SMALL AND SCARECLY USED?

local IsTheFrontEnd = GLOBAL.rawget(GLOBAL, "TheFrontEnd")


--original code referrenced from Forged Forge mod
if IsTheFrontEnd then  --OTHERWISE ALL THIS STUFF WILL HAPPEN ON DEDICATED SERVERS. RIGHT?
	--EVERYTHING IN HERE HAPPENS THE INSTANT THE USER ENABLES A MOD IN THE MODS TAB IN SERVER SETUP
	--
	local ModsTab = require("widgets/redux/modstab") --WHY DID YOU USE CAPITALS IN YOUR VARIABLE NAMES, THIS UPSETS ME 
	local _OnConfirmEnable = ModsTab.OnConfirmEnable
	
	local WorldCustTab = require("widgets/redux/worldcustomizationtab") --THINK ILL BORROW THIS TOO
	-- local _OnChangeGameMode = WorldCustTab.OnChangeGameMode --NOT GONNA ADD TO IT. JUST FLAT OUT OVERWRITE IT
	
	
	--WHEN WE ENABLE SMASHUP, SET OUR GAMEMODE TO SMASHUP
	ModsTab.OnConfirmEnable = function(self, restart, modname) --HEY HEY THIS DOESNT WORK SO HOT IF WE WANT TO ENABLE OTHER MODS AFTERWARDS, IT TURNS IT ALL BACK OFF
		local CurrentScreen = GLOBAL.TheFrontEnd:GetActiveScreen()
		local modinfo = GLOBAL.KnownModIndex:GetModInfo(modname) --SHOULDNT THIS BE UP HERE??? YES IT SHOULD, SILLY
		-- print("SO AM I ENABLED FOR SPINNING? ", CurrentScreen.server_settings_tab.game_mode.spinner.enabled)
		
		if CurrentScreen and CurrentScreen.server_settings_tab then
			local fancy_name = modname and GLOBAL.KnownModIndex:GetModFancyName(modname) or nil
			
			-- If someone disabled our mod or unloaded all mods (nil).
			-- if modname == nil or fancy_name == modinfo.name then   --NOOO NO, IF WE DISABLE SOME -ELSES- MOD, IT THINKS WE DISABLED THIS ONE!
			if CurrentScreen.server_settings_tab.game_mode.spinner.disabled and (fancy_name == modinfo.name) then --GOTCHA >:3 
				-- print("CHANGING BACK TO DEFAULT!")
				CurrentScreen.server_settings_tab.game_mode.spinner:Enable()
				CurrentScreen.server_settings_tab.game_mode.spinner:SetOptions(GLOBAL.GetGameModesSpinnerData(GLOBAL.ModManager:GetEnabledServerModNames()))
				CurrentScreen.server_settings_tab.game_mode.spinner:SetSelectedIndex(1) --SET GAME MODE BACK TO SURVIVAL. THE DEFAULT
				CurrentScreen.server_settings_tab.game_mode.spinner:Changed()
				
				
			-- elseif fancy_name == modinfo.name then --if CurrentScreen.server_settings_tab.game_mode.spinner.enabled then --ITS ONLY SAFE TO ASSUME WE CAN DISABLE T
				-- CurrentScreen.server_settings_tab.game_mode.spinner:SetOptions(GLOBAL.GetGameModesSpinnerData(GLOBAL.ModManager:GetEnabledServerModNames()))
				-- CurrentScreen.server_settings_tab.game_mode.spinner:SetSelected("smashup")
				-- CurrentScreen.server_settings_tab.game_mode.spinner:Changed()
				-- CurrentScreen.server_settings_tab.game_mode.spinner:Disable()
			end
		end
		_OnConfirmEnable(self, restart, modname) --OHHH AND THEN IT CONTINUES WITH THE NORMAL ONE. SO THIS ESSENTIALLY ADDS ONTO THE EXISTING FUNCTION. COOL
		
		-- local modinfo = GLOBAL.KnownModIndex:GetModInfo(modname) --THIS DOESNT DO ANY GOOD DOWN HERE
	end
	--KEEP IN MIND, EVERY TIME YOU ENABLE AND DISABLE THIS MOD, THIS FUNCTION DUPLICATES ITSELF.
	--COULD THAT BE A PROBLEM?... MAYBE? EH. 
	--2-4-2020 YES IT WILL!!!! IF YOUR LAST-SELECTED WORLD SLOT HAS THIS MOD ENABLED, THE LAUNCH SCREEN WILL CREATE THE FUNCTION, WHICH MAKES CHANGING GAME MODES IMPOSSIBLE ONCE CREATED!!
	
	--[[ 4-21-22 THEY REPLACED THIS TAB!!!
	--OKAY THE GAME MODE SETTINGS AUTOMATICALLY CHANGE. BUT I WANT THE WORLD SETTINGS TO CHANGE TOO...
	--CHANGE THE WORLD CUST TAB TOO
	WorldCustTab.OnChangeGameMode = function(self, gamemode)
		--2-4-20 OKAY, SINCE THIS CRASHES OUR GAME AFTER ENABLING THE MOD ONCE, LETS TRY AND SOLVE THAT
		self.allowEdit = true --I THINK THIS SPECIFIC VALUE SKIPS OVER THE ASSERT VALUE. LETS JUST TURN IT BACK WHEN DONE
		--4-3-20 OH I GUESS HAVING THIS AS FALSE WAS ALSO SCREWING IT UP IF CREATING A NEW WORLD FROM SCRATCH
		
		--SKIP ALL THAT NONSENSE. LETS JUST CUT STRAIGHT TO THE CHASE
		self:LoadPreset("GM_SMASHUP")  -- GENTLEMEN... WE HAVE LIFTOFF >:3   

		--OH, EXCEPT THIS PART. WE DO WANT TO REMOVE THE CAVES (if we did want to allow caves (shared lag) in the future, consider uncommenting the above version)
		self:RemoveMultiLevel(2) --WOW THAT WAS EASY
		self:Refresh()
		self.allowEdit = true --2-4-20
	end
	--IF THE USER FLIPS THIS MOD ON AND OFF, THE GAME SETTING IS LEFT AT ENDLESS MODE IN THE LIGHTS-OUT PRESET... BUT YOU KNOW WHAT, THATS CLOSE ENOUGH FOR ME. IM HAPPY WITH THIS
	]]
	
	
	
	--4-21-22 YOU LITTLE SNEAK... YOU WENT AND CHANGED THE WIDGET FILE ON ME. OKAY, LETS SET THIS UP AGAIN.
	local WorldSettingTab = require("widgets/redux/worldcustomizationtab") --THINK ILL BORROW THIS TOO
	--I'M JUST GONNA COPY WHAT I HAD FOR THE WORLDCUSTTAB. THIS VERSION SEEMS TO WORK MOSTLY THE SAME
	WorldSettingTab.OnChangeGameMode = function(self, gamemode)
		-- self.allowEdit = true --THIS DOESN'T EXIST IN THE NEW VERSION, SO IM TAKING IT OUT
		
		--SKIP ALL THAT NONSENSE. LETS JUST CUT STRAIGHT TO THE CHASE
		self:LoadPreset("GM_SMASHUP")  -- GENTLEMEN... WE HAVE LIFTOFF >:3   

		--OH, EXCEPT THIS PART. WE DO WANT TO REMOVE THE CAVES (if we did want to allow caves (shared lag) in the future, consider uncommenting the above version)
		self:RemoveMultiLevel() --NEW VERSION DOESN'T PASS IN ANY ARGUMENTS
		self:Refresh()
	end
	
	
	
	
	
	local CurrentScreen = GLOBAL.TheFrontEnd:GetActiveScreen()
	if CurrentScreen and CurrentScreen.server_settings_tab then --and CurrentScreen.server_settings_tab.game_mode.spinner.enabled then
		-- print("SERVER SCREEN ACTIVE", GLOBAL.GetGameModesSpinnerData(GLOBAL.ModManager:GetEnabledServerModNames()))
		CurrentScreen.server_settings_tab.game_mode.spinner:SetOptions(GLOBAL.GetGameModesSpinnerData(GLOBAL.ModManager:GetEnabledServerModNames()))
		CurrentScreen.server_settings_tab.game_mode.spinner:SetSelected("smashup")
        CurrentScreen.server_settings_tab.game_mode.spinner:Changed()
        -- CurrentScreen.server_settings_tab.game_mode.spinner:Disable() --ACTUALLY, I'LL LEAVE THE SPINNER ENABLED. SINCE THIS MOD MIGHT NOT DISABLE PROPERLY
		--CAN I SWITCH MY WORLD SETTINGS TOO?
		--CurrentScreen.server_settings_tab.world_tabs[1]:LoadPreset("GM_SMASHUP") --NOPE LOL
	end
	
end