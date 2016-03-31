--
-- Author: Kenny Dai
-- Date: 2015-03-03 15:40:53
--
local UILib = import("..ui.UILib")
local Localize_item = import("..utils.Localize_item")
local Localize = import("..utils.Localize")

local WidgetGachaItemBox = class("WidgetGachaItemBox",function ()
    return display.newNode()
end)
function WidgetGachaItemBox:ctor(gacha_item,isSenior,include_tips_node)
    self:setContentSize(cc.size(92,92))
    self:align(display.CENTER)
    self.gacha_item = gacha_item
    self.isSenior = isSenior
    local gacha_box = display.newSprite("box_gacha_92x92.png"):addTo(self)
    local num_bg = display.newSprite("gacha_num_bg.png"):addTo(self,2):align(display.RIGHT_BOTTOM, 39,-40)
    UIKit:ttfLabel({
        text = "X"..gacha_item.itemCount,
        size = 16,
        color = 0xffedae
    }):align(display.RIGHT_CENTER, num_bg:getContentSize().width, num_bg:getContentSize().height/2)
        :addTo(num_bg)
    -- item icon
    local item_icon = display.newScale9Sprite(self:GetGachaItemIcon()):addTo(self)
    item_icon:scale(74/item_icon:getContentSize().width)
    self:SetNodeEvent(gacha_box,include_tips_node)
end
function WidgetGachaItemBox:SetNodeEvent(gacha_box,include_tips_node)
    UIKit:addTipsToNode(gacha_box,Localize_item.item_name[self:GetGachaItemName()] or Localize.fight_reward[self:GetGachaItemName()],include_tips_node)
end
-- 设置起点或取消起点状态
function WidgetGachaItemBox:SetOrginStatus()
    local img_1 = self.isSenior and "box_gacha_senior_136x136_1.png" or "box_gacha_112x112_1.png"
    if self.light_box then
        self:removeChild(self.light_box, true)
        self.light_box = nil
    else
        local patten
        if self.isSenior then
            patten = "box_gacha_senior_136x136_%d.png"
        else
            patten = "box_gacha_112x112_%d.png"
        end
        local light_box = display.newSprite(img_1)
        self:addChild(light_box)
        self.light_box = light_box
        local frames = display.newFrames(patten, 1, 2)
        if not frames then
            return
        end
        local animation = display.newAnimation(frames, 0.2)
        light_box:playAnimationForever(animation)
    end
end
-- 设置选中点或取消选中点状态 ，针对3连抽
function WidgetGachaItemBox:SetSelectedStatus()
    local img_1 = self.isSenior and "box_gacha_senior_136x136_1.png" or "box_gacha_112x112_1.png"
    if self.select_box then
        self:removeChild(self.select_box, true)
        self.select_box = nil
    else
        local patten 
        if self.isSenior then
            patten = "box_gacha_senior_136x136_%d.png"
        else
            patten = "box_gacha_112x112_%d.png"
        end
        local select_box = display.newSprite(img_1)
        self:addChild(select_box)

        local frames = display.newFrames(patten, 1, 2)
        self.select_box = select_box
        if not frames then
            return
        end
        local animation = display.newAnimation(frames, 0.2)
        select_box:playAnimationForever(animation)
    end
end
-- 设置经过状态或取消经过状态
function WidgetGachaItemBox:SetPassStatus()
    if self.pass_box then
        self:removeChild(self.pass_box, true)
        self.pass_box = nil
    else
        local img
        if self.isSenior then
            img="box_gacha_senior_136x136_1.png"
        else
            img="box_gacha_112x112_1.png"
        end
        local pass_box = display.newSprite(img):addTo(self)
        self.pass_box = pass_box
    end
end
function WidgetGachaItemBox:ResetLigt()
    if self.pass_box then
        self:removeChild(self.pass_box, true)
        self.pass_box = nil
    end
    if self.light_box then
        self:removeChild(self.light_box, true)
        self.light_box = nil
    end

end
function WidgetGachaItemBox:GetGachaItemName()
    return self.gacha_item.itemName
end
function WidgetGachaItemBox:GetGachaItemCount()
    return self.gacha_item.itemCount
end
function WidgetGachaItemBox:GetGachaItemIcon( )
    local name = self:GetGachaItemName()
    return UILib.item[name]
end
function WidgetGachaItemBox:RemoveSelectStatus( )
    if self.select_box then
        self:removeChild(self.select_box, true)
        self.select_box = nil
    end
end
return WidgetGachaItemBox












