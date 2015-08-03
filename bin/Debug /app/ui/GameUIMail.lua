local GameUIWithCommonHeader = import('.GameUIWithCommonHeader')
local UIListView = import(".UIListView")
local GameUIStrikeReport = import(".GameUIStrikeReport")
local GameUIWarReport = import(".GameUIWarReport")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local StarBar = import(".StarBar")
local Flag = import("..entity.Flag")
local WidgetRoundTabButtons = import("..widget.WidgetRoundTabButtons")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local UILib = import(".UILib")
local Localize = import("..utils.Localize")
local GameUICollectReport = import(".GameUICollectReport")
local Report = import("..entity.Report")


local GameUIMail = class('GameUIMail', GameUIWithCommonHeader)

GameUIMail.ONE_TIME_LOADING_MAILS = 10
GameUIMail.ONE_TIME_LOADING_REPORTS = 10

function GameUIMail:ctor(city)
    GameUIMail.super.ctor(self)
    self.title = _("邮件")
    self.city = city
    self.manager = MailManager

    app:GetAudioManager():PlayeEffectSoundWithKey("OPEN_MAIL")
end

function GameUIMail:OnMoveInStage()
    GameUIMail.super.OnMoveInStage(self)
    self:CreateMailControlBox()

    self:CreateTabButtons({
        {
            label = _("收件箱"),
            tag = "inbox",
            default = true,
        },
        {
            label = _("战报"),
            tag = "report",
        },
        {
            label = _("收藏夹"),
            tag = "saved",
        },
        {
            label = _("已发送"),
            tag = "sent",
        },
    }, function(tag)
        if tag == 'inbox' then
            self.inbox_layer:setVisible(true)
            -- if not self.inbox_listview then
            local mails = self.manager:GetMails()
            self:InitInbox(mails)
            -- end
        else
            self.inbox_layer:ClearAll()
            self.inbox_layer:setVisible(false)
        end

        if tag == 'report' then
            -- if not self.report_listview then
            self:InitReport()
            -- end
            self.report_layer:setVisible(true)
        else
            self.report_layer:ClearAll()
            self.report_layer:setVisible(false)
        end

        if tag == 'saved' then
            self.saved_layer:setVisible(true)
            -- if not self.saved_reports_listview then
            self:InitSavedReports()
            -- end
        else
            self.saved_layer:ClearAll()
            self.saved_layer:setVisible(false)
        end

        if tag == 'sent' then
            self.sent_layer:setVisible(true)
            -- if not self.send_mail_listview then
            local send_mails = self.manager:GetSendMails()
            self:InitSendMails(send_mails)
            -- end
        else
            self.sent_layer:ClearAll()
            self.sent_layer:setVisible(false)
        end
    end):pos(window.cx, window.bottom + 34)

    self.manager:AddListenOnType(self,MailManager.LISTEN_TYPE.MAILS_CHANGED)
    self.manager:AddListenOnType(self,MailManager.LISTEN_TYPE.REPORTS_CHANGED)
    self.manager:AddListenOnType(self,MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED)

    self:InitUnreadMark()
end
function GameUIMail:InitUnreadMark()
    local mail_unread_num = MailManager:GetUnReadMailsNum()
    self.mail_unread_num_bg = display.newSprite("back_ground_32x33.png"):addTo(self:GetView(),3)
        :pos(window.left+158, window.bottom_top)
    self.mail_unread_num_label = UIKit:ttfLabel(
        {
            text = mail_unread_num > 99 and "99+" or mail_unread_num,
            size = 16,
            color = 0xf5f2b3
        }):align(display.CENTER,self.mail_unread_num_bg:getContentSize().width/2-2,self.mail_unread_num_bg:getContentSize().height/2+4)
        :addTo(self.mail_unread_num_bg)

    local report_unread_num = MailManager:GetUnReadReportsNum()
    self.report_unread_num_bg = display.newSprite("back_ground_32x33.png"):addTo(self:GetView(),3)
        :pos(window.left+304, window.bottom_top)
    self.report_unread_num_label = UIKit:ttfLabel(
        {
            text = report_unread_num > 99 and "99+" or report_unread_num,
            size = 16,
            color = 0xf5f2b3
        }):align(display.CENTER,self.report_unread_num_bg:getContentSize().width/2-2,self.report_unread_num_bg:getContentSize().height/2+4)
        :addTo(self.report_unread_num_bg)
    self.mail_unread_num_bg:setVisible(mail_unread_num>0)
    self.report_unread_num_bg:setVisible(report_unread_num>0)
