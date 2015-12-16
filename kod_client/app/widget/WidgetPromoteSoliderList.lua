--
-- Author: Kenny Dai
-- Date: 2015-01-20 17:51:56
--
local StarBar = import("..ui.StarBar")
local window = import("..utils.window")
local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetSoldierPromoteDetails = import(".WidgetSoldierPromoteDetails")
local WidgetPushButton = import(".WidgetPushButton")
local Localize = import("..utils.Localize")
local UILib = import("..ui.UILib")

local max_star = 3

local WidgetPromoteSoliderList = class("WidgetPromoteSoliderList", function ()
    local list,list_node = UIKit:commonListView({
        viewRect = cc.rect(0, 0,568, 620),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list_node.listview = list
    list_node:setNodeEventEnabled(true)
    return list_node
end)

function WidgetPromoteSoliderList:ctor(building)
    self.building = building
    local soldiers_star = User:GetBuildingSoldiersInfo(self.building:GetType())
    self.items_list = {}
    self.boxes = {}
    for k,v in ipairs(soldiers_star) do
        self.items_list[v[1]] =  self:CreateItem(v[1],v[2])
    end
    self.listview:reload()
end

function WidgetPromoteSoliderList:CreateItem(soldier_type,star)
    local list = self.listview
    local item = list:newItem()
    local item_width,item_height = 568,260
    item:setItemSize(item_width,item_height)
    list:addItem(item)
    local content = WidgetUIBackGround.new({width = item_width,height = item_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    item:addContent(content)

    local title_bg = display.newSprite("title_blue_554x34.png")
        :addTo(content)
        :pos(item_width/2,item_height-25)
    local temp = UIKit:ttfLabel({
        text =  Localize.soldier_name[soldier_type],
        size = 22,
        color = 0xffedae,
    }):align(display.CENTER, title_bg:getContentSize().width/2 , title_bg:getContentSize().height/2)
        :addTo(title_bg)

    local gap_x = 54
    local total_width = 3 * 148 + 2*gap_x
    local origin_x = (item_width - total_width)/2 + 148/2
    for i=1,max_star do
        table.insert(self.boxes, self:CreateSoliderBox(soldier_type,i,star):addTo(content):pos(origin_x+(i-1)*(gap_x+148),item_height-120))
    end

    return item
end
function WidgetPromoteSoliderList:CreateSoliderBox(soldier_type,index,star)
    local status
    if star >= index then
        status = "unlock"
    elseif star == index-1 then
        status = "toUnlock"
    elseif star < index-1 then
        status = "lock"
    end
    local soldier_box

    if status == "unlock" or status == "toUnlock" then
        soldier_box = display.newSprite("box_light_148x148.png")
        if index>1 then
            soldier_box.line = display.newSprite("box_light_70x32.png"):addTo(soldier_box):align(display.CENTER_RIGHT, 8, soldier_box:getContentSize().height/2)
        end
    else
        soldier_box = display.newSprite("box_148x148.png")
        if index>1 then
            soldier_box.line = display.newSprite("box_70x32.png"):addTo(soldier_box):align(display.CENTER_RIGHT, 8, soldier_box:getContentSize().height/2)
        end
    end

    -- 打开晋级详情信息
    WidgetPushButton.new()
        :addTo(soldier_box)
        :align(display.CENTER, soldier_box:getContentSize().width/2 ,soldier_box:getContentSize().height/2)
        :onButtonClicked(function(event)
            if index > 1 then
                UIKit:newWidgetUI("WidgetSoldierPromoteDetails",soldier_type,index - 1 ,self.building,true):AddToCurrentScene()
            end
        end):setContentSize(soldier_box:getContentSize())
    local label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color = 0x403c2f,
    }):align(display.CENTER, soldier_box:getContentSize().width/2 , -30)
        :addTo(soldier_box)
    if status == "unlock" then
        label:setString(_("已解锁"))
    elseif status == "lock" then
        label:setString(_("未解锁"))
    elseif status == "toUnlock" then
        if User:GetPromotionName(self.building:GetType()) == soldier_type then
            label:setString(_("正在晋级"))
            label:setColor(UIKit:hex2c4b(0x007c23))
        else
            soldier_box.button = WidgetPushButton.new(
                {normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
                :addTo(soldier_box)
                :align(display.CENTER, soldier_box:getContentSize().width/2 , -30)
                :setButtonLabel(UIKit:ttfLabel({
                    text = _("研发"),
                    size = 24,
                    color = 0xfff3c7,
                    shadow = true
                }))
                :onButtonClicked(function(event)
                    UIKit:newWidgetUI("WidgetSoldierPromoteDetails",soldier_type,star,self.building):AddToCurrentScene()
                end)
        end
    end
    local blue_bg = display.newSprite(UILib.soldier_color_bg_images[soldier_type], soldier_box:getContentSize().width/2, soldier_box:getContentSize().height/2, {class=cc.FilteredSpriteWithOne}):addTo(soldier_box)
    local soldier_icon = display.newSprite(UILib.soldier_image[soldier_type][index], soldier_box:getContentSize().width/2, soldier_box:getContentSize().height/2, {class=cc.FilteredSpriteWithOne}):addTo(soldier_box)
    soldier_icon:scale(124/math.max(soldier_icon:getContentSize().width,soldier_icon:getContentSize().height))
    local soldier_star_bg = display.newSprite("tmp_back_ground_102x22.png"):addTo(soldier_icon):align(display.BOTTOM_CENTER,soldier_icon:getContentSize().width/2-10, 3)
    StarBar.new({
        max = 3,
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
        num = index,
        margin = 5,
        direction = StarBar.DIRECTION_HORIZONTAL,
        scale = 0.8,
    }):addTo(soldier_star_bg):align(display.CENTER,58, 11)
    display.newSprite("i_icon_20x20.png"):addTo(soldier_star_bg):align(display.LEFT_CENTER,5, 11)

    if status ~= "unlock" then
        local my_filter = filter
        local filters = my_filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1})
        blue_bg:setFilter(filters)
        soldier_icon:setFilter(filters)
    end
    display.newSprite("box_soldier_128x128.png"):addTo(soldier_box):align(display.CENTER, soldier_box:getContentSize().width/2, soldier_box:getContentSize().height/2)

    local parent = self
    function soldier_box:Refresh(star)
        local status
        if star >= index then
            status = "unlock"
        elseif star == index-1 then
            status = "toUnlock"
        elseif star < index-1 then
            status = "lock"
        end
        if status == "unlock" then
            soldier_box:setTexture("box_light_148x148.png")
            blue_bg:clearFilter()
            soldier_icon:clearFilter()
        end
        if status == "unlock" then
            label:setString(_("已解锁"))
            label:setColor(UIKit:hex2c4b(0x403c2f))
        elseif status == "lock" then
            label:setString(_("未解锁"))
            label:setColor(UIKit:hex2c4b(0x403c2f))
        else
            label:setString("")
        end
        if status == "toUnlock" then

            if User:GetPromotionName(parent.building:GetType()) == soldier_type then
                label:setString("正在晋级")
                label:setColor(UIKit:hex2c4b(0x007c23))
                if self.button then
                    self:removeChild(self.button, true)
                end
            elseif not self.button then
                self.button = WidgetPushButton.new(
                    {normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
                    :addTo(soldier_box)
                    :align(display.CENTER, soldier_box:getContentSize().width/2 , -30)
                    :setButtonLabel(UIKit:ttfLabel({
                        text = _("研发"),
                        size = 24,
                        color = 0xfff3c7,
                        shadow = true
                    }))
                    :onButtonClicked(function(event)
                        UIKit:newWidgetUI("WidgetSoldierPromoteDetails",soldier_type,star,parent.building):AddToCurrentScene()
                    end)
            end
        elseif self.button and status ~= "toUnlock"then
            self:removeChild(self.button, true)
        end

        if status == "unlock" or status == "toUnlock" then
            if self.line then
                self.line:setTexture("box_light_70x32.png")
            end
        end
    end
    function soldier_box:GetSoldierType()
        return soldier_type
    end

    return soldier_box
end
function WidgetPromoteSoliderList:onEnter()
    User:AddListenOnType(self, "soldierStars")
    User:AddListenOnType(self, "soldierStarEvents")
end
function WidgetPromoteSoliderList:onExit()
    User:RemoveListenerOnType(self, "soldierStars")
    User:RemoveListenerOnType(self, "soldierStarEvents")
end
function WidgetPromoteSoliderList:OnUserDataChanged_soldierStars(userData, deltaData)
    local ok, value = deltaData("soldierStars")
    if ok then
        for soldier_name,star in pairs(value) do
            for _,box in ipairs(self.boxes) do
                if soldier_name == box:GetSoldierType() then
                    box:Refresh(star)
                end
            end
        end
    end
end
function WidgetPromoteSoliderList:OnUserDataChanged_soldierStarEvents(userData, deltaData)
    local User = User
    local ok, value = deltaData("soldierStarEvents.add")
    if ok then
        for _,v in ipairs(value) do
            for _,box in ipairs(self.boxes) do
                if v.name == box:GetSoldierType() then
                    box:Refresh(User:SoldierStarByName(v.name))
                end
            end
        end
    end
    local ok, value = deltaData("soldierStarEvents.remove")
    if ok then
        for _,v in ipairs(value) do
            for _,box in ipairs(self.boxes) do
                if v.name == box:GetSoldierType() then
                    box:Refresh(User:SoldierStarByName(v.name))
                end
            end
        end
    end
end

return WidgetPromoteSoliderList










