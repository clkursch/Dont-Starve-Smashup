
name = "Smashup"
--[[
description = "Give your F key a break and jump into a new type of brawl with this smash-inspired combat rework! \n"
description = description .."Choose from a handful of fighters with unique stats and movesets with the goal of knocking your opponents offstage! \n" -- and you can make your own! \n" --SHH, NOT YET...
description = description .."Playable on either Keyboard or USB controller. Use the 'Smashup Custom Controls' mod to change your controls. \n \n"
description = description .."=== SETTING UP A WORLD === \n"
description = description .. "1. Create a NEW world and enable this mod in the mods tab. \n"
description = description .. "2. Disable caves for best results. \n"
description = description .. "3. Start the server! And you're done! \n"
--NOT SURE HOW TRUE THIS IS AT THE MOMENT, SO I'M REMOVING IT FOR NOW
--description = description .. "[Dedicated servers require a bit more setup. See workshop page for more details] \n \n"
description = description .. "Change game-mode settings and more in the mod's settings menu. \n" 
]]

description = "Knock your opponents off the stage to win in this smash-inspired combat rework! \n"
description = description .."Playable on keyboard or controller. Use the 'Smashup Custom Controls' mod to change your controls. \n \n"
description = description .."SETUP: Enable this mod on a NEW world and disable caves for best results.\n\n"
description = description .."=== CHANGE LOG: 1.2.15 === \n"
description = description .."Compatibility fix \n"
-- description = description .."Fixed a bug that would sometimes cause the game to crash when creating a world \n"
-- description = description .."Fixed a bug that increased hitlag for all attacks \n"



-- description = description .. "-Lives counters and AI spider huds finally show up properly for non-host players \n"
-- description = description .. "-Teammates now respawn inbetween waves during horde mode \n"
-- description = description .. "-Players ping is now properly displayed for everyone \n"
-- description = description .. "--Fixed some bugs with blocking projectile knockback \n"
-- description = description .. "--Slapped a chat-bar onto the character select screen \n"

-- description = description .. "-Greatly improved keybuffers! and added 1 frame to the duration \n"
-- description = description .. "-Character balance changes! See change log for full changes \n"
-- description = description .. "-Nerfed Wes's specials and gave Woodie a sweet new up-air \n"
-- description = description .. "-Increased light level during sudden death \n"

-- description = description .. "-Slight improvements to controls and control buffers.  \n"
-- description = description .. "-Controllers can now be used to navigate the smashup menus.  \n"
-- description = description .. "-While tapjump is disabled: upward diagonal inputs for airials will perform an up-air instead of a f-air/b-air  \n"
-- description = description .. "-Player Ping is displayed at the start of an online match  \n"
-- description = description .. "-Game music settings are seperate from DST music settings, and can be enabled/disabled from the in-game settings menu   \n"

-- description = description .. "-Team Battles! Selectable from the new PvP gamemode menu \n"
-- description = description .. "-Added team color tints to some in-game entities \n"
-- description = description .. "-Added a 'return to lobby' button to the host's pause menu \n"
-- description = description .. "-Some bugfixes, as usual \n"

-- description = description .. "-He's bigger! He's Better! AI Overhaul part 2, now even smarter! \n"
-- description = description .. "-Added respawn invulnerability. You get 1 second, so don't waste it. \n"
-- description = description .. "-Reworked Maxwell's shadow-recall features to be more intuitive. \n"
-- description = description .. "-Charlie's attacks now instantly break shields and ignore invulnerability. \n"
-- description = description .. "-Added an experimental 'spectate-only' button to the pause menu. \n"
-- description = description .. "-Quick hotfix to wickerbottom crashing the game \n"


--CUSTOM CONTROLS MOD LINK, SINCE IT'S CURRENTLY UNLISTED
--https://steamcommunity.com/sharedfiles/filedetails/?id=2298228108

author = "Pickleplayer"
version = "1.2.15" --"0.912"
api_version = 10
api_version_dst = 10
dst_compatible = true
server_filter_tags = {"smashup", "smash up", "smash bros"}

all_clients_require_mod = true

forumthread = "" --DOESNT MATTER, THESE NOW JUST TAKE YOU TO THE STEAM WORKSHOP ANYWAYS

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

priority = 3300
--PRIORITY SHOULD BE LOWER THAN THE CONTROLS MOD, SO THE GLOBALS CAN INIT
--BUT HIGHER THAN THE TEMPLATE MOD, WHICH WE WANT TO LOAD LAST SO THE CHARACTER ICON APPEARS AT THE END