end
function GameUIMail:CreateMailControlBox()
    -- 标记邮件，已读，删除多封邮件
    self.mail_control_box = display.newSprite("back_ground_624x134.png")
        :pos(window.cx+1, window.bottom + 66)
        :addTo(self:GetView(),4)
    self.mail_control_box:hide()
    self.mail_control_box:setTouchEnabled(true)

    local box = self.mail_control_box
    local w,h = box:getContentSize().width, box:getContentSize().height
    local gap_x = (624-132*4)/5
    local select_all_btn = WidgetPushButton.new({normal = "brown_btn_up_132x98.png",pressed = "brown_btn_down_132x98.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("全选"),
            size = 22,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:SelectAllMailsOrReports(true)
            end
        end):align(display.LEFT_CENTER,gap_x,h/2-6):addTo(box)
    local delete_btn = WidgetPushButton.new({normal = "brown_btn_up_132x98.png",pressed = "brown_btn_down_132x98.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("删除"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                local control_type = self:GetCurrentSelectType()
                local replace_text = (control_type == "mail" and _("邮件")) or (control_type == "report" and _("战报")) or (control_type == "send_mails" and _("邮件"))
                UIKit:showMessageDialog(string.format(_("删除%s"),replace_text),string.format(_("您即将删除所选%s,删除的%s将无法恢复,您确定要这么做吗?"),replace_text,replace_text))
                    :CreateOKButton(
                        {
                            listener =function ()
                                local select_map = self:GetSelectMailsOrReports()
                                local ids = {}
                                for k,v in pairs(select_map) do
                                    table.insert(ids, v.id)
                                end
                                self.is_deleting = true
                                if control_type == "mail" then
                                    MailManager:DecreaseUnReadMailsNumByIds(ids)
                                    NetManager:getDeleteMailsPromise(ids):done(function ()
                                        self:SelectAllMailsOrReports(false)
                                        self.mail_control_box:hide()

                                        if self.inbox_layer:isVisible() then
                                            -- 批量删除结束后获取
                                            if #self.manager:GetMails() < 10 then
                                                local response = self.manager:FetchMailsFromServer(#self.manager:GetMails())
                                                if response then
                                                    response:done(function ( response )
                                                        self.inbox_listview:asyncLoadWithCurrentPosition_()
                                                        self.is_deleting = false
                                                        return response
                                                    end)
                                                else
                                                    self.is_deleting = false
                                                end
                                            else
                                                self.is_deleting = false
                                            end
                                        end
                                        if self.saved_layer:isVisible() then
                                            -- 批量删除结束后获取
                                            if #self.manager:GetSavedMails() < 10 then
                                                local response = self.manager:FetchSavedMailsFromServer(#self.manager:GetSavedMails())
                                                if response then
                                                    response:done(function ( response )
                                                        self.save_mails_listview:asyncLoadWithCurrentPosition_()
                                                        self.is_deleting = false
                                                        return response
                                                    end)
                                                else
                                                    self.is_deleting = false
                                                end
                                            else
                                                self.is_deleting = false
                                            end
                                        end
                                    end)
                                elseif control_type == "report" then
                                    MailManager:DecreaseUnReadReportsNumByIds(ids)
                                    NetManager:getDeleteReportsPromise(ids):done(function ()
                                        self:SelectAllMailsOrReports(false)
                                        self.mail_control_box:hide()
                                        if self.report_layer:isVisible() then
                                            -- 批量删除结束后获取
                                            if #self.manager:GetReports()<10 then
                                                local response = self.manager:FetchReportsFromServer(#self.manager:GetReports())
                                                if response then
                                                    response:done(function ( response )
                                                        self.report_listview:asyncLoadWithCurrentPosition_()
                                                        self.is_deleting = false
                                                        return response
                                                    end)
                                                else
                                                    self.is_deleting = false
                                                end
                                            else
                                                self.is_deleting = false
                                            end
                                        end
                                        if self.saved_layer:isVisible() then
                                            -- 批量删除结束后获取
                                            if #self.manager:GetSavedReports()<10 then
                                                local response self.manager:FetchSavedReportsFromServer(#self.manager:GetSavedReports())
                                                if response then
                                                    response:done(function ( response )
                                                        self.saved_reports_listview:asyncLoadWithCurrentPosition_()
                                                        self.is_deleting = false
                                                        return response
                                                    end)
                                                else
                                                    self.is_deleting = false
                                                end
                                            else
                                                self.is_deleting = false
                                            end
                                        end
                                    end)
                                elseif control_type == "send_mails" then
                                    NetManager:getDeleteSendMailsPromise(ids):done(function ()
                                        self:SelectAllMailsOrReports(false)
                                        self.mail_control_box:hide()

                                        if self.sent_layer:isVisible() then
                                            -- 批量删除结束后获取
                                            if #self.manager:GetSendMails() < 10 then
                                                local response = self.manager:FetchSendMailsFromServer(#self.manager:GetSendMails())
                                                if response then
                                                    response:done(function ( response )
                                                        self.send_mail_listview:asyncLoadWithCurrentPosition_()
                                                        self.is_deleting = false
                                                        return response
                                                    end)
                                                else
                                                    self.is_deleting = false
                                                end
                                            else
                                                self.is_deleting = false
                                            end
                                        end
                                    end)
                                end
                            end
                        }
                    )
            end
        end):align(display.LEFT_CENTER,select_all_btn:getPositionX() + select_all_btn:getCascadeBoundingBox().size.width+gap_x,h/2-6):addTo(box)
    local mark_read_btn = WidgetPushButton.new({normal = "brown_btn_up_132x98.png",pressed = "brown_btn_down_132x98.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("标记已读"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                if self.sent_layer:isVisible() then
                    return
                end
                local select_map,select_type = self:GetSelectMailsOrReports()
                local ids = {}
                for k,v in pairs(select_map) do
                    if not v.isRead then
                        table.insert(ids, v.id)
                    end
                end
                if #ids>0 then
                    self:ReadMailOrReports(ids,function ()
                        self:SelectAllMailsOrReports(false)
                        if select_type=="mail" then
                            self.manager:DecreaseUnReadMailsNum(#ids)
                        elseif select_type=="report" then
                            self.manager:DecreaseUnReadReportsNum(#ids)
                        end
                    end)
                end
            end
        end):align(display.LEFT_CENTER,delete_btn:getPositionX() + delete_btn:getCascadeBoundingBox().size.width+gap_x,h/2-6):addTo(box)
    local cancel_btn = WidgetPushButton.new({normal = "brown_btn_up_132x98.png",pressed = "brown_btn_down_132x98.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("取消"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:SelectAllMailsOrReports(false)
            end
        end):align(display.LEFT_CENTER,mark_read_btn:getPositionX() + mark_read_btn:getCascadeBoundingBox().size.width+gap_x,h/2-6):addTo(box)

end
function GameUIMail:onExit()
    self.manager:RemoveListenerOnType(self,MailManager.LISTEN_TYPE.MAILS_CHANGED)
    self.manager:RemoveListenerOnType(self,MailManager.LISTEN_TYPE.REPORTS_CHANGED)
    self.manager:RemoveListenerOnType(self,MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED)
    GameUIMail.super.onExit(self)
end
function GameUIMail:CreateShopButton()
    local write_mail_button = WidgetPushButton.new(
        {normal = "home_btn_up.png", pressed = "home_btn_down.png"}
    ):onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            self:CreateMailContacts()
        end
    end)
    write_mail_button:align(display.RIGHT_TOP,  670, 86)
    cc.ui.UIImage.new("write_mail_58X46.png")
        :addTo(write_mail_button)
        :pos(-75, -48)
        :scale(0.8)
    return write_mail_button
end
function GameUIMail:CreateBetweenBgAndTitle()
    local parent = self
    self.inbox_layer = display.newLayer():addTo(self:GetView())
    local inbox_layer = self.inbox_layer
    function inbox_layer:ClearAll()
        parent.inbox_listview = nil
        self:removeAllChildren()
    end

    self.report_layer = display.newLayer():addTo(self:GetView())
    local report_layer = self.report_layer
    function report_layer:ClearAll()
        parent.report_listview = nil
        self:removeAllChildren()
    end

    self.saved_layer = display.newLayer():addTo(self:GetView())
    local saved_layer = self.saved_layer
    function saved_layer:ClearAll()
        parent.save_mails_listview = nil
        parent.saved_reports_listview = nil
        self.save_dropList = nil
        self:removeAllChildren()
    end

    self.sent_layer = display.newLayer():addTo(self:GetView())

    local sent_layer = self.sent_layer
    function sent_layer:ClearAll()
        parent.send_mail_listview = nil
        self:removeAllChildren()
    end
end

function GameUIMail:InitInbox(mails)
    self.inbox_listview = UIListView.new{
        async = true, --异步加载
        viewRect = cc.rect(display.cx-284, display.top-870, 568, 790),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(self.inbox_layer)
    self.inbox_listview:setRedundancyViewVal(200)
    self.inbox_listview:setDelegate(handler(self, self.DelegateInbox))
    if not mails then
        local promise = self.manager:FetchMailsFromServer(0)
        if promise then
            promise:done(function ( response )
                if self.inbox_listview then
                    self.inbox_listview:reload()
                end
                return response
            end)
        end
    end
    self.inbox_listview:reload()
end
function GameUIMail:DelegateInbox( listView, tag, idx )
    if cc.ui.UIListView.COUNT_TAG == tag then
        local mails = self.manager:GetMails()
        local mails_count = not mails and 0 or #mails
        return mails_count
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateInboxContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetData(idx)
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        -- 当取到客户端本地最后一封收件箱邮件后，请求服务器获得更多以前的邮件
        if idx == #self.manager:GetMails() then
            if not self.is_deleting then
                self.manager:FetchMailsFromServer(#self.manager:GetMails())
            end
        end
        return item
    elseif UIListView.ASY_REFRESH == tag then
        for i,v in ipairs(listView:getItems()) do
            if v.idx_ == idx then
                local content = v:getContent()
                content:SetData(idx)
                local size = content:getContentSize()
                v:setItemSize(size.width, size.height)
                if idx == #self.manager:GetMails() then
                    if not self.is_deleting then
                        self.manager:FetchMailsFromServer(#self.manager:GetMails())
                    end
                end
            end
        end
    end
end
function GameUIMail:CreateInboxContent()
    local item_width, item_height = 568,118
    local content = display.newNode()
    content:setContentSize(cc.size(item_width, item_height))
    -- 标题背景框
    local title_bg = display.newSprite("title_blue_482x30.png",item_width-482/2-2, item_height-24)
        :addTo(content,2)
    -- 不变的模板部分
    local content_title_bg = display.newScale9Sprite("back_ground_166x84.png",item_width-4,10,cc.size(482,60),cc.rect(15,10,136,64))
        :align(display.RIGHT_BOTTOM)
        :addTo(content,2)

    local from_name_label =  UIKit:ttfLabel(
        {
            size = 22,
            dimensions = cc.size(0,24),
            color = 0xffedae
        }):align(display.LEFT_CENTER, 10, 17)
        :addTo(title_bg)
    local date_label = UIKit:ttfLabel(
        {
            size = 16,
            dimensions = cc.size(0,0),
            color = 0xffedae
        }):align(display.RIGHT_CENTER, title_bg:getContentSize().width-30, 17)
        :addTo(title_bg)

    local mail_content_title_label =  UIKit:ttfLabel(
        {
            size = 20,
            color = 0x403c2f,
            ellipsis = true,
            dimensions = cc.size(370,20),
        }):align(display.LEFT_CENTER, 60, content_title_bg:getContentSize().height/2)
        :addTo(content_title_bg)


    local parent = self
    function content:SetData(idx,new_mail)
        local mail = new_mail or parent.manager:GetMails()[idx]
        self.mail = mail
        if self.bg_button then
            self.bg_button:removeFromParent(true)
            self.bg_button = nil
        end
        self.bg_button = WidgetPushButton.new({normal = "back_ground_568x118.png",pressed = "back_ground_568x118.png"})
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    parent:SelectAllMailsOrReports(false)
                    if tolua.type(mail.isRead)=="boolean" and not mail.isRead then
                        parent:ReadMailOrReports({mail.id},function ()
                            parent.manager:DecreaseUnReadMailsNum(1)
                        end)
                    end
                    --如果是发送邮件
                    if mail.toId then
                        parent:ShowSendMailDetails(mail)
                    else
                        parent:ShowMailDetails(mail)
                    end
                end
            end):addTo(self)
            :pos(item_width/2, item_height/2)

        title_bg:setTexture(mail.isRead and "title_grey_482x30.png" or "title_blue_482x30.png")
        if self.mail_icon then
            self.mail_icon:removeFromParent(true)
            self.mail_icon = nil
        end
        if not mail.isRead then
            self.mail_icon = display.newSprite(mail.fromId == "__system" and "icon_system_mail.png" or "mail_state_user_not_read.png")
                :align(display.LEFT_CENTER,11, 24):addTo(content_title_bg)
        end

        local from_name = Localize.mails[mail.fromName] or mail.fromName
        from_name_label:setString(_("From")..":"..((mail.fromAllianceTag~="" and "["..mail.fromAllianceTag.."]"..from_name) or from_name))
        from_name_label:setColor(mail.isRead and UIKit:hex2c4b(0x969696) or UIKit:hex2c4b(0xffedae))
        date_label:setString(GameUtils:formatTimeStyle2(mail.sendTime/1000))
        date_label:setColor(mail.isRead and UIKit:hex2c4b(0x969696) or UIKit:hex2c4b(0xffedae))
        mail_content_title_label:setString(mail.fromName == "__system" and _(mail.title) or mail.title)
        if mail.isRead then
            mail_content_title_label:setPositionX(10)
        else
            mail_content_title_label:setPositionX(60)
        end
        -- 保存按钮
        if self.saved_button then
            self.saved_button:removeFromParent(true)
        end
        self.saved_button = cc.ui.UICheckBoxButton.new({
            off = "mail_saved_button_normal.png",
            off_pressed = "mail_saved_button_normal.png",
            off_disabled = "mail_saved_button_normal.png",
            on = "mail_saved_button_pressed.png",
            on_pressed = "mail_saved_button_pressed.png",
            on_disabled = "mail_saved_button_pressed.png",
        }):setButtonSelected(tolua.type(mail.isSaved)=="nil" or mail.isSaved,true):onButtonStateChanged(function(event)
            parent:SaveOrUnsaveMail(mail,event.target)
        end):addTo(content_title_bg):align(display.RIGHT_CENTER, content_title_bg:getContentSize().width+4, content_title_bg:getContentSize().height/2)
        if self.check_box then
            self.check_box:removeFromParent(true)
        end
        self.check_box = parent:CreateCheckBox(self):align(display.LEFT_CENTER,14,item_height/2)
            :addTo(self)
    end

    function content:GetContentData()
        return self.mail
    end

    return content
end
function GameUIMail:InitSaveMails(mails)
    self.save_mails_listview = UIListView.new{
        async = true, --异步加载
        viewRect = cc.rect(display.cx-284, display.top-870, 568, 710),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(self.saved_layer)
    self.save_mails_listview:setRedundancyViewVal(200)
    self.save_mails_listview:setDelegate(handler(self, self.DelegateSavedMails))
    if not self.manager:GetSavedMails() then
        local promise =self.manager:FetchSavedMailsFromServer(0)
        if promise then
            promise:done(function ( response )
                if self.save_mails_listview then
                    self.save_mails_listview:reload()
                end
                return response
            end)
        end
    end
    self.save_mails_listview:reload()
end
function GameUIMail:DelegateSavedMails( listView, tag, idx )
    if cc.ui.UIListView.COUNT_TAG == tag then
        local saved_mails = self.manager:GetSavedMails()
        local mails_count = not saved_mails and 0 or #saved_mails
        return mails_count
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateSavedMailContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetData(idx)
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        -- 当取到客户端本地最后一封收藏邮件后，请求服务器获得更多以前的邮件
        if idx == #self.manager:GetSavedMails() then
            if not self.is_deleting then
                self.manager:FetchSavedMailsFromServer(#self.manager:GetSavedMails())
            end
        end
        return item
    elseif UIListView.ASY_REFRESH == tag then
        for i,v in ipairs(listView:getItems()) do
            if v.idx_ == idx then
                local content = v:getContent()
                content:SetData(idx)
                local size = content:getContentSize()
                v:setItemSize(size.width, size.height)
                -- 当取到客户端本地最后一封收藏邮件后，请求服务器获得更多以前的邮件
                if idx == #self.manager:GetSavedMails() then
                    if not self.is_deleting then
                        self.manager:FetchSavedMailsFromServer(#self.manager:GetSavedMails())
                    end
                end
            end
        end
    end
end
function GameUIMail:CreateSavedMailContent()
    local item_width, item_height = 568,118
    local content = display.newNode()
    content:setContentSize(cc.size(item_width, item_height))
    -- 标题背景框
    local title_bg = display.newSprite("title_blue_482x30.png",item_width-482/2-2, item_height-24)
        :addTo(content,2)
    -- 不变的模板部分
    local content_title_bg = display.newScale9Sprite("back_ground_166x84.png",item_width-4,10,cc.size(482,60),cc.rect(15,10,136,64))
        :align(display.RIGHT_BOTTOM)
        :addTo(content,2)

    local from_name_label =  UIKit:ttfLabel(
        {
            size = 22,
            dimensions = cc.size(0,24),
            color = 0xffedae
        }):align(display.LEFT_CENTER, 10, 17)
        :addTo(title_bg)
    local date_label = UIKit:ttfLabel(
        {
            size = 16,
            dimensions = cc.size(0,0),
            color = 0xffedae
        }):align(display.RIGHT_CENTER, title_bg:getContentSize().width-30, 17)
        :addTo(title_bg)

    local mail_content_title_label =  UIKit:ttfLabel(
        {
            size = 20,
            dimensions = cc.size(580,0),
            color = 0x403c2f
        }):align(display.LEFT_CENTER, 60, content_title_bg:getContentSize().height/2)
        :addTo(content_title_bg)


    local parent = self
    function content:SetData(idx,new_mail)
        local mail = new_mail or parent.manager:GetSavedMails()[idx]
        self.mail = mail
        if self.bg_button then
            self.bg_button:removeFromParent(true)
        end
        self.bg_button = WidgetPushButton.new({normal = "back_ground_568x118.png",pressed = "back_ground_568x118.png"})
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    parent:SelectAllMailsOrReports(false)
                    if tolua.type(mail.isRead)=="boolean" and not mail.isRead then
                        parent:ReadMailOrReports({mail.id},function ()
                            parent.manager:DecreaseUnReadMailsNum(1)
                        end)
                    end
                    --如果是发送邮件
                    if mail.toId then
                        parent:ShowSendMailDetails(mail)
                    else
                        parent:ShowMailDetails(mail)
                    end
                end
            end):addTo(self)
            :pos(item_width/2, item_height/2)
        title_bg:setTexture(mail.isRead and "title_grey_482x30.png" or "title_blue_482x30.png")

        local mail_icon = display.newSprite(mail.fromId == "__system" and "icon_system_mail.png" or "mail_state_user_not_read.png")
            :align(display.LEFT_CENTER,11, 24):addTo(content_title_bg)

        local from_name = Localize.mails[mail.fromName] or mail.fromName
        from_name_label:setString(_("From")..":"..((mail.fromAllianceTag~="" and "["..mail.fromAllianceTag.."]"..from_name) or from_name))
        date_label:setString(GameUtils:formatTimeStyle2(mail.sendTime/1000))
        mail_content_title_label:setString(mail.title)

        -- 保存按钮
        if self.saved_button then
            self.saved_button:removeFromParent(true)
        end
        self.saved_button = cc.ui.UICheckBoxButton.new({
            off = "mail_saved_button_normal.png",
            off_pressed = "mail_saved_button_normal.png",
            off_disabled = "mail_saved_button_normal.png",
            on = "mail_saved_button_pressed.png",
            on_pressed = "mail_saved_button_pressed.png",
            on_disabled = "mail_saved_button_pressed.png",
        }):setButtonSelected(tolua.type(mail.isSaved)=="nil" or mail.isSaved,true):onButtonStateChanged(function(event)
            parent:SaveOrUnsaveMail(mail,event.target)
        end):addTo(content_title_bg):align(display.RIGHT_CENTER, content_title_bg:getContentSize().width+4, content_title_bg:getContentSize().height/2)
        if self.check_box then
            self.check_box:removeFromParent(true)
        end
        self.check_box = parent:CreateCheckBox(self):align(display.LEFT_CENTER,14,item_height/2)
            :addTo(self)
    end

    function content:GetContentData()
        return self.mail
    end

    return content
end
function GameUIMail:InitSendMails(mails)
    self.send_mail_listview = UIListView.new{
        async = true, --异步加载
        viewRect = cc.rect(display.cx-284, display.top-870, 568, 790),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(self.sent_layer)
    self.send_mail_listview:setRedundancyViewVal(200)
    self.send_mail_listview:setDelegate(handler(self, self.DelegateSendMails))
    if not mails then
        local promise = self.manager:FetchSendMailsFromServer(0)
        if promise then
            promise:done(function ( response )
                if self.send_mail_listview then
                    self.send_mail_listview:reload()
                end
                return response
            end)
        end
    end
    self.send_mail_listview:reload()
end
function GameUIMail:DelegateSendMails( listView, tag, idx )
    if cc.ui.UIListView.COUNT_TAG == tag then
        local send_mails = self.manager:GetSendMails()
        local mails_count = not send_mails and 0 or #send_mails
        return mails_count
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateSendMailContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        if content.SetData then
            content:SetData(idx)
            local size = content:getContentSize()
            item:setItemSize(size.width, size.height)
            -- 当取到客户端本地最后一封发件箱邮件后，请求服务器获得更多以前的邮件
            if idx == #self.manager:GetSendMails() then
                self.manager:FetchSendMailsFromServer(#self.manager:GetSendMails())
            end
        else
            listView:unloadOneItem_(idx)
        end
        return item
    elseif UIListView.ASY_REFRESH == tag then
        for i,v in ipairs(listView:getItems()) do
            if v.idx_ == idx then
                local content = v:getContent()
                if not content.SetData then
                    listView:unloadOneItem_(idx)
                else
                    content:SetData(idx)
                    local size = content:getContentSize()
                    v:setItemSize(size.width, size.height)
                    -- 当取到客户端本地最后一封发件箱邮件后，请求服务器获得更多以前的邮件
                    if idx == #self.manager:GetSendMails() then
                        self.manager:FetchSendMailsFromServer(#self.manager:GetSendMails())
                    end
                end
            end
        end
    end
end
function GameUIMail:CreateSendMailContent()
    local item_width, item_height = 568,118
    local content = display.newNode()
    content:setContentSize(cc.size(item_width, item_height))
    -- 标题背景框
    local title_bg = display.newScale9Sprite("title_grey_482x30.png",item_width/2 + 39, item_height-24,cc.size(482,30),cc.rect(10,5,462,20))
        :addTo(content,2)
    -- 不变的模板部分
    local content_title_bg = display.newScale9Sprite("back_ground_166x84.png",item_width-4,10,cc.size(482,60),cc.rect(15,10,136,64))
        :align(display.RIGHT_BOTTOM)
        :addTo(content,2)

    local from_name_label =  UIKit:ttfLabel(
        {
            size = 22,
            dimensions = cc.size(0,24),
            color = 0xffedae
        }):align(display.LEFT_CENTER, 10, 17)
        :addTo(title_bg)
    local date_label = UIKit:ttfLabel(
        {
            size = 16,
            dimensions = cc.size(0,0),
            color = 0xffedae
        }):align(display.RIGHT_CENTER, title_bg:getContentSize().width-30, 17)
        :addTo(title_bg)

    local mail_content_title_label =  UIKit:ttfLabel(
        {
            size = 20,
            dimensions = cc.size(580,0),
            color = 0x403c2f
        }):align(display.LEFT_CENTER, 60, content_title_bg:getContentSize().height/2)
        :addTo(content_title_bg)


    local parent = self
    function content:SetData(idx,new_mail)
        local mail = new_mail or parent.manager:GetSendMails()[idx]
        self.mail = mail
        if self.bg_button then
            self.bg_button:removeFromParent(true)
        end
        self.bg_button = WidgetPushButton.new({normal = "back_ground_568x118.png",pressed = "back_ground_568x118.png"})
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    parent:SelectAllMailsOrReports(false)
                    if tolua.type(mail.isRead)=="boolean" and not mail.isRead then
                        parent:ReadMailOrReports({mail.id},function ()
                            parent.manager:DecreaseUnReadMailsNum(1)
                        end)
                    end
                    parent:ShowSendMailDetails(mail)
                end
            end):addTo(self)
            :pos(item_width/2, item_height/2)

        local mail_icon = display.newSprite(mail.fromId == "__system" and "icon_system_mail.png" or "mail_state_user_not_read.png")
            :align(display.LEFT_CENTER,11, 24):addTo(content_title_bg)
        local name = Localize.mails[mail.fromName] or mail.fromName
        from_name_label:setString(_("From")..":"..((mail.fromAllianceTag~="" and "["..mail.fromAllianceTag.."]".. name or name)))
        date_label:setString(GameUtils:formatTimeStyle2(mail.sendTime/1000))
        mail_content_title_label:setString(mail.title)
        if self.check_box then
            self.check_box:removeFromParent(true)
        end
        self.check_box = parent:CreateCheckBox(self):align(display.LEFT_CENTER,14,item_height/2)
            :addTo(self)
    end

    function content:GetContentData()
        return self.mail
    end

    return content
end

function GameUIMail:CreateCheckBox(content)
    local checkbox_bg = display.newSprite("box_62X98.png")

    --  选择checkbox
    local checkbox_image = {
        off = "checkbox_unselected.png",
        off_pressed = "checkbox_unselected.png",
        off_disabled = "checkbox_unselected.png",
        on = "checkbox_selectd.png",
        on_pressed = "checkbox_selectd.png",
        on_disabled = "checkbox_selectd.png",
    }
    local check_box = cc.ui.UICheckBoxButton.new(checkbox_image)
        :align(display.CENTER,checkbox_bg:getContentSize().width/2,checkbox_bg:getContentSize().height/2)
        :onButtonStateChanged(function(event)
            self:SelectItems(content:GetContentData(),event.state == "on")
        end)
        :setButtonSelected(
            not (self.un_selected_items and self.un_selected_items[content:GetContentData().id]) and
            (self.selected_items and self.selected_items[content:GetContentData().id] or self.is_select_all))
        :addTo(checkbox_bg)
    return checkbox_bg
end
function GameUIMail:GetCurrentSelectType()
    if self.inbox_layer:isVisible()
        or (self.saved_layer:isVisible() and self.save_mails_listview and self.save_mails_listview:isVisible())
    then
        return "mail"
    elseif self.report_layer:isVisible()
        or (self.saved_layer:isVisible() and self.saved_reports_listview:isVisible())
    then
        return "report"
    elseif self.sent_layer:isVisible() then
        return "send_mails"
    end
end
-- @parms source_data : mail(map) or report对象
function GameUIMail:SelectItems(source_data,isSelected)
    if not self.selected_items then -- 选中列表
        self.selected_items = {}
    end
    if not self.un_selected_items then -- 取消选中列表
        self.un_selected_items = {}
    end

    if isSelected then
        self.selected_items[source_data.id] = source_data
        self.un_selected_items[source_data.id] = nil
    else
        self.selected_items[source_data.id] = nil
        self.un_selected_items[source_data.id] = source_data
    end

    self.mail_control_box:setVisible(LuaUtils:table_size(self.selected_items)>0)
end
function GameUIMail:GetSelectMailsOrReports()
    local select_type
    if self.inbox_layer:isVisible() then
        select_type = "mail"
    elseif self.report_layer:isVisible() then
        select_type = "report"
    elseif self.saved_layer:isVisible() and self.saved_reports_listview:isVisible() then
        select_type = "report"
    elseif self.saved_layer:isVisible() and self.save_mails_listview:isVisible() then
        select_type = "mail"
    elseif self.sent_layer:isVisible() then
        select_type = "send_mails"
    end
    return self.selected_items,select_type
end
function GameUIMail:SelectAllMailsOrReports(isSelect)
    self.is_select_all = isSelect
    if not isSelect then
        self.selected_items = {}
        self.un_selected_items = {}
    end
    if self.inbox_layer:isVisible() then
        for i,v in ipairs(self.manager:GetMails()) do
            self:SelectItems(v,isSelect)
        end
        self.inbox_listview:asyncLoadWithCurrentPosition_()
    elseif self.report_layer:isVisible() then
        for i,v in ipairs(self.manager:GetReports()) do
            self:SelectItems(v,isSelect)
        end
        self.report_listview:asyncLoadWithCurrentPosition_()
    elseif self.saved_layer:isVisible() then
        if self.save_mails_listview and self.save_mails_listview:isVisible() then
            for i,v in ipairs(self.manager:GetSavedMails()) do
                self:SelectItems(v,isSelect)
            end
            self.save_mails_listview:asyncLoadWithCurrentPosition_()
        elseif self.saved_reports_listview and self.saved_reports_listview:isVisible() then
            for i,v in ipairs(self.manager:GetSavedReports()) do
                self:SelectItems(v,isSelect)
            end
            self.saved_reports_listview:asyncLoadWithCurrentPosition_()
        end
    elseif self.sent_layer:isVisible() then
        for i,v in ipairs(self.manager:GetSendMails()) do
            self:SelectItems(v,isSelect)
        end
        self.send_mail_listview:asyncLoadWithCurrentPosition_()
    end
end
function GameUIMail:SaveOrUnsaveMail(mail,target)
    if target:isButtonSelected() then
        NetManager:getSaveMailPromise(mail.id):fail(function()
            target:setButtonSelected(false,true)
        end)
    else
        NetManager:getUnSaveMailPromise(mail.id):fail(function()
            target:setButtonSelected(true,true)
        end)
    end
end

function GameUIMail:ReadMailOrReports(Ids,cb)
    local control_type = self:GetCurrentSelectType()
    if control_type == "mail" then
        NetManager:getReadMailsPromise(Ids):done(cb)
    elseif control_type == "report" then
        NetManager:getReadReportsPromise(Ids):done(cb)
    end
end


function GameUIMail:OnInboxMailsChanged(changed_mails)
    if not self.inbox_listview then
        return
    end
    if changed_mails.add_mails then
        if #changed_mails.add_mails > 0 then
            self.inbox_listview:asyncLoadWithCurrentPosition_()
        end
    end
    if changed_mails.edit_mails then
        for _,edit_mail in pairs(changed_mails.edit_mails) do
            for i,listitem in ipairs(self.inbox_listview:getItems()) do
                local content = listitem:getContent()
                local content_mail = content:GetContentData()
                if content_mail.id == edit_mail.id then
                    content:SetData(nil,edit_mail)
                end
            end
        end
    end
    if changed_mails.remove_mails then
        if #changed_mails.remove_mails > 0 then
            self.inbox_listview:asyncLoadWithCurrentPosition_()
        end
    end
end

function GameUIMail:OnSavedMailsChanged(changed_mails)
    if not self.save_mails_listview then
        return
    end
    if changed_mails.add_mails then
        if #changed_mails.add_mails > 0 then
            self.save_mails_listview:asyncLoadWithCurrentPosition_()
        end
    end

    if changed_mails.remove_mails then
        if #changed_mails.remove_mails > 0 then
            self.save_mails_listview:asyncLoadWithCurrentPosition_()
        end
    end
    if changed_mails.edit_mails then
        for _,edit_mail in pairs(changed_mails.edit_mails) do
            if self.save_mails_listview then
                for i,listitem in ipairs(self.save_mails_listview:getItems()) do
                    local content = listitem:getContent()
                    local content_mail = content:GetContentData()
                    if content_mail.id == edit_mail.id then
                        content:SetData(nil,edit_mail)
                    end
                end
            end
        end
    end
end
function GameUIMail:OnSendMailsChanged(changed_mails)
    if not self.send_mail_listview then
        return
    end
    if changed_mails.add_mails then
        if #changed_mails.add_mails > 0 then
            self.send_mail_listview:asyncLoadWithCurrentPosition_()
        end
    end

    if changed_mails.remove_mails then
        if #changed_mails.remove_mails > 0 then
            self.send_mail_listview:asyncLoadWithCurrentPosition_()
        end
    end
end
function GameUIMail:MailUnreadChanged(unreads)
    local mail_bg = self.mail_unread_num_bg
    local mail_label = self.mail_unread_num_label
    local report_bg = self.report_unread_num_bg
    local report_label = self.report_unread_num_label
    if unreads.mail then
        if unreads.mail > 0  then
            mail_bg:setVisible(true)
            mail_label:setString(unreads.mail > 99 and "99+" or unreads.mail)
        else
            mail_bg:setVisible(false)
            mail_label:setString("")
        end
    end
    if unreads.report then
        if unreads.report > 0 then
            report_bg:setVisible(true)
            report_label:setString(unreads.report > 99 and "99+" or unreads.report)
        else
            report_bg:setVisible(false)
            report_label:setString("")
        end
    end
end

--已发送邮件详情弹出框
function GameUIMail:ShowSendMailDetails(mail)
    local title_string = (mail.fromAllianceTag~="" and "["..mail.fromAllianceTag.."] "..mail.fromName) or mail.fromName
    local dialog = WidgetPopDialog.new(748,title_string):addTo(self,201)
    local bg = dialog:GetBody()
    local size = bg:getContentSize()

    -- mail content bg
    local content_bg = WidgetUIBackGround.new({width=568,height = 494},WidgetUIBackGround.STYLE_TYPE.STYLE_5):addTo(bg)
    content_bg:align(display.LEFT_BOTTOM,(bg:getContentSize().width-content_bg:getContentSize().width)/2,80)

    -- player head icon
    UIKit:GetPlayerCommonIcon(mail.fromIcon):align(display.CENTER, 76, bg:getContentSize().height - 90):addTo(bg)
    -- 收件人
    local subject_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("收件人")..": ",
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.LEFT_CENTER, 155, bg:getContentSize().height-60)
        :addTo(bg)
    local subject_content_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = Localize.mails[mail.toName] or mail.toName,
            font = UIKit:getFontFilePath(),
            size = 20,
            dimensions = cc.size(0,24),
            color = UIKit:hex2c3b(0x403c2f)
        }):align(display.LEFT_CENTER,155 + subject_label:getContentSize().width+20, bg:getContentSize().height-60)
        :addTo(bg)
    -- 主题
    local subject_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("主题")..": ",
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.LEFT_CENTER, 155, bg:getContentSize().height-100)
        :addTo(bg)
    local subject_content_label = UIKit:ttfLabel(
        {
            text = mail.title,
            size = 20,
            color = 0x403c2f,
            ellipsis = true,
            dimensions = cc.size(300,20)
        }):align(display.LEFT_CENTER,155 + subject_label:getContentSize().width+20, bg:getContentSize().height-96)
        :addTo(bg)
    -- 日期
    local date_title_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("日期")..": ",
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.LEFT_CENTER, 155, bg:getContentSize().height-140)
        :addTo(bg)
    local date_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = GameUtils:formatTimeStyle2(mail.sendTime/1000),
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x403c2f)
        }):align(display.LEFT_CENTER, 155 + date_title_label:getContentSize().width+20, bg:getContentSize().height-140)
        :addTo(bg)
    -- 删除按钮
    local delete_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("删除"),
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)})
    delete_label:enableShadow()

    local del_btn = WidgetPushButton.new(
        {normal = "red_btn_up_148x58.png", pressed = "red_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(delete_label)
        :addTo(bg):align(display.CENTER, size.width/2, 42)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                NetManager:getDeleteSendMailsPromise({mail.id}):done(function ()
                    dialog:LeftButtonClicked()
                end)
            end
        end)
    -- 内容
    local content_listview = UIListView.new{
        viewRect = cc.rect(0, 10, 550, 470),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(content_bg):pos(10, 0)
    local content_item = content_listview:newItem()
    local content_label = UIKit:ttfLabel(
        {
            text = mail.content,
            size = 20,
            dimensions = cc.size(550,0),
            color = 0x403c2f
        }):align(display.LEFT_TOP)
    content_item:setItemSize(570,content_label:getContentSize().height)
    content_item:addContent(content_label)
    content_listview:addItem(content_item)
    content_listview:reload()
end
--邮件详情弹出框
function GameUIMail:ShowMailDetails(mail)
    local name = Localize.mails[mail.fromName] or mail.fromName
    local title_string = (mail.fromAllianceTag~="" and "["..mail.fromAllianceTag.."] "..name) or name
    local dialog = WidgetPopDialog.new(768,title_string):addTo(self,201)
    local body = dialog:GetBody()
    local size = body:getContentSize()

    local content_bg = WidgetUIBackGround.new({width=568,height = 544},WidgetUIBackGround.STYLE_TYPE.STYLE_5):addTo(body)
    content_bg:pos((size.width-content_bg:getContentSize().width)/2,80)

    -- player head icon
    UIKit:GetPlayerCommonIcon(mail.fromIcon):align(display.CENTER, 76, size.height - 80):addTo(body)

    -- 主题
    local subject_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("主题: "),
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.LEFT_CENTER, 155, size.height-60)
        :addTo(body)
    local subject_content_label = UIKit:ttfLabel(
        {
            text = mail.title,
            size = 20,
            color = 0x403c2f,
            ellipsis = true,
            dimensions = cc.size(300,20)
        }):align(display.LEFT_CENTER,155 + subject_label:getContentSize().width+20, size.height-56)
        :addTo(body)
    -- 日期
    local date_title_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("日期: "),
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.LEFT_CENTER, 155, size.height-100)
        :addTo(body)
    local date_label = UIKit:ttfLabel(
        {
            text = GameUtils:formatTimeStyle2(mail.sendTime/1000),
            size = 20,
            color = 0x403c2f
        }):align(display.LEFT_CENTER, 155 + date_title_label:getContentSize().width+20, size.height-100)
        :addTo(body)
    -- 内容
    local content_listview = UIListView.new{
        viewRect = cc.rect(0, 10, 550, 520),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(content_bg):pos(10, 0)
    local content_item = content_listview:newItem()
    local mail_content = mail.content
    if mail.fromName == "__system" then
        for k,v in pairs(Localize.mails) do
            mail_content = string.gsub(mail_content, k, v)
        end
    end
    local content_label = UIKit:ttfLabel(
        {
            text = mail_content,
            size = 20,
            dimensions = cc.size(550,0),
            color = 0x403c2f
        }):align(display.LEFT_TOP)
    content_item:setItemSize(570,content_label:getContentSize().height)
    content_item:addContent(content_label)
    content_listview:addItem(content_item)
    content_listview:reload()

    if tolua.type(mail.isSaved)~="nil" then
        -- 删除按钮
        local delete_label = cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("删除"),
            size = 20,
            font = UIKit:getFontFilePath(),
            color = UIKit:hex2c3b(0xfff3c7)})
        delete_label:enableShadow()

        local del_btn = WidgetPushButton.new(
            {normal = "red_btn_up_148x58.png", pressed = "red_btn_down_148x58.png"},
            {scale9 = false}
        ):setButtonLabel(delete_label)
            :addTo(body):align(display.CENTER, 92, 42)
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    NetManager:getDeleteMailsPromise({mail.id}):done(function ()
                        dialog:LeftButtonClicked()
                    end)
                end
            end)
        if mail.fromId ~="__system" then
            -- 回复按钮
            local replay_label = cc.ui.UILabel.new({
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = _("回复"),
                size = 20,
                font = UIKit:getFontFilePath(),
                color = UIKit:hex2c3b(0xfff3c7)})

            replay_label:enableShadow()
            WidgetPushButton.new(
                {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
                {scale9 = false}
            ):setButtonLabel(replay_label)
                :addTo(body):align(display.CENTER, size.width-92, 42)
                :onButtonClicked(function(event)
                    dialog:LeftButtonClicked()
                    self:OpenReplyMail(mail)
                end)
        else
            del_btn:setPositionX(size.width/2)
        end
    end
    -- 收藏按钮
    local saved_button = cc.ui.UICheckBoxButton.new({
        off = "mail_saved_button_normal.png",
        off_pressed = "mail_saved_button_normal.png",
        off_disabled = "mail_saved_button_normal.png",
        on = "mail_saved_button_pressed.png",
        on_pressed = "mail_saved_button_pressed.png",
        on_disabled = "mail_saved_button_pressed.png",
    }):setButtonSelected(tolua.type(mail.isSaved)=="nil" or mail.isSaved,true):onButtonStateChanged(function(event)
        self:SaveOrUnsaveMail(mail,event.target)
    end):addTo(body):pos(size.width-48, size.height-80)
end

-- report layer
function GameUIMail:InitReport()
    local flag = true
    self.report_listview = UIListView.new{
        async = true, --异步加载
        viewRect = cc.rect(display.cx-284, display.top-870, 568, 790),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(self.report_layer)
    self.report_listview:setRedundancyViewVal(200)
    self.report_listview:setDelegate(handler(self, self.DelegateReport))
    if not self.manager:GetReports() then
        local promise = self.manager:FetchReportsFromServer(0)
        if promise then
            promise:done(function ( response )
                if self.report_listview then
                    self.report_listview:reload()
                end
                return response
            end)
        end
    end
    self.report_listview:reload()
end

function GameUIMail:DelegateReport( listView, tag, idx )
    if cc.ui.UIListView.COUNT_TAG == tag then
        local reports = self.manager:GetReports()
        local count = not reports and 0 or #reports
        return count
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateReportContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetData(idx)
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        -- 当取到客户端本地最后一封战报后，请求服务器获得更多以前的战报
        if idx == #self.manager:GetReports() then
            if not self.is_deleting then
                self.manager:FetchReportsFromServer(#self.manager:GetReports())
            end
        end

        return item
    elseif UIListView.ASY_REFRESH == tag then
        for i,v in ipairs(listView:getItems()) do
            if v.idx_ == idx then
                local content = v:getContent()
                content:SetData(idx)
                local size = content:getContentSize()
                v:setItemSize(size.width, size.height)
                -- 当取到客户端本地最后一封战报后，请求服务器获得更多以前的战报
                if idx == #self.manager:GetReports() then
                    if not self.is_deleting then
                        self.manager:FetchReportsFromServer(#self.manager:GetReports())
                    end
                end
            end
        end
    end
end
function GameUIMail:CreateReportContent()
    local item_width, item_height = 568,150
    local content = display.newNode()
    content:setContentSize(cc.size(item_width, item_height))
    local parent = self
    function content:GetContentData()
        return self.report
    end
    function content:SetData(idx,report)
        self:removeAllChildren()
        local report = report or parent.manager:GetReports()[idx]
        self.report = report
        local c_size = self:getContentSize()
        WidgetPushButton.new({normal = "back_ground_568x150.png"})
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    parent:SelectAllMailsOrReports(false)
                    if not report:IsRead() then
                        parent:ReadMailOrReports({report:Id()}, function ()
                            parent.manager:DecreaseUnReadReportsNum(1)
                        end)
                    end
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
                end
            end):addTo(self):pos(item_width/2, item_height/2)

        local c_size = self:getContentSize()
        local title_bg_image
        if report:IsRead() then
            title_bg_image = "title_grey_558x34.png"
        else
            if report:IsWin() then
                title_bg_image = "title_green_558x34.png"
            else
                title_bg_image = "title_red_556x34.png"
            end
        end
        local title_bg = display.newSprite(title_bg_image, item_width/2, 52+item_height/2):addTo(self)
        local report_title =  UIKit:ttfLabel(
            {
                text = report:GetReportTitle(),
                size = 22,
                color = 0xffedae
            }):align(display.LEFT_CENTER, 30, 17)
            :addTo(title_bg)
        local date_label =  UIKit:ttfLabel(
            {
                text = GameUtils:formatTimeStyle2(math.floor(report.createTime/1000)),
                size = 16,
                color = 0xffedae
            }):align(display.RIGHT_CENTER, 540, 17)
            :addTo(title_bg)
        local report_content_bg = WidgetUIBackGround.new({width = 484,height = 98},WidgetUIBackGround.STYLE_TYPE.STYLE_4)
            :align(display.CENTER, 35+item_width/2, -18+item_height/2):addTo(self)

        local report_big_type = report:IsAttackOrStrike()
        if report_big_type == "strike" then
            display.newSprite("icon_strike_69x50.png"):align(display.LEFT_BOTTOM, 0, 0):addTo(report_content_bg):scale(0.8)
            display.newSprite("icon_strike_69x50.png"):align(display.LEFT_BOTTOM, 410, 0):addTo(report_content_bg):flipX(true):scale(0.8)
        elseif report_big_type == "attack" then
            display.newSprite("icon_attack_76x88.png"):align(display.CENTER, 80, 47):addTo(report_content_bg)
            display.newSprite("icon_attack_76x88.png"):align(display.CENTER, 310, 47):addTo(report_content_bg)
        end
        local isFromMe = report:IsFromMe()
        if isFromMe == "collectResource" then
            local rewards = report:GetMyRewards()[1]
            UIKit:ttfLabel(
                {
                    text = _("资源采集报告"),
                    size = 20,
                    color = 0x403c2f
                }):align(display.CENTER, report_content_bg:getContentSize().width/2-20, 60)
                :addTo(report_content_bg)
            display.newSprite(UILib.resource[rewards.name], 190, 30):addTo(report_content_bg):scale(0.4)
            UIKit:ttfLabel(
                {
                    text = "+"..string.formatnumberthousands(rewards.count),
                    size = 20,
                    color = 0x403c2f
                }):align(display.LEFT_CENTER, report_content_bg:getContentSize().width/2-20, 30)
                :addTo(report_content_bg)
        elseif isFromMe == "attackMonster" then
            local monster_level = report:GetAttackTarget().level
            local monster_data = report:GetEnemyPlayerData().soldiers[1]
            local soldier_type = monster_data.name
            local soldier_star = monster_data.star
            local soldier_ui_config = UILib.black_soldier_image[soldier_type][tonumber(soldier_star)]

            display.newSprite(UILib.black_soldier_color_bg_images[soldier_type]):addTo(report_content_bg)
                :align(display.CENTER_TOP,180, 86):scale(80/128)

            local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER_TOP,180, 86):addTo(report_content_bg)
            soldier_head_icon:scale(80/soldier_head_icon:getContentSize().height)
            display.newSprite("box_soldier_128x128.png")
                :align(display.CENTER, soldier_head_icon:getContentSize().width/2, soldier_head_icon:getContentSize().height-64)
                :addTo(soldier_head_icon)

            UIKit:ttfLabel(
                {
                    text = _("黑龙军团"),
                    size = 18,
                    color = 0x615b44
                }):align(display.LEFT_CENTER, report_content_bg:getContentSize().width/2-10, 70)
                :addTo(report_content_bg)
            UIKit:ttfLabel(
                {
                    text = Localize.soldier_name[soldier_type] .. " " ..string.format(_("等级%s"),monster_level),
                    size = 20,
                    color = 0x403c2f
                }):align(display.LEFT_CENTER, report_content_bg:getContentSize().width/2-10, 25)
                :addTo(report_content_bg)
        elseif isFromMe == "attackShrine" then
            display.newScale9Sprite("alliance_shrine.png"):addTo(report_content_bg)
                :align(display.CENTER_TOP,160, 80):scale(0.6)
            -- 圣地关卡名字
            local attackTarget = report:GetAttackTarget()
            UIKit:ttfLabel(
                {
                    text = string.gsub(attackTarget.stageName,"_","-")..Localize.shrine_desc[attackTarget.stageName][1],
                    size = 18,
                    color = 0x403c2f
                }):align(display.LEFT_CENTER, report_content_bg:getContentSize().width/2-20, 60)
                :addTo(report_content_bg)
            print("attackTarget.fightStar=",attackTarget.fightStar)
            StarBar.new({
                max = 3,
                bg = "alliance_shire_star_60x58_0.png",
                fill = "alliance_shire_star_60x58_1.png",
                num = attackTarget.fightStar
            }):addTo(report_content_bg):align(display.LEFT_CENTER,report_content_bg:getContentSize().width/2-20, 30):scale(0.5)
        else
            -- 战报发出方信息
            -- 旗帜
            local my_flag_data = report:GetMyPlayerData().alliance.flag
            local enemy_flag_data = report:GetEnemyPlayerData().alliance.flag

            local a_helper = WidgetAllianceHelper.new()
            local my_flag = a_helper:CreateFlagContentSprite(Flag:DecodeFromJson(my_flag_data))
            local enemy_flag = a_helper:CreateFlagContentSprite(Flag:DecodeFromJson(enemy_flag_data))
            my_flag:scale(0.55)
            enemy_flag:scale(0.55)
            my_flag:align(display.CENTER, isFromMe and 48 or 278, 8)
                :addTo(report_content_bg)
            enemy_flag:align(display.CENTER, isFromMe and 278 or 48, 8)
                :addTo(report_content_bg)
            -- from title label
            local from_label = UIKit:ttfLabel(
                {
                    text = _("From"),
                    size = 16,
                    color = 0x615b44
                }):align(display.LEFT_CENTER, 120, 70)
                :addTo(report_content_bg)
            -- 发出方名字
            local from_player_label =  UIKit:ttfLabel(
                {
                    text = isFromMe and parent:GetMyName(report) or parent:GetEnemyName(report),
                    size = 20,
                    color = 0x403c2f,
                    dimensions = cc.size(150,20),
                    ellipsis = true
                }):align(display.LEFT_CENTER, 120, 50)
                :addTo(report_content_bg)
            -- 发出方所属联盟
            local from_alliance_label = UIKit:ttfLabel(
                {
                    text = isFromMe and "["..parent:GetMyAllianceTag(report).."]" or "["..parent:GetEnemyAllianceTag(report).."]",
                    size = 20,
                    color = 0x403c2f
                }):align(display.LEFT_CENTER, 120, 27)
                :addTo(report_content_bg)


            -- 战报发向方信息
            -- to title label
            local to_label = UIKit:ttfLabel(
                {
                    text = _("To"),
                    size = 16,
                    color = 0x615b44
                }):align(display.LEFT_CENTER, 350, 70)
                :addTo(report_content_bg)
            -- 发向方名字
            local to_player_label = UIKit:ttfLabel(
                {
                    text = isFromMe and parent:GetEnemyName(report) or parent:GetMyName(report),
                    size = 20,
                    color = 0x403c2f,
                    dimensions = cc.size(150,20),
                    ellipsis = true
                }):align(display.LEFT_CENTER, 350, 50)
                :addTo(report_content_bg)
            -- 发向方所属联盟
            local to_alliance_label = UIKit:ttfLabel(
                {
                    text = isFromMe and "["..parent:GetEnemyAllianceTag(report).."]" or "["..parent:GetMyAllianceTag(report).."]",
                    size = 20,
                    color = 0x403c2f
                }):align(display.LEFT_CENTER, 350, 27)
                :addTo(report_content_bg)
        end

        cc.ui.UICheckBoxButton.new({
            off = "report_saved_button_normal.png",
            off_pressed = "report_saved_button_normal.png",
            off_disabled = "report_saved_button_normal.png",
            on = "report_saved_button_selected.png",
            on_pressed = "report_saved_button_selected.png",
            on_disabled = "report_saved_button_selected.png",
        }):onButtonStateChanged(function(event)
            parent:SaveOrUnsaveReport(report,event.target)
        end):addTo(self):pos(249+item_width/2, -41+item_height/2)
            :setButtonSelected(report:IsSaved(),true)

        parent:CreateCheckBox(self):align(display.LEFT_CENTER,10,-18+item_height/2)
            :addTo(self)
    end


    return content
end

function GameUIMail:InitSavedReports()
    local dropList = WidgetRoundTabButtons.new(
        {
            {tag = "menu_1",label = _("战报"),default = true},
            {tag = "menu_2",label = _("邮件")},
        },
        function(tag)
            if tag == 'menu_2' then
                local saved_mails = self.manager:GetSavedMails()
                self:InitSaveMails(saved_mails)
                self.save_mails_listview:show()

                self.saved_reports_listview:hide()
            end
            if tag == 'menu_1' then
                if self.save_mails_listview then
                    self.save_mails_listview:setVisible(false)
                end
                self.saved_reports_listview = UIListView.new{
                    async = true, --异步加载
                    viewRect = cc.rect(display.cx-284, display.top-870, 568, 710),
                    direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
                }:addTo(self.saved_layer)

                self.saved_reports_listview:setRedundancyViewVal(200)
                self.saved_reports_listview:setDelegate(handler(self, self.DelegateSavedReport))
                if not self.manager:GetSavedReports() then
                    local promise = self.manager:FetchSavedReportsFromServer(0)
                    if promise then
                        promise:done(function ( response )
                            if self.saved_reports_listview then
                                self.saved_reports_listview:reload()
                            end
                            return response
                        end)
                    end
                end
                self.saved_reports_listview:reload()

                self.saved_reports_listview:setVisible(true)
            end
        end
    )
    dropList:align(display.TOP_CENTER,display.cx,display.top-80):addTo(self.saved_layer,2)
    self.save_dropList = dropList
end

function GameUIMail:DelegateSavedReport( listView, tag, idx )
    if cc.ui.UIListView.COUNT_TAG == tag then
        local saved_reports = self.manager:GetSavedReports()
        local count = not saved_reports and 0 or #saved_reports
        return count
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateSavedReportContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetData(idx)
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        -- 当取到客户端本地最后一封战报后，请求服务器获得更多以前的战报
        if idx == #self.manager:GetSavedReports() then
            if not self.is_deleting then
                self.manager:FetchSavedReportsFromServer(#self.manager:GetSavedReports())
            end
        end
        return item
    elseif UIListView.ASY_REFRESH == tag then
        for i,v in ipairs(listView:getItems()) do
            if v.idx_ == idx then
                local content = v:getContent()
                content:SetData(idx)
                local size = content:getContentSize()
                v:setItemSize(size.width, size.height)
                -- 当取到客户端本地最后一封战报后，请求服务器获得更多以前的战报
                if idx == #self.manager:GetSavedReports() then
                    if not self.is_deleting then
                        self.manager:FetchSavedReportsFromServer(#self.manager:GetSavedReports())
                    end
                end
            end
        end
    end
end
function GameUIMail:CreateSavedReportContent()
    local item_width, item_height = 568,150
    local content = display.newNode()
    content:setContentSize(cc.size(item_width, item_height))
    local parent = self
    function content:GetContentData()
        return self.report
    end
    function content:SetData(idx,new_report)
        self:removeAllChildren()
        local report = new_report or parent.manager:GetSavedReports()[idx]
        self.report = report
        local c_size = self:getContentSize()
        WidgetPushButton.new({normal = "back_ground_568x150.png"})
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    parent:SelectAllMailsOrReports(false)
                    if not report:IsRead() then
                        parent:ReadMailOrReports({report:Id()}, function ()
                            parent.manager:DecreaseUnReadReportsNum(1)
                        end)
                    end
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

                end
            end):addTo(self):pos(item_width/2, item_height/2)

        local c_size = self:getContentSize()
        local title_bg_image
        if report:IsRead() then
            title_bg_image = "title_grey_558x34.png"
        else
            if report:IsWin() then
                title_bg_image = "title_green_558x34.png"
            else
                title_bg_image = "title_red_556x34.png"
            end
        end
        local title_bg = display.newSprite(title_bg_image, item_width/2, 52+item_height/2):addTo(self)
        local report_title =  UIKit:ttfLabel(
            {
                text = report:GetReportTitle(),
                size = 22,
                color = 0xffedae
            }):align(display.LEFT_CENTER, 30, 17)
            :addTo(title_bg)
        local date_label =  UIKit:ttfLabel(
            {
                text = GameUtils:formatTimeStyle2(math.floor(report.createTime/1000)),
                size = 16,
                color = 0xffedae
            }):align(display.RIGHT_CENTER, 540, 17)
            :addTo(title_bg)
        local report_content_bg = WidgetUIBackGround.new({width = 484,height = 98},WidgetUIBackGround.STYLE_TYPE.STYLE_4)
            :align(display.CENTER,35+item_width/2, -18+item_height/2):addTo(self)
        local report_big_type = report:IsAttackOrStrike()
        if report_big_type == "strike" then
            display.newSprite("icon_strike_69x50.png"):align(display.LEFT_BOTTOM, 0, 0):addTo(report_content_bg):scale(0.8)
            display.newSprite("icon_strike_69x50.png"):align(display.LEFT_BOTTOM, 410, 0):addTo(report_content_bg):flipX(true):scale(0.8)
        elseif report_big_type == "attack" then
            display.newSprite("icon_attack_76x88.png"):align(display.CENTER, 80, 47):addTo(report_content_bg)
            display.newSprite("icon_attack_76x88.png"):align(display.CENTER, 310, 47):addTo(report_content_bg)
        end
        local isFromMe = report:IsFromMe()
        if isFromMe == "collectResource" then
            local rewards = report:GetMyRewards()[1]
            UIKit:ttfLabel(
                {
                    text = _("资源采集报告"),
                    size = 20,
                    color = 0x403c2f
                }):align(display.CENTER, report_content_bg:getContentSize().width/2-20, 60)
                :addTo(report_content_bg)
            display.newSprite(UILib.resource[rewards.name], 190, 30):addTo(report_content_bg):scale(0.5)
            UIKit:ttfLabel(
                {
                    text = "+"..rewards.count,
                    size = 20,
                    color = 0x403c2f
                }):align(display.LEFT_CENTER, report_content_bg:getContentSize().width/2-20, 30)
                :addTo(report_content_bg)
        elseif isFromMe == "attackMonster" then
            local monster_level = report:GetAttackTarget().level
            local monster_data = report:GetEnemyPlayerData().soldiers[1]
            local soldier_type = monster_data.name
            local soldier_star = monster_data.star
            local soldier_ui_config = UILib.black_soldier_image[soldier_type][tonumber(soldier_star)]

            display.newSprite(UILib.black_soldier_color_bg_images[soldier_type]):addTo(report_content_bg)
                :align(display.CENTER_TOP,120, 86):scale(80/128)

            local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER_TOP,120, 86):addTo(report_content_bg)
            soldier_head_icon:scale(80/soldier_head_icon:getContentSize().height)
            display.newSprite("box_soldier_128x128.png")
                :align(display.CENTER, soldier_head_icon:getContentSize().width/2, soldier_head_icon:getContentSize().height-64)
                :addTo(soldier_head_icon)

            UIKit:ttfLabel(
                {
                    text = _("黑龙军团"),
                    size = 18,
                    color = 0x615b44
                }):align(display.LEFT_CENTER, report_content_bg:getContentSize().width/2-70, 70)
                :addTo(report_content_bg)
            UIKit:ttfLabel(
                {
                    text = Localize.soldier_name[soldier_type] .. " " ..string.format(_("等级%s"),monster_level),
                    size = 20,
                    color = 0x403c2f
                }):align(display.LEFT_CENTER, report_content_bg:getContentSize().width/2-70, 25)
                :addTo(report_content_bg)
        elseif isFromMe == "attackShrine" then
            display.newScale9Sprite("alliance_shrine.png"):addTo(report_content_bg)
                :align(display.CENTER_TOP,160, 80):scale(0.6)
            -- 圣地关卡名字
            local attackTarget = report:GetAttackTarget()
            UIKit:ttfLabel(
                {
                    text = string.gsub(attackTarget.stageName,"_","-")..Localize.shrine_desc[attackTarget.stageName][1],
                    size = 18,
                    color = 0x403c2f
                }):align(display.LEFT_CENTER, report_content_bg:getContentSize().width/2-20, 60)
                :addTo(report_content_bg)
            print("attackTarget.fightStar=",attackTarget.fightStar)
            StarBar.new({
                max = 3,
                bg = "alliance_shire_star_60x58_0.png",
                fill = "alliance_shire_star_60x58_1.png",
                num = attackTarget.fightStar
            }):addTo(report_content_bg):align(display.LEFT_CENTER,report_content_bg:getContentSize().width/2-20, 30):scale(0.5)        
        else
            -- 战报发出方信息
            -- 旗帜
            local my_flag_data = report:GetMyPlayerData().alliance.flag
            local enemy_flag_data = report:GetEnemyPlayerData().alliance.flag

            local a_helper = WidgetAllianceHelper.new()
            local my_flag = a_helper:CreateFlagContentSprite(Flag:DecodeFromJson(my_flag_data))
            local enemy_flag = a_helper:CreateFlagContentSprite(Flag:DecodeFromJson(enemy_flag_data))
            my_flag:scale(0.55)
            enemy_flag:scale(0.55)
            my_flag:align(display.CENTER, isFromMe and 48 or 278, 8)
                :addTo(report_content_bg)
            enemy_flag:align(display.CENTER, isFromMe and 278 or 48, 8)
                :addTo(report_content_bg)
            -- from title label
            local from_label = UIKit:ttfLabel(
                {
                    text = _("From"),
                    size = 16,
                    color = 0x615b44
                }):align(display.LEFT_CENTER, 120, 70)
                :addTo(report_content_bg)
            -- 发出方名字
            local from_player_label =  UIKit:ttfLabel(
                {
                    text = isFromMe and parent:GetMyName(report) or parent:GetEnemyName(report),
                    size = 20,
                    color = 0x403c2f,
                    dimensions = cc.size(150,20),
                    ellipsis = true
                }):align(display.LEFT_CENTER, 120, 50)
                :addTo(report_content_bg)
            -- 发出方所属联盟
            local from_alliance_label = UIKit:ttfLabel(
                {
                    text = isFromMe and "["..parent:GetMyAllianceTag(report).."]" or "["..parent:GetEnemyAllianceTag(report).."]",
                    size = 20,
                    color = 0x403c2f
                }):align(display.LEFT_CENTER, 120, 27)
                :addTo(report_content_bg)


            -- 战报发向方信息
            -- to title label
            local to_label = UIKit:ttfLabel(
                {
                    text = _("To"),
                    size = 16,
                    color = 0x615b44
                }):align(display.LEFT_CENTER, 350, 70)
                :addTo(report_content_bg)
            -- 发向方名字
            local to_player_label = UIKit:ttfLabel(
                {
                    text = isFromMe and parent:GetEnemyName(report) or parent:GetMyName(report),
                    size = 20,
                    color = 0x403c2f,
                    dimensions = cc.size(150,20),
                    ellipsis = true
                }):align(display.LEFT_CENTER, 350, 50)
                :addTo(report_content_bg)
            -- 发向方所属联盟
            local to_alliance_label = UIKit:ttfLabel(
                {
                    text = isFromMe and "["..parent:GetEnemyAllianceTag(report).."]" or "["..parent:GetMyAllianceTag(report).."]",
                    size = 20,
                    color = 0x403c2f
                }):align(display.LEFT_CENTER, 350, 27)
                :addTo(report_content_bg)
        end

        cc.ui.UICheckBoxButton.new({
            off = "report_saved_button_normal.png",
            off_pressed = "report_saved_button_normal.png",
            off_disabled = "report_saved_button_normal.png",
            on = "report_saved_button_selected.png",
            on_pressed = "report_saved_button_selected.png",
            on_disabled = "report_saved_button_selected.png",
        }):onButtonStateChanged(function(event)
            parent:SaveOrUnsaveReport(report,event.target)
        end):addTo(self):pos(249+item_width/2, -41+item_height/2)
            :setButtonSelected(report:IsSaved(),true)

        parent:CreateCheckBox(self):align(display.LEFT_CENTER,10,-18+item_height/2)
            :addTo(self)
    end


    return content
end
function GameUIMail:OpenReplyMail(mail)
    local dialog = WidgetPopDialog.new(748,_("回复邮件")):addTo(self,201)
    dialog:DisableAutoClose()
    local reply_mail = dialog:GetBody()
    local r_size = reply_mail:getContentSize()

    -- 收件人
    local addressee_title_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("收件人："),
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.RIGHT_CENTER,120, r_size.height-70)
        :addTo(reply_mail)
    local addressee_input_box_image = display.newSprite("input_box.png",350, r_size.height-70):addTo(reply_mail)
    local addressee_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = mail.fromAllianceTag~="" and "["..mail.fromAllianceTag.."]"..mail.fromName
            or mail.fromName,
            font = UIKit:getFontFilePath(),
            size = 18,
            dimensions = cc.size(410,24),
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.LEFT_CENTER,10,18)
        :addTo(addressee_input_box_image)
    -- 主题
    local subject_title_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("主题："),
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.RIGHT_CENTER,120, r_size.height-120)
        :addTo(reply_mail)
    local subject_input_box_image = display.newSprite("input_box.png",350, r_size.height-120):addTo(reply_mail)
    local subject_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = string.find(mail.title,_("RE:")) and mail.title or _("RE:")..mail.title,
            font = UIKit:getFontFilePath(),
            size = 18,
            dimensions = cc.size(410,24),
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.LEFT_CENTER,10,18)
        :addTo(subject_input_box_image)
    -- 分割线
    display.newScale9Sprite("dividing_line.png",r_size.width/2, r_size.height-160,cc.size(594,2),cc.rect(10,2,382,2)):addTo(reply_mail)
    -- 内容
    cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("内容："),
            font = UIKit:getFontFilePath(),
            size = 18,
            dimensions = cc.size(410,24),
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.LEFT_CENTER,30,r_size.height-180)
        :addTo(reply_mail)
    -- 回复的邮件内容
    local lucid_bg = WidgetUIBackGround.new({width = 580,height=472},WidgetUIBackGround.STYLE_TYPE.STYLE_4):addTo(reply_mail)
    lucid_bg:pos((r_size.width-lucid_bg:getContentSize().width)/2, 82)
    display.newScale9Sprite("dividing_line.png",lucid_bg:getContentSize().width/2, lucid_bg:getContentSize().height-288,cc.size(580,2),cc.rect(10,2,382,2)):addTo(lucid_bg)


    local textView = ccui.UITextView:create(cc.size(578,278),display.newScale9Sprite("background_578X278.png"))
    textView:align(display.LEFT_TOP,1,lucid_bg:getContentSize().height-5):addTo(lucid_bg)
    textView:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    textView:setFont(UIKit:getEditBoxFont(), 24)

    textView:setFontColor(cc.c3b(0,0,0))

    -- 被回复的邮件内容
    local content_listview = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a000000),
        viewRect = cc.rect(0, 10, 560, 170),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(lucid_bg):pos(10, 0)
    local content_item = content_listview:newItem()
    local content_label = cc.ui.UILabel.new(
        {cc.ui.UILabel.LABEL_TYPE_TTF,
            text = mail.content,
            font = UIKit:getFontFilePath(),
            size = 20,
            dimensions = cc.size(560,0),
            color = UIKit:hex2c3b(0x403c2f)
        }):align(display.LEFT_TOP)
    content_item:setItemSize(560,content_label:getContentSize().height)
    content_item:addContent(content_label)
    content_listview:addItem(content_item)
    content_listview:reload()

    -- 回复按钮
    local send_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("发送"),
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)})

    send_label:enableShadow()
    WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(send_label)
        :addTo(reply_mail):align(display.CENTER, reply_mail:getContentSize().width-92, 46)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:ReplyMail(mail,string.find(mail.title,_("RE:")) and mail.title or _("RE:")..mail.title, textView:getText())
                dialog:LeftButtonClicked()
            end
        end)
    textView:setRectTrackedNode(send_label)

    return reply_mail
