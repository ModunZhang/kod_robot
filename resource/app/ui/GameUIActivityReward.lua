--
-- Author: Danny He
-- Date: 2015-02-11 14:25:56
--
local GameUIActivityReward = UIKit:createUIClass("GameUIActivityReward","UIAutoClose")
local Enum = import("..utils.Enum")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local config_day60 = GameDatas.Activities.day60
local config_online = GameDatas.Activities.online
local config_day14 = GameDatas.Activities.day14
local GameUtils = GameUtils
local config_stringInit = GameDatas.PlayerInitData.stringInit
local config_intInit = GameDatas.PlayerInitData.intInit
local config_levelup = GameDatas.Activities.levelup
local Localize_item = import("..utils.Localize_item")
local Localize = import("..utils.Localize")

local height_config = {
	EVERY_DAY_LOGIN = 762,
	ONLINE = 762,
	CONTINUITY = 762,
	FIRST_IN_PURGURE = 762,
	PLAYER_LEVEL_UP = 762,
}
local ui_titles = {
	EVERY_DAY_LOGIN = _("每日登陆奖励"),
	ONLINE = _("在线奖励"),
	CONTINUITY = _("王城援军"),
	FIRST_IN_PURGURE = _("首次充值奖励"),
	PLAYER_LEVEL_UP = _("新手冲级奖励"),
}

GameUIActivityReward.REWARD_TYPE = Enum("EVERY_DAY_LOGIN","ONLINE","CONTINUITY","FIRST_IN_PURGURE","PLAYER_LEVEL_UP")

function GameUIActivityReward:ctor(reward_type,params)
	GameUIActivityReward.super.ctor(self)
	self.reward_type = reward_type
	if self:GetRewardType() == self.REWARD_TYPE.ONLINE then
		local countInfo = User:GetCountInfo()
		self.diff_time = (countInfo.todayOnLineTime - countInfo.lastLoginTime) / 1000
		app.timer:AddListener(self)
	elseif self:GetRewardType() == self.REWARD_TYPE.PLAYER_LEVEL_UP then
		local countInfo = User:GetCountInfo()
		self.player_level_up_time = countInfo.registerTime/1000 + config_intInit.playerLevelupRewardsHours.value * 60 * 60 -- 单位秒
		self.player_level_up_time_residue = self.player_level_up_time - app.timer:GetServerTime() 
		app.timer:AddListener(self)
	end
end

function GameUIActivityReward:GetRewardType()
	return self.reward_type or self.REWARD_TYPE.EVERY_DAY_LOGIN
end

function GameUIActivityReward:onEnter()
	GameUIActivityReward.super.onEnter(self)
	self:BuildUI()
	User:AddListenOnType(self,User.LISTEN_TYPE.COUNT_INFO)
end

function GameUIActivityReward:OnTimer(current_time)
	if self.time_label then
		local time =  current_time + self.diff_time
		self.time_label:setString(GameUtils:formatTimeStyle1(time))
	end
	if self.level_up_time_label then
		self.player_level_up_time_residue = self.player_level_up_time - current_time
		if self.player_level_up_time_residue > 0 then
			self.level_up_time_label:setString(GameUtils:formatTimeStyle1(self.player_level_up_time_residue))
		else
			self.level_up_time_label:hide()
			self.level_up_time_desc_label:hide()
			self.level_up_state_label:show()
		end
	end
end

function GameUIActivityReward:onExit()
	if self:GetRewardType() == self.REWARD_TYPE.ONLINE or self:GetRewardType() == self.REWARD_TYPE.PLAYER_LEVEL_UP then
		app.timer:RemoveListener(self)
	end
	User:RemoveListenerOnType(self,User.LISTEN_TYPE.COUNT_INFO)
	GameUIActivityReward.super.onExit(self)
end

function GameUIActivityReward:BuildUI()
	local height = height_config[self.REWARD_TYPE[self:GetRewardType()]]
	self.height = height
	local bg = WidgetUIBackGround.new({height=height})
	self:addTouchAbleChild(bg)
	self.bg = bg
	bg:pos(((display.width - bg:getContentSize().width)/2),window.bottom_top)
	local titleBar = display.newSprite("title_blue_600x56.png"):align(display.LEFT_BOTTOM,3,height - 15):addTo(bg)
	local closeButton = cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"}, {scale9 = false})
	   	:addTo(titleBar)
	   	:align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
	   	:onButtonClicked(function ()
	   		self:LeftButtonClicked()
	   	end)
	UIKit:ttfLabel({
		text = ui_titles[self.REWARD_TYPE[self:GetRewardType()]],
		size = 22,
		shadow = true,
		color = 0xffedae
	}):addTo(titleBar):align(display.CENTER,300,24)
	if self['ui_' .. self.REWARD_TYPE[self:GetRewardType()]] then
		self['ui_' .. self.REWARD_TYPE[self:GetRewardType()]](self)
	end
