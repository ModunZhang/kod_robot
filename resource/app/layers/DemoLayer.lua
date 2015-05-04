local MultiCorps = import("..ui.MultiCorps")
local UILib = import("..ui.UILib")
local BattleObject = import("..ui.BattleObject")
local cocos_promise = import("..utils.cocos_promise")
local promise = import("..utils.promise")
local NormalMapAnchorBottomLeftReverseY = import("..map.NormalMapAnchorBottomLeftReverseY")
local MapLayer = import(".MapLayer")
local DemoLayer = class("DemoLayer", MapLayer)


function DemoLayer:ctor()
    DemoLayer.super.ctor(self, 0.3, 1)
    self.background = cc.TMXTiledMap:create("tmxmaps/demo.tmx"):addTo(self)
    self.normal_map = NormalMapAnchorBottomLeftReverseY.new({
        tile_w = 80,
        tile_h = 80,
        map_width = 21,
        map_height = 28,
        base_x = 0,
        base_y = 28 * 80,
    })

    local manager = ccs.ArmatureDataManager:getInstance()
    for _, anis in pairs(UILib.soldier_animation_files) do
        for _, v in pairs(anis) do
            manager:addArmatureFileInfo(v)
        end
    end
    -- manager:addArmatureFileInfo("animations/dragon_red/dragon_red.ExportJson")

    local corps = {}
    for i = 1, 6 do
        corps[i] = MultiCorps.new():addTo(self):pos(self.normal_map:ConvertToMapPosition(0, 0)):hide()
        corps[i]:setColor(cc.c3b(80, 80, 80))
    end
    self.corps = corps

    local armature = ccs.Armature:create("dragon_red"):addTo(self):pos(self.normal_map:ConvertToMapPosition(6, 25))
    armature:getAnimation():play("Idle")
    armature:setScaleX(-1)
    self.dragon = armature
end
function DemoLayer:onEnter()
	self:test()
end
function DemoLayer:DefferGetCorps(index)
    return cocos_promise.defer(function()
        return self.corps[index]:show()
    end)
end
function DemoLayer:ConvertLogicPositionToMapPosition(lx, ly)
    local map_pos = cc.p(self.normal_map:ConvertToMapPosition(lx, ly))
    return self:convertToNodeSpace(self.background:convertToWorldSpace(map_pos))
end
function DemoLayer:getContentSize()
    if not self.content_size then
        local layer = self.background:getLayer("layer1")
        self.content_size = layer:getContentSize()
    end
    return self.content_size
end
function DemoLayer:OnSceneMove()

end
function DemoLayer:OnSceneScale()

end
function DemoLayer:GotoLogicPointInstant(x, y)
    local point = self:ConvertLogicPositionToMapPosition(x, y)
    self:GotoMapPositionInMiddle(point.x, point.y)
    return cocos_promise.defer()
end
function DemoLayer:GotoLogicPoint(x, y, s)
    local point = self:ConvertLogicPositionToMapPosition(x, y)
    return self:PromiseOfMove(point.x, point.y, s)
end
function DemoLayer:test()
	local scene = self

	scene:GotoLogicPointInstant(5, 20):next(function(result)
	return	promise.all(self:DefferGetCorps(1):next(function(result)
	return	result:move(0, self.normal_map:ConvertToMapPosition(5, 18))
end):next(function(result)
	return	result:breath(true)
end), self:DefferGetCorps(2):next(function(result)
	return	result:move(0, self.normal_map:ConvertToMapPosition(5, 22))
end):next(function(result)
	return	result:breath(true)
end), self:DefferGetCorps(3):next(function(result)
	return	result:move(0, self.normal_map:ConvertToMapPosition(5, 26))
end):next(function(result)
	return	result:breath(true)
end), self:DefferGetCorps(4):next(function(result)
	return	result:move(0, self.normal_map:ConvertToMapPosition(0, 18))
end):next(function(result)
	return	result:breath(true)
end), self:DefferGetCorps(5):next(function(result)
	return	result:move(0, self.normal_map:ConvertToMapPosition(0, 22))
end):next(function(result)
	return	result:breath(true)
end), self:DefferGetCorps(6):next(function(result)
	return	result:move(0, self.normal_map:ConvertToMapPosition(0, 26))
end):next(function(result)
	return	result:breath(true)
end))
end):next(function(result)
	return	scene:GotoLogicPoint(15, 20)
end):next(function(result)
	return	cocos_promise.Delay(1, function() return result end)
end):next(function(result)
	return	scene:GotoLogicPoint(5, 20)
end):next(function(result)
	return	promise.all(self:DefferGetCorps(1):next(function(result)
	return	result:move(15, self.normal_map:ConvertToMapPosition(25, 18))
end):next(function(result)
	return	result:breath(true)
end), self:DefferGetCorps(2):next(function(result)
	return	result:move(15, self.normal_map:ConvertToMapPosition(25, 22))
end):next(function(result)
	return	result:breath(true)
end), self:DefferGetCorps(3):next(function(result)
	return	result:move(15, self.normal_map:ConvertToMapPosition(25, 26))
end):next(function(result)
	return	result:breath(true)
end), self:DefferGetCorps(4):next(function(result)
	return	result:move(15, self.normal_map:ConvertToMapPosition(20, 18))
end):next(function(result)
	return	result:breath(true)
end), self:DefferGetCorps(5):next(function(result)
	return	result:move(15, self.normal_map:ConvertToMapPosition(20, 22))
end):next(function(result)
	return	result:breath(true)
end), self:DefferGetCorps(6):next(function(result)
	return	result:move(15, self.normal_map:ConvertToMapPosition(20, 26))
end):next(function(result)
	return	result:breath(true)
end))
end)
end


return DemoLayer



