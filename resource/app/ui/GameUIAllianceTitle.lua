--
-- Author: Danny He
-- Date: 2014-10-23 20:46:22
--
local GameUIAllianceTitle = UIKit:createUIClass("GameUIAllianceTitle","UIAutoClose")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local UIListView = import(".UIListView")
local UIScrollView = import(".UIScrollView")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPages = import("..widget.WidgetPages")
local memberMeta = import("..entity.memberMeta")
local UILib = import(".UILib")
local Alliance_Manager = Alliance_Manager
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")
local config_intInit = GameDatas.AllianceInitData.intInit

function GameUIAllianceTitle:ctor(title)
	GameUIAllianceTitle.super.ctor(self)
	self.title_ = title
end

function GameUIAllianceTitle:onEnter()
    GameUIAllianceTitle.super.onEnter(self)
    self:BuildUI()
end


function GameUIAllianceTitle:GetAllianceTitleAndLevelPng(title)
	local alliance = Alliance_Manager:GetMyAlliance()
	return alliance:GetTitles()[title],UILib.alliance_title_icon[title]
end

function GameUIAllianceTitle:GetTitleKeys(index)
	local keys =  {"member","elite","supervisor","quartermaster","general","archon"}
	if index then return keys[index] end
	return keys
end

function GameUIAllianceTitle:GetAllTitlesAndImages()
	local keys =  self:GetTitleKeys()
	local titles,images = {},{}
	for _,v in ipairs(keys) do
		local display_title,levelImage = self:GetAllianceTitleAndLevelPng(v)
		table.insert(titles,display_title)
		table.insert(images, levelImage)
	end
	return titles,images
end

