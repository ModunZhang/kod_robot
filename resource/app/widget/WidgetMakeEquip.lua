local EQUIPMENTS = GameDatas.DragonEquipments.equipments
local Localize = import("..utils.Localize")
local MaterialManager = import("..entity.MaterialManager")
local WidgetPushButton = import(".WidgetPushButton")
local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetUIBackGround2 = import(".WidgetUIBackGround2")
local WidgetPopDialog = import(".WidgetPopDialog")
local UILib = import("..ui.UILib")


local WidgetMakeEquip = class("WidgetMakeEquip", WidgetPopDialog
    --     function()
    --     local node = display.newColorLayer(UIKit:hex2c4b(0x7a000000))
    --     node:setNodeEventEnabled(true)
    --     return node
    -- end
    )
local STAR_BG = {
    "box_100x100_1.png",
    "box_100x100_2.png",
    "box_100x100_3.png",
    "box_100x100_4.png",
    "box_100x100_5.png",
}
local DRAGON_BG = {
    redDragon = "box_100x100_1.png",
    blueDragon = "box_100x100_2.png",
    greenDragon = "box_100x100_3.png",
}

-- local EQUIP_LOCALIZE = Localize.equip_material
local EQUIP_LOCALIZE = Localize.equip
local DRAGON_LOCALIZE = Localize.dragon
local BODY_LOCALIZE = Localize.body
function WidgetMakeEquip:ctor(equip_type, black_smith, city)
    WidgetMakeEquip.super.ctor(self,862,_("制造装备"),display.top-80)
    self.equip_type = equip_type
    self.black_smith = black_smith
    self.city = city
    local equip_config = EQUIPMENTS[equip_type]
    self.matrials = LuaUtils:table_map(string.split(equip_config.materials, ","), function(k, v)
        return k, string.split(v, ":")
    end)
    self.equip_config = equip_config
    -- back_ground
    local back_ground = self:GetBody()

    -- title
    local size = back_ground:getContentSize()


    local make_eq_bg_2 = display.newSprite("make_eq_bg_2.png"):addTo(back_ground):pos(size.width/2, size.height - 436/2-20)
    local make_eq_bg_4 = display.newSprite("make_eq_bg_4.png"):addTo(back_ground):pos(size.width/2, size.height - 436/2-20)
    local make_eq_bg_3 = display.newSprite("make_eq_bg_3.png"):addTo(back_ground):pos(size.width/2, size.height - 436/2-20)
    local make_eq_bg_1 = display.newSprite("make_eq_bg_1.png"):addTo(back_ground):pos(size.width/2, size.height - 436/2-20)
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
    -- 装备星级背景
    local bg = STAR_BG[equip_config.maxStar]
    local size = back_ground:getContentSize()
    local star_bg = cc.ui.UIImage.new(bg):addTo(make_eq_bg_3, 2)
        :align(display.CENTER, make_eq_bg_3:getContentSize().width/2+3, make_eq_bg_3:getContentSize().height/2+3)



    -- 装备图标
    local pos = star_bg:getAnchorPointInPoints()
    cc.ui.UIImage.new(UILib.equipment[equip_type]):addTo(star_bg, 2)
        :align(display.CENTER, pos.x, pos.y):scale(0.5)

    -- 装备的数量背景
    local back_ground_97x20 = cc.ui.UIImage.new("back_ground_138x34.png"):addTo(star_bg, 2)
        :align(display.CENTER, pos.x, pos.y - 10 - 128/2+6):scale(0.7)

    -- 装备数量label
    local pos = back_ground_97x20:getAnchorPointInPoints()
    self.number = cc.ui.UILabel.new({
        text = "",
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(back_ground_97x20)
        :align(display.CENTER, pos.x, pos.y)

    -- 装备信息背景框
    local  eq_info_bg = cc.ui.UIImage.new("back_ground_314x108.png"):addTo(make_eq_bg_1)
        :align(display.CENTER, make_eq_bg_1:getContentSize().width/2,90)

    -- 装备名字
    cc.ui.UILabel.new({
        text = EQUIP_LOCALIZE[equip_type],
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0xffedae)
    }):addTo(eq_info_bg)
        :align(display.BOTTOM_CENTER, eq_info_bg:getContentSize().width/2, 70)


    -- used for dragon
    cc.ui.UILabel.new({
        text = string.format("%s%s%s", _("仅供"), DRAGON_LOCALIZE[equip_config.usedFor], _("装备")),
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0xffedae)
    }):addTo(eq_info_bg)
        :align(display.BOTTOM_CENTER, eq_info_bg:getContentSize().width/2, 42)


    -- used for dragon category
    cc.ui.UILabel.new({
        text = BODY_LOCALIZE[equip_config.category],
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0xffedae)
    }):addTo(eq_info_bg)
        :align(display.BOTTOM_CENTER, eq_info_bg:getContentSize().width/2, 14)


    -- 立即建造
    local size = back_ground:getContentSize()
    local instant_button = cc.ui.UIPushButton.new({normal = "green_btn_up_250x65.png",
        pressed = "green_btn_down_250x65.png"}):addTo(back_ground)
        :align(display.CENTER, 150, 100)
        :setButtonLabel(cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("立即制造"),
            size = 24,
            color = UIKit:hex2c3b(0xfff3c7)
        }))
        :onButtonClicked(function(event)
            if self:IsAbleToMakeEqui(true) then
                NetManager:getInstantMakeDragonEquipmentPromise(equip_type):done(function()
                    self:RefreshUI()
                end)
            end
        end)

    -- gem
    cc.ui.UIImage.new("gem_icon_62x61.png"):addTo(instant_button, 2)
        :align(display.CENTER, -100, -50):scale(0.5)

    -- gem count
    self.gem_label = cc.ui.UILabel.new({
        text = "600",
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(instant_button, 2)
        :align(display.LEFT_CENTER, -100 + 20, -50)

    local size = back_ground:getContentSize()
    local button = WidgetPushButton.new({
        normal = "yellow_btn_up_185x65.png",
        pressed = "yellow_btn_down_185x65.png"
    }
    ,{}
    ,{
        disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}
    }
    ):addTo(back_ground)
        :align(display.CENTER, size.width - 130, 100)
        :setButtonLabel(cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("制造"),
            size = 24,
            color = UIKit:hex2c3b(0xfff3c7)
        }))
        :onButtonClicked(function(event)
            if self:IsAbleToMakeEqui(false) then
                NetManager:getMakeDragonEquipmentPromise(equip_type):catch(function(err)
                    dump(err:reason())
                end)
                self:Close()
            end
        end)
    self.normal_build_btn = button

    -- 时间glass
    cc.ui.UIImage.new("hourglass_39x46.png"):addTo(button, 2)
        :align(display.LEFT_CENTER, -90, -55):scale(0.7)

    -- 时间
    local center = -20
    self.make_time = cc.ui.UILabel.new({
        text = GameUtils:formatTimeStyle1(equip_config.makeTime),
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(button, 2)
        :align(display.CENTER, center, -50)

    -- buff增益
    self.buff_time = cc.ui.UILabel.new({
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x068329)
    }):addTo(button, 2)
        :align(display.CENTER, center, -70)

    -- 需求列表
    local unit_len, origin_y, gap_x = 105, 350, 80
    local len = #self.matrials
    local total_len = len * unit_len + (len - 1) * gap_x
    local origin_x = (size.width - total_len) / 2 + unit_len / 2
    local materials_map = {}
    for i, v in ipairs(self.matrials) do
        local material_type = v[1]
        -- 材料背景根据龙的颜色来
        local material = cc.ui.UIImage.new(DRAGON_BG[equip_config.usedFor]):addTo(back_ground, 2)
            :align(display.CENTER, origin_x + (unit_len + gap_x) * (i - 1), origin_y)
        -- 材料icon
        local pos = material:getAnchorPointInPoints()
        local material_image = UILib.dragon_material_pic_map[material_type]
        local image = cc.ui.UIImage.new(material_image):addTo(material, 2)
            :align(display.CENTER, pos.x, pos.y)
        image:scale(80/math.max(image:getContentSize().width,image:getContentSize().height))
        -- 数量背景框
        local materials_bg =  cc.ui.UIImage.new("back_ground_96x30.png"):addTo(material, 2)
            :align(display.CENTER, pos.x, pos.y - material:getContentSize().height / 2 - 18)
        -- 材料数量
        materials_map[i] = UIKit:ttfLabel({
            text ="",
            size = 20,
            color = 0xffedae
        }):addTo(materials_bg, 2)
            :align(display.CENTER, materials_bg:getContentSize().width / 2, materials_bg:getContentSize().height / 2)
    end
    self.materials_map = materials_map


    -- 制造条件
    local condition_bg = WidgetUIBackGround.new({width = 568,height = 100},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
        :addTo(back_ground)
        :align(display.CENTER, size.width/2, 200)
   
    -- 建造队列
    local  condition_bg_1 = display.newSprite("back_ground_548x40_1.png")
        :addTo(condition_bg)
        :align(display.TOP_CENTER, 284, 90)
    cc.ui.UIImage.new("hammer_31x33.png"):addTo(condition_bg_1, 2)
        :align(display.CENTER, 30, 20)

    self.build_label = cc.ui.UILabel.new({
        text = _("制造队列"),
        size = 22,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(condition_bg_1, 2)
        :align(display.LEFT_CENTER, 60, 20)

    local size = back_ground:getContentSize()
    self.build_check_box = cc.ui.UICheckBoxButton.new({on = "yes_40x40.png", off = "no_40x40.png" })
        :addTo(condition_bg_1)
        :align(display.LEFT_CENTER, 500, 20)
        :setButtonSelected(true)
    self.build_check_box:setTouchEnabled(false)


    -- 需要银币
    local  condition_bg_2 = display.newSprite("back_ground_548x40_2.png")
        :addTo(condition_bg)
        :align(display.BOTTOM_CENTER, 284, 10)

    cc.ui.UIImage.new("res_coin_81x68.png"):addTo(condition_bg_2, 2)
        :align(display.CENTER, 30, 20):scale(0.3)

    self.coin_label = cc.ui.UILabel.new({
        text = _("银币"),
        size = 22,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(condition_bg_2, 2)
        :align(display.LEFT_CENTER, 60, 20)

    self.coin_check_box = cc.ui.UICheckBoxButton.new({on = "yes_40x40.png", off = "no_40x40.png" })
        :addTo(condition_bg_2)
        :align(display.LEFT_CENTER, 500, 20)
        :setButtonSelected(true)
    self.coin_check_box:setTouchEnabled(false)

    self.back_ground = back_ground
end
function WidgetMakeEquip:onEnter()
    self.black_smith:AddBlackSmithListener(self)
    self.city:GetMaterialManager():AddObserver(self)
    self.city:GetResourceManager():AddObserver(self)
    self:RefreshUI()
end
function WidgetMakeEquip:onExit()
    self.black_smith:RemoveBlackSmithListener(self)
    self.city:GetMaterialManager():RemoveObserver(self)
    self.city:GetResourceManager():RemoveObserver(self)
end
function WidgetMakeEquip:RefreshUI()
    self:UpdateEquipCounts()
    self:UpdateMaterials()
    self:UpdateBuildLabel(self.black_smith:IsEquipmentEventEmpty() and 0 or 1)
    self:UpdateCoin(self.city:GetResourceManager():GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime()))
    self:UpdateGemLabel()
    self:UpdateBuffTime()
end
-- 装备数量监听
function WidgetMakeEquip:OnMaterialsChanged(material_manager, material_type, changed)
    if material_type == MaterialManager.MATERIAL_TYPE.EQUIPMENT then
        local current = changed[self.equip_type]
        if current then
            self.number:setString(current.new)
        end
    end
end
-- 资源数量监听
function WidgetMakeEquip:OnResourceChanged(resource_manager)
    self:UpdateCoin(resource_manager:GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime()))
end
-- 建造队列监听
function WidgetMakeEquip:OnBeginMakeEquipmentWithEvent(black_smith, event)
    self:UpdateBuildLabel(1)
end
function WidgetMakeEquip:OnMakingEquipmentWithEvent(black_smith, event, current_time)
    self:UpdateBuildLabel(1)
end
function WidgetMakeEquip:OnEndMakeEquipmentWithEvent(black_smith, event, equipment)
    self:UpdateBuildLabel(0)
end
-- 更新装备数量
function WidgetMakeEquip:UpdateEquipCounts()
    local material_manager = self.city:GetMaterialManager()
    local cur = material_manager:GetMaterialsByType(MaterialManager.MATERIAL_TYPE.EQUIPMENT)[self.equip_type]
    local max = self.city:GetFirstBuildingByType("materialDepot"):GetMaxDragonEquipment()
    local label = string.format("%d/%d", cur, max)
    if label ~= self.number:getString() then
        self.number:setString(label)
    end
end
-- 更新材料数量
function WidgetMakeEquip:UpdateMaterials()
    local material_manager = self.city:GetMaterialManager()
    local materials = material_manager:GetMaterialsByType(MaterialManager.MATERIAL_TYPE.DRAGON)
    local matrials_map = self.materials_map
    for i, v in ipairs(self.matrials) do
        local material_type = v[1]
        local matrials_need = tonumber(v[2])
        local ui = matrials_map[i]
        local current = materials[material_type]
        LuaUtils:outputTable("materials[material_type]", materials)
        print("current>>",tolua.type(current))

        ui:setString(string.format("%d/%d", current, matrials_need))
        local un_reached = matrials_need > current
        ui:setColor(un_reached and display.COLOR_RED or UIKit:hex2c3b(0xffedae))
    end
end
-- 更新建筑队列
function WidgetMakeEquip:UpdateBuildLabel(queue)
    local is_enough = queue == 0
    -- self.normal_build_btn:setButtonEnabled(is_enough)
    local label = string.format("%s %d/%d", _("制造队列"), 1,queue)
    if label ~= self.build_label:getString() then
        self.build_label:setString(label)
    end
    self.build_label:setColor(is_enough and UIKit:hex2c3b(0x403c2f) or display.COLOR_RED)
    self.build_check_box:setButtonSelected(is_enough)
end
-- 更新银币数量
function WidgetMakeEquip:UpdateCoin(coin)
    local equip_config = self.equip_config
    local need_coin = equip_config.coin
    local label = string.format("%s %s/%s", _("需要银币"),  GameUtils:formatNumber(coin),GameUtils:formatNumber(need_coin))
    if self.coin_label:getString() ~= label then
        self.coin_label:setString(label)
    end
    local is_enough = coin >= need_coin
    self.coin_label:setColor(is_enough and UIKit:hex2c3b(0x403c2f) or display.COLOR_RED)
    self.coin_check_box:setButtonSelected(is_enough)
end
-- 更新金龙币数量
function WidgetMakeEquip:UpdateGemLabel()
    local equip_config = self.equip_config
    local gem_label = string.format("%d", DataUtils:buyResource({coin = equip_config.coin}, {}) + DataUtils:getGemByTimeInterval(equip_config.makeTime))
    if self.gem_label:getString() ~= gem_label then
        self.gem_label:setString(gem_label)
    end
end
-- 更新buff加成
function WidgetMakeEquip:UpdateBuffTime()
    local time = self.equip_config.makeTime
    local efficiency = self.black_smith:GetEfficiency()
    local buff_time = DataUtils:getBuffEfffectTime(time,efficiency)
    self.buff_time:setString(string.format("(-%s)", GameUtils:formatTimeStyle1(buff_time)))
end

function WidgetMakeEquip:Close()
    if type(self.on_closed) == "function" then
        self.on_closed(self)
    end
    self:removeFromParent()
end
function WidgetMakeEquip:OnClosed(func)
    self.on_closed = func
    return self
end
function WidgetMakeEquip:align(anchorPoint, x, y)
    local size = self.back_ground:getContentSize()
    local point = display.ANCHOR_POINTS[anchorPoint]
    local offset_x, offset_y = size.width * point.x, size.height * point.y
    if x and y then self.back_ground:setPosition(- offset_x + x, - offset_y + y) end
    return self
end

function WidgetMakeEquip:IsAbleToMakeEqui(isFinishNow)
    local city = self.city
    local equip_config = self.equip_config
    if isFinishNow then
        local gem =  DataUtils:buyResource({coin = equip_config.coin}, {}) + DataUtils:getGemByTimeInterval(equip_config.makeTime)
        if gem > User:GetGemResource():GetValue() then
            UIKit:showMessageDialog(_("提示"),_("金龙币不足"),function()  UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)  end)
            return false
        end
    end
    local material_manager = city:GetMaterialManager()
    local is_material_enough = true
    for k,v in pairs(self.matrials) do
        if not is_material_enough then
            break
        end
        material_manager:IteratorDragonMaterialsByType(function (m_name,m_count)
            if m_name == v[1] then
                if tonumber(v[2]) > m_count then
                    UIKit:showMessageDialog(_("提示"),_("材料不足"),function()end)
                    is_material_enough = false
                end
            end
        end)
    end
    if not is_material_enough  then
        return is_material_enough
    end


    if not isFinishNow then
        local not_suitble = {}
        local need_gems = 0
        -- 制造队列
        if self.black_smith:IsMakingEquipment() then
            local making_event = self.black_smith:GetMakeEquipmentEvent()
            local time_gem = DataUtils:getGemByTimeInterval(making_event:LeftTime(app.timer:GetServerTime()))
            need_gems = need_gems + time_gem
            table.insert(not_suitble, _("完成当前制造队列,需要")..time_gem)
        end
        -- 检查银币
        local current_coin = city:GetResourceManager():GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
        if equip_config.coin>current_coin then
            local coin_gem = DataUtils:buyResource({coin = equip_config.coin}, {coin =current_coin })
            table.insert(not_suitble, _("银币不足,需要")..coin_gem)
            need_gems = need_gems + coin_gem
        end

        if not LuaUtils:table_empty(not_suitble) then
            local message = ""
            for k,v in ipairs(not_suitble) do
                message = message .. v .. "\n"
            end
            UIKit:showMessageDialog(_("提示"),message,function()
                NetManager:getMakeDragonEquipmentPromise(self.equip_type):catch(function(err)
                    dump(err:reason())
                end)
                self:Close()
            end):CreateNeeds({value = need_gems})
            return false
        end
    end
    return true
end

return WidgetMakeEquip