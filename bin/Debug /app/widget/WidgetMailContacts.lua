--
-- Author: Kenny Dai
-- Date: 2015-04-22 21:33:43
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetPushButton = import("..widget.WidgetPushButton")
local GameUIWriteMail = import("..ui.GameUIWriteMail")
local WidgetMailContacts = class("WidgetMailContacts", WidgetPopDialog)

function WidgetMailContacts:ctor()
    WidgetMailContacts.super.ctor(self,674,_("最近联系人"))
    local contacts = app:GetGameDefautlt():getRecentContacts()
    self.contacts = contacts
    local body = self:GetBody()
    local size = body:getContentSize()
    local tips = UIKit:ttfLabel({
        text = _("向其他玩家发送邮件,会自动添加到最近联系人列表"),
        size = 20,
        color = 0x403c2f,
        dimensions = cc.size(520,0),
        align = cc.TEXT_ALIGNMENT_CENTER,
    }):align(display.TOP_CENTER,size.width/2,size.height-20)
        :addTo(body)
    local list,list_node = UIKit:commonListView_1({
        async = true, --异步加载
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,548,674 - tips:getContentSize().height - 80),
    })
    self.head_icon_list = list
    list:setRedundancyViewVal(list:getViewRect().height + 76 * 2)
    list:setDelegate(handler(self, self.sourceDelegate))
    list:reload()
    list_node:addTo(body):align(display.BOTTOM_CENTER, size.width/2,20)

end
function WidgetMailContacts:sourceDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.contacts
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateContactsContent()

            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetData(idx)

        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        return item
    else
    end
end
function WidgetMailContacts:CreateContactsContent()
    local list =  self.head_icon_list
    local item =list:newItem()
    local item_width,item_height = 548, 124
    item:setItemSize(item_width,item_height)
    local content = display.newNode()
    content:setContentSize(cc.size(item_width,item_height))

    list.which_bg = not list.which_bg
    local alliance_tag = UIKit:ttfLabel({
        size = 24,
        color = 0x403c2f
    }):align(display.LEFT_CENTER,134,44)
        :addTo(content,2)
    local name = UIKit:ttfLabel({
        size = 24,
        color = 0x5c553f
    }):align(display.LEFT_CENTER,134,84)
        :addTo(content,2)
    local parent = self
    function content:SetData( idx )
        local contacts = parent.contacts[idx]
        if self.bg then
            self.bg:removeFromParent(true)
        end
        local body_image = idx%2==0 and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
        self.bg = display.newScale9Sprite(body_image,item_width/2,item_height/2,cc.size(item_width,item_height),cc.rect(10,10,528,20)):addTo(self)

        alliance_tag:setString(contacts.allianceTag and contacts.allianceTag~="" and "["..contacts.allianceTag.."]" or "")
        if not contacts.allianceTag then
            name:setPositionY(62)
        end
        name:setString(contacts.name)
        if self.icon then
            self.icon:removeFromParent(true)
        end
        self.icon =UIKit:GetPlayerCommonIcon():align(display.CENTER, 60, item_height/2):addTo(self):scale(0.8)
        if self.button then
            self.button:removeFromParent(true)
        end
        self.button = WidgetPushButton.new(
            {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
            {scale9 = false},
            {
                disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
            }
        ):setButtonLabel(UIKit:ttfLabel({
            text = _("邮件"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    local mail = UIKit:newGameUI("GameUIWriteMail", GameUIWriteMail.SEND_TYPE.PERSONAL_MAIL,contacts)
                    mail:SetTitle(_("个人邮件"))
                    mail:AddToCurrentScene(true)
                    mail:setLocalZOrder(3000)
                    parent:LeftButtonClicked()
                end
            end):addTo(self):align(display.RIGHT_CENTER, item_width-10,40)
    end
    return content
end
return WidgetMailContacts







