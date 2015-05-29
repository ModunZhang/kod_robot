--
-- Author: Danny He
-- Date: 2015-04-08 09:28:09
--
local GameUILoginBeta = UIKit:createUIClass('GameUILoginBeta','GameUISplashBeta')
local WidgetPushButton = import("..widget.WidgetPushButton")
local LOCAL_RESOURCES_PERCENT = 60
local Localize = import("..utils.Localize")
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")

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
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    local random = math.random(1,#Localize.login_tips)
    local label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = Localize.login_tips[random],
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
        button:setButtonEnabled(false)
        display.getRunningScene().startGame = true
        local sp = cc.Spawn:create(cc.ScaleTo:create(1,1.5),cc.FadeOut:create(1))
        local seq = transition.sequence({sp,cc.CallFunc:create(function()
                self:connectLogicServer()
            end)})
            self.star_game_sprite:runAction(seq)
        end)
end

function GameUILoginBeta:showStartState()
    self.star_game_sprite:show()
    self.start_button:show()
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
    :align(display.RIGHT_BOTTOM,display.right-2,display.bottom)
end

function GameUILoginBeta:showVersion()
    if  CONFIG_IS_DEBUG or device.platform == 'mac' then
        local __debugVer = require("debug_version")
        self.verLabel:setString(string.format(_("版本%s(%s)"), ext.getAppVersion(), __debugVer))
    else
        local jsonPath = cc.FileUtils:getInstance():fullPathForFilename("fileList.json")
        local file = io.open(jsonPath)
        local jsonString = file:read("*a")
        file:close()

        local tag = json.decode(jsonString).tag
        local version = string.format(_("版本%s(%s)"), ext.getAppVersion(), tag)
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
 	cc.Director:getInstance():getTextureCache():removeTextureForKey("splash_logo_515x92.png")
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
            self:showStartState()
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
        UIKit:NoWaitForNet()
    end)

end
function GameUILoginBeta:login()
    NetManager:getLoginPromise():done(function(response)
        ext.market_sdk.onPlayerLogin(User:Id(),User:Name(),User:ServerName())
        ext.market_sdk.onPlayerLevelUp(User:Level())
        self:performWithDelay(function()
            if DataManager:getUserData().basicInfo.terrain == "__NONE__" then
  		        app:EnterFteScene()
            else
                self:checkFte()
                if GLOBAL_FTE then
                    app:EnterMyCityFteScene()
                else
                    app:EnterMyCityScene()
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
            else
                content = UIKit:getErrorCodeData(code).message
            end
        end
        self:showError(content,function()
			self:connectLogicServer()
		end)
    end):always(function()
        UIKit:NoWaitForNet()
    end)      
end

function GameUILoginBeta:showError(msg,cb)
    msg = msg or ""
    UIKit:showKeyMessageDialog(_("提示"),msg, function()
        if cb then cb() end
    end)
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


local check = import("..fte.check")
local mockData = import("..fte.mockData")
function GameUILoginBeta:checkFte()
    if check("ALL") then
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
    if check("InstantRecruitSoldier_swordsman") then
        mockData.InstantRecruitSoldier("swordsman", 10)
    end
    if check("BuildHouseAt_5_3") then
        mockData.BuildHouseAt(5,3,"farmer")
        mockData.FinishBuildHouseAt(5,1)
    end
    if check("GetSoldier") then
        mockData.GetSoldier()
    end
    if check("FightWithNpc1") then
        mockData.FightWithNpc(1)
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
        mockData.TreatSoldier("swordsman", 12)
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
    if check("FightWithNpc2") then
        mockData.FightWithNpc(2)
    end
    if check("FightWithNpc3") then
        mockData.FightWithNpc(3)
    end
    if check("InstantRecruitSoldier_skeletonWarrior") then
        mockData.RecruitSoldier("skeletonWarrior", 1)
        mockData.FinishRecruitSoldier()
    end
    if check("BuildHouseAt_7_3") then
        mockData.BuildHouseAt(7,3,"quarrier")
        mockData.FinishBuildHouseAt(7,1)
    end
    if check("BuildHouseAt_8_3") then
        mockData.BuildHouseAt(8,3,"miner")
    end
end



return GameUILoginBeta
