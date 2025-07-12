local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text" --I NEED TO BORROW THIS
local Grid = require "widgets/grid" --AND THIS
local TEMPLATES = require "widgets/redux/templates"
local UIAnim = require "widgets/uianim"
local Puppet = require "widgets/skinspuppet"
local Button = require "widgets/button"
local Screen = require "widgets/screen"


local VsAiScreen = Class(Screen, function(self, profile)
	Screen._ctor(self, "VsAiScreen")
	self.profile = profile
	
	--1-19-22 OK, GOT IT. THIS IS MANDITORY
	self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0,15,0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	self.selectmenu = self:_BuildAIvs()
	
	self.default_focus = self.selectmenu
	
	-- self.denselectmenu:SetFocus()
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




--8-19-20 LEVEL SELECT LOOKS GREAT, SO LETS DO THE SAME FOR VS-AI
function VsAiScreen:_BuildAIvs()
    local vscpu_root = self.root
	vscpu_root:SetPosition(0,0)
	--CENTERED PLEASE
	vscpu_root:SetHAnchor(ANCHOR_MIDDLE)
	vscpu_root:SetVAnchor(ANCHOR_MIDDLE)
	
	
	local bgframe = vscpu_root:AddChild(Image("images/fepanels.xml", "wideframe.tex")) -- I GUESS THIS WAS THE "DARK" THEME BACK THEN
	bgframe:SetScale(0.76, .9)
	local bg = vscpu_root:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex"))
	bg:SetScale(1.0, .90)
	
	local frame = vscpu_root:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
	frame:SetScale(1.3)
	frame:SetPosition(-200, 0)
	
	
	--JUST A FUN VISUAL VISUAL REPRESENTATION
	local puppet = frame:AddChild(Puppet()) --CORNER_DUDE'S DISTANT COUSIN
    puppet:SetScale(1.6)
    puppet:SetClickable(false)
    puppet:SetPosition(0, -20) -- -70
    puppet:AddShadow()
	
	puppet.animstate:SetBank("spiderfighter")
	puppet.animstate:SetBuild("spider_fighter_build")
	puppet.animstate:PlayAnimation("sleep_loop", true)
	puppet.animstate:Pause() 
	
	
	vscpu_root.spinbg = vscpu_root:AddChild(TEMPLATES.ListItemBackground_Static(350, 60))
    vscpu_root.spinbg:SetPosition(100,0)
	vscpu_root.spinbg:SetTint(0,0,0,.75) --(unpack(normal_list_item_bg_tint))
	
	-- local text = "difficulty"												--text, min, max, label_width, widget_width, height, spacing, CHATFONT, 20
	vscpu_root.difficultyspinner = vscpu_root:AddChild(TEMPLATES.LabelNumericSpinner(STRINGS.SMSH.UI_DIFFICULTY, 1,   5,      150,         150,      50,     3   , CHATFONT, 50))
	vscpu_root.difficultyspinner:SetPosition(100,0)
	local difvalue = vscpu_root.difficultyspinner.spinner:GetSelectedIndex() * 2
	
	-- vscpu_root.difficultyspinner.spinner.OnControl = function() --WELL YEA BUT THIS ALSO BREAKS THE ORIGINAL FUNCTION --( _, control, down)
	--IM GONNA TRY SOMETHING WEIRD. SOMETHING I SAW THE SMARTCROCKPOT DO WITH CAMERA CONTROLS TO "APPEND" AN EXISTING FUNCTION
	local old_oncontrol = vscpu_root.difficultyspinner.OnControl
	vscpu_root.difficultyspinner.OnControl = function(self, control, down, ...)
		old_oncontrol(self, control, down, ...)
		-- print("HI") --OH MY GOD IT WORKS. THATS AWESOME. CRAFT-POT GUY YOU RULE
		difvalue = vscpu_root.difficultyspinner.spinner:GetSelectedIndex() * 2 --TECHNICALLY RETURNS THE INDEX, NOT THE VALUE, BUT THEY SHOULD BE THE SAME
		
		if difvalue < 3 then
			puppet.animstate:PlayAnimation("sleep_loop", true)
			puppet:SetPosition(0, -20)
		elseif difvalue < 6 then
			puppet.animstate:SetBuild("spider_fighter_build")
			puppet.animstate:PlayAnimation("idle", true)
			puppet:SetPosition(0, -40)
		elseif difvalue < 10 then
			puppet.animstate:SetBuild("spider_warrior_build")
		else
		
		end
	end
	
	self.dentitle = vscpu_root:AddChild(BuildSectionTitle("AI DIFFICULTY", 800))
	self.dentitle:SetScale(0.6, 0.6)
    self.dentitle:SetPosition(0, 120)
	
	--IM NOT GONNA MAKE A GRID FOR JUST TWO BUTTONS, RIGHT?
	self.startbtn = vscpu_root:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
	self.startbtn.image:SetScale(.7)
    self.startbtn:SetFont(CHATFONT)
	self.startbtn:SetHAnchor(ANCHOR_MIDDLE)
	self.startbtn:SetVAnchor(ANCHOR_MIDDLE)
	self.startbtn:SetPosition(120, -100, 0)
	self.startbtn:SetClickable(true)
	
	self.startbtn:SetText(STRINGS.SMSH.UI_OK) --"OK"
	-- self.startbtn:SetScale(0.8, 1.0, 1.0)
	
	self.startbtn:SetOnClick( function() 
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["set_cpu_lvl"], difvalue) 
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setservergamemode"], "VS-AI") 
		-- self.vscpumenu:Hide()
		TheFrontEnd:PopScreen()
	end)
	
	--HAVE A CANCEL BUTTON  --MAYBE A SILLY BUTTON
	self.cancelbtn = vscpu_root:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
	self.cancelbtn.image:SetScale(.7)
	self.cancelbtn:SetFont(CHATFONT)
	self.cancelbtn:SetHAnchor(ANCHOR_MIDDLE)
	self.cancelbtn:SetVAnchor(ANCHOR_MIDDLE)
	self.cancelbtn:SetPosition(-100, -100, 0)
	self.cancelbtn:SetClickable(true)
	self.cancelbtn:SetText(STRINGS.SMSH.UI_CANCEL) --"Cancel"
	-- self.cancelbtn:SetScale(1.2, 1.2, 1.2)
	
	self.cancelbtn:SetOnClick( function() 
		-- self.vscpumenu:Hide()
		TheFrontEnd:PopScreen()
	end)
	
	--THESE ARENT IN A GRID SO WE HAVE TO MANUALLY DEFINE THEIR SELECTION ORDER
	vscpu_root.difficultyspinner:SetFocusChangeDir(MOVE_DOWN, self.startbtn)
	self.startbtn:SetFocusChangeDir(MOVE_UP, vscpu_root.difficultyspinner)
	self.startbtn:SetFocusChangeDir(MOVE_LEFT, self.cancelbtn)
	self.cancelbtn:SetFocusChangeDir(MOVE_UP, vscpu_root.difficultyspinner)
	self.cancelbtn:SetFocusChangeDir(MOVE_RIGHT, self.startbtn)
	
	vscpu_root.focus_forward = vscpu_root.difficultyspinner

    return vscpu_root
end


return VsAiScreen