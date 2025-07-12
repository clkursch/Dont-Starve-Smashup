require("camerashake")

--When onupdatefn is set to nil, use dummyfn instead.
--This way we don't need to check for nil in the update loop.
--It's more optimized because there's always an actual onupdatefn
--when the world is live and performance does matter.
local function dummyfn()
end

local FollowCamera = Class(function(self, inst)
    self.inst = inst
    self.target = nil
    self.currentpos = Vector3(0, 0, 0)
    self.currentscreenxoffset = 0
    self.distance = 30
    self.screenoffsetstack = {}
    self:SetDefault()
    self:Snap()
    self.time_since_zoom = nil
    self.onupdatefn = dummyfn
end)

function FollowCamera:SetDefault()
   self.targetpos = Vector3(0,0,0)
    --self.currentpos = Vector3(0,0,0)
    self.targetoffset = Vector3(0,1.5,0)

    if self.headingtarget == nil then
        --self.headingtarget = 45
		self.headingtarget = 90  --@@@@
    end

    self.fov = 35
    -- self.pangain = 4
    -- self.headinggain = 20
    -- self.distancegain = 1
	self.pangain = 10 --4--20
    self.headinggain = 20 --0
    self.distancegain = 1 --1 --20

    self.zoomstep = 4
    self.distancetarget = 10 --15

    --self.mindist = 15
	-- self.mindist = 15 --0
    -- self.maxdist = 70 --40
	self.mindist = 10 --0
    self.maxdist = 45 --40
   
    --self.mindistpitch = 30
	self.mindistpitch = 5  --ITS NORMALLY 5
	
	
    self.maxdistpitch = 10--60 
    self.paused = false
    self.shake = nil
    self.controllable = true
    self.cutscene = false


    -- if GetWorld() and GetWorld():IsCave() then  --DSTCHANGE@@
        -- self.mindist = 15
        -- self.maxdist = 35
        -- self.mindistpitch = 25
        -- self.maxdistpitch = 40
        -- self.distancetarget = 25
    -- end

    if self.target then
        self:SetTarget(self.target)
    end
end


--12-5-17 DST CHANGE - A SPECIAL LITTLE BUMP TO THE CAMERA SETTINGS FOR CINNIMATIC EFFECT.
function FollowCamera:RoundStartBump()
    self.mindistpitch = 70 --IT WILL AUTOMATICALLY SLOWLY WRITE ITSELF OVER TIME
	self.targetoffset.y = 15 --ITS NORMALLY 1.5
end

function FollowCamera:MiniBump() --FOR GRUE SLASHES
	self.targetoffset.y = 5
	self.mindistpitch = 20
end

--11-24-21 THIS MUST BE FOR THE QOL UPDATE. ADDING A DUMMY FN TO PREVENT CRASHING
function FollowCamera:EnableBoatCamera()
    --DUMMY
end


function FollowCamera:GetRightVec()
    local right = (self.headingtarget + 90) * DEGREES
    return Vector3(math.cos(right), 0, math.sin(right))
end

function FollowCamera:GetDownVec()
    local heading = self.headingtarget * DEGREES
    return Vector3(math.cos(heading), 0, math.sin(heading))
end

function FollowCamera:SetPaused(val)
	self.paused = val
end

function FollowCamera:SetMinDistance(distance)
    self.mindist = distance
end

function FollowCamera:SetGains(pan, heading, distance)
    self.distancegain = distance
    self.pangain = pan
    self.headinggain = heading
end

function FollowCamera:IsControllable()
    return self.controllable
end

function FollowCamera:SetControllable(val)
    self.controllable = val
end

function FollowCamera:CanControl()
    return self.controllable
end

function FollowCamera:SetOffset(offset)
    self.targetoffset.x, self.targetoffset.y, self.targetoffset.z = offset:Get()
end

function FollowCamera:PushScreenHOffset(ref, xoffset)
    self:PopScreenHOffset(ref)
    table.insert(self.screenoffsetstack, 1, { ref = ref, xoffset = xoffset })
end

function FollowCamera:PopScreenHOffset(ref)
    for i, v in ipairs(self.screenoffsetstack) do
        if v.ref == ref then
            table.remove(self.screenoffsetstack, i)
            return
        end
    end
end

function FollowCamera:GetDistance()
    return self.distancetarget
end

function FollowCamera:SetDistance(dist)
    self.distancetarget = dist
end

function FollowCamera:Shake(type, duration, speed, scale)
    -- if Profile:IsScreenShakeEnabled() then  --11-24-21 GET THIS OUTTA HERE, WE WANT TO FORCE THIS TO ENABLE
        self.shake = CameraShake(type, duration, speed, scale)
		
		ShakeAllCameras(0, duration, speed, scale) --OH... THATS CONVENIENT
    -- end
    TheInputProxy:AddVibration(VIBRATION_CAMERA_SHAKE, duration, math.max(0, math.min(scale * .25, 1)), false)    
end

