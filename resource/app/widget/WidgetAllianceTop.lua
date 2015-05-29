--
-- Author: Kenny Dai
-- Date: 2015-04-18 10:00:48
--
local WidgetPushButton = import(".WidgetPushButton")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local UIPageView = import("..ui.UIPageView")

local WidgetAllianceTop = class("WidgetAllianceTop", function ()
    local node = display.newSprite("back_ground_640x62.png")
    node:setNodeEventEnabled(true)
    node:setTouchEnabled(true)
    return node
end)

function WidgetAllianceTop:ctor(alliance)
    self.alliance = alliance
end
function WidgetAllianceTop:onEnter()
    local size = self:getContentSize()
    -- 显示区域标识
    local mark_1 = display.newSprite("back_ground_28x14_1.png"):addTo(self):align(display.CENTER, size.width/2+11, size.height-7)
    local mark_2 = display.newSprite("back_ground_28x14_2.png"):addTo(self):align(display.CENTER, size.width/2-11, size.height-7)

    local pv = UIPageView.new {
        viewRect = cc.rect(54, 8, size.width-104, size.height-14),
        row = 1,
        padding = {left = 0, right = 0, top = 10, bottom = 0},
        nBounce = true
    }:onTouch(function (event)
        if event.name == "pageChange" then
            if event.pageIdx == 1 then
                mark_1:setPositionX(size.width/2+11)
                mark_2:setPositionX(size.width/2-11)
            else
                mark_1:setPositionX(size.width/2-11)
                mark_2:setPositionX(size.width/2+11)
            end
            if self.auto_change_page then
                scheduler.unscheduleGlobal(self.auto_change_page)
            end
            self.auto_change_page = scheduler.scheduleGlobal(handler(self, self.Change), 20.0, false)
        end
    end):addTo(self)
    pv:setTouchSwallowEnabled(false)
    pv:setCascadeOpacityEnabled(true)
    self.pv = pv
    -- add items
    self:CreateBtnsPageItem()
    self:CreateResourcesPageItem()
    pv:reload()
    City:GetResourceManager():AddObserver(self)
    City:GetResourceManager():OnResourceChanged()
    self.auto_change_page = scheduler.scheduleGlobal(handler(self, self.Change), 20.0, false)
end
function WidgetAllianceTop:onExit()
    City:GetResourceManager():RemoveObserver(self)
    if self.auto_change_page then
        scheduler.unscheduleGlobal(self.auto_change_page)
    end
end
function WidgetAllianceTop:Change()
    local pv = self.pv
    if not pv:IsOnTouch() then
        pv:setTouchEnabled(false)
        pv:gotoPage(pv:getCurPageIdx() == 1 and 2 or 1,true)
        pv:performWithDelay(function ()
            pv:setTouchEnabled(true)
        end,0.3)
    end
end
function WidgetAllianceTop:SetHonour( text )
    self.honour_label:setString(text)
end
function WidgetAllianceTop:SetLoyalty( text )
    self.loyalty_label:setString(text)
end
function WidgetAllianceTop:SetCoordinateTitle( text )
    self.coordinate_title_label:setString(text)
end
function WidgetAllianceTop:SetCoordinate( text )
    self.coordinate_label:setString(text)
