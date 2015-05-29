local Localize = import("..utils.Localize")
local window = import("..utils.window")
local WidgetRoundTabButtons = import("..widget.WidgetRoundTabButtons")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local WidgetInfo = import("..widget.WidgetInfo")
local WidgetSliderWithInput = import("..widget.WidgetSliderWithInput")
local MaterialManager = import("..entity.MaterialManager")
local TradeManager = import("..entity.TradeManager")
local UILib = import(".UILib")


local GameUITradeGuild = UIKit:createUIClass('GameUITradeGuild',"GameUIUpgradeBuilding")

local RESOURCE_TYPE = {
    [1] = "wood",
    [2] = "stone",
    [3] = "iron",
    [4] = "food",
}
local BUILD_MATERIAL_TYPE = {
    [1] = "blueprints",
    [2] = "tools",
    [3] = "tiles",
    [4] = "pulley",
}
local MARTIAL_MATERIAL_TYPE = {
    [1] = "trainingFigure",
    [2] = "bowTarget",
    [3] = "saddle",
    [4] = "ironPart",
}

local function get_goods_unit(goods_name)
    if goods_name== "wood"
        or goods_name=="stone"
        or goods_name=="iron"
        or goods_name=="food" then
        return "k"
    else
        return ""
    end
end

function GameUITradeGuild:ctor(city,building, default_tab)
    local bn = Localize.building_name
    GameUITradeGuild.super.ctor(self,city,bn[building:GetType()],building,default_tab)
    self.trade_manager = User:GetTradeManager()
    self.max_sell_queue = self.building:GetMaxSellQueue()
end

function GameUITradeGuild:CreateBetweenBgAndTitle()
    GameUITradeGuild.super.CreateBetweenBgAndTitle(self)

    -- 购买页面
    self.buy_layer = display.newLayer():addTo(self:GetView())
    -- 我的商品页面
    self.my_goods_layer = display.newLayer():addTo(self:GetView())
end

function GameUITradeGuild:OnMoveInStage()
    GameUITradeGuild.super.OnMoveInStage(self)
    self.tab_buttons = self:CreateTabButtons({
        {
            label = _("购买"),
            tag = "buy",
        },
        {
            label = _("我的商品"),
            tag = "myGoods",
        },
    }, function(tag)
        self.buy_layer:setVisible(tag == 'buy')
        self.my_goods_layer:setVisible(tag == 'myGoods')
        if tag == 'buy' and not self.resource_drop_list then
            self:LoadBuyPage()
        end
        if tag == 'myGoods' and not self.my_goods_listview then
            self:LoadMyGoodsPage()
        end
    end):pos(window.cx, window.bottom + 34)
    self:RefreshSoldMark()

    self.building:AddUpgradeListener(self)
    self.trade_manager:AddListenOnType(self, TradeManager.LISTEN_TYPE.DEAL_CHANGED)
    self.trade_manager:AddListenOnType(self, TradeManager.LISTEN_TYPE.MY_DEAL_REFRESH)
    self.city:GetMaterialManager():AddObserver(self)
end

function GameUITradeGuild:onExit()
    self.trade_manager:RemoveListenerOnType(self, TradeManager.LISTEN_TYPE.DEAL_CHANGED)
    self.trade_manager:RemoveListenerOnType(self, TradeManager.LISTEN_TYPE.MY_DEAL_REFRESH)
    self.building:RemoveUpgradeListener(self)
    self.city:GetMaterialManager():RemoveObserver(self)
    GameUITradeGuild.super.onExit(self)
end
function GameUITradeGuild:RefreshSoldMark()
    if self.trade_manager:IsSomeDealsSold() then
        if not self.is_some_sold then
            self.is_some_sold = display.newSprite("back_ground_32x33.png"):addTo(self.tab_buttons)
                :pos(280,40)
        end
    else
        if self.is_some_sold then
            self.is_some_sold:removeFromParent(true)
            self.is_some_sold = nil
        end
    end
end
function GameUITradeGuild:LoadBuyPage()
    local layer = self.buy_layer
    self.resource_drop_list =  WidgetRoundTabButtons.new(
        {
            {tag = "resource",label = "基本资源",default = true},
            {tag = "build_material",label = "建筑材料"},
            {tag = "martial_material",label = "军事材料"},
        },
        function(tag)
            if tag == 'resource' and not self.resource_layer then
                self.resource_layer, self.resource_listview , self.resource_options= self:LoadResource(self:GetGoodsDetailsByType(RESOURCE_TYPE),RESOURCE_TYPE)
            end
            if tag == 'build_material' and not self.build_material_layer then
                self.build_material_layer, self.build_material_listview , self.build_material_options= self:LoadResource(self:GetGoodsDetailsByType(BUILD_MATERIAL_TYPE),BUILD_MATERIAL_TYPE)
            end
            if tag == 'martial_material' and not self.martial_material_layer then
                self.martial_material_layer, self.martial_material_listview , self.martial_material_options= self:LoadResource(self:GetGoodsDetailsByType(MARTIAL_MATERIAL_TYPE),MARTIAL_MATERIAL_TYPE)
            end


            if self.resource_layer then
                self.resource_layer:setVisible(tag == 'resource')
                if self.resource_options:getSelectedIndex() then
                    self:RefreshSellListView(RESOURCE_TYPE,self.resource_options:getSelectedIndex())
                else
                    self.resource_options:getButtonAtIndex(1):setButtonSelected(true)
                end
            end
            if self.build_material_layer then
                self.build_material_layer:setVisible(tag == 'build_material')
                if self.build_material_options:getSelectedIndex() then
                    self:RefreshSellListView(BUILD_MATERIAL_TYPE,self.build_material_options:getSelectedIndex())
                else
                    self.build_material_options:getButtonAtIndex(1):setButtonSelected(true)
                end
            end
            if self.martial_material_layer then
                self.martial_material_layer:setVisible(tag == 'martial_material')
                if self.martial_material_options:getSelectedIndex() then
                    self:RefreshSellListView(BUILD_MATERIAL_TYPE,self.martial_material_options:getSelectedIndex())
                else
                    self.martial_material_options:getButtonAtIndex(1):setButtonSelected(true)
                end
            end
        end
    )
    self.resource_drop_list:align(display.TOP_CENTER,window.cx,window.top-80):addTo(layer,2)
