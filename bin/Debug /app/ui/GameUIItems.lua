--
-- Author: Kenny Dai
-- Date: 2015-01-23 09:34:06
--
local WidgetRoundTabButtons = import("..widget.WidgetRoundTabButtons")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local UIListView = import(".UIListView")
local Localize_item = import("..utils.Localize_item")
local UILib = import("..ui.UILib")
local Item = import("..entity.Item")
local MaterialManager = import("..entity.MaterialManager")
local WidgetUseItems = import("..widget.WidgetUseItems")

local GameUIItems = UIKit:createUIClass("GameUIItems","GameUIWithCommonHeader")

function GameUIItems:ctor(city,default_tab)
    GameUIItems.super.ctor(self,city,_("道具"))

    -- 记录选中的tab，切换商城和我的道具标签时，保持切过去的和当前的选中同一个tab
    self.top_tab = nil
    self.default_tab = default_tab
end
function GameUIItems:OnMoveInStage()
    GameUIItems.super.OnMoveInStage(self)
    self:CreateTabButtons({
        {
            label = _("商城"),
            tag = "shop",
            default = self.default_tab == "shop"
        },
        {
            label = _("我的道具"),
            tag = "myItems",
            default = self.default_tab == "myItems"
        },
    }, function(tag)
        self.shop_layer:setVisible(tag == 'shop')
        self.myItems_layer:setVisible(tag == 'myItems')
        if tag == 'shop' then
            if not self.shop_dropList then
                self:InitShop()
            end
            if self.top_tab and self.shop_dropList then
                self.shop_dropList:PushButton(self.shop_dropList:GetTabByTag(self.top_tab))
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
        {tag = "menu_1",label = "特殊" , default = self.default_tab == "shop"},
        {tag = "menu_2",label = "持续增益"},
        {tag = "menu_3",label = "资源"},
        {tag = "menu_4",label = "时间加速"},
    }, function(tag)
        self.top_tab = tag
        self:ReloadShopList(tag)
    end):align(display.TOP_CENTER,window.cx,window.top-84):addTo(layer)
end
function GameUIItems:ReloadShopList( tag ,isRefresh)
    self.shop_select_tag = tag
    if isRefresh then
        self.shop_listview:asyncLoadWithCurrentPosition_()
    else
        self.shop_listview:reload()
    end
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
    elseif UIListView.ASY_REFRESH == tag then
        for i,v in ipairs(listView:getItems()) do
            if v.idx_ == idx then
                local content = v:getContent()
                content:SetData(idx)
                local size = content:getContentSize()
                v:setItemSize(size.width, size.height)
            end
        end
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
    }):align(display.LEFT_CENTER, 14 , title_bg:getContentSize().height/2)
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
        size = 20,
        color = 0x615b44,
        dimensions = cc.size(380,0)
    }):align(display.LEFT_CENTER, 19 , 38)
        :addTo(desc_bg)
    local item_bg = display.newSprite("box_118x118.png"):addTo(content):align(display.TOP_CENTER,  70, item_height-10)
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
        self.button = cc.ui.UIPushButton.new({normal = "green_btn_up_148x76.png",pressed = "green_btn_down_148x76.png"})
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
        {tag = "menu_1",label = "特殊",default = self.default_tab == "myItems"},
        {tag = "menu_2",label = "持续增益"},
        {tag = "menu_3",label = "资源"},
        {tag = "menu_4",label = "时间加速"},
    }, function(tag)
        self.top_tab = tag
        self:ReloadMyItemsList(tag)
    end):align(display.TOP_CENTER,window.cx,window.top-84):addTo(layer)
end
function GameUIItems:ReloadMyItemsList( tag ,isRefresh)
    self.my_item_tag = tag
    if isRefresh then
        self.myItems_listview:asyncLoadWithCurrentPosition_()
    else
        self.myItems_listview:reload()
    end
