--
-- Author: Your Name
-- Date: 2014-10-21 22:55:03
--
local GameUIAllianceMemberInfo = UIKit:createUIClass("GameUIAllianceMemberInfo","UIAutoClose")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local UIListView = import(".UIListView")
local UIScrollView = import(".UIScrollView")
local NetService = import('..service.NetService')
local Alliance = import('..entity.Alliance')
local memberMeta = import('..entity.memberMeta')
local GameUIWriteMail = import('.GameUIWriteMail')
local WidgetPlayerNode = import("..widget.WidgetPlayerNode")
local WidgetPushButton = import("..widget.WidgetPushButton")
local Localize = import("..utils.Localize")
local config_playerLevel = GameDatas.PlayerInitData.playerLevel
function GameUIAllianceMemberInfo:ctor(isMyAlliance,memberId,func_call,serverId)
    GameUIAllianceMemberInfo.super.ctor(self)
    self.isMyAlliance = isMyAlliance or false
    self.memberId_ = memberId
    self.serverId_ = serverId or User.serverId
    self.func_call = func_call
end

function GameUIAllianceMemberInfo:OnMoveInStage()
    GameUIAllianceMemberInfo.super.OnMoveInStage(self)
    local main_height,min_y = 750,window.bottom + 120


    local bg = WidgetUIBackGround.new({height=main_height}):pos(window.left+20,min_y)
    self:addTouchAbleChild(bg)
    local title_bar = display.newSprite("title_blue_600x56.png")
        :addTo(bg)
        :align(display.LEFT_BOTTOM, 0, main_height - 15)

    UIKit:closeButton():align(display.RIGHT_BOTTOM,600,0):addTo(title_bar):onButtonClicked(function()
        self:LeftButtonClicked()
    end)
    UIKit:ttfLabel({
        text = _("玩家信息"),
        size = 24,
        color = 0xffedae,
    }):align(display.CENTER, 300, 26):addTo(title_bar)
    self.bg = bg
    self.title_bar = title_bar

    NetManager:getPlayerInfoPromise(self.memberId_,self.serverId_):done(function(data)
        self:OnGetPlayerInfoSuccess(data)
    end):fail(function()
        self:LeftButtonClicked()
    end)
end

function GameUIAllianceMemberInfo:BuildUI()
    if self.isMyAlliance then
        if not Alliance_Manager:GetMyAlliance():GetSelf():CanHandleAllianceApply() then
            WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
                :setButtonLabel(
                    UIKit:ttfLabel({
                        text = _("邮件"),
                        size = 20,
                        shadow = true,
                        color = 0xfff3c7
                    })
                )
                :align(display.CENTER_BOTTOM,self.bg:getContentSize().width/2,15)
                :onButtonClicked(function(event)
                    self:OnPlayerButtonClicked(5)
                end)
                :addTo(self.bg)
        else
            local titles =  {_("逐出"),_("移交盟主"),_("降级"),_("晋级"),_("邮件"),}
            local x,y = 15,15
            for i = 1,5 do
                WidgetPushButton.new({normal = "player_operate_n_116x64.png",pressed = "player_operate_h_116x64.png"})
                    :align(display.LEFT_BOTTOM, x + (i - 1)*116, y)
                    :addTo(self.bg)
                    :setButtonLabel("normal", UIKit:ttfLabel({
                        text = titles[i],
                        size = 20,
                        color= 0xffedae,
                        shadow= true
                    }))
                    :onButtonClicked(function()
                        self:OnPlayerButtonClicked(i)
                    end)
            end
        end
    else
        WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
            :setButtonLabel(
                UIKit:ttfLabel({
                    text = _("邮件"),
                    size = 20,
                    shadow = true,
                    color = 0xfff3c7
                })
            )
            :align(display.CENTER_BOTTOM,self.bg:getContentSize().width/2,15)
            :onButtonClicked(function(event)
                 local mail = GameUIWriteMail.new(GameUIWriteMail.SEND_TYPE.PERSONAL_MAIL,{
                    id = self.player_info.id,
                    name = self.player_info.name,
                    icon = self.player_info.icon,
                    allianceTag = self.player_info.alliance and self.player_info.alliance.tag,
                })
                mail:SetTitle(_("个人邮件"))
                mail:SetAddressee(self.player_info.name)
                mail:addTo(self)
            end)
            :addTo(self.bg)
    end
    local player_node = WidgetPlayerNode.new(cc.size(564,644),self)
        :addTo(self.bg):pos(22,82)
    self.player_node = player_node
end

