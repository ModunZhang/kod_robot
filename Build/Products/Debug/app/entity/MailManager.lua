local Enum = import("..utils.Enum")
local MultiObserver = import("..entity.MultiObserver")
local Report = import("..entity.Report")

local MailManager = class("MailManager", MultiObserver)
MailManager.LISTEN_TYPE = Enum("MAILS_CHANGED","UNREAD_MAILS_CHANGED","REPORTS_CHANGED")

function MailManager:ctor()
    MailManager.super.ctor(self)
    self.mails = nil
    self.savedMails = nil
    self.sendMails = nil
    self.reports = nil
    self.savedReports = nil
    self.is_last_mail = false
    self.is_last_saved_mail = false
    self.is_last_send_mail = false
    self.is_last_report = false
    self.is_last_saved_report = false
end
function MailManager:Reset()
    self.mails = nil
    self.savedMails = nil
    self.sendMails = nil
    self.reports = nil
    self.savedReports = nil
    self.is_last_mail = false
    self.is_last_saved_mail = false
    self.is_last_send_mail = false
    self.is_last_report = false
    self.is_last_saved_report = false
end
function MailManager:IncreaseUnReadMailsNum(num)
    self.unread_mail = self.unread_mail + num
    GameGlobalUI:showTips(_("提示"),_("你有一封新的邮件"))
    self:NotifyListeneOnType(MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED,function(listener)
        listener:MailUnreadChanged({mail=self.unread_mail})
    end)
end

function MailManager:IncreaseUnReadReportNum(num)
    self.unread_report = self.unread_report + num
    GameGlobalUI:showTips(_("提示"),_("你有一封新的邮件"))
    self:NotifyListeneOnType(MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED,function(listener)
        listener:MailUnreadChanged({report=self.unread_report})
    end)
end

function MailManager:DecreaseUnReadMailsNum(num)
    self.unread_mail = self.unread_mail - num
    self:NotifyListeneOnType(MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED,function(listener)
        listener:MailUnreadChanged(
            {
                mail=self.unread_mail
            }
        )
    end)
end

function MailManager:DecreaseUnReadReportsNum(num)
    self.unread_report = self.unread_report - num
    self:NotifyListeneOnType(MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED,function(listener)
        listener:MailUnreadChanged(
            {
                report=self.unread_report
            }
        )
    end)
end

function MailManager:DecreaseUnReadMailsNumByIds(ids)
    local mails = self.mails
    local num = 0
    for _,mail in pairs(mails) do
        for _,id in pairs(ids) do
            if id==mail.id and not mail.isRead then
                num = num + 1
            end
        end
    end
    self.unread_mail = self.unread_mail - num
    self:NotifyListeneOnType(MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED,function(listener)
        listener:MailUnreadChanged(
            {
                mail=self.unread_mail
            }
        )
    end)
end

function MailManager:DecreaseUnReadReportsNumByIds(ids)
    local reports = self.reports
    local num = 0
    for _,report in pairs(reports) do
        for _,id in pairs(ids) do
            if id==report.id and not report.isRead then
                num = num + 1
            end
        end
    end
    self.unread_report = self.unread_report - num
    self:NotifyListeneOnType(MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED,function(listener)
        listener:MailUnreadChanged(
            {
                report=self.unread_report
            }
        )
    end)
end

function MailManager:GetUnReadMailsAndReportsNum()
    return self.unread_mail + self.unread_report
end
function MailManager:GetUnReadMailsNum()
    return self.unread_mail
end
function MailManager:GetUnReadReportsNum()
    return self.unread_report
end
function MailManager:AddSavedMail(mail)
    table.insert(self.savedMails,1, mail)
end
function MailManager:DeleteSavedMail(mail)
    for k,v in pairs(self.savedMails) do
        if v.id == mail.id then
            table.remove(self.savedMails,k)
        end
    end
end
function MailManager:DeleteMail(mail)
    -- 由于服务器每次删除邮件后都回更改index，所以每次删除邮件后，对于客服端本地保存的邮件的服务器index大于当前删除邮件的都需要-1
    local delete_mail_server_index
    for k,v in pairs(self.mails) do
        if v.id == mail.id then
            table.remove(self.mails,k)
            delete_mail_server_index = v.index
            if mail.isSaved then
                mail.isSaved = false
                self:OnNewSavedMailsChanged(mail)
            end
        end
    end
    for k,v in pairs(DataManager:getUserData().mails) do
        if v.index > delete_mail_server_index then
            local old = clone(v.index)
            v.index = old - 1
        end
    end
    for k,v in pairs(self.mails) do
        if v.index > delete_mail_server_index then
            local old = clone(v.index)
            v.index = old - 1
        end
    end
