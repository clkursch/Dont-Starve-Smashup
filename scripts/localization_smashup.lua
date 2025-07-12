local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS 


local currloc = GLOBAL.GetCurrentLocale()
local setlanguage = GLOBAL.TUNING.SMASHUP.LANGUAGE
--SNAPPING TILLS HANDLES THIS REALLY WELL
if setlanguage == "auto" and (currloc ~= nil and currloc.code == "zh") then
	setlanguage = "sch"
end


--9-1-21 SOME PRE-COMPUTED STRINGS FOR THE CONTROLS DISPLAY BASED ON THE CURRENT CONTROLS
local KeyTable = STRINGS.UI.CONTROLSSCREEN.INPUTS[1]
local MOVEMENTKEYS = KeyTable[GLOBAL.KEY_W]..KeyTable[GLOBAL.KEY_A]..KeyTable[GLOBAL.KEY_S]..KeyTable[GLOBAL.KEY_D]
local JUMPKEY = KeyTable[GLOBAL.KEY_SPACE]
local ATKKEY = KeyTable[GLOBAL.KEY_N]
local SPCKEY = KeyTable[GLOBAL.KEY_M]
local GRABKEY = KeyTable[GLOBAL.KEY_PERIOD]
local SMASHKEY = KeyTable[44]
local BLOCKKEY = KeyTable[GLOBAL.KEY_LSHIFT]




----BASE ENGLISH----
--STAGE GEN--
STRINGS.SMSH = {}
STRINGS.SMSH.STAGEGEN_MSG = "First-time stage detected \n".."A restart is required to finish the stage setup. \n".."Server will auto-restart in 5 seconds... \n"
STRINGS.SMSH.HUNT_MSG_1 = "Almost Ready..."
STRINGS.SMSH.HUNT_MSG_2 = "Got it"

--JUMBOTRON & ANNOUNCEMENTS--
STRINGS.SMSH.JUMBO_SPECTATE = "Spectate-Mode. Waiting for match to end..."
STRINGS.SMSH.JUMBO_WAITING4PLYRS = "Waiting for other players..."
STRINGS.SMSH.JUMBO_PLAYERS_LEFT = "Players left. Entering practice mode"
STRINGS.SMSH.JUMBO_DROPOUT = "MISSING PLAYER DETECTED!"
STRINGS.SMSH.JUMBO_STARTING_ANYWAY = "STARTING WITHOUT THEM"
STRINGS.SMSH.JUMBO_NOT_ENOUGH_PLAYERS = "Too Few Players To Start - Retrying"
STRINGS.SMSH.JUMBO_STARTING_W_PARTIAL = "Starting match with spectators"
STRINGS.SMSH.JUMBO_NO_SELECTION = "No Selection Made"
STRINGS.SMSH.JUMBO_SELECT_TIMER = "10 Seconds Remaining"
STRINGS.SMSH.JUMBO_NEW_MATCH = "Starting new match."
STRINGS.SMSH.JUMBO_WINNER = "WINNER: "
STRINGS.SMSH.JUMBO_GAMESET = "GAME SET"

--HORDE MODE--
STRINGS.SMSH.JUMBO_WAVE = "WAVE "
STRINGS.SMSH.JUMBO_NEW_UNLOCK = "New Fighter Unlocked!"
STRINGS.SMSH.JUMBO_HORDE_WIN = "HORDE COMPLETE!"
STRINGS.SMSH.JUMBO_HORDE_FAIL = "FAILED..."

--SMASH MENUS--
STRINGS.SMSH.UI_SELECT_P1 = "Select Player 1's Character"
STRINGS.SMSH.UI_SELECT_P2 = "Select Player 2's Character"
STRINGS.SMSH.UI_SELECT_CHAR = "Select Character"
STRINGS.SMSH.UI_TIME_UP = "Time Expired"
STRINGS.SMSH.UI_READY = "Ready to begin. Click Start"
STRINGS.SMSH.UI_CONTROLS = "Settings" --STRINGS.UI.MAINSCREEN.CONTROLS --"Controls"
STRINGS.SMSH.UI_CHANGE_CHAR = STRINGS.UI.HELP.CHANGECHARACTER --"Change character"

STRINGS.SMSH.UI_GAME_MODES = "Game Modes"
STRINGS.SMSH.UI_SELECT_MODE = "Select a Game Mode..."
STRINGS.SMSH.UI_GAMEMODE_HORDE = "Horde Mode"
STRINGS.SMSH.UI_GAMEMODE_VSAI = "Vs Spider"
STRINGS.SMSH.UI_GAMEMODE_CANCEL = "Nevermind"

STRINGS.SMSH.UI_GAMEMODE_HORDE_DESC = "Fight through increasing difficult waves of spiders and destroy their dens to unlock more challenges.\n (1-2 players)"
STRINGS.SMSH.UI_GAMEMODE_VSAI_DESC = "Fight an AI spider opponent at varying levels of difficulty. One spider will spawn for each player joined."
STRINGS.SMSH.UI_GAMEMODE_PVP_DESC = "Fight other players! Solo, or in teams (2+ players)"
STRINGS.SMSH.UI_GAMEMODE_CANCEL_DESC = STRINGS.UI.CHARACTERSELECT.CANCEL