function FollowCamera:SetTarget(inst)
    self.target = inst
    if inst ~= nil then
        self.targetpos.x, self.targetpos.y, self.targetpos.z = self.target.Transform:GetWorldPosition()
    else
        self.targetpos.x, self.targetpos.y, self.targetpos.z = 0, 0, 0
    end
end

function FollowCamera:Apply()
    --dir
    local pitch = self.pitch * DEGREES
    local heading = self.heading * DEGREES
    local cos_pitch = math.cos(pitch)
    local cos_heading = math.cos(heading)
    local sin_heading = math.sin(heading)
    local dx = -cos_pitch * cos_heading
    local dy = -math.sin(pitch)
    local dz = -cos_pitch * sin_heading

    --screen horizontal offset
    local xoffs, zoffs = 0, 0
    if self.currentscreenxoffset ~= 0 then
        --FOV is relative to screen height
        --hoffs is in units of screen heights
        --convert hoffs to xoffs and zoffs in world space
        local hoffs = 2 * self.currentscreenxoffset / RESOLUTION_Y
        local magic_number = 1.03 -- plz... halp.. if u can figure out what this rly should be  --LMAO WHO IS THIS?
        local screen_heights = math.tan(self.fov * .5 * DEGREES) * self.distance * magic_number
        xoffs = -hoffs * sin_heading * screen_heights
        zoffs = hoffs * cos_heading * screen_heights
    end

    --pos
    TheSim:SetCameraPos(
        self.currentpos.x - dx * self.distance + xoffs,
        self.currentpos.y - dy * self.distance,
        self.currentpos.z - dz * self.distance + zoffs
    )
    TheSim:SetCameraDir(dx, dy, dz)

    --right
    local right = (self.heading + 90) * DEGREES
    local rx = math.cos(right)
    local ry = 0
    local rz = math.sin(right)

    --up
    local ux = dy * rz - dz * ry
    local uy = dz * rx - dx * rz
    local uz = dx * ry - dy * rx

    TheSim:SetCameraUp(ux, uy, uz)
    TheSim:SetCameraFOV(self.fov)

    --listen dist
    local listendist = -.1 * self.distance
    TheSim:SetListener(
        dx * listendist + self.currentpos.x,
        dy * listendist + self.currentpos.y,
        dz * listendist + self.currentpos.z,
        dx, dy, dz,
        ux, uy, uz
    )
end

local function lerp(lower, upper, t)
    return t > 1 and upper
        or (t < 0 and lower
        or lower * (1 - t) + upper * t)
end

local function normalize(angle)
    while angle > 360 do
        angle = angle - 360
    end
    while angle < 0 do
        angle = angle + 360
    end
    return angle
end

function FollowCamera:GetHeading()
    return self.heading
end

function FollowCamera:GetHeadingTarget()
    return self.headingtarget
end

function FollowCamera:SetHeadingTarget(r) --3-31-19 WITH THE FIRST PERSON MOD FINISHED, I NOW KNOW WHAT THIS FUNCTION DOES. AND IT SHOULD BE NEVER EVER BE USED HERE
    -- self.headingtarget = r	--GOODBYE
end

function FollowCamera:ZoomIn()
    self.distancetarget = math.max(self.mindist, self.distancetarget - self.zoomstep)
    self.time_since_zoom = 0
end

function FollowCamera:ZoomOut()
    self.distancetarget = math.min(self.maxdist, self.distancetarget + self.zoomstep)
    self.time_since_zoom = 0
end

function FollowCamera:Snap()

	--DST CHANGE -- JUST SOME BOGUS WORKAROUND //SHRUG/
	-- local testx = self.target.Transform:GetWorldPosition()
	-- if self.target ~= nil and not testx then 
		-- return end
	
	
    if self.target ~= nil then
        local x, y, z = self.target.Transform:GetWorldPosition()
		
		--DST CHANGE -- JUST SOME BOGUS WORKAROUND //SHRUG/
		if not x then
			return end
		
        self.targetpos.x = x + self.targetoffset.x
        self.targetpos.y = y + self.targetoffset.y
        self.targetpos.z = z + self.targetoffset.z
    else
        self.targetpos.x, self.targetpos.y, self.targetpos.z = self.targetoffset:Get()
    end

    self.currentscreenxoffset = #self.screenoffsetstack > 0 and self.screenoffsetstack[1].xoffset or 0
    self.currentpos.x, self.currentpos.y, self.currentpos.z = self.targetpos:Get()
    self.heading = self.headingtarget
    self.distance = self.distancetarget
	
	

    self.pitch = lerp(self.mindistpitch, self.maxdistpitch, (self.distance - self.mindist) / (self.maxdist - self.mindist))

    self:Apply()
end

function FollowCamera:CutsceneMode(b)
    self.cutscene = b
end

function FollowCamera:SetCustomLocation(loc)
    self.targetpos.x, self.targetpos.y, self.targetpos.z  = loc:Get()
end

