local SpiderSpawner = Class(function(self, inst)
    self.inst = inst

	self.maxkids = 3
	
	self.kids = {}
	
	self.readyfornewkids = true
	
	self.autobirth = false --FOR EGGSACKS, BECAUSE THE HAVEKID COMMAND WONT CALL ITSELF

	-- self.inst:DoPeriodicTask(20, function()
		-- if self:GetNumberOfKids() < self.maxkids then
			-- self.readyfornewkids = true
		-- end
	-- end)
	
	self.newkidtimer = 0
	self.babytype = "baby" --TYPE OF SPIDERS TO SPAWN
	self.respawnrate = 12
	

end)



function SpiderSpawner:InitiateSpawner(counter) 

	self.newkidtimer = counter
	self.inst:StartUpdatingComponent(self)

end


function SpiderSpawner:InsertIntoKidTable(player) 

	table.insert(self.kids, player)

end

function SpiderSpawner:GetNumberOfKids() 
	local num = 0 
	
	-- for k,v in pairs(self.kids) do
		-- num = num + 1
	-- end
	--ACTUALLY, LETS TAKE THE NUMBER OF KIDS ON SCREEN TOTAL. WE DONT WANT MULTIPLE SOURCES OVERRUNING THE PLAYER
	local ents = TheSim:FindEntities(0, 0, 0, 200, {"babyspider"}) --NOT TO BE CONFUSED WITH THE ACTUAL LVL1 "BABY SPIDER"
	num = #ents
	
	return num
end

function SpiderSpawner:RemoveKid(player)   
	local player = player 
	
	for k,v in pairs(self.kids) do
		if v == player then
			self.kids[k] = nil
		end
	end
end



function SpiderSpawner:WantsToHaveKids()
	-- print("AM I READY FOR KIDS?", self:GetNumberOfKids(), self.readyfornewkids)
	if self:GetNumberOfKids() <= self.maxkids and self.readyfornewkids then
		return true
	end
		
	return false
	--MKE A TIMER THAT DETERMINES WHEN TO CHECK HOW MANY KIDS ARE ON THE FIELD
end



--EGGSACK SPECIFIC, I BELEIVE
function SpiderSpawner:HaveKids()
	
	if self:WantsToHaveKids() == false then
		self.newkidtimer = self.respawnrate/2
		return end
	
	self.inst:PushEvent("throwattack", {key = "dspecial"})
	self.inst:PushEvent("make_child", {key = "dspecial"})
	--7-3-20 THESE WONT BE NEEDED SINCE ONLY THE EGGSACKS CALL THIS FUNCTION NOW
	
	self.readyfornewkids = false
	-- self.newkidtimer = math.random(10, 15)
	-- self.newkidtimer = 15 --NAH LETS MAKE IT EVEN  --ACTUALLY LETS JUST SET IT FROM THE STATEGRAPH
	-- self.newkidtimer = self.respawnrate + math.random(-2,2) --DESYNC THE DEN SPAWN RATES A BIT
	
	--10-19-20 ALRIGHT, ALRIGHT... THINGS GET A LITTLE TOO CRAZY WITH 4+ SPIDERS ON STAGE. LETS TONE IT DOWN...
	--OH WIAT! IT WAS JUST BECAUSE SPIDER DENS DIDNT PROPERLY MARK THEIR CHILDREN TO COUNT TOWARD THE MAX
	local respawndamper = -6 --ESSENTIALLY, NEGATIVE 2 SPIDERS (ONLY FROM NESTS! INITIAL SPAWNS DONT COUNT)
	--AFTER OUR 3RD SPIDER, LETS START SLOWING DOWN RESPAWN TIMES
	respawndamper = math.clamp(respawndamper + ((self:GetNumberOfKids()+1) * 3), 0, 20)
	-- print("SPAWNING A KID! HERES DAMPER INFO:", (self:GetNumberOfKids()+1), respawndamper, math.random(-2,2))
	
	self.newkidtimer = self.respawnrate + respawndamper + math.random(-2,2) --DESYNC THE DEN SPAWN RATES A BIT
	
end


function SpiderSpawner:SpawnBaby(mother)
	
	--EGGSACKS RUN A VERSION OF THIS CODE WITHIN THEIR OWN STATEGRAPH
	local baby = nil --TO BE DETERMINED
	if self.babytype == "baby" then
		baby = SpawnPrefab("spiderfighter_baby")
	elseif self.babytype == "easy" then
		baby = SpawnPrefab("spiderfighter_easy")
	elseif self.babytype == "medium" then
		baby = SpawnPrefab("spiderfighter_medium")
	end
	
	local x, y, z = mother.Transform:GetWorldPosition()
	
	baby:AddTag("dummynpc") --9-14-17 DST TO DETIRMINE IF THE CHARACTER IS A LITERAL CHARACTER NOT CONTROLLED BY A USER
	baby:AddTag("customspawn")
	baby:AddTag("babyspider") --NOT TO BE CONFUSED WITH THE ACTUAL LVL1 "BABY SPIDER" BUILD
	--THIS TAG JUST SIGNIFIES THAT IT WAS BORN FROM A SPAWNER, AND SPAWNERS ONLY COUNT SPIDERS FROM SPAWNERS
	
	baby.components.percent.hpmode = true
	baby.components.percent.maxhp = 25
	baby:AddTag("nohud") --6-10-18 --THERE WOULD BE TOO MANY ON SCREEN!!!
	
	baby.components.stats.team = "spiderclan" --SET THEIR STATS TO RESPECTIVE HORDE MODE STATS
	baby.components.stats.lives = 1
	
	TheSim:FindFirstEntityWithTag("anchor").components.gamerules:SpawnPlayer(
		baby, 
		(x-(1*mother.components.launchgravity:GetRotationValue()))+math.random(-1.0,1.0), 
		y, 
		z, 
	true) 
	
	self:InsertIntoKidTable(baby)
	baby:ListenForEvent("onko", function() 
		-- self:RemoveKid(baby) --7-1-20 WE'RE USING SOMETHING ELSE NOW
	end)

end





function SpiderSpawner:OnUpdate(dt)
	if self.newkidtimer > 0 then
		self.newkidtimer = self.newkidtimer - (1/30)
	else
		self.readyfornewkids = true
		if self.autobirth then
			self:HaveKids()
		end
	end
end



return SpiderSpawner
