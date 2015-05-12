local cocos_promise = import("..utils.cocos_promise")
local Localize = import("..utils.Localize")
local promise = import("..utils.promise")
local GameUIWatchTowerTroopDetail = import("..ui.GameUIWatchTowerTroopDetail")
local WidgetMoveHouse = import("..widget.WidgetMoveHouse")
local check = import("..fte.check")
local TutorialLayer = import("..ui.TutorialLayer")
local GameUINpc = import("..ui.GameUINpc")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local WidgetFteMark = import("..widget.WidgetFteMark")
local Arrow = import("..ui.Arrow")
local Sprite = import("..sprites.Sprite")
local SoldierManager = import("..entity.SoldierManager")
local User = import("..entity.User")
local NotifyItem = import("..entity.NotifyItem")
local CityScene = import(".CityScene")
local MyCityScene = class("MyCityScene", CityScene)


function MyCityScene:ctor(...)
    self.clicked_callbacks = {}
    self.util_node = display.newNode():addTo(self)
    MyCityScene.super.ctor(self, ...)
end
function MyCityScene:onEnter()
    MyCityScene.super.onEnter(self)
    self.home_page = self:CreateHomePage()
    -- self:GetSceneLayer():IteratorInnnerBuildings(function(_, building)
    --     self:GetSceneUILayer():NewUIFromBuildingSprite(building)
    -- end)

    self:GetCity():AddListenOnType(self, City.LISTEN_TYPE.UPGRADE_BUILDING)
    self:GetCity():GetUser():AddListenOnType(self, User.LISTEN_TYPE.BASIC)
    self:GetCity():GetSoldierManager():AddListenOnType(self, SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED)


    local alliance = Alliance_Manager:GetMyAlliance()
    local alliance_map = alliance:GetAllianceMap()
    local allianceShirine = alliance:GetAllianceShrine()
    alliance_map:AddListenOnType(allianceShirine, alliance_map.LISTEN_TYPE.BUILDING_INFO)
    app:sendApnIdIf()
end
function MyCityScene:onExit()
    MyCityScene.super.onExit(self)
end
function MyCityScene:EnterEditMode()
    MyCityScene.super.EnterEditMode(self)
    self:GetSceneUILayer():EnterEditMode()
    self:GetHomePage():DisplayOff()
end
function MyCityScene:LeaveEditMode()
    MyCityScene.super.LeaveEditMode(self)
    self:GetSceneUILayer():LeaveEditMode()
    self:GetHomePage():DisplayOn()
    self:GetSceneUILayer():removeChildByTag(WidgetMoveHouse.ADD_TAG, true)
end
-- 给对应建筑添加指示动画
function MyCityScene:AddIndicateForBuilding(building_sprite)
    self:GetSceneUILayer():ShowIndicatorOnBuilding(building_sprite)
end
function MyCityScene:GetHomePage()
    return self.home_page
end
function MyCityScene:onEnterTransitionFinish()
    self:RunFte()
end
function MyCityScene:CreateHomePage()
    if UIKit:GetUIInstance("GameUIHome") then
        UIKit:GetUIInstance("GameUIHome"):removeFromParent()
    end
    local home = UIKit:newGameUI('GameUIHome', self:GetCity()):AddToScene(self)
    home:setLocalZOrder(10)
    home:setTouchSwallowEnabled(false)
    return home
end
function MyCityScene:onExit()
    self:GetCity():GetUser():RemoveListenerOnType(self, User.LISTEN_TYPE.BASIC)
    self.home_page = nil
    MyCityScene.super.onExit(self)
