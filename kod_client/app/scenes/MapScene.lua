local window = import("..utils.window")
local WidgetMaskFilter = import("..widget.WidgetMaskFilter")
local EventManager = import("..layers.EventManager")
local TouchJudgment = import("..layers.TouchJudgment")
local MapScene = class("MapScene", function()
    return display.newScene("MapScene")
end)
local sqrt = math.sqrt
local floor = math.floor
local abs = math.abs
local fmod = math.fmod
local elastic = 200
function MapScene:ctor()
    if User then
        User:ResetAllListeners()
        User:AddListenOnType(self, "basicInfo")
        self.level = User:GetLevel()
    end
    if City then
        City:ResetAllListeners()
    end
    if Alliance_Manager then
        Alliance_Manager:GetMyAlliance():ResetAllListeners()
        self.my_alliance = Alliance_Manager:GetMyAlliance()
    end
    self.blur_count = 1
    self.event_manager = EventManager.new(self)
    self.touch_judgment = TouchJudgment.new(self)

    app:GetGameDefautlt():setStringForKey("PASS_SPLASH", "yes")
    app:GetGameDefautlt():flush()
end
function MapScene:OnUserDataChanged_basicInfo(userData, deltaData)
    local ok, value = deltaData("basicInfo.levelExp")
    if ok then
        local level = userData:GetLevel()
        if userData:GetLevel() ~= self.level then
            UIKit:newGameUI('GameUILevelUp', self.level, level):AddToScene(self)
        end
        self.level = level
    end
end
function MapScene:onEnter()
    if self.PreLoadImages then
        self:PreLoadImages()
    end
    -- self.scene_node = display.newClippingRegionNode(cc.rect(0, 0, display.width, display.height)):addTo(self)
    -- self.scene_node:setContentSize(cc.size(display.width, display.height))
    self.scene_node = display.newNode():addTo(self)
    self.scene_layer = self:CreateSceneLayer():addTo(self:GetSceneNode(), 0)
    self.touch_layer = self:CreateMultiTouchLayer():addTo(self:GetSceneNode(), 1)
    if type(self.CreateSceneUILayer) == "function" then
        self.scene_ui_layer = self:CreateSceneUILayer():addTo(self:GetSceneNode(), 2)
    end
    self.top_layer = display.newNode():addTo(self, 3)
    self.screen_layer = display.newNode():addTo(self:GetSceneNode(), 4)
    display.newNode():addTo(self):schedule(function()
        local flag = false
        if self.my_alliance and self.my_alliance:IsDefault() then
            flag = false 
        else
            flag = Alliance_Manager:HasToMyCityEvents()
        end
        if flag then
            self:Warning()
        else
            self:DisableWaring()
        end
    end, 1)
end
function MapScene:onExit()
    if self.UnloadImages then
        self:UnloadImages()
    end
end
function MapScene:PreLoadImages()
    for _,v in ipairs(self:GetPreloadImages()) do
        display.addSpriteFrames(DEBUG_GET_ANIMATION_PATH(v.list),DEBUG_GET_ANIMATION_PATH(v.image))
    end
end
function MapScene:UnloadImages()
    for _,v in ipairs(self:GetPreloadImages()) do
        display.removeSpriteFramesWithFile(DEBUG_GET_ANIMATION_PATH(v.list),DEBUG_GET_ANIMATION_PATH(v.image))
    end
end
function MapScene:GetPreloadImages()
    return {}
end
function MapScene:GetScreenLayer()
    return self.screen_layer
end
function MapScene:GetTopLayer()
    return self.top_layer 
end
function MapScene:BlurRenderScene()
    self.blur_count = self.blur_count - 1
    if self.blur_count ~= 0 then
        return
    end
    if self.render_scene then
        self.render_scene:removeFromParent()
        self.render_scene = nil
    end
    -- self.render_scene = self:DumpScene():addTo(self):pos(display.cx, display.cy)
    -- self:GetSceneNode():hide()
