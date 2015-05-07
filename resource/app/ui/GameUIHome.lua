local cocos_promise = import("..utils.cocos_promise")
local promise = import("..utils.promise")
local window = import("..utils.window")
local WidgetChat = import("..widget.WidgetChat")
local WidgetNumberTips = import("..widget.WidgetNumberTips")
local WidgetHomeBottom = import("..widget.WidgetHomeBottom")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetEventTabButtons = import("..widget.WidgetEventTabButtons")
local SoldierManager = import("..entity.SoldierManager")
local WidgetAutoOrder = import("..widget.WidgetAutoOrder")
local UILib = import(".UILib")
local Arrow = import(".Arrow")
local WidgetChangeMap = import("..widget.WidgetChangeMap")
local GameUIHelp = import(".GameUIHelp")
local Alliance = import("..entity.Alliance")
local GrowUpTaskManager = import("..entity.GrowUpTaskManager")
local GameUIHome = UIKit:createUIClass('GameUIHome')


local app = app
local timer = app.timer

function GameUIHome:OnResourceChanged(resource_manager)
    local server_time = timer:GetServerTime()
    local wood_resource = resource_manager:GetWoodResource()
    local food_resource = resource_manager:GetFoodResource()
    local iron_resource = resource_manager:GetIronResource()
    local stone_resource = resource_manager:GetStoneResource()
    local citizen_resource = resource_manager:GetPopulationResource()
    local coin_resource = resource_manager:GetCoinResource()
    local wood_number = wood_resource:GetResourceValueByCurrentTime(server_time)
    local food_number = food_resource:GetResourceValueByCurrentTime(server_time)
    local iron_number = iron_resource:GetResourceValueByCurrentTime(server_time)
    local stone_number = stone_resource:GetResourceValueByCurrentTime(server_time)
    local citizen_number = citizen_resource:GetNoneAllocatedByTime(server_time)
    local coin_number = coin_resource:GetResourceValueByCurrentTime(server_time)
    local gem_number = self.city:GetUser():GetGemResource():GetValue()
    self.wood_label:setString(GameUtils:formatNumber(wood_number))
    self.food_label:setString(GameUtils:formatNumber(food_number))
    self.iron_label:setString(GameUtils:formatNumber(iron_number))
    self.stone_label:setString(GameUtils:formatNumber(stone_number))
    self.citizen_label:setString(GameUtils:formatNumber(citizen_number))
    self.coin_label:setString(GameUtils:formatNumber(coin_number))
    self.gem_label:setString(string.formatnumberthousands(gem_number))

    self.wood_label:setColor(wood_resource:IsOverLimit() and UIKit:hex2c4b(0x7e0000) or wood_resource:IsOverWarning() and UIKit:hex2c4b(0xff8400) or UIKit:hex2c4b(0xf3f0b6))
    self.food_label:setColor(food_resource:IsOverLimit() and UIKit:hex2c4b(0x7e0000) or food_resource:IsOverWarning() and UIKit:hex2c4b(0xff8400) or UIKit:hex2c4b(0xf3f0b6))
    self.iron_label:setColor(iron_resource:IsOverLimit() and UIKit:hex2c4b(0x7e0000) or iron_resource:IsOverWarning() and UIKit:hex2c4b(0xff8400) or UIKit:hex2c4b(0xf3f0b6))
    self.stone_label:setColor(stone_resource:IsOverLimit() and UIKit:hex2c4b(0x7e0000) or stone_resource:IsOverWarning() and UIKit:hex2c4b(0xff8400) or UIKit:hex2c4b(0xf3f0b6))
    self.citizen_label:setColor(citizen_resource:IsOverLimit() and UIKit:hex2c4b(0x7e0000) or citizen_resource:IsOverWarning() and UIKit:hex2c4b(0xff8400) or UIKit:hex2c4b(0xf3f0b6))

end
function GameUIHome:OnUpgradingBegin()
    self:OnTaskChanged()
end
function GameUIHome:OnUpgrading()
end
function GameUIHome:OnUpgradingFinished()
    self:OnTaskChanged()
    self:RefreshHelpButtonVisible()
end
function GameUIHome:OnTaskChanged()
    self.task = self.city:GetRecommendTask()
    if self.task then
        self.quest_label:setString(self.task:Title())
    else
        self.quest_label:setString(_("当前没有推荐任务!"))
    end
