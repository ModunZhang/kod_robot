	--
-- Author: Danny He
-- Date: 2014-10-24 11:41:10
--
local GameAllianceApproval = UIKit:createUIClass("GameAllianceApproval")
local window = import("..utils.window")
local UIListView = import(".UIListView")
local UIScrollView = import(".UIScrollView")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")

function GameAllianceApproval:onEnter()
	GameAllianceApproval.super.onEnter(self)
	local layer = UIKit:shadowLayer():addTo(self)
	local bg = WidgetUIBackGround.new({height=754}):addTo(layer):pos(window.left+10,window.bottom+50)
	local title_bar = display.newSprite("title_blue_600x56.png")
		:addTo(bg)
		:align(display.LEFT_BOTTOM, 2, 754 - 20)
	UIKit:closeButton():align(display.BOTTOM_RIGHT,title_bar:getContentSize().width, 0)
		:onButtonClicked(function ()
	   		self:LeftButtonClicked()
	   	end)
	   	:addTo(title_bar)
	UIKit:ttfLabel({
		text = _("申请审批"),
		color = 0xffedae,
		size = 22,
	}):align(display.CENTER, 300, 26):addTo(title_bar)
	local list,list_node = UIKit:commonListView({
		viewRect = cc.rect(0, 0,568,687),
        direction = UIScrollView.DIRECTION_VERTICAL,
	})
	list_node:addTo(bg):pos(20,30)
	self.listView = list
	self:RefreshListView()
end

function GameAllianceApproval:RefreshListView()
	self.listView:removeAllItems()
	table.foreachi(Alliance_Manager:GetMyAlliance():JoinRequestEvents(),function(k,v)
		local newItem = self:GetListItem(v)
		self.listView:addItem(newItem)
	end)
	self.listView:reload()
end


function GameAllianceApproval:OnPlayerDetailButtonClicked(memberId)
    UIKit:newGameUI('GameUIAllianceMemberInfo',false,memberId,function()end):AddToCurrentScene(true)
end

function GameAllianceApproval:GetListItem(player)
	local item = self.listView:newItem()
	local bg = WidgetUIBackGround.new({width = 568,height = 152},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
	local icon_box = display.newSprite("alliance_item_flag_box_126X126.png"):align(display.LEFT_BOTTOM, 10,15):addTo(bg)
	UIKit:GetPlayerCommonIcon():addTo(icon_box):pos(icon_box:getContentSize().width/2,icon_box:getContentSize().height/2)
	WidgetPushTransparentButton.new(cc.rect(0,0,126,126))
		:align(display.LEFT_BOTTOM, 0, 0)
		:addTo(icon_box)
		:onButtonClicked(function()
			self:OnPlayerDetailButtonClicked(player.id)
		end)
	local line = display.newScale9Sprite("dividing_line.png")
		:align(display.LEFT_CENTER,icon_box:getPositionX()+icon_box:getContentSize().width + 5,icon_box:getPositionY() + icon_box:getContentSize().height/2)
		:addTo(bg)
		:size(416,2)
	--name
	UIKit:ttfLabel({
		text = player.name or " ",
		size = 22,
		color = 0x403c2f
	}):align(display.LEFT_BOTTOM,line:getPositionX(),line:getPositionY() + 20):addTo(bg)
	local power_icon = display.newSprite("dragon_strength_27x31.png")
        :align(display.LEFT_BOTTOM, line:getPositionX() + 260,line:getPositionY() + 20)
        :addTo(bg)
	UIKit:ttfLabel({
		text = string.formatnumberthousands(player.power),
		size = 22,
		color = 0x403c2f,
		align = cc.TEXT_ALIGNMENT_LEFT,
	}):align(display.LEFT_BOTTOM,power_icon:getPositionX()+power_icon:getContentSize().width + 2,power_icon:getPositionY()):addTo(bg)

    local rejectButton = WidgetPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"})
        :setButtonLabel(
            UIKit:commonButtonLable({
            	color = 0xfff3c7,
            	text  = _("拒绝")
            })
        )
        :align(display.LEFT_TOP,line:getPositionX(), line:getPositionY() - 5)
        :onButtonClicked(function(event)
            self:OnRefuseButtonClicked(player.id)
        end)
        :addTo(bg)
	 local argreeButton = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
            :setButtonLabel(
                UIKit:commonButtonLable({
                    text = _("同意"),
                    color = 0xfff3c7
                })
            )
            :align(display.LEFT_TOP,power_icon:getPositionX(),line:getPositionY() - 5)
            :onButtonClicked(function(event)
                self:OnAgreeButtonClicked(player.id)
            end)
            :addTo(bg)
	item:addContent(bg)
	item:setItemSize(568,152)
	return item
end

function GameAllianceApproval:OnRefuseButtonClicked(memberId)
	NetManager:getRemoveJoinAllianceReqeustsPromise({memberId}):done(function(result)
        self:RefreshListView()
    end)
end

function GameAllianceApproval:OnAgreeButtonClicked(memberId)
	NetManager:getApproveJoinAllianceRequestPromise(memberId):done(function(result)
		self:RefreshListView()
		end):fail(function(msg)
			local code = msg.errcode and msg.errcode[1].code or nil
			if code then
				if UIKit:getErrorCodeKey(code) == 'playerCancelTheJoinRequestToTheAlliance' then
					self:OnRefuseButtonClicked(memberId)
				end
			end
	end)
end

return GameAllianceApproval
