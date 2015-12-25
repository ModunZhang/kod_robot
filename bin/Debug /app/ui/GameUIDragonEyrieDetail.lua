--
-- Author: Danny He
-- Date: 2014-10-31 15:08:59
--
local GameUIDragonEyrieDetail = UIKit:createUIClass("GameUIDragonEyrieDetail","GameUIWithCommonHeader")
local cocos_promise = import('..utils.cocos_promise')
local window = import('..utils.window')
local StarBar = import(".StarBar")
local DragonSprite = import("..sprites.DragonSprite")
local GameUIDragonEyrieMain = import(".GameUIDragonEyrieMain")
local WidgetPushButton = import("..widget.WidgetPushButton")
local DragonManager = import("..entity.DragonManager")
local WidgetDragonTabButtons = import("..widget.WidgetDragonTabButtons")
local Dragon = import("..entity.Dragon")
local UIListView = import(".UIListView")
local Localize = import("..utils.Localize")
local config_intInit = GameDatas.PlayerInitData.intInit
local WidgetUseItems = import("..widget.WidgetUseItems")
local UILib = import(".UILib")
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")
local GameUIShowDragonUpStarAnimation = import(".GameUIShowDragonUpStarAnimation")
-- building = DragonEyrie
function GameUIDragonEyrieDetail:ctor(city,building,dragon_type)
    GameUIDragonEyrieDetail.super.ctor(self,city,_("龙巢"))
    self.building = building
    self.dragon_manager = building:GetDragonManager()
    self.dragon = self.dragon_manager:GetDragon(dragon_type)
end


function GameUIDragonEyrieDetail:CreateHomeButton()
     local home_button = cc.ui.UIPushButton.new(
        {normal = "home_btn_up.png",pressed = "home_btn_down.png",disabled = "home_btn_disabled.png"}, nil, {down = "HOME_PAGE"})
        :onButtonClicked(function(event)
            local main_ui = UIKit:GetUIInstance("GameUIDragonEyrieMain")
            if main_ui then
                main_ui:LeftButtonClicked()
            end
            self:LeftButtonClicked()
        end)
        :align(display.LEFT_TOP, 50 , 86)
    cc.ui.UIImage.new("home_icon.png")
        :pos(34, -50)
        :addTo(home_button)
        :scale(0.8)
    return home_button
end

function GameUIDragonEyrieDetail:CreateBetweenBgAndTitle()
    self.content_node = display.newNode():addTo(self:GetView())
    local clipNode = display.newClippingRegionNode(cc.rect(0,0,614,519))
    clipNode:addTo(self.content_node):pos(window.cx - 307,window.top - 519)
    display.newSprite("dragon_animate_bg_624x606.png"):align(display.LEFT_BOTTOM,-5,0):addTo(clipNode)
    display.newSprite("eyrie_584x547.png"):align(display.CENTER_TOP,307, 353):addTo(clipNode)
    self.dragon_base = clipNode
    self:BuildDragonContent()
    local star_bg = display.newSprite("dragon_title_bg_534x16.png")
        :align(display.CENTER_TOP,window.cx,window.top - 100)
        :addTo(self.content_node)
    self.star_bg = star_bg
    local nameLabel = UIKit:ttfLabel({
        text = self:GetDragon():GetLocalizedName(),
        color = 0xebdba0,
        size = 28
    }):align(display.LEFT_CENTER, 50,star_bg:getContentSize().height/2)
        :addTo(star_bg)
    local star_bar = StarBar.new({
        max = self:GetDragon():MaxStar(),
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
        num = self:GetDragon():Star(),
    }):addTo(star_bg):align(display.RIGHT_BOTTOM,480,5)
    self.star_bar = star_bar
    self.tab_buttons = WidgetDragonTabButtons.new(function(tag)
        self:OnTabButtonClicked(tag)
    end):addTo(self.dragon_base):pos(-4,-42)
    --lv label 是公用
    self.lv_label = UIKit:ttfLabel({
        text = "LV 22/50",
        size = 22,
        color = 0x403c2f
    }):align(display.BOTTOM_CENTER,window.cx,self.dragon_base:getPositionY()-self.dragon_base:getContentSize().height - 35):addTo(self:GetView())
    self.hp_process_bg,self.hp_process_timer = self:CreateProgressTimer()
    self.hp_process_bg:addTo(self:GetView()):align(display.CENTER_TOP, window.cx, self.lv_label:getPositionY() - 5)