end
function GameUIHome:OnMilitaryTechEventsChanged()
    self:RefreshHelpButtonVisible()
end
function GameUIHome:OnSoldierStarEventsChanged()
    self:RefreshHelpButtonVisible()
end
function GameUIHome:OnProductionTechnologyEventDataChanged()
    self:RefreshHelpButtonVisible()
end
function GameUIHome:RefreshHelpButtonVisible()
    if self.help_button then
        self.top_order_group:RefreshOrder()
    end
end
function GameUIHome:DisplayOn()
    self.visible_count = self.visible_count + 1
    -- self:setVisible(self.visible_count > 0)
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIHome:DisplayOff()
    self.visible_count = self.visible_count - 1
    -- self:setVisible(self.visible_count > 0)
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIHome:FadeToSelf(isFullDisplay)
    self:setCascadeOpacityEnabled(true)
    local opacity = isFullDisplay == true and 255 or 0
    local p = isFullDisplay and 0 or 99999999
    transition.fadeTo(self, {opacity = opacity, time = 0.2,
        onComplete = function()
            self:pos(p, p)
        end
    })
end

function GameUIHome:ctor(city)
    GameUIHome.super.ctor(self,{type = UIKit.UITYPE.BACKGROUND})
    self.city = city
end
function GameUIHome:onEnter()
    self.visible_count = 1
    local city = self.city
    -- 上背景
    self:CreateTop()
    self.bottom = self:CreateBottom()

    WidgetChangeMap.new(WidgetChangeMap.MAP_TYPE.OUR_CITY):addTo(self)

    local ratio = self.bottom:getScale()
    self.event_tab = WidgetEventTabButtons.new(self.city, ratio)
    local rect1 = self.chat:getCascadeBoundingBox()
    local x, y = rect1.x, rect1.y + rect1.height - 2

    self.event_tab:addTo(self):pos(x, y)
    self:AddOrRemoveListener(true)
    self:OnResourceChanged(city:GetResourceManager())
    self:RefreshData()
    self:OnTaskChanged(User)
    self:RefreshHelpButtonVisible()
end
function GameUIHome:onExit()
    self:AddOrRemoveListener(false)
end
function GameUIHome:AddOrRemoveListener(isAdd)
    local city = self.city
    local user = self.city:GetUser()
    if isAdd then
        city:AddListenOnType(self, city.LISTEN_TYPE.UPGRADE_BUILDING)
        city:AddListenOnType(self, city.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
        city:GetResourceManager():AddObserver(self)
        city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
        city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
        Alliance_Manager:GetMyAlliance():AddListenOnType(self, Alliance.LISTEN_TYPE.BASIC)
        Alliance_Manager:GetMyAlliance():AddListenOnType(self, Alliance.LISTEN_TYPE.HELP_EVENTS)
        Alliance_Manager:GetMyAlliance():AddListenOnType(self, Alliance.LISTEN_TYPE.ALL_HELP_EVENTS)
        user:AddListenOnType(self, user.LISTEN_TYPE.BASIC)
        user:AddListenOnType(self, user.LISTEN_TYPE.TASK)
        user:AddListenOnType(self, user.LISTEN_TYPE.VIP_EVENT_ACTIVE)
        user:AddListenOnType(self, user.LISTEN_TYPE.VIP_EVENT_OVER)
    else
        city:RemoveListenerOnType(self, self.city.LISTEN_TYPE.UPGRADE_BUILDING)
        city:RemoveListenerOnType(self,city.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
        city:GetResourceManager():RemoveObserver(self)
        city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
        city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
        Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, Alliance.LISTEN_TYPE.BASIC)
        Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, Alliance.LISTEN_TYPE.HELP_EVENTS)
        Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, Alliance.LISTEN_TYPE.ALL_HELP_EVENTS)
        user:RemoveListenerOnType(self, user.LISTEN_TYPE.BASIC)
        user:RemoveListenerOnType(self, user.LISTEN_TYPE.TASK)
        user:RemoveListenerOnType(self, user.LISTEN_TYPE.VIP_EVENT_ACTIVE)
        user:RemoveListenerOnType(self, user.LISTEN_TYPE.VIP_EVENT_OVER)
    end
end
function GameUIHome:OnAllianceBasicChanged(fromEntity,changed_map)
    self:RefreshHelpButtonVisible()
    self:RefreshData()
