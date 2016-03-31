local DragonEquipments = GameDatas.DragonEquipments
local EQUIPMENTS = DragonEquipments.equipments
local Localize = import("..utils.Localize")
local WidgetPushButton = import(".WidgetPushButton")
local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetPopDialog = import(".WidgetPopDialog")
local UILib = import("..ui.UILib")


local WidgetMakeEquip = class("WidgetMakeEquip", WidgetPopDialog)
local STAR_BG = {
    "box_104x104_1.png",
    "box_104x104_2.png",
    "box_104x104_3.png",
    "box_104x104_4.png",
}
local DRAGON_BG = {
    redDragon = "box_118x118.png",
    blueDragon = "box_118x118.png",
    greenDragon = "box_118x118.png",
}

-- local EQUIP_LOCALIZE = Localize.equip_material
local EQUIP_LOCALIZE = Localize.equip
local EQUIP_MAKE = Localize.equip_make
local DRAGON_LOCALIZE = Localize.dragon
local DRAGON_ONLY = Localize.dragon_only
local BODY_LOCALIZE = Localize.body
function WidgetMakeEquip:ctor(equip_type, black_smith, city)
    WidgetMakeEquip.super.ctor(self,862,_("制造装备"),display.top-80)
    self.equip_type = equip_type
    self.black_smith = black_smith
    self.city = city
    local equip_config = EQUIPMENTS[equip_type]
    local equip_attr = DragonEquipments[string.split(equip_config.category,",")[1]][equip_config.maxStar.."_0"]
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
        :align(display.CENTER, pos.x, pos.y):scale(0.62)

    -- 装备的数量背景
    local back_ground_97x20 = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(138,34),cc.rect(15,10,136,64)):addTo(star_bg, 2)
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

    local added = 1
    for i = 1,3 do
        local desc,value
        if i == 1 and equip_attr.strength > 0 then
            desc = _("攻击力")
            value = equip_attr.strength
        elseif i == 2 and equip_attr.vitality > 0 then
            desc = _("生命值")
            value = equip_attr.vitality * 4
        elseif i == 3 and equip_attr.leadership > 0 then
            desc = _("带兵量")
            value = equip_attr.leadership * 100
        end
        if desc then
            UIKit:ttfLabel({
                text = desc,
                size = 18,
                color = 0xffedae
            }):addTo(eq_info_bg)
                :align(display.BOTTOM_LEFT, 20, added == 1 and 42 or 14)
            UIKit:ttfLabel({
                text = "+" .. value,
                size = 20,
                color = 0x57ce00
            }):addTo(eq_info_bg)
                :align(display.BOTTOM_RIGHT, eq_info_bg:getContentSize().width - 20, added == 1 and 42 or 14)
            added = added + 1
        end
    end

    -- 立即建造
    local size = back_ground:getContentSize()
    local instant_button = cc.ui.UIPushButton.new({normal = "green_btn_up_250x66.png",
        pressed = "green_btn_down_250x66.png"}):addTo(back_ground)
        :align(display.CENTER, 150, 100)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("立即制造"),
            size = 24,
            color = 0xfff3c7,
            shadow = true
        }))
        :onButtonClicked(function(event)
            if self:IsAbleToMakeEqui(true) then
                if app:GetGameDefautlt():IsOpenGemRemind() then
                    UIKit:showConfirmUseGemMessageDialog(_("提示"),string.format(_("是否消费%s金龙币"),self.gem_label:getString()), function()
                        NetManager:getInstantMakeDragonEquipmentPromise(equip_type):done(function()
                            self:RefreshUI()
                        end)
                    end,true,true)
                else
                    NetManager:getInstantMakeDragonEquipmentPromise(equip_type):done(function()
                        self:RefreshUI()
                    end)
                end
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
        normal = "yellow_btn_up_186x66.png",
        pressed = "yellow_btn_down_186x66.png"
    }
    ,{}
    ,{
        disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}
    }
    ):addTo(back_ground)
        :align(display.CENTER, size.width - 130, 100)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("制造"),
            size = 24,
            color = 0xfff3c7,
            shadow = true
        }))
        :onButtonClicked(function(event)
            if self:IsAbleToMakeEqui(false) then
                NetManager:getMakeDragonEquipmentPromise(equip_type):done(function (response)
                    GameGlobalUI:showTips(_("提示"), EQUIP_MAKE[equip_type])
                    return response
                end)

                self:Close()
            end
        end)
    self.normal_build_btn = button

    -- 时间glass
    cc.ui.UIImage.new("hourglass_30x38.png"):addTo(button, 2)
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
        local material = WidgetPushButton.new({normal = DRAGON_BG[equip_config.usedFor]})
            :onButtonClicked(function(event)
                UIKit:newWidgetUI("WidgetMaterialDetails", "dragonMaterials",material_type):AddToCurrentScene()
            end):addTo(back_ground, 2)
            :align(display.CENTER, origin_x + (unit_len + gap_x) * (i - 1), origin_y)

        -- 材料icon
        local pos = material:getAnchorPointInPoints()
        local material_image = UILib.dragon_material_pic_map[material_type]
        local image = cc.ui.UIImage.new(material_image):addTo(material, 2)
            :align(display.CENTER, pos.x, pos.y)
        image:scale(100/math.max(image:getContentSize().width,image:getContentSize().height))
        -- 数量背景框
        local materials_bg =  cc.ui.UIImage.new("back_ground_96x30.png"):addTo(material, 2)
            :align(display.CENTER, pos.x, pos.y - material:getContentSize().height / 2 -78)
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
    cc.ui.UIImage.new("hammer_33x40.png"):addTo(condition_bg_1, 2)
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
    self.build_check_box = cc.ui.UICheckBoxButton.new({on = "yes_40x40.png", off = "wow_40x40.png" })
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

    self.coin_check_box = cc.ui.UICheckBoxButton.new({on = "yes_40x40.png", off = "wow_40x40.png" })
        :addTo(condition_bg_2)
        :align(display.LEFT_CENTER, 500, 20)
        :setButtonSelected(true)
    self.coin_check_box:setTouchEnabled(false)

    self.back_ground = back_ground
