local cocos_promise = import("..utils.cocos_promise")
local promise = import("..utils.promise")
local window = import("..utils.window")
local WidgetLight = import("..widget.WidgetLight")
local WidgetChat = import("..widget.WidgetChat")
local WidgetNumberTips = import("..widget.WidgetNumberTips")
local WidgetHomeBottom = import("..widget.WidgetHomeBottom")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetEventTabButtons = import("..widget.WidgetEventTabButtons")
local SoldierManager = import("..entity.SoldierManager")
local WidgetAutoOrder = import("..widget.WidgetAutoOrder")
local UILib = import(".UILib")
local WidgetChangeMap = import("..widget.WidgetChangeMap")
local GameUIHelp = import(".GameUIHelp")
local Alliance = import("..entity.Alliance")
local ResourceManager = import("..entity.ResourceManager")
local GrowUpTaskManager = import("..entity.GrowUpTaskManager")
local GameUIActivityRewardNew = import(".GameUIActivityRewardNew")
local GameUIHome = UIKit:createUIClass('GameUIHome')
local WidgetAutoOrderAwardButton = import("..widget.WidgetAutoOrderAwardButton")
local WidgetAutoOrderGachaButton = import("..widget.WidgetAutoOrderGachaButton")
local WidgetAutoOrderBuffButton = import("..widget.WidgetAutoOrderBuffButton")
local light_gem = import("..particles.light_gem")
local fire_var = import("app.particles.fire_var")



local app = app
local timer = app.timer
local WOOD          = ResourceManager.RESOURCE_TYPE.WOOD
local FOOD          = ResourceManager.RESOURCE_TYPE.FOOD
local IRON          = ResourceManager.RESOURCE_TYPE.IRON
local COIN          = ResourceManager.RESOURCE_TYPE.COIN
local STONE         = ResourceManager.RESOURCE_TYPE.STONE
local CITIZEN       = ResourceManager.RESOURCE_TYPE.CITIZEN

local red_color = UIKit:hex2c4b(0xff3c00)
local normal_color = UIKit:hex2c4b(0xf3f0b6)

function GameUIHome:OnResourceChanged(resource_manager)
    local server_time = timer:GetServerTime()
    local allresources = resource_manager:GetAllResources()
    local wood_resource = allresources[WOOD]
    local food_resource = allresources[FOOD]
    local iron_resource = allresources[IRON]
    local stone_resource = allresources[STONE]
    local citizen_resource = allresources[CITIZEN]
    local coin_resource = allresources[COIN]
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
    self.wood_label:setColor(wood_resource:IsOverLimit() and red_color or normal_color)
    self.food_label:setColor(food_resource:IsOverLimit() and red_color or normal_color)
    self.iron_label:setColor(iron_resource:IsOverLimit() and red_color or normal_color)
    self.stone_label:setColor(stone_resource:IsOverLimit() and red_color or normal_color)
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
        self.quest_bar_bg:show()
        self.quest_label:setString(self.task:Title())
    else
        self.quest_bar_bg:hide()
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
    self:OnTaskChanged()
end
function GameUIHome:OnCountInfoChanged()
    self.join_alliance_tips_button:setVisible(not User:GetCountInfo().firstJoinAllianceRewardGeted)
    if self.join_alliance_tips_button:getChildByTag(321) and
        User:GetCountInfo().firstJoinAllianceRewardGeted then
        self.join_alliance_tips_button:removeChildByTag(321)
    end
    self.left_order_group:RefreshOrder()
    self.top_order_group:RefreshOrder()
    self:CheckAllianceRewardCount()
end
function GameUIHome:RefreshHelpButtonVisible()
    if self.help_button then
        self.top_order_group:RefreshOrder()
    end
end

function GameUIHome:DisplayOn()
    self.visible_count = self.visible_count + 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIHome:DisplayOff()
    self.visible_count = self.visible_count - 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIHome:FadeToSelf(isFullDisplay)
    self:stopAllActions()
    if isFullDisplay then
        self:show()
        transition.fadeIn(self, {
            time = 0.2,
        })
    else
        transition.fadeOut(self, {
            time = 0.2,
            onComplete = function()
                self:hide()
            end,
        })
    end
end

function GameUIHome:ctor(city)
    GameUIHome.super.ctor(self,{type = UIKit.UITYPE.BACKGROUND})
    self.city = city