STRINGS.SMSH.UI_PVP_FIGHTERS = "Fighters"
STRINGS.SMSH.UI_PVP_LIVES = "Lives"
STRINGS.SMSH.UI_PVP_TEAMSETTINGS = "Team Settings"
STRINGS.SMSH.UI_PVP_TEAMS = "Teams"
STRINGS.SMSH.UI_PVP_TEAMS_D3 = "On for 4+ players"
STRINGS.SMSH.UI_PVP_TEAMS_H1 = "Every man for themselves"
STRINGS.SMSH.UI_PVP_TEAMS_H2 = "Fighters will be grouped into 2 teams"
STRINGS.SMSH.UI_PVP_TEAMS_H3 = "Teams will be enabled as long as there are at least 4 players"
STRINGS.SMSH.UI_PVP_TEAMSELECTION = "Team Selection"
STRINGS.SMSH.UI_PVP_TEAMSELECTION_D1 = "Select Teams"
STRINGS.SMSH.UI_PVP_TEAMSELECTION_D2 = "Random Teams"
STRINGS.SMSH.UI_PVP_TEAMSELECTION_H1 = "Players may choose their own team"
STRINGS.SMSH.UI_PVP_TEAMSELECTION_H2 = "Teams are randomly assigned"
STRINGS.SMSH.UI_PVP_TEAMSIZECR = "Team Size Correction"
STRINGS.SMSH.UI_PVP_TEAMSIZECR_D1 = "Auto Balance"
STRINGS.SMSH.UI_PVP_TEAMSIZECR_D2 = "Allow Imbalance"
STRINGS.SMSH.UI_PVP_TEAMSIZECR_H1 = "Players from the larger team will be moved to fill any empty slots on the smaller team"
STRINGS.SMSH.UI_PVP_TEAMSIZECR_H2 = "Unbalanced team sizes will not be adjusted"
STRINGS.SMSH.UI_PVP_TEAMFILL = "Open Team Slots"
STRINGS.SMSH.UI_PVP_TEAMFILL_D1 = "Leave Empty"
STRINGS.SMSH.UI_PVP_TEAMFILL_D2 = "Fill with Spiders"
STRINGS.SMSH.UI_PVP_TEAMFILL_H1 = "Unfilled team slots will be left empty"
STRINGS.SMSH.UI_PVP_TEAMFILL_H2 = "Unfilled team slots will be filled with AI spider teammates"
STRINGS.SMSH.TEAM_RED = "red"
STRINGS.SMSH.TEAM_BLUE = "blue"
STRINGS.SMSH.TEAM_RANDOM = "random"
STRINGS.SMSH.TEAM_NAME = "team"


STRINGS.SMSH.UI_LOCAL_VS = "Local VS"
STRINGS.SMSH.UI_LOCAL_MULTIPLAYER = "Local Multiplayer"
STRINGS.SMSH.UI_LOCAL_MULTIPLAYER_DESC = "Play with a second person, sharing one keyboard! If it's big enough. \n Player 2 will use the Arrow keys to move \n And the [4,5,6] Keys on the num-pad to attack."
STRINGS.SMSH.UI_GAMEMODE_COOP_VS = "VS Mode"
STRINGS.SMSH.UI_GAMEMODE_COOP_HORDE = "Co-Op VS Horde"

STRINGS.SMSH.UI_CLICK_START = "CLICK TO START"
STRINGS.SMSH.UI_WAITING = "Waiting for players..."
STRINGS.SMSH.UI_HOST_START = "Waiting for host to start"

STRINGS.SMSH.UI_LOCKED = "LOCKED"
STRINGS.SMSH.UI_TIER = "TIER "
STRINGS.SMSH.UI_DIFFICULTY = "difficulty"
STRINGS.SMSH.UI_OK = "OK"
STRINGS.SMSH.UI_CANCEL = STRINGS.UI.CHARACTERSELECT.CANCEL
STRINGS.SMSH.UI_QUIT = "Quit"
STRINGS.SMSH.UI_DONE = "Done"
STRINGS.SMSH.UI_INITIALIZING = "Initializing..."
STRINGS.SMSH.UI_LEVEL_SELECT = "Level Select"
STRINGS.SMSH.UI_END_GAME = "End Game"
STRINGS.SMSH.UI_ARE_YOU_SURE = "Return to Lobby?"
STRINGS.SMSH.UI_EXIT_LOBBY_DESC = "Exit to lobby and select a new game mode? \n Any queued players will lose their spot in line. \n"
STRINGS.SMSH.UI_NEWSESSIOIN = "started the game" --*
STRINGS.SMSH.UI_ON = "On"
STRINGS.SMSH.UI_OFF = "Off"

STRINGS.SMSH.UI_CLOCK_WAITING = "waiting"
STRINGS.SMSH.UI_CLOCK_SUDDEN_DEATH = "sudden".."\n".."death"

--CONTROLS
STRINGS.SMSH.CTRLS_PREFERENCES = "--PREFERENCES--"
STRINGS.SMSH.CTRLS_DEF_CONTROLS = "DEFAULT CONTROLS"
STRINGS.SMSH.CTRLS_TAPJ_ON = "Tap-Jump: ON"
STRINGS.SMSH.CTRLS_TAPJ_OFF = "Tap-Jump: OFF"
STRINGS.SMSH.CTRLS_AUTODASH_ON = "Auto-Dash: ON" --WE DON'T ACTUALLY USE THIS CURRENTLY THOUGH...
STRINGS.SMSH.CTRLS_AUTODASH_OFF = "Auto-Dash: OFF" --BUT WE DO NOW
STRINGS.SMSH.CTRLS_MUSIC_ON = "Music: ON"
STRINGS.SMSH.CTRLS_MUSIC_OFF = "Music: OFF"


STRINGS.SMSH.CTRLS_DESC_1 = "["..MOVEMENTKEYS.."]=Movement     ["..JUMPKEY.."]=Jump \n(Double-Tap or Hold a direction to dash) \n"
STRINGS.SMSH.CTRLS_DESC_2 = "["..ATKKEY.."]=Attack    ["..SPCKEY.."]=Special    ["..SMASHKEY.."]=Smash \n(Hold directional keys to do different attacks) \n"
STRINGS.SMSH.CTRLS_DESC_3 = "["..BLOCKKEY.."] = Block     ["..GRABKEY.."] = Grab \n(Use movement keys while blocking to Dodge)"
STRINGS.SMSH.CTRLS_MODHINT = "Change your controls with the 'Smashup Custom Controls' client mod"

