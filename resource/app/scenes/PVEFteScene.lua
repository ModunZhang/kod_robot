local Enum = import("..utils.Enum")
local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local WidgetUseItems = import("..widget.WidgetUseItems")
local WidgetPVEKeel = import("..widget.WidgetPVEKeel")
local WidgetPVECamp = import("..widget.WidgetPVECamp")
local WidgetPVEMiner = import("..widget.WidgetPVEMiner")
local WidgetPVEFteMiner = import("..widget.WidgetPVEFteMiner")
local WidgetPVEFarmer = import("..widget.WidgetPVEFarmer")
local WidgetPVEObelisk = import("..widget.WidgetPVEObelisk")
local WidgetPVEQuarrier = import("..widget.WidgetPVEQuarrier")
local WidgetPVEWoodcutter = import("..widget.WidgetPVEWoodcutter")
local WidgetPVEAncientRuins = import("..widget.WidgetPVEAncientRuins")
local WidgetPVEWarriorsTomb = import("..widget.WidgetPVEWarriorsTomb")
local WidgetPVEEntranceDoor = import("..widget.WidgetPVEEntranceDoor")
local WidgetPVEStartAirship = import("..widget.WidgetPVEStartAirship")
local WidgetPVECrashedAirship = import("..widget.WidgetPVECrashedAirship")
local WidgetPVEConstructionRuins = import("..widget.WidgetPVEConstructionRuins")
local WidgetDirectionSelect = import("..widget.WidgetDirectionSelect")
local PVEDefine = import("..entity.PVEDefine")
local PVEObject = import("..entity.PVEObject")
local GameUINpc = import("..ui.GameUINpc")
local UILib = import("..ui.UILib")
local PVEScene = import(".PVEScene")
local PVEFteScene = class("PVEFteScene", PVEScene)
function PVEFteScene:ctor(...)
    PVEFteScene.super.ctor(self, ...)
end
function PVEFteScene:onExit()
    PVEFteScene.super.super.onExit(self)
end
function PVEFteScene:OnTouchClicked(pre_x, pre_y, x, y)

    if not self.move_data then return end

    -- 有动画就什么都不处理
    if self.event_manager:TouchCounts() ~= 0 or
        self:GetSceneLayer():GetChar():getNumberOfRunningActions() > 0 then
        return
    end

    -- 获取当前点
    -- 检查是不是在中心
    local old_x, old_y = self:GetCurrentPos()
    local logic_x, logic_y = self:GetCenterPos()
    if logic_x ~= old_x or logic_y ~= old_y then
        local s = math.abs(logic_x - old_x) + math.abs(logic_y - old_y)
        return self:GetSceneLayer():GotoLogicPoint(old_x, old_y, s * 3)
    end

    -- 检查目标如果在原地，则打开原地的界面
    local new_x, new_y = self:GetClickedPos(x, y)
    if new_x == old_x and new_y == old_y and self:CheckCanMoveTo(old_x, old_y) then
        return self:OpenUI(old_x, old_y)
    end

    -- 检查行走偏移, 得到目标点
    local is_offset_x = math.abs(new_x - old_x) > math.abs(new_y - old_y)
    local offset_x = is_offset_x and (new_x - old_x) / math.abs(new_x - old_x) or 0
    local offset_y = is_offset_x and 0 or (new_y - old_y) / math.abs(new_y - old_y)
    local tx, ty = old_x + offset_x, old_y + offset_y

    -- 检查fte
    if not self:CheckCanMoveDelta(offset_x, offset_y) then return end

    if self:GetSceneLayer():CanMove(tx, ty) and
        self.user:HasAnyStength() then
        -- 能走的话检查fte

        if not self.user:GetPVEDatabase():IsInTrap() then
            self.user:GetPVEDatabase():ReduceNextEnemyStep()
        end

        self.user:UseStrength(1)
        self:GetSceneLayer():MoveCharTo(tx, ty)


        self:GetDirectionArrow()
            :EnableDirection(offset_x < 0, offset_x > 0, offset_y < 0, offset_y > 0)
            :performWithDelay(function()
                self:CheckDirection()
            end, 0.5)


        app:GetAudioManager():PlayeEffectSoundWithKey(string.format("PVE_MOVE%d", self.move_step))
        self.move_step = self.move_step + 1
        if self.move_step > 3 then
            self.move_step = 1
        end

        if self:GetSceneLayer():GetTileInfo(tx, ty) > 0 and
            self:CheckCanMoveTo(tx, ty) then
            self:CheckBuilding(tx, ty)
        else
            self:CheckTrap()
        end
    elseif not self.user:HasAnyStength() then
        -- 没体力则买体力
        if self.user:GetStaminaUsed() > 0 then
            self.user:ResetPveData()
            NetManager:getSetPveDataPromise(
                self.user:EncodePveDataAndResetFightRewardsData()
            ):fail(function()
                -- 失败回滚
                local location = DataManager:getUserData().pve.location
                self.user:GetPVEDatabase():SetCharPosition(location.x, location.y, location.z)
                self:GetSceneLayer():MoveCharTo(self.user:GetPVEDatabase():GetCharPosition())
            end)
        end
        WidgetUseItems.new():Create({
            item_type = WidgetUseItems.USE_TYPE.STAMINA
        }):AddToCurrentScene()
    end
