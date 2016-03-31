local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetBuyGoods = import("..widget.WidgetBuyGoods")
local WidgetStockGoods = import("..widget.WidgetStockGoods")
local WidgetPushButton = import("..widget.WidgetPushButton")
local GameUIAllianceShop = UIKit:createUIClass('GameUIAllianceShop', "GameUIAllianceBuilding")
local UIListView = import(".UIListView")
local UILib = import(".UILib")
local Localize = import("..utils.Localize")
local Localize_item = import("..utils.Localize_item")
local shop = GameDatas.AllianceBuilding.shop


function GameUIAllianceShop:ctor(city,default_tab,building)
    GameUIAllianceShop.super.ctor(self, city, _("商店"))
    self.default_tab = default_tab
    self.building = building
    self.alliance = Alliance_Manager:GetMyAlliance()
    self:InitUnLockItems()
end
function GameUIAllianceShop:InitUnLockItems()
    self.unlock_items = {}
    for i=1,self.building.level do
        local unlock = string.split(shop[i].itemsUnlock, ",")
        for i,v in ipairs(unlock) do
            self.unlock_items[v] = true
        end
    end
end
function GameUIAllianceShop:CheckSell(item_type)
    return self.unlock_items[item_type]
end
function GameUIAllianceShop:OnMoveInStage()
    GameUIAllianceShop.super.OnMoveInStage(self)
    self:CreateTabButtons({
        {
            label = _("商品"),
            tag = "goods",
            default = "goods" == self.default_tab,
        },
        {
            label = _("进货"),
            tag = "stock",
            default = "stock" == self.default_tab,
        },
        {
            label = _("商品记录"),
            tag = "record",
            default = "record" == self.default_tab,
        },
    }, function(tag)
        if tag == 'goods' then
            self.goods_layer:setVisible(true)
            -- 打开商店,更新查看新货物状态
            if self.alliance.isNewGoodsCome then
                self.alliance:SetNewGoodsCome(false)
            end
        else
            self.goods_layer:setVisible(false)
        end
        if tag == 'stock' then
            self.stock_layer:setVisible(true)
        else
            self.stock_layer:setVisible(false)
        end
        if tag == 'record' then
            self.goods_record_layer:setVisible(true)
        else
            self.goods_record_layer:setVisible(false)
        end
        if tag == 'goods' and not self.goods_listview then
            self:InitGoodsPart()
        end
        if tag == 'stock' and not self.stock_listview then
            self:InitStockPart()
        end
        if tag == 'record' and not self.record_list then
            self:InitRecordPart()
        end

        if tag ~= "upgrade" then
            if not self.honourAndLoyalty then
                self.honourAndLoyalty = self:HonourAndLoyalty():addTo(self:GetView()):align(display.CENTER, window.cx, window.top_bottom - 30)
            end
            self.honourAndLoyalty:show()
        else
            if self.honourAndLoyalty then
                self.honourAndLoyalty:hide()
            end
        end
    end):pos(window.cx, window.bottom + 34)
    self.alliance:AddListenOnType(self, "basicInfo")
    self.alliance:AddListenOnType(self, "buildings")
    self.alliance:AddListenOnType(self, "itemLogs")
    self.alliance:AddListenOnType(self, "items")
    User:AddListenOnType(self, "allianceData")
end
function GameUIAllianceShop:CreateBetweenBgAndTitle()
    GameUIAllianceShop.super.CreateBetweenBgAndTitle(self)

    -- goods_layer
    self.goods_layer = display.newLayer():addTo(self:GetView())
    -- stock_layer
    self.stock_layer = display.newLayer():addTo(self:GetView())
    -- goods_record_layer
    self.goods_record_layer = display.newLayer():addTo(self:GetView())
end
function GameUIAllianceShop:onExit()
    self.alliance:RemoveListenerOnType(self, "basicInfo")
    self.alliance:RemoveListenerOnType(self, "itemLogs")
    self.alliance:RemoveListenerOnType(self, "buildings")
    self.alliance:RemoveListenerOnType(self, "items")
    User:RemoveListenerOnType(self, "allianceData")
    GameUIAllianceShop.super.onExit(self)
