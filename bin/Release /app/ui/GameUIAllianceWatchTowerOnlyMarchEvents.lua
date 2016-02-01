--
-- Author: Kenny Dai
-- Date: 2015-10-21 20:56:39
--
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local UILib = import(".UILib")
local Alliance = import("..entity.Alliance")
local Localize = import("..utils.Localize")
local GameUIAllianceWatchTowerTroopDetail = import("..ui.GameUIAllianceWatchTowerTroopDetail")

local GameUIAllianceWatchTowerOnlyMarchEvents = UIKit:createUIClass('GameUIAllianceWatchTowerOnlyMarchEvents', "GameUIWithCommonHeader")

function GameUIAllianceWatchTowerOnlyMarchEvents:ctor(city)
    GameUIAllianceWatchTowerOnlyMarchEvents.super.ctor(self, city, _("战斗"))
    self.alliance = Alliance_Manager:GetMyAlliance()
end

function GameUIAllianceWatchTowerOnlyMarchEvents:OnMoveInStage()
    GameUIAllianceWatchTowerOnlyMarchEvents.super.OnMoveInStage(self)
    self:CreateBeStrikedList()
    self:CreateMarchList()
    self:CreateTabButtons({
        {
            label = _("来袭"),
            tag = "beStriked",
            default = true,
        },
        {
            label = _("行军"),
            tag = "march",
        },
    }, function(tag)
        self.beStriked_list_node:setVisible(tag == "beStriked")
        self.atack_list_node:setVisible(tag == "march")
    end):pos(window.cx, window.bottom + 34)
    self.alliance:AddListenOnType(self, "marchEvents")
end
function GameUIAllianceWatchTowerOnlyMarchEvents:CreateBetweenBgAndTitle()
    GameUIAllianceWatchTowerOnlyMarchEvents.super.CreateBetweenBgAndTitle(self)
    self.event_layer = display.newLayer():addTo(self:GetView())
end

function GameUIAllianceWatchTowerOnlyMarchEvents:onExit()
    self.alliance:RemoveListenerOnType(self, "marchEvents")
    GameUIAllianceWatchTowerOnlyMarchEvents.super.onExit(self)
end
-- 获取所有可显示事件数据 timer
function GameUIAllianceWatchTowerOnlyMarchEvents:GetAllOrderedMarchEvents()
    local alliance = self.alliance
    -- local allianceWTLevel = alliance.buildings["watchTower"].level
    local marchEvents = clone(alliance.marchEvents)
    -- local strikeMarchEvents = marchEvents.strikeMarchEvents
    -- local strikeMarchReturnEvents = marchEvents.strikeMarchReturnEvents
    -- local attackMarchEvents = marchEvents.attackMarchEvents
    -- local attackMarchReturnEvents = marchEvents.attackMarchReturnEvents
    local beStrikedEvents = {}
    local attackEvents = {}
    for eventType,marchEventRoot in pairs(marchEvents) do
        for _,marchEvent in ipairs(marchEventRoot) do
            marchEvent.eventType = eventType -- 添加一个事件类型，突袭，进攻
            if marchEvent.marchType ~= "shrine" and not string.find(eventType,"Return") then -- 过滤掉圣地事件和返回事件
                -- 目的地是我方联盟，并且出发地不是我方联盟，或者是协防事件:来袭事件
                if marchEvent.toAlliance.id == alliance._id and marchEvent.fromAlliance.id ~= alliance._id or marchEvent.marchType == "helpDefence" then
                    table.insert(beStrikedEvents, marchEvent)
            else
                table.insert(attackEvents, marchEvent)
            end
            end
        end
    end
    table.sort(beStrikedEvents,function (a,b)
        return a.startTime > b.startTime
    end)
    table.sort(attackEvents,function (a,b)
        return a.startTime > b.startTime
    end)
    -- if not LuaUtils:table_empty(beStrikedEvents) then
    --     dump(beStrikedEvents,"beStrikedEvents")
    -- end
    -- if not LuaUtils:table_empty(attackEvents) then
    --     dump(attackEvents,"attackEvents")
    -- end
    return beStrikedEvents , attackEvents
