--
-- Author: Danny He
-- Date: 2014-10-19 20:00:50
--
local Enum = import("..utils.Enum")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local GameUIAllianceNoticeOrDescEdit = UIKit:createUIClass("GameUIAllianceNoticeOrDescEdit","UIAutoClose")
GameUIAllianceNoticeOrDescEdit.EDIT_TYPE = Enum("ALLIANCE_NOTICE","ALLIANCE_DESC")

local content_height = 348

function GameUIAllianceNoticeOrDescEdit:ctor(edit_type)
	GameUIAllianceNoticeOrDescEdit.super.ctor(self)
	self.isNotice_ = edit_type == self.EDIT_TYPE.ALLIANCE_NOTICE
end

function GameUIAllianceNoticeOrDescEdit:OnMoveInStage()
	--base UI
	local bg_node = WidgetUIBackGround.new({height=content_height}):pos(window.left+20,window.bottom + 400)
	self:addTouchAbleChild(bg_node)
	local titleBar = display.newSprite("title_blue_600x56.png")
		:align(display.LEFT_BOTTOM, 2,content_height - 15)
		:addTo(bg_node)
	local title = self.isNotice_ and _("联盟公告") or _("联盟描述")
	local titleLabel = UIKit:ttfLabel({
		text = title,
		size = 22,
		color = 0xffedae
	}):align(display.CENTER,300,26):addTo(titleBar)
	

	local textView = ccui.UITextView:create(cc.size(555,238),display.newScale9Sprite("background_88x42.png"))
    textView:addTo(bg_node):align(display.CENTER_TOP,bg_node:getContentSize().width/2, titleBar:getPositionY() - 10)
    textView:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)    
    textView:setFont(UIKit:getEditBoxFont(), 24)
    textView:setPlaceHolder(_("最多输入600个字符"))
    textView:setMaxLength(600)
    textView:setFontColor(UIKit:hex2c3b(0x000000))

    local text = ""
    if self.isNotice_ then
    	text = Alliance_Manager:GetMyAlliance():Notice()
    else
    	text = Alliance_Manager:GetMyAlliance():Describe()
    end
    if text == json.null or string.len(text) == 0 then
    	text = ""
    end
	textView:setText(text)
    self.textView = textView


	local cancelButton = WidgetPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"})
        :setButtonLabel(
        	UIKit:ttfLabel({
				text = _("取消"),
				size = 22,
				shadow = true,
				color = 0xffedae
			})
		)
		:onButtonClicked(function()
			self:LeftButtonClicked()
		end)
		:addTo(bg_node)
		:align(display.LEFT_BOTTOM,25, 20)
	local okButton = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
        :setButtonLabel(
        	UIKit:ttfLabel({
				text = _("确定"),
				size = 22,
				shadow = true,
				color = 0xffedae
			})
		)
		:onButtonClicked(handler(self, self.onOkButtonClicked))
		:addTo(bg_node)
		:align(display.RIGHT_BOTTOM,bg_node:getCascadeBoundingBox().width - 100, 20)
end

function GameUIAllianceNoticeOrDescEdit:onOkButtonClicked()
	local content = self.textView:getText()
	if self.isNotice_ then
		NetManager:getEditAllianceNoticePromise(content)
        	:done(function()
        		self:LeftButtonClicked()
        		GameGlobalUI:showTips(_("提示"),_("修改联盟公告成功"))
        	end)
	else
		NetManager:getEditAllianceDescriptionPromise(content)
			:done(function()
        		self:LeftButtonClicked()
        		GameGlobalUI:showTips(_("提示"),_("修改联盟描述成功"))
        	end)
	end
end

return GameUIAllianceNoticeOrDescEdit