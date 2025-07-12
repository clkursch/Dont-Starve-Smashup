require "behaviours/chaseandfight"
require "behaviours/recover"
require "behaviours/defendself"
require "behaviours/react"
require "behaviours/edgegaurd"
require "behaviours/search"
require "behaviours/escapekb"
require "behaviours/getup"


local MAX_CHASE_TIME = 80

local SpiderFighterBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


function SpiderFighterBrain:OnStart()
    local root =
        PriorityNode(
        {
            -- WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
					
			WhileNode( function() return self.inst.components.launchgravity:GetIsAirborn() end, "Recover", Recover(self.inst, "Recover")),
			
			Search(self.inst, "doesthisdoanything"), --TO PREVENT THE GAME FROM CRASHING WHEN OPPONENT DISAPPEARS
			
			Escapekb(self.inst), --ATTEMPTS TO ESCAPE FROM COMBOS AND AVOID GETTING HIT IN THE AIR
			
			GetUp(self.inst), --JUST TO GET UP OFF OF THE GROUND/LEDGE
			
			React(self.inst, "React"), --7-26 --ADDED TO ALLOW CPU TO CANCEL THEIR APPROACH TO DEFEND THEMSELVES INSTEAD
			
			EdgeGaurd(self.inst, "EdgeGaurd"), --8-7 GIVES THE CPU SOMETHING TO DO WHILE OPPONENT IS OFF EDGE AS TO NOT JUMP OFF AFTER THEM
			
			WhileNode( function() return not self.inst:HasTag("going_in") end, "Defend", DefendSelf(self.inst, "Defend")),
			
			ChaseAndFight(self.inst, MAX_CHASE_TIME),
			        
        },0.20) --0.35--1
    
    self.bt = BT(self.inst, root)
end




function SpiderFighterBrain:ForceRefresh() --1-18-17 LETS SEE IF THIS WORKS, BECAUSE ONSTART() DOESNT WORK.
	-- print("REV UP THE ENGINES")	
	self.bt.root.period = 0
	self.bt:Update()
	self.bt.root.period = 0.20
end


function SpiderFighterBrain:OnInitializationComplete()
	--1-28-17 THIS HAS TO HAPPEN FIRST BECAUSE THE SEARCH NODE HASN'T RUN YET
	local nemisis = self.inst.components.aifeelings:FindNearestEnemy() --2-7-17
	if nemisis then
		self.inst.components.stats.opponent = nemisis
		if nemisis.components.stats then --TO FIX A BUG IN CASE OPPONENT IS TEMP AND DOESNT HAVE STATS
			nemisis.components.stats.opponent = self.inst 
		end
	end
	
	--1-3-17
	self.inst.components.aifeelings:GetAttackNode():InitAction() --HAH!! IT WORKS
	
	--1-31-17 ANOTHER INITIATION FOR REACTION TIME AND STUFF
	for i,node in ipairs(self.inst.brain.bt.root.children) do
		if node.name == "React" then
			node:InitAction()
		end
	end

end

return SpiderFighterBrain



--[[
SPIDER BRAIN PRIORITY LISTING

	RECOVER
	
	--if not currenly aproaching then skip defensself and just continue the aproach
		--UNLESS scared by a charging smash attack or projectile or sometimes a counteraproach
	
	DEFEND SELF --if opp ~= attack range
		block for ~ time then finish
			stay in sheild if opponent is about to attack
			--on hit sheild:
				grab if close enough
				counter if punishable
				roll if scared
			escape
			
		(counter) finish
		
	APPROACH
]]




--[[
He is getting very hard to beat. 
He can do just about anything a player can do now. He knows about frame advantage and how to tech and RAR and use aireals out of shield
ever since I gave him a down-air he's become the dunk master and no ledge is safe anymore because he will drop right down off the ledge and spike you down and still make it back up

I'm curently teaching him how to deal with projectiles 

--great close qurters combat
--proper defense to prevent punishes 

edgegaurding improvements, can properly chase opponentsnts offstage, will drop down from ledge to spike
improved recovery can use sidespecial to recover high.

much better air combat and followups. will chase opponents up for followups. 
its pretty easy to fastfall-nair out of most of his followups though. but if you keep challenging his followups in the air, he'll wise up and start holding shield beneath you

major difference in design:
he does not make instant reactions to hitboxes on screen.
level7 and higher cpus for smash bros have "magic airdodging" which is an aweful concept that means that they will magically instantly aidodge any attack that comes out with instant eaction time
luigi nair, airdodged. the higher the level, the more likely they are to magically airdodge it. You cant bait an airdodge either

smashup ai has reaction time, and does not take into account on-screen hitboxes. decisions are made based on player position, velocity, direction ai confidence, and a lot of other aspects.
you can bait air-dodges.  they can even miss-judge distances, as attack decisions have modifiers that slightly increase/decrease their percieved range by a different amount every time it is run.

AI WILL NOT JUST WALK INTO CHARGING SMASH ATTACKS FROM ACROSS THE MAP.
I could write a 5 page essay on how the AI confidence system works, how it decides it should act out of shield and when to stay in shield

]]