end

function GameUIActivityReward:ui_EVERY_DAY_LOGIN()
	self.rewards_buttons = {}
	local rewards = self:GetDay60Reward()
	local flag = User:GetCountInfo().day60RewardsCount % 30
	UIKit:ttfLabel({
		text = _("领取30日奖励后，刷新奖励列表"),
		size = 20,
		color= 0x403c2f
	}):align(display.CENTER_TOP,304,self.height - 20):addTo(self.bg)
	local content_bg = UIKit:CreateBoxPanelWithBorder({
		width = 556,
		height= 668
	}):align(display.CENTER_BOTTOM, 304, 22):addTo(self.bg)
	local x,y = 3,668 - 10
	for i=1,30 do
		local button = WidgetPushButton.new({normal = 'activity_item_bg_110x108.png'})
			:align(display.LEFT_TOP, x, y)
			:addTo(content_bg)
			:onButtonClicked(function()
				self:On_EVERY_DAY_LOGIN_GetReward(i)
			end)
		table.insert(self.rewards_buttons,button)
		local enable = display.newSprite("activity_item_icon_90x90.png",55,-54):addTo(button)
		local unable = display.newFilteredSprite("activity_item_icon_90x90.png","GRAY", {0.2, 0.3, 0.5, 0.1}):pos(55,-54):addTo(button)
		local check_bg = display.newSprite("activity_check_bg_34x34.png"):align(display.RIGHT_BOTTOM,105,-105):addTo(button,2)
		button.enable = enable
		button.unable = unable
		button.check_bg = check_bg
		display.newSprite("activity_check_body_34x34.png"):addTo(check_bg):pos(17,17)
		if i <= flag then
			enable:hide()
			unable:show()
			check_bg:show()
		else
			check_bg:hide()
			unable:hide()
			enable:show()
		end
		local num_bg = display.newSprite("activity_num_bg_28x28.png",20,-18):addTo(button)
		UIKit:ttfLabel({
			text = i,
			size = 15,
			color= 0xfff9e4
		}):align(display.CENTER, 14, 14):addTo(num_bg)
		x = x + 110 
		if i % 5 == 0 then
			x = 3
			y = y - 108
		end
	end
end

