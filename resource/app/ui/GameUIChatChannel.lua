--
-- Author: Danny He
-- Date: 2015-01-21 16:07:41
--
local GameUIChatChannel = UIKit:createUIClass('GameUIChatChannel','GameUIWithCommonHeader')
local WidgetBackGroundTabButtons = import('..widget.WidgetBackGroundTabButtons')
local NetService = import('..service.NetService')
local window = import("..utils.window")
local UIListView = import(".UIListView")
local ChatManager = import("..entity.ChatManager")
local RichText = import("..widget.RichText")
local GameUIWriteMail = import('.GameUIWriteMail')
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetChatSendPushButton = import("..widget.WidgetChatSendPushButton")

local LISTVIEW_WIDTH = 556
local PLAYERMENU_ZORDER = 201
local BASE_CELL_HEIGHT = 82
local CELL_FIX_WIDTH = 484

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
end



function GameUIChatChannel:OnMoveOutStage()
    self:GetChatManager():RemoveListenerOnType(self,ChatManager.LISTEN_TYPE.TO_TOP)
    GameUIChatChannel.super.OnMoveOutStage(self)    
end

function GameUIChatChannel:TO_TOP(data)
    local isLastMessageInViewRect = false
    local count = #data
    if count > 0 then
        isLastMessageInViewRect = self.listView:getItemWithLogicIndex(count)
    end
    if #self:GetDataSource() == 0 or isLastMessageInViewRect then
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
            if self._channelType == ChatManager.CHANNNEL_TYPE.ALLIANCE then
                if Alliance_Manager:GetMyAlliance():IsDefault() then
                    UIKit:showMessageDialog(_("错误"),_("未加入联盟"),function()end,nil,false)
                    return
                end
            end
            local msg = editbox:getText()
            if not msg or string.len(string.trim(msg)) == 0 then 
                UIKit:showMessageDialog(_("错误"), _("聊天内容不能为空"),function()end,nil,false)
                return 
            end  
            editbox:setText('')
            self:GetChatManager():SendChat(self._channelType,msg)
        end
    end

    local editbox = cc.ui.UIInput.new({
    	UIInputType = 1,
        image = "chat_Input_box_417x51.png",
        size = cc.size(417,51),
        listener = onEdit,
    })
    editbox:setPlaceHolder(_("最多可输入140字符"))
    editbox:setMaxLength(140)
    editbox:setFont(UIKit:getEditBoxFont(),22)
    editbox:setFontColor(cc.c3b(0,0,0))
    editbox:setPlaceholderFontColor(cc.c3b(204,196,158))
    editbox:setReturnType(cc.KEYBOARD_RETURNTYPE_SEND)
    editbox:align(display.LEFT_TOP,emojiButton:getPositionX() + 73,window.top - 100):addTo(self:GetView())
    self.editbox = editbox

    local sendChatButton = WidgetChatSendPushButton.new():align(display.LEFT_TOP, editbox:getPositionX() + 422, window.top - 100):addTo(self:GetView())
    sendChatButton:onButtonClicked(function()
       if self._channelType == ChatManager.CHANNNEL_TYPE.ALLIANCE then
            if Alliance_Manager:GetMyAlliance():IsDefault() then 
                UIKit:showMessageDialog(_("错误"),_("未加入联盟"),function()end)
                return
            end
        end
        local msg = editbox:getText()
        if not msg or string.len(string.trim(msg)) == 0 then 
            UIKit:showMessageDialog(_("错误"), _("聊天内容不能为空"),function()end)
            return 
        end  
        editbox:setText('')
        self:GetChatManager():SendChat(self._channelType,msg,function()
            sendChatButton:StartTimer()
        end)
    end)
    self.sendChatButton = sendChatButton
    
    -- body button

	-- local emojiButton = cc.ui.UIPushButton.new({normal = "chat_expression.png",pressed = "chat_expression_highlight.png",},{scale9 = false})
	-- 	:onButtonClicked(function(event)
 --            -- if CONFIG_IS_DEBUG then
 --                self:CreateEmojiPanel()
 --            -- end
 --    	end)
 --    	:addTo(self:GetView())
 --    	:align(display.LEFT_TOP,self.editbox:getPositionX()+self.editbox:getContentSize().width+10, window.top - 100)
 --        :zorder(2)
 --    local plusButton = cc.ui.UIPushButton.new({normal = "chat_add.png",pressed = "chat_add_highlight.png",}, {scale9 = false})
 --    	:onButtonClicked(function(event)
 --            if CONFIG_IS_DEBUG then
 --                if self._channelType == ChatManager.CHANNNEL_TYPE.ALLIANCE then
 --                    if Alliance_Manager:GetMyAlliance():IsDefault() then 
 --                        UIKit:showMessageDialog(_("错误"),_("未加入联盟"),function()end)
 --                        return
 --                    end
 --                end
 --                local msg = editbox:getText()
 --                if not msg or string.len(string.trim(msg)) == 0 then 
 --                    UIKit:showMessageDialog(_("错误"), _("聊天内容不能为空"),function()end)
 --                    return 
 --                end  
 --                editbox:setText('')
 --                self:GetChatManager():SendChat(self._channelType,msg)
 --            end
	-- 	end)
	-- 	:addTo(self:GetView())
	-- 	:align(display.LEFT_TOP, emojiButton:getPositionX()+emojiButton:getCascadeBoundingBox().size.width+10,emojiButton:getPositionY()-2)
 --        :zorder(2)
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
    dump(self:GetChatManager():FetchChannelMessage(self._channelType),"self:GetChatManager():FetchChannelMessage(self._channelType)--->")
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
        }
    },
    function(tag)
        self._channelType = tag == 'global' and ChatManager.CHANNNEL_TYPE.GLOBAL or ChatManager.CHANNNEL_TYPE.ALLIANCE
        self:RefreshListView()
    end):addTo(self:GetView()):pos(window.cx, window.bottom + 34)
