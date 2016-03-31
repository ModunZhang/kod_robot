--
-- Author: Danny He
-- Date: 2015-01-21 16:07:41
--
local GameUIChatChannel          = UIKit:createUIClass('GameUIChatChannel','GameUIWithCommonHeader')
local WidgetBackGroundTabButtons = import('..widget.WidgetBackGroundTabButtons')
local NetService                 = import('..service.NetService')
local window                     = import("..utils.window")
local UIListView                 = import(".UIListView")
local ChatManager                = import("..entity.ChatManager")
local RichText                   = import("..widget.RichText")
local GameUIWriteMail            = import('.GameUIWriteMail')
local WidgetUIBackGround         = import("..widget.WidgetUIBackGround")
local WidgetPushButton           = import("..widget.WidgetPushButton")
local WidgetChatSendPushButton   = import("..widget.WidgetChatSendPushButton")
local Report                     = import("..entity.Report")


local LISTVIEW_WIDTH    = 556
local PLAYERMENU_ZORDER = 201
local BASE_CELL_HEIGHT  = 82
local CELL_FIX_WIDTH    = 484

local NAME_COLOR_SYSTEM = UIKit:hex2c3b(0x245f00) 
local NAME_COLOR_NORMAL = UIKit:hex2c3b(0x005e6c) 

function GameUIChatChannel:ctor(default_tag)
    GameUIChatChannel.super.ctor(self,City,_("聊天"))
    self.default_tag = default_tag
    self.chatManager = app:GetChatManager()
end

function GameUIChatChannel:GetChatManager()
    return self.chatManager
end

function GameUIChatChannel:OnMoveInStage()
    GameUIChatChannel.super.OnMoveInStage(self)
    self:CreateBackGround()
    self:CreateTextFieldBody()
    self:CreateListView()
    self:CreateTabButtons()
    self:GetChatManager():AddListenOnType(self,ChatManager.LISTEN_TYPE.TO_TOP)
    self:GetChatManager():AddListenOnType(self,ChatManager.LISTEN_TYPE.TO_REFRESH)
end



function GameUIChatChannel:onCleanup()
    self:GetChatManager():RemoveListenerOnType(self,ChatManager.LISTEN_TYPE.TO_TOP)
    self:GetChatManager():RemoveListenerOnType(self,ChatManager.LISTEN_TYPE.TO_REFRESH)
    GameUIChatChannel.super.onCleanup(self)
end

function GameUIChatChannel:TO_REFRESH()
    self:RefreshListView()
end

