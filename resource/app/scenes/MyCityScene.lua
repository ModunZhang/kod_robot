local cocos_promise = import("..utils.cocos_promise")
local promise = import("..utils.promise")
local GameUIWatchTowerTroopDetail = import("..ui.GameUIWatchTowerTroopDetail")
local WidgetMoveHouse = import("..widget.WidgetMoveHouse")
local TutorialLayer = import("..ui.TutorialLayer")
local GameUINpc = import("..ui.GameUINpc")
local Arrow = import("..ui.Arrow")
local Sprite = import("..sprites.Sprite")
local SoldierManager = import("..entity.SoldierManager")
local City = import("..entity.City")
local User = import("..entity.User")
local CityScene = import(".CityScene")
local MyCityScene = class("MyCityScene", CityScene)


function MyCityScene:ctor(...)
    self.util_node = display.newNode():addTo(self)
    MyCityScene.super.ctor(self, ...)
    self.clicked_callbacks = {}
end
function MyCityScene:onEnter()
    MyCityScene.super.onEnter(self)
    self.arrow_layer = self:CreateArrowLayer()
    self.tutorial_layer = self:CreateTutorialLayer()
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
function MyCityScene:GetArrowTutorial()
    if not self.arrow_tutorial then
        local arrow_tutorial = TutorialLayer.new():addTo(self)
        self.arrow_tutorial = arrow_tutorial
    end
    return self.arrow_tutorial
end
function MyCityScene:DestoryArrowTutorial(func)
    if self.arrow_tutorial then
        self.arrow_tutorial:removeFromParent()
        self.arrow_tutorial = nil
    end
    return cocos_promise.defer(func)
end
function MyCityScene:GetHomePage()
    return self.home_page
end
function MyCityScene:onEnterTransitionFinish()
    if device.platform == "mac" then
        return
    end
    local city = self:GetCity()
    local scene = self
    local check_map = {
        [1] = function()
            if #City:GetUnlockedFunctionBuildings() <= 4 then
                return City:GetHouseByPosition(12, 12)
            end
            return true
        end,
        [2] = function()
            if #City:GetUnlockedFunctionBuildings() <= 4 then
                local building = City:GetHouseByPosition(12, 12)
                return not building:IsUpgrading() and building:GetLevel() == 1
            end
            return true
        end,
        [3] = function()
            if #City:GetUnlockedFunctionBuildings() <= 4 then
                return City:GetHouseByPosition(15, 12)
            end
            return true
        end,
        [4] = function()
            if #City:GetUnlockedFunctionBuildings() <= 4 then
                local building = City:GetHouseByPosition(15, 12)
                return not building:IsUpgrading() and building:GetLevel() == 1
            end
            return true
        end,
        [5] = function()
            if #City:GetUnlockedFunctionBuildings() <= 4 then
                return City:GetHouseByPosition(18, 12)
            end
            return true
        end,
        [6] = function()
            if #City:GetUnlockedFunctionBuildings() <= 4 then
                local building = City:GetHouseByPosition(18, 12)
                return not building:IsUpgrading() and building:GetLevel() == 1
            end
            return true
        end,
        [7] = function()
            if #City:GetUnlockedFunctionBuildings() <= 4 then
                local building = City:GetFirstBuildingByType("keep")
                return building:GetLevel() == 2 or (building:IsUpgrading() and building:GetLevel() == 1)
            end
            return true
        end,
        [8] = function()
            if #City:GetUnlockedFunctionBuildings() <= 4 then
                local building = City:GetFirstBuildingByType("keep")
                return not building:IsUpgrading() and building:GetLevel() == 2
            end
            return true
        end,
        [9] = function()
            if #City:GetUnlockedFunctionBuildings() <= 4 then
                return false
            end
            return true
        end,
        [10] = function()
            if #City:GetUnlockedFunctionBuildings() <= 5 then
                local building = City:GetFirstBuildingByType("barracks")
                return not building:IsUpgrading() and building:GetLevel() == 1
            end
            return true
        end,
        [11] = function()
            local count = City:GetSoldierManager():GetCountBySoldierType("swordsman")
            local barracks = City:GetFirstBuildingByType("barracks")
            if count > 0 or barracks:IsRecruting() then
                return true
            end
        end,
    }
    local function check(step)
        local check_func = check_map[step]
        return not check_func and true or check_func()
    end
end
function MyCityScene:CreateHomePage()
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
function MyCityScene:GetTutorialLayer()
    return self.tutorial_layer
