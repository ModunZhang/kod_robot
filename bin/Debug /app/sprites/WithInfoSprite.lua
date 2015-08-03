local UILib = import("..ui.UILib")
local Sprite = import(".Sprite")
local WithInfoSprite = class("WithInfoSprite", Sprite)


function WithInfoSprite:ctor(city_layer, entity, is_my_alliance)
    self:setNodeEventEnabled(true)
    self.is_my_alliance = is_my_alliance
    local x, y = city_layer:GetLogicMap():ConvertToMapPosition(entity:GetLogicPosition())
    WithInfoSprite.super.ctor(self, city_layer, entity, x, y)
end
function WithInfoSprite:onExit()
    if self.info then
        self.info:removeFromParent()
    end
end
function WithInfoSprite:RefreshSprite()
    WithInfoSprite.super.RefreshSprite(self)
    if self.info then
        self.info:removeFromParent()
        self.info = nil
    end
    local map_layer = self:GetMapLayer()
    local x,y = map_layer:GetLogicMap():ConvertToMapPosition(self:GetEntity():GetLogicPosition())
    self.info = display.newNode():addTo(map_layer:GetInfoNode()):pos(x, y - 50):scale(0.8):zorder(x * y)

    local banners = self.is_my_alliance and UILib.my_city_banner or UILib.enemy_city_banner
    self.banner = display.newSprite(banners[0]):addTo(self.info):align(display.CENTER_TOP)
    self.level = UIKit:ttfLabel({
        size = 22,
        color = 0xffedae,
    }):addTo(self.banner):align(display.CENTER, 30, 30)
    self.name = UIKit:ttfLabel({
        size = 20,
        color = 0xffedae,
    }):addTo(self.banner):align(display.LEFT_CENTER, 60, 32)
    self:RefreshInfo()
end
function WithInfoSprite:RefreshInfo()
    local level, name, banner_head_png = self:GetInfo()
    if banner_head_png then
    	self.banner:setTexture(banner_head_png)
    end
    self.level:setString(level)
    self.name:setString(name)
end
function WithInfoSprite:GetInfo()
	assert(false)
end


---
function WithInfoSprite:CreateBase()
    self:GenerateBaseTiles(1, 1)
end
function WithInfoSprite:newBatchNode(w, h)
    local start_x, end_x, start_y, end_y = self:GetLocalRegion(w, h)
    local base_node = display.newBatchNode("grass_80x80_.png", 10)
    local map = self:GetLogicMap()
    for ix = start_x, end_x do
        for iy = start_y, end_y do
			display.newSprite(base_node:getTexture()):addTo(base_node):pos(map:ConvertToLocalPosition(ix, iy)):scale(2)
        end
    end
    return base_node
end
return WithInfoSprite