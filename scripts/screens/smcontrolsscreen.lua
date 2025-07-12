local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text" --I NEED TO BORROW THIS
local Grid = require "widgets/grid" --AND THIS
local TEMPLATES = require "widgets/redux/templates"
local UIAnim = require "widgets/uianim"
local Puppet = require "widgets/skinspuppet"
local Button = require "widgets/button"
local Screen = require "widgets/screen"


local SMControlsScreen = Class(Screen, function(self)
	Screen._ctor(self, "SMControlsScreen")
	-- self.profile = profile
	
	
	
	-- self.selectmenu = self:_BuildAIvs()
	-- self.default_focus = self.selectmenu
	-- self.denselectmenu:SetFocus()
	
	
	
	--HAH, THEY REALLY JUST SHOVE A BLACK SQUARE ON SCREEN??
	self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.75)	
	
	--1-19-22 OK, GOT IT. THIS IS MANDITORY
	self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0,100,0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	self.pane = self.root:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex"))
	self.pane:SetVRegPoint(ANCHOR_MIDDLE)
    self.pane:SetHRegPoint(ANCHOR_MIDDLE)
	self.pane:SetScale(0.65,1.25,0.8)
	self.pane:SetPosition(0,-20,0)
	
	
	self.playerselect_title = self.root:AddChild(Text(BUTTONFONT, 65))
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
		self.ctext = self.root:AddChild(Text(BUTTONFONT, 25))
	else
		self.ctext = self.root:AddChild(Text(BUTTONFONT, 32))
	end
	-- self.ctext:SetHAnchor(ANCHOR_LEFT)
	self.ctext:SetString( text )
	self.ctext:SetColour(BLACK)
	self.ctext:SetPosition(0,-40,0)
	self.ctext:SetHAlign(ANCHOR_LEFT)
	self.ctext:SetRegionSize(380,800)
	-- self.pane:MoveToBack()
	
	
	--1-2-22 FOR PPL WHO DON'T KNOW MY MOD
	self.modhint = self.root:AddChild(Text(BUTTONFONT, 40))
	self.modhint:SetString( STRINGS.SMSH.CTRLS_MODHINT ) --"Change your controls with the 'Smashup Custom Controls' client mod" 
	self.modhint:SetColour(WHITE)
	self.modhint:SetPosition(0,-275,0)
	-- self.modhint:SetPosition(((RESOLUTION_X/4)*3) + 25, (RESOLUTION_Y/2)+130, 0)
	
	
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
	
	
	--WHAT WAS I EVEN DOING WITH ALL OF THIS??
	-- self:SetClickable(true)
	-- self:SetOnClick( function() self:SpawnADude() end)
	-- self.tracking_mouse = true
	-- TheInputProxy:SetCursorVisible(true)
	-- self.default_focus = self.menu
	-- self.active = true
	-- TheInput:DisableAllControllers()
	-- TheInput:ClearCachedController()
	-- TheInput:EnableMouse(true) --7-29-17 OH. THIS MAKES THINGS EASIER
	
	self.fixed_root = self.root:AddChild(Widget("root"))
    self.fixed_root:SetPosition(-RESOLUTION_X/2, -RESOLUTION_Y/2, 0)
	
	
	
	
	-- self.preflabel = self.fixed_root:AddChild(Text(BUTTONFONT, 50))
	self.preflabel = self.root:AddChild(Text(BUTTONFONT, 50))
	self.preflabel:SetString( STRINGS.SMSH.CTRLS_PREFERENCES ) --"--PREFERENCES--" 
	self.preflabel:SetColour(WHITE)
	self.preflabel:SetPosition(((RESOLUTION_X/4)*3) + 25, (RESOLUTION_Y/2)+130, 0)
	
	
	self.sidebarbtns = {}
	
	--6-9-17 A CUSTOM BUTTON FOR THE KIRTLE
	self.kirtbutton = self.fixed_root:AddChild(ImageButton())
	-- self.kirtbutton:SetPosition(((RESOLUTION_X/4)*3) + 25, (RESOLUTION_Y/2)+75, 0)
	-- self.kirtbutton:SetClickable(true)
	self.kirtbutton:SetText(STRINGS.SMSH.CTRLS_TAPJ_OFF)
	table.insert(self.sidebarbtns, self.kirtbutton)
	
	--10-7-17 LETS MAKE THESE CONTROLS MORE FLEXIBLE.
	-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["rectrler"], tapjumppreference) --MAKE SURE TO RE-SEND CONTROLS FOR NEW-SPAWNS TO PICK UP
	-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["rectrler"], tapjumppreference) --IN FACT, WE GOTTA SEND EM TWICE, TO DOUBLE TOGGLE AND CANCEL OUT THE TOGGLES
	--OKAY WOW ALL WE REALLY NEEDED WAS TO WAIT A SEC BEFORE REAPPLYING THE PREFERENCES. NOW DONE IN PLAYERCOMMON
	if Preftapjump == "on" then
		self.kirtbutton:SetText(STRINGS.SMSH.CTRLS_TAPJ_ON)
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
	-- self.dashbutton:SetPosition(((RESOLUTION_X/4)*3) + 25, (RESOLUTION_Y/2)+25, 0) --75
	-- self.dashbutton:SetClickable(true)
	self.dashbutton:SetText("Auto-Dash: Initializing")
	table.insert(self.sidebarbtns, self.dashbutton)
	
	if Prefautodash == "on" then
		self.dashbutton:SetText(STRINGS.SMSH.CTRLS_AUTODASH_ON) 
	else
		self.dashbutton:SetText(STRINGS.SMSH.CTRLS_AUTODASH_OFF) 
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
	
	
	
	--1-29-22 MUSIC BUTTON
	self.musicbutton = self.fixed_root:AddChild(ImageButton())
	self.musicbutton:SetText("Auto-Dash: Initializing")
	table.insert(self.sidebarbtns, self.musicbutton)
	
	if Prefmusic == "on" then
		self.musicbutton:SetText(STRINGS.SMSH.CTRLS_MUSIC_ON) 
	else
		self.musicbutton:SetText(STRINGS.SMSH.CTRLS_MUSIC_OFF) 
	end
	
	self.musicbutton:SetOnClick( function() 
		if Prefmusic == "off" then
			Prefmusic = "on"
			self.musicbutton:SetText(STRINGS.SMSH.CTRLS_MUSIC_ON) --"Auto-Dash: ON"
		else
			Prefmusic = "off"
			self.musicbutton:SetText(STRINGS.SMSH.CTRLS_MUSIC_OFF) --"Auto-Dash: OFF"
			TheFocalPoint.SoundEmitter:KillSound("busy")
		end
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["reautodash"], Prefautodash) 
	end)
	
	
	--AND ONE FOR CLOSING IT
	self.closebutton = self.root:AddChild(ImageButton())
	table.insert(self.sidebarbtns, self.closebutton)
	
	
	self.sidebar_grid = self.root:AddChild(Grid())
	self.sidebar_grid:SetHAnchor(ANCHOR_MIDDLE)
	self.sidebar_grid:SetVAnchor(ANCHOR_MIDDLE)
	self.sidebar_grid:SetPosition(400, 0, 0)
	self.sidebar_grid:FillGrid(1, 10, 75, self.sidebarbtns)  --1, button_width, button_height
	
	
	
	--PART OF THE GRID, BUT SET DOWN AT THE BOTTOM OF THE PAGE
	self.closebutton:SetPosition(-400, -200, 0)
	-- self.closebutton:SetScale(0.7,0.7,0.7)
	-- self.closebutton:SetClickable(true)
	self.closebutton:SetText(STRINGS.SMSH.UI_DONE) --"Done"
    self.closebutton:SetOnClick( function() 
		TheFrontEnd:PopScreen() 
	end)
	
	
	self.default_focus = self.sidebar_grid
	
end)


--8-4-20 STEPPING THINGS UP A NOTCH FOR THE HORDE MODE
--AND BY THAT I MEAN STEALING KLEIS NEW IMPROVED MENU BUILDING FUNCTIONS
local function BuildSectionTitle(text, region_size)
    local title_root = Widget("title_root")
    local title = title_root:AddChild(Text(CHATFONT_OUTLINE, 70))
	
    title:SetRegionSize(region_size, 70)
    title:SetString(text)
    title:SetColour(UICOLOURS.GOLD_SELECTED)

    local titleunderline = title_root:AddChild( Image("images/frontend_redux.xml", "achievements_divider_top.tex") )
    titleunderline:SetScale(1.5, 1.5)
    titleunderline:SetPosition(0, -20)

    return title_root
end




return SMControlsScreen