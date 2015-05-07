
local Localize = import("..utils.Localize")
local UILib = import(".UILib")
local GameUIWall = UIKit:createUIClass('GameUIWall',"GameUIUpgradeBuilding")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local WidgetSelectDragon = import("..widget.WidgetSelectDragon")
local timer = app.timer
local WidgetUseItems = import("..widget.WidgetUseItems")
local WidgetSelectWallDragon = import("..widget.WidgetSelectWallDragon")

function GameUIWall:ctor(city,building,default_tab)
	self.city = city
    GameUIWall.super.ctor(self,city,Localize.building_name[building:GetType()],building,default_tab)
    self.dragon_manager = city:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    self.dragon_manager:AddListenOnType(self,self.dragon_manager.LISTEN_TYPE.OnHPChanged)
end

function GameUIWall:OnMoveInStage()
	GameUIWall.super.OnMoveInStage(self)
	self:CreateMilitaryUIIf():addTo(self:GetView()):hide():pos(window.left,window.bottom)
	self:CreateTabButtons({
        {
            label = _("驻防"),
            tag = "military",
        }
    },
    function(tag)
        if tag == 'military' then
        	self.military_node:show()
        else
        	self.military_node:hide()
        end
    end):pos(window.cx, window.bottom + 34)
end

function GameUIWall:OnMoveOutStage()
	self.dragon_manager:RemoveListenerOnType(self,self.dragon_manager.LISTEN_TYPE.OnHPChanged)
	GameUIWall.super.OnMoveOutStage(self)
end

