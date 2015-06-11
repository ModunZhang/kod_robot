--
-- Author: Danny He
-- Date: 2014-12-25 17:50:45
--
local UIListView = import("..ui.UIListView")
local UIScrollView = import("..ui.UIScrollView")
local WidgetPushButton = import("..widget.WidgetPushButton")
local Enum = import("..utils.Enum")

local WidgetPushTransparentButton = import(".WidgetPushTransparentButton")
local DELEGATE_METHODS = Enum("OnMedalButtonClicked","OnTitleButtonClicked","OnPlayerNameCliked","OnPlayerIconCliked",
	"DataSource","PlayerCanClickedButton")


local WidgetPlayerNode = class("WidgetPlayerNode", function()
	return display.newNode()
end)

--size == view size
function WidgetPlayerNode:ctor(size,delegate)
	size = size or {}
	size.width = size.width or 560
	self.size_ = size
	self:size(size)
	self.listView_ = UIListView.new {
    	viewRect = cc.rect(0, 0,size.width,size.height),
        direction = UIScrollView.DIRECTION_VERTICAL,
    }:addTo(self)
    if delegate then
    	self:SetDelegate(delegate)
    end
end


function WidgetPlayerNode:RefreshUI()
	self:GetListView():removeAllItems()
	self:GetListView():addItem(self:GetBasicInfoItemNode())
	--暂时关闭勋章
	-- self:GetListView():addItem(self:GetMedalItemNode())
	self:GetListView():addItem(self:GetTitleItemNode())
	local data_list = self:BuildDataItemNode()
	self:GetListView():addItem(data_list)
	self:GetListView():reload()
end

function WidgetPlayerNode:RefreshUIPart(flag)
	if flag == 'BasicInfoData' then
	elseif flag == 'MedalData' then
	elseif flag == 'TitleData' then

	end
end


function WidgetPlayerNode:GetSize()
	return self.size_
end


function WidgetPlayerNode:GetListView()
	return self.listView_
end

function WidgetPlayerNode:GetBoxNodeWithTitle(title)
	local medal_node = UIKit:CreateBoxPanelWithBorder({width = 556,height = 156})
	local title_bar = display.newSprite("player_node_title_546x34.png"):align(display.LEFT_TOP,5,150):addTo(medal_node)
	UIKit:ttfLabel({
		text = title,
		size = 22,
		color= 0xffedae
	}):align(display.CENTER,273, 17):addTo(title_bar)
	return medal_node
end

function WidgetPlayerNode:GetTitleItemNode(basic_data)
	local data_source = basic_data or self:CallDelegate_(DELEGATE_METHODS.DataSource,{"TitleData"})
	local item = self:GetListView():newItem()
	local node = display.newNode():size(self:GetSize().width,156)
	local content = self:GetBoxNodeWithTitle(_("头衔")):addTo(node):align(display.LEFT_BOTTOM,(self:GetSize().width - 556)/2,0)
	local title_button = WidgetPushButton.new({normal = "player_title_icon_bg_102x102.png"})
			:align(display.LEFT_BOTTOM, 14, 10):addTo(content)
			:onButtonClicked(function()
				if self:CallDelegate_(DELEGATE_METHODS.PlayerCanClickedButton,{"PlayerTitle"}) then
					self:CallDelegate_(DELEGATE_METHODS.OnTitleButtonClicked)
				end
			end)
	if data_source.image then 
		display.newSprite(data_source.image, 51, 51):addTo(title_button)
	end
	UIKit:ttfLabel({
		text = data_source.desc or _("头衔为空，占领王城后可以给其他玩家指定头衔"),
		size = 20,
		color= 0x403c2f,
		dimensions = cc.size(389, 79)
	}):align(display.LEFT_TOP, title_button:getPositionX()+102 + 18, title_button:getPositionY()+102 - 18):addTo(content)
	item:addContent(node)
	item:setItemSize(self:GetSize().width,156+10)
	return item
end