--Updated player_classified and SGnewwoodie for compatability

--Updated playercommon.lua to fix compatibility with the Wilson refresh

--Updated fighterhud.lua to fix compatibility with the maxwell refresh

--Fixed hitlag so it no longer adds 1 frame across the board. (11-20-22 in hitboxes.lua) 
--reduced the likelyhood of some characters (woodie, maxwell) would start blinking red if using a smash attack in the first second of lobby mode


--Compatability fix for the A Little Drama update.
--(Applied this crash fix to the local multiplayer branch too, just in case)
--Fixed a typo in the loading screen tips
--Fixed a bug that would sometimes cause the game to crash when creating a world
--Buffs to spider warrior:
--Made Up-tilt jump-cancel early
--Improved the strength of Back-Air and Down-Smash



--Added a check for Woodie's meme skin to reskin the thrown projectile



--Wes's side-special charges are restored when respawning
--Fixed maxwell clones not recognizing some up inputs
--Increased the cooldown on Wickerbottom's tentacle spellbook
--Fixed getup attack hitboxes not having full intangibility during the invuln window
--Replaced the in-game loading tips with Smashup tips
--Hotfix: fixed a crash when generating a new world

--The unfinished Local Multiplayer update was moved to a new branch for now. I'm hoping that Klei will fix the engine issue thats keeping the analog sticks from working before I get back to it.





--Renamed some hud elements so hud altering mods don't interfere with smashup's hud layout
--Fixed an issue with hitbox priority not resetting after certain attacks
--Cleaned up some unused hitbox variables
--For dedicated servers, any player will be able to choose the game mode regardless of settings because server owners keep forgetting to set the correct gamemode settings



--Fixed knockback while blocking sometimes being the wrong direction against projectiles
--Fixed wes's ledge getup options sometimes falling past the ledge if he held on long enough
--Maxwells clones keylisteners don't get reversed when facing a different direction than him
--Slapped the dst lobby chatbar onto the character select screen to chat during character select
--Smashup music settings will default to "off" if music volume is set to 0 when loading in



----Major features / changes
--AI spider huds finally show up properly for non-hosting players
--The lives counter FINALLY displays the correct number of lives for non-hosting players when starting a match
--Players Ping is now displayed at the start of a round
--Teammates now respawn inbetween waves during horde mode
--Spider queen now spawns adult spiders

----Keybuffer improvements / bugfixes
--Better recognition for uptilts/smashes with tapjump enabled
--With tapjump enabled jumpsquat can be canceled into uptilt
--With tapjump disabled, buffering jumping cstick_up will buffer an upair instead of upsmash 
--Gave grab a proper keybuffer and added support for directional buffering
--fixed d-tilt buffers being eaten by the crouch animation
--Maxwell clones now use their own keybuffer instead of looking at Maxwells, and control more fluently.
--Fixed a few special moves that could not be b-reversed
--Fixed some of Wes's reflector sounds not playing correctly online
--AI Spider warriors face the correct direction when throwing projectiles
--Removed the player_classified prefab from the mod files since all functionality has been moved to player_common
--Fixed some rare crashes caused when players join a server within the 0.5 second window of a match ending or starting
--Hopefully fixed spectate-only mode still cycling through the queue of players
--Fixed a bug with player queues that caused caves to be counted as a player
--Failed yet again to add gift opening into the game. pls somebody tell me what I'm doing wrong

----Slight balance/qol tweaks:
--Made Wilson's usmash and Wickerbottom's uair much less likely to drop opponents out of the multihit
--Wilson's up-special now only cancels the endlag on-hit if it was used from the ground
--Slightly increased the startup speed and first hitbox size of Wilson's up-smash
--Greatly increased the landing lag on Woodie's up-air
--Added a frame to wes's jumpsquat to bring him in line with the rest of the cast (and make it easier to shorthop/uptilt, etc)
--slightly Adjusted the hitboxes for Maxwell's up-air, lowering it's position
--Using "command" on maxwell's clone will always make it walk in the direction maxwell is facing



--Add 2 frames of autocorrect to sidespecials to make upspecial
--Changed some component settings to hopefully allow opening gifts from client / with mouse, no longer requiring a science machine
--Attempted to sync skin selections on servers