end

function GameUIDragonEyrieDetail:CreateProgressTimer()
    local bg,progressTimer = nil,nil
    bg = display.newSprite("process_bar_540x40.png")
    progressTimer = UIKit:commonProgressTimer("bar_color_540x40.png"):addTo(bg):align(display.LEFT_CENTER,0,20)
    progressTimer:setPercentage(0)
    local iconbg = display.newSprite("drgon_process_icon_bg.png")
        :addTo(bg)
        :align(display.LEFT_BOTTOM, -13,-2)
    display.newSprite("upgrade_experience_icon.png")
        :addTo(iconbg)
        :pos(iconbg:getContentSize().width/2,iconbg:getContentSize().height/2)
        :scale(0.9)
    self.dragon_hp_label = UIKit:ttfLabel({
         text = "120/360",
         color = 0xfff3c7,
         shadow = true,
         size = 20
    }):addTo(bg):align(display.LEFT_CENTER, 40, 20)
    local add_button = WidgetPushButton.new({normal = "add_btn_up_50x50.png",pressed = "add_btn_down_50x50.png"})
        :addTo(bg)
        :align(display.CENTER_RIGHT,bg:getContentSize().width+10,20)
        :onButtonClicked(function()
            self:OnDragonExpItemUseButtonClicked()
        end)
    return bg,progressTimer
end

function GameUIDragonEyrieDetail:OnMoveInStage()
    GameUIDragonEyrieDetail.super.OnMoveInStage(self)
    local User = User
    self:BuildUI()
    User:AddListenOnType(self, "dragonEquipments")
    self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)

    scheduleAt(self, function()
        if not self:GetDragon():Ishated() then return end
        if self.skill_ui and self.skill_ui.blood_label then
            self.skill_ui.blood_label:setString(string.formatnumberthousands(User:GetResValueByType("blood")))
        end
    end)
    
end

function GameUIDragonEyrieDetail:OnMoveOutStage()
    local User = User
    User:RemoveListenerOnType(self, "dragonEquipments")
    self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)
    GameUIDragonEyrieDetail.super.OnMoveOutStage(self)
end

function GameUIDragonEyrieDetail:VisibleStarBar(v)
    self.star_bg:setVisible(v)
end

function GameUIDragonEyrieDetail:BuildUI()
    self.tab_buttons:SelectButtonByTag("equipment")
end

function GameUIDragonEyrieDetail:BuildDragonContent()
    local dragon_content = self.dragon_base:getChildByTag(101)
    if dragon_content then dragon_content:removeFromParent() end
    if self:GetDragon():Ishated() then
        local dragon = DragonSprite.new(display.getRunningScene():GetSceneLayer(),self:GetDragon():Type())
            :addTo(self.dragon_base)
            :align(display.CENTER, 300,150)
        dragon:setTag(101)
        local bound = dragon:getBoundingBox()
        local nodePoint = self.dragon_base:convertToWorldSpace(cc.p(bound.x, bound.y))
        self.dragon_world_point = nodePoint
    else
        local dragon = display.newSprite(string.format("%s_egg_176x174.png",self:GetDragon():Type()))
            :align(display.CENTER, 307,180)
            :addTo(self.dragon_base)
        dragon:setTag(101)
    end
end

function GameUIDragonEyrieDetail:GetDragon()
    return self.dragon
end
--充能
function GameUIDragonEyrieDetail:OnEnergyButtonClicked()
    local dragon = self:GetDragon()
    NetManager:getHatchDragonPromise(dragon:Type())
end

function GameUIDragonEyrieDetail:GetUpgradDragonStarTips(dragon)
    if dragon:Star() < 2 then
        return string.format(_("晋级需要龙的等级到达%d级，集齐已解锁装备，并全部强化到%d星"),dragon:GetPromotionLevel(),dragon:Star())
    else
        return string.format(_("晋级需要龙的等级到达%d级，集齐全部装备，并全部强化到%d星"),dragon:GetPromotionLevel(),dragon:Star())
    end
end

