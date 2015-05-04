local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local UIListView = import(".UIListView")
local Alliance = import("..entity.Alliance")
local Observer = import("..entity.Observer")
local window = import("..utils.window")

local ResourceManager = import("..entity.ResourceManager")


local WidgetUIBackGround = import("..widget.WidgetUIBackGround")

local CON_TYPE = {
    wood = ResourceManager.RESOURCE_TYPE.WOOD,
    food = ResourceManager.RESOURCE_TYPE.FOOD,
    iron = ResourceManager.RESOURCE_TYPE.IRON,
    stone = ResourceManager.RESOURCE_TYPE.STONE,
    coin = ResourceManager.RESOURCE_TYPE.COIN,
    gem = ResourceManager.RESOURCE_TYPE.GEM,
}
local GameUIAllianceContribute = class("GameUIAllianceContribute", WidgetPopDialog)

function GameUIAllianceContribute:ctor()
    GameUIAllianceContribute.super.ctor(self,398,_("联盟捐献"),window.top-200)
    self:setNodeEventEnabled(true)
    -- 联盟主页滑动框需要监听捐赠ui是否开启来决定是否自动滚动
    self.observer = Observer.new()
    self.alliance = Alliance_Manager:GetMyAlliance()

    self.group = self:CreateContributeGroup()

    -- 捐赠能获得荣耀点
    local honour_bg = display.newSprite("back_ground_138x34.png"):align(display.LEFT_CENTER, 30, 90):addTo(self.body)
    display.newSprite("honour_128x128.png"):align(display.CENTER, 30, 90):addTo(self.body):scale(42/128)
    self.donate_honour = UIKit:ttfLabel({
        text = "+0",
        size = 22,
        color = 0x288400,
    }):align(display.CENTER, honour_bg:getContentSize().width/2,honour_bg:getContentSize().height/2)
        :addTo(honour_bg)
    -- 捐赠能获得忠诚
    local loyalty_bg = display.newSprite("back_ground_138x34.png"):align(display.LEFT_CENTER, 200, 90):addTo(self.body)
    display.newSprite("loyalty_128x128.png"):align(display.CENTER, 200, 90):addTo(self.body):scale(42/128)
    self.donate_loyalty = UIKit:ttfLabel({
        text = "+0",
        size = 22,
        color = 0x288400,
    }):align(display.CENTER, loyalty_bg:getContentSize().width/2,loyalty_bg:getContentSize().height/2)
        :addTo(loyalty_bg)

    self.donate_eff = UIKit:ttfLabel({
        text = "",
        size = 20,
        color = 0x514d3e,
    }):align(display.LEFT_CENTER, 20,40)
        :addTo(self.body)

    local contribute_btn = WidgetPushButton.new({normal = "yellow_btn_up_185x65.png",pressed = "yellow_btn_down_185x65.png"})
        :align(display.CENTER,500,60)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                if self:IsAbleToContribute() then
                    NetManager:getDonateToAlliancePromise(self.group:GetSelectedType())
                else

                end
            end
        end)
        :setButtonLabel("normal", UIKit:ttfLabel({
            text = _("捐赠"),
            size = 22,
            color = 0xfff3c7,
            shadow = true
        }))
        :addTo(self.body)

end
function GameUIAllianceContribute:AddIsOpenObserver( listener )
    self.observer:AddObserver(listener)
end
function GameUIAllianceContribute:RemoveIsOpenObserver( listener )
    self.observer:RemoveObserver(listener)
end
function GameUIAllianceContribute:onEnter()
    City:GetResourceManager():AddObserver(self)
    User:AddListenOnType(self, User.LISTEN_TYPE.ALLIANCE_DONATE)
end

function GameUIAllianceContribute:onExit()
    -- UIKit:getRegistry().removeObject(self.__cname)
    self.observer:NotifyObservers(function ( listener )
        listener:UIAllianceContributeClose()
    end)
    City:GetResourceManager():RemoveObserver(self)
    User:RemoveListenerOnType(self, User.LISTEN_TYPE.ALLIANCE_DONATE)
