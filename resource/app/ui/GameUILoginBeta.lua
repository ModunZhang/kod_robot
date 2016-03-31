--
-- Author: Danny He
-- Date: 2015-04-08 09:28:09
--
local GameUILoginBeta = UIKit:createUIClass('GameUILoginBeta','GameUISplashBeta')
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UIListView = import(".UIListView")
local Localize = import("..utils.Localize")
local LOCAL_RESOURCES_PERCENT = 100
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")
function GameUILoginBeta:ctor()
    GameUILoginBeta.super.ctor(self)
    self.m_localJson = nil
    self.m_serverJson = nil
    self.m_jsonFileName = "fileList.json"
    self.m_totalSize = 0
    self.m_currentSize = 0
    self.local_resources = {
        -- {image = "animations/building_animation0.pvr.ccz",list = "animations/building_animation0.plist"},
        -- {image = "animations/ui_animation_0.pvr.ccz",list = "animations/ui_animation_0.plist"},
        -- {image = "animations/ui_animation_1.pvr.ccz",list = "animations/ui_animation_1.plist"},
        -- {image = "animations/ui_animation_2.pvr.ccz",list = "animations/ui_animation_2.plist"},

        {image = "level0.png",list = "level0.plist"},
    -- {image = "ui_png1.pvr.ccz",list = "ui_png1.plist"},

    -- {image = "ui_pvr0.pvr.ccz",list = "ui_pvr0.plist"},
    -- {image = "ui_pvr1.pvr.ccz",list = "ui_pvr1.plist"},
    -- {image = "ui_pvr2.pvr.ccz",list = "ui_pvr2.plist"},
    }
    self.local_resources_percent_per = LOCAL_RESOURCES_PERCENT / #self.local_resources
end

function GameUILoginBeta:onEnter()
    GameUILoginBeta.super.onEnter(self)
    assert(self.ui_layer)
    self:createProgressBar()
    self:createTips()
    self:createStartGame()
    self:createContactUs()
    self:createVerLabel()
    self:createUserAgreement()
end

function GameUILoginBeta:Reset()
    self.m_localJson = nil
    self.m_serverJson = nil
    self.m_jsonFileName = nil
    self.m_totalSize = nil
    self.m_currentSize = nil
    self.local_resources = nil
    self.local_resources_percent_per = nil
end

-- UI
--------------------------------------------------------------------------------------------------------------
function GameUILoginBeta:createProgressBar()
    local bar = display.newSprite("splash_process_bg_606x25.png"):addTo(self.ui_layer):pos(display.cx,display.bottom+150)
    local progressFill = display.newSprite("splash_process_color_606x25.png")
    local ProgressTimer = cc.ProgressTimer:create(progressFill)
    ProgressTimer:setType(display.PROGRESS_TIMER_BAR)
    ProgressTimer:setBarChangeRate(cc.p(1,0))
    ProgressTimer:setMidpoint(cc.p(0,0))
    ProgressTimer:align(display.LEFT_BOTTOM, 0, 0):addTo(bar)
    ProgressTimer:setPercentage(1)
    local label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "",
        font = UIKit:getFontFilePath(),
        size = 14,
        align = cc.TEXT_ALIGNMENT_CENTER,
        color = UIKit:hex2c3b(0xf5fee9),
    }):addTo(bar):align(display.CENTER,303,13)
    self.progressTips = label
    self.progressTimer = ProgressTimer
    self.progress_bar = bar
end

function GameUILoginBeta:createTips()
    local LOGIN_TIPS = {
        _("提示：预留一定的空闲城民，兵营将他们训练成士兵"),
        _("登录提示帮助2"),
        -- _("登录提示帮助3"),
        _("登录提示帮助4"),
        _("登录提示帮助5"),
        -- _("登录提示帮助6"),
        _("登录提示帮助7"),
        _("登录提示帮助8"),
        _("登录提示帮助9"),
    -- _("登录提示帮助10"),
    }
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    local random = math.random(1,#LOGIN_TIPS)
    local label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = LOGIN_TIPS[random],
        font = UIKit:getFontFilePath(),
        size = 18,
        align = cc.TEXT_ALIGNMENT_CENTER,
        color = UIKit:hex2c3b(0xb7c2a0),
        dimensions = cc.size(460,0)
    })
    local size = label:getContentSize()
    local real_size =  cc.size(544,size.height)
    local bgImage = display.newScale9Sprite("splash_tips_bg_544x30.png", display.cx,display.bottom+100, cc.size(544,size.height), cc.rect(30,0,484,30))
        :addTo(self.ui_layer)
    label:addTo(bgImage):align(display.CENTER,272,size.height/2)
    self.tips_ui = bgImage