end



function GameUIChatChannel:GetChatIcon(icon)
    local bg = display.newSprite("chat_hero_background_66x66.png")
    local icon = UIKit:GetPlayerIconOnly(icon):addTo(bg):align(display.LEFT_BOTTOM,-5, 1)
    bg.icon = icon
    -- local size = icon:getContentSize()
    icon:scale(0.6)
    return bg
end

function GameUIChatChannel:GetChatItemCell()
	local content = display.newNode()
    local other_content = display.newNode()
    local bottom = display.newScale9Sprite("chat_bubble_bottom_484x14.png"):addTo(other_content):align(display.RIGHT_BOTTOM,LISTVIEW_WIDTH, 0)
    local middle = display.newScale9Sprite("chat_bubble_middle_484x20.png"):addTo(other_content):align(display.RIGHT_BOTTOM, LISTVIEW_WIDTH, 14)
    local header = display.newScale9Sprite("chat_bubble_header_484x38.png"):addTo(other_content):align(display.RIGHT_BOTTOM, LISTVIEW_WIDTH,34)
    local chat_icon = self:GetChatIcon():addTo(other_content):align(display.LEFT_TOP, 3, 72)
    local from_label = UIKit:ttfLabel({
        text = "[ P/L ] SkinnMart",
        size = 16,
        color= 0x005e6c,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):align(display.LEFT_BOTTOM, 7, 15):addTo(header)

    local vip_label =  UIKit:ttfLabel({
        text = "VIP 99",
        size = 12,
        color= 0xdd7f00,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):align(display.LEFT_BOTTOM, 22 + from_label:getContentSize().width, 17):addTo(header)

    local time_label =  UIKit:ttfLabel({
        text = "4 secs ago",
        size = 14,
        color= 0x403c2f,
        align = cc.TEXT_ALIGNMENT_RIGHT,
    }):align(display.BOTTOM_RIGHT, 450, 16):addTo(header)

    local translation_sp = display.newSprite("chat_translation_45x43.png"):align(display.RIGHT_BOTTOM, 478,12):addTo(header):scale(25/45)

    local content_label = RichText.new({width = 430,size = 18,color = 0x403c2f})
    content_label:Text("")
    content_label:align(display.LEFT_BOTTOM, 10, 0):addTo(middle)

    -- set var 
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
    local bottom = display.newScale9Sprite("chat_bubble_bottom_484x14.png"):addTo(mine_content):align(display.LEFT_BOTTOM, 0, 0)
    local middle = display.newScale9Sprite("chat_bubble_middle_484x20.png"):addTo(mine_content):align(display.LEFT_BOTTOM, 0, 14)
    local header = display.newScale9Sprite("chat_bubble_header_484x38.png"):addTo(mine_content):align(display.LEFT_BOTTOM, 0,34)
    local chat_icon = self:GetChatIcon():addTo(mine_content):align(display.RIGHT_TOP, LISTVIEW_WIDTH - 3, 72)

    local from_label = UIKit:ttfLabel({
        text = "[ P/L ] SkinnMart",
        size = 16,
        color= 0x005e6c,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):align(display.LEFT_BOTTOM, 7, 15):addTo(header)

    local vip_label =  UIKit:ttfLabel({
        text = "VIP 99",
        size = 12,
        color= 0xdd7f00,
        align = cc.TEXT_ALIGNMENT_LEFT,
    }):align(display.LEFT_BOTTOM, 22 + from_label:getContentSize().width, 17):addTo(header)

    local time_label =  UIKit:ttfLabel({
        text = "4 secs ago",
        size = 14,
        color= 0x403c2f,
        align = cc.TEXT_ALIGNMENT_RIGHT,
    }):align(display.BOTTOM_RIGHT, 478, 16):addTo(header)


    local content_label = RichText.new({width = 430,size = 18,color = 0x403c2f})
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
        self._channelType = ChatManager.CHANNNEL_TYPE.GLOBAL
    end
    self.dataSource_ = clone(self:FetchCurrentChannelMessages())
    self.listView:reload()
    return item
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
    vipLabel:setString('VIP ' .. DataUtils:getPlayerVIPLevel(chat.vip))
    vipLabel:setPositionX(titleLabel:getPositionX() + titleLabel:getContentSize().width + 15)
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
    labelText = self:GetChatManager():GetEmojiUtil():ConvertEmojiToRichText(labelText)
    content_label:Text(labelText) -- 聊天信息
    content_label:align(display.LEFT_BOTTOM, 10, 0)
    if not isSelf then
        --重新布局
        local adjustFunc = function()
            local height = content_label:getCascadeBoundingBox().height or 0
            middle:setContentSize(cc.size(CELL_FIX_WIDTH,height))
            header:align(display.RIGHT_BOTTOM, LISTVIEW_WIDTH, bottom:getContentSize().height+middle:getContentSize().height)
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
        local fix_height = height - 20
        middle:setContentSize(cc.size(CELL_FIX_WIDTH,height))
        header:align(display.LEFT_BOTTOM, 0, bottom:getContentSize().height+middle:getContentSize().height)
        palyerIcon:align(display.RIGHT_TOP,LISTVIEW_WIDTH - 3,bottom:getContentSize().height+middle:getContentSize().height + header:getContentSize().height)
        local final_height = BASE_CELL_HEIGHT + fix_height
        mainContent.other_content:size(LISTVIEW_WIDTH,final_height)
        mainContent.mine_content:size(LISTVIEW_WIDTH,final_height)
        mainContent:size(LISTVIEW_WIDTH,final_height)
        return fix_height
    end
end

function GameUIChatChannel:CreatShieldView()
    local shieldView = display.newColorLayer(UIKit:hex2c4b(0x7a000000))
        :addTo(self,PLAYERMENU_ZORDER)
    local bg =  WidgetUIBackGround.new({height=608}):addTo(shieldView):pos(window.left+20,window.bottom+150)
    local header = display.newSprite("title_blue_600x52.png")
        :addTo(bg)
        :align(display.CENTER_BOTTOM, 304, 594)
    UIKit:closeButton():addTo(header)
        :align(display.BOTTOM_RIGHT,header:getContentSize().width, 0)
        :onButtonClicked(function ()
            shieldView:removeFromParent(true)
        end)
    local title_label = UIKit:ttfLabel({
        text = _("设置"),
        size = 24,
        color = 0xffedae,
    }):align(display.CENTER,header:getContentSize().width/2, header:getContentSize().height/2):addTo(header)
   local translation = display.newSprite("chat_translation_45x43.png")
        :addTo(bg)
        :pos(50,508)

    local descLabel = UIKit:ttfLabel({
         text = _("点击后，会根据你的系统语言，将其他玩家发言翻译成你熟悉的语种。若要修改翻译的语种，请修改你当前的系统语种。"),
            size = 20,
            color=0x403c2f,
            dimensions = cc.size(bg:getContentSize().width - translation:getPositionX() - 50 - translation:getContentSize().width, 0),
    }):addTo(bg):pos(translation:getPositionX() + 50,translation:getPositionY())
    local line = display.newScale9Sprite("dividing_line.png")
        :addTo(bg)
        line:size(bg:getContentSize().width - 40,line:getContentSize().height)
        :align(display.TOP_LEFT, 20, translation:getPositionY() - descLabel:getContentSize().height)

    local heightOfList,widthOfList = line:getPositionY() - 30,bg:getContentSize().width - 40
    self.blackListView = UIListView.new({
        bg = "chat_setting_listview_bg.png",
        bgScale9 = true,
        viewRect = cc.rect(20, 20, bg:getContentSize().width - 40,heightOfList),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        alignment = cc.ui.UIListView.ALIGNMENT_LEFT
    }):addTo(bg)
    self:RefreshBlockedList(widthOfList)
end


function GameUIChatChannel:RefreshBlockedList(widthOfList)
    self.blackListView:removeAllItems()
    local blockListDataSource = self:GetChatManager():GetBlockList()
    for _,v in pairs(blockListDataSource) do
        local newItem = self:GetBlackListItem(v,widthOfList)
        self.blackListView:addItem(newItem)
    end
    self.blackListView:reload()
end


function GameUIChatChannel:GetBlackListItem(chat,width)
    local item = self.blackListView:newItem()
    local bg = display.newScale9Sprite("chat_setting_item_bg.png")
    bg:size(width,bg:getContentSize().height)
    --content
    local iconBg = UIKit:GetPlayerCommonIcon():scale(0.8):addTo(bg,2):pos(60,math.floor(bg:getContentSize().height/2))
    local nameLabel = cc.ui.UILabel.new({
        UILabelType = 2,
        text = chat.name or "player" ,
        size = 22,
        color = UIKit:hex2c3b(0x403c2f),
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
    }):addTo(bg,2)
      :pos(iconBg:getPositionX()+50,iconBg:getPositionY()+20)

    local allianceLabel = cc.ui.UILabel.new({
        UILabelType = 2,
        text = chat.allianceTag or "",
        size = 16,
        color = UIKit:hex2c3b(0x403c2f),
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
    }):addTo(bg,2)
      :pos(iconBg:getPositionX()+50,iconBg:getPositionY()-10)

    cc.ui.UIPushButton.new({normal="yellow_btn_up_149x47.png",pressed="yellow_btn_down_149x47.png"}, {scale9 = false})
        :onButtonClicked(function(event)
            local success = self:GetChatManager():RemoveItemFromBlockList(chat)
            if success then
                self.blackListView:removeItem(item,false)
            end
        end)
        :setButtonLabel("normal",cc.ui.UILabel.new({
            UILabelType = 2,
            text = _("取消屏蔽"),
            size = 22,
            color = UIKit:hex2c3b(0xfff3c7),
            align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
        }))
        :align(display.RIGHT_TOP,bg:getContentSize().width - 30, allianceLabel:getPositionY()+10)
        :addTo(bg)
    item:addContent(bg)
    item:setItemSize(width,bg:getContentSize().height)
    return item
end
-- 这里如果点中时间label及后面的部分均处理为点中了翻译按钮
function GameUIChatChannel:listviewListener(event)
    local listView = event.listView
    if "clicked" == event.name then
        local item = event.item
        if not item then return end
        local chat = self.dataSource_[item.idx_]
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
                GameUtils:Translate(final_chat_msg,function(result,errText)
                    if result then
                        chat._translate_ = result
                        chat._translateMode_ = true
                        contentLable:Text(self:GetChatManager():GetEmojiUtil():ConvertEmojiToRichText(chat._translate_)) -- 聊天信息
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
                    contentLable:Text(self:GetChatManager():GetEmojiUtil():ConvertEmojiToRichText(chat.text)) -- 聊天信息
                    contentLable:align(display.LEFT_BOTTOM, 10, 0)
                else
                    chat._translateMode_ = true
                    contentLable:Text(self:GetChatManager():GetEmojiUtil():ConvertEmojiToRichText(chat._translate_)) -- 聊天信息
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
    	self:CreatePlayerMenu(event,chat)
    end
end


function GameUIChatChannel:CreatePlayerMenu(event,chat)
    local item = event.item
    local menuLayer = UIKit:shadowLayer()
    menuLayer:setTouchEnabled(true)
    menuLayer:addTo(self,PLAYERMENU_ZORDER):pos(0, 0)
    -- local tabBg = display.newSprite("chat_tab_backgroud.png"):align(display.LEFT_BOTTOM, 0, 0):addTo(menuLayer)
    menuLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT,function()
        menuLayer:removeFromParent(true)
    end)
    local x,y = item:getPosition()
    local p = item:getParent():convertToWorldSpace(cc.p(x,y))
    local targetP = menuLayer:convertToNodeSpace(p)
    local newItem = self:GetChatItemCell()
    self:HandleCellUIData(newItem,chat,false)
    newItem.transition_action = nil
    newItem:setPosition(targetP)
    newItem:addTo(menuLayer)
    --copy
    local copyButton = WidgetPushButton.new({normal="chat_button_n_124x92.png",pressed="chat_button_h_124x92.png"}, {scale9 = false})
        :setButtonLabel("normal",UIKit:commonButtonLable({
            text = _("复制"),
            size = 16,
            color= 0xffedae
        }))
        :onButtonClicked(function(event)
            local labelText = chat.text
            if chat._translate_ and chat._translateMode_ then
                labelText = chat._translate_
            end
            ext.copyText(labelText)
            menuLayer:removeFromParent(true)
            UIKit:showMessageDialog(nil,_("复制成功"))
        end)
        :align(display.LEFT_BOTTOM,window.left + 10, window.bottom + 2)
        :addTo(menuLayer)
        :setTouchSwallowEnabled(true)
    local label = copyButton:getButtonLabel()
    display.newSprite("chat_copy_62x56.png"):align(display.CENTER,label:getPositionX(), label:getPositionY()+10):addTo(copyButton)
    copyButton:setButtonLabelOffset(0,-30)

    --chat_check_out
    local checkButton = WidgetPushButton.new({normal="chat_button_n_124x92.png",pressed="chat_button_h_124x92.png"}, {scale9 = false})
        :setButtonLabel("normal",UIKit:commonButtonLable({
            text = _("查看信息"),
            size = 16,
            color= 0xffedae
        }))
        :onButtonClicked(function(event)
            menuLayer:removeFromParent(true)
            UIKit:newGameUI("GameUIAllianceMemberInfo",false,chat.id):AddToCurrentScene(true)
        end)
        :setTouchSwallowEnabled(true)
        :align(display.LEFT_BOTTOM, window.left + 134 ,window.bottom +  2)
        :addTo(menuLayer)
    local label = checkButton:getButtonLabel()
    display.newSprite("chat_check_out_62x56.png"):align(display.CENTER,label:getPositionX(), label:getPositionY()+10):addTo(checkButton)
    checkButton:setButtonLabelOffset(0,-30)

    --chat_shield
    local shieldButton = WidgetPushButton.new({normal="chat_button_n_124x92.png",pressed="chat_button_h_124x92.png"}, {scale9 = false})
        :setButtonLabel("normal",UIKit:commonButtonLable({
            text = _("屏蔽"),
            size = 16,
            color= 0xffedae
        }))
        :onButtonClicked(function(event)
            self:GetChatManager():AddBlockChat(chat)
            menuLayer:removeFromParent(true)
            self:RefreshListView()
            UIKit:showMessageDialog(nil,_("屏蔽成功"))
        end)
        :align(display.LEFT_BOTTOM,  window.left + 258,window.bottom +  2)
        :addTo(menuLayer)
        :setTouchSwallowEnabled(true)
    local label = shieldButton:getButtonLabel()
    display.newSprite("chat_shield_62x56.png"):align(display.CENTER,label:getPositionX(), label:getPositionY()+10):addTo(shieldButton)
    shieldButton:setButtonLabelOffset(0,-30)

    --chat_report
    local reportButton = WidgetPushButton.new({normal="chat_button_n_124x92.png",pressed="chat_button_h_124x92.png",disabled = "chat_button_d_124x92.png"}, {scale9 = false})
        :setButtonLabel("normal", UIKit:commonButtonLable({
            text = _("举报"),
            size = 16,
            color= 0xffedae
        }))
        :onButtonClicked(function(event)
            menuLayer:removeFromParent(true)
        end)
        :align(display.LEFT_BOTTOM, window.left + 382,window.bottom +  2)
        :addTo(menuLayer)
        :setTouchSwallowEnabled(true)
    local label = reportButton:getButtonLabel()
    display.newSprite("chat_report_62x56.png"):align(display.CENTER,label:getPositionX(), label:getPositionY()+10):addTo(reportButton)
    reportButton:setButtonLabelOffset(0,-30)
    reportButton:setButtonEnabled(false)
    --chat_mail
    local mailButton = WidgetPushButton.new({normal="chat_button_n_124x92.png",pressed="chat_button_h_124x92.png"}, {scale9 = false})
        :setButtonLabel("normal",  UIKit:commonButtonLable({
            text = _("邮件"),
            size = 16,
            color= 0xffedae
        }))
        :onButtonClicked(function(event)
            menuLayer:removeFromParent(true)
            local mail = GameUIWriteMail.new(GameUIWriteMail.SEND_TYPE.PERSONAL_MAIL,{
                    id = chat.id,
                    name = chat.name,
                    icon = chat.icon,
                    allianceTag = chat.allianceTag,
                })
            mail:SetTitle(_("个人邮件"))
            mail:addTo(self,201)
        end)
        :setTouchSwallowEnabled(true)
        :align(display.LEFT_BOTTOM, window.left + 506 ,window.bottom +  2)
        :addTo(menuLayer)
    local label = mailButton:getButtonLabel()
    display.newSprite("chat_mail_62x56.png"):align(display.CENTER,label:getPositionX(), label:getPositionY()+10):addTo(mailButton)
    mailButton:setButtonLabelOffset(0,-30)
end

function GameUIChatChannel:CreateEmojiPanel()
    UIKit:newGameUI("GameUIEmojiSelect",function(code)
         local text = self.editbox:getText()
        self.editbox:setText(string.trim(text) .. code)
    end):AddToCurrentScene(true)
end

function GameUIChatChannel:LeftButtonClicked()
    self.listView:removeAllItems()
    GameUIChatChannel.super.LeftButtonClicked(self)
end

return GameUIChatChannel