local PopupDialogScreen 	= require("screens/popupdialog")
-- local HuntOverDialogScreen 	= require("screens/huntoverdialog")
local LobbyScreen	 		= require("screens/lobbyscreen")
local Text 					= require "widgets/text"

local _SmashGameLogic = nil

--MATCHMAKING AND QUEUE SYSTEM BASED OFF OF KLEI'S HUNTGAMELOGIC COMPONENT FROM "THE HUNT" SAMPLE MOD


--1-1-2018 
function StageGenMessage()
	
	--A MESSAGE FOR THE INITIAL SERVER AUTO-RESTART
	-- local text = "First-time stage detected \n"
	-- text = text .. "A restart is required to finish the stage setup. \n"
	-- text = text .. "Server will auto-restart in 5 seconds... \n"
	local text = STRINGS.SMSH.STAGEGEN_MSG
	
	--"Almost Ready..."
	-- local hunt_message = PopupDialogScreen( STRINGS.SMSH.HUNT_MSG_1, text, {{text=STRINGS.SMSH.HUNT_MSG_2, cb = function() TheFrontEnd:PopScreen() end}} )
	-- hunt_message.text:SetPosition(5, 0, 0)
	-- hunt_message.menu:SetPosition(0, -80, 0) 
	-- TheFrontEnd:PushScreen( hunt_message )
	if ThePlayer and ThePlayer.stagegenmsgnetvar then
		print("LOADING THE STAGE!")
		ThePlayer.stagegenmsgnetvar:set("SHOWME")
	end
end



--9-23-17 A RESULTS SCREEN AFTER THE STAGE HAS RESET --NOPE, DOESNT WORK FOR CLIENTS. WINNER IS NOW DISPLAYED IN ENDGAME SCREEN ANYWAYS


local OnPlayerActivated = function()
	-- IntroMessage() --NAH...
	StageGenMessage()
end

local function OnHuntKillsDirty(inst)
    inst.components.SmashGameLogic.hunt_kills = inst.components.SmashGameLogic.net_hunt_kills:value()
end


--9-7-17 ADDING CUSTOM FUNCTIONS FROM ANCHOR

--6-10-18 -TESTING HORDEMODE WITH FORCED ENABLED
local forcehordemode = false --WAIT, WHY IS THIS HERE? I DONT THINK THIS WORKS
-- local forcelobbymode = false --5-4-20 REALLY JUST FOR RECORDING TRAILERS. --MAKING A GLOBAL


