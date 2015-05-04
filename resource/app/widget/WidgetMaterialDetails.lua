local UIListView = import('..ui.UIListView')
local WidgetPushButton = import(".WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetMaterialBox = import("..widget.WidgetMaterialBox")
local MaterialManager = import("..entity.MaterialManager")
local UILib = import("..ui.UILib")
local Localize = import("..utils.Localize")

local WidgetMaterialDetails = UIKit:createUIClass("WidgetMaterialDetails", "UIAutoClose")


function WidgetMaterialDetails:ctor(material_type,material_name)
    WidgetMaterialDetails.super.ctor(self)
    self:InitMaterialDetails(material_type,material_name)
end

function WidgetMaterialDetails:InitMaterialDetails(material_type,material_name)
    self.body = WidgetUIBackGround.new({height=478,isFrame="no"}):align(display.TOP_CENTER,display.cx,display.top-240)
    local bg = self.body
    self:addTouchAbleChild(bg)
    -- bg
    local bg_width,bg_height = bg:getContentSize().width,bg:getContentSize().height
    -- title bg
    local title_bg = display.newSprite("title_blue_600x52.png", bg_width/2,bg_height+10):addTo(bg,2)
    UIKit:ttfLabel(
        {
            text = _("材料详情"),
            size = 24,
            color = 0xffedae
        }):align(display.CENTER, title_bg:getContentSize().width/2, title_bg:getContentSize().height/2)
        :addTo(title_bg)
   
    -- close button
    cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"})
        :onButtonClicked(function(event)
            self:removeFromParent(true)
        end):align(display.CENTER, bg_width-32, bg_height+12):addTo(bg,2)

    local icon_bg = display.newSprite("box_118x118.png"):addTo(bg)
        :align(display.CENTER, 80, bg_height-80)

    local material = cc.ui.UIImage.new(self:GetMaterialImage(material_type,material_name)):addTo(icon_bg)
        :align(display.CENTER, icon_bg:getContentSize().width/2, icon_bg:getContentSize().height/2):scale(100/128)
   
    UIKit:ttfLabel({
        text = Localize.materials[material_name] or Localize.equip[material_name] or Localize.equip_material[material_name] or Localize.soldier_material[material_name] ,
        size = 22,
        color = 0x403c2f
    }):align(display.LEFT_CENTER,150,bg_height-40):addTo(bg,2)
    -- 材料介绍
    self.material_introduce = cc.ui.UILabel.new(
        {
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("材料介绍"),
            font = UIKit:getFontFilePath(),
            size = 22,
            valign = ui.TEXT_VALIGN_TOP,
            dimensions = cc.size(320, 120),
            color = UIKit:hex2c3b(0x797154)
        }):align(display.LEFT_TOP, 150,bg_height-70)
        :addTo(bg)
   
    -- listview
     local origin_listview ,listnode=  UIKit:commonListView({
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(0, 0, 568, 280),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
     listnode:addTo(bg):pos(20,20)
   origin_listview:addItem(self:CreateOriginItem(origin_listview))
   origin_listview:addItem(self:CreateOriginItem(origin_listview))
   origin_listview:addItem(self:CreateOriginItem(origin_listview))
   origin_listview:addItem(self:CreateOriginItem(origin_listview))
   origin_listview:addItem(self:CreateOriginItem(origin_listview))
   origin_listview:reload()
   self.origin_listview = origin_listview
end

function WidgetMaterialDetails:CreateOriginItem(listView)
    local item = listView:newItem()
    item:setItemSize(568,65)
    local bg = display.newSprite("drop_down_box_content_562x58.png")
    local size_bg = bg:getContentSize()
    -- star icon 
    display.newSprite("star_23X23.png"):align(display.LEFT_CENTER, 10, size_bg.height/2):addTo(bg)
    -- 来源 label
    UIKit:ttfLabel(
        {
            text = "假数据！！！！！！！",
            size = 20,
            color = 0x5d563f
        }):align(display.LEFT_CENTER, 30,  size_bg.height/2)
        :addTo(bg)
    -- 来源链接button
    WidgetPushButton.new({normal = "shrine_page_btn_normal_52x44.png",
        pressed = "shrine_page_btn_light_52x44.png"}):align(display.CENTER_RIGHT,size_bg.width-8, size_bg.height/2):addTo(bg)
        :onButtonClicked(function (event)
            print("链接到资源来源")
        end):addChild(display.newSprite("shrine_page_control_26x34.png",-26,0))
    item:addContent(bg)
    return item
end
function WidgetMaterialDetails:GetMaterialImage(material_type,material_name)
    local metarial = ""
    if material_type == MaterialManager.MATERIAL_TYPE.BUILD then
        metarial = "materials"
    elseif material_type == MaterialManager.MATERIAL_TYPE.DRAGON  then
        metarial = "dragon_material_pic_map"
    elseif material_type == MaterialManager.MATERIAL_TYPE.SOLDIER  then
        metarial = "soldier_metarial"
    elseif material_type == MaterialManager.MATERIAL_TYPE.EQUIPMENT  then 
        metarial = "equipment"
    end
    return UILib[metarial][material_name]
end

return WidgetMaterialDetails




