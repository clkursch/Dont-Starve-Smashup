local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text" --I NEED TO BORROW THIS
local Grid = require "widgets/grid" --AND THIS
local TEMPLATES = require "widgets/redux/templates"
local UIAnim = require "widgets/uianim"
local Puppet = require "widgets/skinspuppet"
local Button = require "widgets/button"
local Screen = require "widgets/screen"


local PvPScreen = Class(Screen, function(self, owner)
	Screen._ctor(self, "PvPScreen")
	self.owner = owner
	
	--1-19-22 OK, GOT IT. THIS IS MANDITORY
	self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0,15,0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	self.selectmenu = self:BuildPvPMenu()
	
	self.default_focus = self.selectmenu
	self.focus_forward = self.selectmenu
	-- self.denselectmenu:SetFocus()
end)


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



--HAPHAZARDLY RIPPED FROM THE OPTIONSELECT SCREEN
--shared section for graphics and settings
local label_width = 200
local spinner_width = 220
local spinner_height = 36 --nil -- use default
local spinner_scale_x = .76
local spinner_scale_y = .68
local narrow_field_nudge = -50
local space_between = 5

local function AddListItemBackground(w)
	local total_width = label_width + spinner_width + space_between
	w.bg = w:AddChild(TEMPLATES.ListItemBackground(total_width + 15, spinner_height + 5))
	w.bg:SetPosition(-40,0)
	w.bg:MoveToBack()
end

local function CreateTextSpinner(labeltext, spinnerdata)
	local w = TEMPLATES.LabelSpinner(labeltext, spinnerdata, label_width, spinner_width, spinner_height, space_between, nil, nil, narrow_field_nudge)
	AddListItemBackground(w)
	-- return w.spinner --BUT THEN WE CAN'T MOVE THEM AROUND IF WE JUST RETURN THE SPINNER!
	return w
end