end

function GameUILoginBeta:createStartGame()
    local star_game_sprite = display.newSprite("start_game_292x28.png"):addTo(self.ui_layer):pos(display.cx,display.bottom+150):hide()
    self.star_game_sprite = star_game_sprite
    local button = WidgetPushTransparentButton.new(cc.rect(0,0,display.width,display.height),nil,{nil,{down = "DRAGON_STRIKE"}})
        :addTo(self.ui_layer):hide():align(display.LEFT_BOTTOM, 0, 0)
    self.start_button = button
    button:onButtonClicked(function()
        -- 检查用户是否同意了用户协议
        if self:IsAgreement() then
            self:startGame()
        else
            UIKit:showMessageDialog(_("提示"),_("我已阅读并同意[用户协议]"))
                :CreateOKButton(
                    {
                        listener = function ()
                            self:SetAgreeAgreement("agree")
                            self:startGame()
                        end,
                        btn_name= _("同意")
                    }
                ):CreateCancelButton(
                {
                    listener = function ()
                        self:OpenUserAgreement()
                    end,
                    btn_name= _("阅读"),
                    btn_images = {normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"}
                }
                )
        end
    end)
end
function GameUILoginBeta:SetAgreeAgreement()
    app:GetGameDefautlt():setStringForKey("USER_AGREEMENT","agree")
end
function GameUILoginBeta:SetNotAgreeAgreement()
    app:GetGameDefautlt():setStringForKey("USER_AGREEMENT","not_agree")
end
function GameUILoginBeta:IsAgreement()
    return app:GetGameDefautlt():getStringForKey("USER_AGREEMENT") == "agree"
end
function GameUILoginBeta:startGame()
    local button = self.start_button
    button:setButtonEnabled(false)
    display.getRunningScene().startGame = true
    local sp = cc.Spawn:create(cc.ScaleTo:create(1,1.5),cc.FadeOut:create(1))
    local seq = transition.sequence({sp,cc.CallFunc:create(function()
        if app:GetGameDefautlt():IsPassedSplash() then
            self:loginAction()
        else
            self:performWithDelay(function()
                self:AddSkip()
            end, 4)
            self.verLabel:fadeOut(0.5)
            self.user_agreement_label:fadeOut(0.5)
            self.user_agreement_button:hide()
            self:RunFte(function()
                self:loginAction()
            end)
        end
    end)})
    self.star_game_sprite:runAction(seq)
end
function GameUILoginBeta:AddSkip()
    cc.ui.UIPushButton.new({normal = "skip.png",pressed = "skip.png"})
        :addTo(self, 1000000):align(display.RIGHT_TOP, display.width, display.height)
        :onButtonClicked(function(event)
            event.target:setButtonEnabled(false)
            UIKit:showMessageDialog(_("提示"),_("是否跳过开头动画?"),function()
                self:Skip()
            end, function()
                event.target:setButtonEnabled(true)
            end, false)
        end):opacity(0):fadeIn(0.5)
end
function GameUILoginBeta:Skip()
    self.animation_node:stopAllActions()
    self:loginAction()
end
function GameUILoginBeta:createContactUs()
    local contact_us_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("[联系我们]"),
        font = UIKit:getFontFilePath(),
        size = 18,
        align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x2a575d),
    }):addTo(self.ui_layer,2)
        :align(display.RIGHT_BOTTOM,display.right-2,display.bottom)
    self.contact_us_label = contact_us_label
    local button = WidgetPushButton.new()
        :addTo(self.ui_layer,2):align(display.RIGHT_BOTTOM, display.right-2,display.bottom)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                local seq = transition.sequence({cc.ScaleTo:create(0.1,1.3),cc.ScaleTo:create(0.1,1),cc.CallFunc:create(function()
                    local subject,body = GameUtils:getLoginErrorMailFormat(_("登陆问题"))
                    local canSendMail = ext.sysmail.sendMail('support@batcatstudio.com',subject,body,function()end)
                    if not canSendMail then
                        UIKit:showMessageDialog(_("错误"),_("您尚未设置邮件：请前往IOS系统“设置”-“邮件、通讯录、日历”-“添加账户”处设置"),function()end)
                    end
                end)})
                contact_us_label:runAction(seq)
            end
        end)
    button:setContentSize(cc.size(contact_us_label:getContentSize().width + 30,contact_us_label:getContentSize().height + 25))
    button:setTouchSwallowEnabled(true)
    self.contact_us_button = button
