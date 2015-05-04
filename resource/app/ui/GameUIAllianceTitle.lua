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
	local title_bar = display.newSprite("title_blue_600x52.png")
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
        fixed_title_position = cc.p(110,15),
        cb = function (page)
        	self.title_ = self:GetTitleKeys(page)
          	self:RefreshListView(page)
        end,
        current_page = member_level,
        icon = images
    }):align(display.CENTER, bg:getContentSize().width/2, bg:getContentSize().height-60)
        :addTo(bg)
    self.widget_page = widget_page
    if Alliance_Manager:GetMyAlliance():GetSelf():CanEditAllianceMemeberTitle() then
    	local label = widget_page.current_page_label
    	display.newSprite("edit_alliance_title_icon_27x26.png")
    		:align(display.RIGHT_CENTER, label:getPositionX()-label:getContentSize().width-10, 28):addTo(widget_page)
    	WidgetPushTransparentButton.new(cc.rect(0,0,434,46))
    		:addTo(widget_page):align(display.LEFT_BOTTOM, 60, 10)
    		:onButtonClicked(function()
    			self:CreateEditTitleUI()
    		end)
    end
    local listBg = display.newSprite("alliance_title_list_572x436.png")
		:addTo(bg)
		:align(display.CENTER_TOP,304,widget_page:getPositionY() - widget_page:getCascadeBoundingBox().height)
	self.authority_list = UIListView.new {
    	viewRect = cc.rect(4, 12, 564,325),
        direction = UIScrollView.DIRECTION_VERTICAL,
    }:addTo(listBg)
    local button = WidgetPushButton.new(
        {normal = "yellow_btn_up_185x65.png",pressed = "yellow_btn_down_185x65.png"})
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
    local gem_icon = display.newSprite("gem_icon_62x61.png"):scale(0.4):align(display.LEFT_BOTTOM, 10, 0):addTo(gem_bg)
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

function GameUIAllianceTitle:OnBuyAllianceArchonButtonClicked()
    if config_intInit.buyArchonGem.value > User:GetGemResource():GetValue() then
        UIKit:showMessageDialog(nil, _("金龙币不足"), function()
        end)
    elseif Alliance_Manager:GetMyAlliance():GetSelf():IsArchon() then
        UIKit:showMessageDialog(nil, _("你已经是盟主"), function()
        end)
    else
        NetManager:getBuyAllianceArchon():done(function(response)
           UIKit:showMessageDialog(nil, _("竞选盟主成功"), function()
           end)
        end)
    end
end

function GameUIAllianceTitle:RefreshListView(index)
	if not self.authority_list then return end
	self.authority_list:removeAllItems()
	local data = self:GetListData(index)
	for i,v in ipairs(data) do
  			local item = self.authority_list:newItem()
    		local bg = display.newSprite(string.format("resource_item_bg%d.png",i%2))
    		UIKit:ttfLabel({
				text = v[1],
				size = 20,
				color = 0x797154,
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

function GameUIAllianceTitle:CreateEditTitleUI()
    local layer = UIKit:shadowLayer()
    local bg = WidgetUIBackGround.new({height=150}):addTo(layer):pos(window.left+20,window.cy-20)
    local title_bar = display.newSprite("title_blue_600x52.png")
        :addTo(bg)
        :align(display.LEFT_BOTTOM, 0,150-15)

    local closeButton = UIKit:closeButton()
        :addTo(title_bar)
        :align(display.BOTTOM_RIGHT,title_bar:getContentSize().width, 0)
        :onButtonClicked(function ()
            layer:removeFromParent(true)
        end)
    UIKit:ttfLabel({
        text = _("修改联盟职位名称"),
        size = 22,
        color = 0xffedae
    }):addTo(title_bar):align(display.LEFT_BOTTOM, 100, 10)

    UIKit:ttfLabel({
        text = _("职位名称"),
        size = 20,
        color = 0x797154
    }):addTo(bg):align(display.LEFT_TOP, 20,150-40)

    local editbox = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(422,40),
    })
    editbox:setFont(UIKit:getEditBoxFont(),18)
    editbox:setFontColor(cc.c3b(0,0,0))
    local display_title,__ = self:GetAllianceTitleAndLevelPng(self.title_)
    editbox:setPlaceHolder(display_title)
    editbox:setPlaceholderFontColor(UIKit:hex2c3b(0xccc49e))
    editbox:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    editbox:align(display.RIGHT_TOP,588,120):addTo(bg)
    WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
            :setButtonLabel(
                UIKit:commonButtonLable({
                    text = _("确定"),
                    color = 0xffedae
                })
            )
            :onButtonClicked(function(event)
                local newTitle = string.trim(editbox:getText())
                if string.len(newTitle) == 0 then
                    UIKit:showMessageDialog(_("陛下"),_("请输入联盟职位名称"))
                    return
                end
                NetManager:getEditAllianceTitleNamePromise(self.title_,newTitle):done(function()
 					self:RefreshTitle()
					layer:removeFromParent(true)
		 		end):fail(function()
		 			layer:removeFromParent(true)
		 		end)
            end)
            :addTo(bg):align(display.RIGHT_BOTTOM,editbox:getPositionX(), 20)
    layer:addTo(self)
end
return GameUIAllianceTitle
