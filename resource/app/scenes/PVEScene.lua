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
local PVELayer = import("..layers.PVELayer")
local GameUIPVEHome = import("..ui.GameUIPVEHome")
local GameUINpc = import("..ui.GameUINpc")
local UILib = import("..ui.UILib")
local MapScene = import(".MapScene")
local PVEScene = class("PVEScene", MapScene)
local DIRECTION_TAG = 911


local timer = app.timer
function PVEScene:ctor(user)
    PVEScene.super.ctor(self)
    self.user = user
    self.move_step = 1
end
function PVEScene:onEnter()
    PVEScene.super.onEnter(self)
    self.home_page = self:CreateHomePage()
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(self.user:GetPVEDatabase():GetCharPosition())
    self:GetSceneLayer():GotoMapPositionInMiddle(point.x, point.y)
    self:GetSceneLayer():ZoomTo(0.8)
    self:GetSceneLayer():MoveCharTo(self.user:GetPVEDatabase():GetCharPosition())
    app:GetAudioManager():PlayGameMusicOnSceneEnter("PVEScene",true)
    self.user:GetPVEDatabase():SetLocationHandle(self)
end
function PVEScene:onEnterTransitionFinish()
    local userdefault = cc.UserDefault:getInstance()
    local pve_key = DataManager:getUserData()._id.."_first_in_pve"
    if not userdefault:getBoolForKey(pve_key) then
        userdefault:setBoolForKey(pve_key, true)
        userdefault:flush()

        UIKit:newGameUI("GameUITips", "pve", _("玩法介绍"), true):AddToScene(self, true)
    end
    local task = City:GetRecommendTask()
    if task then
        if task:TaskType() == "explore" then
            City:SetBeginnersTaskFlag(task:Index())
        end
    end
end
function PVEScene:onExit()
    PVEScene.super.onExit(self)
    self.user:ResetPveData()
    local location = DataManager:getUserData().pve.location
    local x,y,z = self.user:GetPVEDatabase():GetCharPosition()
    if location.x ~= x or location.y ~= y or location.z ~= z then
        NetManager:getSetPveDataPromise(
            self.user:EncodePveDataAndResetFightRewardsData(),
            true
        ):fail(function()
            -- 失败回滚
            local location = DataManager:getUserData().pve.location
            User:GetPVEDatabase():SetCharPosition(location.x, location.y, location.z)
        end)
    end
end
function PVEScene:GetPreloadImages()
    return {
        {image = "animations/heihua_animation_0.pvr.ccz",list = "animations/heihua_animation_0.plist"},
        {image = "animations/heihua_animation_1.pvr.ccz",list = "animations/heihua_animation_1.plist"},
        {image = "animations/heihua_animation_2.pvr.ccz",list = "animations/heihua_animation_2.plist"},
        {image = "animations/region_animation_0.pvr.ccz",list = "animations/region_animation_0.plist"},
        {image = "animations/building_animation.pvr.ccz",list = "animations/building_animation.plist"},
        {image = "pve_png_rgba5555.pvr.ccz",list = "pve_png_rgba5555.plist"},
    }
end
function PVEScene:CreateDirectionArrow()
    if not self:getChildByTag(DIRECTION_TAG) then
        return WidgetDirectionSelect.new():pos(display.cx, display.cy)
            :addTo(self, 10, DIRECTION_TAG):EnableDirection():hide():scale(1.5)
    end
end
function PVEScene:GetDirectionArrow()
    if not self:getChildByTag(DIRECTION_TAG) then
        return self:CreateDirectionArrow()
    end
    return self:getChildByTag(DIRECTION_TAG)
end
function PVEScene:DestroyDirectionArrow()
    self:removeChildByTag(DIRECTION_TAG)
end
function PVEScene:CreateSceneLayer()
    return PVELayer.new(self, self.user)
end
function PVEScene:CreateHomePage()
    local home_page = GameUIPVEHome.new(self.user, self):AddToScene(self, true)
    home_page:setLocalZOrder(10)
    home_page:setTouchSwallowEnabled(false)
    return home_page
end
function PVEScene:GetHomePage()
    return self.home_page
end
function PVEScene:OnLocationChanged(is_pos_changed, is_switch_floor)
    local location = DataManager:getUserData().pve.location
    if is_switch_floor then
        self.user:GetPVEDatabase():SetCharPosition(location.x, location.y, location.z)
        app:EnterPVEScene(location.z)
    elseif is_pos_changed then
        self:GetSceneLayer():MoveCharTo(location.x, location.y)
    end
    assert(false)
end
function PVEScene:PormiseOfCheckObject(x, y, type)
    local object = self.user:GetCurrentPVEMap():GetObjectByCoord(x, y)
    if not object or not object:Type() then
        self.user:GetCurrentPVEMap():ModifyObject(x, y, 0, type)
        self.user:ResetPveData()
        return NetManager:getSetPveDataPromise(
            self.user:EncodePveDataAndResetFightRewardsData()
        ):fail(function()
            -- 失败回滚
            local location = DataManager:getUserData().pve.location
            self.user:GetPVEDatabase():SetCharPosition(location.x, location.y, location.z)
            self:GetSceneLayer():MoveCharTo(self.user:GetPVEDatabase():GetCharPosition())
        end)
    else
        return cocos_promise.defer()
    end
end
function PVEScene:OnTwoTouch()

end
function PVEScene:GetCurrentPos()
    local logic_map = self:GetSceneLayer():GetLogicMap()
    local char_x,char_y = self:GetSceneLayer():GetChar():getPosition()
    return logic_map:ConvertToLogicPosition(char_x, char_y)