function GameUIAllianceTitle:BuildUI()
	local bg = WidgetUIBackGround.new({height=614}):pos(window.left+20,window.bottom+150)
    self:addTouchAbleChild(bg)
	local title_bar = display.newSprite("title_blue_600x56.png")
		:addTo(bg)
		:align(display.CENTER_BOTTOM, 304, 600)
	UIKit:closeButton():addTo(title_bar)
	   	:align(display.BOTTOM_RIGHT,title_bar:getContentSize().width, 0)
	   	:onButtonClicked(function ()
	   		self:LeftButtonClicked()
	   	end)
	self.title_label = UIKit:ttfLabel({
		text = _("联盟权限"),
		size = 24,
		color = 0xffedae,
	}):align(display.CENTER,title_bar:getContentSize().width/2, title_bar:getContentSize().height/2)
		:addTo(title_bar)
	local titles,images = self:GetAllTitlesAndImages()
	local member_level = memberMeta.Title2Level(self.title_)
	local widget_page = WidgetPages.new({
        page = #titles, -- 页数
        titles =  titles, -- 标题 type -> table
        fixed_title_position = cc.p(110,20),
        cb = function (page)
        	self.title_ = self:GetTitleKeys(page)
          	self:RefreshListView(page)
        end,
        current_page = member_level,
        icon = images
    }):align(display.CENTER, bg:getContentSize().width/2, bg:getContentSize().height-60)
        :addTo(bg)
    self.widget_page = widget_page
    local listBg = display.newScale9Sprite("background_568x120.png", 0,0,cc.size(572,346),cc.rect(15,10,538,100))
		:addTo(bg)
		:align(display.CENTER_TOP,304,widget_page:getPositionY() - widget_page:getCascadeBoundingBox().height)
	self.authority_list = UIListView.new {
    	viewRect = cc.rect(4, 12, 564,325),
        direction = UIScrollView.DIRECTION_VERTICAL,
    }:addTo(listBg)
    local button = WidgetPushButton.new(
        {normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png"})
    :addTo(bg):pos(304,listBg:getPositionY() - listBg:getContentSize().height - 40)
    :onButtonClicked(handler(self, self.OnBuyAllianceArchonButtonClicked))
    :setButtonLabel("normal",
    	UIKit:ttfLabel({
			text = _("竞选盟主"),
			size = 18,
			color = 0xfff3c7,
			shadow = true,
		})
    )
    :setButtonLabelOffset(0, 15)
    local gem_bg = display.newSprite("alliance_title_gem_bg_154x20.png"):addTo(button):align(display.TOP_CENTER,0,0)
    local gem_icon = display.newSprite("gem_icon_62x61.png"):scale(0.4):align(display.LEFT_BOTTOM, 10, -2):addTo(gem_bg)
    UIKit:ttfLabel({
			text = config_intInit.buyArchonGem.value,
			size = 20,
			color = 0xfff3c7,
	}):align(display.LEFT_BOTTOM, gem_icon:getPositionX()+gem_icon:getContentSize().width*0.4+20, -3):addTo(gem_bg)

	UIKit:ttfLabel({
			text = _("盟主离线超过7天可以使用竞选盟主和盟主职位对换"),
			size = 18,
			color = 0x7e0000,
	}):align(display.TOP_CENTER, 304, button:getPositionY() - 50):addTo(bg)
	self:RefreshListView(member_level)
end

function GameUIAllianceTitle:CheckArchonLastLoginTimeGraterThen7Days()
    local alliance = Alliance_Manager:GetMyAlliance()
    local alliance_archon =  alliance:GetAllianceArchon()
    if app.timer:GetServerTime() - alliance_archon.lastLogoutTime / 1000  > 7 * 24 * 60 *60 then
        return true
    else
        return false
    end
end

function GameUIAllianceTitle:OnBuyAllianceArchonButtonClicked()
    if config_intInit.buyArchonGem.value > User:GetGemValue() then
        UIKit:showMessageDialog(nil, _("金龙币不足"), function()
        end)
    elseif Alliance_Manager:GetMyAlliance():GetSelf():IsArchon() then
        UIKit:showMessageDialog(nil, _("你已经是盟主"), function()
        end)
    elseif not self:CheckArchonLastLoginTimeGraterThen7Days() then
         UIKit:showMessageDialog(nil, _("盟主连续离线7天才能购买盟主职位"), function()
        end)
    else
        NetManager:getBuyAllianceArchon():done(function(response)
           UIKit:showMessageDialog(nil, _("竞选盟主成功"), function()
           end)
           local ui_alliance = UIKit:GetUIInstance("GameUIAlliance")
           if ui_alliance and ui_alliance.RefreshMemberListIf then
                ui_alliance:RefreshMemberListIf()
           end
        end)
    end
end

function GameUIAllianceTitle:RefreshListView(index)
	if not self.authority_list then return end
	self.authority_list:removeAllItems()
	local data = self:GetListData(index)
	for i,v in ipairs(data) do
  			local item = self.authority_list:newItem()
    		local bg = display.newScale9Sprite(string.format("back_ground_548x40_%d.png",i%2 == 0 and 2 or 1)):size(547,46)
    		UIKit:ttfLabel({
				text = v[1],
				size = 20,
				color = 0x615b44,
			}):addTo(bg):align(display.LEFT_CENTER, 10, 23)
			local icon_image = v[2] and  "yes_40x40.png" or "no_40x40.png"
			display.newSprite(icon_image):align(display.RIGHT_CENTER,537,23):addTo(bg)
    		item:addContent(bg)
    		item:setItemSize(547, 46)
    		self.authority_list:addItem(item)
	end
    self.authority_list:reload()
end

function GameUIAllianceTitle:GetListData(index)
	local r = {}
	for i,data in ipairs(Localize.alliance_authority_list) do
  		for j,v in ipairs(data) do
  			local can_do = false
  			if index >= i then
  				can_do = true
  			end
  			table.insert(r, {v,can_do})
  		end
  	end
  	return r
end

function GameUIAllianceTitle:RefreshTitle()
	local alliance = Alliance_Manager:GetMyAlliance()
	local index =  memberMeta.Title2Level(self.title_)
	self.widget_page:ResetOneTitle(alliance:GetTitles()[self.title_],index)
end

return GameUIAllianceTitle
