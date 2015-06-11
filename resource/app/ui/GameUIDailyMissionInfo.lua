--
-- Author: Danny He
-- Date: 2015-03-06 17:27:51
--

local GameUIDailyMissionInfo = UIKit:createUIClass("GameUIDailyMissionInfo","UIAutoClose")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UIKit = UIKit
local UIListView = import(".UIListView")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")
local config_stringInit = GameDatas.PlayerInitData.stringInit
local Localize_item = import("..utils.Localize_item")

function GameUIDailyMissionInfo:ctor(key_of_daily)
    GameUIDailyMissionInfo.super.ctor(self)
    self.key_of_daily = key_of_daily
end

function GameUIDailyMissionInfo:GetRewardsStr()
    local key_of_daily = self:GetKeyOfDaily()
    local config_key = ""
    if key_of_daily == 'empireRise' then
        config_key = 'empireRiseDailyTaskRewards'
    elseif key_of_daily == 'brotherClub' then
        config_key = 'brotherClubDailyTaskRewards'
    elseif key_of_daily == 'conqueror' then
        config_key = 'conquerorDailyTaskRewards'
    elseif key_of_daily == 'growUp' then
        config_key = 'growUpDailyTaskRewards'
    end
    local config_rewards = config_stringInit[config_key].value
    if config_rewards then
        local reward_type,reward_key,count = unpack(string.split(config_rewards,":"))
        return string.format("%s x%s",Localize_item.item_name[reward_key],count)
    end
end

function GameUIDailyMissionInfo:onEnter()
    GameUIDailyMissionInfo.super.onEnter(self)
    User:AddListenOnType(self,User.LISTEN_TYPE.DAILY_TASKS)
    self:BuildUI()
end


function GameUIDailyMissionInfo:BuildUI()
    local bg = WidgetUIBackGround.new({height=552})
    self:addTouchAbleChild(bg)
    bg:pos(((display.width - bg:getContentSize().width)/2),window.bottom_top + 178)
    local titleBar = display.newSprite("title_blue_600x56.png"):align(display.LEFT_BOTTOM,3,537):addTo(bg)
    local closeButton = UIKit:closeButton()
        :addTo(titleBar)
        :align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
        :onButtonClicked(function ()
            self:LeftButtonClicked()
        end)
    UIKit:ttfLabel({
        text = Localize.daily_tasks[self:GetKeyOfDaily()].title,
        size = 22,
        shadow = true,
        color = 0xffedae
    }):addTo(titleBar):align(display.CENTER,300,28)
    local list_bg = display.newScale9Sprite("background_568x120.png", 0,0,cc.size(568,326),cc.rect(15,10,538,100))
        :addTo(bg):align(display.BOTTOM_CENTER, 304, 25)
    self.info_list = UIListView.new({
        viewRect = cc.rect(11,10, 546, 306),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }):addTo(list_bg)

    UIKit:ttfLabel({
        text = _("完成下列任务,领取奖励"),
        color= 0x403c2f,
        size = 20,
    }):align(display.LEFT_BOTTOM, 22, 396):addTo(bg)
    local progress_bg,progress = self:GetProgressBar()
    progress_bg:align(display.LEFT_BOTTOM, 22, 436):addTo(bg)
    self.progress = progress
    UIKit:ttfLabel({
        text = _("当前进度"),
        color= 0x403c2f,
        size = 20,
    }):align(display.LEFT_BOTTOM,22,484):addTo(bg)

    local yin_box = ccs.Armature:create("yin_box")
        :align(display.RIGHT_BOTTOM, 562,378)
        :addTo(bg)
        :scale(174/400)
    self.button_finish_animation = yin_box
    local button_finish_sprite = display.newSprite("#root/yin/a0002.png"):align(display.RIGHT_BOTTOM, 562,378)
        :addTo(bg)
        :scale(174/400)
    self.button_finish_sprite = button_finish_sprite
    local button = WidgetPushTransparentButton.new(cc.rect(0,0,174,141))
        :align(display.RIGHT_BOTTOM, 562,378)
        :addTo(bg)
        :onButtonClicked(function()
            self:GetRewardFromServer()
        end)
    local finish_icon = display.newSprite("minssion_finish_icon_51x51.png")
        :align(display.CENTER, -50, 70)
        :addTo(yin_box)
    finish_icon:setVisible(true)
    self.button_finish_icon = finish_icon
    self:RefreshListUI()
end

