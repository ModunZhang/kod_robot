local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local UILib = import("..ui.UILib")
local SpriteButton = import("..ui.SpriteButton")
local BuildingLevelUpUINode = import("..ui.BuildingLevelUpUINode")
local BuildingUpgradeUINode = import("..ui.BuildingUpgradeUINode")
local CityLayer = import("..layers.CityLayer")
local EventManager = import("..layers.EventManager")
local TouchJudgment = import("..layers.TouchJudgment")
local IsoMapAnchorBottomLeft = import("..map.IsoMapAnchorBottomLeft")
local MapScene = import(".MapScene")
local promise = import("..utils.promise")
local Alliance = import("..entity.Alliance")
local CityScene = class("CityScene", MapScene)

local app = app
local timer = app.timer
local DEBUG_LOCAL = false
function CityScene:ctor(city)
    CityScene.super.ctor(self)
    self.city = city
end
function CityScene:onEnter()
    self:LoadAnimation()
    CityScene.super.onEnter(self)
    self:GetSceneLayer():AddObserver(self)
    self:GetSceneLayer():InitWithCity(self:GetCity())
    self:PlayBackgroundMusic()
    self:GotoLogicPointInstant(6, 4)
    self:GetSceneLayer():ZoomTo(1)

    -- local sprite = display.newSprite("batcat_logo_368x390.png", 0, 0, {class=cc.FilteredSpriteWithOne}):addTo(self):align(display.LEFT_BOTTOM)
    -- sprite:setScaleX(display.width/368)
    -- sprite:setScaleY(display.height/390)
    -- sprite:setFilter(filter.newFilter("CUSTOM", json.encode({
    --     frag = "shaders/snow.fs",
    --     shaderName = "snow",
    --     u_resolution = {display.width, display.height},
    --     curTime = 0,
    -- })))
    -- local time = 0
    -- sprite:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
    --     time = time + dt
    --     sprite:getFilter():getGLProgramState():setUniformFloat("curTime", time)
    -- end)
    -- sprite:scheduleUpdate()
end
function CityScene:onExit()
    UILib.unLoadBuildingAnimation()
    self:stopAllActions()
    --TODO:注意：这里因为主城现在播放两个音乐文件 所以这里要关掉鸟叫的sound音效
    audio.stopAllSounds()
    CityScene.super.onExit(self)
end
-- init ui
function CityScene:LoadAnimation()
    UILib.loadSolidersAnimation()
    UILib.loadBuildingAnimation()
    UILib.loadDragonAnimation()
end
function CityScene:GetCity()
    return self.city
end
function CityScene:CreateSceneLayer()
    local scene = CityLayer.new(self)
    local origin_point = scene:GetPositionIndex(0, 0)
    self.iso_map = IsoMapAnchorBottomLeft.new({
        tile_w = 80, tile_h = 56, map_width = 50, map_height = 50, base_x = origin_point.x, base_y = origin_point.y
    })
    return scene
