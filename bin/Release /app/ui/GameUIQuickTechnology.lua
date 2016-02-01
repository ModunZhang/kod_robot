--
-- Author: Danny He
-- Date: 2014-12-18 08:35:48
--
--TreeNode
------------------------------------------------------------------------------------------------
local TreeNode = class("TreeNode")
local property = import("app.utils.property")
local productionTechs = GameDatas.ProductionTechs.productionTechs
function TreeNode:ctor(child_id,pos,data)
    property(self,"child",child_id) -- one child
    property(self,"pos",pos or {x = 0,y = 0})
    property(self,"data",data or {})
end

function TreeNode:hasChild()
    return self:Child()
end
function TreeNode:OnPropertyChange()
end
-- 1 同横向 2 同竖向
function TreeNode:CheckDirection(treeNode)
    if treeNode:Pos().x == self:Pos().x then return 2 end
    if treeNode:Pos().y == self:Pos().y then return 1 end
end

------------------------------------------------------------------------------------------------
local GameUIQuickTechnology = UIKit:createUIClass("GameUIQuickTechnology","GameUIWithCommonHeader")
local window = import("..utils.window")
local UIScrollView = import(".UIScrollView")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local GameUITechnologySpeedUp = import(".GameUITechnologySpeedUp")


function GameUIQuickTechnology:GetTechsData()
    local r = {}
    for tech_name,tech in pairs(User.productionTechs) do
        table.insert(r, {tech_name, tech})
    end
    table.sort( r, function(a,b) 
        return tonumber(a[2].index) <  tonumber(b[2].index) 
    end)
    return r
end