function WidgetPlayerNode:GetMedalItemNode(basic_data)
	local data_source = basic_data or self:CallDelegate_(DELEGATE_METHODS.DataSource,{"MedalData"})
	local item = self:GetListView():newItem()
	local node = display.newNode():size(self:GetSize().width,156)
	local content = self:GetBoxNodeWithTitle(_("勋章")):addTo(node):align(display.LEFT_BOTTOM,(self:GetSize().width - 556)/2,0)
	local x,y,margin = 15,5,145
	for i=1,4 do
		local button = WidgetPushButton.new({normal = "box_buff_1.png"})
			:align(display.LEFT_BOTTOM, x + (i -1) * margin, 5):addTo(content)
			:onButtonClicked(function()
				if self:CallDelegate_(DELEGATE_METHODS.PlayerCanClickedButton,{"Medal",i}) then 
					self:CallDelegate_(DELEGATE_METHODS.OnMedalButtonClicked,{i})
				end
			end):scale(108/160)
		if data_source[i] then
			display.newSprite(data_source[i], 46, 54):addTo(button)
		end
	end
	item:addContent(node)
	item:setItemSize(self:GetSize().width,156+10)
	return item
end


function WidgetPlayerNode:GetBasicInfoItemNode(basic_data)
	local data_source = basic_data or self:CallDelegate_(DELEGATE_METHODS.DataSource,{"BasicInfoData"})
	local item = self:GetListView():newItem()
	local node = display.newNode()
	local vip_bg  = display.newSprite("player_VIP_bg_110x54.png")
		:align(display.LEFT_BOTTOM,(self:GetSize().width - 560)/2, 0)
		:addTo(node)
	local icon_bg = display.newSprite("player_info_bg_120x120.png")
		:align(display.LEFT_BOTTOM,(self:GetSize().width - 560)/2 - 5,vip_bg:getPositionY()+vip_bg:getContentSize().height - 18)
		:addTo(node,-1)
	UIKit:GetPlayerIconOnly(data_source.playerIcon):addTo(icon_bg):pos(60,70):scale(0.8)
	if self:CallDelegate_(DELEGATE_METHODS.PlayerCanClickedButton,{"PlayerIcon"}) then
		display.newSprite("goods_26x26.png"):align(display.LEFT_BOTTOM, icon_bg:getPositionX()+8, icon_bg:getPositionY()+14):addTo(node)
		WidgetPushTransparentButton.new(cc.rect(0,0,120,175))
        :align(display.LEFT_BOTTOM,0,0)
        :addTo(vip_bg)
        :onButtonClicked(function()
        	self:CallDelegate_(DELEGATE_METHODS.OnPlayerIconCliked)
        end)
	end
	UIKit:ttfLabel({
		text = "VIP " .. data_source.vip,
		size = 18,
		color= 0xe19319
	}):align(display.CENTER_TOP, 55, 50):addTo(vip_bg)
	local name_bar = display.newSprite("title_blue_430x30.png")
		:addTo(node)
		:align(display.LEFT_TOP, icon_bg:getPositionX()+icon_bg:getContentSize().width + 10, icon_bg:getPositionY() + icon_bg:getContentSize().height)
	UIKit:ttfLabel({
		text = data_source.name or "",
		size = 20,
		color= 0xffedae
	}):align(display.LEFT_CENTER, 20, 15):addTo(name_bar)
	if data_source.location then
		UIKit:ttfLabel({
			text = data_source.location ,
			size = 20,
			color= 0xffedae,
			align=cc.TEXT_ALIGNMENT_RIGHT,
		}):align(display.RIGHT_CENTER, 400, 15):addTo(name_bar)
	end
	if self:CallDelegate_(DELEGATE_METHODS.PlayerCanClickedButton,{"PlayerName"}) then
		local icon_edit = display.newSprite("alliance_notice_icon_26x26.png"):addTo(name_bar):align(display.RIGHT_CENTER,400, 15)
		WidgetPushTransparentButton.new(cc.rect(0,0,430,30))
        :align(display.LEFT_BOTTOM,0,0)
        :addTo(name_bar)
        :onButtonClicked(function()
        	self:CallDelegate_(DELEGATE_METHODS.OnPlayerNameCliked)
        end)
	end
	local progress_bg = display.newSprite("progress_bar_410x40_1.png")
		:addTo(node)
		:align(display.LEFT_TOP, name_bar:getPositionX()+10,name_bar:getPositionY()-name_bar:getContentSize().height - 10)

	local progress = UIKit:commonProgressTimer("progress_bar_410x40_2.png")
		:addTo(progress_bg)
		:align(display.LEFT_BOTTOM, 0,0)
	progress:setPercentage(data_source.currentExp/data_source.maxExp*100)
	local xp = display.newSprite("upgrade_experience_icon.png")
		:addTo(progress_bg)
		:align(display.LEFT_CENTER, -14,20)
		:scale(0.7)
	UIKit:ttfLabel({
		text = "LV " .. data_source.lv,
		size = 20,
		color= 0xfff3c7,
		shadow= true
	}):align(display.LEFT_CENTER,xp:getPositionX()+xp:getCascadeBoundingBox().width + 10, 20):addTo(progress_bg)

	UIKit:ttfLabel({
		text =  string.formatnumberthousands(data_source.currentExp)  .. "/" .. string.formatnumberthousands(data_source.maxExp),
		size = 20,
		color= 0xfff3c7,
		shadow= true
	}):align(display.RIGHT_CENTER,400, 20):addTo(progress_bg)
	local power_icon = display.newSprite("dragon_strength_27x31.png")
        :align(display.LEFT_TOP, progress_bg:getPositionX() - 10,progress_bg:getPositionY() - progress_bg:getContentSize().height - 20)
        :addTo(node)
 	local power_label = UIKit:ttfLabel({
		text = _("战斗力") .. ":" .. string.formatnumberthousands(data_source.power),
		size = 22,
		color = 0x403c2f,
	}):addTo(node)
		:align(display.LEFT_BOTTOM, power_icon:getPositionX() + power_icon:getContentSize().width + 5, power_icon:getPositionY() - power_icon:getContentSize().height)
	if self:CallDelegate_(DELEGATE_METHODS.PlayerCanClickedButton,{"PlayerIDCopy"}) then
		WidgetPushButton.new({
			normal = "yellow_btn_up_148x58.png",
			pressed= "yellow_btn_down_148x58.png"
		})
			:align(display.RIGHT_BOTTOM,progress_bg:getPositionX() + progress_bg:getContentSize().width, vip_bg:getPositionY())
			:addTo(node)
			:setButtonLabel("normal",UIKit:commonButtonLable({
				text = _("复制玩家ID"),
				size = 22,
			}))
			:onButtonClicked(function()
				ext.copyText(data_source.playerId)
				 GameGlobalUI:showTips(_("提示"),_("复制成功"))
			end)
	end
	item:addContent(node)
	node:size(self:GetSize().width,node:getCascadeBoundingBox().height)
	item:setItemSize(self:GetSize().width,node:getCascadeBoundingBox().height)
	return item
