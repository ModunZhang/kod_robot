--
-- Author: Danny He
-- Date: 2015-03-05 16:11:11
--
local UIKit = UIKit
local GameUIMission = UIKit:createUIClass("GameUIMission","GameUIWithCommonHeader")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local WidgetGrowUpTask = import('..widget.WidgetGrowUpTask')
local WidgetBackGroundTabButtons = import('..widget.WidgetBackGroundTabButtons')
local window = import("..utils.window")
local Enum = import("..utils.Enum")
local scheduler = import(cc.PACKAGE_NAME .. ".scheduler")
local UIScrollView = import(".UIScrollView")
local WidgetPushButton = import("..widget.WidgetPushButton")
local Localize = import("..utils.Localize")
local UILib = import(".UILib")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local KEYS_OF_DAILY = {"empireRise","conqueror","brotherClub","growUp"}
local GameUIDailyMissionInfo = import(".GameUIDailyMissionInfo")

GameUIMission.MISSION_TYPE = Enum("achievement","daily")



function GameUIMission:OnUserDataChanged_dailyTasks(userData, deltaData)
    self:RefreshDisplayGreenPoint()
    if not self:CurrentIsDailyMission() then return end
    local changed_task_types = {}
    for k,v in pairs(userData.dailyTasks) do
        table.insert(changed_task_types, k)
    end
    for __,v in ipairs(changed_task_types) do
        self:RefreshDailyList(v)
    end
end
function GameUIMission:OnUserDataChanged_growUpTasks()
    self:RefreshAchievementList()
end




function GameUIMission:ctor(city,mission_type, need_tips)
    GameUIMission.super.ctor(self,city, _("任务"))
    self.city = city
    self.need_tips = need_tips
    self.init_mission_type = mission_type or self.MISSION_TYPE.achievement
    self.action_node = display.newNode():addTo(self)
end
function GameUIMission:OnMoveInStage()
    self:CreateTabButtons()
    self.city:GetUser():AddListenOnType(self, "growUpTasks")
    self.city:GetUser():AddListenOnType(self, "dailyTasks")
    GameUIMission.super.OnMoveInStage(self)
end
function GameUIMission:OnMoveOutStage()
    self.city:GetUser():RemoveListenerOnType(self, "growUpTasks")
    self.city:GetUser():RemoveListenerOnType(self, "dailyTasks")
    GameUIMission.super.OnMoveOutStage(self)
end
function GameUIMission:CreateTabButtons()
    local tab_buttons = WidgetBackGroundTabButtons.new({
        {
            label = _("成就任务"),
            tag = "achievement",
            default = self.init_mission_type == self.MISSION_TYPE.achievement,
        },
        {
            label = _("日常任务"),
            tag = "daily",
            default = self.init_mission_type == self.MISSION_TYPE.daily,
        }
    },
    function(tag)
        self:OnTabButtonClicked(tag)
    end):addTo(self:GetView()):pos(window.cx, window.bottom + 34)
    self.tab_buttons = tab_buttons
    self:RefreshDisplayGreenPoint()
end

function GameUIMission:OnTabButtonClicked(tag)
    if self.current_ui then
        self.current_ui:hide()
    end
    if self['CreateUIIf_' .. tag] then
        self.current_ui = self['CreateUIIf_' .. tag](self)
        self.current_ui:show()
        self.current_mission_type = self.MISSION_TYPE[tag]
    end
end

function GameUIMission:CurrentIsDailyMission()
    return self.current_mission_type == self.MISSION_TYPE.daily
