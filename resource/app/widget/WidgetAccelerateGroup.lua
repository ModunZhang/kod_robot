--
-- Author: Kenny Dai
-- Date: 2015-01-16 17:14:13
--
local WidgetPushButton = import(".WidgetPushButton")
local Localize_item = import("..utils.Localize_item")
local SmallDialogUI = import("..ui.SmallDialogUI")
local Enum = import("..utils.Enum")

local WidgetAccelerateGroup = class("WidgetAccelerateGroup",function ()
    local node = display.newNode()
    node:setContentSize(cc.size(640,500))
    node:setNodeEventEnabled(true)
    return node
end)


function WidgetAccelerateGroup:ctor(eventType,eventId)
    local width,height = 640,500
    self.acc_button_layer = display.newNode()
    self.acc_button_layer:setContentSize(cc.size(width,height))
    self.acc_button_layer:addTo(self,2)
    self.acc_button_layer:setTouchSwallowEnabled(false)
    self.acc_button_layer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function ( event )
        if event.name=="end" then
            self:ResetAccButtons()
        end
        return true
    end, 1)
    local gap_x , gap_y= 148,140
    self.acc_button_table = {}
    self.time_button_tbale = {}
    self.own_labels = {}
    self.gem_images = {}
    for i=1,8 do
        -- 按钮背景框
        display.newSprite("upgrade_props_box.png", width/2-220 + gap_x*math.mod(i-1,4), 230-gap_y*math.floor((i-1)/4)):addTo(self)
        -- 花销数值背景
        local cost_bg = display.newSprite("back_ground_138x34.png", width/2-220 + gap_x*math.mod(i-1,4), 160-gap_y*math.floor((i-1)/4)):addTo(self):scale(0.8)

        local speedUp_item_name = "speedup_"..i
        local speedUp_item = ItemManager:GetItemByName(speedUp_item_name)
        local speedUp_item_num = speedUp_item:Count()
        local cost_text = ""
        local gem_icon = display.newSprite("gem_icon_62x61.png"):addTo(cost_bg):align(display.CENTER, 20, cost_bg:getContentSize().height/2):scale(0.6)

        if speedUp_item_num>0 then
            cost_text = _("拥有")..speedUp_item_num
            gem_icon:hide()
        else
            cost_text = speedUp_item:Price()
            gem_icon:show()
        end
        table.insert(self.gem_images, gem_icon)
        -- 花销数值
        local own_label = UIKit:ttfLabel({
            text = cost_text,
            size = 20,
            color = 0x403c2f
        }):align(display.CENTER, width/2-220+gap_x*math.mod(i-1,4), 160-gap_y*math.floor((i-1)/4))
            :addTo(self)
        table.insert(self.own_labels, own_label)

        -- 时间按钮
        local time_button = WidgetPushButton.new({normal = "upgrade_time_"..i..".png"},{scale9 = false}
            ,{
                disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}
            })
            -- :setButtonEnabled(false)
            :SetFilter({
                disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}
            })
        -- 确认加速按钮
        local acc_button = WidgetPushButton.new({normal = "upgrade_acc_button_1.png",pressed="upgrade_acc_button_2.png"})
        time_button:onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:ResetAccButtons()
                acc_button:setVisible(true)
                time_button:setVisible(false)
                self:addChild(SmallDialogUI.new(
                    {
                        listener = function ()
                            acc_button:setVisible(false)
                            time_button:setVisible(true)
                        end,
                        x = math.floor((i-1)/4)==0 and cost_bg:getPositionX() or
                        math.floor((i-1)/4)==1 and acc_button:getPositionX(),
                        y = math.floor((i-1)/4)==0 and cost_bg:getPositionY()-cost_bg:getContentSize().height/2 or
                        math.floor((i-1)/4)==1 and acc_button:getPositionY()+acc_button:getCascadeBoundingBox().size.height/2,
                        tips1 = _("使用立即减少升级时间"),
                        tips2 = Localize_item.item_name[speedUp_item_name] ,
                        direction = math.floor((i-1)/4), -- 0表示dialog的箭头指向上方，1反之
                        scale_left = i==1 or i==5,
                        scale_right = i==4 or i==8,
                    }
                ),2)
            end
        end):align(display.CENTER, width/2-220+gap_x*math.mod(i-1,4), 230-gap_y*math.floor((i-1)/4)):addTo(self.acc_button_layer)
        time_button:setScale(0.7)
        acc_button:onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                acc_button:setVisible(false)
                time_button:setVisible(true)
                if string.find(own_label:getString(),_("拥有")) then
                    NetManager:getUseItemPromise(speedUp_item_name,{[speedUp_item_name] = {
                        eventType = eventType,
                        eventId = eventId
                    }})
                else
                    if speedUp_item:Price() > User:GetGemResource():GetValue() then
                        UIKit:showMessageDialog(_("陛下"),_("金龙币不足"))
                            :CreateOKButton(
                                {
                                    listener = function ()
                                        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                    end,
                                    btn_name= _("前往商店")
                                }
                            )
                    else
                        NetManager:getBuyAndUseItemPromise(speedUp_item_name,{[speedUp_item_name] = {
                            eventType = eventType,
                            eventId = eventId
                        }})
                    end
                end
            end
        end):align(display.CENTER, width/2-220+gap_x*math.mod(i-1,4), 230-gap_y*math.floor((i-1)/4)):addTo(self.acc_button_layer)
        acc_button:setVisible(false)
        self.acc_button_table[i] = acc_button
        self.time_button_tbale[i] = time_button
    end
end
function WidgetAccelerateGroup:ResetAccButtons()
    for k,v in pairs(self.time_button_tbale) do
        v:setVisible(true)
    end
    for k,v in pairs(self.acc_button_table) do
        v:setVisible(false)
    end
end
function WidgetAccelerateGroup:onExit()
    ItemManager:RemoveListenerOnType(self,ItemManager.LISTEN_TYPE.ITEM_CHANGED)
end
function WidgetAccelerateGroup:onEnter()
    ItemManager:AddListenOnType(self,ItemManager.LISTEN_TYPE.ITEM_CHANGED)
end
function WidgetAccelerateGroup:OnItemsChanged( changed_map )
    for i=1,8 do
        local speed_item = ItemManager:GetItemByName("speedup_"..i)
        local count = speed_item:Count()
        if count>0 then
            self.own_labels[i]:setString(_("拥有")..count)
            self.gem_images[i]:hide()
        else
            self.own_labels[i]:setString(speed_item:Price())
            self.gem_images[i]:show()
        end
    end
end
return WidgetAccelerateGroup













