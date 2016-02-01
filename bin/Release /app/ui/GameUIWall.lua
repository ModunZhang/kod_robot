
local Localize = import("..utils.Localize")
local UILib = import(".UILib")
local GameUIWall = UIKit:createUIClass('GameUIWall',"GameUIUpgradeBuilding")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local WidgetSoldierBox = import("..widget.WidgetSoldierBox")
local WidgetSelectDragon = import("..widget.WidgetSelectDragon")
local timer = app.timer
local WidgetUseItems = import("..widget.WidgetUseItems")
local WidgetSelectWallDragon = import("..widget.WidgetSelectWallDragon")

function GameUIWall:ctor(city,building,default_tab)
    self.city = city
    GameUIWall.super.ctor(self,city,Localize.building_name[building:GetType()],building,default_tab)
    self.dragon_manager = city:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    self.dragon_manager:AddListenOnType(self,self.dragon_manager.LISTEN_TYPE.OnHPChanged)
end

function GameUIWall:OnMoveInStage()
    GameUIWall.super.OnMoveInStage(self)
    self:CreateMilitaryUIIf():addTo(self:GetView()):hide():pos(window.left,window.bottom)
    self:CreateTabButtons({
        {
            label = _("驻防"),
            tag = "military",
        }
    },
    function(tag)
        if tag == 'military' then
            self.military_node:show()
        else
            self.military_node:hide()
        end
    end):pos(window.cx, window.bottom + 34)
    scheduleAt(self, function()
        --更新城墙hp
        if self.military_node:isVisible() then
            local value = self.city:GetUser():GetResValueByType("wallHp")
            local res = self.city:GetUser():GetResProduction("wallHp")
            local string = string.format("%d/%d", value, res.limit)
            self.wall_hp_process_label:setString(string)
            self.wall_hp_recovery_label:setString("+" .. res.output .. "/H")
            self.progressTimer_wall:setPercentage(value/res.limit*100)
        end
    end)
end

function GameUIWall:OnMoveOutStage()
    self.dragon_manager:RemoveListenerOnType(self,self.dragon_manager.LISTEN_TYPE.OnHPChanged)
    GameUIWall.super.OnMoveOutStage(self)
end