--Training dummy also flashes colors in the prone state when it is able to move
--Uptilts and upsmashes are now possible with tapjump enabled, if timed before the jump leaves the ground


--Changed the way keyhandlers listen for keys. make sure mashing during loading in doesnt break anything
--Jumper updater now inits right away. may or may not fix buffering backairs
--Made a change to allow buffering grounded jump+b-airs without turning around during the jump
--Major restructuring of controller code that should, 'theoretically', have no impact on performance...
--Players Ping is now displayed at the start of a round
--Open gift, attempt 2 (giftitemtoast)
--Increased the agro range of the tentacle.
--Removed the 3 charge limit on the tentacle summoning book. There is now a 4 second cooldown on the tentacle summon after the current one despawns
--Illegally spawned spiderfighter_queen is spawned with normal health stats (and are killable)
--Hid the character choice when selecting random
--Made a change to hopefully prevent getting locked without a hud when disconnecting during a stage transition.
--Made smash attacks during a dash startup register the correct direction
--@Pressing down on a ledge no longer fastfalls
--Hopefully fixed the rare case where projectiles would hit backwards even with force_direction
--Fixed a rare crash from the AI attack node
--In-game smashup music ignores the player's music_fx volume settings, and can be enabled/disabled by a new button in the controls menu.
--Reduced endlag on woodie's f-air
--tapjump uair
--XXXStagegen message should now appear for clients on caves servers


--If you buffer a jump and an aireal far enough away from each other (the jump must be buffered out of busy) the jump will come out but not the aireal (cstick)
--make the controler binds unpress the opposite direction key. they can get reversed if holding a direction during loading
--Extend wes's reflectbox downward
--The controls still wonk up even when using them normally
--maybe add 1 to the buffer
--Consider clearing out playercommon's "OnSave" so player data isn't saved?
--adjust meteor physics sizes and angle
--Maybe move the skin selector to the right side of the screen
-- offcentered stuff?
--???disjoint getupattacks
--Can we bring the escapemenu back to the fighterselect screen
--@@using backwards cstick while walking forward will not turn around before the fsmash
--@@make tentacle persistant
--made tentcl despawn a taskintime
--Test if making the angle on wilson's bair negative fixes the launch angle
--fix wes lol
--check to make sure stick values work with "iscontroldown" before changing them
--@Make sure pressing the back button on other menus won't steal focus
--@Maybe gifts will fr fr actually work now
--Music setting
--hud focus


--Added team colors to in-game projectiles and entities
--Fixed wes's back-throw throwing forward
--Fixed a crash with the level select screen
--Added a "return to lobby" button to the host's pause menu



--Maybe fixed the spider player ocasionally causing a crash.
--Hopefully fixed some issues with camera positions getting locked at the start of a match
--Some small tweaks to chineese translations
--Slightly increased the movement speed of woodies Fspecial
--Wes's Fspecial has more endlag if the balloon is popped
--Maxwell's shadow clone always spawns facing the same direction as him
--Wickerbottom's Uair multihit more consistantly locks enemies into the whole attack


--GREATLY increased mod priority to hopefully decrease the likelyhood of unrelated client mods from crashing the game
--fixed some crashes caused by AI goofs
--Added "force direction" to a few tilts to fix some wonky reversed launch angles
--*Fixed calculation bug that added WAY too much blockstun to certain heavy attacks (woodies axe throw, meteor, queen, etc)
--Fixed wickerbottom's tentacles ignoring some fighters to focus on specific ones
--Typing in a chat message should automatically stop any character movement
--small localization changes
--Fixed a rare crash related to AI brain stuff
--Fixed controller cstick not registering retreating bairs correctly


--Fixed some inconsistant clank behaviors in general
--Wes's reflector no longer clanks with normals (This was definately not supposed to be a thing)
--Wes's reflector reflects wilson's throwable potions correctly
--Wilsons throwable potions now explode when clanked instead of magically vanishing
--The sweetspot on woodies fspecial is more consistant to land, and no longer gets eaten by the sourspot
--Added a sourspot to the beginning of Wes's fsmash so that it no longer whifs enemies right in front of him

--Fixed a crash caused by nightmare creatures wandering onto stage aat low sanity
--Added more context to the Control menu

