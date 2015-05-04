local window = import("..utils.window")
local UILib = import("..ui.UILib")
local Sprite = import("..sprites.Sprite")
local MultiAllianceLayer = import("..layers.MultiAllianceLayer")
local WidgetPushButton = import("..widget.WidgetPushButton")
local MapScene = import(".MapScene")
local AllianceScene = class("AllianceScene", MapScene)
local Alliance = import("..entity.Alliance")
local GameUIAllianceHome = import("..ui.GameUIAllianceHome")
function AllianceScene:ctor()
    self.util_node = display.newNode():addTo(self)
    AllianceScene.super.ctor(self)
end
function AllianceScene:onEnter()
    self:LoadAnimation()

    AllianceScene.super.onEnter(self)

    self:CreateAllianceUI()
    self:GotoCurrectPosition()
    app:GetAudioManager():PlayGameMusic()
    self:GetSceneLayer():ZoomTo(0.8)

    self:GetAlliance():AddListenOnType(self, Alliance.LISTEN_TYPE.BASIC)
    self:GetAlliance():AddListenOnType(self, Alliance.LISTEN_TYPE.OPERATION)
    local alliance_map = self:GetAlliance():GetAllianceMap()
    local allianceShirine = self:GetAlliance():GetAllianceShrine()
    alliance_map:AddListenOnType(allianceShirine,alliance_map.LISTEN_TYPE.BUILDING_INFO)
end
function AllianceScene:LoadAnimation()
    UILib.loadSolidersAnimation()
    UILib.loadDragonAnimation()
end
function AllianceScene:GotoCurrectPosition()
    local mapObject = self:GetAlliance():GetAllianceMap():FindMapObjectById(self:GetAlliance():GetSelf():MapId())
    local location = mapObject.location
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(location.x, location.y)
    self:GetSceneLayer():GotoMapPositionInMiddle(point.x, point.y)
end
function AllianceScene:EnterEditMode()
    self:GetHomePage():DisplayOff()
end
function AllianceScene:LeaveEditMode()
    self:GetHomePage():DisplayOn()
end
function AllianceScene:IsEditMode()
    return not self:GetHomePage():IsDisplayOn()
end
function AllianceScene:CreateAllianceUI()
    -- local home_page = UIKit:newGameUI('GameUIAllianceHome',Alliance_Manager:GetMyAlliance()):AddToScene(self)
    local home_page = GameUIAllianceHome.new(self:GetAlliance()):addTo(self)
    self:GetSceneLayer():AddObserver(home_page)
    home_page:setTouchSwallowEnabled(false)
    self.home_page = home_page
end
function AllianceScene:GetHomePage()
    return self.home_page
end
function AllianceScene:GetAlliance()
    return Alliance_Manager:GetMyAlliance()
end
function AllianceScene:onExit()
    self:GetAlliance():RemoveListenerOnType(self, Alliance.LISTEN_TYPE.BASIC)
    AllianceScene.super.onExit(self)
end
function AllianceScene:CreateSceneLayer()
    return MultiAllianceLayer.new(nil, self:GetAlliance())
end
function AllianceScene:GotoLogicPosition(x, y)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x, y)
    return self:GetSceneLayer():PromiseOfMove(point.x, point.y)
end
function AllianceScene:OnTouchClicked(pre_x, pre_y, x, y)
    if not AllianceScene.super.OnTouchClicked(self, pre_x, pre_y, x, y) then return end
    if self.util_node:getNumberOfRunningActions() > 0 then return end
    local building = self:GetSceneLayer():GetClickedObject(x, y)
    if building then
        app:lockInput(true)
        self.util_node:performWithDelay(function()
            app:lockInput(false)
        end, 0.5)

        app:GetAudioManager():PlayeEffectSoundWithKey("HOME_PAGE")
        if iskindof(building, "Sprite") then
            Sprite:PromiseOfFlash(building):next(function()
                self:OpenUI(building)
            end)
        else
            self:GetSceneLayer():PromiseOfFlashEmptyGround(building, true):next(function()
                self:OpenUI(building)
            end)
        end
    elseif self:IsEditMode() then
        self:LeaveEditMode()
    end
end
function AllianceScene:OpenUI(building)
    if building:GetEntity():GetType() ~= "building" then
        self:EnterNotAllianceBuilding(building:GetEntity())
    else
        self:EnterAllianceBuilding(building:GetEntity())
    end
end
function AllianceScene:OnAllianceBasicChanged(alliance,changed_map)
    if changed_map.terrain then
        app:EnterMyAllianceScene()
    end
end
function AllianceScene:ChangeTerrain()
    self:GetSceneLayer():ChangeTerrain()
end
function AllianceScene:OnOperation(alliance,operation_type)
    if operation_type == "quit" then
        UIKit:showMessageDialog(_("提示"),_("您已经退出联盟"), function()
            app:EnterMyCityScene()
        end,nil,false)
    end
end

function AllianceScene:EnterAllianceBuilding(entity)
    if self:IsEditMode() then
        self:LeaveEditMode()
    else
        local isMyAlliance = true
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
        UIKit:newGameUI(class_name,entity,isMyAlliance,self:GetAlliance()):AddToCurrentScene(true)
    end
end

function AllianceScene:EnterNotAllianceBuilding(entity)
    local isMyAlliance = true
    local type_ = entity:GetType()
    local class_name = ""
    if not self:IsEditMode() then
        if type_ == 'none' then
            class_name = "GameUIAllianceEnterBase"
        elseif type_ == 'member' then
            app:GetAudioManager():PlayBuildingEffectByType("keep")
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
        UIKit:newGameUI(class_name,entity,isMyAlliance,self:GetAlliance()):AddToCurrentScene(true)
    else
        if type_ == 'none' then
            local x,y = entity:GetLogicPosition()
            self:CheckCanMoveAllianceObject(x,y)
        else
            self:LeaveEditMode()
        end
    end
end

function AllianceScene:LoadEditModeWithAllianceObj(alliance_obj)
    self.alliance_obj_to_move = alliance_obj
    self:EnterEditMode()
end

function AllianceScene:CheckCanMoveAllianceObject(x,y)
    if self.alliance_obj_to_move then
        UIKit:showMessageDialog(nil
            ,string.format(
                _("可以移动%s到%s将消耗荣耀值%s,确认移动?")
                ,self.alliance_obj_to_move.name
                ,"(" .. x .."," .. y .. ")"
                ,self.alliance_obj_to_move.honour
            )
            ,function()
                if self:GetAlliance():GetAllianceMap():CanMoveBuilding(self.alliance_obj_to_move.obj,x,y) then
                    NetManager:getMoveAllianceBuildingPromise(self.alliance_obj_to_move.obj:Id(), x, y):always(function()
                        self.alliance_obj_to_move = nil
                        self:LeaveEditMode()
                    end)
                else
                    UIKit:showMessageDialog(nil, _("不能移动到目标点位"),function()end)
                end
            end
            ,nil
            ,true
            ,function()
                self:LeaveEditMode()
            end
        )
    end
end

function AllianceScene:ReEnterScene()
    app:enterScene("AllianceScene")
end
return AllianceScene

















