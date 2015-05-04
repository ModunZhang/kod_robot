--
-- Author: Kenny Dai
-- Date: 2015-01-23 09:34:06
--
local WidgetDropList = import("..widget.WidgetDropList")
local WidgetRoundTabButtons = import("..widget.WidgetRoundTabButtons")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local Localize_item = import("..utils.Localize_item")
local UILib = import("..ui.UILib")
local Item = import("..entity.Item")
local MaterialManager = import("..entity.MaterialManager")
local WidgetUseItems = import("..widget.WidgetUseItems")

local GameUIItems = UIKit:createUIClass("GameUIItems","GameUIWithCommonHeader")

function GameUIItems:ctor(city)
    GameUIItems.super.ctor(self,city,_("道具"))

    -- 记录选中的tab，切换商城和我的道具标签时，保持切过去的和当前的选中同一个tab
    self.top_tab = nil
end
function GameUIItems:OnMoveInStage()
    GameUIItems.super.OnMoveInStage(self)
    self:CreateTabButtons({
        {
            label = _("商城"),
            tag = "shop",
            default = true
        },
        {
            label = _("我的道具"),
            tag = "myItems",
        },
    }, function(tag)
        self.shop_layer:setVisible(tag == 'shop')
        self.myItems_layer:setVisible(tag == 'myItems')
        if tag == 'shop' then
            if self.top_tab and self.shop_dropList then
                self.shop_dropList:PushButton(self.shop_dropList:GetTabByTag(self.top_tab))
            end
            if not self.shop_dropList then
                self:InitShop()
            end
        end
        if tag == 'myItems' then
            if not self.myItems_dropList then
                self:InitMyItems()
            end
            if self.top_tab and self.myItems_dropList then
                self.myItems_dropList:PushButton(self.myItems_dropList:GetTabByTag(self.top_tab))
            end
        end
    end):pos(window.cx, window.bottom + 34)

    ItemManager:AddListenOnType(self,ItemManager.LISTEN_TYPE.ITEM_CHANGED)
end
function GameUIItems:CreateBetweenBgAndTitle()
    GameUIItems.super.CreateBetweenBgAndTitle(self)
    -- shop_layer
    self.shop_layer = cc.Layer:create():addTo(self:GetView())
    -- myItems_layer
    self.myItems_layer = cc.Layer:create():addTo(self:GetView())
end
function GameUIItems:onExit()
    ItemManager:RemoveListenerOnType(self,ItemManager.LISTEN_TYPE.ITEM_CHANGED)
    GameUIItems.super.onExit(self)
end

function GameUIItems:InitShop()
    local layer = self.shop_layer
    local list,list_node = UIKit:commonListView({
        async = true, --异步加载
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,568,window.betweenHeaderAndTab-110),
    })
    list_node:addTo(layer):align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20)
    list:setRedundancyViewVal(list:getViewRect().height + 76 * 2)
    list:setDelegate(handler(self, self.sourceDelegate))
    self.shop_listview = list

    self.shop_dropList = WidgetRoundTabButtons.new({
        {tag = "menu_1",label = "特殊",default = true},
        {tag = "menu_2",label = "持续增益"},
        {tag = "menu_3",label = "增益"},
        {tag = "menu_4",label = "时间加速"},
    }, function(tag)
        self.top_tab = tag
        self.shop_items = {}
        self:ReloadShopList(tag)
    end):align(display.TOP_CENTER,window.cx,window.top-84):addTo(layer)
end
function GameUIItems:ReloadShopList( tag )
    self.shop_select_tag = tag
    self.shop_listview:reload()
end
function GameUIItems:sourceDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self:GetShopItemByTag(self.shop_select_tag)
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateShopContentByIndex(idx)

            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetData(idx)

        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        return item
    else
    end
end
function GameUIItems:FilterShopItems( items )
    local f_items = {}
    for i,v in ipairs(items) do
        if v:IsSell() then
            table.insert(f_items, v)
        end
    end
    return f_items
end
function GameUIItems:GetShopItemByTag(tag)
    if tag == 'menu_1' then
        return self:FilterShopItems(ItemManager:GetSpecialItems())
    elseif tag == 'menu_2' then
        return self:FilterShopItems(ItemManager:GetBuffItems())
    elseif tag == 'menu_3' then
        return  self:FilterShopItems(ItemManager:GetResourcetItems())
    elseif tag == 'menu_4' then
        return self:FilterShopItems(ItemManager:GetSpeedUpItems())
    end
