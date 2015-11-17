local WorldLayer = import("..layers.WorldLayer")
local MapScene = import(".MapScene")
local WorldScene = class("WorldScene", MapScene)



function WorldScene:ctor()
    WorldScene.super.ctor(self)
end
function WorldScene:onEnter()
    WorldScene.super.onEnter(self)
    self:GotoPosition(0,0)
    self:ScheduleLoadMap()
    self.home_page = self:CreateHomePage()
end
function WorldScene:GetHomePage()
	return  self.home_page
end
function WorldScene:CreateHomePage()
    if UIKit:GetUIInstance("GameUIWorldHome") then
        UIKit:GetUIInstance("GameUIWorldHome"):removeFromParent()
    end
    local home = UIKit:newGameUI('GameUIWorldHome', City):AddToScene(self)
    home:setLocalZOrder(10)
    home:setTouchSwallowEnabled(false)
    return home
end
function WorldScene:CreateSceneLayer()
    return WorldLayer.new(self)
end
function WorldScene:ScheduleLoadMap()
	self:GetSceneLayer():LoadAlliance()
	self.load_map_node = display.newNode():addTo(self)
end
function WorldScene:LoadMap()
	if self:IsFingerOn() then
		return
	end
	self.load_map_node:stopAllActions()
	self.load_map_node:performWithDelay(function()
		self:GetSceneLayer():LoadAlliance()
	end, 0.5)
end
function WorldScene:GotoPosition(x,y)
    local point = self:GetSceneLayer():ConvertLogicPositionToMapPosition(x,y)
    self:GetSceneLayer():GotoMapPositionInMiddle(point.x, point.y)
end
function WorldScene:OnTouchEnd(pre_x, pre_y, x, y, ismove)
	if not ismove then
		self:LoadMap()
	end
end
function WorldScene:OnTouchMove(...)
	WorldScene.super.OnTouchMove(self, ...)
	self.load_map_node:stopAllActions()
end
function WorldScene:OnTouchExtend(old_speed_x, old_speed_y, new_speed_x, new_speed_y, millisecond, is_end)
	WorldScene.super.OnTouchExtend(self, old_speed_x, old_speed_y, new_speed_x, new_speed_y, millisecond, is_end)
    if is_end then
		self:LoadMap()
	end
end
function WorldScene:OnTouchClicked(pre_x, pre_y, x, y)
    if self:IsFingerOn() then
        return
    end
    local click_object,index = self:GetSceneLayer():GetClickedObject(x, y)
    UIKit:newWidgetUI("WidgetWorldAllianceInfo",click_object,index):AddToCurrentScene()
end

return WorldScene

