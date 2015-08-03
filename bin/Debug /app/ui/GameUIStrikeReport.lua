local StarBar = import(".StarBar")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UICheckBoxButton = import(".UICheckBoxButton")
local Localize = import("..utils.Localize")
local UILib = import(".UILib")

local GameUIStrikeReport = UIKit:createUIClass("GameUIStrikeReport", "UIAutoClose")

function GameUIStrikeReport:ctor(report)
    GameUIStrikeReport.super.ctor(self)
    self:setNodeEventEnabled(true)
    self.report = report
end

function GameUIStrikeReport:GetReportLevel()
    local report = self.report
    local level = report:GetStrikeLevel()
    local report_level = level == 1 and _("没有得到任何情报") or _("得到一封%s级的情报")
    local level_map ={
        "",
        "C",
        "B",
        "A",
        "S",
    }
    return  level == 0 and (string.format(_("由于诡计之雾的效果,%s没有获得任何情报"),report:Type() == "cityBeStriked" and  _("敌方") or "")) or (report:Type() == "cityBeStriked" and _("敌方") or "")..string.format(report_level,level_map[level])
end
function GameUIStrikeReport:GetBattleCityName()
    local battleAt = self.report:GetBattleAt()
    local location = self.report:GetBattleLocation()
    return string.format(_("Battle at %s (%d,%d)"),battleAt,location.x,location.y)
end
function GameUIStrikeReport:GetBooty()
    local booty = {}
    if self.report:GetMyRewards() then

        for k,v in pairs(self.report:GetMyRewards()) do
            table.insert(booty, {
                resource_type = Localize.fight_reward[v.name],
                icon= UILib.resource[v.name],
                value = v.count
            })
        end
    end
    return booty
