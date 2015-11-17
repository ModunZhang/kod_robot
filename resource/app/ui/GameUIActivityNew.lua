--
-- Author: Danny He
-- Date: 2015-05-12 10:52:45
--
local GameUIActivityNew = UIKit:createUIClass("GameUIActivityNew","GameUIWithCommonHeader")
local GameUtils = GameUtils
local UILib = import(".UILib")
local Enum = import("..utils.Enum")
local window = import("..utils.window")
local RichText = import("..widget.RichText")
local UIListView = import(".UIListView")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local User = User
local config_day14 = GameDatas.Activities.day14
local config_levelup = GameDatas.Activities.levelup
local config_intInit = GameDatas.PlayerInitData.intInit
local GameUIActivityRewardNew = import(".GameUIActivityRewardNew")
local WidgetPushButton = import("..widget.WidgetPushButton")
local Localize_item = import("..utils.Localize_item")
--异步列表按钮事件修复
GameUIActivityNew.ITEMS_TYPE = Enum("EVERY_DAY_LOGIN","CONTINUITY","FIRST_IN_PURGURE","PLAYER_LEVEL_UP")

local titles = {
    EVERY_DAY_LOGIN = _("每日登陆奖励"),
    CONTINUITY = _("王城援军"),
    FIRST_IN_PURGURE = _("首次充值奖励"),
    PLAYER_LEVEL_UP = _("新手冲级奖励"),
}

function GameUIActivityNew:ctor(city)
    GameUIActivityNew.super.ctor(self,city, _("活动"))
    local countInfo = User.countInfo
    self.player_level_up_time = countInfo.registerTime/1000 + config_intInit.playerLevelupRewardsHours.value * 60 * 60 -- 单位秒

    scheduleAt(self, function()
        local current_time = app.timer:GetServerTime()
        if self.activity_list_view and self.tab_buttons:GetSelectedButtonTag() == 'activity' then
            local count = #self.activity_list_view:getItems()
            local item = self.activity_list_view:getItems()[count]
            if item.item_type ~= self.ITEMS_TYPE.PLAYER_LEVEL_UP then return end
            if current_time <= self.player_level_up_time and item then
                if not item.time_label then return end
                self.player_level_up_time_residue = self.player_level_up_time - current_time
                if self.player_level_up_time_residue > 0 then
                    item.time_label:setString(GameUtils:formatTimeStyle1(self.player_level_up_time_residue))
                else
                    self.activity_list_view:removeItem(item)
                end
            end
        end
    end)
end


function GameUIActivityNew:onCleanup()
    User:RemoveListenerOnType(self, "countInfo")
    User:RemoveListenerOnType(self, "iapGifts")
    GameUIActivityNew.super.onCleanup(self)
end

function GameUIActivityNew:OnMoveInStage()
    GameUIActivityNew.super.OnMoveInStage(self)
    self.tab_buttons = self:CreateTabButtons(
        {
            {
                label = _("活动"),
                tag = "activity",
                default = true,
            },
            {
                label = _("奖励"),
                tag = "award",
            }
        },
        function(tag)
            self:OnTabButtonClicked(tag)
        end
    ):pos(window.cx, window.bottom + 34)
    self:RefreshAwardCountTips()
end


function GameUIActivityNew:OnTabButtonClicked(tag)
    local method_name = "CreateTabIf_" .. tag
    if self[method_name] then
        if self.current_content then self.current_content:hide() end
        self.current_content = self[method_name](self)
        self.current_content:show()
    end
end

function GameUIActivityNew:CreateTabIf_activity()
    self.player_level_up_time_residue = self.player_level_up_time - app.timer:GetServerTime()
    if not self.activity_list_view then
        local list = UIListView.new({
            direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
            viewRect = cc.rect(window.left+(window.width - 612)/2,window.bottom_top + 20,612,785),
        }):addTo(self:GetView())
        list:onTouch(handler(self, self.OnActivityListViewTouch))
        self.activity_list_view = list
        self:RefreshActivityListView()
        User:AddListenOnType(self, "countInfo")
    end
    self:RefreshActivityListView()
    return self.activity_list_view
end

function GameUIActivityNew:RefreshActivityListView()
    self.activity_list_view:removeAllItems()
    local countInfo = User.countInfo
    local item = self:GetActivityItem(self.ITEMS_TYPE.EVERY_DAY_LOGIN)
    self.activity_list_view:addItem(item)
    --
    if countInfo.day14RewardsCount < #config_day14 then
        item = self:GetActivityItem(self.ITEMS_TYPE.CONTINUITY)
        self.activity_list_view:addItem(item)
    end
    if not countInfo.isFirstIAPRewardsGeted then
        item = self:GetActivityItem(self.ITEMS_TYPE.FIRST_IN_PURGURE)
        self.activity_list_view:addItem(item)
    end
    if self.player_level_up_time - app.timer:GetServerTime() > 0 and not self:CheckFinishAllLevelUpActiIf() then
        item = self:GetActivityItem(self.ITEMS_TYPE.PLAYER_LEVEL_UP)
        self.activity_list_view:addItem(item)
    end
    self.activity_list_view:reload()
end

function GameUIActivityNew:CheckFinishAllLevelUpActiIf()
    local checkLevelInUserCountInfoRewards = function(level)
        local countInfo = User.countInfo
        for __,v in ipairs(countInfo.levelupRewards) do
            if v == level then
                return true
            end
        end
        return false
    end
    for __,v in ipairs(config_levelup) do
        if not checkLevelInUserCountInfoRewards(v.level) then
            return false

        end
    end
    return true
end
function GameUIActivityNew:OnUserDataChanged_iapGifts(changed_map)
    self:RefreshAwardCountTips()
    if self.award_list and self.tab_buttons:GetSelectedButtonTag() == 'award' then
        self:RefreshAwardList()
    end
end
function GameUIActivityNew:OnUserDataChanged_countInfo()
    self:RefreshActivityListView()
end

function GameUIActivityNew:OnActivityListViewTouch(event)
    if event.name == "clicked" and event.item then
        self:OnSelectActivityAtItem(event.item.item_type)
    end
end

function GameUIActivityNew:OnSelectActivityAtItem(item_type)
    app:GetAudioManager():PlayeEffectSoundWithKey("NORMAL_DOWN")
    UIKit:newGameUI("GameUIActivityRewardNew",GameUIActivityRewardNew.REWARD_TYPE[self.ITEMS_TYPE[item_type]]):AddToCurrentScene(true)
end

function GameUIActivityNew:GetFirstPurgureTips()
    local str = _("首次充值%s金额")
    local s,e = string.find(str,"%%s")
    return string.format("[{\"type\":\"text\", \"value\":\"%s\"},{\"type\":\"text\",\"color\":0xa2ff00,\"size\":22,\"value\":\"%s\"},{\"type\":\"text\", \"value\":\"%s\"}]",
        string.sub(str,1,s - 1),_("任意"),string.sub(str,e+1))
end

function GameUIActivityNew:GetActivityItem(item_type)
    local countInfo = User.countInfo
    local item = self.activity_list_view:newItem()
    item.item_type = item_type
    local bg = display.newSprite("activity_bg_612x198.png")
    local title_txt = titles[self.ITEMS_TYPE[item_type]]
    UIKit:ttfLabel({
        text = title_txt,
        size = 22,
        color= 0xfed36c
    }):align(display.CENTER_TOP,306, 188):addTo(bg)
    local content = display.newSprite(UILib.activity_image_config[self.ITEMS_TYPE[item_type]]):align(display.CENTER_BOTTOM,306, 12):addTo(bg)
    local size = content:getContentSize()
    if item_type ~= self.ITEMS_TYPE.EVERY_DAY_LOGIN then
        display.newSprite("activity_layer_blue_586x114.png"):align(display.RIGHT_CENTER, size.width,size.height/2+2):addTo(content)
    end
    display.newSprite("next_32x38.png"):align(display.LEFT_CENTER, 566, 80):addTo(bg)

    if item_type == self.ITEMS_TYPE.EVERY_DAY_LOGIN then
        local title_label = UIKit:ttfLabel({
            text = _("免费领取海量道具"),
            size = 20,
            color= 0xffedae,
            align = cc.TEXT_ALIGNMENT_LEFT,
            shadow= true
        }):align(display.LEFT_BOTTOM,268,92):addTo(bg)
        local sign_str,sign_color = _("已签到"),0xa2ff00
        if countInfo.day60 > countInfo.day60RewardsCount then
            sign_str = _("未签到")
            sign_color = 0xff4e00
        end
        local sign_bg = display.newSprite("activity_day_bg_104x34.png")
            :align(display.LEFT_BOTTOM,441,50)
            :addTo(bg)
        local today_label = UIKit:ttfLabel({
            text = _("今日"),
            size = 20,
            color= 0xffedae,
            align = cc.TEXT_ALIGNMENT_LEFT,
            shadow= true
        }):align(display.RIGHT_BOTTOM,sign_bg:getPositionX() - 34,54):addTo(bg)
        local content_label = UIKit:ttfLabel({
            text = sign_str,
            size = 20,
            color= sign_color
        }):align(display.CENTER, 52, 17):addTo(sign_bg)
    elseif item_type == self.ITEMS_TYPE.CONTINUITY then
        local title_label = UIKit:ttfLabel({
            text = _("连续登陆，来自王城的援军"),
            size = 20,
            color= 0xffedae,
            align = cc.TEXT_ALIGNMENT_LEFT,
            shadow= true
        }):align(display.LEFT_BOTTOM,268,90):addTo(bg)

        local day_label = UIKit:ttfLabel({
            text = string.format("%d/%d",countInfo.day14,#config_day14),
            size = 20,
            color= 0xa2ff00,
            shadow= true,
            align = cc.TEXT_ALIGNMENT_LEFT,
        }):addTo(bg):align(display.LEFT_BOTTOM, 268, 46)
        local day_label2 = UIKit:ttfLabel({
            text = _("天"),
            size = 20,
            color= 0xffedae,
            shadow= true,
            align = cc.TEXT_ALIGNMENT_LEFT,
        }):align(display.LEFT_BOTTOM, day_label:getPositionX()+day_label:getContentSize().width+4, 46):addTo(bg)
        local today_label = UIKit:ttfLabel({
            text = _("今日"),
            size = 20,
            color= 0xffedae,
            align = cc.TEXT_ALIGNMENT_LEFT,
            shadow= true
        }):align(display.LEFT_BOTTOM,day_label2:getPositionX()+day_label2:getContentSize().width + 15,46):addTo(bg)
        local got_bg = display.newSprite("activity_day_bg_104x34.png")
            :align(display.LEFT_BOTTOM,441,42)
            :addTo(bg)
        local str,color = _("已领取"),0xa2ff00
        if countInfo.day14 > countInfo.day14RewardsCount then
            str = _("未领取")
            color= 0xff4e00
        end
        local content_label = UIKit:ttfLabel({
            text = str,
            size = 20,
            color= color,
            align = cc.TEXT_ALIGNMENT_CENTER,
            shadow= true
        }):align(display.CENTER,52,17):addTo(got_bg)
    elseif item_type == self.ITEMS_TYPE.FIRST_IN_PURGURE then
        local title_label = RichText.new({width = 400,size = 20,color = 0xffedae,shadow = true})
        local str = self:GetFirstPurgureTips()
        title_label:Text(str):align(display.LEFT_BOTTOM,268,82):addTo(bg)
        --
        local content_label = UIKit:ttfLabel({
            text = _("永久获得第二条建筑队列"),
            size = 20,
            color= 0xffedae,
            align = cc.TEXT_ALIGNMENT_LEFT,
            shadow= true
        }):align(display.LEFT_CENTER,268,62):addTo(bg)
    elseif item_type == self.ITEMS_TYPE.PLAYER_LEVEL_UP then
        local title_label = UIKit:ttfLabel({
            text = _("活动时间类，升级智慧中心，获得丰厚奖励"),
            size = 20,
            color= 0xffedae,
            align = cc.TEXT_ALIGNMENT_LEFT,
            shadow= true,
            dimensions = cc.size(272, 0)
        }):align(display.LEFT_TOP,278,126):addTo(bg)

        local time_desc_label = UIKit:ttfLabel({
            text = _("倒计时:"),
            size = 20,
            color= 0xffedae,
            align = cc.TEXT_ALIGNMENT_LEFT,
            shadow= true
        }):align(display.LEFT_BOTTOM,268,40):addTo(bg)
        local time_label = UIKit:ttfLabel({
            text = GameUtils:formatTimeStyle1(self.player_level_up_time_residue),
            size = 20,
            color= 0xa2ff00,
            align = cc.TEXT_ALIGNMENT_LEFT,
            shadow= true
        }):align(display.LEFT_BOTTOM,268 + time_desc_label:getContentSize().width + 10,40):addTo(bg)

        local countInfo = User.countInfo
        local current_level = City:GetFirstBuildingByType('keep'):GetLevel()
        local flag = false
        for __,v in ipairs(config_levelup) do
            if app.timer:GetServerTime() > countInfo.registerTime/1000 + config_intInit.playerLevelupRewardsHours.value * 60 * 60 then
                break
            else
                if  v.level <= current_level then
                    flag = self:CheckCanGetLevelUpReward(v.index)
                    if flag then
                    	break
                    end
                end
            end
        end
        local sign_str,sign_color = _("已领取"),0xa2ff00
        if flag then
            sign_str = _("未领取")
            sign_color = 0xff4e00
        end
        local sign_bg = display.newSprite("activity_day_bg_104x34.png")
            :align(display.LEFT_BOTTOM,441,time_label:getPositionY())
            :addTo(bg)
        local content_label = UIKit:ttfLabel({
            text = sign_str,
            size = 20,
            color= sign_color
        }):align(display.CENTER, 52, 17):addTo(sign_bg)
        item.time_label = time_label
    end
    -- bg:size(576,190)
    item:addContent(bg)
    item:setMargin({left = 0, right = 0, top = 0, bottom = 5})
    item:setItemSize(612, 190,false)
    return item
end
function GameUIActivityNew:CheckCanGetLevelUpReward(level)
    local countInfo = User.countInfo
    for __,v in ipairs(countInfo.levelupRewards) do
        if v == level then
            return false
        end
    end
    return true
end
function GameUIActivityNew:CreateTabIf_award()
    if not self.award_list_view then
        local list,list_node = UIKit:commonListView({
            direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
            viewRect = cc.rect(0,0,576,772),
            async = true,

        })
        list_node:addTo(self:GetView()):pos(window.left + 35,window.bottom_top + 20)
        self.award_list = list
        self.award_list_view = list_node
        self.award_list:setDelegate(handler(self, self.sourceDelegateAwardList))
        User:AddListenOnType(self, "iapGifts")
    end
    self:RefreshAwardList()
    return self.award_list_view
end

function GameUIActivityNew:RefreshAwardList()
    self:RefreshAwardListDataSource()
    self.award_list:reload()
    self.award_list:stopAllActions()
    self.award_list:scheduleAt(function()
        for k,v in pairs(User.iapGifts) do
            self:OnIapGiftTimer(v)
        end
    end)
end

function GameUIActivityNew:RefreshAwardListDataSource()
    self.award_dataSource = {}
    self.award_logic_index_map = {}
    local data = {}
    for __,v in pairs(User.iapGifts) do
        table.insert(data,v)
    end

    table.sort( data,function(a,b)
        return User:GetIapGiftTime(a) > User:GetIapGiftTime(b)
    end)
    for index,v in ipairs(data) do
        self.award_logic_index_map[v.id] = index
        table.insert(self.award_dataSource,v)
    end
end

function GameUIActivityNew:RefreshAwardCountTips()
    if self.tab_buttons then
        self.tab_buttons:SetButtonTipNumber('award', #User.iapGifts)
    end
end

function GameUIActivityNew:OnIapGiftTimer(iapGift)
    if not self.award_logic_index_map then return end
    local index = self.award_logic_index_map[iapGift.id]
    local item = self.award_list:getItemWithLogicIndex(index)
    if not item then return end
    local content = item:getContent()
    local time = User:GetIapGiftTime(iapGift)
    if time >= 0 then
        content.time_out_label:hide()
        if content.red_btn then
            content.red_btn:hide()
        end
        content.time_label:setString(GameUtils:formatTimeStyle1(time))
        content.time_label:show()
        content.time_desc_label:show()
        if content.yellow_btn then
            content.yellow_btn:show()
        end

    else
        content.time_label:hide()
        content.time_desc_label:hide()
        if content.yellow_btn then
            content.yellow_btn:hide()
        end
        content.time_out_label:show()
        if content.red_btn then
            content.red_btn:show()
        end
        self.award_logic_index_map[index] = nil -- remove refresh item event
    end
end

function GameUIActivityNew:sourceDelegateAwardList(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.award_dataSource
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        local data = self.award_dataSource[idx]
        item = self.award_list:dequeueItem()
        if not item then
            item = self.award_list:newItem()
            content = self:GetAwardListContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        self:FillAwardItemContent(content,data,idx)
        item:setItemSize(576,164)
        return item
    else
    end
end

function GameUIActivityNew:GetAwardListContent()
    local content = WidgetUIBackGround.new({width = 576,height = 149},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local title_bg = display.newSprite("activity_title_552x42.png"):align(display.TOP_CENTER,288,145):addTo(content)
    local title_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color= 0xfed36c
    }):align(display.CENTER,276, 21):addTo(title_bg)
    display.newSprite("activity_box_552x112.png"):align(display.CENTER_BOTTOM,288, 10):addTo(content,2)
    local icon_bg = display.newSprite("activity_icon_box_78x78.png"):align(display.LEFT_BOTTOM, 20, 20):addTo(content)
    local reward_icon = display.newSprite(nil, 39, 39):addTo(icon_bg)
    local contenet_label = RichText.new({width = 400,size = 20,color = 0x403c2f})
    local str = "[{\"type\":\"text\", \"value\":\"%s\"},{\"type\":\"text\",\"color\":0x076886,\"value\":\"%s\"},{\"type\":\"text\", \"value\":\"%s\"}]"
    str = string.format(str,_("盟友"),"xxx",_("赠送!"))
    contenet_label:Text(str):align(display.LEFT_BOTTOM,115,67):addTo(content)

    local time_out_label = UIKit:ttfLabel({
        text = _("已过期。请每日登陆关注"),
        color= 0x943a09,
        size = 20
    }):align(display.LEFT_BOTTOM,115,31):addTo(content)


    local time_label = UIKit:ttfLabel({
        text = "00:00:00",
        color= 0x008b0a,
        size = 20
    }):align(display.LEFT_BOTTOM,115,31):addTo(content)
    local time_desc_label =  UIKit:ttfLabel({
        text = _("到期,请尽快领取"),
        color= 0x403c2f,
        size = 20
    }):align(display.LEFT_BOTTOM,time_label:getPositionX()+time_label:getContentSize().width,31):addTo(content)

    content.title_label = title_label
    content.reward_icon = reward_icon
    content.contenet_label = contenet_label
    content.time_out_label = time_out_label
    content.time_label = time_label
    content.time_desc_label = time_desc_label
    content.yellow_btn = yellow_btn
    content.red_btn = red_btn
    content:size(576,164)
    return content
end

function GameUIActivityNew:FillAwardItemContent(content,data,idx)
    content.idx = idx
    content.reward_icon:setTexture(UILib.item[data.name])
    content.reward_icon:scale(0.6)
    content.title_label:setString(string.format(_("获得%s"),Localize_item.item_name[data.name]))
    local str = "[{\"type\":\"text\", \"value\":\"%s\"},{\"type\":\"text\",\"color\":0x076886,\"value\":\"%s\"},{\"type\":\"text\", \"value\":\"%s\"}]"
    str = string.format(str,_("盟友"),data.from,_("赠送!"))
    content.contenet_label:Text(str):align(display.LEFT_BOTTOM,115,67)
    local time = User:GetIapGiftTime(data)
    content.time_label:setString(GameUtils:formatTimeStyle1(time))
    if content.yellow_btn then
        content.yellow_btn:removeSelf()
    end
    if content.red_btn then
        content.red_btn:removeSelf()
    end
    if time < 0 then
        content.time_label:hide()
        content.time_desc_label:hide()
        content.time_out_label:show()
        local red_btn = WidgetPushButton.new({
            normal = "red_btn_up_148x58.png",
            pressed= "red_btn_down_148x58.png"
        })
            :align(display.BOTTOM_RIGHT, 556, 18)
            :addTo(content)
            :setButtonLabel("normal", UIKit:commonButtonLable({
                text = _("放弃"),
            }))
            :onButtonClicked(function()
                self:OnAwardButtonClicked(content.idx)
            end)
        content.red_btn = red_btn
    else
        content.time_label:show()
        content.time_desc_label:show()
        content.time_out_label:hide()
        local yellow_btn = WidgetPushButton.new({
            normal = "yellow_btn_up_148x58.png",
            pressed= "yellow_btn_down_148x58.png"
        })
            :align(display.BOTTOM_RIGHT, 556, 18)
            :addTo(content)
            :setButtonLabel("normal", UIKit:commonButtonLable({
                text = _("领取"),
            }))
            :onButtonClicked(function()
                self:OnAwardButtonClicked(content.idx)
            end)
        content.yellow_btn = yellow_btn
    end

end


function GameUIActivityNew:OnAwardButtonClicked(idx)
    local data = self.award_dataSource[idx]
    if data then
        NetManager:getIapGiftPromise(data.id):done(function()
            if User:GetIapGiftTime(data) > 0 then
                GameGlobalUI:showTips(_("提示"),Localize_item.item_name[data:Name()] .. " x" .. data:Count())
                app:GetAudioManager():PlayeEffectSoundWithKey("BUY_ITEM")
            end
        end)
    end
end

return GameUIActivityNew

