local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetPages = import("..widget.WidgetPages")
local WidgetInfo = import("..widget.WidgetInfo")
local WidgetInfoAllianceKills = import("..widget.WidgetInfoAllianceKills")
local WidgetInfoWithTitle = import("..widget.WidgetInfoWithTitle")
local Alliance = import("..entity.Alliance")
local UIListView = import(".UIListView")
local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local Localize = import("..utils.Localize")
local aliance_buff = GameDatas.AllianceMap.buff
-- local fire_wall = import("..particles.fire_wall")
local revenge_limit = GameDatas.AllianceInitData.intInit.allianceRevengeMaxMinutes.value

local GameUIAllianceBattle = UIKit:createUIClass('GameUIAllianceBattle', "GameUIWithCommonHeader")

function GameUIAllianceBattle:ctor(city,tag,other_alliance)
    GameUIAllianceBattle.super.ctor(self, city, _("联盟会战"))
    self.alliance = Alliance_Manager:GetMyAlliance()
    self.other_alliance = other_alliance
    self.tag = tag
    self.a_helper = WidgetAllianceHelper.new()
end

function GameUIAllianceBattle:OnMoveInStage()
    GameUIAllianceBattle.super.OnMoveInStage(self)
    local tag = self.tag
    if tag == "history" then
        -- self:InitAllianceInfo()
        -- self:CreateTabButtons({
        --     {
        --         label = _("信息"),
        --         tag = "info",
        --         default = true
        --     },
        --     {
        --         label = _("联盟战历史"),
        --         tag = "history",
        --     },
        -- }, function(tag_1)
        --     if tag_1 == "info" then
        --         if self.history_listview then
        --             self.history_listview:hide()
        --         end
        --         self.info_layer:show()
        --     else
        --         -- 获取历史记录
        --         if self.alliance.allianceFightReports == nil then
        --             NetManager:getAllianceFightReportsPromise(self.alliance.id):done(function ()
        --                 self:InitHistoryRecord()
        --                 self.history_listview:show()
        --             end)
        --         else
        --             self:InitHistoryRecord()
        --             self.history_listview:show()
        --         end
        --         self.info_layer:hide()
        --     end
        -- end):pos(window.cx, window.bottom + 34)
        -- 获取历史记录
        if self.alliance.allianceFightReports == nil then
            NetManager:getAllianceFightReportsPromise(self.alliance._id):done(function ()
                self:InitHistoryRecord()
                -- self.history_listview:show()
            end)
        else
            self:InitHistoryRecord()
            -- self.history_listview:show()
        end
    elseif tag == "fight" then
        self:InitBattleStatistics()
    elseif tag == "capture" then
        UIKit:ttfLabel(
            {
                text = _("即将开放"),
                size = 24,
                color = 0x403c2f,
            }):align(display.CENTER, window.cx, window.cy)
            :addTo(self)
    end
    -- self:CreateTabButtons({
    --     {
    --         label = _("战争统计"),
    --         tag = "statistics",
    --         default = true
    --     },
    --     {
    --         label = _("历史记录"),
    --         tag = "history",
    --     },
    --     {
    --         label = _("其他联盟"),
    --         tag = "other_alliance",
    --     },
    -- }, function(tag)
    --     self.statistics_layer:setVisible(tag == 'statistics')
    --     if tag == 'history' then
    --         self.history_layer:setVisible(true)
    --         if not self.history_listview then
    --             self:InitHistoryRecord()
    --         end
    --     else
    --         self.history_layer:setVisible(false)
    --     end
    --     if tag == 'other_alliance' then
    --         self.other_alliance_layer:setVisible(true)
    --         if not self.alliance_listview then
    --             self:InitOtherAlliance()
    --             NetManager:getNearedAllianceInfosPromise():done(function(response)
    --                 if response.msg.allianceInfos then
    --                     table.sort(response.msg.allianceInfos,function ( a,b )
    --                         return a.basicInfo.power > b.basicInfo.power
    --                     end)
    --                     self:RefreshAllianceListview(response.msg.allianceInfos)
    --                 end
    --             end)

    --         end
    --     else
    --         self.other_alliance_layer:setVisible(false)
    --     end
    -- end):pos(window.cx, window.bottom + 34)

    -- self:InitBattleStatistics()


    self.alliance:AddListenOnType(self, "basicInfo")
end
function GameUIAllianceBattle:OnAllianceDataChanged_basicInfo(alliance,deltaData)
    local ok_status, new_status = deltaData("basicInfo.status")
    if ok_status then
        self:LeftButtonClicked()
    end
end
function GameUIAllianceBattle:onExit()
    self.alliance:RemoveListenerOnType(self, "basicInfo")
    GameUIAllianceBattle.super.onExit(self)
end
function GameUIAllianceBattle:onCleanup()
    GameUIAllianceBattle.super.onCleanup(self)
    cc.Director:getInstance():getTextureCache():removeTextureForKey("alliance_battle_bg_612x886.jpg")
end

-- function GameUIAllianceBattle:OnTimer(current_time)
--     if self.statistics_layer:isVisible() then
--         local status = self.alliance.basicInfo.status
--         if status ~= "peace" then
--             local statusFinishTime = self.alliance.basicInfo.statusFinishTime
--             if math.floor(statusFinishTime/1000)>current_time then
--                 self.time_label:setString(GameUtils:formatTimeStyle1(math.floor(statusFinishTime/1000)-current_time))
--             end
--         else
--             local statusStartTime = self.alliance.basicInfo.statusStartTime
--             if current_time>= math.floor(statusStartTime/1000) then
--                 self.time_label:setString(GameUtils:formatTimeStyle1(current_time-math.floor(statusStartTime/1000)))
--             end
--         end
--     end
--     if self.history_layer:isVisible() then
--         for k,listitem in pairs(self.history_listview:getItems()) do
--             local content = listitem:getContent()
--             if content.RefreshRevengeTime then
--                 listitem:getContent():RefreshRevengeTime(current_time)
--             end
--         end
--     end
-- end

function GameUIAllianceBattle:CreateBetweenBgAndTitle()
    GameUIAllianceBattle.super.CreateBetweenBgAndTitle(self)

    if self.tag == "history" then
        -- info_layer
        self.info_layer = display.newLayer():addTo(self:GetView())
    elseif self.tag == "fight" then
        -- statistics_layer
        self.statistics_layer = display.newLayer():addTo(self:GetView())
    end
    -- other_alliance_layer
    -- self.other_alliance_layer = display.newLayer():addTo(self:GetView())

end
function GameUIAllianceBattle:InitAllianceInfo()
    local layer = self.info_layer
    local alliance = self.alliance
    local bg_jpg = display.newSprite("background_550x170.jpg"):align(display.CENTER, window.cx, window.top_bottom - 80):addTo(layer)

    local shadow_layer = UIKit:shadowLayer():size(548,44):pos(1,110):addTo(bg_jpg)
    WidgetPushButton.new()
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:OpenAllianceBuffDetails()
            end
        end)
        :align(display.LEFT_BOTTOM, 0,0)
        :addTo(shadow_layer):setContentSize(cc.size(548,44))
    local a_helper = self.a_helper
    local flag_sprite = a_helper:CreateFlagContentSprite(alliance.basicInfo.flag)
    flag_sprite:align(display.LEFT_CENTER, 30, -10)
        :addTo(shadow_layer)
        :scale(0.46)

    local alliance_name = UIKit:ttfLabel(
        {
            text = alliance.basicInfo.name,
            size = 30,
            color = 0xffedae,
        }):align(display.LEFT_CENTER, 100, 22)
        :addTo(shadow_layer)
    display.newSprite("info_16x33.png"):align(display.LEFT_CENTER,alliance_name:getPositionX() + alliance_name:getContentSize().width + 20, 22):addTo(shadow_layer)

    local current_position = WidgetUIBackGround.new({
        width = 548,
        height = 50,
    },WidgetUIBackGround.STYLE_TYPE.STYLE_3):align(display.TOP_CENTER,window.cx, bg_jpg:getPositionY() - 100):addTo(layer)
    UIKit:ttfLabel(
        {
            text = _("当前位置"),
            size = 20,
            color = 0x615b44,
        }):align(display.LEFT_CENTER, 16, 25)
        :addTo(current_position)
    UIKit:ttfLabel(
        {
            text = string.format(_("第%d圈"),DataUtils:getMapRoundByMapIndex(alliance.mapIndex) + 1) ,
            size = 22,
            color = 0x403c2f,
        }):align(display.RIGHT_CENTER, 548 - 16, 25)
        :addTo(current_position)

    local bg = WidgetInfoWithTitle.new({
        title = _("联盟地图BUFF"),
        h = 386,
        info = DataUtils:GetAllianceMapBuffByRound(DataUtils:getMapRoundByMapIndex(alliance.mapIndex))
    }):align(display.TOP_CENTER, window.cx, current_position:getPositionY() - 120):addTo(layer)

end
function GameUIAllianceBattle:OpenAllianceBuffDetails()
    UIKit:newWidgetUI("WidgetAllianceMapBuff",self.alliance.mapIndex):AddToCurrentScene()