--Removed the bedazzle on the queen
--*Hopefully reduced the frequency of getting stuck in grab animations
--Silent KOs are now actually silent and don't play the bell (mostly for horde mode)
--Multiple wilsons joining lobby mode should show up with different skins now
--Stage generation should now disable resource regrowth (existing worlds will need to be regenerated)
--Spiders should no longer be able to block mid-air
--Made some slight tweaks to the AI brain for the formula that chooses it's attacks
--Hopefully fixed a crash caused by spiders being too afraid to do anything at all
--Non-admins can no longer click the "Start Game" button when server game-mode configuration is set to "Admin's Choice"
--When assigning skins, if all skins are already in use, a random one will be assigned instead of always choosing the last one 
--Fixed some crashes caused by players joining the server right as certain events happen
--made an attempt to seperate the spectator anims from the actual in-game character "spectator"
--Adjusted the hud display in an attempt to fix some of the overlapping issues

--Small tweaks to spawn layout
--Tier2 wave1 no longer spawns you directly on top of a spider warrior
--The playable spider warrior can no longer air-block too
--Display the correct number of lives on round start
--Made some small cleanups that may or may not improve performance online. maybe.


--Cleaned up some script related to maxwells clones
--Moved the function of playercontroller_1 to keydetector and scrapped playercontroller_1 entirely.
--Keydetector component now inits immediately. This should reduce some of the crashes on high stress servers


--Maxwell's shadow clone should stop brefily gaining color during certain animations
--Fixed a bug where the background and players would un-load for spectators and players out of lives. Wilson can no longer send you to the shadow realm
--Fixed a visual bug when maxwell grabs 2 players at once with a shadow hand, the other one would breifly teleport behind him
--Disabled world regrowth for real this time. No more random trees
--Added "spawnlight" tag to the portal to prevent spawnlights from being added when a player joins at dusk/night
--Made some major reforms to the hitbox code to improve the clanking mechanics


--Added a failsafe crash prevention for the ocasionaly late clank fx spawner
--Fixed the controls text displaying the wrong keys




--The "/" key no longer opens chat because people keep accidentally pressing it.
--Hitting the honey ham no longer prevents you from eating it.
--Fixed some of the grab glitches caused by grabbing at odd ranges or high speeds
--Reduced the glitchiness letting go of a ledge immediately after grabbing it
--Fixed wickerbottom's tentacles sometimes just ignoring enemies, hopefully for real this time
--Applied the controller fix from keyboard movement that should prevent controller users from being forceably walked off the edge
--Added a failsafe to prevent players from violently vibrating out of control if charging state skips the onexit task
--Charlie does even more block damage
--Increased the queen's health to 350

-- Wilson:
--Charging n-special past stage 2 can deal between 0-8 damage to yourself on exploding, depending on how long the potion was charged
--Increased the active frames on u-speclial sweetspot if used from the ground
--Increased the knockback of u-air

--Woodie
--Increased the hitbox size and startup speed of woodie's n-air and u-smash
--Increased hitbox size of dash-attack, f-tilt, and d-tilt
--Increased the endlag on axe-throw
--Axe throw no longer whifs on point-blank targets or close range spiders
--Grounded up-special greatly reduces in power after the first few frames

--Wickerbottom
--wickerbottom's meteor book and tentacle book: If used in the air, wicker air-stalls until the book is closed
--Wickerbottom's ice-staff attack: If used in the air, the projectile has a sharper downward angle
--Reduced the landing lag on Wickerbottom's d-air
--Increased the hitbox size on b-air
--The hitboxes on b-air, u-air, and u-tilt are now disjointed
--Getting hit by an ice staff projectile near the ledge will no longer bump you over the ledge

-- Maxwell:
--Decreased landing lag on b-air
--The final hit of n-special has a larger hitbox to prevent it from whiffing light characters like spiders

--Wes
--u-tilt has a larger hitbox and can now hit prone targets
--Greatly increased the hitbox size of up-special.
--Up-special's knockback values have been redone, giving it low base knockback and high growth. (This makes it harder to kill targets at low percents but easier to kill at high percents)
--Wes's fall speed is reduced during his bycicle kick animation
--Wes's down-special has a lower launch angle when used in the air. (rip tod)





--Hitting a frozen enemy with an ice staff projectile no longer unfreezes them
--Being frozen now lowers your falling speed
--Set a zoom limit to the camera
--Lowered the chat box to take up less of the fighting space
--Increased the left and right blast zone edges
--Fixed wickerbottom's tentacle sometimes lasting forever
--fixed Wes's reflector sometimes not reflecting certain projectiles for the full duration
--Wes's Downb can stall in the air for longer
--Wickerbottom and Maxwell can b-reverse their n-specials 
--increased endlag on woodie's grounded up-special
--Increased the speed of Wilson's boomerang and reduced the endlag


