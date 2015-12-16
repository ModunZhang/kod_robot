--
-- Author: Danny He
-- Date: 2015-02-10 11:27:19
--
local GameUISettingLanguage = UIKit:createUIClass("GameUISettingLanguage","UIAutoClose")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")
local Localize = import("..utils.Localize")

function GameUISettingLanguage:onEnter()
	GameUISettingLanguage.super.onEnter(self)
	self:BuildUI()
end

function GameUISettingLanguage:BuildUI()
	local bg = WidgetUIBackGround.new({height=762})
	self:addTouchAbleChild(bg)
	bg:pos(((display.width - bg:getContentSize().width)/2),window.bottom_top)
	local titleBar = display.newSprite("title_blue_600x56.png"):align(display.LEFT_BOTTOM,3,747):addTo(bg)
	local closeButton = cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"}, {scale9 = false})
	   	:addTo(titleBar)
	   	:align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
	   	:onButtonClicked(function ()
	   		self:LeftButtonClicked()
	   	end)
	UIKit:ttfLabel({
		text = _("选择语言"),
		size = 22,
		shadow = true,
		color = 0xffedae
	}):addTo(titleBar):align(display.CENTER,300,28)
	local code = app:GetGameLanguage()
	print(code,"code------>")
	local languages = {
		{image = 'flag_zh_Hant_83x83.png',code = 'tw'},
		{image = 'flag_zh_83x83.png',code = 'cn'},
		-- {image = 'flag_en_83x83.png',code = 'en'},
	}
	local x,y = 20,732
	for i,v in ipairs(languages) do
		local item = self:GetItem(v.image,v.code,code == v.code)
		item:addTo(bg):align(display.LEFT_TOP, x, y)
		x = x + 144
		if i%4 == 0 then
			x = 20 
			y = y - 168 - 10
		end
	end
end

function GameUISettingLanguage:GetItem(iamge,language_code,selected)
	local sp = display.newSprite("flag_bg_130x168.png")
	display.newSprite(iamge):align(display.TOP_CENTER,65,150):addTo(sp)
	local check_bg = display.newSprite("activity_check_bg_55x51.png"):align(display.BOTTOM_CENTER, 65,8):addTo(sp)
	local check_body = display.newSprite("activity_check_body_55x51.png"):addTo(check_bg):pos(27,25)
	check_body:setVisible(selected)
	WidgetPushTransparentButton.new(cc.rect(0,0,130,168)):addTo(sp):align(display.LEFT_BOTTOM, 0, 0):onButtonClicked(function()
		local code = app:GetGameLanguage()
		if code ~= language_code then
			UIKit:showMessageDialog(_("提示"),string.format(_("修改游戏语言为%s?\n确认后游戏将重新启动"),Localize.game_language[language_code]),function()
				self:SendCodeToServer(language_code)
			end,function()end,false)
		end
	end)
	return sp
end

function GameUISettingLanguage:SendCodeToServer(code)
	NetManager:getSetPlayerLanguagePromise(code):done(function(response)
		app:SetGameLanguage(code)
	end)
end

return GameUISettingLanguage
