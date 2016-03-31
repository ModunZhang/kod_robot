--
-- Author: gaozhou
-- Date: 2014-08-18 14:33:28
--
local window = import("..utils.window")
local WidgetProgress = import("..widget.WidgetProgress")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetInfoWithTitle = import("..widget.WidgetInfoWithTitle")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local StarBar = import("..ui.StarBar")
local UILib = import(".UILib")
local Localize = import("..utils.Localize")
local intInit = GameDatas.PlayerInitData.intInit
local WidgetInfo = import("..widget.WidgetInfo")
local dailyQuests_config = GameDatas.DailyQuests.dailyQuests
local dailyQuestStar_config = GameDatas.DailyQuests.dailyQuestStar
local GameUITownHall = UIKit:createUIClass("GameUITownHall", "GameUIUpgradeBuilding")
function GameUITownHall:ctor(city, townHall,default_tab)
    GameUITownHall.super.ctor(self, city, _("市政厅"), townHall,default_tab)
    self.town_hall_city = city
    self.town_hall = townHall
end
function GameUITownHall:OnMoveInStage()
    GameUITownHall.super.OnMoveInStage(self)
    self:CreateDwelling()
    self:TabButtons()
    self:UpdateDwellingCondition()
end
function GameUITownHall:onExit()
    User:RemoveListenerOnType(self, "dailyQuests")
    User:RemoveListenerOnType(self, "dailyQuestEvents")
    User:RemoveListenerOnType(self, "buildingEvents")
    GameUITownHall.super.onExit(self)
end


function GameUITownHall:UpdateDwellingCondition()
    local cur = #self.town_hall_city:GetHousesAroundFunctionBuildingByType(self.town_hall, "dwelling", 2)
    self.dwelling:GetLineByIndex(1):SetCondition(cur, 6)
    self.dwelling:GetLineByIndex(2):SetCondition(cur, 3)
end

function GameUITownHall:TabButtons()
    self:CreateTabButtons({
        {
            label = _("市政"),
            tag = "administration",
        }
    },
    function(tag)
        if tag == 'upgrade' then
            self.admin_layer:setVisible(false)
        elseif tag == "administration" then
            self.admin_layer:setVisible(true)
            if not self.quest_list_view then
                self:CreateAdministration()
            end
        end
    end):pos(window.cx, window.bottom + 34)
end
function GameUITownHall:CreateDwelling()
    local admin_layer = display.newLayer():addTo(self:GetView()):pos(window.left+20,window.bottom_top+10)
    admin_layer:setContentSize(cc.size(layer_width,layer_height))
    local layer_width,layer_height = 600,window.betweenHeaderAndTab
    self.dwelling = self:CreateDwellingItemWithListView():addTo(admin_layer):align(display.TOP_CENTER,layer_width/2,layer_height-60)
    self.admin_layer = admin_layer
