
--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

--[[--

quick 列表控件
3.2 更新
]]

local UIScrollView = import(".UIScrollView")
local UIListView = class("UIListView", UIScrollView)

local UIListViewItem = import(".UIListViewItem")


UIListView.DELEGATE                 = "ListView_delegate"
UIListView.TOUCH_DELEGATE           = "ListView_Touch_delegate"

UIListView.CELL_TAG                 = "Cell"
UIListView.CELL_SIZE_TAG            = "CellSize"
UIListView.COUNT_TAG                = "Count"
UIListView.CLICKED_TAG              = "Clicked"
UIListView.UNLOAD_CELL_TAG          = "UnloadCell"
UIListView.ASY_REFRESH              = "refresh"

UIListView.BG_ZORDER                = -1
UIListView.CONTENT_ZORDER           = 10

UIListView.ALIGNMENT_LEFT           = 0
UIListView.ALIGNMENT_RIGHT          = 1
UIListView.ALIGNMENT_VCENTER        = 2
UIListView.ALIGNMENT_TOP            = 3
UIListView.ALIGNMENT_BOTTOM         = 4
UIListView.ALIGNMENT_HCENTER        = 5

--[[--

UIListView构建函数

可用参数有：

-   direction 列表控件的滚动方向，默认为垂直方向
-   alignment listViewItem中content的对齐方式，默认为垂直居中
-   viewRect 列表控件的显示区域
-   scrollbarImgH 水平方向的滚动条
-   scrollbarImgV 垂直方向的滚动条
-   bgColor 背景色,nil表示无背景色
-   bgStartColor 渐变背景开始色,nil表示无背景色
-   bgEndColor 渐变背景结束色,nil表示无背景色
-   bg 背景图
-   bgScale9 背景图是否可缩放
-   capInsets 缩放区域


@param table params 参数表

]]
function UIListView:ctor(params)
    UIListView.super.ctor(self, params)

    self.items_ = {}
    self.direction = params.direction or UIScrollView.DIRECTION_VERTICAL
    self.alignment = params.alignment or UIListView.ALIGNMENT_VCENTER
    self.bAsyncLoad = params.async or false
    self.iscleanup = params.iscleanup == nil and true or params.iscleanup
    self.container = display.newNode()
    -- self.padding_ = params.padding or {left = 0, right = 0, top = 0, bottom = 0}

    -- params.viewRect.x = params.viewRect.x + self.padding_.left
    -- params.viewRect.y = params.viewRect.y + self.padding_.bottom
    -- params.viewRect.width = params.viewRect.width - self.padding_.left - self.padding_.right
    -- params.viewRect.height = params.viewRect.height - self.padding_.bottom - self.padding_.top

    self:setDirection(params.direction)
    self:setViewRect(params.viewRect)
    self:addScrollNode(self.container)
    self:onScroll(handler(self, self.scrollListener))

    self.size = {}
    self.itemsFree_ = {}
    self.delegate_ = {}
    self.redundancyViewVal = 0 --异步的视图两个方向上的冗余大小,横向代表宽,竖向代表高
    self.nTest = 0
    self.trackTop = params.trackTop or false -- 是否追终与上边的距离
    self.tipsString = params.tipsString or _("暂时没有内容") -- 统一提示信息
    if type(params.needTips) == 'boolean' then
        self.needTips =  params.needTips
    else
        self.needTips = true
    end
    self.isTipsStringShow = false
    self:setNodeEventEnabled(true)
end

function UIListView:onCleanup()
    self:releaseAllFreeItems_()
end


function UIListView:isTrackTop()
    return self.trackTop
end

--[[--

列表控件触摸注册函数

@param function listener 触摸临听函数

@return UIListView self 自身

]]
function UIListView:onTouch(listener)
    self.touchListener_ = listener

    return self
end

--[[--

列表控件设置所有listItem中content的对齐方式

@param number align 对

@return UIListView self 自身

]]
function UIListView:setAlignment(align)
    self.alignment = align
end

--[[--

创建一个新的listViewItem项

@param node item 要放到listViewItem中的内容content

@return UIListViewItem

]]
function UIListView:newItem(item)
    item = UIListViewItem.new(item)
    item:setDirction(self.direction)
    item:onSizeChange(handler(self, self.itemSizeChangeListener))

    return item
end

--[[--

设置显示区域

@return UIListView self

]]
function UIListView:setViewRect(viewRect)
    if UIScrollView.DIRECTION_VERTICAL == self.direction then
        self.redundancyViewVal = viewRect.height
    else
        self.redundancyViewVal = viewRect.width
    end

    UIListView.super.setViewRect(self, viewRect)
end

