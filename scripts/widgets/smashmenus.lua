local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text" --I NEED TO BORROW THIS
local Grid = require "widgets/grid" --AND THIS
local TEMPLATES = require "widgets/redux/templates"
local UIAnim = require "widgets/uianim"
local Puppet = require "widgets/skinspuppet"
local Button = require "widgets/button"

local PopupDialogScreen 	= require("screens/popupdialog") --OH, I NEED THIS ONE
-- local PopupDialogScreen 	= require("screens/redux/popupdialog") --OH SNAP, THIS ONE USES THE UPDATED VERSION INSTEAD... HMM.. DO I WANT TO KEEP THE OLD ONE?
-- local PopupDialogScreenTall = require("screens/popupdialogtall") --NOW THIS CUSTOM ONE 11-25-18 --ENDED UP NOT USING THESE

local GameSet = require "widgets/gameset"

local LevelSelect = require "screens/levelselect"
local VsAiScreen = require "screens/vsaiscreen"
local PvPScreen = require "screens/pvpscreen"
local SMControlsScreen = require "screens/smcontrolsscreen"

--8-18-20 FINALLY SEPERATING THIS OUT FROM THE STATUSDISPLAYS LIKE A NORMAL PERSON



--CHECK IF WE'RE ON A DEDICATED SERVER
local function IsDedicatedServer() --GetPlayerClientTable()
	local ClientObjs = TheNet:GetClientTable()
	local dedicated = false
	if ClientObjs == nil or TheNet:GetServerIsClientHosted() then
		--DO NOTHING?
	else
		--CHECK TO SEE IF WE HAVE A DEDICATED HOST OBJECT
		for i, v in ipairs(ClientObjs) do
			if v.performance ~= nil then
				--displaycontrolmenu = true --IF WE DO, ENABLE THE THINGS!
				dedicated = true
				break
			end
		end
	end
	return dedicated
end