end


function GameUIMail:CreateMailContacts()
    UIKit:newWidgetUI("WidgetMailContacts"):AddToCurrentScene(true)
end

--[[
    回复邮件
    @param addressee 收件人
    @param title 邮件主题
    @param content 邮件内容 
]]
function GameUIMail:ReplyMail(mail,title,content)
    local addressee = mail.fromId
    if not addressee or string.trim(addressee)=="" then
        UIKit:showMessageDialog(_("提示"),_("请填写正确的收件人ID"))
        return
    elseif addressee == User:Id() then
        UIKit:showMessageDialog(_("提示"),_("不能向自己发送邮件"))
        return
    elseif not title or string.trim(title)=="" then
        UIKit:showMessageDialog(_("提示"),_("请填写邮件主题"))
        return
    elseif not content or string.trim(content)=="" then
        UIKit:showMessageDialog(_("提示"),_("请填写邮件内容"))
        return
    end
    NetManager:getSendPersonalMailPromise(addressee, title, content,{
        id = mail.fromId,
        name = mail.fromName,
        icon = mail.fromIcon,
        allianceTag = mail.fromAllianceTag,
    })
end

function GameUIMail:OnReportsChanged( changed_map )
    if not self.report_listview then
        return
    end
    if changed_map.add then
        if #changed_map.add > 0 then
            self.report_listview:asyncLoadWithCurrentPosition_()
        end
    end
    if changed_map.edit then
        for _,report in pairs(changed_map.edit) do
            for i,listitem in ipairs(self.report_listview:getItems()) do
                local content = listitem:getContent()
                local content_report = content:GetContentData()
                if content_report.id == report.id then
                    content:SetData(nil,report)
                end
            end
        end
    end
    if changed_map.remove then
        if #changed_map.remove > 0 then
            self.report_listview:asyncLoadWithCurrentPosition_()
        end
    end
