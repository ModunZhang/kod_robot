--
-- Author: Danny He
-- Date: 2014-11-27 20:23:42
--
local GameUIAttackPlayerCity = UIKit:createUIClass("GameUIAttackPlayerCity")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local content_height = 400
local UILib = import(".UILib")
local UIListView = import(".UIListView")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetSoldierBox = import("..widget.WidgetSoldierBox")

function GameUIAttackPlayerCity:ctor(alliance,to_location,enemyPlayerId)
	-- dump(to_location,"to_location--->")
	self.enemyPlayerId = enemyPlayerId
	assert(enemyPlayerId)
	self.to_location = to_location
	self.alliance = alliance
	GameUIAttackPlayerCity.super.ctor(self)
end


function GameUIAttackPlayerCity:GetAlliance()
	return self.alliance
end

function GameUIAttackPlayerCity:onEnter()
	GameUIAttackPlayerCity.super.onEnter(self)
	self:BuildUI()
end

function GameUIAttackPlayerCity:BuildUI()
	local shadowLayer = display.newColorLayer(UIKit:hex2c4b(0x7a000000))
		:addTo(self)
	local bg_node = WidgetUIBackGround.new({height=content_height}):addTo(shadowLayer):pos(window.left+20,window.bottom+250)
	self.bg_node = bg_node
	local titleBar = display.newScale9Sprite("title_blue_600x52.png")
		:size(bg_node:getCascadeBoundingBox().width,42)
		:align(display.LEFT_BOTTOM, -2,content_height - 15)
		:addTo(bg_node)
	local titleLabel = UIKit:ttfLabel({
		text = _("月门中的部队"),
		size = 22,
		color = 0xffedae
	}):align(display.CENTER,300,21):addTo(titleBar)
	local closeButton = UIKit:closeButton():addTo(titleBar)
   		:align(display.BOTTOM_RIGHT,titleBar:getContentSize().width+10, 0)
   		:onButtonClicked(function ()
   		self:LeftButtonClicked()
   	end)
   	local box = display.newSprite("alliance_item_flag_box_126X126.png"):align(display.LEFT_TOP,30,titleBar:getPositionY()-10):addTo(bg_node):scale(0.7)
   	local head_bg = display.newSprite("chat_hero_background.png", 63, 63):addTo(box)
	display.newSprite(UILib.dragon_head[self:GetMyTroop().dragon.type], 56, 60):addTo(head_bg)

	local line_2 = display.newScale9Sprite("dividing_line.png")
		:align(display.LEFT_BOTTOM,box:getPositionX()+box:getContentSize().width*0.7+10,box:getPositionY()-box:getContentSize().height*0.7):size(450,2)
		:addTo(bg_node)
	local from_label = UIKit:ttfLabel({
		text = _("出发地"),
		size = 20,
		color= 0x797154
	}):align(display.LEFT_BOTTOM, line_2:getPositionX()+2, line_2:getPositionY()+4):addTo(bg_node)

	local from_location = self:GetAlliance():GetAllianceMap():FindAllianceBuildingInfoByName('moonGate').location
	UIKit:ttfLabel({
		text = from_location.x .. "," .. from_location.y,
		size = 20,
		color= 0x403c2f
	}):align(display.RIGHT_BOTTOM, line_2:getPositionX()+line_2:getContentSize().width, from_label:getPositionY()):addTo(bg_node)
	local line_1 = display.newScale9Sprite("dividing_line.png")
		:align(display.LEFT_BOTTOM,line_2:getPositionX(),line_2:getPositionY()+40)
		:addTo(bg_node):size(450,2)

	local to_label = UIKit:ttfLabel({
		text = _("目的地"),
		size = 20,
		color = 0x797154
	}):align(display.LEFT_BOTTOM, line_1:getPositionX()+2, line_1:getPositionY()+4):addTo(bg_node)
	UIKit:ttfLabel({
		text = self.to_location.x .. "," .. self.to_location.y,
		size = 20,
		color= 0x403c2f
	}):align(display.RIGHT_BOTTOM, line_1:getPositionX()+line_1:getContentSize().width, to_label:getPositionY()):addTo(bg_node)
	local left_bottom_x,left_bottom_y = box:getPositionX(),100
	local right_top_x,right_top_y = line_2:getPositionX()+line_2:getContentSize().width,line_2:getPositionY()-5
	local width, height = right_top_x - left_bottom_x, right_top_y - left_bottom_y
	self.list_view = UIListView.new ({
        viewRect = cc.rect(left_bottom_x,left_bottom_y,width,height),
        direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL,
    }):addTo(self.bg_node)

	self.next_tip = display.newSprite("solider_nex_28x42.png"):align(display.LEFT_CENTER,
		 line_2:getPositionX()+line_2:getContentSize().width-10,
		 right_top_y - height/2):addTo(self.bg_node)
	self.pre_tip = display.newSprite("solider_nex_28x42.png")
	self.pre_tip:setFlippedX(true)
	self.pre_tip:align(display.RIGHT_CENTER, box:getPositionX()+10,self.next_tip:getPositionY())
	self.pre_tip:addTo(self.bg_node)
	local button = WidgetPushButton.new({
		normal = "yellow_btn_up_185x65.png",
		pressed = "yellow_btn_down_185x65.png",
	}):align(display.RIGHT_TOP, right_top_x, left_bottom_y - 20):addTo(bg_node)
	:setButtonLabel("normal", UIKit:commonButtonLable({text = _("进攻"),}))
	:onButtonClicked(handler(self, self.OnAttackButtonClicked))
	
     -- 行军所需时间
    local icon = display.newSprite("hourglass_39x46.png"):align(display.LEFT_TOP,260,button:getPositionY()-20)
        :addTo(bg_node):scale(0.6)
    self.march_time = UIKit:ttfLabel({
        text = "20:00:00",
        size = 18,
        color = 0x403c2f
    }):align(display.LEFT_TOP,icon:getPositionX()+icon:getCascadeBoundingBox().width+10,icon:getPositionY()+5):addTo(bg_node)

    -- 科技减少行军时间
    self.buff_reduce_time = UIKit:ttfLabel({
        text = "(-00:20:00)",
        size = 18,
        color = 0x068329
    }):align(display.LEFT_TOP,self.march_time:getPositionX(),self.march_time:getPositionY()-self.march_time:getContentSize().height):addTo(bg_node)
    self:RefreshSoldierListView()