end
function GameUIHome:onEnter()
    self.visible_count = 1
    local city = self.city
    -- 上背景
    self.top = self:CreateTop()
    self.bottom = self:CreateBottom()

    local ratio = self.bottom:getScale()
    self.event_tab = WidgetEventTabButtons.new(self.city, ratio)
    local rect1 = self.chat:getCascadeBoundingBox()
    local x, y = rect1.x, rect1.y + rect1.height - 2
    self.event_tab:addTo(self,0):pos(x, y)

    self:AddOrRemoveListener(true)
    self:OnResourceChanged(city:GetResourceManager())
    self:RefreshData()
    self:OnTaskChanged()
    self:RefreshHelpButtonVisible()
end
function GameUIHome:onExit()
    self:AddOrRemoveListener(false)
end
function GameUIHome:AddOrRemoveListener(isAdd)
    local city = self.city
    local user = self.city:GetUser()
    local my_allaince = Alliance_Manager:GetMyAlliance()
    local alliance_belvedere = my_allaince:GetAllianceBelvedere()
    if isAdd then
        city:AddListenOnType(self, city.LISTEN_TYPE.UPGRADE_BUILDING)
        city:AddListenOnType(self, city.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
        city:GetResourceManager():AddObserver(self)
        city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
        city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
        my_allaince:AddListenOnType(self, Alliance.LISTEN_TYPE.BASIC)
        my_allaince:AddListenOnType(self, Alliance.LISTEN_TYPE.HELP_EVENTS)
        my_allaince:AddListenOnType(self, Alliance.LISTEN_TYPE.ALL_HELP_EVENTS)
        my_allaince:AddListenOnType(self, Alliance.LISTEN_TYPE.OPERATION)
        user:AddListenOnType(self, user.LISTEN_TYPE.BASIC)
        user:AddListenOnType(self, user.LISTEN_TYPE.TASK)
        user:AddListenOnType(self, user.LISTEN_TYPE.VIP_EVENT_ACTIVE)
        user:AddListenOnType(self, user.LISTEN_TYPE.VIP_EVENT_OVER)
        user:AddListenOnType(self, user.LISTEN_TYPE.COUNT_INFO)
        user:AddListenOnType(self, user.LISTEN_TYPE.IAP_GIFTS_REFRESH)
        user:AddListenOnType(self, user.LISTEN_TYPE.IAP_GIFTS_CHANGE)
        alliance_belvedere:AddListenOnType(self, alliance_belvedere.LISTEN_TYPE.OnMarchDataChanged)
        alliance_belvedere:AddListenOnType(self, alliance_belvedere.LISTEN_TYPE.OnCommingDataChanged)
        my_allaince:GetAllianceShrine():AddListenOnType(self,my_allaince:GetAllianceShrine().LISTEN_TYPE.OnShrineEventsChanged)
    else
        city:RemoveListenerOnType(self,city.LISTEN_TYPE.UPGRADE_BUILDING)
        city:RemoveListenerOnType(self,city.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
        city:GetResourceManager():RemoveObserver(self)
        city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
        city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
        my_allaince:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.BASIC)
        my_allaince:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.HELP_EVENTS)
        my_allaince:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.ALL_HELP_EVENTS)
        my_allaince:RemoveListenerOnType(self, Alliance.LISTEN_TYPE.OPERATION)
        user:RemoveListenerOnType(self, user.LISTEN_TYPE.BASIC)
        user:RemoveListenerOnType(self, user.LISTEN_TYPE.TASK)
        user:RemoveListenerOnType(self, user.LISTEN_TYPE.VIP_EVENT_ACTIVE)
        user:RemoveListenerOnType(self, user.LISTEN_TYPE.VIP_EVENT_OVER)
        user:RemoveListenerOnType(self, user.LISTEN_TYPE.COUNT_INFO)
        user:RemoveListenerOnType(self, user.LISTEN_TYPE.IAP_GIFTS_REFRESH)
        user:RemoveListenerOnType(self, user.LISTEN_TYPE.IAP_GIFTS_CHANGE)
        alliance_belvedere:RemoveListenerOnType(self, alliance_belvedere.LISTEN_TYPE.OnMarchDataChanged)
        alliance_belvedere:RemoveListenerOnType(self, alliance_belvedere.LISTEN_TYPE.OnCommingDataChanged)
        my_allaince:GetAllianceShrine():RemoveListenerOnType(self,my_allaince:GetAllianceShrine().LISTEN_TYPE.OnShrineEventsChanged)
    end