end
function GameUIAllianceBattle:InitBattleStatistics()
    local layer = self.statistics_layer
    local alliance = self.alliance
    local other_alliance = self.other_alliance
    layer:removeAllChildren()
    self.request_num_label = nil

    display.newSprite("alliance_battle_bg_612x886.jpg"):addTo(layer):align(display.TOP_CENTER,window.cx,window.top_bottom+28)
    local status = alliance.basicInfo.status
    -- local status = ""
    if status == "peace" or status == "protect" then
        local blue_bg = display.newSprite("back_ground_blue_308x96.png"):addTo(layer):align(display.RIGHT_CENTER,window.cx,window.top_bottom - 40)
        local red_bg = display.newSprite("back_ground_red_308x96.png"):addTo(layer):align(display.LEFT_CENTER,window.cx,window.top_bottom - 40)

        local vs_bg = display.newSprite("box_104x104.png")
            :align(display.CENTER, window.cx,window.top_bottom - 42)
            :addTo(layer)
            :scale(0.7)
        display.newSprite("VS_78x50.png")
            :align(display.CENTER, vs_bg:getContentSize().width/2, vs_bg:getContentSize().height/2)
            :addTo(vs_bg)

        -- 己方联盟旗帜
        local a_helper = self.a_helper
        local flag_sprite = a_helper:CreateFlagContentSprite(alliance.basicInfo.flag)
        flag_sprite:align(display.RIGHT_CENTER, blue_bg:getContentSize().width - 110, 10)
            :addTo(blue_bg)
            :scale(0.56)
        local self_name_label = UIKit:ttfLabel(
            {
                text = "["..alliance.basicInfo.tag.."] "..alliance.basicInfo.name,
                size = 18,
                color = 0xffedae,
                dimensions = cc.size(160,18),
                ellipsis = true
            }):align(display.LEFT_CENTER, 30, 84)
            :addTo(blue_bg)
        local self_period_label = UIKit:ttfLabel(
            {
                text = Localize.period_type[alliance.basicInfo.status],
                size = 18,
                color = 0xbdb582,
            }):align(display.LEFT_CENTER, 30, 48)
            :addTo(blue_bg)
        local self_period_time_label = UIKit:ttfLabel(
            {
                size = 18,
                color = 0xffedae,
            }):align(display.LEFT_CENTER, self_period_label:getPositionX() + self_period_label:getContentSize().width + 10, 48)
            :addTo(blue_bg)
        local self_power_bg = display.newSprite("power_background_146x26.png")
            :align(display.LEFT_CENTER, self_period_label:getPositionX() + 10, 18):addTo(blue_bg)
        display.newSprite("dragon_strength_27x31.png")
            :align(display.CENTER, 0,13)
            :addTo(self_power_bg)
        UIKit:ttfLabel(
            {
                text = string.formatnumberthousands(alliance.basicInfo.power),
                size = 18,
                color = 0xbdb582,
            }):align(display.LEFT_CENTER, 20, 13)
            :addTo(self_power_bg)
        -- 敌方联盟旗帜
        local flag_sprite1 = a_helper:CreateFlagContentSprite(other_alliance.basicInfo.flag)
        flag_sprite1:align(display.LEFT_CENTER, 40, 10)
            :addTo(red_bg)
            :scale(0.56)
        local other_name_label = UIKit:ttfLabel(
            {
                text = "["..other_alliance.basicInfo.tag.."] "..other_alliance.basicInfo.name,
                size = 18,
                color = 0xffedae,
                dimensions = cc.size(160,18),
                ellipsis = true
            }):align(display.LEFT_CENTER, 125, 84)
            :addTo(red_bg)
        local other_period_label = UIKit:ttfLabel(
            {
                text = Localize.period_type[other_alliance.basicInfo.status],
                size = 18,
                color = 0xbdb582,
            }):align(display.LEFT_CENTER, 125, 48)
            :addTo(red_bg)
        local other_period_time_label = UIKit:ttfLabel(
            {
                size = 18,
                color = 0xffedae,
            }):align(display.LEFT_CENTER, other_period_label:getPositionX() + other_period_label:getContentSize().width + 10, 48)
            :addTo(red_bg)
        local other_power_bg = display.newSprite("power_background_red_146x26.png")
            :align(display.LEFT_CENTER, other_period_label:getPositionX() + 10, 18):addTo(red_bg)
        display.newSprite("dragon_strength_27x31.png")
            :align(display.CENTER, 0,13)
            :addTo(other_power_bg)
        UIKit:ttfLabel(
            {
                text = string.formatnumberthousands(other_alliance.basicInfo.power),
                size = 18,
                color = 0xbdb582,
            }):align(display.LEFT_CENTER, 20, 13)
            :addTo(other_power_bg)
        display.newSprite("i_icon_20x20.png"):addTo(other_power_bg):align(display.RIGHT_CENTER,148, 14)
        WidgetPushButton.new()
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    UIKit:newGameUI("GameUIAllianceInfo",other_alliance._id,nil,other_alliance.serverId):AddToCurrentScene(true)
                end
            end)
            :align(display.LEFT_BOTTOM, 0,0)
            :addTo(red_bg):setContentSize(cc.size(308,96))

        scheduleAt(layer, function()
            local basicInfo = alliance.basicInfo
            if basicInfo.status ~= "peace" then
                local statusFinishTime = basicInfo.statusFinishTime
                if math.floor(statusFinishTime/1000)>app.timer:GetServerTime() then
                    self_period_time_label:setString(GameUtils:formatTimeStyle1(math.floor(statusFinishTime/1000)-app.timer:GetServerTime()))
                end
            else
                local statusStartTime = basicInfo.statusStartTime
                if app.timer:GetServerTime()>= math.floor(statusStartTime/1000) then
                    self_period_time_label:setString(GameUtils:formatTimeStyle1(app.timer:GetServerTime()-math.floor(statusStartTime/1000)))
                end
            end
            self_period_label:setString(Localize.period_type[basicInfo.status])
            local basicInfo = other_alliance.basicInfo
            if basicInfo.status ~= "peace" then
                local statusFinishTime = basicInfo.statusFinishTime
                if math.floor(statusFinishTime/1000)>app.timer:GetServerTime() then
                    other_period_time_label:setString(GameUtils:formatTimeStyle1(math.floor(statusFinishTime/1000)-app.timer:GetServerTime()))
                end
            else
                local statusStartTime = basicInfo.statusStartTime
                if app.timer:GetServerTime()>= math.floor(statusStartTime/1000) then
                    other_period_time_label:setString(GameUtils:formatTimeStyle1(app.timer:GetServerTime()-math.floor(statusStartTime/1000)))
                end
            end
            other_period_label:setString(Localize.period_type[basicInfo.status])
        end)
        local war_award_info = {
            {_("联盟战荣耀值基础奖励"),"honour_128x128.png",GameDatas.AllianceInitData.fightRewards[User.serverLevel].honour},
            {_("联盟战期间最高击杀者"),"gem_icon_62x61.png",GameDatas.AllianceInitData.fightRewards[User.serverLevel].gem},
            {_("可召集其他联盟前来助阵")},
            {_("将敌方所有玩家城墙摧毁可强制敌方联盟搬迁")},
        }
        local origin_y, gap_y = window.top - 550 - 58/2, -60
        for i,v in ipairs(war_award_info) do
            local award_bg = display.newSprite("tmp_background_red_612x58.png"):addTo(layer)
                :align(display.CENTER,window.cx, origin_y + (i - 1) * gap_y)
            display.newSprite("Stars_bar_highlight.png"):addTo(award_bg)
                :align(display.CENTER,30, 29):scale(1.2)

            local info_label = UIKit:ttfLabel({
                text = v[1],
                size = 20,
                color = 0xffedae,
            }):addTo(award_bg)
                :align(display.LEFT_CENTER,50,29)

            if v[2] then
                local icon = display.newSprite(v[2]):addTo(award_bg)
                    :align(display.CENTER,info_label:getPositionX() + info_label:getContentSize().width + 30, 29)
                icon:scale(45/icon:getContentSize().width)
                UIKit:ttfLabel({
                    text = "+"..v[3],
                    size = 22,
                    color = 0x90e300,
                }):addTo(award_bg,2)
                    :align(display.LEFT_CENTER,icon:getPositionX() + 20,29)
            end
        end

        -- 只有权限大于将军的玩家可以请求开启联盟会战匹配
        local isEqualOrGreater = alliance:GetMemeberById(User:Id())
            :IsTitleEqualOrGreaterThan("general")
        if isEqualOrGreater then
            local button = WidgetPushButton.new({normal = "tmp_button_battle_up_234x82.png",pressed = "tmp_button_battle_down_234x82.png"})
                :setButtonLabel(UIKit:ttfLabel({
                    text = _("开始战斗!") ,
                    size = 24,
                    color = 0xffedae,
                    shadow= true
                }))
                :onButtonClicked(function(event)
                    if event.name == "CLICKED_EVENT" then
                        if alliance.basicInfo.status=="fight" or alliance.basicInfo.status=="prepare" then
                            UIKit:showMessageDialog(_("提示"),_("联盟正在战争准备期或战争期"))
                            return
                        end
                         if other_alliance.basicInfo.status ~= "peace" then
                            UIKit:showMessageDialog(_("提示"),_("目标联盟未处于和平期，不能宣战"))
                            return
                        end
                        UIKit:showMessageDialog(_("主人"),_("确定开启联盟会战吗?")):CreateOKButton(
                            {
                                listener = function ()
                                    NetManager:getAttackAlliancePromose(other_alliance._id)
                                    self:LeftButtonClicked()
                                end
                            }
                        )
                    end
                end):align(display.CENTER_BOTTOM, window.cx, window.bottom_top - 40)
                :addTo(layer)
        else
            UIKit:ttfLabel({
                text = _("由联盟中，将军以上职位玩家发起联盟战"),
                size = 22,
                color = 0xff6023,
            }):addTo(layer)
                :align(display.CENTER,window.cx,window.bottom_top)
        end

    else
        display.newColorLayer(UIKit:hex2c4b(0xcc1a1e26)):addTo(layer):align(display.CENTER,window.left + 14,window.bottom):setContentSize(cc.size(612,886))
        -- time bg
        local time_bg = display.newSprite("tmp_background_624x62.png"):addTo(layer):align(display.TOP_CENTER,window.cx,window.top_bottom+18)
        WidgetPushButton.new({normal = "tmp_battle_btn_up_296x40.png",
            pressed = "tmp_battle_btn_down_296x40.png"})
            :onButtonClicked(function()
                UIKit:newWidgetUI("WidgetWarIntroduce"):AddToCurrentScene(true)
            end)
            :align(display.CENTER,time_bg:getContentSize().width/2, time_bg:getContentSize().height/2)
            :addTo(time_bg)


        local period_label = UIKit:ttfLabel({
            text = Localize.period_type[alliance.basicInfo.status],
            size = 24,
            color = 0xffedae,
        }):addTo(time_bg):align(display.LEFT_CENTER,time_bg:getContentSize().width/2 - 90, time_bg:getContentSize().height/2)

        local time_label = UIKit:ttfLabel({
            text = "",
            size = 24,
            color = 0xe63600,
        }):addTo(time_bg)
            :align(display.LEFT_CENTER,period_label:getPositionX()+period_label:getContentSize().width+20,time_bg:getContentSize().height/2)
        period_label:setPositionX((time_bg:getContentSize().width - (period_label:getContentSize().width + 90 + 20))/2)
        time_label:setPositionX(period_label:getPositionX()+period_label:getContentSize().width+20)
        scheduleAt(layer, function()
            local basicInfo = alliance.basicInfo
            local statusFinishTime = basicInfo.statusFinishTime
            if math.floor(statusFinishTime/1000)>app.timer:GetServerTime() then
                time_label:setString(GameUtils:formatTimeStyle1(math.floor(statusFinishTime/1000)-app.timer:GetServerTime()))
            end
            period_label:setString(Localize.period_type[basicInfo.status])
        end)

        local top_bg = display.newSprite("back_ground_540x70.png")
            :align(display.TOP_CENTER, window.cx, window.top-160)
            :addTo(layer)
            :scale(1.1)
        local t_size = top_bg:getContentSize()

        local enemy_alliance = alliance.allianceFight.attacker.alliance.id == alliance._id and alliance.allianceFight.defencer.alliance or alliance.allianceFight.attacker.alliance

        local self_alliance_bg = WidgetPushButton.new({normal = "button_blue_normal_232x64.png",
            pressed = "button_blue_pressed_232x64.png"})
            :onButtonClicked(function()
                -- self:OpenAllianceDetails(true)
                app:EnterMyAllianceScene({mapIndex = alliance.mapIndex})
            end)
            :align(display.RIGHT_CENTER,t_size.width/2-35, t_size.height/2)
            :addTo(top_bg)
        local enemy_alliance_bg = WidgetPushButton.new({normal = "button_red_normal_232x64.png",
            pressed = "button_red_pressed_232x64.png"})
            :onButtonClicked(function()
                -- self:OpenAllianceDetails(false)
                app:EnterMyAllianceScene({mapIndex = enemy_alliance.mapIndex})
            end)
            :align(display.LEFT_CENTER,t_size.width/2+35, t_size.height/2)
            :addTo(top_bg)

        display.newSprite("icon_goto_30x34.png")
            :align(display.CENTER, 20, t_size.height/2)
            :addTo(top_bg)
        display.newSprite("icon_goto_30x34.png")
            :align(display.CENTER, t_size.width-20, t_size.height/2)
            :addTo(top_bg)
        -- 己方联盟名字
        local our_alliance_tag = UIKit:ttfLabel({
            text = "["..alliance.basicInfo.tag.."]",
            size = 20,
            color = 0xffedae,
        }):addTo(self_alliance_bg)
            :align(display.CENTER,-110,14)
        local our_alliance_name = UIKit:ttfLabel({
            text = alliance.basicInfo.name,
            size = 20,
            color = 0xffedae,
        }):addTo(self_alliance_bg)
            :align(display.CENTER,-110,-14)
        -- 敌方联盟名字
        local a_tag = enemy_alliance.tag
        local a_name = enemy_alliance.name
        local enemy_alliance_tag = UIKit:ttfLabel({
            text ="["..a_tag.."]",
            size = 20,
            color = 0xffedae,
        }):addTo(enemy_alliance_bg)
            :align(display.CENTER,110,14)
        local enemy_alliance_name = UIKit:ttfLabel({
            text =a_name,
            size = 20,
            color = 0xffedae,
        }):addTo(enemy_alliance_bg)
            :align(display.CENTER,110,-14)
        local period_bg = display.newSprite("box_104x104.png")
            :align(display.CENTER, t_size.width/2, t_size.height/2-4)
            :addTo(top_bg)
            :scale(0.75)
        display.newSprite("VS_78x50.png")
            :align(display.CENTER, period_bg:getContentSize().width/2, period_bg:getContentSize().height/2)
            :addTo(period_bg)

        -- 双方击杀排行
        local self_kill = WidgetPushButton.new({normal = "blue_btn_up_256x40.png",pressed = "blue_btn_down_256x40.png"})
            :onButtonClicked(function()
                self:OpenAllianceDetails(true)
            end)
            :setButtonLabel(UIKit:ttfLabel({
                text = _("击杀排行"),
                size = 18,
                color = 0xffedae,
            }))
            :align(display.TOP_LEFT, window.left + 20, window.top-260)
            :addTo(layer)
        display.newSprite("setting_rank_a_75x66.png")
            :align(display.CENTER, 27,-20)
            :addTo(self_kill)
            :scale(0.5)
        display.newSprite("setting_rank_a_75x66.png")
            :align(display.CENTER, 256 - 27,-20)
            :addTo(self_kill)
            :scale(0.5)


        local enemy_kill = WidgetPushButton.new({normal = "red_btn_up_256x40.png",pressed = "red_btn_down_256x40.png"})
            :onButtonClicked(function()
                self:OpenAllianceDetails(false)
            end)
            :setButtonLabel(UIKit:ttfLabel({
                text = _("击杀排行"),
                size = 18,
                color = 0xffedae,
            }))
            :align(display.TOP_RIGHT, window.right - 20, window.top-260)
            :addTo(layer)
        display.newSprite("setting_rank_a_75x66.png")
            :align(display.CENTER, -256 + 27,-20)
            :addTo(enemy_kill)
            :scale(0.5)
        display.newSprite("setting_rank_a_75x66.png")
            :align(display.CENTER, - 27,-20)
            :addTo(enemy_kill)
            :scale(0.5)
        UIKit:ttfLabel({
            text = _("本次联盟会战结束后奖励,总击杀越高奖励越高.获胜方获得70%的总奖励,失败方获得剩下的,获胜联盟击杀第1名的玩家还将获得金龙币奖励"),
            size = 22,
            color = 0xff6023,
            dimensions = cc.size(580,0),
        }):addTo(layer)
            :align(display.TOP_CENTER,window.cx,window.top-320-30)

        -- 荣耀值奖励
        local honour_bg = display.newScale9Sprite("tmp_background_red_130x30.png",window.right-200,window.top-440-50,cc.size(166,32),cc.rect(15,10,100,10))
            :align(display.LEFT_CENTER)
            :addTo(layer)
        display.newSprite("honour_128x128.png"):align(display.CENTER,0,honour_bg:getContentSize().height/2)
            :addTo(honour_bg,2)
            :scale(50/128)
        UIKit:ttfLabel({
            text = "+"..string.formatnumberthousands(GameDatas.AllianceInitData.fightRewards[User.serverLevel].honour),
            size = 22,
            color = 0x90e300,
        }):addTo(honour_bg,2)
            :align(display.CENTER,honour_bg:getContentSize().width/2,honour_bg:getContentSize().height/2)
        -- 金龙币奖励
        local gem_bg = display.newScale9Sprite("tmp_background_red_130x30.png",window.left+210,window.top-440-50,cc.size(166,32),cc.rect(15,10,100,10))
            :align(display.RIGHT_CENTER)
            :addTo(layer)
        display.newSprite("gem_icon_62x61.png"):align(display.CENTER,0,gem_bg:getContentSize().height/2)
            :addTo(gem_bg,2)
            :scale(0.7)
        UIKit:ttfLabel({
            text = "+"..string.formatnumberthousands(GameDatas.AllianceInitData.fightRewards[User.serverLevel].gem),
            size = 22,
            color = 0x90e300,
        }):addTo(gem_bg,2)
            :align(display.CENTER,gem_bg:getContentSize().width/2,gem_bg:getContentSize().height/2)

        local fight_list_node = display.newNode():addTo(layer)
        fight_list_node:setContentSize(cc.size(612,58 * 8 + 6 * 12))
        fight_list_node:align(display.TOP_CENTER,window.cx, window.top - 470)
        self.fight_list_node = fight_list_node
        self:RefreshFightInfoList()
    end



    -- if self.alliance.basicInfo.status ~= "peace" then
    --     display.newColorLayer(UIKit:hex2c4b(0xcc1a1e26)):addTo(layer):align(display.CENTER,window.left + 14,window.bottom):setContentSize(cc.size(612,886))
    -- end

    -- time bg
    -- local time_bg = display.newSprite("tmp_background_624x62.png"):addTo(layer):align(display.TOP_CENTER,window.cx,window.top_bottom+18)

    -- WidgetPushButton.new({normal = "tmp_battle_btn_up_296x40.png",
    --     pressed = "tmp_battle_btn_down_296x40.png"})
    --     :onButtonClicked(function()
    --         self:OpenWarDetails()
    --     end)
    --     :align(display.CENTER,time_bg:getContentSize().width/2, time_bg:getContentSize().height/2)
    --     :addTo(time_bg)

    -- local period_label = UIKit:ttfLabel({
    --     text = self:GetAlliancePeriod(),
    --     size = 24,
    --     color = 0xffedae,
    -- }):addTo(time_bg):align(display.LEFT_CENTER,time_bg:getContentSize().width/2 - 90, time_bg:getContentSize().height/2)

    -- self.time_label = UIKit:ttfLabel({
    --     text = "",
    --     size = 24,
    --     color = 0xe63600,
    -- }):addTo(time_bg)
    --     :align(display.LEFT_CENTER,period_label:getPositionX()+period_label:getContentSize().width+20,time_bg:getContentSize().height/2)
    -- period_label:setPositionX((time_bg:getContentSize().width - (period_label:getContentSize().width + 90 + 20))/2)
    -- self.time_label:setPositionX(period_label:getPositionX()+period_label:getContentSize().width+20)
    if self.alliance.basicInfo.status == "peace" then
    -- 请求开战玩家数量
    -- local request_fight_bg = display.newSprite("tmp_background_red_130x30.png"):align(display.LEFT_CENTER, window.left + 40, window.bottom_top + 55)
    --     :addTo(layer)
    -- WidgetPushButton.new()
    --     :onButtonClicked(function()
    --         self:OpenRequestFightList()
    --     end)
    --     :align(display.LEFT_BOTTOM, window.left + 40, window.bottom_top + 40)
    --     :addTo(layer):setContentSize(cc.size(160,70))
    -- cc.ui.UIImage.new("res_citizen_88x82.png")
    --     :align(display.CENTER,request_fight_bg:getContentSize().width-120, request_fight_bg:getContentSize().height/2)
    --     :addTo(request_fight_bg)
    --     :scale(0.4)
    -- local fight_label = UIKit:ttfLabel({
    --     text = _("请求开战玩家"),
    --     size = 22,
    --     color = 0xffedae,
    -- }):addTo(layer)
    --     :align(display.LEFT_CENTER,window.left + 40, window.bottom_top + 95)
    -- display.newSprite("i_icon_24x24.png"):align(display.LEFT_CENTER, fight_label:getContentSize().width + fight_label:getPositionX() + 10, window.bottom_top + 95)
    --     :addTo(layer)
    -- self.request_num_label = UIKit:ttfLabel(
    --     {
    --         text = 0,
    --         size = 22,
    --         color = 0xffedae
    --     }):align(display.CENTER, request_fight_bg:getContentSize().width-60, request_fight_bg:getContentSize().height/2)
    --     :addTo(request_fight_bg)
    -- self.request_num_label:schedule(function()
    --     if self.request_num_label then
    --         self.request_num_label:setString(0)
    --     end
    -- end, 1)

    -- -- 介绍
    -- -- 只有权限大于将军的玩家可以请求开启联盟会战匹配
    -- local isEqualOrGreater = self.alliance:GetMemeberById(DataManager:getUserData()._id)
    --     :IsTitleEqualOrGreaterThan("general")


    -- local button = WidgetPushButton.new({normal = "tmp_button_battle_up_234x82.png",pressed = "tmp_button_battle_down_234x82.png"})
    --     :setButtonLabel(UIKit:ttfLabel({
    --         text = isEqualOrGreater and _("开始战斗!") or _("请求开战!"),
    --         size = 24,
    --         color = 0xffedae,
    --         shadow= true
    --     }))
    --     :onButtonClicked(function(event)
    --         if event.name == "CLICKED_EVENT" then
    --             if isEqualOrGreater then
    --                 if self.alliance.basicInfo.status=="fight" or self.alliance.basicInfo.status=="prepare" then
    --                     UIKit:showMessageDialog(_("提示"),_("联盟正在战争准备期或战争期"))
    --                     return
    --                 end
    --                 UIKit:showMessageDialog(_("主人"),_("确定开启联盟会战吗?")):CreateOKButton(
    --                     {
    --                         listener = function ()
    --                             NetManager:getAttackAlliancePromose()
    --                         end
    --                     }
    --                 )
    --             end
    --         end
    --     end):align(display.RIGHT_BOTTOM, window.right - 36, window.bottom_top + 26)
    --     :addTo(layer)

    -- display.newSprite("fight_icon_66x66.png"):addTo(button):align(display.LEFT_CENTER, -312,48)


    -- local intro_1_text = isEqualOrGreater and _("参加联盟会战,赢得荣誉,金龙币和丰厚战利品,联盟处在和平期可以主动匹配或被其他联盟匹配进行联盟会战")
    --     or _("联盟处在和平期可以主动匹配或被其他联盟匹配进行联盟会战")
    -- local intro_1 = UIKit:ttfLabel({
    --     text = intro_1_text,
    --     size = 22,
    --     color = 0xff6023,
    --     dimensions = cc.size(530,0),
    -- }):addTo(layer)
    --     :align(display.TOP_CENTER,window.cx, window.top-420)

    -- 奖励介绍
    -- local award_bg1 = display.newSprite("tmp_background_red_612x58.png"):addTo(layer)
    --     :align(display.CENTER,window.cx, window.top-570)
    -- local award_bg2 = display.newSprite("tmp_background_red_612x58.png"):addTo(layer)
    --     :align(display.CENTER,window.cx, window.top-630)
    -- local award_bg3 = display.newSprite("tmp_background_red_612x58.png"):addTo(layer)
    --     :align(display.CENTER,window.cx, window.top-690)
    -- display.newSprite("Stars_bar_highlight.png"):addTo(award_bg1)
    --     :align(display.CENTER,30, 29):scale(1.2)
    -- display.newSprite("Stars_bar_highlight.png"):addTo(award_bg2)
    --     :align(display.CENTER,30, 29):scale(1.2)
    -- display.newSprite("Stars_bar_highlight.png"):addTo(award_bg3)
    --     :align(display.CENTER,30, 29):scale(1.2)
    -- local honour_label = UIKit:ttfLabel({
    --     text = _("联盟荣耀"),
    --     size = 22,
    --     color = 0xffedae,
    -- }):addTo(award_bg1)
    --     :align(display.LEFT_CENTER,50,29)
    -- local gem_label = UIKit:ttfLabel({
    --     text = _("金龙币"),
    --     size = 22,
    --     color = 0xffedae,
    -- }):addTo(award_bg2)
    --     :align(display.LEFT_CENTER,50,29)
    -- UIKit:ttfLabel({
    --     text = _("击杀敌方单位获得龙的材料"),
    --     size = 22,
    --     color = 0xffedae,
    -- }):addTo(award_bg3)
    --     :align(display.LEFT_CENTER,50,29)

    -- -- 荣耀值奖励
    -- local honour_icon = display.newSprite("honour_128x128.png"):align(display.CENTER,honour_label:getContentSize().width + honour_label:getPositionX() + 40,29)
    --     :addTo(award_bg1)
    --     :scale(45/128)
    -- UIKit:ttfLabel({
    --     text = "+"..string.formatnumberthousands(GameDatas.AllianceInitData.fightRewards[User.serverLevel].honour),
    --     size = 22,
    --     color = 0x90e300,
    -- }):addTo(award_bg1,2)
    --     :align(display.LEFT_CENTER,honour_icon:getPositionX() + 20,29)
    -- -- 金龙币奖励
    -- local gem_icon = display.newSprite("gem_icon_62x61.png"):align(display.CENTER,gem_label:getContentSize().width + gem_label:getPositionX() + 40,29)
    --     :addTo(award_bg2)
    --     :scale(0.7)
    -- UIKit:ttfLabel({
    --     text = "+"..string.formatnumberthousands(GameDatas.AllianceInitData.fightRewards[User.serverLevel].gem),
    --     size = 22,
    --     color = 0x90e300,
    -- }):addTo(award_bg2)
    --     :align(display.LEFT_CENTER, gem_icon:getPositionX() + 20,29)
    else
    -- local our_alliance = self.alliance
    -- -- local enemy_alliance = Alliance_Manager:GetEnemyAlliance()
    -- local top_bg = display.newSprite("back_ground_540x70.png")
    --     :align(display.TOP_CENTER, window.cx, window.top-160)
    --     :addTo(layer)
    --     :scale(1.1)
    -- local t_size = top_bg:getContentSize()

    -- local self_alliance_bg = WidgetPushButton.new({normal = "button_blue_normal_232x64.png",
    --     pressed = "button_blue_pressed_232x64.png"})
    --     :onButtonClicked(function()
    --         self:OpenAllianceDetails(true)
    --     end)
    --     :align(display.RIGHT_CENTER,t_size.width/2-35, t_size.height/2)
    --     :addTo(top_bg)
    -- local enemy_alliance_bg = WidgetPushButton.new({normal = "button_red_normal_232x64.png",
    --     pressed = "button_red_pressed_232x64.png"})
    --     :onButtonClicked(function()
    --         self:OpenAllianceDetails(false)
    --     end)
    --     :align(display.LEFT_CENTER,t_size.width/2+35, t_size.height/2)
    --     :addTo(top_bg)
    -- -- 己方联盟名字
    -- local our_alliance_tag = UIKit:ttfLabel({
    --     text = "["..our_alliance.basicInfo.tag.."]",
    --     size = 22,
    --     color = 0xffedae,
    -- }):addTo(self_alliance_bg)
    --     :align(display.CENTER,-120,14)
    -- local our_alliance_name = UIKit:ttfLabel({
    --     text = our_alliance.basicInfo.name,
    --     size = 22,
    --     color = 0xffedae,
    -- }):addTo(self_alliance_bg)
    --     :align(display.CENTER,-120,-14)
    -- -- 敌方联盟名字
    -- local a_tag = ""
    -- local a_name = ""
    -- if enemy_alliance then
    --     if enemy_alliance.basicInfo.tag
    --         and enemy_alliance.basicInfo.name then
    --         a_tag = "["..enemy_alliance.basicInfo.tag.."]"
    --         a_name = enemy_alliance.basicInfo.name
    --     end
    -- end
    -- local enemy_alliance_tag = UIKit:ttfLabel({
    --     text =a_tag,
    --     size = 22,
    --     color = 0xffedae,
    -- }):addTo(enemy_alliance_bg)
    --     :align(display.CENTER,120,14)
    -- local enemy_alliance_name = UIKit:ttfLabel({
    --     text =a_name,
    --     size = 22,
    --     color = 0xffedae,
    -- }):addTo(enemy_alliance_bg)
    --     :align(display.CENTER,120,-14)
    -- local period_bg = display.newSprite("box_104x104.png")
    --     :align(display.CENTER, t_size.width/2, t_size.height/2-4)
    --     :addTo(top_bg)
    --     :scale(0.75)
    -- display.newSprite("VS_78x50.png")
    --     :align(display.CENTER, period_bg:getContentSize().width/2, period_bg:getContentSize().height/2)
    --     :addTo(period_bg)


    -- -- 保护期显示战斗结果
    -- local info_bg_y
    -- if our_alliance.basicInfo.status == "protect" then
    --     -- 禁用联盟按钮
    --     self_alliance_bg:setButtonEnabled(false)
    --     enemy_alliance_bg:setButtonEnabled(false)
    --     local last_fight_reports = our_alliance:GetLastAllianceFightReports()
    --     local fight_result
    --     if our_alliance.id == last_fight_reports.attackAllianceId then
    --         fight_result = last_fight_reports.fightResult == "attackWin"
    --     else
    --         fight_result = last_fight_reports.fightResult == "defenceWin"
    --     end
    --     local our_reprot_data = our_alliance:GetOurLastAllianceFightReportsData()
    --     local enemy_reprot_data = our_alliance:GetEnemyLastAllianceFightReportsData()

    --     our_alliance_name:setString(our_reprot_data.name)
    --     enemy_alliance_name:setString(enemy_reprot_data.name)
    --     our_alliance_tag:setString("["..our_reprot_data.tag.."]")
    --     enemy_alliance_tag:setString("["..enemy_reprot_data.tag.."]")


    --     local win = ccs.Armature:create("win"):align(fight_result and display.RIGHT_CENTER or display.LEFT_CENTER,fight_result and window.left+250 or window.right-250,window.top-270)
    --         :addTo(layer)
    --         :scale(0.5)
    --     win:getAnimation():play("Victory", -1, 0)
    --     local defeat = ccs.Armature:create("win"):align(fight_result and display.LEFT_CENTER or display.RIGHT_CENTER,not fight_result and window.left+250 or window.right-250,window.top-270)
    --         :addTo(layer)
    --         :scale(0.5)
    --     defeat:getAnimation():play("Defeat", -1, 0)

    --     local isEqualOrGreater = self.alliance:GetMemeberById(DataManager:getUserData()._id)
    --         :IsTitleEqualOrGreaterThan("general")
    --     if isEqualOrGreater then
    --         UIKit:ttfLabel({
    --             text = _("不需要保护,立即开战!"),
    --             size = 22,
    --             color = 0xffefba,
    --         }):addTo(layer)
    --             :align(display.LEFT_CENTER,window.left+50,window.bottom_top + 70)

    --         local button = WidgetPushButton.new({normal = "tmp_button_battle_up_234x82.png",pressed = "tmp_button_battle_down_234x82.png"})
    --             :setButtonLabel(UIKit:ttfLabel({
    --                 text = _("开始战斗!"),
    --                 size = 24,
    --                 color = 0xffedae,
    --                 shadow= true
    --             }))
    --             :onButtonClicked(function(event)
    --                 if event.name == "CLICKED_EVENT" then
    --                     UIKit:showMessageDialog(_("主人"),_("确定开启联盟会战吗?")):CreateOKButton(
    --                         {
    --                             listener = function ()
    --                                 NetManager:getAttackAlliancePromose()
    --                             end
    --                         }
    --                     )
    --                 end
    --             end):align(display.RIGHT_BOTTOM, window.right - 36, window.bottom_top + 26)
    --             :addTo(layer)
    --         -- display.newSprite("fight_icon_66x66.png"):addTo(button):align(display.LEFT_CENTER, -312,48)
    --     end
    --     info_bg_y = window.top-310
    -- else
    --     UIKit:ttfLabel({
    --         text = _("本次联盟会战结束后奖励,总击杀越高奖励越高.获胜方获得70%的总奖励,失败方获得剩下的,获胜联盟击杀第1名的玩家还将获得金龙币奖励"),
    --         size = 22,
    --         color = 0xff6023,
    --         dimensions = cc.size(560,0),
    --     }):addTo(layer)
    --         :align(display.TOP_CENTER,window.cx,window.top-250)
    --     -- 荣耀值奖励
    --     local honour_bg = display.newScale9Sprite("tmp_background_red_130x30.png",window.right-240,window.top-390,cc.size(166,32),cc.rect(15,10,100,10))
    --         :align(display.LEFT_CENTER)
    --         :addTo(layer)
    --     display.newSprite("honour_128x128.png"):align(display.CENTER,0,honour_bg:getContentSize().height/2)
    --         :addTo(honour_bg,2)
    --         :scale(50/128)
    --     UIKit:ttfLabel({
    --         text = "+"..string.formatnumberthousands(GameDatas.AllianceInitData.fightRewards[User.serverLevel].honour),
    --         size = 22,
    --         color = 0x90e300,
    --     }):addTo(honour_bg,2)
    --         :align(display.CENTER,honour_bg:getContentSize().width/2,honour_bg:getContentSize().height/2)
    --     -- 金龙币奖励
    --     local gem_bg = display.newScale9Sprite("tmp_background_red_130x30.png",window.left+250,window.top-390,cc.size(166,32),cc.rect(15,10,100,10))
    --         :align(display.RIGHT_CENTER)
    --         :addTo(layer)
    --     display.newSprite("gem_icon_62x61.png"):align(display.CENTER,0,gem_bg:getContentSize().height/2)
    --         :addTo(gem_bg,2)
    --         :scale(0.7)
    --     UIKit:ttfLabel({
    --         text = "+"..string.formatnumberthousands(GameDatas.AllianceInitData.fightRewards[User.serverLevel].gem),
    --         size = 22,
    --         color = 0x90e300,
    --     }):addTo(gem_bg,2)
    --         :align(display.CENTER,gem_bg:getContentSize().width/2,gem_bg:getContentSize().height/2)
    --     info_bg_y = window.top-430
    -- end
    -- local fight_list_node = display.newNode():addTo(layer)
    -- fight_list_node:setContentSize(cc.size(612,58 * 7 + 6 * 12))
    -- fight_list_node:align(display.TOP_CENTER,window.cx, info_bg_y)
    -- self.fight_list_node = fight_list_node
    -- self:RefreshFightInfoList()
    end