local SmashMenus = Class(Widget, function(self, owner)
    Widget._ctor(self, "Status")
    self.owner = owner
	
	self.cornermenubtns = {} --8-22-20
	
	--10-6-17 AND ANOTHER ONE --DISPLAYS THE ENDGAME SCREEN. -EY IT WORKS!! IM SURPRISED HONESTLY
	self.owner.EndGameScreen= function()
		TheSim:SetTimeScale(0.25)
		-- print("SELF.OWNER.UPDATEBADGES! GENERAL")
		self.gameset = self:AddChild(GameSet(owner))
		self.gameset:TurnOn()
		
		self.owner:DoTaskInTime(0.6, function()
			TheSim:SetTimeScale(1) --SET THE CLIENT'S TIMESCALE BACK TO 1, BECAUSE IT WONT DO IT ON ITS OWN.
			-- !!JUST HOPE OWNER ISN'T DESPAWNED BEFORE THIS RUNS!!! OTHERWISE CLIENT WILL BE STUCK IN SLOMO FOREVER.
		end)
	end
	
	--8-15-20 LETS NOT BE AN IDIOT AND RE-CREATE THIS MENU EVERY TIME WE WANT TO OPEN IT.
	self.owner.PostGameOptions= function()
		-- self.postgameselect:Show()
		self.postgameselect = self:AddChild(self:BuildPostGameOptions())
	end
	
	
	--THE MAGIC THAT MAKES IT SHOW UP
	self.owner.ShowControlScreen = function()
		-- TheFrontEnd:PopScreen()
		TheFrontEnd:PushScreen(SMControlsScreen())
	end
	
	
	
	-- self.owner.ShowSelectScreen= function()
		-- self.owner:PushEvent("show_select_screen")
	-- end
	
	--[[
	-- Show the help text for secondary widgets, like scroll bars
	local intermediate_widgets = self:GetIntermediateFocusWidgets()
	if intermediate_widgets then
		for i,v in ipairs(intermediate_widgets) do
			if v and v ~= widget and v.GetHelpText then
				local str = v:GetHelpText()
				if str and str ~= "" then
					if v.HasExclusiveHelpText and v:HasExclusiveHelpText() then
						-- Only use this widgets help text, clear all other help text
						t = {}
						table.insert(t, v:GetHelpText())
						break
					else
						table.insert(t, v:GetHelpText())
					end
				end
			end
		end
	end
	
	
	]]
	
	-- self.owner.HUD:SetClickable(false)
	-- self.owner.HUD.tracking_mouse = false
	-- self.owner.HUD.controls.focus_forward = nil
	
	
	self.focustoggle = false
	self.owner:ListenForEvent("cornermenu_focus", function()
		-- print("CORNERMENU FOCUS", TheFrontEnd:GetFocusWidget(), TheFrontEnd:GetActiveScreen())
		-- if not self.owner.HUD.controls.foodcrafting:IsFocused()
		-- if not self.owner.HUD:IsFocused() then
		-- if not self.owner.HUD:HasInputFocus() then
			--IF WE'RE IN A DIFFERENT MENU AT THE MOMENT, DON'T PULL US AWAY
			-- return end
			
		if TheFrontEnd:GetActiveScreen() ~= self.owner.HUD then
			return end
		
		-- self.last_focus = self.cornermenu_grid.items_by_coords[1][1]
		-- self.last_focus = self.controlbtn
		-- self.cornermenu_grid.last_focus = self.controlbtn
		if self.focustoggle == false then
		-- if TheFrontEnd:GetFocusWidget() == self.owner.HUD then --"Controls" then
			-- TheFrontEnd:ClearFocus()
			self.owner.HUD.focus_forward = self.cornermenu_grid --WAIT WTF?? THIS ONE JUST WORKS?
			-- print("CORNERMENU FOCUS", TheFrontEnd:GetFocusWidget(), TheFrontEnd.tracking_mouse)
			
			self.cornermenu_grid:SetFocus(1, 1)
			-- if TheInput:ControllerAttached() then --and not TheFrontEnd.tracking_mouse then
				-- self:OnFocusMove(MOVE_DOWN, true)
			-- end
			-- TheFrontEnd:OnRawKey(MOVE_DOWN, true)
			-- TheFrontEnd:OnRawKey(MOVE_DOWN, true)
			-- TheFrontEnd:OnControl(CONTROL_NEXTVALUE, true)
			-- TheFrontEnd:OnControl(CONTROL_NEXTVALUE, true)
			-- TheFrontEnd:OnRawKey(MOVE_UP, true)
			
			-- self:OnFocusMove(MOVE_DOWN, true)
			-- TheFrontEnd:OnControl(CONTROL_FOCUS_DOWN, true)
			
			-- TheInput:OnControl(CONTROL_MOVE_DOWN, true)
			-- TheInput:OnControl(CONTROL_MOVE_DOWN, true)
			-- TheInput:OnControl(KEY_DOWN, true)
			-- TheInput:OnRawKey(CONTROL_MOVE_DOWN, true)
			
			-- TheFrontEnd:LockFocus(true)
			
			-- local intermediate_widgets = TheFrontEnd:GetIntermediateFocusWidgets()
			-- if intermediate_widgets then
				-- for i,v in ipairs(intermediate_widgets) do
					-- print("INTERMEDIATE WIDGETS", v)
					
				-- end
			-- end
			-- print("CORNERMENU FOCUS", TheFrontEnd:GetFocusWidget(), TheFrontEnd.tracking_mouse)
			
			
			-- self.cornermenu_grid.OnLoseFocus = function()
				-- print("DOUBLE DOWN ON FOCUS", TheFrontEnd:GetFocusWidget())
				-- self.cornermenu_grid:SetFocus()
			-- end
			
			self.focustoggle = true
		else --if tostring(TheFrontEnd:GetFocusWidget()) == "Controls" then
			-- print("FOCUSING ON HUD", TheFrontEnd:GetFocusWidget())
			-- self.owner.HUD:SetFocus()
			self.owner.HUD.focus_forward = nil
			TheFrontEnd:ClearFocus()
			self.focustoggle = false
		end
		
		--self.last_focus = self.menu.items[self.options_button_index]
		--[[
		local devices = TheInput:GetInputDevices()
		for i,v in ipairs(devices) do
			print("DEVICE ", v.text)
		end
		
		print("GetLastActiveControllerIndex ", TheInputProxy:GetLastActiveControllerIndex())
		TheInput:EnableAllControllers()
		]]
		-- print("GetLastActiveControllerIndex ", TheInputProxy:GetLastActiveControllerIndex())
		
	end)
			
			
	-- self.unlocktier = unlocktiernetvar:value() --REPLICA OF THE VARIABLE HELD BY HORDES.LUA
	-- self.unlocktier = 1
	--8-16-20 
	
	-- self.owner.UnlockTier= function()
		-- -- self.unlocktier = unlocktiernetvar:value()
		-- print("ATTEMPTING TO RETREIVE UNLOCKTIER FROM ANCHOR")
		-- self.unlocktier = anchor._unlockteir:value()
	-- end
	
	
	-- self.inst:ListenForEvent("endgame", function() 
		-- TheSim:SetTimeScale(0.25)
		-- print("SELF.OWNER.UPDATEBADGES! GENERAL")
		-- local GameSet = require "widgets/gameset"
		-- self.gameset = self:AddChild(GameSet(owner))
		-- self.gameset:TurnOn()
	-- end, self.owner)
	
	
	
	
	--10-17-17 ONE LAST BUTTON! THIS ONE IS TO BRING UP CONTROLS SCREEN, AND IS AVAILABLE AT ALL TIMES.
	self.controlbtn = self:AddChild(ImageButton())
	self.controlbtn:SetText(STRINGS.SMSH.UI_CONTROLS) --"Controls"
	self.controlbtn:SetScale(1.0, 1.0, 1.0)
	table.insert(self.cornermenubtns, self.controlbtn) --8-22-20 WE'RE LETTING THE GRID HANDLE FORMATTING NOW
	self.controlbtn:SetOnClick( function() 
		-- self.owner:PushEvent("controlscreendirty")
		-- TheFrontEnd:PopScreen()
		TheFrontEnd:PushScreen(SMControlsScreen())
	end)
	
	
	
	
	--9-23-17 DST- IM BACK!! A LITTLE CHARACTER-SWAP BUTTON FOR PLAYERS IN LOBBY MODE ONLY.
	if self.owner:HasTag("autospawn") then
		self.charswapbutton = self:AddChild(ImageButton())
		self.charswapbutton:SetText(STRINGS.SMSH.UI_CHANGE_CHAR) --"Change character"
		self.charswapbutton:SetScale(1.0, 1.0, 1.0)
		table.insert(self.cornermenubtns, self.charswapbutton) --8-22-20 WE'RE LETTING THE GRID HANDLE FORMATTING NOW
		self.charswapbutton:SetOnClick( function() 
			self.owner:PushEvent("show_select_screen", {teams = false})
		end)
	end
	
	
	
	--5-20-20 DISABLE MOST OF THE MENU FOR CERTAIN CONDITIONS
	local servergamemode = TUNING.SMASHUP.SERVERGAMEMODE
	local displaycontrolmenu = false
	
	--11-26-20 CHECK BY SERVERGAMEMODE INSTEAD.
	if servergamemode == 1 then --1 = ANYONES CHOICE
		displaycontrolmenu = true
	end
	
	--5-25-20 JUST A TEST
	if TheNet:GetIsServerAdmin() then
		-- print("IM AN ADMIN. SHOW ME THE MENU", self.owner:HasTag("autospawn"))
		displaycontrolmenu = true
	
	else
	
		--2-11-22 DEDICATED SERVER OWNERS KEEP FORGETTING TO SET THE RIGHT GAME SETTINGS! WE SHOULD DO SOMETHING ABOUT THAT.
		if IsDedicatedServer() then
			displaycontrolmenu = true
		end
	end
	
	
	--6-10-18 --JUST KIDDING, BACK AGAIN. GIVE HOSTS AN OPTION TO START HORDE MODE
	if self.owner:HasTag("autospawn") and displaycontrolmenu == true then
		--A SELECTION OF SINGLE PLAYER MODES--
		self.singleplayerbtn = self:AddChild(ImageButton())
		-- self.singleplayerbtn:SetText("Single Player") --11-26-20 THIS NEEDS A BETTER NAME. ITS NOT FOR ONLY ONE PLAYER
		self.singleplayerbtn:SetText(STRINGS.SMSH.UI_GAME_MODES) --"Game Modes"
		self.singleplayerbtn:SetScale(1.0, 1.0, 1.0)
		table.insert(self.cornermenubtns, self.singleplayerbtn) --8-22-20 WE'RE LETTING THE GRID HANDLE FORMATTING NOW
		self.singleplayerbtn:SetOnClick( function() 
			-- self.owner:PushEvent("show_select_screen") --NOT SO FAST! START THE GAME MODE FIRST
			local anchor = TheSim:FindFirstEntityWithTag("anchor")
			
			local text = "Select a game mode \n"
			local text = nil --WAIT WUT
			
			-- local menu_message = PopupDialogScreen( "Singleplayer", text, {
			local menu_message = PopupDialogScreen( "Singleplayer", text, { --HEY, LETS GIVE THE REDUX VERSION A SHOT
				--=="Horde Mode"==
				{text=STRINGS.SMSH.UI_GAMEMODE_HORDE, cb = function() 
					-- self.focus_forward = self.lang_grid
					TheFrontEnd:PopScreen() 
					-- self.denselectmenu:Show() --8-15-20 I MADE A SHINY NEW MENU FOR THIS
					--self.denselectmenu = self:GenerateDenSelect() --8-18-20 AND THEN I KILLED IT AND MADE A BETTER ONE
					-- self.lang_grid:SetFocus()
					-- TheFrontEnd:PushScreen(self.denselectmenu)
					-- self.denselectmenu:SetFocus()
					TheFrontEnd:PushScreen(LevelSelect())
					
					--[[
					TheFrontEnd:PushScreen(self.denselectmenu)
					
					local screen = TheFrontEnd:GetActiveScreen()
					if screen then
						screen:Enable()
					end
					
					
					]]
					
					
					
				end,
				hovertext=STRINGS.SMSH.UI_GAMEMODE_HORDE_DESC},
				--"Fight through increasing difficult waves of spiders and destroy their dens to unlock more challenges.\n (1-2 players)"
				
				--=="Vs Spider"==
				{text=STRINGS.SMSH.UI_GAMEMODE_VSAI, cb = function() 
					-- anchor.components.gamerules.cpulevel = 10 --THAT AINT CLIENT COMPATIBLE, SON
					TheFrontEnd:PopScreen() 
					-- self.vscpumenu:Show()
					TheFrontEnd:PushScreen(VsAiScreen())
				end,
				hovertext=STRINGS.SMSH.UI_GAMEMODE_VSAI_DESC},
				--"Fight an AI spider opponent at varying levels of difficulty. One spider will spawn for each player joined."
				
				--11-28-20 A NEW TEST
				-- {text="Test AI", cb = function() 
					-- local p1 = SpawnPrefab("newwilson")
					
					-- p1:AddTag("dummynpc") --9-14-17 DST TO DETIRMINE IF THE CHARACTER IS A LITERAL CHARACTER NOT CONTROLLED BY A USER
					-- p1:AddTag("customspawn")
					-- p1:AddTag("noplayeranchor")
					
					-- p1:AddComponent("aifeelings")
					-- p1.components.aifeelings.ailevel = 9
					
					-- local newbrain = require "brains/spiderfighterbrain"
					-- p1:SetBrain(newbrain)
					
					-- local x, y, z = anchor.Transform:GetWorldPosition()
					-- anchor.components.gamerules:SpawnPlayer(p1, x, y, z-0)
					
					-- TheFrontEnd:PopScreen()  --JUST CLOSE THE MENU
				-- end,
				-- hovertext="Testing."},
				--
				--=="PVP"==
				{text="PvP", cb = function() 
					TheFrontEnd:PopScreen() 
					-- self.vscpumenu:Show()
					TheFrontEnd:PushScreen(PvPScreen(self.owner))
				end,
				hovertext=STRINGS.SMSH.UI_GAMEMODE_PVP_DESC},
				
				--==Nevermind==
				{text=STRINGS.SMSH.UI_GAMEMODE_CANCEL, cb = function() 
					TheFrontEnd:PopScreen()  --JUST CLOSE THE MENU
				end,
				hovertext=STRINGS.SMSH.UI_GAMEMODE_CANCEL_DESC} --"Cancel"
				
			},
			nil, nil, "light") --BUT SET IT TO THE LIGHT THEME, I GUESS --OH HEY ITS JUST THE OLD THEME LOL OK. THIS WORKS
			
			--10-6-20 IF WE'RE CLEVER ABOUT IT, WE MIGHT BE ABLE TO MAKE THIS CHANGE EXTERNALLY...
			-- for k, v in ipairs(menu_message.buttons) do
			for k, v in ipairs(menu_message.menu.items) do
				-- print("at least i exist", v.widget, v.text)
				-- v:SetOnGainFocus( function() print("doody") end ) --self:SetMenuIndex(k)
				
				-- if v.hovertext then
				if menu_message.buttons[k].hovertext then
					v:SetOnGainFocus( function() 
						-- print(menu_message.buttons[k].hovertext) 
						-- menu_message.text = menu_message.buttons[k].hovertext
						menu_message.text:SetString(menu_message.buttons[k].hovertext)
					end )
					
					-- v.ongainfocus = function()
						-- --OH I GUESS THIS WOULD HAVE WORKED TOO
					-- end
					-- v.OnLoseFocus = function()
						-- -- SOMEHOW THIS ONE STILL WORKS?
					-- end
				end
			end
				
				
			TheFrontEnd:PushScreen( menu_message )
			
			--10-6-20
			menu_message.text:SetString(STRINGS.SMSH.UI_SELECT_MODE) --"Select a Game Mode..."
			
		end)
	
	
		
		--9-29-20 LOCAL MULTIPLAYER IS REALLY AN UNFINISHED FEATURE AT BEST. SO LETS KEEP IT DISABLED UNLESS SETTINGS SAY OTHERWISE
		if TUNING.SMASHUP.ENABLELOCALPLAY == 2 and TheWorld.ismastersim then
			--7-3-18  --HOW ABOUT HANDING THE KEYBOARD TO A LOCAL BUD? DIDN'T EXPECT TO BE PUTTING THIS ONE IN HERE, HONESTLY
			self.localbudbutton = self:AddChild(ImageButton())
			-- self.localbudbutton:SetHAnchor(ANCHOR_LEFT)
			-- self.localbudbutton:SetVAnchor(ANCHOR_TOP)
			-- self.localbudbutton:SetPosition(125, -270, 0) --75
			table.insert(self.cornermenubtns, self.localbudbutton) --8-22-20 WE'RE LETTING THE GRID HANDLE FORMATTING NOW
			-- self.localbudbutton:SetClickable(true)
			
			self.localbudbutton:SetText(STRINGS.SMSH.UI_LOCAL_VS) --"Local VS"
			self.localbudbutton:SetScale(1.0, 1.0, 1.0)
			
			self.localbudbutton:SetOnClick( function() 
				-- self.owner:PushEvent("show_select_screen")
				local anchor = TheSim:FindFirstEntityWithTag("anchor")
				-- anchor.components.gamerules:SpawnLocalP2()
				
				--BRING UP AN INTRO SCREEN FIRST, TELLING THEM HOW IT WORKS.
				-- local text = "Play with a second person, sharing one keyboard! If it's big enough. \n"
				-- text = text .. "Player 2 will use the Arrow keys to move \n"
				-- text = text .. "And the [4,5,6] Keys on the num-pad to attack. \n"
				-- text = text .. "Got it? \n"
				local text = STRINGS.SMSH.UI_LOCAL_MULTIPLAYER_DESC
				
				local vs_message = PopupDialogScreen( STRINGS.SMSH.UI_LOCAL_MULTIPLAYER, text, {
				-- local vs_message = PopupDialogScreenTall( "Local Multiplayer", text, {
					{text=STRINGS.SMSH.UI_GAMEMODE_COOP_VS, --"VS Mode"
					cb = function() 
						-- self.owner:PushEvent("select_local_p2") --7-3-18  --IF THIS WORKS ON THE FIRST GO, IM GONNA LOSE IT  --!!! I JUST LOST IT - I GOT IT RIGHT FIRST TRY
						self.owner:PushEvent("set_local_p2") --THIS ONE SETS IT UP WITHOUT SHOWING THE ACTUAL SCREEN
						local anchor = TheSim:FindFirstEntityWithTag("anchor")
						anchor.components.gamerules.localp2mode = true
						-- anchor.components.gamerules:StageReset()
						TheFrontEnd:PopScreen() 
					end},
					
					{text=STRINGS.SMSH.UI_GAMEMODE_COOP_HORDE, --"Co-Op VS Horde"
					cb = function() 
						-- self.owner:PushEvent("select_local_p2")
						self.owner:PushEvent("set_local_p2") --THIS ONE SETS IT UP WITHOUT SHOWING THE ACTUAL SCREEN
						local anchor = TheSim:FindFirstEntityWithTag("anchor")
						-- anchor.components.gamerules.hordemode = true --GAME WILL GO INTO HORDE MODE ON THE NEXT ROUND
						anchor.components.gamerules.localp2mode = true --THIS IS GETTING A LITTLE TANGLED, NOW THERE ARE LIKE 3 WAYS TO INITIATE LOCAL P2 MODE, BUT OH WELL
						anchor.components.hordes:PrepareHordeMode() --GONNA TRY SOME DIFFERENT VERSIONS --NNNOPE. THATS WORSE IN EVERY WAY
						TheFrontEnd:PopScreen() 
					end},
					
					{text=STRINGS.SMSH.UI_GAMEMODE_CANCEL, cb = function() --"Nevermind"
						TheFrontEnd:PopScreen()  --JUST CLOSE THE MENU
					end}
				} )
				
				TheFrontEnd:PushScreen( vs_message )
			end)
		end
	end
	
	
	
	--[[ 9-29-20 WE'RE REPLACING THIS WITH THE "END GAME" BUTTON IN THE CHARACTER SELECT SCREEN
	--THIS MENU IS AVAILABLE EVEN OUTSIDE OF LOBBY MODE. BUT ONLY UNDER CERTAIN CONDITIONS/SETTINGS
	--THERE IS A DUPLICATE MENU IN FIGHTERSELECT, ITS SO SMALL I COULDNT BE BOTHERED TO MAKE A UNIVERSAL ONE
	if (servergamemode == 1) or (servergamemode == 2 and TheNet:GetIsServerAdmin()) then
		--8-22-20 A SCREEN TO CHANGE THE SERVER'S GAME MODE
		self.gamemodebtn = self:AddChild(ImageButton())

		table.insert(self.cornermenubtns, self.gamemodebtn) --8-22-20 WE'RE LETTING THE GRID HANDLE FORMATTING NOW
		self.gamemodebtn:SetClickable(true)
		self.gamemodebtn:SetText("Change GameMode")
		self.gamemodebtn.text:SetScale(.85)
		
		self.gamemodebtn:SetOnClick( function() 
			-- local anchor = TheSim:FindFirstEntityWithTag("anchor")
			-- anchor.components.gamerules:SpawnLocalP2()
			
			--
			--BRING UP AN INTRO SCREEN FIRST, TELLING THEM HOW IT WORKS.
			local text = "All players on the server will be forced to switch to this game mode! \n"
			text = text .. "Change will take place after the current round ends \n"
			if TheWorld.ismastersim then
				local anchor = TheSim:FindFirstEntityWithTag("anchor")
				text = text .. "Current GameMode:".. anchor.components.gamerules.gamemode
			end
			
			local message = PopupDialogScreen( "Change Server-wide Gamemode", text, {
			-- local message = PopupDialogScreenTall( "Local Multiplayer", text, {
				{text="PvP", cb = function() 
					TheNet:Announce(self.owner:GetDisplayName().." changed the game-mode to PVP")
					SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setservergamemode"], "PVP") 
					TheFrontEnd:PopScreen() 
				end},
				
				{text="Horde", cb = function() 
					TheNet:Announce(self.owner:GetDisplayName().." wants to set the game-mode to Horde")
					self:GenerateDenSelect()
					TheFrontEnd:PopScreen() 
				end},
				
				{text="VS-AI", cb = function() 
					TheNet:Announce(self.owner:GetDisplayName().." wants to set the game-mode to VS-AI")
					TheFrontEnd:PopScreen() 
					self.vscpumenu:Show() 
				end},
				
				{text="Nevermind", cb = function() 
					TheFrontEnd:PopScreen()  --JUST CLOSE THE MENU
				end}
			} )
			TheFrontEnd:PushScreen( message )
		end)
	end
	]]
	
	
	
	
	--8-22-20 LETS MAKE OUR CORNER MENU A LITTLE CLEANER
	self.cornermenu_grid = self:AddChild(Grid())
	self.cornermenu_grid:SetHAnchor(ANCHOR_LEFT)
	self.cornermenu_grid:SetVAnchor(ANCHOR_TOP)
	self.cornermenu_grid:SetPosition(125, -45, 0)
	-- self.cornermenubtns = {}
    -- self.cornermenu_grid:SetPosition(-125, 90)
    -- for _,id in pairs(LOC.GetLanguages()) do
        -- table.insert(self.langButtons, self:_BuildLangButton(button_width, button_height, id))
    -- end
	local button_width = 300
    local button_height = 60
	-- table.insert(self.cornermenubtns, self.controlbtn) -- WE'LL LET THE LOGIC ABOVE HANDLE THIS
    
	
	
	
	--10-17-17 OKAY, JUST GIVE THEM A LIL HINT OF THE CONTROLS ON SCREEN
	
	self.hinter = self:AddChild(Text(BODYTEXTFONT, 40))
    self.hinter:SetPosition(0, -(RESOLUTION_Y/4), 0)
	self.hinter:SetScale(1,1,1)
    self.hinter:SetString(STRINGS.SMSH.UI_CONTR_HINT) --(WASD: Movement) - (N: Attack) - (M: Special)
	
	self.hinter:SetVAnchor(ANCHOR_BOTTOM)
    self.hinter:SetHAnchor(ANCHOR_MIDDLE)
	self.hinter:SetPosition(0, 45, 0)
	
	self.hinter:Hide() --HIDE IT FIRST. GIVE IT A SEC TO SHOW UP
	
	self.owner:DoTaskInTime(4, function()
		self.hinter:Show()
	end)
	
	self.owner:DoTaskInTime(8.5, function()
		self.hinter:Hide()
	end)
	
	
	
	--8-21-20 A SPECIAL BUTTON AT THE BOTTOM OF THE SCREEN THAT ANYONE CAN PRESS TO "START" THE GAME
	self.startgamebtn = self:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
	
	--I WANNA SNEAK THE START BUTTON INTO THE GRID SO CONTROLLERS CAN PRESS IT
	table.insert(self.cornermenubtns, self.startgamebtn)
	self.cornermenu_grid:FillGrid(1, button_width, button_height, self.cornermenubtns)
	
	
	
	self.startgamebtn:SetHAnchor(ANCHOR_MIDDLE)
	self.startgamebtn:SetVAnchor(ANCHOR_BOTTOM)
	self.startgamebtn:SetPosition(0, 110, 0)
	self.startgamebtn:SetClickable(false)
	self.startgamebtn:SetText(STRINGS.SMSH.UI_INITIALIZING) --"Initializing..."
	self.startgamebtn.image:SetScale(1.3, 1.0, 1.0)
	self.startgamebtn.text:SetScale(.9, .9, .9)
	self:MoveToBack()
	-- local btntint = 0.7
	-- self.startgamebtn:SetImageDisabledColour(btntint,btntint,btntint,1)
	
	self.startgamebtn:SetOnClick( function() 
		-- self.owner:PushEvent("controlscreendirty")
		TheNet:Announce(self.owner:GetDisplayName().." "..STRINGS.SMSH.UI_NEWSESSIOIN) --"started the game"
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["gen_menu_handler"], "begin_session") 
	end)
	
	
	--RPC FUNCTION CALLED WHENEVER THIS VALUE UPDATES
	self.owner.EnableSessionStart= function()
		--OK MY CRAPTOP REALLY HAS TROUBLE IDENTIFYING THE ANCHOR IN TIME. BUT NORMAL LAPTOP WORKS FINE
		local anchor = TheSim:FindFirstEntityWithTag("anchor")
		if not anchor then
			return end --CRAPTOP WILL JUST HAVE TO WAIT. THATS OK, THIS BUTTON AUTO-UPDATES PERIODICALLY. CANT SAY THE SAME FOR EVERYTHING ELSE THOUGH
		local ready = anchor._sessionready:value()
		-- print("SESSION READY?", ready)
		if ready then 
			--1-3-22 OKAY, HAVING RANDOS CLICK START WHEN NO ONE IS READY IS ANNOYING. GIVE ADMINS SPECIAL PERMISSION
			if (servergamemode == 1) or (TheNet:GetIsServerAdmin()) or IsDedicatedServer() then
				self.startgamebtn:SetClickable(true)
				self.startgamebtn:SetText(STRINGS.SMSH.UI_CLICK_START) --"CLICK TO START"
				self.owner.jumbotronheader:set(STRINGS.SMSH.UI_READY) --"Ready to begin. Click Start"
				self.startgamebtn:OnEnable()
				self.startgamebtn.focus_forward = nil
			else
				self.startgamebtn:SetText(STRINGS.SMSH.UI_HOST_START) --"Waiting for host to start"
				self.startgamebtn.focus_forward = self.controlbtn
			end
		else
			self.startgamebtn:SetClickable(false)
			self.startgamebtn:SetText(STRINGS.SMSH.UI_WAITING) --"Waiting for players..."
			self.startgamebtn:OnDisable() --TO SET THE TINT COLOR
			self.owner.jumbotronheader:set(" ") --BLANK IT OUT
			self.startgamebtn.focus_forward = self.controlbtn
		end
	end
	
	--THE "AUTOSPAWN" TAG IS ONLY ON PLAYERS IN LOBBY MODE!! THIS BUTTON SHOULD ONLY EVER SHOW UP IN LOBBY
	if not self.owner:HasTag("autospawn") then
		self.startgamebtn:Hide()
	else
		self.owner.EnableSessionStart() --UPDATE IT ONCE
	end
	
	
	
	-- if self.show_language_options then
        -- menu_items["languages"] = self.panel_root:AddChild(self:_BuildLevelSelect())
    -- end
	-- self.denselectmenu = self:AddChild(self:_BuildLevelSelect()) --YEA IM SURE THIS WILL GO OFF WITHOUT A HITCH. REAL SMOOTH
	-- self.denselectmenu:Hide() --NO WE CANT JUST HIDE/UNHIDE THIS BECAUSE IT WONT RECOGNIZE UPDATED UNLOCKTIER UPGRADES
	--WE HAVE TO KILL IT AND RECREATE IT EVERY TIME
	-- self.denselectmenu = self:GenerateDenSelect()
	-- TheFrontEnd:PopScreen(self.denselectmenu)
	-- self.denselectmenu = nil
	-- self:GenerateDenSelect()
	
	-- self.vscpumenu = self:AddChild(self:_BuildAIvs()) --1-20-22 TURNING THIS INTO A SCREEN
	-- self.vscpumenu:Hide()
	
	-- self.postgameselect = self:AddChild(self:BuildPostGameOptions()) --1-24-22 WHY DO WE DO THIS
	-- self.postgameselect:Hide()
	
	
	self.default_focus = self.cornermenu_grid
	self.focus_forward = self.cornermenu_grid
end)


--8-18-20 RISE MY NEW CLONE. TO RECOGNIZE NEW NETVARS ATTACHED TO THE ANCHOR
function SmashMenus:GenerateDenSelect()
	-- self.denselectmenu = self:AddChild(self:_BuildLevelSelect())
	-- self.denselectmenu:Hide() --IS THIS HOW IM SUPPOSED TO DO IT THOUGH??
	-- self:RemoveChild(self.denselectmenu) --WILL THIS REMOVE EVERYTHING?
	self.denselectmenu:Kill() --KILL THE OLD ONE
	self.denselectmenu = self:AddChild(self:_BuildLevelSelect()) --MAKE A NEW ONE
	return self.denselectmenu
	-- return self:AddChild(self:_BuildLevelSelect())
end



--8-4-20 STEPPING THINGS UP A NOTCH FOR THE HORDE MODE
--AND BY THAT I MEAN STEALING KLEIS NEW IMPROVED MENU BUILDING FUNCTIONS



local function BuildSectionTitle(text, region_size)
    local title_root = Widget("title_root")
    -- local title = title_root:AddChild(Text(HEADERFONT, 70))
	local title = title_root:AddChild(Text(CHATFONT_OUTLINE, 70))
	
    title:SetRegionSize(region_size, 70)
    title:SetString(text)
    title:SetColour(UICOLOURS.GOLD_SELECTED)

    local titleunderline = title_root:AddChild( Image("images/frontend_redux.xml", "achievements_divider_top.tex") )
    titleunderline:SetScale(1.5, 1.5)
    titleunderline:SetPosition(0, -20)

    return title_root
end



--OK BUT I WANT SPECIAL BUTTONS. IMAGE BUTTONS ARE ALWAYS FUN.
-- self.fixed_root:AddChild(ImageButton("images/avatars.xml", "avatar_bg.tex"))
	-- local denbutton = self.fixed_root:AddChild(ImageButton("images/avatars.xml", "avatar_bg.tex"))
	
--8-8-20 FORGET THIS. TOO COMPLICATED. DOING THINGS THE STUPID WAY LIKE I ALWAYS DO.

function SmashMenus:_BuildLangButton(densize, level, locked)
    
	local puppet_root = self:AddChild(Widget("puppet_root"))
	puppet_root:SetPosition(0, -250)
	
	local frame = puppet_root:AddChild(Widget("frame"))
    -- frame.bg = frame:AddChild(Image(GetPlayerPortraitAtlasAndTex()))
	frame.bg = frame:AddChild(ImageButton(GetPlayerPortraitAtlasAndTex()))
    frame:SetScale(.85)
	-- self.frame.bg:SetHoverText( GetSkinName(item_key), { font = UIFONT, offset_x = 0, offset_y = 40, colour = GetColorForItem(item_key) } )
	-- frame.bg:SetHoverText( "TEST1", { font = UIFONT, offset_x = 0, offset_y = 40, colour = { 0.718, 0.824, 0.851, 1 }}) --, colour = GetColorForItem(item_key) } )
	frame.bg:SetClickable(true)
	
	
	
	
	local puppet = puppet_root:AddChild(Puppet()) --CORNER_DUDE'S DISTANT COUSIN
    puppet:SetScale(1.5)
    puppet:SetClickable(false)
    puppet:SetPosition(0, -40) -- -70
    puppet:AddShadow()
	--self.puppet:SetVAlign(ANCHOR_MIDDLE)
	
	--MAKE THE STAGE UNSELECTABLE IF NOT UNLOCKED YET
	if locked then --"LOCKED"
		frame.bg:SetClickable(false)
		puppet.animstate:SetMultColour(0.3,0.3,0.3,1)
		puppet:SetClickable(true) --SO HOVERTEXT WORKS
		puppet:SetHoverText( STRINGS.SMSH.UI_LOCKED, { font = UIFONT, offset_x = 0, offset_y = 40, colour = { 0.718, 0.824, 0.851, 1 }}) --"LOCKED"
	end
	
	-- puppet_root.OnGainFocus = function()
		-- print("doo doo")
		-- puppet:SetScale(1.6)
    -- end
    -- puppet_root.OnLoseFocus = function()
        -- puppet:SetScale(1.5)
    -- end
	
	
	local playername = puppet_root:AddChild(Text(CHATFONT_OUTLINE, 40))
    playername:SetPosition(0, -120)
    playername:SetHAlign(ANCHOR_MIDDLE)
	-- playername:SetString(btntext)
	playername:SetString(STRINGS.SMSH.UI_TIER..level) --"TIER "
	
	-- self.puppet.animstate:SetBank("wilson")
	puppet.animstate:SetBank("spider_cocoon")
	puppet.animstate:SetBuild("spider_cocoon")
	puppet.animstate:PlayAnimation(densize, true) --"cocoon_medium"
	puppet.animstate:HideSymbol("bedazzled_flare") --9-7-21 WHY IS THIS ON BY DEFAULT >:(
	
	
	frame.bg:SetOnClick(function()
        local anchor = TheSim:FindFirstEntityWithTag("anchor")
		-- anchor.components.gamerules.hordemode = true
		-- anchor.components.hordes:StartHordeMode()
		-- anchor.components.hordes:NextWave()
		-- print("HORDE BUTTON PRESSED")
		--LOL NOT QUITE
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["gen_menu_handler"], "horde")
		
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setservergamemode"], "HORDE") 
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["gen_menu_handler"], "horde"..level) --THIS NO LONGER AUTO-STARTS WHEN CLICKED. NEEDS A BEGIN SESSION
		print("CLICKING THE DEN BUTTON! TWO RPC HANDLERS ", level)
		
		-- self.denselectmenu:Hide() --THEN HIDE THE MENU
		if self.denselectmenu then
			self.denselectmenu:Kill() --9-27-20 THE CANCEL BUTTON USED TO DO THIS, BUT WE KILLED THAT BUTTON
		end
    end)
	
    return puppet_root
end


function SmashMenus:_BuildLevelSelect()
    local languagesRoot = Widget("ROOT")
	
	--8-18-20 CLIENTSIDE ISNT SO GOOD AT FINDING THE ANCHOR
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	if not anchor then
		return languagesRoot --IF WE CANT FIND THE ANCHOR, JUST RETURN AN EMPTY ROOT
	end
    
    languagesRoot:SetPosition(0,0)
	--CENTERED PLEASE
	languagesRoot:SetHAnchor(ANCHOR_MIDDLE)
	languagesRoot:SetVAnchor(ANCHOR_MIDDLE)
    
    local button_width = 430
    local button_height = 45

    -- self.langtitle = languagesRoot:AddChild(BuildSectionTitle(STRINGS.UI.OPTIONS.LANG_TITLE, 200))
    -- self.langtitle:SetPosition(92, 160)
	
	self.dentitle = languagesRoot:AddChild(BuildSectionTitle("LEVEL SELECT", 800))
    self.dentitle:SetPosition(0, 320)

    self.langButtons = {}

    self.lang_grid = languagesRoot:AddChild(Grid())
    -- self.lang_grid:SetPosition(-125, 90)
    -- for _,id in pairs(LOC.GetLanguages()) do
        -- table.insert(self.langButtons, self:_BuildLangButton(button_width, button_height, id))
    -- end
	
	local button_width = 300
    local button_height = 45
	
	--8-18-20 THIS IS WHERE WE PRY THE UNLOCKTEIR FROM THE ANCHOR. HOPEFULLY THIS UPDATES ACCURATELY CLIENTSIDE
	local anchor = TheSim:FindFirstEntityWithTag("anchor")
	local unlocktier = anchor._unlockteir:value()
	-- print("THE UNLOCK TIER IS", unlocktier)
	
	self.lang_grid:SetPosition(-300, 30)
	table.insert(self.langButtons, self:_BuildLangButton("cocoon_small", "1", false))
	table.insert(self.langButtons, self:_BuildLangButton("cocoon_medium", "2", (unlocktier < 2)))
	table.insert(self.langButtons, self:_BuildLangButton("cocoon_large", "3", (unlocktier < 3)))
    self.lang_grid:FillGrid(3, button_width, button_height, self.langButtons)
    
    languagesRoot.focus_forward = self.lang_grid --SO FOCUSING ON THIS CHILD WILL SET THE FOCUS TO THE GRID (I THINK)
	
	--self.lang_grid:SetFocus() --1-18-22
	
	--YOU KNOW, SOMETIMES PLAYERS CAN BE SOFTLOCKED BY CANCELING DEPENDING ON WHEN THE PLAYER CLICKS THIS
	--SINCE WE ADDED THE END-GAME BUTTON TO THE CHAR SELECT SCREEN, LETS JUST GET RID OF THIS ONE TO PREVENT SHENANIGAINS
	--[[
	--HAVE A CANCEL BUTTON  --MAYBE A SILLY BUTTON
	self.cancelbtn = languagesRoot:AddChild(ImageButton("images/global_redux.xml", "button_carny_xlong_normal.tex", "button_carny_xlong_hover.tex", "button_carny_xlong_disabled.tex", "button_carny_xlong_down.tex"))
        self.cancelbtn.image:SetScale(.7)
        self.cancelbtn:SetFont(CHATFONT)
	-- self.cancelbtn = languagesRoot:AddChild(Button())
	self.cancelbtn:SetHAnchor(ANCHOR_MIDDLE)
	self.cancelbtn:SetVAnchor(ANCHOR_MIDDLE)
	self.cancelbtn:SetPosition(0, -220, 0)
	self.cancelbtn:SetClickable(true)
	
	self.cancelbtn:SetText("Cancel")
	-- self.cancelbtn:SetScale(1.2, 1.2, 1.2)
	
	self.cancelbtn:SetOnClick( function() 
		-- self.denselectmenu:Hide()
		-- TheFrontEnd:PopScreen(self.denselectmenu)
		-- self.denselectmenu:Close() --WE JUST WANT IT GONE SO WE CAN REGENERATE IT
		-- self.denselectmenu:Hide() --IS THIS HOW IM SUPPOSED TO DO IT THOUGH??
		-- self:RemoveChild(self.denselectmenu) --SO WILL THIS CLEAN IT ALL UP PROPERLY THOUGH?
		
		-- for i,v in ipairs(self.langButtons) do
            -- v.cb() --THE HECK IS CB??
        -- end
		self.denselectmenu:Kill() --DIE
	end)
	]]

    return languagesRoot
end



--8-19-20 LEVEL SELECT LOOKS GREAT, SO LETS DO THE SAME FOR VS-AI
--[[
function SmashMenus:_BuildAIvs()
    local vscpu_root = Widget("ROOT")
	
	
	-- local bg = vscpu_root:AddChild(TEMPLATES.CurlyWindow(130, 150, 1, 1, 68, -40))
	-- bg.fill = bg:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex"))
	-- local bgframe = self:AddChild(TEMPLATES.CurlyWindow(130, 150)) --HEY, THIS ISNT THE SAME THEME??
	 local bgframe = vscpu_root:AddChild(Image("images/fepanels.xml", "wideframe.tex")) -- I GUESS THIS WAS THE "DARK" THEME BACK THEN
	bgframe:SetScale(0.76, .9)
	local bg = vscpu_root:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex"))
	bg:SetScale(1.0, .90)
	-- bg:SetPosition(8, 12)
	
	-- frame:GetAnimState():SetBuild("accountitem_frame") -- use the animation file as the build, then override it
    -- frame:GetAnimState():SetBank("accountitem_frame") -- top level symbol from accountitem_frame
    -- self:_HideExtraLayers() -- only show these layers when requested.
	
	local frame = vscpu_root:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
	 frame:SetScale(1.3)
	frame:SetPosition(-200, 0)
	
	
	--IMPORTANT!!!
	--self.menu = self.root:AddChild(TEMPLATES.StandardMenu(menu_items, 65, nil, nil, false))
    
	
	-- local frame = vscpu_root:AddChild(Widget("frame"))
	-- frame.bg = frame:AddChild(ImageButton(GetPlayerPortraitAtlasAndTex()))
    -- frame:SetScale(.65)
	-- frame:SetPosition(-300, -40)
	
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
    -- vscpu_root.spinbg:MoveToBack()
	vscpu_root.spinbg:SetPosition(100,0)
	vscpu_root.spinbg:SetTint(0,0,0,.75) --(unpack(normal_list_item_bg_tint))
	
	
	
	-- local text = "difficulty"														--text, min, max, label_width, widget_width, height, spacing, CHATFONT, 20
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
	
	
	
    vscpu_root:SetPosition(0,0)
	--CENTERED PLEASE
	vscpu_root:SetHAnchor(ANCHOR_MIDDLE)
	vscpu_root:SetVAnchor(ANCHOR_MIDDLE)
    
    local button_width = 430
    local button_height = 45

    -- self.langtitle = languagesRoot:AddChild(BuildSectionTitle(STRINGS.UI.OPTIONS.LANG_TITLE, 200))
    -- self.langtitle:SetPosition(92, 160)
	
	self.dentitle = vscpu_root:AddChild(BuildSectionTitle("AI DIFFICULTY", 800))
	self.dentitle:SetScale(0.6, 0.6)
    self.dentitle:SetPosition(0, 120)

    vscpu_root.focus_forward = vscpu_root.difficultyspinner
	
	--IM NOT GONNA MAKE A GRID FOR JUST TWO BUTTONS, RIGHT?
	self.startbtn = vscpu_root:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
	self.startbtn.image:SetScale(.7)
    self.startbtn:SetFont(CHATFONT)
	self.startbtn:SetHAnchor(ANCHOR_MIDDLE)
	self.startbtn:SetVAnchor(ANCHOR_MIDDLE)
	self.startbtn:SetPosition(120, -100, 0) --75
	self.startbtn:SetClickable(true)
	
	self.startbtn:SetText(STRINGS.SMSH.UI_OK) --"OK"
	-- self.startbtn:SetScale(0.8, 1.0, 1.0)
	
	self.startbtn:SetOnClick( function() 
		-- self.owner:PushEvent("show_select_screen")
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["set_cpu_lvl"], difvalue) 
		-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["gen_menu_handler"], "vs_harold") 
		-- self.owner:PushEvent("show_select_screen") 
		SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setservergamemode"], "VS-AI") 
		self.vscpumenu:Hide()
	end)
	
	
	--HAVE A CANCEL BUTTON  --MAYBE A SILLY BUTTON
	self.cancelbtn = vscpu_root:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
        self.cancelbtn.image:SetScale(.7)
        self.cancelbtn:SetFont(CHATFONT)
	-- self.cancelbtn = vscpu_root:AddChild(Button())
	self.cancelbtn:SetHAnchor(ANCHOR_MIDDLE)
	self.cancelbtn:SetVAnchor(ANCHOR_MIDDLE)
	self.cancelbtn:SetPosition(-100, -100, 0)
	self.cancelbtn:SetClickable(true)
	
	self.cancelbtn:SetText(STRINGS.SMSH.UI_CANCEL) --"Cancel"
	-- self.cancelbtn:SetScale(1.2, 1.2, 1.2)
	
	self.cancelbtn:SetOnClick( function() 
		self.vscpumenu:Hide()
	end)

    return vscpu_root
end
]]





