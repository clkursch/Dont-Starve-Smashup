local Hordes = Class(function(self, inst)
    self.inst = inst

	self.wavenumber = 1
	
	self.waveslots = {}
	self.currentwave = nil
	
	self.level = 1 --8-15-20 SPLITTING THE WAVES UP INTO SEPERATE "LEVELS" (DEN TIERS)
	-- self.unlockteir = 1 --BY DEFAULT, THEY ONLY HAVE THE FIRST DEN UNLOCKED
	--OH AND I GUESS THIS IS NORMAL FOR DEDICATED SERVERS TOO
	--WAIT NO SOMETHINGS NOT RIGHT HERE... I THINK WE NEED TO MESS WITH PRISTINE OR SOMETHING FIRST... ALRIGHT JUST COME BACK TO IT
	--I GET IT NOW. I MOVED THIS ALL INTO THE ANCHOR PREFAB. CANT DO IT IN A COMPONENT BECAUSE ITS NOT ON CLIENT
	
	--11-29-18 GUESS WE CAN ALSO STORE OUR SINGLEPLAYER SPARRING PARNER HERE
	-- self.sparring_cpu = nil --DONT FORGET TO SET IT BACK TO NIL WHEN YOURE DONE
	self.sparring_cpus = {} --8-21-20 STEPPING THINGS UP A NOTCH. NOW ITS A TABLE CONTAINING ALL CPUS
	-- ^^^ THIS IS STILL ONLY FOR USE IN THE VS-CPU MODE. NOT MEANT FOR HORDE MODE
	
	--WE WANT A LEVEL PREPARED IN CASE FORCEHORDEMODE IS ENABLED, IN WHICH CASE WE WOULDNT SELECT FROM THE MENU
	self:SetupTier1()
end)






