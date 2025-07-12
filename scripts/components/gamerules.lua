local GameRules = Class(function(self, inst)
    self.inst = inst

	--------------------------------
	self.stage_bounds = 15 
	self.padding = 14  --1-11-22 INCREASING FROM 12   --12-16-18 -CHANGING FROM 13 BECAUSE ITS TOO WIDE   -9-7 CHANGING FROM 10 TO INCREASE BLAST ZONES
	self.bottom_padding = 14 --10-23-18 -15 IS JUST A TAD TOO MUCH
	self.top_padding = 18 --10-7-18 CREATING TOP PADDING AND CHANGING FROM 15 TO GREATLY INCREASE BLAST ZONES FROM TOP -REUSEABLE
	self.center_stage = 0
	
	self.lledgepos = 0 --7-31 LEDGE POSITION RELATIVE TO CENTER STAGE
	self.rledgepos = 0 --FOR USE IN AI RECOVER AND STUFF
	
	self.stage_prefab = nil
	
	self.livingplayers = {}
	
	self.playernumbers = {} --10-27-16
	self.popup = "oh boy"
	
	self.visiblehuds = true --false
	
	self.freezecam = false
	self.nokos = false
	self.gameover = false
	
	self.hordemode = false --false
	
	self.gamemode = "PRACTICE" --8-21-20 ITS ABOUT TIME I GOT AROUND TO THIS
	--CHECK OUR SERVER SETTINGS TO SEE IF WE SHOULD OVERRIDE THIS DEFAULT.
	if TUNING.SMASHUP.SERVERGAMEMODE == 4 then
		self.gamemode = "HORDE"
	elseif TUNING.SMASHUP.SERVERGAMEMODE == 5 then
		self.gamemode = "VS-AI"
	end
	
	self.localp2mode = false --7-4-18 --FOR LOCAL MULTIPLAYER
	self.p2_reincarne = nil --7-4-18 --IF THIS IS EVER ANYTHING OTHER THAN NIL WHEN A MATCH STARTS, ADD THIS TO THE MATCH. THIS IS THE LOCAL P2 CHARACTER THAT WAS CHOSEN
	
	--DST CHANGE - 9-3-17 
	self.matchstate = "lobby" --TELL IF THE MATCH IS IN LOBBY MODE, PREPARING, OR ACTIVE
	-- self.haltstate = false  --5-30-20 SOME ARBITRARY BOOLEAN TO TELL SMASHGAMELOGIC TO STOP RESETTING THE GAME MULTIPLE TIMES AFTER ONE RESTART IS ALREADY SCHEDULED
	--NO FORGET THAT ^^^ CHECK FOR QUETASK INSTEAD, ANY TIMED TASK ATTACHED TO THE ANCHOR RELATED TO CHANGING GAMESTATES OR RESPAWNING PLAYERS 
	
	self.inlobby = {} --DST- 9-24-17 A NEW USE FOR THIS - TELLS THE GAMELOGIC IF THE PLAYER IS NEW TO THE LOBBY OR NOT
	
	--10-14-17 DST - NEW CHANGES FOR THE MATCH QUE SYSTEM
	self.playerque = {} --PLAYERS WAITING TO PLAY THE NEXT MATCH
	self.matchpool = {} --PLAYERS PLAYING THE CURRENT MATCH
	self.permaspectators = {} --1-18-22 PLAYERS THAT ARE ONLY SPECTATING
	self.teamreserves = {} --1-19-22
	
	self.matchpoollimit = TUNING.SMASHUP.MATCHSIZE --4 --DST
	self.matchlives = TUNING.SMASHUP.MATCHLIVES 
	
	self.winner = nil --DST
	
	--11-27-18 -DST --A CPU DIFFICULTY PLACEHOLDER. IF EXISTING AT ALL AS THE STAGE RESETS, A CPU WILL TAKE THE PLACE OF A PLAYER
	self.cpulevel = nil -- (any number)  --NOTE, 0 IS A QUEEN (OR IS TREATED AS SUCH IN SOME BEHAVIORS)
end)



--8-19-20 NOW THAT THESE VARY BETWEEN GAMEMODES, WE WILL GRAB THEIR VALUES FROM THESE FUNCTIONS
function GameRules:GetMatchPoolLimit()
	if self.hordemode == true then
		return 2 --MAX 2 (NON-SPIDER) PLAYERS IN HORDE MODE
	else
		return TUNING.SMASHUP.MATCHSIZE
	end
end

function GameRules:GetMatchLives()
	if self.hordemode == true then
		return 1 --ONLY ONE LIFE IN HORDE MODE
	elseif self.matchstate == "lobby" then
		return 11 --INFINITE IN LOBBY MODE
	else
		return TUNING.SMASHUP.MATCHLIVES 
	end
end



--4-2-19 JUST SO I CAN WATCH WHERE THESE ARE CALLED FROM..
function GameRules:ChangeMatchState(state)
	print("CHANGING GAMESTATE : FROM ", self.matchstate, " TO ", state)
	-- TheNet:Announce("CHANGING GAMESTATE :".. state)
	self.matchstate = state
	--8-21-20 IF RETURNING TO LOBBY, SET THIS VALUE BACK TO FALSE
	self.inst._sessionready:set(false)
end

--10-14-17 DST - CREATE AND MANAGE QUE/LOBBY POOLS.  --ANY PLAYER THAT JOINS THE SERVER DURING ANY MATCHSTATE (EVEN LOBBY) IS AUTOMATICALLY ADDED 
function GameRules:AddToQue(player)
	local playerid = tostring(player:GetDisplayName()) --ADDS THEIR ID AS A STRING TO THE TABLE
	-- local playerid = tostring(player) --JUST TO TEST
	
	local alreadyinline = false --SINCE THIS WILL RUN EVERY TIME THEY RESPAWN, WE NEED TO CHECK IF THEYRE ALREADY IN EITHER OF THE TABLES
	
	for k,v in pairs(self.playerque) do
		if v == playerid then alreadyinline = true end
	end
	for k,v in pairs(self.matchpool) do
		if v == playerid then alreadyinline = true end
	end
	
	if alreadyinline == true then
		return end --THEN DONT ADD THEM TO THE QUE, THEYRE ALREADY IN IT.
	
	table.insert(self.playerque, playerid) --SETS THEIR ID IN THE TABLE
end


--5-23-20 REMOVE A SPECIFIC PLAYER FROM THE MATCH POOL TABLE
function GameRules:RemoveFromMatchQue(player)
	local playerid = tostring(player:GetDisplayName()) --THEIR ID AS A STRING
	-- print("REMOVING FROM MATCHQUE: ", playerid)
	
	table.removearrayvalue(self.matchpool, playerid) --WAIT.. WHATS THIS? HOW LONG HAS THIS EXISTED? DOES IT WORK? SEEMS USEFUL
	--THIS WONT CRASH IF THE VALUE DOESNT EXIST THERE RIGHT?
	
	self:RestackQues() --AND THATS IT HUH?
end


--REMOVE AND RE-ADD THE MATCHPOOL TABLE TO ITSELF, REMOVING ANY NILL OR MISSING PLAYER VALUES THAT MIGHT BE THERE
function GameRules:RestackQues()
	local cycletable = {}
	
	for k,v in pairs(self.matchpool) do
		for l,b in pairs(AllPlayers) do
			if v == tostring(b:GetDisplayName()) then
				table.insert(cycletable, v)
			end
		end
	end
	self.matchpool = {}
	
	for k,v in pairs(cycletable) do
		table.insert(self.matchpool, v)
	end --AND NOW ITS BACK! RIGHT?
	
	
	--AND ALSO THE SAME ONE FOR PLAYERQUE
	local cycletable = {}
	
	for k,v in pairs(self.playerque) do
		for l,b in pairs(AllPlayers) do
			if v == tostring(b:GetDisplayName()) then
				table.insert(cycletable, v)
			end
		end
	end
	
	self.playerque = {} --THEN YOU HAVE TO DELETE IT AGAIN, YOU DINGUS
	
	for k,v in pairs(cycletable) do
		table.insert(self.playerque, v)
	end --AND NOW ITS BACK! RIGHT?
	
	--1-18-22 YEA YEA, AND ALSO PUT SPECTATE-ONLY PLAYERS IN HERE. SO THEY CAN JUMP RIGHT INTO THE NEXT GAME AFTER DISABLING IT.
	for k,v in pairs(self.permaspectators) do
		table.insert(self.playerque, v) --DO THESE NEED TO BE THEIR STEAM NAMES? OR...
	end
	
end