local function OnPlayerJoined(inst, player, state)
    -- for i, v in ipairs(inst._activeplayers) do
	local anchor = TheSim:FindFirstEntityWithTag("anchor") --9-7-17
	
	if TRAILERMODE then return end --JUST STAY IN LOBBY MODE FOREVER
	
	--11-4-20 DON'T DO ANYTHING FOR MAXWELLS CLONES
	if player:HasTag("dummynpc") then return end --WOW, IM SURPRISED THE TAGS HAVE ALREADY APPLIED BY THE TIME IT REACHES THIS
	
	if forcehordemode then
		anchor.components.gamerules.hordemode = true
		--THESE ARE SPECIFIC TO 
		anchor.components.gamerules.matchpoollimit = 2
		anchor.components.gamerules.matchlives = 1
	end
	
	--9-23-17 THESE GAMESTATES ARE GETTING ANNOYING.
	if anchor.components.gamerules.matchstate == "transition" then
		anchor.components.gamerules:ChangeMatchState("countdown")
	end
	--9-23-17 -JUST... HOPE NOBODY JOINS THE SERVER BETWEEN ENDGAME AND PREP
	if anchor.components.gamerules.matchstate == "endgame" then
		anchor.components.gamerules:ChangeMatchState("prep") 
	end
	
	--11-28-17 IF PLAYERS HAVE JUST JOINED, RESET THE TIMER TO GET NEXT PLAYER IN LINE, OR ELSE IT MIGHT TAKE THEM BEFORE THEY HAVE FINISHED INITIALIZING
	if anchor.quetask then
		print("PLAYER JOINED MID QUETASK - CANCELING QUETASK")
		anchor.quetask:Cancel()
		anchor.quetask = nil
	end
	
	-- ALRIGHT, WE MIGHT NEED A DELAY TO ALLOW ALL THE TAGS TO APPLY PROPERLY BEFORE WE COUNT EVERYTHING... --9-14-17 
	anchor:DoTaskInTime(0, function() --HOPEFULLY THIS WONT BREAK ANYTHING
		
		--10-13-21 PASS IN OUR HORDE UNLOCK LEVEL FOR THEIR SELECT SCREENS
		if player.unlockstatusnetvar then
			print("UNLOCK NETVAR DETECTED!")
			player.unlockstatusnetvar:set(anchor._unlockteir:value()) --MY EXPECTATIONS ARE LOW, BUT I WOULD REALLY APPRECIATE IT IF THIS WORKED
		end
		
		--9-14-17 THIS WILL COUNT THE NUMBER OF DUMMY NPCs THAT SHOULD NOT BE COUNTED AS REAL PLAYERS
		local npccount = 0 --ALSO HAPPY 2nd ANIVERSERY TO THE START OF THIS MOD OOPS I WANTED IT TO BE DONE BY NOW  --10-14-21 lol you naive child
		for i, v in ipairs(AllPlayers) do
			if v:HasTag("dummynpc") then
				npccount = npccount + 1 --5-23-20 DISABLING ONLY FOR TESTING
			end
		end
		
		
		for i, v in ipairs(AllPlayers) do
			-- print("ACTIVE PLAYER COUNTED", v)
		end
		local playercount = #AllPlayers - npccount  --i - npccount
		
		if (playercount >= 2 and anchor.components.gamerules.matchstate == "lobby") --then  --ITS SUPPOSED TO BE 2, SETTING IT TO 1 FOR TESTING      --8-19-20 vvv AND THEN I FORGOT :)
			or (playercount >= 1 and anchor.components.gamerules.matchstate == "lobby" and anchor.components.gamerules.hordemode == true) --6-10-18 FOR TESTING ONLY!! REMOVE WHEN DONE
			or (playercount >= 1 and anchor.components.gamerules.matchstate == "lobby" and anchor.components.gamerules.localp2mode == true) then --7-4-18 -FOR LOCAL MULTIPLAYER
		-- if i >= 2 and state == 0 then
			--[[
			anchor.components.gamerules:ChangeMatchState("prep") --GETTING READY TO START
			TheWorld:AddTag("gamestate.prep") --9-9-17
			TheNet:Announce("Players found! Starting new match.") --OH WAIT.... YOU CAN'T SEE THE NET MESSAGES BEHIND THE BADGES...
			
			--10-15-17 SETS UP ALL THE PLAYERS
			anchor.components.gamerules:MoveQueToMatch()
			
			anchor:DoTaskInTime(3, function() --GIVE THEM A SEC TO INITIALIZE PLAYERCONTROLER FIRST SO IT WONT CRASH
				anchor.components.gamerules:ClearLobbyList() --9-24-17 
				print("STAGE RESET DUE TO PLAYERS JOINING")
				anchor.components.gamerules:StageReset() --!!! THIS COULD BE AN ISSUE FOR PLAYERS JOINING SO CLOSE TO EACH OTHER
			end)
			
			anchor:DoTaskInTime(15, function() --FOR TESTING, JUST ASSIME THEYVE PICKED IN 10 SECONDS
				-- anchor.components.gamerules.matchstate = "running" 
				TheWorld:AddTag("gamestate.running") --9-9-17
				-- local trafficrock = SpawnPrefab("seeds") --TRAFFIC ROCK PHASE 2 TO SIGNIFY MATCH RUNNING
			end)
			break --WE BREAK HERE SO THAT THIS DOEST RUN MULTIPLE TIMES PER PLAYER IN THE SERVER 
			]]
			
			--8-21-20 WE NOW JUST EDIT THIS VALUE AND LET THE PLAYERS CHOOSE WHEN TO ACTUALLY HIT THE START BUTTON
			anchor._sessionready:set(true)
		end
		
		
		--9-9-17 HOW ABOUT....
		if anchor.components.gamerules.matchstate == "prep" then 
			-- print("CHECKING IF PLAYER IN MATCHPOOL")
			anchor.components.gamerules:PrintQues()
			if anchor.components.gamerules:IsPlayerInMatchPool(player) then --10-15-17 ONLY LET THOSE IN THE "MATCHPOOL" CHOOSE
				--9-16-17 TRYING SOMETHING TO MANUALLY TELL CLIENTS TO SHOW SCREEN
				-- print("--PLAYER IS IN MATCH POOL. ADDING SELECT SCREEN TAG")
				player:AddTag("showselectscreen")  --SHOULDNT I JUST MAKE THIS A NETVAR OR SOMETHING??
				-- player:AddTag("choosingcharacter") --9-22-17 WILL BE REMOVED WHEN THEY SELECT ONE --5-23-20 SEEMS UNUSED NOW
			else
				player:AddTag("spectator")
				player:AddTag("waitinline")
			end
		end
		
		
		--9-10-17 --IF RUNNNG, ADD SPECTATOR TAG TO PLAYER BEFORE SELECT SCREEN SHOWS UP
		if anchor.components.gamerules.matchstate == "running" then
			if not player:HasTag("dummynpc") then
				player:AddTag("spectator")
			end
			player.jumbotronheader:set(STRINGS.SMSH.JUMBO_SPECTATE) -- "Spectate-Mode. Waiting for match to end..."
		end
		
		
		
		-- 9-18-17 IF PLAYER SEEMS TO BE ONLY ONE HERE, JUST AUTOSPAWN -- TRYING AGAIN   --11-28-18 -BUT NOT IF WE'RE TRYING TO SPAR WITH HAROLD
		-- if playercount == 1 and anchor.components.gamerules.matchstate == "lobby" and anchor.components.gamerules.cpulevel == nil then
		if anchor.components.gamerules.matchstate == "lobby" then --8-22-20 I SEE NO REASON WHY THIS SHOULDNT WORK. RIGHT?
			if not player:HasTag("dummynpc") then --ALLOW DUMMY NPCs IN LIKE MAXCLONES OR MEAT DUMMIES
				player:AddTag("autospawn")
				
				--9-24-17 IF PLAYER IS A SPECTATOR JOINING LOBBY MODE, FORCE THEM TO TURN INTO WILSON.
				--SECOND WIND!! LETS TRY THIS VERSION. A TABLE THAT KEEPS TRACK OF PLAYERS ADDED TO THE LOBBY
				if not anchor.components.gamerules:LobbyGuestList(player:GetDisplayName()) then --THIS FUNCTION CHECKS IF THEYRE ON THE LIST, AND THEN ADDS THEM TO IT IF THEY ARENT
					player:AddTag("forcewilson")
				end
				
				player.components.stats.lives = 11 --11 THE SPECIFIC NUMBER FOR THE "INF" HUD IDENTIFIER
				player:PushEvent("livesdelta") --AND UPDATE THE HUD
			end
		end
		
		
		
		if anchor.components.gamerules.matchstate == "lobby" then  --WHEN THERES NOT ENOUGH PLAYERS FOR THE GAME TO START YET
			-- TheNet:Announce("Waiting for players...")
			if player.jumbotronheader then --10-8-17
				player.jumbotronheader:set(STRINGS.SMSH.JUMBO_WAITING4PLYRS) -- "Waiting for other players..."
			end
			
			--9-27-17 GIVE THEM SOMETHING TO BAT AROUND WHILE THEY WAIT IN LOBBY MODE
			if not TheSim:FindFirstEntityWithTag("punchingbag") then
				local dummy = SpawnPrefab("punchingbag")
				dummy:AddTag("dummynpc")
				dummy:AddTag("punchingbag")
			end
		end
			
	end)
	
	
	if not player:HasTag("dummynpc") then
		--10-15-17 ADD PLAYER TO QUE
		anchor.components.gamerules:AddToQue(player) --IF THEYRE ALREADY THERE, IT WONT JOIN
	end

    -- inst:ListenForEvent("performaction", inst._OnPlayerAction, player)
    -- table.insert(inst._activeplayers, player)