end
function GameUITradeGuild:LoadResource(goods_details,goods_type)
    local layer = self:CreateLayer():addTo(self.buy_layer)
    local size = layer:getContentSize()
    local w,h = size.width,size.height


    -- 展示出售中的资源列表
    local list_view ,listnode=  UIKit:commonListView({
        viewRect = cc.rect(0, 0, 568, 520),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    listnode:addTo(layer):align(display.BOTTOM_CENTER,window.width/2,20)
    -- 列名
    UIKit:ttfLabel(
        {
            text = _("资源"),
            size = 20,
            color = 0x615b44
        }):align(display.LEFT_CENTER,50, 570)
        :addTo(layer)
    UIKit:ttfLabel(
        {
            text = _("数量"),
            size = 20,
            color = 0x615b44
        }):align(display.LEFT_CENTER,135, 570)
        :addTo(layer)
    UIKit:ttfLabel(
        {
            text =_("单价"),
            size = 20,
            color = 0x615b44
        }):align(display.LEFT_CENTER,250, 570)
        :addTo(layer)
    UIKit:ttfLabel(
        {
            text = _("总价"),
            size = 20,
            color = 0x615b44
        }):align(display.LEFT_CENTER,365, 570)
        :addTo(layer)

    -- 资源选择框
    local options = self:CreateOptions(goods_details)
        :pos(40, h-140):addTo(layer)
        :onButtonSelectChanged(function(event)
            self:RefreshSellListView(goods_type,event.selected)
        end)

    return layer,list_view,options
end
function GameUITradeGuild:RefreshSellListView(goods_type,selected)
    local list_view = self:GetSellListViewByGoodsType(goods_type)
    list_view:removeAllItems()
    NetManager:getGetSellItemsPromise(self:GetGoodsTypeMapToString(goods_type),goods_type[selected]):done(function(response)
        for k,v in pairs(response.msg.itemDocs) do
            self:CreateSellItemForListView(list_view,v)
        end
        list_view:reload()
    end)
end
function GameUITradeGuild:CreateSellItemForListView(listView,goods)
    local item = listView:newItem()
    local item_width,item_height = 568,64
    item:setItemSize(item_width, item_height)
    local content = display.newSprite("back_ground_568x64.png")
    item:addContent(content)
    listView:addItem(item)
    -- 商品icon
    local icon_bg =  display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(58,54),cc.rect(15,10,136,64))
        :align(display.LEFT_CENTER, 6, content:getContentSize().height/2)
        :addTo(content)
    local icon_image = display.newSprite(self:GetGoodsIcon(listView,goods.itemData.name))
        :align(display.CENTER, icon_bg:getContentSize().width/2, icon_bg:getContentSize().height/2)
        :addTo(icon_bg)
    -- 缩放icon到合适大小
    local max = math.max(icon_image:getContentSize().width,icon_image:getContentSize().height)
    icon_image:scale(42/max)
    -- 商品数量
    UIKit:ttfLabel(
        {
            text = goods.itemData.count..get_goods_unit(goods.itemData.name),
            size = 20,
            color = 0x403c2f
        }):align(display.CENTER, 120 ,content:getContentSize().height/2)
        :addTo(content)
    -- 商品单价
    UIKit:ttfLabel(
        {
            text = goods.itemData.price,
            size = 20,
            color = 0x403c2f
        }):align(display.CENTER, 230 ,content:getContentSize().height/2)
        :addTo(content)
    -- 银币icon
    display.newSprite("res_coin_81x68.png")
        :align(display.CENTER, 310, content:getContentSize().height/2)
        :addTo(content):scale(0.4)
    -- 总价
    UIKit:ttfLabel(
        {
            text = string.formatnumberthousands(goods.itemData.price*goods.itemData.count),
            size = 20,
            color = 0x403c2f
        }):align(display.LEFT_CENTER, 330 ,content:getContentSize().height/2)
        :addTo(content)
    -- 购买
    WidgetPushButton.new(
        {normal = "yellow_btn_up_108x48.png",pressed = "yellow_btn_down_108x48.png"})
        :addTo(content)
        :align(display.RIGHT_CENTER, content:getContentSize().width - 10, content:getContentSize().height/2)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("购买"),
            size = 24,
            color = 0xffedae,
            shadow = true
        }))
        :onButtonClicked(function(event)

                local buy_func = function ()
                    NetManager:getBuySellItemPromise(goods._id):next(function ( response )
                        -- 商品不存在
                        if response.errcode then
                            if response.errcode[1].code==573 then
                                listView:removeItem(item)
                            end
                        end
                        return response
                    end):done(function()
                        GameGlobalUI:showTips(_("提示"),string.format(_("购买%s成功"),Localize.sell_type[goods.itemData.name]))
                        listView:removeItem(item)
                    end)
                end
                if City:GetResourceManager():GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())<goods.itemData.price*goods.itemData.count then
                    UIKit:showMessageDialog(_("主人"),_("银币不足,是否使用金龙币补充"))
                        :CreateOKButton({
                            listener = function ()
                                buy_func()
                            end
                        })
                        :CreateNeeds({value = DataUtils:buyResource({coin = goods.itemData.price*goods.itemData.count}, {coin=City:GetResourceManager():GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())})})
                    return
                end
                buy_func()
        end)
