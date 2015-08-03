local ResourceManager = import('..entity.ResourceManager')
local SoldierManager = import('..entity.SoldierManager')
local WidgetUseItems= import(".WidgetUseItems")
local WidgetUIBackGround= import(".WidgetUIBackGround")
local WidgetPushButton = import('.WidgetPushButton')
local UIListView = import("..ui.UIListView")
local resource_type = {
    WOOD = ResourceManager.RESOURCE_TYPE.WOOD,
    FOOD = ResourceManager.RESOURCE_TYPE.FOOD,
    IRON = ResourceManager.RESOURCE_TYPE.IRON,
    STONE = ResourceManager.RESOURCE_TYPE.STONE,
    COIN = ResourceManager.RESOURCE_TYPE.COIN
}
local WidgetResources = class("WidgetResources", function ()
    return display.newLayer()
end)

function WidgetResources:ctor()
    self:setNodeEventEnabled(true)
    self.city = City
    self.building = self.city:GetFirstBuildingByType("warehouse")
end
function WidgetResources:onEnter()
    self:CreateResourceListView()
    self:InitAllResources()
    self.city:GetResourceManager():AddObserver(self)
    self.city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_CHANGED)
    local user = self.city:GetUser()
    user:AddListenOnType(self, user.LISTEN_TYPE.VIP_EVENT_ACTIVE)
    user:AddListenOnType(self, user.LISTEN_TYPE.VIP_EVENT_OVER)
    ItemManager:AddListenOnType(self,ItemManager.LISTEN_TYPE.ITEM_EVENT_CHANGED)
    local resourceBuildingMap = {
        wood = "lumbermill",
        stone = "stoneMason",
        iron = "foundry",
        food = "mill"
    }
    for k,v in pairs(resourceBuildingMap) do
        self.city:GetFirstBuildingByType(v):AddUpgradeListener(self)
    end
end
function WidgetResources:onExit()
    self.city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_CHANGED)
    self.city:GetResourceManager():RemoveObserver(self)
    local user = self.city:GetUser()
    user:RemoveListenerOnType(self, user.LISTEN_TYPE.VIP_EVENT_ACTIVE)
    user:RemoveListenerOnType(self, user.LISTEN_TYPE.VIP_EVENT_OVER)
    ItemManager:RemoveListenerOnType(self,ItemManager.LISTEN_TYPE.ITEM_EVENT_CHANGED)
    local resourceBuildingMap = {
        wood = "lumbermill",
        stone = "stoneMason",
        iron = "foundry",
        food = "mill"
    }
    for k,v in pairs(resourceBuildingMap) do
        self.city:GetFirstBuildingByType(v):RemoveUpgradeListener(self)
    end
end
function WidgetResources:OnItemEventChanged()
    self:RefreshProtectPercent()
end
function WidgetResources:OnBuildingUpgradingBegin( bulding )
end
function WidgetResources:OnBuildingUpgrading( bulding )
end
function WidgetResources:OnBuildingUpgradeFinished( bulding )
    self:RefreshProtectPercent()
end
function WidgetResources:OnVipEventActive( vip_event )
    self:RefreshProtectPercent()
end
function WidgetResources:OnVipEventOver( vip_event )
    self:RefreshProtectPercent()
end
function WidgetResources:OnSoliderCountChanged(...)
    self.maintenance_cost.value:setString("-"..GameUtils:formatNumber(self.city:GetSoldierManager():GetTotalUpkeep()).."/h")
end
function WidgetResources:RefreshProtectPercent()
    if self.resource_items then
        for k,v in pairs(self.resource_items) do
            if v.protectPro then
                local p = DataUtils:GetResourceProtectPercent(v.type) * 100
                v.protectPro:setPercentage(18)
                v.protectPro:setPercentage(math.min(v.r_percent,p))
            end
        end
    end