end


function WidgetPlayerNode:BuildDataItemNode(data_list_data)
	local data_list_data = data_list_data or self:CallDelegate_(DELEGATE_METHODS.DataSource,{"DataInfoData"})
	local item = self:GetListView():newItem()
	if #data_list_data == 0 then return end
	local box_height = #data_list_data * 48 + 66
	local node = display.newNode():size(self:GetSize().width,box_height)
	local data_panel = UIKit:commonTitleBox(box_height):addTo(node):pos((self:GetSize().width - 540)/2,0) --width:540
	UIKit:ttfLabel({
		text = _("数据统计"),
		size = 24,
		color= 0xffedae
	}):align(display.CENTER_TOP,270,box_height - 12):addTo(data_panel)
	local x,y = 14,10
	for i,v in ipairs(data_list_data) do
		local image_name = string.format("back_ground_548x40_%d.png",i % 2 == 0 and 1 or 2)
		local bg = display.newScale9Sprite(image_name):align(display.LEFT_BOTTOM, x, y + (i - 1) * 48):addTo(data_panel):size(520,48)
		UIKit:ttfLabel({
			text = data_list_data[i][1],
			color= 0x615b44,
			size = 20
		}):align(display.LEFT_CENTER, 5, 24):addTo(bg)

		UIKit:ttfLabel({
			text = data_list_data[i][2],
			color= 0x403c2f,
			size = 20
		}):align(display.RIGHT_CENTER, 515, 24):addTo(bg)
	end
	item:addContent(node)
	item:setItemSize(self:GetSize().width,box_height)
	return item
end

function WidgetPlayerNode:GetDelegate()
	return self.delegate_
end
-- api
function WidgetPlayerNode:SetDelegate(delegate)
	self.delegate_ = delegate
end
--- events
function WidgetPlayerNode:CallDelegate_(methodName,args)
	if not self:GetDelegate() then return  end
	args = args or {}
	methodName = checknumber(methodName)
	methodName = DELEGATE_METHODS[methodName]
	if type(self:GetDelegate()["WidgetPlayerNode_" .. methodName]) == 'function' then
		return self:GetDelegate()["WidgetPlayerNode_" .. methodName](self:GetDelegate(),unpack(args))
	end
	assert(false,"你必须实现" .. methodName .. "方法在:" .. self:GetDelegate().__cname)
end

return WidgetPlayerNode