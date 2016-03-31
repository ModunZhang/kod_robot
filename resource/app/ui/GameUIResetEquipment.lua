--
-- Author: Your Name
-- Date: 2016-01-22 14:54:30
--
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetDragonEquipIntensify = import("..widget.WidgetDragonEquipIntensify")
local WidgetInfo = import("..widget.WidgetInfo")
local GameUIDragonEyrieDetail = import(".GameUIDragonEyrieDetail")
local DragonManager = import("..entity.DragonManager")
local UIListView = import(".UIListView")
local Localize = import("..utils.Localize")

local BODY_HEIGHT = 700
local BODY_WIDTH = 608
local LISTVIEW_WIDTH = 548
local GameUIResetEquipment = class("GameUIResetEquipment", WidgetPopDialog)

function GameUIResetEquipment:ctor(building,dragon,equipment_obj)
    GameUIResetEquipment.super.ctor(self,BODY_HEIGHT,Localize.body[equipment_obj:Body()],window.top-120)
    self.dragon = dragon
    self.equipment = equipment_obj
    self.building = building
end
function GameUIResetEquipment:onEnter()
    GameUIResetEquipment.super.onEnter(self)
    local node = self:GetBody()

    local size = node:getContentSize()

    local make_eq_bg_2 = display.newSprite("make_eq_bg_2.png"):addTo(node):pos(size.width/2, size.height - 436/2 + 10):scale(0.8)
    local make_eq_bg_4 = display.newSprite("make_eq_bg_4.png"):addTo(node):pos(size.width/2, size.height - 436/2 + 10):scale(0.8)
    local make_eq_bg_3 = display.newSprite("make_eq_bg_3.png"):addTo(node):pos(size.width/2, size.height - 436/2 + 10):scale(0.8)
    local make_eq_bg_1 = display.newSprite("make_eq_bg_1.png"):addTo(node):pos(size.width/2, size.height - 436/2 + 10):scale(0.8)
    local action_1 = cc.RotateTo:create(20, -180)
    local action_2 = cc.RotateTo:create(20, -360)
    local action_3 = cc.RotateTo:create(20, 180)
    local action_4 = cc.RotateTo:create(20, 360)

    local seq_1 = transition.sequence{
        action_1,action_2
    }
    local seq_2 = transition.sequence{
        action_3,action_4
    }
    make_eq_bg_2:runAction(cc.RepeatForever:create(seq_1))
    make_eq_bg_4:runAction(cc.RepeatForever:create(seq_2))

    local mainEquipment = self:GetEquipmentItem()
        :addTo(make_eq_bg_3):align(display.CENTER_TOP,make_eq_bg_3:getContentSize().width/2 + 4,make_eq_bg_3:getContentSize().height/2 + 64)
    local count_bg = WidgetUIBackGround.new({width = 116,height = 30},WidgetUIBackGround.STYLE_TYPE.STYLE_3):addTo(make_eq_bg_3)
        :align(display.CENTER_TOP,make_eq_bg_3:getContentSize().width/2 + 4,make_eq_bg_3:getContentSize().height/2 - 54)
	self.current_count = UIKit:ttfLabel({
            text = self:GetCurrentEquipmentCount(),
            size = 22,
            color= 0x403c2f
        }):addTo(count_bg):align(display.RIGHT_CENTER,count_bg:getContentSize().width/2,count_bg:getContentSize().height/2)
	UIKit:ttfLabel({
            text = "-1",
            color= 0x8c3708,
            size = 22
        }):addTo(count_bg):align(display.LEFT_CENTER,count_bg:getContentSize().width/2,count_bg:getContentSize().height/2)
        
    local desc_label = UIKit:ttfLabel({
        text = _("消耗相同一个装备，重新随机装备的加成属性"),
        size = 20,
        color= 0x615b44
    }):addTo(node):align(display.TOP_CENTER, BODY_WIDTH/2, make_eq_bg_1:getPositionY() - make_eq_bg_1:getContentSize().height/2 + 30)

    self.widgetInfo = WidgetInfo.new({
        h = 160,
        info = self:GetEquipmentEffect()
    }):align(display.TOP_CENTER, BODY_WIDTH/2, desc_label:getPositionY() - desc_label:getContentSize().height - 20):addTo(node)

    self.reset_button = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
        :addTo(node)
        :align(display.RIGHT_BOTTOM,BODY_WIDTH - 40,20)
        :setButtonLabel("normal", UIKit:commonButtonLable({
            text = _("重置"),
            size = 22,
        }))
        :onButtonClicked(function()
            local equipment = self:GetEquipment()
            app:GetAudioManager():PlayeEffectSoundWithKey("UI_BLACKSMITH_FORGE")
            NetManager:getResetDragonEquipmentPromise(equipment:Type(),equipment:Body()):done(function()
                GameGlobalUI:showTips(_("提示"),_("装备重置成功"))
                self:RefreshInfoUI()
            end)
        end)
    self.reset_button:setButtonEnabled(self:GetCurrentEquipmentCount() > 0) 
    WidgetPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
        :addTo(node)
        :align(display.LEFT_BOTTOM,40,20)
        :setButtonLabel("normal", UIKit:commonButtonLable({
            text = _("取消"),
            size = 22,
        }))
        :onButtonClicked(function()
            self:LeftButtonClicked()
        end)

end

function GameUIResetEquipment:onExit()
    GameUIResetEquipment.super.onExit(self)
end

function GameUIResetEquipment:GetEquipment()
    return self.equipment
end


-- 调用龙巢详情界面的函数获取道具图标
function GameUIResetEquipment:GetEquipmentItem()
    local item = GameUIDragonEyrieDetail:GetEquipmentItem(self:GetEquipment(),self.dragon:Star(),false)
    item:scale(120/item:getContentSize().width)
    return item
end
function GameUIResetEquipment:GetEquipmentEffect()
    local r = {}
    local equipment = self:GetEquipment()
    local buffers = equipment:GetBufferAndEffect()
    for __,v in ipairs(buffers) do
        table.insert(r,{Localize.dragon_buff_effection[v[1]],string.format("%d%%",v[2]*100)})
    end
    return r
end
function GameUIResetEquipment:GetCurrentEquipmentCount()
    local player_equipments = User.dragonEquipments
    local equipment = self:GetEquipment()
    local eq_name = equipment:IsLoaded() and equipment:Name() or equipment:GetCanLoadConfig().name
    return player_equipments[eq_name] or 0
end
function GameUIResetEquipment:RefreshInfoUI()
    local equipment = self:GetEquipment()
    self.reset_button:setButtonEnabled(self:GetCurrentEquipmentCount() > 0)
    self.current_count:setString(self:GetCurrentEquipmentCount())
    self.widgetInfo:SetInfo(self:GetEquipmentEffect())
end

return GameUIResetEquipment