--8-15-20
function SmashMenus:BuildPostGameOptions()
	local text = nil
		
	local menu_message = PopupDialogScreen( "Wave Complete", text, { --HEY, LETS GIVE THE REDUX VERSION A SHOT
		
		--[[
		{text="Retry", cb = function() 
			SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["gen_menu_handler"], "retry_horde") 
		end},
		
		{text="Change Fighter", cb = function() 
			self.postgameselect:Hide()
			-- SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["gen_menu_handler"], "retry_horde") 
			self.owner:PushEvent("show_select_screen") 
		end},
		]]
		
		{text=STRINGS.SMSH.UI_QUIT, cb = function()  --"Quit"
			SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["gen_menu_handler"], "quit_horde")
			SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["setservergamemode"], "PRACTICE") --10-3-20 
			-- TheFrontEnd:PopScreen()  --NO THIS DELETES THE ENTIRE HUD
			self.postgameselect:Hide()
		end},
		
		{text=STRINGS.SMSH.UI_LEVEL_SELECT, cb = function() --"Level Select"
			--JUST KNOW, IF THEY CLICK CANCEL HERE... THEYRE BONED
			-- self.denselectmenu = self:GenerateDenSelect()
			-- self.postgameselect:Hide()
			TheFrontEnd:PopScreen() 
			TheFrontEnd:PushScreen(LevelSelect())
		end}
		
	},
	nil, nil, "light")
	
	-- self.cancelbtn:SetOnClick( function() 
		-- self.denselectmenu:Hide()
	-- end)

    return menu_message
end




return SmashMenus