end
function GameUIHome:OnShrineEventsChanged(changed_map)
    self.right_bottom_order:RefreshOrder()
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
            UIKit:newGameUI('GameUIVip', self.city,"info"):AddToCurrentScene(true)
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
    display.newSprite("dragon_strength_27x31.png"):addTo(top_bg):pos(ox + 20, 65):scale(16/27)

    -- 玩家战斗值文字
    UIKit:ttfLabel({
        text = _("战斗力："),
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

    self.shadow_power_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color = 0xf3f0b6,
        shadow = true
    }):addTo(top_bg):align(display.LEFT_CENTER, ox + 14, 42):hide()

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
    self.res_icon_map = {}
    local first_row = 18
    local first_col = 18
    local label_padding = 15
    local padding_width = 100
    local padding_height = 35
    for i, v in ipairs({
        {"res_wood_82x73.png", "wood_label", "wood"},
        {"res_stone_88x82.png", "stone_label", "stone"},
        {"res_citizen_88x82.png", "citizen_label", "citizen"},
        {"res_food_91x74.png", "food_label", "food"},
        {"res_iron_91x63.png", "iron_label", "iron"},
        {"res_coin_81x68.png", "coin_label", "coin"},
    }) do
        local row = i > 3 and 1 or 0
        local col = (i - 1) % 3
        local x, y = first_col + col * padding_width, first_row - (row * padding_height)
        self.res_icon_map[v[3]] = display.newSprite(v[1]):addTo(button):pos(x, y):scale(0.3)

        self[v[2]] = UIKit:ttfLabel({text = "",
            size = 18,
            color = 0xf3f0b6,
            shadow = true
        }):addTo(button):pos(x + label_padding, y)
    end

    -- 玩家信息背景
    local player_bg = display.newSprite("player_info_bg_120x120.png")
        :align(display.LEFT_BOTTOM, display.width>640 and 58 or 60, 10)
        :addTo(top_bg, 2):scale(106/120):setCascadeOpacityEnabled(true)
    self.player_icon = UIKit:GetPlayerIconOnly(User:Icon())
        :addTo(player_bg):pos(60, 68):scale(0.78)
    self.exp = display.newProgressTimer("player_exp_bar_110x106.png",
        display.PROGRESS_TIMER_RADIAL):addTo(player_bg):pos(60, 58):scale(1.15)
    self.exp:setRotationSkewY(180)
    self:RefreshExp()

    local level_bg = display.newSprite("level_bg_72x19.png"):addTo(player_bg):pos(55, 18):setCascadeOpacityEnabled(true)
    self.level_label = UIKit:ttfLabel({
        text = "",
        size = 14,
        color = 0xfff1cc,
        shadow = true,
    }):addTo(level_bg):align(display.CENTER, 37, 11)

    -- vip
    local vip_btn = cc.ui.UIPushButton.new(
        {},
        {scale9 = false}
    ):addTo(top_bg):align(display.CENTER, ox + 195, 65)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                UIKit:newGameUI('GameUIVip', self.city,"VIP"):AddToCurrentScene(true)
            end
        end)
    local vip_btn_img = User:IsVIPActived() and "vip_bg_110x124.png" or "vip_bg_disable_110x124.png"
    vip_btn:setButtonImage(cc.ui.UIPushButton.NORMAL, vip_btn_img, true)
    vip_btn:setButtonImage(cc.ui.UIPushButton.PRESSED, vip_btn_img, true)
    self.vip_level = display.newNode():addTo(vip_btn):pos(-3, 0):scale(0.8)
    self.vip_btn = vip_btn



    -- 金龙币按钮

    local button = cc.ui.UIPushButton.new(
        {normal = "gem_btn_up_196x68.png", pressed = "gem_btn_down_196x68.png"},
        {scale9 = false}
    ):onButtonClicked(function(event)
        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
    end):addTo(top_bg):pos(top_bg:getContentSize().width - 155, -16)
    local gem_icon = display.newSprite("gem_icon_62x61.png"):addTo(button):pos(60, 3)
    light_gem():addTo(gem_icon, 1022):pos(62/2, 61/2)

    self.gem_label = UIKit:ttfLabel({
        size = 20,
        color = 0xffd200,
    }):addTo(button):align(display.CENTER, -30, 8)

    -- 任务条
    local quest_bar_bg = cc.ui.UIPushButton.new(
        {normal = "quest_btn_up_386x62.png", pressed = "quest_btn_down_386x62.png"},
        {scale9 = false}
    ):addTo(top_bg):pos(255, -10):onButtonClicked(function(event)
        if self.task then
            if self.task:TaskType() == "cityBuild" then
                self:GotoOpenBuildingUI(self.city:PreconditionByBuildingType(self.task:BuildingType()))
            elseif self.task:TaskType() == "unlock" then
                self:GotoUnlockBuilding(self.task:Location())
            elseif self.task:TaskType() == "reward" then
                UIKit:newGameUI("GameUIMission", self.city, nil, true):AddToCurrentScene(true)
            elseif self.task:TaskType() == "productionTech" then
                UIKit:newGameUI("GameUIQuickTechnology", self.city, self.task.name):AddToCurrentScene(true)
            elseif self.task:TaskType() == "recruit" then
                UIKit:newGameUI('GameUIBarracks', self.city, self.city:GetFirstBuildingByType("barracks"), "recruit", self.task.name):AddToCurrentScene(true)
            elseif self.task:TaskType() == "explore" then
                self:GotoExplore()
            elseif self.task:TaskType() == "build" then
                self:GotoOpenBuildUI(self.task)
            elseif self.task:TaskType() == "encourage" then
                UIKit:newGameUI("GameUIActivityRewardNew", GameUIActivityRewardNew.REWARD_TYPE.PLAYER_LEVEL_UP):AddToCurrentScene(true)
            end
        end
    end)
    self.quest_bar_bg = quest_bar_bg
    display.newSprite("quest_icon_27x42.png"):addTo(quest_bar_bg):pos(-162, 0)
    self.quest_label = UIKit:ttfLabel({
        size = 20,
        color = 0xfffeb3,
    }):addTo(quest_bar_bg):align(display.LEFT_CENTER, -120, 0)

    local left_order =  WidgetAutoOrder.new(WidgetAutoOrder.ORIENTATION.TOP_TO_BOTTOM,50):addTo(self):pos(display.left+40, display.top-200)
    -- 活动按钮
    local button = cc.ui.UIPushButton.new(
        {normal = "tips_66x64.png", pressed = "tips_66x64.png"},
        {scale9 = false}
    )
    WidgetLight.new():addTo(button, -1001):scale(0.6)
    button:onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            UIKit:newGameUI("GameUIActivityNew",self.city):AddToCurrentScene(true)
        end
    end)
    function button:CheckVisible()
        return true
    end
    function button:GetElementSize()
        return {width = 66,height = 64}
    end
    left_order:AddElement(button)
    button.tips_button_count = WidgetNumberTips.new():addTo(button):pos(20,-20)
    local award_num = 0

    if User:HaveEveryDayLoginReward() then
        award_num = award_num + 1
    end
    if User:HaveContinutyReward() then
        award_num = award_num + 1
    end
    if User:HavePlayerLevelUpReward() then
        award_num = award_num + 1
    end
    button.tips_button_count:SetNumber(LuaUtils:table_size(User:GetIapGifts()) + award_num)
    self.tips_button = button
    --在线活动
    local activity_button = WidgetAutoOrderAwardButton.new(self)
    left_order:AddElement(activity_button)



    if not self.city:GetDragonEyrie():GetDragonManager():IsAllHated() then
        local this = self
        local dragon_egg_btn = UIKit:ButtonAddScaleAction(cc.ui.UIPushButton.new(
            {normal = "dragon_eggs_68x80.png", pressed = "dragon_eggs_68x80.png"}
        ):onButtonClicked(function(event)
            if not event.target:CheckVisible() then
                event.target:hide()
            else
                local dragon = this.city:GetDragonEyrie():GetDragonManager():GetEnableHatedDragon()
                if dragon then
                    UIKit:newGameUI("GameUIDragonEyrieMain", self.city, self.city:GetFirstBuildingByType("dragonEyrie"), "dragon", false, dragon:Type()):AddToCurrentScene(true)
                end
            end
        end))
        function dragon_egg_btn:CheckVisible()
            return this.city:GetDragonEyrie():GetDragonManager():IsHateEnable()
        end
        function dragon_egg_btn:GetElementSize()
            return {width = 68,height = 80}
        end
        dragon_egg_btn:schedule(function()
            local old_visible = dragon_egg_btn:isVisible()
            local cur_visible = dragon_egg_btn:CheckVisible()
            if old_visible ~= cur_visible then
                dragon_egg_btn:setVisible(cur_visible)
                left_order:RefreshOrder()
            end
        end, 1)
        self.dragon_egg_btn = dragon_egg_btn
        left_order:AddElement(dragon_egg_btn)
    end
    left_order:RefreshOrder()


    local order = WidgetAutoOrder.new(WidgetAutoOrder.ORIENTATION.TOP_TO_BOTTOM,50):addTo(self):pos(display.right-50, display.top-200)
    -- BUFF按钮
    local buff_button = WidgetAutoOrderBuffButton.new(self)
    order:AddElement(buff_button)


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

    -- gacha button
    local gacha_button = WidgetAutoOrderGachaButton.new(self)
    order:AddElement(gacha_button)

    order:RefreshOrder()
    self.top_order_group = order
    self.left_order_group = left_order



    --联盟提示按钮
    self.join_alliance_tips_button = cc.ui.UIPushButton.new({normal = 'alliance_join_tips_79x83.png'}):pos(display.left+40, display.top-600):addTo(self)
        :onButtonClicked(function()
            UIKit:newGameUI("GameUIAllianceJoinTips"):AddToCurrentScene(true)
        end)
    self.join_alliance_tips_button:setVisible(not User:GetCountInfo().firstJoinAllianceRewardGeted)
    if self.join_alliance_tips_button:isVisible() then
        fire_var():addTo(self.join_alliance_tips_button, -1000, 321)
    end

    local right_bottom_order = WidgetAutoOrder.new(WidgetAutoOrder.ORIENTATION.BOTTOM_TO_TOP,50):addTo(self):pos(display.right-50, display.top-600)
    --瞭望塔事件按钮
    local alliance_belvedere_button = cc.ui.UIPushButton.new({normal = 'fight_62x70.png'})
    alliance_belvedere_button.alliance_belvedere_events_count = WidgetNumberTips.new():addTo(alliance_belvedere_button):pos(20,-20)
    alliance_belvedere_button:onButtonClicked(function()
        local default_tab = 'march'
        local alliance = Alliance_Manager:GetMyAlliance()
        local alliance_belvedere = alliance:GetAllianceBelvedere()
        local hasMarch,__ = alliance_belvedere:HasMyEvents()
        if not hasMarch then
            local hasComming,__ = alliance_belvedere:HasOtherEvents()
            if hasComming then
                default_tab = 'comming'
            end
        end
        UIKit:newGameUI('GameUIWathTowerRegion',self.city,default_tab):AddToCurrentScene(true)
    end)
    function alliance_belvedere_button:CheckVisible()
        local alliance = Alliance_Manager:GetMyAlliance()
        local alliance_belvedere = alliance:GetAllianceBelvedere()
        local hasEvent,count = alliance_belvedere:HasEvents()
        alliance_belvedere_button.alliance_belvedere_events_count:SetNumber(count)
        return hasEvent
    end
    function alliance_belvedere_button:GetElementSize()
        return alliance_belvedere_button:getCascadeBoundingBox().size
    end
    right_bottom_order:AddElement(alliance_belvedere_button)

    -- 圣地时间按钮
    local shrine_event_button = cc.ui.UIPushButton.new({normal = 'tmp_btn_shrine_72x72.png'})
    shrine_event_button:onButtonClicked(function()
        local buildings = Alliance_Manager:GetMyAlliance():GetAllianceMap():GetMapObjectsByType("building")
        local shrine_info
        for k,v in pairs(buildings) do
            if v.name == "shrine" then
                shrine_info = v
            end
        end
        UIKit:newGameUI("GameUIAllianceShrine",self.city,"fight_event",shrine_info:GetAllianceBuildingInfo()):AddToCurrentScene(true)
    end)
    function shrine_event_button:CheckVisible()
        local alliance = Alliance_Manager:GetMyAlliance()
        print("shrine_event_button:CheckVisible()",alliance:GetAllianceShrine():HaveEvent())
        return alliance:GetAllianceShrine():HaveEvent()
    end
    function shrine_event_button:GetElementSize()
        return shrine_event_button:getCascadeBoundingBox().size
    end
    right_bottom_order:AddElement(shrine_event_button)


    right_bottom_order:RefreshOrder()
    self.right_bottom_order = right_bottom_order
    return top_bg
