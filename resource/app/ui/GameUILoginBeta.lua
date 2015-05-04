--
-- Author: Danny He
-- Date: 2015-04-08 09:28:09
--
local GameUILoginBeta = UIKit:createUIClass('GameUILoginBeta','GameUISplashBeta')
local WidgetPushButton = import("..widget.WidgetPushButton")
local LOCAL_RESOURCES_PERCENT = 60

function GameUILoginBeta:ctor()
    GameUILoginBeta.super.ctor(self)
    self.m_localJson = nil
    self.m_serverJson = nil
    self.m_jsonFileName = "fileList.json"
    self.m_totalSize = 0
    self.m_currentSize = 0
    self.local_resources = {
		{image = "animations/dragon_animation_0.pvr.ccz",list = "animations/dragon_animation_0.plist"},
		{image = "animations/dragon_animation_1.pvr.ccz",list = "animations/dragon_animation_1.plist"},
		{image = "animations/dragon_animation_2.pvr.ccz",list = "animations/dragon_animation_2.plist"},
		{image = "animations/dragon_animation_3.pvr.ccz",list = "animations/dragon_animation_3.plist"},
		{image = "animations/dragon_animation_4.pvr.ccz",list = "animations/dragon_animation_4.plist"},
		{image = "animations/dragon_animation_5.pvr.ccz",list = "animations/dragon_animation_5.plist"},
		{image = "animations/dragon_animation_6.pvr.ccz",list = "animations/dragon_animation_6.plist"},
		{image = "animations/soldiers_animation_0.pvr.ccz",list = "animations/soldiers_animation_0.plist"},
		{image = "animations/soldiers_animation_1.pvr.ccz",list = "animations/soldiers_animation_1.plist"},
		{image = "animations/soldiers_animation_2.pvr.ccz",list = "animations/soldiers_animation_2.plist"},
		{image = "animations/soldiers_animation_3.pvr.ccz",list = "animations/soldiers_animation_3.plist"},
		{image = "animations/ui_animation_0.pvr.ccz",list = "animations/ui_animation_0.plist"},
        {image = "animations/ui_animation_1.pvr.ccz",list = "animations/ui_animation_1.plist"},
        {image = "animations/heihua_animation_0.pvr.ccz",list = "animations/heihua_animation_0.plist"},
        {image = "animations/heihua_animation_1.pvr.ccz",list = "animations/heihua_animation_1.plist"},
        {image = "animations/heihua_animation_2.pvr.ccz",list = "animations/heihua_animation_2.plist"},
        {image = "animations/region_animation_0.pvr.ccz",list = "animations/region_animation_0.plist"},
		{image = "animations/building_animation.pvr.ccz",list = "animations/building_animation.plist"},
		{image = "emoji.png",list = "emoji.plist"},
	}
	self.local_resources_percent_per = LOCAL_RESOURCES_PERCENT / #self.local_resources
end

function GameUILoginBeta:onEnter()
	GameUILoginBeta.super.onEnter(self)
	assert(self.ui_layer)
	self:createProgressBar()
    self:createTips()
    self:createStartGame()
    self:createVerLabel()
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
    local bar = display.newSprite("splash_process_bg.png"):addTo(self.ui_layer):pos(display.cx,display.bottom+150)
    local progressFill = display.newSprite("splash_process_color.png")
    local ProgressTimer = cc.ProgressTimer:create(progressFill)
    ProgressTimer:setType(display.PROGRESS_TIMER_BAR)
    ProgressTimer:setBarChangeRate(cc.p(1,0))
    ProgressTimer:setMidpoint(cc.p(0,0))
    ProgressTimer:align(display.LEFT_BOTTOM, 0, 0):addTo(bar)
    ProgressTimer:setPercentage(1)
    display.newSprite("splash_process_bound.png"):align(display.LEFT_BOTTOM, -10, -4):addTo(bar)
    local label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "Loading(1/3)...",
        font = UIKit:getFontFilePath(),
        size = 12,
        align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0xf3f0b6),
        valign = cc.VERTICAL_TEXT_ALIGNMENT_CENTER,
    }):addTo(bar):align(display.CENTER,bar:getContentSize().width/2,bar:getContentSize().height/2)
    self.progressTips = label
    self.progressTimer = ProgressTimer
    self.progress_bar = bar
