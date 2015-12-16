--
-- Author: Kenny Dai
-- Date: 2015-07-21 15:26:33
--
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
-- 圣地战报每回合战斗回放对象
local ShrinePlayFightReport = class("ShrinePlayFightReport")
local GameUIShrineReportInMail = UIKit:createUIClass("GameUIShrineReportInMail", "UIAutoClose")


function GameUIShrineReportInMail:ctor(report,can_share)
    GameUIShrineReportInMail.super.ctor(self)
    self.body = WidgetUIBackGround.new({height=800}):align(display.TOP_CENTER,display.cx,display.top-100)
    self:addTouchAbleChild(self.body)
    self:setNodeEventEnabled(true)
    self.report = report
    self.can_share = can_share
end

function GameUIShrineReportInMail:onEnter()
    GameUIShrineReportInMail.super.onEnter(self)
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
    local result_img = self.report:GetAttackTarget().isWin and "report_victory_590x137.png" or "report_failure_590x137.png"
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
        viewRect = cc.rect(0, 70, 588, 505),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(report_body):pos(10, 5)

    -- 战利品部分
    self:CreateBootyPart()

    -- 战斗统计部分
    self:CreateWarStatisticsPart()


    self.details_view:reload()



    -- 分享战报按钮
    if self.can_share then
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
        -- 分享战报按钮
        local share_button = WidgetPushButton.new(
            {normal = "tmp_blue_btn_up_64x56.png", pressed = "tmp_blue_btn_down_64x56.png"},
            {scale9 = false}
        ):addTo(report_body):align(display.CENTER, report_body:getContentSize().width-80, rb_size.height-186)
            :onButtonClicked(function(event)
                UIKit:newGameUI("GameUIShareReport", report):AddToCurrentScene()
            end)
        display.newSprite("tmp_icon_share_24x34.png"):addTo(share_button)
    end
end

function GameUIShrineReportInMail:GetBooty()
    local booty = {}
    for k,v in pairs(self:GetRewards()) do
        table.insert(booty, {
            resource_type = Localize_item.item_name[v.name] or Localize.materials[v.name] or Localize.equip_material[v.name] or v.name == "loyalty" and _("忠诚值"),
            icon= UILib.item[v.name] or UILib.materials[v.name] or UILib.dragon_material_pic_map[v.name] or v.name == "loyalty" and "loyalty_128x128.png",
            value = v.count
        })
    end
    return booty
end

function GameUIShrineReportInMail:CreateBootyPart()
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

function GameUIShrineReportInMail:CreateWarStatisticsPart()
    local report = self.report
    local roundDatas = report:GetShrineRoundDatas()

    if LuaUtils:table_empty(roundDatas) then
        local war_s_label_item = self.details_view:newItem()
        war_s_label_item:setItemSize(540,40)
        local g = cc.ui.UIGroup.new()
        g:addWidget(UIKit:ttfLabel({
            text = _("由于你派兵过晚，未能成功参与本次圣地事件。") ,
            size = 22,
            color = 0x403c2f
        }):align(display.CENTER, 0, 0))
        war_s_label_item:addContent(g)
        self.details_view:addItem(war_s_label_item)
    else
        for i,data in ipairs(roundDatas) do
            self:FightReportsData(i,data)
        end
    end
end