function GameUIDailyMissionInfo:RefreshListUI()
    local percentage = #User:GetDailyTasksInfo(self:GetKeyOfDaily()) / 4
    self.progress:setPercentage(percentage * 100)
    self.button_finish_icon:setVisible(User:CheckDailyTasksWasRewarded(self:GetKeyOfDaily()))
    self:RefreshListView()
    if User:CheckDailyTasksWasRewarded(self:GetKeyOfDaily()) then
        self.button_finish_sprite:show()
        self.button_finish_animation:hide()
    else
        self.button_finish_sprite:hide()
        self.button_finish_animation:show()
    end
end


function GameUIDailyMissionInfo:GetProgressBar()
    local bg = display.newSprite("mission_progress_bar_bg_348x40.png")
    local progress = UIKit:commonProgressTimer("mission_progress_bar_content_348x40.png"):align(display.LEFT_CENTER, 0, 20):addTo(bg)
    local box = display.newSprite("mission_progress_bar_box_348x40.png"):align(display.LEFT_CENTER, 0, 20):addTo(bg)
    return bg,progress
end

function GameUIDailyMissionInfo:GetRewardFromServer()
    local percentage = #User:GetDailyTasksInfo(self:GetKeyOfDaily()) / 4
    if percentage < 1 then
        GameGlobalUI:showTips(_("提示"),_("你还未完成所有任务"))
        return
    end
    if not User:CheckDailyTasksWasRewarded(self:GetKeyOfDaily()) then
        NetManager:getDailyTaskRewards(self:GetKeyOfDaily()):done(function()
            self.button_finish_animation:getAnimation():play("Animation1", -1, 0)
            app:GetAudioManager():PlayeEffectSoundWithKey("USE_ITEM")
            GameGlobalUI:showTips(_("恭喜"),self:GetRewardsStr())
        end)
    else
        GameGlobalUI:showTips(_("提示"),_("你已经领取了该奖励"))
    end
end

function GameUIDailyMissionInfo:RefreshListView()
    self.info_list:removeAllItems()
    local data = self:GetMissionConfig()[self:GetKeyOfDaily()]
    local daily_info = User:GetDailyTasksInfo(self:GetKeyOfDaily())
    for __,v in ipairs(daily_info) do
        data[v].finished = true
    end
    for index,v in ipairs(data) do
        local item = self:GetItem(index,v,v.finished)
        self.info_list:addItem(item)
    end
    self.info_list:reload()
end

function GameUIDailyMissionInfo:GetItem(index,item_data,isFinish)
    local item = self.info_list:newItem()
    local content = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", index % 2 == 0 and 1 or 2)):size(546,78)
    UIKit:ttfLabel({
        text = item_data.title,
        size = 20,
        color= 0x403c2f
    }):align(display.LEFT_CENTER, 16, 39):addTo(content)

    if isFinish then
        display.newSprite("minssion_finish_icon_51x51.png"):align(display.CENTER, 462, 39):addTo(content)
    else
        if not item_data.isDesc then
            WidgetPushButton.new({
                normal = "yellow_btn_up_148x58.png",
                pressed= "yellow_btn_down_148x58.png"
            })
                :align(display.RIGHT_CENTER, 536, 39)
                :addTo(content)
                :onButtonClicked(function()
                    if item_data.func then
                        if item_data.func() then
                            self:CloseUIIf("GameUIMission")
                            self:CloseUIIf("GameUIDailyMissionInfo")
                        end
                    end
                end)
                :setButtonLabel("normal", UIKit:commonButtonLable({
                    text = _("前往"),
                }))
        end
    end
    item:addContent(content)
    item:setItemSize(546,78)
    return item
end

function GameUIDailyMissionInfo:CloseUIIf(class_name)
    local ui = UIKit:GetUIInstance(class_name)
    if ui then
        ui:LeftButtonClicked()
    end
end