function GameUIDragonEyrieDetail:RefreshUI()
    local dragon = self:GetDragon()
    local button_tag = self.tab_buttons:GetCurrentTag()
    -- if button_tag ~= 'skill' and self.skill_ui and self.skill_ui.listView then
    --     self.skill_ui.listView:removeAllItems()
    -- end
    if button_tag == 'equipment' then
        self.lv_label:show()
        self.dragon_hp_label:setString(string.formatnumberthousands(dragon:Exp()) .. "/" .. string.formatnumberthousands(dragon:GetMaxExp()))
        self.hp_process_timer:setPercentage(dragon:Exp()/dragon:GetMaxExp()*100)
        self.hp_process_bg:show()
        self.equipment_ui.promotionLevel_label:setString(self:GetUpgradDragonStarTips(dragon))
        local canloadAnyEq = self:FillEquipemtBox()
        self.equipment_ui.upgrade_star_btn:setVisible(not canloadAnyEq)
        self.equipment_ui.load_equipment_btn:setVisible(canloadAnyEq) 
    elseif button_tag == 'skill' then
        self.hp_process_bg:hide()
        self:RefreshSkillList()
        self.skill_ui.blood_label:setString(string.formatnumberthousands(User:GetResValueByType("blood")))
        self.lv_label:hide()
    else
        self.lv_label:show()
        self.dragon_hp_label:setString(string.formatnumberthousands(dragon:Exp()) .. "/" .. string.formatnumberthousands(dragon:GetMaxExp()))
        self.hp_process_timer:setPercentage(dragon:Exp() / dragon:GetMaxExp()*100)
        self.hp_process_bg:show()
        self:RefreshInfoListView()
         self.info_strenth_label:setString(string.formatnumberthousands(dragon:TotalStrength()))
         self.info_vitality_label:setString(string.formatnumberthousands(dragon:TotalVitality()))
         self.info_leadership_label:setString(string.formatnumberthousands(dragon:TotalLeadership()))
    end
    self.lv_label:setString("LV " .. dragon:Level() .. "/" .. dragon:GetMaxLevel())
    self.star_bar:setNum(dragon:Star())
end

--装备
function GameUIDragonEyrieDetail:CreateNodeIf_equipment()
    if self.equipment_node then return self.equipment_node end
    local equipment_node = display.newNode():addTo(self:GetView())
    self.equipment_ui = {}
    self.equipment_ui.promotionLevel_label =  UIKit:ttfLabel({
        text = "",
        size = 20,
        color = 0x403c2f
    }):align(display.BOTTOM_CENTER,window.cx,window.bottom+50):addTo(equipment_node)
    local content_box = UIKit:CreateBoxPanel9({width = 546,height = 244})
        :addTo(equipment_node)
        :pos(window.left+45,self.dragon_base:getPositionY()-self.dragon_base:getContentSize().height  - 244 - 40 - 60)

    local equipment_box = display.newNode()
    equipment_box:addTo(content_box):pos(8,5)
    self.equipment_ui.equipment_box = equipment_box
    self.equipment_ui.upgrade_star_btn = WidgetPushButton.new({
        normal = "yellow_btn_up_186x66.png",
        pressed = "yellow_btn_down_186x66.png"
    }):setButtonLabel("normal", UIKit:commonButtonLable({
        text = _("晋级")
    })):align(display.BOTTOM_CENTER, 273, 20)
        :addTo(content_box)
        :onButtonClicked(function()
            self:UpgradeDragonStar()
        end)
    self.equipment_ui.load_equipment_btn = WidgetPushButton.new({
        normal = "purple_btn_up_148x58.png",
        pressed = "purple_btn_down_148x58.png"
    }):setButtonLabel("normal", UIKit:commonButtonLable({
        text = _("装备")
    })):align(display.BOTTOM_CENTER, 273, 20)
        :addTo(content_box)
        :onButtonClicked(function()
            self:OnLoadAllButtonClicked()
        end)
    self:PlaceEquipmentBoxIntoEqNode()
    -- self:FillEquipemtBox()
    self.equipment_node = equipment_node
    return self.equipment_node
end

function GameUIDragonEyrieDetail:OnLoadAllButtonClicked()
    if #self.can_load_equipemts ~= 0 then
        local eq = self.can_load_equipemts[1]
        NetManager:getLoadDragonEquipmentPromise(eq:Type(),eq:Body(),eq:GetCanLoadConfig().name):done(function(msg)
            self:FillEquipemtBox()
            self:OnLoadAllButtonClicked()

        end)
    else
        return 
    end