end

function GameUIAllianceBattle:RefreshFightInfoList(info_bg_y)
    local fight_list_node = self.fight_list_node
    if fight_list_node and fight_list_node.removeAllChildren then
        fight_list_node:removeAllChildren()

        local alliance = self.alliance
        local our = alliance.allianceFight.attacker.alliance.id == alliance._id and alliance.allianceFight.attacker or alliance.allianceFight.defencer
        local enemy = alliance.allianceFight.attacker.alliance.id == alliance._id and alliance.allianceFight.defencer or alliance.allianceFight.attacker
        local ourKillMaxName,enemyKillMaxName


        local temp_name,temp_kills = _("无"),0
        for i,v in ipairs(our.playerKills) do
            if v.kill > temp_kills then
                temp_kills = v.kill
                temp_name = v.name
            end
        end
        local enemy_temp_name,enemy_temp_kills = _("无"),0
        for i,v in ipairs(enemy.playerKills) do
            if v.kill > enemy_temp_kills then
                enemy_temp_kills = v.kill
                enemy_temp_name = v.name
            end
        end
        if temp_kills < enemy_temp_kills then
            ourKillMaxName = _("无")
            enemyKillMaxName = enemy_temp_name
        else
            ourKillMaxName = temp_name
            enemyKillMaxName = _("无")
        end
        local our_count_data = our.allianceCountData
        local enemy_count_data = enemy.allianceCountData
        local info_message = {
            {string.formatnumberthousands(our_count_data.kill),_("击杀积分"),string.formatnumberthousands(enemy_count_data.kill)},
            {our_count_data.routCount.."/"..enemy.alliance.memberCount,_("击溃城市"),enemy_count_data.routCount.."/"..our.alliance.memberCount},
            {our_count_data.attackCount,_("进攻次数"),enemy_count_data.attackCount},
            {our_count_data.attackSuccessCount,_("进攻获胜"),enemy_count_data.attackSuccessCount},
            {our_count_data.strikeCount,_("突袭次数"),enemy_count_data.strikeCount},
            {our_count_data.strikeSuccessCount,_("突袭成功"),enemy_count_data.strikeSuccessCount},
            {ourKillMaxName,_("头号杀手"),enemyKillMaxName},
        }

        local origin_y = fight_list_node:getContentSize().height - 58
        for i,v in ipairs(info_message) do
            local item = self:CreateInfoItem(v,i):addTo(fight_list_node):align(display.TOP_CENTER, fight_list_node:getContentSize().width/2, origin_y - (i-1) * 60)
            -- 击杀积分和击溃城市有点击效果，弹出提示
            if i == 2 then
                local layer = display.newColorLayer(UIKit:hex2c4b(0x19ffffff)):align(display.CENTER, 0, origin_y - (i-1) * 60 - 58)
                    :addTo(fight_list_node):size(612,58):hide()
               local button = WidgetPushButton.new()
                    :onButtonPressed(function(event)
                        layer:show()
                    end):onButtonRelease(function(event)
                        layer:hide()
                    end)
                    :align(display.CENTER, fight_list_node:getContentSize().width/2, origin_y - (i-1) * 60 - 29)
                    :addTo(fight_list_node):setContentSize(cc.size(612,58))
                UIKit:addTipsToNode(button,_("当击溃的敌方城市数量大于等于其联盟的玩家数量，且我方获得联盟战的最终胜利，敌方联盟则会被强制迁移"),
                    self,cc.size(300,0))
            end
        end
    end