end


--9-3-17 - WHEN ANYONE LEAVES THE SERVER
local function OnPlayerLeft(inst, player)
	
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	
	--9-16-17 REMOVE ALL OF THE PLAYER'S LIVES AND KO THEM AS THEY WALK OUT THE DOOR
		--OKAY, I'M PUTTING THIS IN PLAYER_COMMON UNDER THE ONDESPAWN() FN
	
	local npccount = 0 --9-14-17 DUMMY NPC COUNT
	for i, v in ipairs(AllPlayers) do
		if v:HasTag("dummynpc") then
			npccount = npccount + 1
		end
	end
	
	local plyrcount = 0
	for i, v in ipairs(AllPlayers) do
		plyrcount = i --COUNTS THE TOTAL NUMBER OF PLAYERS REMAINING IN THE SERVER
    end
	
	local plyrcount = plyrcount - npccount --NUMBER OF PLAYERS EXCLUDING DUMMIES
	
	if anchor.components.gamerules.matchstate ~= "lobby" then --9-12-17 REMOVE ALL PLAYER'S LIVES WHEN THEY LEAVE
		anchor.components.gamerules:RemoveFromPlayerTable(player) --I HOPE THE STALE COMPONENT REFERENCE WONT BE A PROBLEM
	end
	
	
	if plyrcount == 2 and anchor.components.gamerules.matchstate ~= "lobby" and anchor.components.gamerules.hordemode == false then --ONLY RESTART IF THERE IS ONE PLAYER IN GAME. NOT 0
		print("A DISCONNECT LEFT 1 PERSON REMAINING IN THE SERVER. RETURNING TO LOBBY")
		anchor.components.gamerules:ChangeMatchState("lobby") --SET TURN THE GAME BACK TO LOBBY MODE ON RESTART TO WAIT FOR MORE PLAYERS
		TheNet:Announce(STRINGS.SMSH.JUMBO_PLAYERS_LEFT) --"Players left. Entering practice mode"
		
		local segs = { day = 1, dusk = 0, night = 0, time = 30} --BRING OUT THE SUNSHINE!
		TheWorld:PushEvent("ms_setclocksegs", segs)
		
		anchor.components.gamerules:ClearLobbyList() --9-24-17 SO WHOEVER IS LEFT WILL SPAWN AS THE DEFAULT
		anchor.components.gamerules:StageReset()
	end
	
	--9-30-20 CAN WE ALSO DO THIS?? SO THE PLAYER'S CHOSEN CHARACTER ISN'T SAVED?
	-- TheWorld:PushEvent("ms_playerdespawnanddelete", player)  --OH BOY, THIS SEEMS TO CAUSE... PROBLEMS...
end







--11-25-17 TRYING TO CATCH A FEW RARE BUGS IN THE ACT!!
local function AngelVision(inst, player)
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	
	print("ANGEL VISION ACTIVE!")
	for i, v in ipairs(AllPlayers) do
		print("ANIMATION DATA ", (v.AnimState:GetCurrentAnimationTime()*FRAMES),  (v.AnimState:GetCurrentAnimationLength()*FRAMES), v)
		print("COLOR DATA ", (v.AnimState:GetMultColour()),  (v.AnimState:GetAddColour()))
		if v.sg then 
			print("STATE DATA ", (v.sg.currentstate.name),  (v.AnimState:IsCurrentAnimation("idle")))
		end
	end
	
