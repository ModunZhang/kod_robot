--
-- Author: Danny He
-- Date: 2014-11-13 15:47:07
--
local GameUIShireFightEvent = UIKit:createUIClass("GameUIShireFightEvent")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local HEIGHT = 846
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local AllianceShrine = import("..entity.AllianceShrine")
local Alliance = import("..entity.Alliance")
local Dragon_head_image = import(".UILib").dragon_head

function GameUIShireFightEvent:ctor(fight_event,allianceShrine)
	GameUIShireFightEvent.super.ctor(self)
	self.fight_event = fight_event
	self.allianceShrine_ = allianceShrine
	self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnFightEventTimerChanged)
	self:GetAllianceShrine():GetAlliance():AddListenOnType(self,Alliance.LISTEN_TYPE.OnAttackMarchEventTimerChanged)
	self:GetAllianceShrine():GetAlliance():AddListenOnType(self,Alliance.LISTEN_TYPE.OnAttackMarchEventDataChanged)
	self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsChanged)
	self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsRefresh)
	self.event_bind_to_label = {}
end

function GameUIShireFightEvent:onEnter()
	GameUIShireFightEvent.super.onEnter(self)
	self:BuildUI()
end

function GameUIShireFightEvent:OnFightEventTimerChanged(event)
	if event:StageName() == self:GetFightEvent():StageName() then
		self.time_label:setString(_("派兵时间") .. " " .. GameUtils:formatTimeStyle1(event:GetTime()))
	end
end

function GameUIShireFightEvent:OnAttackMarchEventDataChanged(change_map)
	if change_map.added or change_map.removed then
		self.popultaion_label:setString(#self:GetFightEvent():PlayerTroops() .. "/" .. self:GetFightEvent():Stage():SuggestPlayer())
		self:RefreshListView()
	end
end

function GameUIShireFightEvent:OnShrineEventsChanged(change_map)
	if change_map.removed then
		local id_ = self:GetFightEvent():Id()
		for _,v in ipairs(change_map.removed) do
			if id_ == v:Id() then 
				self:LeftButtonClicked()
				break
			end
		end
	end
end

function GameUIShireFightEvent:OnShrineEventsRefresh()
	local id_ = self:GetFightEvent():Id()
	local event = self:GetAllianceShrine():GetShrineEventById(id_)
	if not event then
		self:LeftButtonClicked()
	end
end

function GameUIShireFightEvent:OnAttackMarchEventTimerChanged(event)
	if self.event_bind_to_label[event:Id()] then
		self.event_bind_to_label[event:Id()]:setString(GameUtils:formatTimeStyle1(event:GetTime()) .. "后到达")
	end
end

function GameUIShireFightEvent:OnMoveOutStage()
	self:GetAllianceShrine():RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnFightEventTimerChanged)
	self:GetAllianceShrine():RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsChanged)
	self:GetAllianceShrine():RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsRefresh)
	self:GetAllianceShrine():GetAlliance():RemoveListenerOnType(self,Alliance.LISTEN_TYPE.OnAttackMarchEventTimerChanged)
	self:GetAllianceShrine():GetAlliance():RemoveListenerOnType(self,Alliance.LISTEN_TYPE.OnAttackMarchEventDataChanged)
	self.event_bind_to_label = nil
	GameUIShireFightEvent.super.OnMoveOutStage(self)
end

function GameUIShireFightEvent:GetAllianceShrine()
	return self.allianceShrine_
end