function GameUIShrineReportInMail:FightReportsData(round,data)
    local report = self.report
    self:CreateReplay(round,data)
    -- 交战双方信息
    local left_player = data.attackPlayerData
    local right_player = data.defenceTroopData
    self:CreateBelligerents(left_player,right_player)
    -- 部队信息
    local left_player_troop = data.attackPlayerData.soldiers

    local right_player_troop = data.defenceTroopData.soldiers
    -- 龙信息
    local left_player_dragon = data.attackPlayerData.dragon

    local right_player_dragon = data.defenceTroopData.dragon
    -- RoundDatas
    local left_round = data.fightWithDefenceTroopReports.attackPlayerSoldierRoundDatas

    local right_round =data.fightWithDefenceTroopReports.defenceTroopSoldierRoundDatas
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
function GameUIShrineReportInMail:IsRoundWin(data)
    local my_round = data.fightWithDefenceTroopReports.attackPlayerSoldierRoundDatas
    local defence_round = data.fightWithDefenceTroopReports.defenceTroopSoldierRoundDatas
    -- 判定是否双方所有士兵都参加了战斗
    local my_soldiers = data.attackPlayerData.soldiers
    local defence_soldiers = data.defenceTroopData.soldiers
    for i,s in ipairs(my_soldiers) do
        local isFight = false
        for i,r in ipairs(my_round) do
            if s.name == r.soldierName then
                isFight = true
            end
        end
        if not isFight then
            return true
        end
    end
    for i,s in ipairs(defence_soldiers) do
        local isFight = false
        for i,r in ipairs(defence_round) do
            if s.name == r.soldierName then
                isFight = true
            end
        end
        if not isFight then
            return false
        end
    end
    return my_round[#my_round].isWin
end
function GameUIShrineReportInMail:CreateReplay(round,data)
    local player_item = self:CreateSmallBackGround({width = 540,height=60})
    local round_label = UIKit:ttfLabel({
        text = string.format(_("第%d回合"),round) ,
        size = 22,
        color = 0x403c2f
    }):align(display.LEFT_CENTER,10, 30):addTo(player_item)


    local isWin = self:IsRoundWin(data)

    UIKit:ttfLabel({
        text = isWin and _("胜利") or _("失败"),
        size = 22,
        color = isWin and 0x298600 or 0x7e3305
    }):align(display.LEFT_CENTER,round_label:getPositionX() + round_label:getContentSize().width + 10, 30):addTo(player_item)
    -- 回放按钮
    local replay_label = UIKit:ttfLabel({
        text = _("回放"),
        size = 20,
        color = 0xfff3c7})

    replay_label:enableShadow()
    WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png", pressed = "yellow_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(replay_label)
        :addTo(player_item):align(display.RIGHT_CENTER, player_item:getContentSize().width-2, 30)
        :onButtonClicked(function(event)
            UIKit:newGameUI("GameUIReplayNew",self:GetFightReportObjectWithJson(data)):AddToCurrentScene(true)
        end)

    local item = self.details_view:newItem()
    item:setItemSize(540,80)
    item:addContent(player_item)
    self.details_view:addItem(item)
end

function GameUIShrineReportInMail:CreateArmyGroup(l_troop,r_troop,l_dragon,r_dragon,left_round,right_round)
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

function GameUIShrineReportInMail:CreateArmyItem(title,troop,dragon,enemy_troop,round_datas,enemy_round_datas,isSelf)
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
            killed = killed+v.soldierDamagedCount
        end
        for k,v in pairs(round_datas) do
            totalDamaged = totalDamaged+v.soldierDamagedCount
            totalWounded = totalWounded+v.soldierWoundedCount
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
function GameUIShrineReportInMail:CreateBelligerents(left_player,right_player)
    local group = cc.ui.UIGroup.new()
    local group_width,group_height = 540,100
    local self_item = self:CreateBelligerentsItem(left_player)
        :align(display.CENTER, -group_width/2+129, 0)

    group:addWidget(self_item)

    local enemy_item = self:CreateShrineItem(right_player)
        :align(display.CENTER, group_width/2-129, 0)
    group:addWidget(enemy_item)
    local item = self.details_view:newItem()
    item:setItemSize(group_width,group_height)
    item:addContent(group)
    self.details_view:addItem(item)
end

function GameUIShrineReportInMail:CreateBelligerentsItem(player)
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
    local attackTarget = self.report:GetAttackTarget()

    UIKit:ttfLabel({
        text =  player.type and string.format(_("等级%d"),player.level) or "["..attackTarget.alliance.tag.."]",
        size = 22,
        color = 0xffedae
    }):align(display.CENTER,170,  height-75)
        :addTo(player_item)

    return player_item
end
function GameUIShrineReportInMail:CreateShrineItem(shrine)
    local height = 100
    local player_item = self:CreateSmallBackGround({height=height})
    -- 联盟名字背景框
    display.newScale9Sprite("back_ground_red_254x42.png", 1, 0,cc.size(256,50),cc.rect(10,10,234,22)):align(display.LEFT_BOTTOM):addTo(player_item)
    -- 玩家头像
    local heroBg = display.newSprite("dragon_bg_114x114.png"):addTo(player_item,1):align(display.CENTER, 50, height/2):setScale(0.7)
    local attackTarget = self.report:GetAttackTarget()
    local terrain = attackTarget.terrain
    local dragon_head_icon
    if terrain == "grassLand" then
        dragon_head_icon = "greenDragon.png"
    elseif terrain == "iceField" then
        dragon_head_icon = "Dragon_blue_113x128.png"
    else
        dragon_head_icon = "redDragon.png"
    end
    local icon = display.newSprite(dragon_head_icon):addTo(heroBg)
        :align(display.CENTER,56,62)


    -- 圣地关卡
    UIKit:ttfLabel({
        text = string.gsub(attackTarget.stageName,"_","-")..Localize.shrine_desc[attackTarget.stageName][1],
        size = 20,
        color = 0x403c2f,
    }):align(display.CENTER,170, height-25)
        :addTo(player_item)

    UIKit:ttfLabel({
        text = string.format(_("第%d支部队"),shrine.stageTroopNumber),
        size = 22,
        color = 0xffedae
    }):align(display.CENTER,170,  height-75)
        :addTo(player_item)

    return player_item
end

-- 击杀敌方
function GameUIShrineReportInMail:KillEnemy(troop)
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
function GameUIShrineReportInMail:OurLose(troop)
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

function GameUIShrineReportInMail:CreateSoldierInfo(soldiers,isSelf)
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
            if soldiers[j] then
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

function GameUIShrineReportInMail:CreateSoldiersInfo(soldier,isSelf)
    local soldier_level = soldier.star
    local soldier_type = soldier.name
    local soldier_ui_config = isSelf and UILib.soldier_image[soldier_type][soldier_level] or UILib.black_soldier_image[soldier_type][soldier_level]
    local color_bg = display.newSprite(isSelf and UILib.soldier_color_bg_images[soldier_type] or UILib.black_soldier_color_bg_images[soldier_type])
        :scale(104/128)
        :align(display.LEFT_BOTTOM)
    local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER,color_bg:getContentSize().width/2,color_bg:getContentSize().height/2)
    soldier_head_icon:addTo(color_bg)

    local soldier_head_bg  = display.newSprite("box_soldier_128x128.png")
        :align(display.CENTER, soldier_head_icon:getContentSize().width/2, soldier_head_icon:getContentSize().height-64)
        :addTo(soldier_head_icon)


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
function GameUIShrineReportInMail:CreateSmallBackGround(params)
    local r_bg = display.newScale9Sprite("back_ground_258x90.png",0,0,cc.size(params.width or 258,params.height),cc.rect(10,10,238,70))
    return r_bg