function GameRules:MoveQueToMatch()

	-- print("-----MOVE QUE TO MATCH------")
	-- self:PrintQues()

	--FIRST, CYCLE THE MATCHPOOL PLAYERS BACK TO THE TOP OF THE QUE (BACK A' THE LINE, BUB!)
	for k,v in pairs(self.matchpool) do
		-- table.insert(self.playerque, v) --CAN'T ADD IN LIKE THIS!! NEEDS TO GO TO TOP OF TABLE
		
		--COUNTS THE SIZE OF THE MATCHPOOL
		local playerquesize = 0
		for l,b in pairs(self.playerque) do
			playerquesize = l --OKAY THIS WEIRD NUMBERING SYSTEM BUGS OUT
			-- playerquesize = playerquesize + 1
		end
		
		self.playerque[(playerquesize+1)] = v
		-- TheNet:Announce("ADDING TO PLAYERQUE".. tostring(k))
		
		--AND REMOVE THEM FROM THIS TABLE AFTER
		self.matchpool[k] = nil --MAKING THEM NIL DOESNT ACTUALLY REMOVE THEM FROM THE TABLE??? WHY?
		
		-- table.remove(self.matchpool, k)
		-- self:RemoveFromMatchPool(v) 
	end
	
	--OKAY NOW WE CAN ERASE IT
	-- self.matchpool = {}
	
	print("--HERES THE CURRENT MATCH QUE--")
	self:PrintQues()
	
	
	-- self:RetireBailedWinner() --5-28-20 MAKE SURE WINNER HASNT RETIRED FIRST
	--THIS IS NOW CALLED WHEN THE PLAYER THEMELVES BAIL
	
	--5-24-20 PLAYER PRIORITY! IF "WINNER-STAYS" IS ENABLED, FAST-PASS THE WINNER RIGHT BACK INTO THE MATCH
	if TUNING.SMASHUP.QUECYCLE == 2 and self.winner ~= nil and self:DoesPlayerExist(self.winner) then 
		-- print("FAST-PASSING WINNER INTO MATCHQUE", self.winner)
		table.insert(self.matchpool, self.winner)
		table.removearrayvalue(self.playerque, self.winner)
	end
	
	
	--RUN THROUGH THE LIST OF PLAYERS IN THE QUE
	for k,v in pairs(self.playerque) do
		local matchpoolsize = 0 --COUNT THE SIZE OF THE MATCHPOOL
		
		--1-18-22 ONLY PRETEND TO PUT THEM IN THE MATCH POOL IF THEY ARE SPECTATE ONLY
		if not self:IsSpectateOnly(v) then
			table.insert(self.matchpool, v) --PUT THEM IN THE POOL
			
			--COUNTS THE SIZE OF THE MATCHPOOL
			for l,b in pairs(self.matchpool) do
				matchpoolsize = l
			end
		end
		
		--REMOVE THE CURRENT PLAYER FROM THIS TABLE AFTER SUCCESFULLY ADDING THEM TO THE MATCHPOOL
		self.playerque[k] = nil
		
		
		--IF THE MATCHPOOL SIZE IS FULL, BREAK THE LOOP
		if matchpoolsize >= self:GetMatchPoolLimit() then break end  --.matchpoollimit
	end
	
	
	--AND THEN..WE... CYCLE THE QUE INTO ANOTHER TABLE, DELETE IT, THEN RE-CYCLE THAT TABLE BACK INTO THE QUE TO REMOVE NIL PLACEHOLDERS?...
	self:RestackQues() --NO JUST RESTACK THEM
end



--11-26-17 ADD PLAYERS INTO MATCHPOOL WITHOUT REMOVING THE CURRENT ONES. FOR PLAYERS THAT HAVE JOINED THE GAME IF PLAYERS ARE STILL SELECTING CHARACTERS
function GameRules:GetNextInLine()

	-- print("NEXT IN LINE, PLEASE")
	self:RestackQues() --FIX EVERYTHING UP FOR THE PLAYER THAT JUST JOINED

	--RUN THROUGH THE LIST OF PLAYERS IN THE QUE
	for k,v in pairs(self.playerque) do
		
		--COUNTS THE SIZE OF THE MATCHPOOL
		local matchpoolsize = #self.matchpool
		
		--IF THE MATCHPOOL SIZE IS ALREADY FULL, DONT LET THEM IN
		if matchpoolsize >= (self:GetMatchPoolLimit()) then  --.matchpoollimit
			print("NEVERMIND, THE RING IS ALREADY FULL")
			break end --SO IS THIS THE SAME AS RETURN? WILL IT STOP THE BELOW FUNCTIONS FROM RUNNING?
		
		if not self:IsSpectateOnly(v) then --1-18-22
			table.insert(self.matchpool, v) --PUT THEM IN THE POOL
			
			if v.components and not v:HasTag("flag_disconnect") then--LETS MAKE SURE THEY ACTUALLY EXIST FIRST  --IS THIS EVER EVEN TRUE AT ALL??? --THERE I ADDED A BETTER ONE
				TheWorld:PushEvent("ms_playerdespawnanddelete", v) --AND THEN DE-RESPAWN THEM, BECAUSE OTHERWISE THEIR SELECT SCREEN WONT SHOW UP
			end
		end
		
		--REMOVE THE CURRENT PLAYER FROM THIS TABLE AFTER SUCCESFULLY ADDING THEM TO THE MATCHPOOL
		self.playerque[k] = nil
	end
	
	self:RestackQues() --AGAIN

end


function GameRules:IsPlayerInMatchPool(player)
	local player = player --???
	for l,b in pairs(self.matchpool) do
		if player:GetDisplayName() == b then
			return true
		end
	end
	return false
end


--11-26-17 FOR PLAYERS WHO HAVE LEFT BEFORE MATCHQUE HAS FINISHED. CHECKS FOR DISPLAY NAME, NOT ENTITY
function GameRules:DoesPlayerExist(player)
	local player = player --???
	for l,b in pairs(AllPlayers) do
		if player == b:GetDisplayName() then  --!!!!!!! THIS FN CHECKS FOR DISPLAY NAME, NOT ENTITY
			return true
		end
	end
	return false
end


--9-30-20 FOR ISSUES REGARDING BAILERS/READY TAGS WHEN SOMEONE LEAVES DURING CHARACTER SELECT
function GameRules:RefreshMatchPool()
	local gonelist = {}
	--THIS FUNCTION COMPARES THE MATCHQUEUE POOL TO THE LIST OF CLIENTS CONNECTED TO THE SERVER, AND REMOVES ANYONE WHO HAS BEEN DISCONNECTED
	
	-- 10-2-20 --LETS CHECK TO SEE IF THEY'RE ACTUALLY CONNECTED TO THE SERVER, AND NOT JUST IF THEIR PREFAB EXISTS
	local function CheckClientList(player)  --c_listplayers() --CHECK OUT THIS USER COMMAND FOR MORE DETAILS ON CLIENT TABLE INFO
		local clientconnected = false
		-- for i, v in ipairs(TheNet:GetClientTable() or {}) do
		for i, v in ipairs(GetPlayerClientTable() or {}) do --2-5-22 THIS VERSION IGNORES NON-PLAYERS
			-- print(string.format("%s[%d] (%s) %s <%s>", v.admin and "*" or " ", index, v.userid, v.name, v.prefab))
			-- print("ARE YOU MY CLIENT?", player, v.name) 
			if player == v.name then --SO UH... THIS COULD MAKE THINGS WEIRD IF PEOPLE HAVE THE SAME NAME... EH, OH WELL
				clientconnected = true
			end
		end
		
		return clientconnected
	end
	
	
	--GET A LIST OF ANY NAMES IN THE MATCH POOL THAT DON'T MATCH ANYONE CURRENTLY CONNECTED TO THE SERVER
	for k,v in pairs(self.matchpool) do
		-- if not self:DoesPlayerExist(v) then --CAN'T USE THIS, SINCE PLAYERS BRIEFLY DISAPPEAR TO RESPAWN BETWEEN STAGE RESETS
		if not CheckClientList(v) then --THIS VERSION CHECKS TO SEE IF THEY'RE STILL CONNECTED TO THE SERVER
			print("GONER DETECTED! REMOVING FROM MATCHLIST", v, CheckClientList(v))
			table.insert(gonelist, v)
		end
	end
	--FOR EVERYONE ON THE GONELIST, RMOVE THEM FROM MATCHPOOL
	for k,v in pairs(gonelist) do
		table.removearrayvalue(self.matchpool, v)
	end
end


--5-31-20 CHECK IF THERE IS ANY ROOM FOR MORE PLAYERS IN THE MATCHQUE
function GameRules:IsMatchpoolFull()
	self:RestackQues() --JUST A PRECAUTION
	local matchpoolsize = #self.matchpool
	-- print("IS THE MATCHQUE FULL? HERES HOW MANY WE GOT:", matchpoolsize)
	
	--IF THE MATCHPOOL SIZE IS ALREADY FULL
	if matchpoolsize >= (self:GetMatchPoolLimit()) then  --.matchpoollimit
		-- print("ITS FULL")
		return true
	else
		-- print("ITS NOT FULL")
		return false
	end

end


function GameRules:PrintQues()

	print("-------PLAYERQUE-------")
	for k,v in pairs(self.playerque) do
		print(v, k)
	end
	print("--MATCHPOOL--")
	for k,v in pairs(self.matchpool) do
		print(v, k)
	end
	print("-------------------")
end



--DST- 9-24-17- TO ADD PLAYER TO LOBBY AND TO DETERMINE IF THE PLAYER JUST ARRIVED TO THE LOBBY OR IS RETURNING FROM A CHARACTER CHANGE
function GameRules:LobbyGuestList(steamid, action)
	local playerid = tostring(steamid) --ADDS THEIR ID AS A STRING TO THE TABLE
	local checkedin = false 
	
	--BUT CHECK TO MAKE SURE IT ISN'T ALREADY THERE FIRST
	for k,v in pairs(self.inlobby) do
		if v == playerid then	--IF THEY ARE, REMOVE IT FROM THE TABLE. WE'LL REPLACE IT
			self.inlobby[k] = nil --THIS IS THE SUPPOSEDLY CORRECT WAY TO REMOVE THEM
			checkedin = true --THEY WERE JUST HERE
		end
	end
	
	if action and action == "remove" then
		return end	--DON'T RE-ADD THE PLAYER TO THE GUEST LIST, AND DONT RETURN ANYTHING. WE ALREADY REMOVED THEM, JUST END IT HERE.
	
	table.insert(self.inlobby, playerid) --SETS THEIR ID IN THE TABLE
	
	return checkedin --RETURNS WETHER OR NOT THEY'RE NEW OR HAVE BEEN THERE A WHILE.
end


--DST- 9-24-17  JUST WIPES THE LOBBY'S GUEST LIST FOR WHEN THE GAME LEAVES LOBBY MODE
function GameRules:ClearLobbyList()
	for k,v in pairs(self.inlobby) do
		self.inlobby[k] = nil --THIS IS THE SUPPOSEDLY CORRECT WAY TO REMOVE THEM
	end
end



-- function GameRules:InsertIntoPlayerTable(player) --NO LONGER USED NOW THAT IT'S HANDLED BY THE SPAWNER
	-- table.insert(self.livingplayers, player)
-- end

function GameRules:RemoveFromPlayerTable(player)  
	local player = player 
	for k,v in pairs(self.livingplayers) do
		if v == player then
			self.livingplayers[k] = nil --2-15-17 COULD THIS HAVE BEEN WRONG THE WHOLE TIME!!! TIME TO FIND OUT...
		end
		
	end
end


function GameRules:RemoveFromGame(player) --FOR WHEN THE PLAYER HAS COMPLETELY RUN OUT OF LIVES
	local player = player 
	--[[
	for k,v in pairs(self.playernumbers) do
		if v == player then
			table.remove(self.playernumbers, k) --WAIT, ISNT THIS THE WRONG WAY TO REMOVE FROM TABLES?...  AS LONG AS IT ONLY REMOVES ONE AT A TIME, IT SHOULD BE FNE
		end
	end
	]]
	
	--11-9-20 ALRIGHT YA GOT ME. I'LL MAKE THIS ONE LAST CHANGE AND HOPE NOTHING BREAKS
	table.removearrayvalue(self.playernumbers, player)
end



--1-18-22 NEW "SPECTATE ONLY" MODE... I GUESS.
function GameRules:ToggleSpectateOnly(player) 
	local playerid = tostring(player:GetDisplayName())
	
	local checkedin = false
	--BUT CHECK TO MAKE SURE IT ISN'T ALREADY THERE FIRST
	for k,v in pairs(self.permaspectators) do
		if v == playerid then	--IF THEY ARE, REMOVE IT FROM THE TABLE. WE'LL REPLACE IT
			self.permaspectators[k] = nil --THIS IS THE SUPPOSEDLY CORRECT WAY TO REMOVE THEM
			checkedin = true --THEY WERE JUST HERE
		end
	end
	
	if checkedin then
		table.removearrayvalue(self.permaspectators, playerid)
		TheNet:Announce("Returned to normal mode")
	else
		--TheNet:Announce(player:GetDisplayName().." ".."Entered Spectate-Only mode")
		TheNet:Announce("Entered Spectate-Only mode")
		table.insert(self.permaspectators, playerid) --SETS THEIR ID IN THE TABLE
	end
end


function GameRules:IsSpectateOnly(player)
	for l,b in pairs(self.permaspectators) do
		--if player:GetDisplayName() == b then
		print("PERMASPECTATOR OR NAH?", player, b)
		if player == b then
			return true
		end
	end
	return false
end



--1-19-22
function GameRules:ReserveTeam(player, team)
	local playerid = tostring(player:GetDisplayName()) --ADDS THEIR ID AS A STRING TO THE TABLE
	-- local playerid = tostring(player) --JUST TO TEST
	
	if self.matchstate ~= "prep" then
		-- print("WE'RE NOT ACCEPTING TEAMS RIGHT NOW!")
		return end
	
	for k,v in pairs(self.teamreserves) do
		if v.pname == playerid then 
			-- print("YOU ALREADY HAVE A RESERVATION! LETS CANCEL IT")
			table.removearrayvalue(self.teamreserves, playerid)
		end
	end
	
	-- print("RESERVING A TEAM!", playerid, team)
	table.insert(self.teamreserves, {pname=playerid, tname=team}) 
end




--1-19-22 THIS WILL COME IN HANDY FOR WHEN PLAYERS RESPAWN WITH NEW REFERENCES
function GameRules:GetPlayerRefFromDisplayname(playerid)
	local playerfound = nil
	for k,v in pairs(AllPlayers) do
		if v:GetDisplayName() == playerid then 
			playerfound = v
		end
	end
	
	return playerfound	
end


--5-23-20 REMOVE A SPECIFIC PLAYER FROM THE MATCH POOL TABLE
function GameRules:RemoveFromMatchQue(player)
	local playerid = tostring(player:GetDisplayName()) --THEIR ID AS A STRING
	-- print("REMOVING FROM MATCHQUE: ", playerid)
	
	table.removearrayvalue(self.matchpool, playerid) --WAIT.. WHATS THIS? HOW LONG HAS THIS EXISTED? DOES IT WORK? SEEMS USEFUL
	--THIS WONT CRASH IF THE VALUE DOESNT EXIST THERE RIGHT?
	
	self:RestackQues() --AND THATS IT HUH?
end




--8-21-20 MOVING THIS FROM SMASHGAMELOGIC SO IT CAN BE ACCESSED FROM MENUS
--THIS FUNCTION SCOOPS UP ALL PLAYERS CURRENTLY SITTING IN LOBBY MODE AND MOVES THEM INTO PLAYERQUES BEFORE STARTING THE ACTUAL GAME
function GameRules:BeginSession() 
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	self:ChangeMatchState("prep") --GETTING READY TO START
	TheWorld:AddTag("gamestate.prep") --9-9-17
	-- TheNet:Announce(STRINGS.SMSH.JUMBO_NEW_MATCH) --"Starting new match."
	
	--10-15-17 SETS UP ALL THE PLAYERS
	self:MoveQueToMatch()
	
	anchor:DoTaskInTime(0.5, function() --GIVE THEM A SEC TO INITIALIZE PLAYERCONTROLER FIRST SO IT WONT CRASH
		self:ClearLobbyList() --9-24-17 
		print("---BEGINNING A SESSION---")
		--8-24-20 MAKE SURE THIS GETS SET HERE AS WELL
		if self.gamemode == "HORDE" then
			self.hordemode = true
		end
		self:StageReset() --!!! THIS COULD BE AN ISSUE FOR PLAYERS JOINING SO CLOSE TO EACH OTHER
		
		--9-30-20 IF THEY CLICKED START GAME DURING PRACTICE MODE, PUSH US INTO PVP MODE. BECAUSE PRACTICE MODE ISNT REAL. AND.. THERE ISNT ANY OTHER WAY TO SET PVP MODE
		if self.gamemode == "PRACTICE" then
			--SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setservergamemode"], "PVP") --I DONT THINK THIS NEEDS TO BE AN RPC, BECAUSE ONLY THE SERVER HANDLES THIS VALUE
			print("--ALTERING SERVER GAMEMODE (ALT): ", "PVP")
			self.gamemode = "PVP"
		end
	end)
	
end



--1-21-17 --THIS CANT BE RIGHT, THAS WAS LONG AGO
local StatusDisplays = require "widgets/statusdisplays"
function GameRules:SpawnHud(player) 
	local player = player 
	
	--9-16-17 DST- MAYBE SPREADING OUT THE HUD CREATION TIMES WILL FIX THIS
	--player:DoTaskInTime((player.components.stats.playernumber)*FRAMES, function()
	
		local doer = player
		local xoffset = (-35) - ((RESOLUTION_X/3) * (player.components.stats.playernumber)) --9-12-17 DST- IT WAS GOOD IDEA, BUT PLAYRNUM DONT WORK...
		--9-12-17 USING -35 SO THAT SERVER MESSAGES ARE VISIBLE BEHIND THE BADGES
		--------- ALRIGHT, YOU KNOW WHAT, THIS IS GOING TO GET REAL COMPLICATED. 
				--AND I COULD DO IT IF I WANTED TO. BUT LETS BE REAL. THERE IS NO REASON TO ASSUME THERE WILL EVER BE MORE THAN 6 ON SCREEN AT ONE TIME
				--SO LETS JUST DO THINGS THE EASY WAY
		
		--9-29-20 OH MY GOOD LORD WHAT ON EARTH WAS I EVEN DOING HERE. THIS IS SO BAD. I WANT TO REDO THIS BUT IDK IF I SHOULD AT THIS LATE IN DEVELOPMENT
		--9-29-20 ALRIGHT, LETS GIVE IT A SHOT...
		
		--9-30-20 LETS CONDENSE THIS PART A BIT
		--[[
		local function GetXOffset(counter) 
			--I HONESTLY CANT REMEMBER HOW I DECIDED UPON THIS FORMULA
			local xoffset = (-35) - ((RESOLUTION_X/3) * (counter))
			
			--//SIGH/ ALRIGHT, FINE, WE'LL USE THE OLD HARDCODED METHOD FOR SPACING
			if counter == 3 then
				xoffset = (-35) - (((RESOLUTION_X/3) * 2) + (1 * (RESOLUTION_X/6)))
			elseif counter == 4 then
				xoffset = (-35) - (((RESOLUTION_X/3) * 1) - (1 * (RESOLUTION_X/6)))
			elseif counter == 5 then
				xoffset = (-35) - (((RESOLUTION_X/3) * 2) + (2 * (RESOLUTION_X/6)))
			elseif counter == 6 then
				xoffset = (-35) - (((RESOLUTION_X/3) * 1) - (2 * (RESOLUTION_X/6)))
			end
			
			return xoffset
		end
		]]
		
		--1-3-22 NEW YEAR. NEW HUD. NEW BADGE DISTRIBUTION FORMULA
		local function GetXOffset(counter) 
			--MULTIPLY BY NEGATIVE ON ODD NUMBERS
			local swithchflop = 1
			if math.floor(counter/2) == counter/2 then
				swithchflop = -1
			end
			
			local xoffset = 0 + ((RESOLUTION_X/8) * math.ceil(counter/2) * swithchflop)
			-- print("XOFFSET! ", xoffset, counter, swithchflop)
			
			return xoffset
		end
		
		local client = ThePlayer
		if client and client.HUD then
			
			local clienthud = client.HUD.smashpanel --client.HUD.controls.status
			
			--IF WE ARE JUST SPAWNING, RECREATE HUDS  FOR ALL PLAYERS ON SCREEN
			if not clienthud.healthbubbles then
				local counter = 1
				for i, v in ipairs(self.playernumbers) do --AllPlayers
					-- print("PLAYERNUMBER", v.components.stats.playernumber, v )
					if v:HasTag("nohud") or self.visiblehuds == false or not v.components.stats.playernumber then --ALSO CHECK IF PLAYERNUMBER EXISTS, BC STALE REFERENCES
						return end
						
					-- local xoffset = (-35) - ((RESOLUTION_X/3) * (counter)) --counter   --v.components.stats.playernumber
					local xoffset = GetXOffset(counter) 
					-- print("BULKSPAWN XOFFSET", xoffset, counter)
					clienthud.healthbubbles = clienthud:AddChild(StatusDisplays(v))
					local newhud = clienthud.healthbubbles --AHH, MUCH BETTER
					newhud:SetPosition((xoffset),0,0)
					v.components.percent:DoDamage(0.1)
					counter = counter + 1
				end
				
				
			else --ELSE, JUST SLAP THE NEW PLAYER'S HEALTH BUBBLE UP WITH THE REST OF THEM
				if player:HasTag("nohud") or self.visiblehuds == false then
						return end
				
				--THE ISSUE WITH #self.playernumbers IS THAT IF EVERYONE SPAWNS AT ONCE, THIS ALL BECOMES THE SAME NUMBER
				-- local xoffset = (-35) - ((RESOLUTION_X/3) * (player.components.stats.playernumber)) --player.components.stats.playernumber   --#self.playernumbers
				local xoffset = GetXOffset(#self.playernumbers) 
				-- print("SINGLE SPAWN XOFFSET", xoffset, #self.playernumbers)
				local newhud = clienthud:AddChild(StatusDisplays(player))
				newhud:SetPosition((xoffset),0,0)
				player.components.percent:DoDamage(0.1)
			end
		end
		
		
		--PICKLE, WHY IS THIS HERE
		player.components.percent:DoDamage(1) --HM. IT SEEMS THEIR PERCENT COMPONENT HASN'T INIT YET
	--end)
end



--DST CHANGE--5-4-17 THE DUMBEST THING IVE EVER HAD TO DO --GAHHHH. NOTHING WILL EVER WORK
--[[function GameRules:ShowSelectScreen(player) 
	--DST CHANGE-- 5-4 TO HECK WITH ALL THIS. I WILL GET THIS THING ATTACHED SOMEHOW
	local TestScreen = require "widgets/testscreen"
	local selectscreen = player.HUD.controls.sidepanel:AddChild(TestScreen(player)) --owner
	
	
	-- self.selectscreen = self:AddChild(TestScreen(owner)) --owner
	-- self.inst:ListenForEvent("show_select_screen", function(inst) self.selectscreen:Show() end, self.owner)
end]]



--10-27-16 A HOPEFULLY BETTER SYSTEM FOR SPAWNING IN PLAYERS AS OPPOSED TO JUST SHOVING THEIR PREFABS INTO EXISTENCE
function GameRules:SpawnPlayer(player, x, y, z, custom) --DST REUSABLE- 9-23-17 ADDING "CUSTOM" BOOL VALUE TO DECIDE IF PLAYERS GET PLATFORM OR NOT
	local player = player
	
	--X Y Z ARE ALMOST ALWAYS THE ANCHOR POSITION AS OF NOW (11-28-18) UNLESS YOU WANT A CUSTOM SPAWN POINT
	player.Transform:SetPosition( x, y, z)-- -DST- MOVE THIS UP HERE SO THEY DONT INSTA KO   --DOESNT WORK ANYWAYS, REMOVE LATER
	
	table.insert(self.playernumbers, player) --I SHOULD REALLY BE USING THIS BUT I DOUBT I ACTUALLY WILL
	table.insert(self.livingplayers, player) --THIS IS WHAT I SHOULD REALLY BE FOCUSING ON
	-- print("WELCOME TO THE FAMILY, SON", player)
	
	
	if player:HasTag("nohud") or self.visiblehuds == false then
		return end
	
	
	local indexsize = 0
	-- for k,v in pairs(self.playernumbers) do --USING PLAYERNUMBER INSTEAD OF LIVINGPLAYERS SO THAT HEALTH BARS DONT STEAL SLOTS OF THOSE WHO ARE WAITING TO RESPAWN
		-- indexsize = indexsize + 1
	-- end
	-- player.components.stats.playernumber = indexsize
	player.components.stats.playernumber = #self.playernumbers + 0 --9-29-20 HERE, YA BIG DUMMY :/
	-- print("ADDING PLAYA", player, player.components.stats.playernumber)
	for k,v in pairs(self.playernumbers) do
		-- print(" PLAYA", k, v)
	end
	
	--9-26-20 HOLD IT! MAKE SURE WE ARE GIVING THEM THE RIGHT NUMBER OF LIVES WHEN THEY SPAWN
	player.components.stats.lives = self:GetMatchLives() --IN HORDE MODE THEY ONLY GET 1 LIFE NO MATTER WHAT
	
	--9-2-17 DST CHANGE
	player.customhpbadgelives:set(player.components.stats.lives) --NETVAR -SET IT BEFORE THE HUD IS APPLIED
	--OK NOW GIVE THEM THEIR HUD
	self:SpawnHud(player, player.components.stats.playernumber)
	
	player.customhpbadgelives:set(player.components.stats.lives + 1) --2-3-22 SET THE CORRECT ONE OFF THE BAT
	player.customhpbadgelives:set(player.components.stats.lives) --1-18-22 AND THEN SET IT AGAIN? MAYBE?
	
	
	--9-23-17 --IF CUSTOM NOT SPECIFIED (LIKE FOR MAXCLONES) SPAWN THEM IN THE USUAL MANNER
	if not (custom and custom == true) then
		local platformposition = -3 + ((player.components.stats.playernumber - 1) * 6)
		--print("IM SPAWNING, WHAT'S MY PLAYER NUMBER?", player.components.stats.playernumber, platformposition)
		
		--10-25-17 DST CHANGE - OKAY, I NEED SOMETHING FOR 4 OR MORE PLAYERS. AND LETS BE REAL. THERE WON'T BE MORE THAN 6. REUSEABLE MAYBE
		if player.components.stats.playernumber == 4 then
			platformposition = -3 + ((0 - 1) * 6)
		elseif player.components.stats.playernumber == 5 then --GONNA HAVE TO HOPE THESE NUMBERS ARE RIGHT. GOD KNOWS HOW LONG TILL' I GET A CHANCE TO TEST THIS
			platformposition = -3 + ((0.5- 1) * 6)
		elseif player.components.stats.playernumber == 6 then
			platformposition = -3 + ((3.5- 1) * 6)
		elseif player.components.stats.playernumber > 6 then --IF THEY HAVE MORE THAN 6 CHARACTERS, WHO THE HECK KNOWS. JUST THROW THEM ANYWHERE CLOSE TO CENTER
			platformposition = 0 + math.random(-6,6) 
		else
			--THEN DONT DO ANYTHING YOU DOOFUS DONT LET PLAYERS 1-3 SPAWN IN RANDOM SPOTS YOU IDIOT
		end
		
		local pt = TheSim:FindFirstEntityWithTag("anchor"):GetPosition()
		player.Transform:SetPosition( (platformposition), 3.5, z) --REPLACING 0 WITH AN ANCHOR POSITION
		player.sg:GoToState("drop_spawn") --LIKE SPAWN PLATFORM BUT YOU JUST DROP INTO AIR_IDLE
	end
	
	--12-26-21 FACE CENTER STAGE WHEN SPAWNING
	if player.components.locomotor and not custom then
		player.components.locomotor:FaceCenterStage()
	end
	
	--7-4-18 --PUT OUR NON-SPIDER PLAYERS ON THE SAME TEAM! ANY TEAM THAT ISN'T SPIDER CLAN
	if self.hordemode == true and player.components.stats.team ~= "spiderclan" then
		player.components.stats.team = "hordekiller"
	end
end



--11-12-16 RESETS THE GAME TO THE CHARACTER SELECT SCREEN AFTER THE GAME FINISHES
function GameRules:ClearBoard()
	--DONT ACTUALLY DELETE THE PLAYERS IN THIS VERSION. DESPAWNANDDELETE WILL HANDLE THAT
	--SO NOW ALL THIS DOES IS CLEAR OUT ALL THE TABLES AND REMOVE ANY EXTRA PROPS
	
	self.livingplayers = {}
	self.playernumbers = {}
	
	local ents1 = TheSim:FindEntities((0), (0), (0), 1000, {"projectile"})
	for k, v in pairs(ents1) do
		v:CancelAllPendingTasks()
		v:Remove()
	end
end




--5-20-17 DST VERSION!! LETS TRY A NEW VERSION OF CLEARBOARD THAT IS FLEXIBLE TO JOINING/LEAVING CHARACTERS   --12-4-17 DID I EVEN USE THIS?
function GameRules:NewRound()
	-- player:ShowSelectScreenPopUp(true)
	
	for i, v in ipairs(AllPlayers) do
        -- OnPlayerJoined(inst, v)
		v:PushEvent("endgame")
    end
end

-- local function OnPlayerJoined(inst, player)
    -- for i, v in ipairs(inst._activeplayers) do
        -- if v == player then
            -- return
        -- end
    -- end

    -- inst:ListenForEvent("performaction", inst._OnPlayerAction, player)
    -- table.insert(inst._activeplayers, player)
-- end




function GameRules:KOPlayer(player, direction)
	local player = player
	local direction = direction
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	
	--2-9-17 IF THE GAME IS ALREADY OVER AND IN SLOMO, DONT LET ANYONE ELSE DIE (OR ELSE THE SELECT SCREEN WILL SHOW UP TWICE)
	if self.nokos == true or not player.components.stats.alive then 
		return end -- ^^^^ AN ALIVE STAT SO THAT PLAYERS DONT GET "KO'D" MORE THAN ONCE
	
	--DONT GAME-SET IN PREP MODE
	if self.matchstate == "prep" or self.matchstate == "countdown" or self.matchstate == "transition" or self.matchstate == "endgame" then 
		player.Physics:Teleport(0,1,0)
		return end
	
	player.components.stats.alive = false
	
	--11-11-16 FREEZES THE CAM FOR A SEC AFTER GETTING A KO
	self.freezecam = true
	anchor:DoTaskInTime(0.3, function() 
		self.freezecam = false
	end)
	
	
	if direction == "left" then --IMPORTANT, MUST BE IN "STRINGS". CANNOT USE WITHOUT QUOTATION MARKS   --11-27-18 OH THE GOOD OL DAYS. BACK WHEN I GOT ALL FLUSTERED OVER STRINGS AND QUOTATION MARKS. HOW OLD IS THIS? MUST BE YEARS
		player.components.hitbox:MakeFX("sidesplash_med", 0, 0, 1,   (-10*player.components.launchgravity:GetRotationValue()), 3,   0.5, 10, 0,   -1, -1, 0.2)
		player.components.hitbox:MakeFX("sidesplash_med", 0, 0, 1,   (-6*player.components.launchgravity:GetRotationValue()), 2,   0.5, 10, 0,   -1, -1, 0.0) 
	elseif direction == "right" then
		player.components.hitbox:MakeFX("sidesplash_med", 0, 0, 1,   (10*player.components.launchgravity:GetRotationValue()), 3,   0.5, 10, 0,   -1, -1, 0.2) 
		player.components.hitbox:MakeFX("sidesplash_med", 0, 0, 1,   (6*player.components.launchgravity:GetRotationValue()), 2,   0.5, 10, 0,   -1, -1, 0.0) 
	elseif direction == "up" then
		player.components.hitbox:MakeFX("sidesplash_med_up2", 0, 0, 1,   3, 10,   0.5, 10, 0,   -1, -1, 0.2)
		player.components.hitbox:MakeFX("sidesplash_med_up2", 0, 0, 1,   2, 6,   0.5, 10, 0,   -1, -1, 0.0)
	elseif direction == "down" then
		player.components.hitbox:MakeFX("sidesplash_med_down2", 0, 0, 1,   3, 10,   0.5, 10, 0,   -1, -1, 0.2)
		player.components.hitbox:MakeFX("sidesplash_med_down2", 0, 0, 1,   2, 6,   0.5, 10, 0,   -1, -1, 0.0)
	else
		--SILENT!! NO KO BLAST
	end
	
	--GEEZ THIS IS KINDA LOUD
	if direction ~= "silent" then --1-3-22 CAN WE PLEASE MAKE THESE ACTUALLY SILENT? THANK YOU
		player.SoundEmitter:PlaySound("dontstarve/HUD/XP_bar_fill_unlock", "ding")
		player.SoundEmitter:SetParameter("ding", "intensity", 0.5) --5-11-21 DOES THIS FINALY MAKE IT QUIET?
	end
	
	player:PushEvent("onko")
	player.sg:GoToState("ragdoll") --11-11-17 DST- SO THEY CAN'T JUST CONTINUE GOING TO OTHER STATES
	player.AnimState:SetMultColour(0,0,0,0) --JUST TEMPORARY, IN CASE THEY WEREN'T "ALL" THE WAY OFF SCREEN WHEN THEY HIT BLAST ZONES	
	
	--10-27-16 --IMPLIMENTING LIVES SYSTEM
	local plives = player.components.stats.lives --NOW WE JUST TAKE A POINT AWAY BUT REUSE THE SAME ENTITY
	plives = plives - 1 -- >:3c
	
	--9-23-17 LOBBY MODE ONLY-- LOBBY MODE SHOW INFINITE LIVES
	if self.matchstate == "lobby" then
		plives = 11
	end
	player.components.stats.lives = plives
	
	if not player:HasTag("nohud") then
		player.customhpbadgelives:set(plives)
	end
	
	--IN FACT IM PRETTY SURE THIS DOES NOTHING AT ALL
	player:PushEvent("livesdelta") --MOSTLY JUST FOR LIVES DISPLAY ON THE HUD --WISH IT WORKED A LITTLE BETTER :/
	
	--11-1-16 SEE IF THE ROUND SHOULD END
	local leftstanding = 0
	local cpustanding = 0
	
	for k,v in pairs(self.livingplayers) do
		if v.components.stats.lives > 0 then
			leftstanding = leftstanding + 1
			if v:HasTag("cpu") then --12-21-16 FOR HORDE MODE
				cpustanding = cpustanding + 1
			end
		else
			self:RemoveFromPlayerTable(player) --2-7-17 FIXES THE TEAM-GAME-SET I GUESS
			self:RemoveFromGame(player)
		end
	end
	-- print("CAT AND MOUSE", cpustanding, leftstanding)
	
	
	--2-6-17 --IF ALL REMAINING PLAYERS ONSCREEN ARE OF THE SAME TEAM, END THE GAME 
	local nonteamies = 0
	for k,v in pairs(self.livingplayers) do
		for l,b in pairs(self.livingplayers) do
			if v.components.stats.lives > 0 and b.components.stats.lives > 0 then --MAKE SURE THEY ARENT DEAD FIRST
				if (v.components.stats.team ~= nil and (v.components.stats.team == b.components.stats.team)) or (v.components.stats.master == b) or (b.components.stats.master == v) or v==b then
					
					--DST CHANGE- 9-23-17- SET THE ROUND WINNER RIGHT HERE
					
				else
					nonteamies = nonteamies + 1
				end
			end
		end
	end
	
	
	
	--9-16-17 NEW VERSION JUST WITH NONTEAMIES THROWN IN
	if (leftstanding <= 1 or nonteamies == 0) and self.matchstate == "running" then
		--8-22-20 ADDING GAMEMODE==HORDE CHECK. SELF.HORDEMODE IS STILL NEEDED!!! WE CAN STILL BE PLAYING HORDE MODE WHILE SOMEONE DECIDES TO CHANGE THE SERVERGAMEMODE TO SOMETHING ELSE
		if self.hordemode == true and self.gamemode == "HORDE" then
			--6-25-18 OKAY LETS TRY THIS AGAIN. BUT BETTER THIS TIME.
			local hordewinner = self:GetWinnerRef()
			if not hordewinner or (hordewinner.components and hordewinner.components.stats.team == "spiderclan") then --7-4-20 ??? hordewinner.components
				-- print("PLAYERS LOST!")				
				anchor.components.hordes:FailedHordeMode()
				--THIS IS REPLACING GAMESET() BUT WE STILL NEED TO REPLICATE IT'S FUNCTIONALITY
				self:RestackQues()
				self:MoveQueToMatch() 
			elseif player.components.stats.team == "spiderclan" then --10-3-20 MAKE SURE WHOEVER JUST DIED WAS ACTUALLY A SPIDER BEFORE DECLARING PLAYERS THE VICTORS
				-- print("PLAYERS WON!")
				anchor.components.hordes:NextWave()
			else
				-- print("SOME DIMWIT JUST JUMPED OFF THE CLIFF BETWEEN WAVES", player, player.components.stats.team)
			end
		
		else
		
			self.winner = self:GetWinner() --9-23-17 SET THE WINNER FOR THE RESULTS SCREEN TO PULL FROM
			self:GameSet()
			self:ChangeMatchState("endgame") --AFTER GAMESET HAS JUST PLAYED AND WAITING FOR THE BOARD TO RESET
			self:RestackQues() --10-15-17 RESTACK QUES
			self:MoveQueToMatch() --AND THEN... THIS??
			
			if self.localp2mode == true then --7-4-18 -THIS SHOULD ONLY BE A HOST THING, SO WE SHOULDN'T NEED TO WORRY ABOUT NETVARS, RIGHT?
				self.localp2mode = false --IS... NOW A GOOD TIME TO TURN THIS OFF?... OR WILL THIS MESS THINGS UP?
				self:ChangeMatchState("lobby")
			end
			
			
			--8-22-20 IF WE ARE THE ONLY PERSON LEFT AND THE GAMEMODE DOESNT SUPPORT SOLO PLAY, TAKE US BACK TO LOBBY
			--[[
			local ClientObjs = TheNet:GetClientTable() or {} --IVE NEVER USED THIS TO COUNT PLAYERS ON THE SERVER BEFORE. DO YOU THINK IT'S ACCURATE?
			--JUST KEEP IN MIND THAT I BELEIVE THIS COUNTS PLAYERS THAT ARE TRYING TO CONNECT TO THE SERVER, BUT NOT ONLINE YET.
			local playercount = #ClientObjs
			if TheNet:IsDedicated() then --ON DEDICATED SERVERS, THE HOST COUNTS AS IT'S OWN CLIENT OBJECT!! CLEARLY WE DONT WANT IT COUNTED AS A PLAYER
				print("DEDICATED SERVER DETECTED! ", #ClientObjs)
				playercount = playercount -1
			end
			--2-5-22 WAIT! SINCE WHEN DO CAVES COUNT AS A PLAYER??? I SWEAR TO GOD THIS HAD NEVER HAPPENED UNTIL NOW....
			]]
			local playercount = #GetPlayerClientTable() --2-5-22 THIS SHOULD WORK BETTER
			print("ALLEGED PLAYERCOUNT -- ", playercount, self.gamemode)
			if (playercount < 2 and self.gamemode == "PVP") or self.gamemode == "PRACTICE" then
				print("LESS THAN 2 PLAYERS REMAINING! RETURNING TO LOBBY ", playercount)
				self:ChangeMatchState("lobby")
			end
			
			--IF HORDEMODE == TRUE BUT OUR SERVERGAMEMODE IS NOT HORDEMODE; TURN IT OFF. WE'VE SWITCHED TO A DIFFERENT GAMEMODE
			if self.hordemode == true and self.gamemode ~= "HORDE" then
				self.hordemode = false
			--AND MAKE THE OPPOSITE TRUE. IF WE WANT TO PLAY HORDEMODE BUT HAVENT STARTED YET, NOWS A GOOD TIME TO TURN IT ON
			elseif self.hordemode == false and self.gamemode == "HORDE" then
				self.hordemode = true
			end
		end
	end
	
	
	--1-6-22 --DON'T JUST MAKE THEM INVISIBLE. MAKE THEM INTANGIBLE TOO SO THEY DON'T GET HIT OFF THE EDGE
	player.sg:GoToState("ragdoll")
	player.AnimState:PlayAnimation("invisible_lol")
	player.sg:AddStateTag("intangible")
	player.Physics:SetActive(false)
	
	--10-27-16 --CHECK TO SEE IF THEY SHOULD RESPAWN
	anchor:DoTaskInTime(2, function() 
		if plives > 0 then
			-- table.remove(self.livingplayers, player) --THATS NOW HOW IT WORKS DUMMY
			if not player:IsValid() then --9-4-17 FIXING
				return end
			
			self:RemoveFromPlayerTable(player) --DST POST PORTAL UPDATE!! REMOVING THIS ONLY FOR THE PRESENTATION!
			self:RespawnPlayer(player, plives)
			
			if self.matchstate == "lobby" then
				player.sg:GoToState("drop_spawn") --JUST TOSS THEM OUT THERE IN LOBBY MODE
			else
				player.sg:GoToState("respawn_platform") 
				player.components.talker:Say(tostring(self:GetPlayerDisplayName(player)), 5, true) --8-31-21 JUST TO REMIND THEM
			end
			
		else	
			player:PushEvent("outoflives") --6-10-18 JUST A GENERIC UTILITY EVENT. MOSTLY FOR HORDE MODE SPIDER DELETIONS
		end
	end)
	
end



function GameRules:RespawnPlayer(player, plives)
	local player = player
	
	player.components.stats.alive = true 
	
	table.insert(self.livingplayers, player)  --WERE WE REMOVED OR SOMETHING?? 
	--11-9-20 YEA I GUESS WE GET REMOVED AND THEN ADDED AGAIN RIGHT AWAY??  WELL, I GUESS THATS OK.

	local host = TheSim:FindFirstEntityWithTag("anchor") 
	local x, y, z = host.Transform:GetWorldPosition()
	player.components.percent.currentpercent = 0
	player.components.percent:DoDamage(1)
	
	player.Transform:SetPosition( x, y + 4, z )
	player.components.stats.lives = plives
	player.components.percent.currentpercent = 0 
	
	-- W WAIT WHAT?? OKAY I GUESS, AS LONG AS THE RESPAWN STATE FIXES IT...
	--5-7-17 DST CHANGE TO GIVE PLAYERS TIME TO CHOOSE A CHARACTER
	player.sg:GoToState("ragdoll")
	player.AnimState:PlayAnimation("invisible_lol")
	player.sg:AddStateTag("intangible")
	player.sg:AddStateTag("busy")
	player.Physics:SetActive(false)
	--THIS IS ALL STUFF THAT IS EASILY REMOVED WHEN THE PLAYER GOES INTO THE RESPAWN_PLATFORM STATE
end


--1-30-21 WHEN SOMEONE DESPAWNS (DISCONNECTS OR DIES AS A TEMPORARY NPC) WE NEED TO MAKE SURE NOBODY IS IN THE MIDDLE OF A THROW THAT COULD ATTEMPT TO REFERENCE THEM
function GameRules:CleanOpponentList(leaver)
	for i, v in ipairs(AllPlayers) do
		
		if v.components.stats and v.components.stats.opponent == leaver then
			--IF THEY WERE IN THE MIDDLE OF A THROW, CANCEL OUT OF IT SO IT DOESN'T CRASH
			if v.sg and v.sg:HasStateTag("handling_opponent") then
				v.sg:GoToState("rebound", 10)
			end
			v.components.stats.opponent = nil
		end
	end
end


--1-4 GRABBABLE LEDGES
function GameRules:SetEdges(x1, y1, z1, stage_bounds, center_stage)	
	
	--6-22-19 HEY BOYS GOT YER FRESH PAIR OF LEDGEBOXES HERE. THIS ONE WITHOUT ALL THE BUGS
	local ledge1 = SpawnPrefab("ledgebox")
	local ledge2 = SpawnPrefab("ledgebox")
	
	local lledgepos = center_stage - (stage_bounds+0.1-2.5) -- +1.5  --1-11 ADDING TO STAGE BOUNDS A BIT TO MAKE LEDGES STICK OUT MORE
	local rledgepos = center_stage + (stage_bounds+0.1-2.5) -- -3.5
	
	self.lledgepos = lledgepos --7-31 FOR USE IN AI RECOVER AND STUFF
	self.rledgepos = rledgepos
	
	
	-- ledgebox1.Transform:SetPosition( x1-xoffset+0, y1+yoffset+0, z1 )
	ledge1.Transform:SetPosition( lledgepos, y1+0, z1 )
	ledge2.Transform:SetPosition( rledgepos, y1+0, z1 )
	
	--11-6-17 DST CHANGE, SINCE LEDGES DONT ALWAYS MATCH UP NICELY WITH VISIBLE STAGE, LETS GIVE THEM A VISIBLE POINT OF REFERENCE
			
	local fx = SpawnPrefab("fight_fx")
	fx.Transform:SetPosition(lledgepos, (y1+0.1), (z1-0.5)) 
	fx.AnimState:SetBank("mole_fx")
	fx.AnimState:SetBuild("mole_move_fx")
	fx.AnimState:PlayAnimation("move")
	fx.AnimState:SetAddColour(0,0,0,0) --OKAY BUT WHY IS IT WHITE??? WILL THIS FIX IT?? --YEA I GUESS
	fx.AnimState:SetTime(2*FRAMES)
	fx.AnimState:Pause()
	
	
	--AND THE SECOND ONE
	local fx = SpawnPrefab("fight_fx")
	fx.Transform:SetPosition(rledgepos, (y1+0.1), (z1-0.5)) 
	fx.AnimState:SetBank("mole_fx")
	fx.AnimState:SetBuild("mole_move_fx")
	fx.AnimState:PlayAnimation("move")
	fx.AnimState:SetAddColour(0,0,0,0)
	fx.AnimState:SetTime(2*FRAMES)
	fx.AnimState:Pause()

end



function GameRules:ApplyBlastZones(host)

	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x1, y1, z1 = anchor.Transform:GetWorldPosition()
	
	-- x1 = x1 + 1 --P1 USED TO BE SPAWNED AT X-1 SO THIS MUST HAVE 1 ADDED TO IT -11-2-16
	--8-31-21 WAIT WHAT?!? COME ON AM I REALLY THIS DENSE? WHAT KIND OF LOGIC IS THAT?
	
	local center_stage = x1
	local bottom_stage = y1
	
	self.center_stage = x1 --FOR USE IN JUMPER.LUA
	self:SetEdges(x1, y1, z1 +0, self.stage_bounds, self.center_stage) 
	
	host:DoPeriodicTask(0, function(inst)
		--CHECK IF ANYONE IS OUTSIDE OF A BLAST ZONE, AND THEN BLAST EM
		for k,v in pairs(self.livingplayers) do --4-12 REVAMPING WITH ~THE MAGIC OF TABLES~ --IF I BREAK IT, REVERT TO A PREVIOUS BUILD CUZ I AINT SAVING THIS HUGE FUNCT
			if v:IsValid() then
				local player1 = v 
				local x1, y1, z1 = player1.Transform:GetWorldPosition()
				
				
				--5-11-21 KINDA HIJACKING THINGS HERE, BUT LETS ALSO CHECK TO CORRECT ANY Z AXIS MISALIGNMENTS
				--9-6-21 NO WE DON'T NEED THIS ANYMORE. EVEN IF Z AXIS SHIFTS, HITBOXES THEMSELVES SHOULD STILL SPAWN IN THE RIGHT PLACE AND READJUST PLAYERS WHEN HIT
				-- if math.abs(z1) > 0.5 then
					-- print("RE-ALLIGNING PLAYER Z AXIS POSITION")
					-- player1.Transform:SetPosition(x1, y1, 0) --SET THEM BACK TO Z = 0
				-- end
				
				
				if x1 >= center_stage + self.stage_bounds + self.padding then
					self:KOPlayer(player1, "left")
				elseif x1 <= center_stage - self.stage_bounds - self.padding then
					self:KOPlayer(player1, "right")
				end
				
				if y1 >= bottom_stage + self.top_padding and player1.sg:HasStateTag("tumbling") then
					self:KOPlayer(player1, "down")
				elseif y1 <= bottom_stage - self.bottom_padding then
					self:KOPlayer(player1, "up")
				end
			end
		end
	end)
end


local function DoBackgroundPlant(decoration, xsize, ysize, xpos, zpos)
	local player = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = player.Transform:GetWorldPosition()
	decoration.Transform:SetPosition( x+xpos, 0.1, z + zpos )
	decoration.Transform:SetScale(xsize,ysize,2)
	decoration.AnimState:SetAddColour(0.1,0.1,0.1,0.1)
	decoration:DoTaskInTime(0, function(decoration) 
		decoration:RemoveComponent("inspectable")
	end)
	decoration.persists = false --NOW THAT THEY RESPAWN EVERY RELOAD, THEY NEED TO DESPAWN
end

--AKA; LEDGE GATES
local function PlantRollBarriers(prefab, xpos, ypos, zpos, mult)
	--9-8 ADDED MULT SO I CAN ADD GATES TO THE OTHER SIDE
	if not mult then
		mult = 1
	end
	
	local gate_distance = -12.8 -- -12.7
	prefab.Transform:SetPosition( xpos-(gate_distance*mult), ypos-0, zpos-0 ) --!!IMPORTANT! MAKE SURE Y VALUE MATCHES FLOOR WIDTH OR ELSE IT WONT BE HIGH ENOUGH
end


--2-28-17 MOVING STAGE CREATION HERE
function GameRules:CreateStage()
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
		
	--9-29-21 IF CAVES EXIST, THEY WILL TRY AND RUN THIS. LETS NOT.
	if TheWorld:HasTag("cave") and not TheWorld:HasTag("run_anyways") then --A CHEEKY WORKAROUND FOR CLEVER MODDERS
		return end
	
	local x, y, z = anchor.Transform:GetWorldPosition()
	--8-31-21 WAIT WHAT AM I EVEN DOING HERE?? ANCHOR POSITION SHOULD ALREADY BE SET BY POSTINITSTAGESTUFF
	--[[
	--11-24-17 OR...MAYBE NOT??? IT SEEMS GRID POSITION HAS A 50/50 CHANCE TO BE DIFFERENT... THATS UNFORTUNATE  --YEP. THATS EXACTLY THE CASE
	--1-1-2018 THIS WILL NUDGE EVERYTHING TO THE SIDE 2 UNITS IF THE MAP GENERATES OFF-CENTER (WHICH IS MOST OF THE TIME)
	if TheWorld.Map:GetTileCenterPoint(0, 0, 0) == 0 then
		x = -2
		z = 0
	end
	--4-13 SLIGHTLY NUDGING PLAYER BACK BEFORE ADDING BG TO GIVE THE FIGHTING GROUND SOME ELBOW ROOM
	anchor.Transform:SetPosition( x, y, z - 0 )
	]]
	
	local background = SpawnPrefab("background") 
	local sizev = 5.3 * 6 --LETS BUMP IT UP SO WE ONLY NEED TO USE ONE
	background.Transform:SetScale(sizev,sizev,sizev)
	-- background.Transform:SetPosition( x-0, (y - 10), z - (10 * 5) )  --LAYER POSITION IS DEPENDANT PURELY ON WHERE YOU SPAWN ON THE MAP. STUPID
	background.Transform:SetPosition( x-0, (y - 20), z - (25) ) --A LITTLE CLOSER TO US, PLEAS
	background.AnimState:SetLayer( LAYER_BACKGROUND )
	
	
	--12-26-17 AS OF TODAY, I JUST NOTICED ALL THESE CAUSE A 10 FPS DROP IN GAME SPEED. I NEED TO REMOVE THESE
	-- local projectile4 = SpawnPrefab("background") 
	-- local projectile5 = SpawnPrefab("background") --4-14 ADDING TWO MORE BGS BC IT ISNT QUITE WIDE ENOUGH. OOPS
	-- local projectile6 = SpawnPrefab("background")
	
	
	--2-1 THIS SHOWS THE STAGE SIZE RELATIVE TO MEMEVERSE IN SMASH BROS
	local x, y, z = anchor.Transform:GetWorldPosition()
	-- background.AnimState:PlayAnimation("memeverse") --AN ALTERNATE BACKROUND EXAMPLE FOR MIIVERSE --11-9-20 IS THIS THING EVEN STILL IN MY MOD FILES?? HAVENT SEEN IT IN YEARS
	local sizev = 5.3 * 5
	
	background.AnimState:SetMultColour(0.52,0.82,1,1) --12-17-18 --HEY, I WANNA TRY AND MATCH MY FIRST PERSON SKY
	
	
	--4-2-20 CAN WE JUST INVIS FOR A SEC?? THANKS. WE'VE GOT SOME PROBLEMS TO FIX AFTER THIS FISHING UPDATE
	--OH!... OKAY, SO THE STAGE AND EVEN THE WAVES ARE ALL STILL THERE... BUT THE BACKGROUND TEXTURES NOW SEEM TO COVER THEM
	-- background.Transform:SetPosition( x-0, (y - 5), z - (25) ) --LETS TEST A FEW THINGS...
	background.AnimState:SetLayer( 0 ) --HAHAAAA! AND ALL I HAD TO DO WAS MAKE UP A LAYER THAT DOESNT EXIST. THIS IS THE LAYER BELOW BACKGROUND (1)
	
	
	--12-24-17 A NEW LIGHTSENSOR 
	local sensor = SpawnPrefab("lightsensor")
	sensor.Transform:SetPosition( x-0, (y - 10), z - (10 * 5) )
	
	
	
	local road = SpawnPrefab("nitre")   --12-23-17 BACKGROUND NEEDS TO BE ITS OWN THING NOW. LETS CHANGE THIS TO NITRE   --11-9-20 PICKLE ARE WE FOR REAL RIGHT NOW
	road.AnimState:SetBank("background_image")
	road.AnimState:SetBuild("background_image")
	road.AnimState:PlayAnimation("ground1") --THE PATH
	road.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround )
	road.Transform:SetScale(1.7,0.5,5) --2.1
	road.AnimState:SetMultColour(0.6,0.6,0.6,0.6)
	road.Transform:SetPosition( x, y, z - 0.1 )
	road.AnimState:SetSortOrder( 0 )
	road.persists = false
	road:AddTag("NOCLICK") --10-23-18 -FINALY
	
	
	
	local tree4 = SpawnPrefab("evergreen_normal")
	DoBackgroundPlant(tree4, 2, 2, -9, -5)
	-- local tree5 = SpawnPrefab("evergreen_short")
	local tree6 = SpawnPrefab("evergreen_normal")
	DoBackgroundPlant(tree6, 1.8, 1.8, 9, -6)
	
	
	-- 1-3 THE STAGE!!!
	local stagebox = SpawnPrefab("background")  
	stagebox.AnimState:PlayAnimation("blank") --THIS'LL JUST MAKE IT INVISIBLE
	stagebox:AddTag("stage")
	stagebox.entity:AddPhysics()

	stagebox.Physics:SetMass(0) 
	stagebox.Physics:SetCylinder(12.5, 12)
	stagebox.Physics:SetFriction(0)
	stagebox.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
	stagebox.Physics:ClearCollisionMask()
	stagebox.Physics:CollidesWith(COLLISION.ITEMS)
	stagebox.Physics:CollidesWith(COLLISION.CHARACTERS)
	stagebox.Transform:SetPosition( x-0, y-12.01, z-0 ) --ADDING .1 SO ITS EVER SO SLIGHTLY BELOW THE FLOOR
	
	--1-5 THE ACTUAL FLOOR
	local stagefloor = SpawnPrefab("background")  
	stagefloor.AnimState:PlayAnimation("blank") --THIS'LL JUST MAKE IT INVISIBLE
	stagefloor:AddTag("floor")
	stagefloor.entity:AddPhysics()
	stagefloor.Physics:SetMass(0) 
	stagefloor.Physics:SetCylinder(12.4, 0.2) --SLIGHTLY THINNER THAN THE ACTUAL STAGE
	-- stagefloor.Physics:SetFriction(0) --SO PEOPLE STOP WALL CLIMBING --MMM NEVERMIND THIS MAKES IT AN ICE RINK
	stagefloor.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
	stagefloor.Physics:ClearCollisionMask()
	stagefloor.Physics:CollidesWith(COLLISION.ITEMS)
	stagefloor.Physics:CollidesWith(COLLISION.CHARACTERS)
	stagefloor.Transform:SetPosition( x-0, y-0.2, z-0 ) --!!IMPORTANT! MAKE SURE Y VALUE MATCHES FLOOR WIDTH OR ELSE IT WONT BE HIGH ENOUGH
	
	--INVISIBLE LEDGE WALLS
	local gate_distance = 12.7
	local ledgegate1 = SpawnPrefab("ledgegate") --7-14-19 -HERE, THEY HAVE THEIR OWN PREFAB NOW
	local ledgegate2 = SpawnPrefab("ledgegate")   
	local ledgegate3 = SpawnPrefab("ledgegate")
	local ledgegate4 = SpawnPrefab("ledgegate")
		
	PlantRollBarriers(ledgegate1, x, y, (z+0.4))  
	PlantRollBarriers(ledgegate2, x, y, (z-0.4))
	--9-8 WALLS FOR THE RIGHT SIDE OF THE STAGE
	PlantRollBarriers(ledgegate3, x, y, (z+0.4), -1)  
	PlantRollBarriers(ledgegate4, x, y, (z-0.4), -1)
	
	--CREATING THE BLAST ZONES IN HERE NOW   --11-9-20 WHY THO...
	anchor.components.gamerules:ApplyBlastZones(anchor) 
	
	
	
	
	--WE SHOULD JUST APPLY THE ENTIRE CAMERA PREFAB HERE TOO--   WHY THO!!
	local campref = SpawnPrefab("cameraprefab")
	campref.Transform:SetPosition( x, y, z )
	campref:AddTag("camera_point")
	TheCamera.target = campref
	
	
	--3-25-17 CREATING NEW STAGE!!!
	
	--just to easily adjust grid size 
	local xcap = 200  --12-16-18 THIS USED TO BE 150, 
	local zcap = 200
	
	local count = 0
	local gridx = -xcap
	local gridz = -zcap
	
	while gridz <= zcap do
	
		-- count = count + 1
		gridx = gridx + 2
		
		if gridx == xcap then
			gridx = -xcap
			gridz = gridz + 2
			-- print("BULDOZING OLD GROUND")
		end
		
		-- print("CREATING THE GROUND???", count, gridx)
	
		local ground = TheWorld
		if ground then
			local pt = anchor:GetPosition()
				local x, y = ground.Map:GetTileCoordsAtPoint(pt.x+gridx, pt.y, pt.z+gridz)
				local newx = x
				local newy = y + 1
				
				-- -- ground.Map:SetTile( newx, newy, GROUND.DIRT, 5 )
				-- ground.Map:SetTile( newx, newy, GROUND.IMPASSABLE, 5 )
				-- -- ground.Map:RebuildLayer( original_tile_type, newx, newy, 5 )
				-- -- ground.Map:RebuildLayer( GROUND.DIRT, newx, newy, 5 )
				-- ground.Map:RebuildLayer( GROUND.IMPASSABLE, newx, newy, 5 )
				
				--NEW TRY
				-- ground.Map:SetTile( newx, newy, GROUND.IMPASSABLE, 5 )
				ground.Map:RebuildLayer( GROUND.IMPASSABLE, newx, newy, 5 )
				ground.Map:SetTile( newx, newy, GROUND.IMPASSABLE )
				
		end
		
		
		
	end
	
	
	
	
	------AND NOW FOR THE ACTUAL STAGE ----
	
	
	--1-1-2018 --HAPPY NEW YEAR! NOW WE HAVE TO CHECK WHAT THE COORDS OF THE CENTER TILE ARE, AND SHIFT EVERYTHING FORWARD/UP 2 SPACES IF ITS OFF CENTER
	local gridoffset = 0
	
	
	local gridx = -10 - gridoffset	--12-16-18 THIS USED TO BE 10, BUT THIS IS TOO WIDE. I'M SHORTENING IT --EH... LATER I WILL. NOT RIGHT BEFORE AN IMPORTANT VIDEO
	local gridz = -8 - gridoffset
	
	while gridz <= -4 do --or (gridz == -2 and gridx == -10) do
	
		
		local ground = TheWorld
		if ground then
			local pt = anchor:GetPosition()
			local tile = ground.Map:GetTileAtPoint(pt.x+gridx, pt.y, pt.z+gridz)
			-- if tile ~= GROUND.DIRT then
				local original_tile_type = ground.Map:GetTileAtPoint(pt.x+gridx, pt.y, pt.z+gridz)
				local x, y = ground.Map:GetTileCoordsAtPoint(pt.x+gridx, pt.y, pt.z+gridz)
				
				-- local newx = x
				local newx = x + 0 --11-22-17 GONNA TRY BUMPING THE VALUE A BIT SO ITS NOT SITTING RIGHT ON THE LINE AND SOMETIMES MISSING IT
				local newy = y + 1
				
				-- -- ground.Map:SetTile( newx, newy, GROUND.DIRT, 5 )
				-- ground.Map:SetTile( newx, newy, GROUND.GRASS, 5 )
				-- -- ground.Map:RebuildLayer( original_tile_type, newx, newy, 5 )
				-- ground.Map:RebuildLayer( GROUND.GRASS, newx, newy, 5 )
				
				ground.Map:RebuildLayer( GROUND.IMPASSABLE, newx, newy, 5 )
				ground.Map:SetTile( newx, newy, 6 ) --7
				
				pt.z = pt.z + 5
				-- SpawnTurf( GROUND_TURFS[tile], pt )
		end
		
		
		
		-- count = count + 1
		gridx = gridx + 1
		
		if gridx == 10 - gridoffset then
			print("CREATING NEW STAGE")
			gridx = -10	- gridoffset	
			gridz = gridz + 2
		end
	end
	
	
	--12-15-17 DST CHANGE - CREATE THE ROGUE HITBOX SPAWNER. I THINK ONLY MASTERSIM WILL NEED TO SEE THIS
	local thenight = SpawnPrefab("roguehitboxer")
	thenight.Transform:SetPosition( x, y, z-1 ) --NO NO HONEY, ITS GOTTA FOLLOW THE ANCHOR
	
	
	
	--1-1-18 RIG THIS WORLD TO THE WAY WE WANT!! LONG TERM VARIABLES TO OFF SO THAT PLAYERS WONT NEED TO ADJUST WORLD SETTINGS
	TheWorld.components.birdspawner:SetMaxBirds(0) --1-1-18 OH OK. I GUESS THAT WAS ALL I NEEDED
	TheWorld.components.penguinspawner:SpawnModeNever()
	-- TheWorld:PushEvent("ms_setseasonsegmodifier", "onlyday")
	TheWorld:PushEvent("ms_setprecipitationmode", "never")
	TheWorld:PushEvent("ms_setlightningmode", "never")
	TheWorld:PushEvent("ms_setlightningdelay", {})
	TheWorld:PushEvent("ms_setwildfirechance", -1)
	TheWorld:PushEvent("ms_quakefrequencymultiplier", -1)
	TheWorld.components.hounded:SpawnModeNever()
	
	--1-3-22 FORGOT A FEW
	TheWorld:PushEvent("ms_enableresourcerenewal", false )
	
	TheWorld:PushEvent("ms_setseasonlength", {season = "autumn", length = TUNING.SEASON_LENGTH_FRIENDLY_VERYLONG})
	TheWorld:PushEvent("ms_setseasonlength", {season = "winter", length = 0})
	TheWorld:PushEvent("ms_setseasonlength", {season = "spring", length = 0})
	TheWorld:PushEvent("ms_setseasonlength", {season = "summer", length = 0})
	
	local segs = { day = 1, dusk = 0, night = 0, time = 30} --BRING OUT THE SUNSHINE!
	TheWorld:PushEvent("ms_setclocksegs", segs)
	--table.remove(savedata.map.topology.nodes, i)
	
	--5-4-20 SHOW THOSE CLIFFSIDES AGAIN (THANKS HORNETE!)
	TheWorld.Map:SetUndergroundFadeHeight(0)
end


--CREATES THE STAGE FOR A SECOND TIME, BUT OOONLY THE STAGE FLOOR. NOTHING ELSE
function GameRules:ReCreateStage()
	
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()

	local stagebox = SpawnPrefab("background")  
	stagebox.AnimState:PlayAnimation("blank") --THIS'LL JUST MAKE IT INVISIBLE
	stagebox:AddTag("stage")
	stagebox.entity:AddPhysics()

	stagebox.Physics:SetMass(0) 
	stagebox.Physics:SetCylinder(12.5, 12) 
	stagebox.Physics:SetFriction(0) 
	stagebox.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
	stagebox.Physics:ClearCollisionMask()
	stagebox.Physics:CollidesWith(COLLISION.ITEMS)
	stagebox.Physics:CollidesWith(COLLISION.CHARACTERS)
	stagebox.Transform:SetPosition( x-0, y-12.01, z-0 ) --ADDING .1 SO ITS EVER SO SLIGHTLY BELOW THE FLOOR



	--1-5 THE ACTUAL FLOOR
	local stagefloor = SpawnPrefab("background")  
	stagefloor.AnimState:PlayAnimation("blank") 
	stagefloor:AddTag("floor")
	stagefloor.entity:AddPhysics()
	stagefloor.Physics:SetMass(0) 
	stagefloor.Physics:SetCylinder(12.4, 0.2) 
	stagefloor.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
	stagefloor.Physics:ClearCollisionMask()
	stagefloor.Physics:CollidesWith(COLLISION.ITEMS)
	stagefloor.Physics:CollidesWith(COLLISION.CHARACTERS)
	stagefloor.Transform:SetPosition( x-0, y-0.2, z-0 ) --ALL THE VALUES CAN NOW BE SET TO 0. WELL, ASSUMING WE NEVER MAKE NEW STAGES
end





function GameRules:ReReCreateStage()
	local anchor = TheSim:FindFirstEntityWithTag("anchor2") --DSTCHANGES@@@
		--4-13 SLIGHTLY NUDGING PLAYER BACK BEFORE ADDING BG TO GIVE THE FIGHTING GROUND SOME ELBOW ROOM
		anchor.Transform:SetPosition( 0,0,0 )
		local x, y, z = anchor.Transform:GetWorldPosition()
		
		-- 1-3 THE STAGE!!!
		local stagebox = SpawnPrefab("background")  
		stagebox.AnimState:PlayAnimation("blank") 
		stagebox:AddTag("stage")
		stagebox.entity:AddPhysics()

		stagebox.Physics:SetMass(0) 
		stagebox.Physics:SetCylinder(12.5, 12) 
		stagebox.Physics:SetFriction(0) --SO PEOPLE STOP WALL CLIMBING 
		stagebox.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
		stagebox.Physics:ClearCollisionMask()
		stagebox.Physics:CollidesWith(COLLISION.ITEMS)
		stagebox.Physics:CollidesWith(COLLISION.CHARACTERS)
		stagebox.Transform:SetPosition( x-0, y-12.01, z-0 ) --ADDING .1 SO ITS EVER SO SLIGHTLY BELOW THE FLOOR
		
		--1-5 THE ACTUAL FLOOR
		local stagefloor = SpawnPrefab("background")  
		stagefloor.AnimState:PlayAnimation("blank") 
		stagefloor:AddTag("floor")
		stagefloor.entity:AddPhysics()
		stagefloor.Physics:SetMass(0) 
		stagefloor.Physics:SetCylinder(12.4, 0.2) 
		stagefloor.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
		stagefloor.Physics:ClearCollisionMask()
		stagefloor.Physics:CollidesWith(COLLISION.ITEMS)
		stagefloor.Physics:CollidesWith(COLLISION.CHARACTERS)
		stagefloor.Transform:SetPosition( x-0, y-0.2, z-0 ) --!!IMPORTANT! MAKE SURE Y VALUE MATCHES FLOOR WIDTH OR ELSE IT WONT BE HIGH ENOUGH
end


--IM NOT EVEN SURE THESE REALLY NEED TO BE HERE...
local GameSet = require "widgets/gameset"
local Text = require "widgets/text"
local PopupDialogScreen = require "screens/popupdialog"

function GameRules:GameSet() --WHEN SOMEONE WINS
	
	if self.gameover then --STOP ENDING THE GAME TWICE
		return end
	
	local segs = { day = 1, dusk = 0, night = 0, time = 30} --BRING OUT THE SUNSHINE!
	TheWorld:PushEvent("ms_setclocksegs", segs)
	
	TheSim:SetTimeScale(0.25)
	for i, v in ipairs(AllPlayers) do
		-- v:PushEvent("endgame")
		v.gamesetnetvar:set(self:GetWinner()) --ENABLES THE GAMESET SCREEN FOR ALL PLAYERS
	end
	
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	
	self.nokos = true --PREVENT KO DURING END-GAME SLOMO
	self.gameover = true
	
	anchor:DoTaskInTime(0.7, function() --THIS HAS TO BE THE ANCHOR
		self.nokos = false
		self.gameover = false
		TheSim:SetTimeScale(1) 
		
		--9-2-17 I WONDER IF IT WILL STOP CRASHING FROM ACTIVECENTERPOINT IF EVERYONE RESETS AT ONCE --I THINK IT WORKED
		for i, v in ipairs(AllPlayers) do
			if not v:HasTag("flag_disconnect") then --1-20something-22
				TheWorld:PushEvent("ms_playerdespawnanddelete", v) 
			end
			--9-4-17 REMOVE ALL PLAYERS FROM ALL TABLES.
			self:RemoveFromPlayerTable(v) --2-7-17 FIXES THE TEAM-GAME-SET I GUESS
			self:RemoveFromGame(v) --DO WE NEED THIS ONE
		end
		
		--2-11-18
		local ents = TheSim:FindEntities(0,0,0, 50, {"nonplayerfighter"})
		for k, v in pairs(ents) do
			v:PushEvent("outoflives") --FOR SPIDERS, THIS WILL HELP REMOVE THEIR COMPONENTS FROM THE STAGE PROPERLY
			v:Remove()
		end
		
		self:ClearBoard() --WE CAN USE IT NOW, AFTER ALL THE PLAYERS ARE TAKEN CARE OF--
	end)
	
end



--DST CHANGE-- 9-23-17- BASICALLY GAMESET() BUT QUICKER AND MEANT TO BE FOR TRANSITIONING BETWEEN GAMESTATES
function GameRules:StageReset() 
	-- print("ALRIGHT EVERYONE, SHOWS OVER. GO HOME")
	if self.gameover then --STOP ENDING THE GAME TWICE
		return end
	
	local player = TheSim:FindFirstEntityWithTag("anchor")
	self.nokos = true --PREVENT KO DURING END-GAME SLOMO
	self.gameover = true
	
	-- local segs = { day = 16, dusk = 0, night = 0, time = 60} --RETURN THE STAGE BACK TO ALL DAY
	for i, v in ipairs(AllPlayers) do
		v:PushEvent("sunresetdirty") --SETS THE TIME BACK TO DAY AND TIMER TO 60
	end
	
	player:DoTaskInTime(0, function()
		self.nokos = false
		self.gameover = false
		TheSim:SetTimeScale(1) --DST CHANGE - WE NEED THIS BACK ON AT SOME POINT
		
		
		--DST CHANGE 9-2-17 I WONDER IF IT WILL STOP CRASHING FROM ACTIVECENTERPOINT IF EVERYONE RESETS AT ONCE --I THINK IT WORKED
		for i, v in ipairs(AllPlayers) do
			if not v:HasTag("flag_disconnect") then
				TheWorld:PushEvent("ms_playerdespawnanddelete", v) 
			end
			
			--9-4-17 REMOVE ALL PLAYERS FROM ALL TABLES.
			self:RemoveFromPlayerTable(v) --2-7-17 FIXES THE TEAM-GAME-SET I GUESS
			self:RemoveFromGame(v) --DO WE NEED THIS ONE
		end
		
		--DST CHANGE 2-11-18
		local ents = TheSim:FindEntities(0,0,0, 50, {"nonplayerfighter"})
		for k, v in pairs(ents) do
			v:PushEvent("outoflives") --FOR SPIDERS, THIS WILL HELP REMOVE THEIR COMPONENTS FROM THE STAGE PROPERLY
			v:Remove()
		end
		
		self:ClearBoard()
	end)
	
end



--DST CHANGE -REUSEABLE -9-23-17  LOOK AT THE REMAINING LIVING PLAYERS AND CHOOSE A VICTOR
function GameRules:GetWinner() --!!! THIS ONLY RETURNS THE WINNER'S USERNAME!!
	local winner = "NO WINNER"
	
	for k,v in pairs(self.livingplayers) do
		winner = v:GetDisplayName()
		-- print("AND THE WINNER IS...", v, v:GetDisplayName())
		
		--IF THE GAME HAPPENED TO GRAB A SLAVE, HAND OVER THE MASTER'S NAME INSTED
		if v.components.stats.master and v.components.stats.master:IsValid() then
			winner = v.components.stats.master:GetDisplayName()
		end
		
		if winner == "MISSING NAME" then --11-27-20 
			winner = self:GetPlayerDisplayName(v, true)
		end
		
		--1-21-22 IF WE'RE PLAYING TEAM BATTLES, DISPLAY THE TEAM NAME INSTEAD
		if self.gamemode == "PVP" and TUNING.SMASHUP.TEAMS > 1 and v.components.stats.team then
			local teamname = v.components.stats.team
			if teamname == "red" then teamname = STRINGS.SMSH.TEAM_RED end
			if teamname == "blue" then teamname = STRINGS.SMSH.TEAM_BLUE end
			winner = teamname.." "..STRINGS.SMSH.TEAM_NAME
		end
	end
	
	if self.hordemode == true then --WAIT, THIS DOESNT SEEM RIGHT...
		winner = "The Spiders"
	end
	
	return winner
end




--DST CHANGE -REUSEABLE -6-25-18 OKAY, BUT NOW RETURN THE ACTUAL WINNER'S REF. THIS IS MORE IMPORTANT
function GameRules:GetWinnerRef()

	local winner = nil --FOR NOW
	
	for k,v in pairs(self.livingplayers) do
		winner = v
		--IF THE GAME HAPPENED TO GRAB A SLAVE, HAND OVER THE MASTER'S NAME INSTED
		if v.components.stats.master and v.components.stats.master:IsValid() then
			winner = v.components.stats.master:GetDisplayName()
		end
	end
	
	return winner
end


--5-28-20 IF THE WINNER BAILED DURING THE CHARACTER SELECT PHASE, WIPE OUT THE WINNER. OTHERWISE WINNER-STAYS WILL ENDLESSLY CYCLE HIM BACK IN
function GameRules:RetireBailedWinner(player)
	local playername = player:GetDisplayName() or nil
	if playername == self.winner then
		self.winner = nil
		print("PREVIOUS WINNER BAILED. REMOVING WINNER STATUS")
	end
	
end



--DST CHANGE -REUSEABLE -6-28-18 DESIGNED SPECIFICALLY FOR FINDING HOW MANY SPIDERS ARE ON SCREEN, BUT CAN USE FOR OTHER PURPOSES TOO
function GameRules:CountPlayersWithTag(tag)
	local tagged_players = 0
	
	for k,v in pairs(self.livingplayers) do --THIS INCLUDES NPCS, RIGHT?...
		if v:HasTag(tag) or (v.sg and v.sg:HasStateTag(tag)) then --SURE, WHY NOT. THIS CAN INCLUDE NORMAL TAGS OR STATE TAGS
			tagged_players = tagged_players + 1
		end
	end
	
	return tagged_players
end



--11-27-20 RETURNS A DISPLAY NAME IF THEY HAVE ONE, AND NOTHING IF THEY DONT
function GameRules:GetPlayerDisplayName(player, booldisplayname)
	local playername = player:GetDisplayName() or nil
	if playername == "MISSING NAME" then
		playername = "" --A BLANK STRING
	end
	--IF WE WANT TO GRAB THEIR DISPLAY NAME INSTEAD, WE CAN DO THAT
	if booldisplayname and player.components.stats.displayname then
		playername = player.components.stats.displayname
	end
	
	return playername
end



--1-25-22 ANNOUNCE OUR NAME (AND PING) AT THE ROUND START.
function GameRules:IntroduceSelf(fighter)
	-- --AND AGAIN, TO REFRESH IT
	-- print("ALLOW US TO INTRODUCE OURSELVES", fighter.speakselfnetvar, self.gamemode)
	if fighter.speakselfnetvar and self.gamemode == "PVP" then
		fighter.speakselfnetvar:set("and_now")
		fighter.speakselfnetvar:set("say_hello") --SAYS BOTH THEIR USERNAME AND THEIR PING
		-- fighter.components.talker:Say(tostring(self:GetPlayerDisplayName(fighter)), 5, true) --JUST CONTINUE TO DO THIS NOW UNTIL IT ACTUALLY WORKS
	else
		fighter.components.talker:Say(tostring(self:GetPlayerDisplayName(fighter)), 5, true)
	end
end



--DST CHANGE -REUSEABLE -9-23-17  CREATE A COUNTDOUN ON SCREEN AND THEN UN-LOCK THE CONTROLS
function GameRules:BeginCountdown()

	--I SHOULD DO NESTED FUNCTIONS MORE OFTEN --NEVERMIND THIS WASN'T THAT USEFUL
	local function UniversalMessage(message) 
		for k,v in pairs(AllPlayers) do
			v.jumbotronmessage:set(message)
		end
	end
	
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	--PLAYER = ANCHOR HERE
	
	if anchor:HasTag("countingdown") then
		return end 	--10-11-17 FOR THE LOVE OF GOD, IF WE'RE ALREADY COUNTING DOWN, DON'T START A SECOND COUNTDOWN
	
	anchor:AddTag("countingdown")
	self.winner = nil --GET THIS OUTTA HERE
	
	
	--7-4-18 --IF THERE IS A LOCAL P2 PLAYER, USHER THEM INTO THE SPAWN QUE LIKE A DISNEY FAST-PASS. THEY ALWAYS GET IN.
	if self.p2_reincarne then
		self:SpawnLocalP2(self.p2_reincarne) --SPAWN THE DUDE
		self.p2_reincarne = nil --OKAY, THEY'RE IN NOW. TAKE THE PASS AWAY FROM THEM. THEY NEED TO BE MANUALLY ADDED IN EVERY NEW ROUND BY THE HOST OF THE SERVER.
		-- self.localp2mode = false --IS... NOW A GOOD TIME TO TURN THIS OFF?... OR WILL THIS MESS THINGS UP?
	end
	
	
	--10-15-17 --ANY PLAYERS WHOS ID MATCHES AN ID IN THE PLAYERQUE; TELL THEM THEY GOTTA WAIT
	anchor:DoTaskInTime(1, function()
		 --MOVE THE PLAYERS FROM QUE TO THE MATCH POOL
		-- self:MoveQueToMatch() --IS ONE SECOND LONG ENOUGH FOR ALL THE PLAYERS TO SPAWN IN?..
		-- self:SkinCylce() --UNUSED
	
		for k,v in pairs(AllPlayers) do
			for l,b in pairs(self.playerque) do --TELL ALL THE PLAYERS NOT CURRENTLY IN THE MATCHPOOL TO WAIT THEIR TURN
				if v:GetDisplayName() == b then
					-- v.jumbotronheader:set("Game Full. Waiting in line - " .. l .. " left")
				end
			end
			
		end
		
		for k,v in pairs(AllPlayers) do
			-- v:PushEvent("cambumpdirty") --MAKES THE CAMERA DO THIS FANCY THING WHERE IT FLIES DOWN ALL CINNEMATIC LIKE
			v.cambumpnetvar:set("JUST DO SOMETHING") --AH YES, IM SURE THIS IS TOTALLY THE PROPER WAY TO DO IT   	--I MEAN... IT WORKED THOUGH
			--1-31-21 START THE MUSIC!~
			v.battlemusicnetvar:set("SHUFFLE") --1-31-21 IF IT WORKED ONCE...
		end
	end)
	
	
	
	--NEEDS MORE THAN ONE SECOND TO LOAD PLAYERS IN AND COUNT THEM
	anchor:DoTaskInTime(1.5, function()
		--11-27-18 ANY CPU SPARRING PARTNERS SHOULD BE DROPPED OFF HERE. THEY AREN'T PLAYERS AT ALL, BUT SHOULD ACT KINDA LIKE ONE!... I GUESS?
		if self.gamemode == "VS-AI" and self.cpulevel then
			--8-20-20
			local spidertype = nil
			if self.cpulevel <= 5 then
				spidertype = "spiderfighter_easy"
			elseif self.cpulevel < 10 then
				spidertype = "spiderfighter_medium"
			else
				spidertype = "spiderfighter"   --spiderfighter --MY BOY
			end
			
			--8-21-20 MATCH THE NUMBER OF CPUS TO THE NUMBER OF PLAYERS
			local playercount = #self.livingplayers --WE HAVE TO TAKE THIS COUNT BEFOREHAND BECAUSE WE'RE ABOUT TO START SPAWNING MORE
			for k,v in pairs(self.livingplayers) do
				anchor.components.hordes:SpawnLocalBaddie(spidertype)
				-- print("SPAWN A GUY")
				if k >= playercount then 
					break end
			end
			
			
			for k,v in pairs(anchor.components.hordes.sparring_cpus) do
				v.components.aifeelings.ailevel = self.cpulevel
				v.sg:GoToState("patient_spawn")
				--HE HAS HIS OWN CUSTOM SPAWN STATE THAT HOLDS HIM STILL UNTIL THE ROUND STARTS. HE'S A GOOD BOY
			end
		end
		
		
		--1-19-22 EVERYONE HERE? OK, LET'S GET TEAMS SORTED OUT.
		if self.gamemode == "PVP" and TUNING.SMASHUP.TEAMS > 1 and not (TUNING.SMASHUP.TEAMS == 3 and #self.livingplayers < 4) then
			local redteam = {}
			local blueteam = {}
			local randomteam = {}
			
			local maxteamsize = math.ceil(#self.livingplayers / 2)
			if TUNING.SMASHUP.TEAMSSIZECR > 1 then
				maxteamsize = #self.livingplayers
			end
			
			local teamqueue = {} --A SNAPSHOT OF LIVINGPLAYERS TO ALTER
			for k, v in pairs(self.livingplayers) do
				table.insert(teamqueue, v)
			end
			
			for k, v in pairs(self.teamreserves) do
				if v.tname == "red" and #redteam < maxteamsize then
					table.insert(redteam, self:GetPlayerRefFromDisplayname(v.pname))
					self.teamreserves[k] = nil --AND BLANK OUT THE TABLE ENTRY, BUT DON'T REMOVE IT! WE'RE STILL CYCLING THROUGH...
					table.removearrayvalue(teamqueue, self:GetPlayerRefFromDisplayname(v.pname))
					print("ASSIGNED TO RED TEAM", v.pname)
				elseif v.tname == "blue" and #blueteam < maxteamsize then
					table.insert(blueteam, self:GetPlayerRefFromDisplayname(v.pname))
					self.teamreserves[k] = nil --AND BLANK OUT THE TABLE ENTRY, BUT DON'T REMOVE IT! WE'RE STILL CYCLING THROUGH...
					table.removearrayvalue(teamqueue, self:GetPlayerRefFromDisplayname(v.pname))
					print("ASSIGNED TO BLUE TEAM", v.pname)
				else
					print("ASSIGNED TO RANDOM", v.pname)
					table.insert(randomteam, self:GetPlayerRefFromDisplayname(v.pname)) --JUST TO HELP REFERENCE TEAM SIZES
				end
			end
			
			--ACTUALLY, THIS IS A BETTER ASSIGNER
			for k, v in pairs(randomteam) do
				if #redteam < #blueteam then
					table.insert(redteam, v)
				elseif #blueteam < #redteam then
					table.insert(blueteam, v)
				--TEAMS ARE EQUAL. RANDOM ASSIGN
				elseif math.random() < (0.5) then
					table.insert(redteam, v)
				else
					table.insert(blueteam, v)
				end
			end
			maxteamsize = math.max(#redteam, #blueteam) --NEW MAX TEAM SIZE IS WHICHEVER TEAM IS LARGEST
			
			
			
			--ALRIGHT, ANY LEFTOVERS ARE PEOPLE WHO EITHER DIDN'T CHOOSE A TEAM, OR THEIR TEAM WAS FULL.
			--[[
			for k, v in pairs(teamqueue) do
				if #redteam < maxteamsize then
					table.insert(redteam, v)
					print("FILLING RED TEAM", v)
				elseif #blueteam < maxteamsize then
					table.insert(blueteam, v)
					print("FILLING BLUE TEAM", v)
				end
			end
			]]
			
			--THAT'S ALL THE PLAYERS. NOW, DO WE NEED TO FILL IN ANY LEFTOVER SLOTS?
			if TUNING.SMASHUP.OPENTEAMFILL == 1 then
				-- local redfillerspiders = #redteam
				while #redteam < maxteamsize do
					local pawn = anchor.components.hordes:SpawnLocalBaddie("spiderfighter_medium", "red")
					table.insert(redteam, pawn)
				end
				
				-- local bluefillerspiders = #blueteam
				while #blueteam < maxteamsize do
					local pawn = anchor.components.hordes:SpawnLocalBaddie("spiderfighter_medium", "blue")
					table.insert(blueteam, pawn)
				end
			end
			
			
			--APPLY TEAMS TO PLAYERS
			for k,v in pairs(redteam) do
				v.components.stats.team = "red"
				v.components.hoverbadge:AddTeamGlow("red")
			end
			
			for k,v in pairs(blueteam) do
				v.components.stats.team = "blue"
				v.components.hoverbadge:AddTeamGlow("blue")
			end
			
			--AND THEN CLEAR THIS OUT FOR NEXT TIME
			-- self.teamreserves = {}
			--AND THAT SHOULD BE IT...
		end
		self.teamreserves = {} --DO IT EVERY TIME THO
	end)
	
	
	
	--6-26-18 - IF WE'RE PLAYING HORDEMODE, JUST SKIP ALL THAT JAZZ AND START THE GAME
	if self.hordemode then
			anchor:DoTaskInTime(2, function()
				for k,v in pairs(self.livingplayers) do
					v.sg:GoToState("idle")
					-- v.components.locomotor:RunForward() --I'M PRETTY SURE THIS IS NO LONGER AN ISSUE --JUMPSTART THIER ENGINES IN AN ATTEMPT TO GET THIER PHYSICS WORKING
					--11-6-17 SET THE NAME ABOVE EVERY PLAYER'S HEAD
					v.components.talker:Say(tostring(v:GetDisplayName()), 5, true) --NOICE. DIDN'T EXPECT THIS TO WORK HONESTLY
					v:RemoveTag("lockcontrols")
					v:PushEvent("livesdelta") --1-4-22 AND UPDATE HUD
				end
				self:ChangeMatchState("running") --WAIT FOR THE ACTUAL MATCH TO START BEFORE SETTING IT TO RUNNING
				anchor:RemoveTag("countingdown")
				anchor.components.hordes:NextWave()
			end)
		return end --AND THEN DONT DO ANYTHING ELSE C:
	--IF NOT, COOL, JUST CONTINUE WITH THE REST OF IT
	
	
	--GIVE THE PLAYERS 2 SECONDS TO FINISH SPAWNING IN FIRST
	
	anchor:DoTaskInTime(2, function()
		UniversalMessage("3")
		anchor.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
		anchor.SoundEmitter:PlaySound("dontstarve/HUD/research_unlock")
		for k,v in pairs(self.livingplayers) do
			v.sg:GoToState("idle")
			v:PushEvent("livesdelta") --1-4-22 AND UPDATE HUD
			--1-26-22 IS IT SO MUCH TO ASK TO START WITH THE CORRECT NUMBER OF LIVES?? DO THEY NEED TO BE DIFFERENT??
			v.customhpbadgelives:set(v.components.stats.lives + 1)
			v.customhpbadgelives:set(v.components.stats.lives)
			--11-6-17 SET THE NAME ABOVE EVERY PLAYER'S HEAD
			-- v.components.talker:Say(tostring(v:GetDisplayName()), 5, true) --NICE. DIDN'T EXPECT THIS TO WORK HONESTLY
			-- v.components.talker:Say(tostring(self:GetPlayerDisplayName(v)), 5, true) --11-27-20 BUT THIS ONE WORKS BETTER
			self:IntroduceSelf(v) --v.speakselfnetvar:set("say_hello")
		end
		for k,v in pairs(anchor.components.hordes.sparring_cpus) do
			v.sg:GoToState("patient_spawn") --IS HAROLD HERE? THAT LITTLE RASCLE, TELL HIM TO HOLD STILL!
		end
	end)
	
	
	anchor:DoTaskInTime(3, function()
		UniversalMessage("2")
		anchor.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
		anchor.SoundEmitter:PlaySound("dontstarve/HUD/research_unlock")
		for k,v in pairs(self.livingplayers) do
			-- v.components.locomotor:RunForward() --AND ATTEMPT TO GET THEIR PHYSICS WORKING
		end
	end)
	
	anchor:DoTaskInTime(4, function()
		for k,v in pairs(self.livingplayers) do
			-- v.components.talker:Say(tostring(self:GetPlayerDisplayName(v)), 5, true) --AND AGAIN, TO REFRESH IT
			-- v.speakselfnetvar:set("say_hello")
			self:IntroduceSelf(v)
		end
		UniversalMessage("1")
		anchor.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
		anchor.SoundEmitter:PlaySound("dontstarve/HUD/research_unlock")
	end)
	
	anchor:DoTaskInTime(5, function()
		UniversalMessage("GO!")
		for k,v in pairs(self.livingplayers) do --THIS ONE IS ONLY FOR LIVINGPLAYERS, THOSE CURRENTLY IN THE FIGHT
			v:RemoveTag("lockcontrols")		--OKAY, THIER BUTTONS WORK STARTING NOW
		end
		self:ChangeMatchState("running") --WAIT FOR THE ACTUAL MATCH TO START BEFORE SETTING IT TO RUNNING
		anchor:RemoveTag("countingdown")
		anchor.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold") --SOME NEATO SOUNDS!
		anchor.SoundEmitter:PlaySound("dontstarve/HUD/get_gold")
		
		-- anchor.components.hordes.sparring_cpu = nil --SO THE NEXT GAME WE RUN WONT SPAWN A SPIDER (UNLESS WE SAY SO)
		anchor.components.hordes.sparring_cpus = {} --CLEAR THE TABLE FOR THE NEXT USE
		
		--6-9-18 -IF WE'RE IN HOARD MODE, RELEASE THE SPIDERS! BUT DONT START THE TIMER
		if self.hordemode then
			anchor.components.hordes:NextWave()
		else
		
			--12-26-17 BEGIN THE MATCH COUNTDOWN
			local segs =
				{
					day = 1,
					dusk = 1,
					night = 4,
					-- time = 3,
					time = (TUNING.SMASHUP.MATCHTIME * TUNING.SMASHUP.MATCHLIVES), --NUMBER OF LIVES * TIME VARIABLE, ALL SET IN MOD CONFIG SETTINGS
				}
			TheWorld:PushEvent("ms_setclocksegs", segs)
		end
	end)
	
end



--KIND OF A WEIRD PLACE FOR A FUNCTION THAT IS ONLY USED TWICE IN AIFEELINGS BUT OK
function GameRules:IsOnSameSide(me, them)
	if (me.components.stats.team ~= nil and (me.components.stats.team == them.components.stats.team)) or (me.components.stats.master == them) or (them.components.stats.master == me) or (me == them) then
		return true
	else
		return false
	end
end



--7-3-18 --OKAY, THIS IS WAY TO BIG TO KEEP HERE, BUT THIS IS JUST TEMPORARY.
--LOCAL (non rpc related) CONTROL HANDLERS ARE THE ONLY CONTROLS THAT CAN BE SET UP OUTSIDE OF MODMAIN LIKE THIS. RPCS WILL EAT EACH OTHER UP IF USED ELSEWHERE
local function p2local_applykeyhandlers(localborn)

	-- local attack =  257		-- //SIGH/..... SO. AS IT TURNS OUT. THIS LAPTOP CANT SUPPORT HOLDING DOWN 2 ARROW KEYS AND PRESSING [1] ON THE NUMPAD AT THE SAME TIME...
	local attack =  260		--OKAY THEN. SHIFT IT ALL TO THE RIGHT ONE KEY. ATTACK IS [2] AND SPECIAL IS [3]    --AND GRAB IS IDK. RIP THAT BUTTON
	local special =  261	--[4][5][6] GAH!!..... ITS CLOSE. BUT THE DOWN+RIGHT ARROW KEYS HELD TOGETHER DONT WORK WITH !ANY! NUMPAD KEY COMBINATION. MAN THAT SUCKS
	local grab = 262  --271  --THE NUMPAD ENTER KEY
	local jump =  256 --KEY_UP
	local block = 305 --LCONTROL  --KEY_LSHIFT --INCOMPATIBLE WHILE NUMPAD IS IN USE OR ESLE RIP PLAYER2
	-- local block2 = KEY_LSHIFT --JUST FOR EASE OF USE
	local up = KEY_UP
	local down = KEY_DOWN
	local left = KEY_LEFT
	local right = KEY_RIGHT
	local cstick_up = 264
	local cstick_down = 261
	local cstick_left = 260
	local cstick_right = 262
	
	
	--OKAY, BUT GIVE IT A FEW SECS THO...
local anchor = TheSim:FindFirstEntityWithTag("anchor")
anchor:DoTaskInTime(0, function()
	
	
	local p2_localplayer = SpawnPrefab(localborn)
	local x, y, z = ThePlayer.Transform:GetWorldPosition()
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	
	anchor.components.gamerules:SpawnPlayer(p2_localplayer, 0, 0, z) --4-11-20 AT LEAST GET THE Z COORD RIGHT!!
	
	-- p2_localplayer:AddTag("maxclone")
	p2_localplayer:AddTag("dummynpc") --9-14-17 DST TO DETIRMINE IF THE CHARACTER IS A LITERAL CHARACTER NOT CONTROLLED BY A USER
	p2_localplayer:AddTag("customspawn") --DST I SHOULDNT NEED THIS ALSO BUT OH WELL
		
		
	--NOW WE HAVE TO RE-ARRANGE THE KEYDETECTOR KEYS WITH THE RIGHT ONES. SPECIFICALLY FOR THE DIAGONAL INPUT DETECTORS.
	-- p2_localplayer:AddComponent("playercontroller_1")
	p2_localplayer.components.keydetector.attack = attack
	p2_localplayer.components.keydetector.special = special
	p2_localplayer.components.keydetector.grab = grab
	p2_localplayer.components.keydetector.jump = jump
	p2_localplayer.components.keydetector.block = block --LCONTROL  --KEY_LSHIFT --INCOMPATIBLE WHILE NUMPAD IS IN USE OR ESLE RIP PLAYER2
	p2_localplayer.components.keydetector.up = up
	p2_localplayer.components.keydetector.down = down
	p2_localplayer.components.keydetector.left = left
	p2_localplayer.components.keydetector.right = right
	p2_localplayer.components.keydetector.cstick_up = KEY_U
	p2_localplayer.components.keydetector.cstick_down = KEY_J
	p2_localplayer.components.keydetector.cstick_left = KEY_H
	p2_localplayer.components.keydetector.cstick_right = KEY_K
	
	-- p2_localplayer:DoTaskInTime(0.5, function()
		p2_localplayer:AddComponent("keydetector")  --APPARENTLY, THIS KIND OF PLAYER DOESN'T NEED A playercontroller_1 COMPONENT. BUT KEYDETECTOR IS STILL A MUST
		-- p2_localplayer.components.keydetector.attack = attack
		-- p2_localplayer.components.keydetector.special = special
		-- p2_localplayer.components.keydetector.jump = jump
		-- p2_localplayer.components.keydetector.block = block
		-- p2_localplayer.components.keydetector.up = up
		-- p2_localplayer.components.keydetector.down = down
		-- p2_localplayer.components.keydetector.left = left
		-- p2_localplayer.components.keydetector.right = right
	-- end)
				
	
	--10-25-20 TAPJUMP SETTINGS FOR PLAYER TWO. THEY'LL HAVE TO BE SET AT THE TIME OF CHOOSING THEIR CHARACTER BUT... EH ITS CLOSE ENOUGH I GUESS
	-- print("AND ANOTHER JUMP?", Preftapjump_p2)
	if Preftapjump_p2 == "off" then
		p2_localplayer.components.stats.tapjump = false
	end
	
	
	
	local function jump1(player)
	if player:HasTag("lockcontrols") then return end --10-8-17 DST- THIS IS BEING ADDED TO ALL KEYBOARD KEY LISTNERS TO PREVENT THEM FROM ACTIVATING WHILE CHATTING
		--self.inst.components.jumper:Jump()
		-- player.components.stats:ShowSelectScreen()
		-- if not player:HasTag("jump_key_dwn") then --!!! IT !!MUST!! BE DEFINED AS PLAYER!! SELF.INST WILL JUST REFER TO THE HOST
		if not player.components.keydetector.holdingjump == true then --6-9-20
			-- print("JUMP BUTTON")
			
			--4-23-20 OKAY, LETS TRY THAT AGAIN
			if player.sg:HasStateTag("listen_for_atk") then
				-- print("---- FORCE RE-JUMP ----")
				--player.components.stats:SetKeyBuffer("jump", player.components.keydetector:GetBufferKey(player)) 
				player.components.stats:SetKeyBuffer("jump", player.components.stats.key) --4-24-20 ACTUALLY, KEEP THE KEY BUFFER THE SAME, THE ATTACKS WILL SET THOSE
			else
			
				player:PushEvent("jump")
				player.components.stats:SetKeyBuffer("jump", "ITSNIL") --4-18-20 REMOVING THE KEYBUFFER CHECK, SINCE WE DONT USE IT HERE  --player.components.keydetector:GetBufferKey(player)
			end
		end
		player:AddTag("jump_key_dwn")
		player.components.keydetector.holdingjump = true
		
		--4-23-20 EXTRA BAGGAGE
		player.sg:AddStateTag("listen_for_jump")
		player:DoTaskInTime(0, function() 
			player.sg:RemoveStateTag("listen_for_jump")
		end)
		
		-- print("UP")
	end
	local function jump2(player)
		if player:HasTag("lockcontrols") then return end
		player:RemoveTag("jump_key_dwn")
		player.components.keydetector.holdingjump = false
		-- print("DOWN")
	end
	
	-- AddModRPCHandler(modname, "jump1er", jump1)
	TheInput:AddKeyDownHandler(jump, function()
		-- if not IsPaused() then
			-- SendModRPCToServer(MOD_RPC[modname]["jump1er"]) 
		-- end
		jump1(p2_localplayer) --JUST SEND THE JUMP COMMAND TO THE DUMMY
	end)
	
	-- AddModRPCHandler(modname, "jump2er", jump2)
	-- TheInput:AddKeyUpHandler(jump, function() if not IsPaused() then SendModRPCToServer(MOD_RPC[modname]["jump2er"]) end end)
	TheInput:AddKeyUpHandler(jump, function() jump2(p2_localplayer) end)
	
	
	--BLOCK
	local function block1(player)
	if player:HasTag("lockcontrols") then return end
		if not player:HasTag("holdingblock") then --1-1-2018 REUSEABLE (DS AND CONTROLER) TO PREVENT BUFFERED AIRDODGES
	-- if ThePlayer.HUD:IsChatInputScreenOpen() then return end
	-- if player.HUD:IsChatInputScreenOpen() then return end
		player:PushEvent("block_key")
		
		if not player:HasTag("trytech_window") then
			player:AddTag("trytech")
			player:AddTag("trytech_window")
			player:DoTaskInTime(0.4, function() --1-19-17 CHANGING BOTH FROM 0.3 TO 0.4 TO ACCOUNT FOR DELAYED LANDING
				player:RemoveTag("trytech")
				player:DoTaskInTime(0.4, function()
					player:RemoveTag("trytech_window")
				end)
			end)
		end
		
		if player.sg:HasStateTag("can_ood") then
			player.sg:GoToState("block_startup")
			player:AddTag("wasrunning")
		end
		
		-- if player.sg:HasStateTag("must_roll") then
			-- player.sg:GoToState("roll_forward")
		-- end
		
		--7-17-17 AN EARLY LISTENER FOR ROLLS 
		-- print("IS LISTENFORROLL ACTIVE?   ", player:HasTag("listen_for_roll"))
		if player:HasTag("listen_for_roll") then
			player:PushEvent("roll", {key = player.components.keydetector:GetLeftRight(player)}) --DONT FORGET TO PASS PLAYER INTO THE KEYDETECTOR FN!
			player.components.stats:SetKeyBuffer("roll", player.components.keydetector:GetLeftRight(player))
		end
		
		player:AddTag("wantstoblock")
		player:AddTag("holdingblock") --1-1-2018 REUSEABLE- LITERALLY THE SAME THING AS WANTS TO BLOCK BUT WHATEVER
	end
	end
	local function block2(player)
	if player:HasTag("lockcontrols") then return end
		player:RemoveTag("wantstoblock")
		player:RemoveTag("holdingblock") --1-1-2018 REUSEABLE-
	end
	
	-- AddModRPCHandler(modname, "block1er", block1)
	TheInput:AddKeyDownHandler(block, function() block1(p2_localplayer) end)
	
	-- AddModRPCHandler(modname, "block2er", block2)
	TheInput:AddKeyUpHandler(block, function() block2(p2_localplayer) end)
	
	
	
	
	--ATTACK
	local function attack1(player)
	if player:HasTag("lockcontrols") then return end
		if not player.components.keydetector.holdingattack then --THE HELD BUTTON TESTER ISNT ON THE CONTROLLER YET
		-- print("SHWING", player, player.components.keydetector:GetBufferKey(player), player.components.keydetector:GetUp())
		-- print("SHWING", player.components.keydetector:GetBufferKey(player)) --TRUE ALSE TRUE (WITH NEUTRAL)
		player:PushEvent("attack_key")
		player:AddTag("atk_key_dwn")
		--4-23-20 POWER MOVE - HAVE 1 FRAME LISTENERS ON BOTH THE ATK AND JUMP KEY. IF EITHER KEYHANDLER DETECTS THE OTHER WAS JUST PRESSED, CANCEL WHATEVER TO BUFFER A JUMP AIREAL
		player.sg:AddStateTag("listen_for_atk")
		player:DoTaskInTime(0, function() --IT'S SAFER TO DO THIS AS A STATETAG SO THAT IF USERS ARE HIT OUT OF IT, IT WILL REMOVE ITSELF
			player.sg:RemoveStateTag("listen_for_atk")
		end)
		--IN THAT ONE FRAME WINDOW, IF THE JUMP KEY IS PRESSED, WE'LL CANCEL THE ATTACK AND SET IT TO A JUMP WITH BUFFERED ATTACK INSTEAD
		if player.sg:HasStateTag("listen_for_jump") then
			--11-10-20 IF THEY HAVE TAPJUMP ENABLED, AND THEY BUFFERED THE UP KEY, WE SHOULD ASSUME THIS WAS MEANT TO BE AN UPSMASH
			if player.components.stats.tapjump and player.components.keydetector:GetBufferKey(player) == "up" and  player:HasTag("listen_for_usmash") then
				player:PushEvent("cstick_up")
				player.components.stats:SetKeyBuffer("cstick_up")
			else
				-- print("---- FORCE RE-JUMP from atk----", player.components.keydetector:GetBufferKey(player))
				player.components.stats:SetKeyBuffer("jump", player.components.keydetector:GetBufferKey(player))
			end
		
		--4-18-20 TESTING NEW BUFFERABLE JUMP-AIRIALS (IF CURRENT BUFFERKEY = JUMP, DONT OVERWRITE IT, BUT ADD A KEY TO IT TO BUFFER AIRIAL)
		elseif player.components.stats.event == "jump" and player.components.stats.buffertick >= 1 then
			--ACTUALLY NO DON'T REFRESH IT, JUST ADD THE ATTACK KEY. OTHERWISE MASHING ATTACK COULD EXTEND THE BUFFER A TON
			player.components.stats.key = player.components.keydetector:GetBufferKey(player)
		--end
		
		elseif player:HasTag("listen_for_smash") or player.sg:HasStateTag("must_fsmash") then
			-- player:PushEvent("cstick_forward")
			-- player.components.stats:SetKeyBuffer("cstick_forward", {key = player.components.keydetector:GetLeftRight(player)}) --7-17-17
			-- player:PushEvent("cstick_side") --7-20-17 THIS WILL MAKE DIRECTIONAL C-STICK BUFFERING SO MUCH EASIER
			player:PushEvent("cstick_side", {key = player.components.keydetector:GetLeftRight(player)}) --12-10-17 ADDING THIS CHECK FOR DIRECTIONAL INPUT --REUSEABLE
			player.components.stats:SetKeyBuffer("cstick_side", player.components.keydetector:GetLeftRight(player)) --7-17-17
		elseif player:HasTag("listen_for_usmash") or player.sg:HasStateTag("must_usmash") then
			player:PushEvent("cstick_up")
			player.components.stats:SetKeyBuffer("cstick_up")
		elseif player:HasTag("listen_for_dsmash") or player.sg:HasStateTag("must_dsmash") then
			player:PushEvent("cstick_down")
			player.components.stats:SetKeyBuffer("cstick_down")
		else
			-- player:PushEvent("throwattack")
			-- player:AddTag("atk_key_dwn")
			-- {hitstun = self.hitstun+self.hitlag}
			-- player:PushEvent("throwattack", {key = player.components.keydetector:GetBufferKey(player)}) --4-5 ADDING ADDITIONAL DATA FOR KEY BUFFERING
			-- player.components.stats:SetKeyBuffer("throwattack", player.components.keydetector:GetBufferKey(player))
			player:PushEvent("throwattack", {key = player.components.keydetector:GetBufferKey(player)}) --3-19-17 THE DST VERSION
			player.components.stats:SetKeyBuffer("throwattack", player.components.keydetector:GetBufferKey(player))
		end
		end
		player.components.keydetector.holdingattack = true
	end
	
	local function attack2(player)
	if player:HasTag("lockcontrols") then return end
		player:RemoveTag("atk_key_dwn") 
		if player.sg:HasStateTag("chargingfsmash") then
			-- player:DoTaskInTime(0.1, function() --NO WHY WOULD I DO THIS???
				-- player.sg:GoToState("fsmash")
			-- end)
			player.sg:GoToState("fsmash")
		elseif player.sg:HasStateTag("chargingdsmash") then
			player.sg:GoToState("dsmash")
		elseif player.sg:HasStateTag("chargingusmash") then
			player.sg:GoToState("usmash")
		elseif player.sg:HasStateTag("chargingmisc") then --THIS IS AN EXTRA ATTACK-BUTTON-UP HANDLER JUST FOR MODDERS <3  --6-11-17 WAIT WHEN DID I MAKE THIS? HOW DOES IT WORK???
			player.sg:GoToState("misc")
		end
		player.components.keydetector.holdingattack = false
	end
	
	-- AddModRPCHandler(modname, "attack1er", attack1)
	TheInput:AddKeyDownHandler(attack, function() attack1(p2_localplayer) end)
	
	-- AddModRPCHandler(modname, "attack2er", attack2)
	TheInput:AddKeyUpHandler(attack, function() attack2(p2_localplayer) end)
	
	
	--9-10 FOR GRABBING
	local function grab1(player)
	if player:HasTag("lockcontrols") then return end
		if not player.components.keydetector.holdinggrab then
			player:PushEvent("throwattack", {key = "block"})
			-- player.components.stats:SetKeyBuffer("jump", player.components.keydetector:GetBufferKey(player)) --9-10 TODOLIST THE FIX LIST --MAKE GRABS BUFFERABLE
		end
		player.components.keydetector.holdinggrab = true
	end
	local function grab2(player)
	if player:HasTag("lockcontrols") then return end
		player.components.keydetector.holdinggrab = false
	end
	
	-- AddModRPCHandler(modname, "grab1er", grab1)
	TheInput:AddKeyDownHandler(grab, function() grab1(p2_localplayer) end)
	
	-- AddModRPCHandler(modname, "grab2er", grab2)
	TheInput:AddKeyUpHandler(grab, function() grab2(p2_localplayer) end)




--[[
	--CSTICK UP
	local function cup1(player)
	if player:HasTag("lockcontrols") then return end
		player:AddTag("atk_key_dwn")
		player:PushEvent("cstick_up")
		player:PushEvent("attack_key") --10-20-17 ADDED THESE BECAUSE QUICK-TAP DIRECTIONAL ATTACK KEYS CAN SOMETIMES BE THESE --REUSEABLE
		player.components.stats:SetKeyBuffer("cstick_up")
		print("STAHP")
		-- TheWorld.components.ambientlighting:CycleBlue()  -----0000000000000
	end
	
	local function cup2(player)
	if player:HasTag("lockcontrols") then return end	
		player:RemoveTag("atk_key_dwn")
		if player.sg:HasStateTag("chargingusmash") then
			player.sg:GoToState("usmash")
		end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "cup1er", cup1)
	TheInput:AddKeyDownHandler(cstick_up, function() if not IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cup1er"]) end end)
	
	AddModRPCHandler(TUNING.MODNAME, "cup2er", cup2)
	TheInput:AddKeyUpHandler(cstick_up, function() if not IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cup2er"]) end end)
	

	--CSTICK DOWN
	local function cdown1(player)
	if player:HasTag("lockcontrols") then return end
		player:AddTag("atk_key_dwn")
		player:PushEvent("cstick_down")
		player:PushEvent("attack_key")
		player.components.stats:SetKeyBuffer("cstick_down")
		-- TheWorld.components.ambientlighting.red = 0.5
		-- TheWorld.components.ambientlighting:CycleRed()   ----00000000000000
	end
	local function cdown2(player)
	if player:HasTag("lockcontrols") then return end
		player:RemoveTag("atk_key_dwn")
		if player.sg:HasStateTag("chargingdsmash") then
			player.sg:GoToState("dsmash")
		end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "cdown1er", cdown1)
	TheInput:AddKeyDownHandler(cstick_down, function() if not IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cdown1er"]) end end)
	
	AddModRPCHandler(TUNING.MODNAME, "cdown2er", cdown2)
	TheInput:AddKeyUpHandler(cstick_down, function() if not IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cdown2er"]) end end)
	
	
	
	--CSTICK LEFT --THESE FUNCTIONS ACTUALLY PUSH EVENTS FOR FORWARD AND BACKWARD INSTEAD OF LEFT AND RIGHT
	local function cleft1(player)
	if player:HasTag("lockcontrols") then return end
		player:AddTag("atk_key_dwn")
		-- player:PushEvent("cstick_side", {key = "left"}) --7-20-17 NOT ANYMORE THEY DONT
		player:PushEvent("cstick_side", {key = "left", key2 = "stick"}) --1-1-18 ADDED "STICK" DATA TO IDENTIFY IF THE INPUT WAS FROM THE CSTICK ITSELF OR THE QUICK-TAP DIR+ATTACK
		player:PushEvent("attack_key")
		player.components.stats:SetKeyBuffer("cstick_side", "left", "stick")
		-- TheWorld.components.ambientlighting:CycleGreen()  -----0000000000000
	end
	local function cleft2(player)
	if player:HasTag("lockcontrols") then return end
		player:RemoveTag("atk_key_dwn")
		if player.sg:HasStateTag("chargingfsmash") then
			player.sg:GoToState("fsmash")
		end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "cleft1er", cleft1)
	TheInput:AddKeyDownHandler(cstick_left, function() if not IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cleft1er"]) end end)
	
	AddModRPCHandler(TUNING.MODNAME, "cleft2er", cleft2)
	TheInput:AddKeyUpHandler(cstick_left, function() if not IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cleft2er"]) end end)
	
	
	--CSTICK RIGHT
	local function cright1(player)
	if player:HasTag("lockcontrols") then return end
		player:AddTag("atk_key_dwn")
		player:PushEvent("cstick_side", {key = "right", key2 = "stick"})
		player:PushEvent("attack_key")
		player.components.stats:SetKeyBuffer("cstick_side", "right", "stick")
	end
	local function cright2(player)
	if player:HasTag("lockcontrols") then return end
	player:RemoveTag("atk_key_dwn")
		if player.sg:HasStateTag("chargingfsmash") then
			player.sg:GoToState("fsmash")
		end
	end
	
	AddModRPCHandler(TUNING.MODNAME, "cright1er", cright1)
	TheInput:AddKeyDownHandler(cstick_right, function() if not IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cright1er"]) end end)
	
	AddModRPCHandler(TUNING.MODNAME, "cright2er", cright2)
	TheInput:AddKeyUpHandler(cstick_right, function() if not IsPaused() then SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["cright2er"]) end end)
	
	]]
	
	
	
	local function special1(player)
	if player:HasTag("lockcontrols") then return end
		-- player:PushEvent("throwspecial")
		-- player:PushEvent("throwspecial", {key = player.components.keydetector:GetBufferKey(player)}) --4-5 ADDING ADDITIONAL DATA FOR KEY BUFFERING
		--11-7-17 REUSEABLE - WAIT!!! WHAT IF I... ADDED MORE DATA? LIKE INITIAL DIRECTION, FOR THROWSPECIAL TO COMPARE TO SEE IF IT'S DIRECTION HAS CHANGED SINCE THE KEY WAS PRESSED
		player:PushEvent("throwspecial", {key = player.components.keydetector:GetBufferKey(player), key2 = player.Transform:GetRotation()}) --11-7-17 INTRODUCING! KEY2! BRILLIANT. SHOULDVE USED THIS FOR ROLLING
			player.components.stats:SetKeyBuffer("throwspecial", player.components.keydetector:GetBufferKey(player), player.Transform:GetRotation())  --GOTTA ADD IT IN THE SETKEYBUFFER TOO!
			--TODOLIST  TEST TO SEE IF EVENT = "TROWATTACK" AND IF BUFFERTICK >= 3 AND IF IT IS, THEN THROW A GRAB EVENT INSTEAD
		player:AddTag("spc_key_dwn")
		
	end
	
	local function special2(player)
	if player:HasTag("lockcontrols") then return end
		player:RemoveTag("spc_key_dwn") 
	end
	
	-- AddModRPCHandler(TUNING.MODNAME, "special1er", special1)
	TheInput:AddKeyDownHandler(special, function() special1(p2_localplayer) end)
	
	-- AddModRPCHandler(TUNING.MODNAME, "special2er", special2)
	TheInput:AddKeyUpHandler(special, function() special2(p2_localplayer) end)
	
	
	--UP
	local function up1(player)
	if player:HasTag("lockcontrols") then return end
	if not player.components.keydetector.holdingup then
		player:PushEvent("up")
		player:AddTag("listen_for_usmash")
		player:DoTaskInTime((2*FRAMES), function()
			player:RemoveTag("listen_for_usmash")
		end)
		
		--6-9-20 OK THERE HAS TO BE A DUPLICATE OF THE JUMP FUNCTION HERE BECAUSE OF TAPJUMP LISTENERS... IM SURE THERE IS A BETTER WAY TO DO THIS BUT I JUST WANT THIS DONE
		if player.components.stats.tapjump and player.components.jumper.currentdoublejumps > 0 then
			-- if not player:HasTag("jump_key_dwn") then --DONT NEED THIS FOR TAPJUMP
				if player.sg:HasStateTag("listen_for_atk") then
					player.components.stats:SetKeyBuffer("jump", player.components.stats.key) --4-24-20 ACTUALLY, KEEP THE KEY BUFFER THE SAME, THE ATTACKS WILL SET THOSE
				else
					player:PushEvent("jump")
					player.components.stats:SetKeyBuffer("jump", "ITSNIL") --4-18-20 REMOVING THE KEYBUFFER CHECK, SINCE WE DONT USE IT HERE  --player.components.keydetector:GetBufferKey(player)
				end
			-- end
			-- player:AddTag("jump_key_dwn")
			--4-23-20 EXTRA BAGGAGE
			player.sg:AddStateTag("listen_for_jump")
			player:DoTaskInTime(0, function() 
				player.sg:RemoveStateTag("listen_for_jump")
			end)
		end
	end
	-- holdingup = true --DST CHANGE-- USING THE ONE BELOW INSTEAD OF THIS ONE
	player.components.keydetector.holdingup = true  --DST CHANGE-- THIS ONE WORKS!!!
	end
	local function up2(player)
	if player:HasTag("lockcontrols") then return end
		player.components.keydetector.holdingup = false
	end
	
	-- AddModRPCHandler(TUNING.MODNAME, "up1er", up1)
	TheInput:AddKeyDownHandler(up, function() up1(p2_localplayer) end)
	
	-- AddModRPCHandler(TUNING.MODNAME, "up2er", up2)
	TheInput:AddKeyUpHandler(up, function() up2(p2_localplayer) end)
	
	
	--DOWN
	local function down1(player)
	if player:HasTag("lockcontrols") then return end
	if not player.components.keydetector.holdingdown then
		player:PushEvent("down")
		if player.sg:HasStateTag("canoos") then
			-- player:DoTaskInTime(0.1, function() --?????WHY WAS IT LIKE THIS??
				-- player.sg:GoToState("spotdodge")
			-- end)
			player.sg:GoToState("spotdodge")
		else
			player:PushEvent("duck")
		end
		player:AddTag("listen_for_dsmash")
		player:DoTaskInTime((2*FRAMES), function()
			player:RemoveTag("listen_for_dsmash")
		end)
	end
	player.components.keydetector.holdingdown = true
	-- TheWorld:PushEvent("ms_playerdespawnanddelete", player) --INTERESTING...
	-- TheWorld:PushEvent("ms_playerdespawn", player)
	-- player:Remove()
	-- player.components.hurtboxes:Unsubscribe()
	-- player.components.hurtboxes:RemoveAllHurtboxes()
	-- player.components.hurtboxes:ResetHurtboxes()
	end
	
	local function down2(player)
	if player:HasTag("lockcontrols") then return end
		if player.sg:HasStateTag("ducking") then
			player.sg:GoToState("idle")
		end
		player.components.keydetector.holdingdown = false
	end
	
	-- AddModRPCHandler(TUNING.MODNAME, "down1er", down1)
	TheInput:AddKeyDownHandler(down, function() down1(p2_localplayer) end)
	
	-- AddModRPCHandler(TUNING.MODNAME, "down2er", down2)
	TheInput:AddKeyUpHandler(down, function() down2(p2_localplayer) end)
	
	
	
	
	
	
	--DST CHANGE-- THIS SEEMS TO BE THE ONLY WAY I KNOW HOW TO FIX THINGS
	-- local canjog = not inst.sg:HasStateTag("busy") then if not inst.sg:HasStateTag("no_running") and not inst.components.launchgravity:GetIsAirborn() then  --11-16
	-- local function IsValidRunner(entity)
		-- return not (entity.sg:HasStateTag("busy") or entity.sg:HasStateTag("no_running") or entity.components.launchgravity:GetIsAirborn())
	-- end
	
	--LEFT
	local function left1(player)
	if player:HasTag("lockcontrols") then return end
	if not player.components.keydetector.holdingleft then
	player.components.keydetector.holdingleft = true --10-14-17 OH OK, THIS NEEDS TO BE UP HERE FOR ROLLS IN DST
	player:PushEvent("left")
	if player.components.launchgravity:GetRotationValue() == 1 then --1-6 FORWARD AND BACKWARD DETECTORS
		player:PushEvent("forward_key")
	else
		player:PushEvent("backward_key")
	end
	if not player.components.launchgravity:GetIsAirborn() then
		player:RemoveTag("listen_for_dashr")
		player:RemoveTag("listen_for_tapr")
		-- if player:HasTag("listen_for_dash") and player:HasTag("listen_for_tap") and not player.sg:HasStateTag("dashing") and not player.sg:HasStateTag("busy") then
		if player:HasTag("listen_for_dash") and player:HasTag("listen_for_tap") and not player.sg:HasStateTag("dashing") then --4-17-20 LETS TRY IGNORING BUSY 
			--player.components.locomotor:DashInDirection(ang, true)
			--player.sg:GoToState("dash")
			-- player:PushEvent("dash") --8-29-20 REMOVING SO THAT THE DASH EVENT ISNT PUSHED TWICE IN A ROW WITH THE BUFFER
			player:AddTag("dashing")
			--4-17-20 TESTING A NEW BUFFERABLE KEYHANDLER THAT LETS YOU BUFFER DASHING! WOW I HAVENT BEEN TO THIS PART OF CODE IN A WHILE.. DONT BREAK ANYTHING PLS
			player.components.stats:SetKeyBuffer("dash", "left") --OH I DONT THINK I USE THE "LEFT/RIGHT" KEY2 VARIABLE ANYWHERE BUT ONE DAY I MIGHT
			--print("I AM SPEED")
		end
		-- if player.components.stats.autodash == true then --9-30-21 REWORKING AUTO DASH FEATURE. REMOVING FROM THE CONTROL SCHEME
			-- player:PushEvent("dash") 
		-- end
		player:AddTag("listen_for_dash")
		player:AddTag("listen_for_smash")
		player:AddTag("listen_for_roll") --7-17-17 EARLY ROLL WINDOW LISTENER
		player:DoTaskInTime(0.5, function() --2-7-17 CHANGING FROM 0.3 TO 0.5
			player:RemoveTag("listen_for_dash")
		end)
		player:DoTaskInTime((2*FRAMES), function()
			player:RemoveTag("listen_for_smash")
			player:RemoveTag("listen_for_roll") --7-17-17
		end)
		if player.sg:HasStateTag("sliding") then  --EVENTUALY DO THIS WITH A KEY CHECKER IN THE STATEGRAPH OR SOMETHING SO IT CAN BE BUFFERED
			-- player.sg:GoToState("idle")
			-- player:PushEvent("dash") --12-14
			-- player:DoTaskInTime(0.1, function()
				-- --player.sg:GoToState("dash")
				-- player:PushEvent("dash")
			-- end)
		end
		-- 7-17-17 LETS BUFFER SOME DODGES
		if player.components.keydetector:GetBlock(player) then
			player:PushEvent("roll", {key = player.components.keydetector:GetLeftRight(player)})
			player.components.stats:SetKeyBuffer("roll", player.components.keydetector:GetLeftRight(player))
		end
	end
	end
	end
	local function left2(player)
	if player:HasTag("lockcontrols") then return end
		if player.sg:HasStateTag("dashing") then
			--player.sg:GoToState("dash_stop")
			player:PushEvent("dash_stop")
		else
			player:AddTag("listen_for_tap")
			player:DoTaskInTime((4*FRAMES), function()
				-- player:RemoveTag("listen_for_dash")
				player:RemoveTag("listen_for_tap")
			end)
		end
		player:RemoveTag("wasrunning")
		player.components.keydetector.holdingleft = false
	end
	
	-- AddModRPCHandler(TUNING.MODNAME, "left1er", left1)
	TheInput:AddKeyDownHandler(left, function() left1(p2_localplayer) end)
	
	-- AddModRPCHandler(TUNING.MODNAME, "left2er", left2)
	TheInput:AddKeyUpHandler(left, function() left2(p2_localplayer) end)


	local function right1(player)
	if player:HasTag("lockcontrols") then return end
	if not player.components.keydetector.holdingright then
	player.components.keydetector.holdingright = true
	player:PushEvent("right")
	if player.components.launchgravity:GetRotationValue() == -1 then
		player:PushEvent("forward_key")
	else
		player:PushEvent("backward_key")
	end
	if not player.components.launchgravity:GetIsAirborn() then
		player:RemoveTag("listen_for_dash")
		player:RemoveTag("listen_for_tap")
		if player:HasTag("listen_for_dashr") and player:HasTag("listen_for_tapr") and not player.sg:HasStateTag("dashing") then
			--player.sg:GoToState("dash")
			-- player:PushEvent("dash") --8-29-20 REMOVING SO THAT THE DASH EVENT ISNT PUSHED TWICE IN A ROW WITH THE BUFFER
			player:AddTag("dashing")
			player.components.stats:SetKeyBuffer("dash", "right") --4-17-20 TESTING A NEW BUFFERABLE KEYHANDLER THAT LETS YOU BUFFER DASHING
		end
		-- if player.components.stats.autodash == true then --11-9-17 TESTING AUTO-DASH
			-- player:PushEvent("dash") 
		-- end
		player:AddTag("listen_for_dashr")
		player:AddTag("listen_for_smash")
		player:AddTag("listen_for_roll") --7-17-17 EARLY ROLL WINDOW LISTENER
		player:DoTaskInTime(0.5, function() 
			player:RemoveTag("listen_for_dashr")
		end)
		player:DoTaskInTime((2*FRAMES), function()
			player:RemoveTag("listen_for_smash")
			player:RemoveTag("listen_for_roll") --7-17-17
		end)
		if player.sg:HasStateTag("sliding") then  --EVENTUALY DO THIS WITH A KEY CHECKER IN THE STATEGRAPH OR SOMETHING SO IT CAN BE BUFFERED
			-- player.sg:GoToState("idle")
			-- player:PushEvent("dash") --12-14
			-- player:DoTaskInTime(0.1, function()
				-- --player.sg:GoToState("dash")
				-- player:PushEvent("dash")
			-- end)
		end
		-- 7-17-17 LETS BUFFER SOME DODGES
		if player.components.keydetector:GetBlock(player) then
			player:PushEvent("roll", {key = player.components.keydetector:GetLeftRight(player)})
			player.components.stats:SetKeyBuffer("roll", player.components.keydetector:GetLeftRight(player))
		end
	end
	end
	end
	local function right2(player)
	if player:HasTag("lockcontrols") then return end
		if player.sg:HasStateTag("dashing") then
			-- player.sg:GoToState("dash_stop")
			player:PushEvent("dash_stop")
		else
			player:AddTag("listen_for_tapr")
			player:DoTaskInTime((4*FRAMES), function()
				-- player:RemoveTag("listen_for_dashr")
				player:RemoveTag("listen_for_tapr")
			end)
		end
		player:RemoveTag("wasrunning")
		player.components.keydetector.holdingright = false
		
	end
	
	-- AddModRPCHandler(TUNING.MODNAME, "right1er", right1)
	TheInput:AddKeyDownHandler(right, function() right1(p2_localplayer) end)
	
	-- AddModRPCHandler(TUNING.MODNAME, "right2er", right2)
	TheInput:AddKeyUpHandler(right, function() right2(p2_localplayer) end)
	
end)

end


function GameRules:SpawnLocalP2(dude) --HANDED TO US FROM THE CHARACTER SELECT SCREEN
	p2local_applykeyhandlers(dude)
end



return GameRules
