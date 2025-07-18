local Badge2 = require "widgets/badge2"
local UIAnim = require "widgets/uianim"

--2-8-22 RETURN OF THE PERCENTBADGE! IT'S BEEN QUITE A WHILE
--MODS THAT ALTER THE PercentBadge ARE REALLY ANNOYING SO LETS DROP OUR DEPENDANCE ON IT
--THIS IS A DIRECT COPY OF HEALTHBADGE.LUA SO A LOT OF THIS IS PROBABLY NOT NEEDED, BUT I'LL LEAVE IT IN

local function OnEffigyDeactivated(inst)
    if inst.AnimState:IsCurrentAnimation("effigy_deactivate") then
        inst.widget:Hide()
    end
end

local PercentBadge = Class(Badge2, function(self, owner, art)
    Badge2._ctor(self, art, owner, { 174 / 255, 21 / 255, 21 / 255, 1 }, "status_health", nil, nil, true)

    self.topperanim = self.underNumber:AddChild(UIAnim())
    self.topperanim:GetAnimState():SetBank("status_meter")
    self.topperanim:GetAnimState():SetBuild("status_meter")
    self.topperanim:GetAnimState():PlayAnimation("anim")
    self.topperanim:GetAnimState():SetMultColour(0, 0, 0, 1)
    self.topperanim:SetScale(1, -1, 1)
    self.topperanim:SetClickable(false)
    self.topperanim:GetAnimState():AnimateWhilePaused(false)
    self.topperanim:GetAnimState():SetPercent("anim", 1)

    if self.circleframe ~= nil then
        self.circleframe:GetAnimState():Hide("frame")
    else
        self.anim:GetAnimState():Hide("frame")
    end

    self.circleframe2 = self.underNumber:AddChild(UIAnim())
    self.circleframe2:GetAnimState():SetBank("status_meter")
    self.circleframe2:GetAnimState():SetBuild("status_meter")
    self.circleframe2:GetAnimState():PlayAnimation("frame")
    self.circleframe2:GetAnimState():AnimateWhilePaused(false)

    self.sanityarrow = self.underNumber:AddChild(UIAnim())
    self.sanityarrow:GetAnimState():SetBank("sanity_arrow")
    self.sanityarrow:GetAnimState():SetBuild("sanity_arrow")
    self.sanityarrow:GetAnimState():PlayAnimation("neutral")
    self.sanityarrow:SetClickable(false)
    self.sanityarrow:GetAnimState():AnimateWhilePaused(false)

    self.effigyanim = self.underNumber:AddChild(UIAnim())
    self.effigyanim:GetAnimState():SetBank("status_health")
    self.effigyanim:GetAnimState():SetBuild("status_health")
    self.effigyanim:GetAnimState():PlayAnimation("effigy_deactivate")
    self.effigyanim:Hide()
    self.effigyanim:SetClickable(false)
    self.effigyanim:GetAnimState():AnimateWhilePaused(false)
    self.effigyanim.inst:ListenForEvent("animover", OnEffigyDeactivated)
    self.effigy = false
    self.effigybreaksound = nil

    self.corrosives = {}
    self._onremovecorrosive = function(debuff)
        self.corrosives[debuff] = nil
    end
    self.inst:ListenForEvent("startcorrosivedebuff", function(owner, debuff)
        if self.corrosives[debuff] == nil then
            self.corrosives[debuff] = true
            self.inst:ListenForEvent("onremove", self._onremovecorrosive, debuff)
        end
    end, owner)

    self.hots = {}
    self._onremovehots = function(debuff)
        self.hots[debuff] = nil
    end
    self.inst:ListenForEvent("starthealthregen", function(owner, debuff)
        if self.hots[debuff] == nil then
            self.hots[debuff] = true
            self.inst:ListenForEvent("onremove", self._onremovehots, debuff)
        end
    end, owner)

    self:StartUpdating()
end)

function PercentBadge:ShowEffigy()
    if not self.effigy then
        self.effigy = true
        self.effigyanim:GetAnimState():PlayAnimation("effigy_activate")
        self.effigyanim:GetAnimState():PushAnimation("effigy_idle", false)
        self.effigyanim:Show()
    end
end

local function PlayEffigyBreakSound(inst, self)
    inst.task = nil
    if self:IsVisible() and inst.AnimState:IsCurrentAnimation("effigy_deactivate") then
        --Don't use FE sound since it's not a 2D sfx
        TheFocalPoint.SoundEmitter:PlaySound(self.effigybreaksound)
    end
end

function PercentBadge:HideEffigy()
    if self.effigy then
        self.effigy = false
        self.effigyanim:GetAnimState():PlayAnimation("effigy_deactivate")
        if self.effigyanim.inst.task ~= nil then
            self.effigyanim.inst.task:Cancel()
        end
        self.effigyanim.inst.task = self.effigyanim.inst:DoTaskInTime(7 * FRAMES, PlayEffigyBreakSound, self)
    end
end

function PercentBadge:SetPercent(val, max, penaltypercent)
    Badge2.SetPercent(self, val, max)

    penaltypercent = penaltypercent or 0
    self.topperanim:GetAnimState():SetPercent("anim", 1 - penaltypercent)
end

function PercentBadge:OnUpdate(dt)
    if TheNet:IsServerPaused() then return end

    local down
    if (self.owner.IsFreezing ~= nil and self.owner:IsFreezing()) or
        (self.owner.replica.health ~= nil and self.owner.replica.health:IsTakingFireDamageFull()) or
        (self.owner.replica.hunger ~= nil and self.owner.replica.hunger:IsStarving()) or
        next(self.corrosives) ~= nil then
        down = "_most"
    elseif self.owner.IsOverheating ~= nil and self.owner:IsOverheating() then
        down = self.owner:HasTag("heatresistant") and "_more" or "_most"
    end

    -- Show the up-arrow when we're sleeping (but not in a straw roll: that doesn't heal us)
    local up = down == nil and
        (
            (   (self.owner.player_classified ~= nil and self.owner.player_classified.issleephealing:value()) or
                next(self.hots) ~= nil or
                (self.owner.replica.inventory ~= nil and self.owner.replica.inventory:EquipHasTag("regen"))
            ) or
            (self.owner:HasDebuff("wintersfeastbuff"))
        ) and
        self.owner.replica.health ~= nil and self.owner.replica.health:IsHurt()

    local anim =
        (down ~= nil and ("arrow_loop_decrease"..down)) or
        (not up and "neutral") or
        (next(self.hots) ~= nil and "arrow_loop_increase_most") or
        "arrow_loop_increase"

    if self.arrowdir ~= anim then
        self.arrowdir = anim
        self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
    end
end

return PercentBadge