function GameUIWall:CreateMilitaryUIIf()
	if self.military_node then return self.military_node end
	local dragon = self:GetDragon()
	local military_node = display.newNode():size(window.width,window.height)
	local top_bg = WidgetUIBackGround.new({height = 382,isFrame = "yes"})
		:addTo(military_node)
		:pos((window.width - 608)/2,window.height - 382 - 91)
	local title_bar = display.newSprite("title_bar_586x34.png"):align(display.LEFT_TOP,10,362):addTo(top_bg)
	UIKit:ttfLabel({
		text = _("驻防部队"),
		size = 22,
		color = 0xffedae
	}):align(display.CENTER, 293, 17):addTo(title_bar)
	local select_button = WidgetPushButton.new({
			normal = "yellow_btn_up_148x58.png",
			pressed = "yellow_btn_down_148x58.png",
			disabled = "gray_btn_148x58.png"
		})
		:addTo(top_bg)
		:align(display.CENTER_BOTTOM, 304,20)
		:setButtonLabel("normal", UIKit:ttfLabel({text = _("选择")}))
		:onButtonClicked(function()
			self:OnSelectDragonButtonClicked()
	end)
	local list_bg = display.newScale9Sprite("box_bg_546x214.png")
			:addTo(top_bg)
			:align(display.LEFT_BOTTOM,22,80)
			:size(568, 100)
	self.info_list = UIListView.new({
			bgColor = UIKit:hex2c4b(0x7a000000),
	        viewRect = cc.rect(11,10, 546, 80),
	        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(list_bg)
	
	local tips_panel = self:GetTipsBoxWithTipsContent({
			_("・不驻防巨龙，所有城市中的部队将不会进行防御。"),
			_("・驻防巨龙能在敌方进攻时，自动带兵参战。"),
			_("・驻防巨龙能防御敌方进行的突袭，获得城市的信息")
		}):addTo(top_bg):align(display.LEFT_BOTTOM,28,80)
	if dragon then
		tips_panel:hide()
	else
		list_bg:hide()
	end
	self.tips_panel = tips_panel
	self.dragon_info_panel = list_bg
	local draogn_box = display.newSprite("alliance_item_flag_box_126X126.png")
		:addTo(top_bg)
		:align(display.LEFT_BOTTOM, list_bg:getPositionX(), list_bg:getPositionY()+list_bg:getContentSize().height + 12)
	local dragon_bg = display.newSprite("dragon_bg_114x114.png", 63, 63):addTo(draogn_box)
	self.dragon_head = display.newSprite(UILib.dragon_head['redDragon']):addTo(dragon_bg):pos(57,60)
	if not dragon then
		self.dragon_head:hide()
	else
		self.dragon_head:setTexture(UILib.dragon_head[dragon:Type()])
	end
	local progressTimer_bg = display.newSprite("process_bar_410x40.png")
		:align(display.LEFT_BOTTOM, draogn_box:getPositionX()+draogn_box:getContentSize().width + 30, draogn_box:getPositionY()+10)
		:addTo(top_bg)
	local progressTimer = UIKit:commonProgressTimer("bar_color_410x40.png"):addTo(progressTimer_bg):align(display.LEFT_BOTTOM,0,0)
	self.dragon_hp_progress = progressTimer
	self.progressTimer_bg = progressTimer_bg
	local iconbg = display.newSprite("drgon_process_icon_bg.png")
     		:addTo(progressTimer_bg)
     		:align(display.LEFT_BOTTOM, -15,0)
    display.newSprite("dragon_lv_icon.png")
     		:addTo(iconbg)
     		:pos(iconbg:getContentSize().width/2,iconbg:getContentSize().height/2)
    self.hp_label = UIKit:ttfLabel({
    	text = "",
    	size = 22,
    	color= 0xfff3c7,
    	shadow = true,
   	}):align(display.LEFT_CENTER, iconbg:getPositionX()+iconbg:getContentSize().width+10,20):addTo(progressTimer_bg)
 	self.dragon_hp_recovery_label = UIKit:ttfLabel({
 		 text = self:GetDragonHPRecoveryStr(),
 		 color = 0xfff3c7,
 		 shadow = true,
 		 size = 22,
 	}):addTo(progressTimer_bg):align(display.RIGHT_CENTER, progressTimer_bg:getContentSize().width - 70, 20)
    if dragon then
    	progressTimer:setPercentage(dragon:Hp()/dragon:GetMaxHP()*100)
    	self.hp_label:setString(dragon:Hp() .. "/" .. dragon:GetMaxHP())
    else
    	progressTimer:setPercentage(0)
    	self.hp_label:hide()
    	self.progressTimer_bg:hide()
    end

   	local button = WidgetPushButton.new({normal = 'add_btn_up_50x50.png',pressed = 'add_btn_down_50x50.png'})
   		:addTo(progressTimer_bg):align(display.RIGHT_CENTER, 410, 20)
   		:onButtonClicked(handler(self, self.OnDragonHpItemUseButtonClicked))

   	local tips_label = UIKit:ttfLabel({
		text = self:GetDefenceDragonBuffDesc(),
		color= 0x514d3e,
		size = 20 
	}):align(display.LEFT_BOTTOM,draogn_box:getPositionX()+draogn_box:getContentSize().width + 30,  draogn_box:getPositionY()+10):addTo(top_bg)
   	self.tips_label = tips_label
   	local name_str = _("请选择一个巨龙驻防")
   	local level_str = string.format(_("当前城市地形:%s"),Localize.terrain[User:Terrain()])
   	if dragon then
   		name_str = dragon:GetLocalizedName()
   		level_str=  _("等级")
   	end
	local name_label = UIKit:ttfLabel({
		text = name_str,
		size = 22,
		color= 0x514d3e
		})
		:addTo(top_bg)
		:align(display.LEFT_TOP,tips_label:getPositionX(), draogn_box:getPositionY() + draogn_box:getContentSize().height)
	self.name_label = name_label
	local level_title_label = UIKit:ttfLabel({
		text = level_str,
		size = 20,
		color= 0x615b44
	}):align(display.LEFT_BOTTOM,name_label:getPositionX(), tips_label:getPositionY() + tips_label:getContentSize().height + 20):addTo(top_bg)
	self.level_title_label = level_title_label
	self.dragon_level_label = UIKit:ttfLabel({
		text = "",
		color= 0x514d3e,
		size = 20 
	}):addTo(top_bg):align(display.LEFT_BOTTOM,level_title_label:getPositionX()+50, level_title_label:getPositionY())
	if dragon then
		self.dragon_level_label:setString(dragon:Level())
		self.tips_label:hide()
	else
		self.dragon_level_label:hide()
		self.tips_label:show()
	end
	--bottom

	local wall_label = UIKit:ttfLabel({
		text = _("城墙耐久度"),
		size = 24,
		color= 0x403c2f
	}):align(display.CENTER_TOP,military_node:getContentSize().width/2,top_bg:getPositionY()-10):addTo(military_node)
	local wallHpResource = self.city:GetResourceManager():GetWallHpResource()
	local string = string.format("%d/%d",wallHpResource:GetResourceValueByCurrentTime(timer:GetServerTime()),wallHpResource:GetValueLimit())

	local process_wall_bg = display.newSprite("process_bar_540x40.png")
		:align(display.CENTER_TOP,military_node:getContentSize().width/2, wall_label:getPositionY() - wall_label:getContentSize().height - 10) 
		:addTo(military_node)
	local progressTimer_wall = UIKit:commonProgressTimer("bar_color_540x40.png"):addTo(process_wall_bg):align(display.LEFT_BOTTOM,0,0)
	progressTimer_wall:setPercentage(wallHpResource:GetResourceValueByCurrentTime(timer:GetServerTime())/wallHpResource:GetValueLimit()*100)
	self.progressTimer_wall = progressTimer_wall
	self.wall_hp_process_label = UIKit:ttfLabel({
		text = string,
		size = 22,
		color= 0xfff3c7,
		shadow= true
	}):align(display.LEFT_CENTER,50,20):addTo(process_wall_bg)

	self.wall_hp_recovery_label = UIKit:ttfLabel({
		text = "+" .. wallHpResource:GetProductionPerHour() .. "/h",
		size = 22,
		color= 0xfff3c7
	}):align(display.RIGHT_CENTER, 530, 20):addTo(process_wall_bg)
	local iconbg = display.newSprite("drgon_process_icon_bg.png")
     		:addTo(process_wall_bg)
     		:align(display.LEFT_BOTTOM, -15,0)
    display.newSprite("icon_wall_83x103.png"):scale(40/103)
     		:addTo(iconbg)
     		:pos(iconbg:getContentSize().width/2,iconbg:getContentSize().height/2)
	local tips_bg = self:GetTipsBoxWithTipsContent({_("・防御敌方进攻时，可能会损失城墙的生命值。"),_("・当生命值为0时，地方联盟将击溃你的城市，获得额外的联盟积分。")})
	tips_bg:align(display.CENTER_TOP,military_node:getContentSize().width/2,process_wall_bg:getPositionY()-process_wall_bg:getContentSize().height - 10):addTo(military_node)

	self.military_node = military_node
	if dragon then 
		self:RefreshListView()
	end
	return self.military_node
end

function GameUIWall:GetDefenceDragonBuffDesc()
	return string.format(_("选择%s会获得战斗力加成"),Localize.dragon[User:GetBestDragon()])
end

function GameUIWall:GetDragonHPRecoveryStr()
	local dragonEyrie = City:GetDragonEyrie()
	return "+" .. dragonEyrie:GetHPRecoveryPerHour() .. "/h"
end

function GameUIWall:OnDragonHpItemUseButtonClicked()
	local widgetUseItems = WidgetUseItems.new():Create({
		item_type = WidgetUseItems.USE_TYPE.DRAGON_HP,
		dragon = self:GetDragon()
	})
	widgetUseItems:AddToCurrentScene()
end

function GameUIWall:GetTipsBoxWithTipsContent(content)
	local tips_bg = display.newSprite("box_panel_556x106.png")
	local y = 100
	for _,v in ipairs(content) do
		local tips_label = UIKit:ttfLabel({text = v,size = 18,color = 0x403c2f})
			:align(display.LEFT_TOP, 10, y)
			:addTo(tips_bg)
		y = y - 10 - tips_label:getContentSize().height
	end
	return tips_bg
end

function GameUIWall:RefreshListView()
	self.info_list:removeAllItems()
	for i,v in ipairs(self:GetListData()) do	
		local item = self:GetListItem(i,v)
		self.info_list:addItem(item)
	end
	self.info_list:reload()
end

function GameUIWall:GetListData()
	local troops_count = self:GetDragon():LeadCitizen()
	local totalstrength = self:GetDragon():TotalStrength()
	local data = {
		{title = _("龙的力量"),val = totalstrength},
		{title = _("最大兵量"),val = troops_count},
	}
	return data
end

function GameUIWall:GetListItem(index,data)
	local item = self.info_list:newItem()
	local imageName = string.format("box_bg_item_520x48_%d.png",index%2)
	local content = display.newScale9Sprite(imageName):size(546,42)
	UIKit:ttfLabel({
		text = data.title,
		size = 20,
		color= 0x615b44
	}):align(display.LEFT_CENTER, 20, 21):addTo(content)
	local val_x = 540
	if data.buffer then --buffer
		local buff_label = UIKit:ttfLabel({
			text = "+ " .. data.buffer,
			size = 20,
			color= 0x007c23
		}):align(display.RIGHT_CENTER, val_x, 21):addTo(content)
		val_x = val_x - buff_label:getContentSize().width - 10
	end
	UIKit:ttfLabel({
		text = data.val,
		size = 20,
		color= 0x403c2f
	}):align(display.RIGHT_CENTER, val_x, 21):addTo(content)
	item:addContent(content)
	item:setItemSize(546,42)
	return item
end

function GameUIWall:GetDragon()
	return self.dragon_manager:GetDefenceDragon()
end

function GameUIWall:OnResourceChanged(resource_manager)
	GameUIWall.super.OnResourceChanged(self,resource_manager)
	local wallHpResource = resource_manager:GetWallHpResource()
	--更新城墙hp
	if self.military_node:isVisible() then
		local string = string.format("%d/%d",wallHpResource:GetResourceValueByCurrentTime(timer:GetServerTime()),wallHpResource:GetValueLimit())
		self.wall_hp_process_label:setString(string)
		self.wall_hp_recovery_label:setString("+" .. wallHpResource:GetProductionPerHour() .. "/H")
		self.progressTimer_wall:setPercentage(wallHpResource:GetResourceValueByCurrentTime(timer:GetServerTime())/wallHpResource:GetValueLimit()*100)
	end
end

function GameUIWall:OnSelectDragonButtonClicked()
	WidgetSelectWallDragon.new({
		callback  = {
			function(dragon)
				self:OnDragonSelected(dragon)
			end,
			function()
				self:OnDragonSelected()
			end
		},
		default_dragon_type = self.dragon_manager:GetDefenceDragon() and self.dragon_manager:GetDefenceDragon():Type()
	}):addTo(self:GetView())
end

function GameUIWall:OnDragonSelected(dragon)
	if dragon then
		if self:GetDragon() and self:GetDragon():Type() == dragon:Type() then return end
		NetManager:getSetDefenceDragonPromise(dragon:Type()):done(function()
			self:RefreshUIAfterSelectDragon(dragon)
		end)
	else
		if self:GetDragon() then
			NetManager:getCancelDefenceDragonPromise():done(function()
				self:RefreshUIAfterSelectDragon()
			end)
		else
			UIKit:showMessageDialog(_("错误"),_("还没有龙驻防"), function()end)
		end
	end
end

function GameUIWall:RefreshUIAfterSelectDragon(dragon)
	if dragon then
		self.name_label:setString(dragon:GetLocalizedName())
		self.dragon_info_panel:show()
		self.tips_panel:hide()
		self.level_title_label:setString(_("等级"))
		self.dragon_level_label:setString(dragon:Level())
		self.dragon_level_label:show()
		self.tips_label:hide()
		self.progressTimer_bg:show()
		self.hp_label:setString(dragon:Hp() .. "/" .. dragon:GetMaxHP())
		self.hp_label:show()
		self.dragon_hp_progress:setPercentage(dragon:Hp()/dragon:GetMaxHP()*100)
		self.dragon_head:setTexture(UILib.dragon_head[dragon:Type()])
		self.dragon_head:show()
		self:RefreshListView()
	else
		self.name_label:setString(_("请选择一个巨龙驻防"))
		self.dragon_info_panel:hide()
		self.tips_panel:show()
		self.tips_label:show()
		self.dragon_level_label:hide()
		self.level_title_label:setString(string.format(_("当前城市地形:%s"),Localize.terrain[User:Terrain()]))
		self.progressTimer_bg:hide()
		self.hp_label:hide()
		self.dragon_hp_progress:setPercentage(0)
		self.dragon_head:hide()
	end
end

function GameUIWall:OnHPChanged()
	local dragon = self:GetDragon()
	if not dragon or not dragon:Ishated() then return end
	if self.hp_label and self.hp_label:isVisible() then
		self.hp_label:setString(dragon:Hp() .. "/" .. dragon:GetMaxHP())
		self.dragon_hp_progress:setPercentage(dragon:Hp()/dragon:GetMaxHP()*100)
	end
end
return GameUIWall