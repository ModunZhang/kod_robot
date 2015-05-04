local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetPages = import("..widget.WidgetPages")
local WidgetUIBackGround2 = import("..widget.WidgetUIBackGround2")
local WidgetInfo = import("..widget.WidgetInfo")
local Alliance = import("..entity.Alliance")
local AllianceMoonGate = import("..entity.AllianceMoonGate")
local UIListView = import(".UIListView")
local Flag = import("..entity.Flag")
local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local revenge_limit = GameDatas.AllianceInitData.intInit.allianceRevengeMaxMinutes.value

local GameUIAllianceBattle = UIKit:createUIClass('GameUIAllianceBattle', "GameUIWithCommonHeader")

function GameUIAllianceBattle:ctor(city)
    GameUIAllianceBattle.super.ctor(self, city, _("联盟会战"))
    self.alliance = Alliance_Manager:GetMyAlliance()
    self.enemy_alliance = Alliance_Manager:GetEnemyAlliance()

    self.alliance_fight_reports_table = {}
    self.history_items = {}
end

function GameUIAllianceBattle:OnMoveInStage()
    GameUIAllianceBattle.super.OnMoveInStage(self)
    self:CreateTabButtons({
        {
            label = _("战争统计"),
            tag = "statistics",
            default = true
        },
        {
            label = _("历史记录"),
            tag = "history",
        },
        {
            label = _("其他联盟"),
            tag = "other_alliance",
        },
    }, function(tag)
        if tag == 'statistics' then
            self.statistics_layer:setVisible(true)
        else
            self.statistics_layer:setVisible(false)
        end
        if tag == 'history' then
            self.history_layer:setVisible(true)
            if not self.history_listview then
                self:InitHistoryRecord()
            end
        else
            self.history_layer:setVisible(false)
        end
        if tag == 'other_alliance' then
            self.other_alliance_layer:setVisible(true)
            if not self.alliance_listview then
                self:InitOtherAlliance()
                NetManager:getNearedAllianceInfosPromise():done(function(response)
                    if response.msg.allianceInfos then
                        table.sort(response.msg.allianceInfos,function ( a,b )
                            return a.basicInfo.power > b.basicInfo.power
                        end)
                        self:RefreshAllianceListview(response.msg.allianceInfos)
                    end
                end)

            end
        else
            self.other_alliance_layer:setVisible(false)
        end
    end):pos(window.cx, window.bottom + 34)

    self:InitBattleStatistics()


    app.timer:AddListener(self)
    self.alliance:AddListenOnType(self, Alliance.LISTEN_TYPE.FIGHT_REQUESTS)
    self.alliance:AddListenOnType(self, Alliance.LISTEN_TYPE.BASIC)
    self.alliance:AddListenOnType(self, Alliance.LISTEN_TYPE.FIGHT_REPORTS)
    self.alliance:AddListenOnType(self, Alliance.LISTEN_TYPE.ALLIANCE_FIGHT)
end

function GameUIAllianceBattle:onExit()
    app.timer:RemoveListener(self)
    self.alliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.FIGHT_REQUESTS)
    self.alliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.BASIC)
    self.alliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.FIGHT_REPORTS)
    self.alliance:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.ALLIANCE_FIGHT)
    GameUIAllianceBattle.super.onExit(self)
end

function GameUIAllianceBattle:OnTimer(current_time)
    if self.statistics_layer:isVisible() then
        local status = self.alliance:Status()
        if status ~= "peace" then
            local statusFinishTime = self.alliance:StatusFinishTime()
            if math.floor(statusFinishTime/1000)>current_time then
                self.time_label:setString(GameUtils:formatTimeStyle1(math.floor(statusFinishTime/1000)-current_time))
            end
        else
            local statusStartTime = self.alliance:StatusStartTime()
            if current_time>= math.floor(statusStartTime/1000) then
                self.time_label:setString(GameUtils:formatTimeStyle1(current_time-math.floor(statusStartTime/1000)))
            end
        end
    end
    if self.history_layer:isVisible() then
        for k,listitem in pairs(self.history_listview:getItems()) do
            listitem:getContent():RefreshRevengeTime(current_time)
        end
    end
end

function GameUIAllianceBattle:CreateBetweenBgAndTitle()
    GameUIAllianceBattle.super.CreateBetweenBgAndTitle(self)

    -- statistics_layer
    self.statistics_layer = display.newLayer():addTo(self:GetView())
    -- history_layer
    self.history_layer = display.newLayer():addTo(self:GetView())
    -- other_alliance_layer
    self.other_alliance_layer = display.newLayer():addTo(self:GetView())

end