end
function GameUIMail:OnSavedReportsChanged( changed_map )
    if not self.saved_reports_listview then
        return
    end
    if changed_map.add then
        if #changed_map.add > 0 then
            self.saved_reports_listview:asyncLoadWithCurrentPosition_()
        end
    end
    if changed_map.edit then
        for _,report in pairs(changed_map.edit) do
            for i,listitem in ipairs(self.saved_reports_listview:getItems()) do
                local content = listitem:getContent()
                local content_report = content:GetContentData()
                if content_report.id == report.id then
                    content:SetData(nil,report)
                end
            end
        end
    end
    if changed_map.remove then
        if #changed_map.remove > 0 then
            self.saved_reports_listview:asyncLoadWithCurrentPosition_()
        end
    end
end
function GameUIMail:SaveOrUnsaveReport(report,target)
    if target:isButtonSelected() then
        NetManager:getSaveReportPromise(report:Id()):fail(function()
            target:setButtonSelected(false,true)
        end)
    else
        NetManager:getUnSaveReportPromise(report:Id()):fail(function()
            target:setButtonSelected(true,true)
        end)
    end
end


function GameUIMail:GetMyName(report)
    local data = report:GetData()
    if report:Type() == "strikeCity" or report:Type()== "cityBeStriked" then
        if data.attackPlayerData.id == DataManager:getUserData()._id then
            return data.attackPlayerData.name
        elseif data.helpDefencePlayerData and data.helpDefencePlayerData.id == DataManager:getUserData()._id then
            return data.helpDefencePlayerData.name
        elseif data.defencePlayerData and data.defencePlayerData.id == DataManager:getUserData()._id then
            return data.defencePlayerData.name
        end
        -- 被突袭时只有协防方发生战斗时
        if report:Type()== "cityBeStriked" then
            if data.helpDefencePlayerData then
                return data.helpDefencePlayerData.name
            end
        end
    elseif report:Type()=="attackCity" then
        if report:GetData().attackPlayerData.id == DataManager:getUserData()._id then
            return report:GetData().attackPlayerData.name
        elseif report:GetData().defencePlayerData and report:GetData().defencePlayerData.id == DataManager:getUserData()._id then
            return report:GetData().defencePlayerData.name
        elseif report:GetData().helpDefencePlayerData and report:GetData().helpDefencePlayerData.id == DataManager:getUserData()._id then
            return report:GetData().helpDefencePlayerData.name
        end
    elseif report:Type() == "strikeVillage" then
        return data.attackPlayerData.name
    elseif report:Type() == "villageBeStriked" then
        return data.defencePlayerData.name
    elseif report:Type() == "attackVillage" then
        if data.attackPlayerData.id == DataManager:getUserData()._id then
            return data.attackPlayerData.name
        elseif data.defencePlayerData and data.defencePlayerData.id == DataManager:getUserData()._id then
            return data.defencePlayerData.name
        end
    else
        return "xxxxx"
    end
