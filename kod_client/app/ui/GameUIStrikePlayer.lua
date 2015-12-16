--
-- Author: Danny He
-- Date: 2014-11-27 11:19:01
--
local GameUIStrikePlayer = UIKit:createUIClass("GameUIStrikePlayer","GameUIWithCommonHeader")
local window = import("..utils.window")
local UIListView = import(".UIListView")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UILib = import(".UILib")
local Enum = import("..utils.Enum")
local DragonSprite = import("..sprites.DragonSprite")
local Alliance_Manager = Alliance_Manager
GameUIStrikePlayer.STRIKE_TYPE = Enum("CITY","VILLAGE")



function GameUIStrikePlayer:ctor(strike_type,params)
	GameUIStrikePlayer.super.ctor(self,City,_("准备突袭"))
	self.dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
	self.params = params
	self.strike_type = strike_type or self.STRIKE_TYPE.CITY
	self:RefreshDefaultDragon()
end

function GameUIStrikePlayer:GetDragonManager()
	return self.dragon_manager
end

function GameUIStrikePlayer:RefreshDefaultDragon()
	local dragons = self:GetDragonManager():GetDragons()
	local power_dragon_type = self:GetDragonManager():GetCanFightPowerfulDragonType()
	if power_dragon_type == "" then
		power_dragon_type = self:GetDragonManager():GetPowerfulDragonType()
	end
	self.select_dragon_type = power_dragon_type
end


function GameUIStrikePlayer:GetDragon()
	return self:GetDragonManager():GetDragon(self.select_dragon_type)
end

function GameUIStrikePlayer:ReloadDragon()
	local dragon = self:GetDragon()
	local x = 257
	if dragon:Type() == 'redDragon' then
		x = 307
	end
	self.dragon_sprite:setPositionX(x)
	self.dragon_sprite:ReloadSpriteCauseTerrainChanged(dragon:Type())
end

function GameUIStrikePlayer:OnMoveInStage()
	GameUIStrikePlayer.super.OnMoveInStage(self)
	self:BuildUI()
end

function GameUIStrikePlayer:CreateBetweenBgAndTitle()
	self.content_node = display.newNode():addTo(self:GetView())
end

function GameUIStrikePlayer:GetMarchTime()
	local from_alliance = Alliance_Manager:GetMyAlliance()
	local mapObject = from_alliance:FindMapObjectById(from_alliance:GetSelf():MapId())
    local fromLocation = mapObject.location
	
	local toLocation = self.params.toLocation or cc.p(0,0)
	local time = DataUtils:getPlayerDragonMarchTime(from_alliance,fromLocation,self.params.alliance,toLocation)
	return GameUtils:formatTimeStyle1(time)
end