end
function GameUITradeGuild:GetGoodsIcon(listView,icon)
    if listView == self.resource_listview then
        return UILib.resource[icon]
    elseif listView == self.build_material_listview then
        return UILib.materials[icon]
    elseif listView == self.martial_material_listview then
        return UILib.materials[icon]
    end
end
function GameUITradeGuild:GetGoodsDetailsByType(goods_type)
    if goods_type==RESOURCE_TYPE then
        local manager = City:GetResourceManager()
        return {
            {
                UILib.resource.wood,
                manager:GetWoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
            },
            {
                UILib.resource.stone,
                manager:GetStoneResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
            },
            {
                UILib.resource.iron,
                manager:GetIronResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
            },
            {
                UILib.resource.food,
                manager:GetFoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
            },
        }
    elseif goods_type==BUILD_MATERIAL_TYPE then
        local build_materials = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)
        return {
            {
                UILib.materials.blueprints,
                build_materials.blueprints
            },
            {
                UILib.materials.tools,
                build_materials.tools
            },
            {
                UILib.materials.tiles,
                build_materials.tiles
            },
            {
                UILib.materials.pulley,
                build_materials.pulley
            },
        }
    elseif goods_type==MARTIAL_MATERIAL_TYPE then
        local technology_materials = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.TECHNOLOGY)
        return {
            {
                UILib.materials.trainingFigure,
                technology_materials.trainingFigure
            },
            {
                UILib.materials.bowTarget,
                technology_materials.bowTarget
            },
            {
                UILib.materials.saddle,
                technology_materials.saddle
            },
            {
                UILib.materials.ironPart,
                technology_materials.ironPart
            },
        }
    end

end
function GameUITradeGuild:GetSellListViewByGoodsType(goods_type)
    if goods_type==RESOURCE_TYPE then
        return self.resource_listview
    elseif goods_type==BUILD_MATERIAL_TYPE then
        return self.build_material_listview
    elseif goods_type==MARTIAL_MATERIAL_TYPE then
        return self.martial_material_listview
    end
end
function GameUITradeGuild:GetGoodsTypeMapToString(goods_type)
    if goods_type==RESOURCE_TYPE then
        return "resources"
    elseif goods_type==BUILD_MATERIAL_TYPE then
        return "buildingMaterials"
    elseif goods_type==MARTIAL_MATERIAL_TYPE then
        return "technologyMaterials"
    end
end
function GameUITradeGuild:CreateOptions(params)
    local checkbox_image = {
        off = "box_136x136_1.png",
        on = "box_136x136_2.png",
    }
    local group = cc.ui.UICheckBoxButtonGroup.new(display.LEFT_TO_RIGHT)

    for i,v in ipairs(params) do
        local checkBoxButton = cc.ui.UICheckBoxButton.new(checkbox_image)
            :align(display.CENTER)
        local icon = display.newSprite(v[1])
            :align(display.CENTER,0,0)
            :addTo(checkBoxButton):scale(0.8)
        group:addButton(checkBoxButton)
        local num_bg = UIKit:shadowLayer()
        num_bg:setContentSize(cc.size(104,26))
        num_bg:addTo(checkBoxButton):pos(-50,-checkBoxButton:getCascadeBoundingBox().size.height/2+15)
        local num_value = UIKit:ttfLabel(
            {
                text = GameUtils:formatNumber(v[2]),
                size = 18,
                color = 0xfff9b5
            }):align(display.CENTER, num_bg:getContentSize().width/2 ,num_bg:getContentSize().height/2)
            :addTo(num_bg)

        -- 封装一下各个选项，以便之后刷新选项最新数值
        function checkBoxButton:SetValue(num)
            local new_value = GameUtils:formatNumber(num)
            if new_value ~= num_value:getString() then
                num_value:setString(new_value)
            end
        end
    end
    group:setButtonsLayoutMargin(0, 4, 0, 0)

    return group