end

--返回装备图片信息 return 背景图 装备图
function GameUIDragonEyrieDetail:GetEquipmentItemImageInfo(equipment_obj,dragon_star)
    local bgImages = {"box_104x104_1.png","box_104x104_2.png","box_104x104_3.png","box_104x104_4.png"}
    local image = UILib.getDragonEquipmentImage(equipment_obj:Type(),equipment_obj:Body(),dragon_star)
    return bgImages[dragon_star ],image
end

function GameUIDragonEyrieDetail:PlaceEquipmentBoxIntoEqNode()
    if self.equipment_boxs then
        for key,v in pairs(self.equipment_boxs) do
            v:removeSelf()
        end
    end
    self.equipment_boxs = {}
    local dragon = self:GetDragon()
    local eq = dragon:GetEquipmentByBody(Dragon.DRAGON_BODY.armguardLeft)
    local image,__ = self:GetEquipmentItemImageInfo(eq,dragon:Star())
    local sp = display.newSprite(image):align(display.LEFT_BOTTOM, 5, 5):addTo(self.equipment_ui.equipment_box)
    
    self.equipment_boxs['armguardLeft'] = sp
    eq = dragon:GetEquipmentByBody(Dragon.DRAGON_BODY.crown)
    image,__ = self:GetEquipmentItemImageInfo(eq,dragon:Star())
    sp = display.newSprite(image):align(display.LEFT_TOP, 5, 230):addTo(self.equipment_ui.equipment_box)
    self.equipment_boxs['crown'] = sp
    eq = dragon:GetEquipmentByBody(Dragon.DRAGON_BODY.orb)
    image,__ = self:GetEquipmentItemImageInfo(eq,dragon:Star())
    sp = display.newSprite(image):align(display.LEFT_TOP, 144, 230):addTo(self.equipment_ui.equipment_box)
    self.equipment_boxs['orb'] = sp
    eq = dragon:GetEquipmentByBody(Dragon.DRAGON_BODY.chest)
    image,__ = self:GetEquipmentItemImageInfo(eq,dragon:Star())
    sp = display.newSprite(image):align(display.LEFT_TOP, 283, 230):addTo(self.equipment_ui.equipment_box)
    self.equipment_boxs['chest'] = sp
    eq = dragon:GetEquipmentByBody(Dragon.DRAGON_BODY.sting)
    image,__ = self:GetEquipmentItemImageInfo(eq,dragon:Star())
    sp = display.newSprite(image):align(display.RIGHT_TOP, 525, 230):addTo(self.equipment_ui.equipment_box)
    self.equipment_boxs['sting'] = sp
    eq = dragon:GetEquipmentByBody(Dragon.DRAGON_BODY.armguardRight)
    image,__ = self:GetEquipmentItemImageInfo(eq,dragon:Star())
    sp = display.newSprite(image):align(display.RIGHT_BOTTOM, 525, 5):addTo(self.equipment_ui.equipment_box)
    self.equipment_boxs['armguardRight'] = sp
end


function GameUIDragonEyrieDetail:OnUserDataChanged_dragonEquipments(userData, deltaData)
    if self.tab_buttons:GetCurrentTag() == 'equipment' then
        local canloadAnyEq = self:FillEquipemtBox()
        self.equipment_ui.upgrade_star_btn:setVisible(not canloadAnyEq)
        self.equipment_ui.load_equipment_btn:setVisible(canloadAnyEq) 
    end
end


function GameUIDragonEyrieDetail:FillEquipemtBox()
    assert(self.equipment_boxs['armguardLeft'])
    self.can_load_equipemts = {}
    local final_point = self.dragon_world_point
    if self.equipment_nodes then
        for k,v in pairs(self.equipment_nodes) do
            v:removeSelf()
        end
    end
    self.equipment_nodes = {}
    local dragon = self:GetDragon()
    for body,box in pairs(self.equipment_boxs) do
        local eq = dragon:GetEquipmentByBody(body)
        if not eq:IsLoaded() and self:CheckCanLoadEquipment(eq) then
            table.insert(self.can_load_equipemts,eq)
        end
        local node = self:GetEquipmentItem(eq,dragon:Star(),true):addTo(box):pos(52,52)
        node.final_point = box:convertToNodeSpace(final_point)
        node.need_animation = not eq:IsLocked()
        self.equipment_nodes[body] = node
    end
    return #self.can_load_equipemts > 0
