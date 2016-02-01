--
-- Author: Kenny Dai
-- Date: 2015-08-10 16:07:13
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local StarBar = import(".StarBar")
local UILib = import(".UILib")
local Localize = import("..utils.Localize")
local GameUIShareReport = class("GameUIShareReport", WidgetPopDialog)

function GameUIShareReport:ctor(report)
    GameUIShareReport.super.ctor(self,382,_("战报分享"))
    self.report = report
end
function GameUIShareReport:onEnter()
    GameUIShareReport.super.onEnter(self)
    local report = self.report
    local body = self:GetBody()
    local b_size = body:getContentSize()

    local report_content_bg = WidgetUIBackGround.new({width = 554,height = 114},WidgetUIBackGround.STYLE_TYPE.STYLE_4)
        :align(display.TOP_CENTER, b_size.width/2, b_size.height - 30):addTo(body)
    local report_big_type = report:IsAttackOrStrike()
    if report_big_type == "strike" then
        display.newSprite("icon_strike_69x50.png"):align(display.LEFT_BOTTOM, 0, 0):addTo(report_content_bg):scale(0.8)
        display.newSprite("icon_strike_69x50.png"):align(display.LEFT_BOTTOM, 498, 0):addTo(report_content_bg):flipX(true):scale(0.8)
    elseif report_big_type == "attack" then
        display.newSprite("icon_attack_76x88.png"):align(display.CENTER, 80, 52):addTo(report_content_bg)
        display.newSprite("icon_attack_76x88.png"):align(display.CENTER, 320, 52):addTo(report_content_bg)
    end
    local isFromMe = report:IsFromMe()
    if isFromMe == "attackMonster" then
        local monster_level = report:GetAttackTarget().level
        local monster_data = report:GetEnemyPlayerData().soldiers[1]
        local soldier_type = monster_data.name
        local soldier_star = monster_data.star
        local soldier_ui_config = UILib.black_soldier_image[soldier_type]

        display.newSprite(UILib.black_soldier_color_bg_images[soldier_type]):addTo(report_content_bg)
            :align(display.CENTER_TOP,200, 96):scale(80/128)

        local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER_TOP,200, 96):addTo(report_content_bg)
        soldier_head_icon:scale(80/soldier_head_icon:getContentSize().height)
        display.newSprite("box_soldier_128x128.png")
            :align(display.CENTER, soldier_head_icon:getContentSize().width/2, soldier_head_icon:getContentSize().height-64)
            :addTo(soldier_head_icon)

        UIKit:ttfLabel(
            {
                text = _("黑龙军团"),
                size = 18,
                color = 0x615b44
            }):align(display.LEFT_CENTER, report_content_bg:getContentSize().width/2-10, 80)
            :addTo(report_content_bg)
        UIKit:ttfLabel(
            {
                text = Localize.soldier_name[soldier_type] .. " " ..string.format(_("等级%s"),monster_level),
                size = 20,
                color = 0x403c2f
            }):align(display.LEFT_CENTER, report_content_bg:getContentSize().width/2-10, 35)
            :addTo(report_content_bg)
    elseif isFromMe == "attackShrine" then
        display.newScale9Sprite("alliance_watchTower.png"):addTo(report_content_bg)
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
        local my_flag = a_helper:CreateFlagContentSprite(my_flag_data)
        local enemy_flag = a_helper:CreateFlagContentSprite(enemy_flag_data)
        my_flag:scale(0.55)
        enemy_flag:scale(0.55)
        my_flag:align(display.CENTER, isFromMe and 48 or 288, 13)
            :addTo(report_content_bg)
        enemy_flag:align(display.CENTER, isFromMe and 288 or 48, 13)
            :addTo(report_content_bg)
        -- from title label
        local from_label = UIKit:ttfLabel(
            {
                text = _("From"),
                size = 16,
                color = 0x615b44
            }):align(display.LEFT_CENTER, 120, 80)
            :addTo(report_content_bg)
        -- 发出方名字
        local from_player_label =  UIKit:ttfLabel(
            {
                text = isFromMe and self:GetMyName(report) or self:GetEnemyName(report),
                size = 20,
                color = 0x403c2f,
                dimensions = cc.size(150,20),
                ellipsis = true
            }):align(display.LEFT_CENTER, 120, 60)
            :addTo(report_content_bg)
        -- 发出方所属联盟
        local from_alliance_label = UIKit:ttfLabel(
            {
                text = isFromMe and "["..self:GetMyAllianceTag(report).."]" or "["..self:GetEnemyAllianceTag(report).."]",
                size = 20,
                color = 0x403c2f
            }):align(display.LEFT_CENTER, 120, 30)
            :addTo(report_content_bg)


        -- 战报发向方信息
        -- to title label
        local to_label = UIKit:ttfLabel(
            {
                text = _("To"),
                size = 16,
                color = 0x615b44
            }):align(display.LEFT_CENTER, 370, 80)
            :addTo(report_content_bg)
        -- 发向方名字
        local to_player_label = UIKit:ttfLabel(
            {
                text = isFromMe and self:GetEnemyName(report) or self:GetMyName(report),
                size = 20,
                color = 0x403c2f,
                dimensions = cc.size(150,20),
                ellipsis = true
            }):align(display.LEFT_CENTER, 370, 60)
            :addTo(report_content_bg)
        -- 发向方所属联盟
        local to_alliance_label = UIKit:ttfLabel(
            {
                text = isFromMe and "["..self:GetEnemyAllianceTag(report).."]" or "["..self:GetMyAllianceTag(report).."]",
                size = 20,
                color = 0x403c2f
            }):align(display.LEFT_CENTER, 370, 30)
            :addTo(report_content_bg)
    end

    local textView = ccui.UITextView:create(cc.size(556,112),display.newScale9Sprite("input_box.png"))
    textView:setPlaceHolder(_("说点什么"))
    textView:addTo(body):align(display.CENTER_BOTTOM,b_size.width/2,100)
    textView:setReturnType(cc.KEYBOARD_RETURNTYPE_DEFAULT)
    textView:setFont(UIKit:getEditBoxFont(), 24)
    textView:setMaxLength(100)
    textView:setFontColor(cc.c3b(0,0,0))

    local reportName = ""
    if report:Type() == "strikeCity" or report:Type()== "cityBeStriked"
        or report:Type() == "villageBeStriked" or report:Type()== "strikeVillage" then
        reportName = _("侦查战报")
    elseif report:Type() == "attackCity" or report:Type() == "attackVillage" then
        reportName = report:GetFightAttackName().." VS "..report:GetFightDefenceName()
    elseif report:Type() == "collectResource" then
    elseif report:Type() == "attackMonster" then
        local monster_data = report:GetEnemyPlayerData().soldiers[1]
        local monster_type = monster_data.name
        reportName = User.basicInfo.name.." VS "..Localize.soldier_name[monster_type]
    elseif report:Type() == "attackShrine" then
        reportName = _("圣地战报")
    end


    -- 世界按钮
    local label = UIKit:ttfLabel({
        text = _("世界"),
        size = 20,
        color = 0xfff3c7})
    label:enableShadow()

    WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(label)
        :addTo(body):align(display.CENTER, 100, 50)
        :onButtonClicked(function(event)
            local message = string.format("<report>reportName:%s,userId:%s,reportId:%s<report> %s",reportName,User:Id(),report:Id(),textView:getText() or "")
            app:GetChatManager():SendChat("global",message)
        	GameGlobalUI:showTips(_("提示"),_("分享成功"))
            self:LeftButtonClicked()
        end)
    -- 联盟按钮
    local label = UIKit:ttfLabel({
        text = _("联盟"),
        size = 20,
        color = 0xfff3c7})
    label:enableShadow()

    WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(label)
        :addTo(body):align(display.CENTER, 310, 50)
        :onButtonClicked(function(event)
            if Alliance_Manager:GetMyAlliance():IsDefault() then
                UIKit:showMessageDialog(_("提示"), _("加入联盟后开放此功能!"))
            else
                local message = string.format("<report>reportName:%s,userId:%s,reportId:%s<report> %s",reportName,User:Id(),report:Id(),textView:getText() or "")
                app:GetChatManager():SendChat("alliance",message)
        		GameGlobalUI:showTips(_("提示"),_("分享成功"))
                self:LeftButtonClicked()
            end

        end)

    -- 对战按钮
    local label = UIKit:ttfLabel({
        text = _("对战"),
        size = 20,
        color = 0xfff3c7})
    label:enableShadow()

    WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(label)
        :addTo(body):align(display.CENTER, 510, 50)
        :onButtonClicked(function(event)
            if Alliance_Manager:GetMyAlliance().basicInfo.status == "fight" or Alliance_Manager:GetMyAlliance().basicInfo.status == "prepare"  then
                local message = string.format("<report>reportName:%s,userId:%s,reportId:%s<report> %s",reportName,User:Id(),report:Id(),textView:getText() or "")
                app:GetChatManager():SendChat("allianceFight",message)
        		GameGlobalUI:showTips(_("提示"),_("分享成功"))
                self:LeftButtonClicked()
            else
                UIKit:showMessageDialog(_("提示"), _("联盟未处于战争状态，不能使用此聊天频道!"))
            end
        end)
end
function GameUIShareReport:GetMyName(report)
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
function GameUIShareReport:GetEnemyName(report)
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
function GameUIShareReport:GetMyAllianceTag(report)
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
function GameUIShareReport:GetEnemyAllianceTag(report)
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
return GameUIShareReport