end
function GameUIHome:GotoUnlockBuilding(location_id)
    self:GotoOpenBuildingUI(self.city:GetBuildingByLocationId(location_id))
end
function GameUIHome:GotoOpenBuildUI(task)
    for i,v in ipairs(self.city:GetDecoratorsByType(task.name)) do
        local location_id = self.city:GetLocationIdByBuilding(v)
        local houses = self.city:GetDecoratorsByLocationId(location_id)
        for i = 3, 1, -1 do
            if not houses[i] then
                self:GotoOpenBuildingUI(self.city:GetRuinByLocationIdAndHouseLocationId(location_id, i), task.name)
                return
            end
        end
    end
    self:GotoOpenBuildingUI(self.city:GetRuinsNotBeenOccupied()[1], task.name)
end
function GameUIHome:GotoOpenBuildingUI(building, build_name)
    if not building then return end
    local current_scene = display.getRunningScene()
    local building_sprite = current_scene:GetSceneLayer():FindBuildingSpriteByBuilding(building, self.city)
    local x,y = building:GetMidLogicPosition()
    current_scene:GotoLogicPoint(x,y,40):next(function()
        current_scene:AddIndicateForBuilding(building_sprite, build_name)
    end)
end
function GameUIHome:GotoExplore()
    local current_scene = display.getRunningScene()
    local building_sprite = current_scene:GetSceneLayer():GetAirship()
    current_scene:GotoLogicPoint(-2,10,40):next(function()
        current_scene:AddIndicateForBuilding(building_sprite)
    end)