end
function GameUIAllianceContribute:GetDonateValueByType(donate_type)
    if not donate_type then return end
    local donate_status = User:AllianceDonate()
    local donate_level = donate_status[donate_type]
    for _,donate in pairs(GameDatas.AllianceInitData.donate) do
        if donate.level==donate_level and donate_type == donate.type then
            return donate
        end
    end
end

function GameUIAllianceContribute:RefreashEff()
    local donate  = self:GetDonateValueByType(self.group:GetSelectedType())
    if not donate then return end
    self.donate_eff:setString(
        string.format(
            _("额外获得荣誉+%d%%，忠诚+%d%%"),
            math.floor(donate.extra*100),
            math.floor(donate.extra*100)
        )
    )
    self.donate_loyalty:setString("+"..donate.loyalty)
    self.donate_honour:setString("+"..donate.honour)
end

function GameUIAllianceContribute:CreateContributeGroup()
    local ui_self = self

    -- 透明背景框
    local group = WidgetUIBackGround.new({width = 580,height=248},WidgetUIBackGround.STYLE_TYPE.STYLE_4)
        :align(display.CENTER,304, 250):addTo(self.body)
    local wood = City.resource_manager:GetWoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local stone = City.resource_manager:GetStoneResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local food = City.resource_manager:GetFoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local iron = City.resource_manager:GetIronResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local coin = City.resource_manager:GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local gem = City:GetUser():GetGemResource():GetValue()
    local group_table = {
        {
            icon="res_wood_82x73.png",
            own=wood,
            donate=self:GetDonateValueByType("wood").count
        },
        {
            icon="res_stone_88x82.png",
            own=stone,
            donate=self:GetDonateValueByType("stone").count
        },
        {
            icon="res_food_91x74.png",
            own=food,
            donate=self:GetDonateValueByType("food").count
        },
        {
            icon="res_iron_91x63.png",
            own=iron,
            donate=self:GetDonateValueByType("iron").count
        },
        {
            icon="res_coin_81x68.png",
            own=coin,
            donate=self:GetDonateValueByType("coin").count
        },
        {
            icon="gem_icon_62x61.png",
            own=gem,
            donate=self:GetDonateValueByType("gem").count
        },
    }

    local gap_x,gap_y = 10 ,10
    local origin_x = 145
    local origin_y = 206
    local count = -1
    for k,v in pairs(group_table) do
        count = count + 1
        local item = self:CreateContributeItem(v)
            :align(display.CENTER, origin_x + math.mod(count,2)*(280+gap_x), origin_y - math.floor(count/2)*(72+gap_y))
            :addTo(group)

        item:setTag(count+1)
        local tag = count+1
        item:OnStateChanged(function(event)
            group:onButtonStateChanged_(event)
        end)
    end

    function group:onButtonStateChanged_(event)
        if event.target:isButtonSelected() == false then
            return
        end
        for i=1,6 do
            local item = self:getChildByTag(i)
            if item:GetCheckBox() == event.target then
                if not item:IsSelected() then
                    item:SetSelected(true)
                end
            else
                if item:IsSelected() then
                    item:SetSelected(false)
                end
            end
        end
        ui_self:RefreashEff()
    end
    function group:GetSelectedType()
        local donate_types = {
            "wood",
            "stone",
            "food",
            "iron",
            "coin",
            "gem",
        }
        for i=1,6 do
            local item = self:getChildByTag(i)
            if item:IsSelected() then
                return donate_types[i]
            end
        end
    end
    function group:RefreashAllOwn(owns)
        for i=1,6 do
            local item = self:getChildByTag(i)
            item:SetOwn(owns[i])
        end
    end
    function group:RefreashAllDonate(donate)
        for i=1,6 do
            local item = self:getChildByTag(i)
            item:SetDonate(donate[i])
        end
    end

    return group