function GameUIDailyMissionInfo:GetMissionConfig()
    local config = {
        empireRise = {
            {
                index = 1,
                title = _("升级一次建筑"),
                isDesc = false,
                func = function()
                    UIKit:newGameUI("GameUIHasBeenBuild", City):AddToCurrentScene(true)
                    return true
                end
            },
            {
                index = 2,
                title = _("招募一次兵种"),
                isDesc = false,
                func = function()
                    local building = City:GetFirstBuildingByType("barracks")
                    if  not building:IsUnlocked() then
                        GameGlobalUI:showTips(_("错误"),_("你还未建造兵营"))
                        return false
                    end
                    UIKit:newGameUI("GameUIBarracks", City,building,"recruit"):AddToCurrentScene(true)
                    return true
                end
            },
            {
                index = 3,
                title = _("成功通关塞琳娜的考验"),
                isDesc = false,
                func = function()
                    UIKit:newGameUI("GameUISelenaQuestion"):AddToCurrentScene(true)
                    return false
                end
            },
            {
                index = 4,
                title = _("制造一批建筑材料"),
                isDesc = false,
                func = function()

                    local building = City:GetFirstBuildingByType("toolShop")
                    if not building:IsUnlocked() then
                        GameGlobalUI:showTips(_("错误"),_("你还未建造工具作坊"))
                        return false
                    end
                    UIKit:newGameUI("GameUIToolShop", City,building,"manufacture"):AddToCurrentScene(true)
                    return false
                end
            }
        },
        conqueror = {
            {
                index = 1,
                title = _("参加一次联盟会战"),
                isDesc = true,
                func = function()
                end
            },
            {
                index = 2,
                title = _("对地方玩家城市进行一次进攻"),
                isDesc = true,
                func = function()

                end
            },
            {
                index = 3,
                title = _("占领一座村落"),
                isDesc = true,
                func = function()

                end
            },
            {
                index = 4,
                title = _("搭乘飞艇进行一次探索"),
                isDesc = false,
                func = function()
                    local dragon_type = City:GetDragonEyrie():GetDragonManager():GetCanFightPowerfulDragonType()
                    if #dragon_type > 0 then
                        local _,_,index = City:GetUser():GetPVEDatabase():GetCharPosition()
                        app:EnterPVEScene(index)
                    else
                        GameGlobalUI:showTips(_("错误"),_("需要一条空闲状态的魔龙才能探险"))
                        return false
                    end
                end
            }
        },
        brotherClub = {
            {
                index = 1,
                title = _("进行一次联盟捐赠"),
                isDesc = false,
                func = function()
                    if Alliance_Manager:GetMyAlliance():IsDefault() then
                        GameGlobalUI:showTips(_("错误"),_("你还未加入联盟"))
                        return false
                    end
                    UIKit:newGameUI("GameUIAllianceContribute"):AddToCurrentScene(true)
                    return false
                end
            },
            {
                index = 2,
                title = _("在联盟商店购买一次道具"),
                isDesc = false,
                func = function()
                    if Alliance_Manager:GetMyAlliance():IsDefault() then
                        GameGlobalUI:showTips(_("错误"),_("你还未加入联盟"))
                        return false
                    end
                    local building = Alliance_Manager:GetMyAlliance():GetAllianceMap():FindAllianceBuildingInfoByName("shop")
                    UIKit:newGameUI("GameUIAllianceShop",City,"goods",building):AddToCurrentScene(true)
                    return false
                end
            },
            {
                index = 3,
                title = _("协助一次盟友建造加速"),
                isDesc = false,
                func = function()
                    if Alliance_Manager:GetMyAlliance():IsDefault() then
                        GameGlobalUI:showTips(_("错误"),_("你还未加入联盟"))
                        return false
                    end
                    UIKit:newGameUI("GameUIHelp"):AddToCurrentScene(true)
                    return false
                end
            },
            {
                index = 4,
                title = _("对盟友进行一次协防"),
                isDesc = true,
                func = function()
                    if Alliance_Manager:GetMyAlliance():IsDefault() then
                        GameGlobalUI:showTips(_("错误"),_("你还未加入联盟"))
                        return false
                    end
                    app:EnterMyAllianceScene()
                    return true
                end
            }
        },
        growUp = {
            {
                index = 1,
                title = _("加速一次正在升级的建筑"),
                isDesc = true,
                func = function()

                end
            },
            {
                index = 2,
                title = _("加速一支正在招募的兵种"),
                isDesc = true,
                func = function()
                    return true
                end
            },
            {
                index = 3,
                title = _("打造一件龙的装备"),
                isDesc = false,
                func = function()
                    local blackSmith = City:GetFirstBuildingByType("blackSmith")
                    if blackSmith:IsUnlocked() then
                        UIKit:newGameUI("GameUIBlackSmith",City,blackSmith,"redDragon"):AddToCurrentScene(true)
                        return false
                    else
                        GameGlobalUI:showTips(_("错误"),_("你还未建造铁匠铺"))
                        return false
                    end
                end
            },
            {
                index = 4,
                title = _("在商店购买任意一个道具"),
                isDesc = false,
                func = function()
                    UIKit:newGameUI("GameUIItems",City,"shop"):AddToCurrentScene(true)
                    return false
                end
            }
        }
    }
    return config
end


function GameUIDailyMissionInfo:OnDailyTasksChanged()
    self:RefreshListUI()
end

function GameUIDailyMissionInfo:onExit()
    User:RemoveListenerOnType(self,User.LISTEN_TYPE.DAILY_TASKS)
    GameUIDailyMissionInfo.super.onExit(self)
end

function GameUIDailyMissionInfo:GetKeyOfDaily()
    return self.key_of_daily
end

return GameUIDailyMissionInfo
-- 608x630


