local UIListView = import("..ui.UIListView")
local WidgetRequirementListview = class("WidgetRequirementListview", function ()
    local layer = cc.Layer:create()
    layer:setCascadeOpacityEnabled(true)
    return layer
end)

function WidgetRequirementListview:ctor(parms)
    self.title = parms.title
    self.listview_height = parms.height
    self.listview_width = 520
    self.listParms = parms.listParms
    self.contents = parms.contents

    self.width = 540
    self:setContentSize(cc.size(self.width, self.listview_height+50))
    self:setAnchorPoint(cc.p(0.5,0))

    local list_bg = display.newScale9Sprite("back_ground_540x64.png", 0, 0,cc.size(self.width, self.listview_height))
        :align(display.LEFT_BOTTOM):addTo(self)
    local title_bg = display.newSprite("alliance_evnets_title_548x50.png", x, y):align(display.CENTER_BOTTOM, self.width/2, self.listview_height):addTo(self)
    UIKit:ttfLabel({
        text = self.title ,
        size = 24,
        color = 0xffedae
    }):align(display.CENTER,self.width/2, 25):addTo(title_bg)
    self.listview = UIListView.new({
        viewRect = cc.rect(0,0, self.listview_width, self.listview_height-20),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL})
        :addTo(list_bg,2):pos((self.width-self.listview_width)/2, 12)

    -- 缓存已经添加的升级条件项,供刷新时使用
    self.added_items = {}
    self.top_index = 0
    self.top_index_1 = 0
    self:RefreshListView(self.contents)
end