end

function GameUIDragonEyrieDetail:OnDragonExpItemUseButtonClicked()
    local widgetUseItems = WidgetUseItems.new():Create({
        item_name = "dragonExp_1",
        dragon = self:GetDragon()
    })
    widgetUseItems:AddToCurrentScene()
end

function GameUIDragonEyrieDetail:UpgradeDragonStar()
    local dragon = self:GetDragon()
    if not dragon:IsReachPromotionLevel() then
        UIKit:showMessageDialog(_("提示"), _("龙未达到晋级等级"), function()end)
        return
    end

    if not dragon:EquipmentsIsReachMaxStar() then
        UIKit:showMessageDialog(_("提示"), _("所有装备未达到最高星级"), function()end)
        return
    end

    if dragon:Star() == 4 then
        UIKit:showMessageDialog(_("提示"), _("5星上限即将开放!"), function()end)
        return
    end

    NetManager:getUpgradeDragonStarPromise(dragon:Type())
end

function GameUIDragonEyrieDetail:CheckCanLoadEquipment(equipment)
    if equipment:IsLocked() or equipment:IsLoaded() then return false end
    local player_equipments = User.dragonEquipments
    local eq_name = equipment:IsLoaded() and equipment:Name() or equipment:GetCanLoadConfig().name
    return (player_equipments[eq_name] or 0) > 0 
end

function GameUIDragonEyrieDetail:GetEquipmentItem(equipment_obj,dragon_star,needInfoIcon)
    needInfoIcon = needInfoIcon or false
    local can_load = self:CheckCanLoadEquipment(equipment_obj)
    local bgImage,equipmentImage = self:GetEquipmentItemImageInfo(equipment_obj,dragon_star)
    local equipment_node = display.newSprite(bgImage) 
    if equipment_obj:IsLocked() then
        display.newSprite("dragon_eq_lock_87x88.png", equipment_node:getContentSize().width/2,equipment_node:getContentSize().height/2):addTo(equipment_node)
    else
        if equipment_obj:IsLoaded() then
            display.newSprite(equipmentImage):addTo(equipment_node):pos(equipment_node:getContentSize().width/2,equipment_node:getContentSize().height/2):scale(0.6)
            if needInfoIcon then
                display.newSprite("i_icon_20x20.png"):align(display.LEFT_BOTTOM, 5, 5):addTo(equipment_node)
            end
            StarBar.new({
                max = equipment_obj:MaxStar(),
                bg = "Stars_bar_bg.png",
                fill = "Stars_bar_highlight.png",
                num =  equipment_obj:Star(),
                margin = 0,
                direction = StarBar.DIRECTION_VERTICAL,
                scale = 0.55,
            }):addTo(equipment_node):align(display.LEFT_BOTTOM,equipment_node:getContentSize().width-30,15)
        else
            local icon = UIKit:getDiscolorrationSprite(equipmentImage)
                :addTo(equipment_node)
                :pos(equipment_node:getContentSize().width/2,equipment_node:getContentSize().height/2):scale(0.6)
            icon:setOpacity(80)
            if needInfoIcon then
                if can_load then
                    display.newSprite("dragon_load_eq_37x38.png"):align(display.RIGHT_BOTTOM,104, 5):addTo(equipment_node)
                else
                    display.newSprite("i_icon_20x20.png"):align(display.LEFT_BOTTOM, 5, 5):addTo(equipment_node)
                end
            end
        end
        if needInfoIcon then
            WidgetPushTransparentButton.new(cc.rect(0,0,104,104)):align(display.LEFT_BOTTOM,0, 0):addTo(equipment_node):onButtonClicked(function()
                self:HandleClickedOnEquipmentItem(equipment_obj,can_load)
            end)
        end
    end
    return equipment_node
end

