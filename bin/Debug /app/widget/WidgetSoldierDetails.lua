local UIListView = import('..ui.UIListView')
local WidgetSlider = import('.WidgetSlider')
local UILib = import("..ui.UILib")
local StarBar = import("..ui.StarBar")
local Localize = import("..utils.Localize")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetSliderWithInput = import("..widget.WidgetSliderWithInput")
local WidgetInfoBuff = import("..widget.WidgetInfoBuff")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local window = import("..utils.window")



local normal = GameDatas.Soldiers.normal
local special = GameDatas.Soldiers.special
local soldier_vs = GameDatas.ClientInitGame.soldier_vs

local function return_vs_soldiers_map(soldier_name)
    local strong_vs = {}
    local weak_vs = {}
    for k, v in pairs(soldier_vs[DataUtils:GetSoldierTypeByName(soldier_name)]) do
        if v == "strong" then
            table.insert(strong_vs, k)
        elseif v == "weak" then
            table.insert(weak_vs, k)
        end
    end
    return {strong_vs = strong_vs, weak_vs = weak_vs}
end

local WidgetSoldierDetails = class("WidgetSoldierDetails", WidgetPopDialog)

function WidgetSoldierDetails:ctor(soldier_type,soldier_level)
    self.soldier_count = User.soldiers[soldier_type]
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
    local soldier_type = self.soldier_type

    local bg_width,bg_height = bg:getContentSize().width,bg:getContentSize().height

    local title_blue = display.newScale9Sprite("title_blue_430x30.png",0,0,cc.size(410,30), cc.rect(10,10,410,10)):addTo(bg, 2)
        :align(display.RIGHT_CENTER, bg_width-20, bg_height - 44)

    local title_size = title_blue:getContentSize()
    self.soldier_name_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = Localize.soldier_name[soldier_type].." X"..string.formatnumberthousands(self.soldier_count),
        font = UIKit:getFontFilePath(),
        size = 24,
        color = UIKit:hex2c3b(0xffedae)
    }):addTo(title_blue):align(display.LEFT_CENTER, 15, title_size.height/2)
    local soldier_ui_config = UILib.soldier_image[soldier_type][self.soldier_level]


    display.newSprite(UILib.soldier_color_bg_images[soldier_type]):addTo(bg)
        :align(display.CENTER_TOP,100, bg_height-30):scale(130/128)

    local soldier_head_icon = display.newSprite(soldier_ui_config):align(display.CENTER_TOP,100, bg_height-30)
    soldier_head_icon:scale(130/soldier_head_icon:getContentSize().height)
    display.newSprite("box_soldier_128x128.png"):addTo(soldier_head_icon):align(display.CENTER, soldier_head_icon:getContentSize().width/2, soldier_head_icon:getContentSize().height-64)
    bg:addChild(soldier_head_icon)
    local soldier_star_bg = display.newSprite("tmp_back_ground_102x22.png"):addTo(soldier_head_icon):align(display.BOTTOM_CENTER,soldier_head_icon:getContentSize().width/2 - 10, 4)
    self.soldier_star = StarBar.new({
            max = 3,
            bg = "Stars_bar_bg.png",
            fill = "Stars_bar_highlight.png",
            num = self.soldier_level,
            margin = 5,
            direction = StarBar.DIRECTION_HORIZONTAL,
            scale = 0.8,
        }):addTo(soldier_star_bg):align(display.CENTER,58, 11)

    --
    local label_origin_x = 205
    local label = UIKit:ttfLabel({
        text = _("强势对抗"),
        size = 22,
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = 0x5bb800
    }):addTo(bg, 2):align(display.LEFT_BOTTOM, label_origin_x - 12 , bg_height - 95 - 11)

    local vs_map = return_vs_soldiers_map(soldier_type)
    local strong_vs = {}
    for i, v in ipairs(vs_map.strong_vs) do
        table.insert(strong_vs, Localize.soldier_category[v])
    end
    local soldier_name = UIKit:ttfLabel({
        text = table.concat(strong_vs, ", "),
        size = 22,
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = 0x403c2f
    }):addTo(bg, 2)
        :align(display.LEFT_BOTTOM, label_origin_x + label:getContentSize().width - 12, bg_height - 95 - 11)

    local label = UIKit:ttfLabel({
        text = _("弱势对抗"),
        size = 22,
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = 0x890000
    }):addTo(bg, 2)
        :align(display.LEFT_BOTTOM, label_origin_x-12, bg_height - 135 - 11)

    local weak_vs = {}
    for i, v in ipairs(vs_map.weak_vs) do
        table.insert(weak_vs, Localize.soldier_category[v])
    end
    local soldier_name = UIKit:ttfLabel({
        text = table.concat(weak_vs, ", "),
        size = 22,
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = 0x403c2f
    }):addTo(bg, 2)
        :align(display.LEFT_BOTTOM, label_origin_x + label:getContentSize().width - 12, bg_height - 135 - 11)

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
            return  " +" .. math.floor(sf[field])
        else
            return " -" .. sf[field]
        end
    else
        return nil
    end
end

return WidgetSoldierDetails





