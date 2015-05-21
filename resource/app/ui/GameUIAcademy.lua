--
-- Author: Danny He
-- Date: 2014-12-17 10:01:36
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
local GameUIAcademy = UIKit:createUIClass("GameUIAcademy","GameUIUpgradeBuilding")
local window = import("..utils.window")
local UIScrollView = import(".UIScrollView")
local WidgetPushButton = import("..widget.WidgetPushButton")


function GameUIAcademy:GetTechsData()
	local r = {}
	City:IteratorTechs(function(index,tech)
			table.insert(r, tech)
	end)
	table.sort( r, function(a,b) return tonumber(a:Index()) <  tonumber(b:Index()) end)
	return r
end

function GameUIAcademy:ctor(city,building,default_tab)
	GameUIAcademy.super.ctor(self,city,_("学院"),building,default_tab)
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
		local need = data:UnlockBy() ~= data:Index() and data:UnlockBy() or nil
		local treeNode = TreeNode.new(need,{x = x,y = y},data)
		techNodes[data:Index()] = treeNode
		if i % 3 == 0 then
			y = y - (142+46)
		end
	end
	self.techNodes = techNodes
end

function GameUIAcademy:GetNodeForKey(key)
	return self.techNodes[key]
end

function GameUIAcademy:OnMoveInStage()
	self:CreateTabButtons({
        {
            label = _("科技"),
            tag = "technology",
        },
    },function(tag)
        if tag == 'technology' then
        	if not self.technology_node then
				self.technology_node = self:BuildTechnologyUI():addTo(self:GetView()):pos(window.left,window.bottom_top)
            end
            self.technology_node:show()
        else
        	if self.technology_node then
            	self.technology_node:hide()
            end
        end
    end):pos(window.cx, window.bottom + 34)
    City:AddListenOnType(self,City.LISTEN_TYPE.PRODUCTION_DATA_CHANGED)
    City:AddListenOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
    City:AddListenOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_TIMER)
    City:AddListenOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_REFRESH)
    City:AddListenOnType(self,City.LISTEN_TYPE.UPGRADE_BUILDING)

    GameUIAcademy.super.OnMoveInStage(self)
end


function GameUIAcademy:OnUpgradingBegin()
end

function GameUIAcademy:OnUpgradingFinished(building)
    if building:GetType() == self:GetBuilding():GetType() and self.technology_node then
    	City:FastUpdateAllTechsLockState()
    	City:IteratorTechs(function(__,tech)
    		local item = self:GetItemByTag(tech:Index())
			if item and item.changeState then
				item.changeState(tech:Enable())
			end
		end)
    end
end

function GameUIAcademy:OnUpgrading()
end

function GameUIAcademy:OnProductionTechsDataChanged(changed_map)
	for _,tech in ipairs(changed_map.edited or {}) do
		local item = self:GetItemByTag(tech:Index())
		if item and item.levelLabel then
			item.levelLabel:setString("Lv " .. tech:Level())
		end
		if item and item.changeState then
			item.changeState(tech:Enable())
		end
	end
end

function GameUIAcademy:OnProductionTechnologyEventDataChanged(changed_map)
	self:CheckUIChanged()
end

function GameUIAcademy:OnProductionTechnologyEventDataRefresh()
	self:CheckUIChanged()
end

function GameUIAcademy:OnProductionTechnologyEventTimer(event)
	if self.time_label and self.time_label:isVisible() then
		self.process_timer:setPercentage(event:GetPercent())
		self.time_label:setString(GameUtils:formatTimeStyle1(event:GetTime()))
		if event:GetTime() > DataUtils:getFreeSpeedUpLimitTime() then
			self.speedButton:show()
			self.freeSpeedUpButton:hide()
		else
			self.speedButton:hide()
			self.freeSpeedUpButton:show()
		end
	end
end

function GameUIAcademy:OnMoveOutStage()
	City:RemoveListenerOnType(self,City.LISTEN_TYPE.PRODUCTION_DATA_CHANGED)
	City:RemoveListenerOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
	City:RemoveListenerOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_TIMER)
	City:RemoveListenerOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_REFRESH)
	City:RemoveListenerOnType(self,City.LISTEN_TYPE.UPGRADE_BUILDING)
	GameUIAcademy.super.OnMoveOutStage(self)
end

function GameUIAcademy:CreateBetweenBgAndTitle()
    GameUIAcademy.super.CreateBetweenBgAndTitle(self)
	
end

function GameUIAcademy:BuildTipsUI(technology_node,y)
	local tips_bg = display.newSprite("box_panel_556x106.png")
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
		size = 20,
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
			if City:HaveProductionTechEvent() then
				local event = City:GetProductionTechEventsArray()[1]
				NetManager:getFreeSpeedUpPromise("productionTechEvents",event:Id()):done(function()
					self:CheckUIChanged()
				end)
			end
		end)
	self.freeSpeedUpButton = freeSpeedUpButton
end

function GameUIAcademy:BuildTechnologyUI(height)
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

function GameUIAcademy:CheckUIChanged()
	if City:HaveProductionTechEvent() then
		self.no_event_label_1:hide()
		self.no_event_label_2:hide()
		self.upgrade_label:show()
		self.icon_bg:show()
		self.process_bg:show()
		self.time_label:show()
		local event = City:GetProductionTechEventsArray()[1]
		if event then
			if event:GetTime() > DataUtils:getFreeSpeedUpLimitTime() then
				self.speedButton:show()
				self.freeSpeedUpButton:hide()
			else
				self.speedButton:hide()
				self.freeSpeedUpButton:show()
			end
			self.upgrade_label:setString(string.format(_("正在研发%s到 Level %d"),event:Entity():GetLocalizedName(),event:Entity():GetNextLevel()))
			self.process_timer:setPercentage(event:GetPercent())
			self.time_label:setString(GameUtils:formatTimeStyle1(event:GetTime()))
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

function GameUIAcademy:CreateScrollNode()
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

function GameUIAcademy:GetItem(tech)
	local item = WidgetPushButton.new({normal = "technology_bg_normal_142x142.png"})
	local icon_image = tech:GetImageName()
	item.enable_icon = display.newSprite(icon_image):addTo(item):scale(0.8)
	item.unable_icon = display.newFilteredSprite(icon_image,"GRAY", {0.2,0.5,0.1,0.1}):addTo(item):scale(0.8)
	local lv_bg = display.newSprite("technology_lv_bg_117x40.png"):align(display.BOTTOM_CENTER, 0, -51):addTo(item)
	item.levelLabel = UIKit:ttfLabel({text = "LV " .. tech:Level() ,size = 22,color = 0xfff3c7}):align(display.CENTER_BOTTOM, 58, 0):addTo(lv_bg)
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
	item.changeState(tech:Enable())
	item:onButtonClicked(function(event)
		if not tech:IsOpen() then
			UIKit:showMessageDialog(nil, _("该技能暂未开放！"))
			return
		end
        UIKit:newGameUI("GameUIUpgradeTechnology",tech):AddToCurrentScene(true)
	end)
	item:setTag(tech:Index())
	return item
end

function GameUIAcademy:GetItemByTag(tag)
	local scrollNode = self.scrollView:getScrollNode()
	return scrollNode:getChildByTag(tag)
end

return GameUIAcademy