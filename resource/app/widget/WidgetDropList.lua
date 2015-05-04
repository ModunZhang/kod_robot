--
-- Author: Danny He
-- Date: 2014-11-19 08:34:30
--
--[[
	example:
	local dropList = WidgetDropList.new(
		{
			{tag = "menu_1",label = "菜单一",default = true},
			{tag = "menu_2",label = "菜单二"},
			...
		},
		function(tag)
			if tag == 'menu_1' then
				...
			end
		end
	)
	dropList:align(display.LEFT_BOTTOM,0,0):addTo(ccNode)
	dropList:SetSelectByTag("menu_2",false)
	assert(dropList:GetSelectdTag() == "menu_2")
]]--

local Enum = import("..utils.Enum")
local ClipHeight = 188
local Animate_Time_Inteval = 0.1
local WidgetPushTransparentButton = import(".WidgetPushTransparentButton")
local WidgetDropList = class("WidgetDropList",function()
	return display.newNode()
end)

WidgetDropList.STATE = Enum("open","close")

function WidgetDropList:ctor(params,callback)
	assert(params)
	self.items_ = params
	self.state_ = self.STATE.close
	self.state_buttons = {}
	self.callback_ = callback
	self.selected_tag = ""
	self:onEnter()
end

function WidgetDropList:onEnter()
	ClipHeight = #self.items_ * 52 + 32
	local clip_node = display.newClippingRegionNode(cc.rect(0,0,566,ClipHeight)):addTo(self):pos(0,20-ClipHeight)
	local content_box = display.newScale9Sprite("drop_down_box_bg_566x188.png")
		:size(566,ClipHeight)
		:align(display.LEFT_BOTTOM, 0, ClipHeight)
		:addTo(clip_node)
	content_box:setTouchCaptureEnabled(false)
	content_box:setTouchEnabled(true)
	content_box:setTouchSwallowEnabled(false)
	self.clip_node = clip_node
	local header = display.newSprite("drop_down_box_content_562x58.png"):align(display.LEFT_BOTTOM,2,0):addTo(self)
	self.header = header
	WidgetPushTransparentButton.new(cc.rect(0,0,562,58))
		:align(display.LEFT_BOTTOM, 0, 0)
		:addTo(header)
		:onButtonClicked(handler(self, self.OnBoxButtonClicked))
	local button = cc.ui.UIPushButton.new({normal = "drop_down_box_button_normal_52x44.png",pressed = "drop_down_box_button_light_52x44.png"})
		:align(display.RIGHT_BOTTOM, 554,7):addTo(header)
		:onButtonClicked(handler(self, self.OnBoxButtonClicked))
	display.newSprite("drop_down_box_icon_3128.png"):addTo(button):pos(-26,22)
	self.title_label = UIKit:ttfLabel({
		text = "",
		size = 20,
		color = 0x5d563f
	}):align(display.LEFT_CENTER, 20, 29):addTo(header)

	self.content_box = content_box
	self:BuildList()
	local bottom = display.newSprite("drop_down_box_bottom_572x16.png")
	bottom:align(display.LEFT_BOTTOM,-2,7):addTo(content_box)
	self:addTouchNode_()
end

function WidgetDropList:BuildList()
	local x,y = 9,13
	local selectTag = ""
	for i= #self.items_,1,-1 do
		local item = self.items_[i]
		local button = cc.ui.UIPushButton.new({normal = string.format("box_bg_item_520x48_%d.png",(i-1)%2)},{scale9 = true})
			:setButtonSize(548, 52)
			:align(display.LEFT_BOTTOM,x, y):addTo(self.content_box)
			:onButtonClicked(function(event)
				print("OnItemSelected---->")
				dump(event,"event--->")
				self:OnItemSelected(item.tag)
			end)
		local statebutton = cc.ui.UIPushButton.new({normal = "checkbox_unselected.png",disabled = "checkbox_selectd.png"})
			:align(display.LEFT_CENTER,20,26):scale(0.65)
			:addTo(button)
		statebutton.tag = item.tag 
		table.insert(self.state_buttons,statebutton)
		UIKit:ttfLabel({
			text = item.label,
			size = 20,
			color = 0x5d563f
		}):align(display.LEFT_CENTER, 80,26):addTo(button)
		y = y + 52
		if item.default then 
			selectTag = item.tag
		end
	end
	if selectTag ~= "" then
		self:SetSelectByTag(selectTag)
	end