end
--成就任务
----------------------------------------------------------------------
function GameUIMission:CreateUIIf_achievement()
    if self.achievement_layer then
        --refresh list and recommend mission
        self:RefreshRecommendMissionDesc()
        self:RefreshAchievementList()
        return self.achievement_layer
    end
    local layer = self:GetCommentBgNode():addTo(self.main_ui)
    self.achievement_layer = layer
    local header_bg = display.newSprite("mission_header_bg_616x184.jpg")
        :align(display.LEFT_TOP, 0, layer:getContentSize().height)
        :addTo(layer)
    header_bg:setTouchEnabled(true)
    header_bg:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        local p = header_bg:convertToNodeSpace(cc.p(event.x, event.y))
        if cc.rectContainsPoint(cc.rect(0,0,172,184),p) then
            self:OnRecommendMissionClicked()
        end
        return false
    end)
    self.info_icon = display.newSprite("mission_i_38x42.png")
        :align(display.LEFT_BOTTOM, 10, 128)
        :addTo(header_bg)
    local recommend_contet_bg = display.newSprite("recommend_misson_bg_438x158.png")
        :align(display.LEFT_BOTTOM, 176,12)
        :addTo(header_bg)
    UIKit:ttfLabel({
        text = _("赛琳娜:"),
        size = 24,
        color= 0x403c2f
    }):align(display.LEFT_BOTTOM, 28, 112):addTo(recommend_contet_bg)
    UIKit:ttfLabel({
        text = _("大人,我们现在应该:"),
        size = 20,
        color= 0x403c2f
    }):align(display.LEFT_BOTTOM, 28, 82):addTo(recommend_contet_bg)
    self.recommend_desc_label = UIKit:ttfLabel({
        text = self:GetRecommendMissionDesc(),
        size = 24,
        color= 0x403c2f
    }):align(display.LEFT_BOTTOM, 34, 28):addTo(recommend_contet_bg)
    display.newSprite("line_624x58.png")
        :align(display.CENTER_TOP, 308, 16)
        :addTo(header_bg)
    local list,list_node = UIKit:commonListView({
        viewRect = cc.rect(0, 0,558,584),
        direction = UIScrollView.DIRECTION_VERTICAL,
    })
    list:onTouch(handler(self, self.listviewListener))
    self.achievement_list = list
    list_node:addTo(layer):pos((layer:getContentSize().width - 558)/2,14)
    self:SchedulerInfo()
    self:RefreshAchievementList()
    return self.achievement_layer
end

function GameUIMission:GetCommentBgNode()
    local layer = display.newNode():pos(window.left + 12,window.bottom_top + 5)
    layer:size(window.width - 24,window.betweenHeaderAndTab + 15)
    return layer
end

function GameUIMission:CreateBetweenBgAndTitle()
    GameUIMission.super.CreateBetweenBgAndTitle(self)
    local layer = display.newNode():pos(0,0):addTo(self:GetView())
    layer:size(window.width,window.height)
    self.main_ui = layer
end

function GameUIMission:SchedulerInfo()
    self:ShakeInfoIcon()
    self.action_node:schedule(handler(self, self.ShakeInfoIcon), 5)
end

function GameUIMission:ShakeInfoIcon()
    local action = self:GetShakeAction()
    self.info_icon:runAction(action)
end

function GameUIMission:GetShakeAction()
    local t = 0.025
    local r = 5
    local action = transition.sequence({
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, -r),
        cc.RotateBy:create(t, r),
    })
    return action
end
function GameUIMission:RefreshAchievementList()
    self.achievement_list:removeAllItems()
    local header = self:GetGetAchievementListHeaderItem(true)
    self.achievement_list:addItem(header)
    local finished_mission = self:GetAchievementMissionData(true)
    for i,v in ipairs(finished_mission) do
        local item = self:GetAchievementListItem(true,v)
        self.achievement_list:addItem(item)
        if i == 1 and self.need_tips then
            WidgetFteArrow.new(_("点击领取奖励"))
            :addTo(item:getContent().button)
            :TurnRight():align(display.RIGHT_CENTER, -150, 0)
        end
    end
    header = self:GetGetAchievementListHeaderItem(false)
    self.achievement_list:addItem(header)
    local todo_mission = self:GetAchievementMissionData(false)
    for __,v in ipairs(todo_mission) do
        local item = self:GetAchievementListItem(false,v)
        self.achievement_list:addItem(item)
    end
    self.achievement_list:reload()
end

function GameUIMission:GetAchievementListItem(isFinished,data)
    local item = self.achievement_list:newItem()
    local content = UIKit:CreateBoxWithoutContent()
    UIKit:ttfLabel({
        text = isFinished and data:Title() or data:Desc(),
        size = 22,
        color= 0x403c2f
    }):align(display.LEFT_CENTER, 5, 33):addTo(content)
    if not isFinished then
        display.newSprite("next_32x38.png"):align(display.RIGHT_CENTER, 548, 33):addTo(content)
    else
        content.button = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
            :align(display.RIGHT_CENTER, 552, 33)
            :addTo(content)
            :setButtonLabel("normal", UIKit:commonButtonLable({
                text = _("领取")
            }))
            :onButtonClicked(function()
                self:OnGetAchievementRewardButtonClicked(data)
            end)
    end
    item:addContent(content)
    item:setMargin({left = 0, right = 0, top = 0, bottom = 5})
    item:setItemSize(558,66,false)
    return item
end

function GameUIMission:GetGetAchievementListHeaderItem(isFinished)
    local item = self.achievement_list:newItem()
    local content = display.newSprite(isFinished and "title_green_558x34.png" or "title_blue_554x34.png")
    UIKit:ttfLabel({
        text = isFinished and _("已完成任务") or _("成就任务"),
        size = 22,
        color= 0xffedae
    }):align(display.CENTER, 279, 17):addTo(content)
    item:addContent(content)
    item:setMargin({left = 0, right = 0, top = 5, bottom = 10})
    item:setItemSize(558, 34,false)
    return item