end
function MyCityScene:PromiseOfClickBuilding(x, y)
    assert(#self.clicked_callbacks == 0)
    local arrow
    self:GetSceneLayer():FindBuildingBy(x, y):next(function(building)
        arrow = Arrow.new():addTo(self.arrow_layer)
        building:AddObserver(arrow)
        building:OnSceneMove()
    end)
    local p = promise.new()
    self:GetTutorialLayer():Enable()
    table.insert(self.clicked_callbacks, function(building)
        local x_, y_ = building:GetEntity():GetLogicPosition()
        if x == x_ and y == y_ then
            self:GetTutorialLayer():Disable()
            self:GetSceneLayer():FindBuildingBy(x, y):next(function(building)
                building:RemoveObserver(arrow)
                arrow:removeFromParent()
            end)
            p:resolve(building)
            return true
        end
    end)
    return p
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
    local btn = self:GetLockButtonsByBuildingType(building_type)
    local tutorial_layer = TutorialLayer.new(btn):addTo(self):Enable()
    local rect = btn:getCascadeBoundingBox()
    Arrow.new():addTo(tutorial_layer):OnPositionChanged(rect.x, rect.y)
    return UIKit:PromiseOfOpen("GameUIUnlockBuilding"):next(function(ui)
        tutorial_layer:removeFromParent()
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
    return cocos_promise.defer(function() return lock_button end)
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
function MyCityScene:OnSceneScale(scene_layer)
    if scene_layer:getScale() < (scene_layer:GetScaleRange()) * 1.3 then
        -- self:GetSceneUILayer():HideLevelUpNode()
        scene_layer:HideLevelUpNode()
    else
        -- self:GetSceneUILayer():ShowLevelUpNode()
        scene_layer:ShowLevelUpNode()
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
function MyCityScene:OpenUI(building)
    local city = self:GetCity()
    if iskindof(building, "HelpedTroopsSprite") then
        local helped = city:GetHelpedByTroops()[building:GetIndex()]
        local type_ = GameUIWatchTowerTroopDetail.DATA_TYPE.HELP_DEFENCE
        local user = self.city:GetUser()
        UIKit:newGameUI("GameUIWatchTowerTroopDetail", type_, helped, user:Id(),false):AddToCurrentScene(true)
        return
    end
    local type_ = building:GetEntity():GetType()
    if type_ == "ruins" and not self:IsEditMode() then
        UIKit:newGameUI('GameUIBuild', city, building:GetEntity()):AddToScene(self, true)
    elseif type_ == "keep" then
        self._keep_page = UIKit:newGameUI('GameUIKeep',city,building:GetEntity())
        self._keep_page:AddToScene(self, true)
    elseif type_ == "dragonEyrie" then
        UIKit:newGameUI('GameUIDragonEyrieMain', city,building:GetEntity()):AddToCurrentScene(true)
    elseif type_ == "toolShop" then
        UIKit:newGameUI('GameUIToolShop', city, building:GetEntity()):AddToScene(self, true)
    elseif type_ == "blackSmith" then
        UIKit:newGameUI('GameUIBlackSmith', city, building:GetEntity()):AddToScene(self, true)
    elseif type_ == "materialDepot" then
        UIKit:newGameUI('GameUIMaterialDepot', city, building:GetEntity()):AddToScene(self, true)
    elseif type_ == "barracks" then
        UIKit:newGameUI('GameUIBarracks', city, building:GetEntity()):AddToScene(self, true)
    elseif type_ == "academy" then
        self._armyCamp_page = UIKit:newGameUI('GameUIAcademy',city,building:GetEntity()):AddToScene(self, true)
    elseif type_ == "townHall" then
        self._armyCamp_page = UIKit:newGameUI('GameUITownHall',city,building:GetEntity()):AddToScene(self, true)
    elseif type_ == "foundry"
        or type_ == "stoneMason"
        or type_ == "lumbermill"
        or type_ == "mill" then
        self._armyCamp_page = UIKit:newGameUI('GameUIPResourceBuilding',city,building:GetEntity()):AddToScene(self, true)
    elseif type_ == "warehouse" then
        self._warehouse_page = UIKit:newGameUI('GameUIWarehouse',city,building:GetEntity())
        self._warehouse_page:AddToScene(self, true)
    elseif iskindof(building:GetEntity(), 'ResourceUpgradeBuilding') then
        if type_ == "dwelling" then
            UIKit:newGameUI('GameUIDwelling',building:GetEntity(), city):AddToCurrentScene(true)
        else
            UIKit:newGameUI('GameUIResource',building:GetEntity()):AddToCurrentScene(true)
        end
    elseif type_ == "hospital" then
        UIKit:newGameUI('GameUIHospital', city, building:GetEntity()):AddToScene(self, true)
    elseif type_ == "watchTower" then
        UIKit:newGameUI('GameUIWatchTower', city, building:GetEntity()):AddToScene(self, true)
    elseif type_ == "tradeGuild" then
        UIKit:newGameUI('GameUITradeGuild', city, building:GetEntity()):AddToScene(self, true)
    elseif type_ == "wall" then
        UIKit:newGameUI('GameUIWall', city, building:GetEntity()):AddToScene(self, true)
    elseif type_ == "tower" then
        UIKit:newGameUI('GameUITower', city, building:GetEntity():BelongCity():GetTower()):AddToScene(self, true)
    elseif type_ == "trainingGround"
        or type_ == "stable"
        or type_ == "hunterHall"
        or type_ == "workshop"
    then
        UIKit:newGameUI('GameUIMilitaryTechBuilding', city, building:GetEntity()):AddToScene(self, true)
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
        UIKit:newGameUI("GameUIGacha", self.city):AddToCurrentScene(true):DisableAutoClose()
    end
end
return MyCityScene

