end
function MyCityScene:PromiseOfClickBuilding(x, y, for_build, msg, arrow_param)
    self:BeginClickFte()

    self:GetSceneLayer()
        :FindBuildingBy(x, y)
        :next(function(building)
            local mx, my = building:GetEntity():GetMidLogicPosition()
            self:GotoLogicPoint(mx, my, 5)

            local mid,top = building:GetWorldPosition()
            local middle_point = self:GetInfoLayer():convertToNodeSpace(mid)
            local top_point = self:GetInfoLayer():convertToNodeSpace(top)

            local str
            if not msg then
                if building:GetEntity():GetType() == "ruins" then
                    str = string.format(_("点击空地：建造%s"), Localize.building_name[for_build])
                else
                    str = string.format(_("点击建筑：%s"), Localize.building_name[building:GetEntity():GetType()])
                end
            end

            self:GetInfoLayer():removeAllChildren()
            local arrow = WidgetFteArrow.new(msg or str)
                :addTo(self:GetInfoLayer()):TurnDown():pos(top_point.x, top_point.y + 50)

            if arrow_param then
                if arrow_param.direction == "up" then
                    arrow:TurnUp():pos(top_point.x + 0, top_point.y - 300)
                end
            end
        end)

    local p = promise.new()
    table.insert(self.clicked_callbacks, function(building)
        local x_, y_ = building:GetEntity():GetLogicPosition()
        if x == x_ and y == y_ then
            self:EndClickFte()
            p:resolve()
            return true
        end
    end)
    return p
end
function MyCityScene:BeginClickFte()
    self.clicked_callbacks = {}
    self:GetInfoLayer():removeAllChildren()
    self:GetFteLayer():Enable()
end
function MyCityScene:EndClickFte()
    self.clicked_callbacks = {}
    self:GetInfoLayer():removeAllChildren()
    self:GetFteLayer():Disable()
end
function MyCityScene:CheckClickPromise(building)
    if #self.clicked_callbacks > 0 then
        if self.clicked_callbacks[1](building) then
            table.remove(self.clicked_callbacks, 1)
            return
        end
        return true
    end
end
function MyCityScene:PromiseOfClickLockButton(building_type)
    return UIKit:PromiseOfOpen("GameUIUnlockBuilding"):next(function(ui)
        return ui
    end)
end
function MyCityScene:GetLockButtonsByBuildingType(building_type)
    local lock_button
    local location_id = self:GetCity():GetLocationIdByBuildingType(building_type)
    self:GetSceneUILayer():IteratorLockButtons(function(_, v)
        if v.sprite:GetEntity().location_id == location_id then
            lock_button = v
            return true
        end
    end)
    assert(lock_button)
    return lock_button
end



---
function MyCityScene:OnSoliderStarCountChanged(soldier_manager, soldier_star_changed)
    self:GetSceneLayer():OnSoliderStarCountChanged(soldier_manager, soldier_star_changed)
end
function MyCityScene:OnUserBasicChanged(user, changed)
    MyCityScene.super.OnUserBasicChanged(self, user, changed)
    if changed.terrain then
        self:ChangeTerrain(changed.terrain.new)
    end
end
function MyCityScene:OnUpgradingBegin()
    app:GetAudioManager():PlayeEffectSoundWithKey("UI_BUILDING_UPGRADE_START")
    self:GetSceneLayer():CheckCanUpgrade()
end
function MyCityScene:OnUpgrading()

end
function MyCityScene:OnUpgradingFinished(building)
    if building:GetType() == "wall" then
        self:GetSceneLayer():UpdateWallsWithCity(self:GetCity())
    end
    self:GetSceneLayer():CheckCanUpgrade()
    app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
end
function MyCityScene:OnCreateDecoratorSprite(building_sprite)
-- self:GetSceneUILayer():NewUIFromBuildingSprite(building_sprite)
end
function MyCityScene:OnDestoryDecoratorSprite(building_sprite)
-- app:GetAudioManager():PlayeEffectSoundWithKey("UI_BUILDING_DESTROY")
-- self:GetSceneUILayer():RemoveUIFromBuildingSprite(building_sprite)
end
function MyCityScene:OnTilesChanged(tiles)
    local city = self:GetCity()
    self:GetSceneUILayer():RemoveAllLockButtons()
    table.foreach(tiles, function(_, tile)
        if tile:GetEntity().location_id then
            local building = city:GetBuildingByLocationId(tile:GetEntity().location_id)
            if building and not building:IsUpgrading() then
                self:GetSceneUILayer():NewLockButtonFromBuildingSprite(tile)
            end
        end
    end)
