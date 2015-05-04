--
-- Author: Danny He
-- Date: 2014-11-27 11:19:01
--
local GameUIStrikePlayer = UIKit:createUIClass("GameUIStrikePlayer","GameUIWithCommonHeader")
local window = import("..utils.window")
local UIListView = import(".UIListView")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UILib = import(".UILib")
local Enum = import("..utils.Enum")

GameUIStrikePlayer.STRIKE_TYPE = Enum("CITY","VILLAGE")
function GameUIStrikePlayer:ctor(params,strike_type)
	GameUIStrikePlayer.super.ctor(self,City,_("准备突袭"))
	self.dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
	self.params = params
	self.strike_type = strike_type or self.STRIKE_TYPE.CITY
	assert(params)
end

function GameUIStrikePlayer:GetDragonManager()
	return self.dragon_manager
end

function GameUIStrikePlayer:OnMoveInStage()
	GameUIStrikePlayer.super.OnMoveInStage(self)
	self:BuildUI()
end

function GameUIStrikePlayer:CreateBetweenBgAndTitle()
	self.content_node = display.newNode():addTo(self:GetView())
end

function GameUIStrikePlayer:BuildUI()
	self.dragon_sprite = display.newSprite("red_dragon_big_612x260.png")
		:align(display.CENTER_TOP,window.cx,window.top)
		:addTo(self.content_node)
	local black_layer = UIKit:shadowLayer():size(619,54):addTo(self.content_node):pos(window.left+10,window.top - 260)
	UIKit:ttfLabel({
		text = _("派出巨龙突袭可以侦查到敌方的城市信息"),
		size = 20,
		color = 0xffedae
	}):align(display.CENTER, 310, 27):addTo(black_layer)
	display.newSprite("black_line_624x4.png"):align(display.LEFT_BOTTOM,0,0):addTo(black_layer)
	self.list_view = UIListView.new ({
        viewRect = cc.rect(black_layer:getPositionX()+30,window.bottom + 80,window.width-80,window.height - 340),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        alignment = UIListView.ALIGNMENT_LEFT
    }):addTo(self.content_node)

	WidgetPushButton.new({
		normal = "yellow_btn_up_149x47.png",
		pressed = "yellow_btn_down_149x47.png"
		},nil,nil,{down = "DRAGON_STRIKE"})
		:align(display.CENTER_BOTTOM,window.cx,window.bottom + 20)
		:addTo(self.content_node)
		:setButtonLabel("normal",UIKit:commonButtonLable({
			text = _("突袭")
		}))
		:onButtonClicked(function()
			local select_DragonType = self:GetSelectDragonType()
			local dragon = self:GetDragonManager():GetDragon(select_DragonType)
			if dragon:WarningStrikeDragon() then
				UIKit:showMessageDialog(_("提示"),_("您派出的龙可能会因血量过低而死亡，您确定还要派出吗？"), function()
					self:OnStrikeButtonClicked()
				end, function()end)
			end
		end)
    self:RefreshListView()
end

function GameUIStrikePlayer:RefreshListView()
	local dragons = self:GetDragonManager():GetDragons()
	local power_dragon_type = self:GetDragonManager():GetCanFightPowerfulDragonType()
	if power_dragon_type == "" then
		power_dragon_type = self:GetDragonManager():GetPowerfulDragonType()
	end
 	for k,dragon in pairs(dragons) do
		if dragon:Ishated() then
			local item = self:GetItem(dragon,power_dragon_type)
			self.list_view:addItem(item)
		end
	end
	self.list_view:reload()
end

function GameUIStrikePlayer:GetItem(dragon,power_dragon_type)
	local item = self.list_view:newItem()
	local content = display.newNode()
	local box = display.newSprite("alliance_item_flag_box_126X126.png")
		:align(display.LEFT_BOTTOM,0,0)
		:addTo(content)
	local head_bg = display.newSprite("chat_hero_background.png", 63, 63):addTo(box)
	display.newSprite(UILib.dragon_head[dragon:Type()], 56, 60):addTo(head_bg)
	local content_box = display.newScale9Sprite("alliance_approval_box_450x126.png")
		:size(426,126)
		:addTo(content)
		:align(display.LEFT_BOTTOM,128,0)
	UIKit:ttfLabel({
		text = dragon:GetLocalizedName() .. "( LV " .. dragon:Level() .. " )",
		size = 22,
		color = 0x514d3e,
	}):align(display.LEFT_TOP,20, 120):addTo(content_box)

	UIKit:ttfLabel({
		text = _("生命值") .. " " .. dragon:Hp() .. "/" .. dragon:GetMaxHP(),
		size = 20,
		color= 0x797154
	}):align(display.LEFT_CENTER,20,63):addTo(content_box)
	local color = 0x007c23
	if dragon:Status() == 'march' then
		color = 0x7e0000
	end
	UIKit:ttfLabel({
		text = dragon:GetLocalizedStatus(),
		size = 20,
		color = color
	}):align(display.LEFT_BOTTOM,20,16):addTo(content_box)
	local button = WidgetPushButton.new({
		normal = "checkbox_unselected.png",disabled = "checkbox_selectd.png"
	}):align(display.RIGHT_CENTER,400,63):addTo(content_box)
	:onButtonClicked(function(event)
		self:OnButtonClickInItem(dragon:Type())
	end)
	if power_dragon_type == dragon:Type() then
		button:setButtonEnabled(false)
		self.select_dragon_type = dragon:Type()
	end
	item.dragon_type = dragon:Type()
	item.button = button
	item:addContent(content)
	item:setItemSize(window.width-80, 132)
	content:size(window.width-80, 132)
	return item
end

function GameUIStrikePlayer:OnButtonClickInItem(dragon_type)
	for _,item in ipairs(self.list_view:getItems()) do
		item.button:setButtonEnabled(dragon_type~=item.dragon_type)
	end	 
	self.select_dragon_type = dragon_type
end

function GameUIStrikePlayer:GetSelectDragonType()
	return self.select_dragon_type
end

function GameUIStrikePlayer:OnStrikeButtonClicked()
	if self.strike_type == self.STRIKE_TYPE.CITY then
		NetManager:getStrikePlayerCityPromise(self:GetSelectDragonType(),self.params):done(function()
			self:LeftButtonClicked()
		end)
	else
		NetManager:getStrikeVillagePromise(self:GetSelectDragonType(),self.params.defenceAllianceId,self.params.defenceVillageId):done(function()
			self:LeftButtonClicked()
		end)
	end
end

return GameUIStrikePlayer
