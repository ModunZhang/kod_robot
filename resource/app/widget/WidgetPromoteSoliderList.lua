--
-- Author: Kenny Dai
-- Date: 2015-01-20 17:51:56
--
local window = import("..utils.window")
local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetSoldierPromoteDetails = import(".WidgetSoldierPromoteDetails")
local WidgetPushButton = import(".WidgetPushButton")
local SoldierManager = import("..entity.SoldierManager")
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

    local soldiers_star = City:GetSoldierManager():FindSoldierStarByBuildingType(self.building:GetType())
    self.items_list = {}
    self.boxes = {}
    for k,v in pairs(soldiers_star) do
        print("WidgetPromoteSoliderList",k,v)
        self.items_list[k] =  self:CreateItem(k,v)
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

    local title_bg = display.newSprite("title_blue_558x34.png")
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
        if City:GetSoldierManager():GetPromotingSoldierName(self.building:GetType()) == soldier_type then
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
                    color = 0xfff3c7
                }))
                :onButtonClicked(function(event)
                    UIKit:newWidgetUI("WidgetSoldierPromoteDetails",soldier_type,star,self.building):AddToCurrentScene()
                end)
        end
    end
    local blue_bg = display.newSprite("back_ground_121x122.png", soldier_box:getContentSize().width/2, soldier_box:getContentSize().height/2, {class=cc.FilteredSpriteWithOne}):addTo(soldier_box)
    local soldier_icon = display.newSprite(UILib.soldier_image[soldier_type][index], soldier_box:getContentSize().width/2, soldier_box:getContentSize().height/2, {class=cc.FilteredSpriteWithOne}):addTo(soldier_box)
    soldier_icon:scale(124/math.max(soldier_icon:getContentSize().width,soldier_icon:getContentSize().height))
    if status ~= "unlock" then
        local my_filter = filter
        local filters = my_filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1})
        blue_bg:setFilter(filters)
        soldier_icon:setFilter(filters)
    end
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

            if City:GetSoldierManager():GetPromotingSoldierName(parent.building:GetType()) == soldier_type then
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
                        color = 0xfff3c7
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
    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED)
    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
end
function WidgetPromoteSoliderList:onExit()
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED)
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
end
function WidgetPromoteSoliderList:OnSoliderStarCountChanged(soldier_manager,changed_map)
    for i,v in ipairs(changed_map) do
        for _,box in ipairs(self.boxes) do
            if v == box:GetSoldierType() then
                box:Refresh(City:GetSoldierManager():GetStarBySoldierType(v))
            end
        end
    end
end
function WidgetPromoteSoliderList:OnSoldierStarEventsChanged(soldier_manager,changed_map)
    for i,v in ipairs(changed_map[1]) do
        for _,box in ipairs(self.boxes) do
            if v.name == box:GetSoldierType() then
                box:Refresh(City:GetSoldierManager():GetStarBySoldierType(v.name))
            end
        end
    end
    for i,v in ipairs(changed_map[3]) do
        for _,box in ipairs(self.boxes) do
            if v.name == box:GetSoldierType() then
                box:Refresh(City:GetSoldierManager():GetStarBySoldierType(v.name))
            end
        end
    end
end

return WidgetPromoteSoliderList