end

function GameUIHome:CheckFinishAllActivity()

end

function GameUIHome:CheckAllianceRewardCount()
    if not self.tips_button then return end
    local count = LuaUtils:table_size(User:GetIapGifts())
    print("CheckAllianceRewardCount----->",count)
    local award_num = 0

    if User:HaveEveryDayLoginReward() then
        award_num = award_num + 1
    end
    if User:HaveContinutyReward() then
        award_num = award_num + 1
    end
    if User:HavePlayerLevelUpReward() then
        award_num = award_num + 1
    end
    self.tips_button.tips_button_count:SetNumber(count + award_num)
    self:OnTaskChanged()
end


function GameUIHome:OnIapGiftsRefresh()
    self:CheckAllianceRewardCount()
end

function GameUIHome:OnIapGiftsChanged(changed_map)
    self:CheckAllianceRewardCount()
end

function GameUIHome:OnMarchDataChanged()
    self:RefreshAllianceBelvedereButton()
end
function GameUIHome:OnCommingDataChanged()
    self:RefreshAllianceBelvedereButton()
end

function GameUIHome:RefreshAllianceBelvedereButton()
    self.right_bottom_order:RefreshOrder()
end

function GameUIHome:CreateBottom()
    local bottom_bg = WidgetHomeBottom.new(self.city):addTo(self, 1)
        :align(display.BOTTOM_CENTER, display.cx, display.bottom)

    self.chat = WidgetChat.new():addTo(bottom_bg)
        :align(display.CENTER, bottom_bg:getContentSize().width/2, bottom_bg:getContentSize().height-11)

    self.change_map = WidgetChangeMap.new(WidgetChangeMap.MAP_TYPE.OUR_CITY):addTo(self, 1)

    return bottom_bg