function GameUIDragonEyrieDetail:OnBasicChanged(dragon,star_chaned)
    if self:GetDragon():Type() ~= dragon:Type() then return end
    if star_chaned then
        local button_tag = self.tab_buttons:GetCurrentTag()
        if button_tag == 'equipment' then
            local sequence = transition.sequence({
                cc.RotateTo:create(0.2, 180),
                cc.RotateTo:create(0.2, 360),
            })
            local action_2 = cc.RepeatForever:create(sequence)
            for __,v in pairs( self.equipment_nodes) do
                if v.need_animation then
                    local action_1 = cc.Spawn:create(cc.ScaleTo:create(1,0.5),cc.FadeOut:create(1))
                    action_1 = cc.Spawn:create(action_1,cc.MoveTo:create(1,v.final_point))
                    action_1 = transition.sequence({action_1,cc.CallFunc:create(function()
                        self:RefreshUI()
                        self:ShowUpgradeStarSuccess()
                        app:GetAudioManager():PlayeEffectSoundWithKey("HOORAY")
                    end)})
                    v:runAction(action_1)
                    v:runAction(action_2:clone())
                end
            end
        else   
             self:RefreshUI()
        end
    else
        self:RefreshUI()
    end
end

function GameUIDragonEyrieDetail:ShowUpgradeStarSuccess()
    GameUIShowDragonUpStarAnimation.new(self:GetDragon()):addTo(self)
end

function GameUIDragonEyrieDetail:OnTabButtonClicked(tag)
    if tag == 'back' then
        self:LeftButtonClicked()
        return
    end
    if not self:GetDragon():Ishated() then return end
    if self['CreateNodeIf_' .. tag] then
        if self.current_node then
            self.current_node:hide()
        end
        self.current_node = self['CreateNodeIf_' .. tag](self)
        self:RefreshUI()
        self.current_node:show()
    end
end

function GameUIDragonEyrieDetail:HandleClickedOnEquipmentItem(equipment_obj,canLoad)
    if equipment_obj:IsLoaded() then
        UIKit:newGameUI("GameUIDragonEquipment",self.building,self:GetDragon(),equipment_obj):AddToCurrentScene(true)
    else
        if canLoad then
            NetManager:getLoadDragonEquipmentPromise(equipment_obj:Type(),equipment_obj:Body(),equipment_obj:GetCanLoadConfig().name):done(function(msg)
                self:FillEquipemtBox()
            end)
        else
            UIKit:newGameUI("GameUIDragonEquipmentMake",self:GetDragon(),equipment_obj):AddToCurrentScene(true)
        end
    end
end

--技能
function GameUIDragonEyrieDetail:CreateNodeIf_skill()
    if self.skill_node then return self.skill_node end
    self.skill_ui = {}
    local skill_node = display.newNode():addTo(self:GetView())

    local list_bg = UIKit:CreateBoxPanel(346)
        :addTo(skill_node)
        :pos(window.left+45,self.dragon_base:getPositionY()-self.dragon_base:getContentSize().height - 320 - 90)
    local header_bg = UIKit:CreateBoxPanel9({height = 40}):addTo(skill_node):align(display.LEFT_BOTTOM, list_bg:getPositionX(), list_bg:getPositionY()+316+40)
    local list = UIListView.new {
        viewRect = cc.rect(3,8, 548, 332),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    }:addTo(list_bg)
    local add_button = WidgetPushButton.new({normal = "add_btn_up_50x50.png",pressed = "add_btn_down_50x50.png"})
        :addTo(header_bg)
        -- :scale(0.7)
        :align(display.RIGHT_CENTER,540,20)
        :onButtonClicked(function()
            self:OnHeroBloodUseItemClicked()
        end)

    self.skill_ui.listView = list
    local blood_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color = 0x403c2f,
        align = cc.TEXT_ALIGNMENT_RIGHT
    })
        :addTo(header_bg)
        :align(display.RIGHT_CENTER,add_button:getPositionX() - 65,add_button:getPositionY())

    self.skill_ui.blood_label = blood_label
    local magic_bottle = display.newSprite("heroBlood_3_128x128.png") 
        :align(display.LEFT_CENTER,15, blood_label:getPositionY())
        :addTo(header_bg)
        :scale(0.3)
    UIKit:ttfLabel({
        text = _("英雄之血"),
        size = 20,
        color = 0x403c2f,
        align = cc.TEXT_ALIGNMENT_LEFT
    }):align(display.LEFT_CENTER, magic_bottle:getPositionX() + magic_bottle:getCascadeBoundingBox().width + 10, magic_bottle:getPositionY()):addTo(header_bg)
    self.skill_ui.magic_bottle = magic_bottle
    self.skill_node = skill_node
    return self.skill_node