function GameUIWall:CreateMilitaryUIIf()
    if self.military_node then return self.military_node end
    local dragon = self:GetDragon()
    local military_node = display.newNode():size(window.width,window.height)

    local wall_bg = WidgetUIBackGround.new({height = 274})
        :addTo(military_node)
        :pos((window.width - 608)/2,window.height - 274 - 91)
    local title_bar = display.newSprite("title_bar_586x34.png"):align(display.LEFT_TOP,10,wall_bg:getContentSize().height - 10):addTo(wall_bg)
    UIKit:ttfLabel({
        text = _("城墙耐久度"),
        size = 22,
        color = 0xffedae
    }):align(display.CENTER, 293, 17):addTo(title_bar)

    local value = self.city:GetUser():GetResValueByType("wallHp")
    local res = self.city:GetUser():GetResProduction("wallHp")
    local string = string.format("%d/%d", value, res.limit)
    local process_wall_bg = display.newSprite("process_bar_540x40.png")
        :align(display.CENTER_TOP,wall_bg:getContentSize().width/2,  wall_bg:getContentSize().height - 70)
        :addTo(wall_bg)
    local progressTimer_wall = UIKit:commonProgressTimer("bar_color_540x40.png"):addTo(process_wall_bg):align(display.LEFT_BOTTOM,0,0)
    progressTimer_wall:setPercentage(value/res.limit*100)
    self.progressTimer_wall = progressTimer_wall
    self.wall_hp_process_label = UIKit:ttfLabel({
        text = string,
        size = 22,
        color= 0xfff3c7,
        shadow= true
    }):align(display.LEFT_CENTER,50,20):addTo(process_wall_bg)
    self.wall_hp_recovery_label = UIKit:ttfLabel({
        text = "+" .. res.output .. "/h",
        size = 22,
        color= 0xfff3c7
    }):align(display.RIGHT_CENTER, 480, 20):addTo(process_wall_bg)

    WidgetPushButton.new({normal = "add_btn_up_50x50.png",pressed = "add_btn_down_50x50.png"})
        :addTo(process_wall_bg)
        :align(display.CENTER_RIGHT,546,20)
        :onButtonClicked(function()
            WidgetUseItems.new():Create({
                item_name = "restoreWall_1"
            }):AddToCurrentScene(true)
        end)

    local iconbg = display.newSprite("drgon_process_icon_bg.png")
        :addTo(process_wall_bg)
        :align(display.LEFT_BOTTOM, -15,0)
    display.newSprite("icon_wall_83x103.png"):scale(40/103)
        :addTo(iconbg)
        :pos(iconbg:getContentSize().width/2,iconbg:getContentSize().height/2)
    local tips_bg = self:GetTipsBoxWithTipsContent({_("・防御敌方进攻时，可能会损失城墙的生命值。"),_("・当生命值为0时，地方联盟将击溃你的城市，获得额外的联盟积分。")})
    tips_bg:align(display.CENTER_TOP,wall_bg:getContentSize().width/2,wall_bg:getContentSize().height - 140):addTo(wall_bg)


    local draogn_box = display.newSprite("alliance_item_flag_box_126X126.png")
        :addTo(military_node)
        :align(display.LEFT_BOTTOM, 42,wall_bg:getPositionY() - wall_bg:getContentSize().height/2 - 10)
    local dragon_bg = display.newSprite("dragon_bg_114x114.png", 63, 63):addTo(draogn_box)
    self.dragon_head = display.newSprite(UILib.dragon_head['redDragon']):addTo(dragon_bg):pos(57,60)
    if not dragon then
        self.dragon_head:hide()
    else
        self.dragon_head:setTexture(UILib.dragon_head[dragon:Type()])
    end
    local progressTimer_bg = display.newSprite("process_bar_410x40.png")
        :align(display.LEFT_BOTTOM, draogn_box:getPositionX()+draogn_box:getContentSize().width + 20, draogn_box:getPositionY()+10)
        :addTo(military_node)
    local progressTimer = UIKit:commonProgressTimer("bar_color_410x40.png"):addTo(progressTimer_bg):align(display.LEFT_BOTTOM,0,0)
    self.dragon_hp_progress = progressTimer
    self.progressTimer_bg = progressTimer_bg
    local iconbg = display.newSprite("drgon_process_icon_bg.png")
        :addTo(progressTimer_bg)
        :align(display.LEFT_BOTTOM, -15,0)
    display.newSprite("dragon_lv_icon.png")
        :addTo(iconbg)
        :pos(iconbg:getContentSize().width/2,iconbg:getContentSize().height/2)
    self.hp_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color= 0xfff3c7,
        shadow = true,
    }):align(display.LEFT_CENTER, iconbg:getPositionX()+iconbg:getContentSize().width+10,20):addTo(progressTimer_bg)
    self.dragon_hp_recovery_label = UIKit:ttfLabel({
        text = self:GetDragonHPRecoveryStr(dragon),
        color = 0xfff3c7,
        shadow = true,
        size = 22,
    }):addTo(progressTimer_bg):align(display.RIGHT_CENTER, progressTimer_bg:getContentSize().width - 70, 20)
    if dragon then
        progressTimer:setPercentage(dragon:Hp()/dragon:GetMaxHP()*100)
        self.hp_label:setString(dragon:Hp() .. "/" .. dragon:GetMaxHP())
    else
        progressTimer:setPercentage(0)
        self.hp_label:hide()
        self.progressTimer_bg:hide()
    end

    local button = WidgetPushButton.new({normal = 'add_btn_up_50x50.png',pressed = 'add_btn_down_50x50.png'})
        :addTo(progressTimer_bg):align(display.RIGHT_CENTER, 415, 20)
        :onButtonClicked(handler(self, self.OnDragonHpItemUseButtonClicked))

    local tips_label = UIKit:ttfLabel({
        text = self:GetDefenceDragonBuffDesc(),
        color= 0x514d3e,
        size = 20
    }):align(display.LEFT_BOTTOM,draogn_box:getPositionX()+draogn_box:getContentSize().width + 15,  draogn_box:getPositionY()+10):addTo(military_node)
    self.tips_label = tips_label
    local name_str = _("请选择一个巨龙驻防")
    local level_str = string.format(_("当前联盟地形:%s"),Alliance_Manager:GetMyAlliance():IsDefault() and _("无") or Localize.terrain[Alliance_Manager:GetMyAlliance().basicInfo.terrain])
    if dragon then
        name_str = dragon:GetLocalizedName()
        level_str=  _("力量")
    end
    local title_bg = display.newScale9Sprite("title_blue_430x30.png",0, 0, cc.size(416,30), cc.rect(10,10,410,10)):addTo(military_node)
        :align(display.LEFT_TOP, tips_label:getPositionX(), draogn_box:getPositionY() + draogn_box:getContentSize().height)
    local name_label = UIKit:ttfLabel({
        text = name_str,
        size = 20,
        color= 0xffedae
    })
        :addTo(title_bg)
        :align(display.LEFT_CENTER,20, title_bg:getContentSize().height/2)
    self.name_label = name_label
    local level_title_label = UIKit:ttfLabel({
        text = level_str,
        size = 20,
        color= 0x615b44
    }):align(display.LEFT_BOTTOM,title_bg:getPositionX(), tips_label:getPositionY() + tips_label:getContentSize().height + 20):addTo(military_node)
    self.level_title_label = level_title_label
    self.dragon_level_label = UIKit:ttfLabel({
        text = "",
        color= 0x514d3e,
        size = 20
    }):addTo(military_node):align(display.LEFT_BOTTOM,level_title_label:getPositionX()+50, level_title_label:getPositionY())
    if dragon then
        self.dragon_level_label:setString(string.formatnumberthousands(dragon:Strength()))
        self.tips_label:hide()
    else
        self.dragon_level_label:hide()
        self.tips_label:show()
    end

    local info_list,list_node = UIKit:commonListView({
        -- bgColor = UIKit:hex2c4b(0x7a000000),
        viewRect = cc.rect(11,10, 546, 270),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    },true)
    list_node:addTo(military_node):align(display.BOTTOM_CENTER, window.width/2, 160)
    self.info_list = info_list

    local tips_panel = self:GetTipsBoxWithTipsContent({
        _("・不驻防巨龙，所有城市中的部队将不会进行防御。"),
        _("・驻防巨龙能防御敌方进行的突袭，获得城市的信息")
    }):addTo(military_node):align(display.CENTER_TOP,window.width/2,draogn_box:getPositionY() - 10)
    local select_button = WidgetPushButton.new({
        normal = "yellow_btn_up_148x58.png",
        pressed = "yellow_btn_down_148x58.png",
        disabled = "gray_btn_148x58.png"
    })
        :addTo(military_node)
        :align(display.CENTER_BOTTOM, window.width/2,tips_panel:getPositionY() - tips_panel:getContentSize().height - 70)
        :setButtonLabel("normal", UIKit:ttfLabel({text = _("驻防部队"),size = 22,color = 0xffedae,shadow = true}))
        :onButtonClicked(function()
            UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers)
                if self.dragon_manager:GetDragon(dragonType):IsDead() then
                    UIKit:showMessageDialog(nil,_("选择的龙已经死亡")):CreateCancelButton(
                        {
                            listener = function ()
                                UIKit:newGameUI("GameUIDragonEyrieMain", self.city, self.city:GetFirstBuildingByType("dragonEyrie"), "dragon", false, self.dragon_manager:GetDragon(dragonType):Type()):AddToCurrentScene(true)
                                self:LeftButtonClicked()
                            end,
                            btn_name= _("查看"),
                            btn_images = {normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"}
                        }
                    )
                    return
                end
                NetManager:getSetDefenceTroopPromise(dragonType,soldiers):done(function ()
                    self:RefreshUIAfterSelectDragon(self.dragon_manager:GetDragon(dragonType),soldiers)
                end)
            end,{isMilitary = true,terrain = not Alliance_Manager:GetMyAlliance():IsDefault() and Alliance_Manager:GetMyAlliance().basicInfo.terrain or User.basicInfo.terrain,title = _("驻防部队")}):AddToCurrentScene(true)
        end)
    self.military_troop_btn = select_button

    local retreat_btn = WidgetPushButton.new({
        normal = "red_btn_up_148x58.png",
        pressed = "red_btn_down_148x58.png",
        disabled = "gray_btn_148x58.png"
    })
        :addTo(military_node)
        :align(display.LEFT_BOTTOM, 50,list_node:getPositionY() - 70)
        :setButtonLabel("normal", UIKit:ttfLabel({text = _("撤防"),size = 22,color = 0xffedae,shadow = true}))
        :onButtonClicked(function()
            NetManager:getCancelDefenceTroopPromise():done(function()
                self:RefreshUIAfterSelectDragon()
            end)
        end)
    self.retreat_troop_btn = retreat_btn

    local edit_button = WidgetPushButton.new({
        normal = "blue_btn_up_148x58.png",
        pressed = "blue_btn_down_148x58.png",
        disabled = "gray_btn_148x58.png"
    })
        :addTo(military_node)
        :align(display.RIGHT_BOTTOM, window.width - 50,list_node:getPositionY() - 70)
        :setButtonLabel("normal", UIKit:ttfLabel({text = _("编辑"),size = 22,color = 0xffedae,shadow = true}))
        :onButtonClicked(function()
            UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers)
                if self.dragon_manager:GetDragon(dragonType):IsDead() then
                    UIKit:showMessageDialog(nil,_("选择的龙已经死亡")):CreateCancelButton(
                        {
                            listener = function ()
                                UIKit:newGameUI("GameUIDragonEyrieMain", self.city, self.city:GetFirstBuildingByType("dragonEyrie"), "dragon", false, self.dragon_manager:GetDragon(dragonType):Type()):AddToCurrentScene(true)
                                self:LeftButtonClicked()
                            end,
                            btn_name= _("查看"),
                            btn_images = {normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"}
                        }
                    )
                    return
                end
                NetManager:getSetDefenceTroopPromise(dragonType,soldiers):done(function ()
                    self:RefreshUIAfterSelectDragon(self.dragon_manager:GetDragon(dragonType),soldiers)
                end)
            end,{isMilitary = true,terrain = not Alliance_Manager:GetMyAlliance():IsDefault() and Alliance_Manager:GetMyAlliance().basicInfo.terrain or User.basicInfo.terrain,title = _("驻防部队"),military_soldiers = User.defenceTroop.soldiers}):AddToCurrentScene(true)
        end)
    self.edit_troop_btn = edit_button
    if dragon then
        tips_panel:hide()
        self.military_troop_btn:hide()
        self.retreat_troop_btn:show()
        self.edit_troop_btn:show()
    else
        list_node:hide()
        self.military_troop_btn:show()
        self.retreat_troop_btn:hide()
        self.edit_troop_btn:hide()
    end
    self.tips_panel = tips_panel
    self.dragon_info_panel = list_node

    --bottom

    self.military_node = military_node
    if dragon then
        self:RefreshListView()
    end
    return self.military_node