end
function MyCityScene:OnTowersChanged(old_towers, new_towers)
-- table.foreach(old_towers, function(k, tower)
--     -- if tower:GetEntity():IsUnlocked() then
--     self:GetSceneUILayer():RemoveUIFromBuildingSprite(tower)
--     -- end
-- end)
-- table.foreach(new_towers, function(k, tower)
--     -- if tower:GetEntity():IsUnlocked() then
--     self:GetSceneUILayer():NewUIFromBuildingSprite(tower)
--     -- end
-- end)
end
function MyCityScene:OnGateChanged(old_walls, new_walls)
-- table.foreach(old_walls, function(k, wall)
--     if wall:GetEntity():IsGate() then
--         self:GetSceneUILayer():RemoveUIFromBuildingSprite(wall)
--     end
-- end)

-- table.foreach(new_walls, function(k, wall)
--     if wall:GetEntity():IsGate() then
--         self:GetSceneUILayer():NewUIFromBuildingSprite(wall)
--     end
-- end)
end
function MyCityScene:OnSceneScale(s)
    if self:GetSceneLayer():getScale() < (self:GetSceneLayer():GetScaleRange()) * 1.3 then
        -- self:GetSceneUILayer():HideLevelUpNode()
        self:GetSceneLayer():HideLevelUpNode()
    else
        -- self:GetSceneUILayer():ShowLevelUpNode()
        self:GetSceneLayer():ShowLevelUpNode()
    end
    local widget_move_house = self:GetSceneUILayer():getChildByTag(WidgetMoveHouse.ADD_TAG)
    if widget_move_house then
        widget_move_house:OnSceneScale()
    end
end
function MyCityScene:OnTouchClicked(pre_x, pre_y, x, y)
    if not MyCityScene.super.OnTouchClicked(self, pre_x, pre_y, x, y) then return end
    if self.util_node:getNumberOfRunningActions() > 0 then return end

    local building = self:GetSceneLayer():GetClickedObject(x, y)
    if building then
        self:GetSceneUILayer():HideIndicator()

        local buildings = {}
        if building:GetEntity():GetType() == "wall" then
            for i,v in ipairs(self:GetSceneLayer():GetWalls()) do
                table.insert(buildings, v)
            end
            for i,v in ipairs(self:GetSceneLayer():GetTowers()) do
                table.insert(buildings, v)
            end
        elseif building:GetEntity():GetType() == "tower" then
            buildings = {unpack(self:GetSceneLayer():GetTowers())}
        else
            buildings = {building}
        end

        app:lockInput(true)
        self.util_node:performWithDelay(function()
            app:lockInput(false)
        end, 0.5)
        Sprite:PromiseOfFlash(unpack(buildings)):next(function()
            if self:IsEditMode() then
                self:GetSceneUILayer():getChildByTag(WidgetMoveHouse.ADD_TAG):SetMoveToRuins(building)
                return
            end
            if self:CheckClickPromise(building) then
                return
            end
            self:OpenUI(building)
        end)
    elseif self:IsEditMode() then
        self:LeaveEditMode()
    end
