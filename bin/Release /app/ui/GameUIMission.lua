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
local Localize_item = import("..utils.Localize_item")
local UILib = import(".UILib")
local UIListView = import(".UIListView")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local dailyTasksConfig = GameDatas.PlayerInitData.dailyTasks
local dailyTaskRewardsConfig = GameDatas.PlayerInitData.dailyTaskRewards

GameUIMission.MISSION_TYPE = Enum("achievement","daily")



function GameUIMission:OnUserDataChanged_dailyTasks(userData, deltaData)
    if not self:CurrentIsDailyMission() then return end
    self:RefreshDailyList()
    local points = self:GetDailyTasksFinishedPoints()
    self.dailyTaskRewardCount_progress:setPercentage(points/200 * 100)
    self.my_points:setString(string.format(_("我的积分:%d"),points))
end
function GameUIMission:OnUserDataChanged_countInfo()
    local points = self:GetDailyTasksFinishedPoints()
    self.dailyTaskRewardCount_progress:setPercentage(points/200 * 100)
    self.boxed_node:RefreshBoxes()
    self:RefreshDisplayGreenPoint()
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
    self.city:GetUser():AddListenOnType(self, "countInfo")
    GameUIMission.super.OnMoveInStage(self)
end
function GameUIMission:OnMoveOutStage()
    self.city:GetUser():RemoveListenerOnType(self, "growUpTasks")
    self.city:GetUser():RemoveListenerOnType(self, "dailyTasks")
    self.city:GetUser():RemoveListenerOnType(self, "countInfo")
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