function GameUIAllianceMemberInfo:OnPlayerButtonClicked( tag )
    local can_do,msg = self:CheckPlayerAuthor(tag)
    if not can_do then
        self:ShowMessage(msg)
        return
    end
    local member = Alliance_Manager:GetMyAlliance():GetMemeberById(self.player_info.id)
    if tag == 1 then -- 踢出
        if Alliance_Manager:GetMyAlliance().basicInfo.status == "fight" or Alliance_Manager:GetMyAlliance().basicInfo.status == "prepare" then
            UIKit:showMessageDialog(_("提示"), _("联盟正在战争准备期或战争期,不能将玩家踢出联盟"))
            return
        end
        self:ShowSureDialog(string.format(_("您确定逐出玩家:%s?"),member:Name()),function()
            self:SendToServerWithTag(tag,member)
        end)
    elseif tag == 2 then -- 移交盟主
        self:ShowSureDialog(string.format(_("您确定移交盟主职位给:%s?"),member:Name()),function()
            self:SendToServerWithTag(tag,member)
        end)
    elseif tag == 3 then --降级
        self:SendToServerWithTag(tag,member)
    elseif tag == 4 then --晋级
        self:SendToServerWithTag(tag,member)
    else
        self:SendToServerWithTag(tag,member)
    end

end

function GameUIAllianceMemberInfo:CallBackFunctionIf()
    if self.func_call and type(self.func_call) == 'function' then
        self.func_call()
    end
end

function GameUIAllianceMemberInfo:SendToServerWithTag(tag,member)
    if tag == 1 then -- 踢出
        NetManager:getKickAllianceMemberOffPromise(member:Id()):done(function(data)
            self:CallBackFunctionIf()
            self:LeftButtonClicked()
        end)
    elseif tag == 2 then -- 移交盟主
        NetManager:getHandOverAllianceArchonPromise(member:Id()):done(function()
            local alliacne =  Alliance_Manager:GetMyAlliance()
            local title = alliacne:GetMemeberById(member:Id()):Title()
            -- self.player_info.alliance.title = title
            self:CallBackFunctionIf()
            self:LeftButtonClicked()
        end)
    elseif tag == 3 then --降级
        if not member:IsTitleLowest() then
            NetManager:getEditAllianceMemberTitlePromise(member:Id(), member:TitleDegrade()):done(function()
                GameGlobalUI:showTips(_("提示"), string.format(_("%s已降级为%s"),member:Name(),Localize.alliance_title[member:Title()]))
                self.player_info.alliance.title = member:Title()
                self:RefreshListView()
                self:CallBackFunctionIf()
            end)
    end
    elseif tag == 4 then --晋级
        if not member:IsTitleHighest() then
            NetManager:getEditAllianceMemberTitlePromise(member:Id(), member:TitleUpgrade()):done(function()
                GameGlobalUI:showTips(_("提示"), string.format(_("%s已晋级为%s"),member:Name(),Localize.alliance_title[member:Title()]))
                self.player_info.alliance.title = member:Title()
                self:CallBackFunctionIf()
                self:RefreshListView()
            end)
    end
    elseif tag == 5 then
        local mail = GameUIWriteMail.new(GameUIWriteMail.SEND_TYPE.PERSONAL_MAIL,{
                    id = member:Id(),
                    name = member:Name(),
                    icon = member:Icon(),
                    allianceTag = self.player_info.alliance and self.player_info.alliance.tag,
                })
        mail:SetTitle(_("个人邮件"))
        mail:SetAddressee(self.player_info.name)
        mail:addTo(self)
    end
end

function GameUIAllianceMemberInfo:RefreshListView()
    self.player_node:RefreshUI()
end

function GameUIAllianceMemberInfo:AdapterPlayerList()
    local player = self.player_info
    local r = {}
    if player.alliance then
        table.insert(r,{_("职位"),Localize.alliance_title[player.alliance.title]})
        table.insert(r,{_("联盟"),player.alliance.name})
    else
        table.insert(r,{_("职位"),_("无")})
        table.insert(r,{_("联盟"),_("无")})
    end
    if type(player.online) == 'boolean' and player.online then
        table.insert(r,{_("最后登陆"),_("在线")})
    else
        table.insert(r,{_("最后登陆"),NetService:formatTimeAsTimeAgoStyleByServerTime(player.lastLogoutTime)})
    end
    local __,__,indexName = string.find(User.serverId or "","-(%d+)")
    table.insert(r,{_("服务器"),string.format("%s %d",Localize.server_name[User.serverLevel],indexName)})
    table.insert(r,{_("战斗力"),string.formatnumberthousands(player.power)})
    table.insert(r,{_("击杀"),string.formatnumberthousands(player.kill)})

    return r
end

