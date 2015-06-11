local GameUtils = GameUtils
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetSliderWithInput = import("..widget.WidgetSliderWithInput")
local WidgetInfoNotListView = import("..widget.WidgetInfoNotListView")
local Localize_item = import("..utils.Localize_item")
local UILib = import("..ui.UILib")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetStockGoods = class("WidgetStockGoods", function(...)
    local node = display.newColorLayer(UIKit:hex2c4b(0x7a000000))
    node:setNodeEventEnabled(true)
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

function WidgetStockGoods:ctor(item)
    self.item = item

    local buy_max = math.floor(Alliance_Manager:GetMyAlliance():Honour()/item:BuyPriceInAlliance())

    local label_origin_x = 190

    -- bg
    local back_ground = WidgetUIBackGround.new({height=400,isFrame="yes"}):align(display.BOTTOM_CENTER, window.cx, 0):addTo(self)
    back_ground:setTag(101)
    back_ground:setTouchEnabled(true)
    local size = back_ground:getContentSize()

    -- 道具图片
    local item_bg = display.newSprite("box_118x118.png"):addTo(back_ground):align(display.CENTER, 70, size.height-80)
    -- tool image
    local goods_icon = display.newSprite(UILib.item[item:Name()]):align(display.CENTER, item_bg:getContentSize().width/2, item_bg:getContentSize().height/2)
        :addTo(item_bg)
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
    }):align(display.LEFT_CENTER,item_bg:getPositionX()+item_bg:getContentSize().width/2+30, size.height-100):addTo(back_ground)
    -- progress
    local slider_height, label_height = size.height - 170, size.height - 170

    local slider = WidgetSliderWithInput.new({max = buy_max,min = buy_max > 0 and 1 or 0}):addTo(back_ground):align(display.LEFT_CENTER, 25, slider_height)
        :SetSliderSize(445, 24)
        :OnSliderValueChanged(function(event)
            self:OnCountChanged(math.floor(event.value))
        end)
        :LayoutValueLabel(WidgetSliderWithInput.STYLE_LAYOUT.RIGHT,0)


    -- 联盟数量，联盟内成员需求
    local widget_info = WidgetInfoNotListView.new(
        {
            info={
                {_("联盟拥有"),item:Count()}
            }
        }
    ):align(display.CENTER, size.width/2, 135)
        :addTo(back_ground)


    -- 荣耀值
    display.newSprite("honour_128x128.png"):align(display.CENTER, 200, 60):addTo(back_ground):scale(42/128)
    local dividing = UIKit:ttfLabel({
        text = "/",
        size = 20,
        color = 0x403c2f,
    }):addTo(back_ground):align(display.CENTER,300, 60)

    self.need_honour_label = UIKit:ttfLabel({
        text = GameUtils:formatNumber(self.item:BuyPriceInAlliance()*slider:GetValue()),
        size = 20,
        color = 0x403c2f,
    }):addTo(back_ground):align(display.LEFT_CENTER,dividing:getPositionX()+4,60)
    local alliance = Alliance_Manager:GetMyAlliance()

    self.honour_label = UIKit:ttfLabel({
        text = GameUtils:formatNumber(alliance:Honour()) ,
        size = 20,
        color = 0x403c2f,
    }):addTo(back_ground):align(display.RIGHT_CENTER,dividing:getPositionX()-4,60)
    -- 购买按钮
    local button = WidgetPushButton.new(
        {normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :setButtonLabel(UIKit:commonButtonLable({text = _("购买")}))
        :onButtonClicked(function(event)
            if item:IsAdvancedItem() and not Alliance_Manager:GetMyAlliance():GetSelf():CanAddAdvancedItemsToAllianceShop() then
                UIKit:showMessageDialog(_("主人"),_("需要军需官或以上权限"))
                return
            end
            if slider:GetValue()<1 then
                UIKit:showMessageDialog(_("主人"),_("请输入正确的进货数量"))
                return
            end
            NetManager:getAddAllianceItemPromise(item:Name(),slider:GetValue()):done(function ( response )
                GameGlobalUI:showTips(_("提示"),_("进货成功"))
                return response
            end)
            self:removeFromParent(true)
        end):pos(500, 60)
        :addTo(back_ground)

    button:setButtonEnabled(buy_max~=0)
end

function WidgetStockGoods:align(anchorPoint, x, y)
    self.back_ground:align(anchorPoint, x, y)
    return self
end

function WidgetStockGoods:OnCountChanged(count)
    self.need_honour_label:setString(GameUtils:formatNumber(self.item:BuyPriceInAlliance()*count))
end
return WidgetStockGoods