end
function GameUIStrikeReport:onEnter()
    local report = self.report
    local report_content = report:GetData()

    local report_body = WidgetUIBackGround.new({height=800}):align(display.TOP_CENTER,display.cx,display.top-100)
    self:addTouchAbleChild(report_body)
    self.body = report_body

    local rb_size = report_body:getContentSize()
    local title = display.newSprite("title_blue_600x56.png"):align(display.CENTER, rb_size.width/2, rb_size.height+10)
        :addTo(report_body)


    local title_label = cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = report:GetReportTitle(),
            font = UIKit:getFontFilePath(),
            size = 22,
            color = UIKit:hex2c3b(0xffedae)
        }):align(display.CENTER, title:getContentSize().width/2, title:getContentSize().height/2)
        :addTo(title)
    -- close button
    cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"})
        :onButtonClicked(function(event)
            self:removeFromParent()
        end):align(display.CENTER, title:getContentSize().width-20, title:getContentSize().height-20)
        :addTo(title)
    -- 突袭结果图片
    local report_result_img
    if report:Type() == "strikeCity" or report:Type() == "strikeVillage" then
        report_result_img = report:GetStrikeLevel() >1 and "report_victory_590x137.png" or "report_failure_590x137.png"
    elseif report:Type() == "cityBeStriked" or report:Type() == "villageBeStriked" then
        report_result_img = report:GetStrikeLevel() >1 and "report_failure_590x137.png" or "report_victory_590x137.png"
    end
    local strike_result_image = display.newSprite(report_result_img)
        :align(display.CENTER_TOP, rb_size.width/2, rb_size.height-10)
        :addTo(report_body)
    local shadow_layer = UIKit:shadowLayer()
    shadow_layer:setContentSize(590,30)
    shadow_layer:align(display.CENTER, 0, 0)
        :addTo(strike_result_image)

    cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = self:GetReportLevel(),
            font = UIKit:getFontFilePath(),
            size = 18,
            color = UIKit:hex2c3b(0xffedae)
        }):align(display.CENTER, strike_result_image:getContentSize().width/2, 15)
        :addTo(strike_result_image)
    cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = self:GetBattleCityName(),
            font = UIKit:getFontFilePath(),
            size = 18,
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.LEFT_CENTER, 20, rb_size.height-170)
        :addTo(report_body)
    cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = GameUtils:formatTimeStyle2(math.floor(report:CreateTime()/1000)),
            font = UIKit:getFontFilePath(),
            size = 18,
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.RIGHT_CENTER, rb_size.width-20, rb_size.height-170)
        :addTo(report_body)
    -- 突袭战报详细内容展示
    self.details_view = UIListView.new{
        viewRect = cc.rect(0, 70, 588, 505),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(report_body):pos(10, 5)
    local terrain = report:GetStrikeTarget().terrain
    local war_result_label = UIKit:ttfLabel(
        {
            text = string.format(_("战斗地形:%s(派出%s获得额外力量)"),Localize.terrain[terrain],terrain=="grassLand" and _("绿龙") or terrain=="desert" and _("红龙") or terrain=="iceField" and _("蓝龙")),
            size = 18,
            color = 0x615b44
        }):align(display.LEFT_CENTER, 20, rb_size.height-195)
        :addTo(report_body)
    -- 战利品部分
    -- self:CreateBootyPart()
    -- 战斗统计部分
    self:CreateWarStatisticsPart()
    if (report:Type() == "strikeCity" or report:Type() == "strikeVillage") and report:GetStrikeLevel()>1 then
        -- 敌方情报部分
        self:CreateReportOfEnemy()
    end

    self.details_view:reload()

    -- 删除按钮
    local delete_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("删除"),
        size = 20,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfff3c7)})
    delete_label:enableShadow()

    WidgetPushButton.new(
        {normal = "red_btn_up_148x58.png", pressed = "red_btn_down_148x58.png"},
        {scale9 = false}
    ):setButtonLabel(delete_label)
        :addTo(report_body):align(display.CENTER, 106, 40)
        :onButtonClicked(function(event)
            NetManager:getDeleteReportsPromise({report:Id()}):done(function ()
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
            NetManager:getSaveReportPromise(report:Id()):fail(function(err)
                target:setButtonSelected(false,true)
            end)
        else
            NetManager:getUnSaveReportPromise(report:Id()):fail(function(err)
                target:setButtonSelected(true,true)
            end)
        end
    end):addTo(report_body):pos(rb_size.width-47, 37)
        :setButtonSelected(report:IsSaved(),true)
end



function GameUIStrikeReport:CreateBootyPart()
    if not self:GetBooty() then
        return
    end
    local booty_count = #self:GetBooty()
    local booty_group = display.newNode()
    local booty_list_bg
    if booty_count>0 then
        local item_height = 46
        -- 战利品列表部分高度
        local booty_list_height = booty_count * item_height
        -- 战利品列表
        booty_list_bg = WidgetUIBackGround.new({width = 540,height = booty_list_height+16},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
            :align(display.CENTER,0,-25)
            :addTo(booty_group)

        local booty_list_bg_size = booty_list_bg:getContentSize()

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
            cc.ui.UILabel.new({
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = booty_parms.resource_type,
                font = UIKit:getFontFilePath(),
                size = 22,
                color = UIKit:hex2c3b(0x403c2f)
            }):align(display.LEFT_CENTER,80,23):addTo(booty_item_bg)
            local color = (self.report:Type() == "strikeCity" or self.report:Type() == "strikeVillage") and 0x288400 or 0x770000
            cc.ui.UILabel.new({
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = ((self.report:Type() == "strikeCity" or self.report:Type() == "strikeVillage") and "" or "-")..string.formatnumberthousands(booty_parms.value),
                font = UIKit:getFontFilePath(),
                size = 22,
                color = UIKit:hex2c3b(color)
            }):align(display.RIGHT_CENTER,booty_list_bg_size.width-30,23):addTo(booty_item_bg)

            added_booty_item_count = added_booty_item_count + 1
            booty_item_bg_color_flag = not booty_item_bg_color_flag
        end
    end


    local booty_title_bg = display.newSprite("alliance_evnets_title_548x50.png")
        :align(display.CENTER_BOTTOM, 0,booty_list_bg and booty_list_bg:getContentSize().height/2-25 or -25)
        :addTo(booty_group)

    cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = booty_count>0 and _("战利品") or _("无战利品"),
        font = UIKit:getFontFilePath(),
        size = 24,
        color = UIKit:hex2c3b(0xffedae)
    }):align(display.CENTER,booty_title_bg:getContentSize().width/2, 25):addTo(booty_title_bg)
    local item = self.details_view:newItem()
    item:setItemSize(548,(booty_list_bg and booty_list_bg:getContentSize().height or 0 )+booty_title_bg:getContentSize().height)
    item:addContent(booty_group)
    self.details_view:addItem(item)
