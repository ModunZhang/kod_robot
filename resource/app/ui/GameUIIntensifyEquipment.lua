--
-- Author: Kenny Dai
-- Date: 2016-01-22 10:56:13
--
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetDragonEquipIntensify = import("..widget.WidgetDragonEquipIntensify")
local GameUIDragonEyrieDetail = import(".GameUIDragonEyrieDetail")
local DragonManager = import("..entity.DragonManager")
local UIListView = import(".UIListView")
local Localize = import("..utils.Localize")

local BODY_HEIGHT = 700
local BODY_WIDTH = 608
local LISTVIEW_WIDTH = 548
local GameUIIntensifyEquipment = class("GameUIIntensifyEquipment", WidgetPopDialog)

function GameUIIntensifyEquipment:ctor(building,dragon,equipment_obj)
    GameUIIntensifyEquipment.super.ctor(self,BODY_HEIGHT,Localize.body[equipment_obj:Body()],window.top-120)
    self.dragon = dragon
    self.equipment = equipment_obj
    self.building = building
    self.dragon_manager = building:GetDragonManager()
    self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)
    User:AddListenOnType(self, "dragonEquipments")
end
function GameUIIntensifyEquipment:onEnter()
    GameUIIntensifyEquipment.super.onEnter(self)
    local node = self:GetBody()
    local mainEquipment = self:GetEquipmentItem()
        :addTo(node):align(display.CENTER_TOP,BODY_WIDTH/2,BODY_HEIGHT - 30)
    self.intensify_mainEquipment = mainEquipment
    local desc_label = UIKit:ttfLabel({
        text = self:GetEquipmentDesc(),
        size = 22,
        color= 0x403c2f
    }):addTo(node):align(display.CENTER_BOTTOM,BODY_WIDTH/2,mainEquipment:getPositionY() - mainEquipment:getContentSize().height - 60)
    self.intensify_desc_label = desc_label

    local progressBg = display.newSprite("progress_bar_540x40_1.png")
        :addTo(node)
        :align(display.CENTER_TOP, BODY_WIDTH/2,desc_label:getPositionY() - desc_label:getContentSize().height + 10)

    local greenProgress = UIKit:commonProgressTimer("progress_bar_540x40_4.png")
        :addTo(progressBg)
        :align(display.LEFT_CENTER,0,20)
    greenProgress:setPercentage(100)
    local yellowProgress = UIKit:commonProgressTimer("progress_bar_540x40_2.png")
        :addTo(progressBg)
        :align(display.LEFT_CENTER,0,20)
    yellowProgress:setPercentage(30)
    self.greenProgress = greenProgress
    self.yellowProgress = yellowProgress
    local exp_label = UIKit:ttfLabel({
        text = "120/120 + 300",
        size = 20,
        color= 0xfff3c7,
        shadow= true,
    }):align(display.LEFT_CENTER,10, 20):addTo(progressBg)

    self.exp_label = exp_label
    local intensify_tip_label = UIKit:ttfLabel({
        text = _("选择多余的装备进行强化"),
        size = 20,
        color= 0x403c2f
    }):align(display.TOP_CENTER, BODY_WIDTH/2, progressBg:getPositionY() - progressBg:getContentSize().height - 22):addTo(node)
    self.intensify_eq_list = UIListView.new {
        viewRect = cc.rect(progressBg:getPositionX() - 270, 90, 540, 282),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        alignment = cc.ui.UIListView.ALIGNMENT_LEFT,
    }:addTo(node)

    local intensify_button = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
        :addTo(node)
        :align(display.RIGHT_BOTTOM,BODY_WIDTH - 40,30)
        :setButtonLabel("normal", UIKit:commonButtonLable({
            text = _("强化"),
            size = 22,
        }))
        :onButtonClicked(function()
            self:IntensifyButtonClicked()
        end)
    self.intensify_button = intensify_button

    WidgetPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
        :addTo(node)
        :align(display.LEFT_BOTTOM,40,30)
        :setButtonLabel("normal", UIKit:commonButtonLable({
            text = _("取消"),
            size = 22,
        }))
        :onButtonClicked(function()
            self:LeftButtonClicked()
        end)

    self:RefreshIntensifyUI()

end

function GameUIIntensifyEquipment:onExit()
    User:RemoveListenerOnType(self, "dragonEquipments")
    self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)
    GameUIIntensifyEquipment.super.onExit(self)