end

function WidgetDropList:SetSelectByTag(tag,dispathEvent)
	if dispathEvent == nil then 
		dispathEvent = true
	end
	local text = ""
	for _,v in ipairs(self.items_) do
		if tag == v.tag then
			text = v.label
			break
		end
	end
	for _,button in ipairs(self.state_buttons) do
		if button.tag == tag then
			button:setButtonEnabled(false)
		else
			button:setButtonEnabled(true)
		end
	end
	self.title_label:setString(text) 
	if self.selected_tag ~= tag then
		if dispathEvent and self.callback_ then
			self.callback_(tag)
		end
		self.selected_tag = tag
	end
end

function WidgetDropList:GetSelectdTag()
	return self.selected_tag
end

function WidgetDropList:OnItemSelected(tag)
	self:SetSelectByTag(tag)
	self:OnBoxButtonClicked()
end

function WidgetDropList:GetState()
	return self.state_
end

function WidgetDropList:OnBoxButtonClicked( event )
	if self.lock_ then return end
	self.lock_ = true
	if self:GetState() == self.STATE.close then
		self.content_box:show()
		transition.execute(self.content_box, cc.MoveBy:create(Animate_Time_Inteval, cc.p(0, -ClipHeight)), {
    		easing = "sineInOut",
    		onComplete = function()
        		self.state_ = self.STATE.open
        		self.lock_ = false
        		self.content_box:setTouchCaptureEnabled(true)
    		end,
		})
	else
		transition.execute(self.content_box, cc.MoveTo:create(Animate_Time_Inteval, cc.p(0,ClipHeight)), {
    		easing = "sineInOut",
    		onComplete = function()
    			self.content_box:hide()
        		self.state_ = self.STATE.close
        		self.lock_ = false
        		self.content_box:setTouchCaptureEnabled(false)
    		end,
		})
	end
end

function WidgetDropList:align(anchorPoint, x, y)
	display.align(self,anchorPoint,x,y)
	local anchorPoint = display.ANCHOR_POINTS[anchorPoint]
	local header = self.header
	local size = header:getContentSize()
	local header_anchorPoint = header:getAnchorPoint()
	header:setPosition(header:getPositionX()+size.width*(header_anchorPoint.x - anchorPoint.x),header:getPositionY()+size.height*(header_anchorPoint.y - anchorPoint.y))
	local clip_node = self.clip_node
	clip_node:setPosition(clip_node:getPositionX()+size.width*(- anchorPoint.x), clip_node:getPositionY()+size.height*(- anchorPoint.y))
	size = self.touchNode_:getContentSize()
	self.touchNode_:setPosition(self.touchNode_:getPositionX()+size.width*(- anchorPoint.x), self.touchNode_:getPositionY()+size.height*(- anchorPoint.y))

	return self
end

function WidgetDropList:addTouchNode_()
	local node
	if self.touchNode_ then
		node = self.touchNode_
	else
		node = display.newNode()
		self.touchNode_ = node
		node:setLocalZOrder(-1)
		node:setTouchEnabled(true)
		node:addNodeEventListener(cc.NODE_TOUCH_EVENT, function (event)
			print("cc.NODE_TOUCH_EVENT---->")
	        return self:onTouch_(event)
	    end)
		node:addNodeEventListener(cc.NODE_TOUCH_CAPTURE_EVENT, function(event)
			local cascadeBound = self.header:getCascadeBoundingBox()
			if cc.rectContainsPoint(cascadeBound, cc.p(event.x, event.y)) then
				print("cc.NODE_TOUCH_CAPTURE_EVENT---->true")
				return true
			else
				print("cc.NODE_TOUCH_CAPTURE_EVENT---->",not self.lock_ and self:GetState() == self.STATE.open	)
        		return not self.lock_ and self:GetState() == self.STATE.open	
			end
    	end)
	    self:addChild(node)
	end
	local nodePoint = self:convertToNodeSpace(cc.p(0,0))
	node:size(display.width,display.height)
	node:setPosition(nodePoint.x,nodePoint.y)
end

function WidgetDropList:onTouch_(event)
	if not self.lock_ and self:GetState() == self.STATE.open then
		self:OnBoxButtonClicked()
	end
	return false
end

return WidgetDropList