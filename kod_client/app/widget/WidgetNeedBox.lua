local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetNeedBox = class("WidgetNeedBox", function(...)
    return display.newNode(...)
end)

local function need_label(params)
    local node = display.newNode()
    local params1 = clone(params)
    node.color = UIKit:hex2c3b(params.color)
    node.current = UIKit:ttfLabel(params):addTo(node)
    node.need = UIKit:ttfLabel(params1):addTo(node)
    function node:SetCurrentAndNeed(current, need)
        self.current:setString(GameUtils:formatNumber(current))
        self.current:setColor(current >= need and node.color or display.COLOR_RED)
        self.need:setString(string.format("/%s", GameUtils:formatNumber(need)))
        local size = self.current:getContentSize()
        self.need:pos((size.width - self.need:getContentSize().width) / 2, - size.height)
        return self
    end
    function node:align(...)
        local anchor, x, y = ...
        self.current:align(anchor)
        self.need:align(anchor)
        return self:pos(x, y)
    end
    return node
end

function WidgetNeedBox:ctor()
    local col1_x, col2_x, col3_x, col4_x = 35, 160, 285, 410
    local row_y, label_relate_x, label_relate_y = 28, 32, 12

    local back_ground_556x56 = WidgetUIBackGround.new({width = 556,height = 56},WidgetUIBackGround.STYLE_TYPE.STYLE_5):addTo(self)

    cc.ui.UIImage.new("res_wood_82x73.png")
        :addTo(back_ground_556x56)
        :align(display.CENTER, col1_x, row_y)
        :scale(0.4)

    self.wood = need_label({
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = 0x403c2f
    }):addTo(back_ground_556x56, 2)
        :align(display.LEFT_CENTER, col1_x + label_relate_x, row_y + label_relate_y)

    cc.ui.UIImage.new("res_stone_88x82.png")
        :addTo(back_ground_556x56)
        :align(display.CENTER, col2_x, row_y)
        :scale(0.4)
    self.stone = need_label({
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = 0x403c2f
    }):addTo(back_ground_556x56, 2)
        :align(display.LEFT_CENTER, col2_x + label_relate_x, row_y + label_relate_y)


    cc.ui.UIImage.new("res_iron_91x63.png")
        :addTo(back_ground_556x56)
        :align(display.CENTER, col3_x, row_y)
        :scale(0.4)
    self.iron = need_label({
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = 0x403c2f
    }):addTo(back_ground_556x56, 2)
        :align(display.LEFT_CENTER, col3_x + label_relate_x, row_y + label_relate_y)


    cc.ui.UIImage.new("hourglass_30x38.png")
        :addTo(back_ground_556x56)
        :align(display.CENTER, col4_x, row_y)
        :scale(0.8)
    self.time = cc.ui.UILabel.new({
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(back_ground_556x56, 2)
        :align(display.LEFT_CENTER, col4_x + label_relate_x, row_y + label_relate_y)

    self.buff_reduce_time = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "(-00:00:00)",
        font = UIKit:getFontFilePath(),
        size = 18,
        color = UIKit:hex2c3b(0x068329)
    }):addTo(back_ground_556x56, 2)
        :align(display.LEFT_CENTER, col4_x + label_relate_x - 5, row_y + label_relate_y - 20)
end

local GameUtils = GameUtils
function WidgetNeedBox:SetNeedNumber(wood, stone, iron, time)
    self.wood:SetCurrentAndNeed(unpack(wood))
    self.stone:SetCurrentAndNeed(unpack(stone))
    self.iron:SetCurrentAndNeed(unpack(iron))
    self.time:setString(GameUtils:formatTimeStyle1(time))
    local effect = UtilsForTech:GetEffect("sketching", User.productionTechs["sketching"])
    self.buff_reduce_time:setString("(-"..GameUtils:formatTimeStyle1(math.ceil(time *  effect))..")")
    return self
end

return WidgetNeedBox