end
function GameUIHome:ChangeChatChannel(channel_index)
    self.chat:ChangeChannel(channel_index)
end
function GameUIHome:OnVipEventActive( vip_event )
    self.top_order_group:RefreshOrder()
    self:RefreshVIP()
end
function GameUIHome:OnVipEventOver( vip_event )
    self.top_order_group:RefreshOrder()
    self:RefreshVIP()
end
function GameUIHome:OnOperation(alliance,operation_type)
    if operation_type == "quit" then
        self.top_order_group:RefreshOrder()
        self.right_bottom_order:RefreshOrder()
    end
end
function GameUIHome:RefreshExp()
    local current_level = User:GetPlayerLevelByExp(User:LevelExp())
    self.exp:setPercentage( (User:LevelExp() - User:GetCurrentLevelExp(current_level))/(User:GetCurrentLevelMaxExp(current_level) - User:GetCurrentLevelExp(current_level)) * 100)
end
function GameUIHome:RefreshVIP()
    local vip_btn = self.vip_btn
    local vip_btn_img = User:IsVIPActived() and "vip_bg_110x124.png" or "vip_bg_disable_110x124.png"
    vip_btn:setButtonImage(cc.ui.UIPushButton.NORMAL, vip_btn_img, true)
    vip_btn:setButtonImage(cc.ui.UIPushButton.PRESSED, vip_btn_img, true)
    local vip_level = self.vip_level
    vip_level:removeAllChildren()
    local level_img = display.newSprite(string.format("VIP_%d_46x32.png", User:GetVipLevel()),5,0,{class=cc.FilteredSpriteWithOne}):addTo(vip_level)
    if not User:IsVIPActived() then
        local my_filter = filter
        local filters = my_filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1})
        level_img:setFilter(filters)
    end