end
function PVEScene:GetClickedPos(x, y)
    local logic_map = self:GetSceneLayer():GetLogicMap()
    local point = self:GetSceneLayer():GetSceneNode():convertToNodeSpace(cc.p(x, y))
    return logic_map:ConvertToLogicPosition(point.x, point.y)
end
function PVEScene:GetCenterPos()
    local logic_map = self:GetSceneLayer():GetLogicMap()
    local point = self:GetSceneLayer():GetSceneNode():convertToNodeSpace(cc.p(display.cx, display.cy))
    return logic_map:ConvertToLogicPosition(point.x, point.y)
end
function PVEScene:OnTouchClicked(pre_x, pre_y, x, y)
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
    if new_x == old_x and new_y == old_y then
        return self:OpenUI(old_x, old_y)
    end
    -- 检查行走偏移, 得到目标点
    local is_offset_x = math.abs(new_x - old_x) > math.abs(new_y - old_y)
    local offset_x = is_offset_x and (new_x - old_x) / math.abs(new_x - old_x) or 0
    local offset_y = is_offset_x and 0 or (new_y - old_y) / math.abs(new_y - old_y)
    local tx, ty = old_x + offset_x, old_y + offset_y



    self:GetDirectionArrow()
        :ShowDirection(offset_x < 0, offset_x > 0, offset_y < 0, offset_y > 0)
        :show():runAction(transition.sequence{cc.FadeIn:create(0.25), cc.FadeOut:create(0.25)})


    if self:GetSceneLayer():CanMove(tx, ty) and
        self.user:HasAnyStength() then

        if not self.user:GetPVEDatabase():IsInTrap() then
            self.user:GetPVEDatabase():ReduceNextEnemyStep()
        end

        self.user:UseStrength(1)
        self:GetSceneLayer():MoveCharTo(tx, ty)

        app:GetAudioManager():PlayeEffectSoundWithKey(string.format("PVE_MOVE%d", self.move_step))
        self.move_step = self.move_step + 1
        if self.move_step > 3 then
            self.move_step = 1
        end

        if self:GetSceneLayer():GetTileInfo(tx, ty) > 0 then
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
function PVEScene:CheckBuilding(x, y)
    local gid = self:GetSceneLayer():GetTileInfo(x, y)
    if gid <= 0 then return end
    self:PormiseOfCheckObject(x, y, gid):done(function()
        self:OpenUI(x, y)
    end)
end
local building_ui_map = setmetatable({
    [PVEDefine.START_AIRSHIP]      = WidgetPVEStartAirship,
    [PVEDefine.WOODCUTTER]         = WidgetPVEWoodcutter,
    [PVEDefine.QUARRIER]           = WidgetPVEQuarrier,
    [PVEDefine.MINER]              = WidgetPVEMiner,
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
function PVEScene:OpenUI(x, y)
    local gid = self:GetSceneLayer():GetTileInfo(x, y)
    if gid <= 0 then return end
    local object = self.user:GetCurrentPVEMap():GetObjectByCoord(x, y)
    if not object or not object:Type() then
        self.user:GetCurrentPVEMap():ModifyObject(x, y, 0, gid)
    end
    return building_ui_map[gid].new(x, y, self.user):AddToScene(self, true)
end
function PVEScene:CheckTrap()
    if self.user:GetPVEDatabase():IsInTrap() then
        self:GetSceneLayer():PromiseOfTrap():next(function()
            local trap_obj = PVEObject.new(0, 0, 0, PVEDefine.TRAP, self:GetSceneLayer():CurrentPVEMap())
            local enemy = trap_obj:GetNextEnemy()
            UIKit:newGameUI('GameUIPVESendTroop',
                enemy.soldiers,-- pve 怪数据
                function(dragonType, soldiers)
                    local dragon = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager():GetDragon(dragonType)

                    local attack_soldier = LuaUtils:table_map(soldiers, function(k, v)
                        return k, {
                            name = v.name,
                            star = v.star,
                            count = v.count
                        }
                    end)

                    local report = DataUtils:DoBattle(
                        {dragon = dragon, soldiers = attack_soldier},
                        {dragon = enemy.dragon, soldiers = enemy.soldiers},
                        trap_obj:GetMap():Terrain(), _("散兵游勇")
                    )

                    if report:IsAttackWin() then
                        self.user:SetPveData(report:GetAttackKDA(), enemy.rewards)
                    else
                        self.user:SetPveData(report:GetAttackKDA())
                    end

                    NetManager:getSetPveDataPromise(
                        self.user:EncodePveDataAndResetFightRewardsData()
                    ):done(function()
                        UIKit:newGameUI("GameUIReplayNew", report, function()
                            if report:IsAttackWin() then
                                GameGlobalUI:showTips(_("获得奖励"), enemy.rewards)
                            end
                        end):AddToCurrentScene(true)

                        self:CheckPveTask(report)

                    end)
                end):AddToCurrentScene(true)
        end)
        self.user:GetPVEDatabase():ResetNextEnemyCounter()
    end
end
function PVEScene:CheckPveTask(report)
    local target,ok = self.user:GetPVEDatabase():GetTarget()
    if ok and target.target > target.count then
        for i,v in ipairs(report:GetDefenceKDA().soldiers) do
            if v.name == target.name then
                self.user:GetPVEDatabase():IncKillCount(v.damagedCount)
                break
            end
        end
    end
    self:GetHomePage().event_tab:PromiseOfSwitch()
end



return PVEScene






