end
function GameUITownHall:CreateAdministration()
    self.quest_items = {}
    local admin_layer = self.admin_layer

    local layer_width,layer_height = 600,window.betweenHeaderAndTab


    -- 每日任务
    UIKit:ttfLabel({
        text = _("每日任务"),
        size = 22,
        color = 0x403c2f,
    }):align(display.CENTER, layer_width/2, 600):addTo(admin_layer)


    -- 刷新倒计时
    UIKit:ttfLabel({
        text = _("刷新时间"),
        size = 22,
        color = 0x00900e,
    }):align(display.RIGHT_CENTER, layer_width/2-10, 570):addTo(admin_layer)

    -- 把上次刷新时间缓存到UI
    local refresh_time = UIKit:ttfLabel({
        text = (User:GetNextDailyQuestsRefreshTime()-app.timer:GetServerTime()) > 0 and GameUtils:formatTimeStyle1(User:GetNextDailyQuestsRefreshTime()-app.timer:GetServerTime()) or _("更新中"),
        size = 22,
        color = 0x00900e,
    }):align(display.LEFT_CENTER, layer_width/2+10, 570):addTo(admin_layer)
    self.refresh_time = refresh_time
    local list_view ,listnode=  UIKit:commonListView({
        viewRect = cc.rect(0,0, layer_width, layer_height-280),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    listnode:align(display.BOTTOM_CENTER, layer_width/2, 20):addTo(admin_layer)
    self.quest_list_view = list_view
    -- 获取任务
    User:AddListenOnType(self, "dailyQuests")
    User:AddListenOnType(self, "dailyQuestEvents")
    User:AddListenOnType(self, "buildingEvents")

    scheduleAt(self, function()
        local current_time = app.timer:GetServerTime()
        if self.refresh_time then
            if (User:GetNextDailyQuestsRefreshTime()-current_time) <= 0 then
                self:ResetQuest()
            else
                self.refresh_time:setString(GameUtils:formatTimeStyle1(User:GetNextDailyQuestsRefreshTime()-current_time))
            end
        end

        for __,item in pairs(self.quest_items) do
            local quest = item:GetQuest()
            if quest and User:IsQuestStarted(quest) and not User:IsQuestFinished(quest) then
                local show_time = quest.finishTime/1000-current_time <0 and 0 or quest.finishTime/1000-current_time
                item:SetProgress(GameUtils:formatTimeStyle1(show_time), 100-(quest.finishTime-current_time*1000)/(quest.finishTime-quest.startTime)*100 )
            end
        end
    end)
end

function GameUITownHall:CreateAllQuests(daily_quests)
    if daily_quests then
        for _,quest in pairs(daily_quests) do
            self:CreateQuestItem(quest)
        end
        self.quest_list_view:reload()
    end
end

function GameUITownHall:CreateQuestItem(quest,index)
    local quest_config = dailyQuests_config[quest.index]
    local list = self.quest_list_view
    local item = list:newItem()
    local item_width,item_height = 568,218
    item:setItemSize(item_width,item_height)

    local body = WidgetUIBackGround.new({width=item_width,height=item_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local b_size = body:getContentSize()
    local title_bg = display.newSprite("title_blue_554x34.png"):addTo(body):align(display.CENTER,b_size.width/2 , b_size.height-24)

    local star_bar = StarBar.new({
        max = 5,
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
        num = quest.star,
        margin = 0,
        direction = StarBar.DIRECTION_HORIZONTAL,
    }):addTo(title_bg):align(display.LEFT_CENTER,10, title_bg:getContentSize().height/2)

    -- 任务icon
    local icon_bg = display.newSprite("box_136x136.png"):addTo(body):pos(58,120):scale(110/136)
    display.newSprite(UILib.daily_quests_icon[quest.index])
        :addTo(icon_bg):pos(icon_bg:getContentSize().width/2,icon_bg:getContentSize().height/2)
        :scale(0.77)

    local status_label = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER,icon_bg:getPositionX()+ icon_bg:getContentSize().width - 50 , icon_bg:getPositionY()+20):addTo(body)
    local add_star_btn = WidgetPushButton.new(
        {normal = "add_btn_up_50x50.png", pressed = "add_btn_down_50x50.png"},
        {scale9 = false}
    )
        :addTo(title_bg):align(display.RIGHT_CENTER, title_bg:getContentSize().width-10, title_bg:getContentSize().height/2)
        :onButtonClicked(function(event)
            if intInit.dailyQuestAddStarNeedGemCount.value > User:GetGemValue() then
                UIKit:showMessageDialog(_("提示"),_("金龙币不足")):CreateOKButton(
                    {
                        listener = function ()
                            UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                            self:LeftButtonClicked()
                        end,
                        btn_name= _("前往商店")
                    })
            else
                if app:GetGameDefautlt():IsOpenGemRemind() then
                    UIKit:showConfirmUseGemMessageDialog(_("提示"),string.format(_("是否消费%s金龙币"),string.formatnumberthousands(intInit.dailyQuestAddStarNeedGemCount.value)), function()
                        NetManager:getAddDailyQuestStarPromise(quest.id)
                    end,true,true)
                else
                    NetManager:getAddDailyQuestStarPromise(quest.id)
                end
            end
        end):scale(0.6)

    -- gem icon
    local gem_icon = display.newSprite("gem_icon_62x61.png")
        :addTo(title_bg)
        :align(display.CENTER, title_bg:getContentSize().width-90, title_bg:getContentSize().height/2-2)
        :scale(0.6)
    local gem_label = UIKit:ttfLabel({
        text = string.formatnumberthousands(intInit.dailyQuestAddStarNeedGemCount.value),
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, title_bg:getContentSize().width-70, title_bg:getContentSize().height/2)
        :addTo(title_bg)

    local glass_icon = display.newSprite("hourglass_30x38.png")
        :align(display.RIGHT_CENTER,icon_bg:getPositionX()+ icon_bg:getContentSize().width - 40, icon_bg:getPositionY()-20)
        :addTo(body)
        :scale(0.8)

    local need_time_label = UIKit:ttfLabel({
        text = "222",
        size = 20,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER,icon_bg:getPositionX()+ icon_bg:getContentSize().width - 40, icon_bg:getPositionY()-20):addTo(body)

    local progress = WidgetProgress.new(0xffedae, "progress_bar_272x40_1.png", "progress_bar_272x40_2.png", {
        icon_bg = "back_ground_43x43.png",
        icon = "hourglass_30x38.png",
        bar_pos = {x = 0,y = 0}
    }):addTo(body):align(display.LEFT_CENTER, icon_bg:getPositionX()+ icon_bg:getContentSize().width-60, icon_bg:getPositionY()-20)

    local control_btn = WidgetPushButton.new()
        :align(display.RIGHT_CENTER,item_width-10,108)
        :addTo(body)

    local reward_bg = display.newScale9Sprite("back_ground_166x84.png", item_width/2,34,cc.size(548,52),cc.rect(15,10,136,64)):addTo(body)

    local TownHallUI = self
    function item:SetStar(quest)
        star_bar:setNum(quest.star)
        if quest.star == 5 then
            add_star_btn:hide()
            gem_icon:hide()
            gem_label:hide()
        end
        return self
    end
    function item:SetStatus(quest)
        local status = ""
        if User:IsQuestStarted(quest) then
            if User:IsQuestFinished(quest) then
                progress:setVisible(false)
                glass_icon:setVisible(false)
                status = _("任务完成")
                control_btn:setButtonImage(cc.ui.UIPushButton.NORMAL, "yellow_btn_up_148x58.png", true)
                control_btn:setButtonImage(cc.ui.UIPushButton.PRESSED,"yellow_btn_down_148x58.png", true)
                control_btn:removeEventListener(cc.ui.UIPushButton.CLICKED_EVENT)
                local total_rewards = self.total_rewards
                control_btn:setButtonLabel(
                    UIKit:commonButtonLable({
                        color = 0xfff3c7,
                        text  = _("获取奖励")
                    })
                ):onButtonClicked(function(event)
                    NetManager:getDailyQeustRewardPromise(quest.id):done(function ()
                        local re_desc = ""
                        for i,v in ipairs(total_rewards) do
                            re_desc = re_desc .. Localize.fight_reward[v.resource_type].."X".. string.formatnumberthousands(v.count) .." "
                        end
                        GameGlobalUI:showTips(_("每日任务完成"),_("获得")..re_desc)

                    end)
                end)
            else
                control_btn:setButtonImage(cc.ui.UIPushButton.NORMAL, "green_btn_up_148x58.png", true)
                control_btn:setButtonImage(cc.ui.UIPushButton.PRESSED,"green_btn_down_148x58.png", true)
                control_btn:removeEventListener(cc.ui.UIPushButton.CLICKED_EVENT)
                control_btn:setButtonLabel(
                    UIKit:commonButtonLable({
                        color = 0xfff3c7,
                        text  = _("加速")
                    })
                ):onButtonClicked(function(event)
                    UIKit:newGameUI("GameUIDailyQuestSpeedUp", quest):AddToCurrentScene()
                end)
                progress:setVisible(true)
                status = _("正在").." "..Localize.daily_quests_name[quest.index]
            end
            need_time_label:setVisible(false)
            add_star_btn:hide()
            gem_icon:hide()
            gem_label:hide()
        else
            control_btn:setButtonImage(cc.ui.UIPushButton.NORMAL, "yellow_btn_up_148x58.png", true)
            control_btn:setButtonImage(cc.ui.UIPushButton.PRESSED,"yellow_btn_down_148x58.png", true)
            control_btn:setButtonLabel(
                UIKit:commonButtonLable({
                    color = 0xfff3c7,
                    text  = _("开始")
                })
            ):onButtonClicked(function(event)
                if User:CouldGotDailyQuestReward() then
                    UIKit:showMessageDialog(_("主人"),_("请先领取已经完成的任务的奖励"))
                    return
                end
                if User:IsOnDailyQuestEvents() then
                    UIKit:showMessageDialog(_("主人"),_("已经有一个任务正在进行中"))
                    return
                end
                NetManager:getStartDailyQuestPromise(quest.id)
            end)

            add_star_btn:show()
            gem_icon:show()
            gem_label:show()
            status = Localize.daily_quests_name[quest.index]
            need_time_label:setString(GameUtils:formatTimeStyle1(dailyQuestStar_config[quest.star].needMinutes*60))
            progress:setVisible(false)
        end
        status_label:setString(status)
        return self
    end
    function item:SetProgress(time_label, percent)
        progress:SetProgressInfo(time_label, percent)
        return self
    end
    function item:SetReward(quest)
        local total_rewards = {}
        reward_bg:removeAllChildren()
        local quest = quest or self:GetQuest()
        local re_label = UIKit:ttfLabel({
            text = _("奖励"),
            size = 20,
            color = 0x403c2f,
        }):align(display.LEFT_CENTER,10,reward_bg:getContentSize().height/2):addTo(reward_bg)
        local rewards = dailyQuests_config[quest.index].rewards
        local origin_x = re_label:getPositionX()+re_label:getContentSize().width + 30
        for k,v in pairs(string.split(rewards,",")) do
            local re = string.split(v,":")
            local reward_icon = display.newSprite(UILib.resource[re[2]]):addTo(reward_bg):pos(origin_x+(k-1)*180,reward_bg:getContentSize().height/2)
            local max = math.max(reward_icon:getContentSize().width,reward_icon:getContentSize().height)
            reward_icon:scale(36/max)

            local reward_count = re[3]*quest.star*(1+0.2*TownHallUI.town_hall:GetLevel())
            table.insert(total_rewards, {resource_type=re[2],count = reward_count})
            UIKit:ttfLabel({
                text = string.formatnumberthousands(reward_count),
                size = 20,
                color = 0x403c2f,
            }):align(display.LEFT_CENTER,reward_icon:getPositionX()+30,reward_bg:getContentSize().height/2):addTo(reward_bg)
        end
        self.total_rewards = total_rewards
        return self
    end
    function item:BindQuest(quest )
        self.quest = quest
    end
    function item:GetQuest()
        return self.quest
    end
    function item:Init(quest)
        self:BindQuest(quest)
        self:SetReward(quest)
        self:SetStar(quest)
        need_time_label:setString(GameUtils:formatTimeStyle1(dailyQuestStar_config[quest.star].needMinutes*60))
    end
    item:Init(quest)
    item:SetStatus(quest)

    item:addContent(body)
    list:addItem(item,index)

    self.quest_items[quest.id] = item
end

function GameUITownHall:CreateDwellingItemWithListView()
    local widget = WidgetInfoWithTitle.new({
        title = _("周围2格范围的住宅数量"),
        h = 146,
    }):align(display.CENTER)
    local size = widget:getContentSize()
    local lineItems = {}
    for i, v in ipairs({1,2}) do
        table.insert(lineItems, self:CreateDwellingLineItem(520,i==1):addTo(widget.info_bg, 2)
            :pos(size.width/2-4, 31+(i-1)*40))
    end

    function widget:GetLineByIndex(index)
        return lineItems[index]
    end
    return widget
end


function GameUITownHall:CreateDwellingLineItem(width,flag)
    local left, right = 0, width
    local node =   display.newScale9Sprite(flag and "back_ground_548x40_1.png" or "back_ground_548x40_2.png")
    node:size(520,40)
    local condition = cc.ui.UILabel.new({
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x615b44)
    }):addTo(node, 2):align(display.LEFT_CENTER, left + 10, 20)

    cc.ui.UILabel.new({
        text = _("增加 5% 银币增长"),
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(node, 2):align(display.RIGHT_CENTER, right - 55, 20)

    local check = cc.ui.UICheckBoxButton.new({on = "yes_40x40.png", off = "no_40x40.png" })
        :addTo(node)
        :align(display.CENTER, right - 20, 20)
        :setButtonSelected(true)
    check:setTouchEnabled(false)

    function node:align()
        assert("you should not use this function for any purpose!")
    end
    function node:SetCondition(current, max)
        local str = string.format(_("达到 %d/%d"), current > max and max or current, max)
        condition:setString(str)
        check:setButtonSelected(max <= current)
        return self
    end
    return node
end
function GameUITownHall:GetQuestItemById(questId)
    return self.quest_items[questId]
end
function GameUITownHall:RemoveQuestItemById( questId )
    local item = self.quest_items[questId]
    self.quest_list_view:removeItem(item)
    self.quest_items[questId]  = nil
end
function GameUITownHall:ResetQuest()
    self.quest_items = {}
    self.quest_list_view:removeAllItems()
    self:CreateAllQuests(User:GetDailyQuests())
end
function GameUITownHall:OnUserDataChanged_dailyQuests(userData, deltaData)
    if deltaData("dailyQuests.refreshTime") 
        and deltaData("dailyQuests.quests") then
        self:ResetQuest()
    end

    local ok, value = deltaData("dailyQuests.quests.add")
    if ok then
        for k,v in pairs(value) do
            self:CreateQuestItem(v)
        end
    end

    local ok, value = deltaData("dailyQuests.quests.edit")
    if ok then
        for k,v in pairs(value) do
            local quest_item = self:GetQuestItemById(v.id)
            quest_item:Init(v)
        end
    end

    local ok, value = deltaData("dailyQuests.quests.remove")
    if ok then
        for k,v in pairs(value) do
            self:RemoveQuestItemById(v.id)
        end
    end
end
function GameUITownHall:OnUserDataChanged_dailyQuestEvents(userData, deltaData)
    local ok, value = deltaData("dailyQuestEvents.add")
    if ok then
        self:performWithDelay(function ()
            local finished_quest_num = 0
            for k,v in pairs(self.quest_items) do
                if User:IsQuestFinished(v:GetQuest()) then
                    finished_quest_num = finished_quest_num + 1
                end
            end
            for k,v in pairs(value) do
                self:CreateQuestItem(v,finished_quest_num+1)
            end
            self.quest_list_view:reload()
        end, 0.3)
    end

    local ok, value = deltaData("dailyQuestEvents.edit")
    if ok then
        for k,v in pairs(value) do
            local quest_item = self:GetQuestItemById(v.id)
            quest_item:Init(v)
            self.quest_items[v.id]:SetStatus(v)
        end
    end

    local ok, value = deltaData("dailyQuestEvents.remove")
    if ok then
        for k,v in pairs(value) do
            self:RemoveQuestItemById(v.id)
        end
    end
end
function GameUITownHall:OnUserDataChanged_buildingEvents(userData, deltaData)
    for k,v in pairs(self.quest_items) do
        v:SetReward()
    end
end

return GameUITownHall