end
function CityScene:CreateSceneUILayer()
    local city = self.city
    local scene_ui_layer = display.newLayer()
    scene_ui_layer:setTouchEnabled(true)
    scene_ui_layer:setTouchSwallowEnabled(false)
    function scene_ui_layer:Init()
        self.action_node = display.newNode():addTo(self)
        self.levelup_node = display.newNode():addTo(self)
        self.levelup_node:setCascadeOpacityEnabled(true)
        self.ui = {}
        self.level_up_ui = {}
        self.lock_buttons = {}
        self.status = nil
    end
    function scene_ui_layer:NewLockButtonFromBuildingSprite(building_sprite)
        local lock_button = SpriteButton.new(building_sprite, city):addTo(self, 1)
        building_sprite:AddObserver(lock_button)
        city:AddListenOnType(lock_button, city.LISTEN_TYPE.UPGRADE_BUILDING)
        table.insert(self.lock_buttons, lock_button)
        building_sprite:OnSceneMove()
    end
    function scene_ui_layer:RemoveAllLockButtons()
        for _, v in pairs(self.lock_buttons) do
            v:removeFromParent()
            city:RemoveListenerOnType(v, city.LISTEN_TYPE.UPGRADE_BUILDING)
        end
        self.lock_buttons = {}
    end
    function scene_ui_layer:ShowIndicatorOnBuilding(building_sprite)
        if not self.indicator then
            self.building__ = building_sprite
            self.indicator = display.newNode():addTo(self):zorder(1001)
            local r = 30
            local len = 50
            local x = math.sin(math.rad(r)) * len
            local y = math.sin(math.rad(90 - r)) * len
            display.newSprite("arrow_home.png")
                :addTo(self.indicator)
                :align(display.BOTTOM_CENTER, 10, 10)
                :rotation(r)
                :runAction(cc.RepeatForever:create(transition.sequence{
                    cc.MoveBy:create(0.4, cc.p(-x, -y)),
                    cc.MoveBy:create(0.4, cc.p(x, y)),
                }))
            self.action_node:stopAllActions()
            self.action_node:performWithDelay(function()
                self:HideIndicator()
            end, 4.0)
            self:OnSceneMove()
        end
    end
    function scene_ui_layer:HideIndicator()
        if self.indicator then
            self.action_node:stopAllActions()
            self.indicator:removeFromParent()
            self.indicator = nil
        end
    end
    function scene_ui_layer:OnSceneMove()
        if self.indicator and self.building__.GetWorldPosition then
            local _,top = self.building__:GetWorldPosition()
            self.indicator:pos(top.x, top.y)
        end
    end
    -- function scene_ui_layer:NewUIFromBuildingSprite(building_sprite)
    --     local progress = BuildingUpgradeUINode.new():addTo(self)
    --     building_sprite:AddObserver(progress)
    --     table.insert(self.ui, progress)

    --     local levelup = BuildingLevelUpUINode.new():addTo(self.levelup_node)
    --     building_sprite:AddObserver(levelup)
    --     table.insert(self.ui, levelup)

    --     building_sprite:CheckCondition()
    --     building_sprite:OnSceneMove()
    -- end
    -- function scene_ui_layer:RemoveUIFromBuildingSprite(building_sprite)
    --     building_sprite:NotifyObservers(function(ob)
    --         table.foreachi(self.ui, function(i, v)
    --             if ob == v then
    --                 table.remove(self.ui, i)
    --                 v:removeFromParent()
    --             end
    --         end)
    --     end)
    -- end
    function scene_ui_layer:ShowLevelUpNode()
        if self.status == "show" then
            return
        end
        self.levelup_node:stopAllActions()
        self.levelup_node:fadeTo(0.5, 255)
        self.status = "show"
    end
    function scene_ui_layer:HideLevelUpNode()
        if self.status == "hide" then
            return
        end
        self.levelup_node:stopAllActions()
        self.levelup_node:fadeTo(0.5, 0)
        self.status = "hide"
    end
    function scene_ui_layer:IteratorLockButtons(func)
        table.foreach(self.lock_buttons, func)
    end
    function scene_ui_layer:EnterEditMode()
        table.foreach(self.lock_buttons, function(_, v)
            v:hide()
        end)
        self.levelup_node:hide()
    end
    function scene_ui_layer:LeaveEditMode()
        table.foreach(self.lock_buttons, function(_, v)
            v:show()
        end)
        self.levelup_node:show()
    end
    scene_ui_layer:Init()
    return scene_ui_layer
end
-- function
function CityScene:GotoLogicPointInstant(x, y)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x, y)
    self:GetSceneLayer():GotoMapPositionInMiddle(point.x, point.y)
end
function CityScene:GotoLogicPoint(x, y, speed)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x, y)
    return self:GetSceneLayer():PromiseOfMove(point.x, point.y, speed)
end
function CityScene:PlayBackgroundMusic()
    app:GetAudioManager():PlayGameMusic()
    -- self:performWithDelay(function()
    --     self:PlayBackgroundMusic()
    -- end, 113 + 30)
end
function CityScene:ChangeTerrain()
    self:GetSceneLayer():ChangeTerrain()
end
function CityScene:CreateArrowLayer()
    local arrow_layer = display.newLayer():addTo(self, 2)
    arrow_layer:setTouchSwallowEnabled(false)
    return arrow_layer