function GameUIAllianceMemberInfo:OnGetPlayerInfoSuccess(data)
    if data.success then
        self.player_info = data.msg.playerViewData
        self:BuildUI()
        self:RefreshListView()
    end
end

function GameUIAllianceMemberInfo:OnMoveOutStage()
    GameUIAllianceMemberInfo.super.OnMoveOutStage(self)
end

--WidgetPlayerNode的回调方法
--点击勋章
function GameUIAllianceMemberInfo:WidgetPlayerNode_OnMedalButtonClicked(index)
end
-- 点击头衔
function GameUIAllianceMemberInfo:WidgetPlayerNode_OnTitleButtonClicked()
end
--修改头像
function GameUIAllianceMemberInfo:WidgetPlayerNode_OnPlayerIconCliked()
end
--修改玩家名
function GameUIAllianceMemberInfo:WidgetPlayerNode_OnPlayerNameCliked()
end
--决定按钮是否可以点击
function GameUIAllianceMemberInfo:WidgetPlayerNode_PlayerCanClickedButton(name,args)
    if name == 'Medal' then --点击勋章
        return true
    elseif name == 'PlayerIcon' then --修改头像
        return false
    elseif name == 'PlayerTitle' then -- 点击头衔
        return true
    elseif name == 'PlayerIDCopy' then --复制玩家ID
        return true
    elseif name == 'PlayerName' then --修改玩家名
        return false
    end

end
--数据回调
function GameUIAllianceMemberInfo:WidgetPlayerNode_DataSource(name)
    print("UIKit:GetPlayerIconImage(self.player_info.icon)--->",UIKit:GetPlayerIconImage(self.player_info.icon))
    if name == 'BasicInfoData' then
        local location
        if self.isMyAlliance then
            local alliacne = Alliance_Manager:GetMyAlliance()
            local member = alliacne:GetMemeberById(self.player_info.id)
            local allianceObj = alliacne:FindMapObjectById(member:MapId())
            location = string.format("(%d,%d)",Alliance:GetLogicPositionWithMapObj(allianceObj))
        end
        local level = User:GetPlayerLevelByExp(self.player_info.levelExp)
        local exp_config = config_playerLevel[level]
        return {
            location = location,
            name = self.player_info.name,
            lv = level,
            currentExp = self.player_info.levelExp  - exp_config.expFrom,
            maxExp =  exp_config.expTo - exp_config.expFrom,
            power = self.player_info.power,
            playerId = self.player_info.id,
            playerIcon = self.player_info.icon,
            vip = DataUtils:getPlayerVIPLevel(self.player_info.vipExp)
        }
    elseif name == "MedalData"  then
        return {}
    elseif name == "TitleData"  then
        return {}
    elseif name == "DataInfoData"  then
        return self:AdapterPlayerList()
    end
end

function GameUIAllianceMemberInfo:CheckPlayerAuthor(button_tag)
    local can_do,msg = true,""
    local alliance = Alliance_Manager:GetMyAlliance()
    local me = alliance:GetSelf()
    local member = alliance:GetMemeberById(self.player_info.id)
    if button_tag == 1 then
        local auth,title_can = me:CanKickOutMember(member:Title())
        can_do = auth and title_can
        if not title_can then
            msg = _("您不能操作此等级成员")
        end
        if not auth then
            msg = _("您没有此权限")
        end
    elseif button_tag == 2 then
        can_do = me:CanGiveUpArchon()
        msg = _("您不是盟主")
    elseif button_tag == 3 then
        local auth,title_can = me:CanDemotionMemberLevel(member:Title())
        local isLow = member:IsTitleLowest()
        can_do = auth and title_can and not isLow
        if not title_can then
            msg = _("您不能操作此等级成员")
        end
        if isLow then
            msg = _("该成员已经是最低等级")
        end
        if not auth then
            msg = _("您没有此权限")
        end
    elseif button_tag == 4 then
        local auth,title_can = me:CanUpgradeMemberLevel(member:TitleUpgrade())
        local isHighest = member:IsTitleHighest()
        can_do = auth and title_can and not isHighest

        if not title_can then
            msg = _("您不能操作此等级成员")
        end
        if isHighest then
            msg = _("该成员已经是最高等级")
        end
        if not auth then
            msg = _("您没有此权限")
        end
    end
    return can_do,msg
end

function GameUIAllianceMemberInfo:ShowMessage(msg)
    UIKit:showMessageDialog(_("提示"), msg,function()end)
end

function GameUIAllianceMemberInfo:ShowSureDialog(msg,ok_func,cancel_func)
    cancel_func = cancel_func or function()end
    UIKit:showMessageDialog(_("提示"), msg, ok_func, cancel_func)
end

return GameUIAllianceMemberInfo


