--
-- Author: Danny He
-- Date: 2014-09-22 19:44:50
--
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local GameUIDragonEquipment = UIKit:createUIClass("GameUIDragonEquipment","UIAutoClose")
local StarBar = import(".StarBar")
local UIListView = import(".UIListView")
local WidgetDragonEquipIntensify = import("..widget.WidgetDragonEquipIntensify")
local BODY_HEIGHT = 780
local BODY_WIDTH = 608
local LISTVIEW_WIDTH = 548
local cocos_promise = import("..utils.cocos_promise")
local Localize = import("..utils.Localize")
local WidgetPushButton = import("..widget.WidgetPushButton")
local DragonManager = import("..entity.DragonManager")
local GameUIDragonEyrieDetail = import(".GameUIDragonEyrieDetail")
local MaterialManager = import("..entity.MaterialManager")
local WidgetRoundTabButtons = import("..widget.WidgetRoundTabButtons")
local WidgetMakeEquip = import("..widget.WidgetMakeEquip")

function GameUIDragonEquipment:ctor(building,dragon,equipment_obj)
    GameUIDragonEquipment.super.ctor(self)
    self.dragon = dragon
    self.equipment = equipment_obj
    self.building = building
    self.dragon_manager = building:GetDragonManager()
    self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)
    City:GetMaterialManager():AddObserver(self)
end

function GameUIDragonEquipment:OnMoveOutStage()
    City:GetMaterialManager():RemoveObserver(self)
    self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnBasicChanged)
    GameUIDragonEquipment.super.OnMoveOutStage(self)
end

function GameUIDragonEquipment:OnMaterialsChanged()
    if self.tab_buttons:GetSelectedButtonTag() == 'info' then
        self:RefreshInfoUI()
    else
        self:RefreshIntensifyEquipmentListView()
    end
end

function GameUIDragonEquipment:onEnter()
    GameUIDragonEquipment.super.onEnter(self)
    local backgroundImage = WidgetUIBackGround.new({height = BODY_HEIGHT})
    self.ui_node_main = display.newNode():addTo(backgroundImage)
    self:addTouchAbleChild(backgroundImage)
    self.background = backgroundImage:pos((display.width-backgroundImage:getContentSize().width)/2,display.height - backgroundImage:getContentSize().height - 150)
    local titleBar = display.newSprite("title_blue_600x56.png")
        :align(display.BOTTOM_LEFT, 2,backgroundImage:getContentSize().height - 15)
        :addTo(backgroundImage)
    self.mainTitleLabel =  UIKit:ttfLabel({
        text = Localize.body[self.equipment:Body()],
        size = 24,
        color= 0xffedae,
    })
        :addTo(titleBar)
        :align(display.CENTER, 300, 26)
    self.titleBar = titleBar
    UIKit:closeButton()
        :addTo(titleBar)
        :align(display.BOTTOM_RIGHT,titleBar:getContentSize().width, 0)
        :onButtonClicked(function ()
            self:LeftButtonClicked()
        end)

    self.tab_buttons = WidgetRoundTabButtons.new({
        {tag = "intensify",label = _("强化"),default = true},
        {tag = "info",label = _("重置")},
    }, function(tag)
        self:OnTabButtonClicked(tag)
    end,1):align(display.BOTTOM_CENTER,304,10):addTo(backgroundImage)

    self.tab_buttons:SetTabButtonWillSelectListener(function(tag)
        if "intensify" == tag then
            local equipment = self:GetEquipment()
            if not equipment:IsLoaded() then
                UIKit:showMessageDialog(nil, _("龙装备未装备上不能强化"))
            else
                return true
            end
        else
            return true
        end
    end)
end

function GameUIDragonEquipment:OnTabButtonClicked(tag)
    if self['TabButtonEvent_' .. tag] then
        if self.ui_node_current then
            self.ui_node_current:hide()
        end
        self.ui_node_current =  self['TabButtonEvent_' .. tag](self)
        self.ui_node_current:show()
    end
end