end
local POWER_ANI_TAG = 1001
function GameUIHome:ShowPowerAni(wp, old_power)
    local pnt = self.top
    self.power_label:hide()
    self.shadow_power_label:show():setString(string.formatnumberthousands(old_power))

    pnt:removeChildByTag(POWER_ANI_TAG)
    local tp = pnt:convertToNodeSpace(self.power_label:convertToWorldSpace(cc.p(0,0)))
    local lp = pnt:convertToNodeSpace(wp)
    local time, delay_time = 1, 0.25
    local emitter = cc.ParticleFlower:createWithTotalParticles(200)
        :addTo(pnt, 100, POWER_ANI_TAG):pos(lp.x, lp.y)
    emitter:setDuration(time + delay_time)
    emitter:setLife(1)
    emitter:setLifeVar(1)
    emitter:setStartColor(cc.c4f(1.0,0.84,0.48,1.0))
    emitter:setStartColorVar(cc.c4f(0.0))
    emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("stars.png"))
    emitter:runAction(transition.sequence{
        cc.MoveTo:create(time, cc.p(tp.x, tp.y)),
        cc.CallFunc:create(function()
            self:ScaleIcon(self.power_label:show())
            self.shadow_power_label:hide()
        end),
        cc.DelayTime:create(delay_time),
    })
end
local RES_ICON_TAG = {
    food = 1010,
    wood = 1011,
    iron = 1012,
    coin = 1013,
    stone = 1014,
    citizen = 1015,
}
local icon_map = {
    food = "res_food_91x74.png",
    wood = "res_wood_82x73.png",
    iron = "res_iron_91x63.png",
    coin = "res_coin_81x68.png",
    stone = "res_stone_88x82.png",
    citizen = "res_citizen_88x82.png",
}
function GameUIHome:ShowResourceAni(resource)
    local pnt = self.top
    pnt:removeChildByTag(RES_ICON_TAG[resource])

    local s1 = self.res_icon_map[resource]:getContentSize()
    local tp = pnt:convertToNodeSpace(self.res_icon_map[resource]:convertToWorldSpace(cc.p(s1.width/2,s1.height/2)))
    local lp = pnt:convertToNodeSpace(cc.p(display.cx, display.cy))

    local x,y,tx,ty = lp.x,lp.y,tp.x, tp.y
    local icon = display.newSprite(icon_map[resource])
        :addTo(pnt):pos(x,y):scale(0.8)

    local size = icon:getContentSize()
    local emitter = cc.ParticleFlower:createWithTotalParticles(200)
        :addTo(icon):pos(size.width/2, size.height/2)

    local time = 1
    emitter:setPosVar(cc.p(10,10))
    emitter:setDuration(time)
    emitter:setCascadeOpacityEnabled(true)
    emitter:setLife(1)
    emitter:setLifeVar(1)
    emitter:setStartColor(cc.c4f(1.0))
    emitter:setStartColorVar(cc.c4f(0.0))
    emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("stars.png"))


    local bezier2 ={
        cc.p(x,y),
        cc.p((x + tx) * 0.5 + math.random(200) - 100, (y + ty) * 0.5),
        cc.p(tx, ty)
    }
    icon:runAction(
        cc.Spawn:create({
            cc.ScaleTo:create(time, 0.3),
            transition.sequence{
                cc.BezierTo:create(time, bezier2),
                cc.CallFunc:create(function()
                    icon:opacity(0)
                    self:ScaleIcon(self.res_icon_map[resource], 0.3, 0.5)
                end),
                cc.DelayTime:create(1),
                cc.RemoveSelf:create(),
            }
        })
    )
end
function GameUIHome:ScaleIcon(ccnode, s, ds)
    local s = s or 1
    local ds = ds or 0.1
    ccnode:runAction(transition.sequence{
        cc.ScaleTo:create(0.2, s * (1 + ds)),
        cc.ScaleTo:create(0.2, s),
    })
end

-- fte
local mockData = import("..fte.mockData")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local WidgetFteMark = import("..widget.WidgetFteMark")
function GameUIHome:Find()
    local item
    self.event_tab:IteratorAllItem(function(_, v)
        if v.GetSpeedUpButton then
            item = v:GetSpeedUpButton()
            return true
        end
    end)
    return item
end
function GameUIHome:FindVip()
    return self.vip_btn
end
function GameUIHome:PromiseOfFteWaitFinish()
    if #self.city:GetUpgradingBuildings() > 0 then
        if not self.event_tab:IsShow() then
            self.event_tab:EventChangeOn("build", true)
        end
        self:GetFteLayer()
        return self.city:PromiseOfFinishUpgradingByLevel(nil, nil)
            :next(function()self:GetFteLayer():Reset()end)
            :next(cocos_promise.delay(1))
            :next(function()self:GetFteLayer():removeFromParent()end)
    end
    return cocos_promise.defer()