end

function GameUIShrineReportInMail:GetReportTitle()
    return self.report:GetReportTitle()

end
function GameUIShrineReportInMail:GetFightTarget()
    local location = self.report:GetBattleLocation()
    return string.format(_("Battle at %s (%d,%d)"),_("圣地"),location.x,location.y)
end
function GameUIShrineReportInMail:GetRewards()
    return  self.report:GetMyRewards()
end


function GameUIShrineReportInMail:GetFightReportObjectWithJson(json_data)
    local shrinePlayFightReport = ShrinePlayFightReport.new(
        json_data.attackPlayerData.name,
        Localize.shrine_desc[self.report:GetAttackTarget().stageName][1],
        json_data.attackPlayerData,
        json_data.defenceTroopData,
        json_data.fightWithDefenceTroopReports.attackPlayerDragonFightData,
        json_data.fightWithDefenceTroopReports.defenceTroopDragonFightData,
        json_data.fightWithDefenceTroopReports.attackPlayerSoldierRoundDatas,
        json_data.fightWithDefenceTroopReports.defenceTroopSoldierRoundDatas,
        self:IsRoundWin(json_data)
    )
    return shrinePlayFightReport
end

-- 战斗回放相关获取数据方法
function ShrinePlayFightReport:ctor(attackName,defenceName,attackPlayerData,defenceTroopData,attackDragonRoundData,defenceDragonRoundData,fightAttackSoldierRoundData,fightDefenceSoldierRoundData,isWin)
    self.attackName = attackName
    self.defenceName = defenceName
    self.attackPlayerData = attackPlayerData
    self.defenceTroopData = defenceTroopData
    self.attackDragonRoundData = attackDragonRoundData
    self.defenceDragonRoundData = defenceDragonRoundData
    self.fightAttackSoldierRoundData = fightAttackSoldierRoundData
    self.fightDefenceSoldierRoundData = fightDefenceSoldierRoundData
    self.isWin = isWin
    for __,v in ipairs(fightAttackSoldierRoundData) do
        v.name = v.soldierName
        v.star = v.soldierStar
        v.count = v.soldierCount
    end
    for __,v in ipairs(fightDefenceSoldierRoundData) do
        v.name = v.soldierName
        v.star = v.soldierStar
        v.count = v.soldierCount
    end
    self:formatOrderedAttackSoldiers()