function GameUIActivityReward:ui_ONLINE()
	UIKit:ttfLabel({
		text = _("每日在线时间到达，即可领取珍贵的道具和金龙币"),
		size = 20,
		color= 0x403c2f
	}):align(display.CENTER_TOP,304,self.height - 30):addTo(self.bg)
	UIKit:ttfLabel({
		text = _("今日已在线："),
		size = 20,
		color= 0x403c2f
	}):align(display.TOP_RIGHT, 304,self.height - 60):addTo(self.bg)
	self.time_label = UIKit:ttfLabel({
		text = GameUtils:formatTimeStyle1(self.diff_time + app.timer:GetServerTime()),
		size = 22,
		color= 0x318200
	}):align(display.TOP_LEFT, 304,self.height - 60):addTo(self.bg)
	self.list_view = UIListView.new{
        viewRect = cc.rect(26,20,556,630),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(self.bg)
    self:RefreshOnLineList()
end

function GameUIActivityReward:GetOnLineItem(item_key,time_str,rewards,flag,timePoint)
	local item = self.list_view:newItem()
	local content = UIKit:CreateBoxPanelWithBorder({
		width = 556,
		height= 116
	})
	local item_bg = display.newSprite("activity_item_bg_110x108.png"):align(display.LEFT_CENTER, 5, 58):addTo(content)
	if flag == 1 then
		display.newFilteredSprite("activity_item_icon_90x90.png","GRAY", {0.2, 0.3, 0.5, 0.1}):pos(55,54):addTo(item_bg)
		local check_bg = display.newSprite("activity_check_bg_34x34.png"):align(display.RIGHT_BOTTOM,105,3):addTo(item_bg,2)
		display.newSprite("activity_check_body_34x34.png"):addTo(check_bg):pos(17,17)
	else
		display.newSprite("activity_item_icon_90x90.png",55,54):addTo(item_bg)
	end
	local time_label = UIKit:ttfLabel({
		text = time_str,
		size = 22,
		color= 0x514d3e
	}):align(display.LEFT_TOP, 120, 105):addTo(content)

	local desc_label = UIKit:ttfLabel({
		text = rewards,
		size = 20,
		color= 0x615b44
	}):align(display.LEFT_CENTER, 120, 58):addTo(content)

	if flag == 1 then
		UIKit:ttfLabel({
			text = _("已领取"),
			size = 22,
			color= 0x514d3e
		}):align(display.CENTER, 471, 35):addTo(content)
	else
		WidgetPushButton.new({normal = 'yellow_btn_up_148x58.png',pressed = 'yellow_btn_down_148x58.png',disabled = 'gray_btn_148x58.png'})
			:setButtonLabel("normal", UIKit:commonButtonLable({
				text = _("领取")
			}))
			:addTo(content)
			:pos(471,35)
			:setButtonEnabled(flag == 2)
			:onButtonClicked(function()
				NetManager:getOnlineRewardPromise(timePoint):done(function()
					GameGlobalUI:showTips(_("提示"),rewards)
				end)
			end)
	end
	item:addContent(content)
	item:setMargin({left = 0, right = 0, top = 0, bottom = 5})
	item:setItemSize(556, 116,false)
	return item
end

function GameUIActivityReward:RefreshOnLineList()
	self.list_view:removeAllItems()
	local data = self:GetOnLineTimePointData()
	for __,v in ipairs(data) do
		local reward_type,item_key,time_str,rewards,flag,timePoint = unpack(v)
		local item = self:GetOnLineItem(item_key,time_str,rewards,flag,timePoint)
		self.list_view:addItem(item)
	end
	self.list_view:reload()
end
--flag 1.已领取 2.可以领取 3.还不能领取
function GameUIActivityReward:GetOnLineTimePointData()
	local online_min = DataUtils:getPlayerOnlineTimeMinutes()
	local r = {}
	local max_point = self:GetMaxOnLineTimePointRewards()
	for __,v in ipairs(config_online) do
		local reward_type,item_key,count = unpack(string.split(v.rewards,":"))
		local flag = 2
		if v.timePoint <= max_point then
			flag = 1
		else
			if tonumber(online_min) < tonumber(v.onLineMinutes) then
				flag = 3
			end
		end
		local name = self:GetRewardName(reward_type,item_key)
		table.insert(r,{reward_type,item_key,string.format(_("在线%s分钟"),v.onLineMinutes),name .. "x" .. count,flag,v.timePoint})
	end
	return r
end

function GameUIActivityReward:GetRewardName(reward_type,reward_key)
	print("reward_type,reward_key---->",reward_type,reward_key)
	if reward_type == 'special' then
		return Localize_item.item_name[reward_key]
	elseif reward_type == 'soldiers' then
		return Localize.soldier_name[reward_key]
	elseif reward_type == 'basicInfo' then
		local localize_basicInfo = {
			marchQueue = _("行军队列"),
			buildQueue = _("建筑队列")
		}
		return localize_basicInfo[reward_key]
	end
end

function GameUIActivityReward:GetMaxOnLineTimePointRewards()
	local countInfo = User:GetCountInfo()
	local maxPoint = 0
	for __,v in ipairs(countInfo.todayOnLineTimeRewards) do
		if v > maxPoint then
			maxPoint = v
		end
	end
	return maxPoint 
end

function GameUIActivityReward:OnCountInfoChanged()
	self:RefreshUI()
end

function GameUIActivityReward:GetDay60Reward()
	local countInfo = User:GetCountInfo()
	if countInfo.day60RewardsCount >= 30 then
		return LuaUtils:table_slice(config_day60,30,60)
	else
		return LuaUtils:table_slice(config_day60,1,30)
	end
end

function GameUIActivityReward:On_EVERY_DAY_LOGIN_GetReward(index)
	local countInfo = User:GetCountInfo()
	local real_index = countInfo.day60 % 30 
	if countInfo.day60 > countInfo.day60RewardsCount and real_index == index then 
		NetManager:getDay60RewardPromise()
	end
end

function GameUIActivityReward:ui_CONTINUITY()
	UIKit:ttfLabel({
		text = _("在未来的14天连续登陆，每天都会有来自王城的援军前来投奔你，连续登陆14天免费解锁第二条行军队列！"),
		size = 20,
		color= 0x403c2f,
		dimensions = cc.size(500,0),
		lineHeight = 34
	}):align(display.CENTER_TOP,304,self.height - 30):addTo(self.bg)
	self.list_view = UIListView.new{
        viewRect = cc.rect(26,20,556,630),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(self.bg)
    self:RefreshContinutyList()
end

function GameUIActivityReward:RefreshContinutyList()
	self.list_view:removeAllItems()
	local data = self:GetContinutyListData()
	for __,v in ipairs(data) do
		local reward_type,item_key,time_str,rewards_str,flag = unpack(v)
		local item = self:GetContinutyListItem(reward_type,item_key,time_str,rewards_str,flag)
		self.list_view:addItem(item)
	end
	self.list_view:reload()
end
-- flag 1.已领取 2.可领取 3.明天领取 0 未来的
function GameUIActivityReward:GetContinutyListData()
	local r = {}
	local countInfo = User:GetCountInfo()
	for i,v in ipairs(config_day14) do
		local reward_type,item_key,count = unpack(string.split(v.rewards,":"))
		local flag = 0
		if v.day <= countInfo.day14RewardsCount then
			flag = 1 
		elseif v.day == countInfo.day14RewardsCount + 1 and countInfo.day14RewardsCount == countInfo.day14 then
			flag = 3
		elseif v.day == countInfo.day14 and countInfo.day14 > countInfo.day14RewardsCount then
			flag = 2
		end
		local name = self:GetRewardName(reward_type, item_key)
		table.insert(r,{reward_type,item_key,string.format(_("第%s天"),v.day), name .. "x" .. count,flag})
	end
	return r
end


function GameUIActivityReward:GetContinutyListItem(reward_type,item_key,time_str,rewards_str,flag)
	local item = self.list_view:newItem()
	local content = UIKit:CreateBoxPanelWithBorder({
		width = 556,
		height= 116
	})
	local item_bg = display.newSprite("activity_item_bg_110x108.png"):align(display.LEFT_CENTER, 5, 58):addTo(content)
	if flag == 1 then
		display.newFilteredSprite("activity_item_icon_90x90.png","GRAY", {0.2, 0.3, 0.5, 0.1}):pos(55,54):addTo(item_bg)
	else
		display.newSprite("activity_item_icon_90x90.png",55,54):addTo(item_bg)
	end
	local time_label = UIKit:ttfLabel({
		text = time_str,
		size = 22,
		color= 0x514d3e
	}):align(display.LEFT_TOP, 120, 105):addTo(content)

	local desc_label = UIKit:ttfLabel({
		text = rewards_str,
		size = 20,
		color= 0x615b44
	}):align(display.LEFT_CENTER, 120, 38):addTo(content)

	if flag == 1 or flag == 3 then
		UIKit:ttfLabel({
			text = flag == 1 and _("已领取") or _("明天领取"),
			size = 22,
			color= 0x514d3e
		}):align(display.RIGHT_CENTER,518, 58):addTo(content)
	elseif flag == 2 then
		WidgetPushButton.new({normal = 'yellow_btn_up_148x58.png',pressed = 'yellow_btn_down_148x58.png',disabled = 'gray_btn_148x58.png'})
			:setButtonLabel("normal", UIKit:commonButtonLable({
				text = _("领取")
			}))
			:addTo(content)
			:pos(473,58)
			:onButtonClicked(function()
				NetManager:getDay14RewardPromise():done(function()
					GameGlobalUI:showTips(_("提示"),rewards_str)
				end)
			end)
	end
	item:addContent(content)
	item:setMargin({left = 0, right = 0, top = 0, bottom = 5})
	item:setItemSize(556, 116,false)
	return item
end

function GameUIActivityReward:RefreshUI()
	if self:GetRewardType() == self.REWARD_TYPE.EVERY_DAY_LOGIN then
		local countInfo = User:GetCountInfo()
		local flag = countInfo.day60RewardsCount % 30
		for i,button in ipairs(self.rewards_buttons) do
			if i <= flag then
				button.enable:hide()
				button.unable:show()
				button.check_bg:show()
			else
				button.check_bg:hide()
				button.unable:hide()
				button.enable:show()
			end
		end
	elseif self:GetRewardType() == self.REWARD_TYPE.CONTINUITY then
		self:RefreshContinutyList()
	elseif self:GetRewardType() == self.REWARD_TYPE.PLAYER_LEVEL_UP then
		self:RefreshLevelUpListView()
	elseif self:GetRewardType() == self.REWARD_TYPE.FIRST_IN_PURGURE then
		local countInfo = User:GetCountInfo()
		self.purgure_get_button:setButtonEnabled(countInfo.iapCount > 0 and not countInfo.isFirstIAPRewardsGeted)
	elseif self:GetRewardType() == self.REWARD_TYPE.ONLINE then
		self:RefreshOnLineList()
	end
end
function GameUIActivityReward:ui_FIRST_IN_PURGURE()
	local bar = display.newSprite("activity_first_purgure_598x190.png"):align(display.TOP_CENTER, 304,self.height - 20):addTo(self.bg)
	display.newSprite("Npc.png"):align(display.RIGHT_BOTTOM, 305, -20):addTo(self.bg):scale(552/423)
	local countInfo = User:GetCountInfo()
	local rewards = self:GetFirstPurgureRewards()
	local x,y = 300,self.height - 245
	self.purgure_get_button = WidgetPushButton.new({normal = 'yellow_btn_up_148x58.png',pressed = 'yellow_btn_down_148x58.png',disabled = 'gray_btn_148x58.png'})
			:setButtonLabel("normal", UIKit:commonButtonLable({
				text = _("领取")
			}))
			:addTo(self.bg)
			:pos(435,54)
	local tips_str = ""
	for index,reward in ipairs(rewards) do
		--TODO:
		if index <= 6 then 
			local __,reward_name,count = unpack(reward)
			tips_str = tips_str .. Localize_item.item_name[reward_name] .. " x" .. count
			local item_bg = display.newSprite("activity_item_bg_110x108.png"):align(display.LEFT_TOP, x, y):addTo(self.bg)
			display.newSprite("activity_item_icon_90x90.png",55,54):addTo(item_bg)
			x = x  + 110 + 35 
			if index % 2 == 0 then 
				x = 300
				y = y - 108 - 21 
			end
		end
	end
	self.purgure_get_button:onButtonClicked(function()
		NetManager:getFirstIAPRewardsPromise():done(function()
			GameGlobalUI:showTips(_("提示"),tips_str)
		end)
	end)
	self.purgure_get_button:setButtonEnabled(countInfo.iapCount > 0 and not countInfo.isFirstIAPRewardsGeted)
end

function GameUIActivityReward:GetFirstPurgureRewards()
	local config = config_stringInit.firstIAPRewards.value
	local r = {}
	local rewards = string.split(config, ',')
	for __,v in ipairs(rewards) do
		local reward_type,reward_name,count = unpack(string.split(v, ':'))
		table.insert(r,{reward_type,reward_name,count})
	end
	return r
end

function GameUIActivityReward:ui_PLAYER_LEVEL_UP()
	local box = display.newSprite("alliance_item_flag_box_126X126.png"):align(display.LEFT_TOP, 20,self.height - 30):addTo(self.bg)
	display.newSprite("keep_1.png",63,63):addTo(box):scale(126/420)
	local title_bg = display.newScale9Sprite("alliance_event_type_cyan_222x30.png",0,0, cc.size(390,30), cc.rect(7,7,190,16))
		:align(display.LEFT_TOP, 180, self.height - 30):addTo(self.bg)
	UIKit:ttfLabel({
		text = string.format("当前等级：LV %s",City:GetFirstBuildingByType('keep'):GetLevel()),
		size = 22,
		color= 0xffedae
	}):align(display.LEFT_CENTER, 14, 15):addTo(title_bg)
	local level_up_time_desc_label = UIKit:ttfLabel({
		text = _("倒计时:"),
			size = 20,
			color= 0x403c2f
	}):align(display.LEFT_TOP, 190, title_bg:getPositionY() -  40):addTo(self.bg)
	local level_up_time_label = UIKit:ttfLabel({
		text = GameUtils:formatTimeStyle1(self.player_level_up_time_residue),
		size = 20,
		color= 0x489200
	}):align(display.LEFT_TOP,level_up_time_desc_label:getPositionX()+level_up_time_desc_label:getContentSize().width,level_up_time_desc_label:getPositionY())
		:addTo(self.bg)
	local level_up_state_label = UIKit:ttfLabel({
		text = _("已失效"),
		size = 20,
		color= 0x403c2f
	}):align(display.LEFT_TOP,190,title_bg:getPositionY() -  40):addTo(self.bg)
	self.level_up_time_label = level_up_time_label
	self.level_up_time_desc_label = level_up_time_desc_label
	self.level_up_state_label = level_up_state_label
	if self.player_level_up_time_residue > 0 then
		level_up_state_label:hide()
	else
		level_up_time_desc_label:hide()
		level_up_time_label:hide()
	end
	local activity_desc_label = UIKit:ttfLabel({
		text = _("活动期间，升级城堡获得丰厚奖励"),
		size = 20,
		color= 0x403c2f
	}):align(display.LEFT_TOP, 190, level_up_state_label:getPositionY() - level_up_state_label:getContentSize().height - 20):addTo(self.bg)

	local list_bg = display.newScale9Sprite("box_bg_546x214.png"):size(568,544):align(display.BOTTOM_CENTER, 304, 30):addTo(self.bg)
	self.list_view = UIListView.new{
        viewRect = cc.rect(13,10,542,524),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(list_bg)
    self:RefreshLevelUpListView()
end

function GameUIActivityReward:RefreshLevelUpListView()
	self.list_view:removeAllItems()
	local data = self:GetLevelUpData()
	for index,v in ipairs(data) do
		local title,rewards,flag = unpack(v)
		local item = self:GetRewardLevelUpItem(index,title,rewards,flag)
		self.list_view:addItem(item)
	end
	self.list_view:reload()
end
-- flag 1.已领取 2.可以领取 3.不能领取
function GameUIActivityReward:GetLevelUpData()
	local countInfo = User:GetCountInfo()

	local current_level = City:GetFirstBuildingByType('keep'):GetLevel()
	local r = {}
	for __,v in ipairs(config_levelup) do
		local flag = 0
		if app.timer:GetServerTime() > countInfo.registerTime/1000 + config_intInit.playerLevelupRewardsHours.value * 60 * 60 then
			flag = 3
		else
			if 	v.level <= current_level then
				flag = self:CheckCanGetLevelUpReward(v.index) and 2 or 1
			else
				flag = 3
			end
		end
		local rewards = self:GetLevelUpRewardListFromConfig(v.rewards)
		table.insert(r,{string.format(_("等级%s"),v.level),rewards,flag})
	end
	return r
end

function GameUIActivityReward:GetLevelUpRewardListFromConfig(config_str)
	local r = {}
	local tmp_list = string.split(config_str, ',')
	for __,v in ipairs(tmp_list) do
		local reward_type,reward_name,count = unpack(string.split(v, ':'))
		table.insert(r,{reward_type,reward_name,count})
	end
	return r
end

function GameUIActivityReward:CheckCanGetLevelUpReward(level)
	local max_level = 0
	local countInfo = User:GetCountInfo()
	for __,v in ipairs(countInfo.levelupRewards) do
		if v == level then
			return false
		end
	end
	return true
end

function GameUIActivityReward:GetRewardLevelUpItem(index,title,rewards,flag)
	local item = self.list_view:newItem()
	local content = display.newScale9Sprite(string.format("resource_item_bg%d.png", index % 2)):size(548,104)
	local title_label = UIKit:ttfLabel({
		text = title,
		size = 22,
		color= 0x514d3e
	}):align(display.LEFT_CENTER, 34, 52):addTo(content)
	local x = 104
	local tips_str = ""
	for __,v in ipairs(rewards) do
		--TODO:
		local __,reward_name,count = unpack(v)
		tips_str = Localize_item.item_name[reward_name] .. " x" .. count
		local item_bg = display.newSprite("activity_item_bg_110x108.png"):align(display.LEFT_CENTER, x, 52):addTo(content):scale(94/110)
		display.newSprite("activity_item_icon_90x90.png",55,54):addTo(item_bg)
		x = x + 130
	end
	if flag == 1 then
		UIKit:ttfLabel({
			text = _("已领取"),
			size = 22,
			color= 0x514d3e
		}):align(display.LEFT_CENTER,436, 54):addTo(content)
	else
		WidgetPushButton.new({normal = 'yellow_btn_up_148x58.png',pressed = 'yellow_btn_down_148x58.png',disabled = 'gray_btn_148x58.png'})
			:setButtonLabel("normal", UIKit:commonButtonLable({
				text = _("领取")
			}))
			:addTo(content)
			:pos(450,54)
			:setButtonEnabled(flag == 2)
			:onButtonClicked(function()
				NetManager:getLevelupRewardPromise(index):done(function()
					GameGlobalUI:showTips(_("提示"),tips_str)
				end)
			end)
	end
	item:addContent(content)
	item:setItemSize(548,104)
	return item
end
return GameUIActivityReward