end
function WidgetAllianceTop:CreateBtnsPageItem()
    local alliance = self.alliance
    local size = self:getContentSize()
    local pv = self.pv
    local item = pv:newItem()
    local content = display.newNode()

    local width,height = size.width-80, size.height
    content:setContentSize(width,height)
    content:setTouchEnabled(false)
    item:addChild(content)
    pv:addItem(item)

    -- 按钮分割线
    display.newSprite("line_4x45.png"):align(display.CENTER, 178, 23)
        :addTo(content)
    display.newSprite("line_4x45.png"):align(display.CENTER, 176+4+176, 23)
        :addTo(content)
    -- 荣耀按钮
    local honour_btn = WidgetPushButton.new({normal = "dark_blue_btn_up_176x44.png",
        pressed = "dark_blue_btn_down_176x44.png"})
        :onButtonClicked(function (event)
            if event.name == "CLICKED_EVENT" then
                if self.auto_change_page then
                    scheduler.unscheduleGlobal(self.auto_change_page)
                end
                local ui = UIKit:newGameUI('GameUIAllianceContribute'):AddToCurrentScene(true)
                ui:AddIsOpenObserver(self)
                self.uiAllianceContribute = ui
            end
        end)
        :align(display.CENTER, 88, 23)
        :addTo(content)
    -- 荣耀值
    display.newSprite("honour_128x128.png")
        :align(display.CENTER, -30,-1)
        :addTo(honour_btn)
        :scale(42/128)
    UIKit:ttfLabel(
        {
            text = _("荣耀值"),
            size = 14,
            color = 0xbdb582
        }):align(display.LEFT_CENTER, 0, 10)
        :addTo(honour_btn)
    self.honour_label = UIKit:ttfLabel(
        {
            text = GameUtils:formatNumber(alliance:Honour()),
            size = 18,
            color = 0xf5e8c4
        }):align(display.LEFT_CENTER, 0,-8)
        :addTo(honour_btn)

    -- 忠诚按钮
    local loyalty_btn = WidgetPushButton.new({normal = "dark_blue_btn_up_176x44.png",
        pressed = "dark_blue_btn_down_176x44.png"})
        :onButtonClicked(function (event)
            if event.name == "CLICKED_EVENT" then
                UIKit:newGameUI('GameUIAllianceLoyalty'):AddToCurrentScene(true)
            end
        end)
        :align(display.CENTER,180+90+176 , 23)
        :addTo(content)
    -- 忠诚值
    display.newSprite("loyalty_128x128.png")
        :align(display.CENTER, -40,loyalty_btn:getContentSize().height/2)
        :addTo(loyalty_btn)
        :scale(42/128)
    UIKit:ttfLabel(
        {
            text = _("忠诚值"),
            size = 14,
            color = 0xbdb582
        }):align(display.LEFT_CENTER, -15, loyalty_btn:getContentSize().height/2+10)
        :addTo(loyalty_btn)
    local member = alliance:GetSelf()
    self.loyalty_label = UIKit:ttfLabel(
        {
            text = GameUtils:formatNumber(User:Loyalty()),
            size = 18,
            color = 0xf5e8c4
        }):align(display.LEFT_CENTER, -15, loyalty_btn:getContentSize().height/2-10)
        :addTo(loyalty_btn)
    -- 坐标按钮
    local coordinate_btn = WidgetPushButton.new({normal = "dark_blue_btn_up_176x44.png",
        pressed = "dark_blue_btn_down_176x44.png"})
        :onButtonClicked(function ( event )
            if event.name == "CLICKED_EVENT" then
                UIKit:newGameUI('GameUIAlliancePosition'):AddToCurrentScene(true)
            end
        end)
        :align(display.CENTER, 180+88, 23)
        :addTo(content)
    -- 坐标
    display.newSprite("coordinate_128x128.png")
        :align(display.CENTER, -40,coordinate_btn:getContentSize().height/2-4)
        :addTo(coordinate_btn)
        :scale(42/128)
    self.coordinate_title_label = UIKit:ttfLabel(
        {
            text = _("坐标"),
            size = 14,
            color = 0xbdb582
        }):align(display.LEFT_CENTER, -15, coordinate_btn:getContentSize().height/2+10)
        :addTo(coordinate_btn)
    self.coordinate_label = UIKit:ttfLabel(
        {
            text = "23,21",
            size = 18,
            color = 0xf5e8c4
        }):align(display.LEFT_CENTER, -15, coordinate_btn:getContentSize().height/2-10)
        :addTo(coordinate_btn)
end

function WidgetAllianceTop:CreateResourcesPageItem()
    local size = self:getContentSize()
    local pv = self.pv
    local item = pv:newItem()
    local content

    local width,height = size.width-80, size.height
    content = display.newNode()
    content:setContentSize(width,height)
    content:setTouchEnabled(false)
    item:addChild(content)
    pv:addItem(item)

    -- 资源按钮
    local resource_btn = WidgetPushButton.new({normal = "dark_blue_btn_up_534x44.png",
        pressed = "dark_blue_btn_down_534x44.png"})
        :onButtonClicked(function (event)
            if event.name == "CLICKED_EVENT" then
                UIKit:newGameUI("GameUIResourceOverview",City):AddToCurrentScene(true)
            end
        end)
        :align(display.CENTER, 267, 23)
        :addTo(content)
    -- 资源图片和文字
    for i, v in ipairs({
        {"res_wood_82x73.png", "wood_label"},
        {"res_stone_88x82.png", "stone_label"},
        {"res_food_91x74.png", "food_label"},
        {"res_iron_91x63.png", "iron_label"},
        {"res_coin_81x68.png", "coin_label"},
    }) do
        local x = -250 + (i-1) * 106
        display.newSprite(v[1]):addTo(resource_btn):pos(x, 0):scale(0.3)
        self[v[2]] = UIKit:ttfLabel({text = "111",
            size = 18,
            color = 0xf3f0b6,
            shadow = true
        }):addTo(resource_btn):pos(x + 20, 0)
    end
end

function WidgetAllianceTop:OnResourceChanged(resource_manager)
    local server_time = app.timer:GetServerTime()
    local wood_number = resource_manager:GetWoodResource():GetResourceValueByCurrentTime(server_time)
    local food_number = resource_manager:GetFoodResource():GetResourceValueByCurrentTime(server_time)
    local iron_number = resource_manager:GetIronResource():GetResourceValueByCurrentTime(server_time)
    local stone_number = resource_manager:GetStoneResource():GetResourceValueByCurrentTime(server_time)
    local coin_number = resource_manager:GetCoinResource():GetResourceValueByCurrentTime(server_time)
    self.wood_label:setString(GameUtils:formatNumber(wood_number))
    self.food_label:setString(GameUtils:formatNumber(food_number))
    self.iron_label:setString(GameUtils:formatNumber(iron_number))
    self.stone_label:setString(GameUtils:formatNumber(stone_number))
    self.coin_label:setString(GameUtils:formatNumber(coin_number))
end
function WidgetAllianceTop:UIAllianceContributeClose()
    self.auto_change_page = scheduler.scheduleGlobal(handler(self, self.Change), 20.0, false)
    self.uiAllianceContribute:RemoveIsOpenObserver(self)
    self.uiAllianceContribute = nil
end
return WidgetAllianceTop