function GameUIStrikePlayer:BuildUI()
	local clipNode = display.newClippingRegionNode(cc.rect(0,0,614,390))
    clipNode:addTo(self.content_node):pos(window.cx - 307,window.top - 390)
    display.newSprite("dragon_animate_bg_624x606.png"):align(display.LEFT_BOTTOM,-5,0):addTo(clipNode)
    display.newSprite("eyrie_584x547.png"):align(display.CENTER_BOTTOM,307, -230):addTo(clipNode)
    local info_layer = UIKit:shadowLayer():size(619,40):addTo(self.content_node):pos(window.cx - 307,window.top - 390)
    display.newSprite("line_624x58.png"):align(display.LEFT_TOP,0,20):addTo(info_layer)
	UIKit:ttfLabel({
		text = _("派出巨龙突袭可以侦查到敌方的城市信息"),
		size = 20,
		color = 0xffedae,
	}):align(display.CENTER, 310, 20):addTo(info_layer)
    local x,y = 257,200
    if self:GetDragon():Type() == 'redDragon' then
            x = 307
            y = 200
    end
    self.dragon_sprite = DragonSprite.new(display.getRunningScene():GetSceneLayer(),self:GetDragon():Type()):addTo(clipNode):align(display.CENTER, x,y):scale(0.7)
	self.list_view = UIListView.new ({
        viewRect = cc.rect(window.left+40,window.bottom + 85,window.width-80,475),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        alignment = UIListView.ALIGNMENT_LEFT,
    }):addTo(self.content_node)
	local button = WidgetPushButton.new({
		normal = "yellow_btn_up_186x66.png",
		pressed = "yellow_btn_down_186x66.png"
		})
		:align(display.CENTER_BOTTOM,window.cx,window.bottom + 20)
		:addTo(self.content_node)
		:setButtonLabel("normal",UIKit:commonButtonLable({
			text = _("突袭"),
			size = 18,
		}))
		:setButtonLabelOffset(0, 12)
		:onButtonClicked(function()
			local select_DragonType = self:GetSelectDragonType()
			local dragon = self:GetDragonManager():GetDragon(select_DragonType)

			local alliance = Alliance_Manager:GetMyAlliance()
			if alliance:IsReachEventLimit() then
				if User.basicInfo.marchQueue < 2 then
					UIKit:showMessageDialogWithParams({
	        			content = _("没有空闲的行军队列"),
	        			ok_callback = function()
	        				UIKit:newGameUI('GameUIWathTowerRegion',City,'march'):AddToCurrentScene(true)
	        			end,
	        			ok_string = _("前往解锁")
	    			})
				else
					UIKit:showMessageDialogWithParams({
	        			content = _("没有空闲的行军队列"),
	        			ok_string = _("确定"),
	    			})
				end
    			return
			end

			if dragon:WarningStrikeDragon() then
				UIKit:showMessageDialog(_("提示"),_("您派出的龙可能会因血量过低而死亡，您确定还要派出吗？"), function()
					self:OnStrikeButtonClicked()
				end, function()end)
			else
				self:OnStrikeButtonClicked()
			end
		end)
	local time_bg = display.newSprite("alliance_title_gem_bg_154x20.png"):addTo(button):align(display.CENTER_BOTTOM,0,10)
	local time_icon = display.newSprite("hourglass_30x38.png"):align(display.LEFT_CENTER, 10, 10):addTo(time_bg):scale(0.8)
	UIKit:ttfLabel({
		size = 18,
		text = self:GetMarchTime(),
	}):align(display.LEFT_CENTER, 10 + time_icon:getCascadeBoundingBox().width + 10, 10):addTo(time_bg)
    self:RefreshListView()
end

function GameUIStrikePlayer:RefreshListView()
	local dragons = self:GetDragonManager():GetDragons()
 	for k,dragon in pairs(dragons) do
		if dragon:Ishated() then
			local item = self:GetItem(dragon,self.select_dragon_type)
			self.list_view:addItem(item)
		end
	end
	self.list_view:reload()
end

function GameUIStrikePlayer:GetItem(dragon,power_dragon_type)
	local item = self.list_view:newItem()
	local content = display.newNode()
	local box = display.newSprite("alliance_item_flag_box_126X126.png")
		:align(display.LEFT_BOTTOM,0,0)
		:addTo(content)
	local head_bg = display.newSprite("dragon_bg_114x114.png", 63, 63):addTo(box)
	display.newSprite(UILib.dragon_head[dragon:Type()], 56, 60):addTo(head_bg)
	local content_box = display.newScale9Sprite("box_426X126.png")
		:size(426,126)
		:addTo(content)
		:align(display.LEFT_BOTTOM,128,0)
	UIKit:ttfLabel({
		text = dragon:GetLocalizedName() .. "( LV " .. dragon:Level() .. " )",
		size = 22,
		color = 0x514d3e,
	}):align(display.LEFT_TOP,20, 120):addTo(content_box)

	UIKit:ttfLabel({
		text = _("生命值") .. " " .. dragon:Hp() .. "/" .. dragon:GetMaxHP(),
		size = 20,
		color= 0x615b44
	}):align(display.LEFT_CENTER,20,63):addTo(content_box)
	local color = 0x007c23
	if dragon:Status() == 'march' then
		color = 0x7e0000
	end
	UIKit:ttfLabel({
		text = dragon:GetLocalizedStatus(),
		size = 20,
		color = color
	}):align(display.LEFT_BOTTOM,20,16):addTo(content_box)
	local button = WidgetPushButton.new({
		normal = "checkbox_unselected.png",disabled = "checkbox_selectd.png"
	}):align(display.RIGHT_CENTER,400,63):addTo(content_box)
	:onButtonClicked(function(event)
		self:OnButtonClickInItem(dragon:Type())
	end)
	if power_dragon_type == dragon:Type() then
		button:setButtonEnabled(false)
		self.select_dragon_type = dragon:Type()
	end
	item.dragon_type = dragon:Type()
	item.button = button
	item:addContent(content)
	item:setItemSize(window.width-80, 132)
	content:size(window.width-80, 132)
	return item