end
function MailManager:ModifyMail(mail)
    for k,v in pairs(self.mails) do
        print("ModifyMail ",v.id, mail.id)
        if v.id == mail.id then
            if mail.isSaved ~= v.isSaved then
                self:OnNewSavedMailsChanged(mail)
            end
            if mail.isRead ~= v.isSaved and mail.isRead then
                self:OnNewSavedMailsChanged(mail,true)
            end
            for i,modify in pairs(mail) do
                v[i] = modify
            end
            return v
        end
    end
    -- 如果收件箱没找到对应邮件,则在收藏夹找一下
    if self.savedMails then
        for k,v in pairs(self.savedMails) do
            if v.id == mail.id then
                if mail.isSaved ~= v.isSaved then
                    self:OnNewSavedMailsChanged(mail)
                end
                if mail.isRead then
                    self:OnNewSavedMailsChanged(mail,true)
                end
                for i,modify in pairs(mail) do
                    v[i] = modify
                end
                return v
            end
        end
    end
end

function MailManager:DeleteSendMail(mail)
    for k,v in pairs(self.sendMails) do
        if v.id == mail.id then
            table.remove(self.sendMails,k)
        end
    end
end

function MailManager:AddMailsToEnd(mail)
    table.insert(self.mails, mail)
end
function MailManager:AddSavedMailsToEnd(mail)
    table.insert(self.savedMails, mail)
end
function MailManager:AddSendMailsToEnd(mail)
    table.insert(self.sendMails, mail)
end
function MailManager:AddReportsToEnd(report)
    table.insert(self.reports, Report:DecodeFromJsonData(report))
end
function MailManager:AddSavedReportsToEnd(report)
    table.insert(self.savedReports, Report:DecodeFromJsonData(report))
end
function MailManager:GetMails()
    return self.mails
end
function MailManager:GetMailByServerIndex(serverIndex)
    local mails = self.mails
    for i,v in ipairs(mails) do
        print(".....v.index == index",v.title,v.index,serverIndex,v.index == serverIndex)
    end
    for i,v in ipairs(mails) do
        if v.index == serverIndex then
            return i
        end
    end
end
function MailManager:GetSavedMailByServerIndex(serverIndex)
    local savedMails = self.savedMails
    for i,v in ipairs(savedMails) do
        print("收藏夹.....v.index == index",v.title,v.index,serverIndex,v.index == serverIndex)
    end
    for i,v in ipairs(savedMails) do
        if v.index == serverIndex then
            return i
        end
    end
end
function MailManager:GetReportByServerIndex(serverIndex)
    local reports = self.reports
    for i,v in ipairs(reports) do
        print(".....v.index == index",v:Index(),serverIndex)
    end
    for i,v in ipairs(reports) do
        if v:Index() == serverIndex then
            return i
        end
    end
end
function MailManager:GetSavedReportByServerIndex(serverIndex)
    local reports = self.savedReports
    for i,v in ipairs(reports) do
        print("收藏战报.....v.index == index",v:Index(),serverIndex)
    end
    for i,v in ipairs(reports) do
        if v:Index() == serverIndex then
            return i
        end
    end
end
function MailManager:FetchMailsFromServer(fromIndex)
    if self.is_last_mail then
        return
    end
    return NetManager:getFetchMailsPromise(fromIndex):done(function(response)
        if response.msg.mails then
            local user_data = DataManager:getUserData()
            local fetch_mails = response.msg.mails
            if #fetch_mails < 10 then
                self.is_last_mail = true
            end
            if not user_data.mails then
                user_data.mails = {}
            end
            if not self.mails then
                self.mails = {}
            end
            for i,v in ipairs(fetch_mails) do
                table.insert(user_data.mails, v)
                self:AddMailsToEnd(clone(v))
            end
        end
        return response
    end)
end
function MailManager:GetSavedMails()
    return self.savedMails