function GameUIQuickTechnology:ctor(city, tech_name)
    GameUIQuickTechnology.super.ctor(self,city,_("科技研发"))
    local tree_data = self:GetTechsData()
    local max_y = (math.ceil(#tree_data/3) - 1) * (142+46) + 71
    local techNodes = {}
    local x,y = 0,max_y
    for i,data in ipairs(tree_data) do
        if i % 3 == 0 then
            x = 2 * (142+46) + 71 + 20
        else
            x = (i % 3 - 1) * (142+46) + 71 + 20
        end
        local tech_name, tech = unpack(data)
        local config = UtilsForTech:GetProductionTechConfig(tech_name)
        local need = config.unlockBy ~= tech.index and config.unlockBy or nil
        local treeNode = TreeNode.new(need,{x = x,y = y},data)
        techNodes[tech.index] = treeNode
        if i % 3 == 0 then
            y = y - (142+46)
        end
    end
    self.techNodes = techNodes
    self.need_tips_tech_name = tech_name
end

function GameUIQuickTechnology:GetNodeForKey(key)
    return self.techNodes[key]
end
function GameUIQuickTechnology:OnMoveInStage()
    GameUIQuickTechnology.super.OnMoveInStage(self)
    self.technology_node = self:BuildTechnologyUI(window.height - 100):addTo(self:GetView()):pos(window.left,window.bottom+15)
    User:AddListenOnType(self, "productionTechs")
    User:AddListenOnType(self, "productionTechEvents")
    User:AddListenOnType(self, "buildingEvents")
    scheduleAt(self, function()
        if self.time_label and self.time_label:isVisible() 
            and User:HasProductionTechEvent() then
            local event = User.productionTechEvents[1]
            local time, percent = UtilsForEvent:GetEventInfo(event)
            self.process_timer:setPercentage(percent)
            self.time_label:setString(GameUtils:formatTimeStyle1(time))
            if time > DataUtils:getFreeSpeedUpLimitTime() then
                self.speedButton:show()
                self.freeSpeedUpButton:hide()
            else
                self.speedButton:hide()
                self.freeSpeedUpButton:show()
            end
        end
    end)
end
function GameUIQuickTechnology:OnUserDataChanged_buildingEvents(userData, deltaData)
    self:CheckUIChanged()
end
function GameUIQuickTechnology:OnUserDataChanged_productionTechEvents(userData, deltaData)
    self:CheckUIChanged()
end
function GameUIQuickTechnology:OnUserDataChanged_productionTechs(userData, deltaData)
    local ok, value = deltaData("productionTechs")
    if ok then
        for tech_name,v in pairs(value) do
            local tech = userData.productionTechs[tech_name]
            local item = self:GetItemByTag(tech.index)
            if item and item.levelLabel then
                item.levelLabel:setString("Lv " .. tech.level)
            end
            if item and item.changeState then
                item.changeState(User:IsTechEnable(tech_name, tech))
            end
        end
    end
end

function GameUIQuickTechnology:OnMoveOutStage()
    GameUIQuickTechnology.super.OnMoveOutStage(self)
    User:RemoveListenerOnType(self, "productionTechs")
    User:RemoveListenerOnType(self, "productionTechEvents")
    User:RemoveListenerOnType(self, "buildingEvents")
end

function GameUIQuickTechnology:CreateBetweenBgAndTitle()
    GameUIQuickTechnology.super.CreateBetweenBgAndTitle(self)
end

function GameUIQuickTechnology:BuildTipsUI(technology_node,y)
    local tips_bg = WidgetUIBackGround.new({width = 556,height = 106},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :addTo(technology_node):align(display.LEFT_TOP,40,y)
    local no_event_label_1 = UIKit:ttfLabel({
        text = _("研发队列空闲"),
        size = 22,
        color= 0x403c2f
    }):align(display.TOP_CENTER,278,90):addTo(tips_bg)
    self.no_event_label_1 = no_event_label_1
    local no_event_label_2 = UIKit:ttfLabel({
        text = _("选择一个技能进行研发"),
        size = 20,
        color= 0x615b44
    }):align(display.BOTTOM_CENTER,278,30):addTo(tips_bg)
    self.no_event_label_2 = no_event_label_2
    local upgrade_label = UIKit:ttfLabel({
        text = "",
        size = 18,
        color= 0x403c2f
    }):align(display.LEFT_TOP,10,96):addTo(tips_bg)
    self.upgrade_label = upgrade_label
    local icon_bg = display.newSprite("back_ground_43x43.png"):align(display.LEFT_BOTTOM, 10, 15):addTo(tips_bg,2)
    display.newSprite("hourglass_30x38.png"):align(display.CENTER, 22, 22):addTo(icon_bg):scale(0.8)
    self.icon_bg = icon_bg
    local process_bg = display.newSprite("progress_bar_364x40_1.png")
        :align(display.LEFT_BOTTOM,icon_bg:getPositionX()+icon_bg:getCascadeBoundingBox().width/2, 15):addTo(tips_bg,1)
    local process_timer = UIKit:commonProgressTimer("progress_bar_364x40_2.png"):align(display.LEFT_CENTER, 0, 20):addTo(process_bg)
    process_timer:setPercentage(100)
    self.process_bg = process_bg
    self.process_timer = process_timer
    local time_label = UIKit:ttfLabel({
        text = "00:00:00",
        size = 22,
        color= 0xfff3c7
    }):align(display.LEFT_CENTER,30,20):addTo(process_bg)
    self.time_label = time_label
    local speedButton = WidgetPushButton.new({normal = "green_btn_up_148x76.png",pressed = "green_btn_down_148x76.png"})
        :align(display.RIGHT_BOTTOM, 546, 10)
        :addTo(tips_bg)
        :setButtonLabel("normal",UIKit:commonButtonLable({text = _("加速")}))
        :onButtonClicked(function()
            UIKit:newGameUI("GameUITechnologySpeedUp"):AddToCurrentScene(true)
        end)

    self.speedButton = speedButton
    local freeSpeedUpButton =  WidgetPushButton.new({normal = "purple_btn_up_148x76.png",pressed = "purple_btn_down_148x76.png"})
        :align(display.RIGHT_BOTTOM, 546, 10)
        :addTo(tips_bg)
        :setButtonLabel("normal",UIKit:commonButtonLable({text = _("免费加速")}))
        :onButtonClicked(function()
            if User:HasProductionTechEvent() then
                local event = User.productionTechEvents[1]
                NetManager:getFreeSpeedUpPromise("productionTechEvents", event.id):done(function()
                    self:CheckUIChanged()
                end)
            end
        end)
    self.freeSpeedUpButton = freeSpeedUpButton
end

function GameUIQuickTechnology:BuildTechnologyUI(height)
    height = height or window.betweenHeaderAndTab
    local technology_node = display.newNode():size(window.width,height)
    self:BuildTipsUI(technology_node,height)
    display.newSprite("technology_magic_549x538.png"):align(display.LEFT_CENTER,40, height/2):addTo(technology_node)
    self.scrollView = UIScrollView.new({
        viewRect = cc.rect(40,0,window.width - 80, height - 116), -- 116 = 106 + 10
    })
        :addScrollNode(self:CreateScrollNode():pos(40, 0))
        :setDirection(UIScrollView.DIRECTION_VERTICAL)
        :addTo(technology_node)
    self.scrollView:fixResetPostion(-30)
    self:CheckUIChanged()
    return technology_node
end

function GameUIQuickTechnology:CheckUIChanged()
    if User:HasProductionTechEvent() then
        self.no_event_label_1:hide()
        self.no_event_label_2:hide()
        self.upgrade_label:show()
        self.icon_bg:show()
        self.process_bg:show()
        self.time_label:show()
        self.speedButton:show()
        local event = User.productionTechEvents[1]
        if event then
            local time, percent = UtilsForEvent:GetEventInfo(event)
            if time > DataUtils:getFreeSpeedUpLimitTime() then
                self.speedButton:show()
                self.freeSpeedUpButton:hide()
            else
                self.speedButton:hide()
                self.freeSpeedUpButton:show()
            end
            local str = UtilsForTech:GetTechLocalize(event.name)
            local next_level = User.productionTechs[event.name].level + 1
            self.upgrade_label:setString(string.format(_("正在研发%s到 Level %d"), str, next_level))
            self.process_timer:setPercentage(percent)
            self.time_label:setString(GameUtils:formatTimeStyle1(time))
        end
    else
        self.no_event_label_1:show()
        self.no_event_label_2:show()
        self.upgrade_label:hide()
        self.icon_bg:hide()
        self.process_bg:hide()
        self.time_label:hide()
        self.speedButton:hide()
        self.freeSpeedUpButton:hide()
    end
end

function GameUIQuickTechnology:CreateScrollNode()
    local node = display.newNode():size(window.width - 80,(math.ceil(LuaUtils:table_size(self.techNodes)/3) - 1) *(142+46) + 142)
    for _,v in pairs(self.techNodes) do
        local item = self:GetItem(v:Data()):align(display.CENTER,v:Pos().x,v:Pos().y):addTo(node)
        if v:hasChild() then
            if v:CheckDirection(self:GetNodeForKey(v:Child())) == 1 then
                local line = display.newSprite("technology_line_normal_72x12.png")
                if self:GetNodeForKey(v:Child()):Pos().x > v:Pos().x then
                    line:align(display.LEFT_CENTER,v:Pos().x+71 - 13,v:Pos().y):addTo(node):zorder(2)
                else
                    line:align(display.RIGHT_CENTER,v:Pos().x-71 + 13,v:Pos().y ):addTo(node):zorder(2)
                end
            else
                local line = display.newSprite("technology_line_normal_72x12.png"):align(display.RIGHT_CENTER, 0,0)
                line:setRotation(90)
                line:addTo(node):pos(v:Pos().x ,v:Pos().y - 13+71):zorder(2)
            end
        end
    end
    return node
end

function GameUIQuickTechnology:GetItem(data)
    local tech_name, tech = unpack(data)
    local item = WidgetPushButton.new({normal = "technology_bg_normal_142x142.png"})
    local icon_image = UtilsForTech:GetProductionTechImage(tech_name)
    item.enable_icon = display.newSprite(icon_image):addTo(item):scale(0.8)
    item.unable_icon = display.newFilteredSprite(icon_image,"GRAY", {0.2,0.5,0.1,0.1}):addTo(item):scale(0.8)
    local lv_bg = display.newSprite("technology_lv_bg_117x40.png"):align(display.BOTTOM_CENTER, 0, -51):addTo(item)
    item.levelLabel = UIKit:ttfLabel({text = "LV " .. tech.level ,size = 22,color = 0xfff3c7}):align(display.CENTER_BOTTOM, 58, 0):addTo(lv_bg)
    item.lock_icon = display.newSprite("technology_lock_40x54.png"):align(display.BOTTOM_CENTER, 0, -55):addTo(item)
    item.changeState = function(enable)
        if enable then
            item.enable_icon:show()
            item.unable_icon:hide()
            item.levelLabel:show()
            item.lock_icon:hide()
        else
            item.enable_icon:hide()
            item.unable_icon:show()
            item.levelLabel:hide()
            item.lock_icon:show()
        end
    end
    item.changeState(User:IsTechEnable(tech_name, tech))
    item:onButtonClicked(function(event)
        event.target:removeChildByTag(111)
        UIKit:newGameUI("GameUIUpgradeTechnology",tech):AddToCurrentScene(true)
    end)
    item:setTag(tech.index)
    if self.need_tips_tech_name == tech_name then
        WidgetFteArrow.new(_("点击科技"), 22 * 1.3):addTo(item, 10, 111)
        :TurnUp():align(display.TOP_CENTER, 0, -80):scale(0.7)
    end
    return item
end

function GameUIQuickTechnology:GetItemByTag(tag)
    local scrollNode = self.scrollView:getScrollNode()
    return scrollNode:getChildByTag(tag)
end


return GameUIQuickTechnology