end

function GameUIAllianceBattle:CreateInfoItem(info_message,index)
    local content =display.newScale9Sprite("tmp_background_red_612x58.png")
    UIKit:ttfLabel({
        text = info_message[1],
        size = 22,
        color = 0xffefba,
    }):align(display.LEFT_CENTER, 20, 29):addTo(content)
    local text_2 = UIKit:ttfLabel({
        text = info_message[2],
        size = 22,
        color = 0xff6023,
    }):align(display.CENTER, 612/2, 29):addTo(content)
    UIKit:ttfLabel({
        text = info_message[3],
        size = 22,
        color = 0xffefba,
    }):align(display.RIGHT_CENTER, 592, 29):addTo(content)
    if index == 2 then
        display.newSprite("info_16x33.png"):addTo(content):align(display.CENTER, text_2:getPositionX() + text_2:getContentSize().width/2 + 15, 29):scale(0.5)
    end
    return content
end

function GameUIAllianceBattle:OpenAllianceDetails(isOur)
    local alliance = self.alliance
    local allianceFight = alliance.allianceFight
    local target_alliance
    if isOur then
        target_alliance = alliance._id == allianceFight.attacker.alliance.id and allianceFight.attacker or allianceFight.defencer
    else
        target_alliance = alliance._id == allianceFight.attacker.alliance.id and allianceFight.defencer or allianceFight.attacker
    end
    local alliance_name = target_alliance.alliance.name
    local alliance_tag = target_alliance.alliance.tag
    -- local count_data = target_alliance.allianceCountData
    -- 玩家联盟成员
    -- local palace_level = alliance:FindAllianceBuildingInfoByName("palace").level
    -- local memberCount = GameDatas.AllianceBuilding.palace[palace_level].memberCount
    -- local enemy_memberCount = GameDatas.AllianceBuilding.palace[target_alliance:FindAllianceBuildingInfoByName("palace").level].memberCount
    -- local alliance_members = isOur and alliance:GetMembersCount().."/"..memberCount or target_alliance:GetMembersCount().."/"..enemy_memberCount
    -- 联盟语言
    -- local  language = isOur and alliance.basicInfo.language or target_alliance.basicInfo.language
    -- 联盟战斗力
    -- local  alliance_power = isOur and alliance.basicInfo.power or target_alliance.basicInfo.power
    -- 联盟击杀
    -- local alliance_kill = count_data.kill
    -- 玩家击杀列表
    local player_kill = target_alliance.playerKills
    -- 联盟旗帜
    -- local alliance_flag = target_alliance.alliance.flag
    -- 联盟地形
    -- local alliance_terrain = isOur and alliance.basicInfo.terrain or target_alliance.basicInfo.terrain


    local body = UIKit:newWidgetUI("WidgetPopDialog",630,_("击杀排行")):AddToCurrentScene():GetBody()
    local rb_size = body:getContentSize()


    UIKit:ttfLabel({
        text = "["..alliance_tag.."]  "..alliance_name,
        size = 24,
        color = 0x403c2f,
    }):align(display.CENTER, rb_size.width/2,rb_size.height-60)
        :addTo(body)

    -- local function addAttr(title,value,x,y)
    --     local attr_title = UIKit:ttfLabel({
    --         text = title,
    --         size = 20,
    --         color = 0x615b44,
    --     }):align(display.LEFT_CENTER, x, y)
    --         :addTo(body)
    --     UIKit:ttfLabel({
    --         text = value,
    --         size = 20,
    --         color = 0x403c2f,
    --     }):align(display.LEFT_CENTER,x + attr_title:getContentSize().width+20,y)
    --         :addTo(body)
    -- end
    -- addAttr(_("成员"),alliance_members,180,rb_size.height-100)
    -- addAttr(_("语言"),language,180,rb_size.height-140)
    -- addAttr(_("战斗力"),string.formatnumberthousands(alliance_power),350,rb_size.height-100)
    -- addAttr(_("击杀"),string.formatnumberthousands(alliance_kill),350,rb_size.height-140)

    local clone_player_kill = clone(player_kill)
    table.sort( clone_player_kill, function (a,b)
        return a.kill>b.kill
    end )
    local bg_color = true
    local infos = {}
    for i,v in ipairs(clone_player_kill) do
        table.insert(infos, {name = v.name, kill = v.kill})
    end
    WidgetInfoAllianceKills.new({h=492,info = infos}):addTo(body)
        :align(display.BOTTOM_CENTER,rb_size.width/2,40)