function GameUIDragonEquipment:TabButtonEvent_info()
    if not self.ui_node_info then
        local node = display.newNode():addTo(self.ui_node_main)
        local mainEquipment = self:GetEquipmentItem()
            :addTo(node):align(display.LEFT_TOP,15,self.titleBar:getPositionY() - 10)
        self.info_mainEquipment = mainEquipment
        local name_bar = display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(468,30), cc.rect(10,10,410,10))
            :addTo(node):align(display.LEFT_TOP,mainEquipment:getPositionX() + mainEquipment:getContentSize().width + 5,mainEquipment:getPositionY() - 2)
        UIKit:ttfLabel({
            text = Localize.equip[self:GetEquipment():GetCanLoadConfig().name],
            size = 22,
            align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
            color = 0xffedae,
        }):addTo(name_bar):align(display.LEFT_CENTER, 14,15)
        local count_label = UIKit:ttfLabel({
            text = "",
            size = 22,
            color= 0x403c2f
        }):addTo(node):align(display.LEFT_BOTTOM,name_bar:getPositionX() + 16,mainEquipment:getPositionY() - mainEquipment:getContentSize().height + 20)
        local tip_label = UIKit:ttfLabel({
            text = "-1",
            color= 0x8c3708,
            size = 22
        }):addTo(node):align(display.LEFT_BOTTOM,count_label:getPositionX() +count_label:getContentSize().width + 5,count_label:getPositionY())
        self.count_tip_label = tip_label
        self.count_label = count_label
        local load_button = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
            :addTo(node)
            :align(display.RIGHT_BOTTOM,name_bar:getPositionX() + 468,mainEquipment:getPositionY() - mainEquipment:getContentSize().height)
            :setButtonLabel("normal", UIKit:commonButtonLable({
                text = _("装备"),
                size = 24,
            }))
            :onButtonClicked(function()
                local equipment = self:GetEquipment()
                NetManager:getLoadDragonEquipmentPromise(equipment:Type(),equipment:Body(),equipment:GetCanLoadConfig().name):done(function()
                    self:RefreshInfoUI()
                end)
            end)
        self.load_button = load_button
        local reset_button = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
            :addTo(node)
            :align(display.RIGHT_BOTTOM,name_bar:getPositionX() + 468,mainEquipment:getPositionY() - mainEquipment:getContentSize().height)
            :setButtonLabel("normal", UIKit:commonButtonLable({
                text = _("重置"),
                size = 22,
            }))
            :onButtonClicked(function()
                local equipment = self:GetEquipment()
                NetManager:getResetDragonEquipmentPromise(equipment:Type(),equipment:Body()):done(function()
                    self:RefreshInfoUI()
                end)
            end)
        self.reset_button = reset_button

        local list,list_node = UIKit:commonListView_1({
            viewRect = cc.rect(0, 0, LISTVIEW_WIDTH, 160),
            direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        })
        list_node:addTo(node):align(display.TOP_CENTER, BODY_WIDTH/2, load_button:getPositionY() - 26)
        self.info_list = list
        local desc_label = UIKit:ttfLabel({
            text = _("消耗相同一个装备，重新随机装备的加成属性"),
            size = 20,
            color= 0x615b44
        }):addTo(node):align(display.TOP_CENTER, BODY_WIDTH/2, list_node:getPositionY() - list_node:getContentSize().height - 10)
        self.ui_node_info = node
    end
    if self.intensify_eq_list then
        self.intensify_eq_list:removeAllItems()
    end
    self:RefreshInfoUI()
    return self.ui_node_info
end


