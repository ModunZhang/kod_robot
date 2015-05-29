local promise = import("..utils.promise")
local window = import("..utils.window")
local UILib = import("..ui.UILib")
local Sprite = import("..sprites.Sprite")
local MultiAllianceLayer = import("..layers.MultiAllianceLayer")
local WidgetPushButton = import("..widget.WidgetPushButton")
local MapScene = import(".MapScene")
local AllianceScene = class("AllianceScene", MapScene)
local Alliance = import("..entity.Alliance")
local GameUIAllianceHome = import("..ui.GameUIAllianceHome")

local ceil = math.ceil
local floor = math.floor


function AllianceScene:ctor(location)
    self.location = location
    self.util_node = display.newNode():addTo(self)
    AllianceScene.super.ctor(self)
end
function AllianceScene:onEnter()
    self:LoadAnimation()
    AllianceScene.super.onEnter(self)
    self:CreateAllianceUI()
    app:GetAudioManager():PlayGameMusic()
    self:GetSceneLayer():ZoomTo(0.8)
    self:GetAlliance():AddListenOnType(self, Alliance.LISTEN_TYPE.BASIC)
    self:GetAlliance():AddListenOnType(self, Alliance.LISTEN_TYPE.OPERATION)
    local alliance_map = self:GetAlliance():GetAllianceMap()

    local alliance_key = DataManager:getUserData()._id.."_SHOW_REGION_TIPS"
    if not app:GetGameDefautlt():getBasicInfoValueForKey(alliance_key) then
        app:GetGameDefautlt():getBasicInfoValueForKey(alliance_key,true)

        UIKit:newGameUI("GameUITips","region"):AddToScene(self, true)
    end
    if self.location then
        self:GotoPosition(self.location.x, self.location.y)
        if self.location.callback then
            self.location.callback(self)
        end
    else
        self:GotoCurrentPosition()
    end
end
function AllianceScene:LoadAnimation()
    UILib.loadSolidersAnimation()
    UILib.loadDragonAnimation()
end
function AllianceScene:GotoCurrentPosition()
    local mapObject = self:GetAlliance():GetAllianceMap():FindMapObjectById(self:GetAlliance():GetSelf():MapId())
    local location = mapObject.location
    self:GotoPosition(location.x, location.y)
end
function AllianceScene:GotoPosition(x,y)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x,y)
    self:GetSceneLayer():GotoMapPositionInMiddle(point.x, point.y)
end
function AllianceScene:EnterEditMode()
    self:GetHomePage():DisplayOff()
end
function AllianceScene:LeaveEditMode()
    self:GetHomePage():DisplayOn()
    self.alliance_obj_to_move = nil
end
function AllianceScene:IsEditMode()
    return not self:GetHomePage():IsDisplayOn()
end
function AllianceScene:CreateAllianceUI()
    local home_page = GameUIAllianceHome.new(self:GetAlliance(), self:GetSceneLayer()):addTo(self)
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
    return MultiAllianceLayer.new(self, nil, self:GetAlliance())
end
function AllianceScene:GotoLogicPosition(x, y)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x, y)
    return self:GetSceneLayer():PromiseOfMove(point.x, point.y)
end
function AllianceScene:OnTouchClicked(pre_x, pre_y, x, y)
    if self.event_manager:TouchCounts() ~= 0 or
        self.util_node:getNumberOfRunningActions() > 0 then
        return
    end

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
            if self.alliance_obj_to_move then
                local x,y = building:GetEntity():GetLogicPosition()
                local mapObj = self.alliance_obj_to_move.obj

                local can_move,squares,out_x,out_y = self:GetAlliance()
                    :GetAllianceMap()
                    :CanMoveBuilding(mapObj, x, y)

                self:PromiseOfShowPlaceInfo(squares, x, y):next(function()
                    if can_move then
                        self:CheckCanMoveAllianceObject(x, y, out_x, out_y)
                    end
                end)
            else
                self:GetSceneLayer():PromiseOfFlashEmptyGround(building, true):next(function()
                    self:OpenUI(building)
                end)
            end
        end
    elseif self:IsEditMode() then
        self:LeaveEditMode()
    end
end
function AllianceScene:PromiseOfShowPlaceInfo(squares, lx, ly)
    local alliance_view = self:GetSceneLayer().alliance_views[1]
    local logic_map = alliance_view:GetLogicMap()
    local click_node = self:GetSceneLayer():AddClickNode()
    for i,v in ipairs(squares) do
        local x,y,is_not_red = unpack(v)
        display.newSprite("click_empty.png"):addTo(click_node)
            :pos(logic_map:ConvertToLocalPosition(lx - x, ly - y))
            :scale(0.96):setColor(is_not_red and display.COLOR_BLUE or display.COLOR_RED)
    end
    local p = promise.new()
    click_node:pos(logic_map:ConvertToMapPosition(lx,ly)):opacity(0)
        :runAction(
            transition.sequence{
                cc.FadeTo:create(0.3, 255),
                cc.FadeTo:create(0.3, 0),
                cc.CallFunc:create(function()
                    p:resolve()
                    self:GetSceneLayer():RemoveClickNode()
                end)
            }
        )
    return p
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
        UIKit:showMessageDialog(nil,_("联盟地形已经改变"),function()
            app:EnterMyAllianceScene()
        end,nil,false,nil)
    end
end
function AllianceScene:ChangeTerrain()
    self:GetSceneLayer():ChangeTerrain()
end
function AllianceScene:OnOperation(alliance,operation_type)
    if operation_type == "quit" then
        UIKit:showMessageDialog(_("提示"),_("你已经退出联盟"), function()
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

function AllianceScene:CheckCanMoveAllianceObject(x, y, out_x, out_y)
    if self.alliance_obj_to_move then
        UIKit:showMessageDialog(nil
            ,string.format(
                _("你可以移动%s到%s将消耗荣耀值%s,确认要移动吗?")
                ,self.alliance_obj_to_move.name
                ,"(" .. x .."," .. y .. ")"
                ,self.alliance_obj_to_move.honour
            )
            ,function()
                if self:GetAlliance():GetAllianceMap():CanMoveBuilding(self.alliance_obj_to_move.obj,x,y) then
                    NetManager:getMoveAllianceBuildingPromise(self.alliance_obj_to_move.obj:Id(), out_x, out_y):always(function()
                        self:LeaveEditMode()
                    end)
                else
                    UIKit:showMessageDialog(nil, _("无法移动到目标位置"),function()end)
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





