end


function GameUIAllianceBattle:OpenWarDetails()
    local layer = UIKit:newWidgetUI("WidgetPopDialog",608,_("联盟对战")):AddToCurrentScene()
    local body = layer:GetBody()
    local rb_size = body:getContentSize()

    local war_introduce_table = {
        _("系统匹配两个战斗力相近的联盟，将彼此的领地拼接到一起。每场联盟匹配战，根据所在天梯服务器的等级，只要进行匹配就会有奖励。需要将军和盟主才能开战。"),
        _("成功匹配到对手后，会有一个准备时间。此时无法对敌方进攻或者突袭，也无法移动城市的位置。请召唤你的盟友，让他们做好战斗准备。"),
        _("进入战争期后，双方可以派兵攻打对方城市，抢占对方的村落。击杀敌方单位可以增加本场匹配战的总奖励。若击溃敌方玩家城市，还可以获得额外的荣耀值奖励加成。"),
        _("联盟匹配战结束后，参战双方都会进入保护期，此时不会被其他联盟攻打。"),
    }

    local info_bg = WidgetUIBackGround.new({
        width = 574,
        height = 422,
    },WidgetUIBackGround.STYLE_TYPE.STYLE_6):align(display.TOP_CENTER,rb_size.width/2,rb_size.height-90):addTo(body)
    local war_introduce_label = UIKit:ttfLabel({
        text = "概述，准备期。战争期，保护期的描述。",
        size = 20,
        color = 0x403c2f,
        dimensions = cc.size(550,0)
    })
        :align(display.LEFT_TOP,12,410)
        :addTo(info_bg)

    WidgetPages.new({
        page =4, -- 页数
        titles =  {_("概述"),
            _("准备期"),
            _("战争期"),
            _("保护期")}, -- 标题 type -> table
        cb = function (page)
            war_introduce_label:setString(war_introduce_table[page])
        end -- 回调
    }):align(display.CENTER, rb_size.width/2,rb_size.height-50)
        :addTo(body)

    local btn_bg = UIKit:commonButtonWithBG(
        {
            w=185,
            h=65,
            style = UIKit.BTN_COLOR.YELLOW,
            labelParams = {text = _("明白")},
            listener = function ()
                layer:removeFromParent(true)
            end,
        }
    ):pos(rb_size.width/2, 50)
        :addTo(body)