function UIListView:itemSizeChangeListener(listItem, newSize, oldSize, ani)
    local pos = self:getItemPos(listItem)
    if not pos then
        return
    end

    local itemW, itemH = newSize.width - oldSize.width, newSize.height - oldSize.height
    if UIScrollView.DIRECTION_VERTICAL == self.direction then
        itemW = 0
    else
        itemH = 0
    end
    local ani_time = 0.2
    if ani then
        local content = listItem:getContent()
        transition.moveBy(content,
            {x = itemW/2, y = itemH/2, time = ani_time})
        if self.bAsyncLoad then -- 修改quick bug 异步加载时的size变动处理
            if UIScrollView.DIRECTION_VERTICAL == self.direction then
                transition.moveBy(self.container,
                    {x = -itemW, y = -itemH, time = ani_time})
                self:moveItems(1, pos - 1, itemW, itemH, ani)
        else
            self:moveItems(pos + 1, table.nums(self.items_), itemW, itemH, ani)
        end
        else
            self.size.width = self.size.width + itemW
            self.size.height = self.size.height + itemH
            if UIScrollView.DIRECTION_VERTICAL == self.direction then
                transition.moveBy(self.container,
                    {x = -itemW, y = -itemH, time = ani_time,})
                self:moveItems(1, pos - 1, itemW, itemH, ani)
            else
                self:moveItems(pos + 1, table.nums(self.items_), itemW, itemH, ani)
            end
        end
    else
        local content = listItem:getContent()
        local x,y = content:getPosition()
        content:pos(x + itemW/2, y + itemH/2)
        if self.bAsyncLoad then -- 修改quick bug 异步加载时的size变动处理
            if UIScrollView.DIRECTION_VERTICAL == self.direction then
                local x,y = self.container:getPosition()
                self.container:pos(x - itemW, y - itemH)
                self:moveItems(1, pos - 1, itemW, itemH, ani)
        else
            self:moveItems(pos + 1, table.nums(self.items_), itemW, itemH, ani)
        end
        else
            self.size.width = self.size.width + itemW
            self.size.height = self.size.height + itemH
            if UIScrollView.DIRECTION_VERTICAL == self.direction then
                local x,y = self.container:getPosition()
                self.container:pos(x - itemW, y - itemH)
                self:moveItems(1, pos - 1, itemW, itemH, ani)
            else
                self:moveItems(pos + 1, table.nums(self.items_), itemW, itemH, ani)
            end
        end
    end

end

function UIListView:scrollListener(event)
    if "clicked" == event.name then
        local nodePoint = self.container:convertToNodeSpace(cc.p(event.x, event.y))
        local pos
        local idx

        if self.bAsyncLoad then
            local itemRect
            for i,v in ipairs(self.items_) do
                local posX, posY = v:getPosition()
                local itemW, itemH = v:getItemSize()
                itemRect = cc.rect(posX, posY, itemW, itemH)
                if cc.rectContainsPoint(itemRect, nodePoint) then
                    idx = v.idx_
                    pos = i
                    break
                end
            end
        else
            nodePoint.x = nodePoint.x - self.viewRect_.x
            nodePoint.y = nodePoint.y - self.viewRect_.y

            local width, height = 0, self.size.height
            local itemW, itemH = 0, 0

            if UIScrollView.DIRECTION_VERTICAL == self.direction then
                for i,v in ipairs(self.items_) do
                    itemW, itemH = v:getItemSize()

                    if nodePoint.y < height and nodePoint.y > height - itemH then
                        pos = i
                        idx = pos
                        nodePoint.y = nodePoint.y - (height - itemH)
                        break
                    end
                    height = height - itemH
                end
            else
                for i,v in ipairs(self.items_) do
                    itemW, itemH = v:getItemSize()

                    if nodePoint.x > width and nodePoint.x < width + itemW then
                        pos = i
                        idx = pos
                        break
                    end
                    width = width + itemW
                end
            end
        end

        self:notifyListener_{name = "clicked",
            listView = self, itemPos = idx, item = self.items_[pos],
            point = nodePoint}
    else
        event.scrollView = nil
        event.listView = self
        self:notifyListener_(event)
    end

end

--[[--

在列表项中添加一项

@param node listItem 要添加的项
@param [integer pos] 要添加的位置

@return UIListView

]]
function UIListView:addItem(listItem, pos)
    self:modifyItemSizeIf_(listItem)

    if pos then
        table.insert(self.items_, pos, listItem)
    else
        table.insert(self.items_, listItem)
    end
    self.container:addChild(listItem)

    return self
end

--[[--

在列表项中移除一项

@param node listItem 要移除的项
@param [boolean bAni] 是否要显示移除动画

@return UIListView

]]
function UIListView:removeItem(listItem, bAni)
    assert(not self.bAsyncLoad, "UIListView:removeItem() - syncload not support remove")

    local itemW, itemH = listItem:getItemSize()
    self.container:removeChild(listItem)

    local pos = self:getItemPos(listItem)
    if pos then
        table.remove(self.items_, pos)
    end

    if UIScrollView.DIRECTION_VERTICAL == self.direction then
        itemW = 0
    else
        itemH = 0
    end

    self.size.width = self.size.width - itemW
    self.size.height = self.size.height - itemH
    if UIScrollView.DIRECTION_VERTICAL == self.direction then
        if pos == 1 then
            self:moveItems(1, #self.items_, -itemW, itemH, bAni)
        else
            self:moveItems(1, pos - 1, -itemW, -itemH, bAni)
        end
    else
        self:moveItems(pos, table.nums(self.items_), -itemW, -itemH, bAni)
    end

    return self
end

--[[--

移除所有的项

@return integer

]]
function UIListView:removeAllItems()
    self.container:removeAllChildren()
    self.items_ = {}

    return self
end

--[[--

取某项在列表控件中的位置

@param node listItem 列表项

@return integer

]]
function UIListView:getItemPos(listItem)
    for i,v in ipairs(self.items_) do
        if v == listItem then
            return i
        end
    end
end

--[[--

判断某项是否在列表控件的显示区域中

@param integer pos 列表项位置

@return boolean

]]
function UIListView:isItemInViewRect(pos)
    local item
    --修改quick 如果异步修改获取item方式
    if self.bAsyncLoad then
        item = self:getItemWithLogicIndex(pos)
    else
        if "number" == type(pos) then
            item = self.items_[pos]
        elseif "userdata" == type(pos) then
            item = pos
        end
    end
    if not item then
        return
    end

    local bound = item:getBoundingBox()
    local nodePoint = self.container:convertToWorldSpace(
        cc.p(bound.x, bound.y))
    bound.x = nodePoint.x
    bound.y = nodePoint.y

    return cc.rectIntersectsRect(self.viewRect_, bound)
end

function UIListView:addCommonTipsNodeIf__()
    if #self.items_ == 0 then
        local item = self:newItem()
        local content = self:getCommonTipsContent()
        local size = content:getContentSize()
        item:addContent(content)
        item:setItemSize(size.width,size.height)
        self:addItem(item)
    end
end

function UIListView:getCommonTipsContent()
    local viewRect = self:getViewRect()
    local node = display.newNode():size(viewRect.width,viewRect.height)
    local tipsLabel= display.newTTFLabel({
        text = self.tipsString,
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0x615b44),
        align = cc.TEXT_ALIGNMENT_CENTER,
        valign = cc.VERTICAL_TEXT_ALIGNMENT_CENTER,
    }):addTo(node):align(display.CENTER, viewRect.width/2, viewRect.height/2)
    return node