end
function CityScene:CreateTutorialLayer()
    local layer = display.newLayer():addTo(self, 2000)
    layer:setTouchSwallowEnabled(true)
    local touch_judgment = self.touch_judgment
    layer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if touch_judgment then
            local touch_type, pre_x, pre_y, x, y = event.name, event.prevX, event.prevY, event.x, event.y
            if touch_type == "began" then
                touch_judgment:OnTouchBegan(pre_x, pre_y, x, y)
                return true
            elseif touch_type == "moved" then
            -- touch_judgment:OnTouchMove(pre_x, pre_y, x, y)
            elseif touch_type == "ended" then
                touch_judgment:OnTouchEnd(pre_x, pre_y, x, y)
            elseif touch_type == "cancelled" then
                touch_judgment:OnTouchCancelled(pre_x, pre_y, x, y)
            end
        end
        return true
    end)
    local count = 0
    function layer:Enable()
        count = count + 1
        if count > 0 then
            layer:setTouchEnabled(true)
        end
    end
    function layer:Disable()
        count = count - 1
        if count <= 0 then
            layer:setTouchEnabled(false)
        end
    end
    function layer:Reset()
        count = 0
        layer:setTouchEnabled(false)
        return self
    end
    return layer:Reset()
end
function CityScene:EnterEditMode()
    self:GetSceneLayer():EnterEditMode()
end
function CityScene:LeaveEditMode()
    self:GetSceneLayer():LeaveEditMode()
end
function CityScene:IsEditMode()
    return self:GetSceneLayer():IsEditMode()
end
--- callback override
function CityScene:OnCreateDecoratorSprite(building_sprite)
end
function CityScene:OnDestoryDecoratorSprite(building_sprite)
end
function CityScene:OnTilesChanged(tiles)
end
function CityScene:OnTreesChanged(trees, road)
end
function CityScene:OnTowersChanged(old_towers, new_towers)
end
function CityScene:OnGateChanged(old_walls, new_walls)
end
function CityScene:OnSceneScale(scene_layer)
end
function CityScene:OnTouchBegan(pre_x, pre_y, x, y)
    if not DEBUG_LOCAL then return end
    local citynode = self:GetSceneLayer():GetCityNode()
    local point = citynode:convertToNodeSpace(cc.p(x, y))
    local tx, ty = self.iso_map:ConvertToLogicPosition(point.x, point.y)
    if not self.building then
        local building = self:GetSceneLayer():GetClickedObject(x, y)
        if building then
            local lx, ly = building:GetLogicPosition()
            building._shiftx = lx - tx
            building._shifty = ly - ty
            building:zorder(99999999)
            self.building = building
        end
    end
end
function CityScene:OnTouchEnd(pre_x, pre_y, x, y, speed)
    CityScene.super.OnTouchEnd(self, pre_x, pre_y, x, y, speed)
    if not DEBUG_LOCAL then return end
    local citynode = self:GetSceneLayer():GetCityNode()
    local point = citynode:convertToNodeSpace(cc.p(x, y))
    local tx, ty = self.iso_map:ConvertToLogicPosition(point.x, point.y)
    if self.building then
        local lx, ly = self.building:GetLogicPosition()
        self.building:zorder(self:GetSceneLayer():GetZOrderBy(self.building, lx, ly))
        if self.building._shiftx + tx == lx and
            self.building._shifty + ty == ly then
        end
    end
    self.building = nil
end
function CityScene:OnTouchCancelled(pre_x, pre_y, x, y)

end
function CityScene:OnTouchMove(pre_x, pre_y, x, y)
    if DEBUG_LOCAL then
        if self.building then
            local citynode = self:GetSceneLayer():GetCityNode()
            local point = citynode:convertToNodeSpace(cc.p(x, y))
            local lx, ly = self.iso_map:ConvertToLogicPosition(point.x, point.y)
            local bx, by = self.building:GetLogicPosition()
            local is_moved_one_more = lx ~= bx or ly ~= by
            if is_moved_one_more then
                self.building:SetLogicPosition(lx + self.building._shiftx, ly + self.building._shifty)
            end
            return
        end
    end
    CityScene.super.OnTouchMove(self, pre_x, pre_y, x, y)
end




return CityScene







