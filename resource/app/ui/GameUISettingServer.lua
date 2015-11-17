--
-- Author: Danny He
-- Date: 2015-02-24 15:14:22
--
local GameUISettingServer = UIKit:createUIClass("GameUISettingServer","UIAutoClose")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local User = User
local config_fightRewards = GameDatas.AllianceInitData.fightRewards
local Localize = import("..utils.Localize")
local UILib = import(".UILib")

function GameUISettingServer:onEnter()
	GameUISettingServer.super.onEnter(self)
	self.current_code = User.serverId
	self.server_code = self.current_code
	self.HIGH_COLOR = UIKit:hex2c3b(0x970000)
	self.LOW_COLOR = UIKit:hex2c3b(0x1d8a00)
	self:BuildUI()
end

function GameUISettingServer:BuildUI()
	local bg = WidgetUIBackGround.new({height=762})
	self:addTouchAbleChild(bg)
	self.bg = bg
	bg:pos(((display.width - bg:getContentSize().width)/2),window.bottom_top)
	local titleBar = display.newSprite("title_blue_600x56.png"):align(display.LEFT_BOTTOM,3,747):addTo(bg)
	local closeButton = cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"}, {scale9 = false})
	   	:addTo(titleBar)
	   	:align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
	   	:onButtonClicked(function ()
	   		self:LeftButtonClicked()
	   	end)
	UIKit:ttfLabel({
		text = _("选择服务器"),
		size = 22,
		shadow = true,
		color = 0xffedae
	}):addTo(titleBar):align(display.CENTER,300,28)
	self.select_button = WidgetPushButton.new({normal = 'yellow_btn_up_186x66.png',pressed = 'yellow_btn_down_186x66.png',disabled = "grey_btn_186x66.png"})
		:align(display.BOTTOM_RIGHT, 588, 28)
		:addTo(bg)
		:setButtonLabel("normal", UIKit:commonButtonLable({
			text = _("切换服务器"),
		}))
		:onButtonClicked(function()
			if not Alliance_Manager:GetMyAlliance():IsDefault() then
				UIKit:showMessageDialog(_("错误"),_("你已加入联盟不能切换服务器，退出联盟后重试。"))
				return 
			end
			if self.server_code ~= User.serverId then
				NetManager:getSwitchServer(self.server_code)
			end
		end)
	self.list_view = UIListView.new{
        viewRect = cc.rect(20,98,568,532),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        async = true,
    }:addTo(bg):onTouch(handler(self, self.listviewListener))
    self.list_view:setDelegate(handler(self, self.sourceDelegate))
 	local tips_bg = UIKit:CreateBoxPanelWithBorder({width = 556,height = 96}):addTo(bg):align(display.TOP_CENTER, 304, 740)
 	UIKit:ttfLabel({
 		text = _("你只能在未加入联盟的情况下，迁移服务器，执行此操作不会清空你当前的进度。"),
 		size = 20,
 		color= 0x615b44,
 		align = cc.TEXT_ALIGNMENT_CENTER,
 		dimensions = cc.size(518, 82)
 	}):align(display.CENTER, 278, 48):addTo(tips_bg)
 	self:FetchServers()
 	
end

function GameUISettingServer:BuildServersUI()
	local tips_label = UIKit:ttfLabel({
 		text = _("每次进行联盟匹配奖励"),
 		size = 18,
 		color= 0x403c2f
 	}):align(display.LEFT_BOTTOM, 30, 76):addTo(self.bg)
 	local honour_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(130,30),cc.rect(15,10,136,64)):addTo(self.bg):align(display.LEFT_CENTER, 42, 56)
 	local honour_icon = display.newSprite("honour_128x128.png"):align(display.LEFT_CENTER, -12, 15):scale(0.48):addTo(honour_bg):scale(0.35)

 	local gems_bg = display.newScale9Sprite("back_ground_166x84.png",0 , 0,cc.size(130,30),cc.rect(15,10,136,64)):addTo(self.bg):align(display.LEFT_CENTER, honour_bg:getPositionX()+130+26, 56)
 	local gems_icon = display.newSprite("gem_icon_62x61.png"):align(display.LEFT_CENTER, -12, 15):addTo(gems_bg):scale(0.7)

 	local honour_label = UIKit:ttfLabel({
 		text = "",
 		size = 22,
 		color= 0x288400,
 		align = cc.TEXT_ALIGNMENT_RIGHT,
 	}):align(display.RIGHT_CENTER, 120, 15):addTo(honour_bg)

 	local gem_label = UIKit:ttfLabel({
 		text = "",
 		size = 22,
 		color= 0x288400,
 		align = cc.TEXT_ALIGNMENT_CENTER,
 	}):align(display.LEFT_CENTER, 30, 15):addTo(gems_bg)
 	self.honour_label = honour_label
 	self.gem_label = gem_label
end

function GameUISettingServer:FetchServers()
	NetManager:getServersPromise():done(function(response)
		if response.msg.code == 200 then
			local servers = response.msg.servers
			self.data = servers
			self:RefreshList()
			self:BuildServersUI()
			self:RefreshServerInfo()
		end
	end)
