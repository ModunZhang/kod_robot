--
-- Author: Danny He
-- Date: 2015-01-27 10:37:38
--
local GameUIEmojiSelect = UIKit:createUIClass("GameUIEmojiSelect","UIAutoClose")
local EmojiTable = import("..utils.EmojiTable") -- 220 count of emoji
local WidgetPushButton = import("..widget.WidgetPushButton")
local window = import("..utils.window")
local UIPageView = import("..ui.UIPageView")
local PAGE_VIEW_WIDTH = 510
local PAGE_VIEW_HEIGHT = 410
local UIListView = import(".UIListView")


function GameUIEmojiSelect:ctor(func)
	GameUIEmojiSelect.super.ctor(self)
	self.selectFunc_ = func
end

function GameUIEmojiSelect:onEnter()
	GameUIEmojiSelect.super.onEnter(self)
	self:BuildUI()
end

function GameUIEmojiSelect:BuildUI()
	local bg = display.newSprite("emoji_bg_536x478.png"):align(display.BOTTOM_CENTER, window.cx, window.bottom+200)
	self:addTouchAbleChild(bg)
	local one_x,two_x = 238,290
	local page = display.newSprite("emoji_page_8x8.png"):align(display.LEFT_CENTER,one_x, 39):addTo(bg)
	self.page = page
	local pv = UIPageView.new {
        viewRect = cc.rect(10, 56, PAGE_VIEW_WIDTH, PAGE_VIEW_HEIGHT),
        row = 1,
        padding = {left = 0, right = 0, top = 10, bottom = 0},
        gap = 10,
        speed_limit = 5,
    }:onTouch(function (event)
        if event.name == "pageChange" then
            if 1 == event.pageIdx then
              	self.page:setPositionX(one_x)
            elseif 2 == event.pageIdx then
              	self.page:setPositionX(two_x)
            end
        end
    end):addTo(bg)
    pv:setTouchEnabled(true)
    pv:setTouchSwallowEnabled(false)
    pv:setCascadeOpacityEnabled(true)
    local item = pv:newItem()
    local content = self:BuildEmojiNode(1,110)
    item:addChild(content)
    pv:addItem(item)    
    item = pv:newItem()
    content = self:BuildEmojiNode(111,220)
    item:addChild(content)
    pv:addItem(item)   
    pv:reload()
end

function GameUIEmojiSelect:BuildEmojiNode(start_index,end_index)
	if not end_index then end_index = #EmojiTable end
	local emoji_node = display.newNode():size(PAGE_VIEW_WIDTH,PAGE_VIEW_HEIGHT)
	local x,y = 16,394 --392
	for index = start_index,end_index do
		local img = EmojiTable[index]
		local __,__,key = string.find(img, "(.+)%.")
		local button = WidgetPushButton.new({normal = "#" .. img}):pos(x, y):addTo(emoji_node):scale(0.5)
		button:onButtonClicked(function()
			self:callFunc__(key)
			local action =  transition.sequence({cc.ScaleTo:create(0.1,0.6),cc.ScaleTo:create(0.1,0.5)})
			button:runAction(action)
		end)			
		x = x + 48
        if index % 11 == 0 then
            y = y - 42
            x = 16
        end
	end
	return emoji_node
end

function GameUIEmojiSelect:OnMoveOutStage()
	GameUIEmojiSelect.super.OnMoveOutStage(self)
end

function GameUIEmojiSelect:callFunc__(key)
	if self.selectFunc_ then
		self.selectFunc_("[" .. key .. "]")
	end
end

return GameUIEmojiSelect