end
function GameUIHome:PromiseOfFteFreeSpeedUp()
    if #self.city:GetUpgradingBuildings() > 0 then
        if not self.event_tab:IsShow() then
            self.event_tab:EventChangeOn("build", true)
        end
        self:GetFteLayer()
        self.event_tab:PromiseOfPopUp():next(function()
            self:GetFteLayer():SetTouchObject(self:Find())
            self:Find():removeEventListenersByEvent("CLICKED_EVENT")
            self:Find():onButtonClicked(function()
                self:Find():setButtonEnabled(false)

                local building = self:GetBuilding()
                if building then
                    if building:IsHouse() then
                        mockData.FinishBuildHouseAt(self:GetBuildingLocation(), building:GetNextLevel())
                    else
                        mockData.FinishUpgradingBuilding(building:GetType(), building:GetNextLevel())
                    end
                end
            end)

            local r = self:Find():getCascadeBoundingBox()
            WidgetFteArrow.new(_("5分钟以下免费加速")):addTo(self:GetFteLayer())
                :TurnDown(true):align(display.RIGHT_BOTTOM, r.x + r.width/2 + 30, r.y + 50)
        end)

        return self.city:PromiseOfFinishUpgradingByLevel(nil, nil)
            :next(function()
                self:GetFteLayer():removeFromParent()
                self:GetFteLayer()
            end)
            :next(cocos_promise.delay(1))
            :next(function()self:GetFteLayer():removeFromParent()end)
    end
    return cocos_promise.defer()
end
function GameUIHome:PromiseOfFteInstantSpeedUp()
    if #self.city:GetUpgradingBuildings() > 0 then
        if not self.event_tab:IsShow() then
            self.event_tab:EventChangeOn("build", true)
        end
        self:GetFteLayer()
        self.event_tab:PromiseOfPopUp():next(function()
            self:GetFteLayer():SetTouchObject(self:Find())

            self:Find():removeEventListenersByEvent("CLICKED_EVENT")
            self:Find():onButtonClicked(function()
                self:Find():setButtonEnabled(false)

                local building = self:GetBuilding()
                if building then
                    if building:IsHouse() then
                        mockData.FinishBuildHouseAt(self:GetBuildingLocation(), building:GetNextLevel())
                    else
                        mockData.FinishUpgradingBuilding(building:GetType(), building:GetNextLevel())
                    end
                end

            end)

            local r = self:Find():getCascadeBoundingBox()
            WidgetFteArrow.new(_("立即完成升级"))
                :addTo(self:GetFteLayer()):TurnDown(true)
                :align(display.RIGHT_BOTTOM, r.x + r.width/2 + 30, r.y + 50)

        end)

        return self.city:PromiseOfFinishUpgradingByLevel()
            :next(function()
                self:GetFteLayer():removeFromParent()
                self:GetFteLayer()
            end)
            :next(cocos_promise.delay(1))
            :next(function()self:GetFteLayer():removeFromParent()end)
    end
    return cocos_promise.defer()
end
function GameUIHome:GetBuildingLocation()
    local building = self.city:GetUpgradingBuildings()[1]
    assert(building)
    local x,y = building:GetLogicPosition()
    local tile = self.city:GetTileByBuildingPosition(x, y)
    return tile.location_id
end
function GameUIHome:GetBuilding()
    local building = self.city:GetUpgradingBuildings()[1]
    assert(building)
    return building
end
function GameUIHome:PromiseOfActivePromise()
    self:GetFteLayer():SetTouchObject(self:FindVip())
    local r = self:FindVip():getCascadeBoundingBox()

    WidgetFteArrow.new(_("点击VIP，免费激活VIP")):addTo(self:GetFteLayer())
        :TurnUp():align(display.TOP_CENTER, r.x + r.width/2, r.y)

    return UIKit:PromiseOfOpen("GameUIVip"):next(function(ui)
        self:GetFteLayer():removeFromParent()
        return ui:PromiseOfFte()
    end)
end
function GameUIHome:PromiseOfFteAlliance()
    self.bottom:TipsOnAlliance()
end
function GameUIHome:PromiseOfFteAllianceMap()
    local btn = self.change_map.btn
    btn:removeChildByTag(102)

    WidgetFteArrow.new(_("进入联盟地图\n体验更多玩法")):addTo(btn, 10, 102)
        :TurnDown(false):align(display.LEFT_BOTTOM, 20, 55)

    btn:stopAllActions()
    btn:performWithDelay(function() btn:removeChildByTag(102) end, 10)
end


return GameUIHome





