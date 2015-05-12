--
-- Author: Danny He
-- Date: 2015-03-28 16:57:58
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUISettingAccount = class("GameUISettingAccount", WidgetPopDialog)
local WidgetPushButton = import("..widget.WidgetPushButton")


function GameUISettingAccount:ctor()
	GameUISettingAccount.super.ctor(self,762,_("账号绑定"),display.top-120)
end

function GameUISettingAccount:onEnter()
	GameUISettingAccount.super.onEnter(self)
	self:CheckGameCenter()
	
end

function GameUISettingAccount:CheckGameCenter()
	if ext.gamecenter.isAuthenticated() then
		local __,gcId = ext.gamecenter.getPlayerNameAndId() 
		NetManager:getGcBindStatusPromise(gcId):done(function(response)
			ext.gamecenter.gc_bind = response.msg.isBind
        	if not User:IsBindGameCenter() and not response.msg.isBind then
            	NetManager:getBindGcIdPromise(gcId):done(function()
            		app:EndCheckGameCenterIf()
            	end)
        	end
			self:CreateUI()
			self:RefreshUI()
		end)
	else
		self:CreateUI()
		self:RefreshUI()
	end
end

function GameUISettingAccount:CreateUI()
	self:CreateAccountPanel()
	self:CreateGameCenterPanel()
end

function GameUISettingAccount:CreateGameCenterPanel()
	self.gamecenter_panel = UIKit:CreateBoxPanel9({width = 552,height = 272})
		:align(display.TOP_CENTER, 304, self.account_panel:getPositionY() - 212)
		:addTo(self:GetBody())
	local account_header = display.newScale9Sprite("setting_account_546x38.png",0,0,cc.size(546,82))
		:align(display.CENTER_TOP, 276, 270)
		:addTo(self.gamecenter_panel)
	self.gamecenter_login_state_label = UIKit:ttfLabel({
		text = "当前GameCenter:",
		size = 20,
		color= 0xffedae
	}):align(display.TOP_CENTER, 273, 75):addTo(account_header)

	self.gamecenter_bind_state_label = UIKit:ttfLabel({
		text = "当前状态:",
		size = 20,
		color= 0xffedae
	}):align(display.BOTTOM_CENTER, 273, 8):addTo(account_header)
	self.gamecenter_tips_label = UIKit:ttfLabel({
		text = "同时可以在其他IOS设备登陆此账号",
		size = 20,
		color= 0x7e0000,
		dimensions = cc.size(525, 85)
	}):align(display.TOP_CENTER, 276, 180):addTo(self.gamecenter_panel)
	self.gamecenter_force_change_button = WidgetPushButton.new({
			normal = "setting_account_red_btn_n_186x64.png",
			pressed="setting_account_red_btn_l_186x64.png"
		})
		:align(display.BOTTOM_CENTER, 276, 10)
		:addTo(self.gamecenter_panel)
		:setButtonLabel("normal", UIKit:commonButtonLable({
			text = _("切换账号")
		}))
		:onButtonClicked(function()
			self:ChangeAccountForceButtonClicked()
		end)
	self.gamecenter_change_account_button = WidgetPushButton.new({
			normal = "yellow_btn_up_185x65.png",
			pressed="yellow_btn_down_185x65.png"
		})
		:align(display.BOTTOM_CENTER, 276, 10)
		:addTo(self.gamecenter_panel)
		:setButtonLabel("normal", UIKit:commonButtonLable({
			text = _("切换账号")
		}))
		:onButtonClicked(function()
			self:CreateOrChangeAccountButtonClicked()
		end)
	self.gamecenter_login_button = WidgetPushButton.new({
			normal = "yellow_btn_up_185x65.png",
			pressed="yellow_btn_down_185x65.png"
		})
		:align(display.BOTTOM_CENTER, 276, 10)
		:addTo(self.gamecenter_panel)
		:setButtonLabel("normal", UIKit:commonButtonLable({
			text = _("开始绑定")
		}))
		:onButtonClicked(function()
			self:GameCenterButtonClicked()
		end)
end
function GameUISettingAccount:CreateAccountPanel()
	self.account_panel = UIKit:CreateBoxPanel9({width = 552,height = 202})
		:align(display.TOP_CENTER, 304, 732)
		:addTo(self:GetBody())
	local account_header = display.newSprite("setting_account_546x38.png")
		:align(display.CENTER_TOP, 276, 200)
		:addTo(self.account_panel)
	self.account_state_label = UIKit:ttfLabel({
		text = "当前账号状态:",
		size = 20,
		color= 0xffedae
	}):align(display.CENTER, 273, 19):addTo(account_header)
	self.account_warn_label =  UIKit:ttfLabel({
		text = "",
		size = 20,
		color= 0x7e0000
	}):align(display.TOP_CENTER, 276, 156):addTo(self.account_panel)
	self.account_tips_label = UIKit:ttfLabel({
		text = "请在系统设置中，",
		size = 18,
		color= 0x403c2f,
		dimensions = cc.size(500, 102)
	}):align(display.BOTTOM_CENTER, 276, 12):addTo(self.account_panel)
	self.account_panel_origin_postion = {
		account_warn_label = cc.p(276, 156),
		account_tips_label = cc.p(276, 12)
	}