end
function GameUIIntensifyEquipment:GetEquipmentDesc()
    return string.format(_("可强化等级:%d/%d"), self:GetEquipment():Star(), self.dragon:Star())
end
function GameUIIntensifyEquipment:GetEquipment()
    return self.equipment
end
function GameUIIntensifyEquipment:RefreshIntensifyUI(isAnimationyellowProcess)
    if type(isAnimationyellowProcess) ~= 'boolean' then isAnimationyellowProcess = false end
    self:RefreshEquipmentItem()
    local equipment = self:GetEquipment()
    if equipment:Star() < self.dragon:Star() then
        self.exp_label:setString(equipment.exp .. "/" .. equipment:GetNextStarDetailConfig().enhanceExp)
        self.greenProgress:setPercentage((equipment:Exp() or 0)/equipment:GetNextStarDetailConfig().enhanceExp * 100)
        if isAnimationyellowProcess then
            local current_percent = self.yellowProgress:getPercentage()
            local percent = (equipment:Exp() or 0)/equipment:GetNextStarDetailConfig().enhanceExp * 100
            if current_percent > percent then
                self.yellowProgress:setPercentage(0)
            end
            local action = cc.ProgressTo:create(0.5, (equipment:Exp() or 0)/equipment:GetNextStarDetailConfig().enhanceExp * 100)
            self.yellowProgress:runAction(action)
        else
            self.yellowProgress:setPercentage((equipment:Exp() or 0)/equipment:GetNextStarDetailConfig().enhanceExp * 100)
        end
    else
        self.greenProgress:setPercentage(100)
        if isAnimationyellowProcess then
            local action = cc.ProgressTo:create(0.5, 100)
            self.yellowProgress:runAction(action)
        else
            self.yellowProgress:setPercentage(100)
        end
        self.exp_label:setString(_("装备已达到最大星级"))
        self.intensify_button:setButtonEnabled(false)
    end
    self:RefreshIntensifyEquipmentListView()
end
function GameUIIntensifyEquipment:RefreshEquipmentItem()
    self.intensify_mainEquipment:removeFromParent()
    local mainEquipment = self:GetEquipmentItem()
    mainEquipment:addTo(self:GetBody()):align(display.CENTER_TOP,BODY_WIDTH/2,BODY_HEIGHT - 30)
    self.intensify_mainEquipment = mainEquipment
end
function GameUIIntensifyEquipment:RefreshIntensifyEquipmentListView()
    self.allEquipemnts = {}
    self.intensify_eq_list:removeAllItems()
    local equipment = self:GetEquipment()
    local lineCount = self:GetPlayerEquipmentsListData(5)
    if lineCount > 0 then
        for i=1,lineCount do
            local item =self.intensify_eq_list:newItem()
            local node = display.newNode()
            local lineData = self:GetPlayerEquipmentsListData(5,i)
            for j=1,#lineData do
                local perData = lineData[j]
                local tempNode = WidgetDragonEquipIntensify.new(self,perData[1],0,perData[2],equipment:Name())
                    :addTo(node)
                local x = tempNode:getCascadeBoundingBox().width/2 + (j-1) * (tempNode:getCascadeBoundingBox().width +5)
                tempNode:pos(x,tempNode:getCascadeBoundingBox().height/2)
                table.insert(self.allEquipemnts,tempNode)
            end
            item:addContent(node)
            node:size(540, 132)
            item:setMargin({left = 0, right = 0, top = 1, bottom = 5})
            item:setItemSize(540, 132,false)
            self.intensify_eq_list:addItem(item)
        end
    else
        local item =self.intensify_eq_list:newItem()
        local node = display.newNode()
        local button = WidgetPushButton.new({normal = "box_104x104_1.png"}):align(display.LEFT_BOTTOM,0,0):addTo(node)
        display.newSprite("dragon_load_eq_37x38.png"):align(display.RIGHT_BOTTOM,104, 5):addTo(button)
        button:onButtonClicked(function()
            UIKit:newGameUI("GameUIBlackSmith",City,City:GetFirstBuildingByType("blackSmith"),self.equipment:Type()):AddToCurrentScene(true)
        end)
        item:addContent(node)
        node:size(540, 104)
        item:setMargin({left = 0, right = 0, top = 0, bottom = 5})
        item:setItemSize(540, 104,false)
        self.intensify_eq_list:addItem(item)
    end
    self.intensify_eq_list:reload()