end


--TUNING VARS:
local select_time_limit = 45 --45

local SmashGameLogic = Class(function(self, inst)
    _SmashGameLogic = self
	self.inst = inst


	--5-22-20 TIMER FOR PLAYERS TO SELECT THEIR CHARACTERS
	self.playerselect_timer = select_time_limit
	
	--Server only code
	if TheWorld.ismastersim then --LETS DISABLE ALL THIS FOR NOW. IT COULD BE USEFUL LATER ON, BUT LETS START SMALL
		
		--9-7-17 THIS IS THE ORIGINAL MATCH STATE STUFF THAT WAS IN ANCHOR.LUA
		--NOTE, THIS IS FOR WHEN A PLAYER ENTERS THE WORLD, NOT JOINS THE SERVER.
		inst:ListenForEvent("ms_playerjoined", function(src, player) OnPlayerJoined(inst, player) end, TheWorld)
		--10-9-20 WOW SO IT REALLY TOOK ME THIS LONG TO FIND THE EVENT THAT LISTENS FOR NON-NPC USERS SPAWNING 
		-- inst:ListenForEvent("playeractivated", function(src, player) OnPlayerJoined(inst, player) end, TheWorld)
		--NOOOOPE!! I GUESS THIS ONLY APPLIES TO THE CLIENT PLAYER JOINING. TOTALLY BREAKS WHEN OTHERS JOIN
		
		-- inst:ListenForEvent("ms_playerjoined", function(src, player, self.hunt_state) OnPlayerJoined(inst, player) end, TheWorld)
		--PLAYERLEFT ALSO RUNS ON PLAYERDESPAWNANDDELETE, MAKING THINGS PRETTY HARD. PERHAPS DISCONNECT WILL WORK BETTER
		inst:ListenForEvent("ms_playerdisconnected", function(src, player) OnPlayerLeft(inst, player) end, TheWorld)
		
		
		
		--9-22-17	--HANDLES THE PART WHERE PLAYERS ARE ALL AT THE CHARACTER SELECT SCREEN
		inst:DoPeriodicTask(0.5, function() self:ManagePrepPhase(inst) end)
		
		--11-25-17 SINCE THERE ARE A FEW RARE BUGS THAT ARE HARD TO REPLICATE, I'M GOING TO BE RUNNING A TESTER AT ALL TIMES TO CHECK ON THESE THINGS
		-- inst:DoPeriodicTask(4, function() AngelVision(inst) end) --ALWAYS WATCHING...
		--3-31-19 -HAVEN'T SEEN THIS BUG IN A WHILE, SO I'M GONNA TURN IT OFF FOR NOW
		
		self.inst:ListenForEvent("playeractivated", function()
			local anchor = TheSim:FindFirstEntityWithTag("anchor")
			if anchor:HasTag("pregeneration") then
				StageGenMessage()
			end
		end, TheWorld)
		
	end
	
	self.inst:StartUpdatingComponent(self)
end)