end
function GameUIItems:CreateShopContentByIndex( idx )
    local items = self:GetShopItemByTag(self.shop_select_tag)[idx]

    local item_width,item_height = 568,212

    local content = WidgetUIBackGround.new({width = item_width,height=item_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)

    local title_bg = display.newScale9Sprite("title_blue_430x30.png",item_width/2+66,item_height-28,cc.size(428,30),cc.rect(15,10,400,10))
        :addTo(content)
    local item_name = UIKit:ttfLabel({
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 18 , title_bg:getContentSize().height/2)
        :addTo(title_bg)

    local own_num = UIKit:ttfLabel({
        text = _("拥有")..":"..string.formatnumberthousands(items:Count()),
        size = 22,
        color = 0x403c2f,
    }):align(display.LEFT_CENTER, 154 , 130)
        :addTo(content)

    local desc_bg = display.newScale9Sprite("back_ground_166x84.png",136 , 10,cc.size(426,76),cc.rect(15,10,136,64))
        :align(display.LEFT_BOTTOM)
        :addTo(content)

    local desc = UIKit:ttfLabel({
        size = 18,
        color = 0x797154,
        dimensions = cc.size(380,0)
    }):align(display.LEFT_CENTER, 19 , 38)
        :addTo(desc_bg)
    -- local icon_bg = display.newSprite("box_120x154.png"):addTo(content):align(display.CENTER, 70, item_height/2)
    local item_bg = display.newSprite("box_118x118.png"):addTo(content):align(display.TOP_CENTER,  70, item_height-10)
    -- local item_icon_color_bg = display.newSprite("box_item_100x100.png"):addTo(item_bg):align(display.CENTER, item_bg:getContentSize().width/2, item_bg:getContentSize().height/2)
    local i_icon = display.newSprite("goods_26x26.png"):addTo(item_bg,2):align(display.CENTER, 15, 15)
    local parent = self
    function content:SetOwnCount( new_item )
        own_num:setString(_("拥有")..":"..string.formatnumberthousands(new_item:Count()))
        if not parent:IsItemCouldUseInShop(new_item) or new_item:Count()<1 then
            self.use_button:setButtonEnabled(false)
        else
            self.use_button:setButtonEnabled(true)
        end
    end
    function content:SetData( idx )
        local items = parent:GetShopItemByTag(parent.shop_select_tag)[idx]
        local item_iamge = UILib.item[items:Name()]

        if item_iamge then
            if self.item_icon then
                item_bg:removeChild(self.item_icon, true)
            end
            local item_icon = display.newSprite(UILib.item[items:Name()]):addTo(item_bg):align(display.CENTER, item_bg:getContentSize().width/2, item_bg:getContentSize().height/2)

            item_icon:scale(100/item_icon:getContentSize().width)
            self.item_icon = item_icon
        end
        desc:setString(items:GetLocalizeDesc())
        item_name:setString(items:GetLocalizeName())
        if self.button then
            self:removeChild(self.button, true)
        end
        self.button = cc.ui.UIPushButton.new({normal = "green_btn_up_148x70.png",pressed = "green_btn_down_148x70.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("购买"),
                size = 20,
                color = 0xffedae,
                shadow = true
            }))
            :setButtonLabelOffset(0, 16)
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    if items:Price() > User:GetGemResource():GetValue() then
                        UIKit:showMessageDialog(_("提示"),_("金龙币不足"))
                            :CreateOKButton(
                                {
                                    listener = function ()
                                        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                    end,
                                    btn_name= _("前往商店")
                                }
                            )
                    else
                        NetManager:getBuyItemPromise(items:Name(),1)
                    end
                end
            end)
            :align(display.RIGHT_BOTTOM, item_width-10, 90)
            :addTo(self)

        local num_bg = display.newSprite("back_ground_124x28.png"):addTo(self.button):align(display.CENTER, -70, 22)
        -- gem icon
        local gem_icon = display.newSprite("gem_icon_62x61.png"):addTo(num_bg):align(display.CENTER, 20, num_bg:getContentSize().height/2):scale(0.6)
        local price = UIKit:ttfLabel({
            text = string.formatnumberthousands(items:Price()),
            size = 18,
            color = 0xffd200,
        }):align(display.LEFT_CENTER, 50 , num_bg:getContentSize().height/2)
            :addTo(num_bg)


        if self.use_button then
            self:removeChild(self.use_button, true)
        end
        self.use_button = cc.ui.UIPushButton.new({normal = "blue_btn_up_112x58.png",pressed = "blue_btn_down_112x58.png",disabled = "grey_btn_112x58.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("使用"),
                size = 24,
                color = 0xffedae,
                shadow = true
            }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    parent:UseItemFunc(items)
                end
            end)
            :align(display.LEFT_BOTTOM, 14, 16)
            :addTo(self)
        if not parent:IsItemCouldUseInShop(items) or items:Count()<1 then
            self.use_button:setButtonEnabled(false)
        end
        self:SetOwnCount( items )
        parent.shop_items[items:Name()] = self
    end
    return content