end
local ui_map = setmetatable({
    ruins          = {"GameUIFteBuild"            ,                           },
    keep           = {"GameUIFteKeep"             ,        "upgrade",         },
    watchTower     = {"GameUIWatchTower"          ,                           },
    warehouse      = {"GameUIWarehouse"           ,       "resource",         },
    dragonEyrie    = {"GameUIFteDragonEyrieMain"  ,              nil, "dragon"},
    barracks       = {"GameUIFteBarracks"         ,        "recruit",         },
    hospital       = {"GameUIHospital"            ,           "heal",         },
    academy        = {"GameUIAcademy"             ,     "technology",         },
    materialDepot  = {"GameUIMaterialDepot"       ,           "info",         },
    blackSmith     = {"GameUIBlackSmith"          ,},
    foundry        = {"GameUIPResourceBuilding"   ,},
    stoneMason     = {"GameUIPResourceBuilding"   ,},
    lumbermill     = {"GameUIPResourceBuilding"   ,},
    mill           = {"GameUIPResourceBuilding"   ,},
    tradeGuild     = {"GameUITradeGuild"          ,            "buy",         },
    townHall       = {"GameUITownHall"            , "administration",         },
    toolShop       = {"GameUIToolShop"            ,    "manufacture",         },
    trainingGround = {"GameUIMilitaryTechBuilding",           "tech",         },
    hunterHall     = {"GameUIMilitaryTechBuilding",           "tech",         },
    stable         = {"GameUIMilitaryTechBuilding",           "tech",         },
    workshop       = {"GameUIMilitaryTechBuilding",           "tech",         },
    dwelling       = {"GameUIDwelling"            ,        "citizen",         },
    farmer         = {"GameUIFteResource"         ,},
    woodcutter     = {"GameUIResource"            ,},
    quarrier       = {"GameUIResource"            ,},
    miner          = {"GameUIResource"            ,},
    wall           = {"GameUIWall"                ,       "military",         },
    tower          = {"GameUITower"               ,},
    airship        = {},
    FairGround     = {},
}, {__index = function() assert(false) end})
function MyCityScene:OpenUI(building)
    local city = self:GetCity()
    if iskindof(building, "HelpedTroopsSprite") then
        local helped = city:GetHelpedByTroops()[building:GetIndex()]
        local type_ = GameUIWatchTowerTroopDetail.DATA_TYPE.HELP_DEFENCE
        local user = self.city:GetUser()
        UIKit:newGameUI("GameUIWatchTowerTroopDetail", type_, helped, user:Id(),false):AddToCurrentScene(true)
        return
    end
    local entity = building:GetEntity()
    entity = "tower" == entity:GetType() and entity:BelongCity():GetTower() or entity
    local type_ = entity:GetType()
    local uiarrays = ui_map[type_]
    if type_ == "ruins" and not self:IsEditMode() then
        UIKit:newGameUI(uiarrays[1], city, entity, uiarrays[2], uiarrays[3]):AddToScene(self, true)
    elseif type_ == "airship" then
        local dragon_manger = city:GetDragonEyrie():GetDragonManager()
        local dragon_type = dragon_manger:GetCanFightPowerfulDragonType()
        if #dragon_type > 0 or dragon_manger:GetDefenceDragon() then
            local _,_,index = self.city:GetUser():GetPVEDatabase():GetCharPosition()
            app:EnterPVEScene(index)
        else
            UIKit:showMessageDialog(_("陛下"),_("必须有一条空闲的龙，才能进入pve"))
        end
    elseif type_ == "FairGround" then
        UIKit:newGameUI("GameUIGacha", self.city):AddToScene(self, true):DisableAutoClose()
    else
        UIKit:newGameUI(uiarrays[1], city, entity, uiarrays[2], uiarrays[3]):AddToScene(self, true)
    end
end




