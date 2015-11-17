--
-- Author: Kenny Dai
-- Date: 2015-05-20 21:32:56
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")

local GameUIWarSummary = class("GameUIWarSummary", WidgetPopDialog)

function GameUIWarSummary:ctor()
    GameUIWarSummary.super.ctor(self,605,_("战斗结算"))
end
function GameUIWarSummary:onEnter()
    app:GetAudioManager():PlayeEffectSoundWithKey('BATTLE_DRAGON')
    GameUIWarSummary.super.onEnter(self)
    self:DisableCloseBtn()
    self:DisableAutoClose()
    local alliance = Alliance_Manager:GetMyAlliance()
      if alliance.allianceFightReports == nil then
            NetManager:getAllianceFightReportsPromise(alliance._id):done(function ()
                self:InitWarSummary(alliance:GetLastAllianceFightReports())
            end)
        else
            self:InitWarSummary(alliance:GetLastAllianceFightReports())
        end
end
function GameUIWarSummary:InitWarSummary(report)
    if not report then
        return
    end
    local alliance = Alliance_Manager:GetMyAlliance()
    -- 各项数据
    local win
    if report.attackAllianceId == alliance._id then
        win = report.fightResult == "attackWin"
    elseif report.defenceAllianceId == alliance._id then
        win = report.fightResult == "defenceWin"
    end
    local fightTime = report.fightTime
    local ourAlliance = report.attackAllianceId == alliance._id and report.attackAlliance or report.defenceAlliance
    local enemyAlliance = report.attackAllianceId == alliance._id and report.defenceAlliance or report.attackAlliance
    local killMax = report.killMax

    local content = self:GetBody()
    local size = content:getContentSize()
    local w,h = size.width,size.height

    local fight_bg = display.newSprite("report_back_ground.png")
        :align(display.TOP_CENTER, w/2,h-30)
        :addTo(content)
        :scale(0.95)
    local win_text = win and _("胜利") or _("失败")
    local win_color = win and 0x007c23 or 0x7e0000
    local our_win_label = UIKit:ttfLabel({
        text = win_text,
        size = 20,
        color = win_color
    }):align(display.RIGHT_CENTER,fight_bg:getContentSize().width/2-90,65)
        :addTo(fight_bg)

    local our_alliance_name = UIKit:ttfLabel({
        text = ourAlliance.name,
        size = 20,
        color = 0x403c2f,
    }):align(display.RIGHT_CENTER,fight_bg:getContentSize().width/2-90,40)
        :addTo(fight_bg)
    local our_alliance_tag = UIKit:ttfLabel({
        text = "["..ourAlliance.tag.."]",
        size = 18,
        color = 0x403c2f,
    }):align(display.RIGHT_CENTER,fight_bg:getContentSize().width/2-90,20)
        :addTo(fight_bg)

    local win_text = not win and _("胜利") or _("失败")
    local win_color = not win and 0x007c23 or 0x7e0000
    local other_win_label = UIKit:ttfLabel({
        text = win_text,
        size = 20,
        color = win_color
    }):align(display.LEFT_CENTER,fight_bg:getContentSize().width/2+90,65)
        :addTo(fight_bg)
    local enemy_alliance_name = UIKit:ttfLabel({
        text = enemyAlliance.name,
        size = 20,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER,fight_bg:getContentSize().width/2+90,40)
        :addTo(fight_bg)
    local enemy_alliance_tag = UIKit:ttfLabel({
        text = "["..enemyAlliance.tag.."]",
        size = 18,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER,fight_bg:getContentSize().width/2+90,20)
        :addTo(fight_bg)
    local VS = UIKit:ttfLabel({
        text = "VS",
        size = 20,
        color = 0x403c2f,
    }):align(display.CENTER,fight_bg:getContentSize().width/2,fight_bg:getContentSize().height/2)
        :addTo(fight_bg)
    -- 己方联盟旗帜
    local ui_helper = WidgetAllianceHelper.new()
    local self_flag = ui_helper:CreateFlagContentSprite(ourAlliance.flag):scale(0.5)
    self_flag:align(display.CENTER, VS:getPositionX()-80, 10)
        :addTo(fight_bg)
    -- 敌方联盟旗帜
    local enemy_flag = ui_helper:CreateFlagContentSprite(enemyAlliance.flag):scale(0.5)
    enemy_flag:align(display.CENTER, VS:getPositionX()+20, 10)
        :addTo(fight_bg)



    -- 击杀数，击溃城市
    local info_bg = WidgetUIBackGround.new({width = 540,height = 388},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
        :align(display.BOTTOM_CENTER,w/2,80):addTo(content)
    local function createItem(info,meetFlag)
        local content
        if meetFlag then
            content = display.newScale9Sprite("back_ground_548x40_1.png"):size(520,46)
        else
            content = display.newScale9Sprite("back_ground_548x40_2.png"):size(520,46)
        end
        UIKit:ttfLabel({
            text = info[1],
            size = 20,
            color = 0x403c2f,
        }):align(display.LEFT_CENTER, 10, 23):addTo(content)
        UIKit:ttfLabel({
            text = info[2],
            size = 20,
            color = 0x5d563f,
        }):align(display.CENTER, 261, 23):addTo(content)
        UIKit:ttfLabel({
            text = info[3],
            size = 20,
            color = 0x403c2f,
        }):align(display.RIGHT_CENTER, 510, 23):addTo(content)
        return content
    end

    local info_message = {
        {string.formatnumberthousands(ourAlliance.kill),_("总击杀"),string.formatnumberthousands(enemyAlliance.kill)},
        {string.formatnumberthousands(ourAlliance.routCount).."/"..string.formatnumberthousands(enemyAlliance.memberCount),_("击溃城市"),string.formatnumberthousands(enemyAlliance.routCount).."/"..string.formatnumberthousands(ourAlliance.memberCount)},
        {string.formatnumberthousands(ourAlliance.strikeCount),_("突袭次数"),string.formatnumberthousands(enemyAlliance.strikeCount)},
        {string.formatnumberthousands(ourAlliance.strikeSuccessCount),_("突袭成功"),string.formatnumberthousands(enemyAlliance.strikeSuccessCount)},
        {string.formatnumberthousands(ourAlliance.attackCount),_("进攻次数"),string.formatnumberthousands(enemyAlliance.attackCount)},
        {string.formatnumberthousands(ourAlliance.attackSuccessCount),_("进攻成功"),string.formatnumberthousands(enemyAlliance.attackSuccessCount)},
        {killMax.allianceId == alliance._id and killMax.playerName ~= json.null and killMax.playerName or _("无"),_("头号杀手"),killMax.allianceId ~= alliance._id and killMax.playerName  ~= json.null and killMax.playerName or _("无")},
        {string.formatnumberthousands(ourAlliance.honour),_("荣耀值奖励"),string.formatnumberthousands(enemyAlliance.honour)},
    }
    local b_flag = true
    local origin_y = 388 - 33
    local gap_y = 46
    for i,v in ipairs(info_message) do
        createItem(v,b_flag):align(display.CENTER, 270, origin_y - (i-1)*gap_y):addTo(info_bg)
        b_flag = not b_flag
    end


    -- 确定返回自己却与地图按钮
    WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}
    ):addTo(content):align(display.CENTER,w/2,45)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("确定"),
            size = 24,
            color = 0xffedae,
            shadow= true
        })):onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            -- local scene_name = display.getRunningScene().__cname
            -- alliance:SetLastAllianceFightReport(nil)
            -- if scene_name == 'AllianceBattleScene' or scene_name == 'AllianceScene' then
            --     app:EnterMyAllianceScene()
            -- elseif scene_name == 'MyCityScene' then
                self:LeftButtonClicked()
            -- end
        end
        end)
end
return GameUIWarSummary