function FollowCamera:Update(dt)
    if self.paused then
        return
    end
	
	
	if self.target ~= nil and not self.target:IsValid() then --DST CHENGE
        return
    end
	
	-- print("MY CAMERA TARGET IS", self.target)
	
	--12-5-17 DST CHANGE - DO A LITTLE CINNIMATIC ZOOM IN ON THE START OF THE MATCH.
	if self.mindistpitch > 5 then
		-- self.mindistpitch = self.mindistpitch - 1 --SLOWLY LOWER THE PITCH BACK TO DEFAULT
		self.mindistpitch = self.mindistpitch * 0.97
		
		if self.mindistpitch < 6 then --ITS CLOSE ENOUGH, JUST SET IT BACK TO NORMAL. WE DONT GOT ALL DAY
			self.mindistpitch = 5 
		end
		
		if not self.target:HasTag("cameraprefab") then --12-26-17 RE-ATTACH THE CAMERA IF IT IS UNDONE
			print("INCORRECT CAMERA TARGET DETECTED")
			self:SetTarget(TheSim:FindFirstEntityWithTag("cameraprefab")) --AYYYYY!  JOB WELL DONE
		end
	end
	
	if self.targetoffset.y > 1.5 then --THE SAME THING BUT WITH THE Y AXIS
		self.targetoffset.y = self.targetoffset.y * 0.98
		if self.targetoffset.y < 1.6 then --ITS CLOSE ENOUGH, JUST SET IT BACK TO NORMAL. WE DONT GOT ALL DAY
			self.targetoffset.y = 1.5 
		end
	end
	
	

    local pangain = dt * self.pangain

    if self.cutscene then
        self.currentpos.x = lerp(self.currentpos.x, self.targetpos.x + self.targetoffset.x, pangain)
        self.currentpos.y = lerp(self.currentpos.y, self.targetpos.y + self.targetoffset.y, pangain)
        self.currentpos.z = lerp(self.currentpos.z, self.targetpos.z + self.targetoffset.z, pangain)
    else
        if self.time_since_zoom ~= nil and not self.cutscene then
            self.time_since_zoom = self.time_since_zoom + dt
            if self.should_push_down and self.time_since_zoom > .25 then
                self.distancetarget = self.distance - self.zoomstep
            end
        end

        if self.target ~= nil and self.target.Transform:GetWorldPosition() then --DST CHANGE
            local x, y, z = self.target.Transform:GetWorldPosition()
            self.targetpos.x = x + self.targetoffset.x
            self.targetpos.y = y + self.targetoffset.y
            self.targetpos.z = z + self.targetoffset.z
        else
            self.targetpos.x, self.targetpos.y, self.targetpos.z = self.targetoffset:Get()
        end

        self.currentpos.x = lerp(self.currentpos.x, self.targetpos.x, pangain)
        self.currentpos.y = lerp(self.currentpos.y, self.targetpos.y, pangain)
        self.currentpos.z = lerp(self.currentpos.z, self.targetpos.z, pangain)
    end

    local screenxoffset = 0
    while #self.screenoffsetstack > 0 do
        if self.screenoffsetstack[1].ref.inst:IsValid() then
            screenxoffset = self.screenoffsetstack[1].xoffset
            break
        end
        table.remove(self.screenoffsetstack, 1)
    end
    if screenxoffset ~= 0 then
        self.currentscreenxoffset = lerp(self.currentscreenxoffset, screenxoffset, pangain)
    elseif self.currentscreenxoffset ~= 0 then
        self.currentscreenxoffset = lerp(self.currentscreenxoffset, 0, pangain)
        if math.abs(self.currentscreenxoffset) < .01 then
            self.currentscreenxoffset = 0
        end
    end

    if self.shake ~= nil then
        local shakeOffset = self.shake:Update(dt)
        if shakeOffset ~= nil then
            local rightOffset = self:GetRightVec() * shakeOffset.x
            self.currentpos.x = self.currentpos.x + rightOffset.x
            self.currentpos.y = self.currentpos.y + rightOffset.y + shakeOffset.y
            self.currentpos.z = self.currentpos.z + rightOffset.z
        else
            self.shake = nil
        end
    end

    self.heading = normalize(self.heading)
    self.headingtarget = normalize(self.headingtarget)

    local diffheading = math.abs(self.heading - self.headingtarget)

    self.heading =
        diffheading <= .01 and
        self.headingtarget or
        lerp(self.heading,
            diffheading <= 180 and
            self.headingtarget or
            self.headingtarget + (self.heading > self.headingtarget and 360 or -360),
            dt * self.headinggain)

    self.distance =
        math.abs(self.distance - self.distancetarget) > .01 and
        lerp(self.distance, self.distancetarget, dt * self.distancegain) or
        self.distancetarget

    self.pitch = lerp(self.mindistpitch, self.maxdistpitch, (self.distance - self.mindist) / (self.maxdist - self.mindist))

    self:onupdatefn(dt)
    self:Apply()
end

function FollowCamera:SetOnUpdateFn(fn)
    self.onupdatefn = fn or dummyfn
end

return FollowCamera