function GameUIChatChannel:TO_TOP(chat_data)
    for i,v in ipairs(chat_data) do
        if v.channel ~= self._channelType then
            self.tab_buttons:SetGreenTipsShow(v.channel,true)
        end
    end
    local data = chat_data
    local isLastMessageInViewRect = false
    local count = #data
    if count > 0 then
        isLastMessageInViewRect = self.listView:getItemWithLogicIndex(count)
    end
    if #self:GetDataSource() == 0 then
        self:RefreshListView()
    elseif isLastMessageInViewRect and not self.isModeView then
        self:RefreshListView()
    else
        LuaUtils:table_insert_top(self.dataSource_,data)
        self.listView:offsetItemsIdx(#data)
    end
end

function GameUIChatChannel:GetDataSource()
    return self.dataSource_
end

function GameUIChatChannel:CreateTextFieldBody()
    local emojiButton = WidgetPushButton.new({
        normal = "chat_button_n_68x50.png",
        pressed= "chat_button_h_68x50.png",
    }):onButtonClicked(function(event)
        self:CreateEmojiPanel()
    end):addTo(self:GetView()):align(display.LEFT_TOP, window.left+40, window.top - 100)
    display.newSprite("chat_emoji_37x37.png"):addTo(emojiButton):pos(34,-25)

    local function onEdit(event, editbox)
        if event == "return" then
            if not self.sendChatButton:CanSendChat() then
                GameGlobalUI:showTips(_("提示"),_("对不起你的聊天频率太频繁"))
                return
            end
            if self._channelType ~= 'global' then
                local my_alliance = Alliance_Manager:GetMyAlliance()
                if my_alliance:IsDefault() then
                    UIKit:showMessageDialog(_("提示"),_("加入联盟后开放此功能!"),function()end)
                    return
                elseif self._channelType == 'allianceFight' then
                    local status = my_alliance.basicInfo.status
                    if status ~= 'prepare' and status ~= 'fight' then
                        UIKit:showMessageDialog(_("提示"),_("联盟未处于战争状态，不能使用此聊天频道!"),function()end)
                        return
                    end
                end
            end
            local msg = editbox:getText()
            if not msg or string.len(string.trim(msg)) == 0 then
                GameGlobalUI:showTips(_("错误"), _("聊天内容不能为空"))
                return
            end
            editbox:setText('')
            self:GetChatManager():SendChat(self._channelType,msg,function()
                if self.sendChatButton then
                    self.sendChatButton:StartTimer()
                end
            end)
        end
    end

    local editbox = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(417,51),
        listener = onEdit,
    })
    editbox:setPlaceHolder(string.format(_("最多可输入%d字符"),140))
    editbox:setMaxLength(140)
    editbox:setFont(UIKit:getEditBoxFont(),22)
    editbox:setFontColor(cc.c3b(0,0,0))
    editbox:setPlaceholderFontColor(cc.c3b(204,196,158))
    editbox:setReturnType(cc.KEYBOARD_RETURNTYPE_SEND)
    editbox:align(display.LEFT_TOP,emojiButton:getPositionX() + 73,window.top - 100):addTo(self:GetView())
    self.editbox = editbox

    local sendChatButton = WidgetChatSendPushButton.new():align(display.LEFT_TOP, editbox:getPositionX() + 422, window.top - 100):addTo(self:GetView())
    sendChatButton:onButtonClicked(function()
        if self._channelType ~= 'global' then
            local my_alliance = Alliance_Manager:GetMyAlliance()
            if my_alliance:IsDefault() then
                UIKit:showMessageDialog(_("提示"),_("加入联盟后开放此功能!"),function()end)
                return
            elseif self._channelType == 'allianceFight' then
                local status = my_alliance.basicInfo.status
                if status ~= 'prepare' and status ~= 'fight' then
                    UIKit:showMessageDialog(_("提示"),_("联盟未处于战争状态，不能使用此聊天频道!"),function()end)
                    return
                end
            end
        end
        local msg = editbox:getText()
        if not msg or string.len(string.trim(msg)) == 0 then
            GameGlobalUI:showTips(_("错误"), _("聊天内容不能为空"))
            return
        end
        editbox:setText('')
        self:GetChatManager():SendChat(self._channelType,msg,function()
            if sendChatButton and sendChatButton.StartTimer then
                sendChatButton:StartTimer()
            end
        end)
    end)
    self.sendChatButton = sendChatButton
end

function GameUIChatChannel:CreateShopButton()
    --right button
    local rightbutton = cc.ui.UIPushButton.new({normal = "home_btn_up.png",pressed = "home_btn_down.png"}, {scale9 = false}, {down = "HOME_PAGE"})
        :onButtonClicked(function(event)
            self:CreatShieldView()
        end)
        :align(display.TOP_RIGHT, 670, 86)
    display.newSprite("chat_setting.png")
        :addTo(rightbutton):scale(0.8)
        :pos(-49,-30)

    return rightbutton
end

function GameUIChatChannel:FetchCurrentChannelMessages()
    return self:GetChatManager():FetchChannelMessage(self._channelType)
end