--5-28-20 BEFORE STARTING, CHECK TO MAKE SURE WE ACUALLY HAVE ENOUGH PLAYERS
function SmashGameLogic:CheckFighterCount()
	-- print("HEADCOUNT BEFORE WE START")
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local playerstotal = #anchor.components.gamerules.matchpool
	local dropouts = 0 --NUMBER OF PLAYERS WHO SELECTED SPECTATOR OR FAILED TO SELECT BEFORE THE TIMER ENDED
	
	--IF WE'VE DETERMINED WE ARE ABOUT TO RESTART, DON'T RUN ANYTHING PAST THIS
	if anchor.quetask then 
		-- print("STOP COUNTING HEADS! WE'RE ABOUT TO TRANSITION")
		return true end--RETURN END, BUT RETURN TRUE FIRST BECAUSE THEY NEED TO KNOW WE ARENT WAITING FOR ANYONE 
	
	for i, v in ipairs(AllPlayers) do 
		if anchor.components.gamerules:IsPlayerInMatchPool(v) then --ONLY TO PLAYERS WHO WERE SUPPOSED TO SELECT A CHAR
			-- v:PushEvent("force_end_charselect") --CANT DO THIS. GOTTA USE A NETVAR
			v.timeoutnetvar:set("SET") --EVEN THOUGH THE VALUE DOESNT MATTER
			-- if v:HasTag("select_bailed") then --OKAY, THIS DOESNT APPLY FAST ENOUGH. 
			if not v:HasTag("readyfreddy") or v:HasTag("select_bailed") then --LETS DO THIS INSTEAD?
				v:AddTag("select_bailed")
				dropouts = dropouts + 1
				-- TheNet:Announce("--1 Failed to select char")
				print("DROPOUT DETECTED", v, v:HasTag("readyfreddy"), v:HasTag("select_bailed"))
			end
		end
	end
	
	--6-6-20 REPURPOSED FROM BELOW, IF A PLAYER ISNT PRESENT AT THE SELECT SCREEN FOR WHATEVER REASON, CONSIDER THEM A DROPOUT
	for i, v in ipairs(anchor.components.gamerules.matchpool) do --COMPARE THE MATCHPOOL LIST WITH ALL CURRENT PLAYERS
		if not anchor.components.gamerules:DoesPlayerExist(v) then --NEEDS TO CHECK IF THEY EXIST
			anchor.components.gamerules:RestackQues() --THIS SHOULD REMOVE ANY MISSING PLAYERS WITHOUT MESSING UP THE QUE... RIGHT?
			TheNet:Announce(STRINGS.SMSH.JUMBO_DROPOUT) --"MISSING PLAYER DETECTED!"
			TheNet:Announce(STRINGS.SMSH.JUMBO_STARTING_ANYWAY) --"STARTING WITHOUT THEM"
			dropouts = dropouts + 1
		end
	end
	--IF THAT SILENT DROPOUT LEFT US AT ONLY 1 PLAYER, PUT US BACK INTO LOBBY MODE --WELL NOW THIS ALSO HAPPEN IF SOMEONE JUST SPECTATES IN A GROUP OF 2 BUT OK
	if dropouts >= 1 and #anchor.components.gamerules.playerque == 0 and ((playerstotal - dropouts <= 1 and anchor.components.gamerules.gamemode == "PVP") or (playerstotal - dropouts == 0))  then
		print("WOOPS, NOT ENOUGH PLAYERS LEFT NOW. RETURNING TO LOBBY", playerstotal, dropouts)
		anchor.components.gamerules:ChangeMatchState("lobby")
		anchor.components.gamerules.gamemode = "PRACTICE"
		print("--ALTERING SERVER GAMEMODE (ALT): ", "PRACTICE")
		return end
	
	
	--5-31-30 WE CANT JUST CHECK FOR MATCHPOOL, WE'RE CYCLING PEOPLE IN AND OUT DURING THIS LOOP. CREATE A TEMPORARY LIST OF THE MATCHPOOL BEFORE WE START
	local matchpool_snapshot = {}
	
	--DO WE HAVE ANY DROPOUTS?
	if (playerstotal - dropouts) < playerstotal then --SHOULDNT THIS JUST CHECK IF DROPOUTS >1?
		print("--Too few players to begin; retrying--")
		anchor.components.gamerules:PrintQues()
		--CANCEL THE CHARACTER SELECTIONS FOR THOSE WHO ALREADY SELECTED
		for i, v in ipairs(AllPlayers) do
			-- v.jumbotronheader:set(STRINGS.SMSH.JUMBO_NOT_ENOUGH_PLAYERS) --"Too Few Players To Start - Retrying"
			--PASS PLAYERS THAT WERE PREVIOUSLY IN THE MATCHQUE INTO THIS TEMPORARY VERSION
			if anchor.components.gamerules:IsPlayerInMatchPool(v) then
				table.insert(matchpool_snapshot, v)
			end
		end
		
		
			
		for i, v in ipairs(matchpool_snapshot) do
				if v:HasTag("select_bailed") then 
					--SEND THE BAILERS TO THE BACK OF THE LINE
					v.jumbotronheader:set(STRINGS.SMSH.JUMBO_NO_SELECTION) --"No Selection Made"
					anchor.components.gamerules:RemoveFromMatchQue(v) --TAKE THEM OUT OF THE CURRENT MATCHQUE
					-- print("--BAILERS REMOVED FROM MATCHQUE--")
					anchor.components.gamerules:PrintQues()
					
					anchor.components.gamerules:AddToQue(v) --PUT THEM BACK AT THE END OF THE LINE
					--MAYBE INVITE THE NEXT IN LINE TO TAKE THEIR PLACE
					print("--BAILER HAS BEEN BUMPED TO THE END OF THE LINE. NEXT PLEASE!--")
					-- anchor.components.gamerules:GetNextInLine() --THIS SHOULD SUFFICE
					-- print("--THE NEXT PARTICIPANTS SHOULD NOW BE IN THE BAILER'S PLACE--")
					-- anchor.components.gamerules:PrintQues()
					--HEY NICE! c:
					if not anchor.components.gamerules:IsSpectateOnly(v) then --2-4-22 LEAVE THEM ON IF THEYRE SPECTATE ONLY
						v:RemoveTag("select_bailed") --5-31-20 ALRIGHT, TAKE OFF THE HANDCUFFS
					end
				end
			-- end
		end
		
		
		--OKAY, NOW THAT THE BAILERS ARE GONE, WE CAN START CYCLING BACK IN
		--9-27-20 BUT FIRST!!! COUNT HOW MANY WE WANT TO LET BACK IN. SO WE DON'T ATTEMPT TO RESTACK THE QUEUE FOREVER
		local reentrycount = #anchor.components.gamerules.playerque - dropouts --# OF PPL WAITING IN LINE, EXCLUDING THE DROPOUTS
		local gatecounter = reentrycount
		--THIS NUMBER WILL BE NEGATIVE IF THERE ARE NO PLAYERS IN THE QUEUE EXCLUDING THE DROPOUTS. THEN WE WON'T TRY AND BRING IN REPLACEMENTS
		
		anchor.components.gamerules:PrintQues()
		while anchor.components.gamerules:IsMatchpoolFull() == false and (gatecounter > 0) do
			print("--BRING IN A REPLACEMENT--")
			anchor.components.gamerules:GetNextInLine() --THIS SHOULD SUFFICE
			gatecounter = gatecounter - 1 --9-27-20
		end
		print("--THE NEXT PARTICIPANTS SHOULD NOW BE IN THE BAILER'S PLACE--")
		anchor.components.gamerules:PrintQues()
		
		
		--9-27-20 IF WE AREN'T ABOUT TO REPLACE ANY BAILERS, AND THERE IS STILL AT LEAST ONE PERSON READY TO PLAY...
		if reentrycount < 1 and #anchor.components.gamerules.matchpool >= 1 then 
			print("--IF YOU DON'T MIND PLAYING BY YOURSELF, I GUESS--")
			for i, v in ipairs(AllPlayers) do
				v.jumbotronheader:set(STRINGS.SMSH.JUMBO_STARTING_W_PARTIAL) --"Starting match with spectators"
			end
			return true --SURE, GO FOR IT I GUESS. IF YOU DON'T MIND PLAYING BY YOURSELF
			
		--ELSE BRING THINGS BACK AROUND FOR ANOTHER LOOP OF CHARACTER SELECT, AS USUAL
		else 
			--1-13-22 MOVING THIS MESSAGE HERE, SINCE THIS SHOULD ONLY SHOW IF WE ARE ACTUALLY RE-SELECTING CHARACTERS
			for i, v in ipairs(AllPlayers) do
				v.jumbotronheader:set(STRINGS.SMSH.JUMBO_NOT_ENOUGH_PLAYERS) --"Too Few Players To Start - Retrying"
			end
			
			--10-2-20 OK NOW WE CAN REVERT CHARACTER SELECTS, KNOWING THAT WE WONT BE RUNNING THE GAME
			for i, v in ipairs(matchpool_snapshot) do
				v.revertnetvar:set("REVERT_CHARSELECT") --MAYBE THIS WILL WORK BETTER THAN THE PUSH EVENT
				--LET THEM RE-SELECT CHARACTER UPON RESET
				v:AddTag("showselectscreen")  --OR DO WE?
				v:RemoveTag("readyfreddy") --5-31-20 WE NEED THIS OR ELSE IT'LL THINK WE'VE ALREADY CHOSEN 
				-- print("REVERTING ALL SELECTIONS")
			end
			
			--9-27-20 IF SOME JOKER PICKED SPECTATOR EVEN THO HE'S THE ONLY ONE IN THE QUEUE, SNAP SOMEONE BACK IN
			if #anchor.components.gamerules.matchpool == 0 then
				-- print("WELL SOMEONES GOTTA CLOSE UP SHOP")
				anchor.components.gamerules:GetNextInLine()
			end
			
			--WHATS THIS DUMB HALTSTATE THING?? USE QUETASK INSTEAD. QUETASK IS ANY TIMER LINKED TO CHANGING STATES AND RESPAWNING PLAYERS
			-- if anchor.components.gamerules.haltstate == false then 
			anchor.quetask = anchor:DoTaskInTime(3, function(anchor) --GIVE EM A SEC TO READ THE MESSAGES ON SCREEN
				anchor.components.gamerules:PrintQues()
				anchor.components.gamerules:ChangeMatchState("prep") --JUST PUT IT BACK TO THE SAME STATE BUT REFRESH
				-- anchor.components.gamerules:StageReset() --CANT DO THIS, THIS CYCLES THE PLAYERQUES
				for i, v in ipairs(AllPlayers) do --REMOVE AND RESET ALL PLAYERS
					TheWorld:PushEvent("ms_playerdespawnanddelete", v) 
				end
				self.playerselect_timer = select_time_limit
				anchor.quetask = nil
			end)
			
			--WE DONT HAVE ENOUGH, SO RETURN FALSE
			return false
		end
	else
	
		return true --MAYBE NOT FULL, BUT FULL ENOUGH TO START THE GAME
	end
