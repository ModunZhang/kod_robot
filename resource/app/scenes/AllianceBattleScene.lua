local Sprite = import("..sprites.Sprite")
local UILib = import("..ui.UILib")
local window = import("..utils.window")
local MultiAllianceLayer = import("..layers.MultiAllianceLayer")
local WidgetPushButton = import("..widget.WidgetPushButton")
local MapScene = import(".MapScene")
local AllianceBattleScene = class("AllianceBattleScene", MapScene)
local GameUIAllianceHome = import("..ui.GameUIAllianceHome")
local Alliance = import("..entity.Alliance")

function AllianceBattleScene:ctor(location)
    self.location = location
    self.util_node = display.newNode():addTo(self)
    AllianceBattleScene.super.ctor(self)
end
function AllianceBattleScene:onEnter()
    AllianceBattleScene.super.onEnter(self)
    self:CreateAllianceUI()
    self:GetAlliance():AddListenOnType(self, Alliance.LISTEN_TYPE.BASIC)
    app:GetAudioManager():PlayGameMusicOnSceneEnter("AllianceBattleScene",false)
    self:GetSceneLayer():ZoomTo(0.82)
    local alliance_key = DataManager:getUserData()._id.."_SHOW_REGION_TIPS"
    if not app:GetGameDefautlt():getBasicInfoValueForKey(alliance_key) then
        app:GetGameDefautlt():getBasicInfoValueForKey(alliance_key,true)
        UIKit:newGameUI("GameUITips","region",_("玩法介绍"), true):AddToScene(self, true)
    end
    if self.location then
        self:GotoPosition(self.location.x, self.location.y,self.location.id)
        if self.location.callback then
            self.location.callback(self)
        end
    else
        self:GotoCurrentPosition()
    end
            if not UIKit:GetUIInstance('GameUIWarSummary') and self:GetAlliance():LastAllianceFightReport() then
                UIKit:newGameUI("GameUIWarSummary"):AddToCurrentScene(true)
            end
    -- cc.ui.UIPushButton.new({normal = "lock_btn.png",pressed = "lock_btn.png"})
    -- :addTo(self, 1000000):align(display.RIGHT_TOP, display.width, display.height)
    -- :onButtonClicked(function(event)
    --     app:onEnterBackground()
    -- end)

    -- cc.ui.UIPushButton.new({normal = "lock_btn.png",pressed = "lock_btn.png"})
    -- :addTo(self, 1000000):align(display.RIGHT_TOP, display.width, display.height - 100)
    -- :onButtonClicked(function(event)
    --     app:onEnterForeground()
    -- end)
end
function AllianceBattleScene:GotoCurrentPosition()
    local mapObject = self:GetAlliance():FindMapObjectById(self:GetAlliance():GetSelf():MapId())
    local location = mapObject.location
    self:GotoPosition(location.x,location.y,self:GetAlliance().id)
end
function AllianceBattleScene:GotoPosition(x,y,aid)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x,y,aid)
    self:GetSceneLayer():GotoMapPositionInMiddle(point.x, point.y)
end
function AllianceBattleScene:GetPreloadImages()
    return {
        {image = "animations/heihua_animation_0.pvr.ccz",list = "animations/heihua_animation_0.plist"},
        {image = "animations/heihua_animation_1.pvr.ccz",list = "animations/heihua_animation_1.plist"},
        {image = "animations/heihua_animation_2.pvr.ccz",list = "animations/heihua_animation_2.plist"},
        {image = "animations/region_animation_0.pvr.ccz",list = "animations/region_animation_0.plist"},
        {image = "region_png.pvr.ccz",list = "region_png.plist"},
        {image = "region_pvr.pvr.ccz",list = "region_pvr.plist"},
    }
end
function AllianceBattleScene:CreateAllianceUI()
    local home_page = GameUIAllianceHome.new(self:GetAlliance(), self:GetSceneLayer()):addTo(self)
    home_page:setTouchSwallowEnabled(false)
    self.home_page = home_page
end
function AllianceBattleScene:GetHomePage()
    return self.home_page
end
function AllianceBattleScene:GetAlliance()
    return Alliance_Manager:GetMyAlliance()
end

function AllianceBattleScene:GetEnemyAlliance()
    return Alliance_Manager:GetEnemyAlliance()
end

function AllianceBattleScene:onExit()
    self:GetAlliance():RemoveListenerOnType(self, Alliance.LISTEN_TYPE.BASIC)
    AllianceBattleScene.super.onExit(self)