end

function GameUIWall:GetDefenceDragonBuffDesc()
    return Alliance_Manager:GetMyAlliance():IsDefault() and "" or string.format(_("选择%s会获得战斗力加成"),Localize.dragon[Alliance_Manager:GetMyAlliance():GetBestDragon()])
end

function GameUIWall:GetDragonHPRecoveryStr(dragon)
    if not dragon then return 0 end
    local dragonEyrie = City:GetDragonEyrie()
    return "+" .. dragonEyrie:GetTotalHPRecoveryPerHour(dragon:Type()) .. "/h"
end

function GameUIWall:OnDragonHpItemUseButtonClicked()
    local widgetUseItems = WidgetUseItems.new():Create({
        item_name = "dragonHp_1",
        dragon = self:GetDragon()
    })
    widgetUseItems:AddToCurrentScene()
end

function GameUIWall:GetTipsBoxWithTipsContent(content)
    local tips_bg = WidgetUIBackGround.new({width = 556,height = 106},WidgetUIBackGround.STYLE_TYPE.STYLE_5)

    local list = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(13,10, 530, 106 - 20),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(tips_bg)
    local y = 100
    for _,v in ipairs(content) do
        local tips_label = UIKit:ttfLabel({text = v,size = 18,color = 0x403c2f,dimensions = cc.size(500,0) })
        local item = list:newItem()
        item:setItemSize(530, tips_label:getContentSize().height)
        item:addContent(tips_label)
        list:addItem(item)
    end
    list:reload()
    return tips_bg