function WidgetRequirementListview:RefreshListView(contents)
    --有两种背景色的达到要求的显示条，通过meeFlag来确定选取哪一个
    local meetFlag = true
    if not contents then
        return
    end
    for k,v in pairs(contents ) do
        if v.isVisible then
            -- 需求已添加，则更新最新资源数据
            if self.added_items[v.resource_type] then
                local added_resource = self.added_items[v.resource_type]
                local content = added_resource:getContent()
                if meetFlag then
                    content.bg:setTexture("upgrade_resources_background_3.png")
                else
                    content.bg:setTexture("upgrade_resources_background_2.png")
                end
                meetFlag =  not meetFlag
                local split_desc = string.split(v.description, "/")
                if v.isSatisfy then
                    -- 符合条件，添加钩钩图标
                    content.mark:setTexture("yes_40x40.png")
                    local v_1 = tonumber(split_desc[1]) and string.formatnumberthousands(tonumber(split_desc[1])) or split_desc[1]
                    content.resource_value[1]:setString(v_1)
                    content.resource_value[1]:setColor(UIKit:hex2c4b(0x403c2f))
                    if split_desc[2] then
                        content.resource_value[2]:setString("/"..string.formatnumberthousands(tonumber(split_desc[2])))
                        content.resource_value[2]:setColor(UIKit:hex2c4b(0x403c2f))
                        content.resource_value[2]:setPositionX(content.resource_value[1]:getPositionX()+content.resource_value[1]:getContentSize().width)
                    end
                else
                    if v.canNotBuy then
                        content.bg:setTexture("upgrade_resources_background_red.png")
                        content.mark:setTexture("no_40x40.png")
                        if v.jump_call then
                            content.mark:stopAllActions()

                            content.bg:setNodeEventEnabled(true)
                            content.bg:setTouchEnabled(true)
                            content.bg:removeAllNodeEventListeners()
                            content.bg:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
                                if event.name == "ended" then
                                    v.jump_call()
                                end
                                return true
                            end)
                        end
                    else
                        -- 不符合条提案，添加!图标
                        content.mark:setTexture("wow_40x40.png")
                    end
                    -- 条件未达到，自己的数据红色显示
                    local v_1 = tonumber(split_desc[1]) and string.formatnumberthousands(tonumber(split_desc[1])) or split_desc[1]
                    content.resource_value[1]:setString(v_1)
                    content.resource_value[1]:setColor(split_desc[2] and UIKit:hex2c4b(0x7e0000) or UIKit:hex2c4b(0x403c2f))
                    if split_desc[2] then
                        content.resource_value[2]:setString("/"..string.formatnumberthousands(tonumber(split_desc[2])))
                        if v.resource_type == "building_queue" then
                            content.resource_value[2]:setColor(UIKit:hex2c4b(0x7e0000))
                        else
                            content.resource_value[2]:setColor(UIKit:hex2c4b(0x403c2f))
                        end
                        content.resource_value[2]:setPositionX(content.resource_value[1]:getPositionX()+content.resource_value[1]:getContentSize().width)
                    end
                end
            else
                -- 添加新条件
                local item = self.listview:newItem()
                local item_width,item_height = self.listview_width,46
                item:setItemSize(item_width,item_height)
                local content = cc.ui.UIGroup.new()
                --  筛选不同背景颜色 bg
                if meetFlag then
                    content.bg = display.newSprite("upgrade_resources_background_3.png", 0, 0):addTo(content)
                else
                    content.bg = display.newSprite("upgrade_resources_background_2.png", 0, 0):addTo(content)
                end
                meetFlag =  not meetFlag
                local split_desc = string.split(v.description, "/")
                if v.isSatisfy then
                    -- 符合条件，添加钩钩图标
                    content.mark = display.newSprite("yes_40x40.png", item_width/2-25, 0):addTo(content)
                    content.resource_value  = {}
                    local v_1 = tonumber(split_desc[1]) and string.formatnumberthousands(tonumber(split_desc[1])) or split_desc[1]
                    content.resource_value[1] = UIKit:ttfLabel({
                        text = v_1,
                        size = 22,
                        color = 0x403c2f
                    }):align(display.LEFT_CENTER,-180,0):addTo(content)
                    if split_desc[2] then
                        content.resource_value[2] = UIKit:ttfLabel({
                            text = "/"..string.formatnumberthousands(tonumber(split_desc[2])),
                            size = 22,
                            color = 0x403c2f
                        }):align(display.LEFT_CENTER,content.resource_value[1]:getPositionX()+content.resource_value[1]:getContentSize().width,0):addTo(content)
                    end
                else
                    if v.canNotBuy then
                        content.bg = display.newSprite("upgrade_resources_background_red.png", 0, 0):addTo(content)
                        content.mark = display.newSprite("no_40x40.png", item_width/2-25, 0):addTo(content)
                        if v.jump_call then
                            content.mark:removeAllNodeEventListeners()
                            content.mark:stopAllActions()

                            content.mark:setNodeEventEnabled(true)
                            content.mark:setTouchEnabled(true)
                            content.mark:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
                                if event.name == "ended" then
                                    v.jump_call()
                                end
                                return true
                            end)
                        end
                    else
                        -- 不符合条提案，添加X图标
                        content.mark = display.newSprite("wow_40x40.png", item_width/2-25, 0):addTo(content)
                    end
                    -- 条件未达到，自己的数据红色显示
                    content.resource_value  = {}
                    local v_1 = tonumber(split_desc[1]) and string.formatnumberthousands(tonumber(split_desc[1])) or split_desc[1]
                    content.resource_value[1] = UIKit:ttfLabel({
                        text = v_1,
                        size = 22,
                        color = split_desc[2] and 0x7e0000 or 0x403c2f
                    }):align(display.LEFT_CENTER,-180,0):addTo(content)
                    if split_desc[2] then
                        content.resource_value[2] = UIKit:ttfLabel({
                            text = "/"..string.formatnumberthousands(tonumber(split_desc[2])),
                            size = 22,
                            color = v.resource_type == "building_queue" and 0x7e0000 or 0x403c2f
                        }):align(display.LEFT_CENTER,content.resource_value[1]:getPositionX()+content.resource_value[1]:getContentSize().width,0):addTo(content)
                    end
                end
                -- 资源类型icon
                local resource_type_icon = display.newSprite(v.icon, -item_width/2+35, 0):addTo(content)
                local size = resource_type_icon:getContentSize()
                resource_type_icon:setScale(40/math.max(size.width,size.height))
                item:addContent(content)
                local index
                if v.canNotBuy then
                    if not v.isSatisfy then
                        self.top_index = self.top_index + 1
                        index = self.top_index
                    else
                        -- index = self.top_index + 1
                    end
                end
                self.listview:addItem(item,index)
                self.added_items[v.resource_type] = item
                self.listview:reload()
            end
        else
            -- 刷新时已经没有此项条件时，删除之前添加的项
            if self.added_items[v.resource_type] then
                self.listview:removeItem(self.added_items[v.resource_type])
                self.listview:reload()
                self.added_items[v.resource_type] = nil
            end
        end
    end
end

return WidgetRequirementListview















