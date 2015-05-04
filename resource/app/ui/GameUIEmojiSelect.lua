--
-- Author: Danny He
-- Date: 2015-01-27 10:37:38
--
local GameUIEmojiSelect = UIKit:createUIClass("GameUIEmojiSelect","UIAutoClose")
local EmojiTable = import("..utils.EmojiTable")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetDropList = import("..widget.WidgetDropList")
local window = import("..utils.window")
local UIScrollView = import(".UIScrollView")

function GameUIEmojiSelect:ctor(func)
	GameUIEmojiSelect.super.ctor(self)
	self.selectFunc_ = func
end

function GameUIEmojiSelect:onEnter()
	GameUIEmojiSelect.super.onEnter(self)
    local bg =  WidgetUIBackGround.new({height=658}):pos(window.left+20,window.bottom+100)
    self:addTouchAbleChild(bg)
    local header = display.newSprite("title_blue_600x52.png")
        :addTo(bg,3)
        :align(display.CENTER_BOTTOM, 304, 644)
    UIKit:closeButton():addTo(header)
        :align(display.BOTTOM_RIGHT,header:getContentSize().width, 0)
        :onButtonClicked(function ()
            self:LeftButtonClicked()
        end)
    local title_label = UIKit:ttfLabel({
        text = _("表情"),
        size = 24,
        color = 0xffedae,
    }):align(display.CENTER,header:getContentSize().width/2, header:getContentSize().height/2):addTo(header)
    self.bg = bg
    local dropList = WidgetDropList.new(
		{
			{tag = "Smiley",label = _("笑脸"),default = true},
			{tag = "Flower",label = _("花")},
		},
		function(tag)
			if self.content then 
				self.content:hide()
			end
			if self['DisplayEmojiWith_' .. tag] then
				self.content = self['DisplayEmojiWith_' .. tag](self)
				self.content:show()
			end
		end
	)
	dropList:align(display.CENTER_TOP,bg:getContentSize().width/2,640):addTo(bg,2)
end

function GameUIEmojiSelect:DisplayEmojiWith_Smiley()
	if self.emoji_node_smiley then
		return self.emoji_node_smiley
	end
	local emoji_node = display.newNode():size(self.bg:getContentSize().width - 60,560):pos(10,20):addTo(self.bg,1)
	local emojis = EmojiTable:GetSmileyImages()
	local x,y = 32,518
	for i,v in ipairs(emojis) do
		local img = "#" .. v
        local __,e = string.find(v,"%.")
        local key = string.sub(v,1,e - 1)
        local button = WidgetPushButton.new({normal = img,pressed = img})
            :align(display.CENTER, x,y):addTo(emoji_node)
            :scale(0.7)
        button:onButtonClicked(function()
            	self:__callFunc(key)
            	local action =  transition.sequence({cc.ScaleTo:create(0.1,1),cc.ScaleTo:create(0.1,0.7)})
        		button:runAction(action)
        end)
        x = x + 20 + 32
        if i % 11 == 0 then
            y = y - 52
            x = 32
        end
	end
	self.emoji_node_smiley = emoji_node
	return self.emoji_node_smiley 
end


function GameUIEmojiSelect:DisplayEmojiWith_Flower()
	if self.emoji_node_flower then
		return self.emoji_node_flower
	end
	local emoji_node = display.newNode():size(self.bg:getContentSize().width - 60,560):pos(10,20):addTo(self.bg,1)
	local emojis = EmojiTable:GetFlowerImages()
	local x,y = 32,518
	for i,v in ipairs(emojis) do
		local img = "#" .. v
        local __,e = string.find(v,"%.")
        local key = string.sub(v,1,e - 1)
        local button = WidgetPushButton.new({normal = img,pressed = img})
            :align(display.CENTER, x,y):addTo(emoji_node)
            :scale(0.7)
        button:onButtonClicked(function()
            	self:__callFunc(key)
            	local action =  transition.sequence({cc.ScaleTo:create(0.1,1),cc.ScaleTo:create(0.1,0.7)})
        		button:runAction(action)
        end)
        x = x + 20 + 32
        if i % 11 == 0 then
            y = y - 52
            x = 32
        end
	end
	self.emoji_node_flower = emoji_node
	return self.emoji_node_flower 
end

function GameUIEmojiSelect:OnMoveOutStage()
	self.content = nil
	self.emoji_node_smiley = nil
	self.emoji_node_flower = nil

	GameUIEmojiSelect.super.OnMoveOutStage(self)
end

function GameUIEmojiSelect:__callFunc(key)
	if self.selectFunc_ then
		self.selectFunc_("[" .. key .. "]")
	end
end

return GameUIEmojiSelect