end
function GameUIAllianceWatchTowerOnlyMarchEvents:FliterEvents(watchTowerLevel)

end
-- 创建来袭事件列表页
function GameUIAllianceWatchTowerOnlyMarchEvents:CreateBeStrikedList()
    local beStriked_listview ,list_node = UIKit:commonListView({
        async = true, --异步加载
        viewRect = cc.rect(display.cx-284, display.top-870, 568, 790),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    },false)
    beStriked_listview:setRedundancyViewVal(200)
    beStriked_listview:setDelegate(handler(self, self.DelegateBeStriked))
    beStriked_listview:reload()
    list_node:hide()
    list_node:addTo(self.event_layer):align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20)
    self.beStriked_listview = beStriked_listview
    self.beStriked_list_node = list_node
end
function GameUIAllianceWatchTowerOnlyMarchEvents:DelegateBeStriked(listView, tag, idx )
    if cc.ui.UIListView.COUNT_TAG == tag then
        local beStrikedEvents, _ = self:GetAllOrderedMarchEvents()
        return #beStrikedEvents
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateBeStrikedContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetBeStrikedData(idx)
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        return item
    elseif UIListView.ASY_REFRESH == tag then
        for i,v in ipairs(listView:getItems()) do
            if v.idx_ == idx then
                local content = v:getContent()
                content:SetBeStrikedData(idx)
                local size = content:getContentSize()
                v:setItemSize(size.width, size.height)
            end
        end
    end