function GameUIChatChannel:CreateTabButtons()
    local tab_buttons = WidgetBackGroundTabButtons.new({
        {
            label = _("世界"),
            tag = "global",
            default = self.default_tag == "global",
        },
        {
            label = _("联盟"),
            tag = "alliance",
            default = self.default_tag == "alliance",
        },
        -- {
        --     label = _("对战"),
        --     tag = "allianceFight",
        --     default = self.default_tag == "allianceFight",
        -- },
    },
    function(tag)
        self._channelType = tag
        self:ShowTipsIf()
        self:RefreshListView()
        if self.tab_buttons then
            self.tab_buttons:SetGreenTipsShow(tag,false)
        end

        local pageIdx
        if tag == "global" then
            pageIdx = 1
        elseif tag == "alliance" then
            pageIdx = 2
        -- else
        --     pageIdx = 3
        end
        app:GetChatManager():setChannelReadStatus(tag,false)
        app:GetGameDefautlt():setStringForKey("LAST_CHAT_CHANNEL",""..pageIdx)
        display.getRunningScene():GetHomePage():ChangeChatChannel(pageIdx)
    end):addTo(self:GetView()):pos(window.cx, window.bottom + 34)
    local channelReadStatus = app:GetChatManager():getAllChannelReadStatus()
    for k,v in pairs(channelReadStatus) do
        if k ~= self.default_tag then
            tab_buttons:SetGreenTipsShow(k,v)
        end
    end
    self.tab_buttons = tab_buttons
end

function GameUIChatChannel:ShowTipsIf()
    local my_alliance = Alliance_Manager:GetMyAlliance()
    if my_alliance:IsDefault() then
        if self._channelType == 'alliance' or self._channelType == 'allianceFight' then
            UIKit:showMessageDialog(_("提示"),_("加入联盟后开放此功能!"),function()end)
        end
    elseif self._channelType == 'allianceFight' then
        local status = my_alliance.basicInfo.status
        if status ~= 'prepare' and status ~= 'fight' then
            UIKit:showMessageDialog(_("提示"),_("联盟未处于战争状态，不能使用此聊天频道!"),function()end)
        end
    end
end

function GameUIChatChannel:GetChatIcon(icon)
    if device.platform == 'winrt' then
        local bg = display.newSprite("dragon_bg_68x68.png")
        local icon = UIKit:GetPlayerIconOnly(icon):addTo(bg):align(display.LEFT_BOTTOM,-3, 1):scale(66/114)
        bg.icon = icon
        return bg
    else
        local bg = display.newSprite("dragon_bg_114x114.png"):scale(66/114)
        local icon = UIKit:GetPlayerIconOnly(icon):addTo(bg):align(display.LEFT_BOTTOM,-5, 1)
        bg.icon = icon
        return bg
    end
end

