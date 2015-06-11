--
-- Author: Danny He
-- Date: 2014-10-13 10:35:06
--
local window = import('..utils.window')
local UIScrollView = import(".UIScrollView")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local GameUIAllianceBasicSetting = UIKit:createUIClass('GameUIAllianceBasicSetting')
local WidgetAllianceCreateOrEdit = import("..widget.WidgetAllianceCreateOrEdit")

function GameUIAllianceBasicSetting:OnMoveInStage()
	assert(not self.isCreateAction_)
	GameUIAllianceBasicSetting.super.OnMoveInStage(self)
	self:BuildModifyUI()
end

function GameUIAllianceBasicSetting:BuildModifyUI()
	local modify_height = window.height - 60
	local shadowLayer = UIKit:shadowLayer():addTo(self)
	local bg = WidgetUIBackGround.new({height=modify_height}):addTo(shadowLayer):pos(window.left+10,window.bottom)
	local titleBar = display.newSprite("title_blue_600x56.png"):align(display.LEFT_BOTTOM,3,modify_height-15):addTo(bg)
	local closeButton = UIKit:closeButton()
	   	:addTo(titleBar)
	   	:align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
	   	:onButtonClicked(function ()
	   		self:LeftButtonClicked()
	   	end)
	UIKit:ttfLabel({
		text = _("联盟设置"),
		size = 22,
		shadow = true,
		color = 0xffedae
	}):addTo(titleBar):align(display.CENTER,300,titleBar:getContentSize().height/2)

	local scrollView = UIScrollView.new({viewRect = cc.rect(0,10,bg:getContentSize().width,titleBar:getPositionY() - 10)})
        :addScrollNode(WidgetAllianceCreateOrEdit.new(true,function()
        	self:LeftButtonClicked()
        end):pos(35,0))
        :setDirection(UIScrollView.DIRECTION_VERTICAL)
        :addTo(bg)
	scrollView:fixResetPostion(3)
	self.createScrollView = scrollView
end

-----------------------------------------------------------------------

return GameUIAllianceBasicSetting