end
function WidgetMakeEquip:onEnter()
    local User = self.city:GetUser()
    User:AddListenOnType(self, "dragonMaterials")
    User:AddListenOnType(self, "dragonEquipmentEvents")
    self:RefreshUI()
    scheduleAt(self, function()
        local coin = self.city:GetUser():GetResValueByType("coin")
        local equip_config = self.equip_config
        local need_coin = equip_config.coin
        local label = string.format( _("需要银币 %s/%s"),  GameUtils:formatNumber(coin),GameUtils:formatNumber(need_coin))
        self.coin_label:setString(label)
        local is_enough = coin >= need_coin
        self.coin_label:setColor(is_enough and UIKit:hex2c3b(0x403c2f) or display.COLOR_RED)
        self.coin_check_box:setButtonSelected(is_enough)
    end)
end
function WidgetMakeEquip:onExit()
    local User = self.city:GetUser()
    User:RemoveListenerOnType(self, "dragonMaterials")
    User:RemoveListenerOnType(self, "dragonEquipmentEvents")
end
function WidgetMakeEquip:RefreshUI()
    local User = self.city:GetUser()
    self:UpdateEquipCounts()
    self:UpdateMaterials()
    self:UpdateBuildLabel(#User.dragonEquipmentEvents)
    self:UpdateGemLabel()
    self:UpdateBuffTime()
end
-- 装备数量监听
function WidgetMakeEquip:OnUserDataChanged_dragonMaterials(userData, deltaData)
    local ok, value = deltaData("dragonMaterials")
    if ok then
        self:UpdateMaterials()
    end
end
-- 建造队列监听
function WidgetMakeEquip:OnUserDataChanged_dragonEquipmentEvents(userData, deltaData)
    if deltaData("dragonEquipmentEvents.add") then
        self:UpdateBuildLabel(1)
    elseif deltaData("dragonEquipmentEvents.remove") then
        self:UpdateBuildLabel(0)
    end
end
-- 更新装备数量
function WidgetMakeEquip:UpdateEquipCounts()
    local cur = self.city:GetUser().dragonEquipments[self.equip_type]
    -- local max = self.city:GetFirstBuildingByType("materialDepot"):GetMaxDragonEquipment()
    local label = string.format("%d", cur, max)
    self.number:setString(label)
end
-- 更新材料数量
function WidgetMakeEquip:UpdateMaterials()
    local materials = self.city:GetUser().dragonMaterials
    local matrials_map = self.materials_map
    for i, v in ipairs(self.matrials) do
        local material_type = v[1]
        local matrials_need = tonumber(v[2])
        local ui = matrials_map[i]
        local current = materials[material_type]

        ui:setString(string.format("%d/%d", current, matrials_need))
        local un_reached = matrials_need > current
        ui:setColor(un_reached and display.COLOR_RED or UIKit:hex2c3b(0xffedae))
    end
end
-- 更新建筑队列
function WidgetMakeEquip:UpdateBuildLabel(queue)
    local is_enough = queue == 0
    -- self.normal_build_btn:setButtonEnabled(is_enough)
    local label = string.format(_("制造队列 %d/%d"), 1 - queue,1)
    self.build_label:setString(label)
    self.build_label:setColor(is_enough and UIKit:hex2c3b(0x403c2f) or display.COLOR_RED)
    self.build_check_box:setButtonSelected(is_enough)
end
-- 更新金龙币数量
function WidgetMakeEquip:UpdateGemLabel()
    local equip_config = self.equip_config
    local gem_label = string.format("%d", DataUtils:buyResource({coin = equip_config.coin}, {}) + DataUtils:getGemByTimeInterval(equip_config.makeTime))
    self.gem_label:setString(gem_label)
end
-- 更新buff加成
function WidgetMakeEquip:UpdateBuffTime()
    local User = self.city:GetUser()
    local time = self.equip_config.makeTime
    local efficiency = UtilsForBuilding:GetEfficiencyBy(User, "blackSmith")
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
    local User = self.city:GetUser()
    local equip_config = self.equip_config
    if isFinishNow then
        local gem =  DataUtils:buyResource({coin = equip_config.coin}, {}) + DataUtils:getGemByTimeInterval(equip_config.makeTime)
        if gem > User:GetGemValue() then
            UIKit:showMessageDialog(_("提示"),_("金龙币不足"),function()  UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)  end)
            return false
        end
    end
    local is_material_enough = true
    for k,v in pairs(self.matrials) do
        if not is_material_enough then
            break
        end
        for m_name,m_count in pairs(User.dragonMaterials) do
            if m_name == v[1] then
                if tonumber(v[2]) > m_count then
                    UIKit:showMessageDialogWithParams({
                        title = _("提示"),
                        content = _("材料不足"),
                        ok_callback = function ()
                            UIKit:newGameUI("GameUIItems", self.city,"shop"):AddToCurrentScene(true)
                        end,
                        ok_btn_images = {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"},
                        ok_string = _("购买"),
                        cancel_callback = function ()
                        end
                    })
                    is_material_enough = false
                end
            end
        end
    end
    if not is_material_enough  then
        return is_material_enough
    end


    if not isFinishNow then
        local not_suitble = {}
        local need_gems = 0
        -- 制造队列
        if #User.dragonEquipmentEvents > 0 then
            local event = User.dragonEquipmentEvents[1]
            local time, percent = UtilsForEvent:GetEventInfo(event)
            local time_gem = DataUtils:getGemByTimeInterval(time)
            need_gems = need_gems + time_gem
            table.insert(not_suitble, string.format( _("完成当前制造队列,需要%d"), time_gem ) )
        end
        -- 检查银币
        local current_coin = User:GetResValueByType("coin")
        if equip_config.coin>current_coin then
            local coin_gem = DataUtils:buyResource({coin = equip_config.coin}, {coin =current_coin })

            table.insert(not_suitble, string.format( _("银币不足,需要%d"), coin_gem ) )
            need_gems = need_gems + coin_gem
        end

        if not LuaUtils:table_empty(not_suitble) then
            local message = ""
            for k,v in ipairs(not_suitble) do
                message = message .. v .. "\n"
            end
            UIKit:showMessageDialog(_("提示"),message)
                :CreateOKButtonWithPrice(
                    {
                        listener = function()
                            if need_gems > User:GetGemValue() then
                                UIKit:showMessageDialog(_("提示"),_("金龙币不足"),function()  UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)  end)
                                return false
                            end
                            local equip_type = self.equip_type
                            NetManager:getMakeDragonEquipmentPromise(self.equip_type):done(function()
                                GameGlobalUI:showTips(_("提示"), EQUIP_MAKE[equip_type])
                            end)
                            self:Close()
                        end,
                        btn_images = {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"},
                        price = need_gems
                    }
                ):CreateCancelButton()
            return false
        end
    end
    return true
end

return WidgetMakeEquip










