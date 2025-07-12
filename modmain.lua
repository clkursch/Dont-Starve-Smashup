--[[A quick note:
Feel free to reference or copy pieces of this mod.
But please don't reupload the entire mod without my permission.
thnx~

If you're here to take a look through the code, I apologize in advance for the huge mess.

I started this project in 2016 back when I was very new to coding and had almost no idea what I was doing. 
Many early parts of this mod are littered with unused functions, bizarre and inefficient logic, poor coding practices, and peppered with nonsensical comments with the spelling skills of an 8th grader. I've learned a lot since then and I promise I’m not as bad anymore.
]]


PrefabFiles = {
	"anchor", "background", "hitsphere", "cameraprefab", "fight_fx", "basicprojectile", 
	"newwilson", "newwoodie", "newwicker", "newmaxwell", "newwes", "spectator2", "punchingbag", "roguehitboxer", "lightsensor", "spiderfighter", "spiderfightereggsack", "spiderfighter_queen",
	 "stageprops", "spider_player",
}

Assets = {
	
	--12/16/18 --AW YEA, CUSTOM SOUNDS BABY
	Asset("SOUNDPACKAGE", "sound/smash_sounds.fev"),
	Asset("SOUND", "sound/smash_sounds_bank00.fsb"),
	
	--Asset( "ANIM", "anim/spritertestanim1.zip" ),
	Asset( "IMAGE", "images/avatars/avatar_spider_warrior.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_spider_warrior.xml" ),
	
	--8-26-20 --THESE IN-GAME ANIMS ARE STORED IN A PLACE THAT ONLY ALLOWS FRONTEND ACCESS. COPYING THEM INTO MY IMAGES FOLDER ALLOWS THEM TO BE ACCESSED ANYWHERE
    Asset("ATLAS", "images/saveslot_portraits.xml"),
    Asset("IMAGE", "images/saveslot_portraits.tex"),
	
	--9-28-20 ABOUT TIME WE MADE A BETTER ONE
	Asset("ANIM", "anim/status_shield.zip"),
	
}




local require = GLOBAL.require
GLOBAL.require( 'debugkeys' )
GLOBAL.require("strings")

GLOBAL.ISGAMEDST = true --10-19-17 ITS ABOUT TIME. REUSEABLE
--4-1-19 NO MORE FUMBLING AROUND WITH THESE IN VARIOUS COMPONENTS
-- GLOBAL.VISIBLEHITBOXES =  false
-- GLOBAL.VISIBLEHURTBOXES = false
--HANDLED BY MOD SETTINGS NOW


--CUSTOM SOUND AND SOUND CHANGES
--LETS SEE IF THIS IS STILL A THING IN DST
RemapSoundEvent( "dontstarve/creatures/krampus/kick_whoosh", "smash_sounds/remaps/kick_woosh" )
RemapSoundEvent( "dontstarve/wilson/attack_whoosh", "smash_sounds/remaps/attack_woosh" )
RemapSoundEvent( "dontstarve/wilson/attack_firestaff", "smash_sounds/remaps/attack_firestaff" )

--GOOD LORD PLEASE GO AWAY
RemapSoundEvent( "dontstarve/common/together/spawn_vines/spawnportal_idle_LP", "sound_mod_tutorial/remaps/AND_NEVER_COME_BACK" )
RemapSoundEvent( "dontstarve/common/together/spawn_vines/spawnportal_idle", "sound_mod_tutorial/remaps/EVER" )
--DUSK AS WELL.
RemapSoundEvent( "dontstarve/music/music_dusk_stinger", "empty" )

GLOBAL.AIDEBUGPRINT = false --1-16-22



--1-12-22 THIS IS ONE OF THE DUMBEST THINGS I HAVE EVER TRIED THAT WORKED
GLOBAL.GLOBEREF = GLOBAL


--ADDING MOD CHARACTER FILES

GLOBAL.STRINGS.NAMES.NEWWILSON = "newwilson"
GLOBAL.STRINGS.CHARACTER_NAMES.newwilson = "Wilson" --THE NAME THAT SHOWS ON THE CHARACTER SELECT SCREEN
GLOBAL.STRINGS.CHARACTER_QUOTES.newwilson = "avatar_wilson.tex" --TELLS WHICH IMAGE THE SELECT SCREEN SHOULD PUT THE ICON AS
AddModCharacter("newwilson")
--8-31-20 TESTING A NEW METHOD FOR SKINS
GLOBAL.NEWWILSON_SKINS = {"newwilson", "newwilsonblue", "newwilsongreen", "newwilsonpurple"}
-- GLOBAL.STRINGS.NEWWILSON_SKINS = {"newwilson", "newwilsonblue", "newwilsongreen", "newwilsonpurple"}


GLOBAL.STRINGS.NAMES.NEWWOODIE = "newwoodie"
GLOBAL.STRINGS.CHARACTER_NAMES.newwoodie = "Woodie"  
GLOBAL.STRINGS.CHARACTER_QUOTES.newwoodie = "avatar_woodie.tex"
AddModCharacter("newwoodie")
GLOBAL.NEWWOODIE_SKINS = {"newwoodie", "newwoodieskin", "newwoodiecyan", "newwoodiegrey"}




GLOBAL.STRINGS.NAMES.NEWWICKER = "newwicker"
GLOBAL.STRINGS.CHARACTER_NAMES.newwicker = "Wickerbottom"  
GLOBAL.STRINGS.CHARACTER_QUOTES.newwicker = "avatar_wickerbottom.tex" --TELLS WHICH IMAGE THE SELECT SCREEN SHOULD PUT THE ICON AS
AddModCharacter("newwicker")
GLOBAL.NEWWICKER_SKINS = {"newwickerbottom", "newwickerbottomskin", "newwickerbottomgrey", "newwickerbottomblack"}