end
function GameUILoginBeta:createUserAgreement()
    local user_agreement_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("[用户协议]"),
        font = UIKit:getFontFilePath(),
        size = 18,
        align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x2a575d),
    }):addTo(self.ui_layer,2)
        :align(display.LEFT_BOTTOM,display.left+2,display.bottom)
    self.user_agreement_label = user_agreement_label
    local click = false
    local button = WidgetPushButton.new()
        :addTo(self.ui_layer,2):align(display.LEFT_BOTTOM, display.left+2,display.bottom)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                if not click then
                    click = true
                    local seq = transition.sequence({cc.ScaleTo:create(0.1,1.3),cc.ScaleTo:create(0.1,1),cc.CallFunc:create(function()
                        self:performWithDelay(function()
                            self:OpenUserAgreement()
                            click = false
                        end, 0.2)
                    end)})
                    user_agreement_label:runAction(seq)
                end
            end
        end)
    button:setContentSize(cc.size(user_agreement_label:getContentSize().width + 30,user_agreement_label:getContentSize().height + 25))
    button:setTouchSwallowEnabled(true)
    self.user_agreement_button = button
end
function GameUILoginBeta:OpenUserAgreement()
    local dialog = UIKit:newWidgetUI("WidgetPopDialog",770,_("用户协议"),display.top-130):addTo(self.ui_layer,2)
    self.agreement_dialog = dialog
    local body = dialog:GetBody()
    local size = body:getContentSize()
    local bg = WidgetUIBackGround.new({width = 580 , height = 658},WidgetUIBackGround.STYLE_TYPE.STYLE_5):align(display.CENTER_BOTTOM, size.width/2, 80):addTo(body)
    local user_agreement_label = UIKit:ttfLabel({
        text = Localize.user_agreement.agreement,
        size = 20,
        color = 0x403c2f,
        align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
        dimensions = cc.size(555, 0),
    })
    local w,h =  user_agreement_label:getContentSize().width,user_agreement_label:getContentSize().height
    -- 提示内容
    local  listview = UIListView.new{
        viewRect = cc.rect(10,10, w, 640),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(bg)
    local item = listview:newItem()
    item:setItemSize(w,h)
    item:addContent(user_agreement_label)
    listview:addItem(item)
    listview:reload()

    cc.ui.UIPushButton.new(btn_images or {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({text =_("同意"), size = 24, color = 0xffedae,shadow=true}))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:SetAgreeAgreement()
                if self:CouldStartGame() then
                    self:startGame()
                end
                dialog:LeftButtonClicked()
            end
        end):align(display.RIGHT_CENTER, size.width - 20, 44):addTo(body)
    cc.ui.UIPushButton.new(btn_images or {normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({text =_("不同意"), size = 24, color = 0xffedae,shadow=true}))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:SetNotAgreeAgreement("not_agree")
                dialog:LeftButtonClicked()
            end
        end):align(display.LEFT_CENTER, 20, 44):addTo(body)
end
function GameUILoginBeta:createGameNotice()
    self:setProgressPercent(0)
    self:setProgressText(_("正在获取游戏公告..."))
    local request = network.createHTTPRequest(function(event)
        local ok = (event.name == "completed")
        local request = event.request
        self:setProgressPercent(50)
        if not ok then
            -- 请求失败，显示错误代码和错误消息
            -- print(request:getErrorCode(), request:getErrorMessage())
            if request:getErrorCode() ~= 0 and request:getErrorMessage() then
                self:setProgressPercent(100)
                self:performWithDelay(function()
                    self.progress_bar:hide()
                    self.tips_ui:hide()
                    self:showStartState()
                end, 0.5)
            end
            return
        end
        local code = request:getResponseStatusCode()
        if code ~= 200 then
            -- 请求结束，但没有返回 200 响应代码
            -- print("code===",code)
            self:setProgressPercent(100)
            self:performWithDelay(function()
                self.progress_bar:hide()
                self.tips_ui:hide()
                self:showStartState()
            end, 0.5)
            return
        end

        -- 请求成功，显示服务端返回的内容
        local response = request:getResponseString()

        local results = json.decode(response)
        if results.code ~= 200 then
            self:setProgressPercent(100)
            self:performWithDelay(function()
                self.progress_bar:hide()
                self.tips_ui:hide()
                self:showStartState()
            end, 0.5)
            return
        end
        if string.trim(results.data) ~= "" then
            local dialog = UIKit:newWidgetUI("WidgetNoticePopDialog",550,_("公告"),display.top-130):addTo(self.ui_layer,2)
            local body = dialog:GetBody()
            local size = body:getContentSize()
            WidgetPushButton.new({normal = 'tmp_button_battle_up_234x82.png',pressed = 'tmp_button_battle_down_234x82.png'},{scale9 = true})
                :setButtonLabel("normal", UIKit:commonButtonLable({
                    text = _("确定")
                }))
                :addTo(body)
                :pos(size.width/2,54)
                :onButtonClicked(function()
                    dialog:LeftButtonClicked()
                end)
                :setButtonSize(188,66)
            local bg = display.newScale9Sprite("background_notice_128x128_2.png", 0, 0,cc.size(568,390),cc.rect(15,15,98,98))
                :align(display.CENTER_BOTTOM,size.width/2,96)
                :addTo(body)
            local user_agreement_label = UIKit:ttfLabel({
                text = results.data,
                size = 22,
                color = 0xffedae,
                align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
                dimensions = cc.size(526, 0),
            })
            local w,h =  user_agreement_label:getContentSize().width,user_agreement_label:getContentSize().height
            -- 提示内容
            local  listview = UIListView.new{
                viewRect = cc.rect(15,10, w, 376),
                direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
            }:addTo(bg)
            local item = listview:newItem()
            item:setItemSize(w,h)
            item:addContent(user_agreement_label)
            listview:addItem(item)
            listview:reload()
        end
        self:setProgressPercent(100)
        self:performWithDelay(function()
            self.progress_bar:hide()
            self.tips_ui:hide()
            self:showStartState()
        end, 0.5)
    end, string.format("http://gate.batcatstudio.com/dragonfall/get-notice?env=%s&platform=%s", string.urlencode(CONFIG_IS_DEBUG and "development" or "production"),string.urlencode(GameUtils:getPlatformForServer())), "GET")
    request:setTimeout(10)
    request:start()
end

function GameUILoginBeta:showStartState()
    self.star_game_sprite:show()
    self.start_button:show()
    self.star_game_sprite:opacity(0)
    self.start_button:opacity(0)
    transition.fadeTo(self.star_game_sprite, {
        time = 1,
        opacity = 255
    })
    transition.fadeIn(self.start_button, {
        time = 1,
        opacity = 255
    })
end
function GameUILoginBeta:CouldStartGame()
    return self.start_button:isVisible() and not self.progress_bar:isVisible()
end
function GameUILoginBeta:createVerLabel()
    self.verLabel = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "版本:1.0.0(ddf3d)",
        font = UIKit:getFontFilePath(),
        size = 18,
        align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x2a575d),
    }):addTo(self.ui_layer,2)
        :align(display.RIGHT_BOTTOM,self.contact_us_label:getPositionX() - self.contact_us_label:getContentSize().width -5,display.bottom)