end
function MailManager:FetchSavedMailsFromServer(fromIndex)
    if self.is_last_saved_mail then
        return
    end
    return NetManager:getFetchSavedMailsPromise(fromIndex):done(function (response)
        if response.msg.mails then
            local user_data = DataManager:getUserData()
            local fetch_mails = response.msg.mails
            if #fetch_mails < 10 then
                self.is_last_saved_mail = true
            end
            if not user_data.savedMails then
                user_data.savedMails = {}
            end
            if not self.savedMails then
                self.savedMails = {}
            end
            for i,v in ipairs(fetch_mails) do
                table.insert(user_data.savedMails, v)
                self:AddSavedMailsToEnd(clone(v))
            end
        end
    end)
end
function MailManager:GetSendMails()
    if not self.sendMails then return end
    -- 按时间排序
    table.sort(self.sendMails,function ( a , b )
        return a.sendTime > b.sendTime
    end)
    return self.sendMails
end
function MailManager:FetchSendMailsFromServer(fromIndex)
    if self.is_last_send_mail then
        return
    end
    return NetManager:getFetchSendMailsPromise(fromIndex):done(function(response)
        if response.msg.mails then
            local user_data = DataManager:getUserData()
            local mails = response.msg.mails
            if #mails < 10 then
                self.is_last_send_mail = true
            end
            if not user_data.sendMails then
                user_data.sendMails = {}
            end
            if not self.sendMails then
                self.sendMails = {}
            end
            for i,v in ipairs(response.msg.mails) do
                table.insert(user_data.sendMails, v)
                self:AddSendMailsToEnd(clone(v))
            end
        end
    end)
end
function MailManager:OnMailStatusChanged( mailStatus )
    if mailStatus.unreadMails then
        self.unread_mail = mailStatus.unreadMails
    end
    if mailStatus.unreadReports then
        self.unread_report = mailStatus.unreadReports
    end
    self:NotifyListeneOnType(MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED,function(listener)
        listener:MailUnreadChanged(
            {
                mail=self.unread_mail,
                report=self.unread_report
            }
        )
    end)
end
function MailManager:OnMailsChanged( mails )
    self.mails = mails and clone(mails)
end
function MailManager:OnSavedMailsChanged( savedMails )
    self.savedMails = savedMails and clone(savedMails)
end
function MailManager:OnSendMailsChanged( sendMails )
    self.sendMails = sendMails and clone(sendMails)
end

function MailManager:OnNewMailsChanged( mails )
    local add_mails = {}
    local remove_mails = {}
    local edit_mails = {}
    for type,mail in pairs(mails) do
        if type == "add" then
            for i,data in ipairs(mail) do
                -- 收到
                if not data.index then
                    data.index = self.mails[1] and (self.mails[1].index + 1) or 0
                end
                table.insert(add_mails, clone(data))
                table.insert(self.mails, 1, clone(data))
                self:IncreaseUnReadMailsNum(1)


                local u_mails = DataManager:getUserData().mails
                local max_index = 0
                for k,v in pairs(u_mails) do
                    max_index = math.max(k,max_index)
                end
                local first = clone(u_mails[max_index])
                u_mails[max_index] = nil
                table.insert(u_mails, 1 ,first)
            end
        elseif type == "remove" then
            for i,data in ipairs(mail) do
                table.insert(remove_mails, clone(data))
                self:DeleteMail(clone(data))
            end
        elseif type == "edit" then
            for i,data in ipairs(mail) do
                LuaUtils:outputTable("edit mail", data)
                table.insert(edit_mails, self:ModifyMail(clone(data)))
            end
        end
    end
    self:NotifyListeneOnType(MailManager.LISTEN_TYPE.MAILS_CHANGED,function(listener)
        listener:OnInboxMailsChanged({
            add_mails = add_mails,
            remove_mails = remove_mails,
            edit_mails = edit_mails,
        })
    end)
end
function MailManager:OnNewSavedMailsChanged( savedMails,isRead )
    if not self.savedMails then return end
    local add_mails = {}
    local remove_mails = {}
    local edit_mails = {}
    if isRead then
        table.insert(edit_mails, savedMails)
        for i,v in ipairs(self.savedMails) do
            if v.id == savedMails.id then
                v.isRead = true
            end
        end
    else
        if savedMails.isSaved then
            table.insert(add_mails, savedMails)
            table.insert(self.savedMails, savedMails)
        else
            table.insert(remove_mails, savedMails)
            self:DeleteSavedMail(savedMails)
        end
    end
    self:NotifyListeneOnType(MailManager.LISTEN_TYPE.MAILS_CHANGED,function(listener)
        listener:OnSavedMailsChanged({
            add_mails = add_mails,
            remove_mails = remove_mails,
            edit_mails = edit_mails,
        })
    end)
