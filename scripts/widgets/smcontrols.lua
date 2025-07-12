local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local easing = require("easing")


local SMControls = Class(Widget, function(self, owner) --WE DONT NEED AN OWNER
-- local SMControls = Class(Screen, function(self, title, text, buttons)
    self.owner = owner
    Widget._ctor(self, "SMControls")
	
	
	--HAH, THEY REALLY JUST SHOVE A BLACK SQUARE ON SCREEN??
	self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.75)	
	
	
	self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0,0,0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	
	
	self.pane = self.proot:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex")) --
    -- self.pane:SetVRegPoint(ANCHOR_MIDDLE)
    -- self.pane:SetHRegPoint(ANCHOR_MIDDLE)
	 self.pane:SetVRegPoint(ANCHOR_MIDDLE)
    self.pane:SetHRegPoint(ANCHOR_MIDDLE)
	self.pane:SetScale(0.65,1.25,0.8)
	self.pane:SetPosition(0,-20,0)
	
	
	self.playerselect_title = self.proot:AddChild(Text(BUTTONFONT, 65))
	self.playerselect_title:SetString( "--"..STRINGS.SMSH.CTRLS_DEF_CONTROLS.."--" ) --"DEFAULT CONTROLS"
	self.playerselect_title:SetColour(BLACK)
	self.playerselect_title:SetPosition(0,150,0)
	
	--[[
	local text = "WASD = Movement   -   SPACE = Jump \n"
	text = text .. "(Double-Tap a direction to dash) \n"
	text = text .. " \n"
	text = text .. "N = Attack  \n"
	text = text .. "M = Special Attack \n"
	text = text .. "(Hold directional keys to do different attacks) \n"
	text = text .. " \n"
	text = text .. "CTRL/SHIFT = Block \n"
	text = text .. "COMMA = Grab \n"
	]]
	local text = STRINGS.SMSH.CTRLS_DESC_1
	text = text .. " \n"
	text = text .. STRINGS.SMSH.CTRLS_DESC_2
	text = text .. " \n"
	text = text .. STRINGS.SMSH.CTRLS_DESC_3
	
	--1-2-22 RUSSIAN LANGUAGE IS WAY TOO BIG. SHRINK IT DOWN IF IT'S RUSSIAN.
	if TUNING.SMASHUP.LANGUAGE == "ru" then
		self.ctext = self.proot:AddChild(Text(BUTTONFONT, 25))
	else
		self.ctext = self.proot:AddChild(Text(BUTTONFONT, 32))
	end
	-- self.ctext:SetHAnchor(ANCHOR_LEFT)
	self.ctext:SetString( text )
	self.ctext:SetColour(BLACK)
	self.ctext:SetPosition(0,-40,0)
	
	self.ctext:SetHAlign(ANCHOR_LEFT)
	self.ctext:SetRegionSize(380,800)
	-- self.pane:MoveToBack()
	
	
	--1-2-22 FOR PPL WHO DON'T KNOW MY MOD
	self.modhint = self.proot:AddChild(Text(BUTTONFONT, 40))
	self.modhint:SetString( STRINGS.SMSH.CTRLS_MODHINT ) --"Change your controls with the 'Smashup Custom Controls' client mod" 
	self.modhint:SetColour(WHITE)
	self.modhint:SetPosition(0,-275,0)
	-- self.modhint:SetPosition(((RESOLUTION_X/4)*3) + 25, (RESOLUTION_Y/2)+130, 0)
	
	
	--WAIT WHY IS THIS HERE? IS THERE JUST AN INVISIBLE WILSON ON THE CONTROL SCREEN?
	self.anim = self:AddChild(UIAnim())
    -- self:SetScaleMode(SCALEMODE_FIXEDPROPORTIONAL)
	-- self:SetScaleMode(SCALEMODE_PROPORTIONAL)
	-- self:SetClickable(false)
    -- self.anim:GetAnimState():SetBank("fire_over")
    -- self.anim:GetAnimState():SetBuild("fire_over")
    -- self.anim:GetAnimState():PlayAnimation("anim", true)
	self.anim:GetAnimState():SetBank("newwilson")
    self.anim:GetAnimState():SetBuild("newwilson")
    self.anim:GetAnimState():PlayAnimation("idle", true)
	-- print("NOW LISTEN CLOSELY", self.anim:GetAnimState():GetBank("newwilson")) --NOPE
    -- self:SetHAnchor(ANCHOR_LEFT)
    -- self:SetVAnchor(ANCHOR_TOP)
	self:SetHAnchor(ANCHOR_MIDDLE)
    self:SetVAnchor(ANCHOR_MIDDLE)
	self:SetPosition(-200,0,0)
	self:SetScale(0.5,0.5,0.5)
    self.targetalpha = 1 --0
    self.startalpha = 1 --0
    self.alpha = 1 --0
    -- self:Hide()
    self.ease_time = .4
    self.t = 0
	self.anim:GetAnimState():SetMultColour(1,1,1,0)
	
	
	
	self:SetClickable(true)
	-- self:SetOnClick( function() self:SpawnADude() end)
	self.tracking_mouse = true
	
	
	
	TheInputProxy:SetCursorVisible(true)
	-- self.default_focus = self.menu
	self.active = true
	-- TheInput:DisableAllControllers()
	TheInput:ClearCachedController()
	TheInput:EnableMouse(true) --7-29-17 OH. THIS MAKES THINGS EASIER
	
	
	
	self.root = self:AddChild(Widget("root")) --THIS IS GETTING OUT OF HAND
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	self.fixed_root = self.root:AddChild(Widget("root"))
    self.fixed_root:SetPosition(-RESOLUTION_X/2, -RESOLUTION_Y/2, 0)
	
	-- local Image = require "widgets/image"
	local ImageButton = require "widgets/imagebutton"
	self.buttonpos = -(2.5 * (RESOLUTION_X/10)) --DST --NOT SURE WHY ITS 2.5 AND NOT 2 OR 3 BUT IT JUST IS
	self.buttonposy = (RESOLUTION_Y/2) - 50 --DST 
	self.rowdampen = 0 --DST
	
	
	--AND ONE FOR CLOSING IT
	self.closebutton = self.proot:AddChild(ImageButton()) --DST CHANGE - REUSEABLE- BETTER BALANCED HUD CLOSEING BUTTON because its added to proot
	self.closebutton:SetPosition(0, -200, 0) --(0, -195, 0)
	self.closebutton:SetScale(0.7,0.7,0.7)
	self.closebutton:SetClickable(true)
	self.closebutton:SetText(STRINGS.SMSH.UI_DONE) --"Done"
    self.closebutton:SetOnClick( function() 
		self:Hide()
	end)
	
	self.default_focus = self.root
	
	
	self.preflabel = self.fixed_root:AddChild(Text(BUTTONFONT, 50))
	self.preflabel:SetString( STRINGS.SMSH.CTRLS_PREFERENCES ) --"--PREFERENCES--" 
	self.preflabel:SetColour(WHITE)
	self.preflabel:SetPosition(((RESOLUTION_X/4)*3) + 25, (RESOLUTION_Y/2)+130, 0)
	
	
	--6-9-17 A CUSTOM BUTTON FOR THE KIRTLE
	self.kirtbutton = self.fixed_root:AddChild(ImageButton())
	self.kirtbutton:SetPosition(((RESOLUTION_X/4)*3) + 25, (RESOLUTION_Y/2)+75, 0)
	self.kirtbutton:SetClickable(true)
	self.kirtbutton:SetText(STRINGS.SMSH.CTRLS_TAPJ_OFF)
	-- self.kirtbutton:SetOnClick( function() SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["rectrler"]) end)
	
	
	
	--10-7-17 LETS MAKE THESE CONTROLS MORE FLEXIBLE.
	local tapjumppreference = Preftapjump
	
	if tapjumppreference then
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["rectrler"], tapjumppreference) --MAKE SURE TO RE-SEND CONTROLS FOR NEW-SPAWNS TO PICK UP
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["rectrler"], tapjumppreference) --IN FACT, WE GOTTA SEND EM TWICE, TO DOUBLE TOGGLE AND CANCEL OUT THE TOGGLES
		--OKAY WOW ALL WE REALLY NEEDED WAS TO WAIT A SEC BEFORE REAPPLYING THE PREFERENCES. NOW DONE IN PLAYERCOMMON
	
		if Preftapjump == "on" then
			self.kirtbutton:SetText(STRINGS.SMSH.CTRLS_TAPJ_ON)
		end
	end
	
	self.kirtbutton:SetOnClick( function() 
		if Preftapjump == "off" then
			Preftapjump = "on"
			self.kirtbutton:SetText(STRINGS.SMSH.CTRLS_TAPJ_ON)
		else
			Preftapjump = "off"
			self.kirtbutton:SetText(STRINGS.SMSH.CTRLS_TAPJ_OFF)
		end
		
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["rectrler"], Preftapjump) 
		
	end)
	
	
	
	--AUTO-DASH
	--9-29-20 THIS IS AN OLD FEATURE THAT WE ENDED UP HALF-BAKING INTO THE GAME. IM HIDING THE BUTTON FOR NOW
	--9-30-21 AAAND I'M BRINGING IT BACK TO REPURPOSE IT! ALMOST EXACTLY 1 YEAR LATER
	self.dashbutton = self.fixed_root:AddChild(ImageButton())
	self.dashbutton:SetPosition(((RESOLUTION_X/4)*3) + 25, (RESOLUTION_Y/2)+25, 0) --75
	self.dashbutton:SetClickable(true)
	self.dashbutton:SetText("Auto-Dash: Initializing")
	
	local autodashpreference = Prefautodash
	
	if autodashpreference ~= nil then
		if Prefautodash == "on" then
			self.dashbutton:SetText(STRINGS.SMSH.CTRLS_AUTODASH_ON) 
		else
			self.dashbutton:SetText(STRINGS.SMSH.CTRLS_AUTODASH_OFF) 
		end
	end
	
	self.dashbutton:SetOnClick( function() 
		if Prefautodash == "off" then
			Prefautodash = "on"
			self.dashbutton:SetText(STRINGS.SMSH.CTRLS_AUTODASH_ON) --"Auto-Dash: ON"
		else
			Prefautodash = "off"
			self.dashbutton:SetText(STRINGS.SMSH.CTRLS_AUTODASH_OFF) --"Auto-Dash: OFF"
		end
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["reautodash"], Prefautodash) 
	end)
	
	
	--THE MAGIC THAT MAKES IT SHOW UP
	self.owner.ShowControlScreen = function()
		self:Show()
	end
	
	self:Hide()
end)



function SMControls:TestSkins() --DST
	self.owner.AnimState:SetBank("newwilson")
	self.owner.AnimState:SetBuild("newwickerbottom")
	self.owner:SetStateGraph("SGnewwickerbottom")
	--SWITCHING STATEGRAPHS MID-STATE WILL IGNORE ANY ONEXIT FUNCTIONS
	self.owner.sg:GoToState("respawn_platform") 
end


--UNUSED? REMNANT OF THE ORIGINAL. SHRUG
function SMControls:OnUpdate(dt)
	self.alpha = easing.outCubic( self.t, self.startalpha, self.targetalpha-self.startalpha, self.ease_time ) 
	self.anim:GetAnimState():SetMultColour(1,1,1,self.alpha)
end


return SMControls