end
function GameUITradeGuild:CreateLayer()
    local layer = display.newColorLayer(cc.c4b(12,12,12,0))
    local layer_w,layer_h = window.width,window.betweenHeaderAndTab-62
    layer:setContentSize(cc.size(layer_w,layer_h))
    layer:pos(window.left,window.bottom_top+4)
    return layer
end
function GameUITradeGuild:LoadMyGoodsPage()
    local layer = self.my_goods_layer
    -- 资源小车 btn
    local car_btn = WidgetPushButton.new(
        {normal = "box_118x118.png",pressed = "box_118x118.png"})
        :addTo(layer)
        :align(display.CENTER, window.left + 110 , window.top - 150)
        :onButtonClicked(function(event)
            self:OpenDollyIntro()
        end)
    -- 资源小车 icon
    display.newSprite("icon_dolly_128x128.png"):addTo(car_btn)
        :align(display.CENTER, 0,0):scale(0.9)

    -- i icon
    display.newSprite("goods_26x26.png"):addTo(car_btn)
        :align(display.BOTTOM_LEFT, -car_btn:getCascadeBoundingBox().size.width/2+6, -car_btn:getCascadeBoundingBox().size.height/2+6)

    --title bg
    local title_bg = display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(408,30), cc.rect(10,10,410,10))
        :align(display.CENTER, window.cx +70 , window.top- 108)
        :addTo(layer)
    --title label
    UIKit:ttfLabel(
        {
            text = _("资源小车"),
            size = 22,
            color = 0xffedae
        }):align(display.LEFT_CENTER,10, title_bg:getContentSize().height/2)
        :addTo(title_bg)
    local tradeGuild = City:GetFirstBuildingByType("tradeGuild")
    self.cart_num = UIKit:createLineItem(
        {
            width = 388,
            text_1 = _("数量"),
            text_2 = City:GetResourceManager():GetCartResource():GetResourceValueByCurrentTime(app.timer:GetServerTime()).. "/"..tradeGuild:GetMaxCart(),
        }
    ):align(display.CENTER,window.cx +70 , window.top- 166)
        :addTo(layer)
    self.cart_recovery = UIKit:createLineItem(
        {
            width = 388,
            text_1 = _("每小时制造"),
            text_2 = tradeGuild:GetCartRecovery(),
        }
    ):align(display.CENTER,window.cx +70 , window.top- 204)
        :addTo(layer)

    -- 我的商品列表
    local list_view ,listnode=  UIKit:commonListView({
        viewRect = cc.rect(0, 0, 568, 625),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    listnode:addTo(layer):align(display.BOTTOM_CENTER,window.cx,window.bottom_top+20)
    self.my_goods_listview = list_view
    -- 加载我的商品
    self:LoadMyGoodsList()
end
function GameUITradeGuild:LoadMyGoodsList()
    if not self.my_goods_listview then
        return
    end
    local list = self.my_goods_listview
    list:removeAllItems()
    -- 获取最大出售队列数
    local max_list_length = self:GetMaxSellListNum()
    for i = 1 , max_list_length do
        self:CreateSellItem(list,i)
    end
    list:reload()
end
function GameUITradeGuild:CreateSellItem(list,index)
    local item = list:newItem()
    local item_width,item_height = 568 ,154
    item:setItemSize(item_width,item_height)
    local content = WidgetUIBackGround.new({width=568, height=154},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    item:addContent(content)
    list:addItem(item)

    -- 基础的元素
    -- 商品背景框
    local goods_bg = display.newSprite("box_118x118.png")
        :align(display.LEFT_CENTER, 6, item_height/2)
        :addTo(content)
    local title_bg = display.newSprite("title_blue_430x30.png")
        :align(display.TOP_CENTER, 344, item_height-20)
        :addTo(content)
    local title_label = UIKit:ttfLabel(
        {
            text = "",
            size = 22,
            color = 0xffedae
        }):align(display.LEFT_CENTER,10, title_bg:getContentSize().height/2)
        :addTo(title_bg)

    local goods = self:GetOnSellGoods()[index]
    if goods then
        title_label:setString(_("出售")..Localize.sell_type[goods.goods_type])
        -- goods icon
        local goods_icon = display.newSprite(UILib.resource[goods.goods_type] or UILib.materials[goods.goods_type])
            :align(display.CENTER, goods_bg:getContentSize().width/2, goods_bg:getContentSize().height/2)
            :addTo(goods_bg)
        goods_icon:scale(84/math.max(goods_icon:getContentSize().width,goods_icon:getContentSize().height))
        -- 商品数量背景框
        local goods_num_bg = UIKit:shadowLayer()
        goods_num_bg:setContentSize(cc.size(102,26))
        goods_num_bg:align(display.BOTTOM_CENTER, 8, 8)
            :addTo(goods_bg)
        UIKit:ttfLabel(
            {
                text = goods.good_num..get_goods_unit(goods.goods_type),
                size = 18,
                color = 0xfff9b5
            }):align(display.CENTER,goods_num_bg:getContentSize().width/2, goods_num_bg:getContentSize().height/2)
            :addTo(goods_num_bg)

        -- 交易状态
        UIKit:ttfLabel(
            {
                text = goods.goods_status and _("交易成功") or _("等待交易"),
                size = 20,
                color = 0x615b44
            }):align(display.LEFT_CENTER,140, item_height-80)
            :addTo(content)

        -- 商品出售价格
        -- 银币icon
        display.newSprite("res_coin_81x68.png")
            :align(display.CENTER, 150, item_height-120)
            :addTo(content):scale(0.5)
        -- 总价
        UIKit:ttfLabel(
            {
                text = string.formatnumberthousands(goods.good_price*goods.good_num),
                size = 20,
                color = 0x403c2f
            }):align(display.LEFT_CENTER, 170 ,item_height-120)
            :addTo(content)

        -- 下架或获得交易银币按钮
        WidgetPushButton.new(
            {normal = goods.goods_status and "yellow_btn_up_148x58.png" or "red_btn_up_148x58.png",
                pressed = goods.goods_status and "yellow_btn_down_148x58.png" or "red_btn_down_148x58.png"})
            :addTo(content)
            :align(display.RIGHT_CENTER, item_width- 10, 50)
            :setButtonLabel(UIKit:ttfLabel({
                text = goods.goods_status and _("获得") or _("下架") ,
                size = 22,
                color = 0xffedae,
                shadow = true
            }))
            :onButtonClicked(function(event)
                if goods.goods_status then
                    NetManager:getGetMyItemSoldMoneyPromise(goods.good_id)
                else
                    NetManager:getRemoveMySellItemPromise(goods.good_id)
                end
            end)
    else
        if index<=self:GetUnlockedSellListNum() then
            title_label:setString(_("空闲"))
            UIKit:ttfLabel(
                {
                    text = _("选择你多余的资源或者材料进行出售"),
                    size = 20,
                    color = 0x403c2f,
                    dimensions = cc.size(200,0)
                }):align(display.LEFT_TOP, 140 ,item_height-60)
                :addTo(content)
            WidgetPushButton.new(
                {normal = "blue_btn_up_148x58.png" ,
                    pressed = "blue_btn_down_148x58.png"})
                :addTo(content)
                :align(display.RIGHT_CENTER, item_width- 10, 50)
                :setButtonLabel(UIKit:ttfLabel({
                    text = _("出售") ,
                    size = 22,
                    color = 0xffedae,
                    shadow = true
                }))
                :onButtonClicked(function(event)
                    self:OpenSellDialog()
                end)
        else
            title_label:setString(_("未解锁"))
            UIKit:ttfLabel(
                {
                    text = _("需要贸易行会").." Lv "..self.building:GetUnlockSellQueueLevel(index),
                    size = 20,
                    color = 0x403c2f,
                    dimensions = cc.size(200,0)
                }):align(display.LEFT_TOP, 140 ,item_height-60)
                :addTo(content)
            display.newSprite("lock_80x104.png")
                :align(display.CENTER, goods_bg:getContentSize().width/2, goods_bg:getContentSize().height/2)
                :addTo(goods_bg)
        end
    end
end
function GameUITradeGuild:GetMaxSellListNum()
    return 4
end
function GameUITradeGuild:GetUnlockedSellListNum()
    return self.building:GetMaxSellQueue()
end
function GameUITradeGuild:GetOnSellGoods()
    local my_deals = self.trade_manager:GetMyDeals()
    local sell_goods = {}
    for k,v in pairs(my_deals) do
        table.insert(sell_goods,
            {
                goods_type = v.itemData.name,
                goods_status = v.isSold,
                good_num = v.itemData.count,
                good_price = v.itemData.price,
                good_id = v.id,
            }
        )
    end
    return sell_goods
end
function GameUITradeGuild:OpenDollyIntro()
    local layer = UIKit:newWidgetUI("WidgetPopDialog", 350,_("资源小车"),display.top-240):AddToCurrentScene()
    local body = layer:GetBody()
    local w,h = body:getContentSize().width,body:getContentSize().height

    -- 资源小车 btn
    local dolly_icon_bg = display.newSprite("box_118x118.png")
        :addTo(body)
        :align(display.CENTER, 80,h-90)

    -- 资源小车 icon
    display.newSprite("icon_dolly_128x128.png"):addTo(dolly_icon_bg)
        :align(display.CENTER, dolly_icon_bg:getContentSize().width/2,dolly_icon_bg:getContentSize().height/2)
        :scale(0.9)
    -- 资源小车介绍
    UIKit:ttfLabel({
        text = _("出售商品需要马车来运输，马车不足则无法出售。在学院提升马车的科技，能够提高每个马车容纳资源和材料的数量"),
        size = 20,
        color = 0x615b44,
        dimensions = cc.size(400,0)
    }):addTo(body)
        :align(display.TOP_LEFT, 160, h-30)

    WidgetInfo.new({
        info={
            {_("容纳资源"),GameDatas.PlayerInitData.intInit.resourcesPerCart.value},
            {_("容纳材料"),GameDatas.PlayerInitData.intInit.materialsPerCart.value},
        },
        h =100
    }):align(display.TOP_CENTER, w/2 , h-160)
        :addTo(body)
    -- 确定
    WidgetPushButton.new(
        {normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png"}
    ):addTo(body)
        :align(display.CENTER, w/2,50)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("确定"),
            size = 24,
            color = 0xffedae,
            shadow = true
        }))
        :onButtonClicked(function(event)
            layer:removeFromParent(true)
        end)
end
function GameUITradeGuild:OpenSellDialog()
    local tradeGuildUI = self
    local root = WidgetPopDialog.new(654,_("出售资源")):addTo(self,10000)
    local body = root:GetBody()
    -- 资源，材料出售价格区间
    local PRICE_SCOPE = {
        resource = {
            min = 100,
            max = 1000
        },
        material = {
            min = 1000,
            max = 5000
        }
    }
    -- body 方法
    function body:CreateOrRefreshSliders(params)
        local max_num = params.max_num
        local min_num = params.min_num
        local min_unit_price = params.min_unit_price
        local max_unit_price = params.max_unit_price
        local unit = params.unit
        local goods_icon = params.goods_icon

        local layer = self.layer
        if self.sell_num_item then
            layer:removeChild(self.sell_num_item, true)
        end
        if self.sell_price_item then
            layer:removeChild(self.sell_price_item, true)
        end
        local size = layer:getContentSize()

        local w,h = size.width,size.height

        -- 出售商品数量拖动条
        self.sell_num_item = self:CreateSliderItem(
            {
                title = _("出售"),
                unit = unit == 1000 and "K" or "",
                max = max_num,
                min = min_num,
                icon = goods_icon,
                onSliderValueChanged = function ( value )
                    self:SetTotalPriceAndCartNum(value,self.sell_price_item:GetValue())
                end
            }
        ):align(display.TOP_CENTER,w/2,h-140):addTo(layer)

        -- 商品单价拖动条
        self.sell_price_item = self:CreateSliderItem(
            {
                title = params.unit == 1000 and _("每1K售价") or _("单价"),
                max = max_unit_price,
                min = min_unit_price,
                icon = "res_coin_81x68.png",
                onSliderValueChanged = function ( value )
                    self:SetTotalPriceAndCartNum(self.sell_num_item:GetValue(),value)
                end
            }
        ):align(display.TOP_CENTER,w/2,h-286):addTo(layer)
    end
    function body:LoadSellResource(goods_type)
        local goods_details = tradeGuildUI:GetGoodsDetailsByType(goods_type)
        local layer =self:CreateSellLayer()
        local size = layer:getContentSize()
        local w,h = size.width,size.height
        self.layer = layer
        -- 总价
        local temp_label = UIKit:ttfLabel(
            {
                text = _("总价"),
                size = 22,
                color = 0x403c2f,
            }):align(display.LEFT_CENTER, 30 ,70)
            :addTo(layer)
        -- 银币icon
        local temp_icon = display.newSprite("res_coin_81x68.png")
            :align(display.CENTER, temp_label:getPositionX()+temp_label:getContentSize().width+24, 70)
            :addTo(layer):scale(0.4)
        -- 总价
        self.total_price_label = UIKit:ttfLabel(
            {
                text = string.formatnumberthousands(1020),
                size = 20,
                color = 0x403c2f
            }):align(display.LEFT_CENTER, temp_icon:getPositionX()+30 ,70)
            :addTo(layer)

        -- 需要小车
        local temp_label = UIKit:ttfLabel(
            {
                text = _("资源小车"),
                size = 22,
                color = 0x403c2f,
            }):align(display.LEFT_CENTER, 30 ,30)
            :addTo(layer)
        -- 需要小车icon
        local temp_icon = display.newSprite("icon_dolly_128x128.png")
            :align(display.CENTER, temp_label:getPositionX()+temp_label:getContentSize().width+20, 30)
            :addTo(layer)
            :scale(0.3)
        -- 已有小车数量
        self.own_cart_num_label = UIKit:ttfLabel(
            {
                text = string.formatnumberthousands(City:GetResourceManager():GetCartResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())),
                size = 20,
                color = 0x403c2f
            }):align(display.LEFT_CENTER, temp_icon:getPositionX()+temp_icon:getContentSize().width*0.2 ,30)
            :addTo(layer)
        -- 需要小车数量
        self.cart_num_label = UIKit:ttfLabel(
            {
                text = "/"..string.formatnumberthousands(1020),
                size = 20,
                color = 0x403c2f
            }):align(display.LEFT_CENTER, self.own_cart_num_label:getPositionX()+self.own_cart_num_label:getContentSize().width ,30)
            :addTo(layer)

        -- 出售
        self.sell_btn = WidgetPushButton.new(
            {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"},
            {scale9 = false},
            {
                disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
            }
        ):addTo(layer)
            :align(display.RIGHT_CENTER, w-20,50)
            :setButtonLabel(UIKit:ttfLabel({
                text = _("出售"),
                size = 24,
                color = 0xffedae,
                shadow = true
            }))
            :onButtonClicked(function(event)
                local tag = self.drop_list:GetSelectedButtonTag()
                local type,options,goods_type
                if tag == 'resource' then
                    type = "resources"
                    options = self.resource_options
                    goods_type = RESOURCE_TYPE
                end
                if tag == 'build_material' then
                    type = "buildingMaterials"
                    options = self.build_material_options
                    goods_type = BUILD_MATERIAL_TYPE
                end
                if tag == 'martial_material' then
                    type = "technologyMaterials"
                    options = self.martial_material_options
                    goods_type = MARTIAL_MATERIAL_TYPE
                end
                local selected = options.currentSelectedIndex_
                if self.sell_num_item:GetValue()==0 then
                    UIKit:showMessageDialog(_("提示"),_("出售数量不能为零"),function()end)
                    return
                end
                -- 判定小车是否足够
                if self.sell_num_item:GetValue()>City:GetResourceManager():GetCartResource():GetResourceValueByCurrentTime(app.timer:GetServerTime()) then
                    UIKit:showMessageDialog(_("提示"),_("资源小车数量不足"), function()end)
                    return
                end
                NetManager:getSellItemPromise(type,goods_type[selected],self.sell_num_item:GetValue(),self.sell_price_item:GetValue()):done(function(result)
                    GameGlobalUI:showTips(_("提示"),string.format(_("出售%s成功"),Localize.sell_type[goods_type[selected]]))
                    self:getParent():LeftButtonClicked()
                end)
            end)


        -- 资源选择框
        local options = tradeGuildUI:CreateOptions(goods_details)
            :pos(26, h-120):addTo(layer)
            :onButtonSelectChanged(function(event)
                dump(event)
                local max_num,min_num,min_unit_price,max_unit_price,unit = self:GetPriceAndNum(goods_type,event.selected)
                self:CreateOrRefreshSliders(
                    {
                        max_num=max_num,
                        min_num=min_num,
                        min_unit_price=min_unit_price,
                        max_unit_price=max_unit_price,
                        unit=unit,
                        goods_icon = self:GetGoodsIcon(goods_type,event.selected),
                    }
                )
                self:SetTotalPriceAndCartNum( self.sell_num_item:GetValue(),self.sell_price_item:GetValue())
            end)

        return layer,options
    end
    function body:GetPriceAndNum(goods_type,index)
        local max_num,min_num,min_unit_price,max_unit_price,unit
        local goods_details = tradeGuildUI:GetGoodsDetailsByType(goods_type)[index]
        if goods_type == RESOURCE_TYPE then
            unit = 1000
            min_unit_price = PRICE_SCOPE.resource.min
            max_unit_price = PRICE_SCOPE.resource.max

            max_num = goods_details[2]
            min_num = max_num>1 and 1 or 0
        else
            min_unit_price = PRICE_SCOPE.material.min
            max_unit_price = PRICE_SCOPE.material.max

            max_num = goods_details[2]
            min_num = max_num>1 and 1 or 0
            unit = 1

        end
        return max_num,min_num,min_unit_price,max_unit_price,unit
    end
    function body:GetGoodsIcon(goods_type,index)
        if goods_type == RESOURCE_TYPE then
            return UILib.resource[goods_type[index]]
        elseif goods_type == BUILD_MATERIAL_TYPE then
            return UILib.materials[goods_type[index]]
        elseif goods_type == MARTIAL_MATERIAL_TYPE then
            return UILib.materials[goods_type[index]]
        end
    end
    function body:SetTotalPriceAndCartNum(goods_num,goods_unit_price)
        self.total_price_label:setString(string.formatnumberthousands(goods_num*goods_unit_price))
        self.cart_num_label:setString("/"..string.formatnumberthousands(goods_num))
        local current_cart_num = City:GetResourceManager():GetCartResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
        self.own_cart_num_label:setString(string.formatnumberthousands(current_cart_num))
        if current_cart_num<goods_num then
            self.own_cart_num_label:setColor(UIKit:hex2c4b(0x7e0000))
        else
            self.own_cart_num_label:setColor(UIKit:hex2c4b(0x403c2f))
        end
        self.cart_num_label:setPositionX(self.own_cart_num_label:getPositionX()+self.own_cart_num_label:getContentSize().width)
        self.total_price = goods_num*goods_unit_price
        self.sell_btn:isButtonEnabled()
        if self.sell_btn:isButtonEnabled() ~= (value~=0) then
            self.sell_btn:setButtonEnabled(value~=0)
        end
    end
    function body:GetTotalPrice()
        return self.total_price
    end
    function body:CreateSellLayer()
        local layer = cc.Layer:create()
        local layer_w,layer_h = 608,520
        layer:setContentSize(cc.size(layer_w,layer_h))
        layer:pos(0,10)
        return layer
    end
    function body:CreateSliderItem(parms)
        local item_width,item_height=580,136
        -- 背景框
        local item = display.newSprite("back_ground_580x136.png")

        -- title
        UIKit:ttfLabel(
            {
                text = parms.title,
                size = 22,
                color = 0x403c2f,
            }):align(display.LEFT_TOP, 20 ,item_height-15)
            :addTo(item)
        -- slider
        local slider = WidgetSliderWithInput.new({max = parms.max,min=parms.min,unit = parms.unit})
            :addTo(item)
            :align(display.CENTER, item:getContentSize().width/2,  60)
            :OnSliderValueChanged(function(event)
                parms.onSliderValueChanged(math.floor(event.value))
            end)
            :LayoutValueLabel(WidgetSliderWithInput.STYLE_LAYOUT.TOP,80)

        -- icon
        local x,y = slider:GetEditBoxPostion()
        if parms.icon then
            local icon_bg = cc.ui.UIImage.new("box_118x118.png"):addTo(slider)
                :align(display.CENTER, x-80, y)
            icon_bg:scale(40/icon_bg:getContentSize().width)
            item.icon = display.newSprite(parms.icon)
                :align(display.CENTER, x-80, y)
                :addTo(slider)
            local icon = item.icon
            local max = math.max(icon:getContentSize().width,icon:getContentSize().height)
            icon:scale(30/max)
        end
        function item:SetIcon(icon)
            local icon = item.icon
            if icon then
                icon:setTexture(icon)
            else
                item.icon = display.newSprite(parms.icon)
                    :align(display.CENTER, x-80, y)
                    :addTo(slider)
                local max = math.max(icon:getContentSize().width,icon:getContentSize().height)
                icon:scale(40/max)
            end
        end
        function item:GetValue()
            return slider:GetValue()
        end
        function item:GetCount()
            local unit =  parms.unit == "K" and 1000 or 1
            return slider:GetValue()*unit
        end
        return item
    end

    -- body 方法

    local body_width,body_height = 608,654
    body.drop_list =  WidgetRoundTabButtons.new(
        {
            {tag = "resource",label = "基本资源",default = true},
            {tag = "build_material",label = "建筑材料"},
            {tag = "martial_material",label = "军事材料"},
        },
        function(tag)
            if body.layer then
                body.layer:removeAllChildren()
            end
            if tag == 'resource' then
                body.layer, body.resource_options= body:LoadSellResource(RESOURCE_TYPE)
                body.resource_options:getButtonAtIndex(1):setButtonSelected(true)
                body.layer:addTo(body)
            end
            if tag == 'build_material' then
                body.layer,  body.build_material_options= body:LoadSellResource(BUILD_MATERIAL_TYPE)
                body.build_material_options:getButtonAtIndex(1):setButtonSelected(true)
                body.layer:addTo(body)
            end
            if tag == 'martial_material' then
                body.layer,  body.martial_material_options= body:LoadSellResource(MARTIAL_MATERIAL_TYPE)
                body.martial_material_options:getButtonAtIndex(1):setButtonSelected(true)
                body.layer:addTo(body)
            end
        end
    )
    body.drop_list:align(display.TOP_CENTER,window.cx,window.top-170):addTo(root)
end

function GameUITradeGuild:OnBuildingUpgradingBegin()
end
function GameUITradeGuild:OnBuildingUpgradeFinished()
    if self.cart_num and self.cart_recovery then
        local tradeGuild = City:GetFirstBuildingByType("tradeGuild")
        self.cart_num:SetValue(City:GetResourceManager():GetCartResource():GetResourceValueByCurrentTime(app.timer:GetServerTime()).. "/"..tradeGuild:GetMaxCart())
        self.cart_recovery:SetValue(tradeGuild:GetCartRecovery())
    end
    local queue_num = self.building:GetMaxSellQueue()
    if queue_num>self.max_sell_queue then
        self:LoadMyGoodsList()
    end
end
function GameUITradeGuild:OnBuildingUpgrading()
end
function GameUITradeGuild:OnDealChanged(changed_map)
    self:RefreshSoldMark()
    self:LoadMyGoodsList()
end
function GameUITradeGuild:OnMyDealsRefresh(changed_map)
    self:RefreshSoldMark()
end
function GameUITradeGuild:OnResourceChanged(resource_manager)
    GameUITradeGuild.super.OnResourceChanged(self,resource_manager)
    local tradeGuild = City:GetFirstBuildingByType("tradeGuild")
    if self.cart_num then
        self.cart_num:SetValue(resource_manager:GetCartResource():GetResourceValueByCurrentTime(app.timer:GetServerTime()).. "/"..tradeGuild:GetMaxCart())
    end
    if self.resource_options then
        local options =  self.resource_options
        local resources = self:GetGoodsDetailsByType(RESOURCE_TYPE)
        for i=1,4 do
            local item = options:getButtonAtIndex(i)
            item:SetValue(resources[i][2])
        end
    end
end
function GameUITradeGuild:OnMaterialsChanged(material_manager, material_type, changed)
    if material_type == MaterialManager.MATERIAL_TYPE.BUILD then
        if self.build_material_options then
            local options =  self.build_material_options
            for k,v in pairs(changed) do
                local index = self:GetMaterialIndexByName(k)
                options:getButtonAtIndex(index):SetValue(v.new)
            end
        end
    elseif material_type == MaterialManager.MATERIAL_TYPE.TECHNOLOGY then
        if self.martial_material_options then
            local options =  self.martial_material_options
            for k,v in pairs(changed) do
                local index = self:GetMaterialIndexByName(k)
                options:getButtonAtIndex(index):SetValue(v.new)
            end
        end
    end
end
-- 通过材料类别取的UI初始化的材料index
function GameUITradeGuild:GetMaterialIndexByName(material_type)
    local build_temp = {
        blueprints = 1,
        tools = 2,
        tiles = 3,
        pulley = 4,
    }
    local teach_temp = {
        trainingFigure = 1,
        bowTarget = 2,
        saddle = 3,
        ironPart = 4,
    }
    return build_temp[material_type] or teach_temp[material_type]
end
return GameUITradeGuild