STRINGS.SMSH.UI_CONTR_HINT = "("..MOVEMENTKEYS..": Movement) - ("..ATKKEY..": Attack) - ("..SPCKEY..": Special) - ("..BLOCKKEY..": Block)"



-- if GLOBAL.TRAILERMODE then
	-- STRINGS.SMSH.UI_CONTR_HINT = ""
-- end



if setlanguage == "sch" then
    --Simplified Chinese
	
	--STAGE GEN--
	STRINGS.SMSH.STAGEGEN_MSG = "准备舞台 \n 需要重新启动才能完成舞台设置. \n 服务器将在 5 秒后自动重启... \n"
	STRINGS.SMSH.HUNT_MSG_1 = "差不多好了..."
	STRINGS.SMSH.HUNT_MSG_2 = "好的"
	
	--JUMBOTRON & ANNOUNCEMENTS--
	STRINGS.SMSH.JUMBO_SPECTATE = "旁观模式。等待比赛结束..."
	STRINGS.SMSH.JUMBO_WAITING4PLYRS = "等待其他玩家..."
	STRINGS.SMSH.JUMBO_PLAYERS_LEFT = "玩家已经离开。进入练习模式"
	STRINGS.SMSH.JUMBO_DROPOUT = "检测到失踪玩家!"
	STRINGS.SMSH.JUMBO_STARTING_ANYWAY = "从没有他们开始"
	STRINGS.SMSH.JUMBO_NOT_ENOUGH_PLAYERS = "没有足够的玩家开始 - 重试"
	STRINGS.SMSH.JUMBO_STARTING_W_PARTIAL = "与观众开始比赛"
	STRINGS.SMSH.JUMBO_NO_SELECTION = "没有选择"
	STRINGS.SMSH.JUMBO_SELECT_TIMER = "剩余 10 秒"
	STRINGS.SMSH.JUMBO_NEW_MATCH = "开始新的比赛"
	STRINGS.SMSH.JUMBO_WINNER = "优胜者: "
	STRINGS.SMSH.JUMBO_GAMESET = "GAME SET"
	
	--HORDE MODE--
	STRINGS.SMSH.JUMBO_WAVE = "战斗 "
	STRINGS.SMSH.JUMBO_NEW_UNLOCK = "新战斗机解锁!"
	STRINGS.SMSH.JUMBO_HORDE_WIN = "关卡完成!"
	STRINGS.SMSH.JUMBO_HORDE_FAIL = "失败..."
	
	--SMASH MENUS--
	STRINGS.SMSH.UI_SELECT_P1 = "选择玩家 1 的角色"
	STRINGS.SMSH.UI_SELECT_P2 = "选择玩家 2 的角色"
	STRINGS.SMSH.UI_SELECT_CHAR = "选择角色"
	STRINGS.SMSH.UI_TIME_UP = "过期时间"
	STRINGS.SMSH.UI_READY = "准备开始。点击开始"
	STRINGS.SMSH.UI_CONTROLS = "控件"
	STRINGS.SMSH.UI_CHANGE_CHAR = "改变性格"
	
	STRINGS.SMSH.UI_GAME_MODES = "游戏模式"
	STRINGS.SMSH.UI_SELECT_MODE = "选择游戏模式..."
	STRINGS.SMSH.UI_GAMEMODE_HORDE = "闯关模式"
	STRINGS.SMSH.UI_GAMEMODE_VSAI = "VS 蜘蛛"
	STRINGS.SMSH.UI_GAMEMODE_CANCEL = "取消"
	
	STRINGS.SMSH.UI_GAMEMODE_HORDE_DESC = "对抗越来越困难的蜘蛛浪潮并摧毁它们的巢穴以解锁更多挑战.\n (1-2 名玩家)"
	STRINGS.SMSH.UI_GAMEMODE_VSAI_DESC = "以不同的难度与 电脑控制 蜘蛛对手战斗。每个玩家会生成一只蜘蛛"
	STRINGS.SMSH.UI_GAMEMODE_CANCEL_DESC = "取消"
	
	
	STRINGS.SMSH.UI_PVP_FIGHTERS = "球员"
	STRINGS.SMSH.UI_PVP_LIVES = "生活"
	STRINGS.SMSH.UI_PVP_TEAMSETTINGS = "团队设置"
	STRINGS.SMSH.UI_PVP_TEAMS = "团队"
	STRINGS.SMSH.UI_PVP_TEAMS_D3 = "为 4 个以上的玩家启用"
	STRINGS.SMSH.UI_PVP_TEAMS_H1 = "团队被禁用"
	STRINGS.SMSH.UI_PVP_TEAMS_H2 = "玩家将被分成两队"
	STRINGS.SMSH.UI_PVP_TEAMS_H3 = "只要有至少 4 名玩家，就会启用团队"
	STRINGS.SMSH.UI_PVP_TEAMSELECTION = "团队选择"
	STRINGS.SMSH.UI_PVP_TEAMSELECTION_D1 = "选择团队"
	STRINGS.SMSH.UI_PVP_TEAMSELECTION_D2 = "《随机队》"
	STRINGS.SMSH.UI_PVP_TEAMSELECTION_H1 = "玩家可以选择自己的球队"
	STRINGS.SMSH.UI_PVP_TEAMSELECTION_H2 = "团队随机分配"
	STRINGS.SMSH.UI_PVP_TEAMSIZECR = "团队规模校正"
	STRINGS.SMSH.UI_PVP_TEAMSIZECR_D1 = "自动平衡"
	STRINGS.SMSH.UI_PVP_TEAMSIZECR_D2 = "允许不平衡"
	STRINGS.SMSH.UI_PVP_TEAMSIZECR_H1 = "来自大队的球员将被转移到小队的任何空位上"
	STRINGS.SMSH.UI_PVP_TEAMSIZECR_H2 = "不平衡的团队规模不会调整"
	STRINGS.SMSH.UI_PVP_TEAMFILL = "开放团队插槽"
	STRINGS.SMSH.UI_PVP_TEAMFILL_D1 = "留空"
	STRINGS.SMSH.UI_PVP_TEAMFILL_D2 = "装满蜘蛛"
	STRINGS.SMSH.UI_PVP_TEAMFILL_H1 = "未填满的团队名额将留空"
	STRINGS.SMSH.UI_PVP_TEAMFILL_H2 = "未填满的队伍名额将被 AI 蜘蛛队友填满"
	
	
	
	STRINGS.SMSH.UI_LOCAL_VS = "本地VS"
	STRINGS.SMSH.UI_LOCAL_MULTIPLAYER = "本地多人游戏"
	STRINGS.SMSH.UI_LOCAL_MULTIPLAYER_DESC = "与第二个人一起玩，共享一个键盘. \n 玩家 2 将使用箭头键移动 \n 和小键盘键攻击"
	STRINGS.SMSH.UI_GAMEMODE_COOP_VS = "VS模式"
	STRINGS.SMSH.UI_GAMEMODE_COOP_HORDE = "合作 VS 部落"
	
	STRINGS.SMSH.UI_CLICK_START = "点击开始"
	STRINGS.SMSH.UI_WAITING = "等待玩家..."
	STRINGS.SMSH.UI_HOST_START = "等待主机启动"
	STRINGS.SMSH.UI_LOCKED = "锁定"
	STRINGS.SMSH.UI_TIER = "等级 "
	STRINGS.SMSH.UI_DIFFICULTY = "困难"
	STRINGS.SMSH.UI_OK = "好的"
	STRINGS.SMSH.UI_CANCEL = "取消"
	STRINGS.SMSH.UI_QUIT = "退出"
	STRINGS.SMSH.UI_DONE = "完毕"
	STRINGS.SMSH.UI_INITIALIZING = "初始化..."
	STRINGS.SMSH.UI_LEVEL_SELECT = "级别选择"
	STRINGS.SMSH.UI_END_GAME = "结束游戏"
	STRINGS.SMSH.UI_ARE_YOU_SURE = "返回大厅？" --"你确定吗?"
	STRINGS.SMSH.UI_EXIT_LOBBY_DESC = "退出大厅并选择新的游戏模式? \n 任何排队的玩家都将失去他们的排队位置. \n"
	
	STRINGS.SMSH.UI_CLOCK_WAITING = "等待"
	STRINGS.SMSH.UI_CLOCK_SUDDEN_DEATH = "猝死"
	
	--CONTROLS
	STRINGS.SMSH.CTRLS_PREFERENCES = "--喜好--"
	STRINGS.SMSH.CTRLS_DEF_CONTROLS = "默认控制"
	STRINGS.SMSH.CTRLS_TAPJ_ON = "点击跳跃: 启用"
	STRINGS.SMSH.CTRLS_TAPJ_OFF = "点击跳跃: 已禁用"
	STRINGS.SMSH.CTRLS_AUTODASH_ON = "自动冲刺: 启用"
	STRINGS.SMSH.CTRLS_AUTODASH_OFF = "自动冲刺: 已禁用"
    STRINGS.SMSH.CTRLS_MUSIC_ON = "音乐: 启用"
	STRINGS.SMSH.CTRLS_MUSIC_OFF = "音乐: 已禁用"
	
	STRINGS.SMSH.CTRLS_DESC_1 = "["..MOVEMENTKEYS.."] = 移动   ["..JUMPKEY.."]=跳 \n(双击一个方向来冲刺) \n"
	STRINGS.SMSH.CTRLS_DESC_2 = "["..ATKKEY.."]=攻击  \n["..SPCKEY.."]=特殊攻击  ["..SMASHKEY.."]=冲锋攻击 \n(按住方向键进行不同的攻击)\n"
	STRINGS.SMSH.CTRLS_DESC_3 = "["..BLOCKKEY.."]=卫   ["..GRABKEY.."]=捉 \n（在阻挡时使用移动键来躲避）"
	STRINGS.SMSH.CTRLS_MODHINT = "使用“Smashup 自定义控件”客户端 mod 更改您的控件"
	
	STRINGS.SMSH.UI_CONTR_HINT = "("..MOVEMENTKEYS..": 移动) - ("..ATKKEY..": 攻击) - ("..SPCKEY..": 特殊攻击)"
	