end
-- 资源刷新
function WidgetResources:OnResourceChanged(resource_manager)
    local maxwood, maxfood, maxiron, maxstone = self.building:GetResourceValueLimit()
    local resource_max = {
        [ResourceManager.RESOURCE_TYPE.WOOD] = maxwood,
        [ResourceManager.RESOURCE_TYPE.FOOD] = maxfood,
        [ResourceManager.RESOURCE_TYPE.IRON] = maxiron,
        [ResourceManager.RESOURCE_TYPE.STONE] = maxstone,
    }
    if self.resource_items then
        for k,v in pairs(self.resource_items) do
            self:RefreshSpecifyResource(resource_manager:GetResourceByType(k),v,resource_max[k],City:GetCitizenByType(City.RESOURCE_TYPE_TO_BUILDING_TYPE[k]), k)
        end
    end
    self:RefreshProtectPercent()
end

local FOOD = ResourceManager.RESOURCE_TYPE.FOOD
function WidgetResources:RefreshSpecifyResource(resource,item,maxvalue,occupy_citizen, type_)
    if maxvalue then
        item.r_percent = math.floor(resource:GetResourceValueByCurrentTime(app.timer:GetServerTime())/maxvalue*100)
        item.ProgressTimer:setPercentage(item.r_percent)
        item.resource_label:setString(GameUtils:formatNumber(resource:GetResourceValueByCurrentTime(app.timer:GetServerTime())).."/"..GameUtils:formatNumber(maxvalue))
        if type_ == FOOD then
            item.produce_capacity.value:setString(GameUtils:formatNumber(self.city:GetResourceManager():GetFoodProductionPerHour()) .."/h")
        else
            item.produce_capacity.value:setString(GameUtils:formatNumber(resource:GetProductionPerHour()).."/h")
        end
        item.occupy_citizen.value:setString(GameUtils:formatNumber(occupy_citizen).."")
    else
        item.resource_label.value:setString(GameUtils:formatNumber(resource:GetResourceValueByCurrentTime(app.timer:GetServerTime())))
    end
end
function WidgetResources:CreateResourceListView()
    self.resource_listview = UIListView.new{
        bgScale9 = true,
        viewRect = cc.rect(display.cx-284, display.top-860, 568, 780),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL}
        :addTo(self)
end

function WidgetResources:InitAllResources()
    local current_time = app.timer:GetServerTime()
    local maxwood, maxfood, maxiron, maxstone = self.building:GetResourceValueLimit()
    local crm = City:GetResourceManager()
    local all_resources = {
        food = {
            resource_icon="res_food_91x74.png",
            resource_limit_value = maxfood,
            resource_current_value=crm:GetFoodResource():GetResourceValueByCurrentTime(current_time),
            total_income=GameUtils:formatNumber(crm:GetFoodProductionPerHour()).."/h",
            occupy_citizen=GameUtils:formatNumber(City:GetCitizenByType("farmer")),
            maintenance_cost="-"..GameUtils:formatNumber(self.city:GetSoldierManager():GetTotalUpkeep()).."/h",
            type = "food"
        },
        wood = {
            resource_icon="res_wood_82x73.png",
            resource_limit_value= maxwood,
            resource_current_value=crm:GetWoodResource():GetResourceValueByCurrentTime(current_time),
            total_income=GameUtils:formatNumber(crm:GetWoodResource():GetProductionPerHour()).."/h",
            occupy_citizen=GameUtils:formatNumber(City:GetCitizenByType("woodcutter")),
            type = "wood"
        },
        stone = {
            resource_icon="res_stone_88x82.png",
            resource_limit_value= maxstone,
            resource_current_value=crm:GetStoneResource():GetResourceValueByCurrentTime(current_time),
            total_income=GameUtils:formatNumber(crm:GetStoneResource():GetProductionPerHour()).."/h",
            occupy_citizen=GameUtils:formatNumber(City:GetCitizenByType("quarrier")),
            type = "stone"
        },
        iron = {
            resource_icon="res_iron_91x63.png",
            resource_limit_value=maxiron,
            resource_current_value=crm:GetIronResource():GetResourceValueByCurrentTime(current_time),
            total_income=GameUtils:formatNumber(crm:GetIronResource():GetProductionPerHour()).."/h",
            occupy_citizen=GameUtils:formatNumber(City:GetCitizenByType("miner")),
            type = "iron"
        },
        coin = {
            resource_icon="res_coin_81x68.png",
            resource_current_value=GameUtils:formatNumber(crm:GetCoinResource():GetResourceValueByCurrentTime(current_time)),
            total_income=GameUtils:formatNumber(crm:GetCoinResource():GetProductionPerHour()).."/h",
            occupy_citizen=GameUtils:formatNumber(self.city:GetResourceManager():GetCitizenResource():GetNoneAllocatedByTime(current_time)),
            type = "coin"
        },
    }
    self.resource_items = {}
    self.resource_items[resource_type.FOOD] = self:AddResourceItem(all_resources.food)
    self.resource_items[resource_type.WOOD] = self:AddResourceItem(all_resources.wood)
    self.resource_items[resource_type.STONE] = self:AddResourceItem(all_resources.stone)
    self.resource_items[resource_type.IRON] = self:AddResourceItem(all_resources.iron)
    self.resource_items[resource_type.COIN] = self:AddResourceItem(all_resources.coin)