-- fte
local check = import("..fte.check")
local mockData = import("..fte.mockData")
function MyCityScene:RunFte()
    if not GLOBAL_FTE then return end
    self:GetFteLayer():Enable()
    cocos_promise.defer():next(function()
        self:GetFteLayer():Disable()
        if not check("HateDragon") or 
            not check("DefenceDragon") then
            return self:PromiseOfHateDragonAndDefence()
        end
    end):next(function()
        if not check("BuildHouseAt_3_3") then
            return self:PromiseOfBuildFirstHouse(18, 12, "dwelling")
        end
    end):next(function()
        if not check("FinishBuildHouseAt_3_1") then
            return self:GetHomePage():PromiseOfFteFreeSpeedUp()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_keep_2") then
            return self:PromiseOfFirstUpgradeKeep()
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_keep_2") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_barracks_1") then
            return self:PromiseOfUnlockBuilding("barracks")
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_barracks_1") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("RecruitSoldier_swordsman_10") then
            return self:PromiseOfRecruitSoldier("swordsman")
        end
    end):next(function()
        if not check("BuildHouseAt_5_3") then
            return self:PromiseOfBuildHouse(8, 22, "farmer")
        end
    end):next(function()
        if not check("FinishBuildHouseAt_5_1") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("UpgradeHouseTo_5_3_2") then
            return self:PromiseOfUpgradeByBuildingType(8, 22, "farmer", _("点击农夫小屋, 将其升级到等级2"))
        end
    end):next(function()
        if not check("FinishBuildHouseAt_5_2") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("FightWithNpc") then
            return self:PromiseOfExplorePve()
        end
    end):next(function()
        if not check("ActiveVip") then
            return self:PromiseOfActiveVip()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_keep_3") then
            return self:PromiseOfUpgradeKeepTo5()
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_keep_3") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_keep_4") then
            return self:PromiseOfUpgradeKeepTo5()
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_keep_4") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_keep_5") then
            return self:PromiseOfUpgradeKeepTo5()
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_keep_5") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_hospital_1") then
            return self:PromiseOfUnlockHospital()
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_hospital_1") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_academy_1") then
            return self:PromiseOfUnlockBuilding("academy")
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_academy_1") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("UpgradeBuildingTo_materialDepot_1") then
            return self:PromiseOfUnlockBuilding("materialDepot")
        end
    end):next(function()
        if not check("FinishUpgradingBuilding_materialDepot_1") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("BuildHouseAt_6_3") then
            return self:PromiseOfBuildWoodcutter()
        end
    end):next(function()
        if not check("FinishBuildHouseAt_6_1") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("BuildHouseAt_7_3") then
            return self:PromiseOfBuildHouse(28, 22, "quarrier", _("建造石匠小屋"))
        end
    end):next(function()
        if not check("FinishBuildHouseAt_7_1") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        if not check("BuildHouseAt_8_3") then
            return self:PromiseOfBuildHouse(28, 12, "miner", _("建造矿工小屋"))
        end
    end):next(function()
        if not check("FinishBuildHouseAt_8_1") then
            return self:GetHomePage():PromiseOfFteInstantSpeedUp()
        end
    end):next(function()
        return self:PromiseOfFteEnd()
    end)
