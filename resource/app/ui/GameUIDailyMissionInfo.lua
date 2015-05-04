--
-- Author: Danny He
-- Date: 2015-03-06 17:27:51
--

local GameUIDailyMissionInfo = UIKit:createUIClass("GameUIDailyMissionInfo","UIAutoClose")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UIKit = UIKit
local UIListView = import(".UIListView")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")

function GameUIDailyMissionInfo:ctor(key_of_daily)
	GameUIDailyMissionInfo.super.ctor(self)
	self.key_of_daily = key_of_daily
end

function GameUIDailyMissionInfo:onEnter()
	GameUIDailyMissionInfo.super.onEnter(self)
    User:AddListenOnType(self,User.LISTEN_TYPE.DAILY_TASKS)
	self:BuildUI()
end


function GameUIDailyMissionInfo:BuildUI()
	local bg = WidgetUIBackGround.new({height=630})
    self:addTouchAbleChild(bg)
	bg:pos(((display.width - bg:getContentSize().width)/2),window.bottom_top + 100)
	local titleBar = display.newSprite("title_blue_600x52.png"):align(display.LEFT_BOTTOM,3,615):addTo(bg)
	local closeButton = UIKit:closeButton()
	   	:addTo(titleBar)
	   	:align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
	   	:onButtonClicked(function ()
	   		self:LeftButtonClicked()
	   	end)
	UIKit:ttfLabel({
		text = Localize.daily_tasks[self:GetKeyOfDaily()].title,
		size = 22,
		shadow = true,
		color = 0xffedae
	}):addTo(titleBar):align(display.CENTER,300,24)
	local list_bg = display.newScale9Sprite("box_bg_546x214.png"):size(568,404):addTo(bg):align(display.BOTTOM_CENTER, 304, 25)
	self.info_list = UIListView.new({
        viewRect = cc.rect(11,10, 546, 384),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(list_bg)

	UIKit:ttfLabel({
		text = _("完成下列任务,领取奖励"),
		color= 0x403c2f,
		size = 20,
	}):align(display.LEFT_BOTTOM, 22, 474):addTo(bg)
	local progress_bg,progress = self:GetProgressBar()
	progress_bg:align(display.LEFT_BOTTOM, 22, 516):addTo(bg)
	self.progress = progress
	UIKit:ttfLabel({
		text = _("当前进度"),
		color= 0x403c2f,
		size = 20,
	}):align(display.LEFT_BOTTOM,22,562):addTo(bg)

    local yin_box = ccs.Armature:create("yin_box")
        :align(display.RIGHT_BOTTOM, 562,456)
        :addTo(bg)
        :scale(174/400)
    self.button_finish_animation = yin_box
    local button = WidgetPushTransparentButton.new(cc.rect(0,0,174,141))
        :align(display.RIGHT_BOTTOM, 562,456)
        :addTo(bg)
		:onButtonClicked(function()
			self:GetRewardFromServer()
		end)
	local finish_icon = display.newSprite("minssion_finish_icon_51x51.png")
		:align(display.CENTER, -50, 70)
		:addTo(yin_box)
	finish_icon:setVisible(true) 
	self.button_finish_icon = finish_icon
	self:RefreshListUI()
end

function GameUIDailyMissionInfo:RefreshListUI()
    local percentage = #User:GetDailyTasksInfo(self:GetKeyOfDaily()) / 5 
    self.progress:setPercentage(percentage * 100)
    self.button_finish_icon:setVisible(User:CheckDailyTasksWasRewarded(self:GetKeyOfDaily()))
	self:RefreshListView()
end


function GameUIDailyMissionInfo:GetProgressBar()
	local bg = display.newSprite("mission_progress_bar_bg_348x40.png")
	local progress = UIKit:commonProgressTimer("mission_progress_bar_content_348x40.png"):align(display.LEFT_CENTER, 0, 20):addTo(bg)
	local box = display.newSprite("mission_progress_bar_box_348x40.png"):align(display.LEFT_CENTER, 0, 20):addTo(bg)
	return bg,progress
end

function GameUIDailyMissionInfo:GetRewardFromServer()
    if not User:CheckDailyTasksWasRewarded(self:GetKeyOfDaily()) then
        NetManager:getDailyTaskRewards(self:GetKeyOfDaily()):done(function()
            self.button_finish_animation:getAnimation():play("Animation1", -1, 0)
        end)
    end
end

function GameUIDailyMissionInfo:RefreshListView()
	self.info_list:removeAllItems()
	local data = self:GetMissionConfig()[self:GetKeyOfDaily()]
	local daily_info = User:GetDailyTasksInfo(self:GetKeyOfDaily())
    for __,v in ipairs(daily_info) do
        data[v].finished = true
    end
	for index,v in ipairs(data) do
		local item = self:GetItem(index,v,v.finished)
		self.info_list:addItem(item)
	end
	self.info_list:reload()
end

function GameUIDailyMissionInfo:GetItem(index,item_data,isFinish)
	local item = self.info_list:newItem()
	local content = display.newScale9Sprite(string.format("resource_item_bg%d.png",index % 2)):size(546,78)
	UIKit:ttfLabel({
		text = item_data.title,
		size = 20,
		color= 0x403c2f
	}):align(display.LEFT_CENTER, 16, 39):addTo(content)

	if isFinish then
       display.newSprite("minssion_finish_icon_51x51.png"):align(display.CENTER, 462, 39):addTo(content)
	else
		WidgetPushButton.new({
			normal = "yellow_btn_up_148x58.png",
			pressed= "yellow_btn_down_148x58.png"
		})
			:align(display.RIGHT_CENTER, 536, 39)
			:addTo(content)
			:onButtonClicked(function()
				if item_data.func then
					item_data.func()
				end
			end)
			:setButtonLabel("normal", UIKit:commonButtonLable({
				text = item_data.isDesc and _("说明") or _("前往"),
			}))
	end
	item:addContent(content)
	item:setItemSize(546,78)
	return item
end

function GameUIDailyMissionInfo:GetMissionConfig()
	local config = {
		empireRise = {
        	{
        		index = 1,
        		title = _("升级一次建筑"),
                isDesc = false,
        		func = function()
        			UIKit:newGameUI("GameUIHasBeenBuild", City):AddToCurrentScene(true)
        		end
        	},
        	{
        		index = 2,
        		title = _("招募一次兵种"),
                isDesc = false,
        		func = function()
        			local building = City:GetFirstBuildingByType("barracks") 
        			if  not building:IsUnlocked() then
        				GameGlobalUI:showTips(_("错误"),_("你还未建造兵营"))
        				return
        			end
        			UIKit:newGameUI("GameUIBarracks", City,building):AddToCurrentScene(true)
        		end
        	},
        	{
        		index = 3,
        		title = _("升级一次科技"),
                isDesc = false,
        		func = function()
        			local building = City:GetFirstBuildingByType("academy") 
        			if not building:IsUnlocked() then
        				GameGlobalUI:showTips(_("错误"),_("你还未建造学院"))
        				return
        			end
        			UIKit:newGameUI("GameUIAcademy", City,building):AddToCurrentScene(true)
        		end
        	},
        	{
        		index = 4,
        		title = _("成功通关塞琳娜的考验"),
                isDesc = false,
        		func = function()
        			UIKit:newGameUI("GameUISelenaQuestion"):AddToCurrentScene(true)
        		end
        	},
        	{
        		index = 5,
        		title = _("制造一批建筑材料"),
                isDesc = false,
        		func = function()
        			
        			local building = City:GetFirstBuildingByType("toolShop") 
        			if not building:IsUnlocked() then
        				GameGlobalUI:showTips(_("错误"),_("你还未建造工具作坊"))
        				return
        			end
        			UIKit:newGameUI("GameUIToolShop", City,building):AddToCurrentScene(true)
        		end
        	}
    	},
	    conqueror = {
	      	{
        		index = 1,
        		title = _("参加一次联盟会战"),
                isDesc = true,
        		func = function()
        			GameGlobalUI:showTips(_("说明"),_("参加一次联盟会战"))
        		end
        	},
        	{
        		index = 2,
        		title = _("对敌方玩家城市进行一次突袭"),
                isDesc = true,
        		func = function()
        		  
        		end
        	},
        	{
        		index = 3,
        		title = _("对地方玩家城市进行一次进攻"),
                isDesc = true,
        		func = function()
        			
        		end
        	},
        	{
        		index = 4,
        		title = _("占领一座村落"),
                isDesc = true,
        		func = function()
        			
        		end
        	},
        	{
        		index = 5,
        		title = _("搭乘飞艇进行一次探索"),
                isDesc = false,
        		func = function()
        			local dragon_type = City:GetDragonEyrie():GetDragonManager():GetCanFightPowerfulDragonType()
		            if #dragon_type > 0 then
		                local _,_,index = City:GetUser():GetPVEDatabase():GetCharPosition()
		                app:EnterPVEScene(index)
		            else
		                GameGlobalUI:showTips(_("错误"),_("必须有一条空闲的龙，才能进入pve"))
		            end
        		end
        	}
	    },
	    brotherClub = {
	        {
        		index = 1,
        		title = _("进行一次联盟捐赠"),
                isDesc = true,
        		func = function()
        			if Alliance_Manager:GetMyAlliance():IsDefault() then
        				GameGlobalUI:showTips(_("错误"),_("你还未加入联盟"))
        				return 
        			end
        		end
        	},
        	{
        		index = 2,
        		title = _("在联盟商店购买一次道具"),
                isDesc = true,
        		func = function()
        			
        		end
        	},
        	{
        		index = 3,
        		title = _("协助一次盟友建造加速"),
                isDesc = true,
        		func = function()
        			
        		end
        	},
        	{
        		index = 4,
        		title = "?",
                isDesc = true,
        		func = function()
        			
        		end
        	},
        	{
        		index = 5,
        		title = _("对盟友进行一次协防"),
                isDesc = true,
        		func = function()
        			
        		end
        	}
	    },
	    growUp = {
	        {
        		index = 1,
        		title = _("加速一次正在升级的建筑"),
                isDesc = true,
        		func = function()

        		end
        	},
        	{
        		index = 2,
        		title = _("加速一支正在招募的兵种"),
                isDesc = true,
        		func = function()
        			
        		end
        	},
        	{
        		index = 3,
        		title = _("打造一件龙的装备"),
                isDesc = false,
        		func = function()
        			
        		end
        	},
        	{
        		index = 4,
        		title = _("进行一次高级抽奖"),
                isDesc = false,
        		func = function()
        			
        		end
        	},
        	{
        		index = 5,
        		title = _("在商店购买任意一个道具"),
                isDesc = false,
        		func = function()
        			UIKit:newGameUI("GameUIShop",City):AddToCurrentScene(true)
        		end
        	}
	    }
	}
	return config
end


function GameUIDailyMissionInfo:OnDailyTasksChanged()
    self:RefreshListUI()
end

function GameUIDailyMissionInfo:onExit()
    User:RemoveListenerOnType(self,User.LISTEN_TYPE.DAILY_TASKS)
	GameUIDailyMissionInfo.super.onExit(self)
end

function GameUIDailyMissionInfo:GetKeyOfDaily()
	return self.key_of_daily
end

return GameUIDailyMissionInfo 
-- 608x630