function GameUIDragonEquipment:TabButtonEvent_intensify()
    if not self.ui_node_intensify then
        local node = display.newNode():addTo(self.ui_node_main)
        local mainEquipment = self:GetEquipmentItem()
            :addTo(node):align(display.LEFT_TOP,15,self.titleBar:getPositionY() - 10)
        self.intensify_mainEquipment = mainEquipment
        local name_bar = display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(468,30), cc.rect(10,10,410,10))
            :addTo(node):align(display.LEFT_TOP,mainEquipment:getPositionX() + mainEquipment:getContentSize().width + 5,mainEquipment:getPositionY() - 2)
        UIKit:ttfLabel({
            text = Localize.equip[self:GetEquipment():GetCanLoadConfig().name],
            size = 22,
            align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
            color = 0xffedae,
        }):addTo(name_bar):align(display.LEFT_CENTER, 14,15)

        local intensify_button = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png",disabled = "grey_btn_148x58.png"})
            :addTo(node)
            :align(display.RIGHT_BOTTOM,name_bar:getPositionX() + 468,mainEquipment:getPositionY() - mainEquipment:getContentSize().height)
            :setButtonLabel("normal", UIKit:commonButtonLable({
                text = _("强化"),
                size = 22,
            }))
            :onButtonClicked(function()
                self:IntensifyButtonClicked()
            end)
        self.intensify_button = intensify_button

        local desc_label = UIKit:ttfLabel({
            text = self:GetEquipmentDesc(),
            size = 22,
            color= 0x403c2f
        }):addTo(node):align(display.LEFT_BOTTOM,name_bar:getPositionX() + 16,mainEquipment:getPositionY() - mainEquipment:getContentSize().height + 20)
        self.intensify_desc_label = desc_label
        local list,list_node = UIKit:commonListView_1({
            viewRect = cc.rect(0, 0, LISTVIEW_WIDTH, 120),
            direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        })
        list_node:addTo(node):align(display.CENTER_TOP, BODY_WIDTH/2, intensify_button:getPositionY() - 10)
        self.intensify_list = list
        local intensify_tip_label = UIKit:ttfLabel({
            text = _("选择多余的装备进行强化"),
            size = 20,
            color= 0x403c2f
        }):align(display.TOP_CENTER, BODY_WIDTH/2, list_node:getPositionY() - list_node:getContentSize().height - 22):addTo(node)
        local progressBg = display.newSprite("progress_bar_540x40_1.png")
            :addTo(node)
            :align(display.CENTER_TOP, BODY_WIDTH/2,intensify_tip_label:getPositionY() - intensify_tip_label:getContentSize().height - 18)

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
        self.intensify_eq_list = UIListView.new {
            viewRect = cc.rect(progressBg:getPositionX() - 270, 90, 540, 272),
            direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
            alignment = cc.ui.UIListView.ALIGNMENT_LEFT,
        }:addTo(node)
        self.ui_node_intensify = node
    end
    self:RefreshIntensifyUI()
    return self.ui_node_intensify
end


--type 为活力 力量 buffer 1 2 3
function GameUIDragonEquipment:GetListItem(index,title,value)
    local bg = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", index % 2 == 0 and 1 or 2)):size(LISTVIEW_WIDTH,40)
    UIKit:ttfLabel({
        text = title,
        size = 20,
        color = 0x615b44,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
    }):addTo(bg):align(display.LEFT_CENTER,14,20)
    UIKit:ttfLabel({
        text = value,
        size = 20,
        align = cc.ui.UILabel.TEXT_ALIGN_RIGHT,
        color = 0x403c2f,
    }):addTo(bg):align(display.RIGHT_CENTER, LISTVIEW_WIDTH - 30, 20)
    return bg
end

function GameUIDragonEquipment:WidgetDragonEquipIntensifyEvent(widgetDragonEquipIntensify)
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
            self:RefreshIntensifyListViewBuffVal(config.vitality - current_config.vitality,config.strength - current_config.strength,config.leadership - current_config.leadership)
        else
            self:RefreshIntensifyListViewBuffVal(0,0,0)
        end
        self.greenProgress:setPercentage(percent)
    end
end

function GameUIDragonEquipment:IntensifyButtonClicked()
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
    NetManager:getEnhanceDragonEquipmentPromise(self.dragon:Type(),equipment:Body(),equipments):done(function()
        if string.len(self.intensify_tips) > 0 then
            GameGlobalUI:showTips(_("装备强化成功"),self.intensify_tips)
            app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
            self.intensify_desc_label:setString(self:GetEquipmentDesc())
        end
    end)
end

function GameUIDragonEquipment:RefreshEquipmentItem(isInfo)
    if isInfo then
        self.info_mainEquipment:removeFromParent()
        local mainEquipment = self:GetEquipmentItem()
        mainEquipment:addTo(self.ui_node_info):align(display.LEFT_TOP,15,self.titleBar:getPositionY() - 10)
        self.info_mainEquipment = mainEquipment
    else
        self.intensify_mainEquipment:removeFromParent()
        local mainEquipment = self:GetEquipmentItem()
        mainEquipment:addTo(self.ui_node_intensify):align(display.LEFT_TOP,15,self.titleBar:getPositionY() - 10)
        self.intensify_mainEquipment = mainEquipment
    end
end