end

function ShrinePlayFightReport:formatOrderedAttackSoldiers()
    local result = {}
    self.orderedAttackSoldiers = {}
    for index,v in ipairs(self.fightAttackSoldierRoundData) do
        if not result[v.soldierName] then
            result[v.soldierName] = {name = v.soldierName,star = v.soldierStar,count = v.soldierCount or 0,index = index}
        end
    end
    for index,v in ipairs(self.attackPlayerData.soldiers) do
        if not result[v.name] then
            result[v.name] = {name = v.name,star = v.star,count = v.count or 0,index = index}
        end
    end
    for ___,v in pairs(result) do
        table.insert(self.orderedAttackSoldiers,v)
    end
    table.sort( self.orderedAttackSoldiers, function(a,b)
        return a.index < b.index
    end)

    result = {}
    self.orderedDefenceSoldierRoundData = {}
    for index,v in ipairs(self.fightDefenceSoldierRoundData) do
        if not result[v.soldierName] then
            result[v.soldierName] = {name = v.soldierName,star = v.soldierStar,count = v.soldierCount or 0,index = index}
        end
    end
    for index,v in ipairs(self.defenceTroopData.soldiers) do
        if not result[v.name] then
            result[v.name] = {name = v.name,star = v.star,count = v.count or 0,index = index}
        end
    end
    for ___,v in pairs(result) do
        table.insert(self.orderedDefenceSoldierRoundData,v)
    end
    table.sort( self.orderedDefenceSoldierRoundData, function(a,b)
        return a.index < b.index
    end)
end

function ShrinePlayFightReport:GetFightAttackName()
    return self.attackName
end
function ShrinePlayFightReport:GetFightDefenceName()
    return self.defenceName
end
function ShrinePlayFightReport:IsDragonFight()
    return true
end
function ShrinePlayFightReport:GetFightAttackDragonRoundData()
    return self.attackDragonRoundData or {}
end
function ShrinePlayFightReport:GetFightDefenceDragonRoundData()
    return self.defenceDragonRoundData or {}
end
function ShrinePlayFightReport:GetFightAttackSoldierRoundData()
    return self.fightAttackSoldierRoundData or {}
end
function ShrinePlayFightReport:GetFightDefenceSoldierRoundData()
    return self.fightDefenceSoldierRoundData or {}
end
function ShrinePlayFightReport:IsFightWall()
    return false
end
function ShrinePlayFightReport:GetFightAttackWallRoundData()
    return {}
end
function ShrinePlayFightReport:GetFightDefenceWallRoundData()
    return {}
end
function ShrinePlayFightReport:GetOrderedAttackSoldiers()
    return self.orderedAttackSoldiers or {}
end
function ShrinePlayFightReport:GetOrderedDefenceSoldiers()
    return self.orderedDefenceSoldierRoundData or {}
end
function ShrinePlayFightReport:GetReportResult()
    return self.isWin
end
function ShrinePlayFightReport:GetAttackDragonLevel()
    return self.attackPlayerData.dragon.level
end

function ShrinePlayFightReport:GetAttackTargetTerrain()
    return Alliance_Manager:GetMyAlliance().basicInfo.terrain
end

function ShrinePlayFightReport:IsAttackCamp()
    return true
end
function ShrinePlayFightReport:GetDefenceDragonLevel()
    return self.defenceTroopData.dragon.level
end

return GameUIShrineReportInMail

















