end
function GameUIMail:GetMyAllianceTag(report)
    local data = report:GetData()
    if report:Type() == "strikeCity" or report:Type()== "cityBeStriked" then
        if data.attackPlayerData.id == DataManager:getUserData()._id then
            return data.attackPlayerData.alliance.tag
        elseif data.helpDefencePlayerData and data.helpDefencePlayerData.id == DataManager:getUserData()._id then
            return data.helpDefencePlayerData.alliance.tag
        elseif data.defencePlayerData and data.defencePlayerData.id == DataManager:getUserData()._id then
            return data.defencePlayerData.alliance.tag
        end
        -- 被突袭时只有协防方发生战斗时使用协防方数据
        if report:Type()== "cityBeStriked" then
            if data.helpDefencePlayerData then
                return data.helpDefencePlayerData.alliance.tag
            end
        end
    elseif report:Type()=="attackCity" then
        if report:GetData().attackPlayerData.id == DataManager:getUserData()._id then
            return report:GetData().attackPlayerData.alliance.tag
        elseif report:GetData().defencePlayerData and report:GetData().defencePlayerData.id == DataManager:getUserData()._id then
            return report:GetData().defencePlayerData.alliance.tag
        elseif report:GetData().helpDefencePlayerData and report:GetData().helpDefencePlayerData.id == DataManager:getUserData()._id then
            return report:GetData().helpDefencePlayerData.alliance.tag
        end
    elseif report:Type() == "strikeVillage" then
        return data.attackPlayerData.alliance.tag
    elseif report:Type() == "villageBeStriked" then
        return data.defencePlayerData.alliance.tag
    elseif report:Type() == "attackVillage" then
        if data.attackPlayerData.id == DataManager:getUserData()._id then
            return data.attackPlayerData.alliance.tag
        elseif data.defencePlayerData and data.defencePlayerData.id == DataManager:getUserData()._id then
            return data.defencePlayerData.alliance.tag
        end
    else
        return "xxxxx"
    end