end

function GameUIStrikePlayer:OnButtonClickInItem(dragon_type)
	for _,item in ipairs(self.list_view:getItems()) do
		item.button:setButtonEnabled(dragon_type~=item.dragon_type)
	end	 
	if dragon_type ~= self.select_dragon_type then
		self.select_dragon_type = dragon_type
		self:ReloadDragon()
	end
end

function GameUIStrikePlayer:CheckDragonIsFree()
	local dragon = self:GetDragon()

	if not dragon:IsFree() and not dragon:IsDefenced() then
        UIKit:showMessageDialog(_("提示"),_("龙未处于空闲状态"))
        return false
    elseif dragon:IsDead() then
	    UIKit:showMessageDialog(_("提示"),_("选择的龙已经死亡"))
	    return false
	end
	if dragon:IsDefenced() then
		 NetManager:getCancelDefenceDragonPromise():done(function()
		 	self:SendDataToServer()
		 end)
		 return
	end
	self:SendDataToServer()
end

function GameUIStrikePlayer:GetSelectDragonType()
	return self.select_dragon_type
end

function GameUIStrikePlayer:SendDataToServerRealy()
	if self.strike_type == self.STRIKE_TYPE.CITY then
		if self.params.targetIsProtected then
			UIKit:showMessageDialog(_("提示"),_("目标城市已被击溃并进入保护期，可能无法发生战斗，你是否继续突袭?"), function()
                NetManager:getStrikePlayerCityPromise(self:GetSelectDragonType(),self.params.memberId,self.params.alliance._id):done(function()
					app:GetAudioManager():PlayeEffectSoundWithKey("DRAGON_STRIKE")
					self:LeftButtonClicked()
				end)
            end,function()end)
        else
        	NetManager:getStrikePlayerCityPromise(self:GetSelectDragonType(),self.params.memberId,self.params.alliance._id):done(function()
				app:GetAudioManager():PlayeEffectSoundWithKey("DRAGON_STRIKE")
				self:LeftButtonClicked()
			end)
		end
		
	else
		NetManager:getStrikeVillagePromise(self:GetSelectDragonType(),self.params.defenceAllianceId,self.params.defenceVillageId):done(function()
			app:GetAudioManager():PlayeEffectSoundWithKey("DRAGON_STRIKE")
			self:LeftButtonClicked()
		end)
	end
end
function GameUIStrikePlayer:SendDataToServer()
	local alliance = Alliance_Manager:GetMyAlliance()
	local me = alliance:GetSelf()
 --    if me:IsProtected() then
 --    	local str = self.strike_type == self.STRIKE_TYPE.CITY and _("突袭玩家城市将失去保护状态，确定继续派兵?") or _("突袭村落将失去保护状态，确定继续派兵?")
	-- 	 UIKit:showMessageDialog(_("提示"),str,function()
	-- 	 	self:SendDataToServerRealy()
	-- 	 end)
	-- else
		self:SendDataToServerRealy()
    -- end
end

function GameUIStrikePlayer:OnStrikeButtonClicked()
	self:CheckDragonIsFree()
end

return GameUIStrikePlayer
