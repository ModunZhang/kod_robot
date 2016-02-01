local ChatManager = import("..entity.ChatManager")
local UIPageView = import("..ui.UIPageView")
local RichText = import(".RichText")
local Report = import("..entity.Report")
local WidgetNumberTips = import(".WidgetNumberTips")
local WidgetChangeMap = import(".WidgetChangeMap")
local WidgetChat = class("WidgetChat", function()
    return display.newSprite("chat_background.png"):setNodeEventEnabled(true)
end)



function WidgetChat:TO_TOP()
    self:RefreshChatMessage()
    local page_index = self.page_view:getCurPageIdx()
    local channel = self:GetCurrentChannel()
    app:GetChatManager():setChannelReadStatus(channel,false)
    self:RefreshNewChatAni()
end

function WidgetChat:TO_REFRESH()
    self:RefreshChatMessage()
end

function WidgetChat:RefreshChatMessage()
    if not self.chat_labels then return end
    local last_chat_messages = self.chatManager:FetchLastChannelMessage()
    for i,v in ipairs(self.chat_labels) do
        local rich_text = self.chat_labels[i]
        if string.find(last_chat_messages[i],"\"url\":\"report:") then
            rich_text:Text(last_chat_messages[i],1,function ( url )
                local info = string.split(url,":")
                NetManager:getReportDetailPromise(info[2],info[3]):done(function ( response )
                    local report = Report:DecodeFromJsonData(clone(response.msg.report))
                    report:SetPlayerId(info[2])
                    if report:Type() == "strikeCity" or report:Type()== "cityBeStriked"
                        or report:Type() == "villageBeStriked" or report:Type()== "strikeVillage" then
                        UIKit:newGameUI("GameUIStrikeReport", report):AddToCurrentScene(true)
                    elseif report:Type() == "attackCity" or report:Type() == "attackVillage" then
                        UIKit:newGameUI("GameUIWarReport", report):AddToCurrentScene(true)
                    elseif report:Type() == "collectResource" then
                        UIKit:newGameUI("GameUICollectReport", report):AddToCurrentScene(true)
                    elseif report:Type() == "attackMonster" then
                        UIKit:newGameUI("GameUIMonsterReport", report):AddToCurrentScene(true)
                    elseif report:Type() == "attackShrine" then
                        UIKit:newGameUI("GameUIShrineReportInMail", report):AddToCurrentScene(true)
                    end
                    app:GetAudioManager():PlayeEffectSoundWithKey("OPEN_MAIL")
                end)
            end)
        else
            rich_text:Text(last_chat_messages[i],1)
        end
        if i % 2 == 0 then
            rich_text:align(display.LEFT_BOTTOM, 40, 0)
        else
            rich_text:align(display.LEFT_TOP, 40, 44)
        end
    end
end