end

function GameUILoginBeta:showVersion()
    if CONFIG_IS_NOT_UPDATE or device.platform == 'mac' or device.platform == 'windows' then
        local __debugVer = require("debug_version")
        self.verLabel:setString("测试"..string.format("%s(%s)", ext.getAppVersion(), __debugVer))
        app.client_tag = -1
    else
        self:loadLocalJson()
        if not self.m_localJson then
            self:loadLocalJson()
        end
        local tag = json.decode(self.m_localJson).tag
        local version = string.format("%s(%s)", ext.getAppVersion(), tag)
        self.verLabel:setString(version)
        app.client_tag = tag
    end
end

-- life cycle
--------------------------------------------------------------------------------------------------------------
function GameUILoginBeta:OnMoveInStage()
    self:showVersion()
    self:GetServerInfo()
end
function GameUILoginBeta:GetServerInfo()
    self:setProgressText(_("正在获取服务器信息..."))
    if CONFIG_IS_NOT_UPDATE or device.platform == 'mac' or device.platform == 'windows' then --如果是player环境
        self:loadLocalResources()
    else -- 真机环境
        GameUtils:GetServerInfo({env = CONFIG_IS_DEBUG and "development" or "production", version = ext.getAppVersion()}, function(success, content)
            if success then
                -- self:setProgressText(_("获取服务器信息成功"))
                dump(content)
                local ip, port = unpack(string.split(content.data.entry, ":"))
                NetManager.m_gateServer.host = ip
                NetManager.m_gateServer.port = tonumber(port)
                NetManager.m_updateServer.basePath = content.data.basePath -- update server base path

                local localAppVersion = self:GetVersionWeight(ext.getAppVersion())
                local serverMinAppVersion = self:GetVersionWeight(content.data.appMinVersion)
                if localAppVersion < serverMinAppVersion then -- 需要强制更新
                    device.showAlert(_("错误"), _("游戏版本过低,请更新!"), { _("确定") }, function(event)
                        device.openURL(CONFIG_APP_URL[device.platform])
                        self:GetServerInfo()
                    end)
                elseif app.client_tag  == content.data.tag then -- 如果tag相等 不需要更新操作
                    self:performWithDelay(function()
                        self:loadLocalResources()
                    end, 0.8)
                else -- 开始更新逻辑
                    self:loadServerJson()
                end
            else
                local SIMULATION_WORKING_TIME = 3
                self:performWithDelay(function()
                    self:showErrorForReTry(_("获取服务器信息失败!"),function()
                        self:GetServerInfo()
                    end)
                end, SIMULATION_WORKING_TIME)
            end
        end)
    end