end

function GameUISettingServer:sourceDelegate(listView, tag, idx)
	if cc.ui.UIListView.COUNT_TAG == tag then
        return #self.data
    elseif cc.ui.UIListView.CELL_TAG == tag then
        local item
        local content
        local data = self.data[idx]
        item = listView:dequeueItem()
        if not item then
            item = listView:newItem()
            content = self:GetItemContent()
            item:addContent(content)
        else
            content = item:getContent()
        end
        self:FillDataItem(content,data)
        item:setItemSize(560,130)
        return item
    end
end

function GameUISettingServer:RefreshList()
	self:SortServerData()
	self.list_view:reload()
end

function GameUISettingServer:SortServerData()
	table.sort( self.data, function(a,b)
		if self:IsServerLevelGreateThanOther(a,b) then 
			return true
		else
		 	return a.id < b.id
		end
	end )
end

function GameUISettingServer:IsServerLevelGreateThanOther(server1,server2)
	return config_fightRewards[server1.level].gem > config_fightRewards[server2.level].gem
end

function GameUISettingServer:GetServerLocalizeName(server)
	local __,__,indexName = string.find(server.id or "","-(%d+)")
	return string.format("%s %d",Localize.server_name[server.level],indexName)
end


function GameUISettingServer:GetStateLableInfoByUserCount(count)
	if count >= 500 then
		return "HIGH",self.HIGH_COLOR
	else
		return "LOW",self.LOW_COLOR
	end
end

function GameUISettingServer:GetItemContent()
	local content = display.newSprite("server_item_568x130.png")
	for k,v in pairs(UILib.server_level_image) do
		local sp = display.newSprite(v):addTo(content):align(display.CENTER, 64,65)
		content[k] = sp
	end
	local title_label = UIKit:ttfLabel({
		text = "",
		size = 22,
		color= 0x403c2f
	}):align(display.LEFT_BOTTOM,142, 74):addTo(content)
	local desc_label = UIKit:ttfLabel({
		text = _("人口"),
		size = 20,
		color= 0x403c2f
	}):align(display.LEFT_BOTTOM, 142, 48):addTo(content)
	local state_label = UIKit:ttfLabel({
		text = "HIGH",
		size = 20,
		color= 0x970000
	}):align(display.LEFT_BOTTOM, desc_label:getContentSize().width + desc_label:getPositionX() + 10, 48):addTo(content)
	local here_label = UIKit:ttfLabel({
		text = _("你在这儿"),
		size = 20,
		color= 0x076886
	}):align(display.LEFT_BOTTOM, 142, 20):addTo(content)
	local unselected = display.newSprite("checkbox_unselected.png"):addTo(content):align(display.RIGHT_CENTER,544, 65)
	local selected = display.newSprite("checkbox_selectd.png"):addTo(content):align(display.RIGHT_CENTER,544, 65)
	content.title_label = title_label
	content.state_label = state_label
	content.unselected = unselected
	content.selected = selected
	content.here_label = here_label
	return content
end

function GameUISettingServer:FillDataItem(content,data)
	content.title_label:setString(self:GetServerLocalizeName(data))
	for k,__ in pairs(UILib.server_level_image) do
		if data.level == k then
			content[k]:show()
		else
			content[k]:hide()
		end
	end

	local str,color = self:GetStateLableInfoByUserCount(data.userCount or 0)
	content.state_label:setString(str)
	content.state_label:setColor(color)
	if data.id == self.server_code then
		content.selected:show()
		content.unselected:hide()
	else
		content.selected:hide()
		content.unselected:show()
	end
	if data.id == self.current_code then
		content.here_label:show()
	else
		content.here_label:hide()
	end
end

function GameUISettingServer:listviewListener(event)
    local listView = event.listView
    if "clicked" == event.name then
    	local server = self.data[event.itemPos]
    	if not server then return end
    	self.server_code = server.id
    	self:RefreshCurrentPageList()
		self:RefreshServerInfo()
    end
end

function GameUISettingServer:RefreshCurrentPageList()
	local items = self.list_view:getItems()
	for __,v in ipairs(items) do
		local idx = v.idx_ 
		local server = self.data[idx]
		local content = v:getContent()
		self:FillDataItem(content,server)
	end
end

function GameUISettingServer:RefreshServerInfo()
	self.select_button:setButtonEnabled(self.server_code ~= self.current_code)
	local current_server_level = ""
	local honour,gem = 0,0
	for __,v in ipairs(self.data) do
		if v.id == self.server_code then
			current_server_level = v.level
			break
		end
	end
	local config = config_fightRewards[current_server_level]
	if config then
		honour,gem = config.honour,config.gem
	end
	self.honour_label:setString(string.format("+%s",string.formatnumberthousands(honour)))
	self.gem_label:setString(string.format("+%s",string.formatnumberthousands(gem)))
end

return GameUISettingServer