end

function GameUIMission:listviewListener(event)
    local listView = event.listView
    if "clicked" == event.name then
        local pos = event.itemPos
        if not pos then
            return
        end
        --这里减掉两个标题item
        local really_pos = pos - 2 - #self:GetAchievementMissionData(true)
        if really_pos > 0 then
            local data = self:GetAchievementMissionData(false)[really_pos]
            app:GetAudioManager():PlayeEffectSoundWithKey("NORMAL_DOWN")
            self:OnTodoAchievementMissionClicked(data)
        end
    end
end

function GameUIMission:RefreshRecommendMissionDesc()
    if self.recommend_desc_label then
        self.recommend_desc_label:setString(self:GetRecommendMissionDesc())
    end
end

-- TODO:
function GameUIMission:GetRecommendMissionDesc()
    local task = self.city:GetRecommendTask()
    if task then
        return task:Title()
    end
    return _("当前没有推荐任务!")
end

function GameUIMission:GetAchievementMissionData(isFinish)
    isFinish = type(isFinish) == 'boolean' and isFinish or false
    if isFinish then
        local tasks = UtilsForTask:GetFirstCompleteTasks(self.city:GetUser().growUpTasks)
        local i1, i2, i3 = unpack(tasks)
        return {i1, i2, i3}
    else
        return UtilsForTask:GetAvailableTasksGroup(self.city:GetUser().growUpTasks)
    end
end
function GameUIMission:OnGetAchievementRewardButtonClicked(data)
    self.need_tips = false
    NetManager:getGrowUpTaskRewardsPromise(data:TaskType(), data.id):done(function()
        GameGlobalUI:showTips(_("获得奖励"), data:GetRewards())
        if not self.is_hooray_on then
            self.is_hooray_on = true
            app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")

            self:performWithDelay(function()
                self.is_hooray_on = false
            end, 1.5)
        end
    end)
    self:RefreshRecommendMissionDesc()
end

function GameUIMission:OnTodoAchievementMissionClicked(data)
    UIKit:newWidgetUI("WidgetGrowUpTask", data):AddToCurrentScene(true)
end

function GameUIMission:OnRecommendMissionClicked()
    UIKit:newGameUI("GameUISelenaQuestion"):AddToCurrentScene(true)
end

--日常任务
function GameUIMission:CreateUIIf_daily()
    print("CreateUIIf_daily---->")
    if self.daily_layer then
        --refresh list
        self:RefreshDailyList()
        return self.daily_layer
    end
    local layer = self:GetCommentBgNode():addTo(self.main_ui)
    self.daily_layer = layer
    local list,list_node = UIKit:commonListView({
        viewRect = cc.rect(0, 0,568,layer:getContentSize().height - 40),
        direction = UIScrollView.DIRECTION_VERTICAL,
    })
    list:onTouch(handler(self, self.dailyListviewListener))
    list_node:addTo(layer):pos((layer:getContentSize().width - 568)/2,14)
    self.daily_list = list
    self:RefreshDailyList()
    return self.daily_layer
end