end

function GameUILoginBeta:createTips()
    local bgImage = display.newSprite("splash_tips_bg.png"):addTo(self.ui_layer):pos(display.cx,display.bottom+100)
    local label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("提示:预留一定的空闲城民,兵营将他们训练成士兵"),
        font = UIKit:getFontFilePath(),
        size = 18,
        align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0xaaa87f),
    }):addTo(bgImage):align(display.CENTER,bgImage:getContentSize().width/2,bgImage:getContentSize().height/2)
    self.tips_ui = bgImage
end

function GameUILoginBeta:createStartGame()
    local button = WidgetPushButton.new({
         normal = "start_game_481x31.png"
    },nil,nil,{down = "SPLASH_BUTTON_START"}):addTo(self.ui_layer):pos(display.cx,display.bottom+150):hide()
    self.start_ui = button

    button:onButtonClicked(function()
        local sp = cc.Spawn:create(cc.ScaleTo:create(1,1.5),cc.FadeOut:create(1))
        local seq = transition.sequence({sp,cc.CallFunc:create(function()
                self:connectLogicServer()
            end)})
            button:setButtonEnabled(false)
            self.start_ui:runAction(seq)
        end)
end

function GameUILoginBeta:createVerLabel()
    self.verLabel = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "版本:1.0.0(ddf3d)",
        font = UIKit:getFontFilePath(),
        size = 18,
        align = cc.ui.UILabel.TEXT_ALIGN_CENTER, 
        color = cc.c3b(0,0,0),
    }):addTo(self.ui_layer,2)
    :align(display.RIGHT_BOTTOM,display.right-2,display.bottom)
end

function GameUILoginBeta:showVersion()
    if  CONFIG_IS_DEBUG or device.platform == 'mac' then
        local __debugVer = require("debug_version")
        self.verLabel:setString(string.format(_("版本:%s(%s)"), ext.getAppVersion(), __debugVer))
    else
        local jsonPath = cc.FileUtils:getInstance():fullPathForFilename("fileList.json")
        local file = io.open(jsonPath)
        local jsonString = file:read("*a")
        file:close()

        local tag = json.decode(jsonString).tag
        local version = string.format(_("版本:%s(%s)"), ext.getAppVersion(), tag)
        self.verLabel:setString(version)
    end
end

-- life cycle
--------------------------------------------------------------------------------------------------------------
function GameUILoginBeta:OnMoveInStage()
    self:showVersion()
    if CONFIG_IS_DEBUG or device.platform == 'mac' then
    	self:loadLocalResources()
    else
    	self:loadLocalJson()
		self:loadServerJson()
    end
end

function GameUILoginBeta:onCleanup()
	GameUILoginBeta.super.onCleanup(self)
	-- clean  all  unused textures
	cc.Director:getInstance():getTextureCache():removeTextureForKey("splash_beta_bg_3987x1136.jpg")
 	cc.Director:getInstance():getTextureCache():removeTextureForKey("splash_beta_logo_467x113.png")
 	cc.Director:getInstance():getTextureCache():removeTextureForKey("splash_process_color.png")
 	cc.Director:getInstance():getTextureCache():removeTextureForKey("splash_process_bg.png")
 	cc.Director:getInstance():getTextureCache():removeTextureForKey("splash_tips_bg.png")
 	cc.Director:getInstance():getTextureCache():removeTextureForKey("splash_process_bound.png")
end


function GameUILoginBeta:loadLocalResources()
	self:setProgressPercent(0)
	self:setProgressText(_("加载游戏资源..."))
	--TODO:这里暂时用emoji图片和已经合图的动画文件测试 60的进度用来加载资源
	local count = #self.local_resources
	for i,v in ipairs(self.local_resources) do
		self:__loadToTextureCache(v,i == count)
	end
	
