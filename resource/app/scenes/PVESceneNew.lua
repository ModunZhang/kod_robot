local GameUIPVEHomeNew = import("..ui.GameUIPVEHomeNew")
local PVELayerNew = import("..layers.PVELayerNew")
local MapScene = import(".MapScene")
local PVESceneNew = class("PVESceneNew", MapScene)
function PVESceneNew:ctor()
    PVESceneNew.super.ctor(self)
end
function PVESceneNew:onEnter()
	PVESceneNew.super.onEnter(self)
    self.home_page = self:CreateHomePage()
    self:GetSceneLayer():ZoomTo(1)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(4.5,0)
    self:GetSceneLayer():GotoMapPositionInMiddle(point.x, point.y)
end
function PVESceneNew:GetHomePage()
    return self.home_page
end
function PVESceneNew:CreateSceneLayer()
    return PVELayerNew.new(self)
end
function PVESceneNew:CreateHomePage()
    local home_page = GameUIPVEHomeNew.new():AddToScene(self, true)
    home_page:setLocalZOrder(10)
    home_page:setTouchSwallowEnabled(false)
    return home_page
end
function PVESceneNew:OneTouch(pre_x, pre_y, x, y, touch_type)
    PVESceneNew.super.OneTouch(self, pre_x, pre_y, pre_x, y, touch_type)
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



return PVESceneNew






