end
function GameUIHome:OnUserBasicChanged(fromEntity,changed_map)
    if changed_map.name then
        self.name_label:setString(changed_map.name.new)
    end
    if changed_map.vipExp then
        self:RefreshVIP()
    end
    if changed_map.icon then
        self.player_icon:setTexture(UILib.player_icon[changed_map.icon.new])
    end
    if changed_map.levelExp then
        self:RefreshExp()
    end
    self:RefreshData()
end
function GameUIHome:OnHelpEventChanged(changed_map)
    self:RefreshHelpButtonVisible()
    self.request_count:SetNumber(Alliance_Manager:GetMyAlliance():GetOtherRequestEventsNum())
end
function GameUIHome:OnAllHelpEventChanged(help_events)
    self:RefreshHelpButtonVisible()
    self.request_count:SetNumber(Alliance_Manager:GetMyAlliance():GetOtherRequestEventsNum())
end
function GameUIHome:RefreshData()
    -- 更新数值
    local user = self.city:GetUser()
    self.name_label:setString(user:Name())
    self.power_label:setString(string.formatnumberthousands(user:Power()))
    self.level_label:setString(user:Level())
    self:RefreshVIP()
end


function GameUIHome:CreateTop()
    local top_bg = display.newSprite("top_bg_768x116.png"):addTo(self)
        :align(display.TOP_CENTER, display.cx, display.top ):setCascadeOpacityEnabled(true)
    if display.width>640 then
        top_bg:scale(display.width/768)
    end

    -- 玩家按钮
    local button = cc.ui.UIPushButton.new(
        {normal = "player_btn_up_314x86.png", pressed = "player_btn_down_314x86.png"},
        {scale9 = false}
    ):onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            UIKit:newGameUI('GameUIVip', City,"info"):AddToCurrentScene(true)
        end
    end):addTo(top_bg):align(display.LEFT_CENTER,top_bg:getContentSize().width/2-2, top_bg:getContentSize().height/2+10)
    button:setRotationSkewY(180)


    -- 玩家名字背景加文字
    local ox = 150
    local name_bg = display.newSprite("player_name_bg_168x30.png"):addTo(top_bg)
        :align(display.TOP_LEFT, ox, top_bg:getContentSize().height-10):setCascadeOpacityEnabled(true)
    self.name_label = cc.ui.UILabel.new({
        text = "",
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0xf3f0b6)
    }):addTo(name_bg):align(display.LEFT_CENTER, 14, name_bg:getContentSize().height/2 + 3)

    -- 玩家战斗值图片
    display.newSprite("power_16x19.png"):addTo(top_bg):pos(ox + 20, 65)

    -- 玩家战斗值文字
    UIKit:ttfLabel({
        text = _("战斗值："),
        size = 14,
        color = 0x9a946b,
        shadow = true
    }):addTo(top_bg):align(display.LEFT_CENTER, ox + 30, 65)

    -- 玩家战斗值数字
    self.power_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color = 0xf3f0b6,
        shadow = true
    }):addTo(top_bg):align(display.LEFT_CENTER, ox + 14, 42)



    -----------------------
    -- 资源按钮
    local button = cc.ui.UIPushButton.new(
        {normal = "player_btn_up_314x86.png", pressed = "player_btn_down_314x86.png"},
        {scale9 = false}
    ):onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            UIKit:newGameUI("GameUIResourceOverview",self.city):AddToCurrentScene(true)
        end
    end):addTo(top_bg):align(display.LEFT_CENTER, top_bg:getContentSize().width/2+2, top_bg:getContentSize().height/2+10)

    -- 资源图片和文字
    local first_row = 18
    local first_col = 18
    local label_padding = 15
    local padding_width = 100
    local padding_height = 35
    for i, v in ipairs({
        {"res_wood_82x73.png", "wood_label"},
        {"res_stone_88x82.png", "stone_label"},
        {"res_citizen_88x82.png", "citizen_label"},
        {"res_food_91x74.png", "food_label"},
        {"res_iron_91x63.png", "iron_label"},
        {"res_coin_81x68.png", "coin_label"},
    }) do
        local row = i > 3 and 1 or 0
        local col = (i - 1) % 3
        local x, y = first_col + col * padding_width, first_row - (row * padding_height)
        display.newSprite(v[1]):addTo(button):pos(x, y):scale(0.3)
        self[v[2]] = UIKit:ttfLabel({text = "",
            size = 18,
            color = 0xf3f0b6,
            shadow = true
        }):addTo(button):pos(x + label_padding, y)
    end

    -- 玩家信息背景
    local player_bg = display.newSprite("player_bg_110x106.png"):addTo(top_bg, 2)
        :align(display.LEFT_BOTTOM, display.width>640 and 58 or 64, 10):setCascadeOpacityEnabled(true)
    self.player_icon = UIKit:GetPlayerIconOnly(User:Icon()):addTo(player_bg):pos(55, 64):scale(0.72)
    -- self.exp = display.newSprite("player_exp_bar_110x106.png"):addTo(player_bg):pos(55, 53)
    self.exp = display.newProgressTimer("player_exp_bar_110x106.png", display.PROGRESS_TIMER_RADIAL):addTo(player_bg):pos(55, 53)
    self.exp:setRotationSkewY(180)
    self:RefreshExp()

    local level_bg = display.newSprite("level_bg_72x19.png"):addTo(player_bg):pos(55, 18):setCascadeOpacityEnabled(true)
    self.level_label = UIKit:ttfLabel({
        size = 14,
        color = 0xfff1cc,
        shadow = true,
    }):addTo(level_bg):align(display.CENTER, 37, 11)

    -- vip
    local vip_btn = cc.ui.UIPushButton.new(
        {},
        {scale9 = false}
    ):addTo(top_bg):align(display.CENTER, ox + 195, 50)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                UIKit:newGameUI('GameUIVip', City,"VIP"):AddToCurrentScene(true)
            end
        end)
    local vip_btn_img = User:IsVIPActived() and "vip_bg_110x124.png" or "vip_bg_disable_110x124.png"
    vip_btn:setButtonImage(cc.ui.UIPushButton.NORMAL, vip_btn_img, true)
    vip_btn:setButtonImage(cc.ui.UIPushButton.PRESSED, vip_btn_img, true)
    self.vip_level = display.newNode():addTo(vip_btn):pos(-3, 15):scale(0.8)
    self.vip_btn = vip_btn



    -- 金龙币按钮
    local button = cc.ui.UIPushButton.new(
        {normal = "gem_btn_up_196x68.png", pressed = "gem_btn_down_196x68.png"},
        {scale9 = false}
    ):onButtonClicked(function(event)
        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
    end):addTo(top_bg):pos(top_bg:getContentSize().width - 155, -16)
    display.newSprite("gem_icon_62x61.png"):addTo(button):pos(60, 3)
    self.gem_label = UIKit:ttfLabel({
        size = 20,
        color = 0xffd200,
        shadow = true
    }):addTo(button):align(display.CENTER, -30, 8)

    -- 任务条
    local quest_bar_bg = cc.ui.UIPushButton.new(
        {normal = "quest_btn_up_386x62.png", pressed = "quest_btn_down_386x62.png"},
        {scale9 = false}
    ):addTo(top_bg):pos(255, -10):onButtonClicked(function(event)
        if self.task then
            local building
            if self.task:BuildingType() == "tower" then
                building = self.city:GetNearGateTower()
            else
                building = self.city:GetHighestBuildingByType(self.task:BuildingType())
            end
            if building then
                local current_scene = display.getRunningScene()
                current_scene:GotoLogicPoint(building:GetMidLogicPosition())
                local building_sprite = current_scene:GetSceneLayer():FindBuildingSpriteByBuilding(building, self.city)
                current_scene:AddIndicateForBuilding(building_sprite)
            end
        end
    end)
    display.newSprite("quest_icon_27x42.png"):addTo(quest_bar_bg):pos(-162, 0)
    self.quest_label = cc.ui.UILabel.new({
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0xfffeb3)})
        :addTo(quest_bar_bg):align(display.LEFT_CENTER, -120, 0)


    -- 礼物按钮
    local button = cc.ui.UIPushButton.new(
        {normal = "activity_68x78.png"},
        {scale9 = false}
    ):onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            UIKit:newGameUI("GameUIActivity",City):AddToCurrentScene(true)
        end
    end):addTo(self):pos(display.left+40, display.top-200)
    local order = WidgetAutoOrder.new(WidgetAutoOrder.ORIENTATION.TOP_TO_BOTTOM,20):addTo(self):pos(display.right-50, display.top-200)
    -- BUFF按钮
    local buff_button = cc.ui.UIPushButton.new(
        {normal = "buff_68x68.png", pressed = "buff_68x68.png"}
    ):onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            UIKit:newGameUI("GameUIBuff",self.city):AddToCurrentScene(true)
        end
    end)
    function buff_button:CheckVisible()
        return true
    end
    function buff_button:GetElementSize()
        return buff_button:getCascadeBoundingBox().size
    end
    order:AddElement(buff_button)
    -- tips
    local button = cc.ui.UIPushButton.new(
        {normal = "tips_66x64.png", pressed = "tips_66x64.png"},
        {scale9 = false}
    )
    button:onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            UIKit:newGameUI("GameUITips",button,function ()
                order:RefreshOrder()
            end):AddToCurrentScene(true)
        end
    end)
    function button:CheckVisible()
        return not app:GetGameDefautlt():getBasicInfoValueForKey("NEVER_SHOW_TIP_ICON")
    end
    function button:GetElementSize()
        return button:getCascadeBoundingBox().size
    end
    order:AddElement(button)

    -- 协助加速按钮
    self.help_button = cc.ui.UIPushButton.new(
        {normal = "help_64x72.png", pressed = "help_64x72.png"},
        {scale9 = false}
    ):onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            if not Alliance_Manager:GetMyAlliance():IsDefault() then
                UIKit:newGameUI("GameUIHelp"):AddToCurrentScene(true)
            else
                UIKit:showMessageDialog(_("提示"),_("加入联盟才能激活帮助功能"))
            end
        end
    end)

    self.request_count = WidgetNumberTips.new():addTo(self.help_button):pos(20,-20)
    self.request_count:SetNumber(Alliance_Manager:GetMyAlliance():GetOtherRequestEventsNum())
    local help_button = self.help_button
    function help_button:CheckVisible()
        local alliance = Alliance_Manager:GetMyAlliance()
        return not alliance:IsDefault() and #alliance:GetCouldShowHelpEvents()>0
    end
    function help_button:GetElementSize()
        return help_button:getCascadeBoundingBox().size
    end
    order:AddElement(help_button)

    order:RefreshOrder()
    self.top_order_group = order
    return top_bg
