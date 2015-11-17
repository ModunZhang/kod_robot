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
    AllianceScene.super.onEnter(self)
    self:CreateAllianceUI()
    app:GetAudioManager():PlayGameMusicOnSceneEnter("AllianceScene",false)
    self:GetSceneLayer():ZoomTo(0.82)
    self:GetAlliance():AddListenOnType(self, Alliance.LISTEN_TYPE.BASIC)
    self:GetAlliance():AddListenOnType(self, Alliance.LISTEN_TYPE.OPERATION)

    local alliance_key = DataManager:getUserData()._id.."_SHOW_REGION_TIPS"
    if not app:GetGameDefautlt():getBasicInfoValueForKey(alliance_key) then
        app:GetGameDefautlt():getBasicInfoValueForKey(alliance_key,true)

        UIKit:newGameUI("GameUITips","region",_("玩法介绍"), true):AddToScene(self, true)
    end
    if self.location then
        self:GotoPosition(self.location.x, self.location.y)
        if self.location.callback then
            self.location.callback(self)
        end
    else
        self:GotoCurrentPosition()
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
function AllianceScene:GetPreloadImages()
    return {
        {image = "animations/heihua_animation_0.pvr.ccz",list = "animations/heihua_animation_0.plist"},
        {image = "animations/heihua_animation_1.pvr.ccz",list = "animations/heihua_animation_1.plist"},
        {image = "animations/heihua_animation_2.pvr.ccz",list = "animations/heihua_animation_2.plist"},
        {image = "animations/region_animation_0.pvr.ccz",list = "animations/region_animation_0.plist"},
        {image = "region_png.pvr.ccz",list = "region_png.plist"},
        {image = "region_pvr.pvr.ccz",list = "region_pvr.plist"},
    }
end
function AllianceScene:GotoCurrentPosition()
    local mapObject = self:GetAlliance():FindMapObjectById(self:GetAlliance():GetSelf():MapId())
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
    self:GetAlliance():RemoveListenerOnType(self, Alliance.LISTEN_TYPE.OPERATION)
    AllianceScene.super.onExit(self)
end
function AllianceScene:CreateSceneLayer()
    return MultiAllianceLayer.new(self, nil, self:GetAlliance())
end
function AllianceScene:GotoLogicPosition(x, y)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x, y)
    return self:GetSceneLayer():PromiseOfMove(point.x, point.y)
end
function AllianceScene:OnTouchBegan(...)
    AllianceScene.super.OnTouchBegan(self, ...)
    self:GetSceneLayer():TrackCorpsById(nil)
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
        local entity = building:GetEntity()
        if iskindof(building, "Sprite") then
            Sprite:PromiseOfFlash(building):next(function()
                self:OpenUI(entity)
            end)
        else
            if self.alliance_obj_to_move then
                local x,y = building:GetEntity():GetLogicPosition()
                local mapObj = self.alliance_obj_to_move.obj

                local can_move,squares,out_x,out_y = self:GetAlliance():GetAllianceMap()
                    :CanMoveBuilding(mapObj, x, y)

                self:PromiseOfShowPlaceInfo(squares, x, y):next(function()
                    if can_move then
                        self:CheckCanMoveAllianceObject(x, y, out_x, out_y)
                    end
                end)
            else
                self:GetSceneLayer():PromiseOfFlashEmptyGround(building, true):next(function()
                    self:OpenUI(entity)
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
function AllianceScene:OpenUI(entity)
    if Alliance:GetMapObjectType(entity) ~= "building" then
        self:EnterNotAllianceBuilding(entity)
    else
        self:EnterAllianceBuilding(entity)
    end
end
function AllianceScene:OnAllianceBasicChanged(alliance,deltaData)
    if deltaData("basicInfo.terrain") then
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
        local building_info = self:GetAlliance():FindAllianceBuildingInfoByObjects(entity)
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
    local type_ = Alliance:GetMapObjectType(entity)
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
            if not self:GetAlliance():FindAllianceVillagesInfoByObject(entity) then -- 废墟
                class_name = "GameUIAllianceRuinsEnter"
            end
        elseif type_ == 'monster' then
            if not self:GetAlliance():FindAllianceMonsterInfoByObject(entity) then
                return
            end
            class_name = "GameUIAllianceMosterEnter"
        end
        UIKit:newGameUI(class_name,entity,isMyAlliance,self:GetAlliance()):AddToCurrentScene(true)
    else
        if type_ == 'none' then
            local x,y = Alliance:GetLogicPositionWithMapObj(entity)
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


function AllianceScene:onEnterTransitionFinish()
    AllianceScene.super.onEnterTransitionFinish(self)
    self:PlayEffectIf()
end

local EFFECT_TAG = 12321
function AllianceScene:PlayEffectIf()
    if math.floor(app.timer:GetServerTime()) % 2 == 1 then return end
    self:GetScreenLayer():removeAllChildren()
    local terrain = self:GetAlliance().basicInfo.terrain
    if terrain == "iceField" then
        local emitter = UIKit:CreateSnow():addTo(self:GetScreenLayer(), 1, EFFECT_TAG)
            :pos(display.cx-80, display.height)
        for i = 1, 1000 do
            emitter:update(0.01)
        end
    elseif terrain == "grassLand" then
        self:performWithDelay(function()
            local emitter = UIKit:CreateRain():addTo(self:GetScreenLayer(), 1, EFFECT_TAG)
                :pos(display.cx + 80, display.height)
        end, 1)
    elseif terrain == "desert" then
        local emitter = UIKit:CreateSand():addTo(self:GetScreenLayer(), 1, EFFECT_TAG)
            :pos(0, display.cy)
        for i = 1, 1000 do
            emitter:update(0.01)
        end
    end
end


return AllianceScene






