end

--[[--

加载列表

@return UIListView

]]
function UIListView:reload()
    if self.bAsyncLoad then
        self:asyncLoad_()
    else
        self:addCommonTipsNodeIf__()
        self:layout_()
    end

    return self
end

--[[--

取一个空闲项出来,如果没有返回空

@return UIListViewItem item

@see UIListViewItem

]]
function UIListView:dequeueItem()
    if #self.itemsFree_ < 1 then
        return
    end

    local item
    item = table.remove(self.itemsFree_, 1)

    --标识从free中取出,在loadOneItem_中调用release
    --这里直接调用release,item会被释放掉
    item.bFromFreeQueue_ = true

    return item
end

function UIListView:layout_()
    local width, height = 0, 0
    local itemW, itemH = 0, 0
    local margin

    -- calcate whole width height
    if UIScrollView.DIRECTION_VERTICAL == self.direction then
        width = self.viewRect_.width

        for i,v in ipairs(self.items_) do
            itemW, itemH = v:getItemSize()
            itemW = itemW or 0
            itemH = itemH or 0

            height = height + itemH
        end
    else
        height = self.viewRect_.height

        for i,v in ipairs(self.items_) do
            itemW, itemH = v:getItemSize()
            itemW = itemW or 0
            itemH = itemH or 0

            width = width + itemW
        end
    end
    self:setActualRect({x = self.viewRect_.x,
        y = self.viewRect_.y,
        width = width,
        height = height})
    self.size.width = width
    self.size.height = height

    local tempWidth, tempHeight = width, height
    if UIScrollView.DIRECTION_VERTICAL == self.direction then
        itemW, itemH = 0, 0

        local content
        for i,v in ipairs(self.items_) do
            itemW, itemH = v:getItemSize()
            itemW = itemW or 0
            itemH = itemH or 0

            tempHeight = tempHeight - itemH
            content = v:getContent()
            content:setAnchorPoint(cc.p(0.5, 0.5))
            -- content:setPosition(itemW/2, itemH/2)
            self:setPositionByAlignment_(content, itemW, itemH, v:getMargin())
            v:setPosition(self.viewRect_.x,
                self.viewRect_.y + tempHeight)
        end
    else
        itemW, itemH = 0, 0
        tempWidth = 0

        for i,v in ipairs(self.items_) do
            itemW, itemH = v:getItemSize()
            itemW = itemW or 0
            itemH = itemH or 0

            content = v:getContent()
            content:setAnchorPoint(cc.p(0.5, 0.5))
            -- content:setPosition(itemW/2, itemH/2)
            self:setPositionByAlignment_(content, itemW, itemH, v:getMargin())
            v:setPosition(self.viewRect_.x + tempWidth, self.viewRect_.y)
            tempWidth = tempWidth + itemW
        end
    end

    self.container:setPosition(0, self.viewRect_.height - self.size.height)
end

function UIListView:notifyItem(point)
    local count = self.listener[UIListView.DELEGATE](self, UIListView.COUNT_TAG)
    local temp = (self.direction == UIListView.DIRECTION_VERTICAL and self.container:getContentSize().height) or 0
    local w,h = 0, 0
    local tag = 0

    for i = 1, count do
        w,h = self.listener[UIListView.DELEGATE](self, UIListView.CELL_SIZE_TAG, i)
        if self.direction == UIListView.DIRECTION_VERTICAL then
            temp = temp - h
            if point.y > temp then
                point.y = point.y - temp
                tag = i
                break
            end
        else
            temp = temp + w
            if point.x < temp then
                point.x = point.x + w - temp
                tag = i
                break
            end
        end
    end

    if 0 == tag then
        printInfo("UIListView - didn't found item")
        return
    end

    local item = self.container:getChildByTag(tag)
    self.listener[UIListView.DELEGATE](self, UIListView.CLICKED_TAG, tag, point)
end