end

function WidgetResources:AddResourceItem(parms)
    local resource_icon = parms.resource_icon
    local resource_limit_value = parms.resource_limit_value
    local resource_current_value = parms.resource_current_value
    local total_income = parms.total_income
    local occupy_citizen = parms.occupy_citizen
    local maintenance_cost = parms.maintenance_cost
    local r_type = parms.type

    local item = self.resource_listview:newItem()
    local item_width, item_height = 568,156
    item:setItemSize(item_width, item_height)
    local content = WidgetUIBackGround.new({width = 568,height = 156},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    local c_size = content:getContentSize()
    -- resource icon bg
    local icon_bg = display.newSprite("alliance_item_flag_box_126X126.png",80,c_size.height/2):addTo(content):scale(134/126)
    local icon_bg_1 = display.newSprite("box_118x118.png",icon_bg:getContentSize().width/2,icon_bg:getContentSize().height/2):addTo(icon_bg)

    -- resou icon
    display.newSprite(resource_icon,icon_bg_1:getContentSize().width/2, icon_bg_1:getContentSize().height/2):addTo(icon_bg_1)

    -- 构造分割线显示信息方法
    local function createTipItem(prams)
        -- 分割线
        local line = display.newScale9Sprite("dividing_line.png",prams.x, prams.y, cc.size(342,2))

        -- title
        line.title = cc.ui.UILabel.new(
            {
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = prams.title,
                font = UIKit:getFontFilePath(),
                size = 20,
                color = prams.title_color
            }):align(display.LEFT_CENTER, 0, 12)
            :addTo(line)
        -- title value
        line.value = cc.ui.UILabel.new(
            {
                UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
                text = prams.value,
                font = UIKit:getFontFilePath(),
                size = 20,
                color = prams.value_color
            }):align(display.RIGHT_CENTER, line:getCascadeBoundingBox().size.width, 12)
            :addTo(line)
        return line
    end

    if resource_limit_value then
        -- 进度条
        local bar = display.newSprite("progress_bar_348x40_1.png"):addTo(content):pos(330,c_size.height-32)
        local progressFill = display.newSprite("progress_bar_348x40_2.png")
        item.ProgressTimer = cc.ProgressTimer:create(progressFill)
        item.ProgressTimer:setType(display.PROGRESS_TIMER_BAR)
        item.ProgressTimer:setBarChangeRate(cc.p(1,0))
        item.ProgressTimer:setMidpoint(cc.p(0,0))
        item.ProgressTimer:align(display.LEFT_BOTTOM, 0, 0):addTo(bar)
        local r_percent = resource_current_value/resource_limit_value * 100
        item.r_percent = math.floor(r_percent)
        item.ProgressTimer:setPercentage(r_percent)
        item.resource_label = UIKit:ttfLabel({
            text = GameUtils:formatNumber(resource_current_value).."/"..GameUtils:formatNumber(resource_limit_value),
            size = 20,
            color = 0xfff3c7,
            shadow = true
        }):addTo(bar,2):align(display.LEFT_CENTER,10 , bar:getContentSize().height/2)

        -- 单位产能
        item.produce_capacity = createTipItem({
            title = _("单位产能"),
            title_color = UIKit:hex2c3b(0x615b44),
            value = total_income ,
            value_color = UIKit:hex2c3b(0x403c2f),
            x = icon_bg:getPositionX()+icon_bg:getContentSize().width/2+180,
            y = bar:getPositionY()-50
        })
        item.produce_capacity:addTo(content)
        --  占用人口
        item.occupy_citizen = createTipItem({
            title = _("占用人口"),
            title_color = UIKit:hex2c3b(0x615b44),
            value = occupy_citizen ,
            value_color = UIKit:hex2c3b(0x403c2f),
            x = icon_bg:getPositionX()+icon_bg:getContentSize().width/2+180,
            y = item.produce_capacity:getPositionY()-30
        })
        item.occupy_citizen:addTo(content)
        if maintenance_cost then
            --  维护费用
            item.maintenance_cost = createTipItem({
                title = _("维护费用"),
                title_color = UIKit:hex2c3b(0x615b44),
                value = maintenance_cost ,
                value_color = UIKit:hex2c3b(0x4ff0000),
                x = icon_bg:getPositionX()+icon_bg:getContentSize().width/2+180,
                y = item.occupy_citizen:getPositionY()-30
            })
            self.maintenance_cost = item.maintenance_cost
            item.maintenance_cost:addTo(content)
        end
        -- 资源保护进度条
        if r_type ~= "coin" then
            local progressFill = display.newSprite("tmp_progress_green_bar_348x40_2.png")
            local progresstimer = cc.ProgressTimer:create(progressFill)
            progresstimer:setType(display.PROGRESS_TIMER_BAR)
            progresstimer:setBarChangeRate(cc.p(1,0))
            progresstimer:setMidpoint(cc.p(0,0))
            progresstimer:align(display.LEFT_BOTTOM, 0, 1):addTo(bar)
            local p_percent = DataUtils:GetResourceProtectPercent(r_type) * 100
            progresstimer:setPercentage(math.min(p_percent,r_percent))
            item.protectPro = progresstimer
        end
    else
        -- coin 显示不同信息
        -- 当前coin
        item.resource_label = createTipItem({
            title = _("当前数量"),
            title_color = UIKit:hex2c3b(0x615b44),
            value = resource_current_value ,
            value_color = UIKit:hex2c3b(0x403c2f),
            x = icon_bg:getPositionX()+icon_bg:getContentSize().width/2+180,
            y = c_size.height-36
        })
        item.resource_label:addTo(content)
        -- 单位产能
        item.produce_capacity = createTipItem({
            title = _("单位产能"),
            title_color = UIKit:hex2c3b(0x615b44),
            value = total_income ,
            value_color = UIKit:hex2c3b(0x403c2f),
            x = icon_bg:getPositionX()+icon_bg:getContentSize().width/2+180,
            y = c_size.height-70
        })
        item.produce_capacity:addTo(content)
    end

    -- 使用道具增加资源按钮
    cc.ui.UIPushButton.new()
        :addTo(content):align(display.CENTER, c_size.width/2, c_size.height/2)
        :onButtonClicked(function(event)
            local items = ItemManager:GetItemByName(parms.type.."Class_1")
            WidgetUseItems.new():Create({item = items}):AddToCurrentScene()
        end):setContentSize(c_size)

    WidgetPushButton.new({normal = "button_wareHouseUI_normal.png",pressed = "button_wareHouseUI_pressed.png"})
        :onButtonClicked(function(event)
            end):align(display.CENTER, c_size.width-32, c_size.height/2):addTo(content)
        :addChild(display.newSprite("add.png"))
    item.type = r_type
    item:addContent(content)
    self.resource_listview:addItem(item)
    self.resource_listview:reload()

    return item
end

return WidgetResources