end
function GameUIAllianceWatchTowerOnlyMarchEvents:CreateBeStrikedContent()
    local c_width , c_height = 568,204
    local content = WidgetUIBackGround.new({width = c_width,height= c_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local head_bg = display.newSprite("alliance_item_flag_box_126X126.png")
        :align(display.LEFT_CENTER, 16, c_height/2 - 16)
        :scale(136/126)
        :addTo(content)
    local title_bg = display.newSprite("title_red_556x34.png")
        :align(display.CENTER_TOP, c_width/2, c_height - 6)
        :addTo(content)
    display.newSprite("icon_check_24x26.png")
        :align(display.CENTER, title_bg:getContentSize().width -20 , title_bg:getContentSize().height/2)
        :addTo(title_bg,2)
    local goto_button = WidgetPushButton.new()
        :addTo(title_bg):align(display.LEFT_BOTTOM, 0,0)
        :setContentSize(title_bg:getContentSize())
    local dragon_head = UIKit:GetDragonHeadWithFrame("redDragon")
        :align(display.CENTER, head_bg:getContentSize().width/2,head_bg:getContentSize().height/2)
        :addTo(head_bg)
    local title_label = UIKit:ttfLabel({
        text = "xxxxxxx",
        size = 20,
        color= 0xffedae,
    }):addTo(title_bg):align(display.LEFT_CENTER, 20, 17)

    local line_1 = UIKit:createLineItem(
        {
            width = 388,
            text_1 = _("来自玩家"),
            text_2 = "daidai",
        }
    ):align(display.LEFT_CENTER,head_bg:getPositionX() + head_bg:getContentSize().width + 20 , head_bg:getPositionY() + 40)
        :addTo(content)
    local line_2 = UIKit:createLineItem(
        {
            width = 388,
            text_1 = _("来自坐标"),
            text_2 = "daidai",
        }
    ):align(display.LEFT_CENTER,head_bg:getPositionX() + head_bg:getContentSize().width + 20 , head_bg:getPositionY() )
        :addTo(content)

    local details_button = WidgetPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
        :setButtonLabel(
            UIKit:commonButtonLable({
                text = _("详情")
            })
        )
        :align(display.RIGHT_BOTTOM,c_width - 16,15)
        :addTo(content)

    local icon_bg = display.newSprite("back_ground_43x43.png")
        :align(display.LEFT_BOTTOM,164, 25):addTo(content):scale(0.7)
    display.newSprite("hourglass_30x38.png"):align(display.CENTER, 22, 22):addTo(icon_bg)

    local event_time_label = UIKit:ttfLabel({
        text = "xxxx后到达",
        size = 22,
        color= 0x403c2f,
    }):addTo(content):align(display.LEFT_CENTER, icon_bg:getPositionX() + 40, icon_bg:getPositionY() + 16)
    local parent = self
    function content:SetBeStrikedData(idx)
        local beStrikedEvents, __ = parent:GetAllOrderedMarchEvents()
        local beStriked_event = beStrikedEvents[idx]
        details_button:removeEventListenersByEvent("CLICKED_EVENT")
        details_button:onButtonClicked(function(event)
            local alliance = parent.alliance
            local watchTowerLevel = 1
            for k,v in pairs(alliance.buildings) do
                if v.name == "watchTower" then
                    watchTowerLevel = v.level
                end
            end
            if watchTowerLevel > 3 then
                if beStriked_event.marchType == "helpDefence" then
                    NetManager:getHelpDefenceMarchEventDetailPromise(beStriked_event.id):done(function(response)
                        UIKit:newGameUI("GameUIAllianceWatchTowerTroopDetail",response.msg.eventDetail,watchTowerLevel,false,GameUIAllianceWatchTowerTroopDetail.DATA_TYPE.HELP_DEFENCE)
                            :AddToCurrentScene(true)
                    end)
                else
                    if string.find(beStriked_event.eventType,"strike") then
                        NetManager:getStrikeMarchEventDetailPromise(beStriked_event.id,beStriked_event.fromAlliance.id):done(function(response)
                            UIKit:newGameUI("GameUIAllianceWatchTowerTroopDetail",response.msg.eventDetail,watchTowerLevel,true,GameUIAllianceWatchTowerTroopDetail.DATA_TYPE.STRIKE)
                                :AddToCurrentScene(true)
                        end)
                    else
                        NetManager:getAttackMarchEventDetailPromise(beStriked_event.id,beStriked_event.fromAlliance.id):done(function(response)
                            UIKit:newGameUI("GameUIAllianceWatchTowerTroopDetail",response.msg.eventDetail,watchTowerLevel,true,GameUIAllianceWatchTowerTroopDetail.DATA_TYPE.MARCH)
                                :AddToCurrentScene(true)
                        end)
                    end
                end
            else
                UIKit:showMessageDialog(_("提示"),_("巨石阵等级大于3级才能查看敌军部队详情"))
            end
        end)
        goto_button:removeEventListenersByEvent("CLICKED_EVENT")
        goto_button:onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                -- TODO
                print("补充定位功能")
            end
        end)
        dragon_head:setDragonImg(beStriked_event.attackPlayerData.dragon.type)
        local defencer = beStriked_event.defencePlayerData or beStriked_event.defenceVillageData or beStriked_event.defenceMonsterData
        if beStriked_event.marchType == "helpDefence" then
            title_bg:setTexture("title_green_558x34.png")
            local title = string.format( _("%s被协防"),defencer.name)
            title_label:setString(title)
        else
            title_bg:setTexture("title_red_556x34.png")
            local title = string.format(string.find(beStriked_event.eventType,"strike") and _("%s遭到突袭") or _("%s遭到进攻"),defencer.name)
            title_label:setString(title)
        end
        local fromAlliance = beStriked_event.fromAlliance
        local location = display.getRunningScene():GetSceneLayer():RealPosition(fromAlliance.mapIndex, fromAlliance.location.x, fromAlliance.location.y)
        line_1:SetValue(beStriked_event.attackPlayerData.name)
        line_2:SetValue(location.x..","..location.y)
        scheduleAt(self,function ()
            local time = beStriked_event.arriveTime/1000.0 - app.timer:GetServerTime()
            event_time_label:setString(string.format(_("%s后到达"),GameUtils:formatTimeStyle1(time >=0 and time or 0)))
        end)
    end

    return content
end
-- 创建行军事件列表页
function GameUIAllianceWatchTowerOnlyMarchEvents:CreateMarchList()
    local atack_listview,list_node  = UIKit:commonListView({
        async = true, --异步加载
        viewRect = cc.rect(display.cx-284, display.top-870, 568, 790),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    },false)
    atack_listview:setRedundancyViewVal(200)
    atack_listview:setDelegate(handler(self, self.DelegateAttack))
    atack_listview:reload()
    list_node:hide()
    list_node:addTo(self.event_layer):align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20)
    self.atack_list_node = list_node
    self.atack_listview = atack_listview