end

function GameUIStrikeReport:CreateWarStatisticsPart()
    local group = cc.ui.UIGroup.new()
    local group_width,group_height = 540,34
    group:addWidget(
        cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("战斗统计") ,
            font = UIKit:getFontFilePath(),
            size = 22,
            color = UIKit:hex2c3b(0x403c2f)
        }):align(display.CENTER,0, 0)
    )

    local item = self.details_view:newItem()
    item:setItemSize(group_width,group_height)
    item:addContent(group)
    self.details_view:addItem(item)


    -- 首先检查是否与协防方战斗  ，交战双方信息
    local report = self.report

    -- 左边为己方，右边为敌方
    local l_player = report:GetMyPlayerData()
    local r_player = report:GetEnemyPlayerData()
    self:CreateBelligerents(l_player,r_player)
    local l_dragon = l_player.dragon
    local r_dragon = r_player.dragon
    self:CreateArmyGroup(l_dragon,r_dragon)
end


-- 交战双方信息
function GameUIStrikeReport:CreateBelligerents(l_player,r_player)
    local group = cc.ui.UIGroup.new()
    local group_width,group_height = 540,100
    local self_item = self:CreateBelligerentsItem(group_height,l_player,true)
        :align(display.CENTER, -group_width/2+129, 0)

    group:addWidget(self_item)

    local enemy_item = self:CreateBelligerentsItem(group_height,r_player,false)
        :align(display.CENTER, group_width/2-129, 0)
    group:addWidget(enemy_item)
    local item = self.details_view:newItem()
    item:setItemSize(group_width,group_height)
    item:addContent(group)
    self.details_view:addItem(item)
end

function GameUIStrikeReport:CreateBelligerentsItem(height,player,isSelf)
    local player_item = self:CreateSmallBackGround({height=height})
    -- 联盟名字背景框
    display.newScale9Sprite(isSelf and "back_ground_blue_254x42.png" or "back_ground_red_254x42.png", 1, 0,cc.size(256,50),cc.rect(10,10,234,22))
        :align(display.LEFT_BOTTOM):addTo(player_item)

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
        text = player.type and string.format(_("等级%d"),player.level) or "["..player.alliance.tag.."]" ,
        size = 22,
        color = 0xffedae
    }):align(display.CENTER,170,  height-75)
        :addTo(player_item)

    return player_item
end

function GameUIStrikeReport:CreateArmyGroup(l_dragon,r_dragon)
    if not l_dragon and not r_dragon then
        return
    end
    local group = cc.ui.UIGroup.new()

    local group_width,group_height = 540,150
    if l_dragon then
        local self_army_item = self:CreateArmyItem(l_dragon,true)
            :align(display.CENTER, -group_width/2+129, 0)

        group:addWidget(self_army_item)
    end
    if r_dragon then
        local enemy_army_item = self:CreateArmyItem(r_dragon,false)
            :align(display.CENTER, group_width/2-129, 0)
        group:addWidget(enemy_army_item)
    end

    local item = self.details_view:newItem()
    item:setItemSize(group_width,group_height)
    item:addContent(group)
    self.details_view:addItem(item)