end
function MailManager:OnNewSendMailsChanged( sendMails )
    local add_mails = {}
    local remove_mails = {}
    for type,mail in pairs(sendMails) do
        if type == "add" then
            for i,data in ipairs(mail) do
                table.insert(add_mails, data)
                table.insert(self.sendMails, data)
            end
        elseif type == "remove" then
            for i,data in ipairs(mail) do
                table.insert(remove_mails, data)
                self:DeleteSendMail(data)
            end
        end
    end
    self:NotifyListeneOnType(MailManager.LISTEN_TYPE.MAILS_CHANGED,function(listener)
        listener:OnSendMailsChanged({
            add_mails = add_mails,
            remove_mails = remove_mails,
        })
    end)
end
function MailManager:OnUserDataChanged(userData,timer,deltaData)
    local is_fully_update = deltaData == nil
    local is_delta_update = not is_fully_update and deltaData.mailStatus ~= nil
    -- 邮件
    if is_fully_update or is_delta_update then
        self:OnMailStatusChanged(userData.mailStatus)
    end
    if is_fully_update then
        self:OnMailsChanged(userData.mails)
        self:OnSavedMailsChanged(userData.savedMails)
        self:OnSendMailsChanged(userData.sendMails)
    end
    is_delta_update = not is_fully_update and deltaData.mails ~= nil
    if is_delta_update then
        self:OnNewMailsChanged(deltaData.mails)
    end
    is_delta_update = not is_fully_update and deltaData.savedMails ~= nil
    if is_delta_update then
        self:OnNewSavedMailsChanged(clone(deltaData.savedMails.edit[1]))
    end
    is_delta_update = not is_fully_update and deltaData.sendMails ~= nil
    if is_delta_update then
        self:OnNewSendMailsChanged(deltaData.sendMails)
    end

    -- 战报部分
    if is_fully_update then
        self:OnReportsChanged(userData.reports)
        self:OnSavedReportsChanged(userData.savedReports)
    end
    local is_delta_update = not is_fully_update and deltaData.reports ~= nil
    if is_delta_update then
        self:OnNewReportsChanged(deltaData.reports)
    end

    local is_delta_update = not is_fully_update and deltaData.savedReports ~= nil
    if is_delta_update then
        self:OnNewSavedReportsChanged(Report:DecodeFromJsonData(clone(deltaData.savedReports.edit[1])))
    end
end

function MailManager:OnReportsChanged( reports )
    if not reports then return end
    for k,v in pairs(reports) do
        table.insert(self.reports, Report:DecodeFromJsonData(clone(v)))
    end
end
function MailManager:OnSavedReportsChanged( savedReports )
    if not savedReports then return end
    for k,v in pairs(savedReports) do
        table.insert(self.savedReports, Report:DecodeFromJsonData(clone(v)))
    end
end
function MailManager:OnNewReportsChanged( __reports )
    local add_reports = {}
    local remove_reports = {}
    local edit_reports = {}
    for type,rp in pairs(__reports) do
        if type == "add" then
            for k,data in pairs(rp) do
                if not data.index then
                    data.index = self.reports[1] and (self.reports[1]:Index() + 1) or 0
                end
                local c_report = Report:DecodeFromJsonData(clone(data))
                table.insert(add_reports, c_report)
                table.insert(self.reports,1, c_report)
                self:IncreaseUnReadReportNum(1)

                -- 由于当前 DataManager中的reports 最新这条是服务器的index,需要修正为客户端index

                local u_reports = DataManager:getUserData().reports
                local max_index = 0
                for k,v in pairs(u_reports) do
                    max_index = math.max(k,max_index)
                end
                local first = clone(u_reports[max_index])
                u_reports[max_index] = nil
                table.insert(u_reports, 1 ,first)
            end
        elseif type == "remove" then
            for k,data in pairs(rp) do
                table.insert(remove_reports, Report:DecodeFromJsonData(data))
                self:DeleteReport(clone(data))
            end
        elseif type == "edit" then
            for k,data in pairs(rp) do
                table.insert(edit_reports,self:ModifyReport(clone(data)))
            end
        end
    end
    self:NotifyListeneOnType(MailManager.LISTEN_TYPE.REPORTS_CHANGED,function(listener)
        listener:OnReportsChanged({
            add = add_reports,
            remove = remove_reports,
            edit = edit_reports,
        })
    end)