end
function GameUIAllianceBattle:OpenRequestFightList()
    local body = UIKit:newWidgetUI("WidgetPopDialog",500,_("请求开战玩家")):AddToCurrentScene():GetBody()
    local rb_size = body:getContentSize()

    WidgetInfo.new({
        info=self:GetFightRequestsInfo(),
        h =404
    }):align(display.BOTTOM_CENTER, rb_size.width/2 , 50)
        :addTo(body)
end
function GameUIAllianceBattle:GetFightRequestsInfo()
    local alliance = self.alliance
    local info = {}

    for _,id in pairs(fight_requests) do
        -- 玩家
        local member = alliance:GetMemeberById(id)
        if member then
            table.insert(info, {member:Name(),string.formatnumberthousands(member:Power()) ,"dragon_strength_27x31.png",true})
        end
    end
    return info
end
function GameUIAllianceBattle:InitHistoryRecord()
    local list = UIListView.new({
        async = true, --异步加载
        viewRect = cc.rect(0, 0,568, 860),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list:setRedundancyViewVal(294)
    list:setDelegate(handler(self, self.HistoryDelegate))
    list:reload()
    list:addTo(self:GetView()):align(display.BOTTOM_CENTER, window.cx - 568/2, window.bottom + 20)
    self.history_listview = list
end
function GameUIAllianceBattle:HistoryDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #(self.alliance.allianceFightReports or {})
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateHistoryContent()

            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetData(idx)
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        return item
    elseif UIListView.ASY_REFRESH == tag then
        for i,v in ipairs(listView:getItems()) do
            if v.idx_ == idx then
                local content = v:getContent()
                content:SetData(idx)
                local size = content:getContentSize()
                v:setItemSize(size.width, size.height)
            end
        end
    end
end
function GameUIAllianceBattle:CreateHistoryContent()
    local w,h = 568,338
    local content = WidgetUIBackGround.new({height=h,width=w},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    -- 战斗发生时间
    UIKit:ttfLabel({
        text = _("立即定位到敌方联盟"),
        size = 20,
        color = 0x615b44,
    }):align(display.LEFT_CENTER,20, 40)
        :addTo(content)

    local fight_bg = display.newSprite("report_back_ground.png")
        :align(display.TOP_CENTER, w/2,h-8)
        :addTo(content)
        :scale(0.95)
    local our_win_label = UIKit:ttfLabel({
        size = 20,
    }):align(display.RIGHT_CENTER,fight_bg:getContentSize().width/2-90,65)
        :addTo(fight_bg)

    local our_alliance_name = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f,
    }):align(display.RIGHT_CENTER,fight_bg:getContentSize().width/2-90,40)
        :addTo(fight_bg)
    local our_alliance_tag = UIKit:ttfLabel({
        size = 18,
        color = 0x403c2f,
    }):align(display.RIGHT_CENTER,fight_bg:getContentSize().width/2-90,20)
        :addTo(fight_bg)


    local other_win_label = UIKit:ttfLabel({
        size = 20,
    }):align(display.LEFT_CENTER,fight_bg:getContentSize().width/2+90,65)
        :addTo(fight_bg)
    local enemy_alliance_name = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER,fight_bg:getContentSize().width/2+90,40)
        :addTo(fight_bg)
    local enemy_alliance_tag = UIKit:ttfLabel({
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

    -- 击杀数，击溃城市
    local info_bg = WidgetUIBackGround.new({width = 540,height = 160},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
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

    -- 定位按钮
    local goto_button = WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false},
        {disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}}
    ):addTo(content):align(display.RIGHT_CENTER,560,40)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("定位"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))

    local parent = self
    local ui_helper = self.a_helper
    function content:SetData( idx )
        local alliance = parent.alliance
        local cloneReports = clone(alliance.allianceFightReports)
        table.sort(cloneReports,function ( a , b )
            return a.fightTime > b.fightTime
        end)
        local report = cloneReports[idx]
        self.report = report
        -- 各项数据
        local win
        if report.attackAllianceId == alliance._id then
            win = report.fightResult == "attackWin"
        elseif report.defenceAllianceId == alliance._id then
            win = report.fightResult == "defenceWin"
        end
        local ourAlliance = report.attackAllianceId == alliance._id and report.attackAlliance or report.defenceAlliance
        local enemyAlliance = report.attackAllianceId == alliance._id and report.defenceAlliance or report.attackAlliance
        local killMax = report.killMax

        local win_text = win and _("胜利") or _("失败")
        local win_color = win and 0x007c23 or 0x7e0000
        our_win_label:setString(win_text)
        our_win_label:setColor(UIKit:hex2c4b(win_color))

        our_alliance_name:setString(ourAlliance.name)
        our_alliance_tag:setString("["..ourAlliance.tag.."]")

        local win_text = not win and _("胜利") or _("失败")
        local win_color = not win and 0x007c23 or 0x7e0000
        other_win_label:setString(win_text)
        other_win_label:setColor(UIKit:hex2c4b(win_color))

        enemy_alliance_name:setString(enemyAlliance.name)
        enemy_alliance_tag:setString("["..enemyAlliance.tag.."]")

        if self.self_flag then
            self.self_flag:SetFlag(ourAlliance.flag)
        else
            -- 己方联盟旗帜
            local self_flag = ui_helper:CreateFlagContentSprite(ourAlliance.flag):scale(0.5)
            self_flag:align(display.CENTER, VS:getPositionX()-80, 10)
                :addTo(fight_bg)
            self.self_flag = self_flag
        end
        if self.enemy_flag then
            self.enemy_flag:SetFlag(enemyAlliance.flag)
        else
            -- 敌方联盟旗帜
            local enemy_flag = ui_helper:CreateFlagContentSprite(enemyAlliance.flag):scale(0.5)
            enemy_flag:align(display.CENTER, VS:getPositionX()+20, 10)
                :addTo(fight_bg)
            self.enemy_flag = enemy_flag
        end

        local info_message = {
            {string.formatnumberthousands(ourAlliance.kill),_("击杀积分"),string.formatnumberthousands(enemyAlliance.kill)},
            {string.formatnumberthousands(ourAlliance.routCount),_("击溃城市"),string.formatnumberthousands(enemyAlliance.routCount)},
            {string.formatnumberthousands(ourAlliance.attackCount),_("进攻次数"),string.formatnumberthousands(enemyAlliance.attackCount)},
        }
        local b_flag = true
        local origin_y = 160 - 33
        local gap_y = 46
        for i,v in ipairs(info_message) do
            createItem(v,b_flag):align(display.CENTER, 270, origin_y - (i-1)*gap_y):addTo(info_bg)
            b_flag = not b_flag
        end
        goto_button:removeEventListenersByEvent("CLICKED_EVENT")
        goto_button:onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                -- display.getRunningScene():GotoAllianceByIndex(enemyAlliance.mapIndex)
                app:EnterMyAllianceScene({mapIndex = enemyAlliance.mapIndex})
                -- parent:LeftButtonClicked()
            end
        end)
    end

    return content