end
function MapScene:DumpScene()
    local director = cc.Director:getInstance()
    local params = {
        filters = "CUSTOM",
        filterParams = json.encode({
            vert = "shaders/fastblur.vs",
            frag = "shaders/fastblur.fs",
            shaderName = "blur_scene",
            u_radius = 0.003,
            u_time = director:getTotalFrames() * director:getAnimationInterval()
        })
    }
    return display.printscreen(self:GetSceneNode(), params)
end
function MapScene:ResetRenderState()
    self.blur_count = self.blur_count + 1
    if self.blur_count ~= 1 then
        return
    end
    -- self.render_scene:hide()
    -- self:GetSceneNode():show()
end
local WARNING_TAG = 99999
function MapScene:DisableWaring()
    if self:getChildByTag(WARNING_TAG) then
        self:removeChildByTag(WARNING_TAG)
    end
end
function MapScene:Warning()
    if not self:getChildByTag(WARNING_TAG) then
        self:CreateWaring()
    end
end
function MapScene:CreateWaring()
    local sprite = display.newSprite(
        "click_empty.png", 
        display.cx, 
        display.cy, 
        {class=cc.FilteredSpriteWithOne}
    ):addTo(self, 2999, WARNING_TAG)
    local size = sprite:getContentSize()
    sprite:setScaleX(display.width / size.width)
    sprite:setScaleY(display.height / size.height)
    local time, lastTime = 0, 1
    sprite:setFilter(filter.newFilter("CUSTOM",
        json.encode({
            frag = "shaders/warning.fs",
            shaderName = "warning",
            iResolution = {display.widthInPixels, display.heightInPixels}
        })
    ))
    sprite:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
        time = time + dt * 0.5
        sprite:getFilter():getGLProgramState():setUniformFloat("ratio", abs(fmod(time, lastTime) - 0.5) / lastTime)
    end)
    sprite:scheduleUpdate()
end
function MapScene:GetSceneNode()
    return self.scene_node
end
function MapScene:GetSceneUILayer()
    return self.scene_ui_layer
end
function MapScene:GetSceneLayer()
    return self.scene_layer
end
function MapScene:CreateSceneLayer()
    assert(false)
end
function MapScene:CreateMultiTouchLayer()
    local touch_layer = display.newLayer()
    touch_layer:setTouchEnabled(true)
    touch_layer:setTouchSwallowEnabled(true)
    touch_layer:setTouchMode(cc.TOUCH_MODE_ALL_AT_ONCE)
    self.handle = touch_layer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        self.event_manager:OnEvent(event)
        return true
    end)
    return touch_layer
end
local FTE_TAG = 11900
function MapScene:GetFteLayer()
    local child = self:getChildByTag(FTE_TAG)
    if not child then
        return self:CreateFteLayer()
    end
    return child
end
function MapScene:CreateFteLayer()
    local layer
    if GLOBAL_FTE_DEBUG then
        layer = display.newColorLayer(cc.c4b(0, 0, 255, 100)):addTo(self, 2000, FTE_TAG)
    else
        layer = display.newLayer(--[[cc.c4b(0, 255, 0, 100)]]):addTo(self, 2000, FTE_TAG)
    end
    local mask_filter = WidgetMaskFilter.new():addTo(layer):pos(display.cx, display.cy)
    layer:setTouchSwallowEnabled(true)
    local touch_judgment = self.touch_judgment
    layer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if self.lock then return end
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
    function layer:LockAll()
        self.lock = true
        self:Enable()
    end
    function layer:UnlockAll()
        self.lock = false
        self:Disable()
    end
    function layer:Enable()
        self:setTouchEnabled(true)
        return self:show()
    end
    function layer:Disable()
        self:setTouchEnabled(false)
        return self:hide()
    end
    function layer:FocusOnRect(rect)
        mask_filter:setVisible(rect ~= nil)
        mask_filter:FocusOnRect(rect)
        return self
    end
    function layer:Reset()
        mask_filter:hide()
        mask_filter:FocusOnRect()
        return self:Disable()
    end
    return layer:Reset()
