local GameUtils = GameUtils
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetSliderWithInput = import("..widget.WidgetSliderWithInput")
local window = import("..utils.window")
local UILib = import("..ui.UILib")
local Localize_item = import("..utils.Localize_item")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetBuyGoods = class("WidgetBuyGoods", function(...)
    local node = display.newColorLayer(UIKit:hex2c4b(0x7a000000))
    local is_began_out = false
    node:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "began" then
            -- 点击空白区域关闭
            local background = node:getChildByTag(101)
            local lbpoint = background:convertToWorldSpace({x = 0, y = 0})
            local size = background:getContentSize()
            local rtpoint = background:convertToWorldSpace({x = size.width, y = size.height})
            if not cc.rectContainsPoint(cc.rect(lbpoint.x, lbpoint.y, rtpoint.x - lbpoint.x, rtpoint.y - lbpoint.y), event) then
                is_began_out = true
            end
        elseif event.name == "ended" then
            -- 点击空白区域关闭
            local background = node:getChildByTag(101)
            local lbpoint = background:convertToWorldSpace({x = 0, y = 0})
            local size = background:getContentSize()
            local rtpoint = background:convertToWorldSpace({x = size.width, y = size.height})

            if not cc.rectContainsPoint(cc.rect(lbpoint.x, lbpoint.y, rtpoint.x - lbpoint.x, rtpoint.y - lbpoint.y), event) then
                if is_began_out then
                    node:removeFromParent(true)
                end
            else
                is_began_out = false
            end
        end
        return true
    end)
    return node
end)

function WidgetBuyGoods:ctor(item)
    self.item = item
    local buy_max = 0
    -- 高级道具有数量限制
    local super_item_count = math.huge
    if item:IsAdvancedItem() then
        super_item_count = item:Count()
    end
    buy_max =math.min(math.floor(Alliance_Manager:GetMyAlliance():GetSelf():Loyalty()/item:SellPriceInAlliance()),super_item_count)

    local label_origin_x = 190

    -- bg
    local back_ground = WidgetUIBackGround.new({height=338,isFrame = 'yes'}):align(display.BOTTOM_CENTER, window.cx, 0):addTo(self)
    back_ground:setTag(101)
    local size = back_ground:getContentSize()

    back_ground:setTouchEnabled(true)

    -- 道具图片
    local item_bg = display.newSprite("box_118x118.png"):addTo(back_ground):align(display.CENTER, 70, size.height-80)
    -- tool image
    local goods_icon = display.newSprite(UILib.item[item:Name()]):align(display.CENTER, item_bg:getContentSize().width/2, item_bg:getContentSize().height/2)
        :addTo(item_bg):scale(0.8)
    goods_icon:scale(100/goods_icon:getContentSize().width)

    local i_icon = display.newSprite("goods_26x26.png"):addTo(item_bg):align(display.CENTER, 15, 15)

    -- 道具title
    local title_bg = display.newScale9Sprite("title_blue_430x30.png",370,size.height-40,cc.size(458,30),cc.rect(15,10,400,10))
        :addTo(back_ground)
    local goods_name = UIKit:ttfLabel({
        text = item:GetLocalizeName(),
        size = 24,
        color = 0xffedae,
    }):align(display.LEFT_CENTER,20, title_bg:getContentSize().height/2):addTo(title_bg)
    UIKit:ttfLabel({
        text = item:IsAdvancedItem() and _("高级道具") or _("普通道具"),
        size = 20,
        color = 0xe8dfbc,
    }):align(display.RIGHT_CENTER,title_bg:getContentSize().width-40, title_bg:getContentSize().height/2):addTo(title_bg)

    local goods_desc = UIKit:ttfLabel({
        text = item:GetLocalizeDesc(),
        size = 20,
        color = 0x403c2f,
        dimensions = cc.size(400,0)
    }):align(display.LEFT_TOP,item_bg:getPositionX()+item_bg:getContentSize().width/2+30, 280):addTo(back_ground)
    -- progress
    local slider_height, label_height = size.height - 170, size.height - 170

    local slider = WidgetSliderWithInput.new({max = buy_max,min = buy_max>0 and 1 or 0}):addTo(back_ground):align(display.LEFT_CENTER, 25, slider_height)
        :SetSliderSize(445, 24)
        :OnSliderValueChanged(function(event)
            self:OnCountChanged(math.floor(event.value))
        end)
        :LayoutValueLabel(WidgetSliderWithInput.STYLE_LAYOUT.RIGHT,0)
    -- 忠诚值
    display.newSprite("loyalty_128x128.png"):align(display.CENTER, 200, 50):addTo(back_ground):scale(42/128)
    local dividing = UIKit:ttfLabel({
        text = "/",
        size = 20,
        color = 0x403c2f,
    }):addTo(back_ground):align(display.CENTER,300, 50)
    local member = Alliance_Manager:GetMyAlliance():GetSelf()
    self.loyalty_label = UIKit:ttfLabel({
        text = GameUtils:formatNumber(member:Loyalty()),
        size = 20,
        color = 0x403c2f,
    }):addTo(back_ground):align(display.RIGHT_CENTER,dividing:getPositionX()-4,50)
    local need_loyalty = item:SellPriceInAlliance() * slider:GetValue()

    self.need_loyalty_label = UIKit:ttfLabel({
        text = GameUtils:formatNumber(need_loyalty),
        size = 20,
        color = 0x403c2f,
    }):addTo(back_ground):align(display.LEFT_CENTER,dividing:getPositionX()+4,50)

    -- 购买按钮
    local button = WidgetPushButton.new(
        {normal = "yellow_btn_up_185x65.png",pressed = "yellow_btn_down_185x65.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :setButtonLabel(UIKit:commonButtonLable({text = _("购买")}))
        :onButtonClicked(function(event)
            if item:IsAdvancedItem() and not Alliance_Manager:GetMyAlliance():GetSelf():CanBuyAdvancedItemsFromAllianceShop() then
                UIKit:showMessageDialog(_("陛下"),_("购买需要精英或以上权限"))
                return
            end
            if slider:GetValue()<1 then
                UIKit:showMessageDialog(_("陛下"),_("请输入正确的购买数量"))
                return
            end
            NetManager:getBuyAllianceItemPromise(item:Name(),slider:GetValue()):done(function ( response )
                GameGlobalUI:showTips(_("提示"),_("购买成功"))
                return response
            end)
            self:removeFromParent(true)

        end):pos(500, 50)
        :addTo(back_ground)

    button:setButtonEnabled(buy_max~=0)
end

function WidgetBuyGoods:align(anchorPoint, x, y)
    self.back_ground:align(anchorPoint, x, y)
    return self
end

function WidgetBuyGoods:OnCountChanged(count)
    local member = Alliance_Manager:GetMyAlliance():GetSelf()
    local  need_loyalty = self.item:SellPriceInAlliance() * count
    self.loyalty_label:setString(GameUtils:formatNumber(member:Loyalty()))
    self.need_loyalty_label:setString(GameUtils:formatNumber(need_loyalty))
    self.loyalty_label:setColor(UIKit:hex2c4b(member:Loyalty()<need_loyalty and 0x7e0000 or 0x403c2f))
end
return WidgetBuyGoods










