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
    self:LoadAnimation()
    AllianceBattleScene.super.onEnter(self)
    self:CreateAllianceUI()
    self:GetAlliance():AddListenOnType(self, Alliance.LISTEN_TYPE.BASIC)
    app:GetAudioManager():PlayGameMusic()
    self:GetSceneLayer():ZoomTo(0.8)

    if self.location then
        self:GotoPosition(self.location.x, self.location.y,self.location.id)
        if self.location.callback then
            self.location.callback(self)
        end
    else
        self:GotoCurrentPosition()
    end
end
function AllianceBattleScene:GotoCurrentPosition()
    local mapObject = self:GetAlliance():GetAllianceMap():FindMapObjectById(self:GetAlliance():GetSelf():MapId())
    local location = mapObject.location
    self:GotoPosition(location.x,location.y,self:GetAlliance():Id())
end
function AllianceBattleScene:GotoPosition(x,y,aid)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x,y,aid)
    self:GetSceneLayer():GotoMapPositionInMiddle(point.x, point.y)
end
function AllianceBattleScene:LoadAnimation()
    UILib.loadSolidersAnimation()
    UILib.loadDragonAnimation()
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
    local pos = self:GetAlliance():FightPosition()
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
        if iskindof(building, "Sprite") then
            Sprite:PromiseOfFlash(building):next(function()
                self:OpenUI(building, isMyAlliance)
            end)
        else
            self:GetSceneLayer():PromiseOfFlashEmptyGround(building, isMyAlliance):next(function()
                self:OpenUI(building, isMyAlliance)
            end)
        end
    end
end
function AllianceBattleScene:OpenUI(building, isMyAlliance)
    if building:GetEntity():GetType() ~= "building" then
        self:EnterNotAllianceBuilding(building:GetEntity(),isMyAlliance)
    else
        self:EnterAllianceBuilding(building:GetEntity(),isMyAlliance)
    end
end
function AllianceBattleScene:OnAllianceBasicChanged(alliance,changed_map)
    -- if changed_map.status and changed_map.status.new == 'protect' then
        -- app:GetAudioManager():PlayGameMusic()
    -- end
end
function AllianceBattleScene:EnterAllianceBuilding(entity,isMyAlliance)
    local building_info = entity:GetAllianceBuildingInfo()
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
        if not entity:GetAllianceVillageInfo() then -- 废墟
            class_name = "GameUIAllianceRuinsEnter"
        end
    end
    UIKit:newGameUI(class_name,entity,isMyAlliance,self:GetAlliance(),self:GetEnemyAlliance()):AddToCurrentScene(true)
end
return AllianceBattleScene