end

function GameUIWall:RefreshListView()
    self.info_list:removeAllItems()
    if not User.defenceTroop or User.defenceTroop == json.null then
        return
    end
    local soldiers = clone(User.defenceTroop.soldiers)
    table.sort( soldiers, function ( a,b )
        local total_power_a = User:GetSoldierConfig(a.name).power * a.count
        local total_power_b = User:GetSoldierConfig(b.name).power * b.count
        return total_power_a > total_power_b
    end )
    for i=1,#soldiers,4 do
        local row_item = display.newNode()
        local added = 1
        local j = i
        for j=1,4 do
            local soldier = soldiers[i+j-1]
            if soldier then
                row_item:setContentSize(cc.size(546,166))
                WidgetSoldierBox.new(nil, function()end):addTo(row_item)
                    :alignByPoint(cc.p(0.5, 0.5), 65 + (130 + 9) * (added - 1) , 83)
                    :SetSoldier(soldier.name, self.city:GetUser():SoldierStarByName(soldier.name))
                    :SetNumber(soldier.count)
                added = added + 1
            end
        end
        local item = self.info_list:newItem()
        item:addContent(row_item)
        item:setItemSize(546, 166)
        self.info_list:addItem(item)
    end
    self.military_soldiers = soldiers
    self.info_list:reload()
