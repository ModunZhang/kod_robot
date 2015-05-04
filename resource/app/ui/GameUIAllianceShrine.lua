--
-- Author: Danny He
-- Date: 2014-11-08 15:13:13
local GameUIAllianceShrine = UIKit:createUIClass("GameUIAllianceShrine","GameUIAllianceBuilding")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local StarBar = import(".StarBar")
local UIListView = import(".UIListView")
local AllianceShrine = import("..entity.AllianceShrine")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UILib = import(".UILib")

function GameUIAllianceShrine:ctor(city,default_tab,building)
	GameUIAllianceShrine.super.ctor(self, city, _("联盟圣地"),default_tab,building)
	self.default_tab = default_tab
	self.my_alliance = Alliance_Manager:GetMyAlliance()
	self.allianceShrine = self.my_alliance:GetAllianceShrine()
	self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnPerceotionChanged)
	self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnFightEventTimerChanged)
	self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsChanged)
	self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnNewStageOpened)
	self:GetAllianceShrine():AddListenOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsRefresh)
	assert(self.allianceShrine)
	self.event_bind_to_label = {}
end

function GameUIAllianceShrine:OnPerceotionChanged()
	if self:GetSelectedButtonTag() ~= "stage" then return end
	local resource = self:GetAllianceShrine():GetPerceptionResource()
	local display_str = string.format(_("感知力:%s"),resource:GetResourceValueByCurrentTime(app.timer:GetServerTime()) .. "/" .. resource:GetValueLimit())
	if self.stage_ui and self.stage_ui.insight_label:getString() ~= display_str then
		self.stage_ui.insight_label:setString(display_str)
		self.stage_ui.progressBar:setPercentage(resource:GetResourceValueByCurrentTime(app.timer:GetServerTime())/resource:GetValueLimit()*100)
	end
end

function GameUIAllianceShrine:OnFightEventTimerChanged(event)
	if self:GetSelectedButtonTag() == "fight_event" and self.event_bind_to_label[event:Id()] then
		self.event_bind_to_label[event:Id()]:setString(GameUtils:formatTimeStyle1(event:GetTime()))
	end
end
function GameUIAllianceShrine:OnShrineEventsChanged(change_map)
	if self:GetSelectedButtonTag() == "fight_event" and (change_map.removed or change_map.added) then
		self:RefreshFightListView()
	end
end

function GameUIAllianceShrine:OnShrineEventsRefresh()
	if self:GetSelectedButtonTag() == "fight_event" then
		self:RefreshFightListView()
	end
end

function  GameUIAllianceShrine:OnNewStageOpened( change_map )
	if self:GetSelectedButtonTag() == "stage" then
		self:RefreshStageListView()
	end
end

function GameUIAllianceShrine:OnMoveOutStage()
	self.event_bind_to_label = nil
	self:GetAllianceShrine():RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnPerceotionChanged)
	self:GetAllianceShrine():RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnFightEventTimerChanged)
	self:GetAllianceShrine():RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsChanged)
	self:GetAllianceShrine():RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnNewStageOpened)
	self:GetAllianceShrine():RemoveListenerOnType(self,AllianceShrine.LISTEN_TYPE.OnShrineEventsRefresh)
	GameUIAllianceShrine.super.OnMoveOutStage(self)
end


function GameUIAllianceShrine:OnMoveInStage()
	GameUIAllianceShrine.super.OnMoveInStage(self)
	self.tab_buttons = self:CreateTabButtons(
		{
	        {
	        	label = _("联盟危机"),
	        	tag = "stage",
	        	default = "stage" == self.default_tab,
	    	},
	    	{
	        	label = _("战斗事件"),
	        	tag = "fight_event",
	        	default = "fight_event" == self.default_tab,
	    	},
	    	{
	        	label = _("事件记录"),
	        	tag = "events_history",
	        	default = "events_history" == self.default_tab,
	    	},
	    },
		function(tag)
			--call common tabButtons event
			if self["TabEvent_" .. tag] then
				if self.currentContent then
					self.currentContent:hide()
				end
				self.currentContent = self["TabEvent_" .. tag](self)
				assert(self.currentContent)
				self.currentContent:show()
				self:RefreshUI()
			else
				if self.currentContent then
					self.currentContent:hide()
				end
			end
		end
	):pos(window.cx, window.bottom + 34)
end