end
function GameUIIntensifyEquipment:GetPlayerEquipments()
    local t = {}
    local player_equipments = User.dragonEquipments
    local r = LuaUtils:table_filter(player_equipments,function(equipment,count)
        return count > 0
    end)
    for k,v in pairs(r) do
        table.insert(t,{k,v})
    end
    return t
end

function GameUIIntensifyEquipment:GetPlayerEquipmentsListData(perLineCount,page)
    local data = self:GetPlayerEquipments()
    local pageCount =  math.ceil(#data/perLineCount)
    if not page then return pageCount end
    return LuaUtils:table_slice(data,1+(page - 1)*perLineCount,perLineCount*page)
end
function GameUIIntensifyEquipment:IntensifyButtonClicked()
    local equipments = {}
    table.foreach(self.allEquipemnts,function(index,v)
        local name,count = v:GetNameAndCount()
        if count > 0 then
            table.insert(equipments,{name=name,count=count})
        end
    end)
    if #equipments == 0 then
        UIKit:showMessageDialog(_("提示"), _("请选择用来强化的装备"), function()end)
        return
    end
    local equipment = self:GetEquipment()
    app:GetAudioManager():PlayeEffectSoundWithKey("UI_BLACKSMITH_FORGE")
    NetManager:getEnhanceDragonEquipmentPromise(self.dragon:Type(),equipment:Body(),equipments):done(function()
        if self.intensify_tips and string.len(self.intensify_tips) > 0 then
            GameGlobalUI:showTips(_("装备强化成功"),self.intensify_tips)
            app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
            self.intensify_desc_label:setString(self:GetEquipmentDesc())
            self.intensify_tips = nil
        else
            GameGlobalUI:showTips(_("提示"),_("装备强化成功"))
        end
    end)
end
-- 调用龙巢详情界面的函数获取道具图标
function GameUIIntensifyEquipment:GetEquipmentItem()
    local item = GameUIDragonEyrieDetail:GetEquipmentItem(self:GetEquipment(),self.dragon:Star(),false)
    item:scale(120/item:getContentSize().width)
    return item
end
function GameUIIntensifyEquipment:WidgetDragonEquipIntensifyEvent(widgetDragonEquipIntensify)
    local equipment = self:GetEquipment()
    --如果装备星级达到最高星级 无条件回滚
    if equipment.star >= self.dragon.star then return true end
    local exp = 0
    table.foreach(self.allEquipemnts,function(index,v)
        exp = exp + v:GetTotalExp()
    end)
    local oldExp = exp - widgetDragonEquipIntensify:GetExpPerEq()
    local oldPercent = (oldExp + (equipment.exp or 0))/equipment:GetNextStarDetailConfig().enhanceExp * 100
    if oldPercent >= 100 then
        return true
    else
        local percent = (exp + (equipment.exp or 0))/equipment:GetNextStarDetailConfig().enhanceExp * 100
        local str = equipment.exp .. "/" .. equipment:GetNextStarDetailConfig().enhanceExp
        if exp > 0 then
            str = str .. " +" .. exp
        end
        self.exp_label:setString(str)
        if percent >= 100 then
            local config =  equipment:GetNextStarDetailConfig()
            local current_config = equipment:GetDetailConfig()
            local tips_global = ""

            local vitality_add = (config.vitality - current_config.vitality) * 4
            local strength_add = config.strength - current_config.strength
            local leadership_add = (config.leadership - current_config.leadership) * 100
            if vitality_add > 0 then
                tips_global = tips_global .. _("生命值") .. "+" .. string.formatnumberthousands(vitality_add)
            end
            if strength_add > 0 then
                tips_global = tips_global .. (tips_global ~= "" and  "," or "") ..  _("攻击力") .. "+" .. string.formatnumberthousands(strength_add)
            end
            if leadership_add > 0 then
                tips_global = tips_global .. (tips_global ~= "" and  "," or "") ..  _("带兵量") .. "+" .. string.formatnumberthousands(leadership_add)
            end
            self.intensify_tips = tips_global
        end
        self.greenProgress:setPercentage(percent)
    end
end
function GameUIIntensifyEquipment:OnUserDataChanged_dragonEquipments()
    self:RefreshIntensifyUI(true)
end
function GameUIIntensifyEquipment:OnBasicChanged()
    self.equipment = self.dragon_manager:GetDragon(self.equipment:Type()):GetEquipmentByBody(self.equipment:Body())
    self:RefreshIntensifyUI(true)
end
return GameUIIntensifyEquipment