function WidgetChat:ctor()
    self.chatManager = app:GetChatManager()
    -- 上次所在的聊天频道
    local last_chat_channel = tonumber(app:GetGameDefautlt():getStringForKey("LAST_CHAT_CHANNEL"))
    local current_page_index
    if not last_chat_channel then
        app:GetGameDefautlt():setStringForKey("LAST_CHAT_CHANNEL","1")
        current_page_index = 1
    else
        current_page_index = last_chat_channel
    end
    local size = self:getContentSize()
    local index_1 = display.newSprite("chat_page_index_1.png"):addTo(self):pos(size.width/2-21,size.height-5)
    local index_2 = display.newSprite("chat_page_index_2.png"):addTo(self):pos(size.width/2,size.height-5)
    local index_3 = display.newSprite("chat_page_index_2.png"):addTo(self):pos(size.width/2+21,size.height-5)

    local pv = UIPageView.new {
        -- bgColor = cc.c4b(255, 0, 0, 255),
        viewRect = cc.rect(15, 4, size.width-80, size.height),
        row = 1,
        padding = {left = 0, right = 0, top = 10, bottom = 0},
        gap = 10,
        speed_limit = 5
    }:onTouch(function (event)
        dump(event,"UIPageView event")
        if event.name == "pageChange" then
            if 1 == event.pageIdx then
                index_1:setPositionX(size.width/2-21)
                index_2:setPositionX(size.width/2)
                index_3:setPositionX(size.width/2+21)
            elseif 2 == event.pageIdx then
                index_1:setPositionX(size.width/2)
                index_2:setPositionX(size.width/2-21)
                index_3:setPositionX(size.width/2+21)
            elseif 3 == event.pageIdx then
                index_3:setPositionX(size.width/2-21)
                index_1:setPositionX(size.width/2+21)
                index_2:setPositionX(size.width/2)
            end
            local channel
            if event.pageIdx == 1 then
                channel = "global"
            elseif event.pageIdx == 2 then
                channel = "alliance"
            else
                channel = "allianceFight"
            end
            app:GetChatManager():setChannelReadStatus(channel,false)
            if self[channel.."Ani"]  then
                self[channel.."Ani"]:removeFromParent(true)
                self[channel.."Ani"] = nil
            end
            app:GetGameDefautlt():setStringForKey("LAST_CHAT_CHANNEL",""..event.pageIdx)
        elseif event.name == "clicked" then
            if event.pageIdx == 1 then
                UIKit:newGameUI('GameUIChatChannel',"global"):AddToCurrentScene(true)
            elseif event.pageIdx == 2 then
                UIKit:newGameUI('GameUIChatChannel',"alliance"):AddToCurrentScene(true)
            elseif event.pageIdx == 3 then
                UIKit:newGameUI('GameUIChatChannel',"allianceFight"):AddToCurrentScene(true)
            end
            app:GetAudioManager():PlayeEffectSoundWithKey("NORMAL_DOWN")
        end
    end):addTo(self)
    pv:setTouchEnabled(true)
    pv:setTouchSwallowEnabled(false)
    pv:setCascadeOpacityEnabled(true)
    self.chat_labels = {}
    local last_chat_messages = self.chatManager:FetchLastChannelMessage()
    -- add items
    for i=1,3 do
        local item = pv:newItem()
        local content
        local index = (i - 1) * 2 + 1
        content = display.newLayer()
        content:setContentSize(550, 46)
        content:setTouchEnabled(false)
        local label = RichText.new({width = 520,size = 18,color = 0xf5f2b3})
        label:Text(last_chat_messages[index],1)
        label:addTo(content):align(display.LEFT_TOP, 40, 44)
        table.insert(self.chat_labels, label)
        label = RichText.new({width = 520,size = 18,color = 0xf5f2b3})
        label:Text(last_chat_messages[index + 1],1)
        label:addTo(content):align(display.LEFT_BOTTOM, 40, 0)
        table.insert(self.chat_labels, label)
        if i == 1 then
            display.newSprite("global_channel_39x44.png"):align(display.LEFT_CENTER,0, 22):addTo(content)
        elseif i == 2 then
            display.newSprite("alliance_join_tips_79x83.png"):align(display.LEFT_CENTER,0, 22):addTo(content):scale(0.53)
        elseif i == 3 then
            display.newSprite("fight_62x70.png"):align(display.LEFT_CENTER,0, 22):addTo(content):scale(0.62)
        end

        item:addChild(content)
        pv:addItem(item)
    end
    pv:reload()
    pv:gotoPage(current_page_index)
    self.page_view = pv
    cc.ui.UIPushButton.new({normal = "chat_btn_up_60x48.png",
        pressed = "chat_btn_down_60x48.png"}):addTo(self)
        :pos(self:getContentSize().width-36, size.height/2 - 4)
        :onButtonClicked(function()
            if 1 == pv:getCurPageIdx() then
                UIKit:newGameUI('GameUIChatChannel',"global"):AddToCurrentScene(true)
            elseif 2 == pv:getCurPageIdx() then
                UIKit:newGameUI('GameUIChatChannel',"alliance"):AddToCurrentScene(true)
            elseif 3 == pv:getCurPageIdx() then
                UIKit:newGameUI('GameUIChatChannel',"allianceFight"):AddToCurrentScene(true)
            end
        end)
    self:RefreshNewChatAni()
    self:RefreshChatMessage()
end
-- 新消息提示动画
function WidgetChat:CreateChatAni()
    local ani_node = display.newSprite("chat_page_index_1.png")
    ani_node:setOpacity(0)
    ani_node:runAction(cc.RepeatForever:create(transition.sequence{
        cc.FadeTo:create(1.5, 255),
        cc.FadeTo:create(1.5, 0),
    }))
    return ani_node
end
function WidgetChat:RefreshNewChatAni()
    -- 新消息动画提示
    local size = self:getContentSize()
    local pos_ani = {
        global = {x = size.width/2-21, y = size.height-5},
        alliance = {x = size.width/2 , y = size.height-5},
        allianceFight = {x = size.width/2+21, y = size.height-5}
    }
    local channel = self:GetCurrentChannel()
    local channelReadStatus = app:GetChatManager():getAllChannelReadStatus()
    for k,v in pairs(channelReadStatus) do
        if k ~= channel and not self[k.."Ani"] and v then
            self[k.."Ani"] = self:CreateChatAni():addTo(self):pos(pos_ani[k].x,pos_ani[k].y)
        end
    end
end
function WidgetChat:GetCurrentChannel()
    local page_index = self.page_view:getCurPageIdx()
    local channel
    if page_index == 1 then
        channel = "global"
    elseif page_index == 2 then
        channel = "alliance"
    else
        channel = "allianceFight"
    end
    return channel
end
function WidgetChat:ChangeChannel(channel_index)
    self.page_view:gotoPage(channel_index)
end
function WidgetChat:onEnter()
    self.chatManager:AddListenOnType(self,ChatManager.LISTEN_TYPE.TO_REFRESH)
    self.chatManager:AddListenOnType(self,ChatManager.LISTEN_TYPE.TO_TOP)
end
function WidgetChat:onExit()
    self.chatManager:RemoveListenerOnType(self,ChatManager.LISTEN_TYPE.TO_REFRESH)
    self.chatManager:RemoveListenerOnType(self,ChatManager.LISTEN_TYPE.TO_TOP)
end

return WidgetChat