end

function GameUILoginBeta:__loadToTextureCache(config,shouldLogin)
	display.addSpriteFrames(DEBUG_GET_ANIMATION_PATH(config.list),DEBUG_GET_ANIMATION_PATH(config.image),function()
		self:setProgressPercent(self.progress_num + self.local_resources_percent_per)
		if shouldLogin then self:loginAction() end
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
    self:setProgressText(_("连接网关服务器...."))
    self:connectGateServer()
end

function GameUILoginBeta:connectGateServer()
    NetManager:getConnectGateServerPromise():done(function()
        self:setProgressPercent(80)
        self:getLogicServerInfo()
    end):catch(function(err)
        self:showError(_("连接网关服务器失败!"),function()
            self:performWithDelay(function()
                self:loginAction()
            end, 1)
        	
        end)
    end)
end
function GameUILoginBeta:getLogicServerInfo()
    NetManager:getLogicServerInfoPromise():done(function()
        self:setProgressPercent(100)
        self:performWithDelay(function()
            self.progress_bar:hide()
            self.tips_ui:hide()
            self.start_ui:show()
        end, 0.5) 
    end):catch(function(err)
        local content, title = err:reason()
        if title == 'timeout' then
            content = _("请求超时")
        else
            local code = content.code 
            if UIKit:getErrorCodeKey(code) == "serverUnderMaintain" then
                content = _("服务器维护中")
            else
                content = _("获取游戏服务器信息失败!")
            end
        end
        dump(err:reason())
        self:showError(content,function()
        	self:connectGateServer()
        end)
    end)
end


function GameUILoginBeta:connectLogicServer()
    UIKit:WaitForNet()
    NetManager:getConnectLogicServerPromise():done(function()
        self:login()
    end):catch(function(err)
        self:showError(_("连接游戏服务器失败!"),function()
            self:performWithDelay(function()
        	   self:connectLogicServer()
            end,1)
        end)
    end)

end

function GameUILoginBeta:login()
    NetManager:getLoginPromise():done(function(response)
        ext.market_sdk.onPlayerLogin(User:Id(),User:Name(),User:ServerName())
        ext.market_sdk.onPlayerLevelUp(User:Level())
        self:performWithDelay(function()
  		    app:EnterMyCityScene()
        end, 0.3)
    end):catch(function(err)
        dump(err)
        local content, title = err:reason()
        if title == 'timeout' then
            content = _("请求超时")
        else
            local code = content.code
            if UIKit:getErrorCodeKey(content.code) == 'reLoginNeeded' then
                self:login()
                return
            else
                content = _("登录游戏失败!")
            end
        end
        self:showError(content,function()
			self:login()
		end)
    end):always(function()
        UIKit:NoWaitForNet()
    end)      
end

function GameUILoginBeta:showError(msg,cb)
    msg = msg or ""
    UIKit:showMessageDialog(_("提示"),msg, function()
        if cb then cb() end
    end, nil, false)
end
-- Auto Update
--------------------------------------------------------------------------------------------------------------
function GameUILoginBeta:loadLocalJson()
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
        self:getUpdateFileList()
    end)
end

function GameUILoginBeta:getUpdateFileList()
    self.m_totalSize = 0
    self.m_currentSize = 0
    local localFileList = json.decode(self.m_localJson)
    local serverFileList = json.decode(self.m_serverJson)
    local localAppVersion = ext.getAppVersion() 
    local serverAppVersion = serverFileList.appVersion
    if localAppVersion < serverAppVersion then
        device.showAlert(_("错误"), _("游戏版本过低,请更新!"), { _("确定") }, function(event)
            if CONFIG_IS_DEBUG then
                device.openURL("https://batcat.sinaapp.com/ad_hoc/build-index.html")
            else
                device.openURL(CONFIG_APP_URL[device.platform])
            end
        end)
        return
    end

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
            current = current
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
return GameUILoginBeta