end
function GameUIItems:IsItemCouldUseInShop(items)
    if items:Category()~=Item.CATEGORY.SPEEDUP
        and items:Name()~="movingConstruction"
        and items:Name()~="torch"
        and items:Name()~="retreatTroop"
        and items:Name()~="moveTheCity"
        and items:Name()~="chestKey_2"
        and items:Name()~="chestKey_3"
        and items:Name()~="chestKey_4"
    then
        return true
    end
end
function GameUIItems:IsItemCouldUseNow(items)
    if items:Name()~="changePlayerName"
        and items:Name()~="changeCityName"
        and items:Name()~="dragonExp_1"
        and items:Name()~="dragonExp_2"
        and items:Name()~="dragonExp_3"
        and items:Name()~="dragonHp_1"
        and items:Name()~="dragonHp_2"
        and items:Name()~="dragonHp_3"
    then
        return true
    end
end
function GameUIItems:InitMyItems()
    local layer = self.myItems_layer
    local list,list_node = UIKit:commonListView({
        async = true, --异步加载
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0, 0,568,window.betweenHeaderAndTab-110),
    })
    list_node:addTo(layer):align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20)
    list:setRedundancyViewVal(list:getViewRect().height + 76 * 2)
    list:setDelegate(handler(self, self.myItemSourceDelegate))
    self.myItems_listview = list

    self.myItems_dropList = WidgetRoundTabButtons.new({
        {tag = "menu_1",label = "特殊"},
        {tag = "menu_2",label = "持续增益"},
        {tag = "menu_3",label = "增益"},
        {tag = "menu_4",label = "时间加速"},
    }, function(tag)
        self.top_tab = tag
        self.my_items = {}
        self:ReloadMyItemsList(tag)
    end):align(display.TOP_CENTER,window.cx,window.top-84):addTo(layer)
end
function GameUIItems:ReloadMyItemsList( tag )
    self.my_item_tag = tag
    self.myItems_listview:reload()
end
function GameUIItems:FilterMyItems( items )
    local f_items = {}
    for i,v in ipairs(items) do
        if v:Count()>0 then
            table.insert(f_items, v)
        end
    end
    return f_items
end
function GameUIItems:GetMyItemByTag(tag)
    if tag == 'menu_1' then
        return self:FilterMyItems(ItemManager:GetSpecialItems())
    elseif tag == 'menu_2' then
        return self:FilterMyItems(ItemManager:GetBuffItems())
    elseif tag == 'menu_3' then
        return  self:FilterMyItems(ItemManager:GetResourcetItems())
    elseif tag == 'menu_4' then
        return self:FilterMyItems(ItemManager:GetSpeedUpItems())
    end
end
function GameUIItems:myItemSourceDelegate(listView, tag, idx)
    if cc.ui.UIListView.COUNT_TAG == tag then
        return #self:GetMyItemByTag(self.my_item_tag)
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:CreateMyItemContentByIndex(idx)

            item:addContent(content)
        else
            content = item:getContent()
        end
        content:SetData(idx)
        local size = content:getContentSize()
        item:setItemSize(size.width, size.height)
        return item
    else
    end
