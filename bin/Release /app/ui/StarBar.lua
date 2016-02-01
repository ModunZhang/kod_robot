-- 用于星级显示或者分页控件 支持横竖
local StarBar = class("StarBar",function()
		return display.newNode()
end)

StarBar.DIRECTION_VERTICAL		= 1
StarBar.DIRECTION_HORIZONTAL	= 2

function StarBar:ctor(params)
	assert(params)
	self.items_ = {}
	self.params_ = {
		max = params.max,
		bg  = params.bg,
		fill = params.fill,
		num = params.num or 0,
		fillOffset = params.fillOffset or cc.p(0,0),
		scale = params.scale or 1,
		margin = params.margin or 0,
		fillFunc = params.fillFunc or function(index,current,max)
			return index <= current
		end,
		direction = params.direction or StarBar.DIRECTION_HORIZONTAL,
	}
 	for i=1,self.params_.max or 1 do
		local stars = display.newSprite(params.bg):addTo(self)
		stars:setScale(self.params_ .scale)
		if self.params_.direction == StarBar.DIRECTION_HORIZONTAL then
			stars:align(display.LEFT_BOTTOM,(i-1)*((self.params_.margin or 0)+stars:getCascadeBoundingBox().width) , 0)
		else
			stars:align(display.LEFT_BOTTOM, 0, (i-1)*((params.margin or 0)+stars:getCascadeBoundingBox().height))
		end
 		stars.fill_ = display.newSprite(self.params_.fill):addTo(stars):pos(stars:getContentSize().width /2 +  self.params_.fillOffset.x ,stars:getContentSize().height/2 + self.params_.fillOffset.y)
 		stars.fill_:setVisible(self.params_.fillFunc(i,self.params_.num or 0,self.params_.max))
		table.insert(self.items_,stars)
	end
end


function StarBar:onExit()
	self.params_ = nil
	self.items_ = nil
end

function StarBar:getContentSize()
	local lastItem = self.items_[#self.items_]
	if not lastItem then return {width = 0,height = 0} end
	if self.params_.direction == StarBar.DIRECTION_HORIZONTAL then
		return {width = (lastItem:getPositionX()+lastItem:getContentSize().width)*self.params_.scale,height = lastItem:getContentSize().height*self.params_.scale}
	else
		return {width = lastItem:getContentSize().width,height = lastItem:getPositionY()+lastItem:getContentSize().height}
	end
end

function StarBar:setNum(num)
	self.params_.num = num
	for i,v in ipairs(self.items_) do
		v.fill_:setVisible(self.params_.fillFunc(i,self.params_.num or 0,self.params_.max))
	end
end

function StarBar:align(anchorPoint, x, y)
	display.align(self,anchorPoint,x,y)
	local anchorPoint = display.ANCHOR_POINTS[anchorPoint]
	local size = self:getContentSize()
	for i,v in ipairs(self.items_) do
		local new_x = v:getPositionX() + size.width * (v:getAnchorPoint().x - anchorPoint.x)
		local new_y = v:getPositionY() + size.height * (v:getAnchorPoint().y - anchorPoint.y)
		v:setPosition(cc.p(new_x,new_y))
	end
	return self
end

return StarBar