function GameUIShireFightEvent:BuildUI()
	local layer = UIKit:shadowLayer():addTo(self)
	local background = WidgetUIBackGround.new({height = HEIGHT})
		:addTo(layer)
		:pos(window.left+22,window.top - 101 - HEIGHT)
	local title_bar = display.newSprite("title_blue_600x56.png"):align(display.LEFT_BOTTOM, 0,HEIGHT - 15):addTo(background)
	UIKit:ttfLabel({
		text = _("事件详情"),
		size = 22,
		color = 0xffedae
	}):align(display.CENTER,300,21):addTo(title_bar)
	local closeButton = UIKit:closeButton():addTo(title_bar)
	   	:align(display.BOTTOM_RIGHT,title_bar:getContentSize().width+10, 0)
	   	:onButtonClicked(function ()
	   		self:LeftButtonClicked()
	   	end)
	local box = UIKit:CreateBoxPanel9({width=574,height=570}):addTo(background):align(display.BOTTOM_CENTER, 304, 100)
	self.info_list = UIListView.new({
		viewRect = cc.rect(3,5,574,562),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(box)

	local info_button = WidgetPushButton.new({
		normal = "yellow_btn_up_149x47.png",
		pressed = "yellow_btn_down_149x47.png"
	})
		:align(display.LEFT_BOTTOM,28,30):addTo(background)
		:setButtonLabel("normal",UIKit:commonButtonLable({
			text = _("信息"),
		}))
		:onButtonClicked(function()
			self:InfomationButtonClicked()
		end)

	local dispath_button = WidgetPushButton.new({
		normal = "yellow_btn_up_149x47.png",
		pressed = "yellow_btn_down_149x47.png"
	},nil,{disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}}):align(display.RIGHT_BOTTOM,box:getPositionX()+box:getContentSize().width/2,30)
		:addTo(background)
		:setButtonLabel("normal",UIKit:commonButtonLable({
			text = _("派兵"),
		}))
		:onButtonClicked(function()
			self:DispathSoliderButtonClicked()
		end)
	self.dispath_button = dispath_button
	local tips_box = UIKit:CreateBoxPanel9({width=574,height=102}):addTo(background):align(display.TOP_CENTER,304, title_bar:getPositionY()- 10)
	UIKit:ttfLabel({
		text = _("参与联盟GVE活动获得的奖励，击杀数量越高奖励越丰富，派出的部队会在战斗结束后返回。根据到达的先后顺序进行战斗排序"),
		dimensions = cc.size(554,82),
		size = 20,
		color = 0x615b44
	}):align(display.CENTER,287,51):addTo(tips_box)
	self:RefreshListView()
	local icon_bg = display.newSprite("back_ground_43x43.png")
		:align(display.LEFT_TOP, 20, tips_box:getPositionY() - tips_box:getContentSize().height - 10)
		:addTo(background):scale(0.7)
	display.newSprite("hourglass_39x46.png"):align(display.CENTER, 22, 22):addTo(icon_bg)
	self.time_label = UIKit:ttfLabel({
		text = _("派兵时间") .. " " .. GameUtils:formatTimeStyle1(self:GetFightEvent():GetTime()),
		size = 22,
		color = 0x403c2f
	}):align(display.LEFT_TOP,icon_bg:getPositionX()+icon_bg:getContentSize().width*0.7+10,icon_bg:getPositionY()):addTo(background)
	local population_icon = display.newSprite("res_citizen_44x50.png"):scale(0.7):align(display.RIGHT_TOP,520,icon_bg:getPositionY()+2):addTo(background)
	self.popultaion_label = UIKit:ttfLabel({
		text = #self:GetFightEvent():PlayerTroops() .. "/" .. self:GetFightEvent():Stage():SuggestPlayer(),
		size = 22,
		color = 0x403c2f
	}):align(display.LEFT_TOP, population_icon:getPositionX()+2,population_icon:getPositionY()-3):addTo(background)
end


function GameUIShireFightEvent:RefreshListView()
	self.info_list:removeAllItems()
	for i,v in ipairs(self:GetFightEvent():PlayerTroops()) do
		local content = self:GetListItem(true,v)
		local item = self.info_list:newItem()
		item:addContent(content)
		item:setMargin({
			left = 0, right = 0, top = 0, bottom = 4
		})
		item:setItemSize(568,186,false)
		self.info_list:addItem(item)
	end

	dump(self:GetAllianceShrine():GetAlliance():GetAttackMarchEvents("shrine"))
	for i,v in ipairs(self:GetAllianceShrine():GetAlliance():GetAttackMarchEvents("shrine")) do
		local content = self:GetListItem(false,v)
		local item = self.info_list:newItem()
		item:addContent(content)
		item:setMargin({
			left = 0, right = 0, top = 0, bottom = 4
		})
		item:setItemSize(568,186,false)
		self.info_list:addItem(item)
	end
	self.info_list:reload()
end
function GameUIShireFightEvent:GetListItem(arrived,obj)
	local bg = display.newSprite("fight_item_bg_568x186.png")
	local icon = display.newSprite("alliance_item_flag_box_126X126.png"):align(display.LEFT_TOP, 12, 175):addTo(bg)
	local title_name = arrived and "alliance_event_type_cyan_222x30.png" or "alliance_event_type_green_222x30.png"
	local title_bar = display.newScale9Sprite(title_name,0,0, cc.size(406,30), cc.rect(7,7,190,16))
		:align(display.LEFT_TOP, icon:getPositionX()+icon:getContentSize().width+10, icon:getPositionY())
		:addTo(bg)
	local playerName = ""
	if arrived then
		playerName = obj.name
	else
		playerName = obj:AttackPlayerData().name
	end
	local dragon_image = ""
	if arrived then
		dragon_image = Dragon_head_image[obj.dragon.type]
	else
		dragon_image = Dragon_head_image[obj:AttackPlayerData().dragon.type]
	end
	display.newSprite(dragon_image):align(display.CENTER,63,63):addTo(icon)
	UIKit:ttfLabel({
		text = playerName,
		color = 0xffedae,
		size = 20,
		shadow = true
	}):align(display.LEFT_CENTER,10,15):addTo(title_bar)
	local icon_bg = display.newSprite("back_ground_43x43.png")
		:align(display.LEFT_BOTTOM, icon:getPositionX()+icon:getContentSize().width + 10, 13)
		:addTo(bg):scale(0.7)
	display.newSprite("hourglass_39x46.png"):align(display.CENTER, 22, 22):addTo(icon_bg)
	local time_label_text = ""
	if not arrived then
		time_label_text = GameUtils:formatTimeStyle1(obj:GetTime()) .. "后到达"
	else
		time_label_text = _("驻防中")
	end
	local time_label = UIKit:ttfLabel({
		text = time_label_text,
		color = 0x403c2f,
		size = 20
	}):align(display.LEFT_BOTTOM,icon:getPositionX()+icon:getContentSize().width+50, 13):addTo(bg)
	if not arrived then
		self.event_bind_to_label[obj:Id()] = time_label
	end
	local line_2 = display.newScale9Sprite("dividing_line_594x2.png"):size(400,2)
		:align(display.LEFT_BOTTOM, icon:getPositionX()+icon:getContentSize().width+10,icon:getPositionY() - icon:getContentSize().height)
		:addTo(bg)

	local power_title_label = UIKit:ttfLabel({
		text = _("坐标"),
		size = 20,
		color = 0x615b44
	}):align(display.LEFT_BOTTOM,line_2:getPositionX(),line_2:getPositionY() + 8):addTo(bg)
	local location_x,location_y = 0,0
	if arrived then
		location_x,location_y = obj.location.x,obj.location.y
	else
		location_x,location_y = obj:FromLocation().x,obj:FromLocation().y
	end
	
	local power_val_label =  UIKit:ttfLabel({
		text = location_x .. "," .. location_y,
		size = 20,
		color = 0x403c2f
	}):align(display.RIGHT_BOTTOM,line_2:getPositionX()+line_2:getContentSize().width,power_title_label:getPositionY()):addTo(bg)

	local line_1 = display.newScale9Sprite("dividing_line_594x2.png"):size(400,2)
		:align(display.LEFT_BOTTOM,line_2:getPositionX(),line_2:getPositionY()+40):addTo(bg)

	local dragon_title_label =  UIKit:ttfLabel({
		text = _("来自"),
		size = 20,
		color = 0x615b44
	}):align(display.LEFT_BOTTOM,line_1:getPositionX(),line_1:getPositionY() + 8):addTo(bg)
	local city_name = arrived and obj.name or obj:AttackPlayerData().name
	local dragon_val_label =  UIKit:ttfLabel({
		text = city_name,
		size = 20,
		color = 0x403c2f
	}):align(display.RIGHT_BOTTOM,line_1:getPositionX()+line_1:getContentSize().width,dragon_title_label:getPositionY()):addTo(bg)

	return bg
end

function GameUIShireFightEvent:GetFightEvent()
	return self.fight_event
end

function GameUIShireFightEvent:GetAllianceShrineLocation()
	local alliance_obj = self:GetAllianceShrine():GetShireObjectFromMap()
	local location = alliance_obj.location
	return location
end

function GameUIShireFightEvent:DispathSoliderButtonClicked()
	if not self:GetAllianceShrine():CheckSelfCanDispathSoldiers() then
		UIKit:showMessageDialog(nil,_("你已经向圣地派遣了部队"))
		return
	end
	UIKit:newGameUI("GameUIAllianceSendTroops",function(dragonType,soldiers)
		NetManager:getMarchToShrinePromose(self:GetFightEvent():Id(),dragonType,soldiers)
	end,{toLocation = self:GetAllianceShrineLocation(),targetIsMyAlliance = true}):AddToCurrentScene(true)
end

function GameUIShireFightEvent:InfomationButtonClicked()
	UIKit:newGameUI("GameUIAllianceShrineDetail",self:GetFightEvent():Stage(),self:GetAllianceShrine()):AddToCurrentScene(true)
end

return GameUIShireFightEvent