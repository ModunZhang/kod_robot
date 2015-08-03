--
-- Author: Kenny Dai
-- Date: 2015-07-16 14:32:48
--
local WidgetInfoWithTitle = import(".WidgetInfoWithTitle")
local UILib = import("..ui.UILib")
local Localize = import("..utils.Localize")


local WidgetShrineRewardsInfo = class("WidgetShrineRewardsInfo", WidgetInfoWithTitle)
function WidgetShrineRewardsInfo:ctor(params)
    WidgetShrineRewardsInfo.super.ctor(self,params)
end

function WidgetShrineRewardsInfo:CreateInfoItems(shrineStage)
    if not shrineStage then
        return
    end
    self.info_listview:removeAllItems()
    local meetFlag = true

    local item_width, item_height = self.width-8,40
    for index,data in pairs(self:GetListData(shrineStage)) do
        local item = self.info_listview:newItem()
        item:setItemSize(item_width, item_height)
        local content = display.newNode()
        content:setContentSize(cc.size(item_width, item_height))
        display.newScale9Sprite(meetFlag and "back_ground_548x40_1.png" or "back_ground_548x40_2.png",item_width/2,item_height/2,cc.size(item_width,item_height),cc.rect(15,10,518,20))
            :addTo(content)

        local iconImage = "goldKill_icon_76x84.png"
        if index == 1 then
            iconImage = "goldKill_icon_76x84.png"
        elseif index == 2 then
            iconImage = "silverKill_icon_76x84.png"
        elseif index == 3 then
            iconImage = "bronzeKill_icon_76x84.png"
        end
        local icon = display.newSprite(iconImage):align(display.LEFT_CENTER,15,item_height/2):addTo(content):scale(0.4)
        local strength_icon = display.newSprite("battle_33x33.png")
            :align(display.LEFT_CENTER,60,item_height/2)
            :addTo(content)
            :scale(0.8)
        UIKit:ttfLabel({
            text = data[1],
            size = 20,
            color = 0x403c2f
        }):addTo(content):align(display.LEFT_CENTER,90,item_height/2)

        local x = {
        item_width - 50,
        item_width - 130,
        item_width - 230,
    }
        local y = item_height/2
        for i,v in ipairs(data[2]) do
            local item = display.newScale9Sprite("box_118x118.png"):scale(0.3)
                :align(display.RIGHT_CENTER,x[i],y)
                :addTo(content)
            if v.type == 'dragonMaterials' then
                local sp = display.newSprite(UILib.dragon_material_pic_map[v.sub_type]):align(display.CENTER,59,59)
                local size = sp:getContentSize()
                sp:scale(100/math.max(size.width,size.height)):addTo(item)
                UIKit:addTipsToNode(item,Localize.equip_material[v.sub_type],self)
            elseif v.type == 'allianceInfo' then
                if v.sub_type == 'loyalty' then
                    local sp = display.newSprite("loyalty_128x128.png"):align(display.CENTER,59,59)
                    sp:scale(0.78):addTo(item)
                end
                UIKit:addTipsToNode(item,_("忠诚值"),self)
            end
            UIKit:ttfLabel({
                text = "x" .. GameUtils:formatNumber(v.count),
                size = 18,
                color = 0x403c2f
            }):addTo(content):align(display.LEFT_CENTER,x[i] + 10,y)
        end
        meetFlag =  not meetFlag
        item:addContent(content)
        self.info_listview:addItem(item)
    end
    self.info_listview:reload()
end
function WidgetShrineRewardsInfo:GetListData(shrineStage)
    local terrain = Alliance_Manager:GetMyAlliance():Terrain()
    local data = {}
    data[1] = {string.formatnumberthousands(shrineStage:GoldKill()),shrineStage:GoldRewards(terrain)}
    data[2] = {string.formatnumberthousands(shrineStage:SilverKill()),shrineStage:SilverRewards(terrain)}
    data[3] = {string.formatnumberthousands(shrineStage:BronzeKill()),shrineStage:BronzeRewards(terrain)}
    return data
end
return WidgetShrineRewardsInfo