function GameUIMission:GetShakeAction(t)
    local t = t or 0.025
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

    local header_bg = display.newSprite("mission_header_bg_nan_616x184.jpg")
        :align(display.LEFT_TOP, 0, layer:getContentSize().height)
        :addTo(layer)


    local recommend_contet_bg = display.newSprite("recommend_misson_bg_438x158.png")
        :align(display.LEFT_BOTTOM, 176,12)
        :addTo(header_bg)
    UIKit:ttfLabel({
        text = _("克里冈:"),
        size = 24,
        color= 0x403c2f
    }):align(display.LEFT_BOTTOM, 28, 112):addTo(recommend_contet_bg)
    UIKit:ttfLabel({
        text = _("大人,完成任务领取丰厚奖励:"),
        size = 20,
        color= 0x403c2f
    }):align(display.LEFT_BOTTOM, 28, 82):addTo(recommend_contet_bg)
    local daily_refresh_label = UIKit:ttfLabel({
        text = string.format(_("%s后刷新"),"00:10:10"),
        size = 24,
        color= 0x403c2f
    }):align(display.LEFT_BOTTOM, 34, 28):addTo(recommend_contet_bg)

    scheduleAt(self, function()
        local serverTime =  app.timer:GetServerTime()
        local c_year = os.date('!%Y',serverTime)
        local c_month = os.date('!%m',serverTime)
        local c_day = os.date('!%d',serverTime)
        local c_hour = os.date('!%H',serverTime)
        local c_second = os.date('!%S',serverTime)
        local c_time = os.time({year=c_year, month=c_month, day=c_day, hour=c_hour, sec=c_second})
        local year = os.date('!%Y',serverTime + 24 * 60 * 60 )
        local month = os.date('!%m', serverTime + 24 * 60 * 60 )
        local day = os.date('!%d', serverTime + 24 * 60 * 60 )
        daily_refresh_label:setString(string.format(_("%s后刷新"),GameUtils:formatTimeStyle1(os.time({year=year, month=month, day=day, hour=0, sec=0}) - c_time)))
    end)
    display.newSprite("line_624x58.png")
        :align(display.CENTER_TOP, 308, 16)
        :addTo(header_bg)

    local points = self:GetDailyTasksFinishedPoints()
    local my_points = UIKit:ttfLabel({
        text = string.format(_("我的积分:%d"),points),
        size = 22,
        color= 0x403c2f
    }):align(display.CENTER_TOP, layer:getContentSize().width/2, header_bg:getPositionY() - header_bg:getContentSize().height - 20):addTo(layer)
    self.my_points = my_points
    local progress_bg,progress =  self:GetProgressBar()
    progress_bg:align(display.CENTER_TOP, layer:getContentSize().width/2, my_points:getPositionY() - my_points:getContentSize().height - 16):addTo(layer)
    progress:setPercentage(points/200 * 100)
    self.dailyTaskRewardCount_progress = progress
    local boxed_node = self:GetRewardsNode():align(display.CENTER_TOP, layer:getContentSize().width/2 + 30, progress_bg:getPositionY() - progress_bg:getContentSize().height - 15):addTo(layer)
    self.boxed_node = boxed_node
    local list_node = WidgetUIBackGround.new({width = 540,height = 430},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
        :addTo(layer):pos((layer:getContentSize().width - 540)/2,14)
    -- list title
    local list_title_bg = display.newScale9Sprite("back_ground_548x40_1.png")
        :size(520,58)
        :align(display.TOP_CENTER, list_node:getContentSize().width/2, list_node:getContentSize().height - 9)
        :addTo(list_node)
    UIKit:ttfLabel({
        text = _("达成条件"),
        size = 20,
        color= 0x615b44
    }):align(display.LEFT_CENTER, 10, 29):addTo(list_title_bg)
    UIKit:ttfLabel({
        text = _("积分"),
        size = 20,
        color= 0x615b44
    }):align(display.CENTER, 320, 29):addTo(list_title_bg)
    UIKit:ttfLabel({
        text = _("进度"),
        size = 20,
        color= 0x615b44
    }):align(display.CENTER, 400, 29):addTo(list_title_bg)
    local list = UIListView.new({
        viewRect = cc.rect(0, 0,520,350),
        direction = UIScrollView.DIRECTION_VERTICAL,
    }):addTo(list_node):pos(10,12)
    list:onTouch(handler(self, self.dailyListviewListener))

    self.daily_list = list
    self:RefreshDailyList()
    return self.daily_layer
end


function GameUIMission:RefreshDailyList()
    self.daily_list:removeAllItems()
    local sort_dailyTasks = {}
    for k,task in pairs(dailyTasksConfig) do
        table.insert(sort_dailyTasks, task)
    end
    table.sort(sort_dailyTasks, function (a,b)
        return a.index < b.index
    end)

    for i,task in ipairs(sort_dailyTasks) do
        local item = self:GetDailyItem(task,i)
        self.daily_list:addItem(item)
    end
    self.daily_list:reload()
end

function GameUIMission:GetDailyItem(data,index)
    local item = self.daily_list:newItem()
    local task_name_desc_bg = UIKit:ttfLabel({
        text = Localize.daily_tasks[data.type],
        size = 20,
        color= 0x403c2f,
        dimensions = cc.size(240,0)
    })
    local content_height = task_name_desc_bg:getContentSize().height + 10
    content_height = content_height > 58 and content_height or 58
    local content = display.newScale9Sprite(string.format("back_ground_548x40_%d.png",index%2==0 and 1 or 2)):size(520,content_height)
    task_name_desc_bg:align(display.LEFT_CENTER, 10, content_height/2):addTo(content)

    -- 积分
    UIKit:ttfLabel({
        text = "+"..data.score,
        size = 20,
        color= 0x403c2f,
    }):align(display.CENTER, 320, content_height/2):addTo(content)

    -- 进度
    UIKit:ttfLabel({
        text = self.city:GetUser():GetDailyTasksFinishedCountByIndex(index).."/"..data.maxCount,
        size = 20,
        color= self.city:GetUser():GetDailyTasksFinishedCountByIndex(index) ~= data.maxCount and 0x403c2f or 0x007c23,
    }):align(display.CENTER, 400, content_height/2):addTo(content)
    display.newSprite("next_32x38.png"):align(display.RIGHT_CENTER, 510, content_height/2):addTo(content)

    item:addContent(content)
    item:setItemSize(520,content_height)
    return item
end

function GameUIMission:GetProgressBar()
    local bg = display.newSprite("mission_progress_bar_bg_530x44.png")
    local progress = UIKit:commonProgressTimer("mission_progress_bar_content_530x44.png"):align(display.LEFT_CENTER, 0, 20):addTo(bg)
    local box = display.newSprite("mission_progress_bar_box_530x44.png"):align(display.LEFT_CENTER, 0, 20):addTo(bg)
    return bg,progress
end
function GameUIMission:GetRewardsNode()
    local node = display.newNode()
    node:setContentSize(cc.size(500,40))
    local parent = self
    function node:RefreshBoxes()
        self:removeAllChildren()
        local gap_x = 100
        for i = 0,4 do
            local box_image
            local flag = 0 -- 0:不能领取 1:可以领取 2:已经领取
            if User.countInfo.dailyTaskRewardCount >= (i+1) then
                box_image = "icon_box_open_66x60.png"
                flag = 2
            else
                if parent:GetDailyTasksCanGetRewardCount() >= i then
                    box_image = "icon_box_light_66x60.png"
                    flag = 1
                else
                    box_image = "icon_box_grey_66x60.png"
                end
            end
            local btn = WidgetPushButton.new({normal = "background_74x28.png"})
                :align(display.LEFT_BOTTOM, i * gap_x , 0)
                :setButtonLabel("normal", UIKit:commonButtonLable({
                    text = dailyTaskRewardsConfig[i].score,
                    size = 18
                }))
                :setButtonLabelOffset(-14,0)
                :addTo(self)
                :onButtonClicked(function()
                    parent:OpenGetDailyRewardDialog(i,flag)
                end)
            local box = display.newSprite(box_image):addTo(btn):align(display.RIGHT_BOTTOM, 100, 0)
            box:setTouchEnabled(false)
            if User.countInfo.dailyTaskRewardCount == i and flag == 1 then
                local action = parent:GetShakeAction(0.1)
                box:runAction(
                    cc.RepeatForever:create(
                        action
                    )
                )
            end
        end
    end
    node:RefreshBoxes()
    return node
end
function GameUIMission:OpenGetDailyRewardDialog(reward_index,flag)
    local rewards = string.split(dailyTaskRewardsConfig[reward_index].rewards,";")
    local dialog = UIKit:newWidgetUI("WidgetPopDialog", #rewards * 130 + 140,_("奖励"),window.top-130):AddToCurrentScene(true)
    local body = dialog:GetBody()
    local size = body:getContentSize()
    local list_bg = display.newScale9Sprite("background_568x120.png",size.width/2,(#rewards * 130+24)/2+90,cc.size(568,#rewards * 130+22),cc.rect(10,10,548,100))
        :addTo(body)
    local show_msg = ""
    for i,re in ipairs(rewards) do
        local data = string.split(re,":")
        show_msg = show_msg .. Localize_item.item_name[data[2]] .. (i ~= #rewards and "," or "")

        local body_1 = display.newScale9Sprite(string.format("back_ground_548x40_%d.png",i%2==0 and 1 or 2),list_bg:getContentSize().width/2,list_bg:getContentSize().height - 10 - 65 - (i-1) * 130,cc.size(548,130),cc.rect(10,10,528,20)):addTo(list_bg)
        body_1:setNodeEventEnabled(true)
        local item_bg = display.newSprite("box_118x118.png"):addTo(body_1):pos(65,65)
        local item_icon = display.newSprite(UILib.item[data[2]]):addTo(item_bg):align(display.CENTER, item_bg:getContentSize().width/2, item_bg:getContentSize().height/2):scale(0.6)
        item_icon:scale(100/item_icon:getContentSize().width)

        -- 道具名称
        UIKit:ttfLabel({
            text = UtilsForItem:GetItemLocalize(data[2]),
            size = 24,
            color = 0x403c2f,
        }):addTo(body_1):align(display.LEFT_CENTER,130, body_1:getContentSize().height-22)
        -- 道具介绍
        UIKit:ttfLabel({
            text = UtilsForItem:GetItemDesc(data[2]),
            size = 20,
            color = 0x5c553f,
            dimensions = cc.size(260,0)
        }):addTo(body_1):align(display.LEFT_CENTER,130, body_1:getContentSize().height/2-10)

    end

    local btn = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
        :align(display.BOTTOM_CENTER, size.width/2, 24)
        :addTo(body)
        :setButtonLabel("normal", UIKit:commonButtonLable({
            text = _("领取")
        }))
        :onButtonClicked(function()
            if flag == 0 then
                UIKit:showMessageDialog(_("提示"),_("积分不足，不能领取奖励"))
                return
            elseif flag == 2 then
                UIKit:showMessageDialog(_("提示"),_("已经领取过奖励"))
                return
            end
            if User.countInfo.dailyTaskRewardCount ~= reward_index + 1 then
                UIKit:showMessageDialog(_("提示"),_("请首先领取前面的奖励"))
                return
            end
            NetManager:getDailyTaskRewards():done(function ()
                GameGlobalUI:showTips(_("获得奖励"),string.format(_("获得%s"),show_msg))
                dialog:LeftButtonClicked()
            end)
        end)
    btn:setButtonEnabled(flag == 1)

end
-- 获取当前能够领取日常任务奖励的数量
function GameUIMission:GetDailyTasksCanGetRewardCount()
    local points = self:GetDailyTasksFinishedPoints()
    local count = -1
    for i=0,4 do
        local reward = dailyTaskRewardsConfig[i]
        if points >= reward.score then
            count = i
        end
    end
    return count
end
function GameUIMission:GetDailyTasksFinishedPoints()
    local points = 0
    for k,task in pairs(dailyTasksConfig) do
        local user_task_data = self.city:GetUser():GetAllDailyTasks()[task.index + 1]
        if user_task_data and task.maxCount <= user_task_data then
            points = points + task.score
        end
    end
    return points
end
function GameUIMission:RefreshDisplayGreenPoint()
    if not self.tab_buttons then return end
    self.tab_buttons:SetButtonTipNumber("daily",self:GetDailyTasksCanGetRewardCount() - User.countInfo.dailyTaskRewardCount + 1)
end




function GameUIMission:dailyListviewListener(event)
    local city = self.city
    local listView = event.listView
    if "clicked" == event.name then
        local pos = event.itemPos
        if pos == 1 then
            UIKit:newGameUI("GameUIHasBeenBuild", city):AddToCurrentScene(true)
            self:LeftButtonClicked()
        elseif pos == 2 then
            UIKit:newGameUI("GameUIAcademy", city,city:GetFirstBuildingByType("academy"),"technology"):AddToCurrentScene(true)
            self:LeftButtonClicked()
        elseif pos == 3 then
            if self:IsBuildingUnLocked(17) or self:IsBuildingUnLocked(18) or self:IsBuildingUnLocked(19) or self:IsBuildingUnLocked(20) then
                app:EnterMyCityScene(false,"twinkle_military")
            else
                UIKit:showMessageDialog(_("提示"),_("请先升级城堡，解锁军事科技建筑"))
            end
        elseif pos == 4 then
            if self:IsBuildingUnLocked(16) then
                UIKit:newGameUI("GameUIToolShop", city,city:GetFirstBuildingByType("toolShop"),"manufacture","buildingMaterials"):AddToCurrentScene(true)
                self:LeftButtonClicked()
            else
                UIKit:showMessageDialog(_("提示"),_("请先升级城堡，解锁工具作坊"))
            end
        elseif pos == 5 then
            if self:IsBuildingUnLocked(16) then
                UIKit:newGameUI("GameUIToolShop", city,city:GetFirstBuildingByType("toolShop"),"manufacture","technologyMaterials"):AddToCurrentScene(true)
                self:LeftButtonClicked()
            else
                UIKit:showMessageDialog(_("提示"),_("请先升级城堡，解锁工具作坊"))
            end
        elseif pos == 6 then
            if Alliance_Manager:GetMyAlliance():IsDefault() then
                UIKit:showMessageDialog(_("提示"),_("你必须加入联盟后，才能参加圣地战"))
            else
                app:EnterMyAllianceScene({mapIndex = Alliance_Manager:GetMyAlliance().mapIndex,x = 13,y = 17,callback = function ( alliance_scene )
                    alliance_scene:TwinkleShrine()
                end})
            end
        elseif pos == 7 then
            if Alliance_Manager:GetMyAlliance():IsDefault() then
                UIKit:showMessageDialog(_("提示"),_("你必须加入联盟后，才能攻击其他玩家"))
            else
                app:EnterMyAllianceScene()
            end
        elseif pos == 8 then
            if Alliance_Manager:GetMyAlliance():IsDefault() then
                UIKit:showMessageDialog(_("提示"),_("你必须加入联盟后，才能占领村落"))
            else
                app:EnterMyAllianceScene()
            end
        elseif pos == 9 then
            local dragon_manger = city:GetDragonEyrie():GetDragonManager()
            local dragon_type = dragon_manger:GetCanFightPowerfulDragonType()
            if #dragon_type > 0 or dragon_manger:GetDefenceDragon() then
                app:EnterPVEScene(city:GetUser():GetLatestPveIndex())
            else
                UIKit:showMessageDialog(_("主人"),_("需要一条空闲状态的魔龙才能探险"))
            end
            app:GetAudioManager():PlayeEffectSoundWithKey("AIRSHIP")
        elseif pos == 10 then
            if Alliance_Manager:GetMyAlliance():IsDefault() then
                UIKit:showMessageDialog(_("提示"),_("你必须加入联盟后，才能进行捐赠"))
            else
                UIKit:newGameUI("GameUIAllianceContribute"):AddToCurrentScene(true)
                self:LeftButtonClicked()
            end
        elseif pos == 11 then
            if Alliance_Manager:GetMyAlliance():IsDefault() then
                UIKit:showMessageDialog(_("提示"),_("你必须加入联盟后，才能进入联盟商店"))
            else
                local building = Alliance_Manager:GetMyAlliance():FindAllianceBuildingInfoByName("shop")
                UIKit:newGameUI('GameUIAllianceShop',city,"goods",building):AddToCurrentScene(true)
                self:LeftButtonClicked()
            end
        elseif pos == 13 then
            if Alliance_Manager:GetMyAlliance():IsDefault() then
                UIKit:showMessageDialog(_("提示"),_("你必须加入联盟后，才能协防盟友"))
            else
                app:EnterMyAllianceScene()
            end
        elseif pos == 16 then
            UIKit:newGameUI("GameUIHospital", city,city:GetFirstBuildingByType("hospital"),"heal"):AddToCurrentScene(true)
        elseif pos == 17 then
            if self:IsBuildingUnLocked(9) then
                UIKit:newGameUI("GameUIBlackSmith", city,city:GetFirstBuildingByType("blackSmith")):AddToCurrentScene(true)
                self:LeftButtonClicked()
            else
                UIKit:showMessageDialog(_("提示"),_("请先升级城堡，解锁铁匠铺"))
            end
        elseif pos == 18 then
            UIKit:newGameUI("GameUIItems", city,"shop"):AddToCurrentScene(true)
            self:LeftButtonClicked()
        end
    end
end

-- 建筑是否解锁
function GameUIMission:IsBuildingUnLocked(location_id)
    local tile = City:GetTileByLocationId(location_id)
    local b_x,b_y =tile.x,tile.y
    -- 建筑是否已解锁
    return City:IsUnLockedAtIndex(b_x,b_y)
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


