function UIListView:moveItems(beginIdx, endIdx, x, y, bAni)
    if 0 == endIdx then
        -- why
        -- self:elasticScroll()
        return
    end
    local posX, posY = 0, 0
    local moveByParams = {x = x, y = y, time = 0.2}
    for i=beginIdx, endIdx do
        if bAni then
            if i == beginIdx then
                moveByParams.onComplete = function()
                    self:elasticScroll()
                end
            else
                moveByParams.onComplete = nil
            end
            transition.moveBy(self.items_[i], moveByParams)
        else
            posX, posY = self.items_[i]:getPosition()
            self.items_[i]:setPosition(posX + x, posY + y)
            if i == beginIdx then
                self:elasticScroll()
            end
        end
    end
end
--[[
    @author Kenny Dai
    将指定index 的 item 显示出来
]]
function UIListView:showItemWithPos(idx)
    local item_width,item_height = self.items_[idx]:getItemSize()
     if UIScrollView.DIRECTION_VERTICAL == self.direction then
        self:scrollTo(cc.p(0,self.viewRect_.height - self.items_[idx]:getPositionY() - item_height)) 
        self:scrollAuto()
    else
        self:scrollTo(cc.p(- self.items_[idx]:getPositionX() - item_width,0)) 
        self:scrollAuto()
    end
end
function UIListView:notifyListener_(event)
    if not self.touchListener_ then
        return
    end

    self.touchListener_(event)
end

function UIListView:modifyItemSizeIf_(item)
    local w, h = item:getItemSize()

    if UIScrollView.DIRECTION_VERTICAL == self.direction then
        if w ~= self.viewRect_.width then
            item:setItemSize(self.viewRect_.width, h, true)
        end
    else
        if h ~= self.viewRect_.height then
            item:setItemSize(w, self.viewRect_.height, true)
        end
    end
end

function UIListView:update_(dt)
    UIListView.super.update_(self, dt)

    self:checkItemsInStatus_()
    if self.bAsyncLoad then
        self:increaseOrReduceItem_()
    end
end