end

function GameUIAllianceBattle:InitOtherAlliance()
    local layer = self.other_alliance_layer

    --搜索
    local searchIcon = display.newSprite("alliacne_search_29x33.png"):addTo(layer)
        :align(display.LEFT_CENTER,window.left+50,window.top-120)
    local function onEdit(event, editbox)
        if event == "return" then
            self:SearchAllianAction(self.editbox_tag_search:getText())
        end
    end

    local editbox_tag_search = cc.ui.UIInput.new({
        UIInputType = 1,
        image = "input_box.png",
        size = cc.size(510,48),
        listener = onEdit,
    })

    editbox_tag_search:setPlaceHolder(_("搜索联盟标签"))
    editbox_tag_search:setMaxLength(600)
    editbox_tag_search:setFont(UIKit:getEditBoxFont(),18)
    editbox_tag_search:setFontColor(cc.c3b(0,0,0))
    editbox_tag_search:setPlaceholderFontColor(UIKit:hex2c3b(0xccc49e))
    editbox_tag_search:setReturnType(cc.KEYBOARD_RETURNTYPE_SEARCH)
    editbox_tag_search:align(display.CENTER,window.cx+20,window.top-120):addTo(layer)
    self.editbox_tag_search = editbox_tag_search

    -- 搜索结果
    local list,list_node = UIKit:commonListView({
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,608,690),
    })
    list_node:addTo(layer):align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20)
    self.alliance_listview = list