end
function MailManager:OnNewSavedReportsChanged( __savedReports , modifyIsRead)
    if not self.savedReports then return end
    local add_reports = {}
    local remove_reports = {}
    local edit_reports = {}
    if modifyIsRead then
        table.insert(edit_reports, __savedReports)
        for k,v in pairs(self.savedReports) do
            if v:Id() == __savedReports:Id() then
                self.savedReports[k] = __savedReports
            end
        end
    else
        if __savedReports:IsSaved() then
            table.insert(add_reports, __savedReports)
            table.insert(self.savedReports, 1 , __savedReports)
        else
            table.insert(remove_reports, __savedReports)
            self:DeleteSavedReport(__savedReports)
        end

    end


    self:NotifyListeneOnType(MailManager.LISTEN_TYPE.REPORTS_CHANGED,function(listener)
        listener:OnSavedReportsChanged({
            add = add_reports,
            remove = remove_reports,
            edit = edit_reports,
        })
    end)

end
function MailManager:DeleteReport( report )
    local delete_report_server_index
    for k,v in pairs(self.reports) do
        if v:Id() == report.id then
            delete_report_server_index = v:Index()
            table.remove(self.reports,k)
            -- 收藏的战报需要在收藏夹中删除
            if v:IsSaved() then
                v:SetIsSaved(false)
                self:OnNewSavedReportsChanged(clone(v))
            end
        end
    end
    for k,v in pairs(DataManager:getUserData().reports) do
        if v.index > delete_report_server_index then
            local old = clone(v.index)
            v.index = old - 1
        end
    end
    for k,v in pairs(self.reports) do
        if v:Index() > delete_report_server_index then
            v:SetIndex(v:Index() - 1)
        end
    end
end
function MailManager:ModifyReport( report )
    for k,v in pairs(self.reports) do
        if v:Id() == report.id then
            if v:IsSaved() ~= report.isSaved then
                self:OnNewSavedReportsChanged(Report:DecodeFromJsonData(report))
            end
            print("v:IsRead()",v:IsRead(),"report.isRead ",report.isRead )
            if v:IsRead() ~= report.isRead then
                self:OnNewSavedReportsChanged(Report:DecodeFromJsonData(report),true)
            end
            v:Update(report)
            return self.reports[k]
        end
    end
end

function MailManager:DeleteSavedReport( report )
    for k,v in pairs(self.savedReports) do
        if v:Id() == report:Id() then
            table.remove(self.savedReports,k)
        end
    end
end

function MailManager:GetReports()
    return self.reports
end
function MailManager:FetchReportsFromServer(fromIndex)
    if self.is_last_report then
        return
    end
    return NetManager:getReportsPromise(fromIndex)
        :done(function (response)
            if response.msg.reports then
                local user_data = DataManager:getUserData()
                local fetch_reports = response.msg.reports
                if #fetch_reports < 10 then
                    self.is_last_report = true
                end
                if not user_data.reports then
                    user_data.reports = {}
                end
                if not self.reports then
                    self.reports = {}
                end
                for i,v in ipairs(fetch_reports) do
                    table.insert(user_data.reports, v)
                    self:AddReportsToEnd(clone(v))
                end
            end
        end)
end
function MailManager:GetSavedReports()
    return self.savedReports
end
function MailManager:FetchSavedReportsFromServer(fromIndex)
    if self.is_last_saved_report then
        return
    end
    return NetManager:getSavedReportsPromise(fromIndex):done(function (response)
        if response.msg.reports then
            local user_data = DataManager:getUserData()
            local fetch_reports = response.msg.reports
            if #fetch_reports < 10 then
                self.is_last_saved_report = true
            end
            if not user_data.savedReports then
                user_data.savedReports = {}
            end
            if not self.savedReports then
                self.savedReports = {}
            end
            for i,v in ipairs(fetch_reports) do
                table.insert(user_data.savedReports, v)
                self:AddSavedReportsToEnd(clone(v))
            end
        end
    end)
end
return MailManager