end
function GameUIAllianceContribute:CreateContributeItem(params)
    -- 背景框
    local item = WidgetUIBackGround.new({
        width = 280,
        height = 72,
        top_img = "back_ground_top_2.png",
        bottom_img = "back_ground_bottom_2.png",
        mid_img = "back_ground_mid_2.png",
        u_height = 10,
        b_height = 10,
        m_height = 1,
    })
    local size = item:getContentSize()
    local icon = display.newSprite(params.icon):align(display.CENTER, 40, size.height/2)
        :addTo(item)
    icon:setScale(60/icon:getContentSize().height)
    UIKit:ttfLabel({
        text = _("拥有").."/".._("捐赠"),
        size = 20,
        color = 0x514d3e,
    }):align(display.LEFT_CENTER, 90,50)
        :addTo(item)
    local own_label = UIKit:ttfLabel({
        text = GameUtils:formatNumber(params.own),
        size = 20,
        color = params.own < params.donate and 0x7e0000 or 0x288400,
    }):align(display.LEFT_CENTER, 90,25)
        :addTo(item)
    local donate_label = UIKit:ttfLabel({
        text = "/"..GameUtils:formatNumber(params.donate),
        size = 20,
        color = 0x288400,
    }):align(display.LEFT_CENTER, own_label:getPositionX()+own_label:getContentSize().width,25)
        :addTo(item)
    item.donate = params.donate
    local checkbox_image = {
        off = "checkbox_unselected.png",
        off_pressed = "checkbox_unselected.png",
        off_disabled = "checkbox_unselected.png",
        on = "checkbox_selectd.png",
        on_pressed = "checkbox_selectd.png",
        on_disabled = "checkbox_selectd.png",

    }
    local check_box = cc.ui.UICheckBoxButton.new(checkbox_image)
        :align(display.CENTER, size.width-30, size.height/2)
        :addTo(item)
    function item:IsSelected()
        return check_box:isButtonSelected()
    end
    function item:SetSelected(isSelected)
        return check_box:setButtonSelected(isSelected)
    end
    function item:GetCheckBox()
        return check_box
    end
    function item:SetOwn(own)
        own_label:setColor(UIKit:hex2c4b(own < self.donate and 0x7e0000 or 0x288400))
        own_label:setString(GameUtils:formatNumber(own))
    end
    function item:SetDonate(donate)
        self.donate = donate
        donate_label:setString("/"..GameUtils:formatNumber(donate))
        donate_label:setPositionX(own_label:getPositionX()+own_label:getContentSize().width) 
    end
    function item:OnStateChanged(listener)
        check_box:onButtonStateChanged(function(event)
            listener(event)
        end)
    end

    return item
end
function GameUIAllianceContribute:IsAbleToContribute()
    local r_type = self.group:GetSelectedType()
    if not r_type then
        UIKit:showMessageDialog(_("提示"),_("请选择一种资源"))
        return false
    end
    local count  = self:GetDonateValueByType(r_type).count
    local r_count
    if r_type == "coin" then
        r_count = City.resource_manager:GetResourceByType(CON_TYPE[r_type]):GetValue()
    elseif r_type == "gem" then
        r_count = User:GetGemResource():GetValue()
    else
        r_count = City.resource_manager:GetResourceByType(CON_TYPE[r_type]):GetResourceValueByCurrentTime(app.timer:GetServerTime())
    end
    if r_count<count then
        UIKit:showMessageDialog(_("提示"),_("选择捐赠的物资不足"))
        return false
    end
    return true
end

function GameUIAllianceContribute:OnResourceChanged(resource_manager)
    local wood = resource_manager:GetWoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local stone = resource_manager:GetStoneResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local food = resource_manager:GetFoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local iron = resource_manager:GetIronResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local coin = resource_manager:GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local gem = City:GetUser():GetGemResource():GetValue()
    local owns = {
        wood,
        stone,
        food,
        iron,
        coin,
        gem,
    }
    self.group:RefreashAllOwn(owns)
end
function GameUIAllianceContribute:OnAllianceDonateChanged()
    local donate = {
        self:GetDonateValueByType("wood").count,
        self:GetDonateValueByType("stone").count,
        self:GetDonateValueByType("food").count,
        self:GetDonateValueByType("iron").count,
        self:GetDonateValueByType("coin").count,
        self:GetDonateValueByType("gem").count,
    }
    self.group:RefreashAllDonate(donate)
    self:RefreashEff()
end
return GameUIAllianceContribute