end

function GameUIStrikeReport:CreateArmyItem(dragon,isSelf)
    local w,h = 258,92

    local army_item = self:CreateSmallBackGround({height=h,title=Localize.dragon[dragon.type],isSelf=isSelf})

    local function createInfoItem(params)
        local item  = display.newScale9Sprite(params.bg_image,0,0,cc.size(254,28),cc.rect(10,10,528,20))
        local title = UIKit:ttfLabel({
            text = params.title ,
            size = 18,
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

    local army_info = {
        {
            bg_image = "back_ground_548x40_1.png",
            title = "Level",
            value = dragon.level,
        },

        {
            bg_image = "back_ground_548x40_2.png",
            title = "HP",
            value = dragon.hp.."/-"..dragon.hpDecreased,
        },
    }

    local gap_y = 28
    local y_postion = h -34
    for k,v in pairs(army_info) do
        createInfoItem(v):addTo(army_item)
            :align(display.TOP_CENTER, w/2, y_postion)
        y_postion = y_postion - gap_y
    end
    return army_item
end

function GameUIStrikeReport:CreateReportOfEnemy()
    local item = self.details_view:newItem()
    item:setItemSize(540,34)
    item:addContent(
        cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("敌方情报") ,
            font = UIKit:getFontFilePath(),
            size = 22,
            color = UIKit:hex2c3b(0x403c2f)
        }):align(display.CENTER,0, 17)
    )
    self.details_view:addItem(item)

    local report_level = self.report:GetStrikeLevel()
    if report_level>1 then
        -- 敌方资源产量
        self:CreateEnemyResource()
        -- 驻防部队
        self:CreateGarrison()
    end
    if report_level>3 then
        -- 敌方龙的装备
        self:CreateDragonEquipments()
        -- 敌方龙的技能
        self:CreateDragonSkills()
    end
    -- 敌方军事水平
    if report_level > 4 then
        self:CreateEnemyTechnology()
    end
end
function GameUIStrikeReport:CreateEnemyResource()
    local resources = self.report:GetStrikeIntelligence().resources
    if not resources then
        return
    end
    local r_tip_height = 36

    -- 敌方资源列表部分高度
    local unpack_resources = self:GetEnemyResource(resources)
    local r_count = #unpack_resources
    local r_list_height = r_count * r_tip_height

    -- 敌方资源列表
    local group = self:CreateSmallBackGround({width=548,height=r_list_height+34,title=_("最大可掠夺量"),isSelf=false})
    local group_width , group_height = 546,r_list_height+50

    -- 构建所有资源标签项
    local r_item_bg_color_flag = true
    local added_r_item_count = 0

    for k,r_parms in pairs(unpack_resources) do
        local r_item_bg_image = r_item_bg_color_flag and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
        local r_item_bg = display.newScale9Sprite(r_item_bg_image,0,0,cc.size(546,36),cc.rect(10,10,528,20))
            :align(display.TOP_CENTER, group_width/2, r_list_height-r_tip_height*added_r_item_count)
            :addTo(group)
        local r_icon = display.newSprite(r_parms.icon, 30, 18):addTo(r_item_bg)
        r_icon:setScale(40/r_icon:getContentSize().width)
        cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = r_parms.resource_type,
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x403c2f)
        }):align(display.LEFT_CENTER,80,18):addTo(r_item_bg)
        local r_value = self.report:GetStrikeLevel() < 3 and self:GetProbableNum(r_parms.value) or r_parms.value
        cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = self.report:GetStrikeLevel() < 3 and r_value or GameUtils:formatNumber(r_value),
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x403c2f)
        }):align(display.RIGHT_CENTER,group_width-10,18):addTo(r_item_bg)

        added_r_item_count = added_r_item_count + 1
        r_item_bg_color_flag = not r_item_bg_color_flag
    end


    local item = self.details_view:newItem()
    item:setItemSize(group_width , group_height)
    item:addContent(group)
    self.details_view:addItem(item)
