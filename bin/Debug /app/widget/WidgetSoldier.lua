local UILib = import("..ui.UILib")
local StarBar = import("..ui.StarBar")
local WidgetSoldier = class("WidgetSoldier", function()
	return display.newNode()
end)
local normal = GameDatas.Soldiers.normal
local special = GameDatas.Soldiers.special
function WidgetSoldier:ctor(soldierName, soldierStar, isPveSoldier)
	local bg,png = self:GetBgAndPng(soldierName, soldierStar, isPveSoldier)
	local t1 = display.newSprite(bg, nil, nil, {class=cc.FilteredSpriteWithOne}):addTo(self)
    local p1 = t1:getAnchorPointInPoints()
    local t2 = display.newSprite(png, nil, nil, {class=cc.FilteredSpriteWithOne}):addTo(t1):pos(p1.x, p1.y)
    display.newSprite("box_soldier_128x128.png"):addTo(t1):pos(p1.x, p1.y)

    self.soldier_bg = t1
    self.soldier_png = t2
    local size = self.soldier_png:getContentSize() 
    self.soldier_png:scale(128 / math.max(size.width, size.height))

    self.soldier_star_bg = display.newSprite("tmp_back_ground_102x22.png")
    						:addTo(self.soldier_png):align(display.CENTER,58,15)
	self.starbar = StarBar.new({
        max = 3,
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
        num = soldierStar,
        margin = 5,
        direction = StarBar.DIRECTION_HORIZONTAL,
        scale = 0.8,
    }):addTo(self.soldier_png):align(display.CENTER,58,15)
end
function WidgetSoldier:SetSoldeir(soldierName, soldierStar, isPveSoldier)
	local bg,png = self:GetBgAndPng(soldierName, soldierStar, isPveSoldier)
	self.soldier_bg:setTexture(bg)
	self.soldier_png:setTexture(png)
	local size = self.soldier_png:getContentSize() 
    self.soldier_png:scale(128 / math.max(size.width, size.height))
    self.starbar:setNum(soldierStar)

    self.starbar:setVisible(soldierName ~= "wall")
    self.soldier_star_bg:setVisible(soldierName ~= "wall")
    return self
end
function WidgetSoldier:GetBgAndPng(soldierName, soldierStar, isPveSoldier)
	soldierStar = soldierStar or 1
	local soldier_bg, soldier_png
	if isPveSoldier and soldierStar >= 2 and not special[soldierName] then
		soldier_bg = "red_bg_128x128.png"
		soldier_png = UILib.black_soldier_image[soldierName]
	else
		soldier_bg = UILib.soldier_color_bg_images[soldierName]
		soldier_png = UILib.soldier_image[soldierName]
	end
	return soldier_bg, soldier_png
end
function WidgetSoldier:SetEnable(isEnable)
	self.soldier_bg:clearFilter()
	self.soldier_png:clearFilter()
	if not isEnable then
    	self.soldier_png:setFilter(filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1}))
    	self.soldier_bg:setFilter(filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1}))
	end
	return self
end

return WidgetSoldier