--11-29-18 --USED FOR PLAYING VS MODE WITH NON-PLAYER PREFABES
function Hordes:SpawnLocalBaddie(prefab, team) --(AKA: NOT FOR HORDE MODE. THIS IS FOR SINGLEPLAYER AI MATCHES WITH HAROLD)
	local Pawn = SpawnPrefab(tostring(prefab))
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local x, y, z = anchor.Transform:GetWorldPosition()
	self.inst.components.gamerules:SpawnPlayer(Pawn, x + #self.sparring_cpus,y,z) --8-21-20 ADDING NUMBER OF CPUS TO THE X VALUE
	
	if team then --1-19-22 PASS IN AN OPTIONAL TEAM
		Pawn.components.stats.team = team
	end
	
	-- self.sparring_cpu = Pawn --HOWEVER, THIS METHOD MEANS WE CAN ONLY HAVE ONE AT ONCE
	table.insert(self.sparring_cpus, Pawn) --8-21-20 NOT ANYMORE!!
	return Pawn --1-20-22 LOOK, CAN WE KEEP HIM?
end


function Hordes:PrepareHordeMode(level)

	print("--PREPARING HORDE MODE!: ", level)
	-- self.inst.components.gamerules.hordemode = true
	--NO NOT YET!! WE WANT THIS VALUE TO !!ONLY!! REPRESENT REAL PLAYTIME IN THIS MODE. ONLY SET ONCE A GAME STARTS
	
	
	--8-19-20 ASSUMING LEVEL IS PASSED IN, SET UP THE LEVEL
	if level then
		self.level = level
	end
	
	
	self.waveslots = {} --CLEAR PREVIOUS LEVEL DATA
	self.wavenumber = 1
	--FIRST CHECK WHAT LEVEL WE WILL BE PLAYING
	
	if self.level == 1 then
		self:SetupTier1()
	elseif self.level == 2 then
		self:SetupTier2()
	elseif self.level == 3 then
		self:SetupTier3()
		
	else --FAILSAFE
		self:SetupTier1()
	end
	-- print("STARTING THE HORDE!", self.wavenumber, #self.waveslots)
	
	--BEGIN THE GAME
	-- self.inst.components.gamerules:StageReset() --NO NOT YET!! PLAYERS CAN DECIDE WHEN THAT HAPPENS
	if self.inst.components.gamerules.matchstate == "endgame" and self.inst.components.gamerules.hordemode then
		--THIS IS A SPECIAL CASE SCENARIO WHERE USERS HAVE BEATEN A LEVEL AND ARE WAITING TO PICK THE NEXT ONE.
		self.inst.components.gamerules:StageReset()
	end
end


--6-10-18 COMPLETE HORDE MODE
function Hordes:CompleteHordeMode()
	-- self.inst.components.gamerules:GameSet() --MAYBE NOT YET...
	self.inst.components.gamerules:ChangeMatchState("endgame") --JUST SO IT ISNT "RUNNING" 
	self:ResetHordeMode()
	-- TheNet:Announce("HORDE COMPLETE! ")
	local bonusunlock = false
	
	--8-19-20 UNLOCK THE NEXT TIER!! ASSUMING IT ISNT ALREADY
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local unlocktier = anchor._unlockteir:value()
	if self.level == 1 and unlocktier == 1 then
		anchor._unlockteir:set(2)
	elseif self.level == 2 and unlocktier == 2 then
		anchor._unlockteir:set(3)
		--11-27-20 THIS IS ALSO WHERE THEY UNLOCK THE NEW FIGHTER
		for i, v in ipairs(AllPlayers) do
			v.jumbotronheader:set(STRINGS.SMSH.JUMBO_NEW_UNLOCK) --"New Fighter Unlocked!"
		end
	elseif self.level == 3 and unlocktier == 3 then
		anchor._unlockteir:set(4) --THERE ISNT A 4TH TIER BUT THIS IS SO THEY DONT "UNLOCK" 3RD TIER OVER AND OVER AGAIN
	end
	
	for i, v in ipairs(AllPlayers) do
		v.jumbotronmessage:set(STRINGS.SMSH.JUMBO_HORDE_WIN) --"HORDE COMPLETE!"
	end
	
	--8-15-20 SEPERATING THESE OUT
	self.inst:DoTaskInTime(2, function()
		-- self:EndHordeMode()
		for i, v in ipairs(AllPlayers) do
			v.postgamenetvar:set("ted") --POPS UP THAT SCREEN
		end
	end)
end




function Hordes:FailedHordeMode()

	self.inst.components.gamerules.hordemode = true
	-- TheNet:Announce("HORDE MODE FAILED! " ..  tostring(self.wavenumber))
	for i, v in ipairs(AllPlayers) do
		v.jumbotronmessage:set(STRINGS.SMSH.JUMBO_HORDE_FAIL) --"FAILED..."
	end
	
	self.wavenumber = self.wavenumber - 1 --SET THEM BACK TO THE WAVE THEY WERE STUCK ON
	if self.wavenumber < 1 then --THIS SHOULd NEVER BE LESS THAN 1. CLAMP IT
		self.wavenumber = 1
	end
	
	--ON SECOND THOUGHT, LETS JUST MAKE THEM ALL RESTART WHEN THEY FAIL. EASIER THAT WAY. UNTIL THEY CAN COMPLETE THE DEN
	self.inst:DoTaskInTime(1, function()
		self:RetryHordeMode()
	end)
end



function Hordes:EndHordeMode()
	self.inst.components.gamerules.hordemode = false
	self.inst.components.gamerules:StageReset() 
	--6-17-18 OR SHOULD WE MAKE IT SET IT TO LOBBY?... SINCE IF IT WAS HORDEMODE WITH ONLY ONE PLAYER, IT WILL SEND THEM INTO A PVP MATCH BY THEMSELVES.
	self.inst.components.gamerules:ChangeMatchState("lobby")
end

function Hordes:RetryHordeMode()
	self.inst.components.gamerules.hordemode = true
	--6-10-18 --SHUFFLE UP THAT PLAY QUE LIKE WE DO IN NORMAL MODE
	self.inst.components.gamerules.matchstate = "endgame"
	self.inst.components.gamerules:StageReset() 
end



--8-15-20 LESS STUPID SETUP THAT SETS INDIVIDUAL WAVES FOR EACH DEN TIER (LEVEL)
function Hordes:SetupTier1()
	
	local wavedata = {
		{name="spiderfighter_sleepy_easy", posx=3, perc=35, mode="hp"},
	}
	--WAIT NO IM JUST THINKING ABOUT THIS TOO HARD. ALL I NEED TO DO IS INSERT WAVEDATA AS A WHOLE INTO WAVESLOTS AND THATS IT
	table.insert(self.waveslots, wavedata) --OK THAT MAKES SENSE
	
	--FOR TESTING SPIDER QUEEN EARLY
	-- local wavedata = {
		-- {name="spiderfighter_queen", posx=-8, perc=235, mode="hp"},
	-- }
	-- table.insert(self.waveslots, wavedata)
	
	
	local wavedata = {
		{name="spiderfighter_easy", posx=8.5, perc=30, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	local wavedata = {
		{name="spiderfighter_easy", posx=-6, perc=30, mode="hp"},
		{name="spiderfighter_easy", posx=6, perc=30, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	local wavedata = {
		{name="spiderfighter_baby", posx=5, perc=18, mode="hp"},
		{name="spiderfighter_baby", posx=6.2, perc=18, mode="hp"},
		{name="spiderfighter_baby", posx=7, perc=18, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	local wavedata = {
		{name="spiderfighter_easy", posx=3, perc=30, mode="hp"},
		{name="spiderfightereggsack_tier0", posx=5, perc=80, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	
	local wavedata = {
		{name="spiderfighter_baby", posx=-5, perc=18, mode="hp"},
		{name="spiderfighter_baby", posx=-6.2, perc=18, mode="hp"},
		{name="spiderfighter_baby", posx=-7, perc=18, mode="hp"},
		{name="spiderfighter_baby", posx=-7.5, perc=18, mode="hp"},
		{name="spiderfighter_baby", posx=-8, perc=18, mode="hp"},
		{name="spiderfighter_baby", posx=-8.8, perc=18, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	

	local wavedata = {
		{name="spiderfighter_sleepy_medium", posx=4.1, perc=60, mode="hp"},
		{name="spiderfightereggsack", posx=5, perc=50, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	-- print("WAVENUMBER", self.waveslots[self.wavenumber], self.wavenumber)
	
end


function Hordes:SetupTier2()

	
	local wavedata = {
		{name="spiderfighter_medium", posx=1.1, perc=60, mode="hp"},
		{name="spiderfightereggsack", posx=2, perc=50, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	
	local wavedata = {
		{name="spiderfighter_medium", posx=11, perc=60, mode="hp"},
		{name="spiderfighter_easy", posx=7.5, perc=30, mode="hp"},
		{name="spiderfighter_easy", posx=8.5, perc=30, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	
	local wavedata = {
		{name="spiderfighter_easy", posx=-7, perc=30, mode="hp"},
		{name="spiderfighter_easy", posx=-9, perc=30, mode="hp"},
		{name="spiderfightereggsack_tier2", posx=-8, perc=120, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	local wavedata = {
		{name="spiderfightereggsack", posx=-8, perc=50, mode="hp"},
		{name="spiderfightereggsack", posx=8, perc=50, mode="hp"},
		{name="spiderfightereggsack_tier2", posx=0, perc=100, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	local wavedata = {
		{name="spiderfighter", posx=5},
	}
	table.insert(self.waveslots, wavedata)
	
	
	local wavedata = {
		{name="spiderfighter_queen", posx=-8, perc=350, mode="hp"}, --235
	}
	table.insert(self.waveslots, wavedata)
end




function Hordes:SetupTier3()
	
	
	local wavedata = {
		{name="spiderfighter_easy", posx=-6, perc=30, mode="hp"},
		{name="spiderfighter_easy", posx=-10, perc=30, mode="hp"},
		{name="spiderfightereggsack_tier3", posx=-8, perc=120, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	local wavedata = {
		{name="spiderfighter_sleepy_medium", posx=5.5, perc=60, mode="hp"},
		{name="spiderfighter_medium", posx=4.1, perc=60, mode="hp"},
		{name="spiderfightereggsack_tier2", posx=4.5, perc=80, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	--TWO BABY-SPAWNER DENS AND A SLEEPING WARRIOR GAURD.
	local wavedata = {
		{name="spiderfighter_baby", posx=5.4, perc=18, mode="hp"},
		{name="spiderfighter_baby", posx=6.2, perc=18, mode="hp"},
		{name="spiderfighter_baby", posx=6.8, perc=18, mode="hp"},
		{name="spiderfightereggsack_tier0", posx=5, perc=60, mode="hp"},
		{name="spiderfighter_sleepy_medium", posx=6.1, perc=60, mode="hp"},
		{name="spiderfightereggsack_tier0", posx=7, perc=60, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	--THIS IS PROBABLY THE MOST FIGHTERS THAT WILL EVER BE ON STAGE AT THE SAME TIME. LETS SEE HOW THIS GOES
	local wavedata = {
		{name="spiderfighter_baby", posx=-5.5, perc=25, mode="hp"}, --WOW EVEN THESE ARE TOO EASY. OK THEN, LETS RAISE THE HEALTH A BIT?
		{name="spiderfighter_baby", posx=-6.2, perc=25, mode="hp"},
		{name="spiderfighter_baby", posx=-7, perc=25, mode="hp"},
		{name="spiderfighter_baby", posx=-7.3, perc=25, mode="hp"},
		{name="spiderfighter_baby", posx=-7.5, perc=25, mode="hp"},
		
		{name="spiderfighter_baby", posx=5.5, perc=25, mode="hp"},
		{name="spiderfighter_baby", posx=6.2, perc=25, mode="hp"},
		{name="spiderfighter_baby", posx=6.8, perc=25, mode="hp"},
		{name="spiderfighter_baby", posx=7.1, perc=25, mode="hp"},
		{name="spiderfighter_baby", posx=7.5, perc=25, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	--GIVING THESE GUYS LESS HEALTH BC THEY CRAZY
	local wavedata = {
		{name="spiderfighter_medium", posx=5.5, perc=40, mode="hp"},
		{name="spiderfighter_medium", posx=4.1, perc=40, mode="hp"},
		{name="spiderfighter_medium", posx=6.1, perc=40, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
	
	
	
	local wavedata = {
		{name="spiderfighter_queen", posx=6, perc=150, mode="hp"},
		{name="spiderfighter_queen", posx=-6, perc=150, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
end



--TEMP FOR TESTING
--[[
function Hordes:SetupTier1()
	local wavedata = {
		{name="spiderfighter_sleepy_easy", posx=3, perc=5, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
end

function Hordes:SetupTier2()
	local wavedata = {
		{name="spiderfighter_medium", posx=3, perc=5, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
end

function Hordes:SetupTier3() --TEMP
	local wavedata = {
		{name="spiderfighter_queen", posx=-8, perc=300, mode="hp"},
	}
	table.insert(self.waveslots, wavedata)
end
]]


function Hordes:NextWave()
	
	local x, y, z = self.inst.Transform:GetWorldPosition()
	-- z = 0 --OH, I GUESS IT REALLY IS AT 0
	
	self.currentwave = self.waveslots[self.wavenumber]
	
	if (self.wavenumber) == (#self.waveslots + 1) then --8-15-20 A LESS STUPID VERSION THAT DOESNT RELY ON SELF.WAVES COUNTER
		self:CompleteHordeMode() --6-10-18 --AN CLEANER SOLUTION
		return 
	else
		self.inst:DoTaskInTime(0.5, function()
			for i, v in ipairs(AllPlayers) do
				v.jumbotronheader:set(STRINGS.SMSH.JUMBO_WAVE .. tostring(self.wavenumber)) --"WAVE "
			end
			
		end)
		
		-- 7-3-20 LETS GIVE THEM SOME HEALTH BACK TOO 
		if self.wavenumber > 1 then --BUT NOT WHEN THE GAME STARTS!
			local rogue = TheSim:FindFirstEntityWithTag("roguehitboxspawner") --SAME ENTITY THAT SPAWNS GRUE DAMAGE
			rogue.components.hitbox:FinishMove()
			-- print("HAVE A HAM")
			rogue.components.hitbox:SetDamage(-100) 
			rogue.components.hitbox:SetAngle(65)
			rogue.components.hitbox:SetBaseKnockback(0)
			rogue.components.hitbox:SetGrowth(0)
			rogue.components.hitbox:SetSize(0.5)
			rogue.components.hitbox:SetLingerFrames(300)
			rogue.components.hitbox:SetProperty(-6)
			rogue.components.hitbox:SetHitFX("none", "dontstarve/HUD/health_up")
			
			rogue.components.hitbox:SetProjectileDuration(300)
			-- rogue.components.hitbox:SetProjectileSpeed(0, -6)
			-- rogue.components.hitbox:SetProjectileAnimation("pickaxe", "pickaxe", "idle")
			-- rogue.components.hitbox:SetProjectileAnimation("meat", "meat", "raw")
			rogue.components.hitbox:SetProjectileAnimation("cook_pot_food", "cook_pot_food", "idle")
			
			
			local projectile = SpawnPrefab("basicprojectile")
			projectile.Transform:SetScale(1.0, 1.0, 1.0)
			projectile.components.projectilestats:BePhysicsBased()
			projectile.AnimState:OverrideSymbol("swap_food", "cook_pot_food", "honeyham")
			projectile.components.hitbox:MakeDisjointed()
			rogue.components.hitbox:SpawnProjectile(0, 3, 0.5, projectile) --Z AXIS IS A BIT OFF, HAD TO MANUALLY ADJUST IT
			--1-8-22 DON'T CLANK OR SCORE THE HAM PLZ
			projectile.sg:AddStateTag("force_trade")
			projectile.sg:AddStateTag("noclanking")
			projectile:ListenForEvent("overpowered", function()
				projectile.components.hitbox:AddNewHit()
			end)
			
			--OR JUST FORCEABLY ADD HEALTH TO EACH PLAYER. BUT THATS LESS FUN
			-- for i, v in ipairs(AllPlayers) do
				-- if v.components.percent then
					-- v.components.percent:DoDamage(150)
				-- end
			-- end
			
			--2-2-22 ALRIGHT FINE, RESPAWN DEAD PLAYERS BETWEEN ROUNDS.
			for i, v in ipairs(AllPlayers) do
				if v.components.stats.lives == 0 and not v:HasTag("spectator") then
					v.components.stats.lives = 1
					v.customhpbadgelives:set(1)
					self.inst.components.gamerules:RespawnPlayer(v, 1)
					v.sg:GoToState("respawn_platform")
				end
			end
		end
		
		
	end
	
	
	self.inst:DoTaskInTime(2, function()
		--11-4-20 COUNT PLAYERS TO BUFF SPIDER HEALTH
		local playercount = #self.inst.components.gamerules.livingplayers
		
		for k,v in pairs(self.currentwave) do
			local Pawn = SpawnPrefab(v.name) --OH WOW! THATS NIFTY. LUA TABLES REALLY ARE FLEXIBLE
			
			--6-9-18 DST CHANGE - THESE GUYS NEED SPECIAL TAGS TO LET THE GAME KNOW THEY ARE NPCs
			Pawn:AddTag("dummynpc") --9-14-17 DST TO DETIRMINE IF THE CHARACTER IS A LITERAL CHARACTER NOT CONTROLLED BY A USER
			Pawn:AddTag("customspawn")
			
			if v.mode == "hp" then
				Pawn.components.percent.hpmode = true
				Pawn.components.percent.maxhp = v.perc * (1+ (0.5 * (playercount-1))) --11-4-20 BUFF HEALTH FOR MULTIPLE PLAYERS
				Pawn:AddTag("nohud") --6-10-18 --THERE WOULD BE TOO MANY ON SCREEN!!!
			else
				Pawn.components.percent.currentpercent = (v.perc or 0)
			end
			
			Pawn.components.stats.team = "spiderclan" --SET THEIR STATS TO RESPECTIVE HORDE MODE STATS
			Pawn.components.stats.lives = 1
			local zoffset = 0
			if Pawn:HasTag("spiderden") then
				zoffset = -0.4 --10-17-20 ADDING ZOFFSET TO DENS SO THEY DONT OVERLAP AND HIDE THE SPIDERS
			end
			
			self.inst.components.gamerules:SpawnPlayer(Pawn, x+(v.posx), y, z+zoffset, true) --DST CHANGE -- ITS NOT 5 ANYMORE
		end
		
		self.wavenumber = self.wavenumber + 1
	end)
	
end




function Hordes:ResetHordeMode()
	self.wavenumber = 1
	--I GUESS THATS IT NOW
end




return Hordes