end




--9-22-17
function SmashGameLogic:ManagePrepPhase(inst, player)
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	if anchor.components.gamerules.matchstate == "prep" then 
		
		local playerstotal = 0
		local playerschoosing = 0 --HOW MANY PLAYERS ARE STILL PICKING THEIR CHARACTER
		local playerschosen = 0 --ALTERNATIVE - THOSE WHO HAVE PICKED
		
		local totalplayers = 0 --IN A SEC. (WE NEED TO KNOW TOTAL TO MAKE SURE WE ARENT MISSING ANY)
		for i, v in ipairs(AllPlayers) do
			totalplayers = i
		end
		
		--10-22-17 WE CANT USE ALLPLAYERS TO COUNT PLAYERSTOTAL!!! IT WONT INCLUDE PLAYERS THAT HAVEN'T FINISHED LOADING IN YET!!!
		anchor.components.gamerules:RefreshMatchPool() --9-30-20 WILL THIS EVEN HELP?... OH! I GUESS IT DID. NEAT.
		playerstotal = #anchor.components.gamerules.matchpool --THIS IS THE ONLY WAY TO COUNT THE NUMBER OF TOTAL PLAYERS TO WAIT FOR WHILE WAITING FOR THEM TO LOAD IN
		--HOPEFULLY, THIS NUMBER WILL ADJUST ITSELF WHEN SOMEBODY IN THE MATCHPOOL LEAVES DURING THE CHARACTER SELECT PHASE
		
		
		for i, v in ipairs(AllPlayers) do
		-- for i, v in ipairs(anchor.components.gamerules.matchpool) do --NO YOU DUMMY, YOU CANT USE THESE AS OBJECTS, THEYRE ONLY STRINGS!!!
			--10-15-17 NOW WE MUST USE MATCHPOOL TO ACCOUNT FOR THE PLAYERS FORCED TO SPECTATE
			if anchor.components.gamerules:IsPlayerInMatchPool(v) then
				if v:HasTag("readyfreddy") or v:HasTag("select_bailed") or anchor.components.gamerules:IsSpectateOnly(v) then 	
					--READYFREADY MEANS THEY HAVE CHOSEN THEIR CHARACTER 
					--SELECT BAILED MEANS THEY FAILED TO SELECT A CHARACTER BEFORE THE TIMER ENDS (OR CHOSE SPECTATOR)
					playerschosen = playerschosen + 1
				end
			end
			-- print("HEAD COUNT!!!", playerstotal, playerschosen, i, v, anchor.components.gamerules.matchstate)
		end
		
		
		--AFTER THE FIRST PERSON CHOOSES THEIR CHARACTER, EMPLOY A TIMER TO FORCE THE OTHER PLAYERS TO CHOOSE
		if playerschosen > 0 then --5-23-20 
			self.playerselect_timer = self.playerselect_timer - 1
			-- print("SELECT TIMER: ", self.playerselect_timer)
		end
		
		--WARN THE PLAYERS WHEN TIME IS RUNNING OUT TO CHOOSE A CHARACTER
		if self.playerselect_timer == 20 then 
			for i, v in ipairs(AllPlayers) do 
				v.jumbotronheader:set(STRINGS.SMSH.JUMBO_SELECT_TIMER) --"10 Seconds Remaining"
			end
		end
		
		
		-- ONCE THE TIMER HITS ZERO: MAKE SURE WE STILL HAVE NEOUGH PLAYERS TO FIGHT
		-- WELL WE ALSO HAVE TO CHECK IF AFTER ALL PLAYERS HAVE CHOSEN, SINCE PLAYERS CAN WILLINGLY SELECT TO SPECTATE
		if (playerschosen == playerstotal) or self.playerselect_timer == 0 or playerstotal == 0 then --10-2-20 HM, LETS JUST TRY IT LIKE THIS...
			print("HEADCOUNT?", playerschosen, playerstotal)
			if not self:CheckFighterCount() and anchor.components.gamerules.matchstate ~= "lobby" then --THIS DOES MORE THAN JUST CHECK THE FIGHTER COUNT
				print("HEADCOUNT FAILED!")
				return end --AND DONT CONTINUE
		end
		
		--1-18-22 IF FOR WHATEVER REASON WE HAVE ABSOLUTELY NO ONE PLAYING, RETURN TO LOBBY
		if playerschosen == 0 and playerstotal == 0 then
			print("WOOPS, NOT ENOUGH PLAYERS LEFT NOW. RETURNING TO LOBBY", playerstotal)
			anchor.components.gamerules:ChangeMatchState("lobby")
			anchor.components.gamerules.gamemode = "PRACTICE"
			return end --AND DONT CONTINUE
		
		
		--6-2-20 IF WE'RE ABOUT TO TRANSITION, DONT RUN ANY OF THIS.
		if anchor.quetask and anchor.quetask ~= nil then
			print("QUETASK DETECTED - CANCELING", anchor.quetask)
			return end --SIDENOTE; QUETASK CANCELS AND DELETES ITSELF IF A PLAYER JOINS BEFORE THE TASK HAS RUN
		
		
		
		-- if playerschoosing == 0 and playerstotal >= 1 then 
		if playerschosen == playerstotal and playerstotal >= 1 then
			--EVERYONES CHOSEN, START THE GAME
			anchor.components.gamerules:StageReset()
			self.playerselect_timer = select_time_limit
			anchor.components.gamerules:ChangeMatchState("transition") --A NEW STATE THAT DEFINES ALL PLAYERS HAVE CHOSEN AND ARE SPAWNING BEFORE THE MATCH HAS BEGUN
			--IF THE NEXT GAME IS ALREADY STARTING, IGNORE ALL THIS, WHO CARES, THE OLD WINNER IS A WASHED UP SELLOUT NOW.
		end
		
	end
	
	--AND ALSO THE PHASE THAT COUNTS DOWN FOR THE GAME TO START.
	if anchor.components.gamerules.matchstate == "countdown" then --ACTUALLY, I GUESS THIS IS MORE OF A "PLAYER SELECT" MATCHSTATE NOW
		local spawnedplayers = 0 
		for i, v in ipairs(anchor.components.gamerules.livingplayers) do
			spawnedplayers = i
		end
		
		anchor.components.gamerules:RefreshMatchPool()
		
		local playerstotal = 0
		for i, v in ipairs(AllPlayers) do
			-- print("WHOS ABOUT TO FIGHT", v, anchor.components.gamerules:IsPlayerInMatchPool(v), spawnedplayers, playerstotal)
			--10-15-17 ONLY COUNT PLAYERS IN THE MATCH POOL!!
			if anchor.components.gamerules:IsPlayerInMatchPool(v) then
				playerstotal = playerstotal + 1
			end
		end
		
		if spawnedplayers == playerstotal and (playerstotal >= 1 or anchor.components.gamerules.hordemode == true or anchor.components.gamerules.cpulevel ~= nil) then
			anchor.components.gamerules:BeginCountdown() --10-8-17 START THE COUNTDOWN
		end
	end
	
	
	
	
	--9-23-17 IF ANYONE AT ALL HAS THE "READYFREDDY" TAG IN LOBBY MODE, THEY JUST CHOSE A NEW CHARACTER
	if anchor.components.gamerules.matchstate == "lobby" then
		
		--8-21-20 FIRST CHECK AND SEE IF WE ARE READY TO START A BATTLE BASED ON THE NUMBER OF PLAYERS AND GAME-MODE
		local npccount = 0  --THIS WILL COUNT THE NUMBER OF DUMMY NPCs THAT SHOULD NOT BE COUNTED AS REAL PLAYERS
		for i, v in ipairs(AllPlayers) do
			if v:HasTag("dummynpc") then
				npccount = npccount + 1
			end
		end
		-- print("GAME MODE", anchor.components.gamerules.gamemode)
		local playercount = #AllPlayers - npccount  
		if (playercount >= 2 and anchor.components.gamerules.matchstate == "lobby") --then  --ITS SUPPOSED TO BE 2, SETTING IT TO 1 FOR TESTING      --8-19-20 vvv AND THEN I FORGOT :)
			-- or (playercount >= 1 and anchor.components.gamerules.matchstate == "lobby" and anchor.components.gamerules.hordemode == true) --6-10-18 FOR TESTING ONLY!! REMOVE WHEN DONE
			or (playercount >= 1 and anchor.components.gamerules.matchstate == "lobby" and anchor.components.gamerules.gamemode == "HORDE")
			or (playercount >= 1 and anchor.components.gamerules.matchstate == "lobby" and anchor.components.gamerules.localp2mode == true) --7-4-18 -FOR LOCAL MULTIPLAYER
			or (playercount >= 1 and anchor.components.gamerules.matchstate == "lobby" and anchor.components.gamerules.gamemode == "VS-AI") then
			--8-21-20 WE NOW JUST EDIT THIS VALUE AND LET THE PLAYERS CHOOSE WHEN TO ACTUALLY HIT THE START BUTTON
			anchor._sessionready:set(true)
		else
			anchor._sessionready:set(false)
		end
		
		
		
		
		for i, v in ipairs(AllPlayers) do
			if v:HasTag("readyfreddy") then
			
				--11-27-18 RIGHT HERE!!! IF CPU DIFFICULTY EXISTS, DO SPECIAL FN WHERE START CPU BATTLE INSTEAD OF JUST RESETTING THE STAGE NORMALY -DST
				-- if anchor.components.gamerules.cpulevel ~= nil then 
				if anchor.components.gamerules.gamemode == "VS-AI" then --8-22-20 DO IT THIS WAY INSTEAD
					anchor.components.gamerules:ChangeMatchState("transition") --SKIP STRAIGHT TO COUNTDOWN! WE BOUT TO FIGHT THIS BOI
					anchor.components.gamerules:StageReset()
						
				--9-29-20 IF WE ARE IN PRACTICE MODE, DONT RESET THE STAGE. JUST RESPAWN THE PLAYER AS THEIR NEW CHARACTER
				elseif anchor.components.gamerules.gamemode == "PRACTICE" then
					TheWorld:PushEvent("ms_playerdespawnanddelete", v)
					anchor.components.gamerules:RemoveFromPlayerTable(v)
					anchor.components.gamerules:RemoveFromGame(v)
					
				else
					--OTHERWISE, JUST RESTART THE GAME LIKE WE ALWAYS DID
					anchor.components.gamerules:StageReset() --SO RESTART THE GAME
				end
			end
		end
	end
	
end






function LookupPlayerInstByUserID( userid )
	for _, v in ipairs(AllPlayers) do
		if v.userid == userid then
			return v
		end
	end
	return nil
end
--HAVE ID'S ADD THEMSELVES TO A TABLE AND THEN HAVE THE TABLE GO THROUGH AND FIND ITSELF TO JUST SLAP ON 



function SmashGameLogic:OnUpdate(dt)

	--EH, TURN ALL THIS OFF FOR NOW
end


function SmashGameLogic:ServerOnUpdate(dt)

	--OH SNAP WHATS THIS?? HOW IS THIS DIFFERENT FROM ONUPDATE??
end

return SmashGameLogic