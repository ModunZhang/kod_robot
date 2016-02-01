local Sprite = import("..sprites.Sprite")
local PVELayerNew = import("..layers.PVELayerNew")
local GameUIPveHomeNew = import("..ui.GameUIPveHomeNew")
local MapScene = import(".MapScene")
local PVESceneNew = class("PVESceneNew", MapScene)
function PVESceneNew:ctor(user, level)
    self.user = user
    self.lv = level
    PVESceneNew.super.ctor(self)
    self.util_node = display.newNode():addTo(self)
end
function PVESceneNew:onEnter()
	PVESceneNew.super.onEnter(self)
    self.home_page = self:CreateHomePage()
    self:GetSceneLayer():ZoomTo(1)
    self:GetSceneLayer():GotoPve()
    app:GetAudioManager():PlayGameMusicOnSceneEnter("PVEScene",true)

    showMemoryUsage()
end
function PVESceneNew:GetPreloadImages()
    return {
        -- {image = "animations/building_animation.pvr.ccz",list = "animations/building_animation.plist"},
    }
end
function PVESceneNew:GetHomePage()
    return self.home_page
end
function PVESceneNew:CreateSceneLayer()
    return PVELayerNew.new(self, self.user, self.lv)
end
function PVESceneNew:CreateHomePage()
    local home_page = GameUIPveHomeNew.new(self.lv):AddToScene(self, true)
    home_page:setLocalZOrder(10)
    home_page:setTouchSwallowEnabled(false)
    return home_page
end
function PVESceneNew:OneTouch(pre_x, pre_y, x, y, touch_type)
    if touch_type == "began" then
        self.touch_judgment:OnTouchBegan(pre_x, pre_y, x, y)
        self.scene_layer:StopMoveAnimation()
        return true
    elseif touch_type == "moved" then
        self.touch_judgment:OnTouchMove(pre_x, pre_y, pre_x, y)
    elseif touch_type == "ended" then
        self.touch_judgment:OnTouchEnd(pre_x, pre_y, x, y)
    elseif touch_type == "cancelled" then
        self.touch_judgment:OnTouchCancelled(pre_x, pre_y, pre_x, y)
    end
end
function PVESceneNew:OnTouchExtend(old_speed_x, old_speed_y, new_speed_x, new_speed_y, millisecond, is_end)
    local parent = self.scene_layer:getParent()
    local speed = parent:convertToNodeSpace(cc.p(new_speed_x, new_speed_y))
    local x, y = self.scene_layer:getPosition()
    local max_speed = 5
    local sp = self:convertToNodeSpace(cc.p(speed.x * millisecond, speed.y * millisecond))
    speed.x = speed.x > max_speed and max_speed or speed.x
    speed.y = speed.y > max_speed and max_speed or speed.y
    self.scene_layer:setPosition(cc.p(x, y + sp.y))
end
function PVESceneNew:OnTwoTouch()
end
function PVESceneNew:OnTouchClicked(pre_x, pre_y, x, y)
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
                self:OpenUI(building)
            end)
        end
    end
end
function PVESceneNew:OpenUI(building)
    UIKit:newGameUI("GameUIPveAttack", self.user, building:GetPveName()):AddToCurrentScene(true)
end


return PVESceneNew






