end
-- 荣耀值和忠诚值
function GameUIAllianceShop:HonourAndLoyalty()
    local node = display.newNode()
    node:setContentSize(cc.size(560,34))
    -- 荣耀值
    local h_title = UIKit:ttfLabel({
        text = _("荣耀值"),
        size = 20,
        color = 0x615b44
    }):addTo(node):align(display.LEFT_CENTER, 0 , 17)
    local bg = WidgetUIBackGround.new({width = 126,height = 34},WidgetUIBackGround.STYLE_TYPE.STYLE_3)
        :addTo(node):align(display.LEFT_CENTER, h_title:getPositionX() + h_title:getContentSize().width + 20, h_title:getPositionY())
    display.newSprite("honour_128x128.png"):addTo(bg):align(display.LEFT_CENTER, -18, bg:getContentSize().height/2):scale(0.4)
    -- 荣耀值
    local honour_label = UIKit:ttfLabel({
        text = GameUtils:formatNumber(self.alliance.basicInfo.honour),
        size = 20,
        color = 0x615b44
    }):addTo(bg):align(display.CENTER, bg:getContentSize().width/2 + 2, bg:getContentSize().height/2)

    -- 忠诚值
    local bg = WidgetUIBackGround.new({width = 126,height = 34},WidgetUIBackGround.STYLE_TYPE.STYLE_3)
        :addTo(node):align(display.RIGHT_CENTER, 560, 17)
    display.newSprite("loyalty_128x128.png"):addTo(bg):align(display.LEFT_CENTER, -20, bg:getContentSize().height/2):scale(0.4)
    local h_title = UIKit:ttfLabel({
        text = _("忠诚值"),
        size = 20,
        color = 0x615b44
    }):addTo(node):align(display.RIGHT_CENTER, bg:getPositionX() - bg:getContentSize().width - 20 , 17)
    -- 荣耀值
    local loyalty_label = UIKit:ttfLabel({
        text = GameUtils:formatNumber(User:Loyalty()),
        size = 20,
        color = 0x615b44
    }):addTo(bg):align(display.CENTER, bg:getContentSize().width/2 + 2 , bg:getContentSize().height/2)

    function node:SetHonour( honour )
        honour_label:setString(GameUtils:formatNumber(honour))
    end
    function node:SetLoyalty( loyalty )
        loyalty_label:setString(GameUtils:formatNumber(loyalty))
    end
    return node
