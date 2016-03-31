--
-- Author: Danny He
-- Date: 2015-03-28 16:57:58
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local Localize = import("..utils.Localize")
local GameUISettingAccount = class("GameUISettingAccount", WidgetPopDialog)


function GameUISettingAccount:ctor()
    GameUISettingAccount.super.ctor(self,722,_("账号绑定"),display.top-120)
end

function GameUISettingAccount:onEnter()
    GameUISettingAccount.super.onEnter(self)
    self:UpdateGcName()
    self:CheckGameCenter()
end
function GameUISettingAccount:onExit()
    GameUISettingAccount.super.onExit(self)
end
function GameUISettingAccount:IsBinded()
    return User:IsBindGameCenter() or User:IsBindFacebook() or User:IsBindGoogle()
end
function GameUISettingAccount:CheckGameCenter()
    self:CreateUI()
    self:RefreshUI()
end
function GameUISettingAccount:UpdateGcName()
    if ext.gamecenter.isAuthenticated() then
        local gcName,gcId = ext.gamecenter.getPlayerNameAndId()
        if User.gc and User.gc.gcId == gcId and gcName ~= User.gc.gcName then
            NetManager:getUpdateGcNamePromise(gcName)
        end
    end
    if ext.facebook and ext.facebook.isAuthenticated() then
        local gcName,gcId = ext.facebook.getPlayerNameAndId()
        if User.gc and User.gc.gcId == gcId and gcName ~= User.gc.gcName then
            NetManager:getUpdateGcNamePromise(gcName)
        end
    end
end
function GameUISettingAccount:CreateUI()
    self:CreateAccountPanel()
    if self:IsBinded() then
        if User:IsBindGameCenter() then
            if device.platform == 'ios' then
                self:CreateGameCenterPanel()
            end
        end
        if User:IsBindFacebook() then
            self:CreateFacebookPanel()
        end
        if User:IsBindGoogle() then
            if device.platform == 'android' then
                self:CreateGooglePanel()
            end
        end
    else
        if device.platform == 'ios' then
            self:CreateGameCenterPanel()
        end
        self:CreateFacebookPanel()
        if device.platform == 'android' then
            self:CreateGooglePanel()
        end
    end

    -- 切换账号按钮
    cc.ui.UIPushButton.new({
        normal = "red_btn_up_186x66.png",
        pressed="red_btn_down_186x66.png"
    })
        :align(display.BOTTOM_CENTER, self:GetBody():getContentSize().width/2,  20)
        :addTo(self:GetBody())
        :setButtonLabel("normal", UIKit:commonButtonLable({
            text = _("切换账号")
        })):onButtonClicked(function()
        self:ExchangeBindAccount()
        end)
end

function GameUISettingAccount:CreateGameCenterPanel()
    local bg_width,bg_height = 568,122
    self.gamecenter_panel = WidgetUIBackGround.new({width = bg_width,height=bg_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
        :align(display.TOP_CENTER, 304, self.account_warn_label:getPositionY() - 50)
        :addTo(self:GetBody())
    display.newSprite("icon_gameCenter_104x104.png"):align(display.LEFT_CENTER, 12, bg_height/2)
        :addTo(self.gamecenter_panel)
    self.gamecenter_bind_state_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color= 0x403c2f,
        dimensions = cc.size(260,0)
    }):align(display.LEFT_CENTER, 130, bg_height/2):addTo(self.gamecenter_panel)
    self.gamecenter_bind_button = cc.ui.UIPushButton.new({
        normal = "yellow_btn_up_148x58.png",
        pressed="yellow_btn_down_148x58.png"
    })
        :align(display.RIGHT_CENTER, bg_width - 10,  bg_height/2)
        :addTo(self.gamecenter_panel)
        :setButtonLabel("normal", UIKit:commonButtonLable({
            text = _("绑定")
        })):onButtonClicked(function()
        if ext.gamecenter.isAuthenticated() then -- 是否登录了GameCenter
            local gcName,gcId = ext.gamecenter.getPlayerNameAndId()
            UIKit:showMessageDialog(_("提示"),string.format(_("是否确认将账号绑定到GameCenter %s"),gcName),function()
                NetManager:getBindGcPromise("gamecenter",gcId,gcName):done(function (response)
                    LuaUtils:outputTable("绑定到GameCenter ",response)
                    User.gc = response.msg.playerData[1][2]
                    GameGlobalUI:showTips(_("提示"),_("绑定账号成功"))
                    self:LeftButtonClicked()
                end)
            end,function()end)
        else
            UIKit:showMessageDialog(_("提示"),_("你尚未登录GameCenter，请先登录你的GameCenter账号，再重试"),function()
                ext.gamecenter.authenticate(true)
            end,function()end)
        end
        end)
