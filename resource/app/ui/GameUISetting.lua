--
-- Author: Danny He
-- Date: 2015-02-10 09:54:53
--
local GameUISetting = UIKit:createUIClass("GameUISetting","GameUIWithCommonHeader")
local window = import("..utils.window")
local WidgetRankingList = import("..widget.WidgetRankingList")
local WidgetPushButton = import("..widget.WidgetPushButton")

function GameUISetting:ctor(city)
	 GameUISetting.super.ctor(self,city, _("更多"))
end

function GameUISetting:onEnter()
	GameUISetting.super.onEnter(self)
	self:BuildUI()
	app.timer:AddListener(self)
end

function GameUISetting:OnTimer(current_time)
	if self.timer_label then
		self.timer_label:setString(_("世界时间:") ..  os.date('!%Y-%m-%d %H:%M:%S', app.timer:GetServerTime()))
	end
end

function GameUISetting:BuildUI()
	local header_bg = UIKit:CreateBoxPanelWithBorder({height = 58}):align(display.TOP_CENTER, window.cx, window.top_bottom):addTo(self:GetView())
	self.timer_label = UIKit:ttfLabel({
		text = _("世界时间:") ..  os.date('!%Y-%m-%d %H:%M:%S', app.timer:GetServerTime()),
		size = 22,
		color= 0x28251d
	}):align(display.CENTER,278,29):addTo(header_bg)
	local buttons_info = {
		{text = _("账号绑定"),image = "setting_account_56x65.png"},
		{text = _("选择服务器"),image = "setting_server_55x62.png"},
		{text = _("语言"),image = "setting_language_71x70.png"},
		{text = _("游戏说明"),image = "setting_declare_48x67.png"},
		{text = _("个人排行榜"),image = "setting_rank_p_75x70.png"},
		{text = _("联盟排行榜"),image = "setting_rank_a_75x66.png"},
		{	
			text = _("音乐"),
			image = "setting_music_65x60.png",
			image2 = "setting_music_close_66x60.png",
			state = app:GetAudioManager():GetBackgroundMusicState() and 1 or 2,
		},
		{	
			text = _("音效"),
			image = "setting_sound_64x56.png",
			image2 = "setting_sound_close_64x56.png",
			state = app:GetAudioManager():GetEffectSoundState() and 1 or 2,
		},
		{text = _("推送通知"),image = "setting_notification_76x66.png"},
		{text = _("已屏蔽用户"),image = "setting_shield_58x70.png"},
		{text = _("我有建议"),image = "setting_user_voice_62x63.png"},
		{text = _("遇到问题"),image = "setting_help_64x65.png"},
	}
	local x,y = window.left + 50,window.top_bottom - 80
	for i,v in ipairs(buttons_info) do
		if (i - 1) % 4 == 0 and i ~= 1 then
			x = window.left + 50
			y = y - 42 - 112
		end
		local button = cc.ui.UIPushButton.new(
	        {normal = "setting_btn_n_112x112.png", pressed = "setting_btn_h_112x112.png"},
	        {scale9 = false}
    	)
    	button:setTag(i)
    	button:setButtonLabel(UIKit:ttfLabel({
	    		color = 0x403c2f,
	    		text = v.text,
	    		size = 18
    		}))
	    	:setButtonLabelOffset(0,-70)
	        :addTo(self:GetView())
	        :align(display.LEFT_TOP,x, y)
	        :onButtonClicked(function(event)
           		self:OnButtonClicked(button)
        	end)
	    if v.image then
	    	local normal_image = display.newSprite(v.image, 56, -56):addTo(button)
	    	button.normal_image = normal_image
	    	if v.image2 then
	    		local state_image = display.newSprite(v.image2, 56, -56):addTo(button)
	    		button.state_image = state_image
	    		normal_image:setVisible(v.state == 1) 
	    		state_image:setVisible(v.state == 2) 
	    	end
	    end
		x = x + 30 + 112
	end
end

function GameUISetting:OnButtonClicked(button)
	local tag = button:getTag()
	if tag == 1 then
		UIKit:newGameUI("GameUISettingAccount"):AddToCurrentScene(true)
	elseif tag == 2 then
		UIKit:newGameUI("GameUISettingServer"):AddToCurrentScene(true)
	elseif tag == 3 then
		UIKit:newGameUI("GameUISettingLanguage"):AddToCurrentScene(true)
	elseif tag == 4 then
		if CONFIG_IS_DEBUG then
			UIKit:newGameUI('GameUIShop', City):AddToCurrentScene(true)
		else
			UIKit:newGameUI("GameUITips"):AddToCurrentScene(true)
		end
	elseif tag == 5 then
		UIKit:newWidgetUI("WidgetRankingList", "player"):AddToCurrentScene(true)
	elseif tag == 6 then
		UIKit:newWidgetUI("WidgetRankingList","alliance"):AddToCurrentScene(true)
	elseif tag == 7 then
		local is_open = app:GetAudioManager():GetBackgroundMusicState()
		app:GetAudioManager():SwitchBackgroundMusicState(not is_open)
		is_open = app:GetAudioManager():GetBackgroundMusicState()
		button.normal_image:setVisible(is_open)
		button.state_image:setVisible(not is_open)
	elseif tag == 8 then
		local is_open = app:GetAudioManager():GetEffectSoundState()
		app:GetAudioManager():SwitchEffectSoundState(not is_open)
		is_open = app:GetAudioManager():GetEffectSoundState()
		button.normal_image:setVisible(is_open)
		button.state_image:setVisible(not is_open)
	elseif tag == 9 then
		UIKit:newGameUI("GameUISettingPush"):AddToCurrentScene(true)
	elseif tag == 10 then
		UIKit:newGameUI("GameUISettingShield"):AddToCurrentScene(true)
	elseif tag == 11 then
		if ext.userVoice then
			ext.userVoice("dannyhe.uservoice.com",280112,"example@batcat.com","DragonFall","DragonFall")
		end
	elseif tag == 12 then
       	UIKit:newGameUI("GameUISettingContactUs"):AddToCurrentScene(true)
	end
end

function GameUISetting:onCleanup()
	app.timer:RemoveListener(self)
	GameUISetting.super.onCleanup(self)
end

return GameUISetting