function GameUIChatChannel:GetChatItemCell()
    local content = display.newNode()
    local other_content = display.newNode()
    local bottom = display.newScale9Sprite("chat_bubble_bottom_484x14.png",
        nil,nil,cc.size(484,14),centerRect(484,14))
    :addTo(other_content):align(display.RIGHT_BOTTOM,LISTVIEW_WIDTH, 0)
    local middle = display.newScale9Sprite("chat_bubble_middle_484x20.png",
        nil,nil,cc.size(484,20),centerRect(484,20))
    :addTo(other_content):align(display.RIGHT_BOTTOM, LISTVIEW_WIDTH, 12)
    local header = display.newScale9Sprite("chat_bubble_header_484x38.png",
        nil,nil,cc.size(484,38),centerRect(484,38)):addTo(other_content):align(display.RIGHT_BOTTOM, LISTVIEW_WIDTH,32)
    local chat_icon = self:GetChatIcon():addTo(other_content):align(display.LEFT_TOP, 3, 72)
    local system_label = UIKit:ttfLabel({
        text = _("官方"),
        size = 14,
        color= 0xe2d9b8,
        align = cc.TEXT_ALIGNMENT_CENTER,
    })
    local system_flag = display.newScale9Sprite("chat_system_flag_42x20.png",nil,nil,cc.size(system_label:getContentSize().width + 12,20),cc.rect(6,6,30,8))
        :align(display.LEFT_BOTTOM, 7, 15):addTo(header)
    system_label:addTo(system_flag):align(display.CENTER, system_flag:getContentSize().width/2,10)
    local from_label = UIKit:ttfLabel({
        text = "[ P/L ] SkinnMart",
        size = 18,
        color= 0x005e6c,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):align(display.LEFT_BOTTOM, 7, 15):addTo(header)

    local vip_label =  UIKit:ttfLabel({
        text = "VIP 99",
        size = 14,
        color= 0xdd7f00,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):align(display.LEFT_BOTTOM, 22 + from_label:getContentSize().width, 17):addTo(header)

    local time_label =  UIKit:ttfLabel({
        text = "4 secs ago",
        size = 14,
        color= 0x403c2f,
        align = cc.TEXT_ALIGNMENT_RIGHT,
    }):align(display.BOTTOM_RIGHT, 440, 16):addTo(header)

    local translation_sp = WidgetPushButton.new({
        normal = "tmp_brown_btn_up_36x24.png",
        pressed= "tmp_brown_btn_down_36x24.png",
    }):align(display.RIGHT_BOTTOM, 478,12):addTo(header)
    display.newSprite("tmp_icon_translate_26x20.png"):addTo(translation_sp):pos(-18,12)
    -- display.newSprite("chat_translation_45x43.png"):align(display.RIGHT_BOTTOM, 478,12):addTo(header):scale(25/45)

    local content_label = RichText.new({width = 430,size = 22,color = 0x403c2f})
    content_label:Text("")
    content_label:align(display.LEFT_BOTTOM, 10, 0):addTo(middle)

    -- set var
    other_content.system_flag = system_flag
    other_content.system_flag_with = system_flag:getContentSize().width
    other_content.content_label = content_label
    other_content.time_label = time_label
    other_content.translation_sp = translation_sp
    other_content.vip_label = vip_label
    other_content.from_label = from_label
    other_content.chat_icon = chat_icon
    other_content.header = header
    other_content.middle = middle
    other_content.bottom = bottom
    other_content:size(LISTVIEW_WIDTH,BASE_CELL_HEIGHT)
    content:addChild(other_content)
    content.other_content = other_content
    -- end of other_content
    -- mine
    local mine_content = display.newNode()
    local bottom = display.newScale9Sprite("chat_bubble_bottom_484x14.png",
        nil,nil,cc.size(484,14),centerRect(484,14))
    :addTo(mine_content):align(display.LEFT_BOTTOM, 0, 0)
    local middle = display.newScale9Sprite("chat_bubble_middle_484x20.png",
        nil,nil,cc.size(484,20),centerRect(484,20))
    :addTo(mine_content):align(display.LEFT_BOTTOM, 0, 12)
    local header = display.newScale9Sprite("chat_bubble_header_484x38.png",
        nil,nil,cc.size(484,38),centerRect(484,38)):addTo(mine_content):align(display.LEFT_BOTTOM, 0, 32)
    local chat_icon = self:GetChatIcon():addTo(mine_content):align(display.RIGHT_TOP, LISTVIEW_WIDTH - 3, 72)

    local from_label = UIKit:ttfLabel({
        text = "[ P/L ] SkinnMart",
        size = 18,
        color= 0x005e6c,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):align(display.LEFT_BOTTOM, 7, 15):addTo(header)

    local vip_label =  UIKit:ttfLabel({
        text = "VIP 99",
        size = 14,
        color= 0xdd7f00,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):align(display.LEFT_BOTTOM, 22 + from_label:getContentSize().width, 17):addTo(header)

    local time_label =  UIKit:ttfLabel({
        text = "4 secs ago",
        size = 14,
        color= 0x403c2f,
        align = cc.TEXT_ALIGNMENT_RIGHT,
    }):align(display.BOTTOM_RIGHT, 478, 16):addTo(header)


    local content_label = RichText.new({width = 430,size = 22,color = 0x403c2f})
    content_label:Text("")
    content_label:align(display.LEFT_BOTTOM, 10, 0):addTo(middle)

    --set var
    mine_content.content_label = content_label
    mine_content.bottom = bottom
    mine_content.middle = middle
    mine_content.header = header
    mine_content.chat_icon = chat_icon
    mine_content.from_label = from_label
    mine_content.vip_label = vip_label
    mine_content.time_label = time_label

    mine_content:size(LISTVIEW_WIDTH,BASE_CELL_HEIGHT)
    content:addChild(mine_content)
    content.mine_content = mine_content
    --all end
    content:size(LISTVIEW_WIDTH,BASE_CELL_HEIGHT)
    return content
end

function GameUIChatChannel:CreateListView()
    display.newSprite("listview_edging.png"):align(display.BOTTOM_CENTER, window.cx, window.bottom + 784):addTo(self:GetView())
    self.listView = UIListView.new {
        viewRect = cc.rect(window.left + (window.width - LISTVIEW_WIDTH)/2, window.bottom+90, LISTVIEW_WIDTH, 700),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        alignment = cc.ui.UIListView.ALIGNMENT_LEFT,
        async = true
    }:onTouch(handler(self, self.listviewListener)):addTo(self:GetView())
    self.listView:setDelegate(handler(self, self.sourceDelegate))
    display.newSprite("listview_edging.png"):align(display.BOTTOM_CENTER, window.cx, window.bottom + 79):addTo(self:GetView()):flipY(true)
end

function GameUIChatChannel:RefreshListView()
    if not  self._channelType then
        self._channelType = 'global'
    end
    if self._channelType ~= 'global' then
        local my_alliance = Alliance_Manager:GetMyAlliance()
        if my_alliance:IsDefault() then
            -- UIKit:showMessageDialog(_("提示"),_("加入联盟后开放此功能!"),function()end)
            self.dataSource_ = {}
        elseif self._channelType == 'allianceFight' then
            local status = my_alliance.basicInfo.status
            if status ~= 'prepare' and status ~= 'fight' then
                self.dataSource_ = {}
                -- UIKit:showMessageDialog(_("提示"),_("联盟未处于战争状态，不能使用此聊天频道!"),function()end)
            else
                self.dataSource_ = clone(self:FetchCurrentChannelMessages())
            end
        else
            self.dataSource_ = clone(self:FetchCurrentChannelMessages())
        end
    else
        self.dataSource_ = clone(self:FetchCurrentChannelMessages())
    end
    self.listView:reload()
end

function GameUIChatChannel:sourceDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.dataSource_
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        local data = self.dataSource_[idx]
        item = self.listView:dequeueItem()
        if not item then
            item = self.listView:newItem()
            content = self:GetChatItemCell()
            item:addContent(content)
        else
            content = item:getContent()
        end
        local height = self:HandleCellUIData(content,data)
        item:setItemSize(LISTVIEW_WIDTH,BASE_CELL_HEIGHT + height)
        return item
    else
    end
end

function GameUIChatChannel:HandleCellUIData(mainContent,chat,update_time)
    if not chat then return end
    if type(update_time) ~= 'boolean' then
        update_time = true
    end
    local isSelf = User:Id() == chat.id
    local isVip = chat.vip and chat.vip > 0
    local currentContent = nil
    if isSelf then
        mainContent.other_content:hide()
        currentContent = mainContent.mine_content
    else
        mainContent.mine_content:hide()
        currentContent = mainContent.other_content
    end
    currentContent:show()

    local bottom = currentContent.bottom
    local middle = currentContent.middle
    local header = currentContent.header

    --header node
    local timeLabel = currentContent.time_label
    local titleLabel = currentContent.from_label
    local vipLabel = currentContent.vip_label
    local name_title = chat.allianceTag == "" and chat.name or string.format("[ %s ] %s",chat.allianceTag,chat.name)
    titleLabel:setString(name_title)
    if not isSelf then 
        local system_flag = currentContent.system_flag
        if string.lower(chat.id) == 'system' and system_flag then
            system_flag:show()
            titleLabel:pos(17 + currentContent.system_flag_with, 15)
            titleLabel:setColor(NAME_COLOR_SYSTEM)
        else
            system_flag:hide()
            titleLabel:setColor(NAME_COLOR_NORMAL)
            titleLabel:pos(7, 15)
        end
    end
    if chat.vipActive then
        vipLabel:setString('VIP ' .. DataUtils:getPlayerVIPLevel(chat.vip))
        vipLabel:setPositionX(titleLabel:getPositionX() + titleLabel:getContentSize().width + 15)
        vipLabel:show()
    else
        vipLabel:hide()
    end
    if update_time or not chat.timeStr then
        chat.timeStr = NetService:formatTimeAsTimeAgoStyleByServerTime(chat.time)
    end
    timeLabel:setString(chat.timeStr)

    local palyerIcon = currentContent.chat_icon -- TODO:
    palyerIcon.icon:setTexture(UIKit:GetPlayerIconImage(chat.icon))
    local content_label = currentContent.content_label
    local labelText = chat.text
    if chat._translate_ and chat._translateMode_ then
        labelText = chat._translate_
    end
    if string.lower(chat.id) == 'system' then
        labelText = self:GetChatManager():GetEmojiUtil():FormatSystemChat(labelText)
        content_label:Text(labelText) -- 聊天信息
    else
        labelText = self:GetChatManager():GetEmojiUtil():ConvertEmojiToRichText(labelText)
        if string.find(labelText,"\"url\":\"report:") then
            content_label:Text(labelText,nil,function ( url )
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
            content_label:Text(labelText) -- 聊天信息
        end
    end
    content_label:align(display.LEFT_BOTTOM, 10, 0)
    if not isSelf then
        --重新布局
        local adjustFunc = function()
            local height = content_label:getCascadeBoundingBox().height or 0
            height = math.max(height,20)
            middle:setContentSize(cc.size(CELL_FIX_WIDTH,height))
            header:align(display.RIGHT_BOTTOM, LISTVIEW_WIDTH, bottom:getContentSize().height+middle:getContentSize().height - 2)
            local fix_height = height - 20
            palyerIcon:align(display.LEFT_TOP,3, bottom:getContentSize().height+middle:getContentSize().height + header:getContentSize().height)
            local final_height = BASE_CELL_HEIGHT + fix_height
            mainContent.other_content:size(LISTVIEW_WIDTH,final_height)
            mainContent.mine_content:size(LISTVIEW_WIDTH,final_height)
            mainContent:size(LISTVIEW_WIDTH,final_height)
            return fix_height
        end
        mainContent.adjustFunc = adjustFunc
        return adjustFunc()
    else
        local height = content_label:getCascadeBoundingBox().height or 0
        height = math.max(height,20)
        local fix_height = height - 20
        middle:setContentSize(cc.size(CELL_FIX_WIDTH,height))
        header:align(display.LEFT_BOTTOM, 0, bottom:getContentSize().height+middle:getContentSize().height - 2)
        palyerIcon:align(display.RIGHT_TOP,LISTVIEW_WIDTH - 3,bottom:getContentSize().height+middle:getContentSize().height + header:getContentSize().height)
        local final_height = BASE_CELL_HEIGHT + fix_height
        mainContent.other_content:size(LISTVIEW_WIDTH,final_height)
        mainContent.mine_content:size(LISTVIEW_WIDTH,final_height)
        mainContent:size(LISTVIEW_WIDTH,final_height)
        return fix_height
    end
end

function GameUIChatChannel:CreatShieldView()
    UIKit:newGameUI("GameUISettingShield"):AddToCurrentScene(true)
end

-- 这里如果点中时间label及后面的部分均处理为点中了翻译按钮
function GameUIChatChannel:listviewListener(event)
    local listView = event.listView
    if "clicked" == event.name then
        local item = event.item
        if not item then return end
        local chat = self.dataSource_[item.idx_]
        if not chat then return end
        local isSelf = User:Id() == chat.id
        if isSelf or not chat then return end
        local content = item:getContent().other_content
        local header = content.header
        local button = content.time_label
        local bound = button:getBoundingBox()
        bound.width = CELL_FIX_WIDTH - bound.x
        bound.height = 26
        local nodePoint = header:convertToWorldSpace(cc.p(bound.x, bound.y))
        nodePoint = listView:getScrollNode():convertToNodeSpace(nodePoint)
        bound.x = nodePoint.x
        bound.y = nodePoint.y
        local isTouchButton = cc.rectContainsPoint(bound,event.point)
        if isTouchButton then
            local contentLable = content.content_label
            if not chat._translate_ then
                local final_chat_msg = self:GetChatManager():GetEmojiUtil():RemoveAllEmojiTag(chat.text)
                if string.utf8len(final_chat_msg) == 0 then
                    return
                end
                if string.find(chat.text,"<report>.+<report>") then
                    return
                end
                GameUtils:Translate(final_chat_msg,function(result,errText)
                    if result then
                        chat._translate_ = result
                        chat._translateMode_ = true
                        if string.lower(chat.id) == 'system' then
                            contentLable:Text(self:GetChatManager():GetEmojiUtil():FormatSystemChat(chat._translate_))
                        else
                            contentLable:Text(self:GetChatManager():GetEmojiUtil():ConvertEmojiToRichText(chat._translate_)) -- 聊天信息
                        end
                        contentLable:align(display.LEFT_BOTTOM, 10, 0)
                        local height = item:getContent().adjustFunc()
                        item:setItemSize(LISTVIEW_WIDTH,BASE_CELL_HEIGHT + height)
                    else
                        print('Translate error------->',errText)
                    end
                end)
            else
                if chat._translateMode_ then
                    chat._translateMode_ = false
                    if string.lower(chat.id) == 'system' then
                        contentLable:Text(self:GetChatManager():GetEmojiUtil():FormatSystemChat(chat.text))
                    else
                        contentLable:Text(self:GetChatManager():GetEmojiUtil():ConvertEmojiToRichText(chat.text)) -- 聊天信息
                    end
                    contentLable:align(display.LEFT_BOTTOM, 10, 0)
                else
                    chat._translateMode_ = true
                    if string.lower(chat.id) == 'system' then
                        contentLable:Text(self:GetChatManager():GetEmojiUtil():FormatSystemChat(chat._translate_))
                    else
                        contentLable:Text(self:GetChatManager():GetEmojiUtil():ConvertEmojiToRichText(chat._translate_)) -- 聊天信息
                    end
                    contentLable:align(display.LEFT_BOTTOM, 10, 0)
                end
                local height = item:getContent().adjustFunc()
                item:setItemSize(LISTVIEW_WIDTH,BASE_CELL_HEIGHT + height)
            end
            return
        end
        if not listView:isItemFullyInViewRect(event.itemPos) then
            return
        end
        if string.lower(chat.id) == 'system' then
            return
        end
        local button = content.chat_icon
        local bound = button:getBoundingBox()
        bound.width = button:getContentSize().width
        bound.height = button:getContentSize().height
        local nodePoint = content:convertToWorldSpace(cc.p(bound.x, bound.y))
        nodePoint = listView:getScrollNode():convertToNodeSpace(nodePoint)
        bound.x = nodePoint.x
        bound.y = nodePoint.y
        local isTouchChatIcon = cc.rectContainsPoint(bound,event.point)
        if isTouchChatIcon then
            UIKit:newGameUI("GameUIAllianceMemberInfo",false,chat.id,nil,chat.serverId):AddToCurrentScene(true)
            return
        end
        self:CreatePlayerMenu(event,chat)
    end
end


function GameUIChatChannel:CreatePlayerMenu(event,chat)
    local listView = event.listView
    local item = event.item
    local x,y = item:getPosition()
    local p = item:getParent():convertToWorldSpace(cc.p(x,y))
    local targetY = window.cy - 100
    local distance = targetY - p.y
    if distance <= 0 then
        targetY = p.y
    end
    local alliance_string = _("查看联盟")
    local my_alliance = Alliance_Manager:GetMyAlliance()
    local has_other_alliane = chat.allianceId and string.len(chat.allianceId) > 0
    local is_invate_action,enbale_alliance_info = false,true
    if my_alliance:IsDefault() then -- 我没有联盟
        if has_other_alliane then
            alliance_string = _("加入联盟")
    else
        alliance_string = _("无联盟信息")
        enbale_alliance_info = false
    end
    else
        if not has_other_alliane then
            alliance_string = _("邀请加入")
            is_invate_action = true
        else
            alliance_string = _("查看联盟")
        end
    end
    local callback = function(msg,data)
        if msg == 'in' then
            self.isModeView = true
            local layer = data
            if distance > 0 then
                listView:scrollBy(0,distance)
            end
            local targetP = layer:convertToNodeSpace(cc.p(p.x,targetY))
            local newItem = self:GetChatItemCell()
            self:HandleCellUIData(newItem,chat,false)
            newItem.transition_action = nil
            newItem:setPosition(targetP)
            newItem:addTo(layer)
            layer.item = newItem
        elseif msg == 'uiAnimationMoveout' then
            local layer = data
            if layer.item then layer.item:removeSelf() end
        elseif msg == 'buttonCallback' then
            if data == 'playerInfo' then
                UIKit:newGameUI("GameUIAllianceMemberInfo",false,chat.id,nil,chat.serverId):AddToCurrentScene(true)
            elseif data == 'sendMail' then
                local mail = GameUIWriteMail.new(GameUIWriteMail.SEND_TYPE.PERSONAL_MAIL,{
                    id = chat.id,
                    name = chat.name,
                    icon = chat.icon,
                    allianceTag = chat.allianceTag,
                })
                mail:SetTitle(_("个人邮件"))
                mail:addTo(self,201)
            elseif data == 'copyAction' then
                local labelText = chat.text
                if chat._translate_ and chat._translateMode_ then
                    labelText = chat._translate_
                end
                ext.copyText(labelText)
                GameGlobalUI:showTips(_("提示"),_("复制成功"))
            elseif data == 'blockChat' then
                self:GetChatManager():AddBlockChat(chat)
                self:RefreshListView()
                GameGlobalUI:showTips(_("提示"),_("屏蔽成功"))
            elseif data == 'allianceInfo' then
                if not is_invate_action then
                    if chat.allianceId and string.len(chat.allianceId) > 0 then
                        UIKit:newGameUI("GameUIAllianceInfo",chat.allianceId,nil,chat.serverId):AddToCurrentScene(true)
                    end
                else
                    if my_alliance:GetSelf():CanInvatePlayer() then
                        if User.serverId ~= chat.serverId then
                            UIKit:showMessageDialog(_("提示"), _("不能邀请其他服务器的玩家"), function()end)
                        else
                            NetManager:getInviteToJoinAlliancePromise(chat.id):done(function()
                                UIKit:showMessageDialog(_("提示"), _("邀请发送成功"), function()end)
                            end)
                        end
                    else
                        UIKit:showMessageDialog(_("提示"), _("您没有此操作权限"), function()end)
                    end
                end
            end
        elseif msg == 'out' then
            local tag = data.tag
            if tag ~= 'blockChat' then
                local __,offset_y = listView:getSlideDistance()
                if offset_y  < 0 then
                    listView:scrollAuto()
                else
                    if distance > 0 then
                        listView:scrollBy(0,-distance)
                    end
                end
            end
            self.isModeView = false
        end
    end
    UIKit:newGameUI("GameUIAllianceInfoMenu",callback,alliance_string,enbale_alliance_info):AddToCurrentScene(true)
end

function GameUIChatChannel:CreateEmojiPanel()
    UIKit:newGameUI("GameUIEmojiSelect",function(code)
        local text = self.editbox:getText()
        self.editbox:setText(string.trim(text) .. code)
    end):AddToCurrentScene(true)
end

function GameUIChatChannel:LeftButtonClicked()
    if self.listView then
        self.listView:removeAllItems()
    end
    GameUIChatChannel.super.LeftButtonClicked(self)
end

return GameUIChatChannel