end
function GameUISettingAccount:CreateFacebookPanel()
    local bg_width,bg_height = 568,122
    self.facebook_panel = WidgetUIBackGround.new({width = bg_width,height=bg_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
        :align(display.TOP_CENTER, 304, self.gamecenter_panel and (self.gamecenter_panel:getPositionY() - 130) or (self.account_warn_label:getPositionY() - 50))
        :addTo(self:GetBody())
    display.newSprite("icon_facebook_104x104.png"):align(display.LEFT_CENTER, 12, bg_height/2)
        :addTo(self.facebook_panel)
    self.facebook_bind_state_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color= 0x403c2f,
        dimensions = cc.size(260,0)
    }):align(display.LEFT_CENTER, 130, bg_height/2):addTo(self.facebook_panel)
    self.facebook_bind_button = cc.ui.UIPushButton.new({
        normal = "yellow_btn_up_148x58.png",
        pressed="yellow_btn_down_148x58.png"
    })
        :align(display.RIGHT_CENTER, bg_width - 10,  bg_height/2)
        :addTo(self.facebook_panel)
        :setButtonLabel("normal", UIKit:commonButtonLable({
            text = _("绑定")
        })):onButtonClicked(function()
        if ext.facebook.isAuthenticated() then -- 是否登录了Facebook
            local gcName,gcId = ext.facebook.getPlayerNameAndId()
            UIKit:showMessageDialog(_("提示"),string.format(_("是否确认将账号绑定到Facebook %s"),gcName),function()
                NetManager:getBindGcPromise("facebook",gcId,gcName):done(function (response)
                    User.gc = response.msg.playerData[1][2]
                    GameGlobalUI:showTips(_("提示"),_("绑定账号成功"))
                    self:LeftButtonClicked()
                end)
            end,function()end)
        else
            ext.facebook.login(function ( data )
                if data.event == "login_success" then
                    local userid,username = data.userid,data.username
                    NetManager:getBindGcPromise("facebook",userid,username):done(function (response)
                        User.gc = response.msg.playerData[1][2]
                        GameGlobalUI:showTips(_("提示"),_("绑定账号成功"))
                        self:LeftButtonClicked()
                    end)
                else
                    UIKit:showMessageDialog(_("提示"),_("链接失败"))
                end
            end)
        end
        end)
end
function GameUISettingAccount:CreateGooglePanel()
    local bg_width,bg_height = 568,122
    self.google_panel = WidgetUIBackGround.new({width = bg_width,height=bg_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
        :align(display.TOP_CENTER, 304, self.facebook_panel and (self.facebook_panel:getPositionY() - 130) or (self.account_warn_label:getPositionY() - 50))
        :addTo(self:GetBody())
    display.newSprite("icon_google_104x104.png"):align(display.LEFT_CENTER, 12, bg_height/2)
        :addTo(self.google_panel)
    self.google_bind_state_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color= 0x403c2f,
        dimensions = cc.size(260,0)
    }):align(display.LEFT_CENTER, 130, bg_height/2):addTo(self.google_panel)
    self.google_bind_button = cc.ui.UIPushButton.new({
        normal = "yellow_btn_up_148x58.png",
        pressed="yellow_btn_down_148x58.png"
    })
        :align(display.RIGHT_CENTER, bg_width - 10,  bg_height/2)
        :addTo(self.google_panel)
        :setButtonLabel("normal", UIKit:commonButtonLable({
            text = _("绑定")
        })):onButtonClicked(function()
        if ext.google.isAuthenticated() then -- 是否登录了Facebook
            local gcName,gcId = ext.google.getPlayerNameAndId()
            UIKit:showMessageDialog(_("提示"),string.format(_("是否确认将账号绑定到Google %s"),gcName),function()
                NetManager:getBindGcPromise("google",gcId,gcName):done(function (response)
                    User.gc = response.msg.playerData[1][2]
                    GameGlobalUI:showTips(_("提示"),_("绑定账号成功"))
                    self:LeftButtonClicked()
                end)
            end,function()end)
        else
            ext.google.login(function ( data )
                if data.event == "login_success" then
                    local userid,username = data.userid,data.username
                    NetManager:getBindGcPromise("google",userid,username):done(function (response)
                        User.gc = response.msg.playerData[1][2]
                        GameGlobalUI:showTips(_("提示"),_("绑定账号成功"))
                        self:LeftButtonClicked()
                    end)
                else
                    UIKit:showMessageDialog(_("提示"),_("链接失败"))
                end
            end)
        end
        end)