elseif setlanguage == "ru" then
	--RUSSIAN--
	
	--STAGE GEN--
	STRINGS.SMSH.STAGEGEN_MSG = "Обнаружена первая настройка \n".."Для завершения настройки сцены требуется перезагрузка. \n".."Сервер автоматически перезапустится через 5 секунд... \n"
	STRINGS.SMSH.HUNT_MSG_1 = "Почти готов..."
	STRINGS.SMSH.HUNT_MSG_2 = "OK"
	
	--JUMBOTRON & ANNOUNCEMENTS--
	STRINGS.SMSH.JUMBO_SPECTATE = "Режим наблюдения. В ожидании окончания матча..."
	STRINGS.SMSH.JUMBO_WAITING4PLYRS = "Жду других игроков..."
	STRINGS.SMSH.JUMBO_PLAYERS_LEFT = "Игроки ушли. Вход в режим практики"
	STRINGS.SMSH.JUMBO_DROPOUT = "ОБНАРУЖЕН ОТСУТСТВУЮЩИЙ ИГРОК!"
	STRINGS.SMSH.JUMBO_STARTING_ANYWAY = "НАЧАТЬ БЕЗ НИХ"
	STRINGS.SMSH.JUMBO_NOT_ENOUGH_PLAYERS = "Слишком мало игроков для начала - повторная попытка"
	STRINGS.SMSH.JUMBO_STARTING_W_PARTIAL = "Старт матча со зрителями"
	STRINGS.SMSH.JUMBO_NO_SELECTION = "Выбор не сделан"
	STRINGS.SMSH.JUMBO_SELECT_TIMER = "Осталось 10 секунд"
	STRINGS.SMSH.JUMBO_NEW_MATCH = "Начало нового матча."
	STRINGS.SMSH.JUMBO_WINNER = "ПОБЕДИТЕЛЬ: "
	STRINGS.SMSH.JUMBO_GAMESET = "НАБОР ИГРЫ"
	
	--HORDE MODE--
	STRINGS.SMSH.JUMBO_WAVE = "БОЕВОЙ "
	STRINGS.SMSH.JUMBO_NEW_UNLOCK = "Разблокирован новый истребитель!"
	STRINGS.SMSH.JUMBO_HORDE_WIN = "ОРДА ПОЛНАЯ!"
	STRINGS.SMSH.JUMBO_HORDE_FAIL = "ОТКАЗ..."
	
	--SMASH MENUS--
	STRINGS.SMSH.UI_SELECT_P1 = "Выберите персонажа игрока 1"
	STRINGS.SMSH.UI_SELECT_P2 = "Выберите персонажа игрока 2"
	STRINGS.SMSH.UI_SELECT_CHAR = "Выбрать персонажа"
	STRINGS.SMSH.UI_TIME_UP = "Время истекло"
	STRINGS.SMSH.UI_READY = "Готовый. Нажмите Пуск"
	STRINGS.SMSH.UI_CONTROLS = "Управление"
	STRINGS.SMSH.UI_CHANGE_CHAR = "Сменить персонажа"
	
	STRINGS.SMSH.UI_GAME_MODES = "Режимы игры"
	STRINGS.SMSH.UI_SELECT_MODE = "Выберите игровой режим..."
	STRINGS.SMSH.UI_GAMEMODE_HORDE = "Ордынская мода"
	STRINGS.SMSH.UI_GAMEMODE_VSAI = "Против паука"
	STRINGS.SMSH.UI_GAMEMODE_CANCEL = "Ничего"
	
	STRINGS.SMSH.UI_GAMEMODE_HORDE_DESC = "Сражайтесь через все более сложные волны пауков и разрушайте их логовища, чтобы разблокировать новые испытания.\n (1-2 игрока)"
	STRINGS.SMSH.UI_GAMEMODE_VSAI_DESC = "Сразитесь с противником-пауком с искусственным интеллектом на разных уровнях сложности. Для каждого присоединившегося игрока появится один паук."
	STRINGS.SMSH.UI_GAMEMODE_CANCEL_DESC = "Отменить"
	
	STRINGS.SMSH.UI_PVP_FIGHTERS = "Игроки"
	STRINGS.SMSH.UI_PVP_LIVES = "Жизни"
	STRINGS.SMSH.UI_PVP_TEAMSETTINGS = "Настройки команды"
	STRINGS.SMSH.UI_PVP_TEAMS = "Команды"
	STRINGS.SMSH.UI_PVP_TEAMS_D3 = "Включено для 4+ игроков"
	STRINGS.SMSH.UI_PVP_TEAMS_H1 = "Команды отключены"
	STRINGS.SMSH.UI_PVP_TEAMS_H2 = "Игроки будут объединены в 2 команды"
	STRINGS.SMSH.UI_PVP_TEAMS_H3 = "Команды будут активны, если в них будет хотя бы 4 игрока"
	STRINGS.SMSH.UI_PVP_TEAMSELECTION = "Выбор команды"
	STRINGS.SMSH.UI_PVP_TEAMSELECTION_D1 = "Выберите команды"
	STRINGS.SMSH.UI_PVP_TEAMSELECTION_D2 = "Случайные команды"
	STRINGS.SMSH.UI_PVP_TEAMSELECTION_H1 = "Игроки могут выбрать свою собственную команду"
	STRINGS.SMSH.UI_PVP_TEAMSELECTION_H2 = "Команды распределяются случайным образом"
	STRINGS.SMSH.UI_PVP_TEAMSIZECR = "Коррекция размера команды"
	STRINGS.SMSH.UI_PVP_TEAMSIZECR_D1 = "Автобаланс"
	STRINGS.SMSH.UI_PVP_TEAMSIZECR_D2 = "Разрешить дисбаланс"
	STRINGS.SMSH.UI_PVP_TEAMSIZECR_H1 = "Игроки из большей команды будут перемещены, чтобы заполнить все пустые места в меньшей команде"
	STRINGS.SMSH.UI_PVP_TEAMSIZECR_H2 = "Несбалансированные размеры команд корректироваться не будут"
	STRINGS.SMSH.UI_PVP_TEAMFILL = "Открытые командные слоты"
	STRINGS.SMSH.UI_PVP_TEAMFILL_D1 = "Оставить пустым"
	STRINGS.SMSH.UI_PVP_TEAMFILL_D2 = "Наполни пауками"
	STRINGS.SMSH.UI_PVP_TEAMFILL_H1 = "Незаполненные слоты команд останутся пустыми"
	STRINGS.SMSH.UI_PVP_TEAMFILL_H2 = "Незаполненные командные слоты будут заполнены товарищами по команде ИИ-пауками"
	
	STRINGS.SMSH.UI_LOCAL_VS = "Локальный VS"
	STRINGS.SMSH.UI_LOCAL_MULTIPLAYER = "Локальный мультиплеер"
	STRINGS.SMSH.UI_LOCAL_MULTIPLAYER_DESC = "Играйте со вторым человеком, используя одну клавиатуру. \n Игрок 2 будет использовать клавиши со стрелками для перемещения \n И цифровая клавиатура для атаки."
	STRINGS.SMSH.UI_GAMEMODE_COOP_VS = "Режим VS"
	STRINGS.SMSH.UI_GAMEMODE_COOP_HORDE = "Совместная игра Орда"
	
	STRINGS.SMSH.UI_CLICK_START = "Совместная игра Орда"
	STRINGS.SMSH.UI_WAITING = "Жду игроков..."
	STRINGS.SMSH.UI_HOST_START = "Ожидание запуска хоста"
	STRINGS.SMSH.UI_LOCKED = "ЗАБЛОКИРОВАНО"
	STRINGS.SMSH.UI_TIER = "РАЗМЕР "
	STRINGS.SMSH.UI_DIFFICULTY = "трудность"
	STRINGS.SMSH.UI_OK = "OK"
	STRINGS.SMSH.UI_CANCEL = "Отменить"
	STRINGS.SMSH.UI_QUIT = "Покидать"
	STRINGS.SMSH.UI_DONE = "Выполнено"
	STRINGS.SMSH.UI_INITIALIZING = "Инициализация..."
	STRINGS.SMSH.UI_LEVEL_SELECT = "Выбор уровня"
	STRINGS.SMSH.UI_END_GAME = "Конец игры"
	STRINGS.SMSH.UI_ARE_YOU_SURE = "Вернуться в лобби?" --"Вы уверены?"
	STRINGS.SMSH.UI_EXIT_LOBBY_DESC = "Выйдите в лобби и выберите новый режим игры? \n Любые игроки в очереди теряют свое место в очереди. \n"
	
	STRINGS.SMSH.UI_CLOCK_WAITING = "ожидающий"
	STRINGS.SMSH.UI_CLOCK_SUDDEN_DEATH = "внезапная".."\n".."смерть"
	
	--CONTROLS
	STRINGS.SMSH.CTRLS_PREFERENCES = "ПРЕДПОЧТЕНИЯ"
	STRINGS.SMSH.CTRLS_DEF_CONTROLS = "инструкции" --"INSTRUCTIONS" --"УПРАВЛЕНИЕ ПО УМОЛЧАНИЮ"
	-- STRINGS.SMSH.CTRLS_TAPJ_ON = "прыжок-вверх: Включено" --THIS IS WAY TOO BIG
	STRINGS.SMSH.CTRLS_TAPJ_ON = "прыжок: да" --THEY'RE GONNA HAVE TO SETTLE FOR "HOP: YES/NO"
	STRINGS.SMSH.CTRLS_TAPJ_OFF = "прыжок: нет"
	STRINGS.SMSH.CTRLS_AUTODASH_ON = "селф-рон: да"
	STRINGS.SMSH.CTRLS_AUTODASH_OFF = "селф-рон: нет"
	STRINGS.SMSH.CTRLS_MUSIC_ON = "Музыка: да"
	STRINGS.SMSH.CTRLS_MUSIC_OFF = "Музыка: нет"
	
	--RUSSIA NEEDS EXTRA LINES BECAUSE THEIR LANGUAGE IS SO BIG. WTH COME ON GUYS. I THOUGHT BEING BIG WAS AMERICA'S THING
	STRINGS.SMSH.CTRLS_DESC_1 = "["..MOVEMENTKEYS.."]=Движение  ["..JUMPKEY.."]=Прыжок \n(Дважды коснитесь направления, \n чтобы броситься)" 
	STRINGS.SMSH.CTRLS_DESC_2 = "["..ATKKEY.."]=Атака  \n["..SPCKEY.."]=особенный  ["..SMASHKEY.."]=громить \n(Удерживайте клавиши со стрелками, \n чтобы выполнять разные атаки) "
	STRINGS.SMSH.CTRLS_DESC_3 = "["..BLOCKKEY.."]=защищать  ["..GRABKEY.."]=захват \n(Используйте клавиши перемещения во \nвремя блокировки, чтобы увернуться)"
	STRINGS.SMSH.CTRLS_MODHINT = "Измените элементы управления с помощью клиентского мода \n'Smashup настраиваемые элементы управления'"
	
	STRINGS.SMSH.UI_CONTR_HINT = "("..MOVEMENTKEYS..": Движение) - ("..ATKKEY..": Атака) - ("..SPCKEY..": особенный)"