function GameUIDragonEquipment:RefreshIntensifyUI(isAnimationyellowProcess)
    if type(isAnimationyellowProcess) ~= 'boolean' then isAnimationyellowProcess = false end
    self:RefreshEquipmentItem(false)
    local equipment = self:GetEquipment()
    if equipment:Star() < self.dragon:Star() then
        self.exp_label:setString(equipment.exp .. "/" .. equipment:GetNextStarDetailConfig().enhanceExp)
        self.greenProgress:setPercentage((equipment:Exp() or 0)/equipment:GetNextStarDetailConfig().enhanceExp * 100)
        if isAnimationyellowProcess then
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
    self:RefreshIntensifyListView()
end

function GameUIDragonEquipment:RefreshIntensifyEquipmentListView( ... )
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
function GameUIDragonEquipment:GetEquipmentDesc()
    return string.format(_("可强化等级:%d/%d"), self:GetEquipment():Star(), self.dragon:Star())
end
function GameUIDragonEquipment:GetEquipment()
    return self.equipment
end

function GameUIDragonEquipment:GetCurrentEquipmentCount()
    local player_equipments = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.EQUIPMENT)
    local equipment = self:GetEquipment()
    local eq_name = equipment:IsLoaded() and equipment:Name() or equipment:GetCanLoadConfig().name
    return player_equipments[eq_name] or 0
end

-- 调用龙巢详情界面的函数获取道具图标
function GameUIDragonEquipment:GetEquipmentItem()
    return GameUIDragonEyrieDetail:GetEquipmentItem(self:GetEquipment(),self.dragon:Star(),false)
end

function GameUIDragonEquipment:RefreshInfoUI()
    self:RefreshEquipmentItem(true)
    local equipment = self:GetEquipment()
    if not equipment:IsLoaded() then -- 没有装备
        self.load_button:show()
        self.reset_button:hide()
        self.load_button:setButtonEnabled(self:GetCurrentEquipmentCount() > 0)
    else -- 已经装备
        self.load_button:hide()
        self.reset_button:show()
        self.reset_button:setButtonEnabled(self:GetCurrentEquipmentCount() > 0)
    end
    self.count_label:setString(_("当前数量") .. " " .. self:GetCurrentEquipmentCount())
    self.count_tip_label:setPositionX(self.count_label:getPositionX() + self.count_label:getContentSize().width + 5)
    self:RefreshInfoListView()
end

function GameUIDragonEquipment:GetPlayerEquipments()
    local t = {}
    local player_equipments = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.EQUIPMENT)
    local r = LuaUtils:table_filter(player_equipments,function(equipment,count)
        return count > 0
    end)
    for k,v in pairs(r) do
        table.insert(t,{k,v})
    end
    return t
end