end
local building_ui_map = setmetatable({
    [PVEDefine.START_AIRSHIP]      = WidgetPVEStartAirship,
    [PVEDefine.WOODCUTTER]         = WidgetPVEWoodcutter,
    [PVEDefine.QUARRIER]           = WidgetPVEQuarrier,
    [PVEDefine.MINER]              = WidgetPVEFteMiner,
    [PVEDefine.FARMER]             = WidgetPVEFarmer,
    [PVEDefine.CAMP]               = WidgetPVECamp,
    [PVEDefine.CRASHED_AIRSHIP]    = WidgetPVECrashedAirship,
    [PVEDefine.CONSTRUCTION_RUINS] = WidgetPVEConstructionRuins,
    [PVEDefine.KEEL]               = WidgetPVEKeel,
    [PVEDefine.WARRIORS_TOMB]      = WidgetPVEWarriorsTomb,
    [PVEDefine.OBELISK]            = WidgetPVEObelisk,
    [PVEDefine.ANCIENT_RUINS]      = WidgetPVEAncientRuins,
    [PVEDefine.ENTRANCE_DOOR]      = WidgetPVEEntranceDoor,
}, {__index = function() assert(false) end})
function PVEFteScene:OpenUI(x, y)
    local gid = self:GetSceneLayer():GetTileInfo(x, y)
    if gid ~= PVEDefine.MINER then return end
    local object = self.user:GetCurrentPVEMap():GetObjectByCoord(x, y)
    if not object or not object:Type() then
        self.user:GetCurrentPVEMap():ModifyObject(x, y, 0, gid)
    end
    return building_ui_map[gid].new(x, y, self.user):AddToScene(self, true)
end
function PVEFteScene:CheckCanMoveDelta(ox, oy)
    if not self.move_data then return true end
    local x,y = self:GetCurrentPos()
    return math.abs(x + ox - self.move_data.x) <= math.abs(x - self.move_data.x) and
        math.abs(y + oy - self.move_data.y) <= math.abs(y - self.move_data.y)
end
function PVEFteScene:CheckCanMoveTo(x, y)
    if not self.move_data then return true end
    if self.move_data.callback(x, y) then
        self.move_data = nil
        self:CheckDirection()
        return true
    end
    self:CheckDirection()
end
function PVEFteScene:PromiseOfMoveTo(x, y)
    local p = promise.new()
    self.move_data = {
        callback = function(x_, y_)
            if x == x_ and y == y_ then
                p:resolve()
                return true
            end
        end,
        x = x,
        y = y,
    }
    self:CheckDirection()
    return p
end
function PVEFteScene:CheckDirection()
    if self.move_data then
        local x,y = self:GetCurrentPos()
        if x == self.move_data.x and y == self.move_data.y then
            self:GetDirectionArrow():hide()
        else
            local left = x - self.move_data.x > 0
            local right = x - self.move_data.x < 0
            local up = y - self.move_data.y < 0
            local down = y - self.move_data.y > 0
            self:GetDirectionArrow():show()
                :EnableDirection(left, right, up, down)
        end
    else
        self:GetDirectionArrow():hide()
    end
end


-- fte
local check = import("..fte.check")
local mockData = import("..fte.mockData")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local WidgetFteMark = import("..widget.WidgetFteMark")
local NPC_POS = {9, 12}
function PVEFteScene:onEnterTransitionFinish()
    if GLOBAL_FTE then
        self:RunFte()
    end