--Cleaned up some of the unused stategraph script
--Swapped controller default controls for attack and special attack
--Updated the controls with a new set of controller alt keys
--Greatly improved controller performance
--*Added the option to set c-stick to tilts. configurable in the custom controls mod settings


--Increased the delay to add smashmenus to hopefully reduce how often an admin will load into a dedicated server and not see server buttons
--Tweaked dash controls to handle buffered dashes better (check maxclones)
--Optimized a lot of the keyboard controls to slightly reduce input lag.
--mightve fixed that glowing red bug
--(check what their deadzones used to be) 


--Some AI fixes!
--Low level spiders no longer stop to ponder about why they don't know how to shield in the middle of battle. They will always quickly choose a new attack.
--Spiders are no longer overly-dedicated to using up-smash once they've decided to use that move
--Spiders should be less likely to fumble punishing after a dodge roll
--Spiders have remembered how to dodge out of juggling combos
--Spiders don't stand there in confusion after dropping shield to try and decide how to attack
--*More fixes to prevent weird slipping past ledges without grabbing
--TODO: apply the same "checking for swung when the move actually happens" with like dodging and stuff so that doesnt get eaten by busy frames
--Fixed a weird grabbing launch bug when getting grabbed during a very specific frame of your jump animation
--*Fixed some grab release bugs, and throw release bugs
--Reduced the recovery distance of side-special and decreased the priority
--Reduced the startup and endlag of the projectile, and increased it's damage
--up-special auto-snaps to the ledge during the beginning of the launch
--Added 2 frames of armor to the startup of the taunt animation because lol why not



--Made it easier to do the grounded version of woodie's and wes's up-special
--Spiders are a bit smarter about how they approach against projectiles and rapid jabs and how they get up from ledges
--Spiders are more likely to throw grabbed players towards the nearest ledge
--Added respawn invulnerability. You get one second, and that's it.
--Charlie's attacks instantly break shields, and now ignore intangibility and invulnerability
--Wilson's n-special doesn't get armor if uncharged
--Oh my god I actually fixed that 5 year old super-fastfalling bug. and then introduced a new one
--Maxwell's n-special no longer hits teammates
--Reworked Maxwell's recall feature to work as a single move that activates a status, not by holding the button. 
--Replaced the "spectator" prefab with "spectator2" to fix wierd visual clothing bugs related to The Forge, somehow.
--Fixed the UI layout to be less hideous with combined hud mod enabled
--Added an experimental "spectate-only" mode to the main menu that automatically chooses spectator for you.



--Rewrote most of the menu script to function with controllers
--Added a "PvP settings" to the gamemodes menu to change certain server settings from in-game
--Added Team Battles, settings accessable from the PvP settings menu
--The cursor should be nudged out of the way when starting a new game
--Fix spider warrior unlockable?
--Character Select timer settings


--TODO: make an "air-rushdown" check to see if spiders should immediatly jump and float towards opponent agressively
--Enable debugprint on chaseandfight and test the results
--We should skip the "evade" jump and dodge for everything except scary & explosions if we are "going_in"
--give that statusdisplay thing another go with removing temperature badges. maybe on a timer?
--tried something stupid with smashmenus to get spider den select to work with controller, idk

--even if a player loads in too early into a prep phase from premature character swap, the logic should still be capable of handing them a select screen if in the match queue
--This points to players not being added to the match queue if not in the game when start is clicked

--comment out line 511 in hitboxes and see if it fixes the issue


--[[
in caves, spider CPUs dont even get huds at all. 
and player hud lives are not updated
the end of round KO at the bell is silent for some reason?
On countdown, maybe check if stage is misaligned and warn the user
--WOODIES fspec suction doesn tseem to activate unless the sourspot hits first
--blocking maxwells nspec does weird stuff
--Maxwells clone sometimes doesn't reapply it's skins
--Meteor hits twice and sometimes spikes so hard they are instantly destroyed
--client wilson (spectator) went into idle at the peak of a jump right after spawning
--Add the smashmenu buttons to the pause menu so controller users can access them

make wicker's tentacles timer based instead of charge based
decrease endlag on clone summon

maybe slightly decrease wes fallspeed
add images of mod settings to steam page
increase character select timer

consider tiltsticks

Move the end game button somewhere else
]]


