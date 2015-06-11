local UILib = import("..ui.UILib")
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
end
function WidgetSoldier:SetSoldeir(soldierName, soldierStar, isPveSoldier)
	local bg,png = self:GetBgAndPng(soldierName, soldierStar, isPveSoldier)
	self.soldier_bg:setTexture(bg)
	self.soldier_png:setTexture(png)
	local size = self.soldier_png:getContentSize() 
    self.soldier_png:scale(128 / math.max(size.width, size.height))
    return self
end
function WidgetSoldier:GetBgAndPng(soldierName, soldierStar, isPveSoldier)
	soldierStar = soldierStar or 1
	local soldier_bg, soldier_png
	if isPveSoldier and soldierStar >= 2 and not special[soldierName] then
		soldier_bg = "red_bg_128x128.png"
		soldier_png = UILib.black_soldier_image[soldierName][soldierStar]
	else
		soldier_bg = UILib.soldier_color_bg_images[soldierName]
		soldier_png = UILib.soldier_image[soldierName][soldierStar]
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