end
function PVEFteScene:RunFte()
    self.touch_layer:removeFromParent()
    self:GetFteLayer():LockAll()
    local p = cocos_promise.defer()
    if not check("FightWithNpc1") then
        p:next(function()
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfFindNpc()
                :next(function(npc_ui)
                    return npc_ui:PormiseOfFte():next(function()
                        return npc_ui:PromiseOfExit()
                    end)
                end):next(function()
                return self:PromiseOfIntroduce()
                end):next(function()
                self:DestoryMark()
                return self:PromiseOfExit()
                end):next(function()
                return promise.new()
                end)
        end)
    end
    if not check("FightWithNpc2") then
        p:next(function()
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfFindNpc()
                :next(function(npc_ui)
                    return npc_ui:PormiseOfFte():next(function()
                        return npc_ui
                    end)
                end)
        end)
    end
    if not check("FightWithNpc3") then
        p:next(function(ui)
            if not ui then
                ui = self:OpenUI(unpack(NPC_POS))
            end
            return ui:PormiseOfFte()
                :next(function()
                    self:GetFteLayer():UnlockAll()
                    return ui:PromiseOfExit()
                end):next(function()
                return self:PromiseOfIntroduce1()
                end):next(function()
                return self:PromiseOfExit()
                end)
        end)
    end
end
function PVEFteScene:PromiseOfFindNpc()
    self:GetFteLayer():Enable()
    local npc_x, npc_y = unpack(NPC_POS)
    local x,y = self:GetSceneLayer():GetFog(npc_x, npc_y):getPosition()
    local cx,cy = self:GetCurrentPos()
    local str = (cx == npc_x and cy == npc_y) and _("请点击目标") or _("这里是我们的目的地，点击屏幕左侧向左移动")

    WidgetFteArrow.new(str):addTo(self:GetSceneLayer():GetFteLayer())
        :TurnDown():align(display.BOTTOM_CENTER, x + 45, y + 80)

    return promise.all(
        UIKit:PromiseOfOpen("WidgetPVEFteMiner"),
        self:PromiseOfMoveTo(npc_x, npc_y)
    ):next(function(results)
        self:GetSceneLayer():GetFteLayer():removeAllChildren()
        return results[1]
    end)
end
function PVEFteScene:PromiseOfIntroduce()
    self:GetFteLayer():Enable()
    return GameUINpc:PromiseOfSay(
        {
            words = _("领主大人，探索会消耗体力值，但击败敌军可以获得资源和材料…"),
            npc = "man",
            callback = function(npc_ui)
                local r = self:GetHomePage().pve_back:getCascadeBoundingBox()
                npc_ui.ui_map.background:FocusOnRect(r)
                self:GetMark():Size(r.width, r.height):pos(r.x + r.width/2, r.y + r.height/2)
            end
        }
    ):next(function()
        self:GetFteLayer():Disable()
        return GameUINpc:PromiseOfLeave()
    end)
end
function PVEFteScene:PromiseOfIntroduce1()
    self:GetFteLayer():Enable()
    return GameUINpc:PromiseOfSay(
        {words = _("亡灵兵种属性极高而且没有维护费用,有了特殊材料,我们就可以招募他们了."), npc = "man"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end)
end
function PVEFteScene:PromiseOfExit()
    self:GetFteLayer():Reset()
    local r = self:GetHomePage().change_map:GetWorldRect()
    self:GetHomePage().change_map.btn:removeEventListenersByEvent("CLICKED_EVENT")
    self:GetHomePage().change_map.btn:onButtonClicked(function()
        app:EnterMyCityFteScene()
    end)
    self:GetHomePage():GetFteLayer():SetTouchRect(r)
    WidgetFteArrow.new(_("返回城市")):addTo(self:GetHomePage():GetFteLayer())
        :TurnDown(false):align(display.LEFT_BOTTOM, r.x + 20, r.y + r.width + 20)
end
function PVEFteScene:GetMark()
    if not self.mark then
        self.mark = WidgetFteMark.new():addTo(self):zorder(4000)
    end
    return self.mark
end
function PVEFteScene:DestoryMark()
    self.mark:removeFromParent()
    self.mark = nil
end

return PVEFteScene




