end
function GameUISettingAccount:CreateAccountPanel()
    local bg_width = 568
    local bg_height = 148
    self.account_panel = WidgetUIBackGround.new({width = bg_width,height=bg_height},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
        :align(display.TOP_CENTER, 304, 680)
        :addTo(self:GetBody())
    local bg = display.newScale9Sprite("back_ground_548x40_1.png"):size(548,42):align(display.TOP_CENTER, bg_width/2, bg_height - 10):addTo(self.account_panel)
    UIKit:ttfLabel({
        text = _("当前账号"),
        size = 20,
        color = 0x615b44,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
    }):addTo(bg):align(display.LEFT_CENTER,14,20)
    UIKit:ttfLabel({
        text = User.basicInfo.name.."(Lv"..User:GetLevel()..")",
        size = 20,
        align = cc.ui.UILabel.TEXT_ALIGN_RIGHT,
        color = 0x403c2f,
    }):addTo(bg):align(display.RIGHT_CENTER, 548 - 14, 20)

    local bg = display.newScale9Sprite("back_ground_548x40_2.png"):size(548,42):align(display.TOP_CENTER, bg_width/2, bg_height - 52):addTo(self.account_panel)
    UIKit:ttfLabel({
        text = _("状态"),
        size = 20,
        color = 0x615b44,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
    }):addTo(bg):align(display.LEFT_CENTER,14,20)
    self.account_state_label = UIKit:ttfLabel({
        size = 20,
        align = cc.ui.UILabel.TEXT_ALIGN_RIGHT,
        color = 0x403c2f,
    }):addTo(bg):align(display.RIGHT_CENTER, 548 - 14, 20)

    local bg = display.newScale9Sprite("back_ground_548x40_1.png"):size(548,42):align(display.TOP_CENTER, bg_width/2, bg_height - 94):addTo(self.account_panel)
    UIKit:ttfLabel({
        text = _("所在服务器"),
        size = 20,
        color = 0x615b44,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
    }):addTo(bg):align(display.LEFT_CENTER,14,20)

    UIKit:ttfLabel({
        text = string.format(_("World %s"),string.sub(User.serverId,-1,-1)),
        size = 20,
        align = cc.ui.UILabel.TEXT_ALIGN_RIGHT,
        color = 0x403c2f,
    }):addTo(bg):align(display.RIGHT_CENTER, 548 - 14, 20)

    self.account_warn_label =  UIKit:ttfLabel({
        text = "",
        size = 20,
        color= 0x7e0000,
        dimensions = cc.size(500, 0)
    }):align(display.CENTER, 276,  self.account_panel:getPositionY() -  self.account_panel:getContentSize().height - 50):addTo(self:GetBody())
end

function GameUISettingAccount:RefreshUI()
    if self:IsBinded() then
        self.account_state_label:setString(_("已绑定"))
        if User:IsBindGameCenter() then
            self.account_warn_label:setString(_("你的账号已经和GameCenter绑定"))
            self.account_warn_label:setColor(UIKit:hex2c3b(0x008b0a))
            if self.gamecenter_bind_state_label then
                self.gamecenter_bind_state_label:setString(string.format(_("%s(已绑定)"),User.gc.gcName))
                self.gamecenter_bind_button:hide()
            end
        end

        if User:IsBindFacebook() then
            self.account_warn_label:setString(_("你的账号已经和Facebook绑定"))
            self.account_warn_label:setColor(UIKit:hex2c3b(0x008b0a))
            self.facebook_bind_state_label:setString(string.format(_("%s(已绑定)"),User.gc.gcName))
            self.facebook_bind_button:hide()
        end
        if User:IsBindGoogle() then
            self.account_warn_label:setString(_("你的账号已经和Google绑定"))
            self.account_warn_label:setColor(UIKit:hex2c3b(0x008b0a))
            self.google_bind_state_label:setString(string.format(_("%s(已绑定)"),User.gc.gcName))
            self.google_bind_button:hide()
        end
    else
        if self.gamecenter_bind_state_label then
            self.gamecenter_bind_state_label:setString(_("与当前的Game Center账号进行绑定"))
            self.gamecenter_bind_button:show()
        end
        self.facebook_bind_state_label:setString(_("使用Facebook绑定账号"))
        self.facebook_bind_button:show()
        if self.google_bind_state_label then
            self.google_bind_state_label:setString(_("与当前的Google账号进行绑定"))
            self.google_bind_button:show()
        end
        self.account_state_label:setString(_("未绑定"))
        self.account_warn_label:setString(_("你的账号尚未进行绑定，存在丢失风险。绑定账号后你可以在不同设备上登录游戏。"))
        self.account_warn_label:setColor(UIKit:hex2c3b(0x7e0000))
    end
end
function GameUISettingAccount:ExchangeBindAccount()
    local dialog = WidgetPopDialog.new(412,_("账号"),display.top-120):addTo(self)
    local body = dialog:GetBody()
    local b_size = body:getContentSize()
    local bg_width,bg_height = 568,122
    local checkbox_image = {
        off = "checkbox_unselected.png",
        on = "checkbox_selectd.png",
    }
    local select_gamecenter
    local gamecenter_panel
    if device.platform == 'ios' then
        gamecenter_panel = WidgetUIBackGround.new({width = bg_width,height=bg_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
            :align(display.TOP_CENTER, 304, b_size.height - 30)
            :addTo(body)
        display.newSprite("icon_gameCenter_104x104.png"):align(display.LEFT_CENTER, 12, bg_height/2)
            :addTo(gamecenter_panel)
        local gamecenter_bind_state_label = UIKit:ttfLabel({
            text = _("切换当前GameCenter账号，请确认你的GameCenter已登录"),
            size = 20,
            color= 0x403c2f,
            dimensions = cc.size(260,0)
        }):align(display.LEFT_CENTER, 130, bg_height/2):addTo(gamecenter_panel)

        select_gamecenter = cc.ui.UICheckBoxButton.new(checkbox_image)
            :align(display.CENTER, bg_width - 40, bg_height/2):addTo(gamecenter_panel)
    end
    local select_google
    local google_panel
    if device.platform == 'android' then
        google_panel = WidgetUIBackGround.new({width = bg_width,height=bg_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
            :align(display.TOP_CENTER, 304, b_size.height - 30)
            :addTo(body)
        display.newSprite("icon_google_104x104.png"):align(display.LEFT_CENTER, 12, bg_height/2)
            :addTo(google_panel)
        local google_bind_state_label = UIKit:ttfLabel({
            text = _("使用你的Google账号登录"),
            size = 20,
            color= 0x403c2f,
            dimensions = cc.size(260,0)
        }):align(display.LEFT_CENTER, 130, bg_height/2):addTo(google_panel)

        select_google = cc.ui.UICheckBoxButton.new(checkbox_image)
            :align(display.CENTER, bg_width - 40, bg_height/2):addTo(google_panel)
    end
    local frist_panel = google_panel or gamecenter_panel
    local facebook_panel = WidgetUIBackGround.new({width = bg_width,height=bg_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
        :align(display.TOP_CENTER, 304, frist_panel and (frist_panel:getPositionY() - 130) or b_size.height - 30)
        :addTo(body)
    display.newSprite("icon_facebook_104x104.png"):align(display.LEFT_CENTER, 12, bg_height/2)
        :addTo(facebook_panel)
    local facebook_bind_state_label = UIKit:ttfLabel({
        text = _("使用你的Facebook账号登录"),
        size = 20,
        color= 0x403c2f,
        dimensions = cc.size(260,0)
    }):align(display.LEFT_CENTER, 130, bg_height/2):addTo(facebook_panel)

    local select_facebook = cc.ui.UICheckBoxButton.new(checkbox_image)
        :align(display.CENTER, bg_width - 40, bg_height/2):addTo(facebook_panel)

    local frist_select_box = select_gamecenter or select_google

    if frist_select_box then
        frist_select_box:setButtonSelected(true)
        frist_select_box:onButtonStateChanged(function(event)
            local isOn = event.state == "on"
            if select_facebook:isButtonSelected() and isOn then
                select_facebook:setButtonSelected(not isOn)
            end
        end)
    else
        select_facebook:setButtonSelected(true)
    end
    select_facebook:onButtonStateChanged(function(event)
        local isOn = event.state == "on"
        if frist_select_box and frist_select_box:isButtonSelected() and isOn then
            frist_select_box:setButtonSelected(not isOn)
        end
    end)

    -- 切换账号按钮
    cc.ui.UIPushButton.new({
        normal = "yellow_btn_up_186x66.png",
        pressed="yellow_btn_down_186x66.png"
    })
        :align(display.BOTTOM_CENTER, b_size.width/2,  40)
        :addTo(body)
        :setButtonLabel("normal", UIKit:commonButtonLable({
            text = _("切换账号")
        })):onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            local function exchange()
                if select_gamecenter and select_gamecenter:isButtonSelected() then
                    if ext.gamecenter.isAuthenticated() then -- 是否登录了GameCenter
                        local gcName,gcId = ext.gamecenter.getPlayerNameAndId()
                        if User.gc and gcId == User.gc.gcId then
                            UIKit:showMessageDialog(_("提示"),_("你的GameCenter账号绑定了当前游戏账号，在游戏外先切换其他GameCenter账号，再重试"))
                        else
                            UIKit:showMessageDialog(_("提示"),string.format(_("是否确认切换账号到GameCenter %s"),gcName),function()
                                NetManager:getSwitchGcPromise(gcId):done(function ()
                                    app:restart(true)
                                end)
                            end,function()end)
                        end
                    else
                        UIKit:showMessageDialog(_("提示"),_("你尚未登录GameCenter，请先登录你的GameCenter账号，再重试"),function()
                            ext.gamecenter.authenticate(true)
                        end,function()end)
                    end
                elseif select_google and select_google:isButtonSelected() then
                    UIKit:showMessageDialog(_("提示"),_("是否确认切换至Google账号？"),function()
                        ext.google.login(function ( data )
                            if data.event == "login_success" then
                                local userid,username = data.userid,data.username
                                if User.gc and User.gc.gcId == userid then
                                    UIKit:showMessageDialog(_("提示"),_("你的Google账号绑定了当前游戏账号，请登录其他Google账号，再重试"))
                                else
                                    NetManager:getSwitchGcPromise(userid):done(function (response)
                                        app:restart(true)
                                    end)
                                end
                            else
                                UIKit:showMessageDialog(_("提示"),_("链接失败"))
                            end
                        end)
                    end,function()end)
                elseif select_facebook:isButtonSelected() then
                    UIKit:showMessageDialog(_("提示"),_("是否确认切换至Facebook账号？"),function()
                        ext.facebook.login(function ( data )
                            if data.event == "login_success" then
                                local userid,username = data.userid,data.username
                                if User.gc and User.gc.gcId == userid then
                                    UIKit:showMessageDialog(_("提示"),_("你的Facebook账号绑定了当前游戏账号，请登录其他Facebook账号，再重试"))
                                else
                                    NetManager:getSwitchGcPromise(userid):done(function (response)
                                        app:restart(true)
                                    end)
                                end
                            else
                                UIKit:showMessageDialog(_("提示"),_("链接失败"))
                            end
                        end)
                    end,function()end)
                end
            end
            if not User.gc then
                UIKit:showMessageDialogWithParams({
                    title = _("警告"),
                    content = _("你当前的账号还未进行绑定，切换账号会导致当前账号丢失，你确定仍要执行本次造作吗？"),
                    ok_callback = exchange,
                    ok_btn_images = {normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"},
                    ok_string = _("切换账号"),
                    cancel_string = _("返回"),
                    cancel_btn_images = {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"},
                    cancel_callback = function ()end
                })
            else
                exchange()
            end
        end

        end)
end

return GameUISettingAccount






