function GameUIAllianceBattle:InitBattleStatistics()
    local layer = self.statistics_layer
    layer:removeAllChildren()
    self.info_listview = nil
    self.request_num_label = nil
    local period_label = UIKit:ttfLabel({
        text = self:GetAlliancePeriod(),
        size = 22,
        color = 0x403c2f,
    }):addTo(layer):align(display.LEFT_CENTER,window.cx-50,window.top-110)

    self.time_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color = 0x7e0000,
    }):addTo(layer)
        :align(display.LEFT_CENTER,period_label:getPositionX()+period_label:getContentSize().width+20,window.top-110)

    WidgetPushButton.new({normal = "info_26x26.png",
        pressed = "info_26x26.png"})
        :onButtonClicked(function()
            self:OpenWarDetails()
        end)
        :align(display.CENTER,period_label:getPositionX()-30, window.top-110)
        :addTo(layer)
    if self.alliance:Status() == "peace" then
        -- 请求开战玩家数量
        local request_fight_bg =display.newSprite("back_ground_556x58.png")
            :align(display.TOP_CENTER, window.cx, window.top - 140)
            :addTo(layer)
        WidgetPushButton.new({normal = "info_26x26.png",
            pressed = "info_26x26.png"})
            :onButtonClicked(function()
                self:OpenRequestFightList()
            end)
            :align(display.CENTER,30,request_fight_bg:getContentSize().height/2)
            :addTo(request_fight_bg)
        UIKit:ttfLabel({
            text = _("请求开战玩家"),
            size = 22,
            color = 0x403c2f,
        }):addTo(request_fight_bg)
            :align(display.LEFT_CENTER,60,request_fight_bg:getContentSize().height/2)

        cc.ui.UIImage.new("res_citizen_44x50.png")
            :align(display.CENTER,request_fight_bg:getContentSize().width-120, request_fight_bg:getContentSize().height/2)
            :addTo(request_fight_bg)
            :scale(0.7)

        self.request_num_label = UIKit:ttfLabel(
            {
                text = self.alliance:GetFightRequestPlayerNum(),
                size = 22,
                color = 0x28251d
            }):align(display.CENTER, request_fight_bg:getContentSize().width-60, request_fight_bg:getContentSize().height/2)
            :addTo(request_fight_bg)

        -- 介绍
        -- 只有权限大于将军的玩家可以请求开启联盟会战匹配
        local isEqualOrGreater = self.alliance:GetMemeberById(DataManager:getUserData()._id)
            :IsTitleEqualOrGreaterThan("general")

        if not isEqualOrGreater then
            UIKit:ttfLabel({
                text = _("向盟主和将军请求联盟会战"),
                size = 22,
                color = 0x403c2f,
            }):addTo(layer)
                :align(display.LEFT_CENTER,window.left+50,window.top-280)
            WidgetPushButton.new({normal = "yellow_btn_up_185x65.png",pressed = "yellow_btn_down_185x65.png",disable="yellow_disable_185x65.png"})
                :setButtonLabel(UIKit:ttfLabel({
                    text = _("请求开战!"),
                    size = 24,
                    color = 0xffedae,
                    shadow= true
                }))
                :onButtonClicked(function(event)
                    if event.name == "CLICKED_EVENT" then
                        if self.alliance:IsRequested() then
                            UIKit:showMessageDialog(_("提示"),_("已经发送过开战请求"))
                            return
                        end
                        NetManager:getRequestAllianceToFightPromose()
                    end
                end):align(display.RIGHT_CENTER,window.right-50,window.top-280):addTo(layer)
        end



        local intro_1_text = isEqualOrGreater and _("参加联盟会战,赢得荣誉,金龙币和丰厚战利品,联盟处在和平期可以主动匹配或被其他联盟匹配进行联盟会战")
            or _("联盟处在和平期可以主动匹配或被其他联盟匹配进行联盟会战")
        local intro_1 = UIKit:ttfLabel({
            text = intro_1_text,
            size = 22,
            color = 0x797154,
            dimensions = cc.size(530,0),
        }):addTo(layer)
            :align(display.CENTER,window.cx,isEqualOrGreater and window.top-320 or window.top-370)

        -- 介绍
        local intro_2 = UIKit:ttfLabel({
            text = _("联盟会战会根据联盟战斗力匹配,你可以通过以下方式提升联盟战斗力"),
            size = 22,
            color = 0x797154,
            dimensions = cc.size(530,0),
        }):addTo(layer)
            :align(display.CENTER,window.cx,intro_1:getPositionY()-intro_1:getContentSize().height-40)

        local tip_1 = UIKit:ttfLabel({
            text = _("1，招募更多的玩家加入联盟"),
            size = 22,
            color = 0x403c2f,
            dimensions = cc.size(530,0),
        }):addTo(layer)
            :align(display.LEFT_CENTER,window.left+60,isEqualOrGreater and window.top-510 or window.top-560)

        local tip_2 = UIKit:ttfLabel({
            text = _("2，在城市中招募更多的部队"),
            size = 22,
            color = 0x403c2f,
            dimensions = cc.size(530,0),
        }):addTo(layer)
            :align(display.LEFT_CENTER,window.left+60,tip_1:getPositionY()-50)

        local tip_3 = UIKit:ttfLabel({
            text = _("3，努力提升城市建筑等级"),
            size = 22,
            color = 0x403c2f,
            dimensions = cc.size(530,0),
        }):addTo(layer)
            :align(display.LEFT_CENTER,window.left+60,tip_2:getPositionY()-50)

        local tip_4 = UIKit:ttfLabel({
            text = _("4，提升龙的等级,技能和装备"),
            size = 22,
            color = 0x403c2f,
            dimensions = cc.size(530,0),
        }):addTo(layer)
            :align(display.LEFT_CENTER,window.left+60,tip_3:getPositionY()-50)



        if isEqualOrGreater then
            UIKit:ttfLabel({
                text = _("准备好了,那就开战吧"),
                size = 22,
                color = 0x403c2f,
            }):addTo(layer)
                :align(display.LEFT_CENTER,window.left+50,window.top-740)
            WidgetPushButton.new({normal = "yellow_btn_up_185x65.png",pressed = "yellow_btn_down_185x65.png",disable="yellow_disable_185x65.png"})
                :setButtonLabel(UIKit:ttfLabel({
                    text = _("开始战斗!"),
                    size = 24,
                    color = 0xffedae,
                    shadow= true
                }))
                :onButtonClicked(function(event)
                    if event.name == "CLICKED_EVENT" then
                        if self.alliance:Status()=="fight" or self.alliance:Status()=="prepare" then
                            UIKit:showMessageDialog(_("提示"),_("联盟正在战争准备期或战争期"))
                            return
                        end
                        NetManager:getFindAllianceToFightPromose()
                    end
                end):align(display.RIGHT_CENTER,window.right-50,window.top-740):addTo(layer)
        end
    else
        local our_alliance = self.alliance
        -- local enemy_alliance = self.alliance:GetAllianceMoonGate():GetEnemyAlliance()
        local enemy_alliance = Alliance_Manager:GetEnemyAlliance()
        local top_bg = display.newSprite("back_ground_580x118.png")
            :align(display.TOP_CENTER, window.cx, window.top-120)
            :addTo(layer)
        -- :scale(0.85)
        local t_size = top_bg:getContentSize()

        local self_alliance_bg = WidgetPushButton.new({normal = "button_blue_normal_314X88.png",
            pressed = "button_blue_pressed_314X88.png"})
            :onButtonClicked(function()
                self:OpenAllianceDetails(true)
            end)
            :align(display.RIGHT_CENTER,t_size.width/2, t_size.height/2)
            :addTo(top_bg)
            :scale(0.8)
        local enemy_alliance_bg = WidgetPushButton.new({normal = "button_red_normal_314X88.png",
            pressed = "button_red_pressed_314X88.png"})
            :onButtonClicked(function()
                self:OpenAllianceDetails(false)
            end)
            :align(display.LEFT_CENTER,t_size.width/2, t_size.height/2)
            :addTo(top_bg)
            :scale(0.8)
        -- 己方联盟名字
        local our_alliance_tag = UIKit:ttfLabel({
            text = "["..our_alliance:Tag().."]",
            size = 26,
            color = 0xffedae,
        }):addTo(self_alliance_bg)
            :align(display.CENTER,-180,14)
        local our_alliance_name = UIKit:ttfLabel({
            text = our_alliance:Name(),
            size = 26,
            color = 0xffedae,
        }):addTo(self_alliance_bg)
            :align(display.CENTER,-180,-14)
        -- 敌方联盟名字
        local a_tag = ""
        local a_name = ""
        if enemy_alliance then
            if enemy_alliance:Tag()
                and enemy_alliance:Name() then
                a_tag = "["..enemy_alliance:Tag().."]"
                a_name = enemy_alliance:Name()
            end
        end
        local enemy_alliance_tag = UIKit:ttfLabel({
            text =a_tag,
            size = 26,
            color = 0xffedae,
        }):addTo(enemy_alliance_bg)
            :align(display.CENTER,180,14)
        local enemy_alliance_name = UIKit:ttfLabel({
            text =a_name,
            size = 26,
            color = 0xffedae,
        }):addTo(enemy_alliance_bg)
            :align(display.CENTER,180,-14)
        local period_bg = display.newSprite("box_104x104.png")
            :align(display.CENTER, t_size.width/2, t_size.height/2-4)
            :addTo(top_bg)
            :scale(0.75)
        display.newSprite("VS_73x44.png")
            :align(display.CENTER, period_bg:getContentSize().width/2, period_bg:getContentSize().height/2)
            :addTo(period_bg)


        -- 保护期显示战斗结果
        local info_bg_y
        if our_alliance:Status() == "protect" then
            -- 禁用联盟按钮
            self_alliance_bg:setButtonEnabled(false)
            enemy_alliance_bg:setButtonEnabled(false)
            local last_fight_reports = our_alliance:GetLastAllianceFightReports()
            local fight_result
            if our_alliance:Id() == last_fight_reports.attackAllianceId then
                fight_result = last_fight_reports.fightResult == "attackWin"
            else
                fight_result = last_fight_reports.fightResult == "defenceWin"
            end
            local our_reprot_data = our_alliance:GetOurLastAllianceFightReportsData()
            local enemy_reprot_data = our_alliance:GetEnemyLastAllianceFightReportsData()

            our_alliance_name:setString(our_reprot_data.name)
            enemy_alliance_name:setString(enemy_reprot_data.name)
            our_alliance_tag:setString("["..our_reprot_data.tag.."]")
            enemy_alliance_tag:setString("["..enemy_reprot_data.tag.."]")

            local text_1 = fight_result and "WIN" or "LOSE"
            local color_1 = fight_result and 0x007c23 or 0x7e0000
            local result_own_bg = display.newSprite("back_ground_130x30.png")
                :align(display.LEFT_CENTER,window.left+60,window.top-240)
                :addTo(layer)
            local result_own = UIKit:ttfLabel({
                text = text_1,
                size = 20,
                color = color_1,
            }):align(display.CENTER,result_own_bg:getContentSize().width/2,result_own_bg:getContentSize().height/2)
                :addTo(result_own_bg)
            local text_1 = not fight_result and "WIN" or "LOSE"
            local color_1 = not fight_result and 0x007c23 or 0x7e0000
            local result_enemy_bg = display.newSprite("back_ground_130x30.png")
                :align(display.RIGHT_CENTER,window.right-60,window.top-240)
                :addTo(layer)
            local result_enemy = UIKit:ttfLabel({
                text = text_1,
                size = 20,
                color = color_1,
            }):align(display.RIGHT_CENTER,result_enemy_bg:getContentSize().width/2,result_enemy_bg:getContentSize().height/2)
                :addTo(result_enemy_bg)


            local isEqualOrGreater = self.alliance:GetMemeberById(DataManager:getUserData()._id)
                :IsTitleEqualOrGreaterThan("general")
            if isEqualOrGreater then
                UIKit:ttfLabel({
                    text = _("不需要保护,立即开战!"),
                    size = 22,
                    color = 0x403c2f,
                }):addTo(layer)
                    :align(display.LEFT_CENTER,window.left+50,window.top-830)
                WidgetPushButton.new({normal = "yellow_btn_up_185x65.png",pressed = "yellow_btn_down_185x65.png",disable="yellow_disable_185x65.png"})
                    :setButtonLabel(UIKit:ttfLabel({
                        text = _("开始战斗!"),
                        size = 24,
                        color = 0xffedae,
                        shadow= true
                    }))
                    :onButtonClicked(function(event)
                        if event.name == "CLICKED_EVENT" then
                            NetManager:getFindAllianceToFightPromose()
                        end
                    end):align(display.RIGHT_CENTER,window.right-50,window.top-830):addTo(layer)
            end

            info_bg_y = window.top-260

        else
            UIKit:ttfLabel({
                text = _("本次联盟会战结束后奖励,总击杀越高奖励越高.获胜方获得70%的总奖励,失败方获得剩下的,获胜联盟击杀前5名的玩家还将平分奖励的金龙币"),
                size = 20,
                color = 0x797154,
                -- align = cc.ui.TEXT_ALIGN_CENTER,
                dimensions = cc.size(500,0),
            }):addTo(layer)
                :align(display.TOP_CENTER,window.cx,window.top-240)
            -- 荣耀值奖励
            local honour_bg = display.newScale9Sprite("back_ground_138x34.png",window.left+70,window.top-350,cc.size(188,34))
                :align(display.LEFT_CENTER)
                :addTo(layer)
            display.newSprite("honour_128x128.png"):align(display.CENTER,0,honour_bg:getContentSize().height/2)
                :addTo(honour_bg,2)
                :scale(50/128)
            UIKit:ttfLabel({
                text = "未定义",
                size = 20,
                color = 0x514d3e,
            }):addTo(honour_bg,2)
                :align(display.CENTER,honour_bg:getContentSize().width/2,honour_bg:getContentSize().height/2)
            -- 金龙币奖励
            local gem_bg = display.newScale9Sprite("back_ground_138x34.png",window.right-60,window.top-350,cc.size(188,34))
                :align(display.RIGHT_CENTER)
                :addTo(layer)
            display.newSprite("gem_icon_62x61.png"):align(display.CENTER,0,gem_bg:getContentSize().height/2)
                :addTo(gem_bg,2)
                :scale(0.7)
            UIKit:ttfLabel({
                text = "未定义",
                size = 20,
                color = 0x514d3e,
            }):addTo(gem_bg,2)
                :align(display.CENTER,gem_bg:getContentSize().width/2,gem_bg:getContentSize().height/2)
            info_bg_y = window.top-380
        end

        local info_bg = WidgetUIBackGround.new({width = 540,height = 434},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
            :align(display.TOP_CENTER,window.cx, info_bg_y):addTo(layer)

        self.info_listview = UIListView.new{
            viewRect = cc.rect(9, 10, 522, 414),
            direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
        }:addTo(info_bg)
        self:RefreshFightInfoList()
    end
end

function GameUIAllianceBattle:RefreshFightInfoList()
    if self.info_listview then
        self.info_listview:removeAllItems()
        local our, enemy
        if self.alliance:Status() == "protect" then
            local report = self.alliance:GetLastAllianceFightReports()
            our = self.alliance:Id() == report.attackAllianceId and report.attackAlliance or report.defenceAlliance
            enemy = self.alliance:Id() == report.attackAllianceId and report.defenceAlliance or report.attackAlliance
        else
            our = self.alliance:GetMyAllianceFightCountData()
            enemy = self.alliance:GetEnemyAllianceFightCountData()
        end
        if our then
            local info_message = {
                {string.formatnumberthousands(our.kill),_("击杀数"),string.formatnumberthousands(enemy.kill)},
                {our.routCount,_("击溃城市"),enemy.routCount},
                {our.attackCount,_("进攻次数"),enemy.attackCount},
                {our.strikeCount,_("突袭次数"),enemy.strikeCount},
                {our.attackSuccessCount,_("获胜进攻"),enemy.attackSuccessCount},
                {our.strikeSuccessCount,_("突袭成功"),enemy.strikeSuccessCount},
            }
            self:CreateInfoItem(self.info_listview,info_message)
        end
    end
end

function GameUIAllianceBattle:CreateInfoItem(listview,info_message)
    local meetFlag = true

    local item_width, item_height = 522,46
    for k,v in pairs(info_message) do
        local item = listview:newItem()
        item:setItemSize(item_width, item_height)
        local content
        if meetFlag then
            content = display.newSprite("upgrade_resources_background_3.png"):scale(item_width/520)
        else
            content = display.newSprite("upgrade_resources_background_2.png"):scale(item_width/520)
        end
        UIKit:ttfLabel({
            text = v[1],
            size = 20,
            color = 0x403c2f,
        }):align(display.LEFT_CENTER, 10, item_height/2):addTo(content)
        UIKit:ttfLabel({
            text = v[2],
            size = 20,
            color = 0x5d563f,
        }):align(display.CENTER, item_width/2, item_height/2):addTo(content)
        UIKit:ttfLabel({
            text = v[3],
            size = 20,
            color = 0x403c2f,
        }):align(display.RIGHT_CENTER, 510, item_height/2):addTo(content)

        meetFlag =  not meetFlag
        item:addContent(content)
        listview:addItem(item)
    end
    listview:reload()
end

function GameUIAllianceBattle:OpenAllianceDetails(isOur)
    local alliance = self.alliance

    local enemy_alliance = Alliance_Manager:GetEnemyAlliance()
    local count_data = isOur and alliance:GetMyAllianceFightCountData() or alliance:GetEnemyAllianceFightCountData()
    local our_player_kills = alliance:GetMyAllianceFightPlayerKills()
    local enemy_player_kills = alliance:GetEnemyAllianceFightPlayerKills()
    local alliance_name = isOur and alliance:Name() or enemy_alliance:Name()
    local alliance_tag = isOur and alliance:Tag() or enemy_alliance:Tag()
    -- 玩家联盟成员
    local palace_level = alliance:GetAllianceMap():FindAllianceBuildingInfoByName("palace").level
    local memberCount = GameDatas.AllianceBuilding.palace[palace_level].memberCount
    local enemy_memberCount = GameDatas.AllianceBuilding.palace[enemy_alliance:GetAllianceMap():FindAllianceBuildingInfoByName("palace").level].memberCount
    local alliance_members = isOur and alliance:GetMembersCount().."/"..memberCount or enemy_alliance:GetMembersCount().."/"..enemy_memberCount
    -- 联盟语言
    local  language = isOur and alliance:DefaultLanguage() or enemy_alliance:DefaultLanguage()
    -- 联盟战斗力
    local  alliance_power = isOur and alliance:Power() or enemy_alliance:Power()
    -- 联盟击杀
    local  alliance_kill = isOur and count_data.kill or count_data.kill
    -- 玩家击杀列表
    local  player_kill = isOur and our_player_kills or enemy_player_kills
    -- 联盟旗帜
    local alliance_flag = isOur and alliance:Flag() or enemy_alliance:Flag()
    -- 联盟地形
    local alliance_terrain = isOur and alliance:Terrain() or enemy_alliance:Terrain()


    local body = UIKit:newWidgetUI("WidgetPopDialog",726,_("联盟详情")):AddToCurrentScene():GetBody()
    local rb_size = body:getContentSize()


    -- 联盟旗帜
    local flag_bg = display.newSprite("alliance_item_flag_box_126X126.png")
        :align(display.CENTER,90,rb_size.height-90)
        :addTo(body)
    local a_helper = WidgetAllianceHelper.new()
    local flag_sprite = a_helper:CreateFlagWithRhombusTerrain(alliance_terrain,alliance_flag)
    flag_sprite:scale(0.85)
    flag_sprite:align(display.CENTER, flag_bg:getContentSize().width/2, flag_bg:getContentSize().height/2-20)
        :addTo(flag_bg)
    -- 联盟名称
    local title_bg = display.newSprite("title_blue_430x30.png")
        :align(display.CENTER,rb_size.width/2+80,rb_size.height-40)
        :addTo(body)
    UIKit:ttfLabel({
        text = "["..alliance_tag.."]  "..alliance_name,
        size = 20,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 10, title_bg:getContentSize().height/2)
        :addTo(title_bg)

    local function addAttr(title,value,x,y)
        local attr_title = UIKit:ttfLabel({
            text = title,
            size = 20,
            color = 0x797154,
        }):align(display.LEFT_CENTER, x, y)
            :addTo(body)
        UIKit:ttfLabel({
            text = value,
            size = 20,
            color = 0x403c2f,
        }):align(display.LEFT_CENTER,x + attr_title:getContentSize().width+20,y)
            :addTo(body)
    end
    addAttr(_("成员"),alliance_members,180,rb_size.height-100)
    addAttr(_("语言"),language,180,rb_size.height-140)
    addAttr(_("战斗力"),string.formatnumberthousands(alliance_power),350,rb_size.height-100)
    addAttr(_("击杀"),string.formatnumberthousands(alliance_kill),350,rb_size.height-140)

    -- display.newSprite("dividing_line_594x2.png")
    --     :align(display.CENTER, rb_size.width/2, rb_size.height-160)
    --     :addTo(body)
    -- self.member_listview = UIListView.new{
    --     -- bgColor = UIKit:hex2c4b(0x7a990000),
    --     viewRect = cc.rect(7, 14, 594, 550),
    --     direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    -- }:addTo(body)

    self.member_listview = WidgetInfo.new({h=492}):addTo(body)
        :align(display.BOTTOM_CENTER,rb_size.width/2,40)
        :GetListView()

    local function addMemberItem(member,flag,i)
        local item = self.member_listview:newItem()
        item:setItemSize(548,40)
        local content = flag and display.newSprite("back_ground_548x40_1.png")
            or display.newSprite("back_ground_548x40_2.png")

        content:setContentSize(548,40)


        UIKit:ttfLabel({
            text = i.."."..member.name,
            size = 22,
            color = 0x403c2f,
        }):align(display.LEFT_CENTER,20,20)
            :addTo(content)

        UIKit:ttfLabel({
            text = "LV"..member.level,
            size = 22,
            color = 0x403c2f,
        }):align(display.CENTER,content:getContentSize().width/2,20)
            :addTo(content)

        local t = UIKit:ttfLabel({
            text = string.formatnumberthousands(member.kill),
            size = 22,
            color = 0x403c2f,
        }):align(display.RIGHT_CENTER,520,20)
            :addTo(content)
        display.newSprite("battle_33x33.png")
            :align(display.RIGHT_CENTER,510-t:getContentSize().width,20)
            :addTo(content)
        item:addContent(content)
        self.member_listview:addItem(item)
    end
    table.sort( player_kill, function (a,b)
        return a.kill>b.kill
    end )
    local bg_color = true
    for i,v in ipairs(player_kill) do
        addMemberItem(v,bg_color,i)
        bg_color = not bg_color
    end
    self.member_listview:reload()
end


function GameUIAllianceBattle:OpenWarDetails()
    local body = UIKit:newWidgetUI("WidgetPopDialog",608,_("联盟对战")):AddToCurrentScene():GetBody()
    local rb_size = body:getContentSize()

    local war_introduce_table = {
        _("概述，准备期。战争期，保护期的描述。1"),
        _("概述，准备期。战争期，保护期的描述。2"),
        _("概述，准备期。战争期，保护期的描述。3"),
        _("概述，准备期。战争期，保护期的描述。4"),
    }

    local info_bg = WidgetUIBackGround.new({
        width = 574,
        height = 422,
        top_img = "back_ground_top_2.png",
        bottom_img = "back_ground_bottom_2.png",
        mid_img = "back_ground_mid_2.png",
        u_height = 10,
        b_height = 10,
        m_height = 1,
    }):align(display.TOP_CENTER,rb_size.width/2,rb_size.height-90):addTo(body)
    local war_introduce_label = UIKit:ttfLabel({
        text = "概述，准备期。战争期，保护期的描述。",
        size = 20,
        color = 0x403c2f,
        dimensions = cc.size(550,0)
    })
        :align(display.LEFT_TOP,12,416)
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
    local fight_requests = alliance:FightRequests()
    local info = {}

    for _,id in pairs(fight_requests) do
        -- 玩家
        local menber = alliance:GetMemeberById(id)
        table.insert(info, {menber:Name(),string.formatnumberthousands(menber:Power()) ,"power_24x29.png",true})
    end
    return info
end
function GameUIAllianceBattle:InitHistoryRecord()
    local layer = self.history_layer
    local list,list_node = UIKit:commonListView({
        async = true, --异步加载
        viewRect = cc.rect(0, 0,568, 786),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    },false)
    list:setRedundancyViewVal(294)
    list:setDelegate(handler(self, self.HistoryDelegate))
    list:reload()
    list_node:addTo(layer):align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20)
    self.history_listview = list
end
function GameUIAllianceBattle:HistoryDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.alliance:GetAllianceFightReports()
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
    else
    end
end
function GameUIAllianceBattle:CreateHistoryContent()
    local w,h = 568,294
    local content = WidgetUIBackGround.new({height=h,width=w},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    -- 战斗发生时间
    local fight_time_label = UIKit:ttfLabel({
        size = 20,
        color = 0x797154,
    }):align(display.LEFT_CENTER,30, 60)
        :addTo(content)

    local fight_bg = display.newSprite("report_back_ground.png")
        :align(display.TOP_CENTER, w/2,h-10)
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
    local info_bg = WidgetUIBackGround.new({width = 540,height = 110},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
        :align(display.BOTTOM_CENTER,w/2,80):addTo(content)
    local function createItem(info,meetFlag)
        local content
        if meetFlag then
            content = display.newSprite("upgrade_resources_background_3.png")
        else
            content = display.newSprite("upgrade_resources_background_2.png")
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

    local revenge_time_label = UIKit:ttfLabel({
        size = 24,
    }):align(display.LEFT_CENTER, 30, 30)
        :addTo(content)
    local title_label = UIKit:ttfLabel({
        size = 24,
        color = 0x797154,
    }):align(display.LEFT_CENTER, 30, 30)
        :addTo(content)

    local parent = self
    function content:SetData( idx )
        local alliance = parent.alliance
        local report = alliance:GetAllianceFightReports()[idx]
        self.report = report
        -- 各项数据
        local win
        if report.attackAllianceId == alliance:Id() then
            win = report.fightResult == "attackWin"
        elseif report.defenceAllianceId == alliance:Id() then
            win = report.fightResult == "defenceWin"
        end
        local fightTime = report.fightTime
        local ourAlliance = report.attackAllianceId == alliance:Id() and report.attackAlliance or report.defenceAlliance
        local enemyAlliance = report.attackAllianceId == alliance:Id() and report.defenceAlliance or report.attackAlliance

        fight_time_label:setString(GameUtils:formatTimeStyle2(math.floor(fightTime/1000)))
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
            self.self_flag:removeFromParent(true)
            self.self_flag = nil
        end
        if self.enemy_flag then
            self.enemy_flag:removeFromParent(true)
            self.enemy_flag = nil
        end
        -- 己方联盟旗帜
        local ui_helper = WidgetAllianceHelper.new()
        local self_flag = ui_helper:CreateFlagContentSprite(Flag.new():DecodeFromJson(ourAlliance.flag)):scale(0.5)
        self_flag:align(display.CENTER, VS:getPositionX()-80, 10)
            :addTo(fight_bg)
        -- 敌方联盟旗帜
        local enemy_flag = ui_helper:CreateFlagContentSprite(Flag.new():DecodeFromJson(enemyAlliance.flag)):scale(0.5)
        enemy_flag:align(display.CENTER, VS:getPositionX()+20, 10)
            :addTo(fight_bg)
        self.self_flag = self_flag
        self.enemy_flag = enemy_flag


        local info_message = {
            {string.formatnumberthousands(ourAlliance.kill),_("总击杀"),string.formatnumberthousands(enemyAlliance.kill)},
            {string.formatnumberthousands(ourAlliance.routCount),_("击溃城市"),string.formatnumberthousands(enemyAlliance.routCount)},
        }
        createItem(info_message[1],true):align(display.CENTER, 270, 33):addTo(info_bg)
        createItem(info_message[2],false):align(display.CENTER, 270, 79):addTo(info_bg)

        -- 只有权限大于将军的玩家可以请求复仇
        local isEqualOrGreater = alliance:GetMemeberById(DataManager:getUserData()._id)
            :IsTitleEqualOrGreaterThan("general")
        if not win and isEqualOrGreater then
            if self.revenge_button then
                self.revenge_button:removeFromParent(true)
            end
            -- 复仇按钮
            local revenge_button = WidgetPushButton.new(
                {normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"},
                {scale9 = false},
                {disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}}
            ):addTo(content):align(display.RIGHT_CENTER,560,40)
                :setButtonLabel(UIKit:ttfLabel({
                    text = _("复仇"),
                    size = 24,
                    color = 0xffedae,
                    shadow= true
                }))
            revenge_button:onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    if alliance:Status()~="peace" then
                        UIKit:showMessageDialog(_("提示"),_("已经处于联盟战期间"))
                        return
                    end
                    NetManager:getRevengeAlliancePromise(report.id):done(function ()
                        revenge_button:setButtonEnabled(false)
                    end)
                end
            end)
            self.revenge_button = revenge_button

            local revenge_time_limit = revenge_limit * 60 + math.floor(fightTime/1000)
            if app.timer:GetServerTime()>revenge_time_limit then
                revenge_button:setButtonEnabled(false)
                title_label:setString("")
                revenge_time_label:setString(_("已过期"))
                revenge_time_label:setColor(UIKit:hex2c4b(0x7e0000))
                self.is_expire = true
            else
                title_label:setString(_("剩余复仇时间:"))
                revenge_time_label:setString(GameUtils:formatTimeStyle1(revenge_time_limit-app.timer:GetServerTime()))
                revenge_time_label:setColor(UIKit:hex2c4b(0x248a00))
                revenge_time_label:setPositionX(title_label:getPositionX()+title_label:getContentSize().width+10)
                revenge_button:setButtonEnabled(true)
            end
        else
            title_label:setString("")
            revenge_time_label:setString("")
        end
    end

    function content:RefreshRevengeTime(current_time)
        if self.is_expire or not self.revenge_button then
            return
        end
        local fightTime = self.report.fightTime
        local revenge_time_limit = revenge_limit * 60 + math.floor(fightTime/1000)
        if current_time>revenge_time_limit then
            title_label:setString("")
            revenge_time_label:setString(_("已过期"))
            revenge_time_label:setPositionX(30)
            revenge_time_label:setColor(UIKit:hex2c3b(0x7e0000))
            self.revenge_button:setButtonEnabled(false)
            self.is_expire = true
        else
            revenge_time_label:setString(GameUtils:formatTimeStyle1(revenge_time_limit-current_time))
        end
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
        image = "alliance_editbox_575x48.png",
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
    local a_helper = WidgetAllianceHelper.new()
    local flag_sprite = a_helper:CreateFlagWithRhombusTerrain(basic.terrain
        ,Flag.new():DecodeFromJson(basic.flag))
    flag_sprite:scale(0.85)
    flag_sprite:align(display.CENTER,0,-20)
        :addTo(flag_bg)


    local i_icon = display.newSprite("info_26x26.png")
        :align(display.CENTER,-flag_bg:getCascadeBoundingBox().size.width/2+15,-flag_bg:getCascadeBoundingBox().size.height/2+15)
        :addTo(flag_bg)


    local title_bg = display.newSprite("title_blue_412x30.png", w-10, h-30)
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
        :align(display.CENTER, 180,70)
        :addTo(content)
    local power_label  = UIKit:ttfLabel({
        text = string.formatnumberthousands(basic.power),
        size = 20,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER,200,70)
        :addTo(content)
    -- 联盟击杀
    display.newSprite("battle_33x33.png")
        :align(display.CENTER, 180,30)
        :addTo(content)
    local hit_label  = UIKit:ttfLabel({
        text = string.formatnumberthousands(basic.kill),
        size = 20,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER,200,30)
        :addTo(content)
    if alliance._id ~= self.alliance:Id() then
        -- 进入按钮
        local enter_btn = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("进入"),
                size = 24,
                color = 0xffedae,
                shadow= true
            }))
            :onButtonClicked(function(event)
                app:EnterViewModelAllianceScene(alliance._id)
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
    local a_helper = WidgetAllianceHelper.new()
    local flag_sprite = a_helper:CreateFlagWithRhombusTerrain(basic.terrain
        ,Flag.new():DecodeFromJson(basic.flag))
    flag_sprite:scale(0.8)
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
            color = 0x797154,
        }):align(display.LEFT_CENTER, x, y)
            :addTo(attr_bg)
        UIKit:ttfLabel({
            text = value,
            size = 20,
            color = 0x403c2f,
        }):align(display.LEFT_CENTER,x + attr_title:getContentSize().width+20,y)
            :addTo(attr_bg)
    end
    addAttr(_("成员"),"30/50",10,60)
    addAttr(_("语言"),basic.language,10,20)
    addAttr(_("战斗力"),basic.power,350,60)
    addAttr(_("击杀"),basic.kill,350,20)

    if alliance._id ~= self.alliance:Id() then
        -- 进入按钮
        local enter_btn = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("进入"),
                size = 24,
                color = 0xffedae,
                shadow= true
            }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    app:EnterViewModelAllianceScene(alliance._id)
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

function GameUIAllianceBattle:OnAllianceBasicChanged(alliance,changed_map)
    if changed_map.status then
        self:InitBattleStatistics()
    end
end

function GameUIAllianceBattle:OnAllianceFightChanged(alliance,alliance_fight)
    self:RefreshFightInfoList()
end

function GameUIAllianceBattle:GetAlliancePeriod()
    local period = ""
    local status = self.alliance:Status()
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

function GameUIAllianceBattle:OnAllianceFightRequestsChanged(request_num)
    if self.request_num_label then
        self.request_num_label:setString(request_num)
    end
end
function GameUIAllianceBattle:OnAllianceFightReportsChanged(changed_map)
    if changed_map.add and #changed_map.add>0 then
        self.history_listview:asyncLoadWithCurrentPosition_()
    end
    if changed_map.remove and #changed_map.remove>0 then
        self.history_listview:asyncLoadWithCurrentPosition_()
    end
end

return GameUIAllianceBattle






