end
function AllianceBattleScene:CreateSceneLayer()
    local arrange = (pos == "top" or pos == "bottom") and MultiAllianceLayer.ARRANGE.V or MultiAllianceLayer.ARRANGE.H
    if pos == "top" or pos == "left" then
        return MultiAllianceLayer.new(self, arrange, self:GetAlliance(), self:GetEnemyAlliance())
    else
        return MultiAllianceLayer.new(self, arrange, self:GetEnemyAlliance(), self:GetAlliance())
    end
end
function AllianceBattleScene:GotoLogicPosition(x, y, id)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x, y, id)
    return self:GetSceneLayer():PromiseOfMove(point.x, point.y)
end
function AllianceBattleScene:OnTouchBegan(...)
    AllianceBattleScene.super.OnTouchBegan(self, ...)
    self:GetSceneLayer():TrackCorpsById(nil)
end
function AllianceBattleScene:OnTouchClicked(pre_x, pre_y, x, y)
    if self.event_manager:TouchCounts() ~= 0 or 
        self.util_node:getNumberOfRunningActions() > 0 then 
        return 
    end

    local building,isMyAlliance = self:GetSceneLayer():GetClickedObject(x, y)
    if building then
        app:lockInput(true)
        self.util_node:performWithDelay(function()
            app:lockInput(false)
        end, 0.5)

        self.event_manager:RemoveAllTouches()
        
        app:GetAudioManager():PlayeEffectSoundWithKey("HOME_PAGE")
        local entity = building:GetEntity()
        if iskindof(building, "Sprite") then
            Sprite:PromiseOfFlash(building):next(function()
                self:OpenUI(entity, isMyAlliance)
            end)
        else
            self:GetSceneLayer():PromiseOfFlashEmptyGround(building, isMyAlliance):next(function()
                self:OpenUI(entity, isMyAlliance)
            end)
        end
    end
end
function AllianceBattleScene:OpenUI(entity, isMyAlliance)
    if entity:GetType() ~= "building" then
        self:EnterNotAllianceBuilding(entity, isMyAlliance)
    else
        self:EnterAllianceBuilding(entity, isMyAlliance)
    end
end
function AllianceBattleScene:OnAllianceBasicChanged(alliance,deltaData)
end
function AllianceBattleScene:EnterAllianceBuilding(entity,isMyAlliance)
    local building_info
    if isMyAlliance then
        building_info = self:GetAlliance():FindAllianceBuildingInfoByObjects(entity)
    else
        building_info = self:GetEnemyAlliance():FindAllianceBuildingInfoByObjects(entity)
    end
    local building_name = building_info.name
    local class_name = ""
    if building_name == 'shrine' then
        class_name = "GameUIAllianceShrineEnter"
    elseif building_name == 'palace' then
        class_name = "GameUIAlliancePalaceEnter"
    elseif building_name == 'shop' then
        class_name = "GameUIAllianceShopEnter"
    elseif building_name == 'orderHall' then
        class_name = "GameUIAllianceOrderHallEnter"
    elseif building_name == 'moonGate' then
        class_name = "GameUIAllianceMoonGateEnter"
    else
        print("没有此建筑--->",building_name)
        return
    end
    UIKit:newGameUI(class_name,entity,isMyAlliance,self:GetAlliance(),self:GetEnemyAlliance()):AddToCurrentScene(true)
end

function AllianceBattleScene:EnterNotAllianceBuilding(entity,isMyAlliance)
    local alliance = isMyAlliance and self:GetAlliance() or self:GetEnemyAlliance()
    local type_ = entity:GetType()
    local class_name = ""
    if type_ == 'none' then
        class_name = "GameUIAllianceEnterBase"
    elseif type_ == 'member' then
        if isMyAlliance then
            app:GetAudioManager():PlayBuildingEffectByType("keep")
        else
            app:GetAudioManager():PlayeEffectSoundWithKey("SELECT_ENEMY_ALLIANCE_CITY")
        end
        class_name = "GameUIAllianceCityEnter"
    elseif type_ == 'decorate' then
        class_name = "GameUIAllianceDecorateEnter"
    elseif type_ == 'village' then
        app:GetAudioManager():PlayBuildingEffectByType("warehouse")
        class_name = "GameUIAllianceVillageEnter"
        if not alliance:FindAllianceVillagesInfoByObject(entity) then -- 废墟
            class_name = "GameUIAllianceRuinsEnter"
        end
    elseif type_ == 'monster' then
        if not alliance:FindAllianceMonsterInfoByObject(entity) then
            return 
        end
        class_name = "GameUIAllianceMosterEnter"
    end
    UIKit:newGameUI(class_name,entity,isMyAlliance,self:GetAlliance(),self:GetEnemyAlliance()):AddToCurrentScene(true)
end
return AllianceBattleScene