function PvPScreen:BuildPvPMenu()
    local pvp_root = self.root
	pvp_root:SetPosition(0,0) --CENTERED PLEASE
	pvp_root:SetHAnchor(ANCHOR_MIDDLE)
	pvp_root:SetVAnchor(ANCHOR_MIDDLE)
	--pvp_root.focus_forward = pvp_root.difficultyspinner
	
	self.pvpoptions = {}
	
	-- local bg = pvp_root:AddChild(TEMPLATES.CurlyWindow(130, 150, 1, 1, 68, -40))
	-- bg.fill = bg:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex"))
	-- local bgframe = self:AddChild(TEMPLATES.CurlyWindow(130, 150)) --HEY, THIS ISNT THE SAME THEME??
	-- local bgframe = pvp_root:AddChild(Image("images/fepanels.xml", "wideframe.tex")) -- I GUESS THIS WAS THE "DARK" THEME BACK THEN
	-- bgframe:SetScale(0.76, .9)
	local bgframe = pvp_root:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex")) -- I GUESS THIS WAS THE "DARK" THEME BACK THEN
	bgframe:SetScale(1, 1.5)
	
	
	
	-- local bg = pvp_root:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex"))
	-- bg:SetScale(1.0, .90)
	
	-- local frame = pvp_root:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
	-- frame:SetScale(1.3)
	-- frame:SetPosition(-200, 0)
	
	-- pvp_root.spinbg = pvp_root:AddChild(TEMPLATES.ListItemBackground_Static(350, 60))
	-- pvp_root.spinbg:SetPosition(100,0)
	-- pvp_root.spinbg:SetTint(0,0,0,.75) --(unpack(normal_list_item_bg_tint))
	
	self.pvptitle = pvp_root:AddChild(BuildSectionTitle("PVP SETTINGS", 800))
	self.pvptitle:SetScale(0.6, 0.6)
    self.pvptitle:SetPosition(0, 170)
	
	--ADD A CONTEXT DESCRIPTION TEXT FIELD
	self.contexthint = pvp_root:AddChild(Text(BUTTONFONT, 30))
	self.contexthint:SetString( "Select a Setting") 
	self.contexthint:SetColour(BLACK)
	self.contexthint:SetPosition(0,-100,0)
	table.insert(self.pvpoptions, self.contexthint)
	
	--COPY PASTED FROM MODINFO BECAUSE I GUESS THAT'S HOW ALL THE COOL KIDS DO IT
	local fightercount_options = {
		{text = "1v1", data = 2},
		{text = "3", data = 3},
		{text = "4", data = 4},
		{text = "5", data = 5},
		{text = "6", data = 6},
		{text = "Unlimited", data = 99},
	}
	self.fightercountSpinner = CreateTextSpinner(STRINGS.SMSH.UI_PVP_FIGHTERS, fightercount_options) --"Fighters"
	
	--FIND WHAT OUR CURRENT SETTINGS ARE AND CHANGE THEM
	local spinner_idx = 0
	for idx, option in pairs( fightercount_options ) do
		if option.data == self.owner.smashmatchsizenetvar:value() then
			spinner_idx = idx
			break
		end
	end
	self.fightercountSpinner.spinner:SetSelectedIndex( spinner_idx )
	self.fightercountSpinner.spinner.OnChanged = function( _, data )
		--self.contexthint:SetText(fightercount_options[self.fightercountSpinner:GetSelectedIndex()].hover)
	end
	table.insert(self.pvpoptions, self.fightercountSpinner)
	
	
	
	
	local livescount_options = {}
	for i = 1, 10 do livescount_options[i] = {text = i, data = i} end
	self.livescountSpinner = CreateTextSpinner(STRINGS.SMSH.UI_PVP_LIVES, livescount_options) --"Lives"
	
	--FIND WHAT OUR CURRENT SETTINGS ARE AND CHANGE THEM
	for idx, option in pairs( livescount_options ) do
		if option.data == self.owner.smashmatchlivesnetvar:value() then
			spinner_idx = idx
			break
		end
	end
	self.livescountSpinner.spinner:SetSelectedIndex( spinner_idx )
	table.insert(self.pvpoptions, self.livescountSpinner)
	
	
	
	
	--ADD A CONTEXT DESCRIPTION TEXT FIELD
	self.seperator = pvp_root:AddChild(Text(BUTTONFONT, 40))
	self.seperator:SetString("=== "..STRINGS.SMSH.UI_PVP_TEAMSETTINGS.." ===") 
	self.seperator:SetColour(BLACK)
	table.insert(self.pvpoptions, self.seperator)
	
	
	
	--[[
	-Team Battles: 
		-Off 
		-On
		-On for 4+ players
	
	-Team Selection:
		-Random Teams
		-Select Teams
	
	-Team Size Corection
		-Auto Balance
		-Allow Imbalance
	
	-Open Team Slots
		-Ignore
		-Fill with Spiders
	
	]]
	
	-- self.teamoptions = {}
	local team_options = {
		{text = STRINGS.SMSH.UI_OFF, data = 1, hover=STRINGS.SMSH.UI_PVP_TEAMS_H1}, --"Every man for themselves"
		{text = STRINGS.SMSH.UI_ON, data = 2, hover=STRINGS.SMSH.UI_PVP_TEAMS_H2}, --"Fighters will be grouped into 2 teams"
		{text = STRINGS.SMSH.UI_PVP_TEAMS_D3, data = 3, hover=STRINGS.SMSH.UI_PVP_TEAMS_H3}, --"Teams will be enabled as long as there are at least 4 players"
	}
	self.teamsSpinner = CreateTextSpinner(STRINGS.SMSH.UI_PVP_TEAMS, team_options)
	self.teamsSpinner.spinner:SetSelectedIndex( self.owner.smashteamsnetvar:value() )
	self.teamsSpinner.spinner.OnChanged = function( _, data )
		print("TEAM DATA!", data)
		self.contexthint:SetString(team_options[self.teamsSpinner.spinner:GetSelectedIndex()].hover)
	end
	table.insert(self.pvpoptions, self.teamsSpinner)
	
	
	--TEAM SELECTION
	local teamselect_options = {
		{text = STRINGS.SMSH.UI_PVP_TEAMSELECTION_D1, data = 1, hover=STRINGS.SMSH.UI_PVP_TEAMSELECTION_H1}, --"Players may choose their own team"
		{text = STRINGS.SMSH.UI_PVP_TEAMSELECTION_D2, data = 2, hover=STRINGS.SMSH.UI_PVP_TEAMSELECTION_H2}, --"Teams are randomly assigned"
	}
	self.teamselectSpinner = CreateTextSpinner(STRINGS.SMSH.UI_PVP_TEAMSELECTION, teamselect_options)
	self.teamselectSpinner.spinner:SetSelectedIndex( self.owner.smashteamselectnetvar:value() )
	self.teamselectSpinner.spinner.OnChanged = function( _, data )
		self.contexthint:SetString(teamselect_options[self.teamselectSpinner.spinner:GetSelectedIndex()].hover)
	end
	table.insert(self.pvpoptions, self.teamselectSpinner)
	
	
	--TEAM SIZE CORRECTION
	local teamsizecr_options = {
		{text = STRINGS.SMSH.UI_PVP_TEAMSIZECR_D1, data = 1, hover=STRINGS.SMSH.UI_PVP_TEAMSIZECR_H1}, --AUTO BALANCE
		{text = STRINGS.SMSH.UI_PVP_TEAMSIZECR_D2, data = 2, hover=STRINGS.SMSH.UI_PVP_TEAMSIZECR_H2}, --IGNORE IMBALANCE
	}
	self.teamsizecrSpinner = CreateTextSpinner(STRINGS.SMSH.UI_PVP_TEAMSIZECR, teamsizecr_options)
	self.teamsizecrSpinner.spinner:SetSelectedIndex( self.owner.smashteamsizecrnetvar:value() )
	self.teamsizecrSpinner.spinner.OnChanged = function( _, data )
		self.contexthint:SetString(teamsizecr_options[self.teamsizecrSpinner.spinner:GetSelectedIndex()].hover)
	end
	table.insert(self.pvpoptions, self.teamsizecrSpinner)
	
	
	--TEAM FILL OPTIONS
	local teamfill_options = {
		{text = STRINGS.SMSH.UI_PVP_TEAMFILL_D2, data = 1, hover=STRINGS.SMSH.UI_PVP_TEAMFILL_H2},
		{text = STRINGS.SMSH.UI_PVP_TEAMFILL_D1, data = 2, hover=STRINGS.SMSH.UI_PVP_TEAMFILL_H1},
	}
	self.teamfillSpinner = CreateTextSpinner(STRINGS.SMSH.UI_PVP_TEAMFILL, teamfill_options)
	self.teamfillSpinner.spinner:SetSelectedIndex( self.owner.smashopenteamfillnetvar:value() )
	self.teamfillSpinner.spinner.OnChanged = function( _, data )
		self.contexthint:SetString(teamfill_options[self.teamfillSpinner.spinner:GetSelectedIndex()].hover)
	end
	table.insert(self.pvpoptions, self.teamfillSpinner)
    
	
	
	self.startbtn = pvp_root:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    self.startbtn:SetFont(CHATFONT)
	self.startbtn:SetScale(.6)
	-- self.startbtn:SetHAnchor(ANCHOR_MIDDLE)
	-- self.startbtn:SetVAnchor(ANCHOR_MIDDLE)
	self.startbtn:SetPosition(120, -100, 0) 
	self.startbtn:SetClickable(true)
	self.startbtn:SetText(STRINGS.SMSH.UI_OK) --"OK"
	self.startbtn:SetOnClick( function() 
		--SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["set_cpu_lvl"], difvalue) 
		--SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setservergamemode"], "VS-AI") 
		-- AddModRPCHandler("ServerStore", "Purchased", ClientPurchased)
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setpvpoptions"], "fightercount", self.fightercountSpinner.spinner:GetSelected().data)
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setpvpoptions"], "livescount", self.livescountSpinner.spinner:GetSelected().data)
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setpvpoptions"], "teams", self.teamsSpinner.spinner:GetSelected().data)
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setpvpoptions"], "teamselect", self.teamselectSpinner.spinner:GetSelected().data)
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setpvpoptions"], "teamsizecr", self.teamsizecrSpinner.spinner:GetSelected().data)
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setpvpoptions"], "teamfill", self.teamfillSpinner.spinner:GetSelected().data)
		
		--AND I GUESS THAT DOESN'T UPDATE IT FOR US SO WE GOTTA FIX THAT???
		-- TUNING.SMASHUP.TEAMS = self.teamsSpinner.spinner:GetSelected().data
		
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setservergamemode"], "PVP")
		-- self.pvp_root:Hide()
		TheFrontEnd:PopScreen() --MAYBE?
	end)
	
	table.insert(self.pvpoptions, self.startbtn)
	
	
	
	--8-22-20 LETS MAKE OUR CORNER MENU A LITTLE CLEANER
	self.pvpmenu_grid = pvp_root:AddChild(Grid())
	self.pvpmenu_grid:SetHAnchor(ANCHOR_MIDDLE)
	self.pvpmenu_grid:SetVAnchor(ANCHOR_MIDDLE)
	self.pvpmenu_grid:SetPosition(0, 130, 0)
	
	local button_width = 300
    local button_height = 40
	self.pvpmenu_grid:FillGrid(1, button_width, button_height, self.pvpoptions)
	
	self.pvpmenu_grid:SetScale(1.5, 1.5)
	
	pvp_root.focus_forward = self.pvpmenu_grid

    return pvp_root
end


return PvPScreen