GLOBAL.STRINGS.NAMES.NEWMAXWELL = "newmaxwell"
GLOBAL.STRINGS.CHARACTER_NAMES.newmaxwell = "Maxwell"  
GLOBAL.STRINGS.CHARACTER_QUOTES.newmaxwell = "avatar_waxwell.tex" --TELLS WHICH IMAGE THE SELECT SCREEN SHOULD PUT THE ICON AS
AddModCharacter("newmaxwell")
GLOBAL.NEWMAXWELL_SKINS = {"newmaxwell", "newmaxwellskin", "newmaxwellbrown"} --, "newmaxwellblue", "newmaxwellred"}
--Maxwell only gets 3 skins right now because his reskins are a lot of work >:(


--5-21-20 WELCOME HOME SMASHTEMPLATE, AKA WES
GLOBAL.STRINGS.NAMES.NEWWES = "newwes"
GLOBAL.STRINGS.CHARACTER_NAMES.newwes = "Wes"
GLOBAL.STRINGS.CHARACTER_QUOTES.newwes = "avatar_wes.tex"
AddModCharacter("newwes")
GLOBAL.NEWWES_SKINS = {"newwes", "newwesblue", "newwesgreyscale", "newwesyellow" }



--2-4-20 PLAYABLE SPIDER CHARACTER!!
GLOBAL.STRINGS.NAMES.SPIDER_PLAYER = "spider_player"
GLOBAL.STRINGS.CHARACTER_NAMES.spider_player = GLOBAL.STRINGS.NAMES.SPIDER_WARRIOR  --"Spider Warrior"  
GLOBAL.STRINGS.CHARACTER_QUOTES.spider_player = "avatar_spider_warrior.tex" --TELLS WHICH IMAGE THE SELECT SCREEN SHOULD PUT THE ICON AS
-- GLOBAL.STRINGS.CHARACTER_QUOTES.spider_player = "NOTPLAYABLE" --LETS DISABLE HIM UNTIL HE'S FINISHED
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.spider_player = "images/avatars/avatar_spider_warrior.xml" --NEW VARIABLE FOR CUSTOM AVATAR XML FILES
AddModCharacter("spider_player")
GLOBAL.SPIDER_PLAYER_SKINS = {"spider_warrior_build", "spider_fighter_build", "spider_harold", "spider_baby" } --JUST THIS ONE FOR NOW. MAYBE WE'LL ADD MORE LATER


GLOBAL.STRINGS.NAMES.SPECTATOR2 = "spectator2"
GLOBAL.STRINGS.CHARACTER_NAMES.spectator2 = "Spectate" 
-- GLOBAL.STRINGS.CHARACTER_QUOTES.spectator2 = "NOTPLAYABLE" --"NOTPLAYABLE" TELLS THE SELECT SCREEN NOT TO INCLUDE IT'S ICON AS A SELECTABLE CHARACTER
GLOBAL.STRINGS.CHARACTER_QUOTES.spectator2 = "avatar_ghost_unknown.tex" --ACTUALLY, LETS MAKE IT SELECTABLE, BUT THE MENU WILL HANDLE THIS TO CHOOSE ANOTHER RANDOM ONE
AddModCharacter("spectator2")


GLOBAL.STRINGS.NAMES.RANDOM = "random"
GLOBAL.STRINGS.CHARACTER_NAMES.random = GLOBAL.STRINGS.CHARACTER_NAMES.random --12-3-21 THIS WILL AUTO TRANSLATE BETTER --"Random" 
GLOBAL.STRINGS.CHARACTER_QUOTES.random = "avatar_unknown.tex"
AddModCharacter("random")


--OH YEA AND FOR EACH MOD CHARACTER, YOU ALSO NEED TO PASTE ANY OLD "avatar_CHARA-NAME" IN THE IMAGES/AVARARS FOLDER. JUST TO EXIST SO IT DOESNT CRASH




--10-15-17 SERVER SETTINGS!
GLOBAL.TUNING.SMASHUP = {}
GLOBAL.TUNING.SMASHUP.MATCHSIZE = (GetModConfigData("MatchSize"))
GLOBAL.TUNING.SMASHUP.MATCHLIVES = (GetModConfigData("MatchLives"))
GLOBAL.TUNING.SMASHUP.MATCHTIME = (GetModConfigData("MatchTime"))
--5-20-20 A DEFINITIVE "MODE" FOR THE ENTIRE MOD (DEBUG - DEV- DEMO - ETC)
GLOBAL.TUNING.SMASHUP.MODMODE = (GetModConfigData("ModMode"))
GLOBAL.TUNING.SMASHUP.QUECYCLE = (GetModConfigData("QueCycle"))
GLOBAL.TUNING.SMASHUP.SERVERGAMEMODE = (GetModConfigData("ServerGameMode"))
GLOBAL.TUNING.SMASHUP.BONUSFIGHTER = (GetModConfigData("BonusFighter"))
GLOBAL.TUNING.SMASHUP.ENABLELOCALPLAY = (GetModConfigData("EnableLocalPlay"))
GLOBAL.TUNING.SMASHUP.LANGUAGE = (GetModConfigData("Language"))

--1-19-22
GLOBAL.TUNING.SMASHUP.TEAMS = 1
GLOBAL.TUNING.SMASHUP.TEAMSELECT = 1
GLOBAL.TUNING.SMASHUP.TEAMSSIZECR = 1
GLOBAL.TUNING.SMASHUP.OPENTEAMFILL = 1


GLOBAL.trainbehavior = "idle" --"evade"


modimport 'scripts/localization_smashup.lua'

local visibox = GetModConfigData("VisibleBoxes") --VALUE 1-5  
GLOBAL.VISIBLEHITBOXES =  false --BOTH OFF BY DEFAULT (1)
GLOBAL.VISIBLEHURTBOXES = false
GLOBAL.VISIBLEMISCBOXES = false


if visibox == 2 then
	GLOBAL.VISIBLEHITBOXES =  true
elseif visibox == 3 then
	GLOBAL.VISIBLEHURTBOXES = true
elseif visibox == 4 then
	GLOBAL.VISIBLEHITBOXES =  true
	GLOBAL.VISIBLEHURTBOXES = true
elseif visibox == 5 then
	GLOBAL.VISIBLEHITBOXES =  true
	GLOBAL.VISIBLEHURTBOXES = true
	GLOBAL.VISIBLEMISCBOXES = true
end


local STRINGS = GLOBAL.STRINGS

--ADDS DEVELOPER KEYS. (CRTL-R TO RELOAD SCRIPTS FROM IN GAME)
if GLOBAL.TUNING.SMASHUP.MODMODE == 2 then
	GLOBAL.CHEATS_ENABLED = true
end

GLOBAL.TUNING.MODNAME = modname --OOOO SNEAKY >:3c FOR USE IN FILES OUTSIDE OF MODMAIN

--12-22-21 CAN I JUST GET RID OF THIS FROM HERE? IT'S A CONSTANT, BUT MAYBE IT WILL WORK...
GLOBAL.CONTROL_TOGGLE_WHISPER = 1
GLOBAL.CONTROL_TOGGLE_SLASH_COMMAND = 1 --AND PEOPLE KEEP MASHING THIS ONE TOO

--1-6-22 SETTING THIS TO 0 WILL HOPEFULLY BE ENOUGH TO CRIPPLE THE "PLANTREGROWTH.LUA" COMPONENT
GLOBAL.TUNING.REGROWTH_TIME_MULTIPLIER = 0


require("components/map")
--8-31-21 NEW CUSTOM FUNCTION TO GRAB SPECIFIC AXIS OF THE TILE OFFSET FROM STAGE GENERATION
function GLOBAL.Map:GetTileAxisOffset(axis)
	local x, y, z = GLOBAL.TheWorld.Map:GetTileCenterPoint(0, 0, 0)
	
	if axis and axis == "z" then
		return z
	else --if axis == "x"
		return x - 2 --SUBTRACT 2 TO GET TO THE EDGE BECAUSE THE STAGE IS AN EVEN NUMBER OF TILES
	end
end 



--ANOTHER VERSION!!! THIS ONE WITH TWO STAGES OF INITIATION, ONE TO CREATE ANCHOR, AND ONE TO REFRESH
local function PostInitStuffStage( inst )
	if GLOBAL.TheWorld.ismastersim then
        
		local anchor = GLOBAL.TheSim:FindFirstEntityWithTag("anchor")
		
		if not anchor then
			print("ANCHOR ABOUT TO BE SPAWNED RIGHT NOW")
			local anchor = GLOBAL.SpawnPrefab("anchor")
			
			--3-9-19 HEY GUESS WHAT?
			GLOBAL.TheNet:SetDefaultGameMode("smashup") --THAT'S RIGHT. MADE IT A GAME MODE. SETTINGS ARE SET IN MODINFO
			--AND DIDN'T EVEN HAVE TO INTRUSIVELY TEAR INTO THE GAMEMODES.LUA SCRIPT TO PERMINANTLY SET THESE VALUES B)
			
			--3-3-19 -OK BUT DEDICATED SERVERS DONT WAIT. PLAYERS JOIN INTO A BROKEN WORLD IF THERE IS A SINGLE FRAME OF DELAY BEFORE THE STAGE IS CREATED
			if GLOBAL.TheNet:IsDedicated() then
				--IS THIS REALLY A GOOD IDEA TO DELETE ALL ENTITIES???--
				local ents = GLOBAL.TheSim:FindEntities(0, 0, 0, 200, {}, {"player", "anchor", "portal"})
				for k, v in pairs(ents) do
					print("AND YOU GET DESTROYED!!!", v)
					v:Remove()
				end
				
				--THEN MOVE THE PORTAL OUT OF THE WAY
				local portal = GLOBAL.TheSim:FindFirstEntityWithTag("portal")
				-- local tileoffset = 0
				-- if GLOBAL.TheWorld.Map:GetTileCenterPoint(0, 0, 0) == 0 then
					-- tileoffset = 2
				-- end
				local tileoffset = GLOBAL.TheWorld.Map:GetTileAxisOffset("x") --8-31-21 CLEANER
				portal.Transform:SetPosition( (tileoffset), 0, (- 3) )
			end
			
			
			anchor:DoTaskInTime(0.2, function()
			
				--1-1-2018 TO FIX THE STAGE GENERATION TILE OFFSET BUG, WE NEED TO FIRST CHECK WHERE ON THE TILE WE HAVE SPAWNED, AND ADJUST ACCORDINGLY.
				local tileoffset = GLOBAL.TheWorld.Map:GetTileAxisOffset("x")
				
				local portal = GLOBAL.TheSim:FindFirstEntityWithTag("portal")
				portal.Transform:SetPosition( 0, 0, 0 ) --8-5-17 SETTING THE PORTAL POSITION TO 0,0,0 SO THAT BACKROUND LAYER IS CONSISTANT
				local x, y, z = portal.Transform:GetWorldPosition()
				--CAREFUL NOW... AT 0,0,0, ALL ORPHANED INCORRETLY SPAWNED ITEMS WILL END UP RIGHT IN THE MIDDLE. SO !!DONT SCREW UP!!
				
				--11-23-20 ANCHOR POSITION IS SLIGHTLY DIFFERENT ON DEDICATED SERVERS AND MAKES Z AXIS HITBOX LOCKING BREAK. 
				--SO IM FORCING THE ANCHOR TO A Z AXIS OF 0 SO THAT WE CAN STILL SAFELY SPAWN ALL HITBOXES AT 0 WITHOUT MESSING EVERYTHING UP.
				-- z = 0 --THIS WHOLE RELIANCE ON ANCHOR IS REALLY STUPID. BUT IF ANYTHING, THE POSITIONAL RELIANCE IS THE LEAST STUPID PART OF THE WHOLE THING.
				--8-31-21 TAKE Z TILE OFFSET INTO ACCOUNT
				z = GLOBAL.TheWorld.Map:GetTileAxisOffset("z") --ALSO, SINCE ANCHOR IS NOW CENTERED, WE SHOULD BE ABLE TO GRAB POS FROM ANCHOR 
				x = GLOBAL.TheWorld.Map:GetTileAxisOffset("x")
				
				-- anchor.Transform:SetPosition( x+1.5, y, z ) --DST11 ADDING 1.5 TO THE X VALUE SO THAT THE EDGES CAN MATCH UP WITH THE STAGE EDGES
				anchor.Transform:SetPosition( x, 0, z ) --8-31-21 THE HECK WAS I DOING?
				local x2, y2, z2 = anchor.Transform:GetWorldPosition()
				print("SETTING THE ANCHOR'S POSITION", x2, y2, z2)
				
				--IS THIS REALLY A GOOD IDEA TO DELETE ALL ENTITIES???--
				local ents = GLOBAL.TheSim:FindEntities(x, y, z, 200, {}, {"player", "anchor", "portal"})
				for k, v in pairs(ents) do
					-- print("AND YOU GET DESTROYED!!!", v)
					v:Remove()
				end
				
				anchor.components.gamerules:CreateStage()
				anchor:AddTag("pregeneration") --1-1-2018 FOR SMASHGAMELOGIC TO TELL PLAYERS THAT THE STAGE NEEDS TO BE REGENERATED
				
				--1-2-18 -CHECK TO MAKE SURE WE ARENT INVADING ON AN EXISTING WORLD, OR ELSE WE ARE ABOUT TO DESTROY IT
				if not GLOBAL.TheNet:IsDedicated() then
					if GLOBAL.ThePlayer then 
						GLOBAL.assert((GLOBAL.ThePlayer.prefab == "spectator" or GLOBAL.ThePlayer.prefab == "spectator2"), "__SMASHUP CANNOT BE LAUNCHED IN AN ALREADY EXISTING WORLD. PLEASE CREATE A NEW WORLD")
					end
				end
				
				--1-1-18 -NOW SAVE AND RESTART THE SERVER TO FINISH GENERATING THE STAGE
				anchor:DoTaskInTime(5, function()
					if not GLOBAL.TheNet:IsDedicated() then --A SECOND CHECK IN CASE THE FIRST ONE FAILED
						GLOBAL.assert((GLOBAL.ThePlayer.prefab == "spectator" or GLOBAL.ThePlayer.prefab == "spectator2"), "__SMASHUP CANNOT BE LAUNCHED IN AN ALREADY EXISTING WORLD. PLEASE CREATE A NEW WORLD")
					end
				
					GLOBAL.TheWorld:PushEvent("ms_save")
				end)
				
				anchor:DoTaskInTime(8, function()
					GLOBAL.c_reset() --THIS CLOSES AND RE-OPENS THE SERVER WITHOUT KICKING PLAYERS OUT TO FINISH GENERATING THE STAGE
				end)
				
				
				-- AND THEN MOVE THIS GOSH DANG PORTAL OUT OF THE WAY
				portal.Transform:SetPosition( (x+tileoffset) , y, (z - 3) )
			end)
			
		else
		
			--9-6-17 FOR...TRAFFIC ROCKS. DELETES THEM ON NEW SERVER STARTUP.
			local trafficrocks = GLOBAL.TheSim:FindEntities(0, 0, 0, 20, {"boulder"})
			for i, v in ipairs(trafficrocks) do
				v:Remove() 
			end
		
			--THIS RECREATES THE STAGE EVERY TIME
			anchor = GLOBAL.TheSim:FindFirstEntityWithTag("anchor")
			anchor.components.gamerules:CreateStage()
			
		end
		
	else
	
		--8-31-17 THIS CREATES JUST THE STAGE FOR THE CLIENT SIDE SO THEY DON'T SINK INTO THE FLOOR
		local anchor2 = GLOBAL.SpawnPrefab("nitre") --AH, A CLASSIC
		anchor2:AddComponent("gamerules")
		anchor2:AddTag("anchor2")
		anchor2.Transform:SetPosition( 0, 0, 0 )
		anchor2.components.gamerules:ReReCreateStage()
		-- anchor2.components.gamerules:CreateStage()
		anchor2.AnimState:SetMultColour(0,0,0,0) --OKAY WE SHOULDNT SEE IT THOUGH
		GLOBAL.TheWorld.Map:SetUndergroundFadeHeight(0) --5-21-20 AND FIX THIS THE CLIFFSIDES FOR CLIENTS TOO (THANKS HORNETE!)
		--OH BUT IT DOESNT WORK :/ FOR CLIENTS
    end	
	
	--9-29-21 IF CAVES EXIST, THEY WILL TRY AND RUN THIS. LETS NOT.
	if GLOBAL.TheWorld:HasTag("cave") and not GLOBAL.TheWorld:HasTag("run_anyways") then --A CHEEKY WORKAROUND FOR CLEVER MODDERS
		return end
	
	--12-3-17 OH MY GOD, I CANT BELEIVE I FOUND IT. THE VARIABLE THAT CHANGES THE HEIGHT OF THE WAVES. THIS CHANGES EVERYTHING -REUSEABLE
	-- GLOBAL.TheWorld.WaveComponent:SetWaveParams(12, 1, 1)  --( x-stretch , z-spacing , height)
	-- GLOBAL.TheWorld.WaveComponent:SetWaveSize(200, 3)   -- (length , y-stretch)
	
	--5-13-20  MAYBE MAKE THEM BELOW THE STAGE? --THAT LOOKS A LITTLE BETTER I GUESS
	GLOBAL.TheWorld.WaveComponent:SetWaveParams(12, 0.5, -4)  --( x-stretch , z-spacing , height)
	GLOBAL.TheWorld.WaveComponent:SetWaveSize(200, 2)   -- (length , y-stretch)
	GLOBAL.TheWorld.WaveComponent:Init(100, 0, 0)
	
	--4-3-20 OH SNAP, TAKE A LOOK AT LAVAARENA.LUA   WHERE HAS THAT BEEN ALL MY LIFE
	--GOSH REALLY HOPE THIS ALL APPLIES CLIENTSIDE TOO, BECAUSE I WONT BE ABLE TO TEST IT FOR A WHILE

    --Dedicated server does not require these components
    --NOTE: ambient lighting is required by light watchers
    if not GLOBAL.TheNet:IsDedicated() then
        --GLOBAL.TheWorld.WaveComponent:SetWaveParams(13.5 * scale, 2.8 * (scale - .15), -5) -- wave texture u repeat, forward distance between waves, world y-axis position
        --GLOBAL.TheWorld.WaveComponent:SetWaveSize(80 * scale, 3.5 * scale)                 -- wave mesh width and height
        --GLOBAL.TheWorld.WaveComponent:SetWaveMotion(.3, .5, .35)                           -- speed, horizontal travel, vertical travel
		GLOBAL.TheWorld.WaveComponent:SetWaveMotion(.7, .9, .5)   --OOO~ DONT MIND IF I DO 

        -- GLOBAL.TheWorld.WaveComponent:SetWaveTexture(resolvefilepath("images/lavaarena_wave.tex"))
		GLOBAL.TheWorld.WaveComponent:SetWaveTexture("images/wave.tex") --LETS JUST GO WITH THE NORMAL ONE
        --GLOBAL.TheWorld.components.ambientsound:SetReverbPreset("lava_arena")
        GLOBAL.TheWorld.components.ambientsound:SetWavesEnabled(true)
	end
	
end

AddSimPostInit( PostInitStuffStage )


--4-10 WOW. NEWWEST UPDATE REMOVED THE PORTAL TAG FROM THE MULTIPLAYER PORTAL. NOW I GOTA PUT IT BACK ON
AddPrefabPostInit("multiplayer_portal", function(inst) 
	inst:AddTag("portal")
	inst:AddTag("spawnlight") --1-6-22 HAH! NOW THERES ALREADY A "SPAWNLIGHT" IN THE AREA. CAN'T SPAWN ANOTHER ONE NOW
	-- inst.SoundEmitter:KillAllSounds()  --12-18-18 GOD THIS THING IS NOISY
	inst.AnimState:SetMultColour(0,0,0,0) --MAKING IT INVISIBLE FOR NOW 9-25-20
	--OK THERES A REALLY WEIRD VISUAL BUG WITH IT THOUGH THAT MAKES IT'S OUTLINE VISIBLE BEHIND VISIBLE HITBOXES
	inst:Hide() --OK THAT WORKS
end)



--9-7-17 --TAKING COMPONENTS FROM "THEHUNT" AND ATTEMPTING TO MAKE THEM WORK WITH THIS
function SmashSetup(inst)
	print("### SmashSetup ###")
	inst.hunt_time = 120000
	inst:AddComponent("SmashGameLogic")
end
--Currently there is no support for a generic world_network postinit.
AddPrefabPostInit("cave_network", SmashSetup) --UM? FOR CAVES? ARE YOU SURE?
AddPrefabPostInit("forest_network", SmashSetup)





--9-19-17 OKAY, MAYBE THIS WILL HELP INSTEAD
GLOBAL.Reincarne = "spectator2" --EACH CLIENT WILL SET THEIR OWN REINCARNE VIA PLAYER SELECT BUTTONS. 
--THIS VARIABLE IS ALSO CHANGED IN LOBBYSCREEN, SO IF YOU CHANGE IT HERE, CHANGE IT THERE TOO
--WOW... TURNS OUT THE BEST SOLUTION WAS THE SHORTEST ONE. LIKE 3 TOTAL LINES OF CODE.
--10-14-21 THIS ONE WILL DETERMINE WHAT PREFAB "SPECTATOR" ACTUALLY SPAWNS IN AS (we're getting rid of the spectator prefab. it was basically just a copy of wilson)
GLOBAL.DefaultFighter = "spectator2" --"newwilson"  --THIS MAKES IT EASIER FOR MODDERS TO SET THE CHARACTER TO SOMETHING DIFFERENT ON THE FLY


--5-26-20 HEY IS THIS A THING I CAN ADD HERE? I LIKE THE CURLYWINDOW (SUE ME(pls dont)) BUT WANT THE BUTTONS A BIT HIGHER
--[[ EHH... MAYBE THIS ISNT WORTH IT FOR HOW RARELY IT WOULD BE USED
local NineSlice = require "widgets/nineslice"
local TEMPLATES = require "widgets/redux/templates"

-- function TEMPLATES.ScreenRoot(name)
    -- local root = Widget(name or "root")
    -- root:SetVAnchor(ANCHOR_MIDDLE)
    -- root:SetHAnchor(ANCHOR_MIDDLE)
    -- root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    -- return root
-- end

function TEMPLATES.CurlyWindow2(sizeX, sizeY, title_text, bottom_buttons, button_spacing, body_text)
    --DECLARE SOME VARIABLES
	local ANCHOR_TOP = GLOBAL.ANCHOR_TOP
	local ANCHOR_MIDDLE = GLOBAL.ANCHOR_MIDDLE
	local ANCHOR_BOTTOM = GLOBAL.ANCHOR_BOTTOM
	
	
	local w = NineSlice("images/dialogcurly_9slice.xml")
    local top = w:AddCrown("crown-top-fg.tex", ANCHOR_MIDDLE, ANCHOR_TOP, 0, 68)
    local top_bg = w:AddCrown("crown-top.tex", ANCHOR_MIDDLE, ANCHOR_TOP, 0, 44)
    top_bg:MoveToBack()

    -- Background overlaps behind and foreground overlaps in front.
    local bottom = w:AddCrown("crown-bottom-fg.tex", ANCHOR_MIDDLE, ANCHOR_BOTTOM, 0, -14)
    bottom:MoveToFront()

    -- Ensure we're within the bounds of looking good and fitting on screen.
    sizeX = math.clamp(sizeX or 200, 190, 1000)
    sizeY = math.clamp(sizeY or 200, 90, 500)
    w:SetSize(sizeX, sizeY)
    w:SetScale(0.7, 0.7)

    if title_text then
        w.title = top:AddChild(Text(GLOBAL.HEADERFONT, 40, title_text, GLOBAL.UICOLOURS.GOLD_SELECTED))
        w.title:SetPosition(0, -50)
        w.title:SetRegionSize(600, 50)
        w.title:SetHAlign(ANCHOR_MIDDLE)
        if JapaneseOnPS4() then
            w.title:SetSize(40)
        end
    end

    if bottom_buttons then
        -- If plain text widgets are passed in, then Menu will use this style.
        -- Otherwise, the style is ignored. Use appropriate style for the
        -- amount of space for buttons. Different styles require different
        -- spacing.
        local style = "carny_long"
        if button_spacing == nil then
            -- 1,2,3,4 buttons can be big at 210,420,630,840 widths.
            local space_per_button = sizeX / #bottom_buttons
            local has_space_for_big_buttons = space_per_button > 209
            if has_space_for_big_buttons then
                style = "carny_xlong"
                button_spacing = 320
            else
                button_spacing = 230
            end
        end
        local button_height = 50
        local button_area_width = button_spacing / 2 * #bottom_buttons
        local is_tight_bottom_fit = button_area_width > sizeX * 2/3
        if is_tight_bottom_fit then
            button_height = 60
        end

        -- Does text need to be smaller than 30 for JapaneseOnPS4()?
        w.actions = bottom:AddChild(Menu(bottom_buttons, button_spacing, true, style, nil, 30))
        w.actions:SetPosition(-(button_spacing*(#bottom_buttons-1))/2, button_height) 

        w.focus_forward = w.actions
    end

    if body_text then
        w.body = w:AddChild(Text(GLOBAL.CHATFONT, 28, body_text, GLOBAL.UICOLOURS.WHITE))
        w.body:EnableWordWrap(true)
        w.body:SetPosition(0, 20)
        local height_reduction = 0
        if bottom_buttons then
            height_reduction = 30
        end
        w.body:SetRegionSize(sizeX, sizeY - height_reduction)
        w.body:SetVAlign(ANCHOR_MIDDLE)
    end

    return w
end
	]]
	





--TRYING SOME STUFF THE MUSHA MOD USES TO KEEP KEYHANDLERS SILENT WHEN TYPING IN CHAT?
--VERY CLEVER!

--THIS CHANGES THE CHAT SCREEN SO THAT THE GAME IS CONSIDERED PAUSED WHILE TYPING
local function ChatPostConstruct(inst)
	function inst:OnBecomeActive()
		GLOBAL.SetPause(true) --BASICALLY JUST ADDED THIS, TELLING THE CLIENT THE GAME IS PAUSED, SO KEYPRESSES WONT ACTIVATE
		--!! ISPAUSED() JUST STRAIGHT UP DOES NOT WORK IN DEDICATED SERVERS. SERVER WILL ALWAYS RETURN CLIENTS AS PAUSED. ALWAYS.
		inst._base.OnBecomeActive(inst)
		inst.chat_edit:SetFocus()
		inst.chat_edit:SetEditing(true)
		GLOBAL.TheFrontEnd:LockFocus(true)
		--5-24-20 LET PLAYERS KNOW WHEN THEY ARE TYPING SOMETHING
		-- GLOBAL.ThePlayer.components.talker:Say(". . .", 8, true)
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["speechpreview"], " ")
	end

	function inst:OnBecomeInactive()
    	GLOBAL.SetPause(false)
		-- GLOBAL.ThePlayer:RemoveTag("lockcontrols") --LETS TRY THIS INSTEAD
    	inst._base.OnBecomeInactive(self)
    	if inst.runtask ~= nil then
        	inst.runtask:Cancel()
        	inst.runtask = nil
    	end
	end
	
	--1-11-22 CHAT IS RIGHT IN OUR WAY >:( LETS SEE IF WE CAN MOVE IT DOWN A BIT.
	-- DOINIT() SHOULD HAVE RUN BY NOW, SO WE SHOULD BE ABLE TO JUST MOVE THE ROOT, RIGHT?
	inst.root:SetPosition(-145.2, 30, 0)
	-- inst.chat_queue_root:SetPosition(-200,-100,0) --THIS ONE DONT DO ANYTHING
	inst:MoveToFront()
	-- inst.chat_queue_root:MoveToFront()
	-- inst.root:MoveToFront()
	
	return inst
end

AddClassPostConstruct("screens/chatinputscreen", ChatPostConstruct)



--9-26-20 HEY WELL I CAN AT LEAST GET RID OF THIS STUPID THING NOW
AddClassPostConstruct("widgets/controls", function(inst)
	inst.inv:Hide() --BUT IT KEEPS TURNING ITSELF BACK ON!
	--WELL THEN LETS CHANGE THAT...
	local old_showinv = inst.ShowCraftingAndInventory
	inst.ShowCraftingAndInventory = function(inst, ...) --ADDING INST TO REFERENCE SELF
		old_showinv(inst, ...)
		inst.inv:Hide() --HIDE IT AGAIN. ONLY HIDE IT. NEVER SHOW IT. EVER
		--FINALY! AFTER ALL THESE YEARS. I'VE KILLED IT
	end
	
	
	--AND YOU
	-- inst.networkchatqueue:SetPosition(-90,665,0)
	inst.chat_queue_root:SetPosition(-150,740,0)
	-- inst.chat_queue_root:MoveToFront()
	
	--1-27-22 --MOVE THE GIFT POPUP SO IT ISNT BEHIND OUR MENUS
	inst.item_notification:SetPosition(400, 150, 0) --115, 150, 0
end)



--1-26-22 SOMETHING TO TRY AND PREVENT THAT UGLY LOGGING OFF BUG WHERE U GET LOCKED WITH NO HUD.
AddClassPostConstruct("screens/redux/pausescreen", function(inst)
	-- local old_doconfirmquit = inst.doconfirmquit --NAH FORGET IT. WE AREN'T ALTERING THE OLD ONE, WE'RE REPLACING IT.
	inst.doconfirmquit = function(inst, ...) --ADDING INST TO REFERENCE SELF
		-- old_doconfirmquit(inst, ...)
		--INSTEAD OF PROMPTING "ARE YOU SURE?" JUST DO IT. NO QUESTIONS.
		SendModRPCToServer(MOD_RPC[modname]["gen_menu_handler"], "disconnecting")
		if not inst.popped_autopause then
            GLOBAL.SetAutopaused(false)
            inst.popped_autopause = true
        end
		--1-27-22 SET OUR FX LEVEL BACK TO WHAT WE HAD IT AT BEFORE WE QUIT.
		GLOBAL.TheMixer:SetLevel("set_music", GLOBAL.TUNING.SMASHUP.OLD_MUSIC_VOLUME)
		inst.parent:Disable()
		inst.menu:Disable()
		--inst.afk_menu:Disable()
		GLOBAL.DoRestart(true)
	end
end)



--2-1-22 DON'T LET PEOPLE CLICK "USE NOW" WHEN THEY UNBOX A NEW ITEM
AddClassPostConstruct("screens/giftitempopup", function(inst)
	local old_showmenu = inst.ShowMenu
	inst.ShowMenu = function(inst, ...) 
		--HIDE THE SECOND BUTTON IN THE MENU. THAT WOULD PROBABLY CAUSE BAD THINGS TO HAPPEN
		inst.disable_use_now = true --2-1-22 HUH! CONVENIENT
		old_showmenu(inst, ...)
	end
end)


AddClassPostConstruct("widgets/giftitemtoast", function(inst)
	
	inst.DisableClick = function(inst, ...) 
		--DO NOTHING
	end
	
	--LIKE THE DEFAULT, BUT CHECK FOR THE BACK BUTTON INSTEAD OF THE X BUTTON
	inst.CheckControl = function(inst, control, down, ...) 
		if inst.shown and down and inst.enabled and control == GLOBAL.CONTROL_MAP and GLOBAL.TheInput:ControllerAttached() then --CONTROL_CONTROLLER_ATTACK and
			-- self.owner.components.playercontroller:GetControllerAttackTarget() == nil then
			inst:DoOpenGift()
			return true
		end
	end
	
	--BUT TELL US THE REAL BUTTON
	local old_UpdateControllerHelp = inst.UpdateControllerHelp
	inst.UpdateControllerHelp = function(inst, ...) 
		old_UpdateControllerHelp(inst, ...)
		
		if inst.controller_help then -- CONTROL_CONTROLLER_ATTACK
			inst.controller_help:SetString(GLOBAL.TheInput:GetLocalizedControl(GLOBAL.TheInput:GetControllerID(), GLOBAL.CONTROL_MAP).." "..GLOBAL.STRINGS.UI.HUD.OPENGIFT)
        end
	end
	
	inst.DoOpenGift = function(inst, ...) 
		--SKIP ALL THOSE CHECKS AND BALANCES, JUST OPEN THE THING
		if not GLOBAL.TheWorld.ismastersim then
			GLOBAL.SendRPCToServer(GLOBAL.RPC.OpenGift)
			inst.owner:PushEvent("ms_opengift")
			print("GIB GIF")
		else
			inst.owner:PushEvent("ms_opengift") --THIS WAS THE ONLY WAY THIS WORKED
		end
	end
	
	inst.tab_gift:SetOnClick(function() 
		inst:DoOpenGift() 
	end)
	
	inst.owner:DoTaskInTime(0.3, function()
		inst:EnableClick()
	end)
end)



AddComponentPostInit("giftreceiver", function(self)
	function self:OpenNextGift()
		if self.giftcount > 0 then
			self.inst:PushEvent("ms_opengift")
		end
	end
end)





AddGlobalClassPostConstruct("stategraph", "StateGraphInstance", function(self)
	
	-- 12-30 OOOOH THIS IS A DANGEROUS GAME, CHANGING SUCH A HUGE FUNCTION LIKE THIS. 
	--BUT I REALLY NEED TO ADD SOMETHING THAT ACTIVATES ON STATE-END
	--WOOOOWWW I NEEDED NONE OF THIS. NEWSTATE WORKS FINE BUT EVENT HANDLERS RUN !AFTER! ONENTER FUNCTIONS RUN. ...WHY?!
	function self:GoToState(statename, params)
		-- print ("STOP CALLING ME", self.inst, statename) --4-3-19 ALRIGHT ALRIGHT, GIVE IT A BREAK FOR NOW
		local state = self.sg.states[statename]
		
		if not state then 
			print (self.inst, "TRIED TO GO TO INVALID STATE", statename)
			return 
		end

		self.prevstate = self.currentstate
		if self.currentstate ~= nil and self.currentstate.onexit ~= nil then 
			self.currentstate.onexit(self.inst)
		end
		
		
		--4-5-20 OK LETS TRY CLEARING ALL THE LAST STATES STUFF OUT FIRST
		self.timelineindex = nil
		-- self.inst.sg.currentstate.timeline[self.timelineindex].time = 0
		--self.currentstate.timeline = nil --NOT SURE HOW THIS WILL GO
		self.timeinstate = 0
		
		-- Record stats
		if GLOBAL.METRICS_ENABLED and self.inst == GLOBAL.ThePlayer and self.currentstate then --and not GLOBAL.IsAwayFromKeyBoard() then --@@DSTCHANGE@@
			local dt = GLOBAL.GetTime() - self.statestarttime
			self.currentstate.totaltime = self.currentstate.totaltime and (self.currentstate.totaltime + dt) or dt  -- works even if currentstate.time is nil
			-- dprint(self.currentstate.name," time in state= ", self.currentstate.totaltime) --THE HECK IS "DPRINT"???
		end
		
		self.statemem = {}
		self.tags = {}
		if state.tags then
			for i,k in pairs(state.tags) do
				self.tags[i] = true
			end
		end

		self.timeout = nil
		self.laststate = self.currentstate
		self.currentstate = state
		self.timeinstate = 0
		

		if self.currentstate.timeline ~= nil then
			self.timelineindex = 1
		else
			-- self.timelineindex = nil --4-5-20 SAY... DON'T WE 'ALWAYS' WANT TIMELINE INDEX TO START AT 1? WE DO WE EVEN HAVE AN OPTION FOR NIL??
			self.timelineindex = 1 --YEA LETS TRY THIS. ALWAYS START AT 1. WHAT COULD GO WRONG
		end
		
		self.timeinstate = 0
		
		
		--MOVING UP HERE
		if self.inst.components and self.inst.components.hitbox then
			self.inst.components.hitbox.lingerframes = 0  --TURNS OFF LINGERING FRAMES UPON EXITING STATE
			self.inst.components.hitbox:FinishMove()
			self.inst.components.hitbox:ResetMove()
			self.inst.components.hitbox:RemoveAllHitboxes() --1-9 AS PART OF HITBOXES 2.0
			if self.inst.components.hurtboxes then
				self.inst.components.hurtboxes:ResetTempHurtboxes() --12-11
			end
			
			if self.inst.components.launchgravity then --1-9
				self.inst.components.launchgravity.landinglag = nil
				
				if not self.inst.sg:HasStateTag("tryingtoblock") then --4-7 BC BUFFERING WHILE BLOCKING DIDNT WORK --OPTIMIZE?
					-- self.inst.components.stats:ClearKeyBuffer() --4-5
					--11-8-17- OKAY, NEW PLAN- WE NEED TO BE ABLE TO PRESS A KEY AND ENTER HIGHLEAP STATE WITHOUT CLEARING THE KEY BUFFER 
					-- print("SHOULD WE CLEAR IT?", self.currentstate, self.inst.components.stats.buffertick == 5)
					--IF IT HAS RECEIVED A BUFFERED INPUT RIGHT ON THE SAME FRAME, THEN.. --OH, AND IT CAND BE A SECOND BUFFERED JUMP. YEA, NO. 
					if (self.currentstate.name == "highleap" and self.inst.components.stats.buffertick == 5 and self.inst.components.stats.event ~= "jump") --then  --WAIT! ONE MORE CONDITION...
						or self.currentstate.name == "ll_medium_getup" --3-27-19 REUSEABLE  --LANDING LAG CAN BE SO SHORT, BUT IS FOLLOWED IMMEDIATLY BY IDLE, SO ALWAYS CUTS SHORT BUFFERED FOLLOWUPS
						or self.currentstate.name == "idle" --1-29-22 I GUESS THIS SHOULD ALSO BE A THING?
						or self.currentstate.name == "air_idle" --AND THIS
						or self.currentstate.name == "run"  --WOW, LOOKS LIKE TRANSITIONING TO THIS STATE IS EATING OUR BUFFERS...
						or self.currentstate.name == "run_stop"  -- :/
						or self.currentstate.name == "run_start" --then
						or self.currentstate.name == "dash_stop" 
						or self.currentstate.name == "duck" then --FOR DTILTS
						-- or self.currentstate.name == "pivot_dash" then --?? DOESNT LIKE THIS ONE I GUESS
						-- or self:HasStateTag ("sliding") then --OK IT CAN'T HEAR TAGS YET
						-- print("DONT CLEAR IT!")
					else
						-- print("CLEARBUFFER")
						self.inst.components.stats:ClearKeyBuffer() --ELSE, GO AHEAD AND CLEAR IT
					end
				end
			end
			
			
			--7-26-17 A SPECIAL HELPER TO MAKE SURE ANY MOVEMENT-RELATED TASKS LIKE MOTORS OR AIRSTALLS END WHEN A STATE EXITS
			if self.inst.components.jumper then
				self.inst.components.jumper:EndAllStateTasks()
			end
		
		end

		if self.currentstate.onenter ~= nil then
			self.currentstate.onenter(self.inst, params)
		end
		
		self.inst:PushEvent("newstate", {statename = statename})

		self.lastupdatetime = GLOBAL.GetTime()
		self.statestarttime = self.lastupdatetime    
		GLOBAL.SGManager:OnEnterNewState(self)
	end
	
end)


--4-7-19 AND YOU KNOW WHAT? I'VE GOT SOME OTHER IMPORTANT CHANGES TO MAKE
modimport 'scripts/stategraph_changes.lua'
modimport 'scripts/dev_utility.lua'
modimport 'scripts/fighter_keyhandlers.lua'
modimport 'scripts/locomotor_changes.lua'

--WAIT... DOWN BELOW US... ITS THE CURRENT VERSION OF WHAT WE'RE ACTUALLY USING......





AddGlobalClassPostConstruct("entityscript", "EntityScript", function(self)
	
	--4-7-19 TRYING SOMETHING STUPID
	self.inhitstun = false --TBH, THIS IS A VERY IMPORTANT VARIABLE THAT I DO NOT MIND MAKING AT THE ROOT OF EVERY ENTITY
	
	function self:FreezeStateGraph()
		if self.sg then
			SGManager:Sleep(self.sg, 8*(1/30))
		end
	end
	
	function self:PauseStateGraph()
		if self.sg then
			-- GLOBAL.SGManager:Sleep(self.sg, 8*(1/30))  
			-- GLOBAL.SGManager:Hibernate(self.sg)  
			--4-11-19 NOT ANYMORE MY FRIEND. TODAY, STAGE 3 OF OUR AFTERBURNERS DEPART. WE ARE FREE
			self.inhitstun = true --4-7-19
		end
	end
	
	function self:UnPauseStateGraph()
		if self.sg then
			self.sg:Update() --4-18-19 WHEW!! OKAY. I THINK THIS WAS THE FINAL PIECE. GOOD LORD THAT WAS DIFFICULT. ANIMS ARE IN SYNC AND EVERYTHING THOUGH
			self.inhitstun = false --4-7-19
		end
	end
	
	--1-6 TO FIX DIRECTIONAL BUG WHEN ANGLES ARE POSITIVE/NEGATIVE
	function self:ForceFacePoint(x, y, z)

		if not x then
			return 
		end
		
		if not self:IsValid() then --2-16-17
			return end

		if x and not y and not z then
			x, y, z = x:Get()
		end

		local angle = self:GetAngleToPoint(x, y, z)
		if angle <= - 90 or angle >= 90 then --1-6 LOL I WONDER IF THIS WILL FIX IT. --YEP IT DID
			angle = -180
		else
			angle = 0
		end
		self.Transform:SetRotation(angle)
	end
	
	
	
	function self:distnorm(v1, v2, v3, v4)

		-- PLEASE FORGIVE US! WE NEVER MEANT FOR IT TO END THIS WAY!    --WHY DOES THIS LOOK LIKE A COMMENT I WOULD MAKE??

		-- assert(v1, "Something is wrong: v1 is nil stale component reference?")
		-- assert(v2, "Something is wrong: v2 is nil stale component reference?")
		
		--special case for 2dvects passed in as numbers
		if v1 and v2 and v3 and v4 then
			local dx = v1-v3
			local dy = v2-v4
			return dx*dx + dy*dy
		end

		local dx = (v1.x or v1[1]) - (v2.x or v2[1])
		local dy = (v1.y or v1[2]) - (v2.y or v2[2])
		local dz = (v1.z or v1[3]) - (v2.z or v2[3])
		return dx*dx+dy*dy+dz*dz
	end

end)





--12-15-17 DST CHANGE-  GIVING GRUE HITBOXES!!
AddComponentPostInit("grue", function(self) --WOW, I CANT BELEIVE THIS WORKED. I TOTALLY JUST GUESSED THE SYNTAX AND GOT IT RIGHT THE FIRST TIME

	--OKAY DONT LEAVE PLAYERS TO FLAIL AROUND IN THE DARK FOR SO LONG
	self.nextHitTime = 2
	self.nextSoundTime = 1 --CANT BE 0 THOUGH
			
	function self:OnUpdate(dt)
		if self.inst:HasTag("the_night") then
		if self.nextHitTime ~= nil and self.nextHitTime > 0 then
			self.nextHitTime = self.nextHitTime - dt
		end

		if self.nextSoundTime ~= nil and self.nextSoundTime > 0 then
			self.nextSoundTime = self.nextSoundTime - dt

			if self.nextSoundTime <= 0 then
				if self.soundwarn ~= nil then
					self.inst.SoundEmitter:PlaySound(self.soundwarn)
				end
				
				local rogue = GLOBAL.TheSim:FindFirstEntityWithTag("roguehitboxspawner")
				rogue.SoundEmitter:PlaySound("dontstarve/charlie/warn")
			end
		end

		if self.nextHitTime ~= nil and self.nextHitTime <= 0 then
			self.level = self.level + 1
			-- self.nextHitTime = 5 + math.random() * 6
			self.nextHitTime = 5 --NICE AND SIMPLE
			self.nextSoundTime = 3 --self.nextHitTime * (.4 + math.random() * .4)

			if self.soundattack ~= nil then
				self.inst.SoundEmitter:PlaySound(self.soundattack)
			end
				
				local anchor = GLOBAL.TheSim:FindFirstEntityWithTag("anchor")
				--1-17-22 FIRST OF ALL~...
				for k,v in pairs(anchor.components.gamerules.livingplayers) do
					v.sg:RemoveStateTag("intangible")
					v.sg:RemoveStateTag("invuln")
				end
				
			-- if self.inst:HasTag("the_night") then --ITS THE ROGUEHITBOXER'S TAG
				local rogue = GLOBAL.TheSim:FindFirstEntityWithTag("roguehitboxspawner") --12-24-17 ONLY THE ROGUE HITBOXSPAWNER SHOULD SPAWN THIS
				rogue.SoundEmitter:PlaySound("dontstarve/charlie/attack")
				-- self.inst.components.hitbox:ResetMove() --OH RIGHT, SINCE IT NEVER LEAVES ITS STATE
				rogue.components.hitbox:FinishMove()
				
				rogue.components.hitbox:SetDamage(25) --JUST SPAWN A GIANT HITBOX CENTER STAGE
				rogue.components.hitbox:SetAngle(65) --KIRBY'S GROUNDED UNCHARGED HAMMER, WITH HIGHER ANGLE
				rogue.components.hitbox:SetBaseKnockback(55)
				rogue.components.hitbox:SetGrowth(78)
				rogue.components.hitbox:SetSize(35, 35)
				rogue.components.hitbox:SetLingerFrames(45)
				rogue.components.hitbox:SetProperty(-6)
				rogue.components.hitbox:SetHitFX("none", "none")
				rogue.components.hitbox:SetBlockDamage(50)
				
				rogue.components.hitbox:SpawnHitbox(0.35, 0.5, 0) 
				
				
				
				
				for k,v in pairs(anchor.components.gamerules.livingplayers) do
					v.components.visualsmanager:Glow(v, 15,  1,1,1,  .4, 0.5, 0.55) --r, g, b, glow, radius, falloff)
					v.components.visualsmanager:Blink(v, 15,  1,1,1,  0, 1) --r, g, b, glow, alpha
					
					-- v.components.hitbox:MakeFX("curve_down", 0, 0, 0.4, 	1.0, 1.0,	 0, 5, 0,  nil,nil,nil, 1, "lavaarena_shadow_lunge", "lavaarena_shadow_lunge")
					v.components.hitbox:MakeFX("curve", 0, 0.5, 0.4, 	1.5, 1.5,	 1, 10, 1,  1,1,1, 0, "lavaarena_shadow_lunge_fx", "lavaarena_shadow_lunge_fx")
					--ALRIGHT. THINGS ARE GOING TO GET A LITTLE TRICKY...
					v.components.stats.lastfx.Transform:SetSixFaced() --OOOOOH THATS RIGHT! SMART MOVE
					v.components.stats.lastfx.Transform:SetRotation(220)
					v.components.stats.lastfx.AnimState:PlayAnimation("curve")
					
					v.components.hitbox:MakeFX("curve", 0.2, 1.0, 0.4, 	1.2, 1.2,	 1, 10, 1,  1,1,1, 0, "lavaarena_shadow_lunge_fx", "lavaarena_shadow_lunge_fx")
					v.components.stats.lastfx.Transform:SetSixFaced() --BUT NOW I GOTTA DO THIS FOR ALL 3 OF THEM
					v.components.stats.lastfx.Transform:SetRotation(220)
					v.components.stats.lastfx.AnimState:PlayAnimation("curve")
					
					v.components.hitbox:MakeFX("curve", -0.2, 0.0, 0.4, 	1.2, 1.2,	 1, 10, 1,  1,1,1, 0, "lavaarena_shadow_lunge_fx", "lavaarena_shadow_lunge_fx")
					v.components.stats.lastfx.Transform:SetSixFaced() 
					v.components.stats.lastfx.Transform:SetRotation(220)
					v.components.stats.lastfx.AnimState:PlayAnimation("curve")
					
					if v.minibumpnetvar then --12-13-18 AH AH!! HOLD IT! MAKE SURE WE ARENT PLAYING WITH A CPU THAT DOESNT OWN ONE OF THESE
						v.minibumpnetvar:set(tostring(math.random())) --AH YES, IM SURE THIS IS TOTALLY THE PROPER WAY TO DO IT   	--I MEAN... IT WORKED THOUGH
					end
				end
				
				GLOBAL.TheCamera:MiniBump()
			end
		end
	end
	
	
	
	--AND LETS DISABLE THIS SO THE ANCHOR CAN HAVE THE GRUE COMPONENT
	function self:CheckForStart()
		return not (self.inst.LightWatcher:IsInLight())
	end
end)



--11-14-20 ITS REALLY ABOUT TIME I EDITED COMBAT THE RIGHT WAY
AddComponentPostInit("combat", function(self)
	
	function self:IsValidTarget(target)
		if not target 
		   or not target.entity:IsValid()
		   or not target.components
		   or not target.components.combat
		   or not target.entity:IsVisible()
		   or not target.components.health
		   or target == self.inst
		   or target.components.health:IsDead()
		   or (target:HasTag("shadow") and not self.inst.components.sanity)
		   
		   or not self.inst.components.stats --1-2-22 WAS THIS A GRUE BUG? I THINK IT WAS
		   --3-9 ADDING THIS SO TENTACLES WONT TARGET OWNER
		   or (target.components.stats and self.inst.components.stats.master == target)
		   
		   or GLOBAL.Vector3(target.Transform:GetWorldPosition()).y > self.attackrange then
			return false
		else
			return true
		end
	end
	
	--IM NOT TOTALLY SURE IF WE EVEN CALL THIS ANYMORE BUT
	function self:GetAttacked(attacker, damage, weapon)
		--self.inst:PushEvent("attacked", {attacker = attacker, damage = damage, weapon = weapon}) DONT THINK WE NEED THIS
		return true  --BYE :)
	end
	
	
	
	--OH WOW WE ACTUALLY CHANGED THIS ONE A LOT. I GUESS WICKER'S TENTACLES STILL USE THIS.
	--1-26-22 BUT IT SHOULDN'T ANYMORE! NOT SINCE I CHANGED IT TO ONLY USE DISTANCE TO ENEMY
	function self:CanAttack(target)

		--ADDING THIS CUZ NO ONE HAS A TARGETS
		local target = target or self.target 
		
		if not target then
			return false
		end

		if not self.canattack then 
			return false 
		end
		
		if self.laststartattacktime then
			local time_since_doattack = GLOBAL.GetTime() - self.laststartattacktime
			
			if time_since_doattack < self.min_attack_period then
				return false
			end
		end

		if not self:IsValidTarget(target) then
			return false
		end
		
		if self.inst.sg and self.inst.sg:HasStateTag("busy") then
			return false
		end

		-- local tpos = Point(target.Transform:GetWorldPosition())
		-- local pos = Point(self.inst.Transform:GetWorldPosition())
		-- print("WHATS ITS RANGE?", distsq(tpos,pos))
		
		--3-21 NEW DETECTION TO TAKE Y HIGHT INTO ACCOUNT
		local tpos, tposy = target.Transform:GetWorldPosition()
		local pos, posy = self.inst.Transform:GetWorldPosition()
		
		--SPECIAL CASE FOR TENTACLES BC WHATEVER
		if self.inst.prefab == "tentacle" then
			posy = posy + 1.2
		end
		
		-- if distsq(tpos,pos) <= self:CalcAttackRangeSq(target) then
		if GLOBAL.distsq(tpos, tposy, pos, posy) <= self:CalcAttackRangeSq(target) then --3-21
			return true
		else
			return false
		end
		--RETURN TRUUUE BABY --okay nevermind stop that
		-- return true 
	end
	
	
	--AGAIN, NOT TOTALLY SURE IF ITS ACTUALLY CALLED, BUT JUST IN CASE
	function self:TryAttack(target)
		local target = target or self.target 
		local is_attacking = self.inst.sg:HasStateTag("attack")
		if is_attacking then
			return true
		end
		
		if self:CanAttack(target) then
			self.inst:PushEvent("doattack", {target = target})
			return true
		end
		--return false
		return true
	end
	
	
	--SOME NEW ONES THAT DO THINGS I DONT LIKE
	function self:StartTrackingTarget(target)
		--BEGONE. YOU DO NOTHING NOW
	end

	function self:StopTrackingTarget(target)
		--YOU TOO
	end
end)







--PRETTY SURE THIS WAS A BUNCH OF GIBBERISH FROM BEFORE I GAVE UP ON TRYING TO MAKE THE CLOCK HAND MOVE WITH MATCH TIME
--12-17-17 AND NOW WE DOING WEIRD STUFF TO THE CLOCK
AddComponentPostInit("clock", function(self)
	
	NUM_SEGS = 1

end)
GLOBAL.TUNING.NUM_SEGS_SMASH = 16 --12-17-17 GONNA EDIT ME UP SOME
--???


--1-1-18 LETS SABOTAGE SOME GAME COMPONENTS THAT MIGHT INTERFERE WITH OUR PLAYERS MID-GAME
AddComponentPostInit("periodicspawner", function(self)
	self.basetime = 400000 --JUST IN CASE
	function self:Start()
		--LOL JUST RIP THE WHOLE THING OUT. CANT DRIVE A CAR WITHOUT AN ENGINE
	end
end)

--4-27-21 WELL, THE EVENT FROM GAMERULES IS DEPRECIATED, SO I GUESS WE DO THIS INSTEAD
GLOBAL.TUNING.BIRD_SPAWN_MAX = 0


AddComponentPostInit("penguinspawner", function(self)
	self:SpawnModeNever() --NOT ENTIRELY SURE HOW WELL THIS WILL WORK
end)

--4-26-21 GONNA TRY GUTTING A FEW COMPONENTS IN AN ATTEMPT TO LEAVE WORLD SPAWNING DEFAULTS...
--THIS SOUND COULD GET REALLY ANNOYING
AddComponentPostInit("meteorshower", function(self) --BIRDTAG
	function self:StartShower()
		--GUTTED
	end
	function self:SpawnMeteor()
		--GUTTED
	end
end)


--WHAT EVEN IS THIS?? I TOTALLY FORGOT WHAT THIS IS AND WHAT IT DOES
local StaticComponentUpdates = {}
function RegisterStaticComponentUpdate(classname, fn)
	StaticComponentUpdates[classname] = fn
end







--1-27 ARE YOU READY TO REPEAT THE MISTAKES OF MY PAST
GLOBAL.PostUpdate = function(dt)
	GLOBAL.TheSim:ProfilerPush("LuaPostUpdate")
	GLOBAL.EmitterManager:PostUpdate()
	GLOBAL.TheSim:ProfilerPop()
	
	
	--THE MASTER HITBOX UPDATER FROM THAT WEIRD EXTERAL COLLISION DETECTOR SPHERES IN HURTBOXES.LUA
	if GLOBAL.TheWorld then 
		local anchor = GLOBAL.TheSim:FindFirstEntityWithTag("anchor") --GLOBAL.ThePlayer -DST
		if anchor then 
			local pos = GLOBAL.Vector3(anchor.Transform:GetWorldPosition())
			local ents1 = GLOBAL.TheSim:FindEntities((pos.x), (pos.y), (pos.z), 50, {}, {}, {"fighter", "projectile", "force_postupdate"})
			for k, v in pairs(ents1) do
				
				if v.components.hitbox then --DST CHANGE FOR CLIENTSIDE
					for k,v in pairs (v.components.hitbox.hitboxtable) do
						--5-31-18 LETS BEAT SOME HEARTS!!
						-- v.components.hitboxes:OnHeartbeat(dt)   --dt --OH, I GUESS DT ISNT A THING HERE...
						v.components.hitboxes:RollToHit()  
						v.components.hitboxes:RollForDamage() --1-6-22
					end
				end
				
				--2-21-17
				if v.components.hoverbadge then
					v.components.hoverbadge:UpdatePosition()
				end
			end
			
			--4-25-17 ALRIGHT FINE. LETS HAVE A SECOND TABLE. WOULD THERE BE LESS LATANCY TO JUST HAVE 1??
			local ents2 = GLOBAL.TheSim:FindEntities((pos.x), (pos.y), (pos.z), 50, {}, {}, {"fx_wallupdate"})
			for k, v in pairs(ents2) do
				if v.components.fxutil then	--FLUENTLY UPDATES STICKING FX 
					v.components.fxutil:UpdatePosition()
				end
			end
		end
	end
	
end






--7-30-17 MAKING TARGET INDICATOR FOLLOW Y POSITION INSTEAD OF Z   
--NAH. THIS AINT WORKING. GONNA JUST DO THINGS THE LAZY WAY AND TAKE THE ENTIRE FILE JUST TO CHANGE ONE LETTER
-- AddGlobalClassPostConstruct("widgets/targetindicator", "TargetIndicator", function(self)
-- -- AddClassPostConstruct("widgets/targetindicator", function(self)
	-- function TargetIndicator:OnUpdate()
    -- -- figure out how far away they are and scale accordingly
    -- -- then grab the new position of the target and update the HUD elt's pos accordingly
    -- -- kill on this is rough: it just pops in/out. would be nice if it faded in/out...

    -- local userflags = self.target.Network ~= nil and self.target.Network:GetUserFlags() or 0
    -- if self.userflags ~= userflags then
        -- self.userflags = userflags
        -- self.isGhost = checkbit(userflags, USERFLAGS.IS_GHOST)
        -- self.isCharacterState1 = checkbit(userflags, USERFLAGS.CHARACTER_STATE_1)
        -- self.isCharacterState2 = checkbit(userflags, USERFLAGS.CHARACTER_STATE_2)
        -- self.headbg:SetTexture(GLOBAL.DEFAULT_ATLAS, self.isGhost and "avatar_ghost_bg.tex" or "avatar_bg.tex")
        -- self.head:SetTexture(self:GetAvatarAtlas(), self:GetAvatar(), GLOBAL.DEFAULT_AVATAR)
    -- end

    -- local dist = self.owner:GetDistanceSqToInst(self.target)
    -- dist = math.sqrt(dist)

    -- local alpha = self:GetTargetIndicatorAlpha(dist)
    -- self.headbg:SetTint(1, 1, 1, alpha)
    -- self.head:SetTint(1, 1, 1, alpha)
    -- self.headframe:SetTint(self.colour[1], self.colour[2], self.colour[3], alpha)
    -- self.arrow:SetTint(self.colour[1], self.colour[2], self.colour[3], alpha)
    -- self.name_label:SetColour(self.colour[1], self.colour[2], self.colour[3], alpha)

    -- if dist < GLOBAL.TUNING.MIN_INDICATOR_RANGE then
        -- dist = GLOBAL.TUNING.MIN_INDICATOR_RANGE
    -- elseif dist > GLOBAL.TUNING.MAX_INDICATOR_RANGE then
        -- dist = GLOBAL.TUNING.MAX_INDICATOR_RANGE
    -- end
    -- local scale = Remap(dist, GLOBAL.TUNING.MIN_INDICATOR_RANGE, GLOBAL.TUNING.MAX_INDICATOR_RANGE, 1, GLOBAL.MIN_SCALE)
    -- self:SetScale(scale)

    -- local x, y, z = self.target.Transform:GetWorldPosition()
    -- -- self:UpdatePosition(x, z)
	-- self:UpdatePosition(x, y)  -- >:3c
-- end
-- end)






--DSTCHANGE@@-- GET THIS GARBAGE OUT OF HERE--
AddPrefabPostInit("nightmarerock", function(inst) 
    
	-- inst:Remove() --LOL WILL THIS WORK?
	inst.active = false
	inst:CancelAllPendingTasks()
end)



--WE MIGHT WANT TO COME BACK TO THIS IDEA SOME DAY!  IT'S A GOOD IDEA BUT WILL REQUIRE SOME WORK FIRST
--9-26-20 OKAY, SO DOES THIS WORK?...  --ADDING ADDITIONAL MATCH INFO TO THE TAB SCREEN
--[[
AddClassPostConstruct("screens/playerstatusscreen", function(inst)
	
	local Widget = require "widgets/widget"
	local Text = require "widgets/text" --I NEED TO BORROW THIS
	
	local old_doinit = inst.DoInit
	inst.DoInit = function(inst, ClientObjs, ...) --ADDING INST TO REFERENCE SELF
		old_doinit(inst, ClientObjs, ...)
		
		--JUST A TEST, BUT IT WORKS!!
		-- inst.black:SetTint(1,0,0,0.2) -- invisible, but clickable!
		
		
		--OK LETS DO SOME REAL THINGS
		inst.list_root2 = inst.root:AddChild(Widget("list_root"))
        inst.list_root2:SetPosition(10, -35)

        inst.row_root2 = inst.root:AddChild(Widget("row_root"))
        inst.row_root2:SetPosition(10, -35)

        inst.player_widgets2 = {}
        for i=1,6 do
            -- table.insert(inst.player_widgets2, listingConstructor(i, inst.row_root))
            --UpdatePlayerListing(inst.player_widgets2[i], ClientObjs[i] or {}, i)
			table.insert(inst.player_widgets2, "TEST VALUE")
        end
--
        -- inst.scroll_list = inst.list_root:AddChild(ScrollableList(ClientObjs, 380, 370, 60, 5, UpdatePlayerListing, self.player_widgets2, nil, nil, nil, -15))
        -- inst.scroll_list:LayOutStaticWidgets(-15)
        -- inst.scroll_list:SetPosition(0,-10)

        -- inst.focus_forward = inst.scroll_list
        -- inst.default_focus = inst.scroll_list
		
		
		inst.scroll_list2 = inst.list_root2:AddChild(Text(GLOBAL.CHATFONT, 28))
		inst.scroll_list2:SetString("MORE TEST VALUE")
		
		--WAIT, THE PLAYERQUEUE TABLE ISN'T AVAILABLE TO CLIENTS BECAUSE IT'S ONLY STORED SERVER-SIDE...
		--ALRIGHT, DANG. THIS WILL HAVE TO WAIT THEN. THIS FEATURE IS TOO MUCH WORK FOR THE TIME BEING
		
	end

end)
]]




--SINCE WE CAN'T GET THE HAND TO MOVE THE WAY WE WANT IT TO. JUST GET RID OF IT.
AddClassPostConstruct("widgets/uiclock", function(inst)
	--LOL IS THIS GOOD ENOUGH?
	inst._hands:Hide() --WOW I CAN'T BELEIVE THAT ACTUALLY WORKED
end)



--8-25-21 ROADS. MY BIGGEST RIVAL...
GLOBAL.ROAD_PARAMETERS.NUM_SUBDIVISIONS_PER_SEGMENT = 50
GLOBAL.ROAD_PARAMETERS.MIN_WIDTH = 0
GLOBAL.ROAD_PARAMETERS.MAX_WIDTH = 0
GLOBAL.ROAD_PARAMETERS.MIN_EDGE_WIDTH = 0
GLOBAL.ROAD_PARAMETERS.MAX_EDGE_WIDTH = 0
GLOBAL.ROAD_PARAMETERS.WIDTH_JITTER_SCALE=1
--WOW THIS ACTUALLY WORKED. GOOD RIDDANCE



--10-14-21 OKAY, WE ADD EXACTLY ONE LINE OF CODE TO THIS FILE. THE LEAST WE CAN DO IS TRY AND ALTER IT CORRECTLY.
AddClassPostConstruct("screens/skinsscreen", function(self)
	
	local OriginalDoInit = self.DoInit
	
	self.DoInit = function(self, ...)
		OriginalDoInit(self, ...)
		self:Quit() --THE ONE LINE I ADDED
	end
	
end)


AddClassPostConstruct("widgets/targetindicator", function(self)
	local OriginalOnUpdate = self.OnUpdate
	self.OnUpdate = function(self, ...)
		--OriginalOnUpdate(self, ...) --DON'T RUN THE ORIGINAL. RUN NOTHING
		-- JUST DO NOTHING (I gave up on trying to make it dusplay icons for offscreen enemies in the X/Y coords)
	end
end)



local ImageButton = require "widgets/imagebutton"
local PopupDialogScreen 	= require("screens/popupdialog")
local function AddToggleButton(class)
	--I BET I CAN GET REAL "PROPER" WITH THIS. MAXIMUM COMPATIBILITY!
	
	class.spectatebtn = class.menu:AddItem("Spectate-Only", nil, GLOBAL.Vector3(0,0,0), "carny_xlong", nil)
	class.spectatebtn:SetOnClick(function() 
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["respectator"], "begin_session") 
		class:unpause()
	end)
	
	class.spectatebtn:SetScale(.7)
	-- class.cambutton:GetAnimState():SetAddColour(0, 0.8, 0, 1) --OOPS
	-- class.cambutton:SetTextColour(0.2, 1, 0.2, 1)
	-- class.cambutton:SetColour(0.2, 1, 0.2, 1)
	
	
	
	
	local servergamemode = GLOBAL.TUNING.SMASHUP.SERVERGAMEMODE
	--NEVERMIND, WE DONT HAVE ACCESS TO THAT ENTIRE MENU FROM HERE. LETS JUST MAKE IT A "END GAME" BUTTON INSTEAD
	--SERIOUSLY, I HOPE YOUR PLAYERS ALL UNDERSTAND THIS CONCEPT, BECAUSE THIS IS SUPER EASY TO ABUSE AND GRIEF
	if (servergamemode == 1) or (servergamemode == 2 and GLOBAL.TheNet:GetIsServerAdmin()) then
		class.gamemodebtn = class.menu:AddItem("Return to lobby", nil, GLOBAL.Vector3(0,0,0), "carny_xlong", nil)
		class.gamemodebtn:SetScale(.7)
		
		class.gamemodebtn:SetOnClick( function() 
			-- local text = "Exit to lobby and select a new game mode? \n"
			-- text = text .. "Any queued players will lose their spot in line. \n"
			local text = GLOBAL.STRINGS.SMSH.UI_EXIT_LOBBY_DESC
			
			local message = PopupDialogScreen( GLOBAL.STRINGS.SMSH.UI_ARE_YOU_SURE, text, {  --"Are you sure?"
				{text=GLOBAL.STRINGS.SMSH.UI_END_GAME, cb = function() 
					GLOBAL.TheFrontEnd:PopScreen() 
					class:unpause()
					SendModRPCToServer(MOD_RPC[modname]["setservergamemode"], "PRACTICE_FORCE") 
				end},
				{text=GLOBAL.STRINGS.SMSH.UI_CANCEL, cb = function() 
					GLOBAL.TheFrontEnd:PopScreen()  --JUST CLOSE THE MENU
				end}
			} )
			GLOBAL.TheFrontEnd:PushScreen( message )
		end)
	end
	
end
AddClassPostConstruct("screens/redux/pausescreen", AddToggleButton)
