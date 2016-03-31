--
-- Author: Kenny Dai
-- Date: 2015-07-10 15:49:21
--
local StarBar = import("..ui.StarBar")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetSoldierBox = import("..widget.WidgetSoldierBox")
local WidgetClickPageView = import("..widget.WidgetClickPageView")
local UICheckBoxButton = import(".UICheckBoxButton")
local window = import("..utils.window")
local UILib = import("..ui.UILib")
local Localize = import("..utils.Localize")
local Localize_item = import("..utils.Localize_item")
local monster_config = GameDatas.AllianceInitData.monster

local GameUIMonsterReport = UIKit:createUIClass("GameUIMonsterReport", "UIAutoClose")


function GameUIMonsterReport:ctor(report,can_share)
    GameUIMonsterReport.super.ctor(self)
    self.body = WidgetUIBackGround.new({height= can_share and 800 or 750}):align(display.TOP_CENTER,display.cx,display.top-100)
    self:addTouchAbleChild(self.body)
    self:setNodeEventEnabled(true)
    self.report = report
    self.can_share = can_share
end

function GameUIMonsterReport:onEnter()
    GameUIMonsterReport.super.onEnter(self)
    local report = self.report
    local report_body = self.body
    local rb_size = report_body:getContentSize()
    local title = display.newSprite("title_blue_600x56.png"):align(display.CENTER, rb_size.width/2, rb_size.height+10)
        :addTo(report_body)
    local title_label = UIKit:ttfLabel(
        {
            text =self:GetReportTitle(),
            size = 22,
            color = 0xffedae
        }):align(display.CENTER, title:getContentSize().width/2, title:getContentSize().height/2)
        :addTo(title)
    -- close button
    cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"})
        :onButtonClicked(function(event)
            self:removeFromParent()
        end):align(display.CENTER, title:getContentSize().width-26, title:getContentSize().height-26)
        :addTo(title)
    -- 战争结果图片
    local result_img = self.report:GetReportResult() and "report_victory_590x137.png" or "report_failure_590x137.png"
    local war_result_image = display.newSprite(result_img)
        :align(display.CENTER_TOP, rb_size.width/2, rb_size.height-16)
        :addTo(report_body)


    -- 战斗发生时间
    local shadow_layer = UIKit:shadowLayer()
    shadow_layer:setContentSize(590,30)
    shadow_layer:align(display.CENTER, 0, 0)
        :addTo(war_result_image)
    local war_result_label = UIKit:ttfLabel(
        {
            text = GameUtils:formatTimeStyle2(math.floor(report.createTime/1000)),
            size = 18,
            color = 0xffedae
        }):align(display.LEFT_CENTER, 10, 15)
        :addTo(war_result_image)
    local war_result_label = UIKit:ttfLabel(
        {
            text = self:GetFightTarget(),
            size = 18,
            color = 0x615b44
        }):align(display.LEFT_CENTER, 20, rb_size.height-170)
        :addTo(report_body)

    local terrain = report:GetAttackTarget().terrain
    local war_result_label = UIKit:ttfLabel(
        {
            text = string.format(_("战斗地形:%s"),Localize.terrain[terrain]),
            size = 18,
            color = 0x615b44
        }):align(display.LEFT_CENTER, 20, rb_size.height-195)
        :addTo(report_body)

    -- 战争战报详细内容展示
    self.details_view = UIListView.new{
        viewRect = cc.rect(0, self.can_share and 70 or 10, 588, 505),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(report_body):pos(10, 5)

    -- 战利品部分
    self:CreateBootyPart()

    -- 战斗统计部分
    self:CreateWarStatisticsPart()


    self.details_view:reload()

    -- 回放按钮
    local r_data = report:GetData()

    local replay_label = UIKit:ttfLabel({
        text = _("回放"),
        size = 20,
        color = 0xfff3c7})

    replay_label:enableShadow()
    WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(replay_label)
        :addTo(report_body):align(display.CENTER, report_body:getContentSize().width-100, rb_size.height-186)
        :onButtonClicked(function(event)
            local c_report = clone(report)
            c_report.IsPveBattle = true
            UIKit:newGameUI("GameUIReplay",c_report):AddToCurrentScene(true)
        end)
    -- 分享战报按钮
    if self.can_share then
        local share_button = WidgetPushButton.new(
            {normal = "tmp_blue_btn_up_64x56.png", pressed = "tmp_blue_btn_down_64x56.png"},
            {scale9 = false}
        ):addTo(report_body):align(display.CENTER,  report_body:getContentSize().width-210, rb_size.height-186)
            :onButtonClicked(function(event)
                UIKit:newGameUI("GameUIShareReport", report):AddToCurrentScene()
            end)
        display.newSprite("tmp_icon_share_24x34.png"):addTo(share_button)
        -- 删除按钮
        local delete_label = UIKit:ttfLabel({
            text = _("删除"),
            size = 20,
            color = 0xfff3c7})
        delete_label:enableShadow()

        WidgetPushButton.new(
            {normal = "red_btn_up_148x58.png", pressed = "red_btn_down_148x58.png"},
            {scale9 = false}
        ):setButtonLabel(delete_label)
            :addTo(report_body):align(display.CENTER, 110, 40)
            :onButtonClicked(function(event)
                NetManager:getDeleteReportsPromise({report.id}):done(function ()
                    self:removeFromParent()
                end)
            end)
        -- 收藏按钮
        local saved_button = UICheckBoxButton.new({
            off = "mail_saved_button_normal.png",
            off_pressed = "mail_saved_button_normal.png",
            off_disabled = "mail_saved_button_normal.png",
            on = "mail_saved_button_pressed.png",
            on_pressed = "mail_saved_button_pressed.png",
            on_disabled = "mail_saved_button_pressed.png",
        }):onButtonStateChanged(function(event)
            local target = event.target
            if target:isButtonSelected() then
                NetManager:getSaveReportPromise(report.id):fail(function(err)
                    target:setButtonSelected(false,true)
                end)
            else
                NetManager:getUnSaveReportPromise(report.id):fail(function(err)
                    target:setButtonSelected(true,true)
                end)
            end
        end):addTo(report_body):pos(rb_size.width-48, 37)
            :setButtonSelected(report:IsSaved(),true)
    end

end

function GameUIMonsterReport:GetBooty()
    local booty = {}
    for k,v in pairs(self:GetRewards()) do
        table.insert(booty, {
            resource_type = Localize_item.item_name[v.name] or Localize.materials[v.name] or Localize.equip_material[v.name],
            icon= UILib.item[v.name] or UILib.materials[v.name] or UILib.dragon_material_pic_map[v.name],
            value = v.count
        })
    end
    return booty
end

function GameUIMonsterReport:CreateBootyPart()
    local item_width = 540
    -- 战利品列表部分高度
    local booty_count = #self:GetBooty()
    local booty_group = display.newNode()
    -- cc.ui.UIGroup.new()
    local booty_list_bg
    if booty_count>0 then
        local item_height = 46
        local booty_list_height = booty_count * item_height

        -- 战利品列表
        booty_list_bg = WidgetUIBackGround.new({width = item_width,height = booty_list_height+16},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
            :align(display.CENTER,0,-25)

        local booty_list_bg_size = booty_list_bg:getContentSize()
        booty_group:addChild(booty_list_bg)

        -- 构建所有战利品标签项
        local booty_item_bg_color_flag = true
        local added_booty_item_count = 0
        for k,booty_parms in pairs(self:GetBooty()) do
            local booty_item_bg_image = booty_item_bg_color_flag and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
            local booty_item_bg = display.newScale9Sprite(booty_item_bg_image):size(520,46)
                :align(display.TOP_CENTER, booty_list_bg_size.width/2, booty_list_bg_size.height-item_height*added_booty_item_count-6)
                :addTo(booty_list_bg,2)
            local booty_icon = display.newSprite(booty_parms.icon, 30, 23):addTo(booty_item_bg)
            booty_icon:setScale(40/booty_icon:getContentSize().width)
            UIKit:ttfLabel({
                text = booty_parms.resource_type,
                size = 22,
                color = 0x403c2f
            }):align(display.LEFT_CENTER,80,23):addTo(booty_item_bg)
            UIKit:ttfLabel({
                text = string.formatnumberthousands(booty_parms.value),
                size = 22,
                color = booty_parms.value>0 and 0x288400 or 0x7e0000
            }):align(display.RIGHT_CENTER,booty_list_bg_size.width-30,23):addTo(booty_item_bg)

            added_booty_item_count = added_booty_item_count + 1
            booty_item_bg_color_flag = not booty_item_bg_color_flag
        end
    end
    local booty_title_bg = display.newSprite("alliance_evnets_title_548x50.png")
        :align(display.CENTER_BOTTOM, 0,booty_list_bg and booty_list_bg:getContentSize().height/2-25 or -25)

    booty_group:addChild(booty_title_bg)


    UIKit:ttfLabel({
        text = booty_count > 0 and _("战利品") or _("无战利品") ,
        size = 24,
        color = 0xffedae
    }):align(display.CENTER,booty_title_bg:getContentSize().width/2, 25):addTo(booty_title_bg)
    local item = self.details_view:newItem()
    item:setItemSize(item_width, (booty_list_bg and booty_list_bg:getContentSize().height or 0) +booty_title_bg:getContentSize().height)
    item:addContent(booty_group)
    self.details_view:addItem(item)
end

function GameUIMonsterReport:CreateWarStatisticsPart()
    local report = self.report
    self:FightWithDefenceMonsterReports()
end

function GameUIMonsterReport:FightWithDefenceMonsterReports()
    local report = self.report
    local war_s_label_item = self.details_view:newItem()
    war_s_label_item:setItemSize(540,40)
    local g = cc.ui.UIGroup.new()
    g:addWidget(UIKit:ttfLabel({
        text = _("战斗统计") ,
        size = 22,
        color = 0x403c2f
    }):align(display.CENTER, 0, 0))
    war_s_label_item:addContent(g)
    self.details_view:addItem(war_s_label_item)
    -- 交战双方信息
    local left_player = report:GetMyPlayerData()
    local right_player = report:GetEnemyPlayerData()
    self:CreateBelligerents(left_player,right_player)
    -- 部队信息
    local left_player_troop = report:GetMyDefenceFightTroop()

    local right_player_troop = report:GetEnemyDefenceFightTroop()
    -- 龙信息
    local left_player_dragon = report:GetMyDefenceFightDragon()

    local right_player_dragon = report:GetEnemyDefenceFightDragon()
    -- RoundDatas
    local left_round = report:GetMyRoundDatas()

    local right_round = report:GetEnemyRoundDatas()
    if left_player_troop then
        self:CreateArmyGroup(left_player_troop,right_player_troop,left_player_dragon,right_player_dragon,left_round,right_round)
    end
    -- 击杀敌方
    if right_player_troop then
        self:KillEnemy(right_player_troop)
    end
    -- 我方损失
    if left_player_troop then
        self:OurLose(left_player_troop)
    end
end
function GameUIMonsterReport:CreateArmyGroup(l_troop,r_troop,l_dragon,r_dragon,left_round,right_round)
    local group = cc.ui.UIGroup.new()

    local group_width,group_height = 540,268

    local self_army_item = self:CreateArmyItem(_("你的部队"),l_troop,l_dragon,r_troop,left_round,right_round,true)
        :align(display.CENTER, -group_width/2+129, 0)

    group:addWidget(self_army_item)

    local enemy_army_item = self:CreateArmyItem(_("敌方部队"),r_troop,r_dragon,l_troop,right_round,left_round,false)
        :align(display.CENTER, group_width/2-129, 0)
    group:addWidget(enemy_army_item)
    local item = self.details_view:newItem()
    item:setItemSize(group_width,group_height)
    item:addContent(group)
    self.details_view:addItem(item)
end

function GameUIMonsterReport:CreateArmyItem(title,troop,dragon,enemy_troop,round_datas,enemy_round_datas,isSelf)
    local w,h = 258,256
    local army_item = self:CreateSmallBackGround({height=h})

    local t_bg = display.newScale9Sprite(isSelf and "back_ground_blue_254x42.png" or "back_ground_red_254x42.png", 0, 0,cc.size(256,34),cc.rect(10,10,234,22))
        :align(display.CENTER_TOP,w/2, h):addTo(army_item)
    UIKit:ttfLabel({
        text = title ,
        size = 20,
        color = 0xffedae
    }):align(display.CENTER,t_bg:getContentSize().width/2, 17):addTo(t_bg)

    local function createInfoItem(params)
        if LuaUtils:table_empty(params) then
            return
        end
        local item  = tolua.type(params.bg_image) == "string" and display.newScale9Sprite(params.bg_image,0,0,cc.size(254,28),cc.rect(10,10,528,20)) or params.bg_image
        local title = UIKit:ttfLabel({
            text = params.title ,
            size = params.size or 18,
            color = params.color or 0x615b44
        }):addTo(item)
        if params.value then
            UIKit:ttfLabel({
                text = params.value ,
                size = 20,
                color = 0x403c2f
            }):align(display.RIGHT_CENTER,item:getContentSize().width-6, item:getContentSize().height/2):addTo(item)
            title:align(display.LEFT_CENTER,6, item:getContentSize().height/2)

        else
            title:align(display.CENTER,item:getContentSize().width/2, item:getContentSize().height/2)
        end

        return item
    end
    local army_info
    if troop then
        local troopTotal,totalDamaged,killed,totalWounded = 0,0,0,0

        for k,v in pairs(troop) do
            troopTotal=troopTotal+v.count
        end
        for k,v in pairs(enemy_round_datas) do
            -- for _,data in pairs(v) do
            killed = killed+v.soldierDamagedCount
            -- end
        end
        for k,v in pairs(round_datas) do
            -- for _,data in pairs(v) do
            totalDamaged = totalDamaged+v.soldierDamagedCount
            totalWounded = totalWounded+v.soldierWoundedCount
            -- end
        end

        army_info = {
            {
                bg_image = "back_ground_548x40_1.png",
                title = _("部队"),
                value = string.formatnumberthousands(troopTotal),
            },
            {
                bg_image = "back_ground_548x40_2.png",
                title = _("存活"),
                value = string.formatnumberthousands(troopTotal-totalDamaged),
            },
            {
                bg_image = "back_ground_548x40_1.png",
                title = _("伤兵"),
                value = string.formatnumberthousands(totalWounded),
            },
            {
                bg_image = "back_ground_548x40_2.png",
                title = _("被消灭"),
                value = string.formatnumberthousands(totalDamaged - totalWounded),
                color = 0x7e0000,
            },
            {
                bg_image = display.newScale9Sprite(isSelf and "back_ground_blue_254x42.png" or "back_ground_red_254x42.png", 0, 0,cc.size(254,28),cc.rect(10,10,234,22)),
                title = Localize.dragon[dragon.type],
                color = 0xffedae,
                size = 20
            },
            {
                bg_image = "back_ground_548x40_2.png",
                title = _("等级"),
                value = dragon.level,
            },
            dragon.expAdd and {
                bg_image = "back_ground_548x40_1.png",
                title = _("XP"),
                value = "+"..string.formatnumberthousands(dragon.expAdd) ,
            } or {},
            {
                bg_image = "back_ground_548x40_2.png",
                title = _("HP"),
                value = string.formatnumberthousands(dragon.hp).."/-"..string.formatnumberthousands(dragon.hpDecreased),
            },
        }
    else
        army_info = {
            {
                bg_image = "back_ground_548x40_1.png",
                title = _("无部队"),
            }
        }
    end


    local gap_y = 28
    local y_postion = h -34
    for k,v in pairs(army_info) do
        local item = createInfoItem(v)
        if item then
            item:addTo(army_item)
                :align(display.TOP_CENTER, w/2, y_postion)
            y_postion = y_postion - gap_y
        end
    end
    return army_item
end
-- 交战双方信息
function GameUIMonsterReport:CreateBelligerents(left_player,right_player)
    local group = cc.ui.UIGroup.new()
    local group_width,group_height = 540,100
    local self_item = self:CreateBelligerentsItem(left_player)
        :align(display.CENTER, -group_width/2+129, 0)

    group:addWidget(self_item)

    local enemy_item = self:CreateMonsterItem(right_player)
        :align(display.CENTER, group_width/2-129, 0)
    group:addWidget(enemy_item)
    local item = self.details_view:newItem()
    item:setItemSize(group_width,group_height)
    item:addContent(group)
    self.details_view:addItem(item)
end

function GameUIMonsterReport:CreateBelligerentsItem(player)
    local height = 100
    local player_item = self:CreateSmallBackGround({height=height})
    -- 联盟名字背景框
    display.newScale9Sprite("back_ground_blue_254x42.png", 1, 0,cc.size(256,50),cc.rect(10,10,234,22)):align(display.LEFT_BOTTOM):addTo(player_item)
    -- 玩家头像
    UIKit:GetPlayerCommonIcon(player.icon):addTo(player_item,1):align(display.CENTER, 50, height/2):setScale(0.7)

    -- 玩家名称
    UIKit:ttfLabel({
        text = player.name or Localize.village_name[player.type] ,
        size = 20,
        color = 0x403c2f,
    }):align(display.CENTER,170, height-25)
        :addTo(player_item)

    UIKit:ttfLabel({
        text =  player.type and string.format(_("等级%d"),player.level) or "["..player.alliance.tag.."]",
        size = 22,
        color = 0xffedae
    }):align(display.CENTER,170,  height-75)
        :addTo(player_item)

    return player_item
end
function GameUIMonsterReport:CreateMonsterItem(monster)
    local height = 100
    local player_item = self:CreateSmallBackGround({height=height})
    -- 联盟名字背景框
    display.newScale9Sprite("back_ground_red_254x42.png", 1, 0,cc.size(256,50),cc.rect(10,10,234,22)):align(display.LEFT_BOTTOM):addTo(player_item)
    -- 玩家头像
    local heroBg = display.newSprite("dragon_bg_114x114.png"):addTo(player_item,1):align(display.CENTER, 45, height/2):setScale(0.7)
    local icon = display.newSprite("tmp_black_dragon_113x128.png"):addTo(heroBg)
        :align(display.CENTER,56,65)

    local monster_data = self.report:GetEnemyPlayerData().soldiers[1]
    local monster_type = monster_data.name
    local battleAt = Localize.soldier_name[monster_type]
    -- 野怪名称
    UIKit:ttfLabel({
        text = battleAt .." " .. string.format(_("等级%d"),monster.level),
        size = 20,
        color = 0x403c2f,
        dimensions = cc.size(140,0)
    }):align(display.CENTER,170, height-25)
        :addTo(player_item)

    UIKit:ttfLabel({
        text = _("黑龙军团"),
        size = 22,
        color = 0xffedae
    }):align(display.CENTER,170,  height-75)
        :addTo(player_item)

    return player_item
end

-- 击杀敌方
function GameUIMonsterReport:KillEnemy(troop)
    local war_s_label_item = self.details_view:newItem()
    war_s_label_item:setItemSize(540,40)
    local g = cc.ui.UIGroup.new()
    g:addWidget(UIKit:ttfLabel({
        text = _("击杀敌方") ,
        size = 22,
        color = 0x403c2f
    }):align(display.CENTER, 0, 0))
    war_s_label_item:addContent(g)
    self.details_view:addItem(war_s_label_item)

    self:CreateSoldierInfo(troop,false)
end
-- 我方损失
function GameUIMonsterReport:OurLose(troop)
    local war_s_label_item = self.details_view:newItem()
    war_s_label_item:setItemSize(540,40)
    local g = cc.ui.UIGroup.new()
    g:addWidget(UIKit:ttfLabel({
        text = _("我方损失") ,
        size = 22,
        color = 0x403c2f
    }):align(display.CENTER, 0, 0))
    war_s_label_item:addContent(g)
    self.details_view:addItem(war_s_label_item)

    self:CreateSoldierInfo(troop,true)

end

function GameUIMonsterReport:CreateSoldierInfo(soldiers,isSelf)
    local item = self.details_view:newItem()
    item:setItemSize(554,172)
    -- 背景框
    local bg = self:CreateSmallBackGround({width=554,height=172})

    local content = WidgetClickPageView.new({bg=bg})
    for i=1,#soldiers,4 do

        local page_item = content:newItem()
        local gap_x = 120
        local origin_x = -4
        local count = 0
        for j=i,i+3 do
            if soldiers[j] and soldiers[j].countDecreased > 0 then
                self:CreateSoldiersInfo(soldiers[j],isSelf):align(display.CENTER, origin_x+count*gap_x,25):addTo(page_item)
                count = count + 1
            end
        end

        content:addItem(page_item)
    end
    content:pos(50,101)
    content:reload()
    item:addContent(content)
    self.details_view:addItem(item)

end

function GameUIMonsterReport:CreateSoldiersInfo(soldier,isSelf)
    local soldier_level = soldier.star
    local soldier_type = soldier.name
    local soldier_ui_config = isSelf and UILib.soldier_image[soldier_type] or UILib.black_soldier_image[soldier_type]
    local color_bg = display.newSprite(UILib.soldier_color_bg_images[soldier_type])
        :scale(104/128)
        :align(display.LEFT_BOTTOM)
    local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER,color_bg:getContentSize().width/2,color_bg:getContentSize().height/2)
    soldier_head_icon:addTo(color_bg)

    local soldier_head_bg  = display.newSprite("box_soldier_128x128.png")
        :align(display.CENTER, soldier_head_icon:getContentSize().width/2, soldier_head_icon:getContentSize().height-64)
        :addTo(soldier_head_icon)
    local soldier_star_bg = display.newSprite("tmp_back_ground_102x22.png"):addTo(soldier_head_bg):align(display.BOTTOM_LEFT,6, 4)
    local soldier_star = StarBar.new({
        max = 3,
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
        num = soldier_level,
        margin = 5,
        direction = StarBar.DIRECTION_HORIZONTAL,
        scale = 0.8,
    }):addTo(soldier_star_bg):align(display.CENTER,58, 11)


    UIKit:ttfLabel({
        text = string.formatnumberthousands(soldier.count),
        size = 18,
        color = 0x403c2f
    }):align(display.CENTER,soldier_head_bg:getContentSize().width/2, -14):addTo(soldier_head_bg)
        :scale(soldier_head_icon:getContentSize().height/104)
    UIKit:ttfLabel({
        text = "-"..string.formatnumberthousands(soldier.countDecreased) ,
        size = 18,
        color = 0x980101
    }):align(display.CENTER,soldier_head_bg:getContentSize().width/2, -38):addTo(soldier_head_bg)
        :scale(soldier_head_icon:getContentSize().height/104)

    return color_bg
end

-- 创建 宽度为258的 UI框
function GameUIMonsterReport:CreateSmallBackGround(params)
    local r_bg = display.newScale9Sprite("back_ground_258x90.png",0,0,cc.size(params.width or 258,params.height),cc.rect(10,10,238,70))
    return r_bg
end

function GameUIMonsterReport:GetReportTitle()
    return self.report:GetReportTitle()

end
function GameUIMonsterReport:GetFightTarget()
    local monster_data = self.report:GetEnemyPlayerData().soldiers[1]

    local battleAt = _("黑龙军团")
    local location = self.report:GetBattleLocation()
    return string.format(_("Battle at %s (%d,%d)"),battleAt,location.x,location.y)
end
function GameUIMonsterReport:GetRewards()
    return  self.report:GetMyRewards()
end
return GameUIMonsterReport

















