end
function GameUIStrikeReport:GetEnemyResource(resources)
    local unpack_resources = {}
    for k,v in pairs({"wood","stone","food","iron","coin"}) do
        local va = resources[v]
        table.insert(unpack_resources, {
            resource_type = Localize.fight_reward[v],
            icon= UILib.resource[v],
            value = va,
        }
        )
    end
    return unpack_resources
end

function GameUIStrikeReport:CreateEnemyTechnology()
    local r_tip_height = 36

    -- 敌方科技列表部分高度
    local militaryTechs = self.report:GetStrikeIntelligence().militaryTechs
    if not militaryTechs then return end
    local r_count = #militaryTechs
    local r_list_height = r_count * r_tip_height

    -- 敌方科技列表

    local group_width , group_height = 548,r_list_height+34
    local group = self:CreateSmallBackGround({width = group_width,height = group_height,title= r_count == 0 and _("无军事科技") or _("军事科技水平"),isSelf=false})

    -- 构建所有科技标签项
    local r_item_bg_color_flag = true
    local added_r_item_count = 0
    for i = #militaryTechs,1,-1 do
        local r_parms = militaryTechs[i]
        local r_item_bg_image = r_item_bg_color_flag and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
        local r_item_bg = display.newScale9Sprite(r_item_bg_image,0,0,cc.size(546,36),cc.rect(10,10,528,20))
            :align(display.TOP_CENTER, group_width/2, r_list_height-r_tip_height*added_r_item_count+4)
            :addTo(group)
        local soldiers = string.split(r_parms.name, "_")
        local tech_name
        if soldiers[2] == "hpAdd" then
            tech_name = string.format(_("%s血量增加"),Localize.soldier_category[soldiers[1]])
        else
            tech_name = string.format(_("%s对%s攻击"),Localize.soldier_category[soldiers[1]],Localize.soldier_category[soldiers[2]])
        end
        cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = tech_name ,
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x403c2f)
        }):align(display.LEFT_CENTER,10,18):addTo(r_item_bg)
        cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = "LV "..r_parms.level,
            font = UIKit:getFontFilePath(),
            size = 20,
            color = UIKit:hex2c3b(0x403c2f)
        }):align(display.RIGHT_CENTER,group_width-10,18):addTo(r_item_bg)

        added_r_item_count = added_r_item_count + 1
        r_item_bg_color_flag = not r_item_bg_color_flag
    end


    local item = self.details_view:newItem()
    item:setItemSize(group_width , group_height)
    item:addContent(group)
    self.details_view:addItem(item)
end
function GameUIStrikeReport:GetTextEnemyTechnology()
    return {
        {
            tech_type = _("步兵科技"),
            value = "X "..100,
        },
        {
            tech_type = _("弓箭手科技"),
            value = "X "..100,
        },
        {
            tech_type = _("骑兵科技"),
            value = "X "..100,
        },
        {
            tech_type = _("投石车科技"),
            value = "X "..100,
        },
    }