end

function GameUIDragonEyrieDetail:GetSkillListItem(skill)
    local bg = WidgetPushButton.new({normal = "dragon_skill_item_180x110.png"}, {scale9 = false})
    bg:setAnchorPoint(cc.p(0,0))
    local skill_bg = display.newSprite("dragon_skill_bg_110x110.png", 62, 55):addTo(bg)
    local skill_icon = UILib.dragon_skill_icon[skill:Name()][skill:Type()]
    if skill:IsLocked() then
        local skill_sp = UIKit:getDiscolorrationSprite(skill_icon):addTo(skill_bg):pos(55,55)
        skill_sp:scale(80/skill_sp:getContentSize().width)
        display.newSprite("dragon_skill_lock_34x46.png",136, 55):addTo(bg)
    else
        local skill_sp = display.newSprite(skill_icon, 55, 55):addTo(skill_bg)
        skill_sp:scale(80/skill_sp:getContentSize().width)
        UIKit:ttfLabel({
            text = _("等级"),
            size = 20,
            color = 0x68634f,
            align = cc.TEXT_ALIGNMENT_LEFT
        }):align(display.LEFT_BOTTOM,120,60):addTo(bg)
        UIKit:ttfLabel({
            text = skill:Level(),
            size = 24,
            color = 0x403c2f,
            align = cc.TEXT_ALIGNMENT_CENTER
        }):align(display.CENTER_BOTTOM,132,30):addTo(bg)
    end
    bg:onButtonClicked(function(event)
        self:SkillListItemClicked(skill)
    end)
    return bg
end

--根据skill 的key排序 并分页
function GameUIDragonEyrieDetail:GetSkillListData(perLineCount,page)
    local skills = self:GetDragon():Skills()
    local keys = table.keys(skills)
    table.sort( keys, function(a,b) return a<b end )
    local skills_local = {}

    for i,v in ipairs(keys) do
        table.insert(skills_local,skills[v])
    end
    local pageCount =  math.ceil(#skills_local/perLineCount)
    if not page then return pageCount end
    return LuaUtils:table_slice(skills_local,1+(page - 1)*perLineCount,perLineCount*page)
end


function GameUIDragonEyrieDetail:RefreshSkillList()
    self.skill_ui.listView:removeAllItems()

    for i=1,self:GetSkillListData(3) do
        local item = self.skill_ui.listView:newItem()
        local content = display.newNode()
        local lineData = self:GetSkillListData(3,i)
        for j=1,#lineData do
            local skillData = lineData[j]
            local oneSkill = self:GetSkillListItem(skillData)
            oneSkill:addTo(content)
            local x = (j-1) * (180 + 4)
            oneSkill:pos(x,0)
        end
        content:size(548,110)
        item:addContent(content)
        item:setItemSize(548,110)
        self.skill_ui.listView:addItem(item)
    end
    self.skill_ui.listView:reload()
end

function GameUIDragonEyrieDetail:SkillListItemClicked(skill)
    UIKit:newGameUI("GameUIDragonSkill",self.building,skill):AddToCurrentScene(true)
end

--信息
function GameUIDragonEyrieDetail:CreateNodeIf_info()
    if self.info_node then return self.info_node end
    local dragon = self:GetDragon()
    local info_node = display.newNode():addTo(self:GetView())
    local list_bg = display.newScale9Sprite("background_568x120.png", 0,0,cc.size(546,212),cc.rect(15,10,538,100))
        :addTo(info_node)
        :align(display.LEFT_BOTTOM, window.left+45,window.bottom + 30)
    self.info_list = UIListView.new({
        viewRect = cc.rect(13,10, 520, 192),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        alignment = cc.ui.UIListView.ALIGNMENT_LEFT
    })
        :addTo(list_bg,2)
    local strenth_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(150,78),cc.rect(15,10,136,64))
        :align(display.LEFT_BOTTOM,window.left + 45,list_bg:getPositionY() + 232)
        :addTo(info_node)
    UIKit:ttfLabel({
        text = _("力量"),
        size = 20,
        color= 0x615b44
    }):align(display.CENTER_TOP,75, 72):addTo(strenth_bg)
    self.info_strenth_label = UIKit:ttfLabel({
        text = string.formatnumberthousands(dragon:TotalStrength()),
        size = 24,
        color=0x117a00
    }):align(display.CENTER_BOTTOM,75, 10):addTo(strenth_bg)
    local vitality_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(150,78),cc.rect(15,10,136,64))
        :align(display.LEFT_BOTTOM,window.left + 242,list_bg:getPositionY() + 232)
        :addTo(info_node)
    UIKit:ttfLabel({
        text = _("活力"),
        size = 20,
        color= 0x615b44
    }):align(display.CENTER_TOP,75, 72):addTo(vitality_bg)
    self.info_vitality_label = UIKit:ttfLabel({
        text = string.formatnumberthousands(dragon:TotalVitality()),
        size = 24,
        color=0x117a00
    }):align(display.CENTER_BOTTOM,75, 10):addTo(vitality_bg)

    local leadership_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(150,78),cc.rect(15,10,136,64))
        :align(display.RIGHT_BOTTOM,window.left + 45+546,list_bg:getPositionY() + 232)
        :addTo(info_node)

    UIKit:ttfLabel({
        text = _("领导力"),
        size = 20,
        color= 0x615b44
    }):align(display.CENTER_TOP,75, 72):addTo(leadership_bg)
    self.info_leadership_label = UIKit:ttfLabel({
        text = string.formatnumberthousands(dragon:TotalLeadership()),
        size = 24,
        color=0x117a00
    }):align(display.CENTER_BOTTOM,75, 10):addTo(leadership_bg)
    self.info_node = info_node
    return self.info_node