--Den command grab
--net swing dair
--double kick fair
--net bounce upspec
--butterfly net swing uair?
--Villager style jab with two spider limbs

--Winona
--Heavy wrench swing that also builds stuff



--TO ADD TO SMASHTEMPLATE
--[[
	
	--Find the state named "grabbed" and paste this code into it, right ABOVE the "onexit =" line
	timeline =
	{
		TimeEvent(90*FRAMES, function(inst)
			inst.sg:GoToState("rebound", 10)
		end),
	},
	
	
	--In the "grabbing" state (different than the one above) find this line: 
		EventHandler("on_hitted", function(inst)
	--Replace it with this:
		EventHandler("on_punished", function(inst)
	--In that same state, add this line anywhere after the "onenter=function()" line:
		inst.Physics:Stop()
	
	--In the "block_stop" state, Paste the following code in the line above "timeline ="
	onupdate = function(inst)
		--HOTFIX
    end,
	
	
	in the "grab_ledge" state, add this state tag to the table of tags underneath the name. Don't forget to include a comma between tags
		"no_air_transition"
	
	
	In the "cstick_side", "cstick_up" and "cstick_down" event handlers, add the following line
		local tiltstick = inst.components.stats.tiltstick
	And also in those event handlers, for every line that put you into a smash attack like this...
		inst.sg:GoToState("fsmash_start")
	Replace each of those lines with this block of code, respective to their direction:
		if tiltstick == "smash" then
			inst.sg:GoToState("fsmash_start")
		else
			inst.sg:GoToState("ftilt")
		end
	
	in the state  name = "ll_medium_getup"   add the following state tag to the "tags" table
		"can_grab_ledge"
	The tags should now look like this:
		tags = {"busy", "can_grab_ledge"}, 
	Do the same for the "run_stop" state, adding "can_grab_ledge" to the tags
	
	
	In the state  name = "dash_start",  Add the following block of code to the "events" section:
		EventHandler("cstick_side", function(inst, data)   
			inst.components.locomotor:FaceDirection(data.key)
			inst.sg:GoToState("fsmash_start")
		end), 
	
	
	In the state  name = "ledge_drop",  Add the following state tag to the "tags" table (don't forget to seperate them with a comma)
		"no_fastfalling"
		
	
	In the state  name = "thrown",   Add the following block of code underneath the onenter fn:
		timeline =
        {
			TimeEvent(30*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
			end),
        },
	
	
	Find the following block of code in the "throwattack" eventhandler (around line 430):
		if data.key == "backward" or data.key == "diagonalb" then 
			inst.sg:GoToState("bair")
		elseif data.key == "forward" or data.key == "diagonalf" then
			inst.sg:GoToState("fair")
	
	Replace it with this:
		if data.key == "backward" then 
			inst.sg:GoToState("bair")
		elseif data.key == "diagonalb" then 
			if inst.components.stats.tapjump then
				inst.sg:GoToState("bair")
			else
				inst.sg:GoToState("uair")
			end
		elseif data.key == "forward" then 
			inst.sg:GoToState("fair")
		elseif data.key == "diagonalf" then
			if inst.components.stats.tapjump then
				inst.sg:GoToState("fair")
			else
				inst.sg:GoToState("uair")
			end
			
			
	Find the following line (it appears twice):
		if is_attacking or is_busy then return end
	Replace both lines with this:
		if is_busy then return end
		
		
	----Find the following line in the C_STICK_UP event handler only:
	----	if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event == "jump" then
	----Replace it with this:
	----	if inst.sg:HasStateTag("listen_for_jump") and inst.components.stats.event == "jump" and inst.components.stats.key2 ~= "tapup" then
		
	
	Find the following:
		EventHandler("cstick_up", function(inst)
	Replace with this:
		EventHandler("cstick_up", function(inst, data)
	And do the same to the "cstick_down"  event handler
		
	Add the following line into the "cstick_up" event handler
		if data and data.key == "backward" and not (is_busy or airial) then
			inst.components.locomotor:TurnAround()
		end
	And add the same thing to the "cstick_down"  event handler

	
	Find the following line of code:
		elseif not inst.sg:HasStateTag("busy") or can_attack then
	Add this block of code above it:
		elseif inst.sg:HasStateTag("can_usmash") and inst.components.stats.tapjump and (data.key == "up" or data.key == "diagonalf" or data.key == "diagonalb") then
			inst.sg:GoToState("uptilt")

	
	Find the following line:
		if (inst.sg:HasStateTag("can_usmash") or can_ood) or not is_busy and not airial then
	Replace it with this:
		if (inst.sg:HasStateTag("can_usmash") or can_ood) and inst.components.stats.tapjump or not is_busy and not airial then
	
	
	Find the following line:
		if can_oos or (data.key == "block" and not airial) then
	Add this line directly underneath it:
		if data.key2 == "backward" then inst.components.locomotor:TurnAround() end
	
]]




--double check disjointed hitboxes on most moves
--btw, yes the visibility on spectators now breaks. (i think that means the hitboxes would also now be tangible when players join? Careful with that...)
--okay, this is just too big of a change right before launch. Maybe we can combine these methods and have it spawn spectator prefabs normally, unless in lobby mode?
----Forget it. We can keep the new system we implimented, but we should make the DefaultFighter "spectator" to avoid any issues. That way modders can still use it, then turn it off later

--@tapsmash, plz
--maybe this is all i need to get rid of? inst:AddComponent("giftreceiver")
--Remove the dusk jingle
--local p2 keys
--run_start footstep sound
--maybe if tapjump=on and up+atk at same time, uptilt instead of jump uair?
--wilson's full run anim has no footstep sounds. his full dash does though





-- 3-9-19 LETS GIVE THIS ANOTHER SHOT. I THINK I CAN MAKE THE STAGE GENERATION PHASE FORCE THE WORLD TO USE THIS GAMEMODE IF IT WORKS
game_modes =
{
	{
		name = "smashup",
		label = "Smashup",
		description = "Knock your opponents off-stage in this 2D fighting game mode!",
		settings =
		{
			text = "Smashup",
			description = "Knock your opponents off-stage in this 2D fighting game mode!",
			-- level_type = 1, --LEVELTYPE.SURVIVAL, --I GUESS?  --OOOKAY OR JUST DONT TOUCH THIS ONE
			-- level_type = "CUSTOM", --IM ABOUT TO FLIP MY     --ARE YOU TELLING ME THESE GAME MODES OVEWRITE EACH OTHER EVEN IF THE MOD ISNT ENABLED?...
			mod_game_mode = true,
			spawn_mode = "fixed",
			resource_renewal = false,
			ghost_sanity_drain = false,
			ghost_enabled = false,
			portal_rez = false,
			reset_time = nil,
			invalid_recipes = nil,
			
			override_item_slots = 0,
			no_crafting = true,
			no_minimap = true,
			no_hunger = true,
			no_eating = true,
			no_sanity = true,
			no_temperature = true,
			no_avatar_popup = true,
			no_morgue_record = true,
			disable_transplanting = true,
			disable_bird_mercy_items = true,
			-- ghost_sanity_drain = true,
			-- portal_rez = true
			--see other setting options in gamemodes.lua
		}
	},
}




configuration_options =
{
	{ 
        name = "Language", --8-31-21 GOTTA CAPITALIZE ON THAT AISAN MARKET YO
        label = "1. Language",
        hover = "Default language.",
        options =
        {
            {description = "Auto detect",  data = "auto",  hover = "Auto detect" },
            {description = "English",  data = "en",  hover = "English" },
            {description = "简体中文",   data = "sch", hover = "Simplified Chinese"},
            {description = "Русский",  data = "ru",  hover = "Russian"},
        },
        default = "auto",
    },
	
	{
        name = "MatchSize",
        label = "2. Match Player Limit",
		hover   = "Maximum number of fighters per match. ",
        options =
        {
		    -- {description = "1", data = 1}, --WHY WOULD I MAKE THIS AN OPTION?
			{description = "1v1", data = 2},
            {description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
			{description = "6", data = 6},
			{description = "Unlimited", data = 99},
       },
        default = 4,
    },

	{
        name = "MatchLives",
        label = "3. Lives",
        options =
        {
		    {description = "1", data = 1},
			{description = "2", data = 2},
            {description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
			{description = "6", data = 6},
			{description = "7", data = 7},
			{description = "8", data = 8},
			{description = "9", data = 9},
			{description = "10", data = 10},
			{description = "Unlimited", data = 11}, --THIS NUMBER IS ACTUALLY TREATED AS INFINITE BY THE SPAWNER
       },
        default = 3,
    },
	
	
	{
        name = "MatchTime",
        label = "4. Time Limit (Per-Life)",
		hover   = "Match time limit (multiplied by lives-per-player)",
        options =
        {
		    {description = "0:30", data = 0.5},
			{description = "0:45", data = 0.75},
            {description = "1:00", data = 1},
			{description = "1:15", data = 1.25},
			{description = "1:30", data = 1.5, hover = "Reccomended"},
			{description = "1:45", data = 1.75},
			{description = "2:00", data = 2},
			{description = "2:15", data = 2.25},
			{description = "2:30", data = 2.5},
			{description = "3:00", data = 3},
			{description = "5:00", data = 5},
			{description = "10:00", data = 10},
       },
        default = 1.5,
    },
	
	{ --5-20-20
		name = "QueCycle",
        label = "5. Player Rotation",
		hover   = "Determines how players are sorted in the queue at the end of a round",
        options =
        {
		    {description = "Rotate All", data = 1,  hover = "All players rotate through the queue normally."},
			{description = "Winner Stays", data = 2,  hover = "The winner continues to play. Everyone else rotates through the queue normally."},
			--UNFORTUNATELY I DONT YET HAVE A METHOD TO DETERMINE THE LOSER
       },
        default = 1,
	},
	
	{ -- 8-22-20
		name = "ServerGameMode",
        label = "6. Server Game-Mode",
		hover   = "Designate a specific game-mode that the server always runs, or allow the game-mode to be changed at any time by hosts/admins, or anyone",
		-- admins/anyone to choose a new game-mode at any time",
        options =
        {
		    {description = "Anyone's Choice", data = 1,  hover = "Anyone can change the game mode at any time. Not good with randos"},
			{description = "Admin's Choice", data = 2,  hover = "The server owner may choose the game-mode"},
			{description = "PvP Only", data = 3,  hover = "The server only runs PvP mode"},
			{description = "Horde Only", data = 4,  hover = "The server only runs Horde mode"},
			{description = "VS-AI Only", data = 5,  hover = "The server only runs VS-AI mode"},
       },
        default = 2,
	},
	
	{ 
		name = "BonusFighter", --FOR THE UNLOCKABLE SPIDER WARRIOR
        label = "Bonus Fighter",
		hover   = "Enable or Disable the unlockable character from the character select screen",
        options =
        {
		    {description = "Never Playable", data = 1},
			{description = "Unlockable", data = 2}, --IM KINDA HOPING THEY DON'T JUST FIND THIS OPTION RIGHT AWAY AND ENABLE IT WITHOUT EVEN PLAYING
			{description = "Always Playable", data = 3},
       },
        default = 2,
	},
	
	
	--THIS IS DUMB, WE DONT NEED THIS --ACTUALLY, SURE WE CAN USE THIS TO ENABLE OR DISABLE DEBUG KEYS
	{ --5-20-20  
		name = "ModMode",
        label = "Dev Settings",
		hover   = "Enables developer keys, like Ctrl-R to reload scripts and square bracket keys to adjust timescale. ",
        options =
        {
		    {description = "Off", data = 1},
			{description = "On", data = 2, hover = "Caves must be disabled to use this feature fully."},
            -- {description = "Demo-Mode", data = 3}, --NAH WE DONT NEED THIS
       },
        default = 1, --DONT FORGET TO CHANGE THIS TO 1 BEFORE LAUNCHING IT
	},
	
	
	{ 
		name = "VisibleBoxes",
        label = "Visible Hitboxes",
		hover   = "Shows hitboxes (red), hurtboxes (yellow), and more, for development purposes. Caves must be disabled to use this feature.",
        options =
        {
		    {description = "None", data = 1},
			{description = "Hitboxes", data = 2},
            {description = "Hurtboxes", data = 3},
			{description = "Both", data = 4,  hover = "Hitboxes(red) and Hurtboxes(yellow)"},
			{description = "All", data = 5,  hover = "Hitboxes(red), Hurtboxes(yellow), Grabboxes(white), LedgeGrabBoxes(blue), Collisionboxes(white), and more"},
       },
        default = 1,
	},
	
	
	{ 
		name = "EnableLocalPlay",
        label = "Local Multiplayer",
		hover   = "(Work-in-progress) Enables two-player mode on the same keyboard. Not compatible with online multiplayer",
        options =
        {
		    {description = "Disabled", data = 1},
			{description = "Enabled", data = 2, hover = "Caves must be disabled to use this feature."},
       },
        default = 1,
	},
	
}