function GameUIAllianceShrine:CreateBetweenBgAndTitle()
	GameUIAllianceShrine.super.CreateBetweenBgAndTitle(self)
	self.main_content = display.newNode():addTo(self:GetView()):pos(window.left,window.bottom_top)
end

function GameUIAllianceShrine:GetSelectedButtonTag()
	local tag = ""
	if self.tab_buttons then
		tag = self.tab_buttons:GetSelectedButtonTag()
	elseif self.default_tab then
		tag = self.default_tab
	end
	return tag
end

function GameUIAllianceShrine:RefreshUI()
	local tag = self:GetSelectedButtonTag()
	if tag == 'stage' then
		self:RefreshStageListView()
		local current,total = self:GetAllianceShrine():GetStarInfoByMainStage(self:GetStagePage())
		self.stage_ui.percentLabel:setString(current .. "/" .. total)
	elseif tag == 'fight_event' then
		self:RefreshFightListView()
	elseif tag == 'events_history' then
		self:RefreshEventsListView()
	end
end

function GameUIAllianceShrine:GetAllianceShrine()
	return self.allianceShrine
end

function GameUIAllianceShrine:GetStagePage()
	return self.state_page_ or 1
end

function GameUIAllianceShrine:SetStagePage(num)
	self.state_page_ = num
end

function GameUIAllianceShrine:ChangeStagePage(offset)
	local targetPage = self:GetStagePage() + offset 
	if targetPage  > self:GetAllianceShrine():MaxCountOfStage() then
		return
	elseif  targetPage < 1 then
		return
	end
	self:SetStagePage(targetPage)
	self.stage_ui.stage_label:setString(self:GetAllianceShrine():GetMainStageDescName(self:GetStagePage()))
	self:RefreshUI()
end

function GameUIAllianceShrine:TabEvent_stage()
	if self.stage_node then return self.stage_node end
	self:SetStagePage(1)
	self.stage_ui = {}
	local stage_node = display.newNode()
	local bar_bg = display.newSprite("process_bar_540x40.png")
		:align(display.LEFT_BOTTOM,60,20)
		:addTo(stage_node)
	local progressBar = UIKit:commonProgressTimer("bar_color_540x40.png"):align(display.LEFT_BOTTOM,0,1):addTo(bar_bg)
	local insight_bg = display.newSprite("back_ground_43x43.png")
		:addTo(bar_bg)
		:align(display.RIGHT_CENTER, 30, 20)
	display.newScale9Sprite("insight_icon_40x44.png")
		:addTo(insight_bg)
		:align(display.CENTER,24,18)
	local resource = self:GetAllianceShrine():GetPerceptionResource()
	local display_str = string.format(_("感知力:%s"),resource:GetResourceValueByCurrentTime(app.timer:GetServerTime()) .. "/" .. resource:GetValueLimit())
	local insight_label = UIKit:ttfLabel({
		text = display_str,
		size = 20,
		color = 0xfff3c7
	}):align(display.LEFT_CENTER,40,20):addTo(bar_bg)
	progressBar:setPercentage(resource:GetResourceValueByCurrentTime(app.timer:GetServerTime())/resource:GetValueLimit()*100)
	self.stage_ui.insight_label = insight_label
	self.stage_ui.progressBar = progressBar
	--title

	local title_bg = display.newSprite("shire_stage_title_564x58.png")
		:align(display.LEFT_TOP,40,window.betweenHeaderAndTab)
		:addTo(stage_node)

	local left_button = WidgetPushButton.new(
			{normal = "shrine_page_btn_normal_52x44.png",pressed = "shrine_page_btn_light_52x44.png"},
			{scale9 = false},
			{disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}}
		):addTo(title_bg):align(display.LEFT_CENTER,7,29)
		:onButtonClicked(function()
			self:ChangeStagePage(-1)
		end)
	local icon = display.newSprite("shrine_page_control_26x34.png")
	icon:setFlippedX(true)
	icon:addTo(left_button):pos(26,0)


	local right_button = WidgetPushButton.new(
			{normal = "shrine_page_btn_normal_52x44.png",pressed = "shrine_page_btn_light_52x44.png"},
			{scale9 = false},
			{disabled = {name = "GRAY", params = {0.2, 0.3, 0.5, 0.1}}}
		):addTo(title_bg):align(display.RIGHT_CENTER,557,29)
		:onButtonClicked(function()
			self:ChangeStagePage(1)
		end)
	display.newSprite("shrine_page_control_26x34.png")
		:addTo(right_button)
		:pos(-26,0)

	local stage_label = UIKit:ttfLabel({
		text = self:GetAllianceShrine():GetMainStageDescName(self:GetStagePage()),
		size = 20,
		color = 0x5d563f
		})
		:align(display.LEFT_BOTTOM,70,15)
		:addTo(title_bg)
	self.stage_ui.stage_label = stage_label
	local star_bar = StarBar.new({
       		max = 1,
       		bg = "Stars_bar_bg.png",
       		fill = "Stars_bar_highlight.png", 
       		num = 1,
       		-- scale = 0.8,
    }):addTo(title_bg):align(display.RIGHT_BOTTOM,430,13)
    local current,total = self:GetAllianceShrine():GetStarInfoByMainStage(self:GetStagePage())
    local percentLabel = UIKit:ttfLabel({
    	color = 0x5d563f,
    	size = 20,
    	text = current .. "/" .. total
    }):align(display.LEFT_BOTTOM,431,15):addTo(title_bg)
    self.stage_ui.percentLabel = percentLabel
    local list,list_node = UIKit:commonListView({
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        viewRect = cc.rect(0,0,568,630),
        -- bgColor = UIKit:hex2c4b(0x7a000000),
	})
	self.stage_list = list
	list_node:addTo(stage_node):pos(35,80)
	self.stage_node = stage_node
	self.stage_node:addTo(self.main_content)
	return self.stage_node
