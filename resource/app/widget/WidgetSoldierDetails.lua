local UIListView = import('..ui.UIListView')
local WidgetSlider = import('.WidgetSlider')
local UILib = import("..ui.UILib")
local Localize = import("..utils.Localize")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetSliderWithInput = import("..widget.WidgetSliderWithInput")
local WidgetInfoBuff = import("..widget.WidgetInfoBuff")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local window = import("..utils.window")



local normal = GameDatas.Soldiers.normal
local special = GameDatas.Soldiers.special


local WidgetSoldierDetails = class("WidgetSoldierDetails", WidgetPopDialog)

function WidgetSoldierDetails:ctor(soldier_type,soldier_level)
    self.soldier_count = City:GetSoldierManager():GetCountBySoldierType(soldier_type)
    local height =  500
    WidgetSoldierDetails.super.ctor(self,height,_("兵种详情"),window.top-200)
    self.soldier_type = soldier_type
    self.soldier_level = soldier_level
    -- 取得对应士兵配置表
    self.s_config = soldier_level and normal[soldier_type.."_"..soldier_level]
        or special[soldier_type]
    self.s_buff_field = DataUtils:getAllSoldierBuffValue(self.s_config)
    self:InitSoldierDetails()
end

function WidgetSoldierDetails:InitSoldierDetails()
    -- 士兵信息配置表
    local sc = self.s_config

    -- bg
    local bg = self.body

    local bg_width,bg_height = bg:getContentSize().width,bg:getContentSize().height

    self.soldier_name_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = Localize.soldier_name[self.soldier_type],
        font = UIKit:getFontFilePath(),
        size = 24,
        color = UIKit:hex2c3b(0x5a5544)
    }):align(display.LEFT_CENTER,180,bg_height-50):addTo(bg,2)
    local soldier_ui_config = UILib.soldier_image[self.soldier_type][self.soldier_level]


    display.newSprite(UILib.soldier_color_bg_images[self.soldier_type]):addTo(bg)
        :align(display.CENTER_TOP,100, bg_height-30):scale(130/128)

    local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER_TOP,100, bg_height-30)
    soldier_head_icon:scale(130/soldier_head_icon:getContentSize().height)
    display.newSprite("box_soldier_128x128.png"):addTo(soldier_head_icon):align(display.CENTER, soldier_head_icon:getContentSize().width/2, soldier_head_icon:getContentSize().height-64)
    bg:addChild(soldier_head_icon)


    local num_title_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = _("数量"),
        font = UIKit:getFontFilePath(),
        size = 22,
        color = UIKit:hex2c3b(0x5a5544)
    }):align(display.LEFT_CENTER,180,bg_height-90):addTo(bg,2)

    local soldier_count = self.soldier_count
    self.total_soldier = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = soldier_count,
        font = UIKit:getFontFilePath(),
        size = 22,
        color = UIKit:hex2c3b(0x5a5544)
    }):align(display.LEFT_CENTER,num_title_label:getPositionX()+num_title_label:getContentSize().width+10,bg_height-90):addTo(bg,2)

    -- 士兵属性
    self:InitSoldierAttr()
end


function WidgetSoldierDetails:InitSoldierAttr()
    local sc = self.s_config

    local  attr_table = {
        {
            _("对步兵攻击"),
            sc.infantry,
            self:GetSoldierFieldWithBuff("infantry")
        },
        {
            _("对弓箭手攻击"),
            sc.archer,
            self:GetSoldierFieldWithBuff("archer")
        },
        {
            _("对骑兵攻击"),
            sc.cavalry,
            self:GetSoldierFieldWithBuff("cavalry")
        },
        {
            _("对投石车攻击"),
            sc.siege,
            self:GetSoldierFieldWithBuff("siege")
        },
        {
            _("对城墙攻击"),
            sc.wall,
            self:GetSoldierFieldWithBuff("wall")
        },
        {
            _("生命值"),
            sc.hp,
            self:GetSoldierFieldWithBuff("hp")
        },
        {
            _("人口"),
            sc.citizen,
            self:GetSoldierFieldWithBuff("citizen")
        },
        {
            _("维护费"),
            sc.consumeFoodPerHour,
            self:GetSoldierFieldWithBuff("consumeFoodPerHour")
        },
        {
            _("负重"),
            sc.load,
            self:GetSoldierFieldWithBuff("load")
        },
        {
            _("行军速度"),
            sc.march,
            self:GetSoldierFieldWithBuff("march")
        },
    }

    WidgetInfoBuff.new({
        info=attr_table,
        h =300,
    }):align(display.BOTTOM_CENTER, self.body:getContentSize().width/2, 20):addTo(self.body)
end

function WidgetSoldierDetails:GetSoldierFieldWithBuff(field)
    local sf = self.s_buff_field
    if sf[field] then
        if field ~= 'consumeFoodPerHour' then
            return  " +" .. sf[field]
        else
            return " -" .. sf[field]
        end
    else
        return nil
    end
end

return WidgetSoldierDetails





