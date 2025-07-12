


local Stats = Class(function(self, inst)
    self.inst = inst

	--------------------------------
	self.opponent = nil
	self.playernumber = nil
	self.master = nil --1-11 USED TO DETERMINE WETHER A SEPERATE ENTITY BELONGS TO AN INDIVIDUAL PLAYER (LIKE PROJECTILES)
	self.slave = nil
	self.team = nil --CHECKS FOR ENTITIES ON THE SAME TEAM TO AVOID HITTING THEM --as soon as i set it up to do that
	
	self.hitscorepartner = nil --SPECIAL CASE (FOR MAXWELLCLONES) FOR PARTNER ENTITIES THAT SHOULDNT BOTH BE ABLE TO HIT AN OPPONENT AT THE SAME TIME
	
	self.myhitstun = 0 --UNUSED    --THEN WHY IS IT STILL HERE?! >:(  COME ON PICKLE CLEAN UP THIS MESS
	
	self.jumpheight = 18 --20  --3-25-19 LETS TEST SOME SLIGHTLY LOWERED JUMP HEIGHTS
	self.doublejumpheight = 20
	self.shorthopheight = 12
	self.numberofdoublejumps = 1
	
	self.friction = 0.9
	
	self.height = 2
	
	self.weight = 100
	self.gravity = 0.87 --1
	self.basegravity = 0.87
	--!! NO WAIT... GRAVITY ISNT THE RATE OF FALLING, ITS THE TIME IT TAKES TO GO FROM 0 TO MAX FALLSPEED..
	self.fallingspeed = 1.5
	self.basefallingspeed = self.fallingspeed
	self.fastfallingspeedincrease = 0.4  --0.6 --3-25-19 THIS NUMBER SEEMS... HIGHER THAN IT SHOULD BE... LOWERING IT A BIT
	
	self.air_speed = 1.15 * 5 
	self.air_accel = 0.07 * 5 * 2 
	self.baseairaccel = self.air_accel
	self.air_friction = 0.016 
	
	self.dashspeed = 6
	
	self.sizemultiplier = 1 --USED IN SCENARIOS WHERE CHARACTERS TEMPORARILY CHANGE SIZE (AND NEED TO CHANGE BACK)
	
	self.storagevar1 = 0 --9-2
	self.storagevar2 = 0
	self.storagevar3 = 0
	self.storagevar4 = 0
	self.storagevar5 = 0
	
	--9-7
	self.storagereference1 = nil
	self.storagereference2 = nil
	self.storagereference3 = nil
	
	--4-5 FOR KEY BUFFER
	self.event = nil
	self.eventalt = nil --FOR BUFFERED JUMP ATTACKS
	self.key = nil
	self.key2 = nil --11-7-17 REUSEABLE- AN ADDITIONAL DATA POINT (INITIALLY USED FOR FSPECIAL DIRECTIONS)
	self.buffertick = 0
	
	
	--FOR MANUAL OVERIDES
	self.jumpspec = nil
	
	-- 7-10 FOR CPU TO KEEP TRACK OF TARGET VIA NEWSTATE EVENT IN MODMAIN... ITS COMPLICATED OKAY?
	self.lasttarget = nil
	self.norecovery = false
	
	-- 10-27-16
	-- self.lives = 2 --999
	self.lives = TUNING.SMASHUP.MATCHLIVES --MAYBE ANOTHER TIME
	
	self.lastfx = nil --BASCIALLY YOU NEED TO USE THIS REFERENCE IMMEDIATELY OR ELSE IT COULD GO STALE... THIS IS A BAD IDEA
	
	self.alive = true --DST CHANGE- ALLOWS PLAYERS TO EXIST PAST THE BLAST ZONE WITHOUT DYING MORE THAN ONCE
	self.hudref = nil --DST-- FINE, IF THATS HOW YOU WANT TO BE
	
	self.tapjump = false --DST-- THIS CAN BE USED IN REGULAR ONE TOO. WITH SOME CHANGES -REUSEABLE
	self.autodash = false --11-9-17 REUSEABLE
	self.tapsmash = false --11-29-21
	self.tiltstick = "smash"
	
	
	--11-3-16 AN ATTEMPT TO MAKE A WAY FOR CHARACTER SELECT SCREEN TO PULL ANIM FILES FROM CHARACTERS
	self.bankname = "blank"
	self.buildname = "blank"
	--8-31-20 WOW THAT WAS FROM 4 YEARS AGO?? ANYWAYS. HERES MY CHANCE TO REDEEM THIS HORRIBLE SKIN SYSTEM
	self.altskins = {"blank"} --1-2-18 
	self.skinnum = 1 --FOR THE RESKIN CALCULATOR IN GAMERULES
	
	self.facepath = "minimap/minimap_data.xml"
	self.facefile = "wilson.png"
	
	self.displayname = nil --11-27-20 A MANUAL OVERRIDE FOR NON-PLAYERS THAT MUST TAKE PLACE BEFORE HUD INITIALIZES
	
	self.spawninvuln = false
	-- self.stategraphname = "SGnewwilson" --9-24-17 -FOR PLAYERCOMMON TO PULL FROM  --10-20-21 WHERE??? WHERE DO WE USE THIS? NOWHERE, GET RID OF IT
	
	--GIVE US A SEC TO SET THESE
	self.inst:DoTaskInTime(0.5, function()
		self.basegravity = self.gravity 
		self.basefallingspeed = self.fallingspeed
	end)
end)



--7-8-17 CHECKS IF THE GAME IS DST OR NOT
function Stats:DSTCheck()
	--7-29-17 WAIT A MINUTE...... WOW I'M DUMB. I DON'T NEED ANY OF THAT PORTAL DETECTING STUFF. ALL I NEEDED WAS THIS
	return true --BECAUSE THIS IS DST
end


--1-23-21 WE'RE ABOUT TO START USING IT NOW. WITH SOME TWEAKS TO AVOID STALE COMPONENT REFERENCES  --DO I EVEN USE THIS ANYMORE???
function Stats:GetOpponent(auto_rebound)  --1-23-21 ADDED "VALIDATION CHECK" TO AUTOMATICALLY FIX 
	if self.opponent and self.opponent:IsValid() then
		return self.opponent
	else
		if auto_rebound then --WE CAN ASSUME PLAYER CHARACTERS SHOULD BE ABLE TO JUMP INTO THE REBOUND STATE AT ANY POINT
			self.inst.sg:GoToState("rebound", 10)
		end
		return nil
	end
end

function Stats:SetGaurdEndurance()
	self.maxfuel = 7.5
    self.currentfuel = 7.5
end

function Stats:ResetFriction()
	self.inst.Physics:SetFriction(self.friction)
end

function Stats:ResetFallingSpeed()
	self.fallingspeed = self.basefallingspeed
end


--4-5
function Stats:SetKeyBuffer(event, key, key2, duration) --11-7-17 ADDING AN ADDITIONAL KEY!
	-- print("BUFFERKEY", event, key, key2, duration)
	self.event = event
	self.key = key
	self.buffertick = duration or 6 --3-30-19 ADDED OPTION TO OVERRIDE THE 5 TICK BUFFER DURATION WHEN SETTING THE BUFFER
	if key2 then --11-7-17 AN ADDITIONAL DATA POINT (INITIALLY USED FOR FSPECIAL DIRECTIONS)
		self.key2 = key2 else self.key2 = nil
	end
	
	if self.slave and not self.slave:HasTag("heel") then
		self.slave.components.stats:SetKeyBuffer(event, key or nil, key2 or nil, duration or nil)
	end
end

function Stats:ClearKeyBuffer()
	-- print("CLEARBUFFER FN")
	-- self.inst:PushEvent("clearbuffer") --1-29-22 WAIT WHY DID WE DO IT LIKE THIS?? THIS TOTALLY SUCKS.
	self.inst.components.stats.buffertick = 0 --THIS HAPPENS FASTER
end


--7-6 FOR CPU BUFFERING  --NOW UNUSED
-- function Stats:SetMoveBuffer(event, key)
	-- self.event = event
	-- self.key = key
	-- self.buffertick = 5
-- end

function Stats:PushMoveBuffer()
	print("MOVE BUFFER?? WHEN DID-", self.event, self.key) --12-30-16 IDK MAN, THIS IS ONLY USED LIKE TWICE IN CODE. I THINK I SHOULD DISABLE IT, ITS MAKING HIM GRAB AFTER DROPPING SHIELD
	--10-17-20 APPARENTLY IT IS BEING USED, THOUGH. THE PRINT MSG IS BEING CALLED. SO I GUESS IM LEAVING IT IN FOR NOW
	--10-31-30 I'M PRETTY SURE IT'S ONLY CURRENT USE IS TO PUSH AN ATTACK RIGHT AFTER SHIELD IS DROPPED, TO PUNISH EFFECTIVELY (ELSE HE WOULD SHIELDGRAB IF PUSHED EARLY)
	--FROM WHAT I CAN TELL, THIS IS NOT THE SOURCE OF HIS BLOCK/UNBLOCK DANCE BUG
	self.inst:PushEvent(self.event, {key = self.key})
end

function Stats:ClearMoveBuffer()
	self.event = "none"
end


--12-29-21 OKAY IM PUTTING THIS IN REAL QUICK CUZ I FORGOT, OOPS.
	--3-27-19 NEW TEST: GO TO A BUFFERED MOVE IF YOU HAVE ONE AVAILABLE. IF YOU DO, RETURN TRUE AND PUSH EVENT FOR THAT KEY. ELSE RETURN FALSE
function Stats:CheckForBufferedMove(player)
	if player.components.stats.buffertick >= 1 then
		player:PushEvent(player.components.stats.event, {key = tostring(player.components.stats.key), key2 = player.components.stats.key2})
		return true
	else
		return false
	end
end


--7-14-19 THINGS LIKE PROJECTILES AND SPIDER DENS REALLY NEEDED THEIR OWN ACCESSABLE COPY OF THIS FN THAT WASNT IN LAUNCHGRAVITY
function Stats:GetRotationValue(inst)
	--LOL THE WAY I DID IT IN LAUNCHGRAV WAS SUUUUPER WEIRD. ILL CUT MYSELF A BREAK THOUGH. IT WAS ONE OF THE FIRST FUNCTIONS I EVER BUILT
	--REFINED THE ACCURACY WITH A GLOBAL FORCEFACEPOINT() REPLACEMENT IN MODMAIN
	if self.inst.Transform:GetRotation() >= - 1 then  
		return 1 
	else
		return -1
	end
end


function Stats:IsInvuln()
	if self.spawninvuln == true or (self.inst.sg and self.inst.sg:HasStateTag("invuln")) then  
		return true
	else
		return false
	end
end

--1-21-22
function Stats:TintTeamColor(amnt)
	local tint = amnt or 0.3
	if self.team == "red" then
		self.inst.AnimState:SetAddColour(tint,0,0,tint)
	elseif self.team == "blue" then
		self.inst.AnimState:SetAddColour(0,0,tint,tint)
	end
end


return Stats