end
function GameUIMail:GetEnemyName(report)
    local data = report:GetData()
    if report:Type() == "strikeCity" or report:Type()== "cityBeStriked" then
        if data.attackPlayerData.id == DataManager:getUserData()._id then
            return (data.defencePlayerData and data.defencePlayerData.name) or (data.helpDefencePlayerData and data.helpDefencePlayerData.name)
        elseif data.helpDefencePlayerData and data.helpDefencePlayerData.id == DataManager:getUserData()._id then
            return data.attackPlayerData.name
        elseif data.defencePlayerData and data.defencePlayerData.id == DataManager:getUserData()._id then
            return data.attackPlayerData.name
        end
        -- 被突袭时只有协防方发生战斗时
        if report:Type()== "cityBeStriked" then
            if data.attackPlayerData then
                return data.attackPlayerData.name
            end
        end
    elseif report:Type()=="attackCity" then
        if report:GetData().attackPlayerData.id == DataManager:getUserData()._id then
            return report:GetData().defencePlayerData and report:GetData().defencePlayerData.name or report:GetData().helpDefencePlayerData and report:GetData().helpDefencePlayerData.name
        elseif report:GetData().defencePlayerData and report:GetData().defencePlayerData.id == DataManager:getUserData()._id
            or (report:GetData().helpDefencePlayerData and report:GetData().helpDefencePlayerData.id == DataManager:getUserData()._id)
        then
            return report:GetData().attackPlayerData.name
        end
    elseif report:Type() == "strikeVillage" then
        return data.defencePlayerData.name
    elseif report:Type() == "villageBeStriked" then
        return data.attackPlayerData.name
    elseif report:Type() == "attackVillage" then
        return data.defencePlayerData.name
    else
        return "xxxxx"
    end