end


function GameUIAttackPlayerCity:RefreshSoldierListView()
	local soldiers = self:GetMyTroop().soldiers
	self.list_view:removeAllItems()
	for _,v in ipairs(soldiers) do
		local item = self.list_view:newItem()
		local content = WidgetSoldierBox.new("",function()end)
		content:SetSoldier(v.name,v.star) -- 这里 name == type??
		content:SetNumber(v.count)
		item:addContent(content)
		item:setItemSize(content:getCascadeBoundingBox().width+20,content:getCascadeBoundingBox().height)
		self.list_view:addItem(item)
	end
	self.list_view:reload()
end

function GameUIAttackPlayerCity:GetMyTroop()
	return Alliance_Manager:GetMyAlliance():GetAllianceMoonGate():GetMyTroop()
end

function GameUIAttackPlayerCity:OnAttackButtonClicked(event)
	NetManager:getAttackPlayerCityPromise(self.enemyPlayerId):done(function()
		self:LeftButtonClicked()
		-- local current_scene = display.getRunningScene()
		-- if type(current_scene.TimerRequestServer) == 'function' then
		-- 	current_scene:TimerRequestServer()
		-- 	print("GameUIAttackPlayerCity:OnAttackButtonClicked--->")
		-- end
	end)
end

return GameUIAttackPlayerCity