end
function MyCityScene:PromiseOfHateDragonAndDefence()
    return GameUINpc:PromiseOfSayImportant(
        {words = _("我们到了。。。现在你的伤也恢复的差不多了，让我们来测试一下你觉醒者的能力吧。。。"), brow = "smile"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfClickBuilding(18, 8)
    end):next(function()
        return UIKit:PromiseOfOpen("GameUIFteDragonEyrieMain")
    end):next(function(ui)
        return ui:PromiseOfFte()
    end)
end
function MyCityScene:PromiseOfBuildFirstHouse(x, y, house_type)
    return GameUINpc:PromiseOfSay(
        {words = _("拥有了驾驭龙族的力量，一定能击败邪恶的黑龙，重建帝国的荣耀！"), brow = "angry"},
        {words = _("不过可惜这座城市太弱小了，我们得重头开始发展。建造住宅为城市提供空闲城民，用于生产资源和招募部队。。。"), brow = "sad"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfBuildHouse(x, y, house_type)
    end)
end
function MyCityScene:PromiseOfBuildHouse(x, y, house_type, msg)
    return self:PromiseOfClickBuilding(x, y, house_type, msg)
        :next(function()
            return UIKit:PromiseOfOpen("GameUIFteBuild")
        end):next(function(ui)
        return ui:PromiseOfFte(house_type)
        end)
end
function MyCityScene:PromiseOfFirstUpgradeKeep()
    return GameUINpc:PromiseOfSayImportant(
        {words = _("非常好，现在我们来升级城堡！城堡等级越高，可以解锁更多建筑。。。")}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfUpgradeKeep()
    end)
end
function MyCityScene:PromiseOfUpgradeKeep()
    return self:PromiseOfClickBuilding(8, 8)
        :next(function()
            return UIKit:PromiseOfOpen("GameUIFteKeep")
        end):next(function(ui)
        return ui:PromiseOfFte()
        end)
end
function MyCityScene:PromiseOfUpgradeByBuildingType(x, y, type_, msg)
    return self:PromiseOfClickBuilding(x, y, nil, msg)
        :next(function()
            local ui = unpack(ui_map[type_])
            return UIKit:PromiseOfOpen(ui)
        end):next(function(ui)
        return ui:PromiseOfFte()
        end)
end
function MyCityScene:PromiseOfUnlockBuilding(building_type)
    self.touch_layer:setTouchEnabled(false)

    local x,y = self:GetCity():GetFirstBuildingByType(building_type):GetMidLogicPosition()
    local tutorial = TutorialLayer.new():addTo(self):Enable()

    return promise.all(
        self:GotoLogicPoint(x, y, 5):next(function()
            WidgetFteArrow.new(_("点击解锁新建筑"))
                :addTo(self:GetLockButtonsByBuildingType(building_type), 1, 123)
                :TurnUp():align(display.TOP_CENTER, 0, -50)

            tutorial:SetTouchObject(self:GetLockButtonsByBuildingType(building_type))
        end),
        self:PromiseOfClickLockButton(building_type)
    ):next(function()
        self.touch_layer:setTouchEnabled(true)

        tutorial:removeFromParent()

        self:GetLockButtonsByBuildingType(building_type):removeChildByTag(123)

        return UIKit:PromiseOfOpen("GameUIUnlockBuilding")
    end):next(function(ui)
        return ui:PormiseOfFte()
    end)
end
function MyCityScene:PromiseOfRecruitSoldier()
    return GameUINpc:PromiseOfSayImportant(
        {words = _("年轻人，带兵打仗可不是过家家，如果你信得过我这把老骨头，就让我来教教你。。。"), npc = "man"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfClickBuilding(6, 29)
    end):next(function()
        return UIKit:PromiseOfOpen("GameUIFteBarracks")
    end):next(function(ui)
        return ui:PromiseOfFte()
    end)
end
function MyCityScene:PromiseOfExplorePve()
    return GameUINpc:PromiseOfSayImportant(
        {words = _("很好，我没有看错你！从今天起，我，皇家骑士克里冈，愿带领我的手下追随大人征战四方。。。"), npc = "man"}
    ):next(function()
        mockData.GetSoldier()
        GameGlobalUI:showTips(
            _("获得奖励"),
            NotifyItem.new({type = "soldiers", name = "swordsman", count = 100},
                {type = "soldiers", name = "ranger", count = 100})
        )
    end):next(function()
        return GameUINpc:PromiseOfSay(
            {words = _("领主大人，光靠城市基本的资源产出，无法满足我们的发展需求。。。"), npc = "man"},
            {words = _("我倒是知道一个地方，有些危险，但有着丰富的物资，也许我们尝试着探索。。。"), npc = "man"}
        )
    end):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfClickBuilding(-9, 4, nil, _("点击飞艇进入探险地图"))
    end):next(function()
        return promise.new()
    end)
end
function MyCityScene:PromiseOfActiveVip()
    return GameUINpc:PromiseOfSayImportant(
        {words = _("领主大人，你跑到哪里去了，人家可是找了你半天了。。。我们得抓紧时间解锁更多建筑！"), brow = "smile"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:GetHomePage():PromiseOfActivePromise()
    end)
end
function MyCityScene:PromiseOfUpgradeKeepTo5()
    return self:PromiseOfClickBuilding(8, 8, nil, _("将城堡升级到5级"), {
        direction = "up"
    }):next(function()
        return UIKit:PromiseOfOpen("GameUIFteKeep")
    end):next(function(ui)
        return ui:PromiseOfFte()
    end)
end
function MyCityScene:PromiseOfUnlockHospital()
    return GameUINpc:PromiseOfSayImportant(
        {words = _("这还差不多！现在让我们一口气来解锁{医院}，{学院}，{材料库房}。。。"), brow = "smile"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfUnlockBuilding("hospital")
    end)
end
function MyCityScene:PromiseOfBuildWoodcutter()
    return GameUINpc:PromiseOfSayImportant(
        {words = _("城市是不是一下繁荣起来了呢？建造{木工小屋}，{石匠小屋}，{旷工小屋}，就算领主你不在，资源也会不停的增长。。。")}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfBuildHouse(18, 22, "woodcutter", _("建造木工小屋"))
    end)
end
local FTE_MARK_TAG = 120
function MyCityScene:PromiseOfFteEnd()
    local r = self:GetHomePage().quest_bar_bg:getCascadeBoundingBox()
    WidgetFteMark.new():addTo(self, 4000, FTE_MARK_TAG):Size(r.width, r.height)
    :pos(r.x + r.width/2, r.y + r.height/2)

    GameUINpc:PromiseOfSayImportant(
        {words = _("看来大人你已经能够顺利接管这座城市了。。。如果不知道该干什么可以点击左上角的推荐任务")}
    ):next(function()
        self:removeChildByTag(FTE_MARK_TAG)
        return GameUINpc:PromiseOfSayImportant({words = _("完成任务后，可以点击任务按钮，我为大人准备了丰厚的奖赏。。。")})
    end):next(function()
        app:EnterUserMode()
        app:EnterMyCityScene()
    end)
end


function MyCityScene:PromiseOfGetRewards()
    self:GetHomePage():GetFteLayer().mark = WidgetFteMark.new():addTo(self:GetHomePage():GetFteLayer())
    local r = self:GetHomePage().quest_bar_bg:getCascadeBoundingBox()
    self:GetHomePage():GetFteLayer():SetTouchObject(self:GetHomePage().quest_bar_bg)
    self:GetHomePage():GetFteLayer().mark:Size(r.width, r.height):pos(r.x + r.width/2, r.y + r.height/2)

    return GameUINpc:PromiseOfSayImportant({words = _("看来大人你已经能够顺利接管这座城市了。。。如果不知道该干什么可以点击左上角的推荐任务")}):next(function()
        self:GetHomePage():GetFteLayer():removeFromParent()
        return GameUINpc:PromiseOfSayImportant({words = _("完成任务后，可以点击任务按钮，我为大人准备了丰厚的奖赏。。。")})
    end):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        self:GetHomePage():GetFteLayer():SetTouchObject(self:GetHomePage().bottom.task_btn)
        local arrow = WidgetFteArrow.new(_("点击任务"))
            :addTo(self:GetHomePage().bottom.task_btn)
            :TurnDown():align(display.CENTER, 0, 70)
        return UIKit:PromiseOfOpen("GameUIMission"):next(function(ui)
            arrow:removeFromParent()
            self:GetHomePage():GetFteLayer():removeFromParent()
            return ui:PromiseOfFte()
        end)
    end):next(function()
        return GameUINpc:PromiseOfSayImportant({words = _("大人，如今我们已经初具规模，但这个世界上的觉醒者却不止你一人，同他们是战是和就在你一念之间。。。")})
    end):next(function()
        return GameUINpc:PromiseOfLeave()
    end)
end


return MyCityScene