end
function GameUIMail:GetEnemyAllianceTag(report)
    local data = report:GetData()
    if report:Type() == "strikeCity" or report:Type()== "cityBeStriked" then
        if data.attackPlayerData.id == DataManager:getUserData()._id then
            return data.strikeTarget.alliance.tag
        elseif data.helpDefencePlayerData and data.helpDefencePlayerData.id == DataManager:getUserData()._id then
            return data.attackPlayerData.alliance.tag
        elseif data.defencePlayerData and data.defencePlayerData.id == DataManager:getUserData()._id then
            return data.attackPlayerData.alliance.tag
        end
        -- 被突袭时只有协防方发生战斗时
        if report:Type()== "cityBeStriked" then
            if data.attackPlayerData then
                return data.attackPlayerData.alliance.tag
            end
        end
    elseif report:Type()=="attackCity" then
        if report:GetData().attackPlayerData.id == DataManager:getUserData()._id then
            return report:GetData().defencePlayerData and report:GetData().defencePlayerData.alliance.tag or report:GetData().helpDefencePlayerData and report:GetData().helpDefencePlayerData.alliance.tag
        elseif report:GetData().defencePlayerData and report:GetData().defencePlayerData.id == DataManager:getUserData()._id
            or (report:GetData().helpDefencePlayerData and report:GetData().helpDefencePlayerData.id == DataManager:getUserData()._id)
        then
            return report:GetData().attackPlayerData.alliance.tag
        end
    elseif report:Type() == "strikeVillage" then
        return data.defencePlayerData.alliance.tag
    elseif report:Type() == "villageBeStriked" then
        return data.attackPlayerData.alliance.tag
    elseif report:Type() == "attackVillage" then
        return data.defencePlayerData.alliance.tag
    else
        return "xxxxx"
    end
end

return GameUIMail





































































