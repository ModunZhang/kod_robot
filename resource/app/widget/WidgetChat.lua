local ChatManager = import("..entity.ChatManager")
local UIPageView = import("..ui.UIPageView")
local RichText = import(".RichText")
local WidgetNumberTips = import(".WidgetNumberTips")
local WidgetChangeMap = import(".WidgetChangeMap")
local WidgetChat = class("WidgetChat", function()
    return display.newSprite("chat_background.png"):setNodeEventEnabled(true)
end)



function WidgetChat:TO_TOP()
    self:RefreshChatMessage()
end

function WidgetChat:TO_REFRESH()
    self:RefreshChatMessage()
end

function WidgetChat:RefreshChatMessage()
    if not self.chat_labels then return end
    local last_chat_messages = self.chatManager:FetchLastChannelMessage()
    for i,v in ipairs(self.chat_labels) do
        local rich_text = self.chat_labels[i]
        rich_text:Text(last_chat_messages[i],1)
        rich_text:align(display.LEFT_CENTER, 0, 10)
    end
end

function WidgetChat:ctor()
    self.chatManager = app:GetChatManager()

    local size = self:getContentSize()
    local index_1 = display.newSprite("chat_page_index_1.png"):addTo(self):pos(size.width/2-10,size.height-5)
    local index_2 = display.newSprite("chat_page_index_2.png"):addTo(self):pos(size.width/2+10,size.height-5)
    local pv = UIPageView.new {
        viewRect = cc.rect(15, 4, size.width-80, size.height),
        row = 2,
        padding = {left = 0, right = 0, top = 10, bottom = 0},
        gap = 10,
        speed_limit = 5
    }:onTouch(function (event)
        dump(event,"UIPageView event")
        if event.name == "pageChange" then
            if 1 == event.pageIdx then
                index_1:setPositionX(size.width/2-10)
                index_2:setPositionX(size.width/2+10)
            elseif 2 == event.pageIdx then
                index_1:setPositionX(size.width/2+10)
                index_2:setPositionX(size.width/2-10)
            end
        elseif event.name == "clicked" then
            if event.pageIdx == 1 then
                UIKit:newGameUI('GameUIChatChannel',"global"):AddToCurrentScene(true)
            elseif event.pageIdx == 2 then
                UIKit:newGameUI('GameUIChatChannel',"alliance"):AddToCurrentScene(true)
            end
        end
    end):addTo(self)
    pv:setTouchEnabled(true)
    pv:setTouchSwallowEnabled(false)
    pv:setCascadeOpacityEnabled(true)
    self.chat_labels = {}
    local last_chat_messages = self.chatManager:FetchLastChannelMessage()
    -- add items
    for i=1,4 do
        local item = pv:newItem()
        local content

        content = display.newLayer()
        content:setContentSize(540, 20)
        content:setTouchEnabled(false)
        local label = RichText.new({width = 540,size = 16,color = 0xf5f2b3})
        label:Text(last_chat_messages[i],1)
        label:addTo(content):align(display.LEFT_CENTER, 0, content:getContentSize().height/2)
        table.insert(self.chat_labels, label)
        item:addChild(content)
        pv:addItem(item)
    end
    pv:reload()
    cc.ui.UIPushButton.new({normal = "chat_btn_up_60x48.png",
        pressed = "chat_btn_down_60x48.png"}):addTo(self)
        :pos(self:getContentSize().width-36, size.height/2 - 4)
        :onButtonClicked(function()
            if 1 == pv:getCurPageIdx() then
                UIKit:newGameUI('GameUIChatChannel',"global"):AddToCurrentScene(true)
            elseif 2 == pv:getCurPageIdx() then
                UIKit:newGameUI('GameUIChatChannel',"alliance"):AddToCurrentScene(true)
            end
        end)
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

