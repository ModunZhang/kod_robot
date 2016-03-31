--
-- Author: Kenny Dai
-- Date: 2015-07-09 10:04:46
--
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetSliderWithInput = import(".WidgetSliderWithInput")
local WidgetPushButton = import(".WidgetPushButton")
local Localize_item = import("..utils.Localize_item")
local WidgetUseMutiItems = class("WidgetUseMutiItems", WidgetPopDialog)
local item_resource = GameDatas.Items.resource

function WidgetUseMutiItems:ctor(item_name)
    local resource_type
    if string.find(item_name,"wood") then
        resource_type = "wood"
    elseif string.find(item_name,"food") then
        resource_type = "food"
    elseif string.find(item_name,"stone") then
        resource_type = "stone"
    elseif string.find(item_name,"iron") then
        resource_type = "iron"
    end
    self.resource_type = resource_type
    WidgetUseMutiItems.super.ctor(self,resource_type and 348 or 282,Localize_item.item_name[item_name],display.top-298)
    self.item_name = item_name
    local body = self:GetBody()
    local body_size = body:getContentSize()
    -- 滑动条部分
    local slider_bg = display.newSprite("back_ground_580x136.png"):addTo(body)
        :align(display.CENTER_TOP,body_size.width/2,body_size.height-30 - (resource_type and 60 or 0))
    -- title
    UIKit:ttfLabel(
        {
            text = _("使用数量"),
            size = 22,
            color = 0x403c2f,
        }):align(display.LEFT_TOP, 20 ,slider_bg:getContentSize().height-15)
        :addTo(slider_bg)

    -- slider

    local slider = WidgetSliderWithInput.new({max = User:GetItemCount(item_name)})
        :addTo(slider_bg)
        :align(display.CENTER, slider_bg:getContentSize().width/2,  65)
        :OnSliderValueChanged(function(event)
            local value = math.floor(event.value)
            self.button:setButtonEnabled(value ~= 0)
        end)
        :LayoutValueLabel(WidgetSliderWithInput.STYLE_LAYOUT.TOP,75)
    local button = WidgetPushButton.new({normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png",disabled = "grey_btn_186x66.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("确定"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                NetManager:getUseItemPromise(item_name,{
                    [item_name] = {count = slider:GetValue()}
                }):done(function ()
                    self:LeftButtonClicked()
                end)
            end
        end):align(display.BOTTOM_CENTER, body_size.width/2,30):addTo(body)
    button:setButtonEnabled(slider:GetValue() ~= 0)
    self.button = button
    slider:SetValue(User:GetItemCount(item_name))
    self.slider = slider
end
function WidgetUseMutiItems:onEnter()
    WidgetUseMutiItems.super.onEnter(self)
    local item_name = self.item_name
    local resource_type = self.resource_type

    if resource_type then
        local resource_data = self:GetResourcesData()[resource_type]
        self:AddProgressTimer(resource_data)
        scheduleAt(self, function()
            local limits = UtilsForBuilding:GetWarehouseLimit(User)
            local resource_max
            if string.find(item_name,"wood") then
                resource_max = limits.maxWood
            elseif string.find(item_name,"food") then
                resource_max = limits.maxFood
            elseif string.find(item_name,"stone") then
                resource_max = limits.maxStone
            elseif string.find(item_name,"iron") then
                resource_max = limits.maxIron
            end
            self:RefreshSpecifyResource(resource_type,resource_max)
            self:RefreshProtectPercent(resource_type)
        end)
    end
end
function WidgetUseMutiItems:onExit()
    WidgetUseMutiItems.super.onExit(self)
end
function WidgetUseMutiItems:RefreshProtectPercent(resource_type)
    if self.protectPro then
        local p = DataUtils:GetResourceProtectPercent(resource_type) * 100
        self.protectPro:setPercentage(p)
    end
end
function WidgetUseMutiItems:RefreshSpecifyResource(res_type,maxvalue)
    local User = User
    local value = User:GetResValueByType(res_type) + self:GetSliderSelectResValue()
    self.progressTimer:setPercentage(math.floor(value/maxvalue*100))
    self.resource_label:setString(GameUtils:formatNumber(value))
    local limit_value = self:GetResourcesData()[self.resource_type].resource_limit_value
    if value > limit_value then
        self.resource_label:setColor(UIKit:hex2c4b(0xff3c00))
    else
        self.resource_label:setColor(UIKit:hex2c4b(0xfff3c7))
    end
    self.resource_limit_label:setString("/"..GameUtils:formatNumber(maxvalue))
    self.resource_limit_label:setPositionX(self.resource_label:getPositionX() + self.resource_label:getContentSize().width + 5 )
end
function WidgetUseMutiItems:GetSliderSelectResValue()
    return self.slider:GetValue() * item_resource[self.item_name].effect * 1000
end
function WidgetUseMutiItems:GetResourcesData()
    local limits = UtilsForBuilding:GetWarehouseLimit(User)
    local maxwood, maxfood, maxiron, maxstone = limits.maxWood, limits.maxFood, limits.maxIron, limits.maxStone
    return {
        food = {
            resource_icon="res_food_91x74.png",
            resource_limit_value = maxfood,
            resource_current_value=User:GetResValueByType("food"),
            type = "food"
        },
        wood = {
            resource_icon="res_wood_82x73.png",
            resource_limit_value= maxwood,
            resource_current_value=User:GetResValueByType("wood"),
            type = "wood"
        },
        stone = {
            resource_icon="res_stone_88x82.png",
            resource_limit_value= maxstone,
            resource_current_value=User:GetResValueByType("stone"),
            type = "stone"
        },
        iron = {
            resource_icon="res_iron_91x63.png",
            resource_limit_value=maxiron,
            resource_current_value=User:GetResValueByType("iron"),
            type = "iron"
        },
    }
end

function WidgetUseMutiItems:AddProgressTimer(parms)
    local resource_icon = parms.resource_icon
    local resource_limit_value = parms.resource_limit_value
    local resource_current_value = parms.resource_current_value
    local r_type = parms.type
    local c_size = self.body:getContentSize()
    -- 进度条
    local bar = display.newSprite("progress_bar_540x40_1.png"):addTo(self.body):pos(310,c_size.height-50)
    local progressFill = display.newSprite("progress_bar_540x40_3.png")
    ProgressTimer = cc.ProgressTimer:create(progressFill)
    ProgressTimer:setType(display.PROGRESS_TIMER_BAR)
    ProgressTimer:setBarChangeRate(cc.p(1,0))
    ProgressTimer:setMidpoint(cc.p(0,0))
    ProgressTimer:align(display.LEFT_BOTTOM, 0, 0):addTo(bar)
    local r_percent = resource_current_value/resource_limit_value * 100
    r_percent = math.floor(r_percent)
    ProgressTimer:setPercentage(r_percent)
    self.progressTimer = ProgressTimer
    self.resource_label = UIKit:ttfLabel({
        text = GameUtils:formatNumber(resource_current_value),
        size = 20,
        color = 0xfff3c7,
        shadow = true
    }):addTo(bar,2):align(display.LEFT_CENTER,30 , bar:getContentSize().height/2)
    self.resource_limit_label = UIKit:ttfLabel({
        text = "/"..GameUtils:formatNumber(resource_limit_value),
        size = 20,
        color = 0xfff3c7,
        shadow = true
    }):addTo(bar,2):align(display.LEFT_CENTER,self.resource_label:getPositionX() + self.resource_label:getContentSize().width + 5 , bar:getContentSize().height/2)

    -- 资源保护进度条
    local progressFill = display.newSprite("progress_bar_540x40_4.png")
    local progresstimer = cc.ProgressTimer:create(progressFill)
    progresstimer:setType(display.PROGRESS_TIMER_BAR)
    progresstimer:setBarChangeRate(cc.p(1,0))
    progresstimer:setMidpoint(cc.p(0,0))
    progresstimer:align(display.LEFT_BOTTOM, 0, 0):addTo(bar)
    local p_percent = DataUtils:GetResourceProtectPercent(r_type) * 100
    progresstimer:setPercentage(math.min(p_percent,r_percent))
    self.protectPro = progresstimer
    local icon_bg = display.newSprite("back_ground_43x43.png", 0 , bar:getContentSize().height/2):addTo(bar)
    display.newSprite(resource_icon, icon_bg:getContentSize().width/2 , icon_bg:getContentSize().height/2):addTo(icon_bg):scale(0.5)
end
return WidgetUseMutiItems








