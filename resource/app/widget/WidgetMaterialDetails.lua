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
    local list_height = self:GetProduceHeight(material_type)
    self.body = WidgetUIBackGround.new({height=200 + list_height,isFrame="no"}):align(display.TOP_CENTER,display.cx,display.top-240)
    local bg = self.body
    self:addTouchAbleChild(bg)
    -- bg
    local bg_width,bg_height = bg:getContentSize().width,bg:getContentSize().height
    -- title bg
    local title_bg = display.newSprite("title_blue_600x56.png", bg_width/2,bg_height+10):addTo(bg,2)
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
            text = Localize.equip_material_desc_localize[material_name] or Localize.materials_desc_map[material_name] or Localize.equip_material_desc_localize[material_name] or Localize.soldier_desc_material[material_name],
            font = UIKit:getFontFilePath(),
            size = 22,
            valign = ui.TEXT_VALIGN_TOP,
            dimensions = cc.size(420, 0),
            color = UIKit:hex2c3b(0x615b44)
        }):align(display.LEFT_TOP, 150,bg_height-60)
        :addTo(bg)

    local list,list_node = UIKit:commonListView_1({
        viewRect = cc.rect(0, 0,550, list_height),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list_node:addTo(bg):align(display.BOTTOM_CENTER, bg_width/2, 20)
    if material_type == MaterialManager.MATERIAL_TYPE.BUILD  or material_type == MaterialManager.MATERIAL_TYPE.TECHNOLOGY then
        self:CreateOriginItem(list,_("由工具作坊生产"),function ()
            if City:GetFirstBuildingByType("toolShop"):IsUnlocked() then
                UIKit:newGameUI("GameUIToolShop", City, City:GetFirstBuildingByType("toolShop"),"manufacture"):AddToCurrentScene(true)
            else
                UIKit:showMessageDialog(_("主人"),_("您还没有解锁工具作坊"))
            end
        end)
    elseif material_type == MaterialManager.MATERIAL_TYPE.DRAGON  then
        self:CreateOriginItem(list,_("参加联盟圣地战"),function ()
            if not Alliance_Manager:GetMyAlliance():IsDefault() then
                local buildings = Alliance_Manager:GetMyAlliance():GetAllianceMap():GetMapObjectsByType("building")
                for k,v in pairs(buildings) do
                    if v.name == "shrine" then
                        app:EnterMyAllianceScene({
                            x = v.location.x,
                            y = v.location.y,
                            id = Alliance_Manager:GetMyAlliance():Id(),
                            callback = function (scene)
                                UIKit:newGameUI("GameUIAllianceShrine",City,"fight_event",v:GetAllianceBuildingInfo()):AddToScene(scene, true)
                            end
                        })
                    end
                end
            else
                UIKit:showMessageDialog(_("主人"),_("您还没有加入联盟"))
            end
        end)
        self:CreateOriginItem(list,_("购买&使用初级巨龙宝箱"),function ()
            UIKit:newGameUI('GameUIItems',City,"shop"):AddToCurrentScene(true)
        end)
        self:CreateOriginItem(list,_("联盟匹配战中击杀敌军掉落"),function ()
            if not Alliance_Manager:GetMyAlliance():IsDefault() then
                local mapObject = Alliance_Manager:GetMyAlliance():GetAllianceMap():FindMapObjectById(Alliance_Manager:GetMyAlliance():GetSelf():MapId())
                local location = mapObject.location
                app:EnterMyAllianceScene({
                    x = location.x,
                    y = location.y,
                    id = Alliance_Manager:GetMyAlliance():Id(),
                    callback = function (scene)
                        UIKit:newGameUI("GameUIAllianceBattle", City):AddToScene(scene,true)
                    end
                })
            else
                UIKit:showMessageDialog(_("主人"),_("您还没有加入联盟"))
            end

        end)
    elseif material_type == MaterialManager.MATERIAL_TYPE.SOLDIER  then
        self:CreateOriginItem(list,_("前往飞艇探险"),function ()
            local city = City
            local dragon_manger = city:GetDragonEyrie():GetDragonManager()
            local dragon_type = dragon_manger:GetCanFightPowerfulDragonType()
            if #dragon_type > 0 or dragon_manger:GetDefenceDragon() then
                local _,_,index = city:GetUser():GetPVEDatabase():GetCharPosition()
                app:EnterPVEScene(index)
            else
                UIKit:showMessageDialog(_("主人"),_("需要一条空闲状态的魔龙才能探险"))
            end
            app:GetAudioManager():PlayeEffectSoundWithKey("AIRSHIP")
        end)
    end
    list:reload()
    self.listview = list
end

function WidgetMaterialDetails:CreateOriginItem(listView,label,callback)
    local item = listView:newItem()
    local item_width,item_height = 547,57
    item:setItemSize(item_width,item_height)
    local image = self.flag and "back_ground_548x40_1.png" or "back_ground_548x40_2.png"
    local bg = display.newScale9Sprite(image,0,0,cc.size(item_width, item_height),cc.rect(10,10,528,20))
    -- star icon
    display.newSprite("star_23X23.png"):align(display.LEFT_CENTER, 10, item_height/2):addTo(bg)
    -- 来源 label
    UIKit:ttfLabel(
        {
            text = label,
            size = 20,
            color = 0x5d563f
        }):align(display.LEFT_CENTER, 40,  item_height/2)
        :addTo(bg)
    -- 来源链接button
    -- WidgetPushButton.new({normal = "next_32x38.png",
    --     pressed = "next_32x38.png"}):align(display.CENTER_RIGHT,item_width-8, item_height/2):addTo(bg)
    --     :onButtonClicked(function (event)
    --     end)
    display.newSprite("next_32x38.png"):align(display.CENTER_RIGHT,item_width-8, item_height/2):addTo(bg)

    item.button = cc.ui.UIPushButton.new():onButtonClicked(function (event)
        callback()
    end):addTo(bg)
        :pos(item_width/2, item_height/2)
        :size(item_width,item_height)
    item:addContent(bg)
    listView:addItem(item)
    self.flag = not self.flag
end
function WidgetMaterialDetails:GetMaterialImage(material_type,material_name)
    local metarial = ""
    if material_type == MaterialManager.MATERIAL_TYPE.BUILD  or material_type == MaterialManager.MATERIAL_TYPE.TECHNOLOGY then
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
function WidgetMaterialDetails:GetProduceHeight(material_type)
    if material_type == MaterialManager.MATERIAL_TYPE.BUILD  or material_type == MaterialManager.MATERIAL_TYPE.TECHNOLOGY then
        return 57
    elseif material_type == MaterialManager.MATERIAL_TYPE.DRAGON  then
        return 57 * 3
    elseif material_type == MaterialManager.MATERIAL_TYPE.SOLDIER  then
        return 57
    end
end

-- fte
function WidgetMaterialDetails:Find()
    return self.listview:getItems()[1]
end

return WidgetMaterialDetails