end
function GameUIStrikeReport:CreateDragonSkills()
    local dragon = self.report:GetStrikeIntelligence().dragon
    if not dragon then
        return
    end
    local r_tip_height = 36

    local skills = dragon.skills
    -- 敌方龙技能列表部分高度
    local r_count = not skills and 0 or #skills
    local r_list_height = r_count * r_tip_height

    -- 敌方龙技能列表
    local title = (not skills or #skills ==0) and _("龙没有技能") or _("龙的技能")
    local group_width , group_height = 552,r_list_height+50
    local group = self:CreateSmallBackGround({width=group_width,height=r_list_height+34,title=title})
    if skills then
        -- 构建所有龙技能标签项
        local r_item_bg_color_flag = true
        local added_r_item_count = 0
        for k,r_parms in pairs(skills) do
            local r_item_bg_image = r_item_bg_color_flag and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
            local r_item_bg = display.newScale9Sprite(r_item_bg_image,0,0,cc.size(546,36),cc.rect(10,10,528,20))
                :align(display.TOP_CENTER, group_width/2, r_list_height-r_tip_height*added_r_item_count)
                :addTo(group)
            cc.ui.UILabel.new({
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = Localize.dragon_skill[r_parms.name],
                font = UIKit:getFontFilePath(),
                size = 20,
                color = UIKit:hex2c3b(0x403c2f)
            }):align(display.LEFT_CENTER,10,18):addTo(r_item_bg)
            if self.report:GetStrikeLevel()>4 then
                cc.ui.UILabel.new({
                    UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                    text = string.format(_("等级%d"),r_parms.level),
                    font = UIKit:getFontFilePath(),
                    size = 20,
                    color = UIKit:hex2c3b(0x403c2f)
                }):align(display.RIGHT_CENTER,group_width-30,18):addTo(r_item_bg)
            end

            added_r_item_count = added_r_item_count + 1
            r_item_bg_color_flag = not r_item_bg_color_flag
        end
    end


    local item = self.details_view:newItem()
    item:setItemSize(group_width , group_height)
    item:addContent(group)
    self.details_view:addItem(item)
end
function GameUIStrikeReport:CreateGarrison()
    local soldiers = self.report:GetStrikeIntelligence().soldiers

    local r_tip_height = 36


    -- 敌方龙技能列表部分高度
    local r_count = not soldiers and 0 or #soldiers
    local r_list_height = r_count * r_tip_height

    -- 敌方龙技能列表
    local title = (not soldiers or #soldiers ==0) and _("没有驻防部队") or _("驻防部队")
    local group_width , group_height = 552,r_list_height+50
    local group = self:CreateSmallBackGround({width=group_width,height=r_list_height+34,title=title})
    if soldiers then
        -- 构建所有龙技能标签项
        local r_item_bg_color_flag = true
        local added_r_item_count = 0
        for k,r_parms in pairs(soldiers) do
            local r_item_bg_image = r_item_bg_color_flag and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
            local r_item_bg = display.newScale9Sprite(r_item_bg_image,0,0,cc.size(546,36),cc.rect(10,10,528,20))
                :align(display.TOP_CENTER, group_width/2, r_list_height-r_tip_height*added_r_item_count)
                :addTo(group)
            cc.ui.UILabel.new({
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = Localize.soldier_name[r_parms.name],
                font = UIKit:getFontFilePath(),
                size = 20,
                color = UIKit:hex2c3b(0x403c2f)
            }):align(display.LEFT_CENTER,10,18):addTo(r_item_bg)
            local report_level = self.report:GetStrikeLevel()

            if report_level>3 then
                local soldier_num = report_level<5 and self:GetProbableNum(r_parms.count) or r_parms.count
                cc.ui.UILabel.new({
                    UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                    text = _("数量")..soldier_num,
                    font = UIKit:getFontFilePath(),
                    size = 20,
                    color = UIKit:hex2c3b(0x403c2f)
                }):align(display.RIGHT_CENTER,group_width-30,18):addTo(r_item_bg)
                StarBar.new({
                    max = 3,
                    bg = "Stars_bar_bg.png",
                    fill = "Stars_bar_highlight.png",
                    num = r_parms.star,
                    margin = 0,
                    direction = StarBar.DIRECTION_HORIZONTAL,
                    scale = 0.6,
                }):addTo(r_item_bg):align(display.RIGHT_CENTER,group_width/2, 18)
            end

            added_r_item_count = added_r_item_count + 1
            r_item_bg_color_flag = not r_item_bg_color_flag
        end
    end


    local item = self.details_view:newItem()
    item:setItemSize(group_width , group_height)
    item:addContent(group)
    self.details_view:addItem(item)
end
function GameUIStrikeReport:CreateDragonEquipments()
    local dragon = self.report:GetStrikeIntelligence().dragon

    local equipments = dragon and dragon.equipments

    local r_tip_height = 36

    -- 敌方龙装备列表部分高度
    local r_count =not equipments and 0 or #equipments
    local r_list_height = r_count * r_tip_height
    -- 敌方龙装备列表
    local title = not dragon and _("敌方龙没有驻防") or (not equipments or #equipments == 0) and _("敌方龙没有装备") or _("龙的装备")
    local group_width , group_height = 552,r_list_height+50
    local group = self:CreateSmallBackGround({width=group_width,height=r_list_height+34,title=title})
    if equipments then
        -- 构建所有龙装备标签项
        local r_item_bg_color_flag = true
        local added_r_item_count = 0
        for k,r_parms in pairs(equipments) do
            local r_item_bg_image = r_item_bg_color_flag and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
            local r_item_bg = display.newScale9Sprite(r_item_bg_image,0,0,cc.size(546,36),cc.rect(10,10,528,20))
                :align(display.TOP_CENTER, group_width/2, r_list_height-r_tip_height*added_r_item_count)
                :addTo(group)
            cc.ui.UILabel.new({
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = Localize.equip[r_parms.name],
                font = UIKit:getFontFilePath(),
                size = 20,
                color = UIKit:hex2c3b(0x403c2f)
            }):align(display.LEFT_CENTER,10,18):addTo(r_item_bg)
            StarBar.new({
                max = 5,
                bg = "Stars_bar_bg.png",
                fill = "Stars_bar_highlight.png",
                num = r_parms.star,
                margin = 0,
                direction = StarBar.DIRECTION_HORIZONTAL,
                scale = 0.6,
            }):addTo(r_item_bg):align(display.RIGHT_CENTER,group_width-50, 18)

            added_r_item_count = added_r_item_count + 1
            r_item_bg_color_flag = not r_item_bg_color_flag
        end
    end


    local item = self.details_view:newItem()
    item:setItemSize(group_width , group_height)
    item:addContent(group)
    self.details_view:addItem(item)
end

-- 创建 宽度为258的 UI框
function GameUIStrikeReport:CreateSmallBackGround(params)
    local widht = params.width or 258
    local height = params.height or 90
    local r_bg = display.newScale9Sprite("back_ground_258x90.png",0,0,cc.size(widht,height),cc.rect(10,10,238,70))
    -- title bg
    if params.title then
        local t_bg = display.newScale9Sprite(params.isSelf and "back_ground_blue_254x42.png" or "back_ground_red_254x42.png", 0, 0,cc.size(widht-2,34),cc.rect(10,10,234,22))
            :align(display.CENTER_TOP, widht/2, height):addTo(r_bg)
        UIKit:ttfLabel({
            text = params.title ,
            size = 20,
            color = 0xffedae
        }):align(display.CENTER,t_bg:getContentSize().width/2, 17):addTo(t_bg)
    end

    return r_bg
end

function GameUIStrikeReport:GetProbableNum(num)
    if num<=20 then
        return "0-20"
    elseif num<=50 then
        return "20-50"
    elseif num<=100 then
        return "50-100"
    elseif num<=200 then
        return "100-200"
    elseif num<=500 then
        return "200-500"
    elseif num<=1000 then
        return "500-1000"
    elseif num<=2000 then
        return "1k-2k"
    elseif num<=5000 then
        return "2k-5k"
    elseif num<=10000 then
        return "5k-10k"
    elseif num<=20000 then
        return "10k-20k"
    elseif num<=50000 then
        return "20k-50k"
    elseif num<=100000 then
        return "50k-100k"
    elseif num<=200000 then
        return "100k-200k"
    elseif num<=500000 then
        return "200k-500k"
    elseif num<=1000000 then
        return "500k-1M"
    elseif num<=2000000 then
        return "1M-2M"
    elseif num<=5000000 then
        return "2M-5M"
    elseif num<=10000000 then
        return "5M-10M"
    else
        return ">10M"
    end
end

return GameUIStrikeReport






















