end

function GameUIDragonEyrieDetail:RefreshInfoListView()
    dump(self:GetInfomationData())
    self.info_list:removeAllItems()
    for index,v in ipairs(self:GetInfomationData()) do
        local item = self.info_list:newItem()
        local content = self:GetInfoListItem(index,v[1],v[2])
        item:addContent(content)
        item:setItemSize(520, 48)
        self.info_list:addItem(item)
    end
    self.info_list:reload()
end

function GameUIDragonEyrieDetail:GetInfomationData()
    local r = {}
    local dragon = self:GetDragon()
    table.insert(r, {_("带兵量"),dragon:LeadCitizen()})
    for __,v in ipairs(dragon:GetAllEquipmentBuffEffect()) do
        if v[2]*100 > 0 then
            table.insert(r,{Localize.dragon_buff_effection[v[1]] or v[1],string.format("%d%%",v[2]*100)})
        end
    end

    for __,v in ipairs(dragon:GetAllSkillBuffEffect()) do
        if v[2]*100 > 0 then
            table.insert(r,{Localize.dragon_skill_effection[v[1]] or v[1],string.format("%d%%",v[2]*100)})
        end
    end
    return r
end

function GameUIDragonEyrieDetail:GetInfoListItem(index,title,val)
    local bg = display.newScale9Sprite(string.format("back_ground_548x40_%d.png",index%2 == 0 and 1 or 2)):size(520,48)
    UIKit:ttfLabel({
        text = title,
        color = 0x615b44,
        size = 20
    }):align(display.LEFT_CENTER, 10, 24):addTo(bg)

    UIKit:ttfLabel({
        text = val,
        color = 0x403c2f,
        size = 20,
        align = cc.TEXT_ALIGNMENT_RIGHT,
    }):align(display.RIGHT_CENTER, 510, 24):addTo(bg)
    return bg
end
-- dragon_body ==> Dragon.DRAGON_BODY.XXX
function GameUIDragonEyrieDetail:Find(dragon_body)
    dragon_body = checknumber(dragon_body)
    return cocos_promise.defer(function()
        if not self.equipment_nodes[dragon_body] then
            promise.reject({code = -1, msg = "没有找到对应item"}, building_type)
        end
        return self.equipment_nodes[dragon_body]
    end)
end

function GameUIDragonEyrieDetail:OnHeroBloodUseItemClicked()
    local widgetUseItems = WidgetUseItems.new():Create({
        item_name = "heroBlood_1",
    })
    widgetUseItems:AddToCurrentScene()
end

return GameUIDragonEyrieDetail