function GameUIMission:GetDailyListData()
    local r = {}
    local dailyTasks = self.city:GetUser():GetAllDailyTasks()
    for __,v in ipairs(KEYS_OF_DAILY) do
        local text_table = Localize.daily_tasks[v]
        local tmp_data = dailyTasks[v]
        if text_table and tmp_data then
            table.insert(r,{category = v,percent = #tmp_data/4,title = text_table.title ,image = UILib.daily_task_icon[v],desc = text_table.desc})
        end
    end
    return r
end

function GameUIMission:RefreshDailyListWithItemAndKeyOfDaily(item,key_of_daily)
    local tmp_data = self.city:GetUser():GetDailyTasksInfo(key_of_daily)
    local percent = #tmp_data/4
    if User:CheckDailyTasksWasRewarded(key_of_daily) then
        item.finfish_tip_label:show()
        item.progress_bg:hide()
    else
        item.finfish_tip_label:hide()
        item.progress_bg:show()
        item.progress:setPercentage(100 * percent)
    end
end

function GameUIMission:RefreshDailyList(key_of_daily)
    if key_of_daily and #self.daily_list:getItems() > 0 then
        local index = table.indexof(KEYS_OF_DAILY, key_of_daily)
        local item = self.daily_list:getItems()[index]
        if item then
            self:RefreshDailyListWithItemAndKeyOfDaily(item,key_of_daily)
        end
    else
        self.daily_list:removeAllItems()
        local  data = self:GetDailyListData()
        for __,v in ipairs(data) do
            local item = self:GetDailyItem(v)
            self.daily_list:addItem(item)
        end
        self.daily_list:reload()
    end
end

function GameUIMission:GetDailyItem(data)
    local item = self.daily_list:newItem()
    local content = WidgetUIBackGround.new({width = 568,height = 154},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local flag_box = display.newScale9Sprite("alliance_item_flag_box_126X126.png"):align(display.LEFT_CENTER, 8, 77):addTo(content):size(134,134)
    local icon_bg = display.newSprite("technology_bg_116x116.png", 67, 67):addTo(flag_box)
    local offset = cc.p(0,6)
    display.newSprite(data.image, 58 + offset.x, 58 + offset.y):addTo(icon_bg)
    local header = display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(412,30), cc.rect(10,10,410,10))
        :align(display.LEFT_BOTTOM, 146, 112)
        :addTo(content)
    UIKit:ttfLabel({
        size = 22,
        color= 0xffedae,
        text = data.title
    }):align(display.LEFT_CENTER, 8, 15):addTo(header)

    UIKit:ttfLabel({
        text = data.desc,
        size = 20,
        color= 0x403c2f,
        dimensions = cc.size(400,0)
    }):align(display.LEFT_CENTER, 156, 78):addTo(content)
    local progress_bg,progress =  self:GetProgressBar()
    local finfish_tip_label = UIKit:ttfLabel({
        text = _("今日的任务已经全部完成！"),
        size = 20,
        color= 0x007c23
    }):align(display.LEFT_BOTTOM, 156, 22):addTo(content)
    item.finfish_tip_label = finfish_tip_label
    item.progress = progress
    item.progress_bg = progress_bg
    progress_bg:align(display.LEFT_BOTTOM, 154, 12):addTo(content)
    -- if data.percent >= 1 then
    if User:CheckDailyTasksWasRewarded(data.category) then
        finfish_tip_label:show()
        progress_bg:hide()
    else
        finfish_tip_label:hide()
        progress_bg:show()
        progress:setPercentage(100 * data.percent)
    end

    display.newSprite("next_32x38.png"):align(display.LEFT_CENTER, 530, 77):addTo(content)


    item:addContent(content)
    item:setMargin({left = 0, right = 0, top = 0, bottom = 4})
    item:setItemSize(568,154,false)
    return item
end

function GameUIMission:GetProgressBar()
    local bg = display.newSprite("mission_progress_bar_bg_348x40.png")
    local progress = UIKit:commonProgressTimer("mission_progress_bar_content_348x40.png"):align(display.LEFT_CENTER, 0, 20):addTo(bg)
    local box = display.newSprite("mission_progress_bar_box_348x40.png"):align(display.LEFT_CENTER, 0, 20):addTo(bg)
    display.newSprite("Icon_reward_174x141.png"):align(display.LEFT_CENTER, 310, 20):addTo(box):scale(48/174)
    return bg,progress
end

function GameUIMission:RefreshDisplayGreenPoint()
    if not self.tab_buttons then return end
    local count = 0
    for __,key_of_daily in ipairs(KEYS_OF_DAILY) do
        local tmp_data = self.city:GetUser():GetDailyTasksInfo(key_of_daily)
        local percent = #tmp_data/4
        if percent < 1 then
            count = count + 1
        end
    end
    self.tab_buttons:SetButtonTipNumber("daily",count)
end




function GameUIMission:dailyListviewListener(event)
    local listView = event.listView
    if "clicked" == event.name then
        local pos = event.itemPos
        local keys_of_daily = KEYS_OF_DAILY[pos]
        if not keys_of_daily then return end
        app:GetAudioManager():PlayeEffectSoundWithKey("NORMAL_DOWN")
        UIKit:newGameUI("GameUIDailyMissionInfo",keys_of_daily):AddToCurrentScene(true)
    end
end


function GameUIMission:onCleanup()
    GameUIMission.super.onCleanup(self)
    cc.Director:getInstance():getTextureCache():removeTextureForKey("mission_header_bg_616x184.jpg")
end


-- fte
local promise = import("..utils.promise")
function GameUIMission:Find()
    return self.achievement_list.items_[2]:getContent().button
end
function GameUIMission:PromiseOfFte()
    self.achievement_list:getScrollNode():setTouchEnabled(false)
    self:Find():setTouchSwallowEnabled(true)
    self:GetFteLayer():SetTouchObject(self:Find())
    local r = self:Find():getCascadeBoundingBox()
    self:GetFteLayer().arrow = WidgetFteArrow.new(_("点击领取奖励"))
        :addTo(self:GetFteLayer())
        :TurnRight():align(display.RIGHT_CENTER, r.x - 10, r.y + r.height/2)

    return self.city:GetUser():PromiseOfGetCityBuildRewards():next(function()
        return self:PromsieOfExit("GameUIMission")
    end)
end





return GameUIMission