function UIListView:checkItemsInStatus_()
    if not self.itemInStatus_ then
        self.itemInStatus_ = {}
    end

    local rectIntersectsRect = function(rectParent, rect)
        -- dump(rectParent, "parent:")
        -- dump(rect, "rect:")

        local nIntersects -- 0:no intersects,1:have intersects,2,have intersects and include totally
        local bIn = rectParent.x <= rect.x and
            rectParent.x + rectParent.width >= rect.x + rect.width and
            rectParent.y <= rect.y and
            rectParent.y + rectParent.height >= rect.y + rect.height
        if bIn then
            nIntersects = 2
        else
            local bNotIn = rectParent.x > rect.x + rect.width or
                rectParent.x + rectParent.width < rect.x or
                rectParent.y > rect.y + rect.height or
                rectParent.y + rectParent.height < rect.y
            if bNotIn then
                nIntersects = 0
            else
                nIntersects = 1
            end
        end

        return nIntersects
    end

    local newStatus = {}
    local bound
    local nodePoint
    for i,v in ipairs(self.items_) do
        bound = v:getBoundingBox()
        nodePoint = self.container:convertToWorldSpace(cc.p(bound.x, bound.y))
        bound.x = nodePoint.x
        bound.y = nodePoint.y
        newStatus[i] =
            rectIntersectsRect(self.viewRect_, bound)
    end

    -- dump(self.itemInStatus_, "status:")
    -- dump(newStatus, "newStatus:")
    for i,v in ipairs(newStatus) do
        if self.itemInStatus_[i] and self.itemInStatus_[i] ~= v then
            -- print("statsus:" .. self.itemInStatus_[i] .. " v:" .. v)
            local params = {listView = self,
                itemPos = i,
                item = self.items_[i]}
            if 0 == v then
                params.name = "itemDisappear"
            elseif 1 == v then
                params.name = "itemAppearChange"
            elseif 2 == v then
                params.name = "itemAppear"
            end
            self:notifyListener_(params)
        else
        -- print("status same:" .. self.itemInStatus_[i])
        end
    end
    self.itemInStatus_ = newStatus
    -- dump(self.itemInStatus_, "status:")
    -- print("itemStaus:" .. #self.itemInStatus_)
end

--[[--

动态调整item,是否需要加载新item,移除旧item
私有函数

]]
function UIListView:increaseOrReduceItem_(nNeedAdjust)
    if 0 == #self.items_ then
        -- print("ERROR items count is 0")
        return
    end

    local getContainerCascadeBoundingBox = function ()
        local boundingBox
        for i, item in ipairs(self.items_) do
            local w,h = item:getItemSize()
            local x,y = item:getPosition()
            local anchor = item:getAnchorPoint()
            x = x - anchor.x * w
            y = y - anchor.y * h

            if boundingBox then
                boundingBox = cc.rectUnion(boundingBox, cc.rect(x, y, w, h))
            else
                boundingBox = cc.rect(x, y, w, h)
            end
        end

        local point = self.container:convertToWorldSpace(cc.p(boundingBox.x, boundingBox.y))
        boundingBox.x = point.x
        boundingBox.y = point.y
        return boundingBox
    end

    local count = self:callAsyncLoadDelegate_(self, UIListView.COUNT_TAG)
    local nNeedAdjust = 2 --作为是否还需要再增加或减少item的标志,2表示上下两个方向或左右都需要调整
    local cascadeBound = getContainerCascadeBoundingBox()
    local localPos = self:convertToNodeSpace(cc.p(cascadeBound.x, cascadeBound.y))
    local item
    local itemW, itemH

    -- print("child count:" .. self.container:getChildrenCount())
    -- dump(cascadeBound, "increaseOrReduceItem_ cascadeBound:")
    -- dump(self.viewRect_, "increaseOrReduceItem_ viewRect:")

    if UIScrollView.DIRECTION_VERTICAL == self.direction then

        --ahead part of view
        local disH = localPos.y + cascadeBound.height - self.viewRect_.y - self.viewRect_.height
        local tempIdx
        item = self.items_[1]
        if not item then
            print("increaseOrReduceItem_ item is nil, all item count:" .. #self.items_)
            return
        end
        tempIdx = item.idx_
        -- print(string.format("befor disH:%d, view val:%d", disH, self.redundancyViewVal))
        if disH > self.redundancyViewVal then
            itemW, itemH = item:getItemSize()
            if cascadeBound.height - itemH > self.viewRect_.height
                and disH - itemH > self.redundancyViewVal then
                self:unloadOneItem_(tempIdx)
            else
                nNeedAdjust = nNeedAdjust - 1
            end
        else
            item = nil
            tempIdx = tempIdx - 1
            if tempIdx > 0 then
                local localPoint = self.container:convertToNodeSpace(cc.p(cascadeBound.x, cascadeBound.y + cascadeBound.height))
                item = self:loadOneItem_(localPoint, tempIdx, true)
            end
            if nil == item then
                nNeedAdjust = nNeedAdjust - 1
            end
        end

        --part after view
        disH = self.viewRect_.y - localPos.y
        item = self.items_[#self.items_]
        if not item then
            return
        end
        tempIdx = item.idx_
        -- print(string.format("after disH:%d, view val:%d", disH, self.redundancyViewVal))
        if disH > self.redundancyViewVal then
            itemW, itemH = item:getItemSize()
            if cascadeBound.height - itemH > self.viewRect_.height
                and disH - itemH > self.redundancyViewVal then
                self:unloadOneItem_(tempIdx)
            else
                nNeedAdjust = nNeedAdjust - 1
            end
        else
            item = nil
            tempIdx = tempIdx + 1
            if tempIdx <= count then
                local localPoint = self.container:convertToNodeSpace(cc.p(cascadeBound.x, cascadeBound.y))
                item = self:loadOneItem_(localPoint, tempIdx)
            end
            if nil == item then
                nNeedAdjust = nNeedAdjust - 1
            end
        end
    else
        --left part of view
        local disW = self.viewRect_.x - localPos.x
        item = self.items_[1]
        local tempIdx = item.idx_
        if disW > self.redundancyViewVal then
            itemW, itemH = item:getItemSize()
            if cascadeBound.width - itemW > self.viewRect_.width
                and disW - itemW > self.redundancyViewVal then
                self:unloadOneItem_(tempIdx)
            else
                nNeedAdjust = nNeedAdjust - 1
            end
        else
            item = nil
            tempIdx = tempIdx - 1
            if tempIdx > 0 then
                local localPoint = self.container:convertToNodeSpace(cc.p(cascadeBound.x, cascadeBound.y))
                item = self:loadOneItem_(localPoint, tempIdx, true)
            end
            if nil == item then
                nNeedAdjust = nNeedAdjust - 1
            end
        end

        --right part of view
        disW = localPos.x + cascadeBound.width - self.viewRect_.x - self.viewRect_.width
        item = self.items_[#self.items_]
        tempIdx = item.idx_
        if disW > self.redundancyViewVal then
            itemW, itemH = item:getItemSize()
            if cascadeBound.width - itemW > self.viewRect_.width
                and disW - itemW > self.redundancyViewVal then
                self:unloadOneItem_(tempIdx)
            else
                nNeedAdjust = nNeedAdjust - 1
            end
        else
            item = nil
            tempIdx = tempIdx + 1
            if tempIdx <= count then
                local localPoint = self.container:convertToNodeSpace(cc.p(cascadeBound.x + cascadeBound.width, cascadeBound.y))
                item = self:loadOneItem_(localPoint, tempIdx)
            end
            if nil == item then
                nNeedAdjust = nNeedAdjust - 1
            end
        end
    end

    -- print("increaseOrReduceItem_() adjust:" .. nNeedAdjust)
    -- print("increaseOrReduceItem_() item count:" .. #self.items_)
    if nNeedAdjust > 0 then
        return self:increaseOrReduceItem_()
    end
end

--[[--

异步加载列表数据

@return UIListView

]]
function UIListView:asyncLoad_()
    self:removeAllItems()
    self.container:setPosition(0, 0)
    self.container:setContentSize(cc.size(0, 0))

    local count = self:callAsyncLoadDelegate_(self, UIListView.COUNT_TAG)

    self.items_ = {}
    local itemW, itemH = 0, 0
    local item
    local containerW, containerH = 0, 0
    local posX, posY = 0, 0
    for i=1,count do
        item, itemW, itemH = self:loadOneItem_(cc.p(posX, posY), i)

        if UIScrollView.DIRECTION_VERTICAL == self.direction then
            posY = posY - itemH

            containerH = containerH + itemH
        else
            posX = posX + itemW

            containerW = containerW + itemW
        end

        -- 初始布局,最多保证可隐藏的区域大于显示区域就可以了
        if containerW > self.viewRect_.width + self.redundancyViewVal
            or containerH > self.viewRect_.height + self.redundancyViewVal then
            break
        end
    end

    -- self.container:setPosition(self.viewRect_.x, self.viewRect_.y)
    if UIScrollView.DIRECTION_VERTICAL == self.direction then
        self.container:setPosition(self.viewRect_.x,
            self.viewRect_.y + self.viewRect_.height)
    else
        self.container:setPosition(self.viewRect_.x, self.viewRect_.y)
    end

    return self
end

--[[--

依据当前位置
异步加载列表数据

@return UIListView
@author Kenny Dai

]]
function UIListView:asyncLoadWithCurrentPosition_()
    local count
    if self.delegate_[UIListView.DELEGATE] then
        count = self.delegate_[UIListView.DELEGATE](self, UIListView.COUNT_TAG)
    else
        count = self:self_sourceDelegate(self, UIListView.COUNT_TAG)
    end
    local current_min_index,current_max_index = math.huge,0
    for i,v in ipairs(self:getItems()) do
        current_min_index = math.min(current_min_index,v.idx_)
        current_max_index = math.max(current_max_index,v.idx_)
    end
    if self:IsTipsStringShow() then
        self:reload()
        return
    end
    for i = current_min_index, current_max_index do
        if i > count then
            self:unloadOneItem_(i)
            self:scrollAuto()
        else
            self:callAsyncLoadDelegate_(self, UIListView.ASY_REFRESH , i)
        end
    end
    if count == 0 then
        self:reload()
    end
    return self
end

--[[--

设置delegate函数

@return UIListView

]]
function UIListView:setDelegate(delegate)
    self.delegate_[UIListView.DELEGATE] = delegate
end

--[[--

调整item中content的布局,
私有函数

]]
function UIListView:setPositionByAlignment_(content, w, h, margin)
    local size = content:getContentSize()
    if 0 == margin.left and 0 == margin.right and 0 == margin.top and 0 == margin.bottom then
        if UIScrollView.DIRECTION_VERTICAL == self.direction then
            if UIListView.ALIGNMENT_LEFT == self.alignment then
                content:setPosition(size.width/2, h/2)
            elseif UIListView.ALIGNMENT_RIGHT == self.alignment then
                content:setPosition(w - size.width/2, h/2)
            else
                content:setPosition(w/2, h/2)
            end
        else
            if UIListView.ALIGNMENT_TOP == self.alignment then
                content:setPosition(w/2, h - size.height/2)
            elseif UIListView.ALIGNMENT_RIGHT == self.alignment then
                content:setPosition(w/2, size.height/2)
            else
                content:setPosition(w/2, h/2)
            end
        end
    else
        local posX, posY
        if 0 ~= margin.right then
            posX = w - margin.right - size.width/2
        else
            posX = size.width/2 + margin.left
        end
        if 0 ~= margin.top then
            posY = h - margin.top - size.height/2
        else
            posY = size.height/2 + margin.bottom
        end
        content:setPosition(posX, posY)
    end
end

--[[--

加载一个数据项
私有函数

@param table originPoint 数据项要加载的起始位置
@param number idx 要加载数据的序号
@param boolean bBefore 是否加在已有项的前面

@return UIListViewItem item

]]
function UIListView:loadOneItem_(originPoint, idx, bBefore)
    printInfo("UIListView loadOneItem idx:" .. idx)
    -- dump(originPoint, "originPoint:")

    local itemW, itemH = 0, 0
    local item
    local containerW, containerH = 0, 0
    local posX, posY = originPoint.x, originPoint.y
    local content

    item = self:callAsyncLoadDelegate_(self, UIListView.CELL_TAG, idx)
    if nil == item then
        printInfo("ERROR! UIListView load nil item")
        return
    end
    item.idx_ = idx
    itemW, itemH = item:getItemSize()

    if UIScrollView.DIRECTION_VERTICAL == self.direction then
        itemW = itemW or 0
        itemH = itemH or 0

        if bBefore then
            posY = posY
        else
            posY = posY - itemH
        end
        content = item:getContent()
        content:setAnchorPoint(cc.p(0.5, 0.5))
        self:setPositionByAlignment_(content, itemW, itemH, item:getMargin())
        item:setPosition(0, posY)

        containerH = containerH + itemH
    else
        itemW = itemW or 0
        itemH = itemH or 0
        if bBefore then
            posX = posX - itemW
        end

        content = item:getContent()
        content:setAnchorPoint(cc.p(0.5, 0.5))
        self:setPositionByAlignment_(content, itemW, itemH, item:getMargin())
        item:setPosition(posX, 0)

        containerW = containerW + itemW
    end

    if bBefore then
        table.insert(self.items_, 1, item)
    else
        table.insert(self.items_, item)
    end

    self.container:addChild(item)
    if item.bFromFreeQueue_ then
        item.bFromFreeQueue_ = nil
        item:release()
    end
    -- local cascadeBound = self.container:getCascadeBoundingBox()
    -- dump(cascadeBound, "cascadeBound:")

    return item, itemW, itemH
end

--[[--

移除一个数据项
私有函数


]]
function UIListView:unloadOneItem_(idx)
    printInfo("UIListView unloadOneItem idx:" .. idx)

    self.nTest = self.nTest + 1

    local item = self.items_[1]

    if nil == item then
        return
    end
    if item.idx_ > idx then
        return
    end
    local unloadIdx = idx - item.idx_ + 1
    item = self.items_[unloadIdx]
    if nil == item then
        return
    end
    table.remove(self.items_, unloadIdx)
    self:addFreeItem_(item)
    -- item:removeFromParentAndCleanup(false)
    self.container:removeChild(item, iscleanup)

    self:callAsyncLoadDelegate_(self, UIListView.UNLOAD_CELL_TAG, idx)
end

--[[--

加一个空项到空闲列表中
私有函数

]]
function UIListView:addFreeItem_(item)
    item:retain()
    table.insert(self.itemsFree_, item)
end

--[[--

释放所有的空闲列表项
私有函数

]]
function UIListView:releaseAllFreeItems_()
    for i,v in ipairs(self.itemsFree_) do
        v:release()
    end
    self.itemsFree_ = {}
end


-- 修改quick:新加接口
------------------------------------------------------------------------------------------------------------------------------------------
function UIListView:setRedundancyViewVal(len)
    if UIScrollView.DIRECTION_VERTICAL == self.direction then
        self.redundancyViewVal = len
    else
        self.redundancyViewVal = len
    end
    return self
end
local abs = math.abs
function UIListView:scrollBy(x, y)
    local rx, ry = self:Ratio(self:getScrollNodeRect())
    x, y = x * rx, y * ry
    self.position_.x, self.position_.y = self:moveXY(self.position_.x, self.position_.y, x, y)
    -- self.position_.x = self.position_.x + x
    -- self.position_.y = self.position_.y + y
    self.scrollNode:setPosition(self.position_)
    if self:isTrackTop() and UIScrollView.DIRECTION_VERTICAL == self.direction then
        local __,disY = self:getSlideDistance()
        if disY > 0 then
            self:notifyListener_({name = "top_distance_changed",disY = disY})
        end
    end
    if self.actualRect_ then
        self.actualRect_.x = self.actualRect_.x + x
        self.actualRect_.y = self.actualRect_.y + y
    end
end

function UIListView:getSlideDistance()
    local cascadeBound = self:getScrollNodeRect()
    local disX, disY = 0, 0
    local viewRect = self:getViewRectInWorldSpace()

    -- dump(cascadeBound, "UIScrollView - cascBoundingBox:")
    -- dump(viewRect, "UIScrollView - viewRect:")
    --修改quick:如果是单方向滑动 只改变该方向上的位移！加上判断
    if UIScrollView.DIRECTION_VERTICAL ~= self.direction then
        if cascadeBound.width < viewRect.width then
            disX = viewRect.x - cascadeBound.x
        else
            if cascadeBound.x > viewRect.x then
                disX = viewRect.x - cascadeBound.x
            elseif cascadeBound.x + cascadeBound.width < viewRect.x + viewRect.width then
                disX = viewRect.x + viewRect.width - cascadeBound.x - cascadeBound.width
            end
        end
    end
    if UIScrollView.DIRECTION_HORIZONTAL ~= self.direction then
        if cascadeBound.height < viewRect.height then
            disY = viewRect.y + viewRect.height - cascadeBound.y - cascadeBound.height
        else
            if cascadeBound.y > viewRect.y then
                disY = viewRect.y - cascadeBound.y
            elseif cascadeBound.y + cascadeBound.height < viewRect.y + viewRect.height then
                disY = viewRect.y + viewRect.height - cascadeBound.y - cascadeBound.height
            end
        end
    end
    return disX,disY
end


local function floor_0(t, c)
    local abs_c = abs(c)
    return abs_c > t and (abs_c - t) * (abs_c/c) or 0
end
function UIListView:twiningScroll()
    if self:isSideShow() then
        -- printInfo("UIScrollView - side is show, so elastic scroll")
        return false
    end

    if abs(self.speed.x) < 10 and abs(self.speed.y) < 10 then
        -- printInfo("#DEBUG, UIScrollView - isn't twinking scroll:"
        --  .. self.speed.x .. " " .. self.speed.y)
        return false
    end
    local disX, disY = self:moveXY(0, 0, self.speed.x*6, self.speed.y*6)
    local rect = self:getScrollNodeRect()
    rect.x = rect.x + disX
    rect.y = rect.y + disY
    local rx, ry, dx, dy = self:Ratio(rect)
    local viewRect = self:getViewRectInWorldSpace()
    transition.moveBy(self.scrollNode,
        {x = disX + floor_0(viewRect.width * 0.5, dx), y = disY + floor_0(viewRect.height * 0.5, dy), time = 0.3,
            easing = "sineOut",
            onComplete = function()
                self:elasticScroll()
            end})
end
function UIListView:Ratio(cascadeBound)
    local disX, disY = 0, 0
    local rx, ry = 1, 1
    local viewRect = self:getViewRectInWorldSpace()
    if UIScrollView.DIRECTION_HORIZONTAL == self.direction then
        if cascadeBound.width < viewRect.width then
            disX = viewRect.x - cascadeBound.x
        else
            if cascadeBound.x > viewRect.x then
                disX = viewRect.x - cascadeBound.x
            elseif cascadeBound.x + cascadeBound.width < viewRect.x + viewRect.width then
                disX = viewRect.x + viewRect.width - cascadeBound.x - cascadeBound.width
            end
        end
        rx = 1 - abs(disX) / (viewRect.width * 0.5)
    end
    if UIScrollView.DIRECTION_VERTICAL == self.direction then
        if cascadeBound.height < viewRect.height then
            disY = viewRect.y + viewRect.height - cascadeBound.y - cascadeBound.height
        else
            if cascadeBound.y > viewRect.y then
                disY = viewRect.y - cascadeBound.y
            elseif cascadeBound.y + cascadeBound.height < viewRect.y + viewRect.height then
                disY = viewRect.y + viewRect.height - cascadeBound.y - cascadeBound.height
            end
        end
        ry = 1 - abs(disY) / (viewRect.height * 0.5)
    end
    return rx, ry, disX, disY
end
function UIListView:isSideShow()
    local bound = self.scrollNode:getCascadeBoundingBox()
    local viewRect_ = self:getViewRectInWorldSpace()
    if self.direction == UIScrollView.DIRECTION_VERTICAL then
        return bound.y > viewRect_.y
            or bound.y + bound.height < viewRect_.y + viewRect_.height
    else
        return bound.x > viewRect_.x
            or bound.x + bound.width < viewRect_.x + viewRect_.width
    end
    return false
end
function UIListView:getItems()
    return self.items_
end

function UIListView:insertItemAndRefresh(listItem, pos)
    assert(not self.bAsyncLoad, "UIListView:insertItemAndRefresh() - Asyncload not support insertItemAndRefresh")
    local pre_x,pre_y = self.container:getPosition()
    self:addItem(listItem, pos)
    self:layout_()
    local item_width,item_height = listItem:getItemSize()
    if self.direction == UIListView.DIRECTION_VERTICAL then
        self.container:setPosition(0, pre_y-item_height)
        -- print("insertItemAndRefresh  item_height=",item_height,"pre_y=",pre_y)
    else
        self.container:setPosition(0, self.viewRect_.height - self.size.height)
    end

    return self
end
--[[--
    显示当前listview的情况
]]
function UIListView:dumpListView()
    assert(self.bAsyncLoad, "UIListView:dumpListView() - syncload not support dumpListView")
    for i,v in ipairs(self.items_) do
        printInfo("%d -> %d",i,v.idx_)
    end
    printInfo("Free item size:%d",#self.itemsFree_)
end
--[[--
    逻辑索引获取item
]]
function UIListView:getItemWithLogicIndex(index)
    assert(self.bAsyncLoad, "UIListView:getItemWithLogicIndex() - syncload not support getItemWithLogicIndex")
    if not index then return end
    for _,v in ipairs(self.items_) do
        if v.idx_ == checkint(index) then
            return v
        end
    end
    return nil
end
--[[--

    通过偏移量修改显示的item的逻辑索引
]]
function UIListView:offsetItemsIdx(offset)
    assert(self.bAsyncLoad, "UIListView:offsetItemsIdx() - syncload not support offsetItemsIdx")
    offset = checkint(offset)
    for __,v in ipairs(self.items_) do
        v.idx_ = v.idx_ + offset
    end
end

function UIListView:rectWholeInRect(rect1,rect2)
    return cc.rectGetMaxX(rect1) >= cc.rectGetMaxX(rect2) and cc.rectGetMinX(rect1) <=  cc.rectGetMinX(rect2)
        and  cc.rectGetMaxY(rect1) >= cc.rectGetMaxY(rect2) and cc.rectGetMinY(rect1) <=  cc.rectGetMinY(rect2)
end
--[[--
    判断item[完全]在viewRect内
    pos 可以为逻辑索引、真实索引或者item
]]
function UIListView:isItemFullyInViewRect(pos)
    local item
    if self.bAsyncLoad then
        item = self:getItemWithLogicIndex(pos)
    else
        if "number" == type(pos) then
            item = self.items_[pos]
        elseif "userdata" == type(pos) then
            item = pos
        end
    end

    if not item then
        return false
    end
    local bound = item:getBoundingBox()
    local nodePoint = self.container:convertToWorldSpace(
        cc.p(bound.x, bound.y))
    bound.x = nodePoint.x
    bound.y = nodePoint.y
    return self:rectWholeInRect(self.viewRect_,bound)
end

function UIListView:IsTipsStringShow()
    return self.isTipsStringShow
end

function UIListView:callAsyncLoadDelegate_(...)
    if self.tipsString then
        local args = {...}
        if self.delegate_[UIListView.DELEGATE](self, UIListView.COUNT_TAG) > 0 then
            self.isTipsStringShow = false
            return self.delegate_[UIListView.DELEGATE](unpack(args))
        else
            self.isTipsStringShow = true
            return self:self_sourceDelegate(unpack(args))
        end
    else
        self.isTipsStringShow = false
        return self.delegate_[UIListView.DELEGATE](unpack(args))
    end
end

function UIListView:self_sourceDelegate(listView, tag, idx)
    if listView == self then
        if UIListView.COUNT_TAG == tag then
            return 1
        elseif UIListView.CELL_TAG == tag then
            local item = self:dequeueItem()
            if not item then
                local content = self:getCommonTipsContent()
                local size = content:getContentSize()
                item = self:newItem(content)
                item:setItemSize(size.width,size.height)
            else
                local content = item:getContent()
                if content then content:removeSelf() end
                content = self:getCommonTipsContent()
                local size = content:getContentSize()
                item:addContent(content)
                item:setItemSize(size.width,size.height)
            end
            return item
        else

        end
    end
end
-- end
------------------------------------------------------------------------------------------------------------------------------------------


return UIListView