end
function GameUIItems:FilterMyItems( items )
    local f_items = {}
    for i,v in ipairs(items) do
        if v:Count() > 0 then
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
    elseif UIListView.ASY_REFRESH == tag then
        for i,v in ipairs(listView:getItems()) do
            if v.idx_ == idx then
                local content = v:getContent()
                content:SetData(idx)
                local size = content:getContentSize()
                v:setItemSize(size.width, size.height)
            end
        end
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
    }):align(display.LEFT_CENTER, 16 , title_bg:getContentSize().height/2)
        :addTo(title_bg)

    local desc = UIKit:ttfLabel({
        text = items:GetLocalizeDesc(),
        size = 18,
        color = 0x615b44,
        dimensions = cc.size(260,0)
    }):align(display.LEFT_TOP, 152 , item_height-60)
        :addTo(content)

    local icon_bg = WidgetUIBackGround.new({width = 120,height = 154},WidgetUIBackGround.STYLE_TYPE.STYLE_4)
        :addTo(content):align(display.CENTER, 70, item_height/2)
    local num_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(118,36),cc.rect(15,10,136,64)):addTo(icon_bg):align(display.CENTER, icon_bg:getContentSize().width/2, 20)
    local item_bg = display.newSprite("box_118x118.png"):addTo(icon_bg):align(display.CENTER, icon_bg:getContentSize().width/2, icon_bg:getContentSize().height-60)


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
                    size = 22,
                    color = 0xffedae,
                    shadow = true
                }))
                :onButtonClicked(function(event)
                    if event.name == "CLICKED_EVENT" then
                        parent:UseItemFunc(items)
                    end
                end)
                :align(display.RIGHT_BOTTOM, item_width-10, 15)
                :addTo(self)
        end
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
        -- 木,铜,银,金宝箱
        local clone_items
        if string.find(name,"chest") then
            -- 需要对应的钥匙
            if name == "chest_2" then
                if ItemManager:GetItemByName("chestKey_2"):Count() < 1 then
                    UIKit:showMessageDialog(_("主人"),_("开启铜宝箱需要铜钥匙"))
                    return
                end
            elseif name == "chest_3" then
                if ItemManager:GetItemByName("chestKey_3"):Count() < 1 then
                    UIKit:showMessageDialog(_("主人"),_("开启银宝箱需要银钥匙"))
                    return
                end
            elseif name == "chest_4" then
                if ItemManager:GetItemByName("chestKey_4"):Count() < 1 then
                    UIKit:showMessageDialog(_("主人"),_("开启金宝箱需要金钥匙"))
                    return
                end
            end
            clone_items = clone(ItemManager:GetItems())
        end
        NetManager:getUseItemPromise(items:Name(),{}):done(function (response)
            local message = ""
            local awards = {}
            if string.find(name,"dragonChest") then
                for i,v in ipairs(response.msg.playerData) do
                    if string.find(v[1],"dragonMaterials") then
                        local m_name = string.split(v[1], ".")[2]
                        local m_count = v[2]-clone_dragon_materials[m_name]
                        message = message .. Localize.equip_material[m_name].."x"..m_count.." "
                        table.insert(awards, {name = m_name, count = m_count})
                    end
                end
                -- GameGlobalUI:showTips(_("获得"),message)
            elseif string.find(name,"chest") then
                LuaUtils:outputTable("name", response)
                for i,v in ipairs(response.msg.playerData) do
                    if tolua.type(v[2]) == "table" then
                        local m_name = v[2].name
                        local m_count = v[2].count - clone_items[v[2].name]:Count()
                        message = message .. Localize_item.item_name[m_name].."x"..m_count.." "
                        table.insert(awards, {name = m_name, count = m_count})
                    end
                end
                -- GameGlobalUI:showTips(_("获得"),message)
            end
            -- 提示统一动画播放之后提示
            UIKit:PlayUseItemAni(items,awards,message)
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
    if changed_map[1] and #changed_map[1] > 0  then
        if self.myItems_layer:isVisible() then
            self:ReloadMyItemsList( self.my_item_tag , true)
        end
        if self.shop_layer:isVisible() then
            self:ReloadShopList( self.shop_select_tag, true)
        end
    end
    if changed_map[2] and #changed_map[2] > 0 then
        if self.myItems_layer:isVisible() then
            self:ReloadMyItemsList( self.my_item_tag, true)
        end
        if self.shop_layer:isVisible() then
            self:ReloadShopList( self.shop_select_tag, true)
        end
    end
    if changed_map[3] and #changed_map[3] > 0 then
        if self.myItems_layer:isVisible() then
            self:ReloadMyItemsList( self.my_item_tag, true)
        end
        if self.shop_layer:isVisible() then
            self:ReloadShopList( self.shop_select_tag, true)
        end
    end
end
return GameUIItems


