end
function GameUIAllianceShop:InitGoodsPart()
    local layer = self.goods_layer
    local list_width = 558
    local list,list_node = UIKit:commonListView({
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(41, window.bottom_top,list_width , window.betweenHeaderAndTab - 100),
    })
    list_node:addTo(layer):align(display.BOTTOM_CENTER, window.cx,window.bottom_top+20)
    self.goods_listview = list

    local function __createListItem(w,h)
        local item = list:newItem()
        item:setItemSize(w, h)
        list:addItem(item)
        return item
    end

    -- 普通道具
    -- title
    local title_item = __createListItem(list_width,50)
    local title_bg = display.newSprite("title_blue_554x34.png")
    UIKit:ttfLabel({
        text = _("普通道具"),
        size = 22,
        color = 0xffedae,
    }):align(display.CENTER, title_bg:getContentSize().width/2, title_bg:getContentSize().height/2):addTo(title_bg)
    title_item:addContent(title_bg)

    -- 道具部分
    local box_width = 130
    local goods_item_height = 176
    local origin_x = box_width/2
    local row_count = 4
    local gap_x = 10
    local normal_items = UtilsForItem:GetNormalItemsInfo()
    local row_items = {}
    for i=1,#normal_items do
        local noraml_item = normal_items[i]
        if self:CheckSell(noraml_item.name) then
            table.insert(row_items,noraml_item)
        end
        if LuaUtils:table_size(row_items) == 4 or (i == #normal_items and LuaUtils:table_size(row_items)>0) then
            local goods_item = __createListItem(list_width,goods_item_height)
            local node = display.newNode()
            node:setContentSize(cc.size(list_width,goods_item_height))
            for i,v in ipairs(row_items) do
                self:CreateGoodsBox(v):addTo(node):pos(origin_x+(i-1)*(gap_x+box_width), goods_item_height/2)
            end
            goods_item:addContent(node)
            row_items = {}
        end
    end

    -- 高级道具
    -- title
    local title_item = __createListItem(list_width,50)
    local title_bg = display.newSprite("title_purple_558x34.png")
    UIKit:ttfLabel({
        text = _("高级道具"),
        size = 22,
        color = 0xffedae,
    }):align(display.CENTER, title_bg:getContentSize().width/2, title_bg:getContentSize().height/2):addTo(title_bg)
    title_item:addContent(title_bg)

    self.super_goods_boxes = {}

    -- 道具部分
    local row_items = {}
    local super_items = UtilsForItem:GetAdvanceItems()
    for i=1,#super_items do
        local super_item = super_items[i]
        if self:CheckSell(super_item.name) then
            table.insert(row_items,super_item)
        end
        if LuaUtils:table_size(row_items) == 4 or (i == #super_items and LuaUtils:table_size(row_items) > 0 ) then
            local goods_item = __createListItem(list_width,goods_item_height)
            local node = display.newNode()
            node:setContentSize(cc.size(list_width,goods_item_height))
            for i,v in ipairs(row_items) do
                local goods_box = self:CreateGoodsBox(v):addTo(node):pos(origin_x+(i-1)*(gap_x+box_width), goods_item_height/2)
                if v.isAdvancedItem then
                    self.super_goods_boxes[v.name] = goods_box
                end
            end
            goods_item:addContent(node)
            row_items = {}
        end
    end
    list:reload()
end



function GameUIAllianceShop:CreateGoodsBox(goods)
    local box_button = WidgetPushButton.new({normal = "back_ground_130x166.png",pressed = "back_ground_130x166.png"})
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                WidgetBuyGoods.new(goods):addTo(self,201)
            end
        end)

    local item_bg = display.newSprite("box_118x118.png"):addTo(box_button):align(display.CENTER, 0, 18)
    -- tool image
    local goods_icon = display.newSprite(UILib.item[goods.name]):align(display.CENTER, item_bg:getContentSize().width/2, item_bg:getContentSize().height/2)
        :addTo(item_bg)
    goods_icon:scale(100/goods_icon:getContentSize().width)

    local i_icon = display.newSprite("goods_26x26.png"):addTo(item_bg):align(display.CENTER, 15, 15)

    -- 高级道具显示数量
    if goods.isAdvancedItem then
        -- 拥有数量
        local own_bg = display.newSprite("back_ground_42x48.png"):align(display.TOP_CENTER, 28, item_bg:getContentSize().height+4):addTo(item_bg)

        local own_label = UIKit:ttfLabel({
            text = self.alliance:GetItemCount(goods.name),
            size = 18,
            color = 0xfff3ca,
            shadow = true
        }):align(display.CENTER, own_bg:getContentSize().width/2, own_bg:getContentSize().height/2+8):addTo(own_bg)

        function box_button:SetOwnCount( count )
            own_label:setString(count)
        end
    end

    local num_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(118,36),cc.rect(15,10,136,64)):align(display.BOTTOM_CENTER, 0, -76)
        :addTo(box_button)
    display.newSprite("loyalty_128x128.png"):align(display.CENTER, 24, num_bg:getContentSize().height/2-2):addTo(num_bg):scale(34/128)
    UIKit:ttfLabel({
        text = GameUtils:formatNumber(goods.sellPriceInAlliance),
        size = 22,
        color = 0x423f32,
    }):align(display.LEFT_CENTER, num_bg:getContentSize().width/2-18, num_bg:getContentSize().height/2-2):addTo(num_bg)
    return box_button
end

function GameUIAllianceShop:CreateStockGoodsBox(goods)
    local box_button = WidgetPushButton.new({normal = "back_ground_130x166.png",pressed = "back_ground_130x166.png"})
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                WidgetStockGoods.new(goods):addTo(self,201)
            end
        end)

    local item_bg = display.newSprite("box_118x118.png"):addTo(box_button):align(display.CENTER, 0, 18)
    -- tool image
    local goods_icon = display.newSprite(UILib.item[goods.name]):align(display.CENTER, item_bg:getContentSize().width/2, item_bg:getContentSize().height/2)
        :addTo(item_bg)
    goods_icon:scale(100/goods_icon:getContentSize().width)

    local i_icon = display.newSprite("goods_26x26.png"):addTo(item_bg):align(display.CENTER, 15, 15)
    -- 拥有数量
    local own_bg = display.newSprite("back_ground_42x48.png"):align(display.TOP_CENTER, 28, item_bg:getContentSize().height+4):addTo(item_bg)

    local own_label = UIKit:ttfLabel({
        text = self.alliance:GetItemCount(goods.name),
        size = 18,
        color = 0xfff3ca,
        shadow = true
    }):align(display.CENTER, own_bg:getContentSize().width/2, own_bg:getContentSize().height/2+8):addTo(own_bg)

    local num_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(118,36),cc.rect(15,10,136,64)):align(display.BOTTOM_CENTER, 0, -76)
        :addTo(box_button)
    display.newSprite("honour_128x128.png"):align(display.CENTER, 24, num_bg:getContentSize().height/2-2):addTo(num_bg):scale(34/128)
    UIKit:ttfLabel({
        text = GameUtils:formatNumber(goods.buyPriceInAlliance),
        size = 22,
        color = 0x423f32,
    }):align(display.LEFT_CENTER, num_bg:getContentSize().width/2-18, num_bg:getContentSize().height/2-2):addTo(num_bg)
    function box_button:SetOwnCount(count)
        own_label:setString(count)
    end
    return box_button