end

function GameUIAllianceShrine:GetStageListItem(index,stage_obj)
	local item = self.stage_list:newItem()
	local is_locked = stage_obj:IsLocked()
	local troop = stage_obj:Troops()[2]
	local desc_color = 0xffffff
	local logo_file = "alliance_shire_stage_bg_554x130_black.png" 
	if not is_locked then  
		if troop.type == 'catapult' or troop.type == 'ballista' then
	 		logo_file = "alliance_shire_stage_bg_554x130_yellow.png"
	 		desc_color = 0xf6b304
	 	else
	 		desc_color = 0x00d2ff
	 		logo_file = "alliance_shire_stage_bg_554x130_blue.png"
	 	end
	end
	local bg = WidgetUIBackGround.new({width = 568,height = 216},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
	local logo_bg = display.newSprite(logo_file)
	logo_bg:align(display.TOP_CENTER, 284, 210):addTo(bg)
	local title_label = UIKit:ttfLabel({
		text = stage_obj:GetDescStageName(),
		size = 25,
		color=  is_locked and 0xffffff or 0xffedae,
	}):align(display.LEFT_BOTTOM, 10, 94):addTo(logo_bg)
	if is_locked then
		display.newSprite("alliance_stage_lock_icon.png")
			:align(display.LEFT_BOTTOM, title_label:getPositionX()+title_label:getContentSize().width + 10, 96)
			:addTo(logo_bg)
	end
	UIKit:ttfLabel({
		text = stage_obj:GetStageDesc(),
		size = 18,
		color=  desc_color,
		dimensions = cc.size(530,74) 
	}):align(display.LEFT_TOP, 10, 82):addTo(logo_bg)
	local stage_star = stage_obj:Star()
	local x,y = 14,15
	for star_index = 1,3 do
		local image_file = "alliance_shire_star_60x58_0.png"
		if star_index <= stage_star then
			image_file = "alliance_shire_star_60x58_1.png"
		end
		display.newSprite(image_file):align(display.LEFT_BOTTOM, x, y):addTo(bg)
		x = x + 70
	end

	local troop_image = UILib.soldier_image[troop.type][troop.star]
	if is_locked then
		local sp = display.newFilteredSprite(troop_image, "CUSTOM", json.encode({frag = "shaders/ps_discoloration.fs",shaderName = "ps_discoloration"}))
			:align(display.RIGHT_BOTTOM, 550, 0)
			:addTo(logo_bg)
		sp:setFlippedX(true)
		display.newSprite("alliance_shire_stage_soldier_shadow_128x107.png"):addTo(sp):align(display.LEFT_BOTTOM, 0, 0)
	else
		local power_bg = display.newSprite("shrie_power_bg_146x26.png"):align(display.LEFT_BOTTOM, 260, 30):addTo(bg)
		display.newSprite("dragon_strength_27x31.png")
			:align(display.LEFT_CENTER,-10,13)
			:addTo(power_bg)
		UIKit:ttfLabel({
			text = string.formatnumberthousands(stage_obj:EnemyPower()),
			size = 20,
			color = 0xfff3c7
		}):align(display.LEFT_CENTER,20,13):addTo(power_bg)
		WidgetPushButton.new({
				normal = "blue_btn_up_148x58.png",
				pressed = "blue_btn_down_148x58.png"
			}):align(display.RIGHT_BOTTOM, 560, 15)
			:addTo(bg)
			:setButtonLabel("normal",UIKit:commonButtonLable({
					text = _("调查"),
					size = 20,
					color = 0xfff3c7
			}))
			:onButtonClicked(function(event)
				self:OnResearchButtonClick(stage_obj)
			end)
		local sp = display.newSprite(troop_image):align(display.RIGHT_BOTTOM, 550, 0):addTo(logo_bg)
		display.newSprite("alliance_shire_stage_soldier_shadow_128x107.png"):addTo(sp):align(display.LEFT_BOTTOM, 0, 0)
	end
	item:addContent(bg)
	item:setItemSize(568,216)
	return item
end

function GameUIAllianceShrine:RefreshStageListView()
	self.stage_list:removeAllItems()
	for i,stage_obj in ipairs(self:GetAllianceShrine():GetSubStagesByMainStage(self:GetStagePage())) do
		local item = self:GetStageListItem(i,stage_obj)
		self.stage_list:addItem(item)
	end
	self.stage_list:reload()
end

function GameUIAllianceShrine:OnResearchButtonClick(stage_obj)
	UIKit:newGameUI("GameUIAllianceShrineDetail",stage_obj,self:GetAllianceShrine(),true):AddToCurrentScene(true)
end

--战斗事件
function GameUIAllianceShrine:TabEvent_fight_event()
	if self.fight_event_node then return self.fight_event_node end
	local fight_event_node = display.newNode()

	self.fight_list = UIListView.new({
    	viewRect = cc.rect(22,0,600,window.betweenHeaderAndTab),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    }):addTo(fight_event_node)
	fight_event_node:addTo(self.main_content)
	self.fight_event_node = fight_event_node
	return self.fight_event_node
end

function GameUIAllianceShrine:BuildFightItemBox(event)
	local box = display.newScale9Sprite("box_bg_546x214.png", 0,0, cc.size(400,102), cc.rect(10,13,521,189))
	local player_strengh_bg = display.newScale9Sprite("box_bg_item_520x48_1.png"):size(377,40):addTo(box,2):align(display.LEFT_BOTTOM, 11,12)
	local player_count_bg = display.newScale9Sprite("box_bg_item_520x48_0.png")
			:size(377,40):addTo(box,2)
			:align(display.LEFT_BOTTOM, 11,player_strengh_bg:getPositionY()+40)
	display.newSprite("res_citizen_44x50.png"):scale(0.7):align(display.LEFT_CENTER,5,20):addTo(player_count_bg,2)
	display.newSprite("dragon_strength_27x31.png"):align(display.LEFT_CENTER,5,20):addTo(player_strengh_bg,2)
	UIKit:ttfLabel({
		text = _("建议玩家数量"),
		size = 18,
		color = 0x5d563f
	}):align(display.LEFT_CENTER, 40, 20):addTo(player_count_bg,2)
	UIKit:ttfLabel({
		text = event:Stage():SuggestPlayer(),
		size = 20,
		color = 0x403c2f
	}):align(display.RIGHT_CENTER, 370, 20):addTo(player_count_bg,2)
	UIKit:ttfLabel({
		text = _("建议部队战斗力"),
		size = 18,
		color = 0x5d563f
	}):align(display.LEFT_CENTER, 40, 20):addTo(player_strengh_bg,2)
	UIKit:ttfLabel({
		text = "> " .. event:Stage():SuggestPower(),
		size = 20,
		color = 0x403c2f
	}):align(display.RIGHT_CENTER, 370, 20):addTo(player_strengh_bg,2)
	return box
end

function GameUIAllianceShrine:GetFight_List_Item(event)
	local bg = display.newScale9Sprite("back_ground_608x227.png"):size(600,178)
	local top = display.newSprite("shrie_state_item_line_606_16.png"):align(display.LEFT_TOP,-5,177):addTo(bg)
	local bottom = display.newSprite("shrie_state_item_line_606_16.png")
	bottom:setFlippedY(true)
	bottom:align(display.LEFT_BOTTOM,-5,5):addTo(bg,2)
	local title_bg =  display.newScale9Sprite("alliance_event_type_cyan_222x30.png",0,0, cc.size(568,30), cc.rect(7,7,190,16))
		:align(display.LEFT_TOP,20,top:getPositionY() - top:getContentSize().height)
		:addTo(bg)
	UIKit:ttfLabel({
		text = event:Stage():GetStageDesc(),
		size = 22,
		color = 0xffedae,
	}):align(display.LEFT_BOTTOM, 10, 0):addTo(title_bg)
	UIKit:ttfLabel({
		text = "Begins",
		size = 22,
		color = 0xffedae,
		align = cc.TEXT_ALIGNMENT_RIGHT
	}):align(display.RIGHT_BOTTOM, 540, 0):addTo(title_bg)
	local box = self:BuildFightItemBox(event)
		:addTo(bg)
		:align(display.LEFT_TOP,20,title_bg:getPositionY() - title_bg:getContentSize().height-10)
	local button = WidgetPushButton.new({
			normal = "blue_btn_up_142x39.png",
			pressed = "blue_btn_down_142x39.png"
		})
		:align(display.RIGHT_TOP,580, box:getPositionY() - 10):addTo(bg,2)
		:setButtonLabel("normal",UIKit:commonButtonLable({
			text = _("派兵"),
			size = 20,
			color = 0xfff3c7
		}))
		:onButtonClicked(function()
			self:OnDispatchSoliderButtonClicked(event)
		end)
	local time_label = UIKit:ttfLabel({
		text = GameUtils:formatTimeStyle1(event:GetTime()),
		color = 0x007c23,
		size = 20,
		align = cc.TEXT_ALIGNMENT_CENTER,
	}):align(display.TOP_CENTER,button:getPositionX()- button:getCascadeBoundingBox().width/2, button:getPositionY() - button:getCascadeBoundingBox().height - 10):addTo(bg,2)
	self.event_bind_to_label[event:Id()] = time_label
	return bg
end

function GameUIAllianceShrine:RefreshFightListView()
	self.fight_list:removeAllItems()
	for i,event in ipairs(self:GetAllianceShrine():GetShrineEvents()) do	
		local item = self.fight_list:newItem()
		local content = self:GetFight_List_Item(event)
		item:addContent(content)
		item:setItemSize(600,178)
		self.fight_list:addItem(item)
	end
	self.fight_list:reload()
end

function GameUIAllianceShrine:OnDispatchSoliderButtonClicked(event)
	UIKit:newGameUI("GameUIShireFightEvent",event,self:GetAllianceShrine()):AddToCurrentScene(true)
end

--事件记录
function GameUIAllianceShrine:TabEvent_events_history()
	if self.events_history then return self.events_history end
	local events_history = display.newNode()
	self.events_list = UIListView.new({
    	viewRect = cc.rect(22,0,600,window.betweenHeaderAndTab),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    }):addTo(events_history)
	events_history:addTo(self.main_content)
	self.events_history = events_history
	return self.events_history
end

function GameUIAllianceShrine:RefreshEventsListView()
	self.events_list:removeAllItems()
	dump(self:GetAllianceShrine():GetShrineReports())
	for _,report in ipairs(self:GetAllianceShrine():GetShrineReports()) do
		local item = self.events_list:newItem()
		local content = self:GetReportsItem(report)
		item:addContent(content)
		item:setItemSize(600,178)
		self.events_list:addItem(item)
	end
	self.events_list:reload()
end

function GameUIAllianceShrine:BuildReportItemBox(report)
	local box = display.newScale9Sprite("box_bg_546x214.png", 0,0, cc.size(400,102), cc.rect(10,13,521,189))
	local player_strengh_bg = display.newScale9Sprite("box_bg_item_520x48_1.png"):size(377,40):addTo(box,2):align(display.LEFT_BOTTOM, 11,12)
	local player_count_bg = display.newScale9Sprite("box_bg_item_520x48_0.png")
			:size(377,40):addTo(box,2)
			:align(display.LEFT_BOTTOM, 11,player_strengh_bg:getPositionY()+40)
	display.newSprite("res_citizen_44x50.png"):scale(0.7):align(display.LEFT_CENTER,5,20):addTo(player_count_bg,2)
	display.newSprite("dragon_strength_27x31.png"):align(display.LEFT_CENTER,5,20):addTo(player_strengh_bg,2)
	UIKit:ttfLabel({
		text = _("参与玩家"),
		size = 18,
		color = 0x5d563f
	}):align(display.LEFT_CENTER, 40, 20):addTo(player_count_bg,2)
	UIKit:ttfLabel({
		text = #report:PlayerDatas(),
		size = 20,
		color = 0x403c2f
	}):align(display.RIGHT_CENTER, 370, 20):addTo(player_count_bg,2)
	UIKit:ttfLabel({
		text = _("人均战斗力"),
		size = 18,
		color = 0x5d563f
	}):align(display.LEFT_CENTER, 40, 20):addTo(player_strengh_bg,2)
	UIKit:ttfLabel({
		text = report.playerAvgPower,
		size = 20,
		color = 0x403c2f
	}):align(display.RIGHT_CENTER, 370, 20):addTo(player_strengh_bg,2)
	return box
end

function GameUIAllianceShrine:GetReportsItem(report)
	local bg = display.newScale9Sprite("back_ground_608x227.png"):size(600,178)
	local top = display.newSprite("shrie_state_item_line_606_16.png"):align(display.LEFT_TOP,-5,177):addTo(bg)
	local bottom = display.newSprite("shrie_state_item_line_606_16.png")
	bottom:setFlippedY(true)
	bottom:align(display.LEFT_BOTTOM,-5,5):addTo(bg)
	local title_iamge_name = report:Star() > 0 and "alliance_event_type_green_222x30.png" or "alliance_event_type_red_222x30.png"
	local title_bg = display.newScale9Sprite(title_iamge_name,0,0, cc.size(568,30), cc.rect(7,7,190,16))
		:align(display.LEFT_TOP,20,top:getPositionY() - top:getContentSize().height)
		:addTo(bg)
	UIKit:ttfLabel({
		text = report:Stage():GetStageDesc(),
		size = 22,
		color = 0xffedae,
	}):align(display.LEFT_BOTTOM, 10, 0):addTo(title_bg)
	if report:Star() > 0 then
		local star_bar = StarBar.new({
       		max = 3,
       		bg = "Stars_bar_bg.png",
       		fill = "Stars_bar_highlight.png", 
       		num = report:Star(),
    	}):addTo(title_bg):align(display.RIGHT_BOTTOM,540,0)
	else
		UIKit:ttfLabel({
			text = _("失败"),
			size = 22,
			color = 0xffedae,
		}):align(display.RIGHT_BOTTOM, 540, 0):addTo(title_bg)
	end
	local box = self:BuildReportItemBox(report)
		:addTo(bg)
		:align(display.LEFT_TOP,20,title_bg:getPositionY() - title_bg:getContentSize().height-10)
	local button = WidgetPushButton.new({
			normal = "blue_btn_up_142x39.png",
			pressed = "blue_btn_down_142x39.png"
		})
		:align(display.RIGHT_BOTTOM,580, box:getPositionY() - box:getContentSize().height):addTo(bg)
		:setButtonLabel("normal",UIKit:commonButtonLable({
			text = _("详情"),
			size = 20,
			color = 0xfff3c7
		}))
		:onButtonClicked(function()
			self:OnReportButtonClicked(report)
		end)
	local date_label = UIKit:ttfLabel({
		text = os.date("%Y-%m-%d",report:Time()),
		size = 20,
		color = 0x403c2f,
	}):align(display.CENTER_TOP, button:getPositionX() - 71, box:getPositionY()):addTo(bg)

	local time_label = UIKit:ttfLabel({
		text = os.date("%H:%M:%S",report:Time()),
		size = 20,
		color = 0x403c2f,
	}):align(display.CENTER_TOP, date_label:getPositionX(), date_label:getPositionY() - date_label:getContentSize().height - 4):addTo(bg)
	return bg	
end

function GameUIAllianceShrine:OnReportButtonClicked(shrineReport)
	UIKit:newGameUI("GameUIShrineReport",shrineReport):AddToCurrentScene(true)
end
return GameUIAllianceShrine