function GameUIDragonEquipment:GetPlayerEquipmentsListData(perLineCount,page)
    local data = self:GetPlayerEquipments()
    local pageCount =  math.ceil(#data/perLineCount)
    if not page then return pageCount end
    return LuaUtils:table_slice(data,1+(page - 1)*perLineCount,perLineCount*page)
end

function GameUIDragonEquipment:OnBasicChanged()
    self.equipment = self.dragon_manager:GetDragon(self.equipment:Type()):GetEquipmentByBody(self.equipment:Body())
    if self.tab_buttons:GetSelectedButtonTag() == 'info' then
        self:RefreshInfoUI()
    else
        self:RefreshIntensifyUI(true)
    end
end

function GameUIDragonEquipment:GetEquipmentEffect(needBuff)
    if type(needBuff) ~= 'boolean' then
        needBuff = true
    end

    local r = {}
    local equipment = self:GetEquipment()
    local vitality,strength = equipment:GetVitalityAndStrengh()
    local leadership = equipment:GetLeadership()
    table.insert(r,{_("活力"),vitality})
    table.insert(r,{_("力量"),strength})
    table.insert(r,{_("领导力"),leadership})
    if needBuff then
        local buffers = equipment:GetBufferAndEffect()
        for __,v in ipairs(buffers) do
            table.insert(r,{Localize.dragon_buff_effection[v[1]],string.format("%d%%",v[2]*100)})
        end
    end
    return r
end

function GameUIDragonEquipment:RefreshInfoListView()
    local data = self:GetEquipmentEffect()
    if not data then return end
    self.info_list:removeAllItems()
    table.foreach(data,function(index,dataItem)
        local item = self.info_list:newItem()
        local content = self:GetListItem(index,dataItem[1],dataItem[2])
        item:addContent(content)
        item:setItemSize(LISTVIEW_WIDTH,40)
        self.info_list:addItem(item)
    end)
    self.info_list:reload()
end

function GameUIDragonEquipment:RefreshIntensifyListView()
    self.intensify_list:removeAllItems()
    local equipment = self:GetEquipment()
    local vitality,strength = equipment:GetVitalityAndStrengh()
    local item = self:GetIntensifyListItem(1,_("活力"),vitality)
    self.intensify_list:addItem(item)
    item = self:GetIntensifyListItem(2,_("力量"),strength)
    self.intensify_list:addItem(item)
    local leadership = equipment:GetLeadership()
    item = self:GetIntensifyListItem(3,_("领导力"),leadership)
    self.intensify_list:addItem(item)
    self.intensify_list:reload()
end


function GameUIDragonEquipment:GetIntensifyListItem(index,title,value)
    local item = self.intensify_list:newItem()
    local bg = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", index % 2 == 0 and 1 or 2)):size(LISTVIEW_WIDTH ,40)
    UIKit:ttfLabel({
        text = title,
        size = 20,
        color = 0x615b44,
        align = cc.ui.UILabel.TEXT_ALIGN_LEFT,
    }):addTo(bg):align(display.LEFT_CENTER,14,20)

    local val_label = UIKit:ttfLabel({
        text = value,
        size = 20,
        align = cc.ui.UILabel.TEXT_ALIGN_RIGHT,
        color = 0x403c2f,
    }):addTo(bg):align(display.RIGHT_CENTER, bg:getContentSize().width-10, 20)
    item.val_label = val_label

    local buff_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color = 0x309700,
        align = cc.TEXT_ALIGNMENT_RIGHT
    }):addTo(bg):align(display.RIGHT_CENTER, bg:getContentSize().width-10, 20):hide()
    item.buff_label = buff_label
    item:addContent(bg)
    item:setItemSize(LISTVIEW_WIDTH,40)
    return item
end

function GameUIDragonEquipment:RefreshIntensifyListViewBuffVal(vitality_add,strength_add,leadership_add)
    print("RefreshIntensifyListViewBuffVal--->",vitality_add,strength_add,leadership_add)
    local tips_global = ""
    local items = self.intensify_list:getItems()
    if #items == 0 then return end
    local vitality_item = items[1]
    if not vitality_item or not vitality_item.buff_label then return end
    if vitality_add == 0 then
        vitality_item.buff_label:hide()
        vitality_item.val_label:setPositionX(LISTVIEW_WIDTH - 10)
    else
        vitality_item.buff_label:setString("+" .. vitality_add)
        vitality_item.val_label:setPositionX(vitality_item.buff_label:getPositionX() - vitality_item.buff_label:getContentSize().width - 10)
        vitality_item.buff_label:show()
        tips_global = tips_global .. _("活力") .. "+" .. vitality_add
    end

    local strength_item = items[2]

    if not strength_item or not strength_item.buff_label then return end
    if strength_add == 0 then
        strength_item.buff_label:hide()
        strength_item.val_label:setPositionX(LISTVIEW_WIDTH - 10)
    else
        strength_item.buff_label:setString("+" .. strength_add)
        strength_item.val_label:setPositionX(strength_item.buff_label:getPositionX() - strength_item.buff_label:getContentSize().width - 10)
        strength_item.buff_label:show()
        tips_global = tips_global .. "," ..  _("力量") .. "+" .. strength_add
    end

    local leadership_item = items[3]
    if not leadership_item or not leadership_item.buff_label then return end
    if leadership_add == 0 then
        leadership_item.buff_label:hide()
        leadership_item.val_label:setPositionX(LISTVIEW_WIDTH - 10)
    else
        leadership_item.buff_label:setString("+" .. leadership_add)
        leadership_item.val_label:setPositionX(leadership_item.buff_label:getPositionX() - leadership_item.buff_label:getContentSize().width - 10)
        leadership_item.buff_label:show()
        tips_global = tips_global .. "," ..  _("领导力") .. "+" .. leadership_add
    end
    self.intensify_tips = tips_global
end

function GameUIDragonEquipment:Find()
    return cocos_promise.defer(function()
        return self.adornOrResetButton
    end)
end

return GameUIDragonEquipment