end
function GameUIAllianceShop:InitStockPart()
    local layer = self.stock_layer
    local list_width = 558
    local list,list_node = UIKit:commonListView({
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(41, window.bottom_top,list_width , window.betweenHeaderAndTab - 100),
    })
    list_node:addTo(layer):align(display.BOTTOM_CENTER, window.cx,window.bottom_top+20)
    self.stock_listview = list


    local function __createListItem(w,h)
        local item = list:newItem()
        item:setItemSize(w, h)
        list:addItem(item)
        return item
    end


    -- 道具部分
    local box_width = 130
    local goods_item_height = 176
    local origin_x = box_width/2
    local row_count = 4
    local gap_x = 10

    -- 高级道具
    -- title
    local title_item = __createListItem(list_width,50)
    local title_bg = display.newSprite("title_purple_558x34.png")
    UIKit:ttfLabel({
        text = _("高级道具"),
        size = 22,
        color = 0xffedae,
    }):align(display.CENTER, title_bg:getContentSize().width/2, title_bg:getContentSize().height/2):addTo(title_bg)
    title_item:addContent(title_bg)

    -- 高级道具 box table
    self.stock_boxes = {}

    -- 道具部分
    local row_items = {}
    local super_items = UtilsForItem:GetAdvanceItems()
    for i=1,#super_items do
        local super_item = super_items[i]
        if self:CheckSell(super_item.name) then
            table.insert(row_items,super_item)
        end
        if LuaUtils:table_size(row_items) == 4 or (i == #super_items and LuaUtils:table_size(row_items)>0)then
            local goods_item = __createListItem(list_width,goods_item_height)
            local node = display.newNode()
            node:setContentSize(cc.size(list_width,goods_item_height))
            for i,v in ipairs(row_items) do
                self.stock_boxes[v.name] = self:CreateStockGoodsBox(v):addTo(node):pos(origin_x+(i-1)*(gap_x+box_width), goods_item_height/2)
            end
            goods_item:addContent(node)
            row_items = {}
        end
    end

    list:reload()
end

function GameUIAllianceShop:InitRecordPart()
    local layer = self.goods_record_layer
    local list,list_node = UIKit:commonListView({
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(41, window.bottom_top,568 , window.betweenHeaderAndTab-100),
    })
    list_node:addTo(layer):align(display.BOTTOM_CENTER, window.cx,window.bottom_top+20)
    self.record_list = list

    local item_logs = self.alliance.itemLogs
    if LuaUtils:table_size(item_logs) == 0 then
        NetManager:getItemLogsPromise(self.alliance.id):done(function ( response )
            local item_logs = response.msg.itemLogs
            if item_logs then
                self.record_logs_items = {}
                local clone_items = clone(item_logs)
                table.sort( clone_items, function ( a,b )
                    return a.time > b.time
                end )
                for i,v in ipairs(clone_items) do
                    self:CreateRecordItem(v)
                end
                self.record_list:reload()
                self.alliance.itemLogs = item_logs
                return response
            end
        end)
    else
        self.record_logs_items = {}
        local clone_items = clone(item_logs)
        table.sort( clone_items, function ( a,b )
            return a.time > b.time
        end )
        for i,v in ipairs(clone_items) do
            self:CreateRecordItem(v)
        end
        self.record_list:reload()
    end
end

function GameUIAllianceShop:CreateRecordItem(item_log,index)
    local item = self.record_list:newItem()
    local item_width,item_height = 568 , 110
    item:setItemSize(item_width, item_height)

    local content = display.newSprite("back_ground_568x110.png")

    local item_bg = display.newSprite("box_118x118.png"):addTo(content):align(display.CENTER, 58, item_height/2):scale(0.8)
    -- tool image
    local goods_icon = display.newSprite(UILib.item[item_log.itemName]):align(display.CENTER, item_bg:getContentSize().width/2, item_bg:getContentSize().height/2)
        :addTo(item_bg)
    goods_icon:scale(100/goods_icon:getContentSize().width)

    local record_type = item_log.type
    local color_1 = record_type == "addItem" and 0x007c23 or 0x7e0000
    local text_1 = record_type == "addItem" and _("补充") or _("购买")
    UIKit:ttfLabel({
        text = text_1..Localize_item.item_name[item_log.itemName].."X"..item_log.itemCount,
        size = 20,
        color = color_1,
    }):align(display.LEFT_CENTER, 120 , 80)
        :addTo(content)


    UIKit:ttfLabel({
        text = item_log.playerName,
        size = 20,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER, 120 , 30)
        :addTo(content)

    UIKit:ttfLabel({
        text = GameUtils:formatTimeStyle2(item_log.time/1000),
        size = 20,
        color = 0x615b44,
    }):align(display.RIGHT_CENTER, 528 , 30)
        :addTo(content)

    item:addContent(content)
    self.record_list:addItem(item,index)

    self.record_logs_items[item_log.time..item_log.playerName] = item
end
function GameUIAllianceShop:OnBuildingInfoChange(building)
    if building.name == 'shop' then
        self:InitUnLockItems()
        if self.goods_listview then
            self.goods_listview:removeAllItems()
            self:InitGoodsPart()
        end
        if  self.stock_listview then
            self.stock_listview:removeAllItems()
            self:InitStockPart()
        end
    end
end
function GameUIAllianceShop:OnAllianceDataChanged_basicInfo(alliance, deltaData)
    local ok, value = deltaData("basicInfo.honour")
    if ok and self.honourAndLoyalty then
        self.honourAndLoyalty:SetHonour(value)
    end
end
function GameUIAllianceShop:OnAllianceDataChanged_buildings(alliance, deltaData)
    local ok, value = deltaData("buildings")
    if ok then
        self:InitUnLockItems()
        if self.goods_listview then
            self.goods_listview:removeAllItems()
            self:InitGoodsPart()
        end
        if  self.stock_listview then
            self.stock_listview:removeAllItems()
            self:InitStockPart()
        end
    end
end
function GameUIAllianceShop:OnAllianceDataChanged_itemLogs(alliance, deltaData)
    if self.record_list then
        local ok, value = deltaData("itemLogs.add")
        if LuaUtils:table_size(alliance.itemLogs) == 1 then
            self.record_list:removeAllItems()
        end
        if ok then
            for i,v in ipairs(value) do
                self:CreateRecordItem(v,1)
                self.record_list:reload()
            end
        end
        local ok, value = deltaData("itemLogs.remove")
        if ok then
            for i,v in ipairs(value) do
                local record_item = self.record_logs_items[v.time..v.playerName]
                if record_item then
                    self.record_list:removeItem(record_item)
                end
            end
        end
    end
end
function GameUIAllianceShop:OnAllianceDataChanged_items(alliance, deltaData)
    local aln = self.alliance
    local ok, value = deltaData("items.add")
    if ok then
        for i,v in ipairs(value) do
            if self.stock_boxes and self.stock_boxes[v.name] then
                self.stock_boxes[v.name]:SetOwnCount(aln:GetItemCount(v.name))
            end
            if self.super_goods_boxes and self.super_goods_boxes[v.name] then
                self.super_goods_boxes[v.name]:SetOwnCount(aln:GetItemCount(v.name))
            end
        end
    end
    local ok, value = deltaData("items.edit")
    if ok then
        for i,v in ipairs(value) do
            if self.stock_boxes and self.stock_boxes[v.name] then
                self.stock_boxes[v.name]:SetOwnCount(aln:GetItemCount(v.name))
            end
            if self.super_goods_boxes and self.super_goods_boxes[v.name] then
                self.super_goods_boxes[v.name]:SetOwnCount(aln:GetItemCount(v.name))
            end
        end
    end
    local ok, value = deltaData("items.remove")
    if ok then
        for i,v in ipairs(value) do
            if self.stock_boxes and self.stock_boxes[v.name] then
                self.stock_boxes[v.name]:SetOwnCount(aln:GetItemCount(v.name))
            end
            if self.super_goods_boxes and self.super_goods_boxes[v.name] then
                self.super_goods_boxes[v.name]:SetOwnCount(aln:GetItemCount(v.name))
            end
        end
    end
end
function GameUIAllianceShop:OnUserDataChanged_allianceData(userData, deltaData)
    self.honourAndLoyalty:SetLoyalty(userData.allianceData.loyalty)
end

return GameUIAllianceShop


