end

function GameUIWall:GetDragon()
    return self.dragon_manager:GetDefenceDragon()
end

function GameUIWall:RefreshUIAfterSelectDragon(dragon,soldiers)
    if dragon then
        self.name_label:setString(dragon:GetLocalizedName())
        self.military_troop_btn:hide()
        self.retreat_troop_btn:show()
        self.edit_troop_btn:show()
        self.dragon_info_panel:show()
        self.tips_panel:hide()
        self.level_title_label:setString(_("力量"))
        self.dragon_level_label:setString(string.formatnumberthousands(dragon:Strength()))
        self.dragon_level_label:show()
        self.tips_label:hide()
        self.progressTimer_bg:show()
        self.hp_label:setString(dragon:Hp() .. "/" .. dragon:GetMaxHP())
        self.dragon_hp_recovery_label:setString(self:GetDragonHPRecoveryStr(dragon))
        self.hp_label:show()
        self.dragon_hp_progress:setPercentage(dragon:Hp()/dragon:GetMaxHP()*100)
        self.dragon_head:setTexture(UILib.dragon_head[dragon:Type()])
        self.dragon_head:show()
        self:RefreshListView()
    else
        self.name_label:setString(_("请选择一个巨龙驻防"))
        self.dragon_info_panel:hide()
        self.military_troop_btn:show()
        self.retreat_troop_btn:hide()
        self.edit_troop_btn:hide()
        self.tips_panel:show()
        self.tips_label:show()
        self.dragon_level_label:hide()
        self.level_title_label:setString(
            string.format(_("当前联盟地形:%s"),Alliance_Manager:GetMyAlliance():IsDefault() and _("无") or Localize.terrain[Alliance_Manager:GetMyAlliance().basicInfo.terrain])
        )
        self.progressTimer_bg:hide()
        self.hp_label:hide()
        self.dragon_hp_progress:setPercentage(0)
        self.dragon_head:hide()
    end
end

function GameUIWall:OnHPChanged()
    local dragon = self:GetDragon()
    if not dragon or not dragon:Ishated() then return end
    if self.hp_label and self.hp_label:isVisible() then
        self.hp_label:setString(dragon:Hp() .. "/" .. dragon:GetMaxHP())
        self.dragon_hp_progress:setPercentage(dragon:Hp()/dragon:GetMaxHP()*100)
    end
end
return GameUIWall