end
function GameUIItems:CreateMyItemContentByIndex( idx )
    local items = self:GetMyItemByTag(self.my_item_tag)[idx]
    local item_width,item_height = 568,164

    local content = WidgetUIBackGround.new({width = item_width,height=item_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)

    local title_bg = display.newScale9Sprite("title_blue_430x30.png",item_width/2+66,item_height-28,cc.size(428,30),cc.rect(15,10,400,10))
        :addTo(content)
    local item_name = UIKit:ttfLabel({
        text = items:GetLocalizeName(),
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 20 , title_bg:getContentSize().height/2)
        :addTo(title_bg)

    local desc = UIKit:ttfLabel({
        text = items:GetLocalizeDesc(),
        size = 18,
        color = 0x797154,
        dimensions = cc.size(260,0)
    }):align(display.LEFT_TOP, 156 , item_height-60)
        :addTo(content)

    local icon_bg = display.newSprite("box_120x154.png"):addTo(content):align(display.CENTER, 70, item_height/2)
    local num_bg = display.newSprite("back_ground_118x36.png"):addTo(icon_bg):align(display.CENTER, icon_bg:getContentSize().width/2, 20)
    local item_bg = display.newSprite("box_118x118.png"):addTo(icon_bg):align(display.CENTER, icon_bg:getContentSize().width/2, icon_bg:getContentSize().height-60)
    -- local item_icon_color_bg = display.newSprite("box_item_100x100.png"):addTo(item_bg):align(display.CENTER, item_bg:getContentSize().width/2, item_bg:getContentSize().height/2)
    local i_icon = cc.ui.UIImage.new("goods_26x26.png"):addTo(item_bg,2):align(display.CENTER, 15, 15)


    local own_num = UIKit:ttfLabel({
        text = _("拥有")..string.formatnumberthousands(items:Count()),
        size = 20,
        color = 0x403c2f,
    }):align(display.CENTER, num_bg:getContentSize().width/2 , num_bg:getContentSize().height/2)
        :addTo(num_bg)



    local parent = self
    function content:SetOwnCount( count )
        own_num:setString(_("拥有")..string.formatnumberthousands(count))
    end
    function content:SetData( idx )
        local items = parent:GetMyItemByTag(parent.my_item_tag)[idx]
        self:SetOwnCount(string.formatnumberthousands(items:Count()))
        local item_image =UILib.item[items:Name()]
        if item_image then
            if self.item_icon then
                item_bg:removeChild(self.item_icon, true)
            end
            local item_icon = display.newSprite(UILib.item[items:Name()]):addTo(item_bg):align(display.CENTER, item_bg:getContentSize().width/2, item_bg:getContentSize().height/2)

            item_icon:scale(100/item_icon:getContentSize().width)
            self.item_icon = item_icon
        end
        desc:setString(items:GetLocalizeDesc())
        item_name:setString(items:GetLocalizeName())
        if self.button then
            self:removeChild(self.button, true)
        end
        if parent:IsItemCouldUseInShop(items) then
            self.button = cc.ui.UIPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
                :setButtonLabel(UIKit:ttfLabel({
                    text = _("使用"),
                    size = 20,
                    color = 0xffedae,
                }))
                :onButtonClicked(function(event)
                    if event.name == "CLICKED_EVENT" then
                        parent:UseItemFunc(items)
                    end
                end)
                :align(display.RIGHT_BOTTOM, item_width-10, 15)
                :addTo(self)
        end
        parent.my_items[items:Name()] = self
    end
    return content
end
function GameUIItems:UseItemFunc( items )
    if self:IsItemCouldUseNow(items) then
        local name = items:Name()
        -- 使用巨龙宝箱会获得龙装备材料，需要提示
        local clone_dragon_materials
        if string.find(name,"dragonChest") then
            clone_dragon_materials = clone(self.city:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.DRAGON))
        end
        NetManager:getUseItemPromise(items:Name(),{}):done(function (response)
            if string.find(name,"dragonChest") then
                local message = ""
                for i,v in ipairs(response.msg.playerData) do
                    if string.find(v[1],"dragonMaterials") then
                        local m_name = string.split(v[1], ".")[2]
                        message = message .. Localize.equip_material[m_name].."x"..(v[2]-clone_dragon_materials[m_name]).." "
                    end
                end
                GameGlobalUI:showTips(_("获得"),message)
            end
            UIKit:PlayUseItemAni(items)
        end)
    else
        local dialog = WidgetUseItems.new():Create({
            item = items
        })
        if dialog then
            dialog:AddToCurrentScene()
        end
    end
end
function GameUIItems:OnItemsChanged( changed_map )
    if changed_map[1] then
        for k,v in pairs(changed_map[1]) do
            if self.my_items then
                local item = self.my_items[v:Name()]
                print("GameUIItems:OnItemsChanged add",v:Name(),v:Count())
                if item then
                    item:SetOwnCount( v:Count() )
                end
                self:ReloadMyItemsList( self.my_item_tag)
            end
            if self.shop_items then
                local item = self.shop_items[v:Name()]
                if item then
                    item:SetOwnCount( v )
                end
            end
        end
    end
    if changed_map[2] then
        for k,v in pairs(changed_map[2]) do
            if self.my_items then
                local item = self.my_items[v:Name()]
                print("GameUIItems:OnItemsChanged edit",v:Name(),v:Count())
                if item then
                    item:SetOwnCount( v:Count() )
                end
            end
            if self.shop_items then
                local item = self.shop_items[v:Name()]
                if item then
                    item:SetOwnCount( v )
                end
            end
        end
    end
    if changed_map[3] then
        for k,v in pairs(changed_map[3]) do
            if self.my_items then
                local item = self.my_items[v:Name()]
                print("GameUIItems:OnItemsChanged remove",v:Name(),v:Count())
                if item then
                    item:SetOwnCount(0)
                    self:ReloadMyItemsList( self.my_item_tag)
                end
            end
            if self.shop_items then
                local item = self.shop_items[v:Name()]
                if item then
                    item:SetOwnCount(v)
                end
            end
        end
    end
end
return GameUIItems