end

function GameUIAllianceBattle:CreateAllianceItem(alliance,index)
    local basic = alliance.basicInfo
    local countInfo = alliance.countInfo

    local item = self.alliance_listview:newItem()
    local w,h = 568,154
    item:setItemSize(w, h)
    local content = WidgetUIBackGround.new({width=w,height=h},WidgetUIBackGround.STYLE_TYPE.STYLE_2)


    -- 联盟旗帜
    local flag_bg =  WidgetPushButton.new({normal = "alliance_item_flag_box_126X126.png",
        pressed = "alliance_item_flag_box_126X126.png"})
        :onButtonClicked(function()
            self:OpenOtherAllianceDetails(alliance)
        end)
        :align(display.CENTER,80,h/2)
        :addTo(content)
    local a_helper = self.a_helper
    local flag_sprite = a_helper:CreateFlagWithRhombusTerrain(basic.terrain,basic.flag)
    flag_sprite:scale(1.2)
    flag_sprite:align(display.CENTER,0,-20)
        :addTo(flag_bg)


    local i_icon = display.newSprite("info_26x26.png")
        :align(display.CENTER,-flag_bg:getCascadeBoundingBox().size.width/2+15,-flag_bg:getCascadeBoundingBox().size.height/2+15)
        :addTo(flag_bg)


    local title_bg = display.newScale9Sprite("title_blue_430x30.png",w-10, h-30, cc.size(412,30), cc.rect(10,10,410,10))
        :align(display.RIGHT_CENTER)
        :addTo(content)
    -- 搜索出的条目index
    local index_box  = UIKit:ttfLabel({
        text = index,
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 10, title_bg:getContentSize().height/2):addTo(title_bg,2)

    -- 联盟tag和名字
    local index_box  = UIKit:ttfLabel({
        text = "["..basic.tag.."]"..basic.name,
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, index_box:getPositionX()+index_box:getContentSize().width+20, title_bg:getContentSize().height/2)
        :addTo(title_bg,2)
    -- 联盟power
    display.newSprite("dragon_strength_27x31.png")
        :align(display.CENTER, 168,78)
        :addTo(content)
    local power_label  = UIKit:ttfLabel({
        text = string.formatnumberthousands(basic.power),
        size = 20,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER,188,78)
        :addTo(content)
    -- 联盟击杀
    display.newSprite("battle_33x33.png")
        :align(display.CENTER, 168,38)
        :addTo(content)
    local hit_label  = UIKit:ttfLabel({
        text = string.formatnumberthousands(basic.kill),
        size = 20,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER,188,38)
        :addTo(content)
    if alliance._id ~= self.alliance.id then
        -- 进入按钮
        local enter_btn = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("查看"),
                size = 24,
                color = 0xffedae,
                shadow= true
            }))
            :onButtonClicked(function(event)
                -- app:EnterViewModelAllianceScene(alliance._id)
                UIKit:newGameUI("GameUIAllianceInfo", alliance._id):AddToCurrentScene(true)
            end):align(display.RIGHT_CENTER,w-20,45):addTo(content)
    end
    item:addContent(content)
    self.alliance_listview:addItem(item)
end

function GameUIAllianceBattle:RefreshAllianceListview(alliances)
    self.alliance_listview:removeAllItems()
    for k,v in ipairs(alliances) do
        self:CreateAllianceItem(v,k)
    end
    self.alliance_listview:reload()
end

-- tag ~= nil -->search
function GameUIAllianceBattle:GetJoinList(tag)
    if tag then
        NetManager:getSearchAllianceInfoByTagPromise(tag):done(function(response)
            if response.msg.allianceInfos then
                self:RefreshAllianceListview(response.msg.allianceInfos)
            end
        end)
    end
end
function GameUIAllianceBattle:SearchAllianAction(tag)
    self:GetJoinList(tag)
end

function GameUIAllianceBattle:OpenOtherAllianceDetails(alliance)
    local basic = alliance.basicInfo
    local countInfo = alliance.countInfo

    local body = WidgetPopDialog.new(524,_("联盟信息")):addTo(self):GetBody()
    local rb_size = body:getContentSize()
    local w,h = rb_size.width,rb_size.height
    -- 联盟旗帜
    local flag_bg = display.newSprite("alliance_item_flag_box_126X126.png")
        :align(display.CENTER,78,h-78)
        :addTo(body)
        :scale(0.8)
    local a_helper = self.a_helper
    local flag_sprite = a_helper:CreateFlagWithRhombusTerrain(basic.terrain,basic.flag)
    flag_sprite:align(display.CENTER, flag_bg:getContentSize().width/2, flag_bg:getContentSize().height/2-20)
        :addTo(flag_bg)

    -- 联盟名字和tag
    local title_bg = display.newScale9Sprite("title_blue_430x30.png", w-30, h-45,cc.size(438,30),cc.rect(15,10,400,10))
        :align(display.RIGHT_CENTER)
        :addTo(body)

    -- 联盟tag和名字
    local index_box  = UIKit:ttfLabel({
        text = "["..basic.tag.."]"..basic.name,
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 20, title_bg:getContentSize().height/2)
        :addTo(title_bg,2)
    -- 盟主名字
    display.newSprite("alliance_item_leader_39x39.png"):addTo(body):pos(178,h-100)
    UIKit:ttfLabel({
        text = alliance.archer,
        size = 22,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER, 198,h-100)
        :addTo(body)
    -- 属性背景
    local attr_bg = WidgetUIBackGround.new({height=82,width=556},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :addTo(body)
        :align(display.CENTER, w/2, h-180)


    local function addAttr(title,value,x,y)
        local attr_title = UIKit:ttfLabel({
            text = title,
            size = 20,
            color = 0x615b44,
        }):align(display.LEFT_CENTER, x, y)
            :addTo(attr_bg)
        UIKit:ttfLabel({
            text = value,
            size = 20,
            color = 0x403c2f,
        }):align(display.LEFT_CENTER,x + attr_title:getContentSize().width+20,y)
            :addTo(attr_bg)
    end
    addAttr(_("成员"),alliance.members.."/"..alliance.membersMax,10,60)
    addAttr(_("语言"),basic.language,10,20)
    addAttr(_("战斗力"),basic.power,350,60)
    addAttr(_("击杀"),basic.kill,350,20)

    if alliance._id ~= self.alliance.id then
        -- 进入按钮
        local enter_btn = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("查看"),
                size = 24,
                color = 0xffedae,
                shadow= true
            }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    -- app:EnterViewModelAllianceScene(alliance._id)
                    UIKit:newGameUI("GameUIAllianceInfo", alliance._id):AddToCurrentScene(true)
                end
            end):align(display.RIGHT_CENTER,w-35,h-100):addTo(body)
    end
    WidgetInfo.new({
        info={
            {_("击杀部队人口"),string.formatnumberthousands(countInfo.kill)},
            {_("阵亡部队人口"),string.formatnumberthousands(countInfo.beKilled)},
            {_("击溃城市"),string.formatnumberthousands(countInfo.routCount)},
            {_("联盟战胜利"),string.formatnumberthousands(countInfo.winCount)},
            {_("联盟战失败"),string.formatnumberthousands(countInfo.failedCount)},
            {_("胜率"),(countInfo.winCount+countInfo.failedCount==0 and 0 or math.floor(countInfo.winCount/(countInfo.winCount+countInfo.failedCount)*1000)/10).."%"},
        },
        h =260
    }):align(display.BOTTOM_CENTER, w/2 , 20)
        :addTo(body)
end

function GameUIAllianceBattle:OnAllianceBasicChanged(alliance,deltaData)
    if deltaData("basicInfo.status") then
        self:InitBattleStatistics()
    end
end

function GameUIAllianceBattle:OnAllianceFightChanged(alliance, deltaData)
    self:InitBattleStatistics()
end

function GameUIAllianceBattle:GetAlliancePeriod()
    local period = ""
    local status = self.alliance.basicInfo.status
    if status == "peace" then
        period = _("和平期")
    elseif status == "prepare" then
        period = _("准备期")
    elseif status == "fight" then
        period = _("战争期")
    elseif status == "protect" then
        period = _("保护期")
    end
    return period
end


return GameUIAllianceBattle