end
function GameUIHome:CreateBottom()
    local bottom_bg = WidgetHomeBottom.new(self.city):addTo(self)
        :align(display.BOTTOM_CENTER, display.cx, display.bottom)

    self.chat = WidgetChat.new():addTo(bottom_bg)
        :align(display.CENTER, bottom_bg:getContentSize().width/2, bottom_bg:getContentSize().height-11)
    return bottom_bg
end
function GameUIHome:OnVipEventActive( vip_event )
    self:RefreshVIP()
end
function GameUIHome:OnVipEventOver( vip_event )
    self:RefreshVIP()
end
function GameUIHome:RefreshExp()
    local exp_config = GameDatas.PlayerInitData.playerLevel[User:Level()]
    local currentExp = User:LevelExp() - exp_config.expFrom
    local maxExp = exp_config.expTo - exp_config.expFrom
    self.exp:setPercentage(currentExp/maxExp*100)
end
function GameUIHome:RefreshVIP()
    local vip_btn = self.vip_btn
    local vip_btn_img = User:IsVIPActived() and "vip_bg_110x124.png" or "vip_bg_disable_110x124.png"
    vip_btn:setButtonImage(cc.ui.UIPushButton.NORMAL, vip_btn_img, true)
    vip_btn:setButtonImage(cc.ui.UIPushButton.PRESSED, vip_btn_img, true)
    local vip_level = self.vip_level
    vip_level:removeAllChildren()
    local level_img = display.newSprite(string.format("VIP_%d_46x32.png", User:GetVipLevel()),0,0,{class=cc.FilteredSpriteWithOne}):addTo(vip_level)
    if not User:IsVIPActived() then
        local my_filter = filter
        local filters = my_filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1})
        level_img:setFilter(filters)
    end
end

-- fte
function GameUIHome:DefferShow(tab_type)
    return self.event_tab:PromiseOfShowTab(tab_type):next(function() return self end)
end
function GameUIHome:Find()
    local item
    self.event_tab:IteratorAllItem(function(_, v)
        if v.GetSpeedUpButton then
            item = v:GetSpeedUpButton()
            return true
        end
    end)
    return cocos_promise.defer(function()
        if not item then
            promise.reject({code = -1, msg = "没有找到对应item"}, "")
        end
        return item
    end)
end

return GameUIHome















