end








--[[

Say goodbye to attack mashing and jump into a totally new fighting game!
[url=https://youtu.be/_odiZImF-iw] Trailer Link [/url]

[h1]--OPENING WEEK BETA--[/h1]
[hr][/hr]
[b]This mod is currently in BETA so please expect changes to be made frequently[/b]
[b]Please report bugs in the bug report section below, and leave any feedback you might have[/b]
[hr][/hr]

[h1]Redesigned combat![/h1]
[list]
[*]Smash-inspired combat overhaul gives each character a full moveset of unique attacks and special attacks
[*]Play as 5* different Don't Starve characters!
replaces the F key with full movesets of unique attacks and special attacks
[*]All new forms of movement to jump, dodge and dash around the 2D environment
[*]Rack up damage on your opponents and knock them off the stage to win!
[/list]

[h1]Different settings for different modes of play![/h1]
[list]
[*]Fight through hordes of enemy spiders in the singleplayer/co-op game-modes
[*]Or test your PVP skills against other players through the shoddy online match system!
[*]Run large free-for-all brawls or elimination style 1v1 duels 
[/list]

[h1]Customize controls for keyboard or controllers![/h1]
[list]
[*]IMPORTANT: You must have the clientside mod below in order to change your controls. 
[*][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2298228108] Smashup Controls Mod [/url]
[*]Change your keybindings in the settings for the above mod
[/list]

[hr][/hr]
Check out some of my other mods!
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=1367276577] Pickle's First Person Mod [/url], [url=https://steamcommunity.com/sharedfiles/filedetails/?id=2564518007] Craftblock - 3D Base Building [/url]

(Please Note: My native language is English. Please feel free to correct any of my translations that are incorrect!)






[h1]Create your own fighters with custom mod support! [/h1]
[list]
[*]Template characters available to start from [______]
[*]Includes tutorials for creating character sprites and movesets
[/list]





告别 F 键，使用这款无平台平台战斗机跳入全新游戏；不要饿死粉碎！

[Trailer Link]

[h1]--开放周测试版--[/h1]
[hr][/hr]
[b]此模组目前处于测试阶段，因此请期待经常进行更改[/b]
[b]请在下面的错误报告部分报告错误，并留下您可能有的任何反馈[/b]
[hr][/hr]

[h1]重新设计的战斗！[/h1]
[list]
[*]以粉碎为灵感的战斗大修为每个角色提供完整的独特攻击和特殊攻击动作
[*]扮演 5* 个不同的饥荒角色！ （未来可能更多吗？...）
用完整的独特攻击和特殊攻击的动作组替换 F 键
[*] 在 2D 环境中跳跃、躲避和冲刺的所有新运动形式
[*]对你的对手造成伤害并将他们从舞台上击倒以获得胜利！
[/list]

[h1]不同玩法的不同设置！[/h1]
[list]
[*]在单人/合作游戏模式中与成群的敌方蜘蛛作战
[*]或者通过劣质的在线比赛系统测试你对其他玩家的PVP技能！
[*]进行大型混战或淘汰式1v1决斗
[/list]

[h1]自定义键盘或控制器的控件！[/h1]
[list]
[*]重要提示：您必须拥有下面的客户端 mod 才能更改您的控件。
[*][url=https://steamcommunity.com/sharedfiles/filedetails/?id=2298228108] Smashup 控制模组 [/url]
[*]在上述模组的设置中更改您的按键绑定
[/list]

--配置模组--
1. 语言
2.每场比赛的最大战士数
3. 每名战士的生命
4.比赛时间限制（乘以每名战士的生命）
5. 队列轮换
 -Rotate All (DEFAULT) ：所有玩家正常轮换队列。
 -Winner Stays：获胜者继续比赛。其他人正常轮换队列。
6. 服务器游戏模式
 -任何人的选择
 - 管理员的选择（默认）
 - 仅限 PvP
 -仅限部落
 -仅VS-AI


（请注意：我的母语是英语。请随时纠正我的任何不正确的翻译！）






Попрощайтесь с клавишей F и окунитесь в совершенно новую игру с этим безплатформенным платформером; Не голодайте Smashup!
[url=https://youtu.be/_odiZImF-iw] Trailer Link [/url]


[h1] - ОТКРЫТИЕ БЕТА НЕДЕЛИ - [/h1]
[hr] [/hr]
[b] Этот мод в настоящее время находится в стадии бета-тестирования, поэтому ожидайте, что изменения будут hrто вноситься [/b]
[b] Пожалуйста, сообщайте об ошибках в разделе отчетов об ошибках ниже и оставляйте любые отзывы, которые у вас могут быть [/b]
[hr] [/hr]

[h1] Новый дизайн боя! [/h1]
[list]
[*] Вдохновленный Smash переработка боя дает каждому персонажу полный набор уникальных атак и специальных атак.
[*] Играйте за 5 * разных персонажей Don't Starve! (И, возможно, еще больше в будущем? ...)
заменяет клавишу F полными наборами уникальных атак и специальных атак
[*] Все новые формы движения, позволяющие прыгать, уворачиваться и метаться в 2D-среде.
[*] Наносите урон своим противникам и сбивайте их со сцены, чтобы побеждать!
[/list]

[h1] Разные настройки для разных режимов игры! [/h1]
[list]
[*] Сражайтесь с ордами вражеских пауков в одиночном / кооперативном режимах игры.
[*] Или испытайте свои навыки PVP против других игроков через дрянную систему онлайн-матчей!
[*] Уhrтвуйте в массовых схватках или дуэлях 1 на 1 на выбывание.
[/list]

[h1] Настройте элементы управления для клавиатуры или контроллеров! [/h1]
[list]
[*] ВАЖНО: у вас должен быть клиентский мод, указанный ниже, чтобы вы могли изменить свой контроль.
[*] [url = https: //steamcommunity.com/sharedfiles/filedetails/? id = 2298228108] Мод Smashup Controls [/ url]
[*] Измените сочетания клавиш в настройках вышеуказанного мода
[/list]


--Настроить мод--
1. Язык
2. Максимальное количество бойцов за матч.
3. Жизней на бойца.
4. Ограничение по времени матча (умноженное на количество жизней бойца).
5. Ротация очереди
 -Поворот всех (ПО УМОЛЧАНИЮ): все игроки обычно перемещаются по очереди.
 -Победитель остается: победитель продолжает играть. Остальные проходят по очереди как обычно.
6. Серверный игровой режим
 -Любой выбор
 -Выбор администратора (ПО УМОЛЧАНИЮ)
 -PvP Только
 -Только Орда
 -VS-AI Только


(Обратите внимание: мой родной язык - английский. Не стесняйтесь исправлять любой из моих неправильных переводов!)



--
Bug Reports
[b]Pleeeaase report bugs! I can't fix something if I don't know it's broken. [/b]
-A screenshot of the crash screen helps a lot! But isn't required
-Also PLEASE mention if you have other mods enabled.  (and then try disabling them. Other mods can often be the cause)








--MOD SETTINGS--
1. Language
2. Maximum number of fighters per match
3. Lives per fighter
4. Match time limit (multiplied by lives per fighter)
5. Queue Rotation
	-Rotate All (DEFAULT) : All players rotate through the queue normally.
	-Winner Stays : The winner continues to play. Everyone else rotates through the queue normally.
6. Server Game-Mode
	-Anyone's Choice
	-Admin's Choice (DEFAULT)
	-PvP Only
	-Horde Only
	-VS-AI Only
	











[h1]Create custom characters or costumes with mods! [/h1]
[list]
[*]Template characters available to start from on the [url=https://forums.kleientertainment.com/files/file/2091-smashtemplate]Klei Forums! [/url]
[*]Includes tutorials (in english) for creating character sprites and movesets 
[/list]


[h1]使用模组创建自定义角色或服装！ [/h1]
[list]
[*]可从 [url=https://forums.kleientertainment.com/files/file/2091-smashtemplate]Klei 论坛开始的模板字符！ [/网址]
[*]包括创建角色精灵和移动集的教程（英文）
[/list]



[h1]Создавайте собственных персонажей или костюмы с помощью модов! [/h1]
[list]
[*]Шаблоны символов доступны для начала на [url=https://forums.kleientertainment.com/files/file/2091-smashtemplate]Klei Forums! [/url]
[*]Включает учебные пособия (на английском языке) по созданию спрайтов персонажей и наборов приемов.
[/list]

--


--

[ENGLISH]
Set your preferred control settings in the configuration menu of this mod.

(For anyone wondering why these settings aren't part of the main mod; If I put them in the main mod, changing the controlls there would change the controlls for everyone else who joins your game)




[BASE TRANSLATOR]
Set your preferred control settings in the configuration menu of this mod.

Configuration Settings Translation (in order from top to bottom)

[*]Tap-Jump: Automatically jump when you press the Up key
[*]Auto-Dash: Automatically sprint after walking for a short time
[*]Attack
[*]Special Attack
[*]Charge Attack (Hold the key to charge the attack longer)
[*]Grapple (Alternatively, press Attack while blocking)
[*]Jump
[*]Guard
[*]Up
[*]Down
[*]Left
[*]Right
[*]CStick-Up (Performs an Up Charge attack on the ground, or an Up-Air in the air)
[*]CStick-Down (Performs a Down Charge attack on the ground, or a Down-Air in the air)
[*]CStick-Left (Performs a Side Charge attack on the ground, or a Side-Air in the air)
[*]CStick-Right (Performs a Side Charge attack on the ground, or a Side-Air in the air)
[*]Attack (controller)
[*]Special Attack (controller)
[*]Charge Attack (controller)
[*]Grapple (controller)
[*]Jump (controller)
[*]Guard (controller)


Controller Translations:
Right Trigger = Right Trigger
Left Trigger = Left Trigger
Right Bumper = Right Bumper
Left Bumper = Left Bumper




[CHINESE]
在此模组的配置菜单中设置您的首选控制设置。

配置设置翻译（按从上到下的顺序）
[list]
[*]Tap-Jump： 按Up键自动跳转
[*]Auto-Dash： 短时间行走后自动冲刺
[*]攻击
[*]特攻
[*]蓄力攻击（按住键可蓄力更长时间）
[*]抓钩（或者，在阻挡时按攻击）
[*]跳
[*]卫
[*]向上
[*]向下
[*]剩下
[*]对
[*]CStick-Up（在地面上进行向上冲锋攻击，或在空中进行空中攻击）
[*]CStick-Down（在地面上进行下冲锋攻击，或在空中进行下空攻击）
[*]CStick-Left（在地面上进行侧冲攻击，或在空中进行侧空攻击）
[*]CStick-Right（在地面上进行侧冲攻击，或在空中进行侧空攻击）
[*]攻击（控制器）
[*]特殊攻击（控制器）
[*]蓄力攻击（控制器）
[*]抓钩（控制器）
[*]跳（控制器）
[*]卫（控制器）
[/list]

控制器翻译：
Right Trigger = 右扳机
Left Trigger = 左扳机
Right Bumper = 右保险杠
Left Bumper = 左保险杠




[RUSSIAN]
Установите предпочтительные параметры управления в меню конфигурации этого мода.

Перевод параметров конфигурации (в порядке сверху вниз)
[list]
[*]Tap-Jump: автоматически прыгать при нажатии клавиши «Вверх».
[*]Auto-Dash: автоматический спринт после короткой прогулки.
[*]Атака
[*]Специальная атака
[*]Заряженная атака (удерживайте клавишу, чтобы зарядить атаку дольше)
[*]Захват (как вариант, нажмите Атака во время блокировки)
[*]Прыжок
[*]защищать
[*]Вверх
[*]Вниз
[*]Левый
[*]Правильно
[*]CStick-Up (Выполняет атаку Up Charge по земле или Up-Air в воздухе)
[*]CStick-Down (Выполняет атаку Down Charge по земле или Down-Air в воздухе)
[*]CStick-Left (Выполняет атаку с боковым рывком по земле или боковой удар в воздухе)
[*]CStick-Right (Выполняет боковую атаку по земле или боковой удар в воздухе)
[*]Атака (контроллер)
[*]Специальная атака (контроллер)
[*]Заряженная атака (контроллер)
[*]Грейфер (контроллер)
[*]Прыжок (контроллер)
[*]защищать (контролер)
[/list]

Переводы контроллера:
Right Trigger = Правый триггер
Left Trigger = Левый триггер
Right Bumper = правый бампер
Left Bumper = левый бампер










Special moves:
Wilson
Neutral-Special: A chargable chemical blast that starts off relatively weak, but the damage and range scale very quickly with just a little bit of charge
Side-Special: Throw a boomerang that returns to you
Up-Special: A quick rising uppercut. If it connects with an opponent at the start of the move, you can act out of it.
Down-Special: Toss a small explosive vial downward, and gain a small aireal boost the first time it's used in the air


Woodie
Neutral-Special: Throw Lucy forward as a strong but sluggish projectile
Side-Special: Rush forward and batter opponents out of the way. Swings Lucy at the end of the charge for big damage
Up-Special: A wide arcing axe swing that lifts him into the air
Down-Special: Drop downward quickly and damage anyone you hit on the way down


Wickerbottom
Neutral-Special: Summon a powerful dragoon egg that explodes on impact with the ground
Side-Special: Use an Ice staff to freeze enemies
Up-Special: Summon a small swarm of birds to lift you up
Down-Special: Summon a tentacle. Can only be used 3 times per life.


Maxwell
Neutral-Special: 
Side-Special:
Up-Special:
Down-Special: Summon a shadow copy of yourself to control. Or send your clone forward if one already exists. 
--Your clone is controlled with the same controlls, but cannot do special attacks.



Neutral-Special: 
Side-Special:
Up-Special:
Down-Special:

]]