end
function MapScene:OnOneTouch(pre_x, pre_y, x, y, touch_type)
    self:OneTouch(pre_x, pre_y, x, y, touch_type)
end
function MapScene:OneTouch(pre_x, pre_y, x, y, touch_type)
    if touch_type == "began" then
        self.touch_judgment:OnTouchBegan(pre_x, pre_y, x, y)
        self.scene_layer:StopMoveAnimation()
        return true
    elseif touch_type == "moved" then
        self.touch_judgment:OnTouchMove(pre_x, pre_y, x, y)
    elseif touch_type == "ended" then
        self.touch_judgment:OnTouchEnd(pre_x, pre_y, x, y)
    elseif touch_type == "cancelled" then
        self.touch_judgment:OnTouchCancelled(pre_x, pre_y, x, y)
    end
end
function MapScene:OnTwoTouch(x1, y1, x2, y2, event_type)
    local scene = self.scene_layer
    if event_type == "began" then
        scene:StopScaleAnimation()
        self.distance = sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
        scene:ZoomBegin(x1, y1, x2, y2)
    elseif event_type == "moved" then
        local new_distance = sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
        scene:ZoomBy(new_distance / self.distance, (x1 + x2) * 0.5, (y1 + y2) * 0.5)
    elseif event_type == "ended" then
        scene:ZoomEnd()
        self.distance = nil
        self:MakeElastic()
    end
end
function MapScene:MakeElastic()
    local scene = self.scene_layer
    local min_s, max_s = scene:GetScaleRange()
    local low = min_s * 1.1
    local high = max_s * 0.95
    if scene:getScale() <= low then
        scene:ZoomToByAnimation(low)
    elseif scene:getScale() >= high then
        scene:ZoomToByAnimation(high)
    end
end
-- TouchJudgment
function MapScene:OnTouchBegan(pre_x, pre_y, x, y)

end
function MapScene:OnTouchEnd(pre_x, pre_y, x, y, speed)
-- if not speed and self.scene_layer:MakeElastic() then
--     self.touch_judgment:ResetTouch()
-- end
end
function MapScene:OnTouchCancelled(pre_x, pre_y, x, y)
    print("OnTouchCancelled")
end
function MapScene:OnTouchMove(pre_x, pre_y, x, y)
    if self.distance then return end
    local parent = self.scene_layer:getParent()
    local old_point = parent:convertToNodeSpace(cc.p(pre_x, pre_y))
    local new_point = parent:convertToNodeSpace(cc.p(x, y))
    local old_x, old_y = self.scene_layer:getPosition()
    local diffX = new_point.x - old_point.x
    local diffY = new_point.y - old_point.y
    self.scene_layer:setPosition(cc.p(old_x + diffX, old_y + diffY))
end
function MapScene:OnTouchClicked(pre_x, pre_y, x, y)

end
function MapScene:OnTouchExtend(old_speed_x, old_speed_y, new_speed_x, new_speed_y, millisecond, is_end)
    local parent = self.scene_layer:getParent()
    local speed = parent:convertToNodeSpace(cc.p(new_speed_x, new_speed_y))
    local x, y = self.scene_layer:getPosition()
    local max_speed = 5
    local sp = self:convertToNodeSpace(cc.p(speed.x * millisecond, speed.y * millisecond))
    speed.x = speed.x > max_speed and max_speed or speed.x
    speed.y = speed.y > max_speed and max_speed or speed.y
    self.scene_layer:setPosition(cc.p(x + sp.x, y + sp.y))
end
function MapScene:IsFingerOn()
    return self.event_manager:TouchCounts() ~= 0
end
function MapScene:OnSceneMove()
    self.top_layer:pos(self.scene_layer:getPosition())
end
function MapScene:OnSceneScale()
    self.top_layer:scale(self.scene_layer:getScale())
    self.top_layer:pos(self.scene_layer:getPosition())
end

function MapScene:onEnterTransitionFinish()
    local message = UIKit:getMessageDialogWillShow()
    if message then
        message:AddToScene(self, false)
        UIKit:clearMessageDialogWillShow()
    end
end
return MapScene