end

function GameUISettingAccount:RefreshUI()
	if User:IsBindGameCenter() then
		self.account_state_label:setString(_("当前账号状态:已绑定"))
		-- self.account_warn_label:hide()
		self.account_warn_label:setString(_("你的账号已经和GameCenter绑定"))
		local tips = _("当前账号已经和一个GameCenter账号之间绑定。你可以在设置中切换你的GameCenter账号来创建新的账号，也可以在其他ios设备上用当前GameCenter账号登录，在其他ios设备上进行游戏")
		self.account_tips_label:setString(tips)
		if ext.gamecenter.isAuthenticated() then 
			self.gamecenter_login_state_label:setString(_("当前GameCenter:已登录"))
			if ext.gamecenter.gc_bind == true then
				self.gamecenter_bind_state_label:setString(_("当前状态:已绑定"))
				local __,gcId = ext.gamecenter.getPlayerNameAndId()
				if gcId == User:GcId() then
					self.gamecenter_tips_label:setString(_("当前账号已经和当前GameCenter账号绑定，请保管好你的GameCenter账号"))
					self.gamecenter_force_change_button:hide()
					self.gamecenter_change_account_button:hide()
					self.gamecenter_login_button:hide()
				else
					self.gamecenter_tips_label:setString(_("当前GameCenter下存在其他游戏账号，点击切换按钮，会立即登录另一个GameCenter游戏账号"))
					self.gamecenter_force_change_button:hide()
					self.gamecenter_change_account_button:setButtonLabelString("normal",_("切换账号"))
					self.gamecenter_change_account_button:show()
					self.gamecenter_login_button:hide()
				end
			else -- 创建新账号
				self.gamecenter_bind_state_label:setString(_("当前状态:未绑定"))
				self.gamecenter_tips_label:setString(_("当前GameCenter下没有绑定的账号，你可以在此创建一个全新的游戏账号。点击下方的按钮后，会登出当前账号，使用新的GameCenter账号进行游戏"))
				self.gamecenter_force_change_button:hide()

				self.gamecenter_change_account_button:setButtonLabelString("normal",_("创建新账号"))
				self.gamecenter_change_account_button:show()
				self.gamecenter_login_button:hide()
			end
		else
			self.gamecenter_login_state_label:setString(_("当前GameCenter:未登录"))
			self.gamecenter_bind_state_label:setString(_("当前状态:未知"))
			self.gamecenter_tips_label:setString(_("请在ios设置中登录你的GameCenter账号，或点击下面的按钮进行绑定"))
			--color change TODO:
			self.gamecenter_force_change_button:hide()
			--show bind button
		end
	else -- 当前账号未绑定gc
		self.account_state_label:setString(_("当前账号状态:未绑定"))
		self.account_warn_label:setString(_("你的账号尚未进行绑定，存在丢失风险"))
		self.account_tips_label:setString(_("请在系统设置中，登陆GameCenter 会自动绑定游戏账号。绑定后的游戏账号会更加安全，同时可以在其他IOS设备登陆此账号"))
		if ext.gamecenter.isAuthenticated() then
			self.gamecenter_login_state_label:setString(_("当前GameCenter:已登录"))
			if ext.gamecenter.gc_bind == true then -- 当前登录的gc已绑定
				self.gamecenter_bind_state_label:setString(_("当前状态:已绑定"))
				self.gamecenter_tips_label:setString(_("注意:如果当前账号状态是未绑定，切换Game Center的其他账号会导致当前账号的丢失，并无法找回，请慎重操作。"))
				self.gamecenter_force_change_button:show()
				self.gamecenter_change_account_button:hide()
				self.gamecenter_login_button:hide()

			else
				--bug ?
				self.gamecenter_bind_state_label:setString(_("当前状态:未绑定"))
				self.gamecenter_force_change_button:hide()
				self.gamecenter_change_account_button:hide()
				self.gamecenter_login_button:hide()
			end
		else
			self.gamecenter_login_state_label:setString(_("当前GameCenter:未登录"))
			self.gamecenter_bind_state_label:setString(_("当前状态:未知"))
			self.gamecenter_tips_label:setString(_("请在ios设置中登录你的GameCenter账号，或点击下面的按钮进行绑定"))
			--color change TODO:
			self.gamecenter_force_change_button:hide()
			self.gamecenter_change_account_button:hide()
			self.gamecenter_login_button:show()
		end
	end
end

function GameUISettingAccount:ChangeAccountForceButtonClicked()
	local __,gcId = ext.gamecenter.getPlayerNameAndId() 
	NetManager:getForceSwitchGcIdPromise(gcId)
end

function GameUISettingAccount:CreateOrChangeAccountButtonClicked()
	local __,gcId = ext.gamecenter.getPlayerNameAndId() 
	NetManager:getSwitchGcIdPromise(gcId)
end

function GameUISettingAccount:GameCenterButtonClicked()
	ext.gamecenter.authenticate(true)
end

return GameUISettingAccount