end
function GameUIAllianceWatchTowerOnlyMarchEvents:DelegateAttack(listView, tag, idx )
    if cc.ui.UIListView.COUNT_TAG == tag then
        local _, attackEvents = self:GetAllOrderedMarchEvents()
        return #attackEvents
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateAttackContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetAttackData(idx)
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        return item
    elseif UIListView.ASY_REFRESH == tag then
        for i,v in ipairs(listView:getItems()) do
            if v.idx_ == idx then
                local content = v:getContent()
                content:SetAttackData(idx)
                local size = content:getContentSize()
                v:setItemSize(size.width, size.height)
            end
        end
    end
end
function GameUIAllianceWatchTowerOnlyMarchEvents:CreateAttackContent()
    local c_width , c_height = 568,204
    local content = WidgetUIBackGround.new({width = c_width,height= c_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local head_bg = display.newSprite("alliance_item_flag_box_126X126.png")
        :align(display.LEFT_CENTER, 16, c_height/2 - 16)
        :scale(136/126)
        :addTo(content)
    local title_bg = display.newSprite("title_blue_558x34.png")
        :align(display.CENTER_TOP, c_width/2, c_height - 6)
        :addTo(content)
    display.newSprite("icon_check_24x26.png")
        :align(display.CENTER, title_bg:getContentSize().width -20 , title_bg:getContentSize().height/2)
        :addTo(title_bg)
    local goto_button = WidgetPushButton.new()
        :addTo(title_bg):align(display.LEFT_BOTTOM, 0,0)
        :setContentSize(title_bg:getContentSize())
    local dragon_head = UIKit:GetDragonHeadWithFrame("redDragon")
        :align(display.CENTER, head_bg:getContentSize().width/2,head_bg:getContentSize().height/2)
        :addTo(head_bg)
    local title_label = UIKit:ttfLabel({
        text = "xxxxxxx",
        size = 20,
        color= 0xffedae,
    }):addTo(title_bg):align(display.LEFT_CENTER, 20, 17)

    local line_1 = UIKit:createLineItem(
        {
            width = 388,
            text_1 = _("来自玩家"),
            text_2 = "daidai",
        }
    ):align(display.LEFT_CENTER,head_bg:getPositionX() + head_bg:getContentSize().width + 20 , head_bg:getPositionY() + 40)
        :addTo(content)
    local line_2 = UIKit:createLineItem(
        {
            width = 388,
            text_1 = _("来自坐标"),
            text_2 = "daidai",
        }
    ):align(display.LEFT_CENTER,head_bg:getPositionX() + head_bg:getContentSize().width + 20 , head_bg:getPositionY() )
        :addTo(content)

    local details_button = WidgetPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
        :setButtonLabel(
            UIKit:commonButtonLable({
                text = _("详情")
            })
        )
        :align(display.RIGHT_BOTTOM,c_width - 16,15)
        :addTo(content)

    local icon_bg = display.newSprite("back_ground_43x43.png")
        :align(display.LEFT_BOTTOM,164, 25):addTo(content):scale(0.7)
    display.newSprite("hourglass_30x38.png"):align(display.CENTER, 22, 22):addTo(icon_bg)

    local event_time_label = UIKit:ttfLabel({
        text = "xxxx后到达",
        size = 22,
        color= 0x403c2f,
    }):addTo(content):align(display.LEFT_CENTER, icon_bg:getPositionX() + 40, icon_bg:getPositionY() + 16)
    local parent = self
    function content:SetAttackData(idx)
        local __, attackEvents = parent:GetAllOrderedMarchEvents()
        local att_event = attackEvents[idx]
        details_button:removeEventListenersByEvent("CLICKED_EVENT")
        details_button:onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                local alliance = parent.alliance
                local watchTowerLevel = 1
                for k,v in pairs(alliance.buildings) do
                    if v.name == "watchTower" then
                        watchTowerLevel = v.level
                    end
                end
                if att_event.marchType == "helpDefence" then
                    NetManager:getHelpDefenceMarchEventDetailPromise(att_event.id):done(function(response)
                        UIKit:newGameUI("GameUIAllianceWatchTowerTroopDetail",response.msg.eventDetail,watchTowerLevel,false,GameUIAllianceWatchTowerTroopDetail.DATA_TYPE.HELP_DEFENCE)
                            :AddToCurrentScene(true)
                    end)
                else
                    if string.find(att_event.eventType,"strike") then
                        NetManager:getStrikeMarchEventDetailPromise(att_event.id,att_event.fromAlliance.id):done(function(response)
                            UIKit:newGameUI("GameUIAllianceWatchTowerTroopDetail",response.msg.eventDetail,watchTowerLevel,false,GameUIAllianceWatchTowerTroopDetail.DATA_TYPE.STRIKE)
                                :AddToCurrentScene(true)
                        end)
                    else
                        NetManager:getAttackMarchEventDetailPromise(att_event.id,att_event.fromAlliance.id):done(function(response)
                            UIKit:newGameUI("GameUIAllianceWatchTowerTroopDetail",response.msg.eventDetail,watchTowerLevel,false,GameUIAllianceWatchTowerTroopDetail.DATA_TYPE.MARCH)
                                :AddToCurrentScene(true)
                        end)
                    end
                end
            end
        end)
        goto_button:removeEventListenersByEvent("CLICKED_EVENT")
        goto_button:onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                -- TODO
                print("补充定位功能")
                display.getRunningScene():GotoAllianceByIndex(att_event.toAlliance.mapIndex)
                parent:LeftButtonClicked()
            end
        end)
        dragon_head:setDragonImg(att_event.attackPlayerData.dragon.type)
        local defencer = att_event.defencePlayerData or att_event.defenceVillageData or att_event.defenceMonsterData
        local fromAlliance = att_event.fromAlliance
        local title = string.format(string.find(att_event.eventType,"strike") and _("突袭%s") or _("进攻%s"),defencer.name)
        title_label:setString(title)
        -- local location = display.getRunningScene():GetSceneLayer():RealPosition(fromAlliance.mapIndex, fromAlliance.location.x, fromAlliance.location.y)
        line_1:SetValue(att_event.attackPlayerData.name)
        line_2:SetValue(fromAlliance.location.x..","..fromAlliance.location.y)
        scheduleAt(self,function ()
            local time = att_event.arriveTime/1000.0 - app.timer:GetServerTime()
            event_time_label:setString(string.format(_("%s后到达"),GameUtils:formatTimeStyle1(time >=0 and time or 0)))
        end)
    end

    return content
end

function GameUIAllianceWatchTowerOnlyMarchEvents:OnAllianceDataChanged_marchEvents(alliance, deltaData)
    if self.beStriked_list_node:isVisible() then
        self.beStriked_listview:asyncLoadWithCurrentPosition_()
    end
    if self.atack_list_node:isVisible() then
        self.atack_listview:asyncLoadWithCurrentPosition_()
    end
end
return GameUIAllianceWatchTowerOnlyMarchEvents