end

function GameUILoginBeta:onCleanup()
    GameUILoginBeta.super.onCleanup(self)
    -- clean  all  unused textures
    cc.Director:getInstance():getTextureCache():removeTextureForKey("splash_beta_bg_3987x1136.jpg")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("splash_logo_516x92.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("splash_process_color_606x25.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("splash_process_bg_606x25.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("splash_tips_bg_544x30.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("start_game_292x28.png.png")
end


function GameUILoginBeta:loadLocalResources()
    self:setProgressPercent(0)
    self:setProgressText(_("正在加载游戏资源..."))
    --TODO:这里暂时用emoji图片和已经合图的动画文件测试 60的进度用来加载资源
    local count = #self.local_resources
    for i,v in ipairs(self.local_resources) do
        self:__loadToTextureCache(v,i == count)
    end
end

function GameUILoginBeta:__loadToTextureCache(config,shouldLogin)
    display.addSpriteFrames(DEBUG_GET_ANIMATION_PATH(config.list),DEBUG_GET_ANIMATION_PATH(config.image),function()
        self:setProgressPercent((self.progress_num or 0) + self.local_resources_percent_per)
        if shouldLogin then
            self:createGameNotice()
            -- self:performWithDelay(function()
            --     self.progress_bar:hide()
            --     self.tips_ui:hide()
            -- end, 0.5)
        end
    end)
end

function GameUILoginBeta:setProgressText(str)
    self.progressTips:setString(str)
end

function GameUILoginBeta:setProgressPercent(num,animac)
    animac = animac or false
    if animac then
        local progressTo = cc.ProgressTo:create(1,num)
        self.progressTimer:runAction(progressTo)
    else
        self.progress_num = num
        self.progressTimer:setPercentage(num)
    end
end

function GameUILoginBeta:loginAction()
    -- self:setProgressText(_("连接网关服务器...."))
    UIKit:WaitForNet(5)
    self:connectGateServer()
end

function GameUILoginBeta:connectGateServer()
    NetManager:getConnectGateServerPromise():done(function()
        -- self:setProgressPercent(80)
        self:getLogicServerInfo()
    end):catch(function(err)
        GameUtils:PingSearchEngine(function(success)
            self:showErrorForReTry(success and _("服务器维护中") or _("连接网关服务器失败!"),function()
                self:performWithDelay(function()
                    self:loginAction()
                end, 1)
            end)
        end)
    end)
end
function GameUILoginBeta:getLogicServerInfo()
    NetManager:getLogicServerInfoPromise():done(function()
        self:connectLogicServer()
    end):catch(function(err)
        local content, title = err:reason()
        local need_restart = false
        if title == 'timeout' then
            content = _("请求超时")
        else
            local code = content.code
            if code == 508 then
                content = _("服务器维护中")
                need_restart = false
            elseif code == 691 then
                content = _("游戏版本验证失败")
                need_restart = true
            elseif code == 692 then
                content = _("游戏版本不匹配")
                need_restart = true
            else
                content = _("获取游戏服务器信息失败!")
                need_restart = false
            end
        end
        dump(err:reason())
        if(need_restart) then
            self:showError(content,function()
                app:restart(false)
            end)
        else
            self:showErrorForReTry(content, function()
                self:connectGateServer()
            end)
        end
        -- self:showError(content,function()
        --     if need_restart then
        --         app:restart(false)
        --     else
        --         self:connectGateServer()
        --     end
        -- end)
    end)
end


function GameUILoginBeta:connectLogicServer()
    NetManager:getConnectLogicServerPromise():done(function()
        self:login()
    end):catch(function(err)
        self:showErrorForReTry(_("连接游戏服务器失败!"),function()
            self:performWithDelay(function()
                self:connectLogicServer()
            end,1)
        end)
    end)

end
function GameUILoginBeta:login()
    local debug_info = debug.traceback("", 2)
    NetManager:getLoginPromise():done(function(response)
        local userData = DataManager:getUserData()
        ext.market_sdk.onPlayerLogin(userData._id, userData.basicInfo.name, userData.logicServerId)
        ext.market_sdk.onPlayerLevelUp(User:GetPlayerLevelByExp(userData.basicInfo.levelExp))

        self:performWithDelay(function()
            self.enter_next_scene = true
            if DataManager:getUserData().basicInfo.terrain == "__NONE__" then
                app:EnterFteScene()
            else
                self:checkFte()
                if GLOBAL_FTE then
                    app:EnterMyCityFteScene()
                else
                    app:EnterMyCityScene(true)
                end
            end
        end, 0.3)
    end):catch(function(err)
        dump(err)
        NetManager:disconnect()
        local content, title = err:reason()
        if title == 'syntaxError' then
            self:showError(content,function()
                app:restart(false)
            end)
            return
        end
        if title == 'timeout' then
            content = _("请求超时")
        else
            local code = content.code
            if UIKit:getErrorCodeKey(content.code) == 'playerAlreadyLogin' then
                content = _("玩家已经登录")
                if checktable(ext.market_sdk) and ext.market_sdk.onPlayerEvent then
                    ext.market_sdk.onPlayerEvent("LUA_ERROR_LOGIN", debug_info)
                end
            else
                content = UIKit:getErrorCodeData(code).message
            end
        end
        self:showErrorForReTry(content,function()
            self:connectLogicServer()
        end)
    end):always(function()
        UIKit:NoWaitForNet()
    end)
end

function GameUILoginBeta:showError(msg,cb)
    UIKit:NoWaitForNet()
    msg = msg or ""
    UIKit:showKeyMessageDialog(_("提示"),msg, function()
        if cb then cb() end
    end)
end
function GameUILoginBeta:showErrorForReTry(msg,cb)
    UIKit:NoWaitForNet()
    msg = msg or ""
    UIKit:showKeyMessageDialog(_("提示"),msg, function()
        if cb then cb() end
    end,nil,_("重试"),true)
end
-- Auto Update
--------------------------------------------------------------------------------------------------------------
function GameUILoginBeta:loadLocalJson()
    if self.m_localJson then return end
    local jsonPath = cc.FileUtils:getInstance():fullPathForFilename(self.m_jsonFileName)
    local file = io.open(jsonPath)
    local jsonString = file:read("*a")
    file:close()
    self.m_localJson = jsonString
end

function GameUILoginBeta:loadServerJson()
    self:setProgressText(_("检查游戏更新...."))

    NetManager:getUpdateFileList(function(success, msg)
        if not success then
            device.showAlert(_("错误"), _("检查游戏更新失败!"), { _("确定") },function(event)
                app:restart(false)
            end)
            return
        end

        self.m_serverJson = msg
        self:donwLoadFilesWithFileList()
    end)
end
-- 1.0 --> 100 1.01 --> 110 1.0.1 --> 101
function GameUILoginBeta:GetVersionWeight(ver)
    ver = tostring(ver)
    local verInfo = string.split(ver,'.')
    local ret,flag = 0,1
    for index=3,1,-1 do
        local current = verInfo[index] or '0'
        current = tonumber(current) * flag
        ret = ret + current
        flag = flag * 10
    end
    return ret
end

function GameUILoginBeta:donwLoadFilesWithFileList()
    self.m_totalSize = 0
    self.m_currentSize = 0
    local localFileList = json.decode(self.m_localJson)
    local serverFileList = json.decode(self.m_serverJson)

    local updateFileList = {}
    for k, v in pairs(serverFileList.files) do
        local localFile = localFileList.files[k]
        if not localFile or localFile.tag ~= v.tag or localFile.crc32 ~= v.crc32 then
            v.path = k
            table.insert(updateFileList, v)
        end
    end
    if #updateFileList > 0 then
        LuaUtils:outputTable("updateFileList", updateFileList)
        for _, v in ipairs(updateFileList) do
            self.m_totalSize = self.m_totalSize + v.size
        end
        dump(updateFileList,"updateFileList------>")
        self:downloadFiles(updateFileList)
    else
        self:setProgressPercent(100)
        self:performWithDelay(function()
            self:loadLocalResources()
        end, 0.8)
    end
end

function GameUILoginBeta:downloadFiles(files)
    if #files > 0 then
        local file = files[1]
        table.remove(files, 1)

        local fileTotal = 0
        local fileCurrent = 0
        local percent = nil
        NetManager:downloadFile(file, function(success)
            if not success then
                self:showError(_("文件下载失败!"), function()
                    app:restart()
                end)
                return
            end
            self.m_currentSize = self.m_currentSize + fileTotal
            self:downloadFiles(files)
        end, function(total, current)
            fileTotal = total
            current = current or 0
            local currentPercent = (self.m_currentSize + current) / self.m_totalSize * 100
            if (percent ~= currentPercent) then
                percent = currentPercent
                self:setProgressPercent(percent)
                self:setProgressText(string.format(_("更新进度:%d%%"), percent))
            end
        end)
    else
        self:saveServerJson()
        app:restart()
    end
end

function GameUILoginBeta:saveServerJson()
    local resPath = GameUtils:getUpdatePath() .. "res/"
    local filePath = resPath .. self.m_jsonFileName
    local file = io.open(filePath, "w")
    if not file then
        self:showError(_("文件下载失败!"), function()
            app:restart()
        end)
        return
    end
    file:write(self.m_serverJson)
    file:close()
end


local check = import("..fte.check")
local mockData = import("..fte.mockData")
function GameUILoginBeta:checkFte()
    if check("ALL") or check("BuildHouseAt_8_3") then
        app:EnterUserMode()
        return
    end

    local dragon_type
    for k,v in pairs(DataManager:getUserData().dragons) do
        if v.star > 0 then
            dragon_type = k
            break
        end
    end
    local bg_auido_on,effect_audio_on = app:GetAudioManager():GetConfig()
    app:GetAudioManager():ResetorConfig(false, false)

    DataManager.need_notify = false
    if check("HateDragon") and dragon_type then
        mockData.HateDragon(dragon_type)
    end
    if check("DefenceDragon") and dragon_type then
        mockData.DefenceDragon(dragon_type)
    end
    if check("BuildHouseAt_3_3") then
        mockData.BuildHouseAt(3,3,"dwelling")
        mockData.FinishBuildHouseAt(3,1)
    end
    if check("UpgradeBuildingTo_keep_2") then
        mockData.UpgradeBuildingTo("keep",2)
    end
    if check("FinishUpgradingBuilding_keep_2") then
        mockData.FinishUpgradingBuilding("keep",2)
    end
    if check("UpgradeBuildingTo_barracks_1") then
        mockData.UpgradeBuildingTo("barracks",1)
    end
    if check("FinishUpgradingBuilding_barracks_1") then
        mockData.FinishUpgradingBuilding("barracks",1)
    end
    if check("InstantRecruitSoldier_swordsman_1") then
        mockData.InstantRecruitSoldier("swordsman_1", 10)
    end
    if check("BuildHouseAt_5_3") then
        mockData.BuildHouseAt(5,3,"farmer")
        mockData.FinishBuildHouseAt(5,1)
    end
    if check("GetSoldier") then
        mockData.GetSoldier()
    end
    if check("FightWithNpc1_1") then
        mockData.FightWithNpc("1_1")
    end
    if check("UpgradeBuildingTo_keep_3") then
        mockData.UpgradeBuildingTo("keep", 3)
    end
    if check("FinishUpgradingBuilding_keep_3") then
        mockData.FinishUpgradingBuilding("keep",3)
    end
    if check("UpgradeBuildingTo_hospital_1") then
        mockData.UpgradeBuildingTo("hospital",1)
    end
    if check("FinishUpgradingBuilding_hospital_1") then
        mockData.FinishUpgradingBuilding("hospital",1)
    end
    if check("TreatSoldier") then
        mockData.TreatSoldier("swordsman_1", 12)
    end
    if check("BuildHouseAt_6_3") then
        mockData.BuildHouseAt(6,3,"woodcutter")
        mockData.FinishBuildHouseAt(6,1)
    end
    if check("UpgradeBuildingTo_keep_4") then
        mockData.UpgradeBuildingTo("keep", 4)
    end
    if check("FinishUpgradingBuilding_keep_4") then
        mockData.FinishUpgradingBuilding("keep",4)
    end
    if check("UpgradeBuildingTo_academy_1") then
        mockData.UpgradeBuildingTo("academy",1)
    end
    if check("FinishUpgradingBuilding_academy_1") then
        mockData.FinishUpgradingBuilding("academy",1)
    end
    if check("Research") then
        mockData.Research()
    end
    if check("UpgradeBuildingTo_keep_5") then
        mockData.UpgradeBuildingTo("keep", 5)
    end
    if check("FinishUpgradingBuilding_keep_5") then
        mockData.FinishUpgradingBuilding("keep",5)
    end
    if check("UpgradeBuildingTo_materialDepot_1") then
        mockData.UpgradeBuildingTo("materialDepot",1)
    end
    if check("FinishUpgradingBuilding_materialDepot_1") then
        mockData.FinishUpgradingBuilding("materialDepot",1)
    end
    if check("FightWithNpc1_2") then
        mockData.FightWithNpc("1_2")
    end
    if check("FightWithNpc1_3") then
        mockData.FightWithNpc("1_3")
    end
    if check("InstantRecruitSoldier_skeletonWarrior") then
        mockData.InstantRecruitSoldier("skeletonWarrior", 1)
    end
    if check("BuildHouseAt_7_3") then
        mockData.BuildHouseAt(7,3,"quarrier")
        mockData.FinishBuildHouseAt(7,1)
    end
    if check("BuildHouseAt_8_3") then
        mockData.BuildHouseAt(8,3,"miner")
    end
    app:GetAudioManager():ResetorConfig(bg_auido_on, effect_audio_on)
    DataManager.need_notify = true
